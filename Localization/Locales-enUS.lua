--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Localization-enUS.lua
-------------------------------------------------------------------------------]]--

local L = LibStub("AceLocale-3.0"):NewLocale("PetsAndMounts", "enUS", true);

if L then
-- Addon name
L["Pets & Mounts"] = true;
-- Words
L["About"] = true;
L["Accept"] = true;
L["Add-on"] = true;
L["Alpha"] = true;
L["Aquatic"] = true;
L["Author"] = true;

L["Bindings"] = true;
L["Bottom"] = true;

L["Cancel"] = true;
L["Casting"] = true;
L["Choose"] = true;
L["Close"] = true;
L["Combat"] = true;
L["Companions"] = true;
L["Credits"] = true;
L["Current"] = true;

L["Debug"] = true;
L["Delete"] = true;
L["Dock"] = true;

L["Enable"] = true;

L["Filters"] = true;
L["Fly"] = true;
L["Flying"] = true;

L["Ground"] = true;

L["Hide"] = true;
L["Hybrid"] = true;

L["Indoor"] = true;

L["Left"] = true;
L["Licence"] = true;
--L["Load"] = true;
L["Lock"] = true;
L["Looting"] = true;

L["Minimap"] = true;
L["Miscellaneous"] = true;
L["Mounted"] = true;
L["Mounts"] = true;

L["Name"] = true;
L["New"] = true;
L["None"] = true;

L["Off"] = true;
L["On"] = true;
L["Options"] = true;

L["Passenger"] = true;

L["Regen"] = true;
L["Release"] = true;
L["Repair"] = true;
L["Reset"] = true;
L["Right"] = true;

L["Save"] = true;
L["Scale"] = true;
L["Select"] = true;
L["Size"] = true;
L["Stealthed"] = true
L["Summon"] = true;
L["Surface"] = true;

L["Timers"] = true;
L["Tooltip"] = true;
L["Top"] = true;

L["Vehicle"] = true;
L["Version"] = true;

