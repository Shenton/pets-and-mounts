--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Summon.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- Globals to locals
local math = math;
local tContains = tContains;
local tostring = tostring;
local ipairs = ipairs;

-- GLOBALS: C_PetJournal, UnitIsFeignDeath, UnitCastingInfo, UnitChannelInfo
-- GLOBALS: UnitIsDeadOrGhost, InCombatLockdown, IsMounted, IsFlying, IsFalling
-- GLOBALS: UnitHasVehicleUI, UnitOnTaxi, HasFullControl, IsSwimming, IsSubmerged
-- GLOBALS: IsFlyableArea, GetNumCompanions, GetCompanionInfo, UnitBuff
-- GLOBALS: CallCompanion, Dismount, IsIndoors, LibStub, IsStealthed
-- GLOBALS: GetSpellInfo, IsSpellKnown, SetMapToCurrentZone, GetItemCount
-- GLOBALS: GetCurrentMapAreaID, select, GetSpellInfo, GetNumLootItems
-- GLOBALS: GetBarberShopStyleInfo, IsUsableSpell, type, GetProfessions
-- GLOBALS: GetProfessionInfo, GetMirrorTimerInfo, VehicleExit

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
        return;
    end

    A:DebugMessage("SummonPet()");

    if ( C_PetJournal.PetIsSummonable(id) ) then
        A:DebugMessage("RandomPet() - Summon pet: "..A:GetPetNameByID(id));

        C_PetJournal.SummonPetByGUID(id);
    end
end

--- Revoke current pet
function A:RevokePet()
    if ( InCombatLockdown() ) then
        A:DebugMessage("RevokePet() - In combat");
        return;
    end

    A:DebugMessage("RevokePet()");

    local currentPet = C_PetJournal.GetSummonedPetGUID();

    if ( not currentPet ) then return; end

    C_PetJournal.SummonPetByGUID(currentPet);
end

