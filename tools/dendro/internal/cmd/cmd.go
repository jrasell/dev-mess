package cmd

import (
	"context"

	"github.com/urfave/cli/v3"

	"github.com/jrasell/dev-mess/tools/dendro/internal/cmd/check"
	"github.com/jrasell/dev-mess/tools/dendro/internal/cmd/diff"
)

func Run(args []string) error {
	app := &cli.Command{
		Name:  "dendro",
		Usage: "Inspect and compare Go dependencies across Git branches",
		Description: "Like tree rings, a repository's branches reveal how its dependencies have\n" +
			"changed over time. Dendro uses an isolated checkout to inspect Go\n" +
			"dependency versions.",
		Commands: []*cli.Command{
			check.Command(),
			diff.Command(),
		},
	}
	return app.Run(context.Background(), args)
}
