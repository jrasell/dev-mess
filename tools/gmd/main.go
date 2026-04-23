package main

import (
	"bytes"
	"context"
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/pterm/pterm"
	"github.com/urfave/cli/v3"
	"golang.org/x/mod/modfile"
)

func main() {
	if err := runCLIApp(os.Args); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	os.Exit(0)
}

type config struct {
	repo       string
	goModPath  string
	refs       []string
	format     string
	directOnly bool
	fetchRefs  bool
}

func runCLIApp(args []string) error {
	app := &cli.Command{
		Name: "gmd",
		Usage: strings.TrimSpace(
			`
Go Module Diff (gmd) compares Golang module dependencies across multiple git
references in a repository. It can be used to identify differences in required
modules and versions which is useful when working across multiple branches and
remotes.`),
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:  "repo",
				Usage: "Path to the local git repository",
				Value: ".",
			},
			&cli.StringFlag{
				Name:  "gomod",
				Usage: "Path to the go.mod file within the repo",
				Value: "go.mod",
			},
			&cli.StringSliceFlag{
				Name:  "ref",
				Usage: "The git ref to compare (can specify multiple times, e.g. -ref=main -ref=feature-branch)",
			},
			&cli.BoolFlag{
				Name:  "direct",
				Usage: "Only consider direct requires (exclude indirect requires)",
				Value: false,
			},
			&cli.BoolFlag{
				Name:  "fetch",
				Usage: "Checkout each ref and pull remote changes before diffing",
				Value: false,
			},
			&cli.StringFlag{
				Name:  "format",
				Usage: "The output format to use. Supported values: 'table' (default), 'csv'",
				Value: "table",
			},
		},
		UseShortOptionHandling: true,
		Action: func(cliCtx context.Context, cmd *cli.Command) error {

			cfg := config{
				repo:       cmd.String("repo"),
				goModPath:  cmd.String("gomod"),
				format:     cmd.String("format"),
				directOnly: cmd.Bool("direct-only"),
				refs:       cmd.StringSlice("ref"),
				fetchRefs:  cmd.Bool("fetch"),
			}

			repo, err := filepath.Abs(cfg.repo)
			if err != nil {
				return err
			}

			// Remove duplicate refs while preserving order. This allows users
			// to specify refs in any order and avoid redundant work if they
			// accidentally repeat a ref.
			refs := uniquePreserveOrder(cfg.refs)

			// Validate repo looks like a git repository.
			if err := ensureGitRepo(cliCtx, repo); err != nil {
				return err
			}

			// Check for uncommitted changes before switching refs. As we will
			// be doing checkouts, we want to avoid losing any uncommitted work.
			if cfg.fetchRefs {
				clean, err := isWorkingTreeClean(cliCtx, repo)
				if err != nil {
					return fmt.Errorf("checking working tree status: %w", err)
				}
				if !clean {
					return fmt.Errorf("working tree is dirty: %q", repo)
				}
			}

			if _, err := git(cliCtx, repo, "pull", "--all"); err != nil {
				pterm.Warning.Printfln("failed to pull all refs: %v", err)
			}

			// Read and parse go.mod from each ref.
			perRef := make(map[string]map[string]reqInfo, len(refs))
			for _, ref := range refs {

				if cfg.fetchRefs {
					if err := checkoutAndPull(cliCtx, repo, ref); err != nil {
						return err
					}
				}

				data, err := readFileAtRef(cliCtx, repo, ref, cfg.goModPath)
				if err != nil {
					return err
				}
				reqs, err := parseGoModRequires(data, cfg.directOnly)
				if err != nil {
					return err
				}
				perRef[ref] = reqs
			}

			// Compute differing modules.
			diffs := computeDiffs(perRef, refs)

			// Render output.
			switch strings.ToLower(cfg.format) {
			case "table":
				err = writeTable(diffs, refs)
			case "csv":
				writeCSV(os.Stdout, diffs, refs)
			default:
				err = fmt.Errorf("unsupported format: %q", cfg.format)
			}
			return err
		},
	}
	return app.Run(context.Background(), args)
}

