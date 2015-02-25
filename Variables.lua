--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Variables.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- GLOBALS: UnitIsFeignDeath, UnitCastingInfo, UnitChannelInfo, UnitIsDeadOrGhost, InCombatLockdown
-- GLOBALS: GetNumLootItems, IsMounted, IsFlying, IsFalling, UnitHasVehicleUI, UnitOnTaxi
-- GLOBALS: HasFullControl, GetBarberShopStyleInfo, IsIndoors

-- Used in PLAYER_ENTERING_WORLD event
-- When it is still true it will permit actions we only want when entering world
A.onFirstLoadActions = 1;

-- If true will init the DB
A.initialized = 1;

-- AddOn version
A.version = GetAddOnMetadata("PetsAndMounts", "Version");
A.versionStage = "Release";
--@alpha@
A.versionStage = "Alpha";
--@end-alpha@

-- Addon URL
A.addonURL = "http://www.curse.com/addons/wow/pets-and-mounts";

-- Text colors
A.color =
{
    RED = "|cffff3333",
    GREEN = "|cff33ff99",
    BLUE = "|cff3399ff",
    WHITE = "|cffffffff",
    DRUID = "|cffff7d0a",
    DEATHKNIGHT = "|cffc41f3b",
    HUNTER = "|cffabd473",
    MAGE = "|cff69ccf0",
    MONK = "|cff00ff96",
    PALADIN = "|cfff58cba",
    PRIEST = "|cffffffff",
    ROGUE = "|cfffff569",
    SHAMAN = "|cff0070de",
    WARLOCK = "|cff9482c9",
    WARRIOR = "|cffc79c6e",
    POOR = "|cff9d9d9d",
    COMMON = "|cffffffff",
    UNCOMMON = "|cff1eff00",
    RARE = "|cff0070dd",
    EPIC = "|cffa335ee",
    LEGENDAY = "|cffff8000",
    ARTIFACT = "|cffe6cc80",
    HEIRLOOM = "|cffe6cc80",
    RESET = "|r",
};

A.rarityColors =
{
    A.color.POOR,
    A.color.COMMON,
    A.color.UNCOMMON,
    A.color.RARE,
    A.color.EPIC,
    A.color.LEGENDAY,
    A.color.ARTIFACT,
    A.color.HEIRLOOM,
};

-- Player pets and mounts table
A.pamTable =
{
    pets = {},
    petsIds = {},
    mounts = {},
    mountsIds = {},
};

A.mountCat =
{
    L["Ground"],
    L["Fly"],
    L["Hybrid"],
    L["Aquatic"],
    L["Passenger"],
    L["Surface"],
    L["Repair"],
};

-- Mounts with passengers spellID
A.passengerMounts =
{
    60424, -- Mekgineer's Chopper
    61465, -- Grand Black War Mammoth (Alliance)
    61467, -- Grand Black War Mammoth (Horde)
    122708, -- Grand Expedition Yak
    61469, -- Grand Ice Mammoth (Horde)
    61470, -- Grand Ice Mammoth (Alliance)
    121820, -- Obsidian Nightwing
    93326, -- Sandstone Drake
    61425, -- Traveler's Tundra Mammoth (Alliance)
    61447, -- Traveler's Tundra Mammoth (Horde)
    55531, -- Mechano-Hog
    75973, -- X-53 Touring Rocket
};

-- Mounts with another bit field than the aquatic ones
-- this will force them to aquatics
A.aquaticMounts =
{
    30174, -- Riding Turtle
    64731, -- Sea Turtle
};

-- Repair mounts spellID
A.repairMounts =
{
    122708, -- Grand Expedition Yak
    61425, -- Traveler's Tundra Mammoth (Alliance)
    61447, -- Traveler's Tundra Mammoth (Horde)
};

