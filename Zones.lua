--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Zones.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- Globals to locals
local ipairs = ipairs;
local tostring = tostring;

-- GLOBALS: GetMapNameByID, WorldMapFrame, SetMapToCurrentZone, GetCurrentMapAreaID, LibStub

-- MapIDs with the same name, scenarios, quest in instance (legendary, green fire, etc), special events, etc
A.zonesIDsOverride =
{
    [539] = "JUSTIGNOREME", -- Gilneas
    [678] = "JUSTIGNOREME", -- Gilneas
    [679] = "JUSTIGNOREME", -- Gilneas
    [751] = "JUSTIGNOREME", -- The Maelstrom
    [737] = "JUSTIGNOREME", -- The Maelstrom
    [681] = "JUSTIGNOREME", -- The Lost Isles
    [682] = "JUSTIGNOREME", -- The Lost Isles
    [683] = "JUSTIGNOREME", -- Mount Hyjal
    [748] = "JUSTIGNOREME", -- Uldum
    [770] = "JUSTIGNOREME", -- Twilight Highlands
    [697] = "JUSTIGNOREME", -- Zul'Gurub
    [803] = "JUSTIGNOREME", -- The Nexus
    [813] = "JUSTIGNOREME", -- Eye of the Storm
    [762] = "JUSTIGNOREME", -- Scarlet Monastery
    [879] = "JUSTIGNOREME", -- Kun-Lai Summit
    [881] = "JUSTIGNOREME", -- Temple of Kotmogu
    [907] = "JUSTIGNOREME", -- Dustwallow Marsh
    [910] = "JUSTIGNOREME", -- Krasarang Wilds
    [919] = "JUSTIGNOREME", -- Black Temple
    [924] = "JUSTIGNOREME", -- Dalaran
    [933] = "JUSTIGNOREME", -- Isle of Thunder
    [939] = L["Blood in the Snow"],
    [937] = L["Dark Heart of Pandaria"],
    [920] = L["Domination Point (H)"],
    [880] = L["Greenstone Village"],
    [911] = L["Lion's Landing (A)"],
    [906] = L["Theramore's Fall (A)"],
    [851] = L["Theramore's Fall (H)"],
};

-- Build the mapIDs DB
function A:BuildMapIDsDB()
    if ( A.db.profile.debug ) then
        A.db.global.zonesIDsToName = {};
    end

    for i=1,2000 do
        if ( A.zonesIDsOverride[i] ) then
            if ( A.zonesIDsOverride[i] == "JUSTIGNOREME" ) then
                A.db.global.zonesIDsToName[tostring(i)] = nil;
            else
                A.db.global.zonesIDsToName[tostring(i)] = A.zonesIDsOverride[i];
            end
        else
            local name = GetMapNameByID(i);

            if ( name ) then
                if ( A.db.profile.debug ) then
                    if ( A:TableValueToKey(A.db.global.zonesIDsToName, name) ) then
                        A:DebugMessage(("BuildMapIDsDB() - %d %s already stored - with ID %s"):format(i, name, A:TableValueToKey(A.db.global.zonesIDsToName, name)));
                    end
                end

                A.db.global.zonesIDsToName[tostring(i)] = name;
            else
                A.db.global.zonesIDsToName[tostring(i)] = nil;
            end
        end
    end
end

-- Hook a script on hide of the worldmap frame
-- used to update the current mapID without
-- switching it while the player got his map open
WorldMapFrame:HookScript("OnHide", function()
    if ( A.getCurrentMapIDDelayed ) then
        A.getCurrentMapIDDelayed = nil;
        A:GetCurrentMapID();
    end
end);

-- Get the current mapID
-- Postponed it if the map is open
function A:GetCurrentMapID()
    if ( WorldMapFrame:IsVisible() ) then
        A.getCurrentMapIDDelayed = 1;
        return;
    end

    SetMapToCurrentZone();

    local mapID = GetCurrentMapAreaID();

    if ( not mapID ) then return; end

    A.currentMapID = mapID;

    if ( not A.db.global.zonesIDsToName[tostring(mapID)] and GetMapNameByID(mapID) ) then
        A.db.global.zonesIDsToName[tostring(mapID)] = GetMapNameByID(mapID);
        if ( A.AceConfigDialog ) then A:NotifyChangeForAll(); end
        A:DebugMessage(("GetCurrentMapID() - Added %d - %s"):format(mapID, GetMapNameByID(mapID) or "Unavailable"));
    end
end

--@debug@
-- Dump zones with the same name in a AceGUI dialog
function A:CreateMapIDFrame()
    if ( not A.mapIDFrame ) then
        if ( not A.AceConfigDialog ) then
            local loaded = A:LoadAddonConfig();
            if ( not loaded ) then return; end
        end
        if( not A.AceGUI ) then A.AceGUI = LibStub("AceGUI-3.0"); end
        A.mapIDFrame = A.AceGUI:Create("Frame");
        A.mapIDFrame:SetTitle("MapID Frame");
        A.mapIDFrame:SetLayout("FLow");
        A.mapIDFrame.editBox = A.AceGUI:Create("MultiLineEditBox");
        A.mapIDFrame.editBox:SetNumLines(20);
        A.mapIDFrame.editBox:SetFullWidth(1);
        A.mapIDFrame:AddChild(A.mapIDFrame.editBox);
    end
end
function A:ProcessMapID()
    A:CreateMapIDFrame();
    local maps = {};
    local count = 0;
    local result = "";
    for i=1,2000 do
        local name = GetMapNameByID(i);
        if ( name ) then
            if ( maps[name] ) then
                result = result..name.." - "..i.." - "..maps[name].."\n";
            end
            maps[name] = i;
            count = count + 1;
            A.mapIDFrame.editBox:SetText(result);
            A.mapIDFrame:SetStatusText(count);
        end
    end
end
--@end-debug@
