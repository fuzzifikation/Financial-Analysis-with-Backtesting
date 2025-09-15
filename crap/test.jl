### Portfolio optimisation: Markowitz mean–variance model


## Activation
#] activate --shared financial_analytics

using Pkg
Pkg.activate(joinpath(DEPOT_PATH[1], "environments", "financial_analytics"))

using DataFrames, Statistics, JuMP, HiGHS, LinearAlgebra
using Random
Random.seed!(42)  # reproducibility

## --- Step 1: Simulate some return data ---
n_assets = 4
n_periods = 100

# Simulated daily returns
returns = randn(n_periods, n_assets) .* 0.01 .+ 0.0005
μ = mean(returns, dims=1)[:]             # mean returns vector
Σ = cov(returns)                         # covariance matrix

println("Mean returns: ", round.(μ, digits=4))
println("Covariance matrix:\n", round.(Σ, digits=6))

## --- Step 2: Build the optimisation model ---
model = Model(HiGHS.Optimizer)

@variable(model, w[1:n_assets] >= 0)     # long-only weights
@constraint(model, sum(w) == 1)          # fully invested

# Risk aversion parameter (0 = max return, high values = low risk)
risk_aversion = 5.0

@objective(model, Max,
    dot(μ, w) - risk_aversion * dot(w, Σ * w)
)

set_time_limit_sec(model, 20)  # limit to 20 seconds

# Set the relative MIP gap tolerance to 1%
set_optimizer_attribute(model, "mip_rel_gap", 0.01)
# Turn on presolve
set_optimizer_attribute(model, "presolve", "on")
   # verbose output
## --- Step 3: Solve ---
optimize!(model)

# Print results
println("Optimization status: ", termination_status(model))
println("Objective value: ", objective_value(model))
println("Widgets to produce: ", value(widgets))
println("Gadgets to produce: ", value(gadgets))


##
w_opt = value.(w)
println("\nOptimal weights:")
for (i, wi) in enumerate(w_opt)
    println("Asset $i: ", round(wi*100, digits=2), "%")
end

# --- Step 4: Portfolio metrics ---
opt_return = dot(μ, w_opt)
opt_vol = sqrt(dot(w_opt, Σ * w_opt))

println("\nExpected return: ", round(opt_return*100, digits=3), "%")
println("Expected volatility: ", round(opt_vol*100, digits=3), "%")
