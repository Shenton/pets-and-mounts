--[[ $Id: AceGUIWidget-DropDown.lua 1029 2011-06-10 23:10:58Z nevcairiel $ ]]--
-- Very light modification to SetList and AddListItem methods/functions, sort by value and model display, for Broker Pets & Mounts, by Shenton, so if it's broken it's my fault :)
local AceGUI = LibStub("AceGUI-3.0")

-- Lua APIs
local min, max, floor = math.min, math.max, math.floor
local select, pairs, ipairs, type = select, pairs, ipairs, type
local tsort = table.sort

-- WoW APIs
local PlaySound = PlaySound
local UIParent, CreateFrame = UIParent, CreateFrame
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: CLOSE

local function fixlevels(parent,...)
    local i = 1
    local child = select(i, ...)
    while child do
        child:SetFrameLevel(parent:GetFrameLevel()+1)
        fixlevels(child, child:GetChildren())
        i = i + 1
        child = select(i, ...)
    end
end

local function fixstrata(strata, parent, ...)
    local i = 1
    local child = select(i, ...)
    parent:SetFrameStrata(strata)
    while child do
        fixstrata(strata, child, child:GetChildren())
        i = i + 1
        child = select(i, ...)
    end
end

do
    local widgetType = "Dropdown-SortByValue"
    local widgetVersion = 25

    --[[ Static data ]]--

    --[[ UI event handler ]]--

    local function Control_OnEnter(this)
        this.obj:Fire("OnEnter")
    end

    local function Control_OnLeave(this)
        this.obj:Fire("OnLeave")
    end

    local function Dropdown_OnHide(this)
        local self = this.obj
        if self.open then
            self.pullout:Close()
        end
    end

    local function Dropdown_TogglePullout(this)
        local self = this.obj
        PlaySound("igMainMenuOptionCheckBoxOn") -- missleading name, but the Blizzard code uses this sound
        if self.open then
            self.open = nil
            self.pullout:Close()
            AceGUI:ClearFocus()
        else
            self.open = true
            self.pullout:SetWidth(self.frame:GetWidth())
            self.pullout:Open("TOPLEFT", self.frame, "BOTTOMLEFT", 0, self.label:IsShown() and -2 or 0)
            AceGUI:SetFocus(self)
        end
    end

    local function OnPulloutOpen(this)
        local self = this.userdata.obj
        local value = self.value

        if not self.multiselect then
            for i, item in this:IterateItems() do
                item:SetValue(item.userdata.value == value)
            end
        end

        self.open = true
    end

    local function OnPulloutClose(this)
        local self = this.userdata.obj
        self.open = nil
        self:Fire("OnClosed")
    end

    local function ShowMultiText(self)
        local text
        for i, widget in self.pullout:IterateItems() do
            if widget.type == "Dropdown-Item-Toggle" then
                if widget:GetValue() then
                    if text then
                        text = text..", "..widget:GetText()
                    else
                        text = widget:GetText()
                    end
                end
            end
        end
        self:SetText(text)
    end

    local function OnItemValueChanged(this, event, checked)
        local self = this.userdata.obj

        if self.multiselect then
            self:Fire("OnValueChanged", this.userdata.value, checked)
            ShowMultiText(self)
        else
            if checked then
                self:SetValue(this.userdata.value)
                self:Fire("OnValueChanged", this.userdata.value)
            else
                this:SetValue(true)
            end
            if self.open then
                self.pullout:Close()
            end
        end
    end

    --[[ Exported methods ]]--

    -- exported, AceGUI callback
    local function OnAcquire(self)
        local pullout = AceGUI:Create("Dropdown-Pullout")
        self.pullout = pullout
        pullout.userdata.obj = self
        pullout:SetCallback("OnClose", OnPulloutClose)
        pullout:SetCallback("OnOpen", OnPulloutOpen)
        self.pullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
        fixlevels(self.pullout.frame, self.pullout.frame:GetChildren())

        self:SetHeight(44)
        self:SetWidth(200)
        self:SetLabel()
    end

    -- exported, AceGUI callback
    local function OnRelease(self)
        if self.open then
            self.pullout:Close()
        end
        AceGUI:Release(self.pullout)
        self.pullout = nil

        self:SetText("")
        self:SetDisabled(false)
        self:SetMultiselect(false)

        self.value = nil
        self.list = nil
        self.open = nil
        self.hasClose = nil

        self.frame:ClearAllPoints()
        self.frame:Hide()
    end

    -- exported
    local function SetDisabled(self, disabled)
        self.disabled = disabled
        if disabled then
            self.text:SetTextColor(0.5,0.5,0.5)
            self.button:Disable()
            self.label:SetTextColor(0.5,0.5,0.5)
        else
            self.button:Enable()
            self.label:SetTextColor(1,.82,0)
            self.text:SetTextColor(1,1,1)
        end
    end

    -- exported
    local function ClearFocus(self)
        if self.open then
            self.pullout:Close()
        end
    end

    -- exported
    local function SetText(self, text)
        self.text:SetText(text or "")
    end

    -- exported
    local function SetLabel(self, text)
        if text and text ~= "" then
            self.label:SetText(text)
            self.label:Show()
            self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,-18)
            self:SetHeight(44)
            self.alignoffset = 30
        else
            self.label:SetText("")
            self.label:Hide()
            self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,0)
            self:SetHeight(26)
            self.alignoffset = 12
        end
    end

    -- exported
    local function SetValue(self, value)
        if self.list then
            self:SetText(self.list[value] or "")
        end
        self.value = value
    end

    -- exported
    local function GetValue(self)
        return self.value
    end

    -- exported
    local function SetItemValue(self, item, value)
        if not self.multiselect then return end
        for i, widget in self.pullout:IterateItems() do
            if widget.userdata.value == item then
                if widget.SetValue then
                    widget:SetValue(value)
                end
            end
        end
        ShowMultiText(self)
    end

    -- exported
    local function SetItemDisabled(self, item, disabled)
        for i, widget in self.pullout:IterateItems() do
            if widget.userdata.value == item then
                widget:SetDisabled(disabled)
            end
        end
    end

    local brokerPAMGlobal = _G["BrokerPAMGlobal"];
    local function AddListItem(self, value, text, itemType)
        if not itemType then itemType = "Dropdown-Item-Toggle" end
        local exists = AceGUI:GetWidgetVersion(itemType)
        if not exists then error(("The given item type, %q, does not exist within AceGUI-3.0"):format(tostring(itemType)), 2) end

        local item = AceGUI:Create(itemType)
        item:SetText(text)
        item.userdata.obj = self
        item.userdata.value = value
        item:SetCallback("OnValueChanged", OnItemValueChanged)
        self.pullout:AddItem(item)
        item:SetCallback("OnEnter", function()
            local creatureID;

            if ( brokerPAMGlobal:IsGUID(value) ) then
                creatureID = select(11, C_PetJournal.GetPetInfoByPetID(value));
            else
                creatureID = brokerPAMGlobal:GetCreatureIDFromSpellID(value);
            end

            if ( not creatureID ) then return; end

            -- Model
            brokerPAMGlobal.modelFrameConfig.rotation = 0;
            brokerPAMGlobal.modelFrameConfig:SetCreature(creatureID);

            -- Frame pos
            brokerPAMGlobal.modelFrameConfig:ClearAllPoints()
            brokerPAMGlobal.modelFrameConfig:SetPoint("TOPLEFT", brokerPAMGlobal.configFrame, "TOPRIGHT", 0, 0);
            brokerPAMGlobal.modelFrameConfig:Show();
        end)
        item:SetCallback("OnLeave", function()
            brokerPAMGlobal.modelFrameConfig:Hide();
        end)
    end

    local function AddCloseButton(self)
        if not self.hasClose then
            local close = AceGUI:Create("Dropdown-Item-Execute")
            close:SetText(CLOSE)
            self.pullout:AddItem(close)
            self.hasClose = true
        end
    end

    -- exported
    local function GetKey(tbl, item)
        for k,v in pairs(tbl) do
            if ( v == item ) then return k; end
        end
        return nil;
    end
    local sortlist = {}
    local function SetList(self, list, order, itemType)
        self.list = list
        self.pullout:Clear()
        self.hasClose = nil
        if not list then return end

        for k, v in pairs(list) do
            if ( k == 0 ) then
            else
                sortlist[#sortlist+1] = v;
            end
        end

        tsort(sortlist);

        if ( list[0] ) then
            AddListItem(self, 0, list[0], itemType);
        end

        for k,v in ipairs(sortlist) do
            AddListItem(self, GetKey(list, v), v, itemType);
            sortlist[k] = nil;
        end

        if self.multiselect then
            ShowMultiText(self)
            AddCloseButton(self)
        end
    end

    -- exported
    local function AddItem(self, value, text, itemType)
        if self.list then
            self.list[value] = text
            AddListItem(self, value, text, itemType)
        end
    end

    -- exported
    local function SetMultiselect(self, multi)
        self.multiselect = multi
        if multi then
            ShowMultiText(self)
            AddCloseButton(self)
        end
    end

    -- exported
    local function GetMultiselect(self)
        return self.multiselect
    end

    --[[ Constructor ]]--

    local function Constructor()
        local count = AceGUI:GetNextWidgetNum(widgetType)
        local frame = CreateFrame("Frame", nil, UIParent)
        local dropdown = CreateFrame("Frame", "AceGUI30DropDownNoSort"..count, frame, "UIDropDownMenuTemplate")

        local self = {}
        self.type = widgetType
        self.frame = frame
        self.dropdown = dropdown
        self.count = count
        frame.obj = self
        dropdown.obj = self

        self.OnRelease   = OnRelease
        self.OnAcquire   = OnAcquire

        self.ClearFocus  = ClearFocus

        self.SetText     = SetText
        self.SetValue    = SetValue
        self.GetValue    = GetValue
        self.SetList     = SetList
        self.SetLabel    = SetLabel
        self.SetDisabled = SetDisabled
        self.AddItem     = AddItem
        self.SetMultiselect = SetMultiselect
        self.GetMultiselect = GetMultiselect
        self.SetItemValue = SetItemValue
        self.SetItemDisabled = SetItemDisabled

        self.alignoffset = 30

        frame:SetScript("OnHide",Dropdown_OnHide)

        dropdown:ClearAllPoints()
        dropdown:SetPoint("TOPLEFT",frame,"TOPLEFT",-15,0)
        dropdown:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",17,0)
        dropdown:SetScript("OnHide", nil)

        local left = _G[dropdown:GetName() .. "Left"]
        local middle = _G[dropdown:GetName() .. "Middle"]
        local right = _G[dropdown:GetName() .. "Right"]

        middle:ClearAllPoints()
        right:ClearAllPoints()

        middle:SetPoint("LEFT", left, "RIGHT", 0, 0)
        middle:SetPoint("RIGHT", right, "LEFT", 0, 0)
        right:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", 0, 17)

        local button = _G[dropdown:GetName() .. "Button"]
        self.button = button
        button.obj = self
        button:SetScript("OnEnter",Control_OnEnter)
        button:SetScript("OnLeave",Control_OnLeave)
        button:SetScript("OnClick",Dropdown_TogglePullout)

        local text = _G[dropdown:GetName() .. "Text"]
        self.text = text
        text.obj = self
        text:ClearAllPoints()
        text:SetPoint("RIGHT", right, "RIGHT" ,-43, 2)
        text:SetPoint("LEFT", left, "LEFT", 25, 2)

        local label = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
        label:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
        label:SetJustifyH("LEFT")
        label:SetHeight(18)
        label:Hide()
        self.label = label

        AceGUI:RegisterAsWidget(self)
        return self
    end

    AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end
