package dendro

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"github.com/BurntSushi/toml"
)

// Config contains the effective settings for the selected subcommand.
type Config struct {
	Repository   string
	WebURL       string
	Branches     []string
	Mode         string
	Ecosystem    string
	Format       string
	Output       string
	GoMods       []string
	DirectOnly   bool
	LogLevel     string
	LogConsole   bool
	Dependencies struct {
		Go []string
	}
}

type modeConfig struct {
	Ecosystem  string   `toml:"ecosystem"`
	Go         []string `toml:"go"`
	DirectOnly bool     `toml:"direct_only"`
}

type fileConfig struct {
	Source struct {
		Repository string   `toml:"repository"`
		WebURL     string   `toml:"web_url"`
		Branches   []string `toml:"branches"`
		GoMods     []string `toml:"go_mods"`
	} `toml:"source"`
	Check  modeConfig `toml:"check"`
	Diff   modeConfig `toml:"diff"`
	Output struct {
		Format string `toml:"format"`
		File   string `toml:"file"`
	} `toml:"output"`
	Log struct {
		Level   string `toml:"level"`
		Console bool   `toml:"console"`
	} `toml:"log"`
}

func LoadConfig(path, mode string) (Config, error) {
	cfg := Config{Mode: mode}
	if path == "" {
		return cfg, nil
	}
	var file fileConfig
	meta, err := toml.DecodeFile(path, &file)
	if err != nil {
		return cfg, fmt.Errorf("read config: %w", err)
	}
	if keys := meta.Undecoded(); len(keys) != 0 {
		return cfg, fmt.Errorf("unknown config key: %s", keys[0])
	}
	cfg.Repository = file.Source.Repository
	cfg.WebURL = file.Source.WebURL
	cfg.Branches = file.Source.Branches
	cfg.GoMods = file.Source.GoMods
	cfg.Format = file.Output.Format
	cfg.Output = file.Output.File
	cfg.LogLevel = file.Log.Level
	cfg.LogConsole = file.Log.Console
	selected := file.Check
	if mode == "diff" {
		selected = file.Diff
	}
	cfg.Ecosystem = selected.Ecosystem
	cfg.DirectOnly = selected.DirectOnly
	cfg.Dependencies.Go = selected.Go
	// Local repositories in configuration are relative to that file.
	if cfg.Repository != "" && !strings.Contains(cfg.Repository, "://") && !strings.HasPrefix(cfg.Repository, "git@") {
		candidate := cfg.Repository
		if !filepath.IsAbs(candidate) {
			candidate = filepath.Join(filepath.Dir(path), candidate)
		}
		if _, err := os.Stat(candidate); err == nil {
			cfg.Repository = candidate
		}
	}
	return cfg, nil
}

func (cfg *Config) Validate() error {
	if cfg.Repository == "" || len(cfg.Branches) == 0 {
		return errors.New("repository and at least one branch are required (in config or flags)")
	}
	if slices.Contains(cfg.Branches, "") || slices.Contains(cfg.Dependencies.Go, "") {
		return errors.New("branches and dependency names cannot be empty")
	}
	if cfg.Mode != "check" && cfg.Mode != "diff" {
		return fmt.Errorf("unsupported mode %q (use check or diff)", cfg.Mode)
	}
	if cfg.Ecosystem == "" {
		cfg.Ecosystem = "go"
	}
	if cfg.Ecosystem != "go" {
		return fmt.Errorf("unsupported ecosystem %q (only go is supported)", cfg.Ecosystem)
	}
	if cfg.Mode == "check" && !(usesGo(*cfg) && len(cfg.Dependencies.Go) != 0) {
		return errors.New("check mode requires at least one dependency in the selected ecosystem")
	}
	if cfg.Format == "" {
		cfg.Format = "table"
	}
	if cfg.Format != "table" && cfg.Format != "csv" && cfg.Format != "json" {
		return fmt.Errorf("unsupported format %q (use table, csv, or json)", cfg.Format)
	}
	if len(cfg.GoMods) == 0 {
		cfg.GoMods = []string{"go.mod"}
	}
	labels := make(map[string]string, len(cfg.GoMods))
	for _, path := range cfg.GoMods {
		if !filepath.IsLocal(path) {
			return fmt.Errorf("manifest path must be relative to repository: %q", path)
		}
		label := goEcosystem(path)
		if other, exists := labels[label]; exists {
			return fmt.Errorf("Go modules %q and %q both have output label %q", other, path, label)
		}
		labels[label] = path
	}
	if cfg.LogLevel == "" {
		cfg.LogLevel = "info"
	}
	return nil
}

func goEcosystem(path string) string {
	dir := filepath.Dir(filepath.Clean(path))
	if dir == "." {
		return "go@root"
	}
	// A directory literally named "go" is usually a language folder; label
	// its containing module instead (e.g. jobspec2/this/go/mod -> go@this).
	if filepath.Base(dir) == "go" && filepath.Dir(dir) != "." {
		dir = filepath.Dir(dir)
	}
	return "go@" + filepath.Base(dir)
}
