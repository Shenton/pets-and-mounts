--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Buttons.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- Globals to locals
local pairs = pairs;
local _G = _G;
local type = type;

-- GLOBALS: BINDING_HEADER_PETSANDMOUNTS, InCombatLockdown, GetSpellInfo, IsFlyableArea, IsSpellKnown
-- GLOBALS: IsShiftKeyDown, IsControlKeyDown, GetItemCount, GetItemInfo, UnitBuff, UIDropDownMenu_SetAnchor
-- GLOBALS: ToggleDropDownMenu, GameTooltip, PetsAndMountsSecureButtonMounts, PetsAndMountsSecureButtonPets
-- GLOBALS: GetScreenWidth

--[[-------------------------------------------------------------------------------
    Bindings
-------------------------------------------------------------------------------]]--

-- Bindings list
A.bindingsTable =
{
    {
        name = "CLICK PetsAndMountsSecureButtonPets:LeftButton",
        localized = L["Random companion"],
        configDesc = L["Bind a key to summon a random companion."],
    },
    {
        name = "CLICK PetsAndMountsSecureButtonMounts:LeftButton",
        localized = L["Random mount"],
        configDesc = L["Bind a key to summon a random mount."],
    },
    {
        name = "CLICK PetsAndMountsSecureButtonPassengers:LeftButton",
        localized = L["Random passengers mount"],
        configDesc = L["Bind a key to summon a random mount."],
    },
    {
        name = "CLICK PetsAndMountsSecureButtonFlying:LeftButton",
        localized = L["Random flying mount"],
        configDesc = L["Bind a key to summon a random mount."],
    },
    {
        name = "CLICK PetsAndMountsSecureButtonGround:LeftButton",
        localized = L["Random ground mount"],
        configDesc = L["Bind a key to summon a random mount."],
    },
    {
        name = "CLICK PetsAndMountsSecureButtonAquatic:LeftButton",
        localized = L["Random aquatic mount"],
        configDesc = L["Bind a key to summon a random mount."],
    },
    {
        name = "CLICK PetsAndMountsSecureButtonSurface:LeftButton",
        localized = L["Random surface mount"],
        configDesc = L["Bind a key to summon a random mount."],
    },
    {
        name = "CLICK PetsAndMountsSecureButtonRepair:LeftButton",
        localized = L["Random repair mount"],
        configDesc = L["Bind a key to summon a random mount."],
    },
    {
        name = "CLICK PetsAndMountsSecureButtonHybrid:LeftButton",
        localized = L["Random hybrid mount"],
        configDesc = L["Bind a key to summon a random mount."],
    },
};

-- Binding UI localization
BINDING_HEADER_PETSANDMOUNTS = L["Pets & Mounts"];

do
    for k,v in ipairs(A.bindingsTable) do
        _G["BINDING_NAME_"..v.name] = v.localized;
    end
end

--[[-------------------------------------------------------------------------------
    Simple buttons macros
-------------------------------------------------------------------------------]]--

