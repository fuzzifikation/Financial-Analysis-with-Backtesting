using GLMakie, TimeSeries

function plot_with_manual_tooltip(
    prices_dict::Dict{String,TimeArray};
    column::Symbol=:AdjClose,
    win_size::Tuple{Int,Int}=(1000, 600)
)
    # 1) Create a blank Scene and full-screen Axis
    scene = Scene(resolution=win_size)
    ax = Axis(scene; xlabel="Date", ylabel=string(column),
        title="Prices: $(column)", xticklabelrotation=π / 4)

    # 2) Remember original view for “Home” later
    orig_xlims, orig_ylims = ax.xlimits[], ax.ylimits[]

    # 3) Plot each series as pickable
    for (ticker, ta) in prices_dict
        if column ∉ colnames(ta)
            @warn "Skipping $ticker (no column $column)"
            continue
        end
        dates = timestamp(ta)
        vals = values(ta[column])
        lines!(ax, dates, vals;
            label=ticker,
            linewidth=2,
            pickable=true)
    end

    # 4) Legend (old API)
    Legend(scene, ax; position=:rt)

    # 5) Home & Save buttons
    btn_home = Button(scene, "Home")
    on(btn_home.events.clicked) do _
        ax.xlimits[] = orig_xlims
        ax.ylimits[] = orig_ylims
    end

    btn_save = Button(scene, "Save")
    on(btn_save.events.clicked) do _
        save("prices_plot.png", scene)
        println("Saved to prices_plot.png")
    end

    # 6) Lay out buttons under the axis
    #    Axis occupies row 1, both cols → buttons live in row 2
    scene[2, 1] = btn_home
    scene[2, 2] = btn_save

    # 7) Set up the manual hover tooltip with text!
    tooltip_pos = Observable(Point2f0(0, 0))
    tooltip_text = Observable("")

    tooltip = text!(
        scene,
        tooltip_pos,
        tooltip_text;
        align=(:left, :bottom),
        color=:black,
        visible=false
    )

    # 8) Update tooltip on every mouse move
    on(events(scene).mouseposition) do mouse_pos
        hit = pick(scene, mouse_pos)
        if hit !== nothing
            plotobj, _, _ = hit
            tooltip_text[] = plotobj.attributes[:label]
            tooltip_pos[] = Point2f0(mouse_pos...) .+ Point2f0(10, 10)
            tooltip.visible[] = true
        else
            tooltip.visible[] = false
        end
    end

    return scene
end

# Usage
# scene = plot_with_manual_tooltip(prices_dict; column=:Close)
# display(scene)
