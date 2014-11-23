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
local select = select;
local loadstring = loadstring;
local tContains = tContains;
local string = string;
local ipairs = ipairs;
local tonumber = tonumber;

-- GLOBALS: BINDING_HEADER_PETSANDMOUNTS, InCombatLockdown, GetSpellInfo, IsFlyableArea, IsSpellKnown
-- GLOBALS: IsShiftKeyDown, IsControlKeyDown, GetItemCount, GetItemInfo, UnitBuff, UIDropDownMenu_SetAnchor
-- GLOBALS: ToggleDropDownMenu, GameTooltip, PetsAndMountsSecureButtonMounts, PetsAndMountsSecureButtonPets
-- GLOBALS: GetScreenWidth, IsMounted, GetUnitSpeed, GetTalentInfo, GetTalentRowSelectionInfo, GetInstanceInfo
-- GLOBALS: GetGlyphSocketInfo, IsFalling, NUM_GLYPH_SLOTS, GetShapeshiftForm, IsEquippedItemType
-- GLOBALS: ShentonFishingGlobal, GetActiveSpecGroup

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
    Mounts smart button pre & post clicks
-------------------------------------------------------------------------------]]--

-- Global macro dismount string
function A:SetMacroDismountString()
    if ( A.db.profile.dismountFlying ) then
        A.macroDismountString = "/dismount [mounted]";
    else
        A.macroDismountString = "/dismount [mounted,noflying]";
    end

    if ( A.db.profile.vehicleExit ) then
        A.macroDismountString = A.macroDismountString.."\n/leavevehicle [vehicleui]";
    end
end

--- Check if we got at least one mount for the given cat, check all tables after restriction
function A:GotMountAllTable(cat)
    if ( A.db.profile.forceOne.mount[cat]
    or A.db.profile.mountByMapID[cat][A.currentMapID]
    or A.db.profile.areaMounts and A.uniqueAreaMounts[cat][A.currentMapID]
    or A:GotRandomMount(A.currentMountsSet[cat])
    or A:GotRandomMount(A.pamTable.mountsIds[cat]) ) then
        return 1;
    end

    return nil;
end

--- IsEquippedItemType with a check on A.fishingPole subType
function A:IsEquippedFishingPole()
    if ( A.fishingPoleSubType ) then
        return IsEquippedItemType(A.fishingPoleSubType);
    end

    return nil;
end

--- Get the mount summon command according to button name
A.mountButtonCommands =
{
    ["PetsAndMountsSecureButtonPassengers"] = "/pampassengers",
    ["PetsAndMountsSecureButtonFlying"] = "/pamfly",
    ["PetsAndMountsSecureButtonGround"] = "/pamground",
    ["PetsAndMountsSecureButtonAquatic"] = "/pamaquatic",
    ["PetsAndMountsSecureButtonSurface"] = "/pamsurface",
    ["PetsAndMountsSecureButtonRepair"] = "/pamrepair",
    ["PetsAndMountsSecureButtonHybrid"] = "/pamhybrid",
};
function A:GetMountCommand(button)
    button = button:GetName();

    local command = A.mountButtonCommands[button];

    if ( command ) then
        return command, 1;
    end

    return "/pammount", nil;
end

--- Is the player a boomkin?
function A:IsBoomkin()
    if ( A.playerCurrentSpecID ~= 102 ) then
        A:DebugMessage("IsBoomkin() - false");
        return nil;
    end

    local form = GetShapeshiftForm(1);

    if ( A:IsGlyphed(114338) ) then -- Glyph of the Stag - Offset by one druid's forms
        if ( form ~= 5 ) then
            A:DebugMessage("IsBoomkin() - false");
            return nil;
        end
    else
        if ( form ~= 4 ) then
            A:DebugMessage("IsBoomkin() - false");
            return nil;
        end
    end

    A:DebugMessage("IsBoomkin() - true");
    return 1;
end

