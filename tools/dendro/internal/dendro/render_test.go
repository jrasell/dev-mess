package dendro

import (
	"bytes"
	"strings"
	"testing"
)

func TestDiffEvidenceHiddenOnlyInConsoleTable(t *testing.T) {
	cfg := Config{Mode: "diff", Ecosystem: "go", Format: "table", Branches: []string{"release", "main"}, GoMods: []string{"go.mod"}}
	results := versionsByBranch{
		"main":    {"go@root": {Versions: map[string]versionInfo{"example.com/lib": {Version: "v1.0.0", Evidence: "https://example.com/main#L5"}}}},
		"release": {"go@root": {Versions: map[string]versionInfo{"example.com/lib": {Version: "v2.0.0", Evidence: "https://example.com/release#L5"}}}},
	}
	var out bytes.Buffer
	if err := render(&out, cfg, results); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), "example.com/lib") || !strings.Contains(out.String(), "v1.0.0") || !strings.Contains(out.String(), "v2.0.0") || strings.Contains(out.String(), "EVIDENCE") || strings.Contains(out.String(), "https://example.com/") {
		t.Fatalf("console diff should contain versions, not evidence: %s", out.String())
	}

	cfg.Output = "report.txt"
	out.Reset()
	if err := render(&out, cfg, results); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), "main EVIDENCE") || !strings.Contains(out.String(), "https://example.com/release#L5") {
		t.Fatalf("file table lost evidence: %s", out.String())
	}

	cfg.Format = "csv"
	cfg.Output = ""
	out.Reset()
	if err := render(&out, cfg, results); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), "main EVIDENCE") || !strings.Contains(out.String(), "https://example.com/main#L5") {
		t.Fatalf("CSV lost evidence: %s", out.String())
	}
}
