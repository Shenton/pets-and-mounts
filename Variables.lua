--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Variables.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- AddOn version
A.version = GetAddOnMetadata("PetsAndMounts", "Version");

-- Text colors
A.color =
{
    RED = "|cffff3333",
    GREEN = "|cff33ff99",
    BLUE = "|cff3399ff",
    WHITE = "|cffffffff",
    RESET = "|r",
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
    L["Surface"]
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

-- Mounts with another bitfield than the aquatic ones
-- this will force them to aquatics
A.aquaticMounts =
{
    64731, -- Sea Turtle
};

-- Those companions will not be auto summoned
A.bannedPets =
{
    15705, -- Winter's Little Helper
    15698, -- Father Winter's Helper
};

-- Mounts listed here can only be summoned in a specific area
A.uniqueAreaMounts =
{
    [1] = -- Ground
    {
        [766] = -- Qiraji Battle Tanks in Temple of Ahn'Qiraj
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
        [614] = 75207, -- Abyssal Depths
        [610] = 75207, -- Kelp'thar Forest
        [615] = 75207, -- Shimmering Expanse
        [613] = 75207, -- Vashj'ir
    },
    [5] = {}, -- with passengers
    [6] = {}, -- Surface
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
    party = L["Party instance"], -- An instance for 5-man groups
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

-- Mount with restriction, location, spell, faction, etc
A.restrictedMounts =
{
    -- Location specific mount
    [25953] = -- Blue Qiraji Battle Tank
    {
        type = "location",
        args = 766,
    },
    [26056] = -- Green Qiraji Battle Tank
    {
        type = "location",
        args = 766,
    },
    [26054] = -- Red Qiraji Battle Tank
    {
        type = "location",
        args = 766,
    },
    [26055] = -- Yellow Qiraji Battle Tank
    {
        type = "location",
        args = 766,
    },
    [75207] = -- Abyssal Seahorse
    {
        type = "location",
        args = {614, 610, 615, 613},
    },
    -- Spell needed mounts
    [127170] = -- Astral Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [123992] = -- Azure Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [127156] = -- Crimson Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [123993] = -- Golden Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [127169] = -- Heavenly Azure Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [127161] = -- Heavenly Crimson Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [127164] = -- Heavenly Golden Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [127165] = -- Heavenly Jade Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [127158] = -- Heavenly Onyx Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [113199] = -- Jade Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [127154] = -- Onyx Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [129918] = -- Thundering August Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [139442] = -- Thundering Cobalt Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [124408] = -- Thundering Jade Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [148476] = -- Thundering Onyx Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    [132036] = -- Thundering Ruby Cloud Serpent
    {
        type = "spell",
        args = 130487,
    },
    -- Class mounts
    -- WARRIOR PALADIN HUNTER ROGUE PRIEST DEATHKNIGHT SHAMAN MAGE WARLOCK MONK DRUID
    [48778] = -- Acherus Deathcharger
    {
        type = "class",
        args = "DEATHKNIGHT",
    },
    [54729] = -- Winged Steed of the Ebon Blade
    {
        type = "class",
        args = "DEATHKNIGHT",
    },
    [66906] = -- Argent Charger
    {
        type = "class",
        args = "PALADIN",
    },
    [66907] = -- Argent Warhorse
    {
        type = "class",
        args = "PALADIN",
    },
    [23161] = -- Dreadsteed
    {
        type = "class",
        args = "WARLOCK",
    },
    [5784] = -- Felsteed
    {
        type = "class",
        args = "WARLOCK",
    },
    -- Race mounts
    -- Dwarf Draenei Gnome Human NightElf Worgen BloodElf Goblin Orc Tauren Troll Scourge Pandaren
    -- Race + class mounts (aka, damn paladins)
    [23214] = -- Summon Charger
    {
        type = "race&class",
        args = {"HumanPALADIN", "DwarfPALADIN"},
    },
    [13819] = -- Summon Warhorse
    {
        type = "race&class",
        args = {"HumanPALADIN", "DwarfPALADIN"},
    },
    [73629] = -- Summon Exarch's Elekk
    {
        type = "race&class",
        args = "DraeneiPALADIN",
    },
    [73630] = -- Summon Great Exarch's Elekk
    {
        type = "race&class",
        args = "DraeneiPALADIN",
    },
    [69826] = -- Summon Great Sunwalker Kodo
    {
        type = "race&class",
        args = "TaurenPALADIN",
    },
    [69820] = -- Summon Sunwalker Kodo
    {
        type = "race&class",
        args = "TaurenPALADIN",
    },
    [34767] = -- Summon Thalassian Charger
    {
        type = "race&class",
        args = "BloodElfPALADIN",
    },
    [34769] = -- Summon Thalassian Warhorse
    {
        type = "race&class",
        args = "BloodElfPALADIN",
    },
    -- Faction mounts
    -- Alliance Horde
    --
    -- Alliance mounts
    -- Human's mounts
    [470] = -- Black Stallion
    {
        type = "faction",
        args = "Alliance",
    },
    [458] = -- Brown Horse
    {
        type = "faction",
        args = "Alliance",
    },
    [6648] = -- Chestnut Mare
    {
        type = "faction",
        args = "Alliance",
    },
    [472] = -- Pinto
    {
        type = "faction",
        args = "Alliance",
    },
    [23229] = -- Swift Brown Steed
    {
        type = "faction",
        args = "Alliance",
    },
    [23227] = -- Swift Palomino
    {
        type = "faction",
        args = "Alliance",
    },
    [23228] = -- Swift White Steed
    {
        type = "faction",
        args = "Alliance",
    },
    -- Draenei's mounts
    [34406] = -- Brown Elekk
    {
        type = "faction",
        args = "Alliance",
    },
    [35710] = -- Gray Elekk
    {
        type = "faction",
        args = "Alliance",
    },
    [35711] = -- Purple Elekk
    {
        type = "faction",
        args = "Alliance",
    },
    [35713] = -- Great Blue Elekk
    {
        type = "faction",
        args = "Alliance",
    },
    [35712] = -- Great Green Elekk
    {
        type = "faction",
        args = "Alliance",
    },
    [35714] = -- Great Purple Elekk
    {
        type = "faction",
        args = "Alliance",
    },
    -- Dwarf's mounts
    [6899] = -- Brown Ram
    {
        type = "faction",
        args = "Alliance",
    },
    [6777] = -- Gray Ram
    {
        type = "faction",
        args = "Alliance",
    },
    [6898] = -- White Ram
    {
        type = "faction",
        args = "Alliance",
    },
    [23238] = -- Swift Brown Ram
    {
        type = "faction",
        args = "Alliance",
    },
    [23239] = -- Swift Gray Ram
    {
        type = "faction",
        args = "Alliance",
    },
    [23240] = -- Swift White Ram
    {
        type = "faction",
        args = "Alliance",
    },
    -- Gnome's mounts
    [10969] = -- Blue Mechanostrider
    {
        type = "faction",
        args = "Alliance",
    },
    [17453] = -- Green Mechanostrider
    {
        type = "faction",
        args = "Alliance",
    },
    [10873] = -- Red Mechanostrider
    {
        type = "faction",
        args = "Alliance",
    },
    [17454] = -- Unpainted Mechanostrider
    {
        type = "faction",
        args = "Alliance",
    },
    [23225] = -- Swift Green Mechanostrider
    {
        type = "faction",
        args = "Alliance",
    },
    [23223] = -- Swift White Mechanostrider
    {
        type = "faction",
        args = "Alliance",
    },
    [23222] = -- Swift Yellow Mechanostrider
    {
        type = "faction",
        args = "Alliance",
    },
    -- Night elf's mounts
    [10789] = -- Spotted Frostsaber
    {
        type = "faction",
        args = "Alliance",
    },
    [66847] = -- Striped Dawnsaber
    {
        type = "faction",
        args = "Alliance",
    },
    [8394] = -- Striped Frostsaber
    {
        type = "faction",
        args = "Alliance",
    },
    [10793] = -- Striped Nightsaber
    {
        type = "faction",
        args = "Alliance",
    },
    [23221] = -- Swift Frostsaber
    {
        type = "faction",
        args = "Alliance",
    },
    [23219] = -- Swift Mistsaber
    {
        type = "faction",
        args = "Alliance",
    },
    [23338] = -- Swift Stormsaber
    {
        type = "faction",
        args = "Alliance",
    },
    -- Worgen's mounts
    [103195] = -- Mountain Horse
    {
        type = "faction",
        args = "Alliance",
    },
    [103196] = -- Swift Mountain Horse
    {
        type = "faction",
        args = "Alliance",
    },
    -- Gryphons
    [32239] = -- Ebon Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    [32235] = -- Golden Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    [32240] = -- Snowy Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    [61229] = -- Armored Snowy Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    [32242] = -- Swift Blue Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    [32290] = -- Swift Green Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    [32292] = -- Swift Purple Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    [32289] = -- Swift Red Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    -- PvP alliance mounts
    [22719] = -- Black Battlestrider
    {
        type = "faction",
        args = "Alliance",
    },
    [22723] = -- Black War Tiger
    {
        type = "faction",
        args = "Alliance",
    },
    [22720] = -- Black War Ram
    {
        type = "faction",
        args = "Alliance",
    },
    [23510] = -- Stormpike Battle Charger
    {
        type = "faction",
        args = "Alliance",
    },
    [48027] = -- Black War Elekk
    {
        type = "faction",
        args = "Alliance",
    },
    [22717] = -- Black War Steed
    {
        type = "faction",
        args = "Alliance",
    },
    -- Argent tournament alliance
    [65638] = -- Swift Moonsaber
    {
        type = "faction",
        args = "Alliance",
    },
    [65637] = -- Great Red Elekk
    {
        type = "faction",
        args = "Alliance",
    },
    [65640] = -- Swift Gray Steed
    {
        type = "faction",
        args = "Alliance",
    },
    [65642] = -- Turbostrider
    {
        type = "faction",
        args = "Alliance",
    },
    [65643] = -- Swift Violet Ram
    {
        type = "faction",
        args = "Alliance",
    },
    [63637] = -- Darnassian Nightsaber
    {
        type = "faction",
        args = "Alliance",
    },
    [63639] = -- Exodar Elekk
    {
        type = "faction",
        args = "Alliance",
    },
    [66090] = -- Quel'dorei Steed
    {
        type = "faction",
        args = "Alliance",
    },
    [63232] = -- Stormwind Steed
    {
        type = "faction",
        args = "Alliance",
    },
    [63638] = -- Gnomeregan Mechanostrider
    {
        type = "faction",
        args = "Alliance",
    },
    [63636] = -- Ironforge Ram
    {
        type = "faction",
        args = "Alliance",
    },
    [66087] = -- Silver Covenant Hippogryph
    {
        type = "faction",
        args = "Alliance",
    },
    -- Others alliance specific mounts
    [60424] = -- Mekgineer's Chopper
    {
        type = "faction",
        args = "Alliance",
    },
    [61465] = -- Grand Black War Mammoth (Alliance)
    {
        type = "faction",
        args = "Alliance",
    },
    [61470] = -- Grand Ice Mammoth (Alliance)
    {
        type = "faction",
        args = "Alliance",
    },
    [61425] = -- Traveler's Tundra Mammoth (Alliance)
    {
        type = "faction",
        args = "Alliance",
    },
    [60114] = -- Armored Brown Bear (Alliance)
    {
        type = "faction",
        args = "Alliance",
    },
    [60118] = -- Black War Bear (Alliance)
    {
        type = "faction",
        args = "Alliance",
    },
    [68057] = -- Swift Alliance Steed
    {
        type = "faction",
        args = "Alliance",
    },
    [92231] = -- Spectral Steed
    {
        type = "faction",
        args = "Alliance",
    },
    [59791] = -- Wooly Mammoth (Alliance)
    {
        type = "faction",
        args = "Alliance",
    },
    [59799] = -- Ice Mammoth (Alliance)
    {
        type = "faction",
        args = "Alliance",
    },
    [135416] = -- Grand Armored Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    [136163] = -- Grand Gryphon
    {
        type = "faction",
        args = "Alliance",
    },
    [90621] = -- Golden King
    {
        type = "faction",
        args = "Alliance",
    },
    [142478] = -- Armored Blue Dragonhawk
    {
        type = "faction",
        args = "Alliance",
    },
    [61996] = -- Blue Dragonhawk
    {
        type = "faction",
        args = "Alliance",
    },
    [130985] = -- Pandaren Kite (Alliance)
    {
        type = "faction",
        args = "Alliance",
    },
    --
    -- Horde mounts
    -- Orc's mounts
    [64658] = -- Black Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [6654] = -- Brown Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [6653] = -- Dire Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [580] = -- Timber Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [23250] = -- Swift Brown Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [23252] = -- Swift Gray Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [23251] = -- Swift Timber Wolf
    {
        type = "faction",
        args = "Horde",
    },
    -- Blood elf's mounts
    [35022] = -- Black Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    [35020] = -- Blue Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    [35018] = -- Purple Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    [34795] = -- Red Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    [35025] = -- Swift Green Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    [33660] = -- Swift Pink Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    [35027] = -- Swift Purple Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    -- Goblin's mounts
    [87090] = -- Goblin Trike
    {
        type = "faction",
        args = "Horde",
    },
    [87091] = -- Goblin Turbo-Trike
    {
        type = "faction",
        args = "Horde",
    },
    -- Tauren's mounts
    [18990] = -- Brown Kodo
    {
        type = "faction",
        args = "Horde",
    },
    [18989] = -- Gray Kodo
    {
        type = "faction",
        args = "Horde",
    },
    [64657] = -- White Kodo
    {
        type = "faction",
        args = "Horde",
    },
    [23249] = -- Great Brown Kodo
    {
        type = "faction",
        args = "Horde",
    },
    [23248] = -- Great Gray Kodo
    {
        type = "faction",
        args = "Horde",
    },
    [23247] = -- Great White Kodo
    {
        type = "faction",
        args = "Horde",
    },
    -- Troll's mounts
    [8395] = -- Emerald Raptor
    {
        type = "faction",
        args = "Horde",
    },
    [10796] = -- Turquoise Raptor
    {
        type = "faction",
        args = "Horde",
    },
    [10799] = -- Violet Raptor
    {
        type = "faction",
        args = "Horde",
    },
    [23241] = -- Swift Blue Raptor
    {
        type = "faction",
        args = "Horde",
    },
    [23242] = -- Swift Olive Raptor
    {
        type = "faction",
        args = "Horde",
    },
    [23243] = -- Swift Orange Raptor
    {
        type = "faction",
        args = "Horde",
    },
    -- Undead's mounts
    [64977] = -- Black Skeletal Horse
    {
        type = "faction",
        args = "Horde",
    },
    [17463] = -- Blue Skeletal Horse
    {
        type = "faction",
        args = "Horde",
    },
    [17464] = -- Brown Skeletal Horse
    {
        type = "faction",
        args = "Horde",
    },
    [17462] = -- Red Skeletal Horse
    {
        type = "faction",
        args = "Horde",
    },
    [17465] = -- Green Skeletal Warhorse
    {
        type = "faction",
        args = "Horde",
    },
    [66846] = -- Ochre Skeletal Warhorse
    {
        type = "faction",
        args = "Horde",
    },
    [23246] = -- Purple Skeletal Warhorse
    {
        type = "faction",
        args = "Horde",
    },
    -- Wyverns
    [32244] = -- Blue Wind Rider
    {
        type = "faction",
        args = "Horde",
    },
    [32245] = -- Green Wind Rider
    {
        type = "faction",
        args = "Horde",
    },
    [32243] = -- Tawny Wind Rider
    {
        type = "faction",
        args = "Horde",
    },
    [61230] = -- Armored Blue Wind Rider
    {
        type = "faction",
        args = "Horde",
    },
    [32295] = -- Swift Green Wind Rider
    {
        type = "faction",
        args = "Horde",
    },
    [32297] = -- Swift Purple Wind Rider
    {
        type = "faction",
        args = "Horde",
    },
    [32246] = -- Swift Red Wind Rider
    {
        type = "faction",
        args = "Horde",
    },
    [32296] = -- Swift Yellow Wind Rider
    {
        type = "faction",
        args = "Horde",
    },
    -- PvP horde mounts
    [35028] = -- Swift Warstrider
    {
        type = "faction",
        args = "Horde",
    },
    [22718] = -- Black War Kodo
    {
        type = "faction",
        args = "Horde",
    },
    [22724] = -- Black War Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [23509] = -- Frostwolf Howler
    {
        type = "faction",
        args = "Horde",
    },
    [22721] = -- Black War Raptor
    {
        type = "faction",
        args = "Horde",
    },
    [22722] = -- Red Skeletal Warhorse
    {
        type = "faction",
        args = "Horde",
    },
    -- Argent tournament horde
    [65639] = -- Swift Red Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    [65641] = -- Great Golden Kodo
    {
        type = "faction",
        args = "Horde",
    },
    [65644] = -- Swift Purple Raptor
    {
        type = "faction",
        args = "Horde",
    },
    [65645] = -- White Skeletal Warhorse
    {
        type = "faction",
        args = "Horde",
    },
    [65646] = -- Swift Burgundy Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [63642] = -- Silvermoon Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    [66091] = -- Sunreaver Hawkstrider
    {
        type = "faction",
        args = "Horde",
    },
    [63641] = -- Thunder Bluff Kodo
    {
        type = "faction",
        args = "Horde",
    },
    [63635] = -- Darkspear Raptor
    {
        type = "faction",
        args = "Horde",
    },
    [63643] = -- Forsaken Warhorse
    {
        type = "faction",
        args = "Horde",
    },
    [63640] = -- Orgrimmar Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [66088] = -- Sunreaver Dragonhawk
    {
        type = "faction",
        args = "Horde",
    },
    -- Others horde specific mounts
    [92232] = -- Spectral Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [60116] = -- Armored Brown Bear (Horde)
    {
        type = "faction",
        args = "Horde",
    },
    [61467] = -- Grand Black War Mammoth (Horde)
    {
        type = "faction",
        args = "Horde",
    },
    [61469] = -- Grand Ice Mammoth (Horde)
    {
        type = "faction",
        args = "Horde",
    },
    [61447] = -- Traveler's Tundra Mammoth (Horde)
    {
        type = "faction",
        args = "Horde",
    },
    [55531] = -- Mechano-Hog
    {
        type = "faction",
        args = "Horde",
    },
    [68056] = -- Swift Horde Wolf
    {
        type = "faction",
        args = "Horde",
    },
    [59793] = -- Wooly Mammoth (Horde)
    {
        type = "faction",
        args = "Horde",
    },
    [59797] = -- Ice Mammoth (Horde)
    {
        type = "faction",
        args = "Horde",
    },
    [135418] = -- Grand Armored Wyvern
    {
        type = "faction",
        args = "Horde",
    },
    [136164] = -- Grand Wyvern
    {
        type = "faction",
        args = "Horde",
    },
    [93644] = -- Kor'kron Annihilator
    {
        type = "faction",
        args = "Horde",
    },
    [60119] = -- Black War Bear (Horde)
    {
        type = "faction",
        args = "Horde",
    },
    [142266] = -- Armored Red Dragonhawk
    {
        type = "faction",
        args = "Horde",
    },
    [61997] = -- Red Dragonhawk
    {
        type = "faction",
        args = "Horde",
    },
    [118737] = -- Pandaren Kite (Horde)
    {
        type = "faction",
        args = "Horde",
    },
};