--- Is the player able to use the Telaari Talbuk or the Frostwolf War Wolf
function A:IsTelaariTalbukUsable()
    if ( not A.draenorZoneAbilityBaseName ) then
        A.draenorZoneAbilityBaseName = GetSpellInfo(161691);
    end

    if ( A.playerFaction == "Alliance" ) then
        if ( select(7, GetSpellInfo(A.draenorZoneAbilityBaseName)) == 165803 ) then
            return 1;
        end
    elseif ( A.playerFaction == "Horde" ) then
        if ( select(7, GetSpellInfo(A.draenorZoneAbilityBaseName)) == 164222 ) then
            return 1;
        end
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
        druidCatForm = 768, -- lvl 6
        druidTravelForm = 783, -- lvl 16
        druidFlightForm = 165962; -- lvl 58
    },
    HUNTER =
    {
        hunterAspectFox = 172106, -- lvl 84
        hunterAspectCheetah = 5118, -- lvl 24
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
        priestLevitate = 1706, -- lvl 34
    },
    ROGUE =
    {
        rogueSprint = 2983, -- lvl 26
    },
    SHAMAN =
    {
        shamanGhostWolf = 2645, -- lvl 15
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
                A:SetPreClickFunction();
                A:DebugMessage(("SetClassSpells() - Error with a spell. Spell: %d"):format(v));
                return;
            end
        end
    end

    A.classSpellsOK = 1;
    A:SetPostClickMacro();
    A:SetPreClickFunction();
end

--- Death Knight preclick macro
-- For DK we handle Death's Advance and Unholy Presence when moving
function A:SetDeathKnightPreClickMacro()
    if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        local specGroup = GetActiveSpecGroup();
        local selected = select(4, GetTalentInfo(3, 1, specGroup));

        if ( A.db.profile.deathKnightPreferUnholy and A.playerLevel >= 64 ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.deathKnightUnholyPresence);
        elseif ( A.playerLevel >= 58 and selected ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.deathKnightDeathAdvance);
        else
            return "/pammount";
        end
    else
        return "/pammount";
    end
end

--- Druid pre click macro
-- For Druids we handle flight forms
function A:SetDruidPreClickMacro()
    if ( A.db.profile.druidWantFormsOnMove ) then
        if ( GetUnitSpeed("player") > 0 ) then
            if ( A:IsGlyphed(114338) and A.playerLevel >= 58 and A:IsFlyable() and not IsMounted() ) then
                return ("%s\n/cast [indoors] %s; [swimming] %s; %s"):format(A.macroDismountString, A.druidCatForm, A.druidTravelForm, A.druidFlightForm);
            elseif ( A.playerLevel >= 16 and not IsMounted() ) then
                return ("%s\n/cast [indoors] %s; %s"):format(A.macroDismountString, A.druidCatForm, A.druidTravelForm);
            elseif ( A.playerLevel >= 6 and not IsMounted() ) then
                return ("%s\n/cast %s"):format(A.macroDismountString, A.druidCatForm);
            else
                return "/pammount";
            end
        elseif ( GetShapeshiftForm(1) > 0 and not A:IsBoomkin() ) then
            if ( A.db.profile.noMountAfterCancelForm ) then
                return "/cancelform [form]";
            else
                return "/cancelform [form]\n/pammount";
            end
        else
            return "/pammount";
        end
    else
        if ( A.playerLevel >= 58 and A:IsFlyable() and not IsMounted() ) then
            if ( A:IsGlyphed(114338) ) then
                return ("%s\n/cast [indoors] %s; [swimming] %s; %s"):format(A.macroDismountString, A.druidCatForm, A.druidTravelForm, A.druidFlightForm);
            else
                return ("%s\n/cast [indoors] %s; %s"):format(A.macroDismountString, A.druidCatForm, A.druidTravelForm);
            end
        elseif ( A.playerLevel >= 20 and A:CanRide() and not IsMounted() ) then
            if ( GetUnitSpeed("player") > 0 and not IsMounted() ) then
                return ("%s\n/cast [indoors] %s; %s"):format(A.macroDismountString, A.druidCatForm, A.druidTravelForm);
            elseif ( GetShapeshiftForm(1) > 0 and not A:IsBoomkin() ) then
                if ( A.db.profile.noMountAfterCancelForm ) then
                    return "/cancelform [form]";
                else
                    return "/cancelform [form]\n/pammount";
                end
            else
                return "/pammount";
            end
        elseif ( A.playerLevel >= 16 and not IsMounted() ) then
            return ("%s\n/cast [indoors] %s; %s"):format(A.macroDismountString, A.druidCatForm, A.druidTravelForm);
        elseif ( A.playerLevel >= 6 and not IsMounted() ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.druidCatForm);
        else
            return "/pammount";
        end
    end
end

--- Hunter pre click macro
-- For Hunters we handle speed aspects when moving
function A:SetHunterPreClickMacro()
    local cheetahOrPack;

    if ( A.db.profile.hunterPreferPack and A.playerLevel >= 56 ) then
        cheetahOrPack = A.hunterAspectPack;
    elseif ( A.playerLevel >= 24 ) then
        cheetahOrPack = A.hunterAspectCheetah;
    end

    if ( cheetahOrPack and not IsMounted() and GetUnitSpeed("player") > 0 ) then
        return ("%s\n/cast !%s"):format(A.macroDismountString, cheetahOrPack);
    elseif ( cheetahOrPack and not IsMounted() ) then
        return ("/cancelaura %s\n/pammount"):format(cheetahOrPack);
    else
        return "/pammount";
    end
end

--- Mage pre click macro
-- For Mages we handle Blink when moving and Slow Fall when falling
function A:SetMagePreClickMacro()
    if ( A.db.profile.mageSlowFall and IsFalling() and A.playerLevel >= 32 ) then
        return ("%s\n/cast %s"):format(A.macroDismountString, A.mageSlowFall);
    elseif ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        local specGroup = GetActiveSpecGroup();
        local selected = select(4, GetTalentInfo(1, 2, specGroup));

        if ( (A.db.profile.magePreferBlink or not selected) and A.playerLevel >= 7 ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.mageBlink);
        elseif ( selected and A.playerLevel >= 15 ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.mageBlazingSpeed);
        else
            return "/pammount";
        end
    else
        return "/pammount";
    end
end

--- Monk pre click macro
-- For monks we handle Roll and Flying Serpent Kick
function A:SetMonkPreClickMacro()
    if ( IsFalling() and A:IsGlyphed(125893) ) then
        return ("%s\n/cast %s"):format(A.macroDismountString, A.monkZenFlight);
    elseif ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        if ( A.db.profile.monkPreferSerpentKick and A.playerLevel >= 18 ) then
            return ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n%s\n/cast %s")
            :format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier, A.macroDismountString, A.monkFlyingSerpentKick);
        elseif ( A.playerLevel >= 5 ) then
            return ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n%s\n/cast %s")
            :format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier, A.macroDismountString, A.monkRoll);
        else
            return ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n/pammount"):format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier);
        end
    else
        return ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n/pammount"):format(A.db.profile.monkModifier, A.monkZenFlight, A.db.profile.monkModifier);
    end
