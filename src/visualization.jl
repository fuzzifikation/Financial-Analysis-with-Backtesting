"""
Visualization functions for financial data using GLMakie.
"""

using GLMakie, TimeSeries, StatsBase

"""
    plot_prices(prices::TimeArray; names=nothing, figsize=(1000, 600))

Create a line plot of price data over time.
"""
function plot_prices(prices::TimeArray; names::Union{Nothing,Vector{String}}=nothing, figsize::Tuple{Int,Int}=(1000, 600))
    labels = isnothing(names) ? string.(colnames(prices)) : names
    @assert length(labels) == size(prices, 2) "Number of labels must match number of columns"

    fig = Figure(size=figsize)
    ax = Axis(fig[1, 1];
        xlabel="Date",
        ylabel="Value", 
        title="Price Evolution",
        xticklabelrotation=π / 4
    )

    dates = timestamp(prices)
    for (i, col) in enumerate(colnames(prices))
        vals = values(prices[col])
        lines!(ax, dates, vals; linewidth=2, label=labels[i])
    end

    axislegend(ax; position=:lt)
    return fig
end

"""
    plot_prices(prices_dict::Dict{String,TimeArray}; column=:AdjClose, figsize=(1000, 600))

Plot multiple price series from a dictionary.
"""
function plot_prices(prices_dict::Dict{String,TimeArray}; column::Symbol=:AdjClose, figsize::Tuple{Int,Int}=(1000, 600))
    fig = Figure(size=figsize)
    ax = Axis(fig[1, 1];
        xlabel="Date",
        ylabel=string(column),
        title="Price Comparison",
        xticklabelrotation=π / 4
    )

    for (ticker, ta) in prices_dict
        if !(column in colnames(ta))
            @warn "Column $column not found for ticker $ticker; skipping"
            continue
        end

        dates = timestamp(ta)
        vals = values(ta[column])
        lines!(ax, dates, vals; label=ticker, linewidth=2)
    end

    axislegend(ax; position=:lt)
    return fig
end

"""
    plot_prices(prices_list::Vector{<:TimeArray}; names=String[], column=:AdjClose, figsize=(1000, 600))

Plot multiple price series from a vector.
"""
function plot_prices(prices_list::Vector{<:TimeArray}; names::Vector{String}=String[], column::Symbol=:AdjClose, figsize::Tuple{Int,Int}=(1000, 600))
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

    return plot_prices(prices_dict; column=column, figsize=figsize)
end

"""
    plot_histograms(ts::TimeArray; nbins=100, names=nothing, edges=nothing, fig=nothing, pos=(1,1))

Create histograms for each column in a TimeArray.
"""
function plot_histograms(ts::TimeArray; 
    nbins::Int=100,
    names::Union{Nothing,Vector{String}}=nothing,
    edges::Union{Nothing,AbstractVector}=nothing,
    fig::Union{Nothing,Figure}=nothing,
    pos=(1, 1))

    labels = isnothing(names) ? string.(colnames(ts)) : names
    @assert length(labels) == size(ts, 2) "Number of labels must match number of columns"

    if edges === nothing
        global_min = minimum(values(ts))
        global_max = maximum(values(ts))
        edges = range(global_min, global_max; length=nbins + 1)
    end

    edges_vec = collect(edges)

    # Compute normalized histograms
    hists = [fit(Histogram, values(ts[col]), edges_vec) for col in colnames(ts)]
    hists = [normalize(h, mode=:probability) for h in hists]

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