

local name, addon = ...;

local L = addon.locales;

DungeonPugsMixin = {};

function DungeonPugsMixin:OnLoad()

    self:RegisterForDrag("LeftButton");

    self:RegisterEvent("ADDON_LOADED");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED");
    self:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED");

    self.helpIcon:SetScript("OnClick", function()
        for k, helptip in ipairs(self.helptips) do
            helptip:SetShown(not helptip:IsVisible())
        end
    end)

    self.clearInstanceFilters:SetScript("OnClick", function()
        self.dungeonPlayersListview.DataProvider:Flush()
        self.dungeonPlayersListview.DataProvider:InsertTable(self.allPlayers or {})
        self.selectedDungeon = nil;
        self.dungeonPlayersListview.header:SetText(L.ALL_PLAYERS_HEADER)
        self:UpdateWhisperMessage()
    end)

    self.blizzDontBreakThis:SetAttribute("macrotext1", [[/click LFGBrowseFrameRefreshButton]])

    self.roleHealer.label:SetText(CreateAtlasMarkup("groupfinder-icon-role-large-heal", 26, 26))
    self.roleTank.label:SetText(CreateAtlasMarkup("groupfinder-icon-role-large-tank", 26, 26))
    self.roleDps.label:SetText(CreateAtlasMarkup("groupfinder-icon-role-large-dps", 26, 26))


    self.roleHealer:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)
    self.roleTank:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)
    self.roleDps:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)
    self.includeInstanceName:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)
    self.includeClass:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)

    self.blizzDontBreakThis:SetText(L.REFRESH_SEARCH)
    self.clearInstanceFilters:SetText(L.CLEAR_INSTANCE_FILTER)

    self.whisperMessageInput.label:SetText(L.WHISPER_MESSAGE)
    self.includeClass.label:SetText(L.INCLUDE_CLASS)
    self.includeInstanceName.label:SetText(L.INCLUDE_INSTANCE_NAME)

    self.dungeonPlayersListview.header:SetText(L.DUNGEON_PLAYERS_HEADER)

    self.help:SetText(L.HELP)

    self.dungeonsListviewHelp:SetText(L.HELPTIP_DUNGEON_LISTVIEW)
    self.dungeonPlayersListviewHelp:SetText(L.HELPTIP_DUNGEON_PLAYERS_LISTVIEW)
    self.configHelp:SetText(L.HELTIP_CONFIG)


    local categories = C_LFGList.GetAvailableCategories()
    local menu = {}
    for k, categoryID in ipairs(categories) do
        local category = C_LFGList.GetCategoryInfo(categoryID)
        table.insert(menu, {
            text = category,
            isTitle = false,
            notCheckable = true,
            func = function()
                UIDropDownMenu_SetText(DungeonPugsInstanceDropdown, category)
                UIDropDownMenu_SetSelectedValue(LFGBrowseFrame.CategoryDropDown, categoryID);
                LFGBrowseFrameRefreshButton:Click()
            end
        })
    end
    DungeonPugsInstanceDropdownButton:SetScript("OnClick", function()
        EasyMenu(menu, DungeonPugsInstanceDropdown, DungeonPugsInstanceDropdown, 10, 10, nil, 5.0)
    end)

--ldfgbrowseframesearchungspinner


    --i had to remove this as blizzard fixed/broke the ability to auto refresh the lfg list
    -- _G[self.refreshTimer:GetName().."Low"]:SetText("5")
    -- _G[self.refreshTimer:GetName().."High"]:SetText("300")

    -- _G[self.refreshTimer:GetName().."Text"]:SetText(30)
    -- self.refreshTimer:SetValue(30)

    -- self.refreshTimer:SetScript("OnMouseWheel", function(self, delta)
    --     self:SetValue(self:GetValue() + delta)
    -- end)
    -- self.refreshTimer:SetScript("OnValueChanged", function()
    --     _G[self.refreshTimer:GetName().."Text"]:SetText(string.format("%.0f", self.refreshTimer:GetValue()))
    -- end)

end

function DungeonPugsMixin:UpdateWhisperMessage()

    local isTank = self.roleTank:GetChecked()
    local isDps = self.roleDps:GetChecked()
    local isHealer = self.roleHealer:GetChecked()

    local dunegon = "";
    if self.selectedDungeon then
        dunegon = self.selectedDungeon.name;

        if self.selectedDungeon.isHeroic == 1 then
            dunegon = string.format("%s %s", "HC", dunegon)
        end
    end

    local msg = L.HELLO

    if self.includeClass:GetChecked() == true then
        msg = string.format("%s %s", msg, UnitClass("player"))
    end

    if isTank then
        msg = string.format("%s %s", msg, L.TANK)
    end
    if isHealer then
        msg = string.format("%s %s", msg, L.HEALER)
    end
    if isDps then
        msg = string.format("%s %s", msg, L.DPS)
    end

    if self.includeInstanceName:GetChecked() == true then
        self.whisperMessageInput:SetText(string.format("%s %s %s", msg, L.LFG, dunegon))
    else
        self.whisperMessageInput:SetText(string.format("%s %s", msg, L.LFG))
    end

    self.whisperMessageInput:SetCursorPosition(1)
