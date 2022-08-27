

local addonName, addon = ...;

addon.Colours = {}

for k, v in pairs(RAID_CLASS_COLORS) do
    addon.Colours[k] = CreateColor(v:GetRGB())
end

local LibLFG = LibStub:GetLibrary("LibLFG-1.0")

local L = addon.locales;

DungeonPugsMixin = {};
DungeonPugsMixin.allPlayers = {};
DungeonPugsMixin.selectedDungeon = nil;

function DungeonPugsMixin:OnLoad()

    self:SetBackdropColor(1,1,1,1)

    self:RegisterForDrag("LeftButton");

    self:RegisterEvent("ADDON_LOADED")

    Mixin(addon, CallbackRegistryMixin)
    addon:GenerateCallbackEvents({
        "Playerslist_OnMouseDown"
    })
    CallbackRegistryMixin.OnLoad(addon);

    addon:RegisterCallback("Playerslist_OnMouseDown", self.Playerslist_OnMouseDown, self)

    LibLFG:RegisterCallback("LibLFG_OnListChanged", self.LFG_OnListChanged, self)

    self.roleSelectTank.background:SetTexCoord(GetBackgroundTexCoordsForRole("TANK"))
    self.roleSelectTank.icon:SetTexCoord(0.0, 0.25, 0.25, 0.5)
    self.roleSelectTank.checkbox:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)

    self.roleSelectHealer.background:SetTexCoord(GetBackgroundTexCoordsForRole("HEALER"))
    self.roleSelectHealer.icon:SetTexCoord(0.25, 0.5, 0.0, 0.25)
    self.roleSelectHealer.checkbox:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)

    self.roleSelectDps.background:SetTexCoord(GetBackgroundTexCoordsForRole("DAMAGER"))
    self.roleSelectDps.icon:SetTexCoord(0.25, 0.5, 0.25, 0.5)
    self.roleSelectDps.checkbox:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)

    self.includeInstanceName:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)
    self.includeClass:SetScript("OnClick", function()
        self:UpdateWhisperMessage()
    end)

    UIDropDownMenu_SetWidth(DungeonPugsInstanceDropdown, 135)
    DungeonPugsInstanceDropdownButton:SetScript("OnClick", function()
        if C_LFGList.GetActiveEntryInfo() then
            --return 
        end;

        local dungeons = LibLFG:GetSearchResults(2)
        local menu = {
            {
                text = "Clear Filters",
                notCheckable = true,
                func = function()
                    UIDropDownMenu_SetText(DungeonPugsInstanceDropdown, "-")
                    self.selectedDungeon = nil;
                    self:ShowFilteredResults()
                end,
            }
        }

        for k, dungeon in ipairs(dungeons) do
            local name = (dungeon.isHeroic == 1) and string.format("%s %s", CreateAtlasMarkup("dungeonskull", 16, 16), dungeon.name) or dungeon.name
            table.insert(menu, {
                text = name,
                notCheckable = true,
                func = function()
                    UIDropDownMenu_SetText(DungeonPugsInstanceDropdown, name)
                    self.selectedDungeon = dungeon;
                    self:ShowFilteredResults()
                end,
            })
        end

        EasyMenu(menu, DungeonPugsInstanceDropdown, DungeonPugsInstanceDropdown, 20, 10, nil, 1.5)
    end)


    UIDropDownMenu_SetWidth(DungeonPugsClassDropdown, 85)
    local classRoleCheck = {
        TANK = {
            DEATHKNIGHT = true,
            PALADIN = true,
            DRUID = true,
            WARRIOR = true,
        },
        HEALER = {
            DRUID = true,
            PRIEST = true,
            PALADIN = true,
            SHAMAN = true,
        },
        DAMAGER = {
            DRUID = true,
            PRIEST = true,
            PALADIN = true,
            SHAMAN = true,
            HUNTER = true,
            MAGE = true,
            WARRIOR = true,
            WARLOCK = true,
            ROGUE = true,
            DEATHKNIGHT = true,
        },
    }
    local classMenulist = {}
    for _, role in ipairs({"TANK", "HEALER", "DAMAGER"}) do
        classMenulist[role] = {}
        for i = 1, GetNumClasses() do
            local className, classFile, classID = GetClassInfo(i)
            if className and classFile then
                if classRoleCheck[role] and classRoleCheck[role][classFile] == true then
                    local atlas = CreateAtlasMarkup(string.format("GarrMission_ClassIcon-%s", classFile:lower()), 18, 18)
                    table.insert(classMenulist[role], {
                        text = string.format("%s %s", atlas, className),
                        notCheckable = true,
                        func = function()
                            UIDropDownMenu_SetText(DungeonPugsClassDropdown, className)
                            self.selectedClass = classFile;
                            self.selectedRole = role,
                            self:ShowFilteredResults()
                        end,
                    })
                end
            end
        end        
    end

    local menu = {
        {
            text = "All",
            notCheckable = true,
            func = function()
                UIDropDownMenu_SetText(DungeonPugsClassDropdown, "All")
                self.selectedClass = nil;
                self.selectedRole = nil;
                self:ShowFilteredResults()
            end,
        },
        {
            text = "Role",
            notCheckable = true,
            menuList = {
                {
                    text = string.format("%s %s", CreateAtlasMarkup("groupfinder-icon-role-large-tank", 18, 18), L.TANK),
                    notCheckable = true,
                    hasArrow = true,
                    menuList = classMenulist.TANK,
                    func = function()
                        UIDropDownMenu_SetText(DungeonPugsClassDropdown, L.TANK)
                        self.selectedRole = "TANK";
                        self:ShowFilteredResults()
                    end,
                },
                {
                    text = string.format("%s %s", CreateAtlasMarkup("groupfinder-icon-role-large-heal", 18, 18), L.HEALER),
                    notCheckable = true,
                    hasArrow = true,
                    menuList = classMenulist.HEALER,
                    func = function()
                        UIDropDownMenu_SetText(DungeonPugsClassDropdown, L.HEALER)
                        self.selectedRole = "HEALER";
                        self:ShowFilteredResults()
                    end,
                },
                {
                    text = string.format("%s %s", CreateAtlasMarkup("groupfinder-icon-role-large-dps", 18, 18), L.DPS),
                    notCheckable = true,
                    hasArrow = true,
                    menuList = classMenulist.DAMAGER,
                    func = function()
                        UIDropDownMenu_SetText(DungeonPugsClassDropdown, L.DPS)
                        self.selectedRole = "DAMAGER";
                        self:ShowFilteredResults()
                    end,
                },
            },
            hasArrow = true,
        },
    }

    DungeonPugsClassDropdownButton:SetScript("OnClick", function()
        EasyMenu(menu, DungeonPugsClassDropdown, DungeonPugsClassDropdown, 20, 10, nil, 1.5)
    end)

    self.refresh:SetAttribute("macrotext1", [[/click LFGBrowseFrameRefreshButton]])
    self.refresh:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.refresh, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L.REFRESH_SEARCH)
        GameTooltip:Show()
    end)
    self.refresh:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)

    self.helptipTop:SetText(L.HELP_TOP)
    self.helptipBottom:SetText(L.HELP_BOTTOM)
    self.help:SetScript("OnClick", function()
        for k, tip in ipairs(self.helptips) do
            tip:SetShown(not tip:IsVisible())
        end
    end)
