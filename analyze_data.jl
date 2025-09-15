## analyze data
## Activation
#] activate --shared financial_analytics

# using Pkg
# Pkg.activate(joinpath(DEPOT_PATH[1], "environments", "financial_analytics"))
include("setup_financial.jl")


merged_prices = merge_timearrays(prices_list; names=asset_symbols)
yoy = yoy_gain(merged_prices)

## Cross Correlation
vals = values(yoy)
corrmat = cor(vals, dims=1)

function highly_correlated_pairs(corrmat, names; threshold=0.9)
    n = length(names)
    pairs = []
    for i in 1:n-1, j in i+1:n
        if abs(corrmat[i, j]) ≥ threshold
            push!(pairs, (names[i], names[j], corrmat[i, j]))
        end
    end
    return pairs
end

pairs = highly_correlated_pairs(corrmat, colnames(yoy), threshold=0.8)
#println("Highly correlated pairs:")
#println(pairs)


# Conclusion: ACWI, World, SP500, EM_ETF, Europe are all highly correlated (>0.8)
# This leaves as investigation: SP500, Bond_ETF, MoneyMarket, Gold

## First, investigate the correlated stuff
correlated_sym = [:ACWI, :World, :SP500TR, :SP500, :EM_ETF, :Europe]
prices_corr = merge_timearrays(prices_list[asset2idx(correlated_sym)], names=correlated_sym)
yoy_corr = yoy_gain(prices_corr)

# now lets make some plots
plot_prices(yoy_corr)
#hists, fig = plot_histograms(yoy_corr; nbins=50)


## Now for the fun part, the uncorrelated stuff
uncorrelated_sym = [:SP500TR, :Bond_ETF, :MoneyMarket, :Gold] #, :Bitcoin]
prices_uncorr = normalize_prices(merge_timearrays(prices_list[asset2idx(uncorrelated_sym)], names=uncorrelated_sym), Date(2000,1,1))
yoy_uncorr = yoy_gain(prices_uncorr)

plot_prices(yoy_uncorr )


## histograms
rets = collect(Float64,0.5:0.01:2)
hists, fig = plot_histograms(yoy_uncorr; nbins=50, edges=rets)
display(fig)



##
#=


## Histogram Plot of a single TimeSeries
hists = [fit(Histogram, yearly_gain[:YearlyGain] |> values , nbins= 100) for yearly_gain in yearly_gains]
hists = [normalize(hist, mode=:probability) for hist in hists]
##
fig = Figure()
ax = Axis(fig[1, 1], xlabel="Value", ylabel="Density")

for h in hists
    edges = h.edges[1]
    weights = h.weights

    # Build step coordinates: repeat each edge twice, and each weight twice
    x = repeat(edges, inner=[2])[2:end-1]  # drop first and last duplicate
    y = repeat(weights, inner=[2])

    lines!(ax, x, y)  # step-style line
end

fig
=#