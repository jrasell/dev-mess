package main

import (
	"context"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"github.com/jrasell/dev-mess/tools/terraform-dev-provider/internal/provider"
)

func main() {
	if err := providerserver.Serve(
		context.Background(),
		provider.New("dev"),
		providerserver.ServeOpts{Address: "registry.terraform.io/jrasell/dev"},
	); err != nil {
		log.Fatal(err.Error())
	}
}
