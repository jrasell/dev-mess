package dendro

import (
	"fmt"
	"net/url"
	"path/filepath"
	"strings"
)

// versionInfo tracks where a declared version appears in the checked-out manifest.
type versionInfo struct {
	Version         string
	Evidence        string
	Line            int
	ReplacementLine int
}

type manifestResult struct {
	FileURL  string
	Versions map[string]versionInfo
}

type versionsByBranch map[string]map[string]manifestResult

// webBase returns an HTTPS repository URL without embedding remote credentials.
// Unknown remotes need an explicit web_url; guessing their URL layout would
// produce misleading evidence links.
func webBase(repository string) (string, error) {
	var host, repoPath string

	if strings.HasPrefix(repository, "git@") {
		parts := strings.SplitN(strings.TrimPrefix(repository, "git@"), ":", 2)
		if len(parts) != 2 {
			return "", nil
		}
		host, repoPath = parts[0], parts[1]
	} else {
		u, err := url.Parse(repository)
		if err != nil || (u.Scheme != "https" && u.Scheme != "ssh") || u.User != nil && u.Scheme == "https" {
			return "", nil
		}
		host, repoPath = u.Hostname(), strings.TrimPrefix(u.Path, "/")
	}
	// Only known forges can be mapped without explicit configuration.
	switch strings.ToLower(host) {
	case "github.com", "gitlab.com", "bitbucket.org":
	default:
		return "", nil
	}
	repoPath = strings.TrimSuffix(strings.Trim(repoPath, "/"), ".git")
	if repoPath == "" || strings.Contains(repoPath, "..") || strings.ContainsAny(repoPath, "?#") {
		return "", nil
	}
	return "https://" + strings.ToLower(host) + "/" + repoPath, nil
}

func permalink(base, commit, manifest string, line int) string {
	if base == "" || commit == "" {
		return ""
	}
	u, err := url.Parse(base)
	if err != nil {
		return ""
	}
	part := "blob"
	fragment := fmt.Sprintf("L%d", line)
	switch strings.ToLower(u.Hostname()) {
	case "gitlab.com":
		part = "-/blob"
	case "bitbucket.org":
		part = "src"
		fragment = fmt.Sprintf("lines-%d", line)
	}
	parts := strings.Split(filepath.ToSlash(manifest), "/")
	for i := range parts {
		parts[i] = url.PathEscape(parts[i])
	}
	result := base + "/" + part + "/" + commit + "/" + strings.Join(parts, "/")
	if line > 0 {
		result += "#" + fragment
	}
	return result
}

func evidence(base, commit, path string, info versionInfo) string {
	if info.Line == 0 {
		return permalink(base, commit, path, 0)
	}
	link := permalink(base, commit, path, info.Line)
	if info.ReplacementLine != 0 {
		link += " " + permalink(base, commit, path, info.ReplacementLine)
	}
	return strings.TrimSpace(link)
}