end

--- Paladin pre click macro
-- For Paladins we handle Speed of Light when moving
function A:SetPaladinPreClickMacro()
    if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        local specGroup = GetActiveSpecGroup();
        local selected = select(4, GetTalentInfo(1, 1, specGroup));

        if ( A.playerLevel >= 15 and selected ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.paladinSpeedOfLight);
        else
            return "/pammount";
        end
    else
        return "/pammount";
    end
end

--- Priest pre click macro
-- For Priests we handle Body and Soul and Angelic Feather when moving
function A:SetPriestPreClickMacro()
    if ( A.db.profile.priestLevitate and IsFalling() and A.playerLevel >= 34 ) then
        return ("%s\n/cast %s"):format(A.macroDismountString, A.priestLevitate);
    elseif ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        local specGroup = GetActiveSpecGroup();

        if ( A.playerLevel >= 30 and select(4, GetTalentInfo(2, 1, specGroup)) ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.priestPowerWordShield);
        elseif ( A.playerLevel >= 30 and select(4, GetTalentInfo(2, 2, specGroup)) ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.priestAngelicFeather);
        else
            return "/pammount";
        end
    else
        return "/pammount";
    end
end

--- Rogue pre click macro
-- For Rogues we handle Sprint when moving
function A:SetRoguePreClickMacro()
    if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
        if ( A.playerLevel >= 26 ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.rogueSprint);
        else
            return "/pammount";
        end
    else
        return "/pammount";
    end
end

--- Shaman pre click macro
-- For Shamans we handle Ghost Wolf when moving
function A:SetShamanPreClickMacro()
    if ( (not IsMounted() and GetUnitSpeed("player") > 0 and A.playerLevel >= 15)
    or (A.db.profile.noMountAfterCancelForm and GetShapeshiftForm(1) > 0) ) then
        return ("%s\n/cast %s"):format(A.macroDismountString, A.shamanGhostWolf);
    else
        return "/pammount";
    end
end

--- Warlock pre click macro
-- For Warlocks we handle teleport and Burning Rush
function A:SetWarlockPreClickMacro()
    local specGroup = GetActiveSpecGroup();
    local selected = select(4, GetTalentInfo(4, 2, specGroup));

    if ( (not selected or A.db.profile.warlockPreferTeleport) and A.playerLevel >= 76 ) then
        if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
            return ("%s\n/cast %s"):format(A.macroDismountString, A.warlockDemonicCircle);
        else
            return "/pammount";
        end
    elseif ( selected ) then
        if ( not IsMounted() and GetUnitSpeed("player") > 0 ) then
            if ( A.db.profile.warlockWantModifier ) then
                return ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n%s\n/cast !%s")
                :format(A.db.profile.warlockModifier, A.warlockBurningRush, A.db.profile.warlockModifier, A.macroDismountString, A.warlockBurningRush);
            else
                return ("%s\n/cast %s"):format(A.macroDismountString, A.warlockBurningRush);
            end
        else
            if ( A.db.profile.warlockWantModifier ) then
                return ("/cancelaura [mod:%s] %s\n/stopmacro [mod:%s]\n/pammount"):format(A.db.profile.warlockModifier, A.warlockBurningRush, A.db.profile.warlockModifier);
            else
                return ("/cancelaura %s\n/pammount"):format(A.warlockBurningRush);
            end
        end
    else
        return "/pammount";
    end
end

--- Warrior pre click macro
-- For Warriors we handle Heroic Leap, Charge and Intervene
function A:SetWarriorPreClickMacro()
    if ( not IsMounted() and GetUnitSpeed("player") > 0 and A.playerLevel >= 76 ) then
        return ("%s\n/cast %s"):format(A.macroDismountString, A.warriorHeroicLeap);
    else
        return "/pammount";
    end
end

--- Default pre click macro
function A:SetDefaultPreClickMacro()
    return "/pammount";
end