func uniquePreserveOrder(in []string) []string {
	seen := make(map[string]struct{}, len(in))
	out := make([]string, 0, len(in))
	for _, s := range in {
		if _, ok := seen[s]; ok {
			continue
		}
		seen[s] = struct{}{}
		out = append(out, s)
	}
	return out
}

func ensureGitRepo(ctx context.Context, repo string) error {
	// git rev-parse --is-inside-work-tree
	out, err := git(ctx, repo, "rev-parse", "--is-inside-work-tree")
	if err != nil {
		return err
	}
	if strings.TrimSpace(out) != "true" {
		return fmt.Errorf("rev-parse returned %q", strings.TrimSpace(out))
	}
	return nil
}

// currentRef returns the active branch name, or the commit hash when in
// detached-HEAD state, so the caller can restore the repository to its
// original position later.
func currentRef(ctx context.Context, repo string) (string, error) {
	branch, err := git(ctx, repo, "rev-parse", "--abbrev-ref", "HEAD")
	if err != nil {
		return "", err
	}
	branch = strings.TrimSpace(branch)
	if branch != "HEAD" {
		return branch, nil
	}
	// Detached HEAD – fall back to the full commit hash.
	hash, err := git(ctx, repo, "rev-parse", "HEAD")
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(hash), nil
}

// isWorkingTreeClean returns true when there are no staged or unstaged changes.
func isWorkingTreeClean(ctx context.Context, repo string) (bool, error) {
	out, err := git(ctx, repo, "status", "--porcelain")
	if err != nil {
		return false, err
	}
	return strings.TrimSpace(out) == "", nil
}

// checkoutAndPull switches to ref and pulls the latest remote changes.
// A pull failure is treated as a warning rather than a hard error because the
// ref may not have a configured upstream (e.g. a local-only branch or tag).
func checkoutAndPull(ctx context.Context, repo, ref string) error {
	if _, err := git(ctx, repo, "checkout", ref); err != nil {
		return fmt.Errorf("failed to checkout ref %q: %w", ref, err)
	}
	if _, err := git(ctx, repo, "pull"); err != nil {
		pterm.Warning.Printfln("pulling remote changes for ref %q: %v", ref, err)
	}
	return nil
}

func readFileAtRef(ctx context.Context, repo, ref, path string) ([]byte, error) {
	// Use "git show ref:path" to read contents without checkout.
	// Note: go.mod path is relative to repo root (same as git expects).
	spec := ref + ":" + filepath.ToSlash(path)
	out, err := gitBytes(ctx, repo, "show", spec)
	if err != nil {
		// Improve error for missing file.
		// git show exits non-zero if path doesn't exist at ref.
		return nil, err
	}
	return out, nil
}

type reqInfo struct {
	version  string
	indirect bool
}

func parseGoModRequires(goMod []byte, directOnly bool) (map[string]reqInfo, error) {
	// Parse with x/mod for correctness.
	f, err := modfile.Parse("go.mod", goMod, nil)
	if err != nil {
		return nil, err
	}

	reqs := make(map[string]reqInfo, len(f.Require))
	for _, r := range f.Require {
		if r == nil || r.Mod.Path == "" {
			continue
		}
		if directOnly && r.Indirect {
			continue
		}

		reqs[r.Mod.Path] = reqInfo{
			version:  strings.TrimSpace(r.Mod.Version),
			indirect: r.Indirect,
		}
	}

	// Note: Some requires may be added by parsing errors? Unlikely; keep simple.
	return reqs, nil
}

type diffRow struct {
	module     string
	perRef     map[string]string
	hasMissing bool
}

