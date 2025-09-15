"""
# FinancialAnalysis.jl

A Julia package for financial analysis, portfolio optimization, and interactive visualization.

## Main Components
- Data downloading from Yahoo Finance and other sources
- Multi-asset correlation analysis and portfolio optimization
- Interactive dashboards with real-time weight adjustment
- Year-over-year return analysis and risk metrics

## Usage
```julia
using FinancialAnalysis

# Download data
tickers = ["^GSPC", "^125904-USD-STRD", "GC=F"]
prices = download_financial_data(tickers)

# Analyze correlations
corr_matrix = analyze_correlations(prices)

# Create interactive dashboard
dashboard = create_portfolio_dashboard(prices)
```
"""
module FinancialAnalysis

using TimeSeries, Dates, MarketData, JLD2, GLMakie, StatsBase, Statistics, LinearAlgebra, CSV, DataFrames

# Include submodules
include("data_download.jl")
include("analysis.jl") 
include("visualization.jl")
include("portfolio.jl")

# Export main functions
export 
    # Data functions
    download_financial_data, clean_prices, merge_timearrays, load_saved_data,
    
    # Analysis functions
    yoy_gain, normalize_prices, analyze_correlations, highly_correlated_pairs,
    
    # Visualization functions
    plot_prices, plot_histograms, create_dashboard,
    
    # Portfolio functions
    make_weight_sliders, portfolio_optimization

end # module FinancialAnalysis