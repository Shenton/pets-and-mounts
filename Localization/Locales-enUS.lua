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
L["Add"] = true;
L["Add-on"] = true;
L["Alpha"] = true;
L["Alt"] = true;
L["Aquatic"] = true;
L["Author"] = true;

L["Bindings"] = true;
L["Bottom"] = true;
L["Buttons"] = true;

L["Cancel"] = true;
L["Casting"] = true;
L["Choose"] = true;
L["Close"] = true;
L["Combat"] = true;
L["Companion"] = true;
L["Companions"] = true;
L["Control"] = true;
L["Credits"] = true;
L["Current"] = true;

L["Default"] = true;
L["Debug"] = true;
L["Delete"] = true;
L["Dock"] = true;

L["Enable"] = true;
L["Expand"] = true;

L["Filters"] = true;
L["Fly"] = true;
L["Flying"] = true;

L["Ground"] = true;

L["Hide"] = true;
L["Hybrid"] = true;

L["Icon"] = true;
L["Indoor"] = true;

L["Label"] = true;
L["Left"] = true;
L["Level"] = true;
L["Levitate"] = true;
L["Licence"] = true;
L["Link"] = true;
--L["Load"] = true;
L["Lock"] = true;
L["Looting"] = true;

--L["Minimap"] = true;
L["Miscellaneous"] = true;
L["Mode"] = true;
L["Modifier"] = true;
L["Mount"] = true;
L["Mounted"] = true;
L["Mounts"] = true;

L["Name"] = true;
L["New"] = true;
L["No"] = true;
L["None"] = true;

L["Off"] = true;
L["Ok"] = true;
L["On"] = true;
L["Options"] = true;

L["Passenger"] = true;

L["Rarity"] = true;
L["Regen"] = true;
L["Release"] = true;
L["Remove"] = true;
L["Repair"] = true;
L["Reset"] = true;
L["Right"] = true;

L["Save"] = true;
L["Scale"] = true;
L["Select"] = true;
L["Separator"] = true;
L["Shift"] = true;
L["Size"] = true;
L["Stealthed"] = true
L["Summary"] = true;
L["Summon"] = true;
L["Surface"] = true;

L["Time"] = true;
L["Timers"] = true;
L["Tooltip"] = true;
L["Top"] = true;

L["Vehicle"] = true;
L["Version"] = true;