--- Specific buttons macro
local buttonsMacro =
{
    [1] = -- With form cancel
    {
        ["PetsAndMountsSecureButtonPets"] = "/run PetsAndMountsGlobal:RandomPet()",
        ["PetsAndMountsSecureButtonPassengers"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(5)",
        ["PetsAndMountsSecureButtonFlying"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(2)",
        ["PetsAndMountsSecureButtonGround"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(1)",
        ["PetsAndMountsSecureButtonAquatic"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(4)",
        ["PetsAndMountsSecureButtonSurface"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(6)",
        ["PetsAndMountsSecureButtonRepair"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(7)",
        ["PetsAndMountsSecureButtonHybrid"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(3)",
    },
    [2] = -- Without
    {
        ["PetsAndMountsSecureButtonPets"] = "/run PetsAndMountsGlobal:RandomPet()",
        ["PetsAndMountsSecureButtonPassengers"] = "/run PetsAndMountsGlobal:RandomMount(5)",
        ["PetsAndMountsSecureButtonFlying"] = "/run PetsAndMountsGlobal:RandomMount(2)",
        ["PetsAndMountsSecureButtonGround"] = "/run PetsAndMountsGlobal:RandomMount(1)",
        ["PetsAndMountsSecureButtonAquatic"] = "/run PetsAndMountsGlobal:RandomMount(4)",
        ["PetsAndMountsSecureButtonSurface"] = "/run PetsAndMountsGlobal:RandomMount(6)",
        ["PetsAndMountsSecureButtonRepair"] = "/run PetsAndMountsGlobal:RandomMount(7)",
        ["PetsAndMountsSecureButtonHybrid"] = "/run PetsAndMountsGlobal:RandomMount(3)",
    },
};

function A:SetButtonsMacro()
    if ( InCombatLockdown() ) then
        A.delayedButtonsMacro = 1;
    else
        if ( A.playerClass == "DRUID" or A.playerClass == "SHAMAN" ) then
            for k,v in pairs(buttonsMacro[1]) do
                _G[k]:SetAttribute("type", "macro");
                _G[k]:SetAttribute("macrotext", v);
            end
        else
            for k,v in pairs(buttonsMacro[2]) do
                _G[k]:SetAttribute("type", "macro");
                _G[k]:SetAttribute("macrotext", v);
            end
        end
    end
end

--[[-------------------------------------------------------------------------------
    Mounts smart button pre & post clicks
-------------------------------------------------------------------------------]]--

-- Global macro dismount string
function A:SetMacroDismountString()
    if ( A.db.profile.vehicleExit ) then
        A.macroDismountString = "/dismount [mounted]\n/leavevehicle [vehicleui]";
    else
        A.macroDismountString = "/dismount [mounted]";
    end
end

--- Check if we got at least one mount for the given cat, check all tables after restriction
function A:GotMountAllTable(cat)
    if ( A.db.profile.forceOne.mount[cat]
    or A.db.profile.mountByMapID[cat][A.currentMapID]
    or A.db.profile.areaMounts and A.uniqueAreaMounts[cat][A.currentMapID]
    or A:GotRandomMount(A.db.profile.favoriteMounts[cat])
    or A:GotRandomMount(A.pamTable.mountsIds[cat]) ) then
        return 1;
    end

    return nil;
end

--- Set the spells names for the player's class
-- This will check if the spell name is not nil
-- it is required as for some ppl they are not available on login
-- latency || bad config + cache deleting = no names from server || client
A.classesSpellsTable =
{
    DEATHKNIGHT =
    {
        deathKnightPathOfFrost = 3714, -- lvl 66
        deathKnightDeathAdvance = 96268, -- lvl 58 - tier 3 row 1 - id 7
        deathKnightUnholyPresence = 48265, -- lvl 64
    },
    DRUID =
    {
        druidTravelForm = 783, -- lvl 16
        druidAquaticForm = 1066, -- lvl 18
        druidFlightForm = 33943, -- lvl 58
        druidSwiftFlightForm = 40120, -- lvl 70
    },
    HUNTER =
    {
        hunterAspectCheetah = 5118, -- lvl 16
        hunterAspectPack = 13159, -- lvl 56
    },
    MAGE =
    {
        mageSlowFall = 130, -- lvl 32
        mageBlink = 1953, -- lvl 7
        mageBlazingSpeed = 108843, -- lvl 15 - tier 1 row 2 - id 2
    },
    MONK =
    {
        monkRoll = 109132, -- lvl 5
        monkFlyingSerpentKick = 101545, -- lvl 18
        monkZenFlight = 125883, -- lvl 25 - need glyph 125893
    },
    PALADIN =
    {
        paladinSpeedOfLight = 85499, -- lvl 15 - tier 1 row 1 - id 1
    },
    PRIEST =
    {
        priestPowerWordShield = 17, -- Body and Soul - lvl 30 - tier 2 row 1 - id 4
        priestAngelicFeather = 121536, -- lvl 30 - tier 2 row 2 - id 5
    },
    ROGUE =
    {
        rogueSprint = 2983, -- lvl 26
    },
    SHAMAN =
    {
        shamanGhostWolf = 2645, -- lvl 16
        shamanWaterWalking = 546, -- lvl 24
    },
    WARLOCK =
    {
        warlockDemonicCircle = 48020, -- lvl 76
        warlockBurningRush = 111400, -- lvl 60 - id 11
    },
    WARRIOR =
    {
        warriorCharge = 100, -- lvl 3
        warriorIntervene = 3411, -- lvl 72
        warriorHeroicLeap = 6544, -- lvl 85
    },
};
function A:SetClassSpells()
    if ( A.classesSpellsTable[A.playerClass] ) then
        for k,v in pairs(A.classesSpellsTable[A.playerClass]) do
            A[k] = GetSpellInfo(v);

            if ( not A[k] ) then
                A:ScheduleTimer("SetClassSpells", 0.5);
                return;
            end
        end
    end

    A.classSpellsOK = 1;
    A:SetPostClickMacro();
end

--- Death Knight preclick macro
-- @param button The button object
-- For DK we handle Death's Advance and Unholy Presence when moving
function A:SetDeathKnightPreClickMacro(button)
    if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        local selected = select(5, GetTalentInfo(7));

        if ( A.db.profile.deathKnightPreferUnholy and A.playerLevel >= 64 ) then
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.deathKnightUnholyPresence));
        elseif ( A.playerLevel >= 58 and selected ) then
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.deathKnightDeathAdvance));
        else
            button:SetAttribute("macrotext", "/pammount");
        end
    else
        button:SetAttribute("macrotext", "/pammount");
    end
end

--- Druid pre click macro
-- @param button The button object
-- For Druids we handle flight forms
function A:SetDruidPreClickMacro(button)
    if ( not IsFlyableArea() and not IsMounted() and GetUnitSpeed("player") > 0 and A.playerLevel >= 16 ) then
        button:SetAttribute("macrotext", ("%s\n/cast [swimming] %s; %s"):format(A.macroDismountString, A.druidAquaticForm, A.druidTravelForm));
    elseif ( IsFlyableArea() and IsSpellKnown(40120) ) then
        button:SetAttribute("macrotext", ("%s\n/cast [swimming] %s; %s"):format(A.macroDismountString, A.druidAquaticForm, A.druidSwiftFlightForm));
    elseif ( A.playerLevel >= 58 and A:IsFlyable() ) then
        button:SetAttribute("macrotext", ("%s\n/cast [swimming] %s; %s"):format(A.macroDismountString, A.druidAquaticForm, A.druidFlightForm));
    elseif ( A.playerLevel >= 20 and A:CanRide() ) then
        button:SetAttribute("macrotext", ("/cancelform\n/cast [swimming] %s\n/stopmacro [swimming]\n/pammount"):format(A.druidAquaticForm));
    elseif ( A.playerLevel >= 18 ) then
        button:SetAttribute("macrotext", ("%s\n/cast [swimming] %s; %s"):format(A.macroDismountString, A.druidAquaticForm, A.druidTravelForm));
    elseif ( A.playerLevel >= 16 ) then
        button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.druidTravelForm));
    else
        button:SetAttribute("macrotext", A.macroDismountString);
    end
end

--- Hunter pre click macro
-- @param button The button object
-- For Hunters we handle speed aspects when moving
function A:SetHunterPreClickMacro(button)
    local spell;

    if ( A.db.profile.hunterPreferPack and A.playerLevel >= 56 ) then
        spell = A.hunterAspectPack;
    elseif ( A.playerLevel >= 16 ) then
        spell = A.hunterAspectCheetah;
    end

    if ( not spell ) then
        button:SetAttribute("macrotext", A.macroDismountString);
    elseif ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        if ( A.db.profile.hunterWantModifier ) then
            button:SetAttribute("macrotext", ("%s\n/cast [nomod] !%s\n/cancelaura [mod:%s] %s"):format(A.macroDismountString, spell, A.db.profile.hunterModifier, spell));
        else
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, spell));
        end
    else
        if ( A.db.profile.hunterWantModifier ) then
            button:SetAttribute("macrotext", ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n/pammount"):format(A.db.profile.hunterModifier, spell, A.db.profile.hunterModifier));
        else
            button:SetAttribute("macrotext", ("/cancelaura %s\n/pammount"):format(spell));
        end
    end
end

--- Mage pre click macro
-- @param button The button object
-- For Mages we handle Blink when moving and Slow Fall when falling
function A:SetMagePreClickMacro(button)
    if ( A.db.profile.mageSlowFall and IsFalling() and A.playerLevel >= 32 ) then
        button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.mageSlowFall));
    elseif ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        local selected = select(5, GetTalentInfo(2));

        if ( (A.db.profile.magePreferBlink or not selected) and A.playerLevel >= 7 ) then
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.mageBlink));
        elseif ( selected and A.playerLevel >= 15 ) then
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.mageBlazingSpeed));
        else
            button:SetAttribute("macrotext", "/pammount");
        end
    else
        button:SetAttribute("macrotext", "/pammount");
    end
