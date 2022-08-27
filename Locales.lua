

local name, addon = ...;

local L = {}

L.HELP_TOP = "You can generate a whisper message using the role checkboxes.\n\nYou can also include your class and the instance name."
L.HELP_BOTTOM = "Use the dropdown menus to filter the results.\n\n"..CreateAtlasMarkup("socialqueuing-icon-group", 16, 16, 0, 2).."indicates a group (group leader is shown).\n\n|cffFFD100Shift|r click a player to whisper them your message.\n\n|cffFFD100Alt|r click a player to invite them."

L.HELLO = "Hi,"
L.LFG = "LF" --LFG or LF or LFM ?
L.TANK = "Tank"
L.HEALER = "Healer"
L.DPS = "Dps"

L.LINK_INVITE = "Invite"

L.CLEAR_INSTANCE_FILTER = "Clear filters"
L.REFRESH_SEARCH = "Refresh LFG list"
L.INCLUDE_CLASS = "Include class"
L.INCLUDE_INSTANCE_NAME = "Include instance name"

L.LAST_UPDATED = "Last updated %s"

addon.locales = L;





