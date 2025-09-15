#!/usr/bin/env julia

"""
Data Download Script

Downloads financial data from Yahoo Finance and saves it for analysis.
Run this script first to populate the data directory.

Usage:
    julia scripts/download_data.jl
"""

using Pkg
Pkg.activate(".")

# Load the main module
include("../src/FinancialAnalysis.jl")
using .FinancialAnalysis

# Asset configuration
tickers = [
    "^125904-USD-STRD",  # MSCI Europe (USD)
    "^GSPC",             # S&P 500 Index (USD)
    "^SP500TR",          # S&P 500 Total Return Index (USD)
    "^892400-USD-STRD",  # MSCI ACWI Index (USD)
    "^990100-USD-STRD",  # MSCI World Index (USD)
    "AGG",               # iShares Core U.S. Aggregate Bond ETF (USD)
    "EEM",               # iShares MSCI Emerging Markets ETF (USD)
    "BTC-USD"            # Bitcoin (USD)
]

asset_names = [
    "MSCI Europe",
    "S&P 500 Index", 
    "S&P 500 Total Return Index",
    "MSCI ACWI Index",
    "MSCI World Index",
    "iShares Aggregate Bond ETF",
    "iShares MSCI Emerging Markets ETF", 
    "Bitcoin"
]

asset_symbols = [
    :Europe, :SP500, :SP500TR, :ACWI, :World, :Bond_ETF, :EM_ETF, :Bitcoin
]

function main()
    println("🔄 Starting financial data download...")
    
    # Download main tickers
    prices_list = download_financial_data(tickers)
    
    # Add money market data from Treasury bills
    println("📊 Processing Treasury bill data for money market simulation...")
    try
        irx = clean_prices(yahoo("^IRX"))
        ret_irx = irx_to_totalreturn(irx[:AdjClose]; dtm=91, expense=0.001)
        push!(prices_list, ret_irx)
        push!(asset_names, "Money Market Fund from ^IRX")
        push!(asset_symbols, :MoneyMarket)
    catch e
        @warn "Failed to process IRX data: $e"
    end
    
    # Add gold data from CSV if available
    gold_file = "data/Gold_finanzen_net.csv"
    if isfile(gold_file)
        println("📈 Loading gold price data from CSV...")
        try
            gold_prices = clean_prices(readtimearray(gold_file, format="dd.mm.yyyy", delim=','))
            push!(prices_list, gold_prices)
            push!(asset_names, "Gold")
            push!(asset_symbols, :Gold)
        catch e
            @warn "Failed to load gold data: $e"
        end
    end
    
    # Create asset dictionary for quick lookups
    asset_dict = Dict{Symbol,Int}()
    for (i, symbol) in enumerate(asset_symbols)
        asset_dict[symbol] = i
    end
    
    # Save all data
    data_dict = Dict(
        "prices_list" => prices_list,
        "tickers" => tickers,
        "asset_names" => asset_names,
        "asset_symbols" => asset_symbols,
        "asset_dict" => asset_dict
    )
    
    save_financial_data(data_dict, "data/data.jld2")
    
    println("✅ Data download completed successfully!")
    println("📁 Saved $(length(prices_list)) assets to data/data.jld2")
    println("🎯 Available assets: $(join(asset_symbols, ", "))")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end