--- Basic grief/scam protection
-- Macro mode
A.basicProtectionCommands = { SLASH_CLICK1, SLASH_CLICK2, SLASH_CONSOLE1, SLASH_CONSOLE2, SLASH_GUILD_DISBAND1, SLASH_GUILD_DISBAND2, SLASH_GUILD_DISBAND3, SLASH_GUILD_DISBAND4,
SLASH_GUILD_LEADER1, SLASH_GUILD_LEADER2, SLASH_GUILD_LEADER3, SLASH_GUILD_LEADER4, SLASH_GUILD_LEADER_REPLACE1, SLASH_GUILD_LEADER_REPLACE2,  SLASH_GUILD_LEAVE1,
SLASH_GUILD_LEAVE2, SLASH_GUILD_LEAVE3, SLASH_GUILD_LEAVE4, SLASH_GUILD_PROMOTE1, SLASH_GUILD_PROMOTE2, SLASH_GUILD_PROMOTE3, SLASH_GUILD_PROMOTE4, SLASH_GUILD_UNINVITE1,
SLASH_GUILD_UNINVITE2, SLASH_GUILD_UNINVITE3, SLASH_GUILD_UNINVITE4, SLASH_LOGOUT1, SLASH_LOGOUT2, SLASH_LOGOUT3, SLASH_LOGOUT4, SLASH_PVP1, SLASH_PVP2, SLASH_QUIT1,
SLASH_QUIT2, SLASH_QUIT3, SLASH_QUIT4, SLASH_RELOAD1, SLASH_RELOAD2, SLASH_SCRIPT1, SLASH_SCRIPT2, SLASH_SCRIPT3, SLASH_SCRIPT4 };
function A:BasicProtectionMacro(code)
    if ( type(code) ~= "string" ) then
        return "NOT A STRING";
    end

    code = string.lower(code);

    for k,v in ipairs(A.basicProtectionCommands) do
        if ( string.find(code, v) ) then
            return v;
        end
    end

    return nil;
end

-- LUA mode
A.basicProtectionFunctions = { "Click", "SetCVar", "ConsoleExec", "GuildDisband", "GuildSetLeader", "GuildLeave", "GuildPromote", "GuildUninvite", "Logout", "Quit",
"ForceQuit", "StartAuction", "PlaceAuctionBid", "ClickAuctionSellItemButton", "SaveBindings", "PickupBagFromSlot", "PickupContainerItem", "SplitContainerItem", "DeleteCursorItem",
"DropCursorMoney", "PickupInventoryItem", "PickupItem", "PickupPlayerMoney", "PickupTradeMoney", "SetGuildBankTabPermissions", "SetGuildBankWithdrawGoldLimit", "ConfirmBindOnUse",
"AcceptSockets", "ConfirmLootRoll", "CreateMacro", "EditMacro", "DeleteInboxItem", "ReturnInboxItem", "SendMail", "BuyMerchantItem", "PickupMerchantItem", "RepairAllItems",
"DropItemOnUnit", "PetRename", "PetAbandon", "ReleasePetByID", "AbandonSkill", "RunScript", "DoTradeSkill", "AcceptTrade", "InitiateTrade", "AddTradeMoney", "PickupPlayerMoney",
"PickupTradeMoney", "SetTradeMoney", "hooksecurefunc", "loadstring" };
function A:BasicProtectionLUA(code)
    if ( type(code) ~= "string" ) then
        return "NOT A STRING";
    end

    --code = string.lower(code);

    for k,v in ipairs(A.basicProtectionFunctions) do
        if ( string.find(code, v) ) then
            return v;
        end
    end

    return nil;
end

