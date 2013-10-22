--[[-------------------------------------------------------------------------------
    Broker Pets & Mounts
    Data Broker display for easy acces to pets and mounts.
    By: Shenton

    Buttons.lua
-------------------------------------------------------------------------------]]--

local A = _G["BrokerPAMGlobal"];
local L = A.L;

-- Globals to locals
local pairs = pairs;
local _G = _G;

-- GLOBALS: BINDING_HEADER_BROKERPAM, BINDING_NAME_BROKERPAMPET, BINDING_NAME_BROKERPAMMOUNT
-- GLOBALS: BINDING_NAME_BROKERPAMMOUNTPASSENGERS, BINDING_NAME_BROKERPAMMOUNTFLYING
-- GLOBALS: BINDING_NAME_BROKERPAMMOUNTGROUND, BINDING_NAME_BROKERPAMMOUNTAQUATIC
-- GLOBALS: InCombatLockdown, GetBindingKey, SetOverrideBindingClick, GetSpellInfo
-- GLOBALS: IsFlyableArea, IsSpellKnown, GetSpellInfo, IsShiftKeyDown, IsControlKeyDown
-- GLOBALS: BrokerPAMSecureButtonMounts, BrokerPAMSecureButtonPets, GetScreenWidth
-- GLOBALS: GameTooltip, GetItemCount, GetItemInfo, UIDropDownMenu_SetAnchor
-- GLOBALS: ToggleDropDownMenu, type

--[[-------------------------------------------------------------------------------
    Bindings
-------------------------------------------------------------------------------]]--

-- Binding UI localization
BINDING_HEADER_BROKERPAM = L["Pets & Mounts"];
BINDING_NAME_BROKERPAMPET = L["Random companion"];
BINDING_NAME_BROKERPAMMOUNT = L["Random mount"];
BINDING_NAME_BROKERPAMMOUNTPASSENGERS = L["Random passengers mount"];
BINDING_NAME_BROKERPAMMOUNTFLYING = L["Random flying mount"];
BINDING_NAME_BROKERPAMMOUNTGROUND = L["Random ground mount"];
BINDING_NAME_BROKERPAMMOUNTAQUATIC = L["Random aquatic mount"];

