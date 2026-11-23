package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ datasource.DataSource = (*failDataSource)(nil)

// failDataSource is a data source whose read always fails.
type failDataSource struct{}

type failDataModel struct {
	ID      types.String `tfsdk:"id"`
	Message types.String `tfsdk:"message"`
}

// NewFailDataSource returns the dev_fail data source.
func NewFailDataSource() datasource.DataSource {
	return &failDataSource{}
}

func (d *failDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_fail"
}

func (d *failDataSource) Schema(_ context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "A data source whose read always fails.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Description: "Never set, as the read always fails.",
				Computed:    true,
			},
			"message": schema.StringAttribute{
				Description: "Error message returned on failure. Defaults to a generic message.",
				Optional:    true,
			},
		},
	}
}

func (d *failDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data failDataModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	msg := "deliberate failure from dev_fail"
	if !data.Message.IsNull() {
		msg = data.Message.ValueString()
	}

	resp.Diagnostics.AddError("dev_fail read failed", msg)
}
