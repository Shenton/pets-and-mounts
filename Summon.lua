-- ********************************************************************************
-- Broker Pets & Mounts
-- Data Broker display for easy acces to pets and mounts.
-- By: Shenton
--
-- Summon.lua
-- ********************************************************************************

local A = _G["BrokerPAMGlobal"];
local L = A.L;

-- Lua globals to locals
local math = math;

-- WoW globals to locals
local tContains = tContains;

-- ********************************************************************************
-- Functions
-- ********************************************************************************

--- Get a random pet from databases and summon it
-- @param auto Bool called from AutoPet()
function A:RandomPet(auto)
    A:Initialize();

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
    -- For example winter helpers refuses to be summoned, and this %*µ£§ of Blizzard auto resummon
    -- will try to summon it when you cast stealth (because the addon revoke it) wich will unstealth you.
    if ( auto and A:CheckBannedPet(id) ) then
        A:DebugMessage("RandomPet() - Banned pet filter");
        return;
    end

    if ( C_PetJournal.PetIsSummonable(id) ) then
        if ( A.db.profile.debug ) then
            local _, customName, _, _, _, _, _,creatureName = C_PetJournal.GetPetInfoByPetID(id);

            if ( customName ) then
                A:DebugMessage("RandomPet() - Summon pet: "..customName);
            else
                A:DebugMessage("RandomPet() - Summon pet: "..creatureName);
            end
        end

        if ( A.stealthCasted ) then
            A.stealthCasted = nil;
            return;
        end
        C_PetJournal.SummonPetByGUID(id);
    end
end

--- Revoke current pet
function A:RevokePet()
    if ( A.currentPet ) then
        C_PetJournal.SummonPetByGUID(A.currentPet);
    elseif ( C_PetJournal.GetSummonedPetGUID() ) then
        C_PetJournal.SummonPetByGUID(C_PetJournal.GetSummonedPetGUID());
    end
end

--- Check if a pet can be summoned
function A:AutoPet()
    local currentPet = C_PetJournal.GetSummonedPetGUID();

    -- Got a pet, option is set to not have a pet when stealthed
    if ( currentPet and A.db.profile.notWhenStealthed and A:IsStealthed() ) then
        A:DebugMessage("AutoPet() - Stealthed revoking pet");
        A:RevokePet();
        return;
    end

    if ( not A.db.profile.autoPet -- Auto pet is disabled.
    or A:IsStealthed() -- You don't want a pet to summon while stealthed, nether, or you hate your e-life.
    or UnitIsFeignDeath("player") -- Not when feigning death, seriously no, will look dumb to stand up with a companion next to you.
    or UnitCastingInfo("player") -- Not when casting.
    or UnitChannelInfo("player") -- Not when channeling.
    or UnitIsDeadOrGhost("player") -- Not when dead (thanks captain).
    or InCombatLockdown() -- Not when in combat.
    or A.noAutoPet -- Combat, reviving, fly path end, etc, delay.
    or IsMounted() -- Not when mounted.
    or IsFlying() -- Not when flying, dunno if this is usefull, perhaps when using a flying "mount" from a dungeon event.
    or IsFalling() -- Not when falling.
    or UnitHasVehicleUI("player") -- Not when in a vehicule.
    or UnitOnTaxi("player") -- Not on a fly path.
    or A:HasRegenBuff() -- Not when eating/drinking.
    or A.stealthCasted -- A stealth/invis spell was casted, this will prevent some rare case of unsteatlth by summoning pet.
    or not HasFullControl() ) then -- Not when not having full control.
        A:DebugMessage("AutoPet() - No summon filter");
        A.stealthCasted = nil;
        return;
    end

    -- Got a pet, option is set to not summon when having a pet
    if ( tContains(A.db.profile.favoritePets, currentPet) or (currentPet and A.db.profile.alreadyGotPet) ) then
        if ( A:CheckBannedPet(currentPet) ) then
            A:DebugMessage("AutoPet() - Summoned pet is banned");
            A:RandomPet(1);
        else
            A:DebugMessage("AutoPet() - Already got a pet");
        end

        return;
    end

    -- Summon a random pet 
    A:RandomPet(1);
end

--- Set wich mount category should be used
function A:SetMountCat()
    -- [1] = {}, -- Ground
    -- [2] = {}, -- Fly
    -- [3] = {}, -- Hybrid (ground & fly)
    -- [4] = {}, -- Aquatic
    -- [5] = {}, -- with passengers
    if ( IsSwimming() ) then -- Aquatic mount
        if ( IsSubmerged() ) then -- We are under water
            A:DebugMessage("SetMountCat() - Aquatic");
            return 4;
        else -- We are at the water surface
            if ( IsFlyableArea() ) then
                A:DebugMessage("SetMountCat() - Flyable");
                return 2;
            else
                A:DebugMessage("SetMountCat() - Aquatic");
                return 4;
            end
        end
    elseif ( IsFlyableArea() ) then -- Flyable mount
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
    local _, name, spellId;

    for i=1,GetNumCompanions("MOUNT") do
        _, name, spellId = GetCompanionInfo("MOUNT", i);

        if ( spellId == id ) then
            A:DebugMessage("Summon mount: "..name);
            CallCompanion("MOUNT", i);
            return;
        end
    end
end

--- If mounted dismount
-- If not choose a random from databases
-- @param cat Mount category set by A:SetMountCat()
function A:RandomMount(cat)
    A:Initialize();

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

    local id;

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
    elseif ( cat == 1 and not A.db.profile.noHybridWhenGround or cat == 2 ) then -- ground, want hybrid when ground - fly
        if ( A.db.profile.forceOne.mount[cat] and A.db.profile.forceOne.mount[3] ) then -- Got forced ground/fly and hybrid
            if ( math.random(100) > 50 ) then -- hybrid
                A:DebugMessage(("RandomMount() - With hybrid - Got forced - Got hybrid - Rand hybrid - %i"):format(cat));
                id = A.db.profile.forceOne.mount[3];
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
        elseif ( #A.db.profile.favoriteMounts[cat] > 0 and #A.db.profile.favoriteMounts[3] > 0 ) then -- got ground/fly and hybrid fav
            if ( math.random(100) > 50 ) then -- hybrid
                A:DebugMessage(("RandomMount() - With hybrid - Got fav - Got hybrid - Rand hybrid - %i"):format(cat));
                id = math.random(#A.db.profile.favoriteMounts[3]);
                id = A.db.profile.favoriteMounts[3][id];
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
        -- No fav checking global
        elseif ( #A.pamTable.mountsIds[cat] > 0 and #A.pamTable.mountsIds[3] > 0 ) then -- got ground/fly & hybrid
            if ( math.random(100) > 50 ) then -- hybrid
                A:DebugMessage(("RandomMount() - With hybrid - Got global - Got hybrid - Rand hybrid - %i"):format(cat));
                id = math.random(#A.pamTable.mountsIds[3]);
                id = A.pamTable.mountsIds[3][id];
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
        else
            A.isSummoningMount = nil;
            return;
        end
    end

    A:SummonMountBySpellId(id);
end
