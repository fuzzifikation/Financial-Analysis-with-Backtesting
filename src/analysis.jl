"""
Core analysis functions for financial data.
"""

using TimeSeries, Dates, Statistics, LinearAlgebra

"""
    yoy_gain(prices::TimeArray) -> TimeArray

Calculate year-over-year gains for each asset in the TimeArray.
"""
function yoy_gain(prices::TimeArray)
    ts = timestamp(prices)
    nrows, ncols = size(prices)

    dates = eltype(ts)[]
    gains_list = Vector{Vector{Float64}}()

    for i in 1:nrows
        start_date = ts[i]
        target_date = start_date + Year(1)

        row_later = next_or_equal(prices, target_date)
        if row_later === nothing
            break
        end

        start_prices = vec(values(prices[i]))
        end_prices = vec(values(row_later))

        push!(dates, start_date)
        push!(gains_list, end_prices ./ start_prices)
    end

    gains_matrix = reduce(vcat, (permutedims(g) for g in gains_list))
    return TimeArray(dates, gains_matrix, colnames(prices))
end

"""
    normalize_prices(prices::TimeArray, date::Date)

Normalize all columns so that values at the specified date equal 1.0.
"""
function normalize_prices(prices::TimeArray, date::Date)
    row_on_date = next_or_equal(prices, date)
    if isempty(row_on_date)
        error("No price data available on or after the specified date: $date")
    end

    factors = values(row_on_date)
    normalized_vals = values(prices) ./ factors

    return TimeArray(timestamp(prices), normalized_vals, colnames(prices))
end

"""
    normalize_prices(prices_list::Vector{TimeArray}, date::Date)

Normalize a list of TimeArrays to the specified date.
"""
function normalize_prices(prices_list::Vector{TimeArray}, date::Date)
    return [normalize_prices(prices, date) for prices in prices_list]
end

"""
    analyze_correlations(prices::TimeArray)

Calculate correlation matrix for the given price data.
"""
function analyze_correlations(prices::TimeArray)
    yoy = yoy_gain(prices)
    vals = values(yoy)
    return cor(vals, dims=1)
end

"""
    highly_correlated_pairs(corrmat::Matrix, names::Vector; threshold=0.9)

Find pairs of assets with correlation above the threshold.
"""
function highly_correlated_pairs(corrmat::Matrix, names::Vector; threshold=0.9)
    n = length(names)
    pairs = []
    
    for i in 1:n-1, j in i+1:n
        if abs(corrmat[i, j]) ≥ threshold
            push!(pairs, (names[i], names[j], corrmat[i, j]))
        end
    end
    
    return pairs
end

"""
    next_or_equal(ta::TimeArray, d::Date)

Find the row in TimeArray at or after the specified date.
"""
function next_or_equal(ta::TimeArray, d::Date)
    idx = searchsortedfirst(timestamp(ta), d)
    if idx > length(ta)
        return nothing
    end
    return ta[idx]
end

"""
    asset2idx(symbols::Vector{Symbol}, asset_dict::Dict{Symbol,Int})

Map asset symbols to their indices in the data structure.
"""
function asset2idx(symbols::Vector{Symbol}, asset_dict::Dict{Symbol,Int})
    return [asset_dict[sym] for sym in symbols]
end