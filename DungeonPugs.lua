

local addonName, addon = ...;

local AceComm = LibStub:GetLibrary("AceComm-3.0")

local Database = addon.database;
local L = addon.locales;

DungeonPugsMixin = {};

function DungeonPugsMixin:OnLoad()

    self:RegisterForDrag("LeftButton");

    self:RegisterEvent("ADDON_LOADED");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED");
    self:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED");
    self:RegisterEvent("LFG_LIST_AVAILABILITY_UPDATE");

    hooksecurefunc("UnitPopup_ShowMenu", function()

        if not IsInGroup() then
            return
        end
        if (UIDROPDOWNMENU_MENU_LEVEL > 1) then
            return;
        end

        --local dropdownMenu = _G["UIDROPDOWNMENU_INIT_MENU"]
        local dropdown = UnitPopupSharedUtil.GetCurrentDropdownMenu();

        local playerName = dropdown.name;
        local playerClass = false;

        if type(dropdown.unit) == "string" then            
            local _, class = UnitClass(dropdown.unit)
            if class then
                playerClass = class;
            end
        end


        UIDropDownMenu_AddSeparator()

        local title = UIDropDownMenu_CreateInfo();
        title.isTitle = true;
        title.text = addonName;
        title.notCheckable = true;
        UIDropDownMenu_AddButton(title);

        local addPugFriend = UIDropDownMenu_CreateInfo();
        addPugFriend.text = L.ADD_PUG_FRIEND;
        addPugFriend.notCheckable = true;
        addPugFriend.func = function()
            self:AddDungeonPugFriend(playerName, playerClass);
        end
        UIDropDownMenu_AddButton(addPugFriend);

        local ignorePugPlayer = UIDropDownMenu_CreateInfo();
        ignorePugPlayer.text = L.IGNORE_PUG_FRIEND;
        ignorePugPlayer.notCheckable = true;
        ignorePugPlayer.func = function()

        end
        UIDropDownMenu_AddButton(ignorePugPlayer);

    end)

    hooksecurefunc("SetItemRef", function(link)
        local linkType, prefix, cmd, sender = strsplit("?", link)
        if linkType == "garrmission" and prefix == "dungeonPugs" and cmd == "inviteLink" then
            InviteToGroup(sender)
        end
    end)

    self.helpIcon:SetScript("OnClick", function()
        for k, helptip in ipairs(self.lfg.helptips) do
            helptip:SetShown(not helptip:IsVisible())
        end
    end)

    PanelTemplates_SetNumTabs(self, 2);
    PanelTemplates_SetTab(self, 1);
    self.tab1:SetScript("OnClick", function()
        PanelTemplates_SetTab(self, 1);
        self.lfg:Show()
        self.pugFriends:Hide()
    end)
    self.tab2:SetScript("OnClick", function()
        PanelTemplates_SetTab(self, 2);
        self.lfg:Hide()
        self.pugFriends:Show()
    end)


    self.lfg.clearInstanceFilters:SetScript("OnClick", function()
        self.lfg.dungeonPlayersListview.DataProvider:Flush()
        self.lfg.dungeonPlayersListview.DataProvider:InsertTable(self.allPlayers or {})
        self.selectedDungeon = nil;
        self.lfg.dungeonPlayersListview.header:SetText(L.ALL_PLAYERS_HEADER)
        self:UpdateWhisperMessage()
        
        --this might be an issue
        --LFGBrowseFrameActivityDropDown.ResetButton:Click()
    end)

    self.lfg.blizzDontBreakThis:SetAttribute("macrotext1", [[/click LFGBrowseFrameRefreshButton]])

    self.lfg.roleHealer.label:SetText(CreateAtlasMarkup("groupfinder-icon-role-large-heal", 26, 26))
    self.lfg.roleTank.label:SetText(CreateAtlasMarkup("groupfinder-icon-role-large-tank", 26, 26))
    self.lfg.roleDps.label:SetText(CreateAtlasMarkup("groupfinder-icon-role-large-dps", 26, 26))


    self.lfg.roleHealer:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)
    self.lfg.roleTank:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)
    self.lfg.roleDps:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)
    self.lfg.includeInstanceName:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)
    self.lfg.includeClass:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)

    self.lfg.blizzDontBreakThis:SetText(L.REFRESH_SEARCH)
    self.lfg.clearInstanceFilters:SetText(L.CLEAR_INSTANCE_FILTER)

    self.lfg.whisperMessageInput.label:SetText(L.WHISPER_MESSAGE)
    self.lfg.includeClass.label:SetText(L.INCLUDE_CLASS)
    self.lfg.includeInstanceName.label:SetText(L.INCLUDE_INSTANCE_NAME)

    self.lfg.dungeonPlayersListview.header:SetText(L.DUNGEON_PLAYERS_HEADER)

    self.lfg.helpParent.text:SetText(L.HELP)

    self.lfg.dungeonsListviewHelp:SetText(L.HELPTIP_DUNGEON_LISTVIEW)
    self.lfg.dungeonPlayersListviewHelp:SetText(L.HELPTIP_DUNGEON_PLAYERS_LISTVIEW)
    self.lfg.configHelp:SetText(L.HELTIP_CONFIG)

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

    local isTank = self.lfg.roleTank:GetChecked()
    local isDps = self.lfg.roleDps:GetChecked()
    local isHealer = self.lfg.roleHealer:GetChecked()
    local includeClass = self.lfg.includeClass:GetChecked()
    local includeInstance = self.lfg.includeInstanceName:GetChecked()

    if (isDps == false) and (isTank == false) and (isHealer == false) and (includeClass == false) and (includeInstance == false) then
        self.lfg.whisperMessageInput:SetText("")
        return;
    end

    local dunegon = "";
    if self.selectedDungeon then
        dunegon = self.selectedDungeon.name;

        if self.selectedDungeon.isHeroic == 1 then
            dunegon = string.format("%s %s", "HC", dunegon)
        end
    end

    local msg = ""

    if includeClass then
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

    if includeInstance then
        self.lfg.whisperMessageInput:SetText(string.format("%s %s %s", msg, L.LFG, dunegon))
    else
        self.lfg.whisperMessageInput:SetText(string.format("%s %s", msg, L.LFG))
    end

    self.lfg.whisperMessageInput:SetCursorPosition(1)
