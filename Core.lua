--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Core.lua
-------------------------------------------------------------------------------]]--

-- TODO: fix menu model frame position
-- TODO: prevent pet summon when summoning someone (assist summon to be clear) (lock portal, stones...)
-- TODO: Modify IsSwimming method to return the 3 states, swimming, surface and not swimming, then do something with that

-- Ace libs (<3)
local A = LibStub("AceAddon-3.0"):NewAddon("PetsAndMounts", "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("PetsAndMounts");
A.L = L;

-- Addon's global
_G["PetsAndMountsGlobal"] = A;

-- Globals to locals
local pairs = pairs;
local ipairs = ipairs;
local string = string;
local table = table;
local tostring = tostring;
local type = type;
local time = time;
local _G = _G;
local select = select;
local strsplit = strsplit;
local tContains = tContains;
local bit = bit;

-- GLOBALS: PlaySound, DEFAULT_CHAT_FRAME, GetScreenWidth, GetNumCompanions
-- GLOBALS: GetCursorPosition, UIParent, GetInstanceInfo, UnitGUID, UnitLevel
-- GLOBALS: C_PetJournal, LE_PET_JOURNAL_FLAG_COLLECTED, LE_PET_JOURNAL_FLAG_FAVORITES
-- GLOBALS: LE_PET_JOURNAL_FLAG_NOT_COLLECTED, PetJournalSearchBox
-- GLOBALS: GetCompanionInfo, InCombatLockdown, GetBindingKey, SetOverrideBindingClick
-- GLOBALS: UIDropDownMenu_AddButton, UIDROPDOWNMENU_MENU_VALUE, CloseDropDownMenus
-- GLOBALS: DropDownList2Button1, DropDownList3, CallCompanion, DropDownList4
-- GLOBALS: LoadAddOn, INTERFACEOPTIONS_ADDONCATEGORIES, CreateFrame
-- GLOBALS: InterfaceOptions_AddCategory, InterfaceAddOnsList_Update
-- GLOBALS: InterfaceOptionsFrame_OpenToCategory, DropDownList1, LibStub
-- GLOBALS: TOOLTIP_DEFAULT_COLOR, TOOLTIP_DEFAULT_BACKGROUND_COLOR
-- GLOBALS: hooksecurefunc, GetTime, MODELFRAME_DRAG_ROTATION_CONSTANT
-- GLOBALS: PI, UnitClass, IsShiftKeyDown, ToggleDropDownMenu, GameTooltip
-- GLOBALS: BINDING_HEADER_PETSANDMOUNTS, BINDING_NAME_PETSANDMOUNTSMOUNT
-- GLOBALS: BINDING_NAME_PETSANDMOUNTSMOUNTPASSENGERS, BINDING_NAME_PETSANDMOUNTSMOUNTFLYING
-- GLOBALS: BINDING_NAME_PETSANDMOUNTSMOUNTGROUND, BINDING_NAME_PETSANDMOUNTSMOUNTAQUATIC
-- GLOBALS: PetsAndMountsMenuModelFrame, PetsAndMountsConfigModelFrame
-- GLOBALS: UnitFactionGroup, UnitRace, UIDropDownMenu_SetAnchor

--[[-------------------------------------------------------------------------------
    Common methods
-------------------------------------------------------------------------------]]--

--- Send a message to the chat frame with the addon name colored
-- @param text The message to display
-- @param color Bool, if true will color in red
function A:Message(text, color, silent)
    if ( color == "debug" ) then
        color = A.color["BLUE"];
    elseif ( color ) then
        color = A.color["RED"];
    else
        color = A.color["GREEN"]
    end

    if ( not silent ) then
        PlaySound("TellMessage");
    end

    DEFAULT_CHAT_FRAME:AddMessage(color..L["Pets & Mounts"]..": "..A.color["RESET"]..text);
end

--- Debug message methods
function A:DebugMessageDummy()
end

function A:DebugMessageActiv(text)
    A:Message(text, "debug", 1);
end

A.DebugMessage = A.DebugMessageDummy;

--- Handle the slash command
-- @param input The string returned after the command
function A:SlashCommand(input)
    local arg1, arg2 = strsplit(" ", input);

    if ( arg1 == "" ) then
        A:OpenConfigPanel();
    elseif ( arg1 == "test" ) then
        --
    elseif ( arg1 == "refresh" ) then
        A:BuildBothTables(1);
        A:Message(L["Companions and mounts informations updated."]);
    elseif ( arg1 == "show" )then
        A.db.profile.ldbi.hide = nil;
        A:ShowHideMinimap();
    elseif ( arg1 == "resetzones" ) then
        A.db.global.zonesIDsToName = {};
    end
end

--- Show or hide the minimap icon
function A:ShowHideMinimap()
    if ( A.db.profile.ldbi.hide ) then
        A:Message(L["Minimap icon is hidden if you want to show it back use: /pam or /petsandmounts"], true);
        LibStub("LibDBIcon-1.0"):Hide("PetsAndMountsLDBI");
    else
        LibStub("LibDBIcon-1.0"):Show("PetsAndMountsLDBI");
    end
end

--- pairs function with alphabetic sort
function A:PairsByKeys(t, f)
    local a, i = {}, 0;

    for n in pairs(t) do a[#a+1] = n; end
    table.sort(a, f);

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

--- Return if the pet or mount name exists in the table
-- @param tbl The table
-- @param name The name
-- @return true or false
function A:NameExists(tbl, name)
    local index = 1;

    while tbl[index] do
        if ( name == tbl[index]["name"] ) then return 1; end

        index = index + 1;
   end

   return nil;
end

--- Remove the given item from the given table
function A:TableRemove(tbl, item)
    for i=1,#tbl do
        if ( tbl[i] == item ) then
            table.remove(tbl, i);
            return;
        end
    end
end

--- Will check if a table got a least one entry
-- Dunno why but in Config.lua I use a for loop "for k,v in ipairs(A.pamTable.mounts) do"
-- #v always return 0, even if the table is not empty
function A:TableNotEmpty(tbl)
    for k,v in pairs(tbl) do
        if ( k ) then return 1; end
    end

    return nil;
end

--- Simple shallow copy for copying specialization profiles
-- Shamelessly ripped off from Ace3 AceDB-3.0
-- Did I say I love you guys? :p
function A:CopyTable(src, dest)
    if ( type(dest) ~= "table" ) then dest = {}; end

    if ( type(src) == "table" ) then
        for k,v in pairs(src) do
            if ( type(v) == "table" ) then
                v = A:CopyTable(v, dest[k]);
            end

            dest[k] = v;
        end
    end

    return dest;
end

--- Compare two tables
function A:CompareTables(t1, t2)
    if ( type(t1) ~= "table" or type(t2) ~= "table" ) then return nil; end

    if ( #t1 ~= #t2 ) then return nil; end

    for k,v in pairs(t1) do
        if ( type(v) == "table" ) then
            if ( type(t2[k]) == "table" ) then
                if ( not A:CompareTables(t2[k], v) ) then
                    return nil;
                end
            else
                return nil;
            end
        elseif ( t2[k] ~= v ) then
            return nil;
        end
    end

    return 1;
end

--- Count table entries
function A:TableCount(t)
    if ( type(t) ~= "table" ) then return nil; end

    local count = 0;

    for _ in pairs(t) do
        count = count + 1;
    end

    return count;
end

--- Check if a table contains a value an return the key
function A:TableValueToKey(tbl, val)
    for k,v in pairs(tbl) do
        if ( v == val ) then return k; end
    end

    return nil;
end

--- Return anchor points according to cursor position
-- function A:GetAnchor()
    -- local w = GetScreenWidth();
    -- local x = GetCursorPosition();

    -- w = (w * UIParent:GetEffectiveScale()) / 2;

    -- if ( x > w ) then return "TOPRIGHT", "TOPLEFT"; end

    -- return "TOPLEFT", "TOPRIGHT";
-- end

function A:GetAnchor()
    local ps = UIParent:GetEffectiveScale();
    local px, py = UIParent:GetCenter();
    local x, y = GetCursorPosition();

    px, py = px * ps, py * ps;

    if ( x > px ) then
        if ( y > py ) then
            return "TOPRIGHT", "BOTTOMLEFT";
        else
            return "BOTTOMRIGHT", "TOPLEFT";
        end
    else
        if ( y > py ) then
            return "TOPLEFT", "BOTTOMRIGHT";
        else
            return "BOTTOMLEFT", "TOPRIGHT";
        end
    end
end

--- Return creature ID from spell ID (mount)
-- Used by modified AceGUI widget dropdown
function A:GetCreatureIDFromSpellID(spellID)
    for k,v in ipairs(A.pamTable.mounts) do
        for kk,vv in pairs(v) do
            for kkk,vvv in ipairs(vv) do
                if ( spellID == vvv.spellId ) then
                    return vvv.creatureID;
                end
            end
        end
    end

    return nil;
end

--- Return mount ID from spell ID
function A:GetMountIDFromSpellID(spellID)
    -- Init addon databases
    A:InitializeDB();

    for k,v in ipairs(A.pamTable.mounts) do
        for kk,vv in pairs(v) do
            for kkk,vvv in ipairs(vv) do
                if ( spellID == vvv.spellId ) then
                    return vvv.id;
                end
            end
        end
    end

    return nil;
end

--- Return pet name
function A:GetPetNameByID(id)
    if ( not id ) then return nil; end

    local _, customName, _, _, _, _, _,creatureName = C_PetJournal.GetPetInfoByPetID(id);

    if ( customName ) then
        return customName;
    end

    return creatureName;
end

--- Return mount name
function A:GetMountNameBySpellID(id)
    if ( not id ) then return nil; end

    return select(2, GetCompanionInfo("MOUNT", A:GetMountIDFromSpellID(id)));
end

--- Return the current set
function A:GetCurrentSet(type)
    local setsTable, favTable;

    if ( type == "PET" ) then
        setsTable = A.db.global.savedSets.pets;
        favTable = A.db.profile.favoritePets
    elseif ( type == "MOUNT" ) then
        setsTable = A.db.global.savedSets.mounts;
        favTable = A.db.profile.favoriteMounts;
    else
        return L["None"];
    end

    for k,v in pairs(setsTable) do
        if ( A:CompareTables(favTable, v) ) then
            return k;
        end
    end

    return L["None"];
end

--- Check if it is a GUID
function A:IsGUID(GUID)
    if ( type(GUID) ~= "string" ) then return nil; end
    if ( string.len(GUID) < 18 ) then return nil; end
    if ( not string.match(GUID, "^0x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$") ) then return nil; end

    return 1;
end

--[[-------------------------------------------------------------------------------
    Frames methods
-------------------------------------------------------------------------------]]--

function A:ModelFrameOnUpdate(frame)
    if ( A.db.profile.modelRotation ) then
        local t = GetTime();

        if ( frame.rotationTime and frame.rotationTime + 0.01 < t ) then
            frame:SetRotation(frame.rotation);
            frame.rotation = frame.rotation + 0.01;
            frame.rotationTime = t;
        end
    end
end

function A:ConfigModelFrameOnUpdate(frame)
    if ( frame.manualRotation ) then
        if ( frame.isRotating ) then
            local x = GetCursorPosition();
            local diff = (x - frame.xOrigin) * MODELFRAME_DRAG_ROTATION_CONSTANT;

            frame.xOrigin = GetCursorPosition();
            frame.rotation = frame.rotation + diff;

            if ( frame.rotation < 0 ) then
                frame.rotation = frame.rotation + (2 * PI);
            end

            if ( frame.rotation > (2 * PI) ) then
                frame.rotation = frame.rotation - (2 * PI);
            end

            frame:SetRotation(frame.rotation, false);
        end
    elseif ( A.db.profile.configModelRotation and not frame.mouseOver ) then
        local t = GetTime();

        if ( frame.rotationTime and frame.rotationTime + 0.03 < t ) then
            frame:SetRotation(frame.rotation);
            frame.rotation = frame.rotation + 0.03;
            frame.rotationTime = t;
        end
    end
end

--[[-------------------------------------------------------------------------------
    Database methods
-------------------------------------------------------------------------------]]--

-- Pets filters handling methods
A.petsFilters = {};
A.petsFilters.types = {};
A.petsFilters.sources = {};
function A:StoreAndResetPetsFilters()
    -- Store filters
    A.petsFilters["LE_PET_JOURNAL_FLAG_COLLECTED"] = C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_COLLECTED);
    A.petsFilters["LE_PET_JOURNAL_FLAG_FAVORITES"] = C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_FAVORITES);
    A.petsFilters["LE_PET_JOURNAL_FLAG_NOT_COLLECTED"] = C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_NOT_COLLECTED);

    for i=1,C_PetJournal.GetNumPetTypes() do
        A.petsFilters.types[i] = C_PetJournal.IsPetTypeFiltered(i);
    end

    for i=1,C_PetJournal.GetNumPetSources() do
        A.petsFilters.sources[i] = C_PetJournal.IsPetSourceFiltered(i);
    end

    --if ( PetJournalSearchBox ) then
        A.petsFilters["SearchBoxValue"] = PetJournalSearchBox:GetText();
    --end

    -- Set filters for DB update
    C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_COLLECTED, 1);
    C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_FAVORITES, nil);
    C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_NOT_COLLECTED, nil);
    C_PetJournal.AddAllPetTypesFilter();
    C_PetJournal.AddAllPetSourcesFilter();
    C_PetJournal.ClearSearchFilter();
