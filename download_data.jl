using TimeSeries, Dates, MarketData, JLD2
include("modules/Dieters_InvestmentHelpers.jl")
include("modules/Dieters_PlottingHelpers.jl")
include("sliderplot.jl")
## Data Downloader

# Step 1 Download from Yahoo
tickers = [
	"^125904-USD-STRD",  # MSCI Europe (USD)
	"^GSPC",             # S&P 500 Index (USD)
    "^SP500TR",          # S&P 500 Total Return Index (USD)
  #  "GC=F",              # Gold Futures (USD)
    "^892400-USD-STRD",  # MSCI ACWI Index (USD)
    "^990100-USD-STRD",  # MSCI World Index (USD)
    "AGG",               # iShares Core U.S. Aggregate Bond ETF (USD)
	"EEM",               # iShares MSCI Emerging Markets ETF (USD)
    "BTC-USD"]
## Step 3 Map asset names to their respective TimeArrays
asset_names = [
    "MSCI Europe",
    "S&P 500 Index",
    "S&P 500 Total Return Index",
 #   "Gold Futures",
    "MSCI ACWI Index",
    "MSCI World Index",
    "iShares Aggregate Bond ETF",
    "iShares MSCI Emerging Markets ETF",
    "Bitcoin",
    "Money Market Fund from ^IRX", # comes below
    "Gold" # comes below
]

asset_symbols = [
    :Europe,
    :SP500,
    :SP500TR,
    :ACWI,
    :World,
    :Bond_ETF,
    :EM_ETF,
    :Bitcoin,
    :MoneyMarket,
    :Gold
]

# Download Prices
prices_list = TimeArray[]

for (i, tick) in enumerate(tickers)
    println("Downloading data for ticker: $tick")
    ta = clean_prices(yahoo(tick))
    push!(prices_list, ta[:AdjClose])    # Get only the Close price
end


## MoneyMarket: Step 2 Get returns from ^IDX
println("Downloading data for ticker: ^IRX")
irx = clean_prices(yahoo("^IRX"))
ret_irx = irx_to_totalreturn(irx[:AdjClose]; dtm=91, expense=0.001 )
push!(prices_list, ret_irx)

## Gold: Step 3 Import Gold separately
# Gold: from finanzen.net - copy&paste 02.09.2025
gold_prices = clean_prices(readtimearray("data/Gold_finanzen_net.csv", format="dd.mm.yyyy", delim=','))

push!(prices_list, gold_prices)


asset_dict = Dict{Symbol,Int}()
for (i, symbol) in enumerate(asset_symbols)
    asset_dict[symbol] = i
end


println("Finished downloading and cleaning data.")  

## store results
@save "data/data.jld2" prices_list tickers asset_names asset2idx asset_symbols asset_dict