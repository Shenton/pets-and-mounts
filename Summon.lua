--[[-------------------------------------------------------------------------------
    Broker Pets & Mounts
    Data Broker display for easy acces to pets and mounts.
    By: Shenton

    Summon.lua
-------------------------------------------------------------------------------]]--

local A = _G["BrokerPAMGlobal"];
local L = A.L;

-- Globals to locals
local math = math;
local tContains = tContains;
local tostring = tostring;

-- GLOBALS: C_PetJournal, UnitIsFeignDeath, UnitCastingInfo, UnitChannelInfo
-- GLOBALS: UnitIsDeadOrGhost, InCombatLockdown, IsMounted, IsFlying, IsFalling
-- GLOBALS: UnitHasVehicleUI, UnitOnTaxi, HasFullControl, IsSwimming, IsSubmerged
-- GLOBALS: IsFlyableArea, GetNumCompanions, GetCompanionInfo, UnitBuff
-- GLOBALS: CallCompanion, Dismount, IsIndoors, LibStub, IsStealthed, ipairs
-- GLOBALS: GetSpellInfo, IsSpellKnown, SetMapToCurrentZone
-- GLOBALS: GetCurrentMapAreaID, select, GetSpellInfo

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
local _, class = UnitClass("player");
function A:IsStealthed()
    if ( IsStealthed() ) then
        A:DebugMessage("IsStealthed() - Stealthed");
        return 1;
    elseif ( class == "HUNTER" or class == "MAGE" ) then
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

--- Check if a pet is banned
function A:CheckBannedPet(id)
    local _, _, _, _, _, _, _, _, _, _, creatureID = C_PetJournal.GetPetInfoByPetID(id);

    if ( tContains(A.bannedPets, creatureID) ) then return 1; end

    return nil;
end

--- Check if the Hanted Memento is in the player bags
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

        if ( A.stealthCasted ) then
            A:DebugMessage("SummonPet() - stealthCasted");
            A.stealthCasted = nil;
            return;
        end

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

