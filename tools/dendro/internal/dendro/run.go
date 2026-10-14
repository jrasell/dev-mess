package dendro

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"go.uber.org/zap"
	"golang.org/x/mod/modfile"
)

func git(ctx context.Context, dir string, args ...string) (string, error) {
	cmd := exec.CommandContext(ctx, "git", args...)
	if dir != "" {
		cmd.Dir = dir
	}
	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, strings.TrimSpace(string(out)))
	}
	return strings.TrimSpace(string(out)), nil
}

// Run checks the configured branches and writes their dependency results to output.
func Run(ctx context.Context, cfg Config, output io.Writer, logger *zap.Logger) error {
	base, err := webBase(cfg.Repository)
	if err != nil {
		return err
	}
	if cfg.WebURL != "" {
		base = strings.TrimSuffix(cfg.WebURL, "/")
	}
	if base == "" {
		logger.Warn("permalinks unavailable for this repository; set source.web_url or --web-url")
	}
	logger.Info("starting dependency check", zap.String("mode", cfg.Mode), zap.Int("branches", len(cfg.Branches)), zap.Int("go_dependencies", len(cfg.Dependencies.Go)))
	scratch, err := os.MkdirTemp("", "depcheck-*")
	if err != nil {
		return err
	}
	defer func() {
		if err := os.RemoveAll(scratch); err != nil {
			logger.Warn("failed to remove scratch directory", zap.Error(err))
		}
	}()
	repo := filepath.Join(scratch, "repo")

	logger.Info("cloning repository into scratch directory", zap.String("path", repo))

	started := time.Now()
	if err := cloneWithProgress(ctx, cfg.Repository, repo, logger); err != nil {
		return err
	}
	logger.Info("repository cloned", zap.Duration("elapsed", time.Since(started)))

	results := make(versionsByBranch, len(cfg.Branches))
	for _, branch := range cfg.Branches {
		started := time.Now()
		logger.Info("checking branch", zap.String("branch", branch))
		// Resolve only remote branches, then check out the commit by ID. This also
		// avoids passing branch names (which might start with '-') to checkout.
		commit, err := git(ctx, repo, "rev-parse", "--verify", "refs/remotes/origin/"+branch+"^{commit}")
		if err != nil {
			return fmt.Errorf("branch %q: %w", branch, err)
		}
		if _, err := git(ctx, repo, "checkout", "--detach", commit); err != nil {
			return fmt.Errorf("branch %q: %w", branch, err)
		}
		logger.Info("branch checked out", zap.String("branch", branch), zap.String("commit", commit))
		results[branch] = make(map[string]manifestResult)
		if usesGo(cfg) {
			for _, modPath := range cfg.GoMods {
				logger.Debug("reading Go module", zap.String("branch", branch), zap.String("path", modPath))
				path := filepath.Join(repo, modPath)
				versions, err := goVersions(path, cfg.DirectOnly)
				if err != nil {
					return fmt.Errorf("branch %q: %w", branch, err)
				}
				result := manifestResult{Versions: versions}
				if _, err := os.Stat(path); err == nil {
					result.FileURL = permalink(base, commit, modPath, 0)
				}
				for name, info := range versions {
					info.Evidence = evidence(base, commit, modPath, info)
					versions[name] = info
				}
				results[branch][goEcosystem(modPath)] = result
			}
		}
		logger.Info("branch complete", zap.String("branch", branch), zap.Duration("elapsed", time.Since(started)))
	}
	if err := render(output, cfg, results); err != nil {
		return err
	}
	logger.Info("dependency check complete", zap.Int("branches", len(cfg.Branches)))
	return nil
}

// RunWithOutput writes to stdout or atomically replaces the configured output file.
func RunWithOutput(ctx context.Context, cfg Config, logger *zap.Logger) error {
	if cfg.Output == "" {
		return Run(ctx, cfg, os.Stdout, logger)
	}
	file, err := os.CreateTemp(filepath.Dir(cfg.Output), ".depcheck-*")
	if err != nil {
		return fmt.Errorf("create output file %q: %w", cfg.Output, err)
	}
	defer os.Remove(file.Name())
	if err := Run(ctx, cfg, file, logger); err != nil {
		_ = file.Close()
		return err
	}
	if err := file.Close(); err != nil {
		return fmt.Errorf("close output file %q: %w", cfg.Output, err)
	}
	if err := os.Rename(file.Name(), cfg.Output); err != nil {
		return fmt.Errorf("save output file %q: %w", cfg.Output, err)
	}
	logger.Info("output saved", zap.String("path", cfg.Output))
	return nil
}

func usesGo(cfg Config) bool {
	return cfg.Ecosystem == "go"
}

func cloneWithProgress(ctx context.Context, source, destination string, logger *zap.Logger) error {
	finished := make(chan struct{})
	var progressDone = make(chan struct{})
	started := time.Now()
	go func() {
		defer close(progressDone)
		ticker := time.NewTicker(10 * time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				logger.Info("repository clone still running",
					zap.Int64("elapsed_ms", time.Since(started).Milliseconds()),
				)
			case <-finished:
				return
			}
		}
	}()
	_, err := git(ctx, "", "clone", "--no-checkout", "--", source, destination)
	close(finished)
	<-progressDone
	return err
}

func display(version string) string {
	if version == "" {
		return "-"
	}
	return version
}

func goVersions(path string, directOnly bool) (map[string]versionInfo, error) {
	versions := make(map[string]versionInfo)
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return versions, nil
	}
	if err != nil {
		return nil, err
	}
	mod, err := modfile.Parse(path, data, nil)
	if err != nil {
		return nil, fmt.Errorf("parse %s: %w", path, err)
	}
	for _, require := range mod.Require {
		if directOnly && require.Indirect {
			continue
		}
		info := versionInfo{Version: require.Mod.Version}
		if require.Syntax != nil {
			info.Line = require.Syntax.Start.Line
		}
		for _, replace := range mod.Replace {
			if replace.Old.Path == require.Mod.Path && (replace.Old.Version == "" || replace.Old.Version == info.Version) {
				info.Version += " => " + replace.New.Path
				if replace.New.Version != "" {
					info.Version += "@" + replace.New.Version
				}
				if replace.Syntax != nil {
					info.ReplacementLine = replace.Syntax.Start.Line
				}
				break
			}
		}
		versions[require.Mod.Path] = info
	}
	return versions, nil
}

