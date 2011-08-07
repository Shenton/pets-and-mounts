-- ********************************************************************************
-- Broker Pets & Mounts
-- Data Broker display for easy acces to pets and mounts.
-- By: Shenton
--
-- Localization-enUS.lua
-- ********************************************************************************

local L = LibStub("AceLocale-3.0"):NewLocale("BrokerPAM", "enUS", true, true);

if L then
L["ADDON_NAME"] = "Pets & Mounts";
L["COMPANIONS"] = "Companions";
L["MOUNTS"] = "Mounts";
L["OPTIONS"] = "Options";
L["CLOSE"] = "Close";
L["SHOW_HIDE_MINIMAP"] = "Show or hide minimap icon";
L["MODEL_ROTATION"] = "Model rotation";
L["HIDE_MINIMAP"] = "Minimap icon is hidden if you want to show it back use: /pam or /petsandmounts";
L["TOOLTIP_TIPS"] = "|cFFC79C6ELeft-Click: |cFF33FF99Open the mounts selection menu.\n|cFFC79C6ERight-Click: |cFF33FF99Open the companions selection menu.";
end