end



function DungeonPugsMixin:AddDungeonPugFriend(name, class)
    StaticPopup_Show ("AddDungeonPugFriend", name, class, { 
        name = name,
        class = class,
    })
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
            "Database_OnDungeonPugFriendsChanged",
            "DungeonList_OnSelectionChanged",
            "Playerslist_OnMouseDown",
            "LFG_OnListChanged",
            "Player_OnAddDungeonPugFriend",
        });
        CallbackRegistryMixin.OnLoad(addon);

        addon:RegisterCallback("Database_OnInitialised", self.Database_OnInitialised, self);
        addon:RegisterCallback("DungeonList_OnSelectionChanged", self.DungeonList_OnSelectionChanged, self);
        addon:RegisterCallback("Playerslist_OnMouseDown", self.Playerslist_OnMouseDown, self);
        addon:RegisterCallback("LFG_OnListChanged", self.LFG_OnListChanged, self);
        addon:RegisterCallback("Player_OnAddDungeonPugFriend", self.Player_OnAddDungeonPugFriend, self);
        addon:RegisterCallback("Database_OnDungeonPugFriendsChanged", self.Database_OnDungeonPugFriendsChanged, self);

        addon.database:Init();

        AceComm:Embed(self)
        self:RegisterComm(addonName)

    end

    if event == "LFG_LIST_SEARCH_RESULT_UPDATED" then
        addon:TriggerEvent("LFG_OnListChanged")
    end

    if event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        addon:TriggerEvent("LFG_OnListChanged")
    end

    if event == "LFG_LIST_AVAILABILITY_UPDATE" then
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
            if C_LFGList.GetActiveEntryInfo() then return end;
            EasyMenu(menu, DungeonPugsInstanceDropdown, DungeonPugsInstanceDropdown, 10, 10, nil, 5.0)
        end)
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

        -- local lfgBrowseFrameWidth = LFGParentFrame:GetWidth()
        -- LFGParentFrameTab1:HookScript("OnClick", function()
        --     LFGParentFrame:SetWidth(lfgBrowseFrameWidth)
        --     LFGBrowseFrame:SetWidth(lfgBrowseFrameWidth)
        -- end)
        -- LFGParentFrameTab2:HookScript("OnClick", function()
        --     LFGParentFrame:SetWidth(lfgBrowseFrameWidth + 400)
        --     LFGBrowseFrame:SetWidth(lfgBrowseFrameWidth + 400)

        --     LFGBrowseFrameFrameBackgroundTop:Hide()
        --     LFGBrowseFrameFrameBackgroundMiddle:Hide()
        --     LFGBrowseFrameBackgroundArt:Hide()
        --     LFGBrowseFrameFrameBackgroundBottom:Hide()
        -- end)
    
        C_Timer.After(5.0, function()
            LFGParentFrameTab2:Click()
            UIDropDownMenu_SetSelectedValue(LFGBrowseFrame.CategoryDropDown, 2);
            LFGBrowseFrameRefreshButton:Click()

        end)

    end

    self.statusText:SetText(event)
end


function DungeonPugsMixin:OnCommReceived(prefix, message, distribution, sender)
    
    if prefix == addonName then
        local cmd, info = strsplit("-", message)
        if cmd == "showInviteLink" then
            self:HandleHyperlink(info, sender)
        end
    end