--- Set the pre click method
function A:SetPreClickFunction(noCustom)
    if ( A.db.profile.customMountMacrosEnabled and not noCustom) then
        local name, where = GetInstanceInfo();

        -- Area types macros
        if ( tContains(A.areaTypes, where) ) then
            if ( A.db.profile.customMountMacros[where].luaMode ) then
                if ( A.db.profile.customMountMacros[where].lua.pre and A.db.profile.customMountMacros[where].lua.pre ~= "" ) then
                    local prot;

                    if ( A.db.profile.customMacrosLUAProtectionEnabled ) then
                        prot = A:BasicProtectionLUA(A.db.profile.customMountMacros[where].lua.pre);
                    end

                    if ( prot ) then
                        A:PopMessageFrame("griefScamProtectionMessageLUA", {prot, A.areaTypesLocales[where], "pre"});
                    else
                        local func, errorString = loadstring(A.db.profile.customMountMacros[where].lua.pre);

                        if ( func ) then
                            A:DebugMessage(("SetPreClickFunction() - Custom pre macro set - Mode: %s - Where: %s"):format("LUA", where));
                            A.PreClickFunc = func;
                            return;
                        else
                            A:Message(L["Your LUA custom %s macro for %s got an error. Error: %s"]:format("pre", A.areaTypesLocales[where], errorString));
                        end
                    end
                end
            else
                if ( A.db.profile.customMountMacros[where].macro.pre and A.db.profile.customMountMacros[where].macro.pre ~= "" ) then
                    local prot;

                    if ( A.db.profile.customMacrosMacroProtectionEnabled ) then
                        prot = A:BasicProtectionMacro(A.db.profile.customMountMacros[where].macro.pre);
                    end

                    if ( prot ) then
                        A:PopMessageFrame("griefScamProtectionMessageMacro", {prot, where, "pre"});
                    else
                        A.PreClickFunc = function() return A.db.profile.customMountMacros[where].macro.pre; end;
                        A:DebugMessage(("SetPreClickFunction() - Custom pre macro set - Mode: %s - Where: %s"):format("Macro", where));
                        return;
                    end
                end
            end
        end

        -- Default custom macro
        if ( A.db.profile.customMountMacros.default.luaMode ) then
            if ( A.db.profile.customMountMacros.default.lua.pre and A.db.profile.customMountMacros.default.lua.pre ~= "" ) then
                local prot;

                if ( A.db.profile.customMacrosLUAProtectionEnabled ) then
                    prot = A:BasicProtectionLUA(A.db.profile.customMountMacros.default.lua.pre);
                end

                if ( prot ) then
                    A:PopMessageFrame("griefScamProtectionMessageLUA", {prot, L["Default"], "pre"});
                else
                    local func, errorString = loadstring(A.db.profile.customMountMacros.default.lua.pre);

                    if ( func ) then
                        A:DebugMessage(("SetPreClickFunction() - Custom pre macro set - Mode: %s - Where: %s"):format("LUA", "default"));
                        A.PreClickFunc = func;
                        return;
                    else
                        A:Message(L["Your LUA custom %s macro for %s got an error. Error: %s"]:format("pre", L["Default"], errorString));
                    end
                end
            end
        else
            if ( A.db.profile.customMountMacros.default.macro.pre and A.db.profile.customMountMacros.default.macro.pre ~= "" ) then
                local prot;

                if ( A.db.profile.customMacrosMacroProtectionEnabled ) then
                    prot = A:BasicProtectionMacro(A.db.profile.customMountMacros.default.macro.pre);
                end

                if ( prot ) then
                    A:PopMessageFrame("griefScamProtectionMessageMacro", {prot, L["Default"], "pre"});
                else
                    A.PreClickFunc = function() return A.db.profile.customMountMacros.default.macro.pre; end;
                    A:DebugMessage(("SetPreClickFunction() - Custom pre macro set - Mode: %s - Where: %s"):format("Macro", "Default"));
                    return;
                end
            end
        end
    end

    if ( A.db.profile.classesMacrosEnabled and A.classSpellsOK ) then
        -- Death Knight
        if ( A.playerClass == "DEATHKNIGHT" ) then
            A.PreClickFunc = A.SetDeathKnightPreClickMacro;
        -- Druid
        elseif ( A.playerClass == "DRUID" ) then
            A.PreClickFunc = A.SetDruidPreClickMacro;
        -- Hunter
        elseif ( A.playerClass == "HUNTER" ) then
            A.PreClickFunc = A.SetHunterPreClickMacro;
        -- Mage
        elseif ( A.playerClass == "MAGE" ) then
            A.PreClickFunc = A.SetMagePreClickMacro;
        -- Monk
        elseif ( A.playerClass == "MONK" ) then
            A.PreClickFunc = A.SetMonkPreClickMacro;
        -- Paladin
        elseif ( A.playerClass == "PALADIN" ) then
            A.PreClickFunc = A.SetPaladinPreClickMacro;
        -- Priest
        elseif ( A.playerClass == "PRIEST" ) then
            A.PreClickFunc = A.SetPriestPreClickMacro;
        -- Rogue
        elseif ( A.playerClass == "ROGUE" ) then
            A.PreClickFunc = A.SetRoguePreClickMacro;
        -- Shaman
        elseif ( A.playerClass == "SHAMAN" ) then
            A.PreClickFunc = A.SetShamanPreClickMacro;
        -- Warlock
        elseif ( A.playerClass == "WARLOCK" ) then
            A.PreClickFunc = A.SetWarlockPreClickMacro;
        -- Warrior
        elseif ( A.playerClass == "WARRIOR" ) then
            A.PreClickFunc = A.SetWarriorPreClickMacro;
        -- Just in case
        else
            A.PreClickFunc = A.SetDefaultPreClickMacro;
        end
    else
        A.PreClickFunc = A.SetDefaultPreClickMacro;
    end
end

