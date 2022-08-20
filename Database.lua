

local addonName, addon = ...;

local L = addon.locales;

local Database = {};

function Database:Init()

    if not DungeonPugsAccount then
        DungeonPugsAccount = {
            config = {},
            characters = {},
            minimapIcon = {},
        };
    end

    if not DungeonPugsCharacter then
        DungeonPugsCharacter = {};
    end

    addon:TriggerEvent("Database_OnInitialised")

end

function Database:Wipe(db, t)

    if db == "all" then
        
        DungeonPugsAccount = {
            config = {},
            characters = {},
        };

        DungeonPugsCharacter = {};

        addon.print(L.ALL_DATA_CLEARED);
        return;
    end

    if db == "account" then

        if DungeonPugsAccount[t] then
            
            DungeonPugsAccount[t] = {};

            addon.print(string.format(L.ACCOUNT_DATA_CLEARED_S, t));
            return;
        end
        
        DungeonPugsAccount = {
            config = {},
            characters = {},
        };

        addon.print(L.ACCOUNT_DATA_CLEARED);
        return;
    end

    if db == "character" then
        
        DungeonPugsCharacter = {};

        addon.print(L.CHARACTER_DATA_CLEARED);
        return;
    end

end

function Database:InsertCharacterData(nameRealm, characterData)

    if DungeonPugsAccount and type(DungeonPugsAccount.characters) == "table" then
        
        if not DungeonPugsAccount.characters[nameRealm] then
            DungeonPugsAccount.characters[nameRealm] = characterData;
        end
    end
end

function Database:WipeCharacterData(nameRealm)

    if DungeonPugsAccount and type(DungeonPugsAccount.characters) == "table" then
        DungeonPugsAccount.characters[nameRealm] = nil;
    end
end


function Database:SetConfigValue(setting, newValue)

    if DungeonPugsAccount and type(DungeonPugsAccount.config) == "table" then
        DungeonPugsAccount.config[setting] = newValue;
    end
end

function Database:GetConfigValue(setting)

    if DungeonPugsAccount and type(DungeonPugsAccount.config) == "table" then
        if DungeonPugsAccount.config[setting] then
            return DungeonPugsAccount.config[setting];
        end
    end
end


addon.db = Database;