

local addonName, addon = ...;

addon.Colours = {}

for k, v in pairs(RAID_CLASS_COLORS) do
    addon.Colours[k] = CreateColor(v:GetRGB())
end

local L = addon.locales;

local Database = {};

Database.accountDbKeys = {
    ["config"] = {},
    ["minimapIcon"] = {},
    ["dungeonPugFriends"] = {},
    ["dungeonPugIgnore"] = {},
    ["characters"] = {},
}

function Database:Init()

    if not DungeonPugsAccount then
        DungeonPugsAccount = {};
    end

    for key, var in pairs(self.accountDbKeys) do
        if not DungeonPugsAccount[key] then
            DungeonPugsAccount[key] = var;
        end
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


function Database:AddDungeonPugFriend(info)

    local exists = false;
    for k, player in ipairs(DungeonPugsAccount.dungeonPugFriends) do
        if player.name == info.name and player.class == info.class then
            exists = true;
        end
    end

    if exists == false then
        table.insert(DungeonPugsAccount.dungeonPugFriends, info)
        addon:TriggerEvent("Database_OnDungeonPugFriendsChanged", DungeonPugsAccount.dungeonPugFriends)
    end
end


function Database:RemoveDungeonPugsFriend(info)

    local key;
    for k, player in ipairs(DungeonPugsAccount.dungeonPugFriends) do
        if player.name == info.name and player.class == info.class then
            key = k;
        end
    end

    if type(key) == "number" then
        table.remove(DungeonPugsAccount.dungeonPugFriends, key)
        addon:TriggerEvent("Database_OnDungeonPugFriendsChanged", DungeonPugsAccount.dungeonPugFriends)
    end

end

function Database:GetDungeonPugFriend(name, class)
    for k, player in ipairs(DungeonPugsAccount.dungeonPugFriends) do
        if player.name == name and player.class == class then
            return player;
        end
    end
end

function Database:GetDungeonPugsFriends(filter, sort)
    return DungeonPugsAccount.dungeonPugFriends;
end

function Database:IgnoreDungeonPugPlayer()

end


function Database:RemoveIgnoreDungeonPugPlayer()

end


function Database:GetDungeonPugsIgnorePlayers()
    
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


addon.database = Database;