end

--- Monk pre click macro
-- @param button The button object
-- For monks we handle Roll and Flying Serpent Kick
function A:SetMonkPreClickMacro(button)
    local glyphed;

    for i=1,NUM_GLYPH_SLOTS do
        local enabled, _, _, spellID = GetGlyphSocketInfo(i);

        if ( enabled and spellID == 125893 ) then
            glyphed = 1;
        end
    end

    if ( IsFalling() and glyphed ) then
        button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.monkZenFlight));
    elseif ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        if ( A.db.profile.monkPreferSerpentKick and A.playerLevel >= 18 ) then
            button:SetAttribute("macrotext", ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n%s\n/cast %s")
            :format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier, A.macroDismountString, A.monkFlyingSerpentKick));
        elseif ( A.playerLevel >= 5 ) then
            button:SetAttribute("macrotext", ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n%s\n/cast %s")
            :format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier, A.macroDismountString, A.monkRoll));
        else
            button:SetAttribute("macrotext", ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n/pammount"):format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier));
        end
    else
        button:SetAttribute("macrotext", ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n/pammount"):format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier));
    end
end

--- Paladin pre click macro
-- @param button The button object
-- For Paladins we handle Speed of Light when moving
function A:SetPaladinPreClickMacro(button)
    if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        local selected = select(5, GetTalentInfo(1));

        if ( A.playerLevel >= 15 and selected ) then
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.paladinSpeedOfLight));
        else
            button:SetAttribute("macrotext", "/pammount");
        end
    else
        button:SetAttribute("macrotext", "/pammount");
    end
end

--- Priest pre click macro
-- @param button The button object
-- For Priests we handle Body and Soul and Angelic Feather when moving
function A:SetPriestPreClickMacro(button)
    if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        local isFree, talent = GetTalentRowSelectionInfo(2);

        if ( A.playerLevel >= 30 and talent == 4 ) then
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.priestPowerWordShield));
        elseif ( A.playerLevel >= 30 and talent == 5 ) then
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.priestAngelicFeather));
        else
            button:SetAttribute("macrotext", "/pammount");
        end
    else
        button:SetAttribute("macrotext", "/pammount");
    end
