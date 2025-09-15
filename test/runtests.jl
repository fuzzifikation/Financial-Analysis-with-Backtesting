using Test

# Add the src directory to the load path
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

# Load the main module
include("../src/FinancialAnalysis.jl")
using .FinancialAnalysis

@testset "FinancialAnalysis Tests" begin
    
    @testset "Data Download Functions" begin
        # Test that functions exist and have reasonable signatures
        @test hasmethod(download_financial_data, (Vector{String},))
        @test hasmethod(clean_prices, (TimeArray,))
        @test hasmethod(merge_timearrays, (Vector{TimeArray},))
    end
    
    @testset "Analysis Functions" begin
        @test hasmethod(yoy_gain, (TimeArray,))
        @test hasmethod(normalize_prices, (TimeArray, Date))
        @test hasmethod(analyze_correlations, (TimeArray,))
    end
    
    @testset "Visualization Functions" begin
        @test hasmethod(plot_prices, (TimeArray,))
        @test hasmethod(plot_histograms, (TimeArray,))
    end
    
    @testset "Portfolio Functions" begin
        @test hasmethod(make_weight_sliders, (TimeArray,))
        @test hasmethod(portfolio_optimization, (Matrix,))
    end
    
    # Test portfolio optimization
    @testset "Portfolio Optimization" begin
        # Create dummy return data
        returns = rand(100, 3)  # 100 periods, 3 assets
        
        # Test equal weight
        weights_eq = portfolio_optimization(returns, :equal_weight)
        @test length(weights_eq) == 3
        @test sum(weights_eq) ≈ 1.0
        @test all(weights_eq .≈ 1/3)
        
        # Test minimum variance
        weights_mv = portfolio_optimization(returns, :min_variance)
        @test length(weights_mv) == 3
        @test sum(weights_mv) ≈ 1.0 atol=1e-10
    end
end

println("✅ All tests passed!")