--- Build a table with usable pets
-- @param tbl The original mounts table
-- @return The table filtered
function A:BuildUsablePetsTable(tbl)
    local out = {};

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
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted pet: %s - type: %s - npc: %d"):format(customName or name, A.restrictedPets[id].type, id));
                    end
                else
                    if ( A.restrictedPets[id].args == A.playerFaction ) then
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted pet: %s - type: %s - npc: %d"):format(customName or name, A.restrictedPets[id].type, id));
                    end
                end
            end
        else
            out[#out+1] = v;
        end
    end

    return out;
end

--- Get a random pet from a petts table
-- @param tbl The original petts table
-- @return The pet ID
function A:GetRandomPet(tbl)
    if ( not A.usablePetsCache ) then
        A.usablePetsCache = {};
    end

    if ( not A.usablePetsCache[tbl] ) then
        A.usablePetsCache[tbl] = A:BuildUsablePetsTable(tbl);
    end

    local index = math.random(#A.usablePetsCache[tbl]);

    return A.usablePetsCache[tbl][index];
end

--- Check if we got a least one mount available after restriction in the given table
-- @param tbl The original mounts table
-- @return The number of mounts available or nil
function A:GotRandomPet(tbl)
    if ( not A.usablePetsCache ) then
        A.usablePetsCache = {};
    end

    if ( not A.usablePetsCache[tbl] ) then
        A.usablePetsCache[tbl] = A:BuildUsablePetsTable(tbl);
    end

    local num = #A.usablePetsCache[tbl];

    if ( num > 0 ) then return num; end

    return nil;
end

--- Get a random pet from databases and summon it
function A:RandomPet()
    -- DB init
    A:InitializeDB();

    local id;

    -- Get a random pet
    if ( A:GotRandomPet(A.db.profile.favoritePets) ) then
        id = A:GetRandomPet(A.db.profile.favoritePets);
    elseif ( A:GotRandomPet(A.pamTable.petsIds) ) then
        id = A:GetRandomPet(A.pamTable.petsIds);
    else
        return;
    end

    A:SummonPet(id);
end

--- Return if the pet summon should be filtered
function A:IsPetSummonFiltered()
    if ( not A.petsSummonFiltersCache ) then
        A.petsSummonFiltersCache = {};

        for k,v in ipairs(A.petsSummonFilters) do
            if ( A.db.profile.petsSummonFilters[k] ) then
                A.petsSummonFiltersCache[k] = v.func;
            end
        end
    end

    for k,v in ipairs(A.petsSummonFiltersCache) do
        if ( v() ) then return 1; end
    end

    return nil;
end

--- Check if a pet can be summoned
function A:AutoPet()
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
    if ( currentPet and A.db.profile.alreadyGotPet ) then
        A:DebugMessage("AutoPet() - Already got a pet");
        return;
    end

    -- Pet summon filtered
    if ( A:IsPetSummonFiltered() ) then
        A:DebugMessage("AutoPet() - Pet summon filtered");
        return;
    end

    -- Haunted Memento
    if ( A:CheckHauntedMemento() ) then
        A:RevokePet();
        return;
    end

    if ( A.db.profile.forceOne.pet ) then -- Forced pet
        if ( currentPet and currentPet == A.db.profile.forceOne.pet ) then
            A:DebugMessage("AutoPet() - Forced pet is current");
        else
            A:DebugMessage("AutoPet() - Forced pet");
            A:SummonPet(A.db.profile.forceOne.pet);
        end
    elseif ( A.db.profile.petByMapID[tostring(A.currentMapID)] ) then -- Area pet
        if ( A.db.profile.petByMapID[tostring(A.currentMapID)] == currentPet ) then
            A:DebugMessage("AutoPet() - Area override pet - Already got that pet");
        else
            A:DebugMessage("AutoPet() - Area override pet - summon");
            A:SummonPet(A.db.profile.petByMapID[tostring(A.currentMapID)]);
        end
    elseif ( A:GotRandomPet(A.db.profile.favoritePets) ) then -- Fav pets
        if ( currentPet and tContains(A.db.profile.favoritePets, currentPet) ) then
            A:DebugMessage("AutoPet() - Already got a fav pet");
        else
            local id = A:GetRandomPet(A.db.profile.favoritePets);
            A:SummonPet(id);
        end
    elseif ( not currentPet and A:GotRandomPet(A.pamTable.petsIds) ) then -- All pets
        local id = A:GetRandomPet(A.pamTable.petsIds);
        A:SummonPet(id);
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
-- Apprentice Riding 33388
-- Journeyman Riding 33391
function A:CanRide()
    if ( IsSpellKnown(33388) or IsSpellKnown(33391) ) then
        return 1;
    end

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
        return 4;
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
function A:SummonMountBySpellId(id)
    local numMounts = GetNumCompanions("MOUNT");
    local _, name, spellID;

    for i=1,numMounts do
        _, name, spellID = GetCompanionInfo("MOUNT", i);

        if ( spellID == id ) then
            A:DebugMessage("Summon mount: "..name);
            CallCompanion("MOUNT", i);
            return 1;
        end
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

--- Build a table with usable mounts
-- @param tbl The original mounts table
-- @return The table filtered
function A:BuildUsableMountsTable(tbl)
    local out = {};

    for k,v in ipairs(tbl) do
        if ( A.restrictedMounts[v] ) then -- Got a restricted mount
            -- Location
            if ( A.restrictedMounts[v].type == "location" ) then
                if ( type(A.restrictedMounts[v].args) == "table" ) then
                    if ( tContains(A.restrictedMounts[v].args, A.currentMapID) ) then
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                    end
                else
                    if ( A.restrictedMounts[v].args == A.currentMapID ) then
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                    end
                end
            -- Spell
            elseif ( A.restrictedMounts[v].type == "spell" ) then
                if ( type(A.restrictedMounts[v].args) == "table" ) then
                    for kk,vv in ipairs(A.restrictedMounts[v].args) do
                        if ( IsSpellKnown(vv) ) then
                            out[#out+1] = v;
                            break;
                        end
                    end

                    A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                else
                    if ( IsSpellKnown(A.restrictedMounts[v].args) ) then
                        out[#out+1] = v
                    else
                        A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                    end
                end
            -- Class
            elseif ( A.restrictedMounts[v].type == "class" ) then
                if ( type(A.restrictedMounts[v].args) == "table" ) then
                    if ( tContains(A.restrictedMounts[v].args, A.playerClass) ) then
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                    end
                else
                    if ( A.restrictedMounts[v].args == A.playerClass ) then
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                    end
                end
            -- Faction
            elseif ( A.restrictedMounts[v].type == "faction" ) then
                if ( type(A.restrictedMounts[v].args) == "table" ) then
                    if ( tContains(A.restrictedMounts[v].args, A.playerFaction) ) then
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                    end
                else
                    if ( A.restrictedMounts[v].args == A.playerFaction ) then
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                    end
                end
            -- Race & class
            elseif ( A.restrictedMounts[v].type == "race&class" ) then
                if ( type(A.restrictedMounts[v].args) == "table" ) then
                    if ( tContains(A.restrictedMounts[v].args, A.playerRace..A.playerClass) ) then
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                    end
                else
                    if ( A.restrictedMounts[v].args == A.playerRace..A.playerClass ) then
                        out[#out+1] = v;
                    else
                        A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                    end
                end
            -- Profession
            elseif ( A.restrictedMounts[v].type == "profession" ) then
                local professionOne, professionTwo = GetProfessions();
                local professionOneSkill, professionTwoSkill, _;

                if ( professionOne ) then
                    _, _, professionOneSkill, _, _, _, professionOne = GetProfessionInfo(professionOne);
                end

                if ( professionTwo ) then
                    _, _, professionTwoSkill, _, _, _, professionTwo = GetProfessionInfo(professionTwo);
                end

                if ( (professionOne and professionOne == A.restrictedMounts[v].args[1] and professionOneSkill >= A.restrictedMounts[v].args[2])
                or (professionTwo and professionTwo == A.restrictedMounts[v].args[1] and professionTwoSkill >= A.restrictedMounts[v].args[2]) ) then
                    out[#out+1] = v;
                else
                    A:DebugMessage(("Restricted mount: %s - type: %s - spell: %d"):format(select(1,GetSpellInfo(v)), A.restrictedMounts[v].type, v));
                end
            end
        else
            out[#out+1] = v;
        end
    end

    return out;
end

--- Get a random mount from a mounts table
-- @param tbl The original mounts table
-- @return The mount spellID
function A:GetRandomMount(tbl)
    if ( not A.usableMountsCache ) then
        A.usableMountsCache = {};
    end

    if ( not A.usableMountsCache[tbl] ) then
        A.usableMountsCache[tbl] = A:BuildUsableMountsTable(tbl);
    end

    local index = math.random(#A.usableMountsCache[tbl]);

    return A.usableMountsCache[tbl][index];
end

--- Check if we got a least one mount available after restriction, in the given table
-- @param tbl The original mounts table
-- @return The number of mounts available or nil
function A:GotRandomMount(tbl)
    if ( not A.usableMountsCache ) then
        A.usableMountsCache = {};
    end

    if ( not A.usableMountsCache[tbl] ) then
        A.usableMountsCache[tbl] = A:BuildUsableMountsTable(tbl);
    end

    local num = #A.usableMountsCache[tbl];

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

--- Summon a random mount
-- If mounted dismount
-- If not choose a random from databases
-- @param cat Mount category set by A:SetMountCat()
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

    local id;

    if ( not cat ) then cat = A:SetMountCat(); end
    -- ground/fly, do not want hybrid when ground/fly - all forced cat
    if ( (cat == 1 and A.db.profile.noHybridWhenGround)
    or (cat == 2 and A.db.profile.noHybridWhenFly)
    or cat == 3 or cat == 4 or cat == 5 or cat == 6 or cat == 7 ) then
        -- Got forced
        if ( A.db.profile.forceOne.mount[cat] ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got forced - %i"):format(cat));
            id = A.db.profile.forceOne.mount[cat];
        -- Got area
        elseif ( A.db.profile.mountByMapID[cat][tostring(A.currentMapID)] ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got area - %i"):format(cat));
            id = A.db.profile.mountByMapID[cat][tostring(A.currentMapID)];
        -- Got unique area
        elseif ( A.db.profile.areaMounts and A.uniqueAreaMounts[cat][A.currentMapID] ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got unique area - %i"):format(cat));
            id = A:GetUniqueAreaMount(cat);
        -- got fav
        elseif ( A:GotRandomMount(A.db.profile.favoriteMounts[cat]) ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got fav - %i"):format(cat));
            id = A:GetRandomMount(A.db.profile.favoriteMounts[cat]);
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
        if ( A.db.profile.forceOne.mount[cat] and A.db.profile.forceOne.mount[3] ) then
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
        elseif ( A.db.profile.forceOne.mount[cat] ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got forced ground/fly - %i"):format(cat));
            id = A.db.profile.forceOne.mount[cat];
        -- Got forced hybrid
        elseif ( A.db.profile.forceOne.mount[3] ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got forced hybrid - %i"):format(cat));
            id = A.db.profile.forceOne.mount[3];
        -- No forced going for area
        -- Got area ground/fly and hybrid
        elseif ( A.db.profile.mountByMapID[cat][tostring(A.currentMapID)] and A.db.profile.mountByMapID[3][tostring(A.currentMapID)] ) then
            -- hybrid
            if ( A:RandHybrid(1, 1) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got area ground/fly - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A.db.profile.mountByMapID[3][tostring(A.currentMapID)];
            -- ground/fly
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got area ground/fly - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = A.db.profile.mountByMapID[cat][tostring(A.currentMapID)];
            end
        -- Got area ground/fly
        elseif ( A.db.profile.mountByMapID[cat][tostring(A.currentMapID)] ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got area ground/fly - %i"):format(cat));
            id = A.db.profile.mountByMapID[cat][tostring(A.currentMapID)];
        -- Got area hybrid
        elseif ( A.db.profile.mountByMapID[3][tostring(A.currentMapID)] ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got area hybrid - %i"):format(cat));
            id = A.db.profile.mountByMapID[3][tostring(A.currentMapID)];
        -- No area going for unique area
        -- Got unique area ground/fly and hybrid
        elseif ( A.db.profile.areaMounts and A.uniqueAreaMounts[cat][A.currentMapID] and A.uniqueAreaMounts[3][A.currentMapID] ) then
            if ( A:RandHybrid(1, 1) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got unique area ground/fly - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A:GetUniqueAreaMount(3);
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got unique area ground/fly - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = A:GetUniqueAreaMount(cat);
            end
        -- Got unique area ground/fly
        elseif ( A.db.profile.areaMounts and A.uniqueAreaMounts[cat][A.currentMapID] ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got unique area ground/fly - %i"):format(cat));
            id = A:GetUniqueAreaMount(cat);
        -- Got unique area hybrid
        elseif ( A.db.profile.areaMounts and A.uniqueAreaMounts[3][A.currentMapID] ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got unique area hybrid - %i"):format(cat));
            id = A:GetUniqueAreaMount(3);
        -- No unique area going for fav
        -- got ground/fly and hybrid fav
        elseif ( A:GotRandomMount(A.db.profile.favoriteMounts[cat]) and A:GotRandomMount(A.db.profile.favoriteMounts[3]) ) then
            -- hybrid
            if ( A:RandHybrid(A:GotRandomMount(A.db.profile.favoriteMounts[cat]), A:GotRandomMount(A.db.profile.favoriteMounts[3])) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got fav - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A:GetRandomMount(A.db.profile.favoriteMounts[3]);
            -- ground/fly
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got fav - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = A:GetRandomMount(A.db.profile.favoriteMounts[cat]);
            end
        -- got fav
        elseif ( A:GotRandomMount(A.db.profile.favoriteMounts[cat]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got fav ground/fly - %i"):format(cat));
            id = A:GetRandomMount(A.db.profile.favoriteMounts[cat]);
        -- got hybrid fav
        elseif ( A:GotRandomMount(A.db.profile.favoriteMounts[3]) ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got fav hybrid - %i"):format(cat));
            id = A:GetRandomMount(A.db.profile.favoriteMounts[3]);
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
