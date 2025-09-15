# Financial Analysis Project

A Julia-based financial analysis toolkit for downloading, analyzing, and visualizing financial data.

## Features

- **Data Download**: Automated downloading of financial data from Yahoo Finance
- **Multi-Asset Analysis**: Support for stocks, indices, ETFs, commodities, and bonds
- **Portfolio Optimization**: Tools for portfolio analysis and optimization
- **Visualization**: Comprehensive plotting capabilities for financial data

## Project Structure

```
├── analyze_data.jl          # Main analysis script
├── download_data.jl         # Data downloading utilities
├── fullplot.jl             # Plotting and visualization functions
├── data/                   # Downloaded financial data
│   └── data.jld2          # Processed time series data
├── modules/               # Custom Julia modules
│   ├── Dieters_InvestmentHelpers.jl   # Investment calculation helpers
│   └── Dieters_PlottingHelpers.jl     # Plotting utilities
└── crap/                  # Experimental/deprecated code
```

## Dependencies

- TimeSeries.jl - Time series data handling
- MarketData.jl - Financial data downloading
- GLMakie.jl - High-performance plotting
- JLD2.jl - Data serialization
- DataFrames.jl - Data manipulation
- Statistics.jl - Statistical functions

## Usage

1. **Download Data**: Run `download_data.jl` to fetch latest financial data
2. **Analyze**: Use `analyze_data.jl` for portfolio analysis and calculations
3. **Visualize**: Execute `fullplot.jl` for generating charts and plots

## Assets Tracked

- MSCI Europe (^125904-USD-STRD)
- S&P 500 Index (^GSPC)
- Gold Futures (GC=F)
- MSCI ACWI Index (^892400-USD-STRD)
- MSCI World Index (^990100-USD-STRD)
- iShares Long-Term Corporate Bond ETF (IGLB)
- 13 Week Treasury Bill (^IRX)
- iShares MSCI Emerging Markets ETF (EEM)

## Getting Started

```julia
# Install required packages
using Pkg
Pkg.add(["TimeSeries", "MarketData", "GLMakie", "JLD2", "DataFrames"])

# Include modules
include("modules/Dieters_InvestmentHelpers.jl")
include("modules/Dieters_PlottingHelpers.jl")

# Download data
include("download_data.jl")

# Run analysis
include("analyze_data.jl")
```
