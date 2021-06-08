--CONSTANTS--
local STYLES = {
    LABEL_HEADER_STYLE = {
        single_line = false,
        font = "heading-1",
        font_color = {r=1,g=1,b=1},
        top_padding = 0,
        bottom_padding = 0
    },
    MY_LONGER_LABEL_STYLE = {
        maximal_width = 600,
        single_line = false,
        font_color = {r=1,g=1,b=1},
        top_padding = 0,
        bottom_padding = 0
    },
    MY_SPACER_STYLE = {
        minimal_height = 10,
        top_padding = 0,
        bottom_padding = 0
    }
}

--REQUIRES--
local mod_gui = require("mod-gui")

--Holds items that are exported
local exports = {
    STYLES = STYLES
}

function exports.does_gui_exist(player, name)
    return (mod_gui.get_frame_flow(player)[name] ~= nil)
end

function exports.is_gui_visible(player, name)
    local gui = mod_gui.get_frame_flow(player)[name]
    return (gui.visible)
end

function exports.hide_gui(player, name)
    local gui = mod_gui.get_frame_flow(player)[name]
    gui.visible = false
    player.opened = nil
end

function exports.show_gui(player, name)
    local gui = mod_gui.get_frame_flow(player)[name]
    gui.visible = true
    player.opened = gui
end

-- Apply a style option to a GUI
local function apply_style (guiIn, styleIn)
    for k,v in pairs(styleIn) do
        guiIn.style[k]=v
    end
end

-- Shorter way to add a label with a style
function exports.add_label(gui, name, message, style)
    local g = gui.add{name = name, type = "label",
                    caption=message}
    if (type(style) == "table") then
        apply_style(g, style)
    else
        g.style = style
    end
end

function exports.add_tab(player, tab_pane, name)
    -- Create new tab
    local new_tab = tab_pane.add{
        type="tab",
        name=name,
        caption=name}

    -- Create inside frame for content
    local tab_inside_frame = tab_pane.add{
        type="frame",
        name=name.."_if",
        style = "inside_deep_frame",
        direction="vertical"}
    tab_inside_frame.style.left_margin = 10
    tab_inside_frame.style.right_margin = 10
    tab_inside_frame.style.top_margin = 4
    tab_inside_frame.style.bottom_margin = 4
    tab_inside_frame.style.padding = 5
    tab_inside_frame.style.horizontally_stretchable = true

    -- Add the whole thing to the tab now.
    tab_pane.add_tab(new_tab, tab_inside_frame)

    -- If no other tabs are selected, select the first one.
    if (tab_pane.selected_tab_index == nil) then
        tab_pane.selected_tab_index = 1
    end

    return tab_inside_frame
end

function exports.add_spacer_line(gui)
    apply_style(gui.add{type = "line", direction="horizontal"}, STYLES.MY_SPACER_STYLE)
end

function exports.formattime_hours_mins(ticks)
    local seconds = ticks / 60
    local minutes = math.floor((seconds)/60)
    local hours   = math.floor((minutes)/60)
    local minutes = math.floor(minutes - 60*hours)
    return string.format("%dh:%02dm", hours, minutes)
end

return exports
