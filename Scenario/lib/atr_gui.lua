--CONSTANTS--
local ATR_BUTTON = "atr_button"
local ATR_GUI = "atr_gui"

--REQUIRES--
local mod_gui = require("mod-gui")
local gui_utils = require("lib/atr_gui_utils")
local CONFIG = require("config")
local split_spawn = require("lib/atr_split_spawn")

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

local function build_info_tab(tab)
    gui_utils.add_label(tab, "welcome_label", "Welcome to All The Rockets!", gui_utils.STYLES.LABEL_HEADER_STYLE)
    gui_utils.add_label(tab, "scenario_text", CONFIG.SCENARIO_TEXT, gui_utils.STYLES.MY_LONGER_LABEL_STYLE)
    gui_utils.add_spacer_line(tab)
    gui_utils.add_label(tab, "server_text", CONFIG.SERVER_TEXT, gui_utils.STYLES.MY_LONGER_LABEL_STYLE)
    gui_utils.add_spacer_line(tab)

    gui_utils.add_label(tab, "map_info", CONFIG.MAP_INFO, gui_utils.STYLES.MY_LONGER_LABEL_STYLE)

    --Enemy Settings
    local enemy_expansion_txt = "disabled"
    if game.map_settings.enemy_expansion.enabled then enemy_expansion_txt = "enabled" end

    local enemy_text="Server Run Time: " .. gui_utils.formattime_hours_mins(game.tick) .. "\n" ..
    "Current Evolution: " .. string.format("%i", game.forces["enemy"].evolution_factor * 100) .. "%\n" ..
    "Enemy evolution time/pollution/destroy factors: " ..
    string.format("%.0f", game.map_settings.enemy_evolution.time_factor * 10000000) .. "/" ..
    string.format("%.0f", game.map_settings.enemy_evolution.pollution_factor * 10000000) .. "/" ..
    string.format("%.0f", game.map_settings.enemy_evolution.destroy_factor * 100000) .. "\n" ..
    "Enemy expansion is " .. enemy_expansion_txt

    gui_utils.add_label(tab, "enemy_info", enemy_text, gui_utils.STYLES.MY_LONGER_LABEL_STYLE)
    gui_utils.add_spacer_line(tab)

    -- Mods
    gui_utils.add_label(tab, "mods_text", CONFIG.MOD_TEXT, gui_utils.STYLES.MY_LONGER_LABEL_STYLE)
    gui_utils.add_label(tab, "softmods_text", "\n" .. CONFIG.SOFTMOD_TEXT, gui_utils.STYLES.MY_LONGER_LABEL_STYLE)
    gui_utils.add_spacer_line(tab)

    -- Discord
    tab.add{type="textfield",
            tooltip="Come join the discord (copy this invite)!",
            text=CONFIG.DISCORD}
    -- Contact information
    gui_utils.add_label(tab, "contact_text", CONFIG.CONTACT_TEXT, gui_utils.STYLES.MY_LONGER_LABEL_STYLE)
    gui_utils.add_label(tab, "version_text", CONFIG.VERSION, gui_utils.STYLES.MY_LONGER_LABEL_STYLE)
end

local function init_gui_tabs(player, tab_pane)
    local tab = gui_utils.add_tab(player, tab_pane, "Info")
    build_info_tab(tab)

    if CONFIG.ENABLE_SPLIT_SPAWN then
        tab = gui_utils.add_tab(player, tab_pane, "Spawn")
        split_spawn.build_tab(tab, player, exports)
    end
end

local function refresh_gui_tabs(player)
    local all_tabs = mod_gui.get_frame_flow(player)[ATR_GUI].atr_if.atr_tabs

    all_tabs["Info_if"].clear()
    build_info_tab(all_tabs["Info_if"])

    if CONFIG.ENABLE_SPLIT_SPAWN then
        all_tabs["Spawn_if"].clear()
        split_spawn.build_tab(all_tabs["Spawn_if"], player, exports)
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
    local atr_tabs = inside_frame.add{
        name="atr_tabs",
        type="tabbed-pane",
        style="tabbed_pane"}
    atr_tabs.style.top_padding = 8

    init_gui_tabs(player, atr_tabs)
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
            refresh_gui_tabs(player)
            gui_utils.show_gui(player, ATR_GUI)
        end
    end
end

function exports.hide_gui(player)
    if (gui_utils.is_gui_visible(player, ATR_GUI)) then
        gui_utils.hide_gui(player, ATR_GUI)
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