--- Set bindings
local bindings =
{
    ["BROKERPAMPET"] = "BrokerPAMSecureButtonPets",
    ["BROKERPAMMOUNT"] = "BrokerPAMSecureButtonMounts",
    ["BROKERPAMMOUNTPASSENGERS"] = "BrokerPAMSecureButtonPassengers",
    ["BROKERPAMMOUNTFLYING"] = "BrokerPAMSecureButtonFlying",
    ["BROKERPAMMOUNTGROUND"] = "BrokerPAMSecureButtonGround",
    ["BROKERPAMMOUNTAQUATIC"] = "BrokerPAMSecureButtonAquatic",
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
        ["BrokerPAMSecureButtonPets"] = "/run BrokerPAMGlobal:RandomPet()",
        ["BrokerPAMSecureButtonPassengers"] = "/cancelform\n/run BrokerPAMGlobal:RandomMount(5)",
        ["BrokerPAMSecureButtonFlying"] = "/cancelform\n/run BrokerPAMGlobal:RandomMount(2)",
        ["BrokerPAMSecureButtonGround"] = "/cancelform\n/run BrokerPAMGlobal:RandomMount(1)",
        ["BrokerPAMSecureButtonAquatic"] = "/cancelform\n/run BrokerPAMGlobal:RandomMount(4)",
    },
    [2] = -- Without
    {
        ["BrokerPAMSecureButtonPets"] = "/run BrokerPAMGlobal:RandomPet()",
        ["BrokerPAMSecureButtonPassengers"] = "/run BrokerPAMGlobal:RandomMount(5)",
        ["BrokerPAMSecureButtonFlying"] = "/run BrokerPAMGlobal:RandomMount(2)",
        ["BrokerPAMSecureButtonGround"] = "/run BrokerPAMGlobal:RandomMount(1)",
        ["BrokerPAMSecureButtonAquatic"] = "/run BrokerPAMGlobal:RandomMount(4)",
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
        A.preClickDruidMacro = "/cancelform\n/run BrokerPAMGlobal:RandomMount()";
    elseif ( A.playerLevel >= 16 ) then
        A.preClickDruidMacro = ("/cast %s\n/dismount [mounted]"):format(A.druidTravelForm);
    else
        A.preClickDruidMacro = "";
    end
end

-- Shaman macros and spellIDs
-- Ghost Wolf 2645
function A:SetShamanSpells()
    A.shamanGhostWolf = GetSpellInfo(2645);
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
    else
        A.postClickMacro = "/dismount [mounted]";
    end
end

--- PreClick
function A:PreClickMount(button, clickedBy)
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
            if ( InCombatLockdown() ) then return; end

            if ( A.db.profile.magicBroom and not A:IsSwimming() and GetItemCount(37011, nil, nil) == 1 ) then -- 37011 - Magic Broom from Hallow's End
                if ( not A.magicBroomName ) then A.magicBroomName = GetItemInfo(37011); end

                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", "/use "..A.magicBroomName or "Magic Broom");
            elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "DRUID" ) then
                A:SetDruidPreClickMacro();
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", A.preClickDruidMacro);
            elseif ( A.db.profile.classesMacrosEnabled and A.playerClass == "SHAMAN" ) then
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", "/cancelform\n/run BrokerPAMGlobal:RandomMount()");
            else
                button:SetAttribute("type", "macro");
                button:SetAttribute("macrotext", "/run BrokerPAMGlobal:RandomMount()");
            end
        end
    elseif ( clickedBy == "RightButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);

        local point, relativePoint = A:GetAnchor();

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
            button:SetAttribute("macrotext", "/run BrokerPAMGlobal:RandomPet()");
        end
    elseif ( clickedBy == "RightButton" ) then
        button:SetAttribute("type", "macro");
        button:SetAttribute("macrotext", nil);

        local point, relativePoint = A:GetAnchor();

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
    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    _G[button]:ClearAllPoints();
    _G[button]:SetPoint(A.db.profile[button].anchor.point, A.db.profile[button].anchor.relativeTo, A.db.profile[button].anchor.relativePoint, A.db.profile[button].anchor.offX, A.db.profile[button].anchor.offY);
end

--- Lock button
function A:LockButton(button)
    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    _G[button]:SetMovable(nil);
    _G[button]:SetScript("OnDragStart", nil);
    _G[button]:SetScript("OnDragStop", nil);
    A.db.profile[button].lock = 1;

    if ( A.AceConfigRegistry ) then
        A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
    end
end

--- Unlock button, saving position
function A:UnlockButton(button)
    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    if ( A.db.profile.dockButton and button == "BrokerPAMSecureButtonPets" ) then return; end

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
        A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
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
        A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
    end
end

--- Dock buttons together
function A:DockButton()
    A.db.profile.BrokerPAMSecureButtonPets.anchor =
    {
        point = "LEFT",
        relativeTo = "BrokerPAMSecureButtonMounts",
        relativePoint = "RIGHT",
        offX = 4,
        offY = 0,
    };

    A:LockButton("BrokerPAMSecureButtonPets")
    A:SetButtonPos("BrokerPAMSecureButtonPets");
end

--- Dock buttons together
function A:UnDockButton()
    local point, relativeTo, relativePoint, offX, offY = BrokerPAMSecureButtonMounts:GetPoint(1);

    offX = offX + 40

    A.db.profile.BrokerPAMSecureButtonPets.anchor =
    {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        offX = offX,
        offY = offY,
    };

    A:SetButtonPos("BrokerPAMSecureButtonPets");
end

--- Reset button
function A:ResetButton(button)
    if ( type(button) ~= "string" ) then
        button = button:GetName();
    end

    local offX;

    if ( button == "BrokerPAMSecureButtonPets" ) then
        offX = 20;
    elseif ( button == "BrokerPAMSecureButtonMounts" ) then
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
    -- Position
    A:SetButtonPos("BrokerPAMSecureButtonPets");
    A:SetButtonPos("BrokerPAMSecureButtonMounts");

    -- Scale
    BrokerPAMSecureButtonPets:SetScale(A.db.profile.BrokerPAMSecureButtonPets.scale);
    BrokerPAMSecureButtonMounts:SetScale(A.db.profile.BrokerPAMSecureButtonMounts.scale);

    -- Visibility
    if ( A.db.profile.BrokerPAMSecureButtonPets.hide ) then
        BrokerPAMSecureButtonPets:Hide();

        if (  A.db.profile.dockButton ) then
            A.db.profile.dockButton = nil;
            A:UnDockButton();
        end
    else
        BrokerPAMSecureButtonPets:Show();
    end

    if ( A.db.profile.BrokerPAMSecureButtonMounts.hide ) then
        BrokerPAMSecureButtonMounts:Hide();

        if (  A.db.profile.dockButton ) then
            A.db.profile.dockButton = nil;
            A:UnDockButton();

            if ( not A.db.profile.BrokerPAMSecureButtonMounts.lock and A.db.profile.BrokerPAMSecureButtonPets.lock ) then
                A.db.profile.BrokerPAMSecureButtonPets.lock = nil;
                A:SetButtons();
                return;
            end
        end
    else
        BrokerPAMSecureButtonMounts:Show();
    end

    -- Movable
    if ( A.db.profile.BrokerPAMSecureButtonPets.lock ) then
        A:LockButton("BrokerPAMSecureButtonPets");
    else
        A:UnlockButton("BrokerPAMSecureButtonPets");
    end

    if ( A.db.profile.BrokerPAMSecureButtonMounts.lock ) then
        A:LockButton("BrokerPAMSecureButtonMounts");
    else
        A:UnlockButton("BrokerPAMSecureButtonMounts");
    end

    -- Refresh config panel
    if ( A.AceConfigRegistry ) then
        A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
    end
end

--[[-------------------------------------------------------------------------------
    Tooltips
-------------------------------------------------------------------------------]]--

--- Display button tooltip
function A:SetTooltip(frame)
    if ( not A.db.profile.BrokerPAMSecureButtonPets.tooltip and frame:GetName() == "BrokerPAMSecureButtonPets" ) then return; end
    if ( not A.db.profile.BrokerPAMSecureButtonMounts.tooltip and frame:GetName() == "BrokerPAMSecureButtonMounts" ) then return; end

    local currentSet;

    if ( frame:GetRight() >= ( GetScreenWidth() / 2 ) ) then
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT");
    else
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
    end

    GameTooltip:AddDoubleLine(A.color["WHITE"]..L["Pets & Mounts"], A.color["GREEN"].."v"..A.version);
    GameTooltip:AddLine(" ");

    if ( frame:GetName() == "BrokerPAMSecureButtonPets" ) then
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
    elseif ( frame:GetName() == "BrokerPAMSecureButtonMounts" ) then
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