-- Mounts listed here can only be summoned in a specific area
A.uniqueAreaMounts =
{
    [1] = -- Ground
    {
        ["766"] = -- Qiraji Battle Tanks in Temple of Ahn'Qiraj
        {
            25953, -- Blue Qiraji Battle Tank
            26056, -- Green Qiraji Battle Tank
            26054, -- Red Qiraji Battle Tank
            26055, -- Yellow Qiraji Battle Tank
        },
    },
    [2] = {}, -- Fly
    [3] = {}, -- Hybrid (ground & fly)
    [4] = -- Aquatic
    {
        -- Abyssal Seahorse in Vashj'ir
        ["614"] = 75207, -- Abyssal Depths
        ["610"] = 75207, -- Kelp'thar Forest
        ["615"] = 75207, -- Shimmering Expanse
        ["613"] = 75207, -- Vashj'ir
    },
    [5] = {}, -- with passengers
    [6] = {}, -- Surface
    [7] = {}, -- Repair
};

-- Area types handled by the addon, for auto summon behavior according to area type
A.areaTypes =
{
    "arena", -- A PvP Arena instance
    "none", -- Normal world area (e.g. Northrend, Kalimdor, Deeprun Tram)
    "party", -- An instance for 5-man groups
    "pvp", -- A PvP battleground instance
    "raid", -- An instance for raid groups
    "scenario", -- A scenario instance
};

A.areaTypesLocales =
{
    arena = L["Arena instance"], -- A PvP Arena instance
    none = L["Open world"], -- Normal world area (e.g. Northrend, Kalimdor, Deeprun Tram)
    party = L["Party instance"], -- An instance for 5-men groups
    pvp = L["Battleground instance"], -- A PvP battleground instance
    raid = L["Raid instance"], -- An instance for raid groups
    scenario = L["Scenario instance"], -- A scenario instance
};

-- Database revision
A.databaseRevision = 2;

-- Surface mounts
A.surfaceMounts =
{
    118089, -- Azure Water Strider
};

-- Docked buttons anchors
-- point, relativePoint offX offY
A.dockButtonsAnchors =
{
    ["Top"] = {"BOTTOM","TOP",0,4},
    ["Right"] = {"LEFT","RIGHT",4,0},
    ["Bottom"] = {"TOP","BOTTOM",0,-4},
    ["Left"] = {"RIGHT","LEFT",-4,0},
};

-- Pet species, called petTypes by Blizzard, so we will do the same
A.petTypes =
{
    "Humanoid",
    "Dragonkin",
    "Flying",
    "Undead",
    "Critter",
    "Magic",
    "Elemental",
    "Beast",
    "Aquatic",
    "Mechanical",
    --"None";
};

-- Modifiers list
A.modifiersList =
{
    ["shift"] = L["Shift"],
    ["ctrl"] = L["Control"],
    ["alt"] = L["Alt"],
};

-- Default icons
A.defaultDataBrokerIcon = "Achievement_WorldEvent_Brewmaster";
A.defaultPetButtonIcon = "INV_Pet_Mouse";
A.defaultMountButtonIcon = "ABILITY_MOUNT_ONYXPANTHER";

-- Pets with restrictions, faction mostly, and some useless (winter helpers)
--[[
# Format
[npcID] =
{
    type = "string type",
    args = "whatever is restricted, can be a table",
}

# Types
banned - simple ban no args here
faction - args = Not localized faction as returned by UnitFactionGroup()
]]--
A.restrictedPets =
{
    [15705] = -- Winter's Little Helper
    {
        type = "banned",
    },
    [15698] = -- Father Winter's Helper
    {
        type = "banned",
    },
    [54541] = -- Horde Balloon
    {
        type = "faction",
        args = "Horde",
    },
    [51649] = -- Moonkin Hatchling - Horde
    {
        type = "faction",
        args = "Horde",
    },
    [49588] = -- Guild Page - Horde
    {
        type = "faction",
        args = "Horde",
    },
    [49590] = -- Guild Herald - Horde
    {
        type = "faction",
        args = "Horde",
    },
    [54539] = -- Alliance Balloon
    {
        type = "faction",
        args = "Alliance",
    },
    [51601] = -- Moonkin Hatchling - Alliance
    {
        type = "faction",
        args = "Alliance",
    },
    [49586] = -- Guild Page - Alliance
    {
        type = "faction",
        args = "Alliance",
    },
    [49587] = -- Guild Herald - Alliance
    {
        type = "faction",
        args = "Alliance",
    },
};