--- PreClick callback
function A:PreClickMount(button, clickedBy)
    if ( not A.addonRunning or InCombatLockdown() ) then return; end

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
            if ( A.db.profile.telaariTalbuk and A:IsTelaariTalbukUsable() and not A:IsSwimming() and not A:IsFlyable() and not (A.db.profile.vehicleExit and A:IsPlayerInVehicle()) ) then -- 165803 - Telaari Talbuk / 164222 - Frostwolf War Wolf
                if ( A.playerFaction == "Alliance" ) then
                    if ( not A.telaariTalbukName ) then A.telaariTalbukName = GetSpellInfo(165803); end

                    button:SetAttribute("type", "macro");
                    button:SetAttribute("macrotext", ("/use %s"):format(A.telaariTalbukName or "Telaari Talbuk"));
                else
                    if ( not A.telaariTalbukName ) then A.telaariTalbukName = GetSpellInfo(164222); end

                    button:SetAttribute("type", "macro");
                    button:SetAttribute("macrotext", ("/use %s"):format(A.telaariTalbukName or "Frostwolf War Wolf"));
                end
            elseif ( A.db.profile.shimmeringMoonstone and GetItemCount(101675, nil, nil) > 0 and not A:IsSwimming() and not A:IsFlyable() and not (A.db.profile.vehicleExit and A:IsPlayerInVehicle()) ) then -- 37011 - Shimmering Moonstone from Darkmoon fair (Moonfang drop)
                if ( not A.shimmeringMoonstoneName ) then A.shimmeringMoonstoneName = GetItemInfo(101675); end

                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", ("/use %s"):format(A.shimmeringMoonstoneName or "Shimmering Moonstone"));
            elseif ( A.db.profile.magicBroom and GetItemCount(37011, nil, nil) > 0 and (A:IsSwimming() == 2 or not A:IsSwimming()) and not (A.db.profile.vehicleExit and A:IsPlayerInVehicle()) ) then -- 37011 - Magic Broom from Hallow's End
                if ( not A.magicBroomName ) then A.magicBroomName = GetItemInfo(37011); end

                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", ("/use %s"):format(A.magicBroomName or "Magic Broom"));
            elseif ( A.db.profile.anglersFishingRaft and GetItemCount(85500, nil, nil) > 0 and A:IsSwimming() == 2 and (A:IsEquippedFishingPole() or (ShentonFishingGlobal and ShentonFishingGlobal.isFishing)) and not (A.db.profile.vehicleExit and A:IsPlayerInVehicle()) ) then -- 85500 - Anglers Fishing Raft
                if ( not A.anglersFishingRaft ) then A.anglersFishingRaft = GetItemInfo(85500); end

                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", ("/use %s"):format(A.anglersFishingRaft or "Anglers Fishing Raft"));
            elseif ( A.db.profile.oculusDrakes and (GetItemCount(37815, nil, nil) > 0 or GetItemCount(37859, nil, nil) > 0 or GetItemCount(37860, nil, nil) > 0)
            and (tonumber(A.currentMapID) == 528) and not (A.db.profile.vehicleExit and A:IsPlayerInVehicle()) ) then -- Oculus drakes: 37815 Emerald Essence - 37859 Amber Essence - 37860 Ruby Essence
                if ( not A.magicBroomName ) then A.magicBroomName = GetItemInfo(37011); end
                if ( GetItemCount(37815, nil, nil) > 0 ) then
                    A.oculusDrake = GetItemInfo(37815);
                elseif ( GetItemCount(37859, nil, nil) > 0 ) then
                    A.oculusDrake = GetItemInfo(37859);
                elseif ( GetItemCount(37860, nil, nil) > 0 ) then
                    A.oculusDrake = GetItemInfo(37860);
                end

                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", ("/use %s"):format(A.oculusDrake or "Amber Essence"));
            -- Water walking spells
            elseif ( A.db.profile.surfaceMount and ((A.playerClass == "DEATHKNIGHT" and A.playerLevel >= 66)
            or (A.playerClass == "SHAMAN" and A.playerLevel >= 24)) and A:IsSwimming() == 2 and A.classSpellsOK ) then
                if ( A.db.profile.preferSurfaceSpell or (not A.db.profile.preferSurfaceSpell and not A:GotMountAllTable(6)) ) then
                    if ( A.playerClass == "DEATHKNIGHT" and not UnitBuff("player", A.deathKnightPathOfFrost) ) then
                        button:SetAttribute("type", "macro");
                        button:SetAttribute("macrotext", "/cast !"..A.deathKnightPathOfFrost);
                        A:DebugMessage(("Preclick macro set to: %s"):format("/cast !"..A.deathKnightPathOfFrost));
                    elseif ( A.playerClass == "SHAMAN" ) then
                        if ( UnitBuff("player", A.shamanWaterWalking) ) then
                            local macro = A:PreClickFunc();
                            button:SetAttribute("type", "macro");
                            button:SetAttribute("macrotext", macro);
                            A:DebugMessage(("Preclick macro set to: %s"):format(macro));
                        else
                            button:SetAttribute("type", "macro");
                            button:SetAttribute("macrotext", "/cast "..A.shamanWaterWalking);
                            A:DebugMessage(("Preclick macro set to: %s"):format("macrotext", "/cast "..A.shamanWaterWalking));
                        end
                    else
                        local macro = A:PreClickFunc();
                        button:SetAttribute("type", "macro");
                        button:SetAttribute("macrotext", macro);
                        A:DebugMessage(("Preclick macro set to: %s"):format(macro));
                    end
                else
                    local macro = A:PreClickFunc();
                    button:SetAttribute("type", "macro");
                    button:SetAttribute("macrotext", macro);
                    A:DebugMessage(("Preclick macro set to: %s"):format(macro));
                end
            else
                local macro = A:PreClickFunc();
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", macro);
                A:DebugMessage(("Preclick macro set to: %s"):format(macro));
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

