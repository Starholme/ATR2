local ATR_BUTTON = "atr_button"
local ATR_GUI = "atr_gui"

local mod_gui = require("mod-gui")
local GuiUtils = require("atr_guiUtils")

local function CreateGuiButton(player)
    if (mod_gui.get_button_flow(player).atr_button == nil) then
        local b = mod_gui.get_button_flow(player).add{name=ATR_BUTTON,
                                                        caption="CLICK ME FOR MORE INFO",
                                                        type="sprite-button",
                                                        style=mod_gui.button_style}
        b.style.padding=2
    end
end

local function CreateAtrGuiTabsPane(player)
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
    GuiUtils.AddLabel(subhead, "scen_info", "Scenario Info and Controls", "subheader_caption_label")

    -- TABBED PANE
    local oarc_tabs = inside_frame.add{
        name="atr_tabs",
        type="tabbed-pane",
        style="tabbed_pane"}
    oarc_tabs.style.top_padding = 8
end

local function OnGuiClick(event)
    local name = event.element.name
    local player = game.players[event.player_index]

    if (name == ATR_BUTTON) then

        --On first click, change to elipsis
        if (event.element.caption ~= "") then
            event.element.caption = ""
            event.element.style.width = 20
            event.element.sprite="utility/expand_dots"
        end

        if (not GuiUtils.DoesGuiExist(player, ATR_GUI)) then
            CreateAtrGuiTabsPane(player)
        else
            if (GuiUtils.IsGuiVisible(player, ATR_GUI)) then
                GuiUtils.HideGui(player, ATR_GUI)
            else
                GuiUtils.ShowGui(player, ATR_GUI)
                --FakeTabChangeEventOarcGui(player)
            end
        end

    end
end

local function OnPlayerCreated(player)
    CreateGuiButton(player)
end

return{
    OnGuiClick = OnGuiClick,
    OnPlayerCreated = OnPlayerCreated
}
