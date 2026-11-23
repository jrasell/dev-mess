package provider

import (
	"context"
	"math/rand/v2"

	"github.com/hashicorp/terraform-plugin-framework-validators/float64validator"
	"github.com/hashicorp/terraform-plugin-framework/diag"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/float64default"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/schema/validator"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ resource.Resource = (*failSometimesResource)(nil)

// failSometimesResource is a resource whose create, read, update and delete
// operations each fail randomly, based on a configurable failure rate.
type failSometimesResource struct{}

type failSometimesModel struct {
	ID          types.String  `tfsdk:"id"`
	Value       types.String  `tfsdk:"value"`
	Triggers    types.Map     `tfsdk:"triggers"`
	FailureRate types.Float64 `tfsdk:"failure_rate"`
}

// NewFailSometimesResource returns the dev_fail_sometimes resource.
func NewFailSometimesResource() resource.Resource {
	return &failSometimesResource{}
}

func (r *failSometimesResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_fail_sometimes"
}

func (r *failSometimesResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "A resource whose operations randomly fail.",
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
			"failure_rate": schema.Float64Attribute{
				Description: "Probability, between 0 and 1, that any single operation fails. Defaults to 0.5.",
				Optional:    true,
				Computed:    true,
				Default:     float64default.StaticFloat64(0.5),
				Validators: []validator.Float64{
					float64validator.Between(0, 1),
				},
			},
		},
	}
}

func (r *failSometimesResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan failSometimesModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if maybeFail(&resp.Diagnostics, opCreate, plan.FailureRate.ValueFloat64()) {
		return
	}

	plan.ID = types.StringValue(newID())
	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *failSometimesResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state failSometimesModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	maybeFail(&resp.Diagnostics, opRead, state.FailureRate.ValueFloat64())
}

func (r *failSometimesResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan failSometimesModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if maybeFail(&resp.Diagnostics, opUpdate, plan.FailureRate.ValueFloat64()) {
		return
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *failSometimesResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state failSometimesModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	maybeFail(&resp.Diagnostics, opDelete, state.FailureRate.ValueFloat64())
}

// maybeFail adds an error diagnostic with probability rate and reports whether
// it did so.
func maybeFail(diags *diag.Diagnostics, op string, rate float64) bool {
	if rand.Float64() >= rate {
		return false
	}

	diags.AddError("dev_fail_sometimes "+op+" failed", "random failure triggered by failure_rate")
	return true
}