function A:PreClickMountForced(button, clickedBy)
    if ( not A.addonRunning or InCombatLockdown() ) then return; end

    -- Get mount summon command
    local command, isCustom = A:GetMountCommand(button);

    -- Death Knight
    --if ( A.playerClass == "DEATHKNIGHT" ) then
    -- Druid
    if ( A.playerClass == "DRUID" ) then
        if ( GetShapeshiftForm(1) > 0 and not A:IsBoomkin() ) then
            if ( A.db.profile.noMountAfterCancelForm ) then
                command = "/cancelform [form]";
            else
                command = ("/cancelform [form]\n%s"):format(command);
            end
        end
    -- Hunter
    --elseif ( A.playerClass == "HUNTER" ) then
    -- Mage
    --elseif ( A.playerClass == "MAGE" ) then
    -- Monk
    --elseif ( A.playerClass == "MONK" ) then
    -- Paladin
    --elseif ( A.playerClass == "PALADIN" ) then
    -- Priest
    --elseif ( A.playerClass == "PRIEST" ) then
    -- Rogue
    --elseif ( A.playerClass == "ROGUE" ) then
    -- Shaman
    elseif ( A.playerClass == "SHAMAN" ) then
        if ( A.db.profile.noMountAfterCancelForm ) then
            command = "/cancelform [form]";
        else
            command = ("/cancelform [form]\n%s"):format(command);
        end
    -- Warlock
    --elseif ( A.playerClass == "WARLOCK" ) then
    -- Warrior
    --elseif ( A.playerClass == "WARRIOR" ) then
    end

    button:SetAttribute("type", "macro");
    button:SetAttribute("macrotext", command);
end