end

function DungeonPugsMixin:OnShow()
    LibLFG:GetSearchResults(2)
end

function DungeonPugsMixin:UpdateWhisperMessage()

    local isTank = self.roleSelectTank.checkbox:GetChecked()
    local isDps = self.roleSelectDps.checkbox:GetChecked()
    local isHealer = self.roleSelectHealer.checkbox:GetChecked()
    local includeClass = self.includeClass:GetChecked()
    local includeInstance = self.includeInstanceName:GetChecked()

    if (isDps == false) and (isTank == false) and (isHealer == false) and (includeClass == false) and (includeInstance == false) then
        self.whisperMessageInput:SetText("")
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
        self.lastUpdatedInfo:SetText(string.format(L.LAST_UPDATED, SecondsToTime(refreshElapsed)))
    end
end

function DungeonPugsMixin:OnEvent(event, ...)

    if event == "ADDON_LOADED" then
        
        self:UnregisterEvent("ADDON_LOADED");

        local ldb = LibStub("LibDataBroker-1.1")
        self.DataObject = ldb:NewDataObject(addonName, {
            type = "launcher",
            icon = 134149, --132320 134149   {136293-136316}
            OnClick = function(ldbIcon, button)
                if button == "LeftButton" then
                    self:SetShown(not self:IsVisible())
                    self:ClearAllPoints()
                    self:SetPoint("TOPRIGHT", ldbIcon, "TOPLEFT", 0, 0)
                end
            end,
            OnEnter = function()
                if self.minimapButton then
                    self.minimapButton.animation:Stop()
                end
            end,
        })
    
        if not DungeonPugsAccount.minimapIcon then DungeonPugsAccount.minimapIcon = {} end
        LibStub("LibDBIcon-1.0"):Register(addonName, self.DataObject, DungeonPugsAccount.minimapIcon)
        
    end