func computeDiffs(perRef map[string]map[string]reqInfo, refs []string) []diffRow {
	// Collect union of module paths.
	union := make(map[string]struct{})
	for _, ref := range refs {
		for mod := range perRef[ref] {
			union[mod] = struct{}{}
		}
	}

	rows := make([]diffRow, 0, len(union))
	for mod := range union {
		versions := make([]string, 0, len(refs))
		per := make(map[string]string, len(refs))
		hasMissing := false

		for _, ref := range refs {
			if info, ok := perRef[ref][mod]; ok {
				per[ref] = info.version
				versions = append(versions, info.version)
			} else {
				per[ref] = ""
				versions = append(versions, "")
				hasMissing = true
			}
		}

		if differs(versions) {
			rows = append(rows, diffRow{
				module:     mod,
				perRef:     per,
				hasMissing: hasMissing,
			})
		}
	}

	sort.Slice(rows, func(i, j int) bool { return rows[i].module < rows[j].module })
	return rows
}

func differs(values []string) bool {
	// Treat "missing" as "no opinion" for whether versions differ:
	// - If all present versions are the same (even if some refs don't require it), it's NOT a diff.
	// - Only report when there are at least two *different* non-empty versions across refs.
	seen := make(map[string]struct{}, len(values))
	for _, v := range values {
		v = strings.TrimSpace(v)
		if v == "" {
			continue
		}
		seen[v] = struct{}{}
		if len(seen) > 1 {
			return true
		}
	}
	return false
}

func writeTable(diffs []diffRow, refs []string) error {

	if len(diffs) == 0 {
		return nil
	}

	out := pterm.TableData{}
	header := make([]string, 0, 1+len(refs))
	header = append(header, "module")
	header = append(header, refs...)
	out = append(out, header)

	for _, row := range diffs {
		r := make([]string, 0, 1+len(refs))
		r = append(r, row.module)

		for _, ref := range refs {
			r = append(r, row.perRef[ref])
		}
		out = append(out, r)
	}

	// Render to the provided writer (not stdout).
	return pterm.DefaultTable.WithHasHeader().WithData(out).Render()
}

func writeCSV(w io.Writer, diffs []diffRow, refs []string) {
	filename := fmt.Sprintf("gmd-%d.csv", time.Now().Unix())

	f, err := os.Create(filename)
	if err != nil {
		// best effort: surface error to the provided writer
		fmt.Fprintf(w, "failed to create csv %q: %v\n", filename, err)
		return
	}
	defer f.Close()

	cw := csv.NewWriter(f)

	// Header: module + refs
	_ = cw.Write(append([]string{"module"}, refs...))

	for _, row := range diffs {
		rec := make([]string, 0, 1+len(refs))
		rec = append(rec, row.module)
		for _, ref := range refs {
			ver := row.perRef[ref]
			if ver == "" {
				ver = "(missing)" // or "" if you prefer blank in CSV
			}
			rec = append(rec, ver)
		}
		_ = cw.Write(rec)
	}

	cw.Flush()
	if err := cw.Error(); err != nil {
		fmt.Fprintf(w, "failed writing csv %q: %v\n", filename, err)
		return
	}

	// Tell the caller where it went
	fmt.Fprintln(w, filename)
}

func git(ctx context.Context, repo string, args ...string) (string, error) {
	out, err := gitBytes(ctx, repo, args...)
	return string(out), err
}

func gitBytes(ctx context.Context, repo string, args ...string) ([]byte, error) {
	// Ensure git runs in repo directory (no need for -C since we set Dir).
	cmd := exec.CommandContext(ctx, "git", args...)
	cmd.Dir = repo

	// Prevent git paging.
	cmd.Env = append(os.Environ(), "GIT_PAGER=cat", "PAGER=cat")

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err == nil {
		return stdout.Bytes(), nil
	}

	// If context deadline exceeded, prefer that message.
	if ctx.Err() != nil {
		return nil, ctx.Err()
	}

	// Provide combined error with stderr.
	msg := strings.TrimSpace(stderr.String())
	if msg == "" {
		msg = err.Error()
	}
	return nil, fmt.Errorf("git %s: %s", strings.Join(args, " "), msg)
}