end

--- Rogue pre click macro
-- @param button The button object
-- For Rogues we handle Sprint when moving
function A:SetRoguePreClickMacro(button)
    if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        if ( A.playerLevel >= 26 ) then
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.rogueSprint));
        else
            button:SetAttribute("macrotext", "/pammount");
        end
    else
        button:SetAttribute("macrotext", "/pammount");
    end
end

--- Shaman pre click macro
-- @param button The button object
-- For Shamans we handle Ghost Wolf when moving
function A:SetShamanPreClickMacro(button)
    if ( not IsMounted() and GetUnitSpeed("player") > 0 and A.playerLevel >= 16 ) then
        button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.shamanGhostWolf));
    else
        button:SetAttribute("macrotext", "/cancelform\n/pammount");
    end
end

--- Warlock pre click macro
-- @param button The button object
-- For Warlocks we handle teleport and Burning Rush
function A:SetWarlockPreClickMacro(button)
    local selected = select(5, GetTalentInfo(11));

    if ( (not selected or A.db.profile.warlockPreferTeleport) and A.playerLevel >= 76 ) then
        if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
            button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.warlockDemonicCircle));
        else
            button:SetAttribute("macrotext", "/pammount");
        end
    elseif ( selected ) then
        if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
            if ( A.db.profile.warlockWantModifier ) then
                button:SetAttribute("macrotext", ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n%s\n/cast !%s")
                :format(A.db.profile.warlockModifier, A.warlockBurningRush, A.db.profile.warlockModifier, A.macroDismountString, A.warlockBurningRush));
            else
                button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.warlockBurningRush));
            end
        else
            if ( A.db.profile.warlockWantModifier ) then
                button:SetAttribute("macrotext", ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n/pammount"):format(A.db.profile.warlockModifier, A.warlockBurningRush, A.db.profile.warlockModifier));
            else
                button:SetAttribute("macrotext", ("/cancelaura %s\n/pammount"):format(A.warlockBurningRush));
            end
        end
    else
        button:SetAttribute("macrotext", "/pammount");
    end
end

--- Warrior pre click macro
-- @param button The button object
-- For Warriors we handle Heroic Leap, Charge and Intervene
function A:SetWarriorPreClickMacro(button)
    if ( not IsMounted() and GetUnitSpeed("player") > 0 and A.playerLevel >= 76 ) then
        button:SetAttribute("macrotext", ("%s\n/cast %s"):format(A.macroDismountString, A.warriorHeroicLeap));
    else
        button:SetAttribute("macrotext", "/pammount");
    end
end

--- PreClick callback
function A:PreClickMount(button, clickedBy)
    if ( InCombatLockdown() ) then return; end

    if ( clickedBy == "LeftButton" ) then
        if ( IsShiftKeyDown() ) then
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", nil);
            A:RandomMount(A.db.profile.mountButtonshiftClickCat);
        elseif ( IsControlKeyDown() ) then
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", nil);
            A:ToggleButtonLock(button);
        else
            -- Specials mounts
            if ( A.db.profile.shimmeringMoonstone and GetItemCount(101675, nil, nil) > 0 and (A:IsSwimming() == 2 or not A:IsSwimming())
            and not A:IsFlyable() and not (A.db.profile.vehicleExit and A:IsPlayerInVehicle()) ) then -- 37011 - Shimmering Moonstone from Darkmoon fair (Moonfang drop)
                if ( not A.shimmeringMoonstoneName ) then A.shimmeringMoonstoneName = GetItemInfo(101675); end

                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", ("/use %s"):format(A.shimmeringMoonstoneName or "Shimmering Moonstone"));
            elseif ( A.db.profile.magicBroom and GetItemCount(37011, nil, nil) > 0 and (A:IsSwimming() == 2 or not A:IsSwimming()) and not (A.db.profile.vehicleExit and A:IsPlayerInVehicle()) ) then -- 37011 - Magic Broom from Hallow's End
                if ( not A.magicBroomName ) then A.magicBroomName = GetItemInfo(37011); end

                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", ("/use %s"):format(A.magicBroomName or "Magic Broom"));
            -- ATM spells names are required
            elseif ( A.classSpellsOK ) then
                -- Water walking spells
                if ( A.db.profile.surfaceMount and ((A.playerClass == "DEATHKNIGHT" and A.playerLevel >= 66) or (A.playerClass == "SHAMAN" and A.playerLevel >= 24)) and A:IsSwimming() == 2 ) then
                    if ( A.db.profile.preferSurfaceSpell or (not A.db.profile.preferSurfaceSpell and not A:GotMountAllTable(6)) ) then
                        if ( A.playerClass == "DEATHKNIGHT" and not UnitBuff("player", A.deathKnightPathOfFrost) ) then
                            button:SetAttribute("type", "macro");
                            button:SetAttribute("macrotext", "/cast !"..A.deathKnightPathOfFrost);
                        elseif ( A.playerClass == "SHAMAN" ) then
                            if ( UnitBuff("player", A.shamanWaterWalking) ) then
                                button:SetAttribute("type", "macro");
                                button:SetAttribute("macrotext", "/cancelform\n/pammount");
                            else
                                button:SetAttribute("type", "macro");
                                button:SetAttribute("macrotext", "/cast "..A.shamanWaterWalking);
                            end
                        else
                            button:SetAttribute("type", "macro");
                            button:SetAttribute("macrotext", "/pammount");
                        end
                    else
                        button:SetAttribute("type", "macro");
                        button:SetAttribute("macrotext", "/pammount");
                    end
                -- Classes
                elseif ( A.db.profile.classesMacrosEnabled ) then
                    -- Death Knight
                    if ( A.playerClass == "DEATHKNIGHT" ) then
                        button:SetAttribute("type", "macro");
                        A:SetDeathKnightPreClickMacro(button);
                    -- Druid
                    elseif ( A.playerClass == "DRUID" ) then
                        button:SetAttribute("type", "macro");
                        A:SetDruidPreClickMacro(button);
                    -- Hunter
                    elseif ( A.playerClass == "HUNTER" ) then
                        button:SetAttribute("type", "macro");
                        A:SetHunterPreClickMacro(button);
                    -- Mage
                    elseif ( A.playerClass == "MAGE" ) then
                        button:SetAttribute("type", "macro");
                        A:SetMagePreClickMacro(button);
                    -- Monk
                    elseif ( A.playerClass == "MONK" ) then
                        button:SetAttribute("type", "macro");
                        A:SetMonkPreClickMacro(button);
                    -- Paladin
                    elseif ( A.playerClass == "PALADIN" ) then
                        button:SetAttribute("type", "macro");
                        A:SetPaladinPreClickMacro(button);
                    -- Priest
                    elseif ( A.playerClass == "PRIEST" ) then
                        button:SetAttribute("type", "macro");
                        A:SetPriestPreClickMacro(button);
                    -- Rogue
                    elseif ( A.playerClass == "ROGUE" ) then
                        button:SetAttribute("type", "macro");
                        A:SetRoguePreClickMacro(button);
                    -- Shaman
                    elseif ( A.playerClass == "SHAMAN" ) then
                        button:SetAttribute("type", "macro");
                        A:SetShamanPreClickMacro(button);
                    -- Warlock
                    elseif ( A.playerClass == "WARLOCK" ) then
                        button:SetAttribute("type", "macro");
                        A:SetWarlockPreClickMacro(button);
                    -- Warrior
                    elseif ( A.playerClass == "WARRIOR" ) then
                        button:SetAttribute("type", "macro");
                        A:SetWarriorPreClickMacro(button);
                    -- Just in case
                    else
                        button:SetAttribute("type", "macro");
                        button:SetAttribute("macrotext", "/pammount");
                    end
                -- Global macro
                else
                    button:SetAttribute("type", "macro");
                    button:SetAttribute("macrotext", "/pammount");
                end
            else
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", "/pammount");
            end
        end
    elseif ( clickedBy == "RightButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);

        local point, relativePoint = A:GetMenuButtonAnchor();

        UIDropDownMenu_SetAnchor(A.menuFrame, 0, 0, point, button, relativePoint);
        ToggleDropDownMenu(1, nil, A.menuFrame, button);
        GameTooltip:Hide();
    elseif ( clickedBy == "MiddleButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);
        A:OpenConfigPanel();
    end
end

-- Post click macro
function A:SetPostClickMacro()
    if ( A.classSpellsOK ) then
        -- Death Knight
        if ( A.playerClass == "DEATHKNIGHT" ) then
            local selected = select(5, GetTalentInfo(7));

            if ( A.db.profile.deathKnightPreferUnholy and A.playerLevel >= 64 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.deathKnightUnholyPresence);
            elseif ( A.playerLevel >= 58 and selected ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.deathKnightDeathAdvance);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Druid
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "DRUID" ) then
            if ( A.playerLevel >= 18 ) then
                A.postClickMacro = ("%s\n/cast [swimming] %s;[nomounted] %s"):format(A.macroDismountString, A.druidAquaticForm, A.druidTravelForm);
            elseif ( A.playerLevel >= 16 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.druidTravelForm);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Hunter
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "HUNTER" ) then
            local spell;

            if ( A.db.profile.hunterPreferPack and A.playerLevel >= 56 ) then
                spell = A.hunterAspectPack;
            elseif ( A.playerLevel >= 16 ) then
                spell = A.hunterAspectCheetah;
            end

            if ( not spell ) then
                A.postClickMacro = A.macroDismountString;
            elseif ( A.db.profile.hunterWantModifier ) then
                A.postClickMacro = ("%s\n/cast [nomounted,novehicleui,nomod] !%s\n/cancelaura [nomounted,novehicleui,mod:%s] %s"):format(A.macroDismountString, spell, A.db.profile.hunterModifier, spell);
            else
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, spell);
            end
        -- Mage
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "MAGE" ) then
            if ( A.db.profile.mageForceSlowFall ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.mageSlowFall);
            else
                local selected = select(5, GetTalentInfo(2));

                if ( (A.db.profile.magePreferBlink or not selected) and A.playerLevel >= 7 ) then
                    A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.mageBlink);
                elseif ( selected and A.playerLevel >= 15 ) then
                    A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.mageBlazingSpeed);
                else
                    A.postClickMacro = A.macroDismountString;
                end
            end
        -- Monk
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "MONK" ) then
            if ( A.db.profile.monkPreferSerpentKick and A.playerLevel >= 18 ) then
                A.postClickMacro = ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n%s\n/cast [nomounted] %s")
                :format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier, A.macroDismountString, A.monkFlyingSerpentKick);
            elseif ( A.playerLevel >= 5 ) then
                A.postClickMacro = ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n%s\n/cast [nomounted] %s")
                :format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier, A.macroDismountString, A.monkRoll);
            else
                A.postClickMacro = ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n%s")
                :format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier, A.macroDismountString);
            end
        -- Paladin
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "PALADIN" ) then
            local selected = select(5, GetTalentInfo(1));

            if ( A.playerLevel >= 15 and selected ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.paladinSpeedOfLight);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Priest
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "PRIEST" ) then
            local isFree, talent = GetTalentRowSelectionInfo(2);

            if ( A.playerLevel >= 30 and talent == 4 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.priestPowerWordShield);
            elseif ( A.playerLevel >= 30 and talent == 5 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.priestAngelicFeather);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Rogue
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "ROGUE" ) then
            if ( A.playerLevel >= 26 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.rogueSprint);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Shaman
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "SHAMAN" ) then
            if ( A.playerLevel >= 16 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.shamanGhostWolf);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Warlock
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "WARLOCK" ) then
            local selected = select(5, GetTalentInfo(11));

            if ( (not selected or A.db.profile.warlockPreferTeleport) and A.playerLevel >= 76 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.warlockDemonicCircle);
            elseif ( selected ) then
                if ( A.db.profile.warlockWantModifier ) then
                    A.postClickMacro = ("%s\n/cast [nomounted,novehicleui,nomod] !%s\n/cancelaura [nomounted,novehicleui,mod:%s] %s")
                    :format(A.macroDismountString, A.warlockBurningRush, A.db.profile.warlockModifier, A.warlockBurningRush);
                else
                    A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.warlockBurningRush);
                end
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Warrior
        elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "WARRIOR" ) then
            if ( A.db.profile.warriorForceHeroicLeap and A.playerLevel >= 76 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.warriorHeroicLeap);
            else
                if ( A.playerLevel >= 72 ) then
                    A.postClickMacro = ("%s\n/cast [nomounted,@target,help] %s;[nomounted,@target,harm] %s"):format(A.macroDismountString, A.warriorIntervene, A.warriorCharge);
                elseif ( A.playerLevel >= 3 ) then
                    A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.warriorCharge);
                else
                    A.postClickMacro = A.macroDismountString;
                end
            end
        else
            A.postClickMacro = A.macroDismountString;
        end
    else
        A.postClickMacro = A.macroDismountString;
    end

    -- Fire the Post Click callback to update the button macro
    A:PostClickMount(PetsAndMountsSecureButtonMounts);
