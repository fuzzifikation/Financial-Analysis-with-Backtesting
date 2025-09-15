"""
Portfolio optimization and interactive dashboard functions.
"""

using GLMakie, TimeSeries, Dates

"""
    make_weight_sliders(ta::TimeArray; fig=nothing, pos=(1,1))

Create interactive sliders for portfolio weights that sum to 1.
"""
function make_weight_sliders(ta::TimeArray; fig::Union{Nothing,Figure}=nothing, pos=(1, 1))
    syms = string.(colnames(ta))
    num = length(syms)

    if fig === nothing
        fig = Figure(size=(1000, 600))
    end

    slider_args = [(label=sym, range=0:0.01:1, startvalue=1/num) for sym in syms]

    sg = SliderGrid(fig[pos...], slider_args...; width=300, tellheight=false)
    sliders = sg.sliders
    updating = Ref(false)

    # Constraint: weights sum to 1
    for i in 1:num
        on(sliders[i].value) do newval
            if updating[]
                return
            end
            updating[] = true

            others = setdiff(1:num, i)
            total_other = sum(sliders[j].value[] for j in others)
            remaining = 1 - newval

            if total_other > 0
                for j in others
                    curval = sliders[j].value[]
                    neww = clamp(curval * remaining / total_other, 0, 1)
                    set_close_to!(sliders[j], neww)
                end
            else
                share = remaining / length(others)
                for j in others
                    set_close_to!(sliders[j], share)
                end
            end

            updating[] = false
        end
    end

    return fig, sliders
end

"""
    create_dashboard(prices_uncorr::TimeArray)

Create an interactive dashboard with price plots, histograms, and portfolio weight sliders.
"""
function create_dashboard(prices_uncorr::TimeArray)
    fig = Figure(size=(1200, 700))

    # Weight sliders in right column
    fig, sliders = make_weight_sliders(prices_uncorr; fig=fig, pos=(1:2, 2))

    # Price plots in left column
    ax_prices, ax_hist, islider = plot_prices_and_yoy(fig, (1, 1), prices_uncorr, sliders)

    # Layout sizing
    colsize!(fig.layout, 1, Relative(0.7))
    colsize!(fig.layout, 2, Relative(0.3))
    rowsize!(fig.layout, 1, Relative(0.66))
    rowsize!(fig.layout, 2, Relative(0.34))

    return fig
end

"""
    plot_prices_and_yoy(fig::Figure, pos, prices::TimeArray, sliders)

Create interactive price and YoY return plots with portfolio weight controls.
"""
function plot_prices_and_yoy(fig::Figure, pos, prices_uncorr::TimeArray, sliders)
    dates = timestamp(prices_uncorr)
    n = length(dates)
    last_valid_right = findlast(d -> d <= dates[end] - Year(1), dates)

    # Time interval slider
    islider = IntervalSlider(fig[pos[1]-1, pos[2]];
        range=1:n,
        startvalues=(1, last_valid_right),
        snap=true)

    # Constraint validation
    on(islider.interval) do (lo, hi)
        if hi > last_valid_right
            set_close_to!(islider, (lo, last_valid_right))
        elseif lo > hi
            set_close_to!(islider, (hi-1, hi))
        end
    end

    # Date range label
    labeltext = lift(islider.interval) do (lo, hi)
        "Normalize from: $(dates[Int(lo)])   YoY window end: $(dates[Int(hi)])"
    end
    Label(fig[pos[1]-1, pos[2]], labeltext; tellwidth=false, tellheight=false)

    # Create axes
    ax_prices = Axis(fig[pos...], title="Weighted Portfolio", xlabel="Date", ylabel="Value")
    ax_hist = Axis(fig[pos[1]+1, pos[2]], title="YoY Gains Distribution", xlabel="Gain", ylabel="Probability")

    # Reactive data observables
    norm_prices_obs = lift(islider.interval) do (lo, _)
        normalize_prices(prices_uncorr, dates[Int(lo)])
    end

    combo_prices_obs = lift(norm_prices_obs, (s.value for s in sliders)...) do nta, vals...
        w = collect(vals)
        w ./= sum(w)
        combo_vec = Matrix(values(nta)) * w
        combo_mat = reshape(combo_vec, :, 1)
        TimeArray(timestamp(nta), combo_mat, [:Portfolio])
    end

    yoy_combo_obs = lift(islider.interval, (s.value for s in sliders)...) do interval, vals...
        lo, hi = interval
        w = collect(vals)
        w ./= sum(w)
        combo_vec = Matrix(values(prices_uncorr)) * w
        combo_mat = reshape(combo_vec, :, 1)
        combo_full = TimeArray(dates, combo_mat, [:Portfolio])
        yoy_full = yoy_gain(combo_full)
        yoy_full[Int(lo):Int(hi)]
    end

    # Drawing functions
    function redraw_prices()
        empty!(ax_prices)
        nta = norm_prices_obs[]
        
        # Plot individual assets in gray
        for c in 1:size(nta, 2)
            lines!(ax_prices, timestamp(nta), values(nta)[:, c], color=(:grey, 0.5))
        end
        
        # Plot portfolio in red
        combo = combo_prices_obs[]
        lines!(ax_prices, timestamp(combo), values(combo)[:, 1], color=:red, linewidth=2)
    end

    function redraw_hist()
        empty!(ax_hist)
        combo_yoy = yoy_combo_obs[]
        data = skipmissing(vec(values(combo_yoy)))

        edges = 0.5:0.05:2.0
        h = fit(Histogram, collect(data), edges)
        h = normalize(h, mode=:probability)

        e, w = h.edges[1], h.weights
        x = repeat(e, inner=[2])[2:end-1]
        y = repeat(w, inner=[2])
        lines!(ax_hist, x, y, color=:red, linewidth=2)

        xlims!(ax_hist, first(edges), last(edges))
        ylims!(ax_hist, 0, 0.5)
    end

    # Set up reactivity
    on(norm_prices_obs) do _; redraw_prices(); end
    on(combo_prices_obs) do _; redraw_prices(); end
    on(yoy_combo_obs) do _; redraw_hist(); end

    # Initial draw
    redraw_prices()
    redraw_hist()

    return ax_prices, ax_hist, islider
end

"""
    portfolio_optimization(returns::Matrix, method=:equal_weight)

Basic portfolio optimization functions.
"""
function portfolio_optimization(returns::Matrix, method::Symbol=:equal_weight)
    n_assets = size(returns, 2)
    
    if method == :equal_weight
        return fill(1.0/n_assets, n_assets)
    elseif method == :min_variance
        # Minimum variance portfolio
        cov_matrix = cov(returns)
        ones_vec = ones(n_assets)
        inv_cov = inv(cov_matrix)
        weights = (inv_cov * ones_vec) / (ones_vec' * inv_cov * ones_vec)
        return vec(weights)
    else
        error("Unknown optimization method: $method")
    end
end