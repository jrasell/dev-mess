package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ resource.Resource = (*succeedResource)(nil)

// succeedResource is a resource whose operations always succeed.
type succeedResource struct{}

type succeedModel struct {
	ID       types.String `tfsdk:"id"`
	Value    types.String `tfsdk:"value"`
	Triggers types.Map    `tfsdk:"triggers"`
}

// NewSucceedResource returns the dev_succeed resource.
func NewSucceedResource() resource.Resource {
	return &succeedResource{}
}

func (r *succeedResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_succeed"
}

func (r *succeedResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "A resource whose operations always succeed.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Description:   "Randomly generated identifier.",
				Computed:      true,
				PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()},
			},
			"value": schema.StringAttribute{
				Description: "Arbitrary value; changing it triggers an in-place update.",
				Optional:    true,
			},
			"triggers": triggersAttribute(),
		},
	}
}

func (r *succeedResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan succeedModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	plan.ID = types.StringValue(newID())
	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *succeedResource) Read(_ context.Context, _ resource.ReadRequest, _ *resource.ReadResponse) {
}

func (r *succeedResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan succeedModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *succeedResource) Delete(_ context.Context, _ resource.DeleteRequest, _ *resource.DeleteResponse) {
}