end

local onUpdateElapsed = 0
function DungeonPugsMixin:OnUpdate(elapsed)

    onUpdateElapsed = onUpdateElapsed + elapsed;

    if self.lfgUpdateTime then

        local refreshElapsed = time() - self.lfgUpdateTime;

        self.lastUpdatedInfo:SetText(string.format("Last updated %s", SecondsToTime(refreshElapsed))) -- date("%H:%M:%S", elapsed)))

    end
    
end

function DungeonPugsMixin:OnEvent(event, ...)

    if event == "ADDON_LOADED" then
        
        self:UnregisterEvent("ADDON_LOADED");

        Mixin(addon, CallbackRegistryMixin)
        addon:GenerateCallbackEvents({
            "Database_OnInitialised",
            "DungeonList_OnSelectionChanged",
            "Playerslist_OnMouseDown",
            "LFG_OnListChanged",
        });
        CallbackRegistryMixin.OnLoad(addon);

        addon:RegisterCallback("Database_OnInitialised", self.Database_OnInitialised, self);
        addon:RegisterCallback("DungeonList_OnSelectionChanged", self.DungeonList_OnSelectionChanged, self);
        addon:RegisterCallback("Playerslist_OnMouseDown", self.Playerslist_OnMouseDown, self);
        addon:RegisterCallback("LFG_OnListChanged", self.LFG_OnListChanged, self);

        addon.db:Init();

    end

    if event == "LFG_LIST_SEARCH_RESULT_UPDATED" then
        addon:TriggerEvent("LFG_OnListChanged")
    end

    if event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        addon:TriggerEvent("LFG_OnListChanged")
    end

    if event == "PLAYER_ENTERING_WORLD" then

        local name, realm = UnitFullName("player");
        if realm == nil or realm == "" then
            realm = GetNormalizedRealmName();
        end
        local nameRealm = string.format("%s-%s", name, realm);

        self:UnregisterEvent("PLAYER_ENTERING_WORLD");

        LoadAddOn("Blizzard_LookingForGroupUI")
        LFGBrowseFrame:HookScript("OnShow", function()
            self:LFG_OnListChanged()
        end)
    
        C_Timer.After(5.0, function()
            LFGParentFrameTab2:Click()
            UIDropDownMenu_SetSelectedValue(LFGBrowseFrame.CategoryDropDown, 2);
            LFGBrowseFrameRefreshButton:Click()
        end)

    end

    self.statusText:SetText(event)
end

function DungeonPugsMixin:Database_OnInitialised()

    local ldb = LibStub("LibDataBroker-1.1")
    self.MinimapButton = ldb:NewDataObject('DungeonPugs', {
        type = "launcher",
        icon = 134068,
        OnClick = function(_, button)
            if button == "LeftButton" then
                self:Show()
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
    
        end,
    })
    self.MinimapIcon = LibStub("LibDBIcon-1.0")
    if not DungeonPugsAccount.minimapIcon then DungeonPugsAccount.minimapIcon = {} end
    self.MinimapIcon:Register('DungeonPugs', self.MinimapButton, DungeonPugsAccount.minimapIcon)
    
end



