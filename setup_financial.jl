# Setup

using TimeSeries, Dates, JLD2, MarketData, GLMakie, StatsBase, Statistics, LinearAlgebra

include("modules/Dieters_InvestmentHelpers.jl")
#using .Dieters_InvestmentHelpers
include("modules/Dieters_PlottingHelpers.jl")
#using .Dieters_PlottingHelpers
include("sliderplot.jl")


@load "data/data.jld2"