-- Pet types
L["Humanoid"] = true;
L["Dragonkin"] = true;
L["Flying"] = true;
L["Undead"] = true;
L["Critter"] = true;
L["Magic"] = true;
L["Elemental"] = true;
L["Beast"] = true;
L["Aquatic"] = true;
L["Mechanical"] = true;
-- Config
L["Model rotation"] = true;
L["Auto summon"] = true;
L["Auto companion options"] = true;
L["Auto summon a random companion."] = true;
L["Not with a companion"] = true;
L["Auto summon will not work if you already have a companion, or it will summon a random favorite companion."] = true;
L["Revoke when stealthed"] = true;
L["If you got a companion it will dismiss it when going stealthed."] = true;
L["Add %s to favorite."] = true;
L["Auto summon timer"] = true;
L["Select how often the addon will check if you got a companion."] = true;
L["Shift timer"] = true;
L["Select the shift timer, this is the time before summoning a random companion after reviving, porting, unstealthing, etc."] = true;
L["Filter multiple"] = true;
L["This will prevent adding to the list all the companions with same names."] = true;
L["Do not filter named companions"] = true;
L["If the companion got a custom name it will not be filtered."] = true;
L["Random mount"] = true;
L["Bind a key to summon a random mount."] = true;
L["Key one"] = true;
L["Key two"] = true;
L["Random mount options"] = true;
L["No hybrid (Ground)"] = true;
L["No hybrid (Fly)"] = true;
L["Do not summon an hybrid mount in a ground only area."] = true;
L["Do not summon an hybrid mount in a flyable area."] = true;
L["Flying dismount"] = true;
L["Using the random mount bind when flying will dismount you."] = true;
L["Random passengers mount"] = true;
L["Random flying mount"] = true;
L["Random ground mount"] = true;
L["Random aquatic mount"] = true;
L["Show icon"] = true;
L["Display an icon on the minimap."] = true;
L["Model frames"] = true;
L["Config frame"] = true;
L["Activate the model rotation in the frame."] = true;
L["Menu frame"] = true;
L["Select the model frame size."] = true;
L["Pets & Mounts config loader"] = true;
L["Load configuration"] = true;
L["Force One"] = true;
L["Companions and mounts informations updated."] = true;
L["Select the companion to force summon."] = true;
L["Select the %s mount to force summon."] = true;
L["You currently have %d selected favorites.\n\n"] = true;
L["Set %s already exists."] = true;
L["You already got a set named %s.\n\nEnter a new name or leave it blank to overwrite."] = true;
L["Database update to revision %d needed."] = true;
L["A full database update is needed."] = true;
L["Database updated to revision %d."] = true;
L["Delete set %s?"] = true;
L["A set named %s already exists, renaming it to %s."] = true;
L["Deleted set %s, due to Blizzard modification to companions code."] = true;
L["Area mounts"] = true;
L["With this enabled it will summon a specific mount according to your current area. Example: the Abyssal Seahorse in Vashj'ir."] = true;
L["Arena instance"] = true;
L["Open world"] = true;
L["Party instance"] = true;
L["Battleground instance"] = true;
L["Raid instance"] = true;
L["Scenario instance"] = true;
L["Auto companion options override"] = true;
L["Area type"] = true;
L["Select witch type of area to work with."] = true;
L["Enable auto pet options override."] = true;
L["Override options for %s"] = true;
L["Random companion"] = true;
L["Bind a key to summon a random companion."] = true;
L["Class specific"] = true;
L["With this enabled it will use flying forms for druids (Only class with specific \"mount\" atm)."] = true;
L["Buttons"] = true;
L["Companions button"] = true;
L["Mounts button"] = true;
L["Hide the companions button."] = true;
L["Lock the companions button."] = true;
L["Enable the tooltip of the companions button."] = true;
L["Set the scale of the companions button."] = true;
L["Reset the companions button configuration."] = true;
L["Hide the mounts button."] = true;
L["Lock the mounts button."] = true;
L["Enable the tooltip of the mounts button."] = true;
L["Set the scale of the mounts button."] = true;
L["Reset the mounts button configuration."] = true;
L["Dock companion button to the mount button."] = true;
L["Area override"] = true;
L["Build areas database"] = true;
L["Build the areas database, this is not needed for the addon to work, but it will know the areas without discovering them first."] = true;
L["The add-on currently knows %d areas\n\n"] = true;
L["The add-on currently knows %d area\n\n"] = true;
L["Currently working with: %s\n\n"] = true;
L["Area selection"] = true;
L["Select the area you want to work with."] = true;
L["Use this to reset the working area to the current area."] = true;
L["Haunted Memento"] = true;
L["Do not automatically summon a pet when the Haunted Memento is in your bags."] = true;
L["Database options"] = true;
L["Magic Broom"] = true;
L["Summon the Magic Broom when it is in your bags."] = true;
L["Surface mount"] = true;
L["If you are in a non flyable area and at the water surface, it will summon a mount able to walk on water. Support Death Knights Path of Frost, Shamans Water Walking and Warlocks glyph."] = true;
L["Prefer surface spell"] = true;
L["If surface mount options is enabled, it will prefer using your water walking spell other the mount. This only works for Death Knights and Shamans."] = true;
L["Random surface mount"] = true;
L["Dock anchor"] = true;
L["Select on which side of the mounts button the companions button should dock."] = true;
L["Vehicle exit"] = true;
L["If you are in a vehicle, using the random mount will make you leave the vehicle."] = true;
L["Random repair mount"] = true;
L["Companions list"] = true;
L["Mounts list"] = true;
L["Sets options"] = true;
L["Favorites override"] = true;
L["Companions auto summon filters"] = true;
L["Prevent companion auto summon when: %s"] = true;
L["Random hybrid mount"] = true;
L["Dock options"] = true;
L["Zones database"] = true;
L["Random mount summon filters"] = true;
L["Prevent mount summon when: %s"] = true;
L["Feign Death"] = true;
L["Debug is enabled. Building the areas database will reset it first."] = true;
L["Shimmering Moonstone"] = true;
L["Summon Moonfang when the Shimmering Moonstone is in your bags."] = true;
L["Companions list options"] = true;
L["Append default name"] = true;
L["When a companion got a custom name, it will append its default name."] = true;
L["Color custom name"] = true;
L["When a companion got a custom name, it will be colored."] = true;
L["Custom name color"] = true;
L["Pick a color for your companions custom names."] = true;
L["Area companions"] = true;
L["Area mounts"] = true;
L["Click behavior"] = true;
L["Shift+Click"] = true;
L["Choose which mount category to summon when using %s"] = true;
L["Special mounts"] = true;
L["Swimming options"] = true;
L["Underwater mount category"] = true;
L["Choose which mount category to summon when under water. This do not impact druid forms."] = true;
L["Copy target mount"] = true;
L["If you target someone and he/she is on a mount, it will summon it if you have it. This have priority other copy mouse hover."] = true;
L["Copy mouse hover mount"] = true;
L["If you mouse hover someone and he/she is on a mount, it will summon it if you have it. Target copy have priority other this."] = true;
L["Enable the model frame on the menu."] = true;
L["Enable the model frame on the configuration panel."] = true;
-- About
L["Auto and random summon for your pets and mounts, highly customizable. With Data Broker support."] = true;
L["A new version is available, version |cff33ff99%s|r revision |cff33ff99%s %s|r."] = true;
L["You are running Pets & Mounts version %s revision %s %s."] = true;
L["Web site"] = true;
L["New version"] = true;
-- Zones
L["Blood in the Snow"] = true;
L["Dark Heart of Pandaria"] = true;
L["Domination Point (H)"] = true;
L["Greenstone Village"] = true;
L["Lion's Landing (A)"] = true;
L["Theramore's Fall (A)"] = true;
L["Theramore's Fall (H)"] = true;
-- Dropdown menu
L["Show or hide minimap icon"] = true;
L["Model frame size"] = true;
-- Tooltip
L["Use me to move both buttons."] = true;
L["Auto summon companion is %s."] = true;
L["Not when stealthed is %s."] = true;
L["Forced companion: %s"] = true;
L["Forced aquatic mount: %s"] = true;
L["Forced ground mount: %s"] = true;
L["Forced fly mount: %s"] = true;
L["Forced hybrid mount: %s"] = true;
L["Forced passenger mount: %s"] = true;
L["Companions set in use: %s."] = true;
L["Mounts set in use: %s."] = true;
L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random companion.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Revoke current companion.\n|cFFC79C6EControl+Left-Click: |cFF33FF99Toggle button lock.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open configuration panel."] = true;
L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random mount.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Summon a %s mount.\n|cFFC79C6EControl+Left-Click: |cFF33FF99Toggle button lock.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open configuration panel."] = true;
L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random companion.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Revoke current companion.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open the configuration panel."] = true;
-- Messages
L["Cannot dock buttons together when at least one of them is hidden."] = true;
L["Tried to summon %s. It is a mount this toon cannot use (Horde/Alliance specific, achievement, level, etc)."] = true;
L["Minimap icon is hidden if you want to show it back use: /pam or /petsandmounts"] = true;
L["Failed to load configuration, reason: %s."] = true;
L["Unable to edit buttons while in combat."] = true;
L["A newer version of Pets & Mounts is available. You have version %s revision %s %s, %s got version %s revision %s %s. Get it on Curse at %s or with the Curse client."] = true;
L["New companions set %s added."] = true;
L["New mounts set %s added."] = true;
L["You have no favorite selected."] = true;
end
