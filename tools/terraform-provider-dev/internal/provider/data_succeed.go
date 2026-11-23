package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ datasource.DataSource = (*succeedDataSource)(nil)

// succeedDataSource is a data source whose read always succeeds.
type succeedDataSource struct{}

type succeedDataModel struct {
	ID    types.String `tfsdk:"id"`
	Value types.String `tfsdk:"value"`
}

// NewSucceedDataSource returns the dev_succeed data source.
func NewSucceedDataSource() datasource.DataSource {
	return &succeedDataSource{}
}

func (d *succeedDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_succeed"
}

func (d *succeedDataSource) Schema(_ context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "A data source whose read always succeeds.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Description: "Randomly generated identifier.",
				Computed:    true,
			},
			"value": schema.StringAttribute{
				Description: "Arbitrary value, returned unchanged.",
				Optional:    true,
			},
		},
	}
}

func (d *succeedDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data succeedDataModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	data.ID = types.StringValue(newID())
	resp.Diagnostics.Append(resp.State.Set(ctx, data)...)
}
