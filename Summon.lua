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

-- GLOBALS: tContains, C_PetJournal, UnitIsFeignDeath, UnitCastingInfo, UnitChannelInfo
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

--- Summon a pet by GUID
function A:SummonPet(id)
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
    A:DebugMessage("RevokePet()");

    -- if ( A.currentPet ) then
        -- C_PetJournal.SummonPetByGUID(A.currentPet);
    -- elseif ( C_PetJournal.GetSummonedPetGUID() ) then
        -- C_PetJournal.SummonPetByGUID(C_PetJournal.GetSummonedPetGUID());
    -- end

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
    if ( #A.pamTable.petsIds > 10 and #A.db.profile.favoritePets > 10 ) then
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
    or A.isLooting -- Player is looting.
    or IsMounted() -- Not when mounted.
    or IsFlying() -- Not when flying, dunno if this is usefull, perhaps when using a flying "mount" from a dungeon event.
    or IsFalling() -- Not when falling. Can seem useless, but summoning a pet trigger a GCD and, falling + GCD + trying to cast a slowfall spell = dead.
    or UnitHasVehicleUI("player") -- Not when in a vehicule.
    or UnitOnTaxi("player") -- Not on a fly path.
    or A:HasRegenBuff() -- Not when eating/drinking.
    or A.stealthCasted -- A stealth/invis spell was casted, this will (should...) prevent some rare case of unsteatlth by summoning pet.
    or not HasFullControl() ) then -- Not when not having full control.
        A:DebugMessage("AutoPet() - No summon filter");
        A.stealthCasted = nil;
        return;
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
-- @param noFav force ignoring fav mounts
function A:RandomMount(cat, noFav)
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
    if ( A:SummonMountByAreaID() ) then
        return;
    end

    local id, isHybrid;

    if ( not cat ) then cat = A:SetMountCat(); end

    if ( (cat == 1 and A.db.profile.noHybridWhenGround) or cat == 4 or cat == 5 ) then -- ground, do not want hybrid when ground - aqua - passenger
        if ( A.db.profile.forceOne.mount[cat] ) then -- Got forced
            A:DebugMessage(("RandomMount() - No hybrid - Got forced - %i"):format(cat));
            id = A.db.profile.forceOne.mount[cat];
        elseif ( #A.db.profile.favoriteMounts[cat] > 0 ) then -- got fav
            A:DebugMessage(("RandomMount() - No hybrid - Got fav - %i"):format(cat));
            id = math.random(#A.db.profile.favoriteMounts[cat]);
            id = A.db.profile.favoriteMounts[cat][id];
        elseif ( #A.pamTable.mountsIds[cat] > 0 ) then -- got global
            A:DebugMessage(("RandomMount() - No hybrid - Got global - %i"):format(cat));
            id = math.random(#A.pamTable.mountsIds[cat]);
            id = A.pamTable.mountsIds[cat][id];
        else
            A.isSummoningMount = nil;
            return;
        end
    elseif ( (cat == 1 and not A.db.profile.noHybridWhenGround) or cat == 2 ) then -- ground, want hybrid when ground - fly
        if ( A.db.profile.forceOne.mount[cat] and A.db.profile.forceOne.mount[3] ) then -- Got forced ground/fly and hybrid
            if ( math.random(100) > 50 ) then -- hybrid
                A:DebugMessage(("RandomMount() - With hybrid - Got forced - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A.db.profile.forceOne.mount[3];
                isHybrid = 1;
            else -- ground/fly
                A:DebugMessage(("RandomMount() - With hybrid - Got forced - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = A.db.profile.forceOne.mount[cat];
            end
        elseif ( A.db.profile.forceOne.mount[cat] ) then -- Got forced ground/fly
            A:DebugMessage(("RandomMount() - With hybrid - Got forced ground/fly - %i"):format(cat));
            id = A.db.profile.forceOne.mount[cat];
        elseif ( A.db.profile.forceOne.mount[3] ) then -- Got forced ground/fly
            A:DebugMessage(("RandomMount() - With hybrid - Got forced hybrid - %i"):format(cat));
            id = A.db.profile.forceOne.mount[3];
            isHybrid = 1;
        elseif ( #A.db.profile.favoriteMounts[cat] > 0 and #A.db.profile.favoriteMounts[3] > 0 ) then -- got ground/fly and hybrid fav
            if ( math.random(100) > 50 ) then -- hybrid
                A:DebugMessage(("RandomMount() - With hybrid - Got fav - Got hybrid - Rand hybrid - %i"):format(cat));
                id = math.random(#A.db.profile.favoriteMounts[3]);
                id = A.db.profile.favoriteMounts[3][id];
                isHybrid = 1;
            else -- ground/fly
                A:DebugMessage(("RandomMount() - With hybrid - Got fav - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = math.random(#A.db.profile.favoriteMounts[cat]);
                id = A.db.profile.favoriteMounts[cat][id];
            end
        elseif ( #A.db.profile.favoriteMounts[cat] > 0 ) then -- got fav
            A:DebugMessage(("RandomMount() - With hybrid - Got fav ground/fly - %i"):format(cat));
            id = math.random(#A.db.profile.favoriteMounts[cat]);
            id = A.db.profile.favoriteMounts[cat][id];
        elseif ( #A.db.profile.favoriteMounts[3] > 0 ) then -- got hybrid fav
            A:DebugMessage(("RandomMount() - With hybrid - Got hybrid - %i"):format(cat));
            id = math.random(#A.db.profile.favoriteMounts[3]);
            id = A.db.profile.favoriteMounts[3][id];
            isHybrid = 1;
        -- No fav checking global
        elseif ( #A.pamTable.mountsIds[cat] > 0 and #A.pamTable.mountsIds[3] > 0 ) then -- got ground/fly & hybrid
            if ( math.random(100) > 50 ) then -- hybrid
                A:DebugMessage(("RandomMount() - With hybrid - Got global - Got hybrid - Rand hybrid - %i"):format(cat));
                id = math.random(#A.pamTable.mountsIds[3]);
                id = A.pamTable.mountsIds[3][id];
                isHybrid = 1;
            else -- ground/fly
                A:DebugMessage(("RandomMount() - With hybrid - Got global - Got hybrid - Rand no hybrid - %i"):format(cat));
                id = math.random(#A.pamTable.mountsIds[cat]);
                id = A.pamTable.mountsIds[cat][id];
            end
        elseif ( #A.pamTable.mountsIds[cat] > 0 ) then -- got ground/fly
            A:DebugMessage(("RandomMount() - With hybrid - Got global - %i"):format(cat));
            id = math.random(#A.pamTable.mountsIds[cat]);
            id = A.pamTable.mountsIds[cat][id];
        elseif ( #A.pamTable.mountsIds[3] > 0 ) then -- got hybrid
            A:DebugMessage(("RandomMount() - With hybrid - Got hybrid - %i"):format(cat));
            id = math.random(#A.pamTable.mountsIds[3]);
            id = A.pamTable.mountsIds[3][id];
            isHybrid = 1;
        else
            A.isSummoningMount = nil;
            return;
        end
    end

    if ( A:SummonMountBySpellId(id) ) then
        return;
    end

    -- If we are here the player cannot use the mount (horde/alliance specific, achievement, level, etc)
    A:DebugMessage("Tryed to summon mount: "..select(1,GetSpellInfo(id)));

    -- Too hazardous
    -- if ( isHybrid ) then
        -- if ( #A.pamTable.mountsIds[3] > 10 and #A.db.profile.favoriteMounts[3] > 10 ) then
            -- A:RandomMount(cat, 1);
            -- return;
        -- end
    -- else
        -- if ( #A.pamTable.mountsIds[cat] > 10 and #A.db.profile.favoriteMounts[cat] > 10 ) then
            -- A:RandomMount(cat, 1);
            -- return;
        -- end
    -- end

    -- If we are here we also failed to resummon a random mount
    -- /!\ MESSAGE TO PLAYER /!\
end
