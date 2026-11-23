package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework-validators/stringvalidator"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringdefault"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/schema/validator"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

const (
	opAll    = "all"
	opCreate = "create"
	opRead   = "read"
	opUpdate = "update"
	opDelete = "delete"
)

var _ resource.Resource = (*failResource)(nil)

// failResource is a resource that always fails on a configurable operation.
type failResource struct{}

type failModel struct {
	ID       types.String `tfsdk:"id"`
	Value    types.String `tfsdk:"value"`
	Triggers types.Map    `tfsdk:"triggers"`
	FailOn   types.String `tfsdk:"fail_on"`
	Message  types.String `tfsdk:"message"`
}

// NewFailResource returns the dev_fail resource.
func NewFailResource() resource.Resource {
	return &failResource{}
}

func (r *failResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_fail"
}

func (r *failResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "A resource that always fails on the configured operation.",
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
			"fail_on": schema.StringAttribute{
				Description: "Operation that fails: all, create, read, update or delete. Defaults to create.",
				Optional:    true,
				Computed:    true,
				Default:     stringdefault.StaticString(opCreate),
				Validators: []validator.String{
					stringvalidator.OneOf(opAll, opCreate, opRead, opUpdate, opDelete),
				},
			},
			"message": schema.StringAttribute{
				Description: "Error message returned on failure. Defaults to a generic message.",
				Optional:    true,
				Computed:    true,
				Default:     stringdefault.StaticString("deliberate failure from dev_fail"),
			},
		},
	}
}

func (r *failResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan failModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if shouldFail(plan.FailOn.ValueString(), opCreate) {
		resp.Diagnostics.AddError("dev_fail create failed", plan.Message.ValueString())
		return
	}

	plan.ID = types.StringValue(newID())
	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *failResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state failModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if shouldFail(state.FailOn.ValueString(), opRead) {
		resp.Diagnostics.AddError("dev_fail read failed", state.Message.ValueString())
	}
}

func (r *failResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan failModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if shouldFail(plan.FailOn.ValueString(), opUpdate) {
		resp.Diagnostics.AddError("dev_fail update failed", plan.Message.ValueString())
		return
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *failResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state failModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if shouldFail(state.FailOn.ValueString(), opDelete) {
		resp.Diagnostics.AddError("dev_fail delete failed", state.Message.ValueString())
	}
}

// shouldFail reports whether an operation should fail given the fail_on value.
func shouldFail(failOn, op string) bool {
	return failOn == opAll || failOn == op
}
