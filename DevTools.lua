--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    DevTools.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];

-- Dump zones with the same name in an AceGUI dialog - call A:ProcessMapID()
-- TODO readd the same names (checkbox, button, whatever)

A.uiMapType =
{
    [4] = "Dungeon",
    [6] = "Orphan",
    [3] = "Zone",
    [2] = "Continent",
    [0] = "Cosmic",
    [5] = "Micro",
    [1] = "World",
    [99] = "None",
};

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
        A.mapIDFrame:SetHeight(600);

        A.mapIDFrame.editBox = A.AceGUI:Create("MultiLineEditBox");
        A.mapIDFrame.editBox:SetNumLines(26);
        A.mapIDFrame.editBox:SetFullWidth(1);
        A.mapIDFrame:AddChild(A.mapIDFrame.editBox);

        A.mapIDFrame.editBox2 = A.AceGUI:Create("EditBox");
        A.mapIDFrame.editBox2:SetFullWidth(1);
        A.mapIDFrame:AddChild(A.mapIDFrame.editBox2);
        A.mapIDFrame.editBox2:SetText();
        A.mapIDFrame.editBox2:SetCallback("OnEnterPressed", function(self, script, val)
            A:SearchMaps(val);
        end);

        A.mapIDFrame.select = A.AceGUI:Create("Dropdown");
        A.mapIDFrame.select:SetLabel("Type");
        A.mapIDFrame:AddChild(A.mapIDFrame.select);
        A.mapIDFrame.select:SetList(A.uiMapType);
        A.mapIDFrame.select:SetValue(nil);
        A.mapIDFrame.select:SetCallback("OnValueChanged", function(info, event, val)
            if ( val == 99 ) then
                A.mapIDFrame.mapType = nil;
            else
                A.mapIDFrame.mapType = val;
            end

            local term = A.mapIDFrame.editBox2:GetText();

            if ( term and term ~= "" ) then
                A:SearchMaps(term);
            else
                A:SearchMaps();
            end
        end);
    else
        A.mapIDFrame:Show();
    end
end
function A:ProcessMapID()
    A:CreateMapIDFrame();
    A.mapIDFrame.maps = {};

    for i=1,2000 do
        local mapInfo = C_Map.GetMapInfo(i);

        if ( mapInfo ) then
            A.mapIDFrame.maps[i] = mapInfo;
        end
    end

    A:SearchMaps();
end
function A:SearchMaps(term)
    local results = "";
    local count = 0;

    if ( term ) then
        term = string.lower(term);

        for k,v in pairs(A.mapIDFrame.maps) do
            local name = string.lower(v.name);

            if ( (not A.mapIDFrame.mapType or A.mapIDFrame.mapType == v.mapType) and string.find(name, term) ) then
                results = results..k.." - "..v.name.."\n";
                count = count + 1;
            end
        end
    else
        for k,v in pairs(A.mapIDFrame.maps) do
            if ( not A.mapIDFrame.mapType or A.mapIDFrame.mapType == v.mapType ) then
                results = results..k.." - "..v.name.."\n";
                count = count + 1;
            end
        end
    end

    A.mapIDFrame.editBox:SetText(results);
    A.mapIDFrame:SetStatusText(count);
end


