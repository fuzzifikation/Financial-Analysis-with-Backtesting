#!/usr/bin/env julia

"""
Analysis Script

Runs the complete financial analysis pipeline including correlation analysis,
portfolio grouping, and statistical analysis.

Usage:
    julia scripts/run_analysis.jl
"""

using Pkg
Pkg.activate(".")

# Load the main module
include("../src/FinancialAnalysis.jl")
using .FinancialAnalysis

function main()
    println("📊 Starting Financial Analysis...")
    
    # Load data
    println("📂 Loading saved data...")
    data = load_saved_data("data/data.jld2")
    prices_list = data["prices_list"]
    asset_symbols = data["asset_symbols"]
    asset_dict = data["asset_dict"]
    
    # Merge all prices into single TimeArray
    println("🔗 Merging price data...")
    merged_prices = merge_timearrays(prices_list; names=asset_symbols)
    yoy = yoy_gain(merged_prices)
    
    # Correlation analysis
    println("📈 Analyzing correlations...")
    corrmat = analyze_correlations(merged_prices)
    
    # Find highly correlated pairs
    pairs = highly_correlated_pairs(corrmat, colnames(yoy), threshold=0.8)
    
    println("\n🎯 Correlation Analysis Results:")
    println("=" ^ 50)
    
    if !isempty(pairs)
        println("📊 Highly correlated pairs (>0.8):")
        for (asset1, asset2, corr) in pairs
            println("  • $asset1 ↔ $asset2: $(round(corr, digits=3))")
        end
    else
        println("📊 No highly correlated pairs found (threshold=0.8)")
    end
    
    # Group assets by correlation
    correlated_syms = [:ACWI, :World, :SP500TR, :SP500, :EM_ETF, :Europe]
    uncorrelated_syms = [:SP500TR, :Bond_ETF, :MoneyMarket, :Gold]
    
    # Filter symbols that actually exist in our data
    available_corr = filter(s -> s in asset_symbols, correlated_syms)
    available_uncorr = filter(s -> s in asset_symbols, uncorrelated_syms)
    
    if !isempty(available_corr)
        println("\n📊 Analyzing correlated assets: $(join(available_corr, ", "))")
        corr_indices = [asset_dict[sym] for sym in available_corr if haskey(asset_dict, sym)]
        if !isempty(corr_indices)
            prices_corr = merge_timearrays(prices_list[corr_indices], names=available_corr)
            yoy_corr = yoy_gain(prices_corr)
            
            println("  • Mean YoY returns: $(round.(mean(values(yoy_corr), dims=1), digits=3))")
            println("  • Std YoY returns: $(round.(std(values(yoy_corr), dims=1), digits=3))")
        end
    end
    
    if !isempty(available_uncorr)
        println("\n📊 Analyzing uncorrelated assets: $(join(available_uncorr, ", "))")
        uncorr_indices = [asset_dict[sym] for sym in available_uncorr if haskey(asset_dict, sym)]
        if !isempty(uncorr_indices)
            prices_uncorr = merge_timearrays(prices_list[uncorr_indices], names=available_uncorr)
            
            # Normalize to start of 2000 if data available
            try
                prices_uncorr_norm = normalize_prices(prices_uncorr, Date(2000,1,1))
                yoy_uncorr = yoy_gain(prices_uncorr_norm)
                
                println("  • Mean YoY returns: $(round.(mean(values(yoy_uncorr), dims=1), digits=3))")
                println("  • Std YoY returns: $(round.(std(values(yoy_uncorr), dims=1), digits=3))")
                
                # Calculate some portfolio metrics
                returns_matrix = values(yoy_uncorr)
                equal_weights = portfolio_optimization(returns_matrix, :equal_weight)
                
                println("\n💼 Equal Weight Portfolio:")
                for (i, sym) in enumerate(available_uncorr)
                    println("  • $sym: $(round(equal_weights[i]*100, digits=1))%")
                end
                
            catch e
                @warn "Could not normalize to 2000-01-01, using raw data: $e"
                yoy_uncorr = yoy_gain(prices_uncorr)
            end
        end
    end
    
    println("\n✅ Analysis completed successfully!")
    println("💡 Run 'julia scripts/dashboard.jl' for interactive visualization")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end