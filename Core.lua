-- ********************************************************************************
-- Alts Anywhere
-- Store informations about your alts, making it accessible from any of your toons.
-- By: Shenton
--
-- Core.lua
-- Ace3 libs, common functions and variables, Ace3 init.
-- ********************************************************************************

-- Ace libs (<3)
local A = LibStub("AceAddon-3.0"):NewAddon("BrokerPAM", "AceHook-3.0");
A.aceDB = LibStub("AceDB-3.0");
--A.aceConfig = LibStub("AceConfig-3.0");
--A.aceConfigDialog = LibStub("AceConfigDialog-3.0");
--A.aceDBOptions = LibStub("AceDBOptions-3.0");
--A.aceGUI = LibStub("AceGUI-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("BrokerPAM");

-- Data Broker libs (<3)
A.ldb = LibStub("LibDataBroker-1.1");
A.ldbi = LibStub("LibDBIcon-1.0");

-- ********************************************************************************
-- Variables
-- ********************************************************************************

-- LUA globals to locals
local pairs, ipairs, ssub = pairs, ipairs, string.sub;

-- AddOn version
A.version = GetAddOnMetadata("Broker_PAM", "Version");

-- Text colors
A.color = {};
A.color["GREEN"] = "|cFF33FF99";
A.color["WHITE"] = "|cFFFFFFFF";
A.color["RESET"] = "|r";

-- ********************************************************************************
-- Functions
-- ********************************************************************************

function A:BuildPetsTable()
    local out = {};

    for i=1,GetNumCompanions("CRITTER") do
        local creatureID, creatureName,_, icon, isSummoned = GetCompanionInfo("CRITTER", i);
        local leadingLetter = ssub(creatureName, 1, 1);

        if ( not out[leadingLetter] ) then out[leadingLetter] = {}; end

        out[leadingLetter][#out[leadingLetter]+1] =
        {
            i = i,
            id = creatureID,
            name = creatureName,
            icon = icon,
            isSummoned = isSummoned
        };
    end

    return out;
end

function A:BuildMountsTable()
    local out = {};

    for i=1,GetNumCompanions("MOUNT") do
        local creatureID, creatureName,_, icon, isSummoned = GetCompanionInfo("MOUNT", i);
        local leadingLetter = ssub(creatureName, 1, 1);

        if ( not out[leadingLetter] ) then out[leadingLetter] = {}; end

        out[leadingLetter][#out[leadingLetter]+1] =
        {
            i = i,
            id = creatureID,
            name = creatureName,
            icon = icon,
            isSummoned = isSummoned
        };
    end

    return out;
end

-- ********************************************************************************
-- Dropdown menu
-- ********************************************************************************

local function PetsMenu(self, level)
    if ( not level ) then return; end

    local pets = A:BuildPetsTable();

    wipe(self.info);

    if ( level == 1 ) then
        -- Menu title
        self.info.isTitle = 1;
        self.info.text = L["COMPANIONS"];
        self.info.notCheckable = 1;
        UIDropDownMenu_AddButton(self.info, level);

        -- Set options
        self.info.keepShownOnClick = 1;
        self.info.hasArrow = 1;
        self.info.isTitle = nil;
        self.info.disabled = nil;

        for k,_ in pairs(pets) do
            self.info.text = "   "..k;
            self.info.value = k;
            UIDropDownMenu_AddButton(self.info, level);
        end

        -- Close
        self.info.text = L["CLOSE"];
        self.info.hasArrow = nil;
        self.info.func = function()
            A:Unhook("CloseDropDownMenus");
            DropDownList1:SetScript("OnHide", nil);
            CloseDropDownMenus();
        end;
        UIDropDownMenu_AddButton(self.info, level);
    elseif (level == 2 ) then
        wipe(self.info);
        self.info.notCheckable = 1;
        self.info.hasArrow = nil;

        for k,v in pairs(pets) do
            local buttonIndex = 1;

            for _,vv in ipairs(v) do
                if ( UIDROPDOWNMENU_MENU_VALUE == k ) then
                    self.info.text = vv.name;
                    self.info.icon = vv.icon;
                    self.info.disabled = vv.isSummoned;
                    self.info.keepShownOnClick = 1;
                    self.info.swatchFunc = function() print("Doh!"); end;
                    self.info.func = function() CallCompanion("CRITTER", vv.i); end;
                    UIDropDownMenu_AddButton(self.info, level);

                    local model = CreateFrame("PlayerModel");
                    model:SetSize(150, 150);
                    model:SetCreature(vv.id);
                    model:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = true, tileSize = 16, edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 }});
                    model:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
					model:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
                    _G["DropDownList2Button"..buttonIndex]:SetScript("OnEnter", function()
                        model:SetPoint("TOPRIGHT", DropDownList2, "TOPLEFT", 0, 0);
                        model:Show();
                    end);
                    _G["DropDownList2Button"..buttonIndex]:SetScript("OnLeave", function() model:Hide(); end);
                    buttonIndex = buttonIndex + 1;
                end
            end
        end
    end
end

