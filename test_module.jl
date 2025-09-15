#!/usr/bin/env julia

println("🧪 Testing new module structure...")

try
    include("src/FinancialAnalysis.jl")
    using .FinancialAnalysis
    println("✅ FinancialAnalysis module loaded successfully!")
    
    # Test that key functions are available
    functions_to_test = [
        :download_financial_data,
        :clean_prices,
        :merge_timearrays,
        :yoy_gain,
        :normalize_prices,
        :analyze_correlations,
        :plot_prices,
        :make_weight_sliders,
        :portfolio_optimization
    ]
    
    for func in functions_to_test
        if isdefined(FinancialAnalysis, func)
            println("  ✓ $func")
        else
            println("  ✗ $func (missing)")
        end
    end
    
    println("\n🎯 Ready to use! Try running:")
    println("  julia scripts/download_data.jl")
    println("  julia scripts/run_analysis.jl") 
    println("  julia scripts/dashboard.jl")
    
catch e
    println("❌ Error loading module: $e")
    println("🔧 Check the src/ directory and fix any syntax errors")
end