function dashboard(prices_uncorr::TimeArray)
    # Create the figure
    fig = Figure(size=(1200, 700))

    # --- Right column: sliders spanning both rows ---
    fig, sliders = make_weight_sliders(
        prices_uncorr;
        fig=fig,
        pos=(1:2, 2)   # span both rows in column 2
    )

    # --- Left column: plots ---
    # Call your plot function directly into the left column
    ax_prices, ax_hist, islider = plot_prices_and_yoy(fig, (1, 1), prices_uncorr, sliders)

    # --- Layout sizing ---
    # Columns: 70% plots, 30% sliders
    colsize!(fig.layout, 1, Relative(0.7))
    colsize!(fig.layout, 2, Relative(0.3))

    # Rows: 2:1 height ratio for price plot vs histogram
    rowsize!(fig.layout, 1, Relative(0.66))
    rowsize!(fig.layout, 2, Relative(0.34))

    return fig
end

function make_weight_sliders(ta::TimeArray;
    fig::Union{Nothing,Figure}=nothing,
    pos=(1, 1))

    syms = string.(colnames(ta))
    num = length(syms)

    if fig === nothing
        fig = Figure(size=(1000, 600))
    end

    slider_args = [(label=sym,
        range=0:0.01:1,
        startvalue=1 / num) for sym in syms]

    # tellheight=false so sliders don't shrink the axis row
    sg = SliderGrid(fig[pos...], slider_args...;
        width=300,
        tellheight=false)

    sliders = sg.sliders
    updating = Ref(false)

    # Sum-to-1 logic
    for i in 1:num
        on(sliders[i].value) do newval
            if updating[]
                return
            end
            updating[] = true

            others = setdiff(1:num, i) # other sliders
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



function plot_prices_and_yoy(fig::Figure, pos, prices_uncorr::TimeArray, sliders)
    dates = timestamp(prices_uncorr)
    n = length(dates)
    # last index where a YoY lookup (date + 1 year) still exists
    last_valid_right = findlast(d -> d <= dates[end] - Year(1), dates)

    # Slider spans the full [1:n] for visual alignment with the price plot
    islider = IntervalSlider(fig[pos[1]-1, pos[2]];
        range=1:n,
        startvalues=(1, last_valid_right),
        snap=true)

    # Reactive guard: keep lo ≤ hi ≤ last_valid_right
    on(islider.interval) do (lo, hi)
        if hi > last_valid_right
            set_close_to!(islider, (lo, last_valid_right))
        elseif lo > hi
            set_close_to!(islider, (hi-1, hi))
        end
    end

    # Label showing normalization date (lo) and YoY-end date (hi)
    labeltext = lift(islider.interval) do (lo, hi)
        "Normalize from: $(dates[Int(lo)])   YoY window end: $(dates[Int(hi)])"
    end
    Label(fig[pos[1]-1, pos[2]], labeltext; tellwidth=false, tellheight=false)

    # Two stacked axes
    ax_prices = Axis(fig[pos...], title="Weighted Combo", xlabel="Date", ylabel="Value")
    ax_hist = Axis(fig[pos[1]+1, pos[2]], title="YoY Gains Histogram", xlabel="Gain", ylabel="Probability")

    # Normalized prices based on left thumb
    norm_prices_obs = lift(islider.interval) do (lo, _)
        normalize_prices(prices_uncorr, dates[Int(lo)])
    end

    # Weighted combo prices (ensure n×1 Matrix for TimeArray)
    combo_prices_obs = lift(norm_prices_obs, (s.value for s in sliders)...) do nta, vals...
        w = collect(vals)
        w ./= sum(w)
        combo_vec = Matrix(values(nta)) * w               # n-vector
        combo_mat = reshape(combo_vec, :, 1)              # n×1 matrix
        TimeArray(timestamp(nta), combo_mat, [:Combo])
    end

    # YoY gains of the combo over [lo:hi] (ensure n×1 Matrix for TimeArray)
    yoy_combo_obs = lift(islider.interval, (s.value for s in sliders)...) do interval, vals...
        lo, hi = interval
        w = collect(vals)
        w ./= sum(w)
        combo_vec = Matrix(values(prices_uncorr)) * w     # n-vector
        combo_mat = reshape(combo_vec, :, 1)              # n×1 matrix
        combo_full = TimeArray(dates, combo_mat, [:Combo])
        yoy_full = yoy_gain(combo_full)
        yoy_full[Int(lo):Int(hi)]
    end

    # Drawing routines
    function redraw_prices()
        empty!(ax_prices)
        nta = norm_prices_obs[]
        for c in 1:size(nta, 2)
            lines!(ax_prices, timestamp(nta), values(nta)[:, c], color=(:grey, 0.5))
        end
        combo = combo_prices_obs[]
        lines!(ax_prices, timestamp(combo), values(combo)[:, 1], color=:red, linewidth=2)
    end

    function redraw_hist()
        empty!(ax_hist)
        combo_yoy = yoy_combo_obs[]
        data = skipmissing(vec(values(combo_yoy)))

        # Fixed bin edges
        edges = 0.5:0.05:2.0
        h = fit(Histogram, collect(data), edges)
        h = normalize(h, mode=:probability)

        e, w = h.edges[1], h.weights
        x = repeat(e, inner=[2])[2:end-1]
        y = repeat(w, inner=[2])
        lines!(ax_hist, x, y, color=:red, linewidth=2)

        # Fixed axis limits
        xlims!(ax_hist, first(edges), last(edges))
        ylims!(ax_hist, 0, 0.5)  # adjust 0.5 to whatever max density you want
    end



    # Reactivity
    on(norm_prices_obs) do _
        redraw_prices()
    end
    on(combo_prices_obs) do _
        redraw_prices()
    end
    on(yoy_combo_obs) do _
        redraw_hist()
    end

    # Initial draw
    redraw_prices()
    redraw_hist()

    return ax_prices, ax_hist, islider
end
