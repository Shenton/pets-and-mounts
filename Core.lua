-- ********************************************************************************
-- Broker Pets & Mounts
-- Data Broker display for easy acces to pets and mounts.
-- By: Shenton
--
-- Core.lua
-- ********************************************************************************

-- Ace libs (<3)
local A = LibStub("AceAddon-3.0"):NewAddon("BrokerPAM", "AceConsole-3.0", "AceHook-3.0");
A.aceDB = LibStub("AceDB-3.0");
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
A.color["RED"] = "|cFFFF3333";
A.color["GREEN"] = "|cFF33FF99";
A.color["WHITE"] = "|cFFFFFFFF";
A.color["RESET"] = "|r";

-- ********************************************************************************
-- Functions
-- ********************************************************************************

--- Send a message to the chat frame with the addon name colored
-- @param text The message to display
-- @param color Bool, if true will color in red
function A:Message(text, color)
	if ( color ) then
		color = A.color["RED"];
	else
		color = A.color["GREEN"]
	end

	DEFAULT_CHAT_FRAME:AddMessage(color..L["ADDON_NAME"]..": "..A.color["RESET"]..text);
end

--- Handle the slash command
-- @param input The string returned after the command
function A:SlashCommand(input)
    A.db.profile.ldbi.hide = nil;
    A:ShowHideMinimap();
end

--- Show or hide the minimap icon
function A:ShowHideMinimap()
	if ( A.db.profile.ldbi.hide ) then
		A:Message(L["HIDE_MINIMAP"], true);
		A.ldbi:Hide("BrokerPAMLDBI");
	else
		A.ldbi:Show("BrokerPAMLDBI");
	end
end

--- Build the companions table used by the dropdown menu
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

--- Build the mounts table used by the dropdown menu
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

        -- Blank separator
        wipe(self.info);
        self.info.disabled = true;
        self.info.notCheckable = true;
        UIDropDownMenu_AddButton(self.info, level);

        -- Options menu
        self.info.text = "   "..L["OPTIONS"];
		self.info.value = "OPTIONS";
        self.info.disabled = nil;
		self.info.hasArrow = true;
		UIDropDownMenu_AddButton(self.info, level);

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

        if ( UIDROPDOWNMENU_MENU_VALUE == "OPTIONS" ) then
            wipe(self.info);

            -- Show/hide minimap icon
            self.info.text = L["SHOW_HIDE_MINIMAP"];
            self.info.checked = not A.db.profile.ldbi.hide;
            self.info.func = function()
                A.db.profile.ldbi.hide = not A.db.profile.ldbi.hide;
                A:ShowHideMinimap();
            end;
            UIDropDownMenu_AddButton(self.info, level);
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

        -- Blank separator
        wipe(self.info);
        self.info.disabled = true;
        self.info.notCheckable = true;
        UIDropDownMenu_AddButton(self.info, level);

        -- Options menu
        self.info.text = "   "..L["OPTIONS"];
		self.info.value = "OPTIONS";
        self.info.disabled = nil;
		self.info.hasArrow = true;
		UIDropDownMenu_AddButton(self.info, level);

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

        if ( UIDROPDOWNMENU_MENU_VALUE == "OPTIONS" ) then
            wipe(self.info);

            -- Show/hide minimap icon
            self.info.text = L["SHOW_HIDE_MINIMAP"];
            self.info.checked = not A.db.profile.ldbi.hide;
            self.info.func = function()
                A.db.profile.ldbi.hide = not A.db.profile.ldbi.hide;
                A:ShowHideMinimap();
            end;
            UIDropDownMenu_AddButton(self.info, level);
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
    if ( not A.ldbi:IsRegistered("BrokerPAMLDBI") ) then A.ldbi:Register("BrokerPAMLDBI", A.ldbObject, A.db.profile.ldbi); end

    -- Slash command
	A:RegisterChatCommand("petsandmounts", "SlashCommand");
	A:RegisterChatCommand("pam", "SlashCommand");

    -- Menu frame & table
    A.menuFrame = CreateFrame("Frame", "BrokerPAMMenuFrame");
    A.menuFrame.displayMode = "MENU";
    A.menuFrame.info = {};
end
