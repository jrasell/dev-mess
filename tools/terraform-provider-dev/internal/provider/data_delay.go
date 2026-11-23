package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/schema/validator"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ datasource.DataSource = (*delayDataSource)(nil)

// delayDataSource is a data source whose read succeeds after a configurable
// delay, simulating a slow network call.
type delayDataSource struct{}

type delayDataModel struct {
	ID        types.String `tfsdk:"id"`
	Value     types.String `tfsdk:"value"`
	ReadDelay types.String `tfsdk:"read_delay"`
}

// NewDelayDataSource returns the dev_delay data source.
func NewDelayDataSource() datasource.DataSource {
	return &delayDataSource{}
}

func (d *delayDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_delay"
}

func (d *delayDataSource) Schema(_ context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "A data source whose read succeeds after a configurable delay.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Description: "Randomly generated identifier.",
				Computed:    true,
			},
			"value": schema.StringAttribute{
				Description: "Arbitrary value, returned unchanged.",
				Optional:    true,
			},
			"read_delay": schema.StringAttribute{
				Description: "Duration the read operation takes, such as \"500ms\" or \"1m30s\". Defaults to \"1s\".",
				Optional:    true,
				Computed:    true,
				Validators:  []validator.String{durationValidator{}},
			},
		},
	}
}

func (d *delayDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data delayDataModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if data.ReadDelay.IsNull() {
		data.ReadDelay = types.StringValue("1s")
	}

	if !sleepFor(ctx, &resp.Diagnostics, opRead, data.ReadDelay.ValueString()) {
		return
	}

	data.ID = types.StringValue(newID())
	resp.Diagnostics.Append(resp.State.Set(ctx, data)...)
}
