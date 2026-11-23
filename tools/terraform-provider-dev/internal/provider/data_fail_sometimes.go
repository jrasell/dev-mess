package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework-validators/float64validator"
	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/schema/validator"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ datasource.DataSource = (*failSometimesDataSource)(nil)

// failSometimesDataSource is a data source whose read randomly fails.
type failSometimesDataSource struct{}

type failSometimesDataModel struct {
	ID          types.String  `tfsdk:"id"`
	Value       types.String  `tfsdk:"value"`
	FailureRate types.Float64 `tfsdk:"failure_rate"`
}

// NewFailSometimesDataSource returns the dev_fail_sometimes data source.
func NewFailSometimesDataSource() datasource.DataSource {
	return &failSometimesDataSource{}
}

func (d *failSometimesDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_fail_sometimes"
}

func (d *failSometimesDataSource) Schema(_ context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "A data source whose read randomly fails.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Description: "Randomly generated identifier.",
				Computed:    true,
			},
			"value": schema.StringAttribute{
				Description: "Arbitrary value, returned unchanged.",
				Optional:    true,
			},
			"failure_rate": schema.Float64Attribute{
				Description: "Probability, between 0 and 1, that the read fails. Defaults to 0.5.",
				Optional:    true,
				Computed:    true,
				Validators: []validator.Float64{
					float64validator.Between(0, 1),
				},
			},
		},
	}
}

func (d *failSometimesDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data failSometimesDataModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if data.FailureRate.IsNull() {
		data.FailureRate = types.Float64Value(0.5)
	}

	if maybeFail(&resp.Diagnostics, opRead, data.FailureRate.ValueFloat64()) {
		return
	}

	data.ID = types.StringValue(newID())
	resp.Diagnostics.Append(resp.State.Set(ctx, data)...)
}
