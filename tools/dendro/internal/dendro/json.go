package dendro

import (
	"encoding/json"
	"io"
)

type jsonVersion struct {
	Version     *string `json:"version"`
	EvidenceURL string  `json:"evidence_url,omitempty"`
}

type jsonCheckRow struct {
	Branch      string  `json:"branch"`
	Ecosystem   string  `json:"ecosystem"`
	Dependency  string  `json:"dependency"`
	Version     *string `json:"version"`
	EvidenceURL string  `json:"evidence_url,omitempty"`
}

type jsonDiffRow struct {
	Ecosystem  string                 `json:"ecosystem"`
	Dependency string                 `json:"dependency"`
	Branches   map[string]jsonVersion `json:"branches"`
}

func jsonCell(version, evidence string) jsonVersion {
	cell := jsonVersion{}
	if version != "-" {
		cell.Version = &version
	}
	if evidence != "-" {
		cell.EvidenceURL = evidence
	}
	return cell
}

func writeJSON(output io.Writer, mode string, rows [][]string) error {
	encoder := json.NewEncoder(output)
	encoder.SetIndent("", "  ")
	encoder.SetEscapeHTML(false)
	if mode == "check" {
		out := struct {
			Mode    string         `json:"mode"`
			Results []jsonCheckRow `json:"results"`
		}{Mode: mode, Results: make([]jsonCheckRow, 0, len(rows)-1)}
		for _, row := range rows[1:] {
			cell := jsonCell(row[3], row[4])
			out.Results = append(out.Results, jsonCheckRow{
				Branch: row[0], Ecosystem: row[1], Dependency: row[2], Version: cell.Version, EvidenceURL: cell.EvidenceURL,
			})
		}
		return encoder.Encode(out)
	}
	branches := make([]string, 0, (len(rows[0])-2)/2)
	for i := 2; i < len(rows[0]); i += 2 {
		branches = append(branches, rows[0][i])
	}
	out := struct {
		Mode     string        `json:"mode"`
		Branches []string      `json:"branches"`
		Results  []jsonDiffRow `json:"results"`
	}{Mode: mode, Branches: branches, Results: make([]jsonDiffRow, 0, len(rows)-1)}
	for _, row := range rows[1:] {
		entry := jsonDiffRow{Ecosystem: row[0], Dependency: row[1], Branches: make(map[string]jsonVersion, len(branches))}
		for i, branch := range branches {
			entry.Branches[branch] = jsonCell(row[2+2*i], row[3+2*i])
		}
		out.Results = append(out.Results, entry)
	}
	return encoder.Encode(out)
}