end

--- Restore pets filters
function A:RestorePetsFilters()
    --if ( PetJournalSearchBox ) then
        PetJournalSearchBox:SetText(A.petsFilters["SearchBoxValue"]);
    --end

    for i=1,C_PetJournal.GetNumPetTypes() do
        C_PetJournal.SetPetTypeFilter(i, not A.petsFilters.types[i]);
    end

    for i=1,C_PetJournal.GetNumPetSources() do
        C_PetJournal.SetPetSourceFilter(i, not A.petsFilters.sources[i]);
    end

    C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_COLLECTED, not A.petsFilters["LE_PET_JOURNAL_FLAG_COLLECTED"]);
    C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_FAVORITES, not A.petsFilters["LE_PET_JOURNAL_FLAG_FAVORITES"]);
    C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_NOT_COLLECTED, not A.petsFilters["LE_PET_JOURNAL_FLAG_NOT_COLLECTED"]);
end

--- Build the companions table
function A:BuildPetsTable(force)
    -- First, check if an update is needed
    local numPets, numOwned = C_PetJournal.GetNumPets();

    if ( not force and A.lastPetsCount == numOwned ) then
        A:DebugMessage("BuildPetsTable() - No update needed");
        return;
    end

    A:DebugMessage(("BuildPetsTable() - Update needed %d %d"):format(A.lastPetsCount, numOwned));

    A.lastPetsCount = numOwned;

    -- Update needed, store filters and set them for update
    A:StoreAndResetPetsFilters();

    A.pamTable.pets = {};
    A.pamTable.petsIds = {};

    for i=1,numPets do
        local petID, _, isOwned, customName, _, _, _, creatureName, icon, _, creatureID = C_PetJournal.GetPetInfoByIndex(i, false);
        --local petID, speciesID, isOwned, customName, level, favorite, isRevoked, name, icon, petType, creatureID, sourceText, description, isWildPet, canBattle = C_PetJournal.GetPetInfoByIndex(index, isWild);

        if ( isOwned ) then
            if ( customName and A.db.profile.noFilterCustom ) then
                local leadingLetter = string.sub(customName, 1, 1);

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
                local leadingLetter = string.sub(creatureName, 1, 1);

                if ( not A.pamTable.pets[leadingLetter] ) then A.pamTable.pets[leadingLetter] = {}; end

                if ( not A:NameExists(A.pamTable.pets[leadingLetter], creatureName)
                --or (A:NameExists(A.pamTable.pets[leadingLetter], creatureName) and not A.db.profile.filterMultiple)
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

    A:RestorePetsFilters();
    A:DebugMessage("BuildPetsTable() - Update successful");
end

--- Return the mount type according to the bit field
-- 0x01 - Ground mount
-- 0x02 - Flying mount
-- 0x04 - Usable at the water's surface
-- 0x08 - Usable underwater
-- 0x10 - Can jump (the turtle mount cannot, for example)
function A:GetMountCategory(bf)
    local ground = bit.band(bf, 0x1) ~= 0 and 1 or nil;
    local fly = bit.band(bf, 0x2) ~= 0 and 1 or nil;
    local surface = bit.band(bf, 0x4) ~= 0 and 1 or nil;
    local water = bit.band(bf, 0x8) ~= 0 and 1 or nil;
    local jump = bit.band(bf, 0x10) ~= 0 and 1 or nil;

    -- 5 Entries x 1
    if ( ground and fly and surface and water and jump ) then -- hybrid - 31
        return 3;
    -- 4 Entries x 5
    elseif ( (ground and fly and surface and water) or (ground and fly and surface and jump) or (ground and fly and water and jump) -- fly - 15 23 27
    or (fly and surface and water and jump) ) then -- fly - 30
        return 2;
    elseif ( (ground and surface and water and jump) ) then -- ground - 29
        return 1;
    -- 3 Entries x 10
    elseif ( (ground and fly and surface) or (ground and fly and water) or (ground and fly and jump) -- fly - 7 11 19
    or (fly and surface and water) or (fly and surface and jump) or (fly and jump and water) ) then-- fly - 14 22 26
        return 2;
    elseif ( (ground and surface and water) or (ground and surface and jump) or (ground and water and jump) ) then -- ground - 13 21 25
        return 1;
    elseif ( water and surface and jump ) then -- aquatic - 28
        return 4;
    -- 2 Entries x 10
    elseif ( (ground and fly) or (fly and surface) or (fly and water) or (fly and jump) ) then -- fly - 3 6 10 18
        return 2;
    elseif ( (ground and surface) or (ground and water) or (ground and jump) or (surface and jump) ) then -- ground - 5 9 17 20
        return 1;
    elseif ( (water and surface) or (water and jump) ) then -- aquatic - 12 24
        return 4;
    -- 1 Entry x 5
    elseif ( ground ) then -- ground - 1
        return 1;
    elseif ( fly ) then -- fly - 2
        return 2;
    elseif ( surface ) then -- fly (going default to fly) - 4
        return 2;
    elseif ( water ) then -- aquatic - 8
        return 4;
    elseif ( jump ) then -- mount (flying mount cannot jump) - 16
        return 1;
    end
end

--- Build the mounts table
function A:BuildMountsTable(force)
    local mountsCount = GetNumCompanions("MOUNT");

    if ( not force and A.lastMountsCount == mountsCount ) then
        A:DebugMessage("BuildMountsTable() - No update needed");
        return;
    end

    A:DebugMessage(("BuildMountsTable() - Update needed %d %d"):format(A.lastMountsCount, mountsCount));

    A.lastMountsCount = mountsCount;

    local creatureID, creatureName, spellId, icon, isSummoned, mountType, leadingLetter, cat;

    -- Rebuilding database, deleting cache
    A.usableMountsCache = nil;

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

    for i=1,mountsCount do
        creatureID, creatureName, spellId, icon, isSummoned, mountType = GetCompanionInfo("MOUNT", i);
        leadingLetter = string.sub(creatureName, 1, 1);

        -- Forced passenger mounts
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

        -- Forced aquatic mounts
        if ( A.aquaticMounts[spellId] ) then
            if ( not A.pamTable.mounts[4][leadingLetter] ) then A.pamTable.mounts[4][leadingLetter] = {}; end

            A.pamTable.mountsIds[4][#A.pamTable.mountsIds[4]+1] = spellId;

            A.pamTable.mounts[4][leadingLetter][#A.pamTable.mounts[4][leadingLetter]+1] =
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

        -- Using the first flying mount found to test swimming area
        if ( (mountType == 23 or mountType == 7 or mountType == 22 or mountType == 21
        or mountType == 6 or mountType == 5 or mountType == 20 or mountType == 4) and not A.swimmingCheckSpellID ) then
            A.swimmingCheckSpellID = spellId;
        end

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

    A:DebugMessage("BuildMountsTable() - Update successful");
end

--- Build companions and mounts tables
function A:BuildBothTables(force)
    A:DebugMessage("BuildBothTables()");
    A:BuildPetsTable(force);
    A:BuildMountsTable(force);
    --A:CleanPetsFavorites();
end

--- Initialize the databases
function A:InitializeDB()
    if ( A.initialized ) then return; end

    A:DebugMessage("Initializing databases");
    A:BuildBothTables();
    A.initialized = 1;
end

--- Remove unknown pets from favorites
function A:CleanPetsFavorites()
    for k,v in ipairs(A.db.profile.favoritePets) do
        if ( not C_PetJournal.GetPetInfoByPetID(v) ) then
            table.remove(A.db.profile.favoritePets, k);
            A:DebugMessage(("CleanPetsFavorites() - Removed petID: %s"):format(v));
        end
    end
end

--[[-------------------------------------------------------------------------------
    Config methods
-------------------------------------------------------------------------------]]--

--- Set main timer
function A:SetMainTimer()
    if ( not A:IsAutoPetEnabled() and A.mainTimer ) then
        A:CancelTimer(A.mainTimer, 1);
    elseif ( A:IsAutoPetEnabled() and A.mainTimer ) then
        A:CancelTimer(A.mainTimer, 1);
        A.mainTimer = A:ScheduleRepeatingTimer("AutoPet", A.db.profile.mainTimer);
    elseif ( A:IsAutoPetEnabled() and not A.mainTimer ) then
        A.mainTimer = A:ScheduleRepeatingTimer("AutoPet", A.db.profile.mainTimer);
    end
end

--- Set combat log event
function A:SetStealthEvents()
    if ( A:IsNotWhenStealthedEnabled() ) then
        A:DebugMessage("SetStealthEvents() - Registering stealth events.");
        A:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        A:RegisterEvent("UPDATE_STEALTH", "AutoPetDelay");
    else
        A:DebugMessage("SetStealthEvents() - UNRegistering stealth events.");
        A:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        A:UnregisterEvent("UPDATE_STEALTH");
    end
end

--- Set options according to current area type
-- Should always set the var if config table is found
-- Set it to nil if no config table
-- @param noSet - bool - Used when launched by SetEverything
function A:SetAutoSummonOverride(noSet)
    if ( not A.db.profile.enableAutoSummonOverride ) then
        A.autoPetOverride = nil;
        A.notWhenStealthedOverride = nil;
        return;
    end

    local name, type = GetInstanceInfo();

    if ( not tContains(A.areaTypes, type) ) then
        A.autoPetOverride = nil;
        A.notWhenStealthedOverride = nil;
        A:DebugMessage(("SetAutoSummonOverride() - Area type %s not supported."):format(tostring(type)));
        return;
    end

    if ( A.db.profile.autoSummonOverride[type] ) then
        if ( A.db.profile.autoSummonOverride[type].autoPet ) then
            A.autoPetOverride = "1";
        else
            A.autoPetOverride = "0";
            A:RevokePet();
        end

        if ( A.db.profile.autoSummonOverride[type].notWhenStealthed ) then
            A.notWhenStealthedOverride = "1";
        else
            A.notWhenStealthedOverride = "0";
        end

        if ( not noSet ) then
            A:SetStealthEvents();
            A:SetMainTimer();
        end

        A:DebugMessage(("SetAutoSummonOverride() - Setting options for %s - auto %s - stealth %s"):format(name, tostring(A.autoPetOverride), tostring(A.notWhenStealthedOverride)));
    else
        A.autoPetOverride = nil;
        A.notWhenStealthedOverride = nil;
    end
end

--- Get auto pet summon option status according to global option or override
function A:IsAutoPetEnabled()
    if ( A.autoPetOverride ) then
        if ( A.autoPetOverride == "1" ) then
            return 1;
        else
            return nil;
        end
    end

    return A.db.profile.autoPet;
end

--- Get not when stealthed option status according to global option or override
function A:IsNotWhenStealthedEnabled()
    if ( A.notWhenStealthedOverride ) then
        if ( A.notWhenStealthedOverride == "1" ) then
            return 1;
        else
            return nil;
        end
    end

    return A.db.profile.notWhenStealthed;
end

--- Set debug message method
function A:SetDebugMessage()
    if ( A.db.profile.debug ) then
        A.DebugMessage = A.DebugMessageActiv;
    else
        A.DebugMessage = A.DebugMessageDummy;
    end
end

--- Set everything
function A:SetEverything()
    -- Set player vars
    A.playerClass = select(2, UnitClass("player"));
    A.playerGUID = UnitGUID("player");
    A.playerLevel = UnitLevel("player");
    A.playerFaction = UnitFactionGroup("player");
    A.playerRace = select(2, UnitRace("player"));

    A:SetDebugMessage();
    A:ShowHideMinimap();
    A:SetStealthEvents();
    A:SetBindings();
    A:SetButtonsMacro();
    A:SetAutoSummonOverride(1);
    A:SetMainTimer();
    A:SetButtons();
    A:SetPostClickMacro();
end

--[[-------------------------------------------------------------------------------
    Dropdown menu
-------------------------------------------------------------------------------]]--

local rotation, rotationTime, isSummoned, buttonIndex;
local function PAMMenu(self, level)
    if ( not level ) then return; end

    A:InitializeDB();

    A.isPetsAndMountsMenu = 1;

    if ( level == 1 ) then
        -- Menu title
        self.info.isTitle = 1;
        self.info.text = L["Pets & Mounts"];
        self.info.notCheckable = 1;
        self.info.icon = nil;
        self.info.hasArrow = nil;
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
            -- Pet auto summon
            self.info.text = L["Auto summon"];
            self.info.icon = nil;
            self.info.hasArrow = nil;
            self.info.notCheckable = nil;
            self.info.checked = A.db.profile.autoPet;
            self.info.func = function()
                A.db.profile.autoPet = not A.db.profile.autoPet;
                A:SetMainTimer();
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- Not when stealthed
            self.info.text = L["Revoke when stealthed"];
            self.info.checked = A.db.profile.notWhenStealthed;
            self.info.func = function()
                A.db.profile.notWhenStealthed = not A.db.profile.notWhenStealthed;
                A:SetStealthEvents();
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- Show/hide minimap icon
            self.info.text = L["Show or hide minimap icon"];
            self.info.checked = not A.db.profile.ldbi.hide;
            self.info.func = function()
                A.db.profile.ldbi.hide = not A.db.profile.ldbi.hide;
                A:ShowHideMinimap();
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- Model rotation
            self.info.text = L["Model rotation"];
            self.info.checked = A.db.profile.modelRotation;
            self.info.func = function()
                A.db.profile.modelRotation = not A.db.profile.modelRotation;
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
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
        local summonedPet = C_PetJournal.GetSummonedPetGUID();

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
                    self.info.hasArrow = nil;
                    self.info.func = function() A:SummonPet(vv.petID); end;
                    UIDropDownMenu_AddButton(self.info, level);

                    _G["DropDownList3Button"..buttonIndex]:HookScript("OnEnter", function()
                        if ( not A.isPetsAndMountsMenu or DropDownList2Button1:GetText() == L["Mounts"] ) then
                            A.menuModelFrame:Hide();

                            return;
                        end

                        -- Model
                        A.menuModelFrame:SetCreature(vv.creatureID);

                        -- Frame pos
                        local point, relativePoint = A:GetAnchor();
                        A.menuModelFrame:ClearAllPoints();
                        A.menuModelFrame:SetPoint(point, DropDownList3, relativePoint, 0, 0);
                        A.menuModelFrame:Show();
                    end);
                    _G["DropDownList3Button"..buttonIndex]:HookScript("OnLeave", function() A.menuModelFrame:Hide(); end);
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
                A.menuModelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
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
                A.menuModelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
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
                A.menuModelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
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
                A.menuModelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
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
                A.menuModelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
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
                A.menuModelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
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
                A.menuModelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                if ( A.AceConfigRegistry ) then
                    A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
                end
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
                            self.info.hasArrow = nil;
                            self.info.func = function() CallCompanion("MOUNT", vvv.id); end;
                            UIDropDownMenu_AddButton(self.info, level);

                            _G["DropDownList4Button"..buttonIndex]:HookScript("OnEnter", function()
                                if ( not A.isPetsAndMountsMenu ) then
                                    A.menuModelFrame:Hide();

                                    return;
                                end

                                -- Model
                                A.menuModelFrame:SetCreature(vvv.creatureID);

                                -- Frame pos
                                local point, relativePoint = A:GetAnchor();
                                A.menuModelFrame:ClearAllPoints();
                                A.menuModelFrame:SetPoint(point, DropDownList4, relativePoint, 0, 0);
                                A.menuModelFrame:Show();
                            end);
                            _G["DropDownList4Button"..buttonIndex]:HookScript("OnLeave", function() A.menuModelFrame:Hide(); end);
                            buttonIndex = buttonIndex + 1;
                        end
                    end
                end
            end
        end
    end
end

--[[-------------------------------------------------------------------------------
    Callbacks
-------------------------------------------------------------------------------]]--

function A:PLAYER_REGEN_DISABLED()
    A:DebugMessage("PLAYER_REGEN_DISABLED() - +Combat");
    A:CancelTimer(A.shiftTimer, 1);
    A.noAutoPet = 1;
end

function A:PLAYER_REGEN_ENABLED()
    A:DebugMessage("PLAYER_REGEN_ENABLED() - -Combat");

    if ( A.delayedBindings ) then
        A:SetBindings();
        A.delayedBindings = nil;
    end

    if ( A.delayedButtonsMacro ) then
        A:SetButtonsMacro();
        A.delayedButtonsMacro = nil;
    end

    A:AutoPetDelay();
end

function A:AutoPetDelay()
    A:DebugMessage("AutoPetDelay()");
    A:CancelTimer(A.shiftTimer, 1);
    A.shiftTimer = A:ScheduleTimer("AutoPetDelayCallback", A.db.profile.shiftTimer);
    A.noAutoPet = 1; -- No auto summon when on timer delay
end

function A:AutoPetDelayCallback()
    A:DebugMessage("AutoPetDelayCallback()");
    A.noAutoPet = nil;
    A:AutoPet();
end

-- Using this because it is a little faster than event UPDATE_STEALTH
-- And it prevent using UNIT_AURA
A.stealthSpellsIDs =
{
    5215, -- Druid's Prowl
    --102280, -- Druid's Displacer Beast -- No longer cast prowl
    1784, -- Rogue's Stealth
    1856, -- Rogue's Vanish
    51753, -- Hunter's Camouflage
    66, -- Mage's Invisibility
    110960, -- Mage's Greater Invisibility
    58984, -- Night Elf's Shadowmeld
    112833, -- Priest's Spectral Guise
};
function A:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    --local timestamp, type, _, sourceGUID = ...;
    local _, type, _, sourceGUID = ...;

    if ( sourceGUID == A.playerGUID and type == "SPELL_CAST_SUCCESS" ) then
        local spellID = select(12, ...);

        if ( tContains(A.stealthSpellsIDs, spellID) ) then
            A:DebugMessage("COMBAT_LOG_EVENT_UNFILTERED() - Stealth/invis spell cast, revoking pet.");
            A.stealthCasted = 1;
            A:RevokePet();
        end
    end
end

-- Imo the best way to know if a new pet or mount was learned
--BATTLE_PET_NEW_PET = "%s has been added to your pet journal!";
A.battlePetNewPet = string.gsub(BATTLE_PET_NEW_PET, "%.", "%%.");
A.battlePetNewPet = string.gsub(A.battlePetNewPet, "%%s", "(.+)");

--ERR_LEARN_COMPANION_S = "You have added the pet %s to your collection.";
A.errLearnCompanion = string.gsub(ERR_LEARN_COMPANION_S, "%.", "%%.");
A.errLearnCompanion = string.gsub(A.errLearnCompanion, "%%s", "(.+)");

--ERR_LEARN_MOUNT_S = "You have added the mount %s to your collection.";
A.errLearnMount = string.gsub(ERR_LEARN_MOUNT_S, "%.", "%%.");
A.errLearnMount = string.gsub(A.errLearnMount, "%%s", "(.+)");

function A:CHAT_MSG_SYSTEM(event, msg)
    -- Pets messages
    local pet = string.match(msg, A.battlePetNewPet);

    if ( not pet ) then pet = string.match(msg, A.errLearnCompanion); end

    if ( pet ) then
        A:DebugMessage(("CHAT_MSG_SYSTEM() - New pet %s."):format(pet));
        A:BuildPetsTable();
        A:CleanPetsFavorites();
    end

    -- Mounts messages
    local mount = string.match(msg, A.errLearnMount);

    if ( mount ) then
        A:DebugMessage(("CHAT_MSG_SYSTEM() - New mount %s."):format(mount));
        A:BuildMountsTable();
    end
end

function A:PLAYER_ENTERING_WORLD()
    A:AutoPetDelay();
    A:SetAutoSummonOverride();
    --A:SetPostClickMacro();
    A:GetCurrentMapID();
end

function A:ZONE_CHANGED_NEW_AREA()
    A:GetCurrentMapID();
    A:AutoPetDelay();

    if ( A.AceConfigRegistry ) then
        A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
    end
end

-- function A:MINIMAP_UPDATE_TRACKING()
    -- A:GetCurrentMapID();
    -- A:UnregisterEvent("MINIMAP_UPDATE_TRACKING");
-- end

function A:PLAYER_LEVEL_UP(event, level, ...)
    A.playerLevel = level;
    A:SetPostClickMacro();
end

--[[-------------------------------------------------------------------------------
    Ace DB and database revision methods
-------------------------------------------------------------------------------]]--

A.aceDefaultDB =
{
    global =
    {
        savedSets =
        {
            pets = {},
            mounts = {},
        },
        zonesIDsToName =
        {
        },
    },
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
        mainTimer = 45, -- d
        shiftTimer = 20, -- d
        alreadyGotPet = 1, -- d
        notWhenStealthed = 1, -- d
        noHybridWhenGround = 1, -- d
        dismountFlying = 1, -- d
        areaMounts = 1, -- d
        hauntedMemento = 1, -- d
        magicBroom = 1, -- d
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
        forceOne = -- d
        {
            pet = nil,
            mount =
            {
                [1] = nil, -- Ground
                [2] = nil, -- Fly
                [3] = nil, -- Hybrid (ground & fly)
                [4] = nil, -- Aquatic
                [5] = nil, -- with passengers
            },
        },
        savedSets = -- d
        {
            pets = {},
            mounts = {},
        },
        enableAutoSummonOverride = nil, -- d
        autoSummonOverride = -- d
        {
        },
        classesMacrosEnabled = 1, -- d
        dockButton = nil, -- d
        PetsAndMountsSecureButtonPets = -- d
        {
            hide = nil,
            lock = nil,
            tooltip = 1,
            scale = 1,
            anchor =
            {
                point = "CENTER",
                relativeTo = UIParent,
                relativePoint = "CENTER",
                offX = 20,
                offY = 0,
            },
        },
        PetsAndMountsSecureButtonMounts = -- d
        {
            hide = nil,
            lock = nil,
            tooltip = 1,
            scale = 1,
            anchor =
            {
                point = "CENTER",
                relativeTo = UIParent,
                relativePoint = "CENTER",
                offX = -20,
                offY = 0,
            },
        },
        petByMapID = -- d
        {
        },
        mountByMapID = -- d
        {
            [1] = {}, -- Ground
            [2] = {}, -- Fly
            [3] = {}, -- Hybrid (ground & fly)
            [4] = {}, -- Aquatic
            [5] = {}, -- with passengers
        },
    },
};

-- Database revision handling
function A:DatabaseRevisionCheck()
    if ( A.db.global.databaseRevision ) then
        if ( A.db.global.databaseRevision < 2 ) then
            A:Message(L["Database update to revision %d needed."]:format(2), 1, 1);
            A:DatabaseRevision2();
        end

        A.db.global.databaseRevision = A.databaseRevision;
    else -- Full update
        A:Message(L["A full database update is needed."], 1, 1);
        A:DatabaseRevision2();
        A.db.global.databaseRevision = A.databaseRevision;
    end
end

-- Rev 2, added global scope db
-- need to move saved sets to global scope
function A:DatabaseRevision2()
    for k,v in ipairs(A.db:GetProfiles()) do
        if ( A.db.profiles[v] and A.db.profiles[v].savedSets and A.db.profiles[v].savedSets.pets ) then
            for kk,vv in pairs(A.db.profiles[v].savedSets.pets) do
                local setName = kk;
                local index = 2;

                while A.db.global.savedSets.pets[setName] do
                    setName = kk.." - "..index;
                    A:Message(L["A set named %s already exists, renaming it to %s."]:format(kk, setName), 1, 1);
                    index = index + 1;
                end

                A.db.global.savedSets.pets[setName] = vv;
            end
        end

        if ( A.db.profiles[v] and A.db.profiles[v].savedSets and A.db.profiles[v].savedSets.mounts ) then
            for kk,vv in pairs(A.db.profiles[v].savedSets.mounts) do
                local setName = kk;
                local index = 2;

                while A.db.global.savedSets.mounts[setName] do
                    setName = kk.." - "..index;
                    index = index + 1;
                end

                A.db.global.savedSets.mounts[setName] = vv;
            end
        end

        if ( A.db.profiles[v] and A.db.profiles[v].savedSets ) then
            A.db.profiles[v].savedSets = nil;
        end
    end

    A:Message(L["Database updated to revision %d."]:format(2));
end

--- Remove old entries from database
function A:RemoveDatabaseOldEntries()
    -- Check for integer in fav pets, Blizzard used GUID instead of ID in 5.1
    for k,v in ipairs(A.db:GetProfiles()) do
        if ( A.db.profiles[v] and A.db.profiles[v].favoritePets ) then
            for kk,vv in pairs(A.db.profiles[v].favoritePets) do
                if ( type(vv) == "number" ) then
                    A.db.profiles[v].favoritePets[kk] = nil;
                end
            end
        end
    end

    for k,v in pairs(A.db.global.savedSets) do
        for kk,vv in pairs(v) do
            if ( vv[1] and type(vv[1]) == "number" ) then
                A.db.global.savedSets[k][kk] = nil;
                A:Message(L["Deleted set %s, due to Blizzard modification to companions code."]:format(kk), 1, 1);
            end
        end
    end
end

--[[-------------------------------------------------------------------------------
    Config panel loader
-------------------------------------------------------------------------------]]--

--- Load config addon and remove config loader from Blizzard options frame
function A:LoadAddonConfig()
    A:DebugMessage("LoadAddonConfig() - Loading configuration addon");

    local loaded, reason = LoadAddOn("PetsAndMountsConfig");

    if ( loaded ) then
        local categories = INTERFACEOPTIONS_ADDONCATEGORIES;
        local cat;

        for i=1,#categories do
            if ( categories[i].name == L["Pets & Mounts config loader"] ) then
                cat = i;
            end
        end

        table.remove(categories, cat);

        A:DebugMessage("LoadAddonConfig() - Successfully loaded configuration addon");
    elseif ( reason ) then
        reason = _G["ADDON_"..reason];
        A:Message(L["Failed to load configuration, reason: %s."]:format(reason), 1, 1);
    end

    return loaded;
end

--- Add to blizzard options frame a temporary category
function A:AddToBlizzTemp()
    local f  = CreateFrame("Frame", "PetsAndMountsTempConfigFrame");
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

--[[-------------------------------------------------------------------------------
    Main
-------------------------------------------------------------------------------]]--

--- AceAddon callback
-- Called after the addon is fully loaded
function A:OnInitialize()
    -- Database
    A.db = LibStub("AceDB-3.0"):New("pamDB", A.aceDefaultDB, true);
    A:DatabaseRevisionCheck();
    A:RemoveDatabaseOldEntries();

    -- Profile modification callbacks
    A.db.RegisterCallback(self, "OnProfileChanged", "SetEverything");
    A.db.RegisterCallback(self, "OnProfileCopied", "SetEverything");
    A.db.RegisterCallback(self, "OnProfileReset", "SetEverything");

    -- Menu frame & table
    A.menuFrame = CreateFrame("Frame", "PetsAndMountsMenuFrame");
    A.menuFrame.displayMode = "MENU";
    A.menuFrame.info = {};
    A.menuFrame.initialize = PAMMenu;
    DropDownList1:HookScript("OnHide", function(self)
        A.isPetsAndMountsMenu = nil;
    end);

    -- Menu model frame
    A.menuModelFrame = PetsAndMountsMenuModelFrame;
    A.menuModelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);

    -- Config model frame
    A.configModelFrame = PetsAndMountsConfigModelFrame;
    A.configModelFrame:SetSize(A.db.profile.configModelFrameWidth, A.db.profile.configModelFrameHeight);

    -- DB auto update hooks
    hooksecurefunc(C_PetJournal, "CagePetByID", function()
        A:DebugMessage("Hook - C_PetJournal.CagePetByID() called");
        A:BuildPetsTable();
    end);
    hooksecurefunc(C_PetJournal, "ReleasePetByID", function()
        A:DebugMessage("Hook - C_PetJournal.ReleasePetByID() called");
        A:BuildPetsTable();
    end);
    hooksecurefunc(C_PetJournal, "SetCustomName", function()
        A:DebugMessage("Hook - C_PetJournal.SetCustomName() called");
        A:BuildPetsTable();
    end);

    -- LDB
    A.ldbObject = LibStub("LibDataBroker-1.1"):NewDataObject("PetsAndMountsLDB", {
        type = "data source",
        text = L["Pets & Mounts"],
        label = L["Pets & Mounts"],
        icon = "Interface\\ICONS\\Achievement_WorldEvent_Brewmaster",
        tocname = "PetsAndMounts",
        OnClick = function(self, button)
            if (button == "LeftButton") then
                if ( IsShiftKeyDown() ) then
                    A:RevokePet();
                else
                    A:RandomPet();
                end
            elseif ( button == "RightButton" ) then
                UIDropDownMenu_SetAnchor(A.menuFrame, nil, nil, nil, nil, nil);
                ToggleDropDownMenu(1, nil, A.menuFrame, self, 0, 0);
                GameTooltip:Hide();
            elseif ( button == "MiddleButton" ) then
                A:OpenConfigPanel();
            end
        end,
        OnTooltipShow = function(tooltip)
            local currentSet;

            tooltip:AddDoubleLine(A.color["WHITE"]..L["Pets & Mounts"], A.color["GREEN"].."v"..A.version);
            tooltip:AddLine(" ");

            currentSet = A:GetCurrentSet("PET");
            if ( currentSet == L["None"] ) then
                currentSet = A.color["RED"]..currentSet;
            else
                currentSet = A.color["GREEN"]..currentSet;
            end

            tooltip:AddLine(L["Companions set in use: %s."]:format(currentSet));
            tooltip:AddLine(L["Auto summon companion is %s."]:format(A:IsAutoPetEnabled() and A.color["GREEN"]..L["On"] or A.color["RED"]..L["Off"]));
            tooltip:AddLine(L["Not when stealthed is %s."]:format(A:IsNotWhenStealthedEnabled() and A.color["GREEN"]..L["On"] or A.color["RED"]..L["Off"]));
            tooltip:AddLine(L["Forced companion: %s"]:format(A.db.profile.forceOne.pet and A.color["GREEN"]..A:GetPetNameByID(A.db.profile.forceOne.pet) or A.color["RED"]..L["None"]));
            tooltip:AddLine(" ");

            currentSet = A:GetCurrentSet("MOUNT");
            if ( currentSet == L["None"] ) then
                currentSet = A.color["RED"]..currentSet;
            else
                currentSet = A.color["GREEN"]..currentSet;
            end

            tooltip:AddLine(L["Mounts set in use: %s."]:format(currentSet));
            tooltip:AddLine(L["Forced aquatic mount: %s"]:format(A.db.profile.forceOne.mount[4] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[4]) or A.color["RED"]..L["None"]));
            tooltip:AddLine(L["Forced ground mount: %s"]:format(A.db.profile.forceOne.mount[1] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[1]) or A.color["RED"]..L["None"]));
            tooltip:AddLine(L["Forced fly mount: %s"]:format(A.db.profile.forceOne.mount[2] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[2]) or A.color["RED"]..L["None"]));
            tooltip:AddLine(L["Forced hybrid mount: %s"]:format(A.db.profile.forceOne.mount[3] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[3]) or A.color["RED"]..L["None"]));
            tooltip:AddLine(L["Forced passenger mount: %s"]:format(A.db.profile.forceOne.mount[5] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[5]) or A.color["RED"]..L["None"]));

            tooltip:AddLine(" ");
            tooltip:AddLine(L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random companion.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Revoke current companion.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open the configuration panel."]);
        end
    });

    -- LDBIcon
    LibStub("LibDBIcon-1.0"):Register("PetsAndMountsLDBI", A.ldbObject, A.db.profile.ldbi);

    -- Add the config loader to blizzard addon configuration panel
    A:AddToBlizzTemp();