--- Get a random pet from databases and summon it
-- @param auto Bool called from AutoPet()
function A:RandomPet(auto)
    -- DB init
    A:InitializeDB();

    -- Fav pets cleaning
    if ( not A.favoritesCleaned ) then
        A:CleanPetsFavorites();
        A.favoritesCleaned = 1;
    end

    local id;

    -- Get a random pet
    if ( #A.db.profile.favoritePets > 0 ) then
        id = math.random(#A.db.profile.favoritePets);
        id = A.db.profile.favoritePets[id];
    elseif ( #A.pamTable.petsIds > 0 ) then
        id = math.random(#A.pamTable.petsIds);
        id = A.pamTable.petsIds[id];
    else
        return;
    end

    -- Recall this method if we already got the same pet, will work if the player got at least 10 pets (global an fav)
    if ( #A.pamTable.petsIds >= 10 and #A.db.profile.favoritePets >= 10 ) then
        if ( C_PetJournal.GetSummonedPetGUID() and C_PetJournal.GetSummonedPetGUID() == id ) then
            A:RandomPet();
            A:DebugMessage("RandomPet() - Already got that pet, resummon");
            return;
        end
    end

    -- If called by AutoPet() filter some nasty buggy pets
    -- For example winter helpers refuses to be summoned
    if ( auto and A:CheckBannedPet(id) ) then
        A:DebugMessage("RandomPet() - Banned pet filter");
        return;
    end

    A:SummonPet(id);
end

--- Check if a pet can be summoned
function A:AutoPet()
    local currentPet = C_PetJournal.GetSummonedPetGUID();

    -- Got a pet, option is set to not have a pet when stealthed
    if ( currentPet and A:IsNotWhenStealthedEnabled() and A:IsStealthed() ) then
        A:DebugMessage("AutoPet() - Stealthed revoking pet");
        A:RevokePet();
        return;
    end

    if ( not A:IsAutoPetEnabled() -- Auto pet is disabled.
    or A:IsStealthed() -- You don't want a pet to summon while stealthed, nether, or you hate your e-life.
    or UnitIsFeignDeath("player") -- Not when feigning death, seriously no, will look dumb to stand up with a companion next to you.
    or UnitCastingInfo("player") -- Not when casting.
    or UnitChannelInfo("player") -- Not when channeling.
    or UnitIsDeadOrGhost("player") -- Not when dead (thanks captain).
    or InCombatLockdown() -- Not when in combat.
    or A.noAutoPet -- Combat, reviving, fly path end, etc, delay.
    or GetNumLootItems() > 0 -- Player is looting.
    or IsMounted() -- Not when mounted.
    or IsFlying() -- Not when flying, dunno if this is usefull, perhaps when using a flying "mount" from a dungeon event.
    or IsFalling() -- Not when falling. Can seem useless, but summoning a pet trigger a GCD and, falling + GCD + trying to cast a slowfall spell = dead.
    or UnitHasVehicleUI("player") -- Not when in a vehicule.
    or UnitOnTaxi("player") -- Not on a fly path.
    or A:HasRegenBuff() -- Not when eating/drinking.
    or A.stealthCasted -- A stealth/invis spell was casted, this will (should...) prevent some rare case of unsteatlth by summoning pet.
    or not HasFullControl() -- Not when not having full control.
    or GetBarberShopStyleInfo(1) -- Not at barber shop
    or A:CheckHauntedMemento() ) then -- Haunted Memento in bags
        A:DebugMessage("AutoPet() - No summon filter");
        A.stealthCasted = nil;
        return;
    end

    -- Area override
    if ( A.db.profile.petByMapID[tostring(A.currentMapID)] ) then
        if ( A.db.profile.petByMapID[tostring(A.currentMapID)] == currentPet ) then
            A:DebugMessage("AutoPet() - Area override pet - Already got that pet");
            return;
        else
            A:DebugMessage("AutoPet() - Area override pet - summon");
            A:SummonPet(A.db.profile.petByMapID[tostring(A.currentMapID)]);
            return;
        end
    end

    -- Got a pet
    if ( currentPet ) then
        -- Option is set to not summon when having a pet
        if ( A.db.profile.alreadyGotPet ) then
            A:DebugMessage("AutoPet() - Already got a pet");
            return;
        else
            -- Current pet is in fav list, return
            if ( tContains(A.db.profile.favoritePets, currentPet) ) then
                A:DebugMessage("AutoPet() - Already got a fav pet");
                return;
            -- Check if the current pet is banned and not forced
            elseif ( (A.db.profile.forceOne.pet ~= currentPet) and A:CheckBannedPet(currentPet) ) then
                A:DebugMessage("AutoPet() - Summoned pet is banned");
                A:RandomPet(1);
                return;
            -- No fav pet, return
            elseif ( #A.db.profile.favoritePets == 0 ) then
                A:DebugMessage("AutoPet() - No fav pet");
                return;
            end
        end
    end

    -- Summon pet
    if ( A.db.profile.forceOne.pet ) then -- Got forced
        A:DebugMessage("AutoPet() - Forced pet");
        A:SummonPet(A.db.profile.forceOne.pet);
    else -- Summon a random pet
        A:DebugMessage("AutoPet() - Random pet");
        A:RandomPet(1);
    end
end

--[[-------------------------------------------------------------------------------
    Mounts methods
-------------------------------------------------------------------------------]]--

--- Return a bool value with a random based on the two args
function A:RandHybrid(ground, hybrid)
    ground = ground * 1000;
    hybrid = hybrid * 1000;

    local total = ground + hybrid;

    if ( math.random(total) > hybrid ) then
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

--- Check if the player can ride a (ground) mount
-- Apprentice Riding 33388
-- Journeyman Riding 33391
function A:CanRide()
    if ( IsSpellKnown(33388) and IsSpellKnown(33391) ) then
        return 1;
    end

    return nil;
end

--- Return the mount type according to the bitfield
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

--- Set wich mount category should be used
function A:SetMountCat()
    -- [1] = {}, -- Ground
    -- [2] = {}, -- Fly
    -- [3] = {}, -- Hybrid (ground & fly)
    -- [4] = {}, -- Aquatic
    -- [5] = {}, -- with passengers
    if ( IsSubmerged() or IsSwimming() ) then -- Aquatic mount
        A:DebugMessage("SetMountCat() - Aquatic");
        return 4;
    elseif ( A:IsFlyable() ) then -- Flyable mount
        A:DebugMessage("SetMountCat() - Flyable");
        return 2;
    else -- Ground mount
        A:DebugMessage("SetMountCat() - Ground");
        return 1;
    end

    return nil;
end

--- Summon a mount with it spell ID
function A:SummonMountBySpellId(id)
    local numMounts = GetNumCompanions("MOUNT");
    local _, name, spellId;

    for i=1,numMounts do
        _, name, spellId = GetCompanionInfo("MOUNT", i);

        if ( spellId == id ) then
            A:DebugMessage("Summon mount: "..name);
            CallCompanion("MOUNT", i);
            return 1;
        end
    end

    return nil;
end

--- Summon a mount according to the current area ID
function A:SummonMountByAreaID()
    if ( not A.db.profile.areaMounts ) then
        return nil;
    end

    local currentArea;

    SetMapToCurrentZone();
    currentArea = GetCurrentMapAreaID();

    if ( A.areaMounts[currentArea] ) then
        A:SummonMountBySpellId(A.areaMounts[currentArea]);
        return 1;
    end

    return nil;
end

--- Summon a random mount
-- If mounted dismount
-- If not choose a random from databases
-- @param cat Mount category set by A:SetMountCat()
function A:RandomMount(cat)
    A:InitializeDB();

    if ( IsMounted() and ((IsFlying() and A.db.profile.dismountFlying) or not IsFlying()) ) then
        A:DebugMessage("RandomMount() - Dismount");
        Dismount();
        return;
    end

    if ( UnitCastingInfo("player") -- Not when casting
    or IsFalling() -- Not when falling.
    or IsIndoors() -- Not indoor, "should" work in indoor place when you can mount, but will see, theramore scenario is flyable and you cant use fly mount, meh blizzard
    or UnitOnTaxi("player") ) then -- Not on a fly path.
        A:DebugMessage("RandomMount() - No summon filter");
        return;
    end

    -- If enabled and defined will sumonn a mount according to areaID
    if ( A:SummonMountByAreaID() ) then return; end

    local id;

    if ( not cat ) then cat = A:SetMountCat(); end

    -- ground, do not want hybrid when ground - aqua - passenger
    if ( (cat == 1 and A.db.profile.noHybridWhenGround) or cat == 4 or cat == 5 ) then
        -- Got area
        if ( A.db.profile.mountByMapID[cat][tostring(A.currentMapID)] ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got area - %i"):format(cat));
            id = A.db.profile.mountByMapID[cat][tostring(A.currentMapID)];
        -- Got forced
        elseif ( A.db.profile.forceOne.mount[cat] ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got forced - %i"):format(cat));
            id = A.db.profile.forceOne.mount[cat];
        -- got fav
        elseif ( #A.db.profile.favoriteMounts[cat] > 0 ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got fav - %i"):format(cat));
            id = math.random(#A.db.profile.favoriteMounts[cat]);
            id = A.db.profile.favoriteMounts[cat][id];
        -- got global
        elseif ( #A.pamTable.mountsIds[cat] > 0 ) then
            A:DebugMessage(("RandomMount() - No hybrid - Got global - %i"):format(cat));
            id = math.random(#A.pamTable.mountsIds[cat]);
            id = A.pamTable.mountsIds[cat][id];
        else
            A.isSummoningMount = nil;
            return;
        end
    -- ground, want hybrid when ground - fly
    elseif ( (cat == 1 and not A.db.profile.noHybridWhenGround) or cat == 2 ) then
        -- Got area ground/fly and hybrid
        if ( A.db.profile.mountByMapID[cat][tostring(A.currentMapID)] and A.db.profile.mountByMapID[3][tostring(A.currentMapID)] ) then
            -- hybrid
            if ( A:RandHybrid(1, 1) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got area - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A.db.profile.mountByMapID[3][tostring(A.currentMapID)];
            -- ground/fly
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got area - Got hybrid - Rand no hybrid - %i"):format(cat));
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
        -- No area going for forced
        -- Got forced ground/fly and hybrid
        elseif ( A.db.profile.forceOne.mount[cat] and A.db.profile.forceOne.mount[3] ) then
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
        -- No forced going for fav
        -- got ground/fly and hybrid fav
        elseif ( #A.db.profile.favoriteMounts[cat] > 0 and #A.db.profile.favoriteMounts[3] > 0 ) then
            -- hybrid
            if ( A:RandHybrid(#A.db.profile.favoriteMounts[cat], #A.db.profile.favoriteMounts[3]) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got fav - Got hybrid - Rand hybrid - %i"):format(cat));
                id = math.random(#A.db.profile.favoriteMounts[3]);
                id = A.db.profile.favoriteMounts[3][id];
            -- ground/fly
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got fav - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = math.random(#A.db.profile.favoriteMounts[cat]);
                id = A.db.profile.favoriteMounts[cat][id];
            end
        -- got fav
        elseif ( #A.db.profile.favoriteMounts[cat] > 0 ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got fav ground/fly - %i"):format(cat));
            id = math.random(#A.db.profile.favoriteMounts[cat]);
            id = A.db.profile.favoriteMounts[cat][id];
        -- got hybrid fav
        elseif ( #A.db.profile.favoriteMounts[3] > 0 ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got fav hybrid - %i"):format(cat));
            id = math.random(#A.db.profile.favoriteMounts[3]);
            id = A.db.profile.favoriteMounts[3][id];
        -- No fav going for global
        -- got ground/fly & hybrid
        elseif ( #A.pamTable.mountsIds[cat] > 0 and #A.pamTable.mountsIds[3] > 0 ) then
            -- hybrid
            if ( A:RandHybrid(#A.pamTable.mountsIds[cat], #A.pamTable.mountsIds[3]) ) then
                A:DebugMessage(("RandomMount() - With hybrid - Got global - Got hybrid - Rand hybrid - %i"):format(cat));
                id = math.random(#A.pamTable.mountsIds[3]);
                id = A.pamTable.mountsIds[3][id];
            -- ground/fly
            else
                A:DebugMessage(("RandomMount() - With hybrid - Got global - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = math.random(#A.pamTable.mountsIds[cat]);
                id = A.pamTable.mountsIds[cat][id];
            end
        -- got ground/fly
        elseif ( #A.pamTable.mountsIds[cat] > 0 ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got global - %i"):format(cat));
            id = math.random(#A.pamTable.mountsIds[cat]);
            id = A.pamTable.mountsIds[cat][id];
        -- got hybrid
        elseif ( #A.pamTable.mountsIds[3] > 0 ) then
            A:DebugMessage(("RandomMount() - With hybrid - Got hybrid - %i"):format(cat));
            id = math.random(#A.pamTable.mountsIds[3]);
            id = A.pamTable.mountsIds[3][id];
        else
            A.isSummoningMount = nil;
            return;
        end
    end

    if ( A:SummonMountBySpellId(id) ) then return; end

    -- If we are here the player cannot use the mount (horde/alliance specific, achievement, level, etc)
    A:DebugMessage("Tried to summon mount: "..select(1,GetSpellInfo(id)));
    A:Message(L["Tried to summon %s. It is a mount this toon cannot use (Horde/Alliance specific, achievement, level, etc)."]:format(select(1,GetSpellInfo(id))));
end
