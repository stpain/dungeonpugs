

local addonName, addon = ...;

local L = addon.locales

--EXAMPLE
-- StaticPopupDialogs['MainCharacterAddAltCharacter'] = {
--     text = L["DIALOG_MAIN_CHAR_ADD"],
--     button1 = L["UPDATE"],
--     button2 = L["CANCEL"],
--     hasEditBox = true,
--     OnShow = function(self)
--         self.button1:Disable()
--     end,
--     EditBoxOnTextChanged = function(self)
--         if self:GetText() ~= '' then
--             local guid = Roster:GetGuildMemberGUID(self:GetText())
--             local dialogText = _G[self:GetParent():GetName().."Text"]
--             if guid then
--                 local character = Guildbook:GetCharacterFromCache(guid)
--                 dialogText:SetText(string.format(L["DIALOG_MAIN_CHAR_ADD_FOUND"], character.Name, character.Level, L[character.Class]))
--                 self:GetParent().button1:Enable()
--             else
--                 dialogText:SetText(L["DIALOG_MAIN_CHAR_ADD"])
--                 self:GetParent().button1:Disable()
--             end
--         end
--     end,

--     -- will look at having this just set the alt/main stuff when my brain is working, for now it just adds the guid to the alt characters table where it can then be set
--     OnAccept = function(self)
--         local guid = Roster:GetGuildMemberGUID(self.editBox:GetText())
--         if guid then
--             if not GUILDBOOK_GLOBAL.myCharacters[guid] then
--                 GUILDBOOK_GLOBAL.myCharacters[guid] = true
--             end
--         end
--     end,
--     OnCancel = function(self)

--     end,
--     timeout = 0,
--     whileDead = true,
--     hideOnEscape = false,
-- }


StaticPopupDialogs.AddDungeonPugFriend = {
    text = "",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    editBoxWidth = 300,
    hideOnEscape = false,
    whileDead = true,
    timeout = 0,

    OnShow = function(self, data)
        self.text:SetText(L.DIALOG_TEXT_ADD_FRIEND_S:format(data.name))
        self.editBox:SetText(L.DIALOG_NOTE)
    end,

    EditBoxOnTextChanged = function(self, data)

    end,

    OnAccept = function(self, data)
        addon:TriggerEvent("Player_OnAddDungeonPugFriend", data.name, data.class, self.editBox:GetText())
    end,

    OnCancel = function(self)

    end,
}