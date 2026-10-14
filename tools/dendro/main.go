package main

import (
	"fmt"
	"os"

	"github.com/jrasell/dev-mess/tools/dendro/internal/cmd"
)

func main() {
	if err := cmd.Run(os.Args); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
