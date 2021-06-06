--CONSTANTS--

--REQUIRES--
local mod_gui = require("mod-gui")

--Holds items that are exported
local exports = {}

function exports.DoesGuiExist(player, name)
    return (mod_gui.get_frame_flow(player)[name] ~= nil)
end

function exports.IsGuiVisible(player, name)
    local gui = mod_gui.get_frame_flow(player)[name]
    return (gui.visible)
end

function exports.HideGui(player, name)
    local gui = mod_gui.get_frame_flow(player)[name]
    gui.visible = false
    player.opened = nil
end

function exports.ShowGui(player, name)
    local gui = mod_gui.get_frame_flow(player)[name]
    gui.visible = true
    player.opened = gui
end

-- Apply a style option to a GUI
local function ApplyStyle (guiIn, styleIn)
    for k,v in pairs(styleIn) do
        guiIn.style[k]=v
    end
end

-- Shorter way to add a label with a style
function exports.AddLabel(gui, name, message, style)
    local g = gui.add{name = name, type = "label",
                    caption=message}
    if (type(style) == "table") then
        ApplyStyle(g, style)
    else
        g.style = style
    end
end

return exports
