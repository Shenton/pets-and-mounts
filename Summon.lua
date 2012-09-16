-- ********************************************************************************
-- Broker Pets & Mounts
-- Data Broker display for easy acces to pets and mounts.
-- By: Shenton
--
-- Summon.lua
-- ********************************************************************************

local A = _G["BrokerPAMGlobal"];
local L = A.L;

-- Lua globals
local mrandom = math.random;

-- ********************************************************************************
-- Functions
-- ********************************************************************************

function A:RandomPet()
    local id;

    if ( #A.db.profile.favoritePets > 0 ) then
        id = mrandom(#A.db.profile.favoritePets);
        id = A.db.profile.favoritePets[id];
    elseif ( #A.pamTable.petsIds > 0 ) then
        id = mrandom(#A.pamTable.petsIds);
        id = A.pamTable.petsIds[id];
    else
        return;
    end

    if ( C_PetJournal.GetSummonedPetID() and C_PetJournal.GetSummonedPetID() == id ) then
        A:RandomPet();
        return;
    end

    if ( C_PetJournal.PetIsSummonable(id) ) then C_PetJournal.SummonPetByID(id); end
end

function A:AutoPet()
    local currentPet = C_PetJournal.GetSummonedPetID();

    -- Got a pet, option is set to not have a pet when stealthed
    if ( currentPet and A.db.profile.notWhenStealthed and A:IsStealthed() ) then
        C_PetJournal.SummonPetByID(currentPet);
        return;
    end

    if ( not A.db.profile.autoPet -- Auto pet is disabled
    or A:IsStealthed() -- You don't want a pet to summon while stealthed, nether, or you hate your e-life.
    or UnitCastingInfo("player") -- Not when casting
    or UnitChannelInfo("player") -- Not when channeling
    or A.noAutoPet -- Combat, reviving, fly path end, etc, delay.
    or IsMounted() -- Not when mounted.
    or IsFalling() -- Not when falling.
    or UnitOnTaxi("player") ) then return; end -- Not on a fly path.

    -- Got a pet, option is set to not summon when having a pet
    if ( tContains(A.db.profile.favoritePets, currentPet) or (currentPet and A.db.profile.alreadyGotPet) ) then
        return;
    end

    -- Summon a random pet 
    A:RandomPet();
end

function A:SetMountCat()
    -- [1] = {}, -- Ground
    -- [2] = {}, -- Fly
    -- [3] = {}, -- Hybrid (ground & fly)
    -- [4] = {}, -- Aquatic
    -- [5] = {}, -- with passengers
    if ( IsSwimming() ) then -- Aquatic mount
        if ( GetMirrorTimerInfo(2) == "BREATH" ) then -- We are under water
            return 4;
        else -- We are at the water surface
            if ( IsFlyableArea() ) then
                return 2;
            else
                return 4;
            end
        end
    elseif ( IsFlyableArea() ) then -- Flyable mount
        return 2;
    else -- Ground mount
        return 1;
    end

    return nil;
end

function A:RandomMount(cat)
    if ( IsMounted() and ((IsFlying() and A.db.profile.dismountFlying) or not IsFlying()) ) then
        Dismount();

        return;
    end

    if ( UnitCastingInfo("player") -- Not when casting
    or IsFalling() -- Not when falling.
    or UnitOnTaxi("player") ) then return; end -- Not on a fly path.

    local id;

    if ( not cat ) then cat = A:SetMountCat(); end

    if ( (cat == 1 and A.db.profile.noHybridWhenGround) or cat == 4 or cat == 5 ) then -- ground, do not want hybrid when ground - aqua - passenger
        if ( #A.db.profile.favoriteMounts[cat] > 0 ) then -- got fav
            id = mrandom(#A.db.profile.favoriteMounts[cat]);
            id = A.db.profile.favoriteMounts[cat][id];
        elseif ( #A.pamTable.mountsIds[cat] > 0 ) then -- got global
            id = mrandom(#A.pamTable.mountsIds[cat]);
            id = A.pamTable.mountsIds[cat][id];
        else
            A.isSummoningMount = nil;
            return;
        end
    elseif ( cat == 1 and not A.db.profile.noHybridWhenGround or cat == 2 ) then -- ground, want hybrid when ground - fly
        if ( #A.db.profile.favoriteMounts[cat] > 0 and #A.db.profile.favoriteMounts[3] > 0 ) then -- got ground/fly and hybrid fav
            if ( mrandom(100) > 50 ) then -- hybrid
                id = mrandom(#A.db.profile.favoriteMounts[3]);
                id = A.db.profile.favoriteMounts[3][id];
            else -- ground/fly
                id = mrandom(#A.db.profile.favoriteMounts[cat]);
                id = A.db.profile.favoriteMounts[cat][id];
            end
        elseif ( #A.db.profile.favoriteMounts[cat] > 0 ) then -- got fav
            id = mrandom(#A.db.profile.favoriteMounts[cat]);
            id = A.db.profile.favoriteMounts[cat][id];
        elseif ( #A.db.profile.favoriteMounts[3] > 0 ) then -- got hybrid fav
            id = mrandom(#A.db.profile.favoriteMounts[3]);
            id = A.db.profile.favoriteMounts[3][id];
        -- No fav checking global
        elseif ( #A.pamTable.mountsIds[cat] > 0 and #A.pamTable.mountsIds[3] > 0 ) then -- got ground/fly & hybrid
            if ( mrandom(100) > 50 ) then -- hybrid
                id = mrandom(#A.pamTable.mountsIds[3]);
                id = A.pamTable.mountsIds[3][id];
            else -- ground/fly
                id = mrandom(#A.pamTable.mountsIds[cat]);
                id = A.pamTable.mountsIds[cat][id];
            end
        elseif ( #A.pamTable.mountsIds[cat] > 0 ) then -- got ground/fly
            id = mrandom(#A.pamTable.mountsIds[cat]);
            id = A.pamTable.mountsIds[cat][id];
        elseif ( #A.pamTable.mountsIds[3] > 0 ) then -- got hybrid
            id = mrandom(#A.pamTable.mountsIds[3]);
            id = A.pamTable.mountsIds[3][id];
        else
            A.isSummoningMount = nil;
            return;
        end
    end

    if ( A.db.profile.debug ) then
        local _,n = GetCompanionInfo("MOUNT", id);
        A:DebugMessage(n)
    end

    CallCompanion("MOUNT", id);
end
