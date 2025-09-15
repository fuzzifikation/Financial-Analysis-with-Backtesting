# Financial Analysis with Backtesting

A professional Julia toolkit for financial analysis, portfolio optimization, and interactive visualization with real-time backtesting capabilities.

## ✨ Features

- **📈 Multi-Asset Data Pipeline**: Automated downloading from Yahoo Finance, Treasury bills, and custom data sources
- **🔗 Correlation Analysis**: Advanced correlation clustering for portfolio diversification
- **⚖️ Portfolio Optimization**: Interactive weight adjustment with real-time constraint satisfaction
- **📊 Interactive Dashboards**: Dynamic visualization with synchronized plots and controls
- **📉 Risk Analytics**: Year-over-year returns, volatility analysis, and distribution modeling
- **🎛️ Real-time Backtesting**: Live portfolio performance simulation with adjustable time windows

## 🏗️ Project Structure

```
├── src/                          # Core library modules
│   ├── FinancialAnalysis.jl     # Main module and exports
│   ├── data_download.jl         # Data acquisition and processing
│   ├── analysis.jl              # Financial analysis functions
│   ├── visualization.jl         # Plotting and charts
│   └── portfolio.jl             # Portfolio optimization and dashboards
├── scripts/                      # Executable scripts
│   ├── download_data.jl         # Data download pipeline
│   ├── run_analysis.jl          # Complete analysis workflow
│   └── dashboard.jl             # Interactive dashboard launcher
├── data/                         # Financial data storage
│   ├── data.jld2               # Processed time series (binary)
│   └── *.csv                   # Raw data files
├── test/                         # Unit tests
│   └── runtests.jl             # Test suite
├── crap/                         # Legacy/experimental code
├── Project.toml                  # Julia package dependencies
└── README.md                     # This file
```

## 🚀 Quick Start

### 1. Setup Environment
```julia
# Clone the repository
git clone https://github.com/fuzzifikation/Financial-Analysis-with-Backtesting.git
cd Financial-Analysis-with-Backtesting

# Activate the project environment
julia --project=.

# Install dependencies
using Pkg; Pkg.instantiate()
```

### 2. Download Data
```bash
julia scripts/download_data.jl
```

### 3. Run Analysis
```bash
julia scripts/run_analysis.jl
```

### 4. Launch Interactive Dashboard
```bash
julia scripts/dashboard.jl
```

## 📊 Supported Assets

- **🌍 Global Indices**: MSCI Europe, ACWI, World indices
- **🇺🇸 US Markets**: S&P 500, S&P 500 Total Return
- **🏛️ Fixed Income**: iShares Aggregate Bond ETF, Treasury Bills
- **🌏 Emerging Markets**: iShares MSCI Emerging Markets ETF
- **🥇 Commodities**: Gold futures and spot prices
- **₿ Cryptocurrency**: Bitcoin (BTC-USD)
- **💰 Money Market**: Simulated from Treasury bill rates

## 💻 Usage Examples

### Basic Analysis
```julia
using Pkg; Pkg.activate(".")
include("src/FinancialAnalysis.jl")
using .FinancialAnalysis

# Load saved data
data = load_saved_data("data/data.jld2")
prices = merge_timearrays(data["prices_list"]; names=data["asset_symbols"])

# Calculate correlations
corr_matrix = analyze_correlations(prices)

# Year-over-year analysis
yoy_returns = yoy_gain(prices)
```

### Interactive Portfolio Dashboard
```julia
# Launch the full dashboard
julia scripts/dashboard.jl

# Or create custom dashboard
prices_subset = prices[:, [:SP500TR, :Bond_ETF, :Gold]]
dashboard_fig = create_dashboard(prices_subset)
display(dashboard_fig)
```

### Custom Portfolio Optimization
```julia
returns = values(yoy_gain(prices))
weights_equal = portfolio_optimization(returns, :equal_weight)
weights_minvar = portfolio_optimization(returns, :min_variance)
```

## 🔧 Dependencies

- **TimeSeries.jl**: Time series data handling and operations
- **MarketData.jl**: Yahoo Finance data integration
- **GLMakie.jl**: High-performance interactive plotting
- **JLD2.jl**: Efficient binary data serialization
- **DataFrames.jl**: Tabular data manipulation
- **StatsBase.jl**: Statistical functions and distributions

## 📈 Analysis Capabilities

### Correlation Clustering
- Automatic identification of highly correlated asset groups (threshold configurable)
- Separation of correlated vs. uncorrelated assets for diversification
- Dynamic correlation matrix visualization

### Portfolio Optimization
- **Equal Weight**: Baseline 1/N portfolio
- **Minimum Variance**: Risk-minimizing allocation
- **Interactive Exploration**: Real-time weight adjustment with constraints

### Risk Metrics
- Year-over-year return distributions
- Rolling volatility analysis
- Maximum drawdown calculations
- Value-at-Risk (VaR) estimation

### Interactive Features
- **Constraint Sliders**: Portfolio weights automatically sum to 1.0
- **Time Window Selection**: Adjustable analysis periods
- **Real-time Updates**: All plots update synchronously
- **Multi-asset Normalization**: Comparable performance visualization

## 🧪 Testing

Run the test suite to verify functionality:
```bash
julia test/runtests.jl
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is open source. See the repository for license details.

## 🙏 Acknowledgments

- **MarketData.jl** team for Yahoo Finance integration
- **TimeSeries.jl** community for robust time series handling
- **GLMakie.jl** developers for interactive plotting capabilities
