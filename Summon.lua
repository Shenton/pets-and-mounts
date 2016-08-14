--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Summon.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- Globals to locals
local ipairs = ipairs;
local time = time;
local type = type;
local tContains = tContains;
local math = math;
local select = select;
local pairs = pairs;

-- GLOBALS: IsStealthed, UnitBuff, GetSpellInfo, UnitBuff, GetItemCount, InCombatLockdown
-- GLOBALS: C_PetJournal, IsFlyableArea, IsSpellKnown, IsUsableSpell, GetMirrorTimerInfo
-- GLOBALS: IsSwimming, IsSubmerged, GetNumCompanions, GetCompanionInfo, CallCompanion
-- GLOBALS: GetProfessions, GetProfessionInfo, GetAchievementInfo, IsMounted, IsFlying
-- GLOBALS: Dismount, VehicleExit, UnitExists, UnitIsPlayer, UnitIsUnit, C_MountJournal
-- GLOBALS: SetMapToCurrentZone, GetCurrentMapAreaID

--[[-------------------------------------------------------------------------------
    Pets methods
-------------------------------------------------------------------------------]]--

--- Check if the player is stealthed/invis
-- 51755 Camouflage (hunter)
-- 32612 Invis (mage)
local stealthAuras =
{
    [1] = GetSpellInfo(51755),
    [2] = GetSpellInfo(32612),
};
function A:IsStealthed()
    if ( IsStealthed() ) then
        A:DebugMessage("IsStealthed() - Stealthed");
        return 1;
    elseif ( A.playerClass == "HUNTER" or A.playerClass == "MAGE" ) then
        for k,v in ipairs(stealthAuras) do
            if ( UnitBuff("player", v) ) then
                A:DebugMessage("IsStealthed() - Stealth/Invis buff found");
                return 1;
            end
        end
    end

    return nil;
end

--- Check if the player is eating or drinking
function A:InitHasRegenBuff()
    A.foodBuffLocalized = GetSpellInfo(104935); -- Food
    A.drinkBuffLocalized = GetSpellInfo(104270); -- Drink
end
function A:HasRegenBuff()
    if ( not A.foodBuffLocalized or not A.drinkBuffLocalized ) then A:InitHasRegenBuff(); end
    if ( UnitBuff("player", A.foodBuffLocalized) ) then
        A:DebugMessage("HasRegenBuff() - Has food buff");
        return 1;
    end
    if ( UnitBuff("player", A.drinkBuffLocalized) ) then
        A:DebugMessage("HasRegenBuff() - Has drink buff");
        return 1;
    end
    return nil;
end

--- Check if the Haunted Memento is in the player bags
-- If it is and the Haunted Memento option is set, return true
function A:CheckHauntedMemento()
    if ( not A.db.profile.hauntedMemento ) then return nil; end

    if ( GetItemCount(40110, nil, nil) == 1 ) then
        A:DebugMessage("CheckHauntedMemento() - Haunted Memento in bags");
        return 1;
    end

    return nil;
end

--- Summon a pet by GUID
function A:SummonPet(id)
    if ( InCombatLockdown() ) then
        A:DebugMessage("SummonPet() - In combat");
        return nil;
    end

    if ( C_PetJournal.PetIsSummonable(id) ) then
        A:DebugMessage("SummonPet() - Summon pet: "..A:GetPetNameByID(id));

        C_PetJournal.SummonPetByGUID(id);

        local t = time();

        A.lastPetSummoned =
        {
            id = id,
            t = t,
        };

        return 1;
    else
        A:DebugMessage("SummonPet() - Pet is not summonable");
        return nil;
    end
end

--- Revoke current pet
-- @param playerCall When called by the player, set a var disabling autopet
function A:RevokePet(playerCall)
    if ( InCombatLockdown() ) then
        A:DebugMessage("RevokePet() - In combat");
        return;
    end

    A:DebugMessage("RevokePet()");

    local currentPet = C_PetJournal.GetSummonedPetGUID();

    if ( not currentPet ) then return; end

    if ( playerCall ) then A.playerRevokedPet = 1; end

    C_PetJournal.SummonPetByGUID(currentPet);
