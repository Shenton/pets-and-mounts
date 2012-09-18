-- ********************************************************************************
-- Broker Pets & Mounts
-- Data Broker display for easy acces to pets and mounts.
-- By: Shenton
--
-- Core.lua
-- ********************************************************************************

-- Ace libs (<3)
local A = LibStub("AceAddon-3.0"):NewAddon("BrokerPAM", "AceConsole-3.0", "AceHook-3.0", "AceTimer-3.0", "AceEvent-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("BrokerPAM");
A.L = L;

_G["BrokerPAMGlobal"] = A;

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
A.color["BLUE"] = "|cFF3399FF";
A.color["WHITE"] = "|cFFFFFFFF";
A.color["RESET"] = "|r";

-- Player pets and mounts table
A.pamTable =
{
    pets = {},
    petsIds = {},
    mounts = {},
    mountsIds = {},
};

A.mountCat = {L["Ground"],L["Fly"],L["Hybrid"],L["Aquatic"],L["Passenger"]};

-- Mounts spellID with passengers
-- Thanks http://mounts.wowlogy.com/special/mounts-with-passengers/
A.passengerMounts =
{
    [60424] = 1, -- Mekgineer's Chopper
    [61465] = 1, -- Grand Black War Mammoth (Alliance)
    [61467] = 1, -- Grand Black War Mammoth (Horde)
    [61469] = 1, -- Grand Ice Mammoth (Horde)
    [61470] = 1, -- Grand Ice Mammoth (Alliance)
    [61425] = 1, -- Traveler's Tundra Mammoth (Alliance)
    [61447] = 1, -- Traveler's Tundra Mammoth (Horde)
    [55531] = 1, -- Mechano-Hog
    [75973] = 1, -- X-53 Touring Rocket
    [93326] = 1, -- Sandstone Drake
};

-- Binding UI localization
BINDING_HEADER_BROKERPAM = L["Pets & Mounts"];
BINDING_NAME_BROKERPAMMOUNT = L["Random mount"];
BINDING_NAME_BROKERPAMMOUNTPASSENGERS = L["Random passengers mount"];
BINDING_NAME_BROKERPAMMOUNTFLYING = L["Random flying mount"];
BINDING_NAME_BROKERPAMMOUNTGROUND = L["Random ground mount"];
BINDING_NAME_BROKERPAMMOUNTAQUATIC = L["Random aquatic mount"];

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

    DEFAULT_CHAT_FRAME:AddMessage(color..L["Pets & Mounts"]..": "..A.color["RESET"]..text);
end

--- Send a debug message
function A:DebugMessage(...)
    if ( A.db.profile.debug ) then
        if ( ... ) then
            DEFAULT_CHAT_FRAME:AddMessage(A.color["BLUE"]..L["Pets & Mounts"]..": "..A.color["RESET"]..(...));
        else
            DEFAULT_CHAT_FRAME:AddMessage(A.color["BLUE"]..L["Pets & Mounts"]..": "..A.color["RESET"].."Arg == nil");
        end
    end
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
        A:Message(L["Minimap icon is hidden if you want to show it back use: /pam or /petsandmounts"], true);
        LibStub("LibDBIcon-1.0"):Hide("BrokerPAMLDBI");
    else
        LibStub("LibDBIcon-1.0"):Show("BrokerPAMLDBI");
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

--- Return the position of an item in a table
-- @param table The table
-- @param item The item
-- @return the item pos or false
function A:Exists(table, name)
    local index = 1;

    while table[index] do
        if ( name == table[index]["name"] ) then return 1; end

        index = index+1;
   end

   return nil;
end

--- Remove the given item from the given table
function A:TableRemove(table, item)
    for i=1,#table do
        if ( table[i] == item ) then
            tremove(table, i);
            return;
        end
    end
end

--- Will check if a table got a least one entry
-- Dunno why but in Config.lua I use a for loop "for k,v in ipairs(A.pamTable.mounts) do"
-- #v always return 0, even if the table is not empty
function A:TableNotEmpty(t)
    for k,v in pairs(t) do
        if ( k ) then return 1; end
    end

    return nil;
end

--- Return anchor points depending on cursor position
function A:GetAnchor()
    local w = GetScreenWidth();
    local x = GetCursorPosition();

    w = (w * UIParent:GetEffectiveScale()) / 2;

    if ( x > w ) then return "TOPRIGHT", "TOPLEFT"; end

    return "TOPLEFT", "TOPRIGHT";
end

-- 51755 Camouflage (hunter)
-- 32612 Invis (mage)
local stealthAuras =
{
    [1] = GetSpellInfo(51755),
    [2] = GetSpellInfo(32612),
};
local _, class = UnitClass("player");
function A:IsStealthed()
    if ( class == "HUNTER" or class == "MAGE" ) then
        for k,v in ipairs(stealthAuras) do
            if ( UnitBuff("player", v) ) then
                A:DebugMessage("IsStealthed() - Stealth buff found");
                return 1;
            end
        end

        return nil;
    else
        return IsStealthed();
    end
end

--- Return the mount type depending on the bitfield
local bitField = {16,8,4,2,1};
local bitFieldCat =
{
    [16] = "jump",
    [8] = "aquatic",
    [4] = "floats",
    [2] = "fly",
    [1] = "ground",
};
local mountCat;
function A:GetMountCategory(cat)
    local index = 1;
    mountCat = {};

    while cat > 0 do
        if ( cat - bitField[index] > 0 ) then
            mountCat[#mountCat+1] = bitFieldCat[bitField[index]];
            cat = cat - bitField[index];
            index = index + 1;
        elseif ( cat - bitField[index] == 0 ) then
            mountCat[#mountCat+1] = bitFieldCat[bitField[index]];
            cat = 0;
        else
            index = index + 1;
        end
    end

    if ( #mountCat == 5 ) then -- 31
        cat = 3;
    elseif ( #mountCat == 4 and not tContains(mountCat, "fly") ) then -- 29
        cat = 1;
    elseif ( #mountCat == 3 and not tContains(mountCat, "jump") and not tContains(mountCat, "aquatic") ) then -- 7
        cat = 2;
    elseif ( #mountCat == 2 and not tContains(mountCat, "jump") and not tContains(mountCat, "fly") and not tContains(mountCat, "jump") ) then -- 12
        cat = 4
    elseif ( tContains(mountCat, "ground") and tContains(mountCat, "fly") ) then
        cat = 3;
    elseif ( tContains(mountCat, "fly") ) then
        cat = 2;
    elseif ( tContains(mountCat, "ground") ) then
        cat = 1;
    elseif ( tContains(mountCat, "aquatic") ) then
        cat = 4;
    end

    return cat;
end

--- Build the companions table
function A:BuildPetsTable()
    A.pamTable.pets = {};
    A.pamTable.petsIds = {};

    local numPets, numOwned = C_PetJournal.GetNumPets(false);

    for i=1,numPets do
        local petID, _, isOwned, customName, _, _, _, creatureName, icon, _, creatureID = C_PetJournal.GetPetInfoByIndex(i, false);
        --local petID, speciesID, isOwned, customName, level, favorite, isRevoked, name, icon, petType, creatureID, sourceText, description, isWildPet, canBattle = C_PetJournal.GetPetInfoByIndex(index, isWild);

        if ( isOwned ) then
            if ( customName and A.db.profile.noFilterCustom ) then
                local leadingLetter = ssub(customName, 1, 1);

                if ( not A.pamTable.pets[leadingLetter] ) then A.pamTable.pets[leadingLetter] = {}; end

                A.pamTable.petsIds[#A.pamTable.petsIds+1] = petID;

                A.pamTable.pets[leadingLetter][#A.pamTable.pets[leadingLetter]+1] =
                {
                    petID = petID,
                    name = customName,
                    icon = icon,
                    creatureID = creatureID,
                };
            else
                local leadingLetter = ssub(creatureName, 1, 1);

                if ( not A.pamTable.pets[leadingLetter] ) then A.pamTable.pets[leadingLetter] = {}; end

                if ( (not A:Exists(A.pamTable.pets[leadingLetter], creatureName)
                or A:Exists(A.pamTable.pets[leadingLetter], creatureName) and not A.db.profile.filterMultiple)
                or not A.db.profile.filterMultiple ) then
                    A.pamTable.petsIds[#A.pamTable.petsIds+1] = petID;

                    A.pamTable.pets[leadingLetter][#A.pamTable.pets[leadingLetter]+1] =
                    {
                        petID = petID,
                        name = creatureName,
                        icon = icon,
                        creatureID = creatureID,
                    };
                end
            end
        end
    end
end

--- Build the mounts table
function A:BuildMountsTable()
    local creatureID, creatureName, spellId, icon, isSummoned, mountType, leadingLetter, cat;
    A.pamTable.mounts =
    {
        [1] = {}, -- Ground
        [2] = {}, -- Fly
        [3] = {}, -- Hybrid (ground & fly)
        [4] = {}, -- Aquatic
        [5] = {}, -- with passengers
    };
    A.pamTable.mountsIds =
    {
        [1] = {}, -- Ground
        [2] = {}, -- Fly
        [3] = {}, -- Hybrid (ground & fly)
        [4] = {}, -- Aquatic
        [5] = {}, -- with passengers
    };

    for i=1,GetNumCompanions("MOUNT") do
        creatureID, creatureName, spellId, icon, isSummoned, mountType = GetCompanionInfo("MOUNT", i);
        leadingLetter = ssub(creatureName, 1, 1);

        if ( A.passengerMounts[spellId] ) then
            if ( not A.pamTable.mounts[5][leadingLetter] ) then A.pamTable.mounts[5][leadingLetter] = {}; end

            A.pamTable.mountsIds[5][#A.pamTable.mountsIds[5]+1] = spellId;

            A.pamTable.mounts[5][leadingLetter][#A.pamTable.mounts[5][leadingLetter]+1] =
            {
                id = i,
                spellId = spellId,
                creatureID = creatureID,
                name = creatureName,
                icon = icon,
                isSummoned = isSummoned,
                mountType = mountType,
            };
        end

        cat = A:GetMountCategory(mountType);

        if ( not A.pamTable.mounts[cat][leadingLetter] ) then A.pamTable.mounts[cat][leadingLetter] = {}; end

        A.pamTable.mountsIds[cat][#A.pamTable.mountsIds[cat]+1] = spellId;

        A.pamTable.mounts[cat][leadingLetter][#A.pamTable.mounts[cat][leadingLetter]+1] =
        {
            id = i,
            spellId = spellId,
            creatureID = creatureID,
            name = creatureName,
            icon = icon,
            isSummoned = isSummoned,
            mountType = mountType,
        };
    end
end

function A:BuildBothTables()
    A:BuildPetsTable();
    A:BuildMountsTable();
    A:DebugMessage("Companions available");
end

-- ********************************************************************************
-- Dropdown menu
-- ********************************************************************************

local rotation, rotationTime, isSummoned, buttonIndex;
local function PAMMenu(self, level)
    if ( not level ) then return; end

    A.isBrokerPamMenu = 1;

    if ( level == 1 ) then
        -- Menu title
        self.info.isTitle = 1;
        self.info.text = L["Pets & Mounts"];
        self.info.notCheckable = 1;
        self.info.icon = nil;
        UIDropDownMenu_AddButton(self.info, level);

        -- Set options
        self.info.keepShownOnClick = 1;
        self.info.hasArrow = 1;
        self.info.isTitle = nil;
        self.info.disabled = nil;

        -- Pets menu
        self.info.text = "   "..L["Companions"];
        self.info.value = "PETS";
        self.info.disabled = nil;
        self.info.hasArrow = 1;
        UIDropDownMenu_AddButton(self.info, level);

        -- Mounts menu
        self.info.text = "   "..L["Mounts"];
        self.info.value = "MOUNTS";
        self.info.disabled = nil;
        self.info.hasArrow = 1;
        UIDropDownMenu_AddButton(self.info, level);

        -- Blank separator
        self.info.text = "";
        self.info.disabled = 1;
        self.info.notCheckable = 1;
        self.info.hasArrow = nil;
        UIDropDownMenu_AddButton(self.info, level);

        -- Options menu
        self.info.text = "   "..L["Options"];
        self.info.value = "OPTIONS";
        self.info.disabled = nil;
        self.info.hasArrow = 1;
        UIDropDownMenu_AddButton(self.info, level);

        -- Close
        self.info.text = L["Close"];
        self.info.hasArrow = nil;
        self.info.func = function() CloseDropDownMenus(); end;
        UIDropDownMenu_AddButton(self.info, level);
    elseif (level == 2 ) then
        -- Pets
        if ( UIDROPDOWNMENU_MENU_VALUE == "PETS" ) then
            -- Menu title
            self.info.isTitle = 1;
            self.info.text = L["Companions"];
            self.info.notCheckable = 1;
            self.info.icon = nil;
            self.info.hasArrow = nil;
            UIDropDownMenu_AddButton(self.info, level);

            -- Set options
            self.info.isTitle = nil;
            self.info.keepShownOnClick = 1;
            self.info.hasArrow = 1;
            self.info.disabled = nil;

            for k in A:PairsByKeys(A.pamTable.pets) do
                self.info.text = "   "..k;
                self.info.value = "PETS"..k;
                self.info.icon = nil;
                UIDropDownMenu_AddButton(self.info, level);
            end
        end

        --Mounts
        if ( UIDROPDOWNMENU_MENU_VALUE == "MOUNTS" ) then
            -- Menu title
            self.info.isTitle = 1;
            self.info.text = L["Mounts"];
            self.info.notCheckable = 1;
            self.info.icon = nil;
            self.info.hasArrow = nil;
            UIDropDownMenu_AddButton(self.info, level);

            -- Set options
            self.info.isTitle = nil;
            self.info.keepShownOnClick = 1;
            self.info.hasArrow = 1;
            self.info.disabled = nil;

            for k,v in A:PairsByKeys(A.pamTable.mounts) do
                if ( A:TableNotEmpty(v) ) then
                    self.info.text = "   "..A.mountCat[k];
                    self.info.value = "MOUNTS"..A.mountCat[k];
                    self.info.icon = nil;
                    UIDropDownMenu_AddButton(self.info, level);
                end
            end
        end

        -- Options
        if ( UIDROPDOWNMENU_MENU_VALUE == "OPTIONS" ) then
            -- Show/hide minimap icon
            self.info.text = L["Show or hide minimap icon"];
            self.info.icon = nil;
            self.info.hasArrow = nil;
            self.info.notCheckable = nil;
            self.info.checked = not A.db.profile.ldbi.hide;
            self.info.func = function()
                A.db.profile.ldbi.hide = not A.db.profile.ldbi.hide;
                A:ShowHideMinimap();
                LibStub("AceConfigRegistry-3.0"):NotifyChange("BrokerPAMConfig");
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- Model rotation
            self.info.text = L["Model rotation"];
            self.info.checked = A.db.profile.modelRotation;
            self.info.func = function()
                A.db.profile.modelRotation = not A.db.profile.modelRotation;
                LibStub("AceConfigRegistry-3.0"):NotifyChange("BrokerPAMConfig");
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- Model frame size
            self.info.text = L["Model frame size"];
            self.info.notCheckable = 1;
            self.info.hasArrow = 1;
            self.info.value = "FRAMESIZE";
            self.info.func = function() A.db.profile.modelRotation = not A.db.profile.modelRotation; end;
            UIDropDownMenu_AddButton(self.info, level);
        end
    elseif (level == 3 ) then
        local summonedPet = C_PetJournal.GetSummonedPetID();

        self.info.notCheckable = 1;
        self.info.hasArrow = nil;

        -- Pets
        for k,v in A:PairsByKeys(A.pamTable.pets) do
            buttonIndex = 1;

            for _,vv in ipairs(v) do
                if ( UIDROPDOWNMENU_MENU_VALUE == "PETS"..k ) then
                    if ( vv.petID == summonedPet ) then
                        isSummoned = 1;
                    else
                        isSummoned = nil;
                    end

                    if ( vv.customName ) then
                        self.info.text = vv.customName;
                    else
                        self.info.text = vv.name;
                    end

                    self.info.icon = vv.icon;
                    self.info.disabled = isSummoned;
                    self.info.keepShownOnClick = 1;
                    self.info.func = function() C_PetJournal.SummonPetByID(vv.petID); end;
                    UIDropDownMenu_AddButton(self.info, level);

                    _G["DropDownList3Button"..buttonIndex]:HookScript("OnEnter", function()
                        if ( not A.isBrokerPamMenu or DropDownList2Button1:GetText() == L["Mounts"] ) then
                            A.modelFrame:Hide();

                            return;
                        end

                        -- Model
                        A.modelFrame:SetCreature(vv.creatureID);

                        -- Frame pos
                        local point, relativePoint = A:GetAnchor();
                        A.modelFrame:ClearAllPoints()
                        A.modelFrame:SetPoint(point, DropDownList3, relativePoint, 0, 0);
                        A.modelFrame:Show();
                    end);
                    _G["DropDownList3Button"..buttonIndex]:HookScript("OnLeave", function() A.modelFrame:Hide(); end);
                    buttonIndex = buttonIndex + 1;
                end
            end
        end

        for k,v in ipairs(A.pamTable.mounts) do
            if ( A:TableNotEmpty(v) ) then
                if ( UIDROPDOWNMENU_MENU_VALUE == "MOUNTS"..A.mountCat[k] ) then
                    for kk,vv in A:PairsByKeys(v) do
                        self.info.text = "   "..kk;
                        self.info.value = "MOUNTS"..A.mountCat[k]..kk;
                        self.info.icon = nil;
                        self.info.hasArrow = 1;
                        UIDropDownMenu_AddButton(self.info, level);
                    end
                end
            end
        end

        -- Options
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
                LibStub("AceConfigRegistry-3.0"):NotifyChange("BrokerPAMConfig");
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
                LibStub("AceConfigRegistry-3.0"):NotifyChange("BrokerPAMConfig");
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
                LibStub("AceConfigRegistry-3.0"):NotifyChange("BrokerPAMConfig");
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
                LibStub("AceConfigRegistry-3.0"):NotifyChange("BrokerPAMConfig");
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
                LibStub("AceConfigRegistry-3.0"):NotifyChange("BrokerPAMConfig");
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 350x350
            self.info.text = "350x350";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 350 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 350;
                A.db.profile.modelFrameHeight = 350;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                LibStub("AceConfigRegistry-3.0"):NotifyChange("BrokerPAMConfig");
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- 400x400
            self.info.text = "400x400";
            self.info.checked = function()
                if ( A.db.profile.modelFrameWidth == 400 ) then return 1; end

                return nil;
            end;
            self.info.func = function()
                A.db.profile.modelFrameWidth = 400;
                A.db.profile.modelFrameHeight = 400;
                A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                LibStub("AceConfigRegistry-3.0"):NotifyChange("BrokerPAMConfig");
            end;
            UIDropDownMenu_AddButton(self.info, level);
        end
    elseif (level == 4 ) then
        for k,v in ipairs(A.pamTable.mounts) do
            if ( A:TableNotEmpty(v) ) then
                buttonIndex = 1;

                for kk,vv in A:PairsByKeys(v) do
                    if ( UIDROPDOWNMENU_MENU_VALUE == "MOUNTS"..A.mountCat[k]..kk ) then
                        for kkk,vvv in ipairs(vv) do
                            self.info.text = vvv.name;
                            self.info.icon = vvv.icon;
                            self.info.keepShownOnClick = 1;
                            self.info.func = function() CallCompanion("MOUNT", vvv.id); end;
                            UIDropDownMenu_AddButton(self.info, level);

                            _G["DropDownList4Button"..buttonIndex]:HookScript("OnEnter", function()
                                if ( not A.isBrokerPamMenu ) then
                                    A.modelFrame:Hide();

                                    return;
                                end

                                -- Model
                                A.modelFrame:SetCreature(vvv.creatureID);

                                -- Frame pos
                                local point, relativePoint = A:GetAnchor();
                                A.modelFrame:ClearAllPoints()
                                A.modelFrame:SetPoint(point, DropDownList4, relativePoint, 0, 0);
                                A.modelFrame:Show();
                            end);
                            _G["DropDownList4Button"..buttonIndex]:HookScript("OnLeave", function() A.modelFrame:Hide(); end);
                            buttonIndex = buttonIndex + 1;
                        end
                    end
                end
            end
        end
    end
end

-- ********************************************************************************
-- Callbacks
-- ********************************************************************************

function A:PLAYER_REGEN_DISABLED()
    A.noAutoPet = 1;
    A:DebugMessage("PLAYER_REGEN_DISABLED() - +Combat");
end

function A:PLAYER_REGEN_ENABLED()
    A:AutoPetDelay();
    A:DebugMessage("PLAYER_REGEN_ENABLED() - -Combat");
end

function A:AutoPetDelay()
    A:CancelTimer(A.shiftTimer, 1);
    A.shiftTimer = A:ScheduleTimer("AutoPetDelayCallback", A.db.profile.shiftTimer);
    A.noAutoPet = 1; -- No auto summon when on timer delay
    A:DebugMessage("AutoPetDelay()");
end

function A:AutoPetDelayCallback()
    A.noAutoPet = nil;
    A:AutoPet();
    A:DebugMessage("AutoPetDelayCallback()");
end

function A:UPDATE_STEALTH()
    if ( not A.db.profile.notWhenStealthed ) then return; end

    if ( C_PetJournal.GetSummonedPetID() ) then
        A:AutoPet();
    else
        A:CancelTimer(A.shiftTimer, 1);
        A:ScheduleTimer("AutoPet", A.db.profile.shiftTimer);
    end
    A:DebugMessage("UPDATE_STEALTH()");
end

-- Other stealth buffs, no timed summon here too spammy
function A:UNIT_AURA(self, unit)
    if ( unit == "player") then
        if ( not A.db.profile.notWhenStealthed ) then return; end

        A:AutoPet();
    end
end

function A:LOOT_OPENED()
    A.noAutoPet = 1;
end

function A:LOOT_CLOSED()
    A.noAutoPet = nil;
end

-- function A:UNIT_SPELLCAST_START(...)
    -- print(...)
-- end
-- function A:UNIT_SPELLCAST_SUCCEEDED(...)
    -- print(...)
-- end

-- ********************************************************************************
-- Ace DB & Config panel loader
-- ********************************************************************************

A.aceDefaultDB =
{
    profile =
    {
        debug = nil, -- d
        modelRotation = 1, -- d
        modelFrameWidth = 200, -- d
        modelFrameHeight = 200, -- d
        configModelRotation = 1, -- d
        configModelFrameWidth = 400, -- d
        configModelFrameHeight = 400, -- d
        filterMultiple = 1, -- d
        noFilterCustom = 1, -- d
        autoPet = 1, -- d
        mainTimer = 30, -- d
        shiftTimer = 10, -- d
        alreadyGotPet = 1, -- d
        notWhenStealthed = 1, -- d
        noHybridWhenGround = 1, -- d
        dismountFlying = 1, -- d
        ldbi = {}, -- d
        favoritePets = {}, -- d
        favoriteMounts = -- d
        {
            [1] = {}, -- Ground
            [2] = {}, -- Fly
            [3] = {}, -- Hybrid (ground & fly)
            [4] = {}, -- Aquatic
            [5] = {}, -- with passengers
        },
    }
};

--- Load config addon and remove config loader from Blizzard options frame
function A:LoadAddonConfig()
    local loaded, reason = LoadAddOn("Broker_PAMConfig");

    if ( loaded ) then
        for k,v in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
            if ( v.name == L["Pets & Mounts config loader"] ) then
                INTERFACEOPTIONS_ADDONCATEGORIES[k] = nil;
            end
        end
    elseif ( reason ) then
        reason = _G["ADDON_"..reason];
        A:Message(L["Failed to load configuration, reason: %s."]:format(reason), 1, 1);
    end

    return loaded;
end

--- Add to blizzard options frame a temporary category
function A:AddToBlizzTemp()
    local f  = CreateFrame("Frame");
    f.name = L["Pets & Mounts config loader"];

    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
    b:SetSize(140, 22);
    b:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -20);
    b:SetText(L["Load configuration"]);
    b:SetScript("OnClick", function(self)
        local loaded = A:LoadAddonConfig();

        if ( loaded ) then
            InterfaceAddOnsList_Update();
            InterfaceOptionsFrame_OpenToCategory(A.configFrame);
        end
    end);

    InterfaceOptions_AddCategory(f);
end

--- Display configuration panel
-- Load it if needed
function A:OpenConfigPanel()
    if ( A.AceConfigDialog ) then
        InterfaceOptionsFrame_OpenToCategory(A.configFrame);
    else
        local loaded = A:LoadAddonConfig();

        if ( loaded ) then
            InterfaceOptionsFrame_OpenToCategory(A.configFrame);
        end
    end
end

-- ********************************************************************************
-- Main
-- ********************************************************************************

--- AceAddon callback
-- Called after the addon is fully loaded
function A:OnInitialize()
    -- Database
    A.db = LibStub("AceDB-3.0"):New("pamDB", A.aceDefaultDB);
end

--- AceAddon callback
-- Called during the PLAYER_LOGIN event
function A:OnEnable()
    -- LDB
    if ( LibStub("LibDataBroker-1.1"):GetDataObjectByName("BrokerPAMLDB") ) then
        A.ldbObject = LibStub("LibDataBroker-1.1"):GetDataObjectByName("BrokerPAMLDB");
    else
        A.ldbObject = LibStub("LibDataBroker-1.1"):NewDataObject("BrokerPAMLDB", {
            type = "data source",
            text = L["Pets & Mounts"],
            label = L["Pets & Mounts"],
            icon = "Interface\\ICONS\\Achievement_WorldEvent_Brewmaster",
            tocname = "Broker_PAM",
            OnClick = function(self, button)
                if (button == "LeftButton") then
                    A:RandomPet();
                elseif ( button == "RightButton" ) then
                    A.menuFrame.initialize = PAMMenu;
                    ToggleDropDownMenu(1, nil, A.menuFrame, self, 0, 0);
                    GameTooltip:Hide();
                elseif ( button == "MiddleButton" ) then
                    A:OpenConfigPanel();
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddDoubleLine(A.color["WHITE"]..L["Pets & Mounts"], A.color["GREEN"].."v"..A.version);
                tooltip:AddLine(" ");
                tooltip:AddLine(L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random pet.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open the configuration panel."]);
            end
        });
    end

    -- LDBIcon
    if ( not LibStub("LibDBIcon-1.0"):IsRegistered("BrokerPAMLDBI") ) then LibStub("LibDBIcon-1.0"):Register("BrokerPAMLDBI", A.ldbObject, A.db.profile.ldbi); end

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

    -- Model frame menu
    A.modelFrame = CreateFrame("PlayerModel", "BrokerPamModelFrame", UIParent);
    A.modelFrame:SetFrameStrata("TOOLTIP");
    A.modelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
    A.modelFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }});
    A.modelFrame:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
    A.modelFrame:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
    A.modelFrame:SetScript("OnShow", function(self) self.rotation, self.rotationTime = 0, GetTime(); end);
    A.modelFrame:SetScript("OnHide", function(self) self:ClearModel(); end);
    A.modelFrame:SetScript("OnUpdate", function(self)
        if ( A.db.profile.modelRotation ) then
            local t = GetTime();

            if ( self.rotationTime and self.rotationTime + 0.01 < t ) then
                self:SetRotation(self.rotation);
                self.rotation = self.rotation + 0.01;
                self.rotationTime = t;
            end
        end
    end);
    A.modelFrame:Hide();

    -- Model frame config
    A.modelFrameConfig = CreateFrame("PlayerModel", "BrokerPamModelFrameConfig", UIParent);
    A.modelFrameConfig:SetFrameStrata("TOOLTIP");
    A.modelFrameConfig:SetSize(A.db.profile.configModelFrameWidth, A.db.profile.configModelFrameHeight);
    A.modelFrameConfig:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }});
    A.modelFrameConfig:SetBackdropBorderColor(.6, .6, .6, .9);
    A.modelFrameConfig:SetBackdropColor(.9, .9, .9, .9);
    A.modelFrameConfig:EnableMouse(1);
    A.modelFrameConfig:SetScript("OnShow", function(self) self.rotation, self.rotationTime = 0, GetTime(); end);
    A.modelFrameConfig:SetScript("OnHide", function(self)
        self.manualRotation = nil;
        self.isRotating = nil;
        self.rotation = nil;
        self.rotationTime = nil;
        self:ClearModel();
    end);
    A.modelFrameConfig:SetScript("OnEnter", function(self)
        self.mouseOver = 1;
    end);
    A.modelFrameConfig:SetScript("OnLeave", function(self)
        self.mouseOver = nil;
        self.manualRotation = nil;
        self.isRotating = nil;
    end);
    A.modelFrameConfig:SetScript("OnMouseDown", function(self)
        self.manualRotation = 1;
        self.isRotating = 1;
        self.rotation = self.rotation or 0;
        self.xOrigin = GetCursorPosition();
    end);
    A.modelFrameConfig:SetScript("OnMouseUp", function(self) self.isRotating = nil; end);
    A.modelFrameConfig:SetScript("OnUpdate", function(self)
        if ( self.manualRotation ) then
            if ( self.isRotating ) then
                local x = GetCursorPosition();
                local diff = (x - self.xOrigin) * MODELFRAME_DRAG_ROTATION_CONSTANT;

                self.xOrigin = GetCursorPosition();
                self.rotation = self.rotation + diff;

                if ( self.rotation < 0 ) then
                    self.rotation = self.rotation + (2 * PI);
                end

                if ( self.rotation > (2 * PI) ) then
                    self.rotation = self.rotation - (2 * PI);
                end

                self:SetRotation(self.rotation, false);
            end
        elseif ( A.db.profile.configModelRotation and not self.mouseOver ) then
            local t = GetTime();

            if ( self.rotationTime and self.rotationTime + 0.03 < t ) then
                self:SetRotation(self.rotation);
                self.rotation = self.rotation + 0.03;
                self.rotationTime = t;
            end
        end
    end);
    A.modelFrameConfig:Hide();

    -- Events
    A:RegisterEvent("COMPANION_LEARNED", "BuildBothTables");
    A:RegisterEvent("COMPANION_UNLEARNED", "BuildBothTables");
    A:RegisterEvent("PLAYER_REGEN_DISABLED"); -- Combat.
    A:RegisterEvent("PLAYER_REGEN_ENABLED"); -- Out of combat.
    A:RegisterEvent("PLAYER_ENTERING_WORLD", "AutoPetDelay"); -- Every loading screen.
    A:RegisterEvent("PLAYER_CONTROL_GAINED", "AutoPetDelay"); -- After a cc or fly path.
    A:RegisterEvent("PLAYER_UNGHOST", "AutoPetDelay"); -- It's alive!! (Corpse run, zoning)
    A:RegisterEvent("PLAYER_ALIVE", "AutoPetDelay"); -- It's alive!! (Res, also fire when releasing)
    A:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA", "AutoPetDelay"); -- Quitting a vehicule or a multi mount you control.
    A:RegisterEvent("UNIT_EXITED_VEHICLE", "AutoPetDelay"); -- Exiting a vehicule.
    A:RegisterEvent("UPDATE_STEALTH"); -- Gain or loose stealth.
    A:RegisterEvent("UNIT_AURA"); -- Damn hunters and mages..
    A:RegisterEvent("LOOT_OPENED"); -- Looting. Summoning a pet close the panel.
    A:RegisterEvent("LOOT_CLOSED"); -- End looting.
    --A:RegisterEvent("COMPANION_UPDATE"); -- Do not want to use this, too spammy, seriously too, wtf blizzard with that. And no args? derp (at least unit :/)
    --A:RegisterEvent("UNIT_SPELLCAST_START"); -- Perhaps I will use it for preventing summon in rare case, if it happen when testing.
    --A:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED"); -- Same.

    -- Main timer
    if ( A.db.profile.autoPet ) then A.mainTimer = A:ScheduleRepeatingTimer("AutoPet", A.db.profile.mainTimer); end

    -- Build companions table (need a better way)
    A:ScheduleTimer("BuildBothTables", 5);

    -- Add the config loader to blizzard addon configuration panel
    A:AddToBlizzTemp();
end
