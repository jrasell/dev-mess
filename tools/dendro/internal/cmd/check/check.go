package check

import (
	"context"

	"github.com/urfave/cli/v3"

	"github.com/jrasell/dev-mess/tools/dendro/internal/cmd/helper"
)

func Command() *cli.Command {
	return &cli.Command{
		Name:                   "check",
		Usage:                  "Show configured dependencies on each branch",
		Flags:                  helper.Flags(),
		UseShortOptionHandling: true,
		Action: func(ctx context.Context, cmd *cli.Command) error {
			return helper.Run(ctx, cmd, "check")
		},
	}
}
