local addonName, addon = ...;

local MAJOR = "LibLFG-1.0";
local MINOR = 1;

if not LibStub then
    error(MAJOR .. " requires LibStub.") 
end
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then
    return
end

if not lib.GenerateCallbackEvents then
    Mixin(lib, CallbackRegistryMixin)
    lib:GenerateCallbackEvents({
        "LibLFG_OnListChanged",
    })
    CallbackRegistryMixin.OnLoad(lib);
end

local dungeons = {};
local allPlayers = {};

local function lfgList_OnChanged()

    dungeons = {};
    allPlayers = {};

    --get the filtered results
    local _, filteredResults = C_LFGList.GetFilteredSearchResults();

    --loop each item in the filtered results
    for k, v in ipairs(filteredResults) do
        local searchResultData = C_LFGList.GetSearchResultInfo(v)

        local isNewbieFriendly = searchResultData.newPlayerFriendly;

        --ignore the listing if it was delisted, nobody wants those
        if not searchResultData.isDelisted then

            --loop the activities (dungeons)
            for k, v in ipairs(searchResultData.activityIDs) do

                --get the activity info
                local activity = C_LFGList.GetActivityInfoTable(v)

                --print(activity.fullName, activity.groupFinderActivityGroupID)

                --set the name and is heroic variables
                local fullName = activity.fullName;    
                local isHeroic = 0;
                if activity.groupFinderActivityGroupID == 289 then --wrath hc
                    isHeroic = 1;
                end
                if activity.groupFinderActivityGroupID == 288 then --tbc hc
                    isHeroic = 1;
                end

                --lets not duplicate things, see if it exists first!
                local exists = false;
                for k, v in ipairs(dungeons) do

                    local isGroup;

                    --look for a matching dungeon entry
                    if (v.name == fullName) and (v.isHeroic == isHeroic) then
        
                        --lets check we have somewhere to store player data....
                        if not v.players then
                            v.players = {}
                        end

                        --upvalue this, leaders are important in groups
                        local leaderName = ""

                        --is this a group?
                        isGroup = searchResultData.numMembers > 1 and true or false;

                        local groupMembers = {};

                        --loop the listing members (or member)
                        for i = 1, searchResultData.numMembers do

                            --finally some dirt on the players, a GUID would be awesome in here Blizzard!
                            local name, role, class, _, level, isLeader = C_LFGList.GetSearchResultMemberInfo(searchResultData.searchResultID, i)

                            if isGroup then
                                table.insert(groupMembers, {
                                    name = name,
                                    class = class,
                                    role = role,
                                    level = level,
                                })
                            end

                            --leaders get special treatment
                            if isLeader then
                                
                                local name, _role, class, _, level, zone, tank, healer, dps = C_LFGList.GetSearchResultLeaderInfo(searchResultData.searchResultID)

                                leaderName = name;

                                local role = _role; --fallback role
    
                                --prio tank > healer > dps
                                if tank then
                                    role = "TANK"
                                elseif healer then
                                    role = "HEALER"
                                elseif dps then
                                    role = "DAMAGER"
                                end
        
                                if role then
                                    table.insert(v.players, {
                                        name = name,
                                        role = role,
                                        class = class,
                                        level = level,
                                        roles = {
                                            tank = tank,
                                            healer = healer,
                                            dps = dps,
                                        },
                                        zone = zone,
                                        isLeader = true,
                                        isNewbieFriendly = isNewbieFriendly,
                                        inGroup = isGroup,
                                    })
                                end
                            end
        
                        end

                        if isGroup then
                            for k, player in ipairs(v.players) do
                                if player.isLeader then
                                    player.groupMembers = groupMembers;
                                end
                            end
                        end
                        exists = true;
                    end
                end

                --add new dungeon, follow above comments as its the same code
                if exists == false then

                    local players = {}

                    local leaderName = ""

                    local groupMembers = {}

                    local isGroup;

                    for i = 1, searchResultData.numMembers do

                        local name, role, class, _, level, isLeader = C_LFGList.GetSearchResultMemberInfo(searchResultData.searchResultID, i)

                        isGroup = searchResultData.numMembers > 1 and true or false;

                        if isGroup then
                            table.insert(groupMembers, {
                                name = name,
                                class = class,
                                role = role,
                                level = level,
                            })
                        end

                        if isLeader then
                            
                            local name, _role, class, _, level, zone, tank, healer, dps = C_LFGList.GetSearchResultLeaderInfo(searchResultData.searchResultID)

                            leaderName = name;

                            local role = _role; --fallback role

                            --prio tank > healer > dps
                            if tank then
                                role = "TANK"
                            elseif healer then
                                role = "HEALER"
                            elseif dps then
                                role = "DAMAGER"
                            end
    
                            if role then
                                table.insert(players, {
                                    name = name,
                                    role = role,
                                    class = class,
                                    level = level,
                                    roles = {
                                        tank = tank,
                                        healer = healer,
                                        dps = dps,
                                    },
                                    zone = zone,
                                    isLeader = true,
                                    isNewbieFriendly = isNewbieFriendly,
                                    inGroup = isGroup,
                                })
                            end
                        end

                    end

                    if isGroup then
                        for k, player in ipairs(players) do
                            if player.isLeader then
                                player.groupMembers = groupMembers;
                            end
                        end
                    end

                    table.insert(dungeons, {
                        name = fullName,
                        isHeroic = isHeroic,
                        players = players,
                    })
                end
            end

        end
    end

    --heroic dungeons should be above normals
    table.sort(dungeons, function(a, b)
        if a.isHeroic == b.isHeroic then
            return a.name < b.name;
        else
            return a.isHeroic > b.isHeroic;
        end
    end)


    --a place for everyone
    allPlayers = {};
    local playersSeen = {};
    for k, dungeon in ipairs(dungeons) do
        for k, player in ipairs(dungeon.players) do

            if type(player) == "table" and player.name ~= nil then

                if not playersSeen[player.name] then
                    playersSeen[player.name] = true;

                    table.insert(allPlayers, player)
                end

            end
        end
    end

    for k, player in ipairs(allPlayers) do
        
        player.activities = {}

        for k, dungeon in ipairs(dungeons) do
            for k, member in ipairs(dungeon.players) do
                if member.name == player.name then
                    table.insert(player.activities, {
                        name = dungeon.name,
                        isHeroic = dungeon.isHeroic,
                    })
                end
            end
        end
    end

    --crowds need sorting out
    table.sort(allPlayers, function(a, b)
        if a.inGroup == b.inGroup then

            if a.isLeader == b.isLeader then

                if a.groupLeader == b.groupLeader then

                    if a.role == b.role then
                    
                        if a.level == b.level then
                            return a.name < b.name
                        else
                            return a.level > b.level
                        end

                    else

                        return a.role > b.role
                    end

                else

                    return a.groupLeader < b.groupLeader
                end
            else
                return a.isLeader and not b.isLeader
            end

        else
            if a.inGroup ~= nil and b.inGroup ~= nil then
                return a.inGroup and not b.inGroup
            end
        end
    end)

    lib:TriggerEvent("LibLFG_OnListChanged", dungeons, allPlayers)
end


--this function relies on being able to click the lfg refresh button
--its very likely blizzard will remove this ability
--if so lib users will need to handle refreshing the list themselves - a SecureActionButtonTemplate button should allow a macro to click the button
function lib:GetSearchResults(categoryID)
    
    UIDropDownMenu_SetSelectedValue(LFGBrowseFrame.CategoryDropDown, categoryID);
    
    --this might require a magic button
    LFGBrowseFrameRefreshButton:Click()

    lfgList_OnChanged()
    return dungeons, allPlayers;
end


local f = CreateFrame("Frame");
f:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED");
f:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED");
f:RegisterEvent("LFG_LIST_AVAILABILITY_UPDATE");

f:SetScript("OnEvent", lfgList_OnChanged)