end

--- AceAddon callback
-- Called during the PLAYER_LOGIN event
function A:OnEnable()
    -- Slash command
    A:RegisterChatCommand("petsandmounts", "SlashCommand");
    A:RegisterChatCommand("pam", "SlashCommand");

    -- Events
    -- Auto summon pet events
    A:RegisterEvent("PLAYER_REGEN_DISABLED"); -- Combat.
    A:RegisterEvent("PLAYER_REGEN_ENABLED"); -- Out of combat.
    A:RegisterEvent("PLAYER_ENTERING_WORLD"); -- Every loading screen.
    A:RegisterEvent("PLAYER_CONTROL_GAINED", "AutoPetDelay"); -- After a cc or fly path.
    A:RegisterEvent("PLAYER_UNGHOST", "AutoPetDelay"); -- It's alive!! (Corpse run, zoning)
    A:RegisterEvent("PLAYER_ALIVE", "AutoPetDelay"); -- It's alive!! (Res, also fire when releasing)
    A:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA", "AutoPetDelay"); -- Quitting a vehicule or a multi mount you control.
    A:RegisterEvent("UNIT_EXITED_VEHICLE", "AutoPetDelay"); -- Exiting a vehicule.
    A:RegisterEvent("UPDATE_BINDINGS", "SetBindings");
    -- Db auto update events
    A:RegisterEvent("CHAT_MSG_SYSTEM");
    A:RegisterEvent("COMPANION_LEARNED", "BuildBothTables");
    A:RegisterEvent("COMPANION_UNLEARNED", "BuildBothTables");
    -- Update post click macros
    A:RegisterEvent("PLAYER_LEVEL_UP");
    -- Update current mapID
    A:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    --A:RegisterEvent("MINIMAP_UPDATE_TRACKING"); -- Using this for the first current mapID update

    -- Set everything
    A:SetEverything();
end
