local mod_gui = require("mod-gui")

local function DoesGuiExist(player, name)
    return (mod_gui.get_frame_flow(player)[name] ~= nil)
end

local function IsGuiVisible(player, name)
    local gui = mod_gui.get_frame_flow(player)[name]
    return (gui.visible)
end

local function HideGui(player, name)
    local gui = mod_gui.get_frame_flow(player)[name]
    gui.visible = false
    player.opened = nil
end

local function ShowGui(player, name)
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
local function AddLabel(gui, name, message, style)
    local g = gui.add{name = name, type = "label",
                    caption=message}
    if (type(style) == "table") then
        ApplyStyle(g, style)
    else
        g.style = style
    end
end

return{
    DoesGuiExist = DoesGuiExist,
    IsGuiVisible = IsGuiVisible,
    HideGui = HideGui,
    ShowGui = ShowGui,
    AddLabel = AddLabel
}
