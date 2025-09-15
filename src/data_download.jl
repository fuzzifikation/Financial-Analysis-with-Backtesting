"""
Data downloading and processing functions for financial analysis.
"""

using TimeSeries, Dates, MarketData, JLD2, CSV, DataFrames

"""
    download_financial_data(tickers::Vector{String}; asset_symbols=nothing)

Download financial data for given tickers from Yahoo Finance and other sources.
Returns a vector of TimeArrays with cleaned price data.
"""
function download_financial_data(tickers::Vector{String}; asset_symbols=nothing)
    prices_list = TimeArray[]
    
    for (i, tick) in enumerate(tickers)
        println("Downloading data for ticker: $tick")
        try
            ta = clean_prices(yahoo(tick))
            push!(prices_list, ta[:AdjClose])
        catch e
            @warn "Failed to download $tick: $e"
            continue
        end
    end
    
    return prices_list
end

"""
    clean_prices(prices::TimeArray)

Remove rows with missing values and ensure data quality.
"""
function clean_prices(prices::TimeArray)
    # Handle both :AdjClose and :Close columns
    price_col = :AdjClose in colnames(prices) ? :AdjClose : :Close
    
    idx = findall(.~isnothing.(prices[price_col] |> values) .& .~isnothing.(prices |> timestamp))
    clean_data = Float64.(prices[idx][price_col] |> values)
    ta = TimeArray(prices[idx] |> timestamp, clean_data, ["AdjClose"])
    
    return ta
end

"""
    merge_timearrays(tas::Vector{<:TimeArray}; names::Vector{Symbol}=Symbol[])

Merge multiple TimeArrays into a single TimeArray with proper column naming.
"""
function merge_timearrays(tas::Vector{<:TimeArray}; names::Vector{Symbol}=Symbol[])
    n = length(tas)
    @assert n > 0 "No TimeArrays provided"

    # Generate names if not provided
    if isempty(names)
        names = Symbol.(string.(1:n))
    else
        @assert length(names) == n "Length of names must match number of TimeArrays"
    end

    # Rename each TimeArray's first column
    tas_named = [TimeSeries.rename(ta, colnames(ta)[1] => names[i]) for (i, ta) in enumerate(tas)]

    # Merge with inner join
    return reduce((a, b) -> merge(a, b, :inner), tas_named)
end

"""
    irx_to_totalreturn(irx::TimeArray; dtm=91, expense=0.001)

Convert Treasury bill rates to total return series for money market simulation.
"""
function irx_to_totalreturn(irx::TimeArray; dtm::Int=91, expense::Float64=0.001)
    @assert :AdjClose in colnames(irx) "TimeArray must have :AdjClose column"

    # Convert BDY to MMY
    bdy_to_mmy(bdy::Float64, dtm::Int) = (360.0 * bdy) / (360.0 - bdy * dtm)

    # Extract BDY in decimal form
    bdy = values(irx[:AdjClose]) ./ 100.0
    mmy = bdy_to_mmy.(bdy, dtm)

    # Daily accrual net of expenses
    daily_r = (mmy .- expense) ./ 360.0

    # Compound returns
    nav = similar(daily_r)
    nav[1] = 1.0
    for i in 2:length(daily_r)
        nav[i] = nav[i-1] * (1 + daily_r[i])
    end

    return TimeArray(timestamp(irx), nav, ["AdjClose"])
end

"""
    load_saved_data(filename::String="data/data.jld2")

Load previously saved financial data from JLD2 file.
"""
function load_saved_data(filename::String="data/data.jld2")
    if isfile(filename)
        return load(filename)
    else
        error("Data file $filename not found. Run download_financial_data() first.")
    end
end

"""
    save_financial_data(data_dict::Dict, filename::String="data/data.jld2")

Save financial data to JLD2 file for fast loading.
"""
function save_financial_data(data_dict::Dict, filename::String="data/data.jld2")
    # Ensure data directory exists
    mkpath(dirname(filename))
    save(filename, data_dict)
    println("Data saved to $filename")
end