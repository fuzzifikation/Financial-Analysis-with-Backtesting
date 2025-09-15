using GLMakie, TimeSeries, Dates





# ------------------------------------------------------------
# Slider panel: make_weight_sliders
# ------------------------------------------------------------
"""
    fig, sliders = make_weight_sliders(ta::TimeArray; fig=nothing, pos=(1,1))

Create a SliderGrid with one slider per column in `ta`.
Sliders are constrained so their values sum to 1.
Returns the figure and the vector of slider objects.
"""
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

# ------------------------------------------------------------
# Weighted combination plot with IntervalSlider
# ------------------------------------------------------------
"""
    plot_weighted_combo!(fig, pos, ta::TimeArray, sliders)

Add a weighted combination plot to `fig` at `pos`.
- Grey lines: normalised series from the date chosen by the IntervalSlider's left thumb.
- Red line: weighted combination of those normalised series, driven by `sliders`.
"""
function plot_weighted_combo!(fig::Figure, pos, ta::TimeArray, sliders)
    dates = timestamp(ta)
    n = length(dates)

    # IntervalSlider above the axis
    islider = IntervalSlider(fig[pos[1]-1, pos[2]];
        range=1:n,
        startvalues=(1, n),  # both thumbs initialised
        snap=true)

    # Label bound to BOTH thumbs' dates, placed just below the slider
    labeltext = lift(islider.interval) do (lo_idx, hi_idx)
        lo_date = dates[round(Int, lo_idx)]
        hi_date = dates[round(Int, hi_idx)]
        "Normalize from: $(lo_date)   End: $(hi_date)"
    end
    Label(fig[pos[1]-1, pos[2]], labeltext;
        tellwidth=false,
        tellheight=false)

    # Axis for the plot
    ax = Axis(fig[pos...], title="Weighted Combination",
        xlabel="Date", ylabel="Value")

    # Normalised TimeArray from left thumb
    norm_ta_obs = lift(islider.interval) do (lo_idx, _hi_idx)
        target_date = dates[round(Int, lo_idx)]
        normalize_prices(ta, target_date)  # your function
    end

    # Weighted combination: reactive to both norm data and sliders
    combo_obs = lift(norm_ta_obs, (s.value for s in sliders)...) do nta, vals...
        w = collect(vals)
        w ./= sum(w)
        (timestamp(nta), Matrix(values(nta)) * w)
    end

    # Redraw function
    function redraw_plot()
        empty!(ax)
        nta = norm_ta_obs[]
        for i in 1:size(nta, 2)
            lines!(ax, timestamp(nta), values(nta)[:, i], color=(:grey, 0.5))
        end
        ts_combo, y_combo = combo_obs[]
        lines!(ax, ts_combo, y_combo, color=:red, linewidth=2)
    end

    # React to both data and weights
    on(norm_ta_obs) do _
        redraw_plot()
    end
    on(combo_obs) do _
        redraw_plot()
    end

    # Force initial draw without moving thumbs
    redraw_plot()

    return ax, islider
end

















#=
# ------------------------------------------------------------
# Example usage
# ------------------------------------------------------------

# Build dashboard: sliders in right column
ta = prices_uncorr
ta_yoy = yoy_uncorr
fig, sliders = make_weight_sliders(ta; pos = (2, 2))
plot_weighted_combo!(fig, (2, 1), ta, sliders)

display(fig)

=#


#=

function plot_with_interval_slider(ta::TimeArray)
    dates = timestamp(ta)
    n     = length(dates)

    fig = Figure(size = (1000, 600))

    # IntervalSlider above the plot
    islider = IntervalSlider(fig[1, 1];
        range = 1:n,                      # indices into dates
        startvalues = (1, n),
        snap = true)

    # Label bound to the left thumb's date
    labeltext = lift(islider.interval) do (lo_idx, _hi_idx)
        "Normalize from: $(dates[round(Int, lo_idx)])"
    end
    Label(fig[2, 1], labeltext; tellwidth = false)

    # Axis for the time series
    ax = Axis(fig[3, 1], title = "Normalized from selected date",
              xlabel = "Date", ylabel = "Value")

    # Observable for normalized data
    norm_ta_obs = lift(islider.interval) do (lo_idx, _hi_idx)
        target_date = dates[round(Int, lo_idx)]
        normalize_prices(ta, target_date)
    end

    # Plot lines that update automatically when norm_ta_obs changes
    on(norm_ta_obs) do nta
        empty!(ax)  # clear old lines
        for i in 1:size(nta, 2)
            lines!(ax, timestamp(nta), values(nta)[:, i])
        end
    end

    return fig, islider
end
=#
# Build dashboard
#fig, sliders = make_weight_sliders(ta; pos=(1, 1))
#plot_weighted_combo!(fig, (1, 2), ta, sliders)

#display(fig)
#=
function weighted_slider_plot(ta::TimeArray)
    syms = colnames(ta)
    num = length(syms)
    x = timestamp(ta)
    Y = Matrix(values(ta))

    fig = Figure(size=(1000, 600))
    ax = Axis(fig[1, 1], title="Weighted Combination",
        xlabel="Date", ylabel="Value")

    # Create sliders dynamically
    slider_args = [(label=string(sym),
        range=0:0.01:1,
        startvalue=1 / num) for sym in syms]

    sg = SliderGrid(fig[1, 2], slider_args...;
        width=200, tellheight=false)

    sliders = sg.sliders
    updating = Ref(false)

    # Keep sum = 1 using set_close_to!
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

    # Weighted combo using slider values directly
    combo_obs = lift((vals...) -> begin
            w = collect(vals)
            w ./= sum(w)
            Y * w
        end, (s.value for s in sliders)...)

    # Plot
    for i in 1:num
        lines!(ax, x, Y[:, i], color=(:grey, 0.5))
    end
    lines!(ax, x, combo_obs, color=:red, linewidth=2)

    return fig
end
=#