package provider

import (
	"context"
	"fmt"
	"time"

	"github.com/hashicorp/terraform-plugin-framework/diag"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringdefault"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/schema/validator"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ resource.Resource = (*delayResource)(nil)

// delayResource is a resource whose operations succeed after a configurable
// delay, simulating slow network calls or long create times.
type delayResource struct{}

type delayModel struct {
	ID          types.String `tfsdk:"id"`
	Value       types.String `tfsdk:"value"`
	Triggers    types.Map    `tfsdk:"triggers"`
	CreateDelay types.String `tfsdk:"create_delay"`
	ReadDelay   types.String `tfsdk:"read_delay"`
	UpdateDelay types.String `tfsdk:"update_delay"`
	DeleteDelay types.String `tfsdk:"delete_delay"`
}

// NewDelayResource returns the dev_delay resource.
func NewDelayResource() resource.Resource {
	return &delayResource{}
}

func (r *delayResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_delay"
}

func (r *delayResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "A resource whose operations succeed after a configurable delay.",
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
			"triggers":     triggersAttribute(),
			"create_delay": delayAttribute("create"),
			"read_delay":   delayAttribute("read"),
			"update_delay": delayAttribute("update"),
			"delete_delay": delayAttribute("delete"),
		},
	}
}

func (r *delayResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan delayModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if !sleepFor(ctx, &resp.Diagnostics, opCreate, plan.CreateDelay.ValueString()) {
		return
	}

	plan.ID = types.StringValue(newID())
	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *delayResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state delayModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	sleepFor(ctx, &resp.Diagnostics, opRead, state.ReadDelay.ValueString())
}

func (r *delayResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan delayModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if !sleepFor(ctx, &resp.Diagnostics, opUpdate, plan.UpdateDelay.ValueString()) {
		return
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *delayResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state delayModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	sleepFor(ctx, &resp.Diagnostics, opDelete, state.DeleteDelay.ValueString())
}

func delayAttribute(op string) schema.StringAttribute {
	return schema.StringAttribute{
		Description: fmt.Sprintf("Duration the %s operation takes, such as \"500ms\" or \"1m30s\". Defaults to \"1s\".", op),
		Optional:    true,
		Computed:    true,
		Default:     stringdefault.StaticString("1s"),
		Validators:  []validator.String{durationValidator{}},
	}
}

// sleepFor blocks for the given duration, returning early with an error
// diagnostic if ctx is cancelled. It reports whether the full delay elapsed.
func sleepFor(ctx context.Context, diags *diag.Diagnostics, op, delay string) bool {
	d, err := time.ParseDuration(delay)
	if err != nil {
		diags.AddError("Invalid duration", fmt.Sprintf("%s delay %q: %s", op, delay, err))
		return false
	}

	t := time.NewTimer(d)
	defer t.Stop()

	select {
	case <-t.C:
		return true
	case <-ctx.Done():
		diags.AddError("dev_delay "+op+" interrupted", ctx.Err().Error())
		return false
	}
}

var _ validator.String = durationValidator{}

// durationValidator checks a string is a non-negative Go duration.
type durationValidator struct{}

func (durationValidator) Description(_ context.Context) string {
	return "value must be a non-negative duration such as \"500ms\" or \"1m30s\""
}

func (v durationValidator) MarkdownDescription(ctx context.Context) string {
	return v.Description(ctx)
}

func (durationValidator) ValidateString(_ context.Context, req validator.StringRequest, resp *validator.StringResponse) {
	if req.ConfigValue.IsNull() || req.ConfigValue.IsUnknown() {
		return
	}

	d, err := time.ParseDuration(req.ConfigValue.ValueString())
	if err != nil {
		resp.Diagnostics.AddAttributeError(req.Path, "Invalid duration", err.Error())
		return
	}
	if d < 0 {
		resp.Diagnostics.AddAttributeError(req.Path, "Invalid duration", "duration must not be negative")
	}
}
