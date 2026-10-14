package dendro

import (
	"encoding/csv"
	"fmt"
	"io"
	"sort"
	"text/tabwriter"

	"github.com/pterm/pterm"
)

func ecosystems(cfg Config) []string {
	var names []string
	for _, path := range cfg.GoMods {
		names = append(names, goEcosystem(path))
	}
	return names
}

func dependencies(cfg Config, ecosystem string) []string {
	return cfg.Dependencies.Go
}

func versionAndEvidence(manifest manifestResult, name string) (string, string) {
	info := manifest.Versions[name]
	link := info.Evidence
	if info.Version == "" {
		link = manifest.FileURL // A file, not a nonexistent line, supports absence.
	}
	return display(info.Version), display(link)
}

func render(output io.Writer, cfg Config, results versionsByBranch) error {
	if cfg.Mode == "check" {
		rows := [][]string{{"BRANCH", "ECOSYSTEM", "DEPENDENCY", "VERSION", "EVIDENCE"}}
		for _, ecosystem := range ecosystems(cfg) {
			for _, name := range dependencies(cfg, ecosystem) {
				for _, branch := range cfg.Branches {
					version, link := versionAndEvidence(results[branch][ecosystem], name)
					rows = append(rows, []string{branch, ecosystem, name, version, link})
				}
			}
		}
		sort.Slice(rows[1:], func(i, j int) bool {
			a, b := rows[i+1], rows[j+1]
			if a[1] != b[1] {
				return a[1] < b[1] // ecosystem (including Go module label)
			}
			if a[0] != b[0] {
				return a[0] < b[0] // branch
			}
			return a[2] < b[2] // dependency within a branch
		})
		if cfg.Format == "json" {
			return writeJSON(output, cfg.Mode, rows)
		}
		return writeRows(output, cfg.Format, cfg.Output == "", rows)
	}

	branches := append([]string(nil), cfg.Branches...)
	sort.Strings(branches)
	header := []string{"ECOSYSTEM", "DEPENDENCY"}
	for _, branch := range branches {
		header = append(header, branch, branch+" EVIDENCE")
	}
	rows := [][]string{header}
	for _, ecosystem := range ecosystems(cfg) {
		names := append([]string(nil), dependencies(cfg, ecosystem)...)
		if len(names) == 0 {
			seen := make(map[string]bool)
			for _, branch := range branches {
				for name := range results[branch][ecosystem].Versions {
					seen[name] = true
				}
			}
			for name := range seen {
				names = append(names, name)
			}
		}
		sort.Strings(names)
		for _, name := range names {
			row := []string{ecosystem, name}
			first := ""
			different := false
			for _, branch := range branches {
				version, link := versionAndEvidence(results[branch][ecosystem], name)
				row = append(row, version, link)
				if version != "-" {
					if first != "" && first != version {
						different = true
					}
					first = version
				}
			}
			// Absence alone is not a version difference.
			if different {
				rows = append(rows, row)
			}
		}
	}
	sort.Slice(rows[1:], func(i, j int) bool {
		a, b := rows[i+1], rows[j+1]
		if a[0] != b[0] {
			return a[0] < b[0]
		}
		return a[1] < b[1]
	})
	if cfg.Format == "json" {
		return writeJSON(output, cfg.Mode, rows)
	}
	if cfg.Format == "table" && cfg.Output == "" {
		// Keep the console diff readable; file tables, CSV, and JSON retain
		// the commit-pinned evidence for every branch.
		compact := make([][]string, len(rows))
		for i, row := range rows {
			compact[i] = append([]string(nil), row[:2]...)
			for column := 2; column < len(row); column += 2 {
				compact[i] = append(compact[i], row[column])
			}
		}
		return writeRows(output, cfg.Format, true, compact)
	}
	return writeRows(output, cfg.Format, false, rows)
}

func writeRows(output io.Writer, format string, console bool, rows [][]string) error {
	if format == "csv" {
		w := csv.NewWriter(output)
		if err := w.WriteAll(rows); err != nil {
			return err
		}
		return w.Error()
	}
	if console {
		table, err := pterm.DefaultTable.WithHasHeader().WithData(rows).Srender()
		if err != nil {
			return err
		}
		_, err = io.WriteString(output, table)
		return err
	}
	w := tabwriter.NewWriter(output, 0, 8, 2, ' ', 0)
	for _, row := range rows {
		for i, cell := range row {
			if i != 0 {
				if _, err := fmt.Fprint(w, "\t"); err != nil {
					return err
				}
			}
			if _, err := fmt.Fprint(w, cell); err != nil {
				return err
			}
		}
		if _, err := fmt.Fprintln(w); err != nil {
			return err
		}
	}
	return w.Flush()
}
