#!/usr/bin/env julia

"""
Interactive Dashboard

Launches an interactive portfolio optimization dashboard with real-time
weight adjustment and visualization.

Usage:
    julia scripts/dashboard.jl
"""

using Pkg
Pkg.activate(".")

# Load the main module
include("../src/FinancialAnalysis.jl")
using .FinancialAnalysis

function main()
    println("🎛️  Starting Interactive Financial Dashboard...")
    
    # Load data
    println("📂 Loading data...")
    data = load_saved_data("data/data.jld2")
    prices_list = data["prices_list"]
    asset_symbols = data["asset_symbols"]
    asset_dict = data["asset_dict"]
    
    # Focus on uncorrelated assets for portfolio optimization
    uncorrelated_syms = [:SP500TR, :Bond_ETF, :MoneyMarket, :Gold]
    available_uncorr = filter(s -> s in asset_symbols, uncorrelated_syms)
    
    if isempty(available_uncorr)
        println("❌ No uncorrelated assets found. Using all available assets.")
        available_uncorr = asset_symbols[1:min(4, length(asset_symbols))]
    end
    
    println("🎯 Dashboard assets: $(join(available_uncorr, ", "))")
    
    # Prepare data
    uncorr_indices = [asset_dict[sym] for sym in available_uncorr if haskey(asset_dict, sym)]
    prices_uncorr = merge_timearrays(prices_list[uncorr_indices], names=available_uncorr)
    
    # Normalize to reasonable start date
    start_date = Date(2000, 1, 1)
    try
        prices_uncorr = normalize_prices(prices_uncorr, start_date)
        println("📊 Normalized prices to $start_date")
    catch e
        @warn "Could not normalize to $start_date, using raw prices: $e"
    end
    
    # Create and display dashboard
    println("🚀 Launching interactive dashboard...")
    println("💡 Use the sliders to adjust portfolio weights")
    println("📈 Top plot shows normalized prices and portfolio performance")
    println("📊 Bottom plot shows year-over-year return distribution")
    println("🔄 Time slider adjusts the analysis window")
    
    try
        dashboard_fig = create_dashboard(prices_uncorr)
        display(dashboard_fig)
        
        println("\n✅ Dashboard launched successfully!")
        println("💡 Interact with the controls to explore different portfolio allocations")
        println("🔗 The portfolio (red line) updates in real-time as you adjust weights")
        
        # Keep the script running
        println("\n⏸️  Press Ctrl+C to exit...")
        try
            while true
                sleep(1)
            end
        catch InterruptException
            println("\n👋 Dashboard closed.")
        end
        
    catch e
        println("❌ Failed to create dashboard: $e")
        println("💡 Make sure you have GLMakie properly configured")
        println("🔧 Try running: using GLMakie; GLMakie.activate!()")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end