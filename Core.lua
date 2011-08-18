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
local pairs, ipairs, ssub, smatch, tsort = pairs, ipairs, string.sub, string.match, table.sort;

-- AddOn version
A.version = GetAddOnMetadata("Broker_PAM", "Version");

-- Text colors
A.color = {};
A.color["RED"] = "|cFFFF3333";
A.color["GREEN"] = "|cFF33FF99";
A.color["WHITE"] = "|cFFFFFFFF";
A.color["RESET"] = "|r";

-- Model adjust
A.modelAdjust =
{
    [2671] = -- Mechanical Squirrel
    {
        s = 1.5,
        x = 0,
        y = 0,
        z = 0
    },
    [8376] = -- Mechanical Chicken
    {
        s = 2.5,
        x = 0,
        y = 0,
        z = 0
    },
    [7394] = -- Ancona Chicken
    {
        s = 2.5,
        x = 0,
        y = 0,
        z = 0
    },
    [14421] = -- Brown Prairie Dog
    {
        s = 2.5,
        x = 0,
        y = 0,
        z = 0
    },
    [29147] = -- Ghostly Skull
    {
        s = 2.5,
        x = 0,
        y = 0,
        z = 0
    },
    [24480] = -- Mojo
    {
        s = 2.5,
        x = 0,
        y = 0,
        z = 0
    },
    [14878] = -- Jubling
    {
        s = 2.5,
        x = 0,
        y = 0,
        z = 0
    }
};

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