-- Post click macro
function A:SetPostClickMacro(noCustom)
    if ( A.db.profile.customMountMacrosEnabled and not noCustom) then
        local name, where = GetInstanceInfo();

        -- Area types macros
        if ( tContains(A.areaTypes, where) ) then
            if ( A.db.profile.customMountMacros[where].luaMode ) then
                if ( A.db.profile.customMountMacros[where].lua.post and A.db.profile.customMountMacros[where].lua.post ~= "" ) then
                    local prot;

                    if ( A.db.profile.customMacrosLUAProtectionEnabled ) then
                        prot = A:BasicProtectionLUA(A.db.profile.customMountMacros[where].lua.post);
                    end

                    if ( prot ) then
                        A:PopMessageFrame("griefScamProtectionMessageLUA", {prot, A.areaTypesLocales[where], "post"});
                    else
                        local func, errorString = loadstring(A.db.profile.customMountMacros[where].lua.post);

                        if ( func ) then
                            A:DebugMessage(("SetPreClickFunction() - Custom post macro set - Mode: %s - Where: %s"):format("LUA", where));
                            A.postClickMacro =  func();
                            return;
                        else
                            A:Message(L["Your LUA custom %s macro for %s got an error. Error: %s"]:format("post", A.areaTypesLocales[where], errorString));
                        end
                    end
                end
            else
                if ( A.db.profile.customMountMacros[where].macro.post and A.db.profile.customMountMacros[where].macro.post ~= "" ) then
                    local prot;

                    if ( A.db.profile.customMacrosMacroProtectionEnabled ) then
                        prot = A:BasicProtectionMacro(A.db.profile.customMountMacros[where].macro.post);
                    end

                    if ( prot ) then
                        A:PopMessageFrame("griefScamProtectionMessageMacro", {prot, where, "post"});
                    else
                        A:DebugMessage(("SetPreClickFunction() - Custom post macro set - Mode: %s - Where: %s"):format("Macro", where));
                        A.postClickMacro = A.db.profile.customMountMacros[where].macro.post;
                        return;
                    end
                end
            end
        end

        -- Default custom macro
        if ( A.db.profile.customMountMacros.default.luaMode ) then
            if ( A.db.profile.customMountMacros.default.lua.post and A.db.profile.customMountMacros.default.lua.post ~= "" ) then
                if ( A.db.profile.customMountMacros[where].lua.post and A.db.profile.customMountMacros[where].lua.post ~= "" ) then
                    local prot;

                    if ( A.db.profile.customMacrosLUAProtectionEnabled ) then
                        prot = A:BasicProtectionLUA(A.db.profile.customMountMacros.default.lua.post);
                    end

                    if ( prot ) then
                        A:PopMessageFrame("griefScamProtectionMessageLUA", {prot, L["Default"], "post"});
                    else
                        local func, errorString = loadstring(A.db.profile.customMountMacros.default.lua.post);

                        if ( func ) then
                            A:DebugMessage(("SetPreClickFunction() - Custom post macro set - Mode: %s - Where: default"):format("LUA"));
                            A.postClickMacro =  func();
                            return;
                        else
                            A:Message(L["Your LUA custom %s macro for %s got an error. Error: %s"]:format("post", L["Default"], errorString));
                        end
                    end
                end
            end
        else
            if ( A.db.profile.customMountMacros.default.macro.post and A.db.profile.customMountMacros.default.macro.post ~= "" ) then
                local prot;

                if ( A.db.profile.customMacrosMacroProtectionEnabled ) then
                    prot = A:BasicProtectionMacro(A.db.profile.customMountMacros.default.macro.post);
                end

                if ( prot ) then
                    A:PopMessageFrame("griefScamProtectionMessageMacro", {prot, L["Default"], "post"});
                else
                    A:DebugMessage(("SetPreClickFunction() - Custom post macro set - Mode: %s - Where: %s"):format("Macro", "default"));
                    A.postClickMacro = A.db.profile.customMountMacros.default.macro.post;
                    return;
                end
            end
        end
    end

    if ( A.db.profile.classesMacrosEnabled and A.classSpellsOK ) then
        -- Death Knight
        if ( A.playerClass == "DEATHKNIGHT" ) then
            local specGroup = GetActiveSpecGroup();
            local selected = select(4, GetTalentInfo(3, 1, specGroup));

            if ( A.db.profile.deathKnightPreferUnholy and A.playerLevel >= 64 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.deathKnightUnholyPresence);
            elseif ( A.playerLevel >= 58 and selected ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.deathKnightDeathAdvance);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Druid
        elseif ( A.playerClass == "DRUID" ) then
            if ( A.playerLevel >= 16 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.druidTravelForm);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Hunter
        elseif ( A.playerClass == "HUNTER" ) then
            local cheetahOrPack;

            if ( A.db.profile.hunterPreferPack and A.playerLevel >= 56 ) then
                cheetahOrPack = A.hunterAspectPack;
            elseif ( A.playerLevel >= 24 ) then
                cheetahOrPack = A.hunterAspectCheetah;
            end

            if ( not cheetahOrPack ) then
                A.postClickMacro = A.macroDismountString;
            else
                A.postClickMacro = ("%s\n/cast [nomounted,novehicleui,nomod] !%s\n/cancelaura [mod:%s] %s"):format(A.macroDismountString, cheetahOrPack, A.db.profile.hunterModifier, cheetahOrPack);
            end
        -- Mage
        elseif ( A.playerClass == "MAGE" ) then
            if ( A.db.profile.mageForceSlowFall ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.mageSlowFall);
            else
                local specGroup = GetActiveSpecGroup();
                local selected = select(4, GetTalentInfo(1, 2, specGroup));

                if ( (A.db.profile.magePreferBlink or not selected) and A.playerLevel >= 7 ) then
                    A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.mageBlink);
                elseif ( selected and A.playerLevel >= 15 ) then
                    A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.mageBlazingSpeed);
                else
                    A.postClickMacro = A.macroDismountString;
                end
            end
        -- Monk
        elseif ( A.playerClass == "MONK" ) then
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
        elseif ( A.playerClass == "PALADIN" ) then
            local specGroup = GetActiveSpecGroup();
            local selected = select(4, GetTalentInfo(1, 1, specGroup));

            if ( A.playerLevel >= 15 and selected ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.paladinSpeedOfLight);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Priest
        elseif ( A.playerClass == "PRIEST" ) then
            if ( A.db.profile.priestForceLevitate ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.priestLevitate);
            else
                local isFree, talent = GetTalentRowSelectionInfo(2);

                if ( A.playerLevel >= 30 and talent == 4 ) then
                    A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.priestPowerWordShield);
                elseif ( A.playerLevel >= 30 and talent == 5 ) then
                    A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.priestAngelicFeather);
                else
                    A.postClickMacro = A.macroDismountString;
                end
            end
        -- Rogue
        elseif ( A.playerClass == "ROGUE" ) then
            if ( A.playerLevel >= 26 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.rogueSprint);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Shaman
        elseif ( A.playerClass == "SHAMAN" ) then
            if ( A.playerLevel >= 15 ) then
                A.postClickMacro = ("%s\n/cast [nomounted] %s"):format(A.macroDismountString, A.shamanGhostWolf);
            else
                A.postClickMacro = A.macroDismountString;
            end
        -- Warlock
        elseif ( A.playerClass == "WARLOCK" ) then
            local specGroup = GetActiveSpecGroup();
            local selected = select(4, GetTalentInfo(4, 2, specGroup));

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
        elseif ( A.playerClass == "WARRIOR" ) then
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

    A:DebugMessage(("Postclick macro set to: %s"):format(A.postClickMacro));
end

--- PostClick callback
function A:PostClickMount(button, clickedBy)
    if ( not A.addonRunning or InCombatLockdown() ) then return; end

    button:SetAttribute("type", "macro");
    button:SetAttribute("macrotext", A.postClickMacro);
end

--[[-------------------------------------------------------------------------------
    Pets button pre & post clicks
-------------------------------------------------------------------------------]]--

--- PreClick callback
function A:PreClickPet(button, clickedBy)
    if ( not A.addonRunning or InCombatLockdown() ) then return; end

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
