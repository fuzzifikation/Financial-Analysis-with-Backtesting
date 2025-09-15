#module Dieters_PlottingHelpers

using TimeSeries, Dates, GLMakie, StatsBase, LinearAlgebra

#export plot_prices, plot_histograms



##
"""
    hists, fig = plot_histograms(ts; nbins=100, names=nothing, edges=nothing, fig=nothing, pos=(1,1))

Compute and plot histograms for each column in a TimeArray.
If `edges` is provided, all histograms will use the same bin edges.
If `fig` is provided, plot into that figure at grid position `pos`.
Returns the vector of normalized Histogram objects and the figure.
"""
function plot_histograms(ts::TimeArray;
    nbins::Int=100,
    names::Union{Nothing,Vector{String}}=nothing,
    edges::Union{Nothing,AbstractVector}=nothing,
    fig::Union{Nothing,Figure}=nothing,
    pos=(1, 1))

    labels = isnothing(names) ? string.(colnames(ts)) : names
    @assert length(labels) == size(ts, 2) "Number of labels must match number of columns"

    # If no edges given, compute them from the global min/max
    if edges === nothing
        global_min = minimum(values(ts))
        global_max = maximum(values(ts))
        edges = range(global_min, global_max; length=nbins + 1)
    end

    # Ensure edges is a plain vector
    edges_vec = collect(edges)

    # Compute histograms with same edges
    hists = [fit(Histogram, values(ts[col]), edges_vec) for col in colnames(ts)]
    hists = [normalize(h, mode=:probability) for h in hists]

    # Use existing figure or create new
    if fig === nothing
        fig = Figure()
    end

    ax = Axis(fig[pos...], xlabel="Value", ylabel="Probability")

    for (i, h) in enumerate(hists)
        e = h.edges[1]
        w = h.weights
        x = repeat(e, inner=[2])[2:end-1]
        y = repeat(w, inner=[2])
        lines!(ax, x, y; label=labels[i])
    end

    axislegend(ax; position=:rt)
    return hists, fig
end
##










function plot_prices(
    prices_list::Vector{<:TimeArray}; # accept any type of timearray
    names::Vector{String}=String[],
    column::Symbol=:AdjClose,
    figsize::Tuple{Int,Int}=(1000, 600)
)

    # Create a Dict from the list for easier handling
    prices_dict = Dict{String,TimeArray}()
    if length(names) == length(prices_list)
        for (i, name) in enumerate(names)
            prices_dict[name] = prices_list[i]
        end
    else
        for (i, ta) in enumerate(prices_list)
            prices_dict["Asset $i"] = ta
        end
    end

    return plot_prices(prices_dict; column=column, figsize=figsize
    )

end

##
function plot_prices(
    prices::TimeArray;
    names::Union{Nothing,Vector{String}}=nothing,
    figsize::Tuple{Int,Int}=(1000, 600)
)
    # 1. Determine legend labels
    labels = isnothing(names) ?
             string.(colnames(prices)) :  # convert Symbols to Strings
             names
    @assert length(labels) == size(prices, 2) "Number of labels must match number of columns"

    # 2. Create figure and axis
    fig = Figure(size=figsize)
    ax = Axis(fig[1, 1];
        xlabel="Date",
        ylabel="Value",
        title="Prices",
        xticklabelrotation=π / 4
    )

    # 3. Plot each column
    dates = timestamp(prices)
    for (i, col) in enumerate(colnames(prices))
        vals = values(prices[col])
        lines!(ax, dates, vals; linewidth=2, label=labels[i])
    end

    # 4. Add legend
    axislegend(ax; position=:lt)

    return fig
end




##
"""
    plot_prices(
    prices_dict::Dict{String,TimeArray};
    column::Symbol = :AdjClose,
    figsize::Tuple{Int,Int} = (1000, 600)
)

TBW
"""
function plot_prices(
    prices_dict::Dict{String,TimeArray};
    column::Symbol=:AdjClose,
    figsize::Tuple{Int,Int}=(1000, 600)
)

    # 1. Create figure and axis
    fig = Figure(size=figsize)
    ax = Axis(fig[1, 1];
        xlabel="Date",
        ylabel=string(column),
        title="Stock “$(column)” Prices",
        xticklabelrotation=π / 4
    )

    # 2. Plot each ticker
    for (i, (ticker, ta)) in enumerate(prices_dict)
        # Skip if requested column not present
        if !(column in ta |> colnames)
            @warn "Column $column not found for ticker $ticker; skipping"
            continue
        end

        dates = ta |> timestamp              # Vector{DateTime}
        vals = ta[column] |> values             # Vector{Float64}

        lines!(ax, dates, vals;
            label=ticker,
            linewidth=2
        )
    end

    # 3. Add a legend in the top‐right corner
    axislegend(ax;
        position=:lt,
        tellwidth=false,
        orientation=:vertical
    )

    return fig
end

#end # module Dieters_PlottingHelpers
#DataInspector()