L["Yes"] = true;

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
-- Classes
L["Death Knight"] = true;
L["Druid"] = true;
L["Hunter"] = true;
L["Mage"] = true;
L["Monk"] = true;
L["Paladin"] = true;
L["Priest"] = true;
L["Rogue"] = true;
L["Shaman"] = true;
L["Warlock"] = true;
L["Warrior"] = true;
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
L["Display the minimap icon."] = true;
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
L["Companions button"] = true;
L["Mounts button"] = true;
L["Hide the companions button."] = true;
L["Lock the companions button."] = true;
L["Enable the tooltip of the companions button."] = true;
L["Set the scale of the companions button."] = true;
L["Reset the companions button position."] = true;
L["Hide the mounts button."] = true;
L["Lock the mounts button."] = true;
L["Enable the tooltip of the mounts button."] = true;
L["Set the scale of the mounts button."] = true;
L["Reset the mounts button position."] = true;
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
L["Select none"] = true;
L["Mass actions"] = true;
L["Select all"] = true;
L["Select all by category"] = true;
L["Select none by category"] = true;
L["Added %d entries."] = true;
L["Added %d entry."] = true;
L["Select all: %s"] = true;
L["Select none: %s"] = true;
L["Removed %d entries."] = true;
L["Removed %d entry."] = true;
L["Areas in use"] = true;
L["List of the areas you are currently using:"] = true;
L["With this enabled, the add-on will summon another pet after a defined time. See next option to define the time.\n\nThis will override the \"Not with a companion\" option."] = true;
L["Define re-summon time."] = true;
L["Re-Summon"] = true;
L["30s"] = true;
L["10m"] = true;
L["30m"] = true;
L["1h"] = true;
L["1h30m"] = true;
L["2h"] = true;
L["3h"] = true;
L["5h"] = true;
L["Enable class specific mount button options."] = true;
L["Prefer Aspect of the Pack"] = true;
L["Prioritise Aspect of the Pack other Aspect of the Cheetah."] = true;
L["Use a modifier"] = true;
L["Use a modifier to disable the aspect, this will also prevent the spell toggle.\n Be aware that if a bind is set to the modifier plus the button bind this will not work."] = true;
L["Select which modifier to use for switching to Aspect of the Cheetah/Pack.\n Be aware that if a bind is set to the modifier plus the button bind this will not work."] = true;
L["Data Broker"] = true;
L["Select the main icon mode. None will use the default one or the one you selected. Companion will use your current companion one. Mount will use your current mount one."] = true;
L["Select the Data Broker main icon. This also set the minimap icon."] = true;
L["Select Icon"] = true;
L["Found %d icon"] = true;
L["Found %d icons"] = true;
L["Current: %s"] = true;
L["Selected: %s"] = true;
L["Minimap icon"] = true;
L["Define the separator between current companion and mount."] = true;
L["Add the current companion icon before the name."] = true;
L["Add the current mount icon before the name."] = true;
L["Enable the main icon."] = true;
L["Display the label. Which is: %s"] = true;
L["Main icon"] = true;
L["The main icon and the label should be disabled within your Data Broker display options. If you are not given the choice to disable both of them, you should consider using another Data Broker display.\n\nThose two options are here just in case. If it mess things up /reload is your friend.\n\n"] = true;
L["Text options"] = true;
L["Companion name"] = true;
L["Enable the current companion name on the Data Broker display."] = true;
L["Companion icon"] = true;
L["Mount name"] = true;
L["Enable the current mount name on the Data Broker display."] = true;
L["Mount icon"] = true;
L["Select the companion button main icon."] = true;
L["Use current"] = true;
L["The companion button will use the current summoned companion icon."] = true;
L["Select the mount button main icon."] = true;
L["The mount button will use the current summoned mount icon."] = true;
L["Prefer Unholy Presence"] = true;
L["Prioritise Unholy Presence other Death's Advance. If Death's Advance is not selected and this option either, it will still use Unholy Presence."] = true;
L["Slow Fall"] = true;
L["Use Slow Fall when falling. IMPORTANT: This will not work when in combat, this is why there is an option to disable it."] = true;
L["Prefer Flying Serpent Kick"] = true;
L["Prioritise Flying Serpent Kick other Roll."] = true;
L["Hide other classes"] = true;
L["Only show options for your current class."] = true;
L["Prefer Blink"] = true;
L["Prioritise Blink other Blazing Speed. If Blazing Speed is not selected and this option either, it will still use Blink."] = true;
L["Force Slow Fall"] = true;
L["Force Slow Fall when in combat. This will obviously make Blazing Speed or Blink unavailable in combat."] = true;
L["For Death Knights it handles Death's Advance and Unholy Presence when moving."] = true;
L["For Druids it handles aquatic, travel and both flight forms."] = true;
L["For Hunters it handles Aspect of the Cheetah/Pack when moving. In combat you have to use a modifier to switch of Aspect of the Cheetah/Pack."] = true;
L["For Mages it handles Blazing Speed and Blink when moving. Slow Fall when falling."] = true;
L["For Paladins it handles Speed of Light when moving."] = true;
L["For Priests it handles Body and Soul and Angelic Feather when moving."] = true;
L["For Rogues it handles Sprint when moving."] = true;
L["For Shamans it handles Ghost Wolf when moving."] = true;
L["For Monks it handles Flying Serpent Kick and Roll when moving. Zen Flight when falling."] = true;
L["Select which modifier to use for cancelling Zen Flight."] = true;
L["For Warlocks it handles Burning Rush and Demonic Circle: Teleport when moving."] = true;
L["Out of combat: standing still will summon a random mount, moving will cast a spell for you class.\nIn combat: if you are mounted it will dismount you first, then it will cast a spell for your class, moving or not."] = true;
L["Prefer Teleport"] = true;
L["Prioritise Demonic Circle: Teleport other Burning Rush. If Burning Rush is not selected and this option either, it will still use Demonic Circle: Teleport."] = true;
L["Use a modifier to disable Burning Rush, this will also prevent the spell toggle.\n Be aware that if a bind is set to the modifier plus the button bind this will not work."] = true;
L["Select which modifier to use for cancelling Burning Rush."] = true;
L["For Warriors it handles Heroic Leap when moving and out of combat. Charge with a hostile target and Intervene with a friendly target when in combat."] = true;
L["Force Heroic Leap"] = true;
L["This will force Heroic Leap when in combat."] = true;
L["A word"] = true;
L["Custom macros"] = true;
L["Enable the mount button/bind custom macros."] = true;
L["Macro: %s"] = true;
L["LUA mode"] = true;
L["Use LUA code instead of macro syntax."] = true;
L["Pre Click"] = true;
L["Expand the text editor."] = true;
L["Post Click"] = true;
L["Prepend default icon"] = true;
L["Prepend the default icon when you have no companion or mount."] = true;
L["Forms on move"] = true;
L["Instead of just using forms, this will only use forms when moving and regular mounts when standing still. This is only affecting out of combat macro."] = true;
L["Macro protection"] = true;
L["LUA protection"] = true;
L["Enable the anti grief/scam protection. This a basic protection, the best one is still your brain."] = true;
L["Icon size"] = true;
L["Select the text icon size."] = true;
L["Icon vertical offset"] = true;
L["Select the text icon vertical offset."] = true;
L["Use Levitate when falling. IMPORTANT: This will not work when in combat, this is why there is an option to disable it."] = true;
L["Force Levitate"] = true;
L["Force Levitate when in combat. This will obviously make Body and Soul or Angelic Feather unavailable in combat."] = true;
L["No mount after cancel form"] = true;
L["This will prevent summoning a mount after cancelling a form. Works for Druids and Shamans."] = true;
L["Prefer higher level"] = true;
L["If you got more than one single pet, this will add only the one with the highest level."] = true;
L["Prefer higher rarity"] = true;
L["If you got more than one single pet, this will add only the one with the highest rarity."] = true;
L["Level/Rarity mode"] = true;
L["Select which filter should gain the upper hand. This only works when both filters are selected."] = true;
L["Rarity and level"] = true;
L["Add companions rarity and level to their names."] = true;
L["Companion rarity"] = true;
L["Set the text colour to the pet rarity."] = true;
L["Companion level"] = true;
L["Add the current companion level after the name."] = true;
L["Anglers Fishing Raft"] = true;
L["Summon the Anglers Fishing Raft when at the water surface and equipped with a fishing pole."] = true;
--L["Flying pet with flying mount."] = true;
L["Oculus drakes"] = true;
L["Summon one of the Oculus drakes if it is in your bags and you are in the instance."] = true;
L["Companions in sets"] = true;
L["List of the companions in the selected sets:"] = true;
L["Mounts in sets"] = true;
L["List of the mounts in the selected sets:"] = true;
L["Set here the default set or sets. This will be used when no set of sets is defined for an area or if area sets are disabled.\n\nIf nothing is defined here the add-on will search for a set named Default and use it.\n\n"] = true;
L["Default sets"] = true;
L["Delete old data"] = true;
L["This will delete the old data. Freeing space and hiding the Import category.\n\nThere is no confirmation, after clicking the button it is gone.\n\n"] = true;
L["Hybrids Options"] = true;
L["Hybrids Selection"] = true;
L["Enable the hybrids selection tab.\n\nFor the changes to take effect, this option need to be disabled. A /reload will also works."] = true;
L["Only owned"] = true;
L["This will display only the mounts you own within the list. Otherwise it will display all the mounts available in the game."] = true;
L["Editing set: %s"] = true;
L["Active: %s"] = true;
-- About
L["Auto and random summon for your pets and mounts, highly customizable. With Data Broker support."] = true;
L["A new version is available, version |cff33ff99%s|r revision |cff33ff99%s %s|r."] = true;
L["You are running Pets & Mounts version %s revision %s %s."] = true;
L["Web site"] = true;
L["New version"] = true;
-- Import
L["Import"] = true;
L["Old companions sets names"] = true;
L["This will import the companions sets names to the new system as empty sets.\n\nRemember that companions unique identifiers changed with 6.0, so the name is the only thing that can be saved.\n\n"] = true;
L["Added %s set name."] = true;
L["%s set name already exists."] = true;
L["Create Sets"] = true;
L["Set %s do not exists."] = true;
L["Set %s is not empty."] = true;
L["Added data to %s set."] = true;
L["Add data"] = true;
L["Global mounts favorites"] = true;
L["This will import the global mounts favorites to a set named OldGlobal.\n\nRemember that Hybrid category is no more automatic, those mounts will be copied to the Flying one.\n\n"] = true;
L["Global mounts sets"] = true;
L["This will import the mounts sets to the new system.\n\nRemember that Hybrid category is no more automatic, those mounts will be copied to the Flying one.\n\n"] = true;
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
L["Cannot modify buttons anchors when they are not docked."] = true;
L["Your LUA custom %s macro for %s got an error. Error: %s"] = true;
-- Popup messages
L["The bindings system have been entirely redone.\n\nThe add-on tried to update them, but just in case you should check if everything is in place.\n\nDo you want to open the configuration panel?"] = true;
L["|cffff3333Anti grief/scam protection triggered, you should be careful.|r\n\nMessage: |cffff3333%s|r was found in your %s %s custom macro.\n\n|cff33ff99This macro was not used.|r\n\nYou can disable the protection within the configuration panel."] = true;
L["|cffff3333Anti grief/scam protection triggered, you should be careful.|r\n\nMessage: |cffff3333%s|r was found in your %s %s custom LUA.\n\n|cff33ff99This code was not used.|r\n\nYou can disable the protection within the configuration panel."] = true
L["New filters added for companions, rarity and level.\n\nThey are enabled by default and could have modified your companions list both in configuration panel and Data Broker menu.\n\nIt did not alter you sets or favorites, but you could want to modify them to use your highest level and rarity companions.\n\nTips: You can disable the \"Filter multiple\" option to see all your companions. Rarity and level are displayed next to their names in the list."] = true;
L["WoD (6.02) modified a lot both companions and mounts APIs.\n\nCheck the add-on page on Curse for some explanations on those changes. The link can be found in the About section of the configuration panel.\n\nDo you want to open the configuration panel?"] = true;
-- Specials
L["CUSTOM_MACROS_EXLANATIONS"] = [[|cff3399ffIf you cannot scroll the page down select a category on the left menu and return back.|r

|cff9d9d9d-----------------------------------------------------------|r

|cffff3333If you are here you need to know what you are doing.|r

You cannot revert any changes made here, but you can disable custom macros and it will use the built in system.

|cff9d9d9d-----------------------------------------------------------|r

|cffff3333If you import someone else code, be sure to have a total trust in him/her. Do not come and blame me if you get griefed.|r

|cff9d9d9d-----------------------------------------------------------|r

First, a look at how secure buttons works.

When clicked (or using a bind), a preclick function is called which set a macro to the button, then this macro is executed, after that a postclick function is called which also set the button macro. Yes, this all happen in one click.

This cannot be done in combat, this is why we set the macro we want in combat with the postclick one.

If pre or post are left blank it will use the built in system.

Custom macros have two modes, classic macros syntax and lua.

|cff9d9d9d-----------------------------------------------------------|r

Classic macros are what they are named after, you can find help with commands and conditions all other the internet.

Here is some commands provided by the addon:
/pampet - Summon a random pet
/pammout - Summon a random mount
/pamground - Summon a random ground mount
/pamfly - Summon a random flying mount
/pamhybrid - Summon a random hybrid mount
/pamaquatic - Summon a random aquatic mount
/pampassengers - Summon a random passengers mount
/pamsurface - Summon a random surface mount
/pamrepair - Summon a random repair mount

Those are just commands, they do not interact with macros conditionals.

|cff9d9d9d----------------------------------------------------------|r

lua mode is again what it is named after.

If you use this mode I assume you really know what you are doing.

The code will be turned into a function. The preclick code will be launched every time when out of combat. The postclick one will be called only once, on login, when changing related options or when editing the code.

And a last, it should always return a macro string.
]];
end