end

--- Get a table with usable pets
-- It set it as an addon var and return it
-- @param tbl The original mounts table
-- @return The table filtered (cached)
function A:GetUsablePetsTable(tbl)
    if ( not A.usablePetsCache ) then
        A.usablePetsCache = {};
    end

    if ( A.usablePetsCache[tbl] ) then
        return A.usablePetsCache[tbl];
    else
        A.usablePetsCache[tbl] = {};
    end

    for k,v in ipairs(tbl) do
        --local id = select(11, C_PetJournal.GetPetInfoByPetID(v));
        local _, customName, _, _, _, _, _, name, _, _, id = C_PetJournal.GetPetInfoByPetID(v);

        if ( A.restrictedPets[id] ) then -- Got a restricted pet
            -- Banned
            if ( A.restrictedPets[id].type == "banned" ) then
                A:DebugMessage(("Restricted pet: %s - type: %s - npc: %d"):format(customName or name, A.restrictedPets[id].type, id));
            -- Faction
            elseif ( A.restrictedPets[id].type == "faction" ) then
                if ( type(A.restrictedPets[id].args) == "table" ) then
                    if ( tContains(A.restrictedPets[id].args, A.playerFaction) ) then
                        A.usablePetsCache[tbl][#A.usablePetsCache[tbl]+1] = v;
                    else
                        A:DebugMessage(("Restricted pet: %s - type: %s - npc: %d"):format(customName or name, A.restrictedPets[id].type, id));
                    end
                else
                    if ( A.restrictedPets[id].args == A.playerFaction ) then
                        A.usablePetsCache[tbl][#A.usablePetsCache[tbl]+1] = v;
                    else
                        A:DebugMessage(("Restricted pet: %s - type: %s - npc: %d"):format(customName or name, A.restrictedPets[id].type, id));
                    end
                end
            end
        else
            A.usablePetsCache[tbl][#A.usablePetsCache[tbl]+1] = v;
        end
    end

    return A.usablePetsCache[tbl];
end

--- Get a random pet from a petts table
-- @param tbl The original petts table
-- @return The pet ID
function A:GetRandomPet(tbl)
    local index = math.random(#A:GetUsablePetsTable(tbl));

    return A.usablePetsCache[tbl][index];
end

--- Check if we got a least one mount available after restriction in the given table
-- @param tbl The original mounts table
-- @return The number of mounts available or nil
function A:GotRandomPet(tbl)
    local num = #A:GetUsablePetsTable(tbl);

    if ( num > 0 ) then return num; end

    return nil;
end

--- Get a random pet from databases and summon it
-- @param playerCall When called by the player, unset the var disabling autopet
function A:RandomPet(playerCall)
    -- DB init
    A:InitializeDB();

    local id;

    -- Get a random pet
    if ( A:GotRandomPet(A.petsDB.profile.favorites) ) then
        id = A:GetRandomPet(A.petsDB.profile.favorites);
    elseif ( A:GotRandomPet(A.pamTable.petsIds) ) then
        id = A:GetRandomPet(A.pamTable.petsIds);
    else
        return;
    end

    if ( A:SummonPet(id) ) then
        if ( playerCall ) then A.playerRevokedPet = nil; end
    end
end

--- Return if the pet summon should be filtered
function A:IsPetSummonFiltered(disabledFilter)
    if ( not A.petsSummonFiltersCache ) then
        A.petsSummonFiltersCache = {};

        for k,v in ipairs(A.petsSummonFilters) do
            if ( A.db.profile.petsSummonFilters[k] ) then
                A.petsSummonFiltersCache[v.name] = v.func;
            end
        end
    end

    for k,v in pairs(A.petsSummonFiltersCache) do
        if ( k ~= disabledFilter and v() ) then
            A:DebugMessage(("IsPetSummonFiltered() - %s"):format(k));
            return 1;
        end
    end

    return nil;
end

--- Return if a resummon is needed
function A:CheckReSummon(id)
    if ( id and A.db.profile.petReSummon ) then
        if ( A.lastPetSummoned ) then
            if ( A.lastPetSummoned.id == id and (time() - A.lastPetSummoned.t) >= A.db.profile.petReSummonTime ) then
                return 1;
            end
        else
            local id = C_PetJournal.GetSummonedPetGUID();
            local t = time();

            A.lastPetSummoned =
            {
                id = id,
                t = t,
            };
        end
    end

    return nil;
end

--- Check if a pet can be summoned
function A:AutoPet(disabledFilter)
    -- DB init
    A:InitializeDB();

    local currentPet = C_PetJournal.GetSummonedPetGUID();

    -- Got a pet, option is set to not have a pet when stealthed
    if ( currentPet and A:IsNotWhenStealthedEnabled() and A:IsStealthed() ) then
        A:DebugMessage("AutoPet() - Stealthed revoking pet");
        A:RevokePet();
        return;
    end

    -- Auto pet is disabled.
    if ( not A:IsAutoPetEnabled() ) then return; end

    -- Option is set to not summon when having a pet
    if ( currentPet and A.db.profile.alreadyGotPet and not A:CheckReSummon(currentPet) ) then
        A:DebugMessage("AutoPet() - Already got a pet");
        return;
    end

    -- Haunted Memento
    if ( A:CheckHauntedMemento() ) then
        A:RevokePet();
        return;
    end

    -- Flying pet
    -- if ( A.db.profile.flyingPetWithFlyingMount.enabled and A.db.profile.flyingPetWithFlyingMount.set
    -- and A.petsDB.profiles[A.db.profile.flyingPetWithFlyingMount.set] and IsFlying() and IsMounted() ) then

        -- if ( currentPet and tContains(A.petsDB.profiles[A.db.profile.flyingPetWithFlyingMount.set].favorites, currentPet) and not A:CheckReSummon(currentPet) ) then
            -- A:DebugMessage("AutoPet() - Already got a flying pet");
        -- elseif ( A:GotRandomPet(A.petsDB.profiles[A.db.profile.flyingPetWithFlyingMount.set].favorites) ) then
            -- A:DebugMessage("AutoPet() - Summon flying pet");
            -- local id = A:GetRandomPet(A.petsDB.profiles[A.db.profile.flyingPetWithFlyingMount.set].favorites);
            -- A:SummonPet(id);
        -- end

        -- return;
    -- end

    -- Pet summon filtered
    if ( A:IsPetSummonFiltered() ) then return; end

    -- Summon pet
    if ( A.db.profile.forceOne.pet ) then -- Forced pet
        if ( currentPet and currentPet == A.db.profile.forceOne.pet ) then
            A:DebugMessage("AutoPet() - Forced pet is current");
        else
            A:DebugMessage("AutoPet() - Forced pet");
            A:SummonPet(A.db.profile.forceOne.pet);
        end
    elseif ( A.db.profile.petByMapID[A.currentMapID] ) then -- Area pet
        if ( A.db.profile.petByMapID[A.currentMapID] == currentPet ) then
            A:DebugMessage("AutoPet() - Area override pet - Already got that pet");
        else
            A:DebugMessage("AutoPet() - Area override pet - summon");
            A:SummonPet(A.db.profile.petByMapID[A.currentMapID]);
        end
    elseif ( A:GotRandomPet(A.currentPetsSet) ) then -- Fav pets
        if ( currentPet and tContains(A.currentPetsSet, currentPet) and not A:CheckReSummon(currentPet) ) then
            A:DebugMessage("AutoPet() - Already got a fav pet");
        else
            A:DebugMessage("AutoPet() - Summon fav pet");
            A:SummonPet(A:GetRandomPet(A.currentPetsSet));
        end
    elseif ( (not currentPet and A:GotRandomPet(A.pamTable.petsIds)) or (A:CheckReSummon(currentPet) and A:GotRandomPet(A.pamTable.petsIds)) ) then -- All pets
        A:DebugMessage("AutoPet() - Summon random pet global");
        A:SummonPet(A:GetRandomPet(A.pamTable.petsIds));
    else
        A:DebugMessage("AutoPet() - No summon");
    end
end

--[[-------------------------------------------------------------------------------
    Mounts methods
-------------------------------------------------------------------------------]]--

--- Return a bool value with a random based on the two args
function A:RandHybrid(ground, hybrid)
    ground = ground * 10000;
    hybrid = hybrid * 10000;

    local total = ground + hybrid;

    if ( hybrid >= math.random(total) ) then
        return 1;
    end

    return nil;
end

-- Are we in Draenor?
-- function A:IsInDraenor()
    -- SetMapToCurrentZone();

    -- local currentMapID = GetCurrentMapAreaID();

    -- if ( tContains(A.draenorMapIDs, currentMapID) ) then
        -- return 1;
    -- end

    -- return nil;
-- end

--- Check if the player can fly
-- This is for handling a rare case, summoning a mount in outland and not having at least Expert Riding
-- But in case another one pop this will ease the process
--
-- Expert Riding 34090
-- Artisan Riding 34091
-- Master Riding 90265
function A:IsFlyable()
    if ( IsFlyableArea() and (IsSpellKnown(34090) or IsSpellKnown(34091) or IsSpellKnown(90265)) ) then
        return 1;
    end

    return nil;
end

--- Check if the player got a water breathing buff
function A:GotWaterBreathingBuff()
    if ( not A.waterBreathingBuffsCache ) then
        A:DebugMessage("GotWaterBreathingBuff() - Building water breathing buffs cache");

        A.waterBreathingBuffsCache = {};

        for k,v in ipairs(A.underwaterBreathingSpells) do
            local name = GetSpellInfo(v);

            if ( name ) then
                A.waterBreathingBuffsCache[#A.waterBreathingBuffsCache+1] = name;
            end
        end
    end

    for k,v in ipairs(A.waterBreathingBuffsCache) do
        if ( UnitBuff("player", v) ) then
            A:DebugMessage("GotWaterBreathingBuff() - Got water breathing buff");
            return 1;
        end
    end

    A:DebugMessage("GotWaterBreathingBuff() - No water breathing buff");
    return nil;
end

--- Check if the player is at the water surface
function A:AtSurface()
    if ( A.swimmingCheckSpellID ) then -- Got a surface checking mount, easy check \o/
        if ( IsUsableSpell(A.swimmingCheckSpellID) ) then
            A:DebugMessage("AtSurface() - Spell is usable");
            return 1;
        end
    else -- No surface checking mount, going for mirror, which is not perfect
        local timer, _, _, rate = GetMirrorTimerInfo(2);

        if ( timer == "UNKNOWN" ) then -- And this is where it sux, ok no breath mirror, but it can be an underwater breathing buff
            if ( not A:GotWaterBreathingBuff() ) then
                A:DebugMessage("AtSurface() - No water breathing buff");
                return 1
            end
        elseif ( timer == "BREATH" and rate > -1 ) then -- This work fine as bar is filling up quickly, the player was in the water
            A:DebugMessage("AtSurface() - Mirror is filling up quickly");
            return 1;
        end
    end

    return nil;
end

--- Check if the player is swimming and not at the surface
-- @return 1 if swimming, 2 if at the water surface, or nil
function A:IsSwimming()
    if ( IsSwimming() or IsSubmerged() ) then -- Swimming
        if ( A:AtSurface() ) then -- At the surface
            A:DebugMessage("IsSwimming() - At the surface");
            return 2;
        elseif ( IsSubmerged() ) then -- Bottom of the water - Have to do this here since 5.4 it is tainted and work as IsSwimming
            A:DebugMessage("IsSwimming() - IsSubmerged");
            return 1;
        else -- Really swimming
            A:DebugMessage("IsSwimming() - Swimming");
            return 1;
        end
    else
        A:DebugMessage("IsSwimming() - Not swimming");
        return nil;
    end
end

--- Check if the player can ride a (ground) mount
-- Lower riding skills are "forgotten", only the highest one is known
-- Apprentice Riding 33388
-- Journeyman Riding 33391
-- Expert Riding 34090
-- Artisan Riding 34091
-- Master Riding 90265
function A:CanRide()
    if (  IsSpellKnown(90265) or IsSpellKnown(34091) or IsSpellKnown(34090) or IsSpellKnown(33391) or IsSpellKnown(33388) ) then
        A:DebugMessage("CanRide() - True");
        return 1;
    end

    A:DebugMessage("CanRide() - False");
    return nil;
end

--- Set which mount category should be used
function A:SetMountCat()
    -- [1] = {}, -- Ground
    -- [2] = {}, -- Fly
    -- [3] = {}, -- Hybrid (ground & fly)
    -- [4] = {}, -- Aquatic
    -- [5] = {}, -- with passengers
    if ( A:IsSwimming() == 1 ) then -- Aquatic mount
        A:DebugMessage("SetMountCat() - Aquatic");
        return A.db.profile.isSwimmingMountCat;
    elseif ( A:IsFlyable() ) then -- Flyable mount
        A:DebugMessage("SetMountCat() - Flyable");
        return 2;
    elseif ( A:IsSwimming() == 2 and not A:IsFlyable() ) then -- Water surface not flyable area
        A:DebugMessage("SetMountCat() - Surface");
        return 6;
    else -- Ground mount
        A:DebugMessage("SetMountCat() - Ground");
        return 1;
    end

    return nil;
end

--- Summon a mount with it spell ID
function A:SummonMountBySpellId(spellID)
    --local id = A:GetMountIDFromSpellID(spellID);
    local id = A:GetMountMountIDFromSpellID(spellID);

    if ( id ) then
        if ( A.db.profile.debug ) then
            --A:DebugMessage("Summon mount: "..id.." - "..select(1, C_MountJournal.GetDisplayedMountInfoByID(id)));
        end

        C_MountJournal.SummonByID(id);
        return 1;
    end

    return nil;
end

--- Return an unique area mount according to cat
function A:GetUniqueAreaMount(cat)
    if ( type(A.uniqueAreaMounts[cat][A.currentMapID]) == "table" ) then
        local index = math.random(1, #A.uniqueAreaMounts[cat][A.currentMapID]);

        return A.uniqueAreaMounts[cat][A.currentMapID][index];
    else
        return A.uniqueAreaMounts[cat][A.currentMapID];
    end
end

--- Check if the mount is restricted
-- @param spellID The mount spellID
-- @return bool
function A:IsMountRestricted(spellID)
    if ( select(5, C_MountJournal.GetDisplayedMountInfo(A:GetMountIDFromSpellID(spellID))) ) then
        return nil;
    end

    return 1;
end

--- Get a table with usable mounts
-- It set it as an addon var and return it
-- @param tbl The original mounts table
-- @return The table filtered (cached)
function A:GetUsableMountsTable(tbl)
    if ( not A.usableMountsCache ) then
        A.usableMountsCache = {};
    end

    if ( A.usableMountsCache[tbl] ) then
        return A.usableMountsCache[tbl];
    else
        A.usableMountsCache[tbl] = {};
    end

    for k,v in ipairs(tbl) do
        if ( A:IsMountRestricted(v) ) then -- Got a restricted mount
            A:DebugMessage(("Restricted mount: %s - spell: %d"):format(select(1,GetSpellInfo(v)), v));
        else
            A.usableMountsCache[tbl][#A.usableMountsCache[tbl]+1] = v;
        end
    end

    -- This will prevent a rare case when the mount cache is reset and you are indoor for the server but not for the client, it build an empty cache.
    -- Grats Blizzard for that one, WoD only (aka addons dev we do not care about you).
    if ( #A.usableMountsCache[tbl] == 0 ) then
        A.usableMountsCache[tbl] = nil;

        return {};
    end

    return A.usableMountsCache[tbl];
end

--- Get a random mount from a mounts table
-- @param tbl The original mounts table
-- @return The mount spellID
function A:GetRandomMount(tbl)
    local index = math.random(#A:GetUsableMountsTable(tbl));

    return A.usableMountsCache[tbl][index];
end

--- Check if we got a least one mount available after restriction, in the given table
-- @param tbl The original mounts table
-- @return The number of mounts available or nil
function A:GotRandomMount(tbl)
    local num = #A:GetUsableMountsTable(tbl);

    if ( num > 0 ) then return num; end

    return nil;
end

--- Return if the mount summon should be filtered
function A:IsMountSummonFiltered()
    if ( not A.mountsSummonFiltersCache ) then
        A.mountsSummonFiltersCache = {};

        for k,v in ipairs(A.mountsSummonFilters) do
            if ( A.db.profile.mountsSummonFilters[k] ) then
                A.mountsSummonFiltersCache[k] = v.func;
            end
        end
    end

    for k,v in ipairs(A.mountsSummonFiltersCache) do
        if ( v() ) then return 1; end
    end

    return nil;
end

--- Get other player summoned mount
-- @param unitID target or mouseover
function A:GetOtherPlayerMount(unitID)
    local index = 1;
    local id = select(11, UnitBuff(unitID, index));

    -- One shot, woot!
    for k,v in ipairs(A.pamTable.mountsIds) do
        if ( tContains(A:GetUsableMountsTable(v), id) ) then return id; end
    end

    -- Continue checking
    while id do
        index = index + 1;
        id = select(11, UnitBuff(unitID, index));

        for k,v in ipairs(A.pamTable.mountsIds) do
            if ( tContains(A:GetUsableMountsTable(v), id) ) then return id; end
        end
    end

    return nil;
end

--- Summon a random mount
-- If mounted dismount
-- If not choose a random mount from databases
-- @param cat Mount category, if nil set by A:SetMountCat()
function A:RandomMount(cat)
    A:InitializeDB();

    if ( not A.db.profile.dismountFlying and IsMounted() and IsFlying() ) then
        A:DebugMessage("RandomMount() - Flying no dismount");
        return;
    elseif ( IsMounted() ) then
        A:DebugMessage("RandomMount() - Dismount");
        Dismount();
        return;
    elseif ( A.db.profile.vehicleExit and A:IsPlayerInVehicle() ) then
        VehicleExit();
        return;
    end

    if ( A:IsMountSummonFiltered() ) then
        A:DebugMessage("RandomMount() - No summon filter");
        return;
    end

    if ( A.db.profile.copyTargetMount ) then
        if ( UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") ) then
            local id = A:GetOtherPlayerMount("target");

            if ( A:SummonMountBySpellId(id) ) then return; end
        end
    end

    if ( A.db.profile.copyMouseoverMount ) then
        if ( UnitExists("mouseover") and UnitIsPlayer("mouseover") and not UnitIsUnit("mouseover", "player") ) then
            local id = A:GetOtherPlayerMount("mouseover");

            if ( A:SummonMountBySpellId(id) ) then return; end
        end
    end

    local id;

    if ( not cat ) then cat = A:SetMountCat(); end
    -- ground/fly, do not want hybrid when ground/fly - all forced cat
    if ( (cat == 1 and A.db.profile.noHybridWhenGround)
    or (cat == 2 and A.db.profile.noHybridWhenFly)
    or cat == 3 or cat == 4 or cat == 5 or cat == 6 or cat == 7 ) then
        -- Got forced
        if ( A.db.profile.forceOne.mount[cat] and not A:IsMountRestricted(A.db.profile.forceOne.mount[cat]) ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got forced - %i"):format(cat));
            id = A.db.profile.forceOne.mount[cat];
        -- Got area
        elseif ( A.db.profile.mountByMapID[cat][A.currentMapID] and not A:IsMountRestricted(A.db.profile.mountByMapID[cat][A.currentMapID]) ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got area - %i"):format(cat));
            id = A.db.profile.mountByMapID[cat][A.currentMapID];
        -- Got unique area
        elseif ( A.db.profile.areaMounts and A.uniqueAreaMounts[cat][A.currentMapID] and not A:IsMountRestricted(A.uniqueAreaMounts[cat][A.currentMapID]) ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got unique area - %i"):format(cat));
            id = A:GetUniqueAreaMount(cat);
        -- got fav
        elseif ( A:GotRandomMount(A.currentMountsSet[cat]) ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got fav - %i"):format(cat));
            id = A:GetRandomMount(A.currentMountsSet[cat]);
        -- got global
        elseif ( A:GotRandomMount(A.pamTable.mountsIds[cat]) ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got global - %i"):format(cat));
            id = A:GetRandomMount(A.pamTable.mountsIds[cat]);
        else
            A:DebugMessage(("RandomMount() - No mount for that cat - %i"):format(cat));
            return;
        end
    -- ground, want hybrid when ground - fly
    elseif ( (cat == 1 and not A.db.profile.noHybridWhenGround) or (cat == 2 and not A.db.profile.noHybridWhenFly) ) then
        -- Got forced ground/fly and hybrid
        if ( A.db.profile.forceOne.mount[cat] and A.db.profile.forceOne.mount[3] and not A:IsMountRestricted(A.db.profile.forceOne.mount[cat]) and not A:IsMountRestricted(A.db.profile.forceOne.mount[3]) ) then
            -- hybrid
            if ( A:RandHybrid(1, 1) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got forced - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A.db.profile.forceOne.mount[3];
            -- ground/fly
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got forced - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = A.db.profile.forceOne.mount[cat];
            end
        -- Got forced ground/fly
        elseif ( A.db.profile.forceOne.mount[cat] and not A:IsMountRestricted(A.db.profile.forceOne.mount[cat]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got forced ground/fly - %i"):format(cat));
            id = A.db.profile.forceOne.mount[cat];
        -- Got forced hybrid
        elseif ( A.db.profile.forceOne.mount[3] and not A:IsMountRestricted(A.db.profile.forceOne.mount[3]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got forced hybrid - %i"):format(cat));
            id = A.db.profile.forceOne.mount[3];
        -- No forced going for area
        -- Got area ground/fly and hybrid
        elseif ( A.db.profile.mountByMapID[cat][A.currentMapID] and A.db.profile.mountByMapID[3][A.currentMapID] and not A:IsMountRestricted(A.db.profile.mountByMapID[cat][A.currentMapID]) and not A:IsMountRestricted(A.db.profile.mountByMapID[3][A.currentMapID]) ) then
            -- hybrid
            if ( A:RandHybrid(1, 1) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got area ground/fly - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A.db.profile.mountByMapID[3][A.currentMapID];
            -- ground/fly
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got area ground/fly - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = A.db.profile.mountByMapID[cat][A.currentMapID];
            end
        -- Got area ground/fly
        elseif ( A.db.profile.mountByMapID[cat][A.currentMapID] and not A:IsMountRestricted(A.db.profile.mountByMapID[cat][A.currentMapID]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got area ground/fly - %i"):format(cat));
            id = A.db.profile.mountByMapID[cat][A.currentMapID];
        -- Got area hybrid
        elseif ( A.db.profile.mountByMapID[3][A.currentMapID] and not A:IsMountRestricted(A.db.profile.mountByMapID[3][A.currentMapID]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got area hybrid - %i"):format(cat));
            id = A.db.profile.mountByMapID[3][A.currentMapID];
        -- No area going for unique area
        -- Got unique area ground/fly and hybrid
        elseif ( A.db.profile.areaMounts and A.uniqueAreaMounts[cat][A.currentMapID] and A.uniqueAreaMounts[3][A.currentMapID] and
        not A:IsMountRestricted(A.uniqueAreaMounts[cat][A.currentMapID]) and not A:IsMountRestricted(A.uniqueAreaMounts[3][A.currentMapID]) ) then
            if ( A:RandHybrid(1, 1) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got unique area ground/fly - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A:GetUniqueAreaMount(3);
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got unique area ground/fly - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = A:GetUniqueAreaMount(cat);
            end
        -- Got unique area ground/fly
        elseif ( A.uniqueAreaMounts[cat][A.currentMapID] and A.db.profile.areaMounts and not A:IsMountRestricted(A.uniqueAreaMounts[cat][A.currentMapID]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got unique area ground/fly - %i"):format(cat));
            id = A:GetUniqueAreaMount(cat);
        -- Got unique area hybrid
        elseif ( A.uniqueAreaMounts[3][A.currentMapID] and A.db.profile.areaMounts and not A:IsMountRestricted(A.uniqueAreaMounts[3][A.currentMapID]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got unique area hybrid - %i"):format(cat));
            id = A:GetUniqueAreaMount(3);
        -- No unique area going for fav
        -- got ground/fly and hybrid fav
        elseif ( A:GotRandomMount(A.currentMountsSet[cat]) and A:GotRandomMount(A.currentMountsSet[3]) ) then
            -- hybrid
            if ( A:RandHybrid(A:GotRandomMount(A.currentMountsSet[cat]), A:GotRandomMount(A.currentMountsSet[3])) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got fav - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A:GetRandomMount(A.currentMountsSet[3]);
            -- ground/fly
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got fav - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = A:GetRandomMount(A.currentMountsSet[cat]);
            end
        -- got fav
        elseif ( A:GotRandomMount(A.currentMountsSet[cat]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got fav ground/fly - %i"):format(cat));
            id = A:GetRandomMount(A.currentMountsSet[cat]);
        -- got hybrid fav
        elseif ( A:GotRandomMount(A.currentMountsSet[3]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got fav hybrid - %i"):format(cat));
            id = A:GetRandomMount(A.currentMountsSet[3]);
        -- No fav going for global
        -- got ground/fly & hybrid
        elseif ( A:GotRandomMount(A.pamTable.mountsIds[cat]) and A:GotRandomMount(A.pamTable.mountsIds[3]) ) then
            -- hybrid
            if ( A:RandHybrid(A:GotRandomMount(A.pamTable.mountsIds[cat]), A:GotRandomMount(A.pamTable.mountsIds[3])) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got global - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A:GetRandomMount(A.pamTable.mountsIds[3]);
            -- ground/fly
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got global - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = A:GetRandomMount(A.pamTable.mountsIds[cat]);
            end
        -- got ground/fly
        elseif ( A:GotRandomMount(A.pamTable.mountsIds[cat]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got global - %i"):format(cat));
            id = A:GetRandomMount(A.pamTable.mountsIds[cat]);
        -- got hybrid
        elseif ( A:GotRandomMount(A.pamTable.mountsIds[3]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got hybrid - %i"):format(cat));
            id = A:GetRandomMount(A.pamTable.mountsIds[3]);
        else
            A:DebugMessage(("RandomMount() - No mount for that cat - %i"):format(cat));
            return;
        end
    else -- Unsupported cat
        return;
    end

    if ( A:SummonMountBySpellId(id) ) then return; end

    -- If we are here the player cannot use the mount (horde/alliance specific, achievement, level, etc)
    A:Message(L["Tried to summon %s. It is a mount this toon cannot use (Horde/Alliance specific, achievement, level, etc)."]:format(select(1,GetSpellInfo(id))), 1);
end
