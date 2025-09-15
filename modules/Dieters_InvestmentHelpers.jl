#module Dieters_InvestmentHelpers
using TimeSeries, Dates, CSV, DataFrames

#export clean_prices, yoy_gain, normalize_prices, irx_to_totalreturn, merge_timearrays


# Map asset symbols to their indices
function asset2idx(symbols::Vector{Symbol})
    return [asset_dict[sym] for sym in symbols]
end


"""
    merge_timearrays(tas::Vector{TimeArray}; names::Vector{Symbol}=Symbol[])

Merge a vector of TimeArrays into one TimeArray.

- If `names` is provided, each TimeArray's first column is renamed to the corresponding symbol.
- If `names` is omitted or empty, columns are named :1, :2, ..., :n.
- Performs an inner join on timestamps (only dates present in all series are kept).
"""
function merge_timearrays(tas::Vector{<:TimeArray}; names::Vector{Symbol}=Symbol[])
    n = length(tas)
    @assert n > 0 "No TimeArrays provided"

    # If no names given, generate :1, :2, ..., :n
    if isempty(names)
        names = Symbol.(string.(1:n))
    else
        @assert length(names) == n "Length of names must match number of TimeArrays"
    end

    # Rename each TimeArray's first column
    tas_named = [TimeSeries.rename(ta, colnames(ta)[1] => names[i]) for (i, ta) in enumerate(tas)]

    # Merge them all with inner join
    reduce((a, b) -> merge(a, b, :inner), tas_named)
end



##
"""
    irx_to_totalreturn(irx::TimeArray; dtm=91, expense=0.001)

Given a TimeArray `irx` with a column :AdjClose containing ^IRX BDY values in percent,
compute the total return series for a USD 1 initial investment, net of `expense`
(annual, decimal). Returns a TimeArray with identical timestamps and a "TotalReturn" column.
"""
function irx_to_totalreturn(irx::TimeArray; dtm::Int=91, expense::Float64=0.001)
    @assert :AdjClose in colnames(irx) "TimeArray must have :AdjClose column"

    # Local helper: BDY (decimal) → MMY (decimal)
    bdy_to_mmy_local(bdy::Float64, dtm::Int) =
        (360.0 * bdy) / (360.0 - bdy * dtm)

    # Extract BDY in decimal form
    bdy = values(irx[:AdjClose]) ./ 100.0

    # Convert to MMY (investment yield, decimal)
    mmy = bdy_to_mmy_local.(bdy, dtm)

    # Daily accrual on 360-day basis, net of expense
    daily_r = (mmy .- expense) ./ 360.0

    # Compound into NAV starting at 1.0
    nav = similar(daily_r)
    nav[1] = 1.0
    for i in 2:length(daily_r)
        nav[i] = nav[i-1] * (1 + daily_r[i])
    end

    # Return as TimeArray
    return TimeArray(timestamp(irx), nav, ["AdjClose"])
end



## Normalizes Prices in a list of prices
function normalize_prices(prices_list, target_date::Date)
    # make a copy
    normalized_prices = prices_list
    for (i, prices) in enumerate(prices_list)
        normalized_prices[i] = normalize_prices(prices, target_date)
    end

    return normalized_prices
end

## Normalize Prices to 1.0 at specific Date
"""
    normalize_prices(prices::TimeArray, date::Date)

Normalize all columns in a TimeArray so that the value at `date`
(or the next available date) is 1.0.
"""
function normalize_prices(prices::TimeArray, date::Date)
    # Find the row on or after the given date
    row_on_date = next_or_equal(prices, date)
    if isempty(row_on_date)
        error("No price data available on or after the specified date: $date")
    end

    # Extract the normalization factors for each column
    factors = values(row_on_date)  # 1×N Matrix

    # Normalize all columns
    normalized_vals = values(prices) ./ factors

    # Return new TimeArray with same timestamps and column names
    return TimeArray(timestamp(prices), normalized_vals, colnames(prices))
end

## Clean the price data by removing rows with missing values
function clean_prices(prices::TimeArray)
    idx = findall(.~isnothing.(prices[:AdjClose] |> values) .& .~isnothing.(prices |> timestamp))
    clean_data = Float64.(prices[idx][:AdjClose] |> values)
	ta = TimeArray(prices[idx] |> timestamp, clean_data, ["AdjClose"])

	# Remove rows with missing values
	return ta
end

## Find the gains of each day and one year later until we end
"""
    yoy_gain(prices::TimeArray) -> TimeArray

For each date in `prices`, compute the gain after one year for each column.
Keeps the original column names.
"""
function yoy_gain(prices::TimeArray)
    ts = timestamp(prices)
    nrows, ncols = size(prices)

    dates = eltype(ts)[]                  # preserve Date or DateTime
    gains_list = Vector{Vector{Float64}}()

    for i in 1:nrows
        start_date = ts[i]
        target_date = start_date + Year(1)

        row_later = next_or_equal(prices, target_date)
        if row_later === nothing
            break  # stop when no date ≥ target_date exists
        end

        start_prices = vec(values(prices[i]))      # 1×N -> Vector
        end_prices = vec(values(row_later))      # 1×N -> Vector

        push!(dates, start_date)
        push!(gains_list, end_prices ./ start_prices)
    end

    # Convert list of vectors to matrix
    gains_matrix = reduce(vcat, (permutedims(g) for g in gains_list))

    return TimeArray(dates, gains_matrix, colnames(prices))
end

## function to fetch the row at or after a date
function next_or_equal(ta::TimeArray, d::Date)
    idx = searchsortedfirst(ta|>timestamp, d)
    if idx > length(ta)
        return nothing
    end
    return ta[idx]
end


#end # module Dieters_InvestmentHelpers	