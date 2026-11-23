package provider

import (
	"context"
	"crypto/rand"
	"encoding/hex"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/function"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/mapplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ provider.Provider = (*devProvider)(nil)

// devProvider is the dev Terraform provider.
type devProvider struct {
	version string
}

// New returns a constructor for the dev provider.
func New(version string) func() provider.Provider {
	return func() provider.Provider {
		return &devProvider{version: version}
	}
}

func (p *devProvider) Metadata(
	_ context.Context,
	_ provider.MetadataRequest,
	resp *provider.MetadataResponse,
) {
	resp.TypeName = "dev"
	resp.Version = p.version
}

func (p *devProvider) Schema(
	_ context.Context,
	_ provider.SchemaRequest,
	_ *provider.SchemaResponse,
) {
}

func (p *devProvider) Configure(
	_ context.Context,
	_ provider.ConfigureRequest,
	_ *provider.ConfigureResponse,
) {
}

func (p *devProvider) Resources(_ context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewSucceedResource,
		NewFailResource,
		NewFailSometimesResource,
		NewDelayResource,
	}
}

func (p *devProvider) DataSources(_ context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		NewSucceedDataSource,
		NewFailDataSource,
		NewFailSometimesDataSource,
		NewDelayDataSource,
	}
}

func (p *devProvider) Functions(_ context.Context) []func() function.Function { return nil }

// newID returns a random hex string that can be used as a resource identifier
// when creating a new resource. It is not guaranteed to be unique, but the
// probability of collision is extremely low.
func newID() string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

// triggersAttribute returns an attribute that forces the resource to be
// replaced whenever its value changes.
func triggersAttribute() schema.MapAttribute {
	return schema.MapAttribute{
		Description:   "Arbitrary map of values; changing it forces the resource to be replaced.",
		ElementType:   types.StringType,
		Optional:      true,
		PlanModifiers: []planmodifier.Map{mapplanmodifier.RequiresReplace()},
	}
}