--- pairs function with alphabetic sort
function A:PairsByKeys(t, f)
    local a, i = {}, 0;

    for n in pairs(t) do a[#a+1] = n; end
    tsort(a, f);

    local iter = function()
        i = i + 1;
        if ( not a[i] ) then
            return nil;
        else
            return a[i], t[a[i]];
        end
    end

    return iter;
end

--- Return anchor points depending on cursor position
function A:GetAnchor()
    local w = GetScreenWidth();
    local x = GetCursorPosition();

    w = (w * UIParent:GetEffectiveScale()) / 2;

    if ( x > w ) then return "TOPRIGHT", "TOPLEFT"; end

    return "TOPLEFT", "TOPRIGHT";
end

--- Build the companions table used by the dropdown menu
local contentTable;
function A:BuildPetsTable()
    contentTable = {};

    for i=1,GetNumCompanions("CRITTER") do
        local creatureID, creatureName,_, icon, isSummoned = GetCompanionInfo("CRITTER", i);
        local leadingLetter = ssub(creatureName, 1, 1);

        if ( not contentTable[leadingLetter] ) then contentTable[leadingLetter] = {}; end

        contentTable[leadingLetter][#contentTable[leadingLetter]+1] =
        {
            i = i,
            id = creatureID,
            name = creatureName,
            icon = icon,
            isSummoned = isSummoned
        };
    end

    return contentTable;
end

--- Build the mounts table used by the dropdown menu
function A:BuildMountsTable()
    contentTable = {};

    for i=1,GetNumCompanions("MOUNT") do
        local creatureID, creatureName,_, icon, isSummoned = GetCompanionInfo("MOUNT", i);
        local leadingLetter = ssub(creatureName, 1, 1);

        if ( not contentTable[leadingLetter] ) then contentTable[leadingLetter] = {}; end

        contentTable[leadingLetter][#contentTable[leadingLetter]+1] =
        {
            i = i,
            id = creatureID,
            name = creatureName,
            icon = icon,
            isSummoned = isSummoned
        };
    end

    return contentTable;
end

-- ********************************************************************************
-- Dropdown menu
-- ********************************************************************************

local rotation, rotationTime;
local function PetsMenu(self, level)
    if ( not level ) then return; end

    A.isBrokerPamMenu = 1;

    local contentTable = A:BuildPetsTable();

    if ( level == 1 ) then
        -- Menu title
        self.info.isTitle = 1;
        self.info.text = L["COMPANIONS"];
        self.info.notCheckable = 1;
        self.info.icon = nil;
        UIDropDownMenu_AddButton(self.info, level);

        -- Set options
        self.info.keepShownOnClick = 1;
        self.info.hasArrow = 1;
        self.info.isTitle = nil;
        self.info.disabled = nil;

        for k in A:PairsByKeys(contentTable) do
            self.info.text = "   "..k;
            self.info.value = k;
            UIDropDownMenu_AddButton(self.info, level);
        end

        -- Blank separator
        self.info.text = "";
        self.info.disabled = 1;
        self.info.notCheckable = 1;
        self.info.hasArrow = nil;
        UIDropDownMenu_AddButton(self.info, level);

        -- Options menu
        self.info.text = "   "..L["OPTIONS"];
		self.info.value = "OPTIONS";
        self.info.disabled = nil;
		self.info.hasArrow = 1;
		UIDropDownMenu_AddButton(self.info, level);

        -- Close
        self.info.text = L["CLOSE"];
        self.info.hasArrow = nil;
        self.info.func = function() CloseDropDownMenus(); end;
        UIDropDownMenu_AddButton(self.info, level);
    elseif (level == 2 ) then
        self.info.notCheckable = 1;
        self.info.hasArrow = nil;

        for k,v in A:PairsByKeys(contentTable) do
            local buttonIndex = 1;

            for _,vv in ipairs(v) do
                if ( UIDROPDOWNMENU_MENU_VALUE == k ) then
                    self.info.text = vv.name;
                    self.info.icon = vv.icon;
                    self.info.disabled = vv.isSummoned;
                    self.info.keepShownOnClick = 1;
                    self.info.func = function() CallCompanion("CRITTER", vv.i); end;
                    UIDropDownMenu_AddButton(self.info, level);

                    _G["DropDownList2Button"..buttonIndex]:HookScript("OnEnter", function()
                        if ( not A.isBrokerPamMenu ) then
                            A.modelFrame:Hide();

                            return;
                        end

                        -- Model
                        A.modelFrame:ClearModel();
                        A.modelFrame:SetCreature(vv.id);
                        --
                        --print(vv.id);
                        --print(A.modelFrame:GetPosition())
                        --
                        --A.modelFrame:SetCamera(2);
                        if ( A.modelAdjust[vv.id] ) then
                            A.modelFrame:SetPosition(0 + A.modelAdjust[vv.id].x, 0 + A.modelAdjust[vv.id].y, 0 + A.modelAdjust[vv.id].z);
                            A.modelFrame:SetModelScale(A.modelAdjust[vv.id].s);
                        else
                            A.modelFrame:SetPosition(0, 0, 0);
                            A.modelFrame:SetModelScale(1);
                        end
                        if ( A.db.profile.modelRotation ) then
                            rotation, rotationTime = 0, GetTime();
                            A.modelFrame:SetScript("OnUpdate", function()
                                local t = GetTime();

                                if ( rotationTime and rotationTime + 0.01 < t ) then
                                    A.modelFrame:SetRotation(rotation);
                                    rotation = rotation + 0.01;
                                    rotationTime = t;
                                end
                            end);
                        else
                            rotationTime = nil;
                            A.modelFrame:SetRotation(0);
                        end

                        -- Frame pos
                        local point, relativePoint = A:GetAnchor();
                        A.modelFrame:ClearAllPoints()
                        A.modelFrame:SetPoint(point, DropDownList2, relativePoint, 0, 0);
                        A.modelFrame:Show();
                    end);
                    _G["DropDownList2Button"..buttonIndex]:HookScript("OnLeave", function() A.modelFrame:Hide(); end);
                    buttonIndex = buttonIndex + 1;
                end
            end
        end

        if ( UIDROPDOWNMENU_MENU_VALUE == "OPTIONS" ) then
            -- Show/hide minimap icon
            self.info.text = L["SHOW_HIDE_MINIMAP"];
            self.info.icon = nil;
            self.info.notCheckable = nil;
            self.info.checked = not A.db.profile.ldbi.hide;
            self.info.func = function()
                A.db.profile.ldbi.hide = not A.db.profile.ldbi.hide;
                A:ShowHideMinimap();
            end;
            UIDropDownMenu_AddButton(self.info, level);

            _G["DropDownList2Button1"]:HookScript("OnEnter", function()
                A.modelFrame:ClearModel();
                A.modelFrame:Hide();
            end);

            -- Model rotation
            self.info.text = L["MODEL_ROTATION"];
            self.info.checked = A.db.profile.modelRotation;
            self.info.func = function() A.db.profile.modelRotation = not A.db.profile.modelRotation; end;
            UIDropDownMenu_AddButton(self.info, level);

            _G["DropDownList2Button2"]:HookScript("OnEnter", function()
                A.modelFrame:ClearModel();
                A.modelFrame:Hide();
            end);

            -- Model frame size
            self.info.text = L["MODEL_FRAME_SIZE"];
            self.info.notCheckable = 1;
            self.info.hasArrow = 1;
            self.info.value = "FRAMESIZE";
            self.info.func = function() A.db.profile.modelRotation = not A.db.profile.modelRotation; end;
            UIDropDownMenu_AddButton(self.info, level);

            _G["DropDownList2Button3"]:HookScript("OnEnter", function()
                A.modelFrame:ClearModel();
                A.modelFrame:Hide();
            end);
        end
    elseif (level == 3 ) then
        if ( UIDROPDOWNMENU_MENU_VALUE == "FRAMESIZE" ) then
            -- 100x100
            self.info.text = "100x100";
            self.info.icon = nil;
            self.info.notCheckable = nil;
            self.info.hasArrow = nil;
            self.info.keepShownOnClick = nil;
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 100 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 100;
                A.db.profile.modelFrameHeight = 100;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 150x150
            self.info.text = "150x150";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 150 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 150;
                A.db.profile.modelFrameHeight = 150;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 200x200
            self.info.text = "200x200";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 200 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 200;
                A.db.profile.modelFrameHeight = 200;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 250x250
            self.info.text = "250x250";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 250 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 250;
                A.db.profile.modelFrameHeight = 250;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 300x300
            self.info.text = "300x300";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 300 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 300;
                A.db.profile.modelFrameHeight = 300;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);
        end
    end
end

local function MountsMenu(self, level)
    if ( not level ) then return; end

    A.isBrokerPamMenu = 1;

    local contentTable = A:BuildMountsTable();

    if ( level == 1 ) then
        -- Menu title
        self.info.isTitle = 1;
        self.info.text = L["MOUNTS"];
        self.info.notCheckable = 1;
        self.info.icon = nil;
        UIDropDownMenu_AddButton(self.info, level);

        -- Set options
        self.info.keepShownOnClick = 1;
        self.info.hasArrow = 1;
        self.info.isTitle = nil;
        self.info.disabled = nil;

        for k in A:PairsByKeys(contentTable) do
            self.info.text = "   "..k;
            self.info.value = k;
            UIDropDownMenu_AddButton(self.info, level);
        end

        -- Blank separator
        self.info.text = "";
        self.info.hasArrow = nil;
        self.info.disabled = 1;
        self.info.notCheckable = 1;
        UIDropDownMenu_AddButton(self.info, level);

        -- Options menu
        self.info.text = "   "..L["OPTIONS"];
		self.info.value = "OPTIONS";
        self.info.disabled = nil;
		self.info.hasArrow = 1;
		UIDropDownMenu_AddButton(self.info, level);

        -- Close
        self.info.text = L["CLOSE"];
        self.info.hasArrow = nil;
        self.info.func = function() CloseDropDownMenus(); end;
        UIDropDownMenu_AddButton(self.info, level);
    elseif (level == 2 ) then
        self.info.notCheckable = 1;
        self.info.hasArrow = nil;

        for k,v in A:PairsByKeys(contentTable) do
            local buttonIndex = 1;

            for _,vv in ipairs(v) do
                if ( UIDROPDOWNMENU_MENU_VALUE == k ) then
                    self.info.text = vv.name;
                    self.info.icon = vv.icon;
                    self.info.disabled = vv.isSummoned;
                    self.info.keepShownOnClick = 1;
                    self.info.func = function() CallCompanion("MOUNT", vv.i); end;
                    UIDropDownMenu_AddButton(self.info, level);

                    _G["DropDownList2Button"..buttonIndex]:HookScript("OnEnter", function()
                        if ( not A.isBrokerPamMenu ) then
                            A.modelFrame:Hide();

                            return;
                        end

                        -- Model
                        A.modelFrame:ClearModel();
                        A.modelFrame:SetCreature(vv.id);
                        if ( A.db.profile.modelRotation ) then
                            rotation, rotationTime = 0, GetTime();
                            A.modelFrame:SetScript("OnUpdate", function()
                                local t = GetTime();

                                if ( rotationTime and rotationTime + 0.01 < t ) then
                                    A.modelFrame:SetRotation(rotation);
                                    rotation = rotation + 0.01;
                                    rotationTime = t;
                                end
                            end);
                        else
                            rotationTime = nil;
                            A.modelFrame:SetRotation(0);
                        end

                        -- Frame pos
                        local point, relativePoint = A:GetAnchor();
                        A.modelFrame:ClearAllPoints()
                        A.modelFrame:SetPoint(point, DropDownList2, relativePoint, 0, 0);
                        A.modelFrame:Show();
                    end);
                    _G["DropDownList2Button"..buttonIndex]:HookScript("OnLeave", function() A.modelFrame:Hide(); end);
                    buttonIndex = buttonIndex + 1;
                end
            end
        end

        if ( UIDROPDOWNMENU_MENU_VALUE == "OPTIONS" ) then
            -- Show/hide minimap icon
            self.info.text = L["SHOW_HIDE_MINIMAP"];
            self.info.notCheckable = nil;
            self.info.icon = nil;
            self.info.checked = not A.db.profile.ldbi.hide;
            self.info.func = function()
                A.db.profile.ldbi.hide = not A.db.profile.ldbi.hide;
                A:ShowHideMinimap();
            end;
            UIDropDownMenu_AddButton(self.info, level);

            _G["DropDownList2Button1"]:HookScript("OnEnter", function()
                A.modelFrame:ClearModel();
                A.modelFrame:Hide();
            end);

            -- Model rotation
            self.info.text = L["MODEL_ROTATION"];
            self.info.checked = A.db.profile.modelRotation;
            self.info.func = function() A.db.profile.modelRotation = not A.db.profile.modelRotation; end;
            UIDropDownMenu_AddButton(self.info, level);

            _G["DropDownList2Button2"]:HookScript("OnEnter", function()
                A.modelFrame:ClearModel();
                A.modelFrame:Hide();
            end);

            -- Model frame size
            self.info.text = L["MODEL_FRAME_SIZE"];
            self.info.notCheckable = 1;
            self.info.hasArrow = 1;
            self.info.value = "FRAMESIZE";
            self.info.func = function() A.db.profile.modelRotation = not A.db.profile.modelRotation; end;
            UIDropDownMenu_AddButton(self.info, level);

            _G["DropDownList2Button3"]:HookScript("OnEnter", function()
                A.modelFrame:ClearModel();
                A.modelFrame:Hide();
            end);
        end
    elseif (level == 3 ) then
        if ( UIDROPDOWNMENU_MENU_VALUE == "FRAMESIZE" ) then
            -- 100x100
            self.info.text = "100x100";
            self.info.icon = nil;
            self.info.notCheckable = nil;
            self.info.hasArrow = nil;
            self.info.keepShownOnClick = nil;
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 100 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 100;
                A.db.profile.modelFrameHeight = 100;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 150x150
            self.info.text = "150x150";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 150 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 150;
                A.db.profile.modelFrameHeight = 150;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 200x200
            self.info.text = "200x200";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 200 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 200;
                A.db.profile.modelFrameHeight = 200;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 250x250
            self.info.text = "250x250";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 250 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 250;
                A.db.profile.modelFrameHeight = 250;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 300x300
            self.info.text = "300x300";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 300 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 300;
                A.db.profile.modelFrameHeight = 300;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
            end;
            UIDropDownMenu_AddButton(self.info, level);
        end
    end
end

-- ********************************************************************************
-- Config
-- ********************************************************************************

A.aceDefaultDB =
{
    profile =
    {
        modelRotation = 1,
        modelFrameWidth = 200,
        modelFrameHeight = 200,
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
        A.ldbObject = A.ldb:NewDataObject("BrokerPAMLDB", {
            type = "data source",
            text = L["ADDON_NAME"],
            label = L["ADDON_NAME"],
            icon = "Interface\\ICONS\\Achievement_WorldEvent_Brewmaster",
            tocname = "Broker_PAM",
            OnClick = function(self, button)
                if (button == "LeftButton") then
                    A.menuFrame.initialize = MountsMenu;
                    ToggleDropDownMenu(1, nil, A.menuFrame, self:GetName(), 0, 0);
                    GameTooltip:Hide();
                elseif ( button == "RightButton" ) then
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
    DropDownList1:HookScript("OnHide", function(self)
        A.isBrokerPamMenu = nil;
    end);

    -- Model Frame
    A.modelFrame = CreateFrame("PlayerModel", "BrokerPamModelFrame", UIParent);
    A.modelFrame:SetFrameStrata("TOOLTIP");
    A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
    A.modelFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }});
    A.modelFrame:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
    A.modelFrame:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
    A.modelFrame:Hide();
end
