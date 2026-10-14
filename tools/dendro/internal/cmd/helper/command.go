package helper

import (
	"context"
	"fmt"
	"os"

	"github.com/urfave/cli/v3"
	"go.uber.org/zap"

	"github.com/jrasell/dev-mess/tools/dendro/internal/dendro"
)

// Flags shared by check and diff. Flag values override the selected TOML section.
func Flags() []cli.Flag {
	return []cli.Flag{
		&cli.StringFlag{Name: "config", Usage: "TOML configuration file (optional when using flags)"},
		&cli.StringFlag{Name: "repo", Usage: "Git repository URL or local path"},
		&cli.StringFlag{Name: "web-url", Usage: "HTTPS repository page for permalinks (for local or unsupported remotes)"},
		&cli.StringSliceFlag{Name: "ref", Aliases: []string{"branch"}, Usage: "Branch to inspect (repeatable)"},
		&cli.StringFlag{Name: "ecosystem", Usage: "go (default: go)"},
		&cli.StringFlag{Name: "output-format", Aliases: []string{"format"}, Usage: "table, csv, or json (default: table)"},
		&cli.StringFlag{Name: "output-file", Aliases: []string{"output"}, Usage: "Write results to this file instead of stdout"},
		&cli.StringSliceFlag{Name: "go-mod", Usage: "Path to a Go module file within the repository (repeatable)"},
		&cli.StringSliceFlag{Name: "go-dep", Usage: "Go module to check or filter (repeatable)"},
		&cli.BoolFlag{Name: "direct", Usage: "Only include direct Go dependencies"},
		&cli.StringFlag{Name: "log-level", Usage: "Log level (default: info)"},
		&cli.BoolFlag{Name: "log-console", Usage: "Also log to stderr; file logging is always on"},
	}
}

func Run(ctx context.Context, cmd *cli.Command, mode string) error {
	if cmd.NArg() != 0 {
		return fmt.Errorf("unexpected arguments: %v", cmd.Args().Slice())
	}
	cfg, err := dendro.LoadConfig(cmd.String("config"), mode)
	if err != nil {
		return err
	}
	applyFlags(&cfg, cmd)
	if err := cfg.Validate(); err != nil {
		return err
	}
	cacheDir, err := os.UserCacheDir()
	if err != nil {
		return fmt.Errorf("locating user cache directory: %w", err)
	}
	logger, closeLog, err := dendro.NewLogger(cacheDir, cfg.LogLevel, cfg.LogConsole, os.Stderr)
	if err != nil {
		return err
	}
	defer closeLog()
	if err := dendro.RunWithOutput(ctx, cfg, logger); err != nil {
		logger.Error("dependency check failed", zap.Error(err))
		return err
	}
	return nil
}

func applyFlags(cfg *dendro.Config, cmd *cli.Command) {
	if cmd.IsSet("repo") {
		cfg.Repository = cmd.String("repo")
	}
	if cmd.IsSet("web-url") {
		cfg.WebURL = cmd.String("web-url")
	}
	if cmd.IsSet("ref") {
		cfg.Branches = cmd.StringSlice("ref")
	}
	if cmd.IsSet("ecosystem") {
		cfg.Ecosystem = cmd.String("ecosystem")
	}
	if cmd.IsSet("output-format") {
		cfg.Format = cmd.String("output-format")
	}
	if cmd.IsSet("output-file") {
		cfg.Output = cmd.String("output-file")
	}
	if cmd.IsSet("go-mod") {
		cfg.GoMods = cmd.StringSlice("go-mod")
	}
	if cmd.IsSet("go-dep") {
		cfg.Dependencies.Go = cmd.StringSlice("go-dep")
	}
	if cmd.IsSet("direct") {
		cfg.DirectOnly = cmd.Bool("direct")
	}
	if cmd.IsSet("log-level") {
		cfg.LogLevel = cmd.String("log-level")
	}
	if cmd.IsSet("log-console") {
		cfg.LogConsole = cmd.Bool("log-console")
	}
}
