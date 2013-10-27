--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Buttons.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- Globals to locals
local pairs = pairs;
local _G = _G;
local tostring = tostring;

-- GLOBALS: BINDING_HEADER_PETSANDMOUNTS, BINDING_NAME_PETSANDMOUNTSPET, BINDING_NAME_PETSANDMOUNTSMOUNT
-- GLOBALS: BINDING_NAME_PETSANDMOUNTSMOUNTPASSENGERS, BINDING_NAME_PETSANDMOUNTSMOUNTFLYING
-- GLOBALS: BINDING_NAME_PETSANDMOUNTSMOUNTGROUND, BINDING_NAME_PETSANDMOUNTSMOUNTAQUATIC
-- GLOBALS: InCombatLockdown, GetBindingKey, SetOverrideBindingClick, GetSpellInfo
-- GLOBALS: IsFlyableArea, IsSpellKnown, GetSpellInfo, IsShiftKeyDown, IsControlKeyDown
-- GLOBALS: PetsAndMountsSecureButtonMounts, PetsAndMountsSecureButtonPets, GetScreenWidth
-- GLOBALS: GameTooltip, GetItemCount, GetItemInfo, UIDropDownMenu_SetAnchor
-- GLOBALS: ToggleDropDownMenu, type, BINDING_NAME_PETSANDMOUNTSMOUNTSURFACE, UnitBuff

--[[-------------------------------------------------------------------------------
    Bindings
-------------------------------------------------------------------------------]]--

-- Binding UI localization
BINDING_HEADER_PETSANDMOUNTS = L["Pets & Mounts"];
BINDING_NAME_PETSANDMOUNTSPET = L["Random companion"];
BINDING_NAME_PETSANDMOUNTSMOUNT = L["Random mount"];
BINDING_NAME_PETSANDMOUNTSMOUNTPASSENGERS = L["Random passengers mount"];
BINDING_NAME_PETSANDMOUNTSMOUNTFLYING = L["Random flying mount"];
BINDING_NAME_PETSANDMOUNTSMOUNTGROUND = L["Random ground mount"];
BINDING_NAME_PETSANDMOUNTSMOUNTAQUATIC = L["Random aquatic mount"];
BINDING_NAME_PETSANDMOUNTSMOUNTSURFACE = L["Random surface mount"];

--- Set bindings
local bindings =
{
    ["PETSANDMOUNTSPET"] = "PetsAndMountsSecureButtonPets",
    ["PETSANDMOUNTSMOUNT"] = "PetsAndMountsSecureButtonMounts",
    ["PETSANDMOUNTSMOUNTPASSENGERS"] = "PetsAndMountsSecureButtonPassengers",
    ["PETSANDMOUNTSMOUNTFLYING"] = "PetsAndMountsSecureButtonFlying",
    ["PETSANDMOUNTSMOUNTGROUND"] = "PetsAndMountsSecureButtonGround",
    ["PETSANDMOUNTSMOUNTAQUATIC"] = "PetsAndMountsSecureButtonAquatic",
    ["PETSANDMOUNTSMOUNTSURFACE"] = "PetsAndMountsSecureButtonSurface",
};
function A:SetBindings()
    if ( InCombatLockdown() ) then
        A.delayedBindings = 1;
    else
        for k,v in pairs(bindings) do
            local key1, key2 = GetBindingKey(k);
            if ( key1 ) then SetOverrideBindingClick(_G[v], 1, key1, v); end

            if ( key2 ) then SetOverrideBindingClick(_G[v], 1, key2, v); end
        end
    end
end

--[[-------------------------------------------------------------------------------
    Simple buttons macros
-------------------------------------------------------------------------------]]--