--so the idea here is to grab all the data baout players and dungeons from the LFG system
--its awkward
--first get the search results - but use the filtered stuff (its healthier for you)
--then loop each search result and grab the activities (dungeons)
--then loop the dungeons and grab info about heroic and dungeon name
--also get the players listed (solo or groups)
--then whack it all in a couple of tables
function DungeonPugsMixin:LFG_OnListChanged()

    --a slight delay is sometimes useful!
    C_Timer.After(1.0, function()

        --clear the old listview data
        self.dungeonsListview.DataProvider:Flush()

        --get the filtered results
        local _, filteredResults = C_LFGList.GetFilteredSearchResults();
    
        --create dungeon table
        local dungeons = {};
    
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
    
                    --set the name and is heroic variables
                    local fullName = activity.fullName;    
                    local isHeroic = activity.groupFinderActivityGroupID == 289 and 1 or 0;
    
                    --lets not duplicate things, see if it exists first!
                    local exists = false;
                    for k, v in ipairs(dungeons) do
    
                        --look for a matching dungeon entry
                        if (v.name == fullName) and (v.isHeroic == isHeroic) then
            
                            --lets check we have somewhere to store player data....
                            if not v.players then
                                v.players = {}
                            end

                            --upvalue this, leaders are important in groups
                            local leaderName = ""
    
                            --loop the listing members (or member)
                            for i = 1, searchResultData.numMembers do

                                --is this a group?
                                local isGroup = searchResultData.numMembers > 1 and true or false;

                                --finally some dirt on the players, a GUID would be awesome in here Blizzard!
                                local name, role, class, _, level, isLeader = C_LFGList.GetSearchResultMemberInfo(searchResultData.searchResultID, i)
    
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
    
                                else
    
                                    table.insert(v.players, {
                                        name = name,
                                        role = role,
                                        class = class,
                                        level = level,
                                        zone = "-",
                                        inGroup = true,
                                        groupLeader = leaderName,
                                        isLeader = false,
                                    })
                                end
            
                            end
                            exists = true;
                        end
                    end
    
                    --add new dungeon, follow above comments as its the same code
                    if exists == false then
    
                        local players = {}

                        local leaderName = ""

                        for i = 1, searchResultData.numMembers do

                            local name, role, class, _, level, isLeader, a, b, c, d, e, f, g = C_LFGList.GetSearchResultMemberInfo(searchResultData.searchResultID, i)

                            local isGroup = searchResultData.numMembers > 1 and true or false;

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

                            else

                                table.insert(players, {
                                    name = name,
                                    role = role,
                                    class = class,
                                    level = level,
                                    zone = "-",
                                    inGroup = true,
                                    groupLeader = leaderName,
                                    isLeader = false,
                                })
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
    
        self.dungeonsListview.DataProvider:InsertTable(dungeons)

        --a thing for everyone
        self.allPlayers = {};
        local playersSeen = {};
        for k, dungeon in ipairs(dungeons) do
            for k, player in ipairs(dungeon.players) do

                if type(player) == "table" and player.name ~= nil then

                    if not playersSeen[player.name] then
                        playersSeen[player.name] = true;

                        table.insert(self.allPlayers, player)
                    end

                end
            end
        end

        --crowds need sorting out
        table.sort(self.allPlayers, function(a, b)
            if a.role == b.role then

                if a.isLeader == b.isLeader then
                    if a.level == b.level then
                        return a.name < b.name
                    else
                        return a.level > b.level
                    end
                else
                    return a.isLeader and not b.isLeader
                end
            else
                if a.role ~= nil and b.role ~= nil then
                    return a.role > b.role
                end
            end
        end)

        --update the dungeon specific list, if the user chose one...
        if self.selectedDungeon then

            for k, dungeon in ipairs(dungeons) do
                
                if dungeon.name == self.selectedDungeon.name and dungeon.isHeroic == self.selectedDungeon.isHeroic then
                    self:DungeonList_OnSelectionChanged(dungeon)
                end
            end

        else
            self.dungeonPlayersListview.DataProvider:Flush()
            self.dungeonPlayersListview.DataProvider:InsertTable(self.allPlayers or {})
            self.dungeonPlayersListview.header:SetText(L.ALL_PLAYERS_HEADER)
        end

        --good to knwo when we last got an update
        self.lfgUpdateTime = time()

    end)


end


function DungeonPugsMixin:DungeonList_OnSelectionChanged(info)

    self.selectedDungeon = info;

    if info.isHeroic == 1 then
        self.dungeonPlayersListview.header:SetText(L.DUNGEON_PLAYERS_HEADER_HC:format(info.name))
    else
        self.dungeonPlayersListview.header:SetText(L.DUNGEON_PLAYERS_HEADER:format(info.name))
    end
    
    self.dungeonPlayersListview.DataProvider:Flush()

    table.sort(info.players, function(a, b)
        if a.role == b.role then

            if a.isLeader == b.isLeader then
                if a.level == b.level then
                    return a.name < b.name
                else
                    return a.level > b.level
                end
            else
                return a.isLeader and not b.isLeader
            end
        else
            if a.role ~= nil and b.role ~= nil then
                return a.role > b.role
            end
        end
    end)

    self.dungeonPlayersListview.DataProvider:InsertTable(info.players)

    self:UpdateWhisperMessage()
end


function DungeonPugsMixin:Playerslist_OnMouseDown(button, player)

    if button == "LeftButton" then
        
        if IsAltKeyDown() then

            InviteToGroup()
        else
            local msg = self.whisperMessageInput:GetText();
            if msg ~= "" then
                SendChatMessage(msg, "WHISPER", nil, player.name)
            end
        end

    elseif button == "RightButton" then

        SendChatMessage("boo", "WHISPER", nil, "Silvessa")
    end
end