end


--going to leave this here in case it gets implemented in the future
function DungeonPugsMixin:AddMinimapSparkles()
    
    local button = LibStub:GetLibrary("LibDBIcon-1.0"):GetMinimapButton(addonName)
    if button then
        
        button.glow = button:CreateTexture(nil, "BACKGROUND")
        button.glow:SetPoint("TOPLEFT", 0, 0)
        button.glow:SetPoint("BOTTOMRIGHT", -1, 1)
        button.glow:SetAlpha(0)

        button.glow:SetAtlas("ShipMission-RedGlowRing") --ArtifactsFX-YellowRing   ShipMission-RedGlowRing Darktrait-Glow 
    
        button.animation = button:CreateAnimationGroup()
        button.animation:SetLooping("REPEAT")

        local duration = 0.6;
        local scaleTo = 1.8;
        
        button.animFade = button.animation:CreateAnimation("Alpha")
        button.animFade:SetFromAlpha(0)
        button.animFade:SetToAlpha(1)
        button.animFade:SetDuration(duration-0.1)
        button.animFade:SetStartDelay(0.1)
        button.animFade:SetSmoothing("OUT")
        button.animFade:SetChildKey("glow")

        button.animScale = button.animation:CreateAnimation("Scale")
        button.animScale:SetFromScale(1, 1)
        button.animScale:SetToScale(scaleTo, scaleTo)
        button.animScale:SetDuration(duration)
        button.animScale:SetChildKey("glow")

        self.minimapButton = button;
    end
end



function DungeonPugsMixin:ShowFilteredResults()
    self.dungeonPlayersListview.DataProvider:Flush()

    local players = type(self.selectedDungeon) == "table" and self.selectedDungeon.players or self.allPlayers;

    local t = {}
    if self.selectedRole then

        if self.selectedClass then

            for k, player in ipairs(players) do
                if player.class and (player.class == self.selectedClass) and player.role and (player.role == self.selectedRole) then
                    table.insert(t, player)
                end
            end
        
        else
            for k, player in ipairs(players) do
                if player.role and (player.role == self.selectedRole) then
                    table.insert(t, player)
                end
            end
        end

    else

        if self.selectedClass then

            for k, player in ipairs(players) do
                if player.class and (player.class == self.selectedClass) then
                    table.insert(t, player)
                end
            end
        
        else
            t = players;
        end
    end


    self.dungeonPlayersListview.DataProvider:InsertTable(t)
    self:UpdateWhisperMessage()
end



function DungeonPugsMixin:LFG_OnListChanged(dungeons, allPlayers)

    --update our variables
    self.dungeons = dungeons;
    self.allPlayers = allPlayers;

    self:ShowFilteredResults()

    self.lfgUpdateTime = time()

end



function DungeonPugsMixin:DungeonList_OnSelectionChanged(info)

    self.selectedDungeon = info;
    
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


function DungeonPugsMixin:Playerslist_OnMouseDown(player)


    local msg = self.whisperMessageInput:GetText();
        
    if IsAltKeyDown() and not IsShiftKeyDown() and not IsControlKeyDown() then

        if type(player.name) == "string" then
            InviteToGroup(player.name)
        end

    elseif IsShiftKeyDown() and not IsAltKeyDown() and not IsControlKeyDown() then
       
        if msg ~= "" then
            SendChatMessage(msg, "WHISPER", nil, player.name)
        end

    end
end


--potential feature for later on
function DungeonPugsMixin:HandleHyperlink(msg, sender)
    local link = string.format("|cFFFFFF00|Hgarrmission?dungeonPugs?inviteLink?%s|h|cffDD66FF[%s]|r |cffffffff%s|r [%s]|h|r", sender, addonName, msg, L.LINK_INVITE)
    print(link)
end