end

--- PostClick callback
function A:PostClickMount(button, clickedBy)
    if ( InCombatLockdown() ) then return; end

    button:SetAttribute("type", "macro");
    button:SetAttribute("macrotext", A.postClickMacro);
end

--[[-------------------------------------------------------------------------------
    Pets button pre & post clicks
-------------------------------------------------------------------------------]]--

--- PreClick callback
function A:PreClickPet(button, clickedBy)
    if ( InCombatLockdown() ) then return; end

    if ( clickedBy == "LeftButton" ) then
        if ( IsShiftKeyDown() ) then
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", nil);
            A:RevokePet(1);
        elseif ( IsControlKeyDown() ) then
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", nil);
            A:ToggleButtonLock(button);
        else
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", "/pampet");
        end
    elseif ( clickedBy == "RightButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);

        local point, relativePoint = A:GetMenuButtonAnchor();

        UIDropDownMenu_SetAnchor(A.menuFrame, 0, 0, point, button, relativePoint);
        ToggleDropDownMenu(1, nil, A.menuFrame, button);

        GameTooltip:Hide();
    elseif ( clickedBy == "MiddleButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);
        A:OpenConfigPanel();
    end
end

--[[-------------------------------------------------------------------------------
    Pets and Mounts clickable buttons methods
-------------------------------------------------------------------------------]]--

--- Set button position
function A:SetButtonPos(button)
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    _G[button]:ClearAllPoints();
    _G[button]:SetPoint(A.db.profile[button].anchor.point, A.db.profile[button].anchor.relativeTo, A.db.profile[button].anchor.relativePoint, A.db.profile[button].anchor.offX, A.db.profile[button].anchor.offY);
end

--- Lock button
function A:LockButton(button)
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    _G[button]:SetMovable(nil);
    _G[button]:SetScript("OnDragStart", nil);
    _G[button]:SetScript("OnDragStop", nil);
    A.db.profile[button].lock = 1;

    if ( A.AceConfigRegistry ) then
        A:NotifyChangeForAll();
    end
end

--- Unlock button, saving position
function A:UnlockButton(button)
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    if ( A.db.profile.dockButton and button == "PetsAndMountsSecureButtonPets" ) then return; end

    _G[button]:SetMovable(1);
    _G[button]:RegisterForDrag("LeftButton");
    _G[button]:SetScript("OnDragStart", _G[button].StartMoving);
    _G[button]:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();

        local point, relativeTo, relativePoint, offX, offY = self:GetPoint(1);

        A.db.profile[button].anchor.point = point;
        A.db.profile[button].anchor.relativeTo = relativeTo;
        A.db.profile[button].anchor.relativePoint = relativePoint;
        A.db.profile[button].anchor.offX = offX;
        A.db.profile[button].anchor.offY = offY;
    end);
    A.db.profile[button].lock = nil;

    if ( A.AceConfigRegistry ) then
        A:NotifyChangeForAll();
    end
end

--- Toggle lock button
function A:ToggleButtonLock(button)
    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    if ( _G[button]:IsMovable() ) then
        A:LockButton(button);
    else
        A:UnlockButton(button);
    end
end

--- Button hide/show toggle
function A:ToggleButtonHideShow(button)
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    if ( _G[button]:IsShown() ) then
        _G[button]:Hide();
        A.db.profile[button].hide = 1;
    else
        _G[button]:Show();
        A.db.profile[button].hide = nil;
    end

    if ( A.AceConfigRegistry ) then
        A:NotifyChangeForAll();
    end
end

--- Dock buttons together
function A:DockButton()
    A.db.profile.PetsAndMountsSecureButtonPets.anchor =
    {
        point = A.dockButtonsAnchors[A.db.profile.dockAnchor][1],
        relativeTo = "PetsAndMountsSecureButtonMounts",
        relativePoint = A.dockButtonsAnchors[A.db.profile.dockAnchor][2],
        offX = A.dockButtonsAnchors[A.db.profile.dockAnchor][3],
        offY = A.dockButtonsAnchors[A.db.profile.dockAnchor][4],
    };

    A:LockButton("PetsAndMountsSecureButtonPets")
    A:SetButtonPos("PetsAndMountsSecureButtonPets");
end

--- Dock buttons together
function A:UnDockButton()
    local point, relativeTo, relativePoint, offX, offY = PetsAndMountsSecureButtonMounts:GetPoint(1);

    offX = offX + 40

    A.db.profile.PetsAndMountsSecureButtonPets.anchor =
    {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        offX = offX,
        offY = offY,
    };

    A:SetButtonPos("PetsAndMountsSecureButtonPets");
end

--- Reset button
function A:ResetButton(button)
    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    local offX;

    if ( button == "PetsAndMountsSecureButtonPets" ) then
        offX = 20;
    elseif ( button == "PetsAndMountsSecureButtonMounts" ) then
        offX = -20
    else
        offX = 0;
    end

    A.db.profile[button] =
    {
        hide = nil,
        lock = nil,
        tooltip = 1,
        scale = 1,
        anchor =
        {
            point = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            offX = offX,
            offY = 0,
        },
    },

    A:SetButtons();
end

function A:SetButtonsIcons()
    if ( A.db.profile.petButtonIconCurrent and A.currentPetIcon ) then
        PetsAndMountsSecureButtonPets.icon:SetTexture(A.currentPetIcon);
    else
        PetsAndMountsSecureButtonPets.icon:SetTexture("Interface\\ICONS\\"..A.db.profile.petButtonIcon);
    end

    if ( A.db.profile.mountButtonIconCurrent and A.currentMountIcon ) then
        PetsAndMountsSecureButtonMounts.icon:SetTexture(A.currentMountIcon);
    else
        PetsAndMountsSecureButtonMounts.icon:SetTexture("Interface\\ICONS\\"..A.db.profile.mountButtonIcon);
    end
end

--- Set buttons on login
function A:SetButtons()
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    -- Position
    A:SetButtonPos("PetsAndMountsSecureButtonPets");
    A:SetButtonPos("PetsAndMountsSecureButtonMounts");

    -- Scale
    PetsAndMountsSecureButtonPets:SetScale(A.db.profile.PetsAndMountsSecureButtonPets.scale);
    PetsAndMountsSecureButtonMounts:SetScale(A.db.profile.PetsAndMountsSecureButtonMounts.scale);

    -- Visibility
    if ( A.db.profile.PetsAndMountsSecureButtonPets.hide ) then
        PetsAndMountsSecureButtonPets:Hide();

        if (  A.db.profile.dockButton ) then
            A.db.profile.dockButton = nil;
            A:UnDockButton();
        end
    else
        PetsAndMountsSecureButtonPets:Show();
    end

    if ( A.db.profile.PetsAndMountsSecureButtonMounts.hide ) then
        PetsAndMountsSecureButtonMounts:Hide();

        if (  A.db.profile.dockButton ) then
            A.db.profile.dockButton = nil;
            A:UnDockButton();

            if ( not A.db.profile.PetsAndMountsSecureButtonMounts.lock and A.db.profile.PetsAndMountsSecureButtonPets.lock ) then
                A.db.profile.PetsAndMountsSecureButtonPets.lock = nil;
                A:SetButtons();
                return;
            end
        end
    else
        PetsAndMountsSecureButtonMounts:Show();
    end

    -- Movable
    if ( A.db.profile.PetsAndMountsSecureButtonPets.lock ) then
        A:LockButton("PetsAndMountsSecureButtonPets");
    else
        A:UnlockButton("PetsAndMountsSecureButtonPets");
    end

    if ( A.db.profile.PetsAndMountsSecureButtonMounts.lock ) then
        A:LockButton("PetsAndMountsSecureButtonMounts");
    else
        A:UnlockButton("PetsAndMountsSecureButtonMounts");
    end

    -- Icon
    

    -- Refresh config panel
    A:NotifyChangeForAll();
end

--[[-------------------------------------------------------------------------------
    Tooltips
-------------------------------------------------------------------------------]]--

--- Display button tooltip
function A:SetTooltip(frame)
    if ( not A.db.profile.PetsAndMountsSecureButtonPets.tooltip and frame:GetName() == "PetsAndMountsSecureButtonPets" ) then return; end
    if ( not A.db.profile.PetsAndMountsSecureButtonMounts.tooltip and frame:GetName() == "PetsAndMountsSecureButtonMounts" ) then return; end

    local currentSet;

    if ( frame:GetRight() >= ( GetScreenWidth() / 2 ) ) then
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT");
    else
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
    end

    GameTooltip:AddDoubleLine(A.color["WHITE"]..L["Pets & Mounts"], A.color["GREEN"].."v"..A.version);
    GameTooltip:AddLine(" ");

    if ( frame:GetName() == "PetsAndMountsSecureButtonPets" ) then
        currentSet = A:GetSetsInUse("PETS");

        if ( currentSet == L["None"] ) then
            currentSet = A.color["RED"]..currentSet;
        else
            currentSet = A.color["GREEN"]..currentSet;
        end

        GameTooltip:AddLine(L["Companions set in use: %s."]:format(currentSet));
        GameTooltip:AddLine(L["Auto summon companion is %s."]:format(A:IsAutoPetEnabled() and A.color["GREEN"]..L["On"] or A.color["RED"]..L["Off"]));
        GameTooltip:AddLine(L["Not when stealthed is %s."]:format(A:IsNotWhenStealthedEnabled() and A.color["GREEN"]..L["On"] or A.color["RED"]..L["Off"]));
        GameTooltip:AddLine(L["Forced companion: %s"]:format(A.db.profile.forceOne.pet and A.color["GREEN"]..A:GetPetNameByID(A.db.profile.forceOne.pet) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random companion.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Revoke current companion.\n|cFFC79C6EControl+Left-Click: |cFF33FF99Toggle button lock.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open configuration panel."]);
    elseif ( frame:GetName() == "PetsAndMountsSecureButtonMounts" ) then
        currentSet = A:GetSetsInUse("MOUNTS");

        if ( currentSet == L["None"] ) then
            currentSet = A.color["RED"]..currentSet;
        else
            currentSet = A.color["GREEN"]..currentSet;
        end

        GameTooltip:AddLine(L["Mounts set in use: %s."]:format(currentSet));
        GameTooltip:AddLine(L["Forced aquatic mount: %s"]:format(A.db.profile.forceOne.mount[4] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[4]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(L["Forced ground mount: %s"]:format(A.db.profile.forceOne.mount[1] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[1]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(L["Forced fly mount: %s"]:format(A.db.profile.forceOne.mount[2] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[2]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(L["Forced hybrid mount: %s"]:format(A.db.profile.forceOne.mount[3] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[3]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(L["Forced passenger mount: %s"]:format(A.db.profile.forceOne.mount[5] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[5]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(" ");

        if ( A.db.profile.dockButton ) then
            GameTooltip:AddLine(L["Use me to move both buttons."]);
            GameTooltip:AddLine(" ");
        end

        GameTooltip:AddLine(L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random mount.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Summon a %s mount.\n|cFFC79C6EControl+Left-Click: |cFF33FF99Toggle button lock.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open configuration panel."]:format(A.mountCat[A.db.profile.mountButtonshiftClickCat]));
    end

    GameTooltip:Show();
end

--[[-------------------------------------------------------------------------------
    Masque support
-------------------------------------------------------------------------------]]--

if ( IsAddOnLoaded("Masque") ) then
    LibStub("Masque"):Group(L["Pets & Mounts"], L["Mounts button"]):AddButton(PetsAndMountsSecureButtonMounts);
    LibStub("Masque"):Group(L["Pets & Mounts"], L["Companions button"]):AddButton(PetsAndMountsSecureButtonPets);
end