local function MountsMenu(self, level)
    if ( not level ) then return; end

    local pets = A:BuildMountsTable();

    wipe(self.info);

    if ( level == 1 ) then
        -- Menu title
        self.info.isTitle = 1;
        self.info.text = L["MOUNTS"];
        self.info.notCheckable = 1;
        UIDropDownMenu_AddButton(self.info, level);

        -- Set options
        self.info.keepShownOnClick = 1;
        self.info.hasArrow = 1;
        self.info.isTitle = nil;
        self.info.disabled = nil;

        for k,_ in pairs(pets) do
            self.info.text = "   "..k;
            self.info.value = k;
            UIDropDownMenu_AddButton(self.info, level);
        end

        -- Close
        self.info.text = L["CLOSE"];
        self.info.hasArrow = nil;
        self.info.func = function()
            A:Unhook("CloseDropDownMenus");
            DropDownList1:SetScript("OnHide", nil);
            CloseDropDownMenus();
        end;
        UIDropDownMenu_AddButton(self.info, level);
    elseif (level == 2 ) then
        wipe(self.info);
        self.info.notCheckable = 1;
        self.info.hasArrow = nil;

        for k,v in pairs(pets) do
            local buttonIndex = 1;

            for _,vv in ipairs(v) do
                if ( UIDROPDOWNMENU_MENU_VALUE == k ) then
                    self.info.text = vv.name;
                    self.info.icon = vv.icon;
                    self.info.disabled = vv.isSummoned;
                    self.info.keepShownOnClick = 1;
                    self.info.swatchFunc = function() print("Doh!"); end;
                    self.info.func = function() CallCompanion("MOUNT", vv.i); end;
                    UIDropDownMenu_AddButton(self.info, level);

                    local model = CreateFrame("PlayerModel");
                    model:SetSize(150, 150);
                    model:SetCreature(vv.id);
                    model:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = true, tileSize = 16, edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 }});
                    model:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
					model:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
                    _G["DropDownList2Button"..buttonIndex]:SetScript("OnEnter", function()
                        model:SetPoint("TOPRIGHT", DropDownList2, "TOPLEFT", 0, 0);
                        model:Show();
                    end);
                    _G["DropDownList2Button"..buttonIndex]:SetScript("OnLeave", function() model:Hide(); end);
                    buttonIndex = buttonIndex + 1;
                end
            end
        end
    end
end

-- ********************************************************************************
-- Callbacks
-- ********************************************************************************

function A:CloseDropDownMenus()
    DropDownList1:SetScript("OnHide", function() DropDownList1:Show(); end);
end

-- ********************************************************************************
-- Config
-- ********************************************************************************

A.aceDefaultDB =
{
    profile =
    {
        ldbi = {}
    }
};

-- ********************************************************************************
-- Main
-- ********************************************************************************

--- AceAddon callback
-- Called after the addon is fully loaded
function A:OnInitialize()
    -- Database
    A.db = A.aceDB:New("pamDB", A.aceDefaultDB);
end

--- AceAddon callback
-- Called during the PLAYER_LOGIN event
function A:OnEnable()
    -- LDB
    if ( A.ldb:GetDataObjectByName("BrokerPAMLDB") ) then
        A.ldbObject = A.ldb:GetDataObjectByName("BrokerPAMLDB");
    else
        A.ldbObject = A.ldb:NewDataObject("AaLDB", {
            type = "data source",
            text = L["ADDON_NAME"],
            label = L["ADDON_NAME"],
            icon = "Interface\\ICONS\\Achievement_WorldEvent_Brewmaster",
            tocname = "Broker_PAM",
            OnClick = function(self, button)
                if (button == "LeftButton") then
                    if ( A:IsHooked("CloseDropDownMenus") ) then
                        A:Unhook("CloseDropDownMenus");
                        DropDownList1:SetScript("OnHide", nil);
                        CloseDropDownMenus();
                    end
                    A:RawHook("CloseDropDownMenus", true);
                    A.menuFrame.initialize = MountsMenu;
                    ToggleDropDownMenu(1, nil, A.menuFrame, self:GetName(), 0, 0);
                    GameTooltip:Hide();
                elseif ( button == "RightButton" ) then
                    if ( A:IsHooked("CloseDropDownMenus") ) then
                        A:Unhook("CloseDropDownMenus");
                        DropDownList1:SetScript("OnHide", nil);
                        CloseDropDownMenus();
                    end
                    A:RawHook("CloseDropDownMenus", true);
                    A.menuFrame.initialize = PetsMenu;
                    ToggleDropDownMenu(1, nil, A.menuFrame, self:GetName(), 0, 0);
                    GameTooltip:Hide();
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddDoubleLine(A.color["WHITE"]..L["ADDON_NAME"], A.color["GREEN"].."v"..A.version);
                tooltip:AddLine(" ");
                tooltip:AddLine(L["TOOLTIP_TIPS"]);
            end
        });
    end

    -- LDBIcon
    if ( not A.ldbi:IsRegistered("AaLDBI") ) then A.ldbi:Register("AaLDBI", A.ldbObject, A.db.profile.ldbi); end

    -- Menu frame & table
    A.menuFrame = CreateFrame("Frame", "BrokerPAMMenuFrame");
    A.menuFrame.displayMode = "MENU";
    A.menuFrame.info = {};
end
