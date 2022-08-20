

local name, addon = ...;

local L = {}

L.HELP = "Click a player to whisper them your message.\n\n|cffFFD100Alt|r click a player to invite them."

L.HELPTIP_DUNGEON_LISTVIEW = "Select an instance to view players looking for a group.\n\nTo view all players click 'Clear filters'."
L.HELPTIP_DUNGEON_PLAYERS_LISTVIEW = "Players shown by role.\n\nTanks are shown as blue.\nHealers shown as green.\nDPS is shown as red.\nUnknown roles show as yellow.\n\nPlayer role icons display multiple roles.\n\nGroup icons are shown for players already in a group, the tooltip will show the group leader.\n\nThis is subject to user error!"
L.HELTIP_CONFIG = "You can create a message from the checkbox options.\nOR, uncheck them all and make your own message for bonus social points.\n\nAs Blizzard made the new UI require a manual update you'll need to check the last update time and probably click 'Refresh'."

L.DUNGEON_HEADER = "Select dungeon"
L.DUNGEON_PLAYERS_HEADER_HC = "Heoric: %s"
L.DUNGEON_PLAYERS_HEADER = "Normal: %s"
L.ALL_PLAYERS_HEADER = "All players"

L.HELLO = "Hi,"
L.LFG = "LFG" --LFG or LF or LFM ?
L.TANK = "Tank"
L.HEALER = "Healer"
L.DPS = "Dps"


L.CLEAR_INSTANCE_FILTER = "Clear filters"
L.REFRESH_SEARCH = "Refresh LFG list"
L.WHISPER_MESSAGE = "Whisper message"
L.INCLUDE_CLASS = "Include class"
L.INCLUDE_INSTANCE_NAME = "Include instance name"

addon.locales = L;