-- Underwater breathing spells
-- Using them all, just in case
-- Thank you Wowhead
A.underwaterBreathingSpells =
{
    1234, -- Joe's God Mode
    5421, -- Aquatic Form Passive
    7178, -- Water Breathing
    11789, -- Water Breathing
    16591, -- Noggenfogger Elixir
    17443, -- Air Bubbles
    17775, -- Air Bubbles
    18733, -- Air Bubbles
    22807, -- Greater Water Breathing
    24347, -- Master Angler
    24925, -- Hallow's End Candy
    27827, -- Spirit of Redemption
    31920, -- Nagrand Cherry
    40621, -- Water Breathing
    41273, -- Deepdiving Pearl
    42275, -- Repaired Diving Gear
    44235, -- Water Breathing
    44258, -- Breathing Tube
    44270, -- Breathing Tube
    44467, -- Recovery Diver's Potion
    48359, -- Tua'kea's Breathing Bladder
    48719, -- Water Breathing
    50003, -- Breathing Tube
    51244, -- Water Breathing
    68121, -- Naga Breath
    71661, -- Mechashark X-Steam
    71914, -- Irresistible Pool Pony
    73701, -- Sea Legs
    75627, -- Speedbarge Diving Helm
    76546, -- Ride Vehicle
    81812, -- Spirit Vision 3
    81952, -- Ride Submarine Chase Vehicle - Seat 2
    82258, -- Teleport Alliance Camera Vehicle
    82367, -- Underwater Breathing
    83028, -- Teleport HORDE Camera Vehicle
    83705, -- Submerged
    85354, -- Puffer Breath
    88416, -- Silversnap Swim Tonic
    91722, -- Puffer Breath
    94758, -- Submarine Sonar Sound
    95675, -- Blackwater Boon
    95830, -- Ride Vehicle WITH WATER BREATHING
    95833, -- Vashj'ir Vehicle Water Breathing Aura
    102737, -- Curse of the Coy
    102942, -- Curse of the Crocodile
    103422, -- Rell's Report
    103824, -- Amber's Report
    104345, -- Shokia's Report
    104474, -- Shokia's Report
    104475, -- Shokia's Report
    105707, -- Darkwater Potion
    110298, -- Noggenfogger Elixir [PH]
    110450, -- Bassgut Breathing
    118078, -- Modified Gear Level (5.0 Testing Only)
    119689, -- Diving Helmet
    119966, -- Blessing of the Pearlfin
    123503, -- Amber Residue
    123710, -- Mazu's Breath
    124555, -- Mark of Skeer
    127285, -- Shimmering Water
    129678, -- Enchanted Essence
    131052, -- Mark of Korven
    144299, -- Damaged Diving Helmet
    147643, -- Cursed Swabby Helmet
    149408, -- Curse of the Sea
    149409, -- Curse of the Sea
};

