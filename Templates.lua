

local addonName, addon = ...;

local L = addon.locales

DungeonPugsHelpTipMixin = {};
function DungeonPugsHelpTipMixin:SetText(text)
    self.text:SetText(text)
end
function DungeonPugsHelpTipMixin:OnShow()

end

DungeonPugsListviewMixin = {}

function DungeonPugsListviewMixin:OnLoad()

    ---these values are set in the xml frames KeyValues, it allows us to reuse code by setting listview item values in xml
    -- if type(self.itemTemplate) ~= "string" then
    --     error("self.itemTemplate name not set or not of type string")
    --     return;
    -- end
    -- if type(self.frameType) ~= "string" then
    --     error("self.frameType not set or not of type string")
    --     return;
    -- end
    -- if type(self.elementHeight) ~= "number" then
    --     error("self.elementHeight not set or not of type number")
    --     return;
    -- end

    CallbackRegistryMixin.OnLoad(self)

    self.DataProvider = CreateDataProvider();
    self.scrollView = CreateScrollBoxListLinearView();
    self.scrollView:SetDataProvider(self.DataProvider);

    ---height is defined in the xml keyValues
    if type(self.elementHeight) == "number" then
        local height = self.elementHeight;
        self.scrollView:SetElementExtent(height);

    else
        self.scrollView:SetElementExtent(24);
    end

    self.scrollView:SetElementInitializer(self.frameType, self.itemTemplate, GenerateClosure(self.OnElementInitialize, self));
    self.scrollView:SetElementResetter(GenerateClosure(self.OnElementReset, self));

    self.scrollView:SetPadding(2, 2, 2, 2, 1);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", 0, 4),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, anchorsWithBar, anchorsWithoutBar);
end

function DungeonPugsListviewMixin:OnElementInitialize(element, elementData, isNew)
    if isNew then
        element:OnLoad();
    end

    local height = self.elementHeight;
    element:SetDataBinding(elementData, height);
end

function DungeonPugsListviewMixin:OnElementReset(element)
    element:ResetDataBinding()
end

function DungeonPugsListviewMixin:OnElementClicked(element)
    self.selectionBehavior:Select(element);
end


function DungeonPugsListviewMixin:OnElementSelectionChanged(elementData, selected)

    local element = self.scrollView:FindFrame(elementData);

    if element then
        element:SetSelected(selected);
    end

end





DungeonPugsPlayerListviewItemTemplateMixin = {}

function DungeonPugsPlayerListviewItemTemplateMixin:OnLoad()

end

function DungeonPugsPlayerListviewItemTemplateMixin:SetDataBinding(binding, height)

    local backgroundOpacity = 0.09

    self:SetHeight(height)

    if binding.class then
        self.class:SetAtlas(string.format("GarrMission_ClassIcon-%s", binding.class))
        self.class:SetSize(height-2, height-2)
    end

    if binding.level then
        self.level:SetText(binding.level)
    end

    local name = binding.name;
    if binding.name then
        if binding.isNewbieFriendly then
            name = string.format("%s %s", name, CreateAtlasMarkup("newplayerchat-chaticon-newcomer", 20, 20))
        end
    end
    self.name:SetText(name)
    
    if binding.role == "TANK" then
        self.background:SetColorTexture(0,0,1,backgroundOpacity)
    elseif binding.role == "HEALER" then
        self.background:SetColorTexture(0,1,0,backgroundOpacity)
    else
        self.background:SetColorTexture(1,0,0,backgroundOpacity)
    end


    if binding.roles then
        local s = "";
        if binding.roles.dps then
            s = s..CreateAtlasMarkup("groupfinder-icon-role-large-dps", 22, 22)
        end
        if binding.roles.healer then
            s = s..CreateAtlasMarkup("groupfinder-icon-role-large-heal", 22, 22)
        end
        if binding.roles.tank then
            s = s..CreateAtlasMarkup("groupfinder-icon-role-large-tank", 22, 22)
        end
        self.roles:SetText(s)
    end

    if binding.inGroup then
        local rolesString = ""
        for k, player in ipairs(binding.groupMembers) do
            if k > 5 then
                return
            end
            if player.role == "DAMAGER" then
                rolesString = string.format("%s %s", rolesString, CreateAtlasMarkup("groupfinder-icon-role-large-dps", 20, 20))
            elseif player.role == "TANK" then
                rolesString = string.format("%s %s", rolesString, CreateAtlasMarkup("groupfinder-icon-role-large-tank", 20, 20))
            else
                rolesString = string.format("%s %s", rolesString, CreateAtlasMarkup("groupfinder-icon-role-large-heal", 20, 20))
            end
        end
        self.roles:SetText(rolesString)

        --overwrite the class icon
        self.class:SetAtlas("socialqueuing-icon-group")
        self.level:SetText(string.format("[%s]", #binding.groupMembers))
    end

    self:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        if binding.inGroup then
            GameTooltip:AddLine("Members:")
            for k, player in ipairs(binding.groupMembers) do
                local icon = player.class and CreateAtlasMarkup(string.format("GarrMission_ClassIcon-%s", player.class)) or ""
                local role;
                if player.role == "DAMAGER" then
                    role = player.role and CreateAtlasMarkup("groupfinder-icon-role-large-dps", 16, 16)
                elseif player.role == "TANK" then
                    role = player.role and CreateAtlasMarkup("groupfinder-icon-role-large-tank", 16, 16)
                else
                    role = player.role and CreateAtlasMarkup("groupfinder-icon-role-large-heal", 16, 16)
                end
                local colour = player.class and player.class:upper() or "PRIEST"
                GameTooltip:AddDoubleLine(string.format("%s |cffffffff%s|r %s", icon, player.level, addon.Colours[colour]:WrapTextInColorCode(player.name)), role)
            end
        end
        
        --DevTools_Dump({binding.activities})
        if binding.activities then
            GameTooltip:AddLine("Activities:")
            table.sort(binding.activities, function(a, b)
                if a.isHeroic == b.isHeroic then
                    return a.name < b.name
                else
                    return a.isHeroic > b.isHeroic;
                end
            end)
            for k, dungeon in ipairs(binding.activities) do
                if dungeon.isHeroic == 1 then
                    GameTooltip:AddLine("HC "..dungeon.name, 1,1,1)
                else
                    GameTooltip:AddLine(dungeon.name, 1,1,1)
                end
            end
        end

        GameTooltip:Show()
    end)

    self:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)

    self:SetScript("OnMouseDown", function()
        addon:TriggerEvent("Playerslist_OnMouseDown", binding)
    end)

    if self.roles:GetText() == "" or self.roles:GetText() == nil then
        self.background:SetColorTexture(252/255, 197/255, 0, backgroundOpacity)
    end

end

function DungeonPugsPlayerListviewItemTemplateMixin:ResetDataBinding()

    self.class:SetAtlas("")
    self.name:SetText("")
    self.roles:SetText("")
    self.background:SetColorTexture(0,0,0,0)

    self:SetScript("OnEnter", nil)
end