--- Specific buttons macro
local buttonsMacro =
{
    [1] = -- With form cancel
    {
        ["PetsAndMountsSecureButtonPets"] = "/run PetsAndMountsGlobal:RandomPet()",
        ["PetsAndMountsSecureButtonPassengers"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(5)",
        ["PetsAndMountsSecureButtonFlying"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(2)",
        ["PetsAndMountsSecureButtonGround"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(1)",
        ["PetsAndMountsSecureButtonAquatic"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(4)",
        ["PetsAndMountsSecureButtonSurface"] = "/cancelform\n/run PetsAndMountsGlobal:RandomMount(6)",
    },
    [2] = -- Without
    {
        ["PetsAndMountsSecureButtonPets"] = "/run PetsAndMountsGlobal:RandomPet()",
        ["PetsAndMountsSecureButtonPassengers"] = "/run PetsAndMountsGlobal:RandomMount(5)",
        ["PetsAndMountsSecureButtonFlying"] = "/run PetsAndMountsGlobal:RandomMount(2)",
        ["PetsAndMountsSecureButtonGround"] = "/run PetsAndMountsGlobal:RandomMount(1)",
        ["PetsAndMountsSecureButtonAquatic"] = "/run PetsAndMountsGlobal:RandomMount(4)",
        ["PetsAndMountsSecureButtonSurface"] = "/run PetsAndMountsGlobal:RandomMount(6)",
    },
};
function A:SetButtonsMacro()
    if ( InCombatLockdown() ) then
        A.delayedButtonsMacro = 1;
    else
        if ( A.playerClass == "DRUID" or A.playerClass == "SHAMAN" ) then
            for k,v in pairs(buttonsMacro[1]) do
                _G[k]:SetAttribute("type", "macro");
                _G[k]:SetAttribute("macrotext", v);
            end
        else
            for k,v in pairs(buttonsMacro[2]) do
                _G[k]:SetAttribute("type", "macro");
                _G[k]:SetAttribute("macrotext", v);
            end
        end
    end
end

--[[-------------------------------------------------------------------------------
    Mounts smart button pre & post clicks
-------------------------------------------------------------------------------]]--

--[[
    Expert Riding 34090
    Artisan Riding 34091
    Master Riding 90265
--]]

-- Druid macros and spellIDs
--[[
    Travel Form - 783 - lvl 16
    Aquatic Form - 1066 - lvl 18
    Flight Form - 33943 - lvl 58
    Swift Flight Form - 40120 - lvl 70
--]]

function A:SetDruidSpells()
    A.druidTravelForm = GetSpellInfo(783);
    A.druidAquaticForm = GetSpellInfo(1066);
    A.druidFlightForm = GetSpellInfo(33943);
    A.druidSwiftFlightForm = GetSpellInfo(40120);
end

function A:SetDruidPreClickMacro()
    if ( IsFlyableArea() and IsSpellKnown(40120) ) then
        A.preClickDruidMacro = ("/cast %s\n/dismount [mounted]"):format(A.druidSwiftFlightForm);
    elseif ( A.playerLevel >= 58 and A:IsFlyable() ) then
        A.preClickDruidMacro = ("/cast %s\n/dismount [mounted]"):format(A.druidFlightForm);
    elseif ( A.playerLevel >= 20 and A:CanRide() ) then
        A.preClickDruidMacro = "/cancelform\n/run PetsAndMountsGlobal:RandomMount()";
    elseif ( A.playerLevel >= 16 ) then
        A.preClickDruidMacro = ("/cast %s\n/dismount [mounted]"):format(A.druidTravelForm);
    else
        A.preClickDruidMacro = "";
    end
end

-- Shaman spellIDs
-- Ghost Wolf 2645
-- Water Walking 546
function A:SetShamanSpells()
    A.shamanGhostWolf = GetSpellInfo(2645);
    A.shamanWaterWalking = GetSpellInfo(546);
end

-- Death Knight spellIDs
-- Path of Frost 3714
function A:SetdeathKnightSpell()
    A.deathKnightPathOfFrost = GetSpellInfo(3714);
end

-- Other classes macros and post click macros
function A:SetPostClickMacro()
    if ( A.playerClass == "DRUID" ) then
        A:SetDruidSpells();

        if ( A.playerLevel >= 18 ) then
            A.postClickMacro = ("/cast [swimming] %s; %s\n/dismount [mounted]"):format(A.druidAquaticForm, A.druidTravelForm);
        elseif ( A.playerLevel >= 16 ) then
            A.postClickMacro = ("/cast %s\n/dismount [mounted]"):format(A.druidTravelForm);
        else
            A.postClickMacro = "";
        end
    elseif ( A.playerClass == "SHAMAN" ) then
        A:SetShamanSpells();

        if ( A.playerLevel >= 16 ) then
            A.postClickMacro = ("/cast %s\n/dismount [mounted]"):format(A.shamanGhostWolf);
        else
            A.postClickMacro = "";
        end
    elseif ( A.playerClass == "DEATHKNIGHT" ) then -- No specific post macro for DK, but this is a good place to set their spells
        A:SetdeathKnightSpell();
        A.postClickMacro = "/dismount [mounted]";
    else
        A.postClickMacro = "/dismount [mounted]";
    end
end

--- Check if we got at least one mount for the given cat, check all tables after restriction
function A:GotMountAllTable(cat)
    if ( A.db.profile.forceOne.mount[cat]
    or A.db.profile.mountByMapID[cat][tostring(A.currentMapID)]
    or A.db.profile.areaMounts and A.uniqueAreaMounts[cat][A.currentMapID]
    or A:GotRandomMount(A.db.profile.favoriteMounts[cat])
    or A:GotRandomMount(A.pamTable.mountsIds[cat]) ) then
        return 1;
    end

    return nil;
end

--- PreClick
function A:PreClickMount(button, clickedBy)
    if ( InCombatLockdown() ) then return; end

    if ( clickedBy == "LeftButton" ) then
        if ( IsShiftKeyDown() ) then
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", nil);
            A:ToggleButtonLock(button);
        elseif ( IsControlKeyDown() ) then
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", nil);
            A.db.profile[button:GetName()].hide = 1;
            A:SetButtons();
        else
            if ( A.db.profile.magicBroom and GetItemCount(37011, nil, nil) == 1 and not A:IsSwimming() ) then -- 37011 - Magic Broom from Hallow's End
                if ( not A.magicBroomName ) then A.magicBroomName = GetItemInfo(37011); end

                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", "/use "..A.magicBroomName or "Magic Broom");
            elseif ( A.db.profile.surfaceMount and A:IsSwimming() == 2 and (A.playerClass == "DEATHKNIGHT" or A.playerClass == "SHAMAN") ) then -- DK and Sham water walking spells
                if ( A.db.profile.preferSurfaceSpell or (not A.db.profile.preferSurfaceSpell and not A:GotMountAllTable(6)) ) then
                    if ( A.playerClass == "DEATHKNIGHT" and not UnitBuff("player", A.deathKnightPathOfFrost) ) then
                        button:SetAttribute("type", "macro");
                        button:SetAttribute("macrotext", "/cast "..A.deathKnightPathOfFrost);
                    elseif ( A.playerClass == "SHAMAN" ) then
                        if ( UnitBuff("player", A.shamanWaterWalking) ) then
                            button:SetAttribute("type", "macro");
                            button:SetAttribute("macrotext", "/cancelform\n/run PetsAndMountsGlobal:RandomMount()");
                        else
                            button:SetAttribute("type", "macro");
                            button:SetAttribute("macrotext", "/cast "..A.shamanWaterWalking);
                        end
                    else
                        button:SetAttribute("type", "macro");
                        button:SetAttribute("macrotext", "/run PetsAndMountsGlobal:RandomMount()");
                    end
                else
                    button:SetAttribute("type", "macro");
                    button:SetAttribute("macrotext", "/run PetsAndMountsGlobal:RandomMount()");
                end
            elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "DRUID" ) then
                A:SetDruidPreClickMacro();
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", A.preClickDruidMacro);
            elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "SHAMAN" ) then
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", "/cancelform\n/run PetsAndMountsGlobal:RandomMount()");
            else
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", "/run PetsAndMountsGlobal:RandomMount()");
            end
        end
    elseif ( clickedBy == "RightButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);

        local point, relativePoint = A:GetMenuButtonAnchor();

        UIDropDownMenu_SetAnchor(A.menuFrame, 0, 0, point, button, relativePoint);
        ToggleDropDownMenu(1, nil, A.menuFrame, button);

        GameTooltip:Hide();
    elseif ( clickedBy == "MiddleButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);
        A:OpenConfigPanel();
    end
end

--- PostClick
function A:PostClickMount(button, clickedBy)
    if ( InCombatLockdown() ) then return; end

    button:SetAttribute("type", "macro");
    button:SetAttribute("macrotext", A.postClickMacro);
end

--[[-------------------------------------------------------------------------------
    Pets button pre & post clicks
-------------------------------------------------------------------------------]]--

--- PreClick
function A:PreClickPet(button, clickedBy)
    if ( InCombatLockdown() ) then return; end

    if ( clickedBy == "LeftButton" ) then
        if ( IsShiftKeyDown() ) then
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", nil);
            A:ToggleButtonLock(button);
        elseif ( IsControlKeyDown() ) then
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", nil);
            A.db.profile[button:GetName()].hide = 1;
            A:SetButtons();
        else
            button:SetAttribute("type", "macro");
            button:SetAttribute("macrotext", "/run PetsAndMountsGlobal:RandomPet()");
        end
    elseif ( clickedBy == "RightButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);

        local point, relativePoint = A:GetMenuButtonAnchor();

        UIDropDownMenu_SetAnchor(A.menuFrame, 0, 0, point, button, relativePoint);
        ToggleDropDownMenu(1, nil, A.menuFrame, button);

        GameTooltip:Hide();
    elseif ( clickedBy == "MiddleButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);
        A:OpenConfigPanel();
    end
end

--[[-------------------------------------------------------------------------------
    Pets and Mounts clickable buttons methods
-------------------------------------------------------------------------------]]--

--- Set button position
function A:SetButtonPos(button)
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    _G[button]:ClearAllPoints();
    _G[button]:SetPoint(A.db.profile[button].anchor.point, A.db.profile[button].anchor.relativeTo, A.db.profile[button].anchor.relativePoint, A.db.profile[button].anchor.offX, A.db.profile[button].anchor.offY);
end

--- Lock button
function A:LockButton(button)
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    _G[button]:SetMovable(nil);
    _G[button]:SetScript("OnDragStart", nil);
    _G[button]:SetScript("OnDragStop", nil);
    A.db.profile[button].lock = 1;

    if ( A.AceConfigRegistry ) then
        A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
    end
end

--- Unlock button, saving position
function A:UnlockButton(button)
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    if ( A.db.profile.dockButton and button == "PetsAndMountsSecureButtonPets" ) then return; end

    _G[button]:SetMovable(1);
    _G[button]:RegisterForDrag("LeftButton");
    _G[button]:SetScript("OnDragStart", _G[button].StartMoving);
    _G[button]:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();

        local point, relativeTo, relativePoint, offX, offY = self:GetPoint(1);

        A.db.profile[button].anchor.point = point;
        A.db.profile[button].anchor.relativeTo = relativeTo;
        A.db.profile[button].anchor.relativePoint = relativePoint;
        A.db.profile[button].anchor.offX = offX;
        A.db.profile[button].anchor.offY = offY;
    end);
    A.db.profile[button].lock = nil;

    if ( A.AceConfigRegistry ) then
        A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
    end
end

--- Toggle lock button
function A:ToggleButtonLock(button)
    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    if ( _G[button]:IsMovable() ) then
        A:LockButton(button);
    else
        A:UnlockButton(button);
    end
end

--- Button hide/show toggle
function A:ToggleButtonHideShow(button)
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    if ( _G[button]:IsShown() ) then
        _G[button]:Hide();
        A.db.profile[button].hide = 1;
    else
        _G[button]:Show();
        A.db.profile[button].hide = nil;
    end

    if ( A.AceConfigRegistry ) then
        A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
    end
end

--- Dock buttons together
function A:DockButton()
    A.db.profile.PetsAndMountsSecureButtonPets.anchor =
    {
        point = A.dockButtonsAnchors[A.db.profile.dockAnchor][1],
        relativeTo = "PetsAndMountsSecureButtonMounts",
        relativePoint = A.dockButtonsAnchors[A.db.profile.dockAnchor][2],
        offX = A.dockButtonsAnchors[A.db.profile.dockAnchor][3],
        offY = A.dockButtonsAnchors[A.db.profile.dockAnchor][4],
    };

    A:LockButton("PetsAndMountsSecureButtonPets")
    A:SetButtonPos("PetsAndMountsSecureButtonPets");
end

--- Dock buttons together
function A:UnDockButton()
    local point, relativeTo, relativePoint, offX, offY = PetsAndMountsSecureButtonMounts:GetPoint(1);

    offX = offX + 40

    A.db.profile.PetsAndMountsSecureButtonPets.anchor =
    {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        offX = offX,
        offY = offY,
    };

    A:SetButtonPos("PetsAndMountsSecureButtonPets");
end

--- Reset button
function A:ResetButton(button)
    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    local offX;

    if ( button == "PetsAndMountsSecureButtonPets" ) then
        offX = 20;
    elseif ( button == "PetsAndMountsSecureButtonMounts" ) then
        offX = -20
    else
        offX = 0;
    end

    A.db.profile[button] =
    {
        hide = nil,
        lock = nil,
        tooltip = 1,
        scale = 1,
        anchor =
        {
            point = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            offX = offX,
            offY = 0,
        },
    },

    A:SetButtons();
end

--- Set buttons on login
function A:SetButtons()
    if ( InCombatLockdown() ) then
        A:Message(L["Unable to edit buttons while in combat."], 1);
        return;
    end

    -- Position
    A:SetButtonPos("PetsAndMountsSecureButtonPets");
    A:SetButtonPos("PetsAndMountsSecureButtonMounts");

    -- Scale
    PetsAndMountsSecureButtonPets:SetScale(A.db.profile.PetsAndMountsSecureButtonPets.scale);
    PetsAndMountsSecureButtonMounts:SetScale(A.db.profile.PetsAndMountsSecureButtonMounts.scale);

    -- Visibility
    if ( A.db.profile.PetsAndMountsSecureButtonPets.hide ) then
        PetsAndMountsSecureButtonPets:Hide();

        if (  A.db.profile.dockButton ) then
            A.db.profile.dockButton = nil;
            A:UnDockButton();
        end
    else
        PetsAndMountsSecureButtonPets:Show();
    end

    if ( A.db.profile.PetsAndMountsSecureButtonMounts.hide ) then
        PetsAndMountsSecureButtonMounts:Hide();

        if (  A.db.profile.dockButton ) then
            A.db.profile.dockButton = nil;
            A:UnDockButton();

            if ( not A.db.profile.PetsAndMountsSecureButtonMounts.lock and A.db.profile.PetsAndMountsSecureButtonPets.lock ) then
                A.db.profile.PetsAndMountsSecureButtonPets.lock = nil;
                A:SetButtons();
                return;
            end
        end
    else
        PetsAndMountsSecureButtonMounts:Show();
    end

    -- Movable
    if ( A.db.profile.PetsAndMountsSecureButtonPets.lock ) then
        A:LockButton("PetsAndMountsSecureButtonPets");
    else
        A:UnlockButton("PetsAndMountsSecureButtonPets");
    end

    if ( A.db.profile.PetsAndMountsSecureButtonMounts.lock ) then
        A:LockButton("PetsAndMountsSecureButtonMounts");
    else
        A:UnlockButton("PetsAndMountsSecureButtonMounts");
    end

    -- Refresh config panel
    if ( A.AceConfigRegistry ) then
        A.AceConfigRegistry:NotifyChange("PetsAndMountsConfig");
    end
end

--[[-------------------------------------------------------------------------------
    Tooltips
-------------------------------------------------------------------------------]]--

--- Display button tooltip
function A:SetTooltip(frame)
    if ( not A.db.profile.PetsAndMountsSecureButtonPets.tooltip and frame:GetName() == "PetsAndMountsSecureButtonPets" ) then return; end
    if ( not A.db.profile.PetsAndMountsSecureButtonMounts.tooltip and frame:GetName() == "PetsAndMountsSecureButtonMounts" ) then return; end

    local currentSet;

    if ( frame:GetRight() >= ( GetScreenWidth() / 2 ) ) then
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT");
    else
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
    end

    GameTooltip:AddDoubleLine(A.color["WHITE"]..L["Pets & Mounts"], A.color["GREEN"].."v"..A.version);
    GameTooltip:AddLine(" ");

    if ( frame:GetName() == "PetsAndMountsSecureButtonPets" ) then
        currentSet = A:GetCurrentSet("PET");

        if ( currentSet == L["None"] ) then
            currentSet = A.color["RED"]..currentSet;
        else
            currentSet = A.color["GREEN"]..currentSet;
        end

        GameTooltip:AddLine(L["Companions set in use: %s."]:format(currentSet));
        GameTooltip:AddLine(L["Auto summon companion is %s."]:format(A:IsAutoPetEnabled() and A.color["GREEN"]..L["On"] or A.color["RED"]..L["Off"]));
        GameTooltip:AddLine(L["Not when stealthed is %s."]:format(A:IsNotWhenStealthedEnabled() and A.color["GREEN"]..L["On"] or A.color["RED"]..L["Off"]));
        GameTooltip:AddLine(L["Forced companion: %s"]:format(A.db.profile.forceOne.pet and A.color["GREEN"]..A:GetPetNameByID(A.db.profile.forceOne.pet) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random pet.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Toggle button lock.\n|cFFC79C6EControl+Left-Click: |cFF33FF99Hide button.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open configuration panel."]);
    elseif ( frame:GetName() == "PetsAndMountsSecureButtonMounts" ) then
        currentSet = A:GetCurrentSet("MOUNT");

        if ( currentSet == L["None"] ) then
            currentSet = A.color["RED"]..currentSet;
        else
            currentSet = A.color["GREEN"]..currentSet;
        end

        GameTooltip:AddLine(L["Mounts set in use: %s."]:format(currentSet));
        GameTooltip:AddLine(L["Forced aquatic mount: %s"]:format(A.db.profile.forceOne.mount[4] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[4]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(L["Forced ground mount: %s"]:format(A.db.profile.forceOne.mount[1] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[1]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(L["Forced fly mount: %s"]:format(A.db.profile.forceOne.mount[2] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[2]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(L["Forced hybrid mount: %s"]:format(A.db.profile.forceOne.mount[3] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[3]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(L["Forced passenger mount: %s"]:format(A.db.profile.forceOne.mount[5] and A.color["GREEN"]..A:GetMountNameBySpellID(A.db.profile.forceOne.mount[5]) or A.color["RED"]..L["None"]));
        GameTooltip:AddLine(" ");

        if ( A.db.profile.dockButton ) then
            GameTooltip:AddLine(L["Use me to move both buttons."]);
            GameTooltip:AddLine(" ");
        end

        GameTooltip:AddLine(L["|cFFC79C6ELeft-Click: |cFF33FF99Summon a random mount.\n|cFFC79C6EShift+Left-Click: |cFF33FF99Toggle button lock.\n|cFFC79C6EControl+Left-Click: |cFF33FF99Hide button.\n|cFFC79C6ERight-Click: |cFF33FF99Open the menu.\n|cFFC79C6EMiddle-Click: |cFF33FF99Open configuration panel."]);
    end

    GameTooltip:Show();
end
