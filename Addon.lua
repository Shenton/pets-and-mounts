--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Addon.lua
-------------------------------------------------------------------------------]]--

-- Ace libs (<3)
local A = LibStub("AceAddon-3.0"):NewAddon("PetsAndMounts", "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0", "AceComm-3.0", "AceHook-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("PetsAndMounts");
A.L = L;

-- LibDBIcon
A.LDBIcon = LibStub("LibDBIcon-1.0");

-- Addon's global
_G["PetsAndMountsGlobal"] = A;