end



function DungeonPugsMixin:Database_OnInitialised()

    local ldb = LibStub("LibDataBroker-1.1")
    self.MinimapButton = ldb:NewDataObject('DungeonPugs', {
        type = "launcher",
        icon = 134149, --132320 134149   {136293-136316}
        OnClick = function(_, button)
            if button == "LeftButton" then
                self:SetShown(not self:IsVisible())
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(addonName)
        end,
    })
    self.MinimapIcon = LibStub("LibDBIcon-1.0")
    if not DungeonPugsAccount.minimapIcon then DungeonPugsAccount.minimapIcon = {} end
    self.MinimapIcon:Register('DungeonPugs', self.MinimapButton, DungeonPugsAccount.minimapIcon)

    self.pugFriends.friendsListview.DataProvider:InsertTable(Database:GetDungeonPugsFriends())

end


function DungeonPugsMixin:Player_OnAddDungeonPugFriend(name, class, note)
    
    Database:AddDungeonPugFriend({
        name = name,
        class = class,
        note = note,
    })
end


function DungeonPugsMixin:Database_OnDungeonPugFriendsChanged(data)

    self.pugFriends.friendsListview.DataProvider:Flush()
    self.pugFriends.friendsListview.DataProvider:InsertTable(data)
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
        self.lfg.dungeonsListview.DataProvider:Flush()

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
    
                                else
    
                                    -- table.insert(v.players, {
                                    --     name = name,
                                    --     role = role,
                                    --     class = class,
                                    --     level = level,
                                    --     zone = "-",
                                    --     inGroup = true,
                                    --     groupLeader = leaderName,
                                    --     isLeader = false,
                                    -- })
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

                            else

                                -- table.insert(players, {
                                --     name = name,
                                --     role = role,
                                --     class = class,
                                --     level = level,
                                --     zone = "-",
                                --     inGroup = true,
                                --     groupLeader = leaderName,
                                --     isLeader = false,
                                -- })
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
    
        self.lfg.dungeonsListview.DataProvider:InsertTable(dungeons)

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

        --update the dungeon specific list, if the user chose one...
        if self.selectedDungeon then

            for k, dungeon in ipairs(dungeons) do
                
                if dungeon.name == self.selectedDungeon.name and dungeon.isHeroic == self.selectedDungeon.isHeroic then
                    self:DungeonList_OnSelectionChanged(dungeon)
                end
            end

        else
            self.lfg.dungeonPlayersListview.DataProvider:Flush()
            self.lfg.dungeonPlayersListview.DataProvider:InsertTable(self.allPlayers or {})
            self.lfg.dungeonPlayersListview.header:SetText(L.ALL_PLAYERS_HEADER)
        end

        --good to knwo when we last got an update
        self.lfgUpdateTime = time()

    end)


end


function DungeonPugsMixin:DungeonList_OnSelectionChanged(info)

    self.selectedDungeon = info;

    if info.isHeroic == 1 then
        self.lfg.dungeonPlayersListview.header:SetText(L.DUNGEON_PLAYERS_HEADER_HC:format(info.name))
    else
        self.lfg.dungeonPlayersListview.header:SetText(L.DUNGEON_PLAYERS_HEADER:format(info.name))
    end
    
    self.lfg.dungeonPlayersListview.DataProvider:Flush()

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

    self.lfg.dungeonPlayersListview.DataProvider:InsertTable(info.players)

    self:UpdateWhisperMessage()
end


function DungeonPugsMixin:Playerslist_OnMouseDown(button, player)

    if button == "LeftButton" then
        
        if IsAltKeyDown() and not IsShiftKeyDown() then

            if type(player.name) == "string" then
                InviteToGroup(player.name)
            end

        elseif IsShiftKeyDown() and not IsAltKeyDown() then
           
            local msg = self.lfg.whisperMessageInput:GetText();
            if msg ~= "" then
                --SendChatMessage(msg, "WHISPER", nil, player.name)
            end

            local link = string.format("|cFFFFFF00|Hgarrmission?%s?%s|h[invite]|h|r", addonName, msg)

            --SendChatMessage(link, "WHISPER", nil, "Kylandia")
            --C_ChatInfo.SendAddonMessageLogged(link, "WHISPER", nil, "Kylandia")

            self:SendCommMessage(addonName, string.format("showInviteLink-%s", msg), "WHISPER", "Kylandia")

        end
    end
end



function DungeonPugsMixin:HandleHyperlink(msg, sender)
    local link = string.format("|cFFFFFF00|Hgarrmission?dungeonPugs?inviteLink?%s|h|cffDD66FF[%s]|r |cffffffff%s|r [%s]|h|r", sender, addonName, msg, L.LINK_INVITE)
    print(link)
end
