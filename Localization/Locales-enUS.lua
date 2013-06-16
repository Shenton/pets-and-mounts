-- ********************************************************************************
-- Broker Pets & Mounts
-- Data Broker display for easy acces to pets and mounts.
-- By: Shenton
--
-- Localization-enUS.lua
-- ********************************************************************************

local L = LibStub("AceLocale-3.0"):NewLocale("BrokerPAM", "enUS", true);

if L then
L["Pets & Mounts"] = true;
L["Companions"] = true;
L["Mounts"] = true;
L["Options"] = true;
L["Close"] = true;
L["Filters"] = true;
L["Binding"] = true;
L["Timers"] = true;
L["Ground"] = true;
L["Fly"] = true;
L["Hybrid"] = true;
L["Aquatic"] = true;
L["Passenger"] = true;
L["Debug"] = true;
L["Summon"] = true;
L["Size"] = true;
L["None"] = true;
L["Sets"] = true;
L["Current"] = true;
L["Load"] = true;
L["Save"] = true;
L["Name"] = true;
L["Accept"] = true;
L["Cancel"] = true;
L["Delete"] = true;
L["Choose"] = true;
L["Show or hide minimap icon"] = true;
L["Model rotation"] = true;
L["Model frame size"] = true;
L["Auto summon"] = true;
L["Auto pet options"] = true;
L["Auto summon a random companion."] = true;
L["Not with a companion"] = true;
L["Auto summon will not work if you already have a companion, or it will summon a random favorite companion."] = true;
L["Not when stealthed"] = true;
L["If you got a companion it will dismiss it when going stealthed."] = true;
L["Add %s to favorite."] = true;
L["Auto summon timer"] = true;
L["Select how often the addon will check if you got a companion."] = true;
L["Shift timer"] = true
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
L["No hybrid"] = true;
L["Do not summon an hybrid mount in a ground only area."] = true;
L["Flying dismount"] = true;
L["Using the random mount bind when flying will dismount you."] = true;
L["Random passengers mount"] = true;
L["Random flying mount"] = true;
L["Random ground mount"] = true;
L["Random aquatic mount"] = true;
L["Minimap"] = true;
L["Show icon"] = true;
L["Display an icon on the minimap."] = true;
L["Model frames"] = true;
L["Config frame"] = true;
L["Activate the model rotation in the frame."] = true;
L["Menu frame"] = true;
L["Select the model frame size."] = true;
L["Pets & Mounts config loader"] = true;
L["Failed to load configuration, reason: %s."] = true;
L["Load configuration"] = true;
L["Force One"] = true;
L["Companions and mounts informations updated."] = true;
L["Select the companion to force summon."] = true;
L["Select the %s mount to force summon."] = true;
L["Currently using set: %s"] = true;
L["Set %s already exists."] = true;
L["Minimap icon is hidden if you want to show it back use: /pam or /petsandmounts"] = true;
L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random companion.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Revoke current companion.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open the configuration panel."] = true;
L["You already got a set named %s.\n\nEnter a new name or leave it blank to overwrite."] = true;
L["Database update to revision %d needed."] = true;
L["A full database update is needed."] = true;
L["Database updated to revision %d."] = true;
L["Delete set %s?"] = true;
L["A set named %s already exists, renaming it to %s."] = true;
L["Deleted set %s, due to Blizzard modification to companions code."] = true;
L["Auto companion summon is %s."] = true;
L["On"] = true;
L["Off"] = true;
L["Forced companion: %s"] = true;
L["Forced aquatic mount: %s"] = true;
L["Forced ground mount: %s"] = true;
L["Forced fly mount: %s"] = true;
L["Forced hybrid mount: %s"] = true;
L["Forced passenger mount: %s"] = true;
L["Companions set in use: %s."] = true;
L["Mounts set in use: %s."] = true;
end
