--CONSTANTS--
local ATR_BUTTON = "atr_button"
local ATR_GUI = "atr_gui"

--REQUIRES--
local mod_gui = require("mod-gui")
local gui_utils = require("atr_gui_utils")

--Holds items that are exported
local exports = {}

local function create_gui_button(player)
    if (mod_gui.get_button_flow(player).atr_button == nil) then
        local b = mod_gui.get_button_flow(player).add{name=ATR_BUTTON,
                                                        caption="CLICK ME FOR MORE INFO",
                                                        type="sprite-button",
                                                        style=mod_gui.button_style}
        b.style.padding=2
    end
end

local function create_atr_gui_skeleton(player)
    -- OUTER FRAME (TOP GUI ELEMENT)
    local frame = mod_gui.get_frame_flow(player).add{
        type = 'frame',
        name = ATR_GUI,
        direction = "vertical"}
    frame.style.padding = 5

    -- INNER FRAME
    local inside_frame = frame.add{
        type = "frame",
        name = "atr_if",
        style = "inside_deep_frame",
        direction = "vertical"
    }

    -- SUB HEADING w/ LABEL
    local subhead = inside_frame.add{
        type="frame",
        name="sub_header",
        style = "changelog_subheader_frame"}
    gui_utils.add_label(subhead, "scen_info", "Scenario Info and Controls", "subheader_caption_label")

    -- TABBED PANE
    local oarc_tabs = inside_frame.add{
        name="atr_tabs",
        type="tabbed-pane",
        style="tabbed_pane"}
    oarc_tabs.style.top_padding = 8
end

local function atr_button_click(event, player)
    --On first click, change to elipsis
    if (event.element.caption ~= "") then
        event.element.caption = ""
        event.element.style.width = 20
        event.element.sprite="utility/expand_dots"
    end

    if (not gui_utils.does_gui_exist(player, ATR_GUI)) then
        create_atr_gui_skeleton(player)
    else
        if (gui_utils.is_gui_visible(player, ATR_GUI)) then
            gui_utils.hide_gui(player, ATR_GUI)
        else
            gui_utils.show_gui(player, ATR_GUI)
            --FakeTabChangeEventOarcGui(player)
        end
    end
end

function exports.on_gui_click(event)
    local name = event.element.name
    local player = game.players[event.player_index]

    if (name == ATR_BUTTON) then
        atr_button_click(event, player)
    end

end

function exports.on_player_created(player)
    create_gui_button(player)
end

return exports
