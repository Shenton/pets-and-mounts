--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    DevTools.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];

-- Dump zones with the same name in an AceGUI dialog - call A:ProcessMapID()
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
    else
        A.mapIDFrame:Show();
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

-- Used to find a spell usable at the water surface but not under water - call A:ProcessSurfaceSpells()
local surfaceSpells = 1;
local surfaceSpellsStop = 500;
local spellTest;
local results = {};
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
            A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.GREEN.."=== Water process started ===\n");
            A:ProcessSurfaceSpells2();
        end);
        A.surfaceSpellsFrame:AddChild(A.surfaceSpellsFrame.btn);

        A.surfaceSpellsFrame.btn2 = A.AceGUI:Create("Button");
        A.surfaceSpellsFrame.btn2:SetFullWidth(1);
        A.surfaceSpellsFrame.btn2:SetText("Surface");
        A.surfaceSpellsFrame.btn2:SetCallback("OnClick", function()
            A.surfaceSpellsFrame.editBox.editBox:Insert(A.color.GREEN.."=== Surface process started ===\n");
            A:ProcessSurfaceSpells4();
        end);
        A.surfaceSpellsFrame:AddChild(A.surfaceSpellsFrame.btn2);

        A.surfaceSpellsFrame.btn3 = A.AceGUI:Create("Button");
        A.surfaceSpellsFrame.btn3:SetFullWidth(1);
        A.surfaceSpellsFrame.btn3:SetText("Reset");
        A.surfaceSpellsFrame.btn3:SetCallback("OnClick", function()
            surfaceSpells = 1;
            surfaceSpellsStop = 500;
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
    spellTest = GetSpellInfo(surfaceSpells);
    A:ScheduleTimer("ProcessSurfaceSpells3", 0.1);
end
function A:ProcessSurfaceSpells3()
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
    A:ScheduleTimer("ProcessSurfaceSpells5", 0.1);
end
local index = 1;
function A:ProcessSurfaceSpells5()
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
    surfaceSpellsStop = surfaceSpellsStop + 500;
    results = {};
    A.surfaceSpellsFrame.editBox2:SetText(surfaceSpells);
    A.surfaceSpellsFrame.editBox3:SetText(surfaceSpellsStop);
    A.surfaceSpellsFrame:SetStatusText(surfaceSpells.."/"..surfaceSpellsStop.." - "..#results);
end
