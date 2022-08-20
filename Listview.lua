

local addonName, addon = ...;

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



--[[
    the following are the listview mixins
]]

--expansion select listview mixin
DungeonPugsExpansionSelectListviewButtonMixin = {}

function DungeonPugsExpansionSelectListviewButtonMixin:OnLoad()

end

function DungeonPugsExpansionSelectListviewButtonMixin:SetDataBinding(binding, height)

    self:SetHeight(height)

    self:SetNormalAtlas(binding.listviewButton.normalAtlas)
    self:SetPushedAtlas(binding.listviewButton.pushedAtlas)

    self:SetScript("OnClick", binding.onClick)

end

function DungeonPugsExpansionSelectListviewButtonMixin:ResetDataBinding()

end





DungeonPugsDungeonListviewItemTemplateMixin = {}

function DungeonPugsDungeonListviewItemTemplateMixin:OnLoad()

end

function DungeonPugsDungeonListviewItemTemplateMixin:SetDataBinding(binding, height)

    self:SetHeight(height)

    if binding.isHeroic == 1 then
        self.name:SetText("Heroic: "..binding.name)
    else
        self.name:SetText(binding.name)
    end

    self:SetScript("OnMouseDown", function()
        addon:TriggerEvent("DungeonList_OnSelectionChanged", binding)
    end)

end

function DungeonPugsDungeonListviewItemTemplateMixin:ResetDataBinding()
    self.name:SetText(" ")
end




DungeonPugsPlayerListviewItemTemplateMixin = {}

function DungeonPugsPlayerListviewItemTemplateMixin:OnLoad()

end

function DungeonPugsPlayerListviewItemTemplateMixin:SetDataBinding(binding, height)

    self:SetHeight(height)

    if binding.class then
        self.class:SetAtlas(string.format("GarrMission_ClassIcon-%s", binding.class))
        self.class:SetSize(height-2, height-2)
    end

    if binding.level then
        self.level:SetText(binding.level)
    end

    if binding.name then
        if binding.isLeader and binding.inGroup then
            self.name:SetText(string.format("%s %s", binding.name, CreateAtlasMarkup("groupfinder-icon-leader", 20, 10)))
        else
            self.name:SetText(binding.name)
        end
    end
    
    if binding.role == "TANK" then
        self.background:SetColorTexture(0,0,1,0.1)
    elseif binding.role == "HEALER" then
        self.background:SetColorTexture(0,1,0,0.1)
    else
        self.background:SetColorTexture(1,0,0,0.1)
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

    if binding.inGroup and (binding.isLeader == false) then
        self.roles:SetText(CreateAtlasMarkup("socialqueuing-icon-group", 22, 22))

        self:SetScript("OnEnter", function()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Group leader")
            GameTooltip:AddLine(binding.groupLeader, 1,1,1)
            GameTooltip:Show()
        end)

        self:SetScript("OnLeave", function()
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        end)
    end

    self:SetScript("OnMouseDown", function(_, button)
        addon:TriggerEvent("Playerslist_OnMouseDown", button, binding)
    end)

    if self.roles:GetText() == "" or self.roles:GetText() == nil then
        self.background:SetColorTexture(252/255, 197/255, 0, 0.1)
    end

end

function DungeonPugsPlayerListviewItemTemplateMixin:ResetDataBinding()

    self.class:SetAtlas("")
    self.name:SetText("")
    self.roles:SetText("")
    self.background:SetColorTexture(0,0,0,0)

    self:SetScript("OnEnter", nil)
end