-- Used to find a spell usable at the water surface but not under water - call A:ProcessSurfaceSpells()
local surfaceSpells = 1;
local step = 1000;
local surfaceSpellsStop = step;
local spellTest;
local results = {};
local freq = 0.05;
local running;
function A:CreateSurfaceSpellsFrame()
    if ( not A.surfaceSpellsFrame ) then
        if ( not A.AceConfigDialog ) then
            local loaded = A:LoadAddonConfig();
            if ( not loaded ) then return; end
        end
        if( not A.AceGUI ) then A.AceGUI = LibStub("AceGUI-3.0"); end
        A.surfaceSpellsFrame = A.AceGUI:Create("Frame");
        A.surfaceSpellsFrame:SetHeight(600);
        A.surfaceSpellsFrame:SetTitle("Surface Spells Frame");
        A.surfaceSpellsFrame:SetLayout("FLow");
        A.surfaceSpellsFrame:SetStatusText(surfaceSpells.."/"..surfaceSpellsStop.." - "..#results);

        A.surfaceSpellsFrame.editBox = A.AceGUI:Create("MultiLineEditBox");
        A.surfaceSpellsFrame.editBox:SetNumLines(22);
        A.surfaceSpellsFrame.editBox:SetFullWidth(1);
        A.surfaceSpellsFrame:AddChild(A.surfaceSpellsFrame.editBox);

        A.surfaceSpellsFrame.editBox2 = A.AceGUI:Create("EditBox");
        A.surfaceSpellsFrame.editBox2:SetFullWidth(1);
        A.surfaceSpellsFrame:AddChild(A.surfaceSpellsFrame.editBox2);
        A.surfaceSpellsFrame.editBox2:SetText(surfaceSpells);
        A.surfaceSpellsFrame.editBox2:SetCallback("OnEnterPressed", function(self, script, val)
            surfaceSpells = tonumber(val);
            A.surfaceSpellsFrame:SetStatusText(surfaceSpells.."/"..surfaceSpellsStop.." - "..#results);
        end);

        A.surfaceSpellsFrame.editBox3 = A.AceGUI:Create("EditBox");
        A.surfaceSpellsFrame.editBox3:SetFullWidth(1);
        A.surfaceSpellsFrame:AddChild(A.surfaceSpellsFrame.editBox3);
        A.surfaceSpellsFrame.editBox3:SetText(surfaceSpellsStop);
        A.surfaceSpellsFrame.editBox3:SetCallback("OnEnterPressed", function(self, script, val)
            surfaceSpellsStop = tonumber(val);
            A.surfaceSpellsFrame:SetStatusText(surfaceSpells.."/"..surfaceSpellsStop.." - "..#results);
        end);

        A.surfaceSpellsFrame.btn = A.AceGUI:Create("Button");
        A.surfaceSpellsFrame.btn:SetFullWidth(1);
        A.surfaceSpellsFrame.btn:SetText("Water");
        A.surfaceSpellsFrame.btn:SetCallback("OnClick", function()
            running = 1;
            A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.GREEN.."=== Water process started ===\n");
            A:ProcessSurfaceSpells2();
        end);
        A.surfaceSpellsFrame:AddChild(A.surfaceSpellsFrame.btn);

        A.surfaceSpellsFrame.btn2 = A.AceGUI:Create("Button");
        A.surfaceSpellsFrame.btn2:SetFullWidth(1);
        A.surfaceSpellsFrame.btn2:SetText("Surface");
        A.surfaceSpellsFrame.btn2:SetCallback("OnClick", function()
            running = 1;
            A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.GREEN.."=== Surface process started ===\n");
            A:ProcessSurfaceSpells4();
        end);
        A.surfaceSpellsFrame:AddChild(A.surfaceSpellsFrame.btn2);

        A.surfaceSpellsFrame.btn3 = A.AceGUI:Create("Button");
        A.surfaceSpellsFrame.btn3:SetFullWidth(1);
        A.surfaceSpellsFrame.btn3:SetText("Reset");
        A.surfaceSpellsFrame.btn3:SetCallback("OnClick", function()
            running = nil;
            surfaceSpells = 1;
            surfaceSpellsStop = step;
            spellTest = nil;
            results = {};
            A.surfaceSpellsFrame.editBox.editBox:SetText("");
            A.surfaceSpellsFrame.editBox2:SetText(surfaceSpells);
            A.surfaceSpellsFrame.editBox3:SetText(surfaceSpellsStop);
            A.surfaceSpellsFrame:SetStatusText(surfaceSpells.."/"..surfaceSpellsStop.." - "..#results);
        end);
        A.surfaceSpellsFrame:AddChild(A.surfaceSpellsFrame.btn3);
    else
        A.surfaceSpellsFrame:Show();
    end
end
function A:ProcessSurfaceSpells()
    A:CreateSurfaceSpellsFrame();
end
function A:ProcessSurfaceSpells2()
    if ( not running ) then return; end
    spellTest = GetSpellInfo(surfaceSpells);
    A:ScheduleTimer("ProcessSurfaceSpells3", freq);
end
function A:ProcessSurfaceSpells3()
    if ( not running ) then return; end
    --spellTest = GetSpellInfo(surfaceSpells);
    if ( spellTest ) then
        if ( not IsUsableSpell(surfaceSpells) ) then
            results[#results+1] = surfaceSpells;
            A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.BLUE..surfaceSpells.."\n");
        end
    end
    spellTest = nil;
    surfaceSpells = surfaceSpells + 1;
    A.surfaceSpellsFrame:SetStatusText(surfaceSpells.."/"..surfaceSpellsStop.." - "..#results);
    if ( surfaceSpells >= surfaceSpellsStop ) then
        A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.RED.."=== Water process ended ===\n");
        return;
    end
    A:ProcessSurfaceSpells2();
end
function A:ProcessSurfaceSpells4()
    if ( not running ) then return; end
    A:ScheduleTimer("ProcessSurfaceSpells5", freq);
end
local index = 1;
function A:ProcessSurfaceSpells5()
    if ( not running ) then return; end
    if ( results[index] ) then
        A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.HEIRLOOM.."Testing spellID "..results[index]..": ");
        if ( IsUsableSpell(results[index]) ) then
            A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.LEGENDARY.."Yes!!\n");
            print(A.color.LEGENDARY.."Found one!!! => "..results[index]);
        else
            A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.RED.."No.\n");
        end
        index = index + 1;
        A:ProcessSurfaceSpells4();
        return;
    end

    A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.RED.."=== Surface process ended ===\n");
    index = 1;
    surfaceSpellsStop = surfaceSpellsStop + step;
    results = {};
    A.surfaceSpellsFrame.editBox2:SetText(surfaceSpells);
    A.surfaceSpellsFrame.editBox3:SetText(surfaceSpellsStop);
    A.surfaceSpellsFrame:SetStatusText(surfaceSpells.."/"..surfaceSpellsStop.." - "..#results);
end

-- Dump mounts categories IDs, will display the name of the first mount found - call A:ProcessMountsCategories()
function A:CreateMountsCategoriesFrame()
    if ( not A.mountsCategoriesFrame ) then
        if ( not A.AceConfigDialog ) then
            local loaded = A:LoadAddonConfig();
            if ( not loaded ) then return; end
        end
        if( not A.AceGUI ) then A.AceGUI = LibStub("AceGUI-3.0"); end
        A.mountsCategoriesFrame = A.AceGUI:Create("Frame");
        A.mountsCategoriesFrame:SetTitle("MapID Frame");
        A.mountsCategoriesFrame:SetLayout("FLow");
        A.mountsCategoriesFrame.editBox = A.AceGUI:Create("MultiLineEditBox");
        A.mountsCategoriesFrame.editBox:SetNumLines(26);
        A.mountsCategoriesFrame.editBox:SetFullWidth(1);
        A.mountsCategoriesFrame:AddChild(A.mountsCategoriesFrame.editBox);
    else
        A.mountsCategoriesFrame:Show();
    end
end
function A:ProcessMountsCategories(providedCat)
    A:CreateMountsCategoriesFrame();

    local mountIDs = C_MountJournal.GetMountIDs();

    if ( providedCat and providedCat ~= "" ) then
        local count = 0;
        local result = "";

        providedCat = tonumber(providedCat);

        for _,mountID in ipairs(mountIDs) do
            local name = C_MountJournal.GetMountInfoByID(mountID);
            local _, _, _, _, cat = C_MountJournal.GetMountInfoExtraByID(mountID);
            if ( name and cat == providedCat ) then
                result = result..cat.." - "..name.."\n";
                count = count + 1;
                A.mountsCategoriesFrame.editBox:SetText(result);
                A.mountsCategoriesFrame:SetStatusText(count);
            end
        end
    else
        local cats = {};
        local count = 0;
        local result = "";
        for _,mountID in ipairs(mountIDs) do
            local name = C_MountJournal.GetMountInfoByID(mountID);
            local _, _, _, _, cat = C_MountJournal.GetMountInfoExtraByID(mountID);
            if ( name ) then
                if ( not cats[cat] ) then
                    cats[cat] = name;
                    result = result..cat.." - "..name.."\n";
                    count = count + 1;
                    A.mountsCategoriesFrame.editBox:SetText(result);
                    A.mountsCategoriesFrame:SetStatusText(count);
                end
            end
        end
    end
end