-- Pets summon filters
-- Integer indexed table of tables
-- Each table contains:
-- - name = name of the filter localized
-- - func = the function called by the auto pet method, it return true when it should be filtered
-- - option = bool if true it will appear in the options panel and can be disabled/enabled by the player
-- - desc = optional, it will search for a description to add to the Ace3 config
A.petsSummonFilters =
{
    { -- 1
        name = L["Stealthed"],
        func = function() return A:IsStealthed(); end,
        option = nil,
    },
    { -- 2
        name = L["Feign Death"],
        func = function() return UnitIsFeignDeath("player"); end,
        option = nil,
    },
    { -- 3
        name = L["Casting"],
        func = function()
            if ( UnitCastingInfo("player") ) then return 1; end
            if ( UnitChannelInfo("player") ) then return 1; end
            return nil;
        end,
        option = nil,
    },
    { -- 4
        name = L["Dead"],
        func = function() return UnitIsDeadOrGhost("player"); end,
        option = nil,
    },
    { -- 5
        name = L["Combat"],
        func = function() return InCombatLockdown(); end,
        option = 1,
    },
    { -- 6
        name = "noAuto",
        func = function() return A.noAutoPet; end,
        option = nil,
    },
    { -- 7
        name = L["Looting"],
        func = function()
            if ( GetNumLootItems() > 0 ) then
                return 1;
            end
            return nil;
        end,
        option = nil,
    },
    { -- 8
        name = L["Mounted"],
        func = function() return IsMounted(); end,
        option = 1,
    },
    { -- 9
        name = L["Flying"],
        func = function() return IsFlying(); end,
        option = 1,
    },
    { -- 10
        name = L["Falling"],
        func = function() return IsFalling(); end,
        option = nil,
    },
    { -- 11
        name = L["Vehicle"],
        func = function() return UnitHasVehicleUI("player"); end,
        option = 1,
    },
    { -- 12
        name = L["Fly path"],
        func = function() return UnitOnTaxi("player"); end,
        option = nil,
    },
    { -- 13
        name = L["Regen"],
        func = function() return A:HasRegenBuff(); end,
        option = nil,
    },
    { -- 14
        name = L["Control lost"],
        func = function() return not HasFullControl(); end,
        option = nil,
    },
    { -- 15
        name = L["Barber"],
        func = function()
            if ( GetBarberShopStyleInfo(1) ) then return 1; end
            return nil;
        end,
        option = nil,
    },
};

A.mountsSummonFilters =
{
    { -- 1
        name = L["Stealthed"],
        func = function() return A:IsStealthed(); end,
        option = 1,
    },
    { -- 2
        name = L["Feign Death"],
        func = function() return UnitIsFeignDeath("player"); end,
        option = 1,
    },
    { -- 3
        name = L["Casting"],
        func = function()
            if ( UnitCastingInfo("player") ) then return 1; end
            if ( UnitChannelInfo("player") ) then return 1; end
            return nil;
        end,
        option = 1,
    },
    { -- 4
        --name = L["Dead"],
        func = function() return UnitIsDeadOrGhost("player"); end,
        option = nil,
    },
    { -- 5
        name = L["Combat"],
        func = function() return InCombatLockdown(); end,
        option = 1,
    },
    { -- 6
        name = L["Looting"],
        func = function()
            if ( GetNumLootItems() > 0 ) then
                return 1;
            end
            return nil;
        end,
        option = 1,
    },
    { -- 7
        name = L["Vehicle"],
        func = function() return UnitHasVehicleUI("player"); end,
        option = 1,
    },
    { -- 8
        --name = L["Fly path"],
        func = function() return UnitOnTaxi("player"); end,
        option = nil,
    },
    { -- 9
        name = L["Regen"],
        func = function() return A:HasRegenBuff(); end,
        option = 1,
    },
    {
        name = L["Indoor"],
        func = function() return IsIndoors(); end,
        option = 1,
    },
};

-- Favorites set
A.currentPetsSet = {};
A.currentMountsSet =
{
    [1] = {}, -- Ground
    [2] = {}, -- Fly
    [3] = {}, -- Hybrid (ground & fly)
    [4] = {}, -- Aquatic
    [5] = {}, -- with passengers
    [6] = {}, -- Water walking
    [7] = {}, -- Repair
};

-- A.draenorMapIDs =
-- {
    -- 962, -- Draenor
    -- 978, -- Ashran
    -- 941, -- Frostfire Ridge
    -- 976, -- Frostwall
    -- 949, -- Gorgrond
    -- 971, -- Lunarfall
    -- 950, -- Nagrand
    -- 947, -- Shadowmoon Valley
    -- 948, -- Spires of Arak
    -- 1009, -- Stormshield
    -- 946, -- Talador
    -- 945, -- Tanaan Jungle
    -- 970, -- Tanaan Jungle - Assault on the Dark Portal
    -- 1011, -- Warspear
-- }
