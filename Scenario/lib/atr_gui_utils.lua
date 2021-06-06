--CONSTANTS--

--REQUIRES--
local mod_gui = require("mod-gui")

--Holds items that are exported
local exports = {}

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

return exports
