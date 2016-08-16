--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Core.lua
-------------------------------------------------------------------------------]]--

-- TODO: prevent pet summon when summoning someone (assist summon to be clear) (lock portal, stones...)

-- 1.8.2 changelog
--[[
Fixed target/mouseover mount copy summon -- Pushed
Fixed pet summon when clicked error
Fixed area sets errors
Fixed an error with hybrid selection
Finally fixed login bug with Blizzard_Collections by adding a loader addon, which will load Blizzard_Collection, which will load PAM, yo dawg
Fixed and updated pets filters store/restore
]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- Globals to locals
local strsplit = strsplit;
local pairs = pairs;
local table = table;
local type = type;
local ipairs = ipairs;
local select = select;
local string = string;
local tonumber = tonumber;
local math = math;
local bit = bit;
local tContains = tContains;
local unpack = unpack;
local tostring = tostring;
local _G = _G;

-- GLOBALS: LibStub, GetScreenWidth, GetCursorPosition, UIParent, C_PetJournal, GetCompanionInfo
-- GLOBALS: UnitInVehicle, UnitHasVehicleUI, GetTime, MODELFRAME_DRAG_ROTATION_CONSTANT, PI
-- GLOBALS: LE_PET_JOURNAL_FILTER_COLLECTED, LE_PET_JOURNAL_FLAG_FAVORITES, LE_PET_JOURNAL_FILTER_NOT_COLLECTED
-- GLOBALS: PetJournalSearchBox, SEARCH, NUM_GLYPH_SLOTS, GetGlyphSocketInfo, GetNumCompanions
-- GLOBALS: GetMapNameByID, WorldMapFrame, SetMapToCurrentZone, GetCurrentMapAreaID, GetInstanceInfo
-- GLOBALS: UnitClass, UnitGUID, UnitLevel, UnitFactionGroup, UnitRace, UnitName, UIDropDownMenu_AddButton
-- GLOBALS: UIDROPDOWNMENU_MENU_VALUE, CloseDropDownMenus, DropDownList4, CallCompanion, InCombatLockdown
-- GLOBALS: IsInGuild, GetNumGroupMembers, IsInRaid, LoadAddOn, INTERFACEOPTIONS_ADDONCATEGORIES, CreateFrame
-- GLOBALS: InterfaceOptions_AddCategory, InterfaceAddOnsList_Update, InterfaceOptionsFrame_OpenToCategory
-- GLOBALS: GetCurrentBindingSet, GetBindingKey, SetBinding, SaveBindings, DropDownList1, IsShiftKeyDown
-- GLOBALS: PetsAndMountsMenuModelFrame, PetsAndMountsConfigModelFrame, PetsAndMountsSearchFrame, GameTooltip
-- GLOBALS: PetsAndMountsPopupMessageFrame, UIDropDownMenu_SetAnchor, ToggleDropDownMenu, UnitBuff
-- GLOBALS: GetSpecialization, GetSpecializationInfo, GetItemInfo, C_MountJournal, UnitFullName
-- GLOBALS: PetsAndMountsSecureButtonPets, PetsAndMountsSecureButtonMounts, time, GetActiveSpecGroup
-- GLOBALS: GetMaxTalentTier, GetTalentTierInfo

--[[-------------------------------------------------------------------------------
    Common methods
-------------------------------------------------------------------------------]]--

--- Fake refresh config method
function A:NotifyChangeForAll()
end

--- Handle the slash command
-- @param input The string returned after the command
function A:SlashCommand(input)
    local arg1, arg2 = strsplit(" ", input);

    if ( arg1 == "" ) then
        A:OpenConfigPanel();
    --@debug@
    elseif ( arg1 == "test" ) then
        --local remoteStage, remoteVersion = strsplit(":", message);
        --local remoteVersion, remoteRevision = A:GetAddonVersion(remoteVersion);
        local localVersion, localRevision = A:GetAddonVersion(A.version);
        local remoteVersion = 1.7
        local remoteRevision = 9
        local remoteStage = "Release"
        local who = "Robert"
        A.addonUpdateMessageInfo = {remoteVersion, remoteRevision, remoteStage};
        A:NotifyChangeForAll();
        A:Message(L["A newer version of Pets & Mounts is available. You have version %s revision %s %s, %s got version %s revision %s %s. Get it on Curse at %s or with the Curse client."]
        :format(tostring(localVersion), tostring(localRevision), L[A.versionStage], who, tostring(remoteVersion), tostring(remoteRevision), L[remoteStage], A.color.BLUE.."|HPAM:config:About|h["..L["Link"].."]|h|r"));
    --@end-debug@
    elseif ( arg1 == "refresh" ) then
        A:BuildBothTables(1);
        A:Message(L["Companions and mounts informations updated."]);
    elseif ( arg1 == "show" )then
        A.db.profile.ldbi.hide = nil;
        A:ShowHideMinimap();
    elseif ( arg1 == "resetzones" ) then
        A.db.global.zonesIDsToName = {};
    --@debug@
    elseif ( arg1 == "mapids" ) then
        A:ProcessMapID();
    elseif ( arg1 == "surface" ) then
        A:ProcessSurfaceSpells();
    elseif ( arg1 == "mcat" ) then
        A:ProcessMountsCategories();
    elseif ( arg1 == "mess" ) then
        A:PopMessageFrame("newBindingsSystemv150");
    --@end-debug@
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
-- @return The key int
function A:NameExists(tbl, name)
    if ( not tbl or type(tbl) ~= "table" ) then
        return nil;
    end

    local index = 1;

    while tbl[index] do
        if ( name == tbl[index]["name"] ) then return index; end

        index = index + 1;
   end

   return nil;
end

--- Remove the given item from the given table
function A:TableRemove(tbl, item)
    if ( type(tbl) == "table" ) then
        for i=1,#tbl do
            if ( tbl[i] == item ) then
                table.remove(tbl, i);
                return 1;
            end
        end
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
-- function A:CompareTables(t1, t2)
    -- if ( type(t1) ~= "table" or type(t2) ~= "table" ) then return nil; end

    -- if ( #t1 ~= #t2 ) then return nil; end

    -- for k,v in pairs(t1) do
        -- if ( type(v) == "table" ) then
            -- if ( type(t2[k]) == "table" ) then
                -- if ( not A:CompareTables(t2[k], v) ) then
                    -- return nil;
                -- end
            -- else
                -- return nil;
            -- end
        -- elseif ( t2[k] ~= v ) then
            -- return nil;
        -- end
    -- end

    -- return 1;
-- end

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
function A:GetMenuModelFrameAnchor()
    local w = GetScreenWidth();
    local x = GetCursorPosition();

    w = (w * UIParent:GetEffectiveScale()) / 2;

    if ( x > w ) then return "TOPRIGHT", "TOPLEFT"; end

    return "TOPLEFT", "TOPRIGHT";
end

function A:GetMenuButtonAnchor()
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
    -- Init addon databases
    A:InitializeDB();

    for k,v in ipairs(A.pamTable.mounts) do
        for kk,vv in pairs(v) do
            for kkk,vvv in ipairs(vv) do
                if ( spellID == vvv.spellID ) then
                    return vvv.creatureID;
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

--- Return mount ID from spell ID
function A:GetMountIDFromSpellID(spellID)
    if ( not A.mountsSpellIDToIDCache ) then
        A.mountsSpellIDToIDCache = {};
    end

    if ( A.mountsSpellIDToIDCache[spellID] ) then
        return A.mountsSpellIDToIDCache[spellID];
    end

    local numMounts = C_MountJournal.GetNumMounts();
    local _, spellIDMatch;

    for i=1,numMounts do
        _, spellIDMatch = C_MountJournal.GetDisplayedMountInfo(i);

        if ( spellID == spellIDMatch ) then
            A.mountsSpellIDToIDCache[spellID] = i;
            return i;
        end
    end

    return nil;
end

--- Return mount ID from spell ID
function A:GetMountMountIDFromSpellID(spellID)
    if ( not spellID ) then return nil; end

    if ( not A.mountsSpellIDToMountIDCache ) then
        A.mountsSpellIDToMountIDCache = {};
    end

    if ( A.mountsSpellIDToMountIDCache[spellID] ) then
        return A.mountsSpellIDToMountIDCache[spellID];
    end

    local numMounts = C_MountJournal.GetNumMounts();
    local _, spellIDMatch, mountID;

    for i=1,numMounts do
        _, spellIDMatch, _, _, _, _, _, _, _, _, _, mountID = C_MountJournal.GetDisplayedMountInfo(i);

        if ( spellID == spellIDMatch ) then
            A.mountsSpellIDToMountIDCache[spellID] = mountID;
            return mountID;
        end
    end

    return nil;
end

--- Return mount name
function A:GetMountNameBySpellID(spellID)
    local id = A:GetMountIDFromSpellID(spellID);

    if ( not id ) then return nil; end

    return select(1, C_MountJournal.GetDisplayedMountInfo(id));
end

--- Check if the player is using a vehicle
function A:IsPlayerInVehicle()
    if ( UnitInVehicle("player") ) then return 1; end

    if ( UnitHasVehicleUI("player") ) then return 1; end

    return nil;
end

--- Return the addon version
-- @param version Full version number (string)
-- @return version - float, revision - int
-- ex: 1.4.1 => 1.4 float 1 int
function A:GetAddonVersion(version)
    local revision;

    version, revision = string.match(version, "^(%d+%.%d+)%.(%d+)$");

    return tonumber(version), tonumber(revision);
end

--- Round function (http://lua-users.org/wiki/SimpleRound)
-- @param num The number to round
-- @param idp Decimal places
function A:Round(num, idp)
    local mult = 10^(idp or 0);
    return math.floor(num * mult + 0.5) / mult;
end

--- Color percent to hex
local b16 =
{
    [0] = "0",
    [1] = "1",
    [2] = "2",
    [3] = "3",
    [4] = "4",
    [5] = "5",
    [6] = "6",
    [7] = "7",
    [8] = "8",
    [9] = "9",
    [10] = "a",
    [11] = "b",
    [12] = "c",
    [13] = "d",
    [14] = "e",
    [15] = "f"
};
function A:PercentToHex(r, g, b, a)
    r = A:Round(r * 255);
    g = A:Round(g * 255);
    b = A:Round(b * 255);
    a = A:Round(a * 255);

    r = b16[math.floor(r / 16)]..b16[r % 16];
    g = b16[math.floor(g / 16)]..b16[g % 16];
    b = b16[math.floor(b / 16)]..b16[b % 16];
    a = b16[math.floor(a / 16)]..b16[a % 16];

    return a..r..g..b;
end

--- strtrim, Blizzard's one is a little to.. "efficiency", derp.
-- @param str The string to trim
-- @param wat What to trim (optional)
function A:StringTrim(str, wat)
    if ( type(str) ~= "string" ) then return; end
    if ( not wat ) then
        wat = "%s\t\r\n";
    end

    return str:match("^["..wat.."]*(.-)["..wat.."]*$");
end

--- Return the current specialization ID or 0 if none
-- Death Knight: 250 - Blood / 251 - Frost / 252 - Unholy
-- Druid: 102 - Balance / 103 - Feral Combat / 104 - Guardian / 105 - Restoration
-- Hunter: 253 - Beast Mastery / 254 - Marksmanship / 255 - Survival
-- Mage: 62 - Arcane / 63 - Fire / 64 - Frost
-- Monk: 268 - Brewmaster / 269 - Windwalker / 270 - Mistweaver
-- Paladin: 65 - Holy / 66 - Protection / 70 - Retribution
-- Priest: 256 Discipline / 257 Holy / 258 Shadow
-- Rogue: 259 - Assassination / 260 - Combat / 261 - Subtlety
-- Shaman: 262 - Elemental / 263 - Enhancement / 264 - Restoration
-- Warlock: 265 - Affliction / 266 - Demonology / 267 - Destruction
-- Warrior: 71 - Arms / 72 - Furry / 73 - Protection
function A:GetPlayerCurrentSpecID()
    local index = GetSpecialization();

    if ( index ) then
        local id = GetSpecializationInfo(index);

        if ( id ) then
            return id;
        end
    end

    return 0;
end

--- Check if it is a BattlePetID
function A:IsBattlePetID(id)
    if ( type(id) ~= "string" ) then return nil; end
    if ( string.len(id) < 18 ) then return nil; end
    if ( not string.match(id, "^BattlePet%-%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ) then return nil; end

    return 1;
end

--- Check if a glyph is active
-- @param spellID The glyph spell ID
-- function A:IsGlyphed(spellID)
    -- if ( not A.isGlyphedCache ) then
        -- A:DebugMessage("IsGlyphed() - Creating cache");
        -- A.isGlyphedCache = {};
    -- end

    -- if ( A.isGlyphedCache[spellID] ~= nil ) then
        -- A:DebugMessage(("IsGlyphed() - %s (Cached)"):format(tostring(A.isGlyphedCache[spellID])));
        -- return A.isGlyphedCache[spellID];
    -- end

    -- for i=1,NUM_GLYPH_SLOTS do
        -- local enabled, _, _, glyphSpellID = GetGlyphSocketInfo(i);

        -- if ( enabled and glyphSpellID == spellID ) then
            -- A.isGlyphedCache[spellID] = true;
            -- A:DebugMessage("IsGlyphed() - true");
            -- return 1;
        -- end
    -- end

    -- A.isGlyphedCache[spellID] = false;
    -- A:DebugMessage("IsGlyphed() - false");
    -- return nil;
-- end

function A:GetPlayerSpecTalentsInfos()
    A.playerSpecTalentsInfos =
    {
        ["spec"] = 0,
        ["row1"] = 0,
        ["row2"] = 0,
        ["row3"] = 0,
        ["row4"] = 0,
        ["row5"] = 0,
        ["row6"] = 0,
        ["row7"] = 0,
    };
    A.playerSpecTalentsInfos["spec"] = GetSpecialization();

    local specGroup = GetActiveSpecGroup();
    local _, selected;

    for i=1,GetMaxTalentTier() do
        _, selected = GetTalentTierInfo(i, specGroup, false, "player");
        A.playerSpecTalentsInfos["row"..i] = selected;
    end
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
local petsFilters = {};
petsFilters.types = {};
petsFilters.sources = {};
function A:StoreAndResetPetsFilters()
    -- Store filters
    for i=1,C_PetJournal.GetNumPetTypes() do
        petsFilters.types[i] = C_PetJournal.IsPetTypeChecked(i);
    end

    for i=1,C_PetJournal.GetNumPetSources() do
        petsFilters.sources[i] = C_PetJournal.IsPetSourceChecked(i);
    end

    -- Check them all
    C_PetJournal.SetAllPetTypesChecked(true);
    C_PetJournal.SetAllPetSourcesChecked(true);
end

--- Restore pets filters
function A:RestorePetsFilters()
    for i=1,C_PetJournal.GetNumPetTypes() do
        if ( petsFilters.types[i] ) then
            C_PetJournal.SetPetTypeFilter(i, true);
        else
            C_PetJournal.SetPetTypeFilter(i, false);
        end
    end

    for i=1,C_PetJournal.GetNumPetSources() do
        if ( petsFilters.sources[i] ) then
            C_PetJournal.SetPetSourceChecked(i, true);
        else
            C_PetJournal.SetPetSourceChecked(i, false);
        end
    end
end

--- Will check if the pet can be used, this is special as there is some pets with the same name, but faction locked
function A:CheckPetWithSameName(id)
    if ( id == 51649 and A.playerFaction == "Alliance" ) then -- Moonkin Hatchling - Horde
        return nil;
    elseif ( id == 49588 and A.playerFaction == "Alliance" ) then -- Guild Page - Horde
        return nil;
    elseif ( id == 49590 and A.playerFaction == "Alliance" ) then -- Guild Herald - Horde
        return nil;
    elseif ( id == 51601 and A.playerFaction == "Horde" ) then -- Moonkin Hatchling - Alliance
        return nil;
    elseif ( id == 49586 and A.playerFaction == "Horde" ) then -- Guild Page - Alliance
        return nil;
    elseif ( id == 49587 and A.playerFaction == "Horde" ) then -- Guild Herald - Alliance
        return nil;
    end

    return 1;
end

--- Build the companions table
function A:BuildPetsTable(force)
    -- First, check if an update is needed
    local _, numOwned = C_PetJournal.GetNumPets();

    if ( not force and A.lastPetsCount == numOwned ) then
        A:DebugMessage("BuildPetsTable() - No update needed");
        return;
    end

    A:DebugMessage(("BuildPetsTable() - Update needed %d %d"):format(A.lastPetsCount, numOwned));

    A.lastPetsCount = numOwned;

    -- Update needed, store filters and set them for update
    A:StoreAndResetPetsFilters();

    -- Getting total number of pets AFTER resetting filters (derp)
    local numPets = C_PetJournal.GetNumPets();

    A.pamTable.pets =
    {
        [1] = {}, -- Humanoid
        [2] = {}, -- Dragonkin
        [3] = {}, -- Flying
        [4] = {}, -- Undead
        [5] = {}, -- Critter
        [6] = {}, -- Magic
        [7] = {}, -- Elemental
        [8] = {}, -- Beast
        [9] = {}, -- Aquatic
        [10] = {}, -- Mechanical
        --[11] = {}, -- None
    };
    A.pamTable.petsIds = {};

    for i=1,numPets do
        local petID, _, isOwned, customName, level, _, _, creatureName, icon, petType = C_PetJournal.GetPetInfoByIndex(i);
        local creatureID = select(6, C_PetJournal.GetPetInfoByPetID(petID or "BattlePet-0-000000000000"));
        local rarity = select(5, C_PetJournal.GetPetStats(petID or "BattlePet-0-000000000000"));

        if ( isOwned and A:CheckPetWithSameName(creatureID) ) then
            if ( A.petTypes[petType] ) then
                local add;
                local leadingLetter = string.sub(creatureName, 1, 1);

                if ( not A.pamTable.pets[petType][leadingLetter] ) then A.pamTable.pets[petType][leadingLetter] = {}; end

                local exists = A:NameExists(A.pamTable.pets[petType][leadingLetter], creatureName);

                if ( exists ) then
                    if ( not A.db.profile.filterMultiple or (customName and A.db.profile.noFilterCustom) ) then
                        add = 1;
                    elseif ( A.db.profile.filterPreferHigherLevel or A.db.profile.filterPreferHigherRarity ) then
                        local higherRarity, higherLevel, equalRarity, equalLevel;

                        if ( A.pamTable.pets[petType][leadingLetter][exists].rarity < rarity ) then
                            higherRarity = 1;
                        elseif ( A.pamTable.pets[petType][leadingLetter][exists].rarity == rarity ) then
                            equalRarity = 1;
                        end

                        if ( A.pamTable.pets[petType][leadingLetter][exists].level < level ) then
                            higherLevel = 1;
                        elseif ( A.pamTable.pets[petType][leadingLetter][exists].level == level ) then
                            equalLevel = 1;
                        end

                        if ( (higherRarity and higherLevel and A.db.profile.filterPreferHigherLevel and A.db.profile.filterPreferHigherRarity)
                        or (higherRarity and A.db.profile.filterPreferHigherRarity and ((equalLevel or A.db.profile.filterLevelRarityMode == "rarity" and A.db.profile.filterPreferHigherLevel)
                          or not A.db.profile.filterPreferHigherLevel))
                        or (higherLevel and A.db.profile.filterPreferHigherLevel and ((equalRarity or A.db.profile.filterLevelRarityMode == "level" and A.db.profile.filterPreferHigherRarity)
                          or not A.db.profile.filterPreferHigherRarity)) ) then
                            table.remove(A.pamTable.pets[petType][leadingLetter], exists);
                            add = 1;
                        end
                    end
                else
                    add = 1;
                end

                if ( add ) then
                    A.pamTable.petsIds[#A.pamTable.petsIds+1] = petID;

                    A.pamTable.pets[petType][leadingLetter][#A.pamTable.pets[petType][leadingLetter]+1] =
                    {
                        petID = petID,
                        name = customName or creatureName,
                        icon = icon,
                        creatureID = creatureID,
                        defaultName = customName and creatureName or nil,
                        petType = petType,
                        level = level,
                        rarity = rarity,
                    };
                end
            end
        end
    end

    A:RestorePetsFilters();
    A:CleanPetsFavorites();
    A:DebugMessage("BuildPetsTable() - Update successful");
end

--- Return the mount category from mount type
-- 230 Ground
-- 231 Both turtles (not pandaren ones)
-- 232 Vashj'ir Seahorse
-- 241 Qiraji Battle Tanks
-- 242 Swift Spectral Gryphon (while dead mount)
-- 247 Red Flying Cloud
-- 248 Flying
-- 254 Subdued Seahorse
-- 269 Water Striders
-- 284 Chauffeured Mechano-Hog
A.mountTypeToCategory =
{
    [230] = 1,
    [231] = 1,
    [232] = 4,
    [241] = 1,
    [247] = 2,
    [248] = 2,
    [254] = 4,
    [269] = 1,
    [284] = 1,
};
function A:GetMountCategory(mountType)
    if ( A.mountTypeToCategory[mountType] ) then
        return A.mountTypeToCategory[mountType];
    end

    return nil;
end

--- Check if the mount is able to walk on water surface
-- @param spellID The mount spell ID
function A:IsWaterWalkingMount(spellID)
    if ( tContains(A.surfaceMounts, spellID) ) then -- Generic mounts
        return 1;
    -- else -- Special cases
        -- if ( spellID == 23161 or spellID == 5784 ) then -- Warlock's Dreadsteed and Felsteed, check for Glyph of Nightmares (spellID: 56232)
            -- if ( A:IsGlyphed(56232) ) then
                -- return 1;
            -- end
        -- end
    end

    return nil;
end

--- Return the number of collected mounts
function A:GetCollectedMounts()
    if ( A.getCollectedMountsDelay and (time() - A.getCollectedMountsDelay < 2) ) then
        return nil;
    end

    local count = 0;

    for i=1,C_MountJournal.GetNumMounts() do
        if ( select(11, C_MountJournal.GetDisplayedMountInfo(i)) ) then
            count = count + 1;
        end
    end

    A.getCollectedMountsDelay = time();
    return count;
end

--- Build the mounts table
function A:BuildMountsTable(force)
    local mountsCount = A:GetCollectedMounts();

    if ( not force and (A.lastMountsCount == mountsCount or not mountsCount) ) then
        A:DebugMessage("BuildMountsTable() - No update needed");
        return;
    end

    A:DebugMessage(("BuildMountsTable() - Update needed %d %d"):format(A.lastMountsCount, mountsCount));

    A.lastMountsCount = mountsCount;
    mountsCount = C_MountJournal.GetNumMounts();

    local _, creatureID, creatureName, spellID, icon, mountType, leadingLetter, cat, isUsable, hideOnChar, isCollected, mountID;

    -- (Re)Building database, deleting cache
    A.usableMountsCache = nil;
    A.mountsSpellIDToIDCache = nil;

    A.pamTable.mounts =
    {
        [1] = {}, -- Ground
        [2] = {}, -- Fly
        [3] = {}, -- Hybrid (ground & fly)
        [4] = {}, -- Aquatic
        [5] = {}, -- with passengers
        [6] = {}, -- Water walking
        [7] = {}, -- Repair
    };
    A.pamTable.mountsIds =
    {
        [1] = {}, -- Ground
        [2] = {}, -- Fly
        [3] = {}, -- Hybrid (ground & fly)
        [4] = {}, -- Aquatic
        [5] = {}, -- with passengers
        [6] = {}, -- Water walking
        [7] = {}, -- Repair
    };

    for i=1,mountsCount do
        -- local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, _, _, hideOnChar, isCollected = C_MountJournal.GetDisplayedMountInfo(i);
        -- local creatureDisplayID, descriptionText, sourceText, isSelfMount = C_MountJournal.GetDisplayedMountInfoExtra(index);
        creatureName, spellID, icon, _, isUsable, _, _, _, _, hideOnChar, isCollected, mountID = C_MountJournal.GetDisplayedMountInfo(i);
        creatureID, _, _, _, mountType = C_MountJournal.GetDisplayedMountInfoExtra(i);

        if ( hideOnChar ~= true and isCollected ) then
            leadingLetter = string.sub(creatureName, 1, 1);

            -- Forced passenger mounts
            if ( tContains(A.passengerMounts, spellID) ) then
                if ( not A.pamTable.mounts[5][leadingLetter] ) then A.pamTable.mounts[5][leadingLetter] = {}; end

                A.pamTable.mountsIds[5][#A.pamTable.mountsIds[5]+1] = spellID;

                A.pamTable.mounts[5][leadingLetter][#A.pamTable.mounts[5][leadingLetter]+1] =
                {
                    id = i,
                    spellID = spellID,
                    creatureID = creatureID,
                    name = creatureName,
                    icon = icon,
                    mountType = mountType,
                    mountID = mountID,
                };
            end

            -- Forced aquatic mounts
            if ( tContains(A.aquaticMounts, spellID) ) then
                if ( not A.pamTable.mounts[4][leadingLetter] ) then A.pamTable.mounts[4][leadingLetter] = {}; end

                A.pamTable.mountsIds[4][#A.pamTable.mountsIds[4]+1] = spellID;

                A.pamTable.mounts[4][leadingLetter][#A.pamTable.mounts[4][leadingLetter]+1] =
                {
                    id = i,
                    spellID = spellID,
                    creatureID = creatureID,
                    name = creatureName,
                    icon = icon,
                    mountType = mountType,
                    mountID = mountID,
                };
            end

            -- Forced water walking mounts
            if ( A:IsWaterWalkingMount(spellID) ) then
                if ( not A.pamTable.mounts[6][leadingLetter] ) then A.pamTable.mounts[6][leadingLetter] = {}; end

                A.pamTable.mountsIds[6][#A.pamTable.mountsIds[6]+1] = spellID;

                A.pamTable.mounts[6][leadingLetter][#A.pamTable.mounts[6][leadingLetter]+1] =
                {
                    id = i,
                    spellID = spellID,
                    creatureID = creatureID,
                    name = creatureName,
                    icon = icon,
                    mountType = mountType,
                    mountID = mountID,
                };
            end

            -- Forced repair mounts
            if ( tContains(A.repairMounts, spellID) ) then
                if ( not A.pamTable.mounts[7][leadingLetter] ) then A.pamTable.mounts[7][leadingLetter] = {}; end

                A.pamTable.mountsIds[7][#A.pamTable.mountsIds[7]+1] = spellID;

                A.pamTable.mounts[7][leadingLetter][#A.pamTable.mounts[7][leadingLetter]+1] =
                {
                    id = i,
                    spellID = spellID,
                    creatureID = creatureID,
                    name = creatureName,
                    icon = icon,
                    mountType = mountType,
                    mountID = mountID,
                };
            end

            -- Forced Hybrids
            if ( tContains(A.db.global.forcedHybrid, spellID) ) then
                cat = 3;
            else
                cat = A:GetMountCategory(mountType);
            end

            -- Using the first non water mount found for water surface testing
            -- Bring me that back Blizzard!!
            -- if ( not A.swimmingCheckSpellID and bit.band(mountType, 0x8) == 0 ) then
                -- A.swimmingCheckSpellID = 29998; -- Decrepit Fever (testing things here)
            -- end

            if ( cat ) then
                if ( not A.pamTable.mounts[cat][leadingLetter] ) then A.pamTable.mounts[cat][leadingLetter] = {}; end

                A.pamTable.mountsIds[cat][#A.pamTable.mountsIds[cat]+1] = spellID;

                A.pamTable.mounts[cat][leadingLetter][#A.pamTable.mounts[cat][leadingLetter]+1] =
                {
                    id = i,
                    spellID = spellID,
                    creatureID = creatureID,
                    name = creatureName,
                    icon = icon,
                    mountType = mountType,
                    mountID = mountID,
                };
            end
        end
    end

    A:DebugMessage("BuildMountsTable() - Update successful");
end

--- Build companions and mounts tables
function A:BuildBothTables(force)
    A:DebugMessage("BuildBothTables()");
    A:BuildPetsTable(force);
    A:BuildMountsTable(force);
end

--- Initialize the databases
function A:InitializeDB()
    if ( not A.initialized ) then return; end

    A:DebugMessage("Initializing databases");
    A.initialized = nil;
    A:BuildBothTables();

    -- Registering database update events here
    -- I do not know if something change for me as I was able to get pets and mounts info when login in
    -- It is obviously not the same for everyone as some players were receiving errors (expected string got nil) within the DB update methods
    A:RegisterEvent("COMPANION_LEARNED");
    A:RegisterEvent("COMPANION_UNLEARNED");
    A:RegisterEvent("PET_JOURNAL_PET_DELETED");
    A:RegisterEvent("PET_JOURNAL_LIST_UPDATE");
    A:RegisterEvent("COMPANION_UPDATE");

    -- This event is used to update Data Broker
    -- It call the DB so setting it here
    A:RegisterEvent("UNIT_AURA");

    -- Same
    A:Hook(C_PetJournal, "SummonPetByGUID", true);

    -- Setting here both infos the first time (Data Broker)
    -- Doing this too soon can cause nil error with strings manipulation when creating the DB
    A:ApplyCurrentBothInfos();
end

--- Remove unknown pets from favorites
function A:CleanPetsFavorites()
    for k,v in ipairs(A.petsDB.profile.favorites) do
        if ( not C_PetJournal.GetPetInfoByPetID(v) ) then
            table.remove(A.petsDB.profile.favorites, k);
            A:DebugMessage(("CleanPetsFavorites() - Removed petID: %s"):format(v));
        end
    end
end

--- Add summon filters to the database
function A:AddSummonFilters()
    for k,v in ipairs(A.petsSummonFilters) do
        if ( A.db.profile.petsSummonFilters[k] == nil ) then
            A.db.profile.petsSummonFilters[k] = 1;
        end
    end
    for k,v in ipairs(A.mountsSummonFilters) do
        if ( A.db.profile.mountsSummonFilters[k] == nil ) then
            A.db.profile.mountsSummonFilters[k] = 1;
        end
    end
end

--- Add custom macros categories to the database
function A:AddCustomMacros()
    for k,v in ipairs(A.areaTypes) do
        if ( A.db.profile.customMountMacros[v] == nil ) then
            A.db.profile.customMountMacros[v] =
            {
                luaMode = nil,
                macro = {},
                lua = {},
            };
        end
    end
end

--[[-------------------------------------------------------------------------------
    Sets methods
-------------------------------------------------------------------------------]]--

--- Build a temporary table with the selected sets
-- @param cat Pets or Mounts sets
-- @param sets A table with selected sets
-- @return the temp fav table
function A:BuildTempSetTable(cat, sets)
    local out;

    if ( cat == "PETS" ) then
        out = {};

        for k,v in ipairs(sets) do
            if ( A.petsDB.profiles[v] and A.petsDB.profiles[v].favorites and #A.petsDB.profiles[v].favorites > 0 ) then
                for kk,vv in ipairs(A.petsDB.profiles[v].favorites) do
                    if ( not tContains(out, vv) ) then
                        out[#out+1] = vv;
                    end
                end
            end
        end
    elseif ( cat == "MOUNTS" ) then
        out =
        {
            [1] = {}, -- Ground
            [2] = {}, -- Fly
            [3] = {}, -- Hybrid (ground & fly)
            [4] = {}, -- Aquatic
            [5] = {}, -- with passengers
            [6] = {}, -- Water walking
            [7] = {}, -- Repair
        };

        for k,v in ipairs(sets) do
            if ( A.mountsDB.profiles[v] and A.mountsDB.profiles[v].favorites ) then
                for kk,vv in ipairs(A.mountsDB.profiles[v].favorites) do
                    if ( #vv > 0 ) then
                        for kkk,vvv in ipairs(vv) do
                            if ( not tContains(out[kk], vvv) ) then
                                out[kk][#out[kk]+1] = vvv;
                            end
                        end
                    end
                end
            end
        end
    end

    return out;
end

--- Set the favorites pets with the selected sets (global)
function A:SetGlobalPetsSets()
    A:DebugMessage("SetGlobalPetsSets()");

    local pets;

    if ( #A.db.profile.defaultSets.pets > 0 ) then
        pets = A:BuildTempSetTable("PETS", A.db.profile.defaultSets.pets);
    else
        pets = A:BuildTempSetTable("PETS", {"Default"});
    end

    if ( pets ) then
        A.currentPetsSet = {};
        A:CopyTable(pets, A.currentPetsSet);
        A.usablePetsCache = nil;
    end
end

--- Set the favorites mounts with the selected sets (global)
function A:SetGlobalMountsSets()
    A:DebugMessage("SetGlobalMountsSets()");

    local mounts;

    if ( #A.db.profile.defaultSets.mounts > 0 ) then
        mounts = A:BuildTempSetTable("MOUNTS", A.db.profile.defaultSets.mounts);
    else
        mounts = A:BuildTempSetTable("MOUNTS", {"Default"});
    end

    if ( mounts ) then
        A.currentMountsSet = {};
        A:CopyTable(mounts, A.currentMountsSet);
        A.usableMountsCache = nil;
    end
end

--- Set the favorites pets with the selected sets (zone)
-- @param cfg When called by the configuration, override the last ~= current check
function A:SetZonePetsSets(cfg)
    if ( not A.db.profile.petsZoneSets ) then
        A:SetGlobalPetsSets();
        return;
    end

    A:DebugMessage(("SetZonePetsSets() - cfg: %s"):format(cfg and "true" or "false"));

    if ( A.db.profile.petsSetsByMapID[A.currentMapID] ) then
        if ( A.db.profile.lastZonePetsSetsDefined ~= A.currentMapID or cfg ) then
            local pets = A:BuildTempSetTable("PETS", A.db.profile.petsSetsByMapID[A.currentMapID]);

            if ( pets ) then
                A.currentPetsSet = {};
                A:CopyTable(pets, A.currentPetsSet);
                A.usablePetsCache = nil;
                A.db.profile.lastZonePetsSetsDefined = A.currentMapID;
                return 1;
            end
        end
    else
        if ( A.db.profile.lastZonePetsSetsDefined ) then
            A:SetGlobalPetsSets();
            A.db.profile.lastZonePetsSetsDefined = nil;
        end
    end

    return nil;
end

--- Set the favorites mounts with the selected sets (zone)
-- @param cfg When called by the configuration, override the last ~= current check
function A:SetZoneMountsSets(cfg)
    if ( not A.db.profile.mountsZoneSets ) then
        A:SetGlobalMountsSets();
        return;
    end

    A:DebugMessage(("SetZoneMountsSets() - cfg: %s"):format(cfg and "true" or "false"));

    if ( A.db.profile.mountsSetsByMapID[A.currentMapID] ) then
        if ( A.db.profile.lastZoneMountsSetsDefined ~= A.currentMapID or cfg ) then
            local mounts = A:BuildTempSetTable("MOUNTS", A.db.profile.mountsSetsByMapID[A.currentMapID]);

            if ( mounts ) then
                A.currentMountsSet = {};
                A:CopyTable(mounts, A.currentMountsSet);
                A.usableMountsCache = nil;
                A.db.profile.lastZoneMountsSetsDefined = A.currentMapID;
                return 1;
            end
        end
    else
        if ( A.db.profile.lastZoneMountsSetsDefined ) then
            A:SetGlobalMountsSets();
            A.db.profile.lastZoneMountsSetsDefined = nil;
        end
    end

    return nil;
end

--- Return the sets in use
function A:GetTableSetsInUse(cat)
    if ( cat == "PETS" ) then
        if ( A.db.profile.petsZoneSets and A.db.profile.lastZonePetsSetsDefined and A.db.profile.petsSetsByMapID[A.currentMapID] ) then
            return A.db.profile.petsSetsByMapID[A.currentMapID];
        elseif ( #A.db.profile.defaultSets.pets > 0 ) then
            return A.db.profile.defaultSets.pets;
        elseif ( A.petsDB.profiles["Default"] and A.petsDB.profiles["Default"].favorites and #A.petsDB.profiles["Default"].favorites > 0 ) then
            return {"Default"};
        else
            return nil;
        end
    elseif ( cat == "MOUNTS" ) then
        if ( A.db.profile.mountsZoneSets and A.db.profile.lastZoneMountsSetsDefined and A.db.profile.mountsSetsByMapID[A.currentMapID] ) then
            return A.db.profile.mountsSetsByMapID[A.currentMapID];
        elseif ( #A.db.profile.defaultSets.mounts > 0 ) then
            return A.db.profile.defaultSets.mounts;
        elseif ( A.mountsDB.profiles["Default"] and A.mountsDB.profiles["Default"].favorites and (#A.mountsDB.profiles["Default"].favorites[1] > 0
        or #A.mountsDB.profiles["Default"].favorites[2] > 0 or #A.mountsDB.profiles["Default"].favorites[3] > 0
        or #A.mountsDB.profiles["Default"].favorites[4] > 0 or #A.mountsDB.profiles["Default"].favorites[5] > 0
        or #A.mountsDB.profiles["Default"].favorites[6] > 0 or #A.mountsDB.profiles["Default"].favorites[7] > 0) ) then
            return {"Default"};
        else
            return nil;
        end
    else
        return nil;
    end
end

function A:GetSetsInUse(cat)
    local sets = A:GetTableSetsInUse(cat);

    if ( sets ) then
        return A:StringTrim(string.join(", ", unpack(sets)), ", ");
    else
        return L["None"];
    end
end

--- Update sets (forced)
function A:ForceSetsUpdate()
    if ( not A:SetZonePetsSets(1) ) then
        A:SetGlobalPetsSets();
    end

    if ( not A:SetZoneMountsSets(1) ) then
        A:SetGlobalMountsSets();
    end
end

--[[-------------------------------------------------------------------------------
    Zones methods
-------------------------------------------------------------------------------]]--

-- MapIDs with the same name. Scenarios, quest in instance (legendary, green fire, etc), special events, etc
-- 970 = Tanaan Jungle arrival in Draenor
A.zonesIDsOverride =
{
    -- JUSTIGNOREME are those area used only once
    [539] = "JUSTIGNOREME", -- Gilneas
    [678] = "JUSTIGNOREME", -- Gilneas
    [679] = "JUSTIGNOREME", -- Gilneas
    [751] = "JUSTIGNOREME", -- The Maelstrom
    [737] = "JUSTIGNOREME", -- The Maelstrom
    [681] = "JUSTIGNOREME", -- The Lost Isles
    [682] = "JUSTIGNOREME", -- The Lost Isles
    [683] = "JUSTIGNOREME", -- Mount Hyjal
    [748] = "JUSTIGNOREME", -- Uldum
    [770] = "JUSTIGNOREME", -- Twilight Highlands
    [697] = "JUSTIGNOREME", -- Zul'Gurub
    [803] = "JUSTIGNOREME", -- The Nexus
    [813] = "JUSTIGNOREME", -- Eye of the Storm
    [762] = "JUSTIGNOREME", -- Scarlet Monastery
    [879] = "JUSTIGNOREME", -- Kun-Lai Summit
    [881] = "JUSTIGNOREME", -- Temple of Kotmogu
    [907] = "JUSTIGNOREME", -- Dustwallow Marsh
    [910] = "JUSTIGNOREME", -- Krasarang Wilds
    [919] = "JUSTIGNOREME", -- Black Temple
    [924] = "JUSTIGNOREME", -- Dalaran
    [933] = "JUSTIGNOREME", -- Isle of Thunder
    [1010] = "JUSTIGNOREME", -- Hillsbrad Foothills (10 years bg event)
    -- MoP
    [939] = L["Blood in the Snow"],
    [937] = L["Dark Heart of Pandaria"],
    [920] = L["Domination Point (H)"],
    [880] = L["Greenstone Village"],
    [911] = L["Lion's Landing (A)"],
    [906] = L["Theramore's Fall (A)"],
    [851] = L["Theramore's Fall (H)"],
    -- WoD
    [947] = L["Shadowmoon Valley (WoD)"],
    [950] = L["Nagrand (WoD)"],
    [971] = L["Lunarfall (Main)"],
    [986] = L["Shattrath City (WoD)"],
    [992] = L["Blasted Lands (WoD)"],
};

-- Build the mapIDs DB
function A:BuildMapIDsDB()
    if ( A.db.profile.debug ) then
        A.db.global.zonesIDsToName = {};
    end

    for i=1,2000 do -- Yes, there is no mapIDs > 9xx, but just in case one pop up
        if ( A.zonesIDsOverride[i] ) then
            if ( A.zonesIDsOverride[i] == "JUSTIGNOREME" ) then
                A.db.global.zonesIDsToName[tostring(i)] = nil;
            else
                A.db.global.zonesIDsToName[tostring(i)] = A.zonesIDsOverride[i];
            end
        else
            local name = GetMapNameByID(i);

            if ( name ) then
                if ( A.db.profile.debug ) then
                    if ( A:TableValueToKey(A.db.global.zonesIDsToName, name) ) then
                        A:DebugMessage(("BuildMapIDsDB() - %d %s already stored - with ID %s"):format(i, name, A:TableValueToKey(A.db.global.zonesIDsToName, name)));
                    end
                end

                A.db.global.zonesIDsToName[tostring(i)] = name;
            end
        end
    end
end

-- Hook a script on hide of the worldmap frame
-- used to update the current mapID without
-- switching it while the player got his map open
WorldMapFrame:HookScript("OnHide", function()
    if ( A.getCurrentMapIDDelayed ) then
        A.getCurrentMapIDDelayed = nil;
        A:GetCurrentMapID();
    end
end);

-- Get the current mapID
-- Postponed it if the map is open
function A:GetCurrentMapID()
    if ( WorldMapFrame:IsVisible() ) then
        A.getCurrentMapIDDelayed = 1;
        return;
    end

    SetMapToCurrentZone();

    local mapID = GetCurrentMapAreaID();

    if ( not mapID ) then return; end

    A.currentMapID = tostring(mapID);

    if ( not A.db.global.zonesIDsToName[A.currentMapID] and GetMapNameByID(mapID)
    and (not A.zonesIDsOverride[A.currentMapID] or (A.zonesIDsOverride[A.currentMapID] and A.zonesIDsOverride[A.currentMapID] ~= "JUSTIGNOREME")) ) then
        if ( A.zonesIDsOverride[A.currentMapID] ) then
            A.db.global.zonesIDsToName[A.currentMapID] = A.zonesIDsOverride[A.currentMapID];
        else
            A.db.global.zonesIDsToName[A.currentMapID] = GetMapNameByID(mapID);
        end

        A:NotifyChangeForAll();
        A:DebugMessage(("GetCurrentMapID() - Added %d - %s"):format(mapID, GetMapNameByID(mapID) or "Unavailable"));
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

--- Get auto pet summon option status according to global option, override or player called revoke
function A:IsAutoPetEnabled()
    if( A.playerRevokedPet ) then
        return nil;
    elseif ( A.autoPetOverride ) then
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

--- Set to vars the current summoned pet infos
function A:SetCurrentPetInfos()
    local id = C_PetJournal.GetSummonedPetGUID();

    if ( id ) then
        local _, customName, level, _, _, _, _,creatureName, icon = C_PetJournal.GetPetInfoByPetID(id);
        local rarity = select(5, C_PetJournal.GetPetStats(id or "0x0000000000000000"));

        A.currentPetName = customName or creatureName;
        A.currentPetIcon = icon;
        A.currentPetRarity = rarity or 1;
        A.currentPetLevel = level;
        return;
    end

    A.currentPetName = nil;
    A.currentPetIcon = nil;
    A.currentPetRarity = nil;
    A.currentPetLevel = nil;
end

--- Set to vars the current summoned mount infos
function A:SetCurrentMountInfos()
    -- Init addon databases
    A:InitializeDB();

    local index = 1;
    local name, _, icon, _, _, _, _, _, _, _, id = UnitBuff("player", index);

    -- One shot, woot!
    for k,v in ipairs(A.pamTable.mountsIds) do
        if ( tContains(v, id) ) then
            A.currentMountName = name;
            A.currentMountIcon = icon;
            return;
        end
    end

    -- Continue checking
    while id do
        index = index + 1;
        name, _, icon, _, _, _, _, _, _, _, id = UnitBuff("player", index);

        for k,v in ipairs(A.pamTable.mountsIds) do
            if ( tContains(v, id) ) then
                A.currentMountName = name;
                A.currentMountIcon = icon;
                return;
            end
        end
    end

    A.currentMountName = nil;
    A.currentMountIcon = nil;
end

--- Set the Data Broker text and icon
function A:SetDataBroker()
    local text = "";

    if ( A.db.profile.dataBrokerTextPet ) then
        if ( A.currentPetName ) then
            if ( A.db.profile.dataBrokerPetRarity ) then
                text = A.rarityColors[A.currentPetRarity];
            end

            if ( A.db.profile.dataBrokerTextPetIcon ) then
                text = text.."|T"..A.currentPetIcon..":"..A.db.profile.dataBrokerTextIconSize..":"..A.db.profile.dataBrokerTextIconSize..":0:"..A.db.profile.dataBrokerTextIconVerticalOffset.."|t "..A.currentPetName;
            else
                text = text..A.currentPetName;
            end

            if ( A.db.profile.dataBrokerPetLevel ) then
                text = text.." ("..A.currentPetLevel..")";
            end

            if ( A.db.profile.dataBrokerPetRarity ) then
                text = text..A.color.RESET;
            end
        end
    end

    if ( A.db.profile.dataBrokerTextMount ) then
        if ( A.currentMountName ) then
            if ( text == "" ) then
                if ( A.db.profile.dataBrokerTextMountIcon ) then
                    text = "|T"..A.currentMountIcon..":"..A.db.profile.dataBrokerTextIconSize..":"..A.db.profile.dataBrokerTextIconSize..":0:"..A.db.profile.dataBrokerTextIconVerticalOffset.."|t "..A.currentMountName;
                else
                    text = A.currentMountName;
                end
            else
                if ( A.db.profile.dataBrokerTextMountIcon ) then
                    text = text..A.db.profile.dataBrokerTextSeparator.."|T"..A.currentMountIcon..":"..A.db.profile.dataBrokerTextIconSize..":"..A.db.profile.dataBrokerTextIconSize..":0:"..A.db.profile.dataBrokerTextIconVerticalOffset.."|t "..A.currentMountName;
                else
                    text = text..A.db.profile.dataBrokerTextSeparator..A.currentMountName;
                end
            end
        end
    end

    if ( text == "" ) then
        if ( A.db.profile.dataBrokerPrependDefaultIcon ) then
            A.ldbObject.text = "|TInterface\\ICONS\\"..A.db.profile.dataBrokerIcon..":"..A.db.profile.dataBrokerTextIconSize..":"..A.db.profile.dataBrokerTextIconSize..":0:"..A.db.profile.dataBrokerTextIconVerticalOffset.."|t "..L["None"];
        else
            A.ldbObject.text = L["None"];
        end
    else
        A.ldbObject.text = text;
    end

    if ( not A.db.profile.dataBrokerDisplayIcon ) then
        A.ldbObject.icon = nil;
        -- LDB Icon should have an icon
        A.LDBIcon:IconCallback(nil, "PetsAndMountsLDBI", "icon", "Interface\\ICONS\\"..A.db.profile.dataBrokerIcon);
    elseif ( A.db.profile.dataBrokerIconMode == "CURRENT_PET" and A.currentPetIcon ) then
        A.ldbObject.icon = A.currentPetIcon;
        A.LDBIcon:IconCallback(nil, "PetsAndMountsLDBI", "icon", A.currentPetIcon);
    elseif ( A.db.profile.dataBrokerIconMode == "CURRENT_MOUNT" and A.currentMountIcon ) then
        A.ldbObject.icon = A.currentMountIcon;
        A.LDBIcon:IconCallback(nil, "PetsAndMountsLDBI", "icon", A.currentMountIcon);
    else
        A.ldbObject.icon = "Interface\\ICONS\\"..A.db.profile.dataBrokerIcon;
        A.LDBIcon:IconCallback(nil, "PetsAndMountsLDBI", "icon", "Interface\\ICONS\\"..A.db.profile.dataBrokerIcon);
    end

    if ( A.db.profile.dataBrokerDisplayLabel ) then
        A.ldbObject.label = L["Pets & Mounts"];
    else
        A.ldbObject.label = nil;
    end
end

--- Set current pet and mount infos and call data broker and buttons update
function A:ApplyCurrentBothInfos()
    if ( InCombatLockdown() ) then
        A.applyCurrentBothInfosDelayed = 1;
        return;
    end

    A:SetCurrentPetInfos();
    A:SetCurrentMountInfos();
    A:SetDataBroker();
    A:SetButtonsIcons();
end

--- Set current pet infos and call data broker and buttons update
function A:ApplyCurrentPetInfos()
    if ( InCombatLockdown() ) then
        A.applyCurrentPetInfosDelayed = 1;
        return;
    end

    A:SetCurrentPetInfos();
    A:SetDataBroker();
    A:SetButtonsIcons();
end

--- Set current mount infos and call data broker and buttons update
function A:ApplyCurrentMountInfos()
    if ( InCombatLockdown() ) then
        A.applyCurrentMountInfosDelayed = 1;
        return;
    end

    A:SetCurrentMountInfos();
    A:SetDataBroker();
    A:SetButtonsIcons();
end

--- Show or hide the minimap icon
function A:ShowHideMinimap()
    if ( A.db.profile.ldbi.hide ) then
        --A:Message(L["Minimap icon is hidden if you want to show it back use: /pam or /petsandmounts"], true);
        LibStub("LibDBIcon-1.0"):Hide("PetsAndMountsLDBI");
    else
        LibStub("LibDBIcon-1.0"):Show("PetsAndMountsLDBI");
    end
end

--- Set the fishing poles subType, localized
function A:SetFishingPoleSubType()
    A.fishingPoleSubType = select(7, GetItemInfo(6256));

    if ( not A.fishingPoleSubType ) then
        A:ScheduleTimer("SetFishingPoleSubType", 1);
    end
end

--- Set everything
function A:SetEverything()
    A:DebugMessage("SetEverything()");
    -- Set player vars
    A.playerClass = select(2, UnitClass("player"));
    A.playerGUID = UnitGUID("player");
    A.playerLevel = UnitLevel("player");
    A.playerFaction = UnitFactionGroup("player");
    A.playerRace = select(2, UnitRace("player"));
    A.playerName, A.playerRealm = UnitFullName("player");
    A.playerCurrentSpecID = A:GetPlayerCurrentSpecID();
    A:GetPlayerSpecTalentsInfos();

    if ( not A.playerClass or not A.playerGUID or not A.playerLevel
    or not A.playerFaction or not A.playerRace or not A.playerName
    or not A.playerRealm or not A.playerCurrentSpecID ) then
        A:ScheduleTimer("SetEverything", 1);
        return;
    end

    A.playerFullName = A.playerName.."-"..A.playerRealm;

    A:SetDebugMessage();
    A:ShowHideMinimap();
    A:SetAutoSummonOverride(1);
    A:SetStealthEvents();

    A:SetFishingPoleSubType();
    A:SetMacroDismountString();
    A:SetClassSpells();
    A:SetButtons();

    A:FixMountsProfilesTables();

    A:ForceSetsUpdate();

    A:SetMainTimer();

    A.addonRunning = 1;
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

            -- Pets families menu
            for k,v in A:PairsByKeys(A.pamTable.pets) do
                if ( A:TableCount(v) > 0 ) then
                    self.info.text = "   "..L[A.petTypes[k]];
                    self.info.value = "PETS"..A.petTypes[k];
                    self.info.icon = nil;
                    UIDropDownMenu_AddButton(self.info, level);
                end
            end
        end

        -- Mounts
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

            -- Mounts categories menu
            for k,v in A:PairsByKeys(A.pamTable.mounts) do
                if ( A:TableCount(v) > 0 ) then
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
                    A:NotifyChangeForAll();
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
                    A:NotifyChangeForAll();
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
                    A:NotifyChangeForAll();
                end
            end;
            UIDropDownMenu_AddButton(self.info, level);

            -- Model rotation
            self.info.text = L["Model rotation"];
            self.info.checked = A.db.profile.modelRotation;
            self.info.func = function()
                A.db.profile.modelRotation = not A.db.profile.modelRotation;
                if ( A.AceConfigRegistry ) then
                    A:NotifyChangeForAll();
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
        self.info.notCheckable = 1;

        -- Pets leading letters menu
        for k,v in ipairs(A.pamTable.pets) do
            if ( A:TableCount(v) > 0 ) then
                if ( UIDROPDOWNMENU_MENU_VALUE == "PETS"..A.petTypes[k] ) then
                    for kk,vv in A:PairsByKeys(v) do
                        self.info.text = "   "..kk;
                        self.info.value = "PETS"..A.petTypes[k]..kk;
                        self.info.icon = nil;
                        self.info.hasArrow = 1;
                        UIDropDownMenu_AddButton(self.info, level);
                    end
                end
            end
        end

        -- Mounts leading letters menu
        for k,v in ipairs(A.pamTable.mounts) do
            if ( A:TableCount(v) > 0 ) then
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
                    A:NotifyChangeForAll();
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
                    A:NotifyChangeForAll();
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
                    A:NotifyChangeForAll();
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
                    A:NotifyChangeForAll();
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
                    A:NotifyChangeForAll();
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
                    A:NotifyChangeForAll();
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
                    A:NotifyChangeForAll();
                end
            end;
            UIDropDownMenu_AddButton(self.info, level);
        end
    elseif (level == 4 ) then
        local summonedPet = C_PetJournal.GetSummonedPetGUID();

        -- Pets list
        for k,v in ipairs(A.pamTable.pets) do
            if ( A:TableCount(v) > 0 ) then
                buttonIndex = 1;

                for kk,vv in A:PairsByKeys(v) do
                    if ( UIDROPDOWNMENU_MENU_VALUE == "PETS"..A.petTypes[k]..kk ) then
                        for kkk,vvv in ipairs(vv) do
                            if ( vvv.petID == summonedPet ) then
                                isSummoned = 1;
                            else
                                isSummoned = nil;
                            end

                            if ( vvv.customName ) then
                                self.info.text = vvv.customName;
                            else
                                self.info.text = vvv.name;
                            end

                            self.info.icon = vvv.icon;
                            self.info.disabled = isSummoned;
                            self.info.keepShownOnClick = 1;
                            self.info.hasArrow = nil;
                            self.info.func = function() A:SummonPet(vvv.petID); end;
                            UIDropDownMenu_AddButton(self.info, level);

                            _G["DropDownList4Button"..buttonIndex]:HookScript("OnEnter", function()
                                if ( not A.isPetsAndMountsMenu or not A.db.profile.showMenuModelFrame ) then
                                    A.menuModelFrame:Hide();

                                    return;
                                end

                                -- Model
                                A.menuModelFrame:SetDisplayInfo(vvv.creatureID);
                                A.menuModelFrame:SetAnimation(618, -1);

                                -- Frame pos
                                local point, relativePoint = A:GetMenuModelFrameAnchor();
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

        -- Mounts list
        for k,v in ipairs(A.pamTable.mounts) do
            if ( A:TableCount(v) > 0 ) then
                buttonIndex = 1;

                for kk,vv in A:PairsByKeys(v) do
                    if ( UIDROPDOWNMENU_MENU_VALUE == "MOUNTS"..A.mountCat[k]..kk ) then
                        for kkk,vvv in ipairs(vv) do
                            self.info.text = vvv.name;
                            self.info.icon = vvv.icon;
                            self.info.keepShownOnClick = 1;
                            self.info.hasArrow = nil;
                            self.info.func = function() C_MountJournal.SummonByID(vvv.mountID); end;
                            UIDropDownMenu_AddButton(self.info, level);

                            _G["DropDownList4Button"..buttonIndex]:HookScript("OnEnter", function()
                                if ( not A.isPetsAndMountsMenu or not A.db.profile.showMenuModelFrame ) then
                                    A.menuModelFrame:Hide();

                                    return;
                                end

                                -- Model
                                A.menuModelFrame:SetDisplayInfo(vvv.creatureID);
                                A.menuModelFrame:SetAnimation(618, -1);

                                -- Frame pos
                                local point, relativePoint = A:GetMenuModelFrameAnchor();
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
    A:PopMessageEnteringCombat();
    A:CancelTimer(A.shiftTimer, 1);
    A.noAutoPet = 1;
end

function A:PLAYER_REGEN_ENABLED()
    A:DebugMessage("PLAYER_REGEN_ENABLED() - -Combat");

    if ( A.delayedPetsTableUpdate ) then
        A:BuildPetsTable();
        A.delayedPetsTableUpdate = nil;
    end

    if ( A.delayedMountsTableUpdate ) then
        A:BuildMountsTable();
        A.delayedMountsTableUpdate = nil;
    end

    if ( A.delayedZoneSets ) then
        A:SetZonePetsSets();
        A:SetZoneMountsSets();
        A.delayedZoneSets = nil;
    end

    if ( A.applyCurrentBothInfosDelayed ) then
        A:ApplyCurrentBothInfos();
        A.applyCurrentBothInfosDelayed = nil
    end

    if ( A.applyCurrentPetInfosDelayed ) then
        A:ApplyCurrentPetInfos();
        A.applyCurrentPetInfosDelayed = nil
    end

    if ( A.applyCurrentMountInfosDelayed ) then
        A:ApplyCurrentMountInfos();
        A.applyCurrentMountInfosDelayed = nil
    end

    if ( A.petBattleButtonsVisibilityDelayed ) then
        A:PET_BATTLE_CLOSE();
        A.petBattleButtonsVisibilityDelayed = nil;
    end

    A:AutoPetDelay();
    A:PopMessageLeavingCombat();
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
            A:RevokePet();
        end
    end
end

function A:PLAYER_ENTERING_WORLD()
    A:SetAutoSummonOverride();
    A:GetCurrentMapID();
    A:SendAddonVersion();

    -- Set those here, prevent every add-on actions with pets or mounts too soon
    if ( A.onFirstLoadActions ) then
        -- Events
        A:RegisterEvent("PLAYER_REGEN_DISABLED"); -- Combat.
        A:RegisterEvent("PLAYER_REGEN_ENABLED"); -- Out of combat.
        A:RegisterEvent("PLAYER_CONTROL_GAINED"); -- After a cc or fly path.
        A:RegisterEvent("PLAYER_UNGHOST"); -- It's alive!! (Corpse run, zoning)
        A:RegisterEvent("PLAYER_ALIVE"); -- It's alive!! (Res, also fire when releasing)
        A:RegisterEvent("PLAYER_LOSES_VEHICLE_DATA"); -- Quitting a vehicle or a multi mount you control.
        A:RegisterEvent("UNIT_EXITED_VEHICLE"); -- Exiting a vehicle.
        A:RegisterEvent("PLAYER_LEVEL_UP"); -- Update post click macros
        A:RegisterEvent("PET_BATTLE_OPENING_START"); -- Buttons visibility
        A:RegisterEvent("PET_BATTLE_CLOSE"); -- Same
        -- A:RegisterEvent("GLYPH_UPDATED", "GlyphModificationCallback"); -- Will also fire when switching spec
        -- A:RegisterEvent("GLYPH_ADDED", "GlyphModificationCallback");
        -- A:RegisterEvent("GLYPH_REMOVED", "GlyphModificationCallback");
        A:RegisterEvent("PLAYER_TALENT_UPDATE");

        A:LoginModificationsFixes();
        A:LoginMessages();
        A:ScheduleTimer("InitializeDB", 5);
        A.onFirstLoadActions = nil;
        return;
    end

    -- No delay for you on fist loading
    A:AutoPetDelay();

    -- No current pets & mounts infos update on first loading too
    A:ApplyCurrentBothInfos();
end

function A:ZONE_CHANGED_NEW_AREA()
    A:GetCurrentMapID();
    A:AutoPetDelay();

    if ( InCombatLockdown() ) then
        A.delayedZoneSets = 1;
        return;
    else
        A:SetZonePetsSets();
        A:SetZoneMountsSets();
    end

    A:NotifyChangeForAll();
end

function A:PLAYER_LEVEL_UP(event, level, ...)
    A.playerLevel = level;
    A:SetPostClickMacro();
end

-- function A:GlyphModificationCallback()
    -- A.isGlyphedCache = nil;

    -- if ( A.lockLastGlyphState ~= A:IsGlyphed(56232) ) then
        -- A:BuildMountsTable(1);
        -- A.lockLastGlyphState = A:IsGlyphed(56232);
    -- end
-- end

function A:COMPANION_UPDATE(event, companionType)
    if ( companionType == "CRITTER" ) then
        if ( InCombatLockdown() ) then
            A.delayedPetsTableUpdate = 1;
            return;
        end

        A:BuildPetsTable();
    elseif ( companionType == "MOUNT" ) then
        if ( InCombatLockdown() ) then
            A.delayedMountsTableUpdate = 1;
            return;
        end

        A:BuildMountsTable();
    end
end

function A:COMPANION_LEARNED()
    if ( InCombatLockdown() ) then
        A.delayedMountsTableUpdate = 1;
        return;
    end

    A:BuildMountsTable();
end

function A:COMPANION_UNLEARNED()
    if ( InCombatLockdown() ) then
        A.delayedMountsTableUpdate = 1;
        return;
    end

    A:BuildMountsTable();
end

function A:PET_JOURNAL_PET_DELETED()
    if ( InCombatLockdown() ) then
        A.delayedPetsTableUpdate = 1;
        return;
    end

    A:BuildPetsTable();
end

function A:PET_JOURNAL_LIST_UPDATE()
    if ( InCombatLockdown() ) then
        A.delayedPetsTableUpdate = 1;
        return;
    end

    A:BuildPetsTable();
end

function A:UNIT_AURA(event, unit)
    if ( InCombatLockdown() or unit ~= "player" ) then return; end

    if ( A.db.profile.mountButtonIconCurrent or A.db.profile.dataBrokerTextMount
    or A.db.profile.dataBrokerTextMountIcon or A.db.profile.dataBrokerIconMode == "CURRENT_MOUNT" ) then
        A:ApplyCurrentMountInfos();
    end
end

function A:SummonPetByGUID()
    if ( A.db.profile.petButtonIconCurrent or A.db.profile.dataBrokerTextPet
    or A.db.profile.dataBrokerTextPetIcon or A.db.profile.dataBrokerIconMode == "CURRENT_PET" ) then
        A:CancelTimer(A.currentInfosTimer, 1);
        A.currentInfosTimer = A:ScheduleTimer("ApplyCurrentPetInfos", 3);
    end
end

function A:PLAYER_CONTROL_GAINED()
    A:AutoPetDelay();

    if ( A.db.profile.petButtonIconCurrent or A.db.profile.dataBrokerTextPet
    or A.db.profile.dataBrokerTextPetIcon or A.db.profile.dataBrokerIconMode == "CURRENT_PET" ) then
        A:CancelTimer(A.currentInfosTimer, 1);
        A.currentInfosTimer = A:ScheduleTimer("ApplyCurrentPetInfos", 3);
    end
end

function A:PLAYER_UNGHOST()
    A:AutoPetDelay();

    if ( A.db.profile.petButtonIconCurrent or A.db.profile.dataBrokerTextPet
    or A.db.profile.dataBrokerTextPetIcon or A.db.profile.dataBrokerIconMode == "CURRENT_PET" ) then
        A:CancelTimer(A.currentInfosTimer, 1);
        A.currentInfosTimer = A:ScheduleTimer("ApplyCurrentPetInfos", 3);
    end
end

function A:PLAYER_ALIVE()
    A:AutoPetDelay();

    if ( A.db.profile.petButtonIconCurrent or A.db.profile.dataBrokerTextPet
    or A.db.profile.dataBrokerTextPetIcon or A.db.profile.dataBrokerIconMode == "CURRENT_PET" ) then
        A:CancelTimer(A.currentInfosTimer, 1);
        A.currentInfosTimer = A:ScheduleTimer("ApplyCurrentPetInfos", 3);
    end
end

function A:PLAYER_LOSES_VEHICLE_DATA()
    A:AutoPetDelay();

    if ( A.db.profile.petButtonIconCurrent or A.db.profile.dataBrokerTextPet
    or A.db.profile.dataBrokerTextPetIcon or A.db.profile.dataBrokerIconMode == "CURRENT_PET" ) then
        A:CancelTimer(A.currentInfosTimer, 1);
        A.currentInfosTimer = A:ScheduleTimer("ApplyCurrentPetInfos", 3);
    end
end

function A:UNIT_EXITED_VEHICLE()
    A:AutoPetDelay();

    if ( A.db.profile.petButtonIconCurrent or A.db.profile.dataBrokerTextPet
    or A.db.profile.dataBrokerTextPetIcon or A.db.profile.dataBrokerIconMode == "CURRENT_PET" ) then
        A:CancelTimer(A.currentInfosTimer, 1);
        A.currentInfosTimer = A:ScheduleTimer("ApplyCurrentPetInfos", 3);
    end
end

function A:PLAYER_TALENT_UPDATE()
    A.playerCurrentSpecID = A:GetPlayerCurrentSpecID();
    A:SetPostClickMacro();
    A:GetPlayerSpecTalentsInfos();
end

function A:PET_BATTLE_OPENING_START()
    if ( InCombatLockdown() ) then
        return;
    end

    if ( PetsAndMountsSecureButtonPets:IsShown() ) then
        PetsAndMountsSecureButtonPets:Hide();
        A.petBattlePetsButtonWasShown = 1;
    end

    if ( PetsAndMountsSecureButtonMounts:IsShown() ) then
        PetsAndMountsSecureButtonMounts:Hide();
        A.petBattleMountsButtonWasShown = 1;
    end
end

function A:PET_BATTLE_CLOSE()
    if ( InCombatLockdown() ) then
        A.petBattleButtonsVisibilityDelayed = 1;
        return;
    end

    if ( A.petBattlePetsButtonWasShown ) then
        PetsAndMountsSecureButtonPets:Show();
        A.petBattlePetsButtonWasShown = nil;
    end

    if ( A.petBattleMountsButtonWasShown ) then
        PetsAndMountsSecureButtonMounts:Show();
        A.petBattleMountsButtonWasShown = nil;
    end
end

--[[-------------------------------------------------------------------------------
    Addon communication
-------------------------------------------------------------------------------]]--

--- Check if the version send is newer than the local one
function A:IsRemoteNewer(vL, vR, rL, rR)
    if ( vL < vR ) then return 1; end
    if ( vL == vR and rL < rR ) then return 1; end
    return nil;
end

--- Receiving an addon message
function A:OnCommReceived(...)
    -- Don't bother the player again
    if ( A.addonUpdateMessageInfo ) then return; end

    local prefix, message, method, who, remoteStage, remoteVersion, remoteRevision, localVersion, localRevision;

    -- Addon comm info
    prefix, message, method, who = ...;

    -- Prevent own message
    if ( who == A.playerName ) then return; end

    remoteStage, remoteVersion = strsplit(":", message);
    remoteVersion, remoteRevision = A:GetAddonVersion(remoteVersion);
    localVersion, localRevision = A:GetAddonVersion(A.version);

    if ( not remoteStage or not remoteVersion or not remoteRevision ) then
        return;
    end

    A:DebugMessage(("OnCommReceived() - method: %s - who: %s - msg: %s"):format(method, who, message));

    if ( remoteStage == A.versionStage or (remoteStage == "Release" and A.versionStage == "Alpha") ) then
        if ( A:IsRemoteNewer(localVersion, remoteVersion, localRevision, remoteRevision) ) then
            A.addonUpdateMessageInfo = {remoteVersion, remoteRevision, remoteStage};
            A:NotifyChangeForAll();
            --A:Message(L["A newer version of Pets & Mounts is available. You have version %s revision %s %s, %s got version %s revision %s %s. Get it on Curse at %s or with the Curse client."]
            --:format(tostring(localVersion), tostring(localRevision), L[A.versionStage], who, tostring(remoteVersion), tostring(remoteRevision), L[remoteStage], A.color.BLUE.."|HPAM:config:About|h["..L["Link"].."]|h|r"));
            A:Message(L["A newer version of Pets & Mounts is available. You have version %s revision %s %s, %s got version %s revision %s %s. Get it on Curse or with the Curse client."]
            :format(tostring(localVersion), tostring(localRevision), L[A.versionStage], who, tostring(remoteVersion), tostring(remoteRevision), L[remoteStage]));
        end
    end
end

function A:SendAddonVersion()
    -- Guild
    if ( IsInGuild() ) then
        A:SendCommMessage("PAMCommPrefix", A.versionStage..":"..A.version, "GUILD");
    end

    -- Party/Raid
    local numMembers = GetNumGroupMembers();

    if ( numMembers > 0 and IsInRaid() ) then
        A:SendCommMessage("PAMCommPrefix", A.versionStage..":"..A.version, "RAID");
    elseif ( numMembers > 0 and not IsInRaid() ) then
        A:SendCommMessage("PAMCommPrefix", A.versionStage..":"..A.version, "PARTY");
    end

    if ( A.addonVersionMessageTimer ) then
        A:CancelTimer(A.addonVersionMessageTimer, 1);
    end

    A.addonVersionMessageTimer = A:ScheduleTimer("SendAddonVersion", 600);
end

--[[-------------------------------------------------------------------------------
    Custom link handling
-------------------------------------------------------------------------------]]--

-- function A:SetItemRef(link, ...)
    -- local linkType, linkSubType, linkArg = strsplit(":", link);

    -- if ( linkType == "PAM" ) then
        -- if ( linkSubType == "config" ) then
            -- A:OpenConfigPanel(linkArg);
        -- end
    -- else
        -- A.hooks.SetItemRef(link, ...);
    -- end
-- end

--[[-------------------------------------------------------------------------------
    Ace DB and database revision methods
-------------------------------------------------------------------------------]]--

-- -- d = added to config frame ok
A.aceDefaultDB =
{
    global =
    {
        savedSets = -- d
        {
            pets = {},
            mounts = {},
        },
        zonesIDsToName = {}, -- d
        popLoginMessages = {}, -- no cfg
        forcedHybrid = {},
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
        noHybridWhenGround = nil, -- d
        noHybridWhenFly = nil, -- d
        dismountFlying = nil, -- d
        areaMounts = 1, -- d
        hauntedMemento = 1, -- d
        magicBroom = 1, -- d
        surfaceMount = 1, -- d
        preferSurfaceSpell = nil, -- d
        vehicleExit = 1, -- d
        shimmeringMoonstone = 1, -- d
        appendPetDefaultName = 1, -- d
        colorPetWithCustomName = 1, -- d
        petWithCustomNameColor = -- d
        {
            r = 0.9137254901960784,
            g = 0.3450980392156863,
            b = 0.2078431372549019,
            a = 1,
            hexa = "|cffe95835",
        },
        ldbi = {}, -- d
        favoritePets = {}, -- d -- deprecated
        favoriteMounts = -- d -- deprecated
        {
            [1] = {}, -- Ground
            [2] = {}, -- Fly
            [3] = {}, -- Hybrid (ground & fly)
            [4] = {}, -- Aquatic
            [5] = {}, -- with passengers
            [6] = {}, -- Water walking
            [7] = {}, -- Repair
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
                [6] = nil, -- Water walking
                [7] = nil, -- Repair
            },
        },
        --savedSets = -- d -- deprecated
        --{
        --    pets = {},
        --    mounts = {},
        --},
        --enabledSets = -- d -- deprecated
        defaultSets = -- d
        {
            pets = {},
            mounts = {},
        },
        petsSetsByMapID = {}, -- d
        mountsSetsByMapID = {}, -- d
        enableAutoSummonOverride = nil, -- d
        autoSummonOverride = -- d
        {
        },
        classesMacrosEnabled = 1, -- d
        dockButton = nil, -- d
        dockAnchor = "Left", -- d
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
            [6] = {}, -- Water walking
            [7] = {}, -- Repair
        },
        petsSummonFilters = {}, -- d
        mountsSummonFilters = {}, -- d
        mountButtonshiftClickCat = 5, -- d
        mountButtonshiftClickEnabled = nil, -- d
        mountButtonControlLock = nil, -- d
        isSwimmingMountCat = 4, -- d
        copyTargetMount = 1, -- d
        copyMouseoverMount = nil, -- d
        showMenuModelFrame = 1, -- d
        showConfigModelFrame = 1, -- d
        petsZoneSets = nil, -- d
        mountsZoneSets = nil, -- d
        petReSummon = nil, -- d
        petReSummonTime = 3600, -- d
        hunterPreferPack = nil, -- d
        hunterWantModifier = nil, -- d -- Unused as of 1.6.2
        hunterModifier = "shift", -- d
        dataBrokerTextPet = 1, -- d
        dataBrokerTextPetIcon = 1, -- d
        dataBrokerTextMount = 1, -- d
        dataBrokerTextMountIcon = 1, -- d
        dataBrokerTextSeparator = " - ", -- d
        dataBrokerIcon = A.defaultDataBrokerIcon, -- d
        dataBrokerIconMode = "none", -- d
        dataBrokerDisplayLabel = 1, -- d
        dataBrokerDisplayIcon = 1, -- d
        petButtonIconCurrent = 1, -- d
        mountButtonIconCurrent = 1, -- d
        petButtonIcon = A.defaultPetButtonIcon, -- d
        mountButtonIcon = A.defaultMountButtonIcon, -- d
        deathKnightPreferUnholy = nil, -- d
        mageSlowFall = nil, -- d
        magePreferBlink = nil, -- d
        mageForceSlowFall = nil, -- d
        monkPreferSerpentKick = nil, -- d
        monkModifier = "shift", -- d
        hideOtherClasses = nil, -- d
        warlockPreferTeleport = nil, -- d
        warlockWantModifier = nil, -- d
        warlockModifier = "shift", -- d
        warlockDemonicCircleModifier = "shift",
        warriorForceHeroicLeap = nil, -- d
        customMountMacrosEnabled = nil, -- d
        customMountMacros = -- d
        {
            default =
            {
                luaMode = nil,
                macro =
                {
                    pre = "/pammount",
                    post = "/pammount",
                },
                lua =
                {
                    pre = "return \"/pammount\";",
                    post = "return \"/pammount\";",
                },
            },
        },
        dataBrokerPrependDefaultIcon = nil, -- d
        druidWantFormsOnMove = nil, -- d
        customMacrosMacroProtectionEnabled = 1, -- d
        customMacrosLUAProtectionEnabled = 1, -- d
        dataBrokerTextIconSize = 16, -- d
        dataBrokerTextIconVerticalOffset = -3, -- d
        priestLevitate = nil, -- d
        priestForceLevitate = nil, -- d
        noMountAfterCancelForm = nil, -- d
        filterPreferHigherLevel = 1, -- d
        filterPreferHigherRarity = 1, -- d
        filterLevelRarityMode = "rarity", -- d
        addPetLevelRarityToList = 1, -- d
        dataBrokerPetRarity = 1, -- d
        dataBrokerPetLevel = 1, -- d
        anglersFishingRaft = 1, -- d
        flyingPetWithFlyingMount = -- d
        {
            enabled = nil,
            set = nil,
        },
        oculusDrakes = 1,
        hybridsSelectionTab = nil, -- d
        hybridsSelectionOnlyOwned = 1, -- d
        telaariTalbuk = 1,
    },
};

-- Pets Ace3 DB
A.aceDefaultPetsDB =
{
    profile =
    {
        favorites = {},
    },
};

-- Mounts Ace3 DB
A.aceDefaultMountsDB =
{
    profile =
    {
        favorites =
        {
            [1] = {}, -- Ground
            [2] = {}, -- Fly
            [3] = {}, -- Hybrid (ground & fly)
            [4] = {}, -- Aquatic
            [5] = {}, -- with passengers
            [6] = {}, -- Water walking
            [7] = {}, -- Repair
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
    else -- Full update just in case someone got an old savedvar
        A:Message(L["A full database update is needed."], 1, 1);
        A:DatabaseRevision2();
        A.db.global.databaseRevision = A.databaseRevision;
        A.addonFirstLoad = 1; -- First time loading the addon, used to not display login messages
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

--- Remove forced hybrids from favorites if they were removed
function A:RemoveUnforcedHybrids()
    for k,v in ipairs(A.mountsDB:GetProfiles()) do
        if ( A.mountsDB.profiles[v] and A.mountsDB.profiles[v].favorites ) then
            if ( A.mountsDB.profiles[v].favorites[3] and #A.mountsDB.profiles[v].favorites[3] > 0 ) then
                for kk,vv in ipairs(A.mountsDB.profiles[v].favorites[3]) do
                    if ( not tContains(A.db.global.forcedHybrid, vv) ) then
                        A:TableRemove(A.mountsDB.profiles[v].favorites[3], vv);
                    end
                end
            end
        end
    end
end

--- Mounts profiles tables are created empty, fix that
function A:FixMountsProfilesTables()
    for k,v in ipairs(A.mountsDB:GetProfiles()) do
        if ( A.mountsDB.profiles[v] and not A.mountsDB.profiles[v].favorites ) then
            A.mountsDB.profiles[v].favorites =
            {
                [1] = {}, -- Ground
                [2] = {}, -- Fly
                [3] = {}, -- Hybrid (ground & fly)
                [4] = {}, -- Aquatic
                [5] = {}, -- with passengers
                [6] = {}, -- Water walking
                [7] = {}, -- Repair
            };
        elseif ( A.mountsDB.profiles[v] and A.mountsDB.profiles[v].favorites ) then
            for i=1,7 do
                if ( not A.mountsDB.profiles[v].favorites[i] ) then
                    A.mountsDB.profiles[v].favorites[i] = {};
                end
            end
        end
    end
end

--- Remove empty area sets from database
function A:RemoveEmptyAreaSets()
    for k,v in pairs(A.db.profile.mountsSetsByMapID) do
        if ( #v == 0 ) then
            A.db.profile.mountsSetsByMapID[k] = nil;
        end
    end
    for k,v in pairs(A.db.profile.petsSetsByMapID) do
        if ( #v == 0 ) then
            A.db.profile.petsSetsByMapID[k] = nil;
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
            InterfaceOptionsFrame_OpenToCategory(A.configFrameOptions);
        end
    end);

    InterfaceOptions_AddCategory(f);
end

--- Display configuration panel
-- Load it if needed
function A:OpenConfigPanel(cat)
    if ( A.AceConfigDialog ) then
        if ( cat ) then
            cat = A["configFrame"..cat];

            if ( not cat ) then
                cat = A.configFrameOptions;
            end
        else
            cat = A.configFrameOptions;
        end

        InterfaceOptionsFrame_OpenToCategory(cat);
    else
        local loaded = A:LoadAddonConfig();

        if ( loaded ) then
            -- Yes I could have simply called this method again
            -- Avoiding "infinite" loop > lazy
            -- If there is an error in the config addon it will freeze the game until a stack overflow
            if ( cat ) then
                cat = A["configFrame"..cat];

                if ( not cat ) then
                    cat = A.configFrameOptions;
                end
            else
                cat = A.configFrameOptions;
            end

            InterfaceOptionsFrame_OpenToCategory(cat);
        end
    end
end

--[[-------------------------------------------------------------------------------
    Add-on modifications on login fixes and on login messages
-------------------------------------------------------------------------------]]--

--- Called upon PLAYER_ENTERING_WORLD
-- Do some check/edit and display messages if necessary
function A:LoginModificationsFixes()
    local mod; -- If true something was modified

    -- Old bindings, check if still present, update them, display message
    local key1, key2;
    local set = GetCurrentBindingSet();
    local oldBindings =
    {
        "PETSANDMOUNTSPET",
        "PETSANDMOUNTSMOUNT",
        "PETSANDMOUNTSMOUNTPASSENGERS",
        "PETSANDMOUNTSMOUNTFLYING",
        "PETSANDMOUNTSMOUNTGROUND",
        "PETSANDMOUNTSMOUNTAQUATIC",
        "PETSANDMOUNTSMOUNTSURFACE",
        "PETSANDMOUNTSMOUNTREPAIR",
        "PETSANDMOUNTSMOUNTHYBRID"
    };
    local newBindings =
    {
        "CLICK PetsAndMountsSecureButtonPets:LeftButton",
        "CLICK PetsAndMountsSecureButtonMounts:LeftButton",
        "CLICK PetsAndMountsSecureButtonPassengers:LeftButton",
        "CLICK PetsAndMountsSecureButtonFlying:LeftButton",
        "CLICK PetsAndMountsSecureButtonGround:LeftButton",
        "CLICK PetsAndMountsSecureButtonAquatic:LeftButton",
        "CLICK PetsAndMountsSecureButtonSurface:LeftButton",
        "CLICK PetsAndMountsSecureButtonRepair:LeftButton",
        "CLICK PetsAndMountsSecureButtonHybrid:LeftButton",
    };

    for k,v in ipairs(oldBindings) do
        key1, key2 = GetBindingKey(v, set);
        if ( key1 )then
            SetBinding(key1, nil, set);
            mod = 1;
        end
        if ( key2 )then
            SetBinding(key2, nil, set);
            mod = 1;
        end
        if ( key1 ) then
            SetBinding(key1, newBindings[k], set);
            mod = 1;
        end
        if ( key2 ) then
            SetBinding(key2, newBindings[k], set);
            mod = 1;
        end
    end

    if ( mod ) then
        SaveBindings(set);
        A:PopMessageFrame("newBindingsSystemv150");
        mod = nil;
    end
    oldBindings, newBindings, key1, key2, set = nil, nil, nil, nil, nil;
    -- / Old bindings
end

A.loginMessagesList =
{
    "newCompanionsFilters161",
    "wodModifications170",
};
A.loginMessagesListForced =
{
    --"wodDraenorIsflyingbug603",
};
function A:LoginMessages()
    for k,v in ipairs(A.loginMessagesList) do
        if ( not A.db.global.popLoginMessages[v] ) then
            if ( not A.addonFirstLoad ) then
                A:PopMessageFrame(v);
            end

            A.db.global.popLoginMessages[v] = 1;
        end
    end

    for k,v in ipairs(A.loginMessagesListForced) do
        if ( not A.db.global.popLoginMessages[v] ) then
            A:PopMessageFrame(v);
            A.db.global.popLoginMessages[v] = 1;
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
    A.db = LibStub("AceDB-3.0"):New("petsAndMountsDB", A.aceDefaultDB, true);
    A.petsDB = LibStub("AceDB-3.0"):New("petsAndMountsPetsDB", A.aceDefaultPetsDB, true);
    A.mountsDB = LibStub("AceDB-3.0"):New("petsAndMountsMountsDB", A.aceDefaultMountsDB, true);
    A:FixMountsProfilesTables();
    A:DatabaseRevisionCheck();
    A:RemoveDatabaseOldEntries();
    A:RemoveUnforcedHybrids();
    A:RemoveEmptyAreaSets();
    A:AddSummonFilters();
    A:AddCustomMacros();

    -- Profile modification callbacks
    A.db.RegisterCallback(self, "OnProfileChanged", "SetEverything");
    A.db.RegisterCallback(self, "OnProfileCopied", "SetEverything");
    A.db.RegisterCallback(self, "OnProfileReset", "SetEverything");
    A.petsDB.RegisterCallback(self, "OnProfileChanged", "SetEverything");
    A.petsDB.RegisterCallback(self, "OnProfileCopied", "SetEverything");
    A.petsDB.RegisterCallback(self, "OnProfileReset", "SetEverything");
    A.mountsDB.RegisterCallback(self, "OnProfileChanged", "SetEverything");
    A.mountsDB.RegisterCallback(self, "OnProfileCopied", "SetEverything");
    A.mountsDB.RegisterCallback(self, "OnProfileReset", "SetEverything");

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

    -- Messages frame
    A.popupMessageFrame = PetsAndMountsPopupMessageFrame;
    A.popupMessageFrame.addon = A;

    -- LDB
    A.ldbObject = LibStub("LibDataBroker-1.1"):NewDataObject("PetsAndMountsLDB", {
        type = "data source",
        text = L["None"],
        label = A.db.profile.dataBrokerDisplayLabel and L["Pets & Mounts"] or nil,
        icon = "Interface\\ICONS\\"..A.db.profile.dataBrokerIcon, -- Setting an icon for LDBI
        tocname = "PetsAndMounts",
        OnClick = function(self, button)
            if (button == "LeftButton") then
                if ( IsShiftKeyDown() ) then
                    A:RevokePet(1);
                else
                    A:RandomPet(1);
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
            local currentSet, forcedInfo1, forcedInfo2, forcedInfo3, forcedInfo4, forcedInfo5;

            tooltip:AddDoubleLine(A.color["WHITE"]..L["Pets & Mounts"], A.color["GREEN"].."v"..A.version);
            tooltip:AddLine(" ");

            currentSet = A:GetSetsInUse("PETS");
            if ( currentSet == L["None"] ) then
                currentSet = A.color["RED"]..currentSet;
            else
                currentSet = A.color["GREEN"]..currentSet;
            end

            if ( A.db.profile.forceOne.pet and A:GetPetNameByID(A.db.profile.forceOne.pet) ) then
                forcedInfo1 = A.color["GREEN"]..A:GetPetNameByID(A.db.profile.forceOne.pet);
            else
                forcedInfo1 = A.color["RED"]..L["None"];
            end

            tooltip:AddLine(L["Companions set in use: %s."]:format(currentSet));
            tooltip:AddLine(L["Auto summon companion is %s."]:format(A:IsAutoPetEnabled() and A.color["GREEN"]..L["On"] or A.color["RED"]..L["Off"]));
            tooltip:AddLine(L["Not when stealthed is %s."]:format(A:IsNotWhenStealthedEnabled() and A.color["GREEN"]..L["On"] or A.color["RED"]..L["Off"]));
            tooltip:AddLine(L["Forced companion: %s"]:format(forcedInfo1));
            tooltip:AddLine(" ");

            currentSet = A:GetSetsInUse("MOUNTS");
            if ( currentSet == L["None"] ) then
                currentSet = A.color["RED"]..currentSet;
            else
                currentSet = A.color["GREEN"]..currentSet;
            end

            if ( A.db.profile.forceOne.mount[4] and A:GetMountNameBySpellID(A.db.profile.forceOne.mount[4]) ) then
                forcedInfo1 = A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[4]);
            else
                forcedInfo1 = A.color["RED"]..L["None"];
            end

            if ( A.db.profile.forceOne.mount[1] and A:GetMountNameBySpellID(A.db.profile.forceOne.mount[1]) ) then
                forcedInfo2 = A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[1]);
            else
                forcedInfo2 = A.color["RED"]..L["None"];
            end

            if ( A.db.profile.forceOne.mount[2] and A:GetMountNameBySpellID(A.db.profile.forceOne.mount[2]) ) then
                forcedInfo3 = A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[2]);
            else
                forcedInfo3 = A.color["RED"]..L["None"];
            end

            if ( A.db.profile.forceOne.mount[3] and A:GetMountNameBySpellID(A.db.profile.forceOne.mount[3]) ) then
                forcedInfo4 = A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[3]);
            else
                forcedInfo4 = A.color["RED"]..L["None"];
            end

            if ( A.db.profile.forceOne.mount[5] and A:GetMountNameBySpellID(A.db.profile.forceOne.mount[5]) ) then
                forcedInfo5 = A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[5]);
            else
                forcedInfo5 = A.color["RED"]..L["None"];
            end

            tooltip:AddLine(L["Mounts set in use: %s."]:format(currentSet));
            tooltip:AddLine(L["Forced aquatic mount: %s"]:format(forcedInfo1));
            tooltip:AddLine(L["Forced ground mount: %s"]:format(forcedInfo2));
            tooltip:AddLine(L["Forced fly mount: %s"]:format(forcedInfo3));
            tooltip:AddLine(L["Forced hybrid mount: %s"]:format(forcedInfo4));
            tooltip:AddLine(L["Forced passenger mount: %s"]:format(forcedInfo5));

            tooltip:AddLine(" ");
            tooltip:AddLine(L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random companion.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Revoke current companion.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open the configuration panel."]);
        end
    });

    -- LDBIcon
    A.LDBIcon:Register("PetsAndMountsLDBI", A.ldbObject, A.db.profile.ldbi);

    -- Addon communication
    A:RegisterComm("PAMCommPrefix");

    -- Raw hook on chat link
    --A:RawHook("SetItemRef", true);
    --A:SecureHook("SetItemRef");

    -- Add the config loader to blizzard addon configuration panel
    A:AddToBlizzTemp();
end

--- AceAddon callback
-- Called during the PLAYER_LOGIN event
function A:OnEnable()
    -- Slash commands
    A:RegisterChatCommand("petsandmounts", "SlashCommand");
    A:RegisterChatCommand("pam", "SlashCommand");
    A:RegisterChatCommand("pampet", "RandomPet");
    -- /pammount cannot call the method directly, arg is not nil and RandomMount check if the arg is nil
    A:RegisterChatCommand("pammount", function() A:RandomMount(); end);
    A:RegisterChatCommand("pamground", function() A:RandomMount(1); end);
    A:RegisterChatCommand("pamfly", function() A:RandomMount(2); end);
    A:RegisterChatCommand("pamhybrid", function() A:RandomMount(3); end);
    A:RegisterChatCommand("pamaquatic", function() A:RandomMount(4); end);
    A:RegisterChatCommand("pampassengers", function() A:RandomMount(5); end);
    A:RegisterChatCommand("pamsurface", function() A:RandomMount(6); end);
    A:RegisterChatCommand("pamrepair", function() A:RandomMount(7); end);

    -- Events
    A:RegisterEvent("PLAYER_ENTERING_WORLD");
    -- Update current mapID
    A:RegisterEvent("ZONE_CHANGED_NEW_AREA");

    -- Set everything
    A:SetEverything();
end
