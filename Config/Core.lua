--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Config.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- Globals to locals
local ipairs = ipairs;
local pairs = pairs;
local type = type;
local tContains = tContains;
local strtrim = strtrim;
local tostring = tostring;
local tonumber = tonumber;

-- GLOBALS: GetCurrentBindingSet, SetBinding, SaveBindings, GetBindingKey, StaticPopup_Show
-- GLOBALS: InCombatLockdown, GetAddOnMetadata, LibStub, GetMapNameByID

-- Ace3 libs <3
A.AceConfigDialog = LibStub("AceConfigDialog-3.0");
A.AceConfigRegistry = LibStub("AceConfigRegistry-3.0");

local modelFrameSizeSelect =
{
    [100] = "100x100",
    [150] = "150x150",
    [200] = "200x200",
    [250] = "250x250",
    [300] = "300x300",
    [350] = "350x350",
    [400] = "400x400",
};

local dockAnchorsSelect =
{
    ["Top"] = L["Top"],
    ["Right"] = L["Right"],
    ["Bottom"] = L["Bottom"],
    ["Left"] = L["Left"],
};

-- Init addon databases
A:InitializeDB();

--[[-------------------------------------------------------------------------------
    Staticpopups
-------------------------------------------------------------------------------]]--

-- Set overwrite or dif name popup dialog
StaticPopupDialogs["PetsAndMountsOverwriteOrChangeNameSet"] =
{
    text = L["You already got a set named %s.\n\nEnter a new name or leave it blank to overwrite."],
    button1 = L["Accept"],
    button2 = L["Cancel"],
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    enterClicksFirstButton = true,
    OnShow = function(self) self.button1:Disable(); end,
    OnHide = function()
        A.newPetSetName = nil;
        A.newMountSetName = nil;
        A:NotifyChangeForAll();
    end,
    EditBoxOnTextChanged = function (self) self:GetParent().button1:Enable(); end,
    EditBoxOnEnterPressed = function(self)
        local name = strtrim(self:GetParent().editBox:GetText());

        if ( not name or name == "" ) then
            if ( A.newPetSetName ) then
                A.db.global.savedSets.pets[A.newPetSetName] = A:CopyTable(A.db.profile.favoritePets);
                A.newPetSetName = nil;
            elseif ( A.newMountSetName ) then
                A.db.global.savedSets.mounts[A.newMountSetName] = A:CopyTable(A.db.profile.favoriteMounts);
                A.newMountSetName = nil;
            end

            A:NotifyChangeForAll();
            return;
        end

        if ( A.newPetSetName ) then
            if ( A.db.global.savedSets.pets[name] ) then
                A:Message(L["Set %s already exists."]:format(name), 1);
            else
                A.db.global.savedSets.pets[name] = A:CopyTable(A.db.profile.favoritePets);
                A.newPetSetName = nil;
                self:GetParent():Hide();
            end
        elseif ( A.newMountSetName ) then
            if ( A.db.global.savedSets.mounts[name] ) then
                A:Message(L["Set %s already exists."]:format(name), 1);
            else
                A.db.global.savedSets.mounts[name] = A:CopyTable(A.db.profile.favoriteMounts);
                A.newPetSetName = nil;
                self:GetParent():Hide();
            end

            A:NotifyChangeForAll();
        end
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
    OnAccept = function(self)
        local name = strtrim(self.editBox:GetText());

        if ( not name or name == "" ) then
            if ( A.newPetSetName ) then
                A.db.global.savedSets.pets[A.newPetSetName] = A:CopyTable(A.db.profile.favoritePets);
                A.newPetSetName = nil;
            elseif ( A.newMountSetName ) then
                A.db.global.savedSets.mounts[A.newMountSetName] = A:CopyTable(A.db.profile.favoriteMounts);
                A.newMountSetName = nil;
            end

            A:NotifyChangeForAll();
            return;
        end

        if ( A.newPetSetName ) then
            if ( A.db.global.savedSets.pets[name] ) then
                A:Message(L["Set %s already exists."]:format(name), 1);
            else
                A.db.global.savedSets.pets[name] = A:CopyTable(A.db.profile.favoritePets);
                A.newPetSetName = nil;
            end
        elseif ( A.newMountSetName ) then
            if ( A.db.global.savedSets.mounts[name] ) then
                A:Message(L["Set %s already exists."]:format(name), 1);
            else
                A.db.global.savedSets.mounts[name] = A:CopyTable(A.db.profile.favoriteMounts);
                A.newPetSetName = nil;
            end

            A:NotifyChangeForAll();
        end
    end,
    preferredIndex = 3,
};

-- Confirm delete set popup dialog
StaticPopupDialogs["PetsAndMountsDeleteSet"] =
{
    text = L["Delete set %s?"],
    button1 = L["Accept"],
    button2 = L["Cancel"],
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    enterClicksFirstButton = true,
    OnHide = function()
        A.deleteSetPets = nil;
        A.deleteSetMounts = nil;
        A:NotifyChangeForAll();
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
    OnAccept = function(self)
        if ( A.deleteSetPets ) then
            A.db.global.savedSets.pets[A.deleteSetPets] = nil;
        elseif ( A.deleteSetMounts ) then
            A.db.global.savedSets.mounts[A.deleteSetMounts] = nil;
        end

        A:NotifyChangeForAll();
    end,
    preferredIndex = 3,
};

--[[-------------------------------------------------------------------------------
    Config table
-------------------------------------------------------------------------------]]--

local orderGroup, orderItem, petAutoSummonOverrideSelected;
local optionsOverrideHeaderText = L["None"];
function A:AceConfig()
    local options =
    {
        name = L["Pets & Mounts"],
        type = "group",
        args =
        {
            --
            -- Main options tree
            --
            options =
            {
                order = 0,
                name = L["Options"],
                type = "group",
                childGroups = "tab",
                args =
                {
                    --
                    -- Main options tree - Common tab
                    --
                    miscellaneousOptions =
                    {
                        order = 0,
                        name = L["Miscellaneous"],
                        type = "group",
                        args =
                        {
                            databaseOptions =
                            {
                                order = 0,
                                name = L["Database options"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    filterMultiple =
                                    {
                                        order = 0,
                                        name = L["Filter multiple"],
                                        desc = L["This will prevent adding to the list all the companions with same names."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.filterMultiple = not A.db.profile.filterMultiple;
                                            A:BuildPetsTable(1);
                                        end,
                                        get = function() return A.db.profile.filterMultiple; end,
                                    },
                                    noFilterCustom =
                                    {
                                        order = 1,
                                        name = L["Do not filter named companions"],
                                        desc = L["If the companion got a custom name it will not be filtered."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.noFilterCustom = not A.db.profile.noFilterCustom;
                                            A:BuildPetsTable(1);
                                        end,
                                        get = function() return A.db.profile.noFilterCustom; end,
                                    },
                                },
                            },
                            model =
                            {
                                order = 100,
                                name = L["Model frames"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    configHeader =
                                    {
                                        order = 0,
                                        name = L["Config frame"],
                                        type = "header",
                                    },
                                    configRotation =
                                    {
                                        order = 1,
                                        name = L["Model rotation"],
                                        desc = L["Activate the model rotation in the frame."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.configModelRotation = not A.db.profile.configModelRotation;

                                            if ( not A.db.profile.configModelRotation ) then
                                                A.configModelFrame.rotation = 0;
                                                A.configModelFrame:SetRotation(A.configModelFrame.rotation);
                                            end
                                        end,
                                        get = function() return A.db.profile.configModelRotation; end,
                                    },
                                    configSize =
                                    {
                                        order = 2,
                                        name = L["Size"],
                                        desc = L["Select the model frame size."],
                                        type = "select",
                                        values = modelFrameSizeSelect,
                                        get = function() return A.db.profile.configModelFrameWidth; end,
                                        set = function(info, val)
                                            A.db.profile.configModelFrameWidth = val;
                                            A.db.profile.configModelFrameHeight = val;
                                            A.configModelFrame:SetSize(A.db.profile.configModelFrameWidth, A.db.profile.configModelFrameHeight);
                                        end
                                    },
                                    menuHeader =
                                    {
                                        order = 10,
                                        name = L["Menu frame"],
                                        type = "header",
                                    },
                                    menuRotation =
                                    {
                                        order = 11,
                                        name = L["Model rotation"],
                                        desc = L["Activate the model rotation in the frame."],
                                        type = "toggle",
                                        set = function() A.db.profile.modelRotation = not A.db.profile.modelRotation; end,
                                        get = function() return A.db.profile.modelRotation; end,
                                    },
                                    menuSize =
                                    {
                                        order = 12,
                                        name = L["Size"],
                                        desc = L["Select the model frame size."],
                                        type = "select",
                                        values = modelFrameSizeSelect,
                                        get = function() return A.db.profile.modelFrameWidth; end,
                                        set = function(info, val)
                                            A.db.profile.modelFrameWidth = val;
                                            A.db.profile.modelFrameHeight = val;
                                            A.configModelFrame:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                                        end
                                    },
                                },
                            },
                            minimap =
                            {
                                order = 200,
                                name = L["Minimap"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    hideIcon =
                                    {
                                        order = 0,
                                        name = L["Show icon"],
                                        desc = L["Display an icon on the minimap."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.ldbi.hide = not A.db.profile.ldbi.hide;
                                            A:ShowHideMinimap();
                                        end,
                                        get = function() return not A.db.profile.ldbi.hide; end,
                                    },
                                },
                            },
                            debug =
                            {
                                order = 300,
                                name = L["Debug"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    debug =
                                    {
                                        order = 0,
                                        name = L["Debug"],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.debug = not A.db.profile.debug;
                                            A:SetDebugMessage();
                                        end,
                                        get = function() return A.db.profile.debug; end,
                                    },
                                },
                            },
                        },
                    },
                    --
                    -- Main options tree - Pets tab
                    --
                    petsOptions =
                    {
                        order = 100,
                        name = L["Companions"],
                        type = "group",
                        args =
                        {
                            petOptions =
                            {
                                order = 0,
                                name = L["Auto companion options"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    summon =
                                    {
                                        order = 0,
                                        name = L["Summon"],
                                        type = "header",
                                    },
                                    autoSummon =
                                    {
                                        order = 1,
                                        name = L["Auto summon"],
                                        desc = L["Auto summon a random companion."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.autoPet = not A.db.profile.autoPet;
                                            A:SetMainTimer();
                                        end,
                                        get = function() return A.db.profile.autoPet; end,
                                    },
                                    alreadyGotPet =
                                    {
                                        order = 2,
                                        name = L["Not with a companion"],
                                        desc = L["Auto summon will not work if you already have a companion, or it will summon a random favorite companion."],
                                        type = "toggle",
                                        set = function() A.db.profile.alreadyGotPet = not A.db.profile.alreadyGotPet; end,
                                        get = function() return A.db.profile.alreadyGotPet; end,
                                    },
                                    notWhenStealthed =
                                    {
                                        order = 3,
                                        name = L["Revoke when stealthed"],
                                        desc = L["If you got a companion it will dismiss it when going stealthed."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.notWhenStealthed = not A.db.profile.notWhenStealthed;
                                            A:SetStealthEvents();
                                        end,
                                        get = function() return A.db.profile.notWhenStealthed; end,
                                    },
                                    hauntedMemento =
                                    {
                                        order = 4,
                                        name = L["Haunted Memento"],
                                        desc = L["Do not automatically summon a pet when the Haunted Memento is in your bags."],
                                        type = "toggle",
                                        set = function() A.db.profile.hauntedMemento = not A.db.profile.hauntedMemento; end,
                                        get = function() return A.db.profile.hauntedMemento; end,
                                    },
                                    timers =
                                    {
                                        order = 20,
                                        name = L["Timers"],
                                        type = "header",
                                    },
                                    mainTimer =
                                    {
                                        order = 21,
                                        name = L["Auto summon timer"],
                                        desc = L["Select how often the addon will check if you got a companion."],
                                        type = "range",
                                        min = 1,
                                        max = 120,
                                        step = 1,
                                        width = "full",
                                        set = function(info, val)
                                            A.db.profile.mainTimer = val;
                                            A:SetMainTimer();
                                        end,
                                        get = function() return A.db.profile.mainTimer; end,
                                    },
                                    shiftTimer =
                                    {
                                        order = 22,
                                        name = L["Shift timer"],
                                        desc = L["Select the shift timer, this is the time before summoning a random companion after reviving, porting, unstealthing, etc."],
                                        type = "range",
                                        min = 1,
                                        max = 60,
                                        step = 1,
                                        width = "full",
                                        set = function(info, val) A.db.profile.shiftTimer = val; end,
                                        get = function() return A.db.profile.shiftTimer; end,
                                    },
                                },
                            },
                            petAutoSummonOverride =
                            {
                                order = 100,
                                name = L["Auto companion options override"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    enableHeader =
                                    {
                                        order = 0,
                                        name = L["Enable"],
                                        type = "header",
                                    },
                                    enableToggle =
                                    {
                                        order = 1,
                                        name = L["Enable"],
                                        desc = L["Enable auto pet options override."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.enableAutoSummonOverride = not A.db.profile.enableAutoSummonOverride;
                                        end,
                                        get = function() return A.db.profile.enableAutoSummonOverride; end,
                                    },
                                    areaSelectHeader =
                                    {
                                        order = 10,
                                        name = L["Area type"],
                                        type = "header",
                                    },
                                    areaSelect =
                                    {
                                        order = 11,
                                        name = L["Area type"],
                                        desc = L["Select witch type of area to work with."],
                                        type = "select",
                                        disabled = function() return not A.db.profile.enableAutoSummonOverride; end,
                                        values = function()
                                            local out = {};

                                            for k,v in ipairs(A.areaTypes) do
                                                out[v] = A.areaTypesLocales[v];
                                            end

                                            return out;
                                        end,
                                        set = function(info, val)
                                            petAutoSummonOverrideSelected = val;

                                            optionsOverrideHeaderText = A.areaTypesLocales[val];
                                        end,
                                        get = function()
                                            return petAutoSummonOverrideSelected;
                                        end,
                                    },
                                    optionsHeader =
                                    {
                                        order = 20,
                                        name = L["Override options for %s"]:format(optionsOverrideHeaderText),
                                        type = "header",
                                    },
                                    autoSummon =
                                    {
                                        order = 21,
                                        name = L["Auto summon"],
                                        desc = L["Auto summon a random companion."],
                                        type = "toggle",
                                        disabled = function()
                                            if ( not A.db.profile.enableAutoSummonOverride ) then
                                                return 1;
                                            end

                                            if ( not petAutoSummonOverrideSelected ) then
                                                return 1;
                                            end

                                            return nil;
                                        end,
                                        set = function()
                                            if ( not petAutoSummonOverrideSelected ) then return; end

                                            if ( not A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] ) then
                                                A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] = {};
                                            end

                                            A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].autoPet = not A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].autoPet;
                                        end,
                                        get = function()
                                            if ( A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] ) then
                                                return A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].autoPet;
                                            else
                                                return nil;
                                            end
                                        end,
                                    },
                                    notWhenStealthed =
                                    {
                                        order = 22,
                                        name = L["Revoke when stealthed"],
                                        desc = L["If you got a companion it will dismiss it when going stealthed."],
                                        type = "toggle",
                                        disabled = function()
                                            if ( not A.db.profile.enableAutoSummonOverride ) then
                                                return 1;
                                            end

                                            if ( not petAutoSummonOverrideSelected ) then
                                                return 1;
                                            end

                                            return nil;
                                        end,
                                        set = function()
                                            if ( not petAutoSummonOverrideSelected ) then return; end

                                            if ( not A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] ) then
                                                A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] = {};
                                            end

                                            A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].notWhenStealthed = not A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].notWhenStealthed;
                                        end,
                                        get = function()
                                            if ( A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] ) then
                                                return A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].notWhenStealthed;
                                            else
                                                return nil;
                                            end
                                        end,
                                    },
                                },
                            },
                            petsSummonFilters =
                            {
                                order = 200,
                                name = L["Companions auto summon filters"],
                                type = "group",
                                inline = true,
                                args = {},
                            },
                            petListOptions =
                            {
                                order = 300,
                                name = L["Companions list options"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    appendDefaultName =
                                    {
                                        order = 0,
                                        name = L["Append default name"],
                                        desc = L["When a companion got a custom name, it will append its default name."],
                                        type = "toggle",
                                        set = function() A.db.profile.appendPetDefaultName = not A.db.profile.appendPetDefaultName; end,
                                        get = function() return A.db.profile.appendPetDefaultName; end,
                                    },
                                    colorCustomName =
                                    {
                                        order = 1,
                                        name = L["Color custom name"],
                                        desc = L["When a companion got a custom name, it will be colored."],
                                        type = "toggle",
                                        set = function() A.db.profile.colorPetWithCustomName = not A.db.profile.colorPetWithCustomName; end,
                                        get = function() return A.db.profile.colorPetWithCustomName; end,
                                    },
                                    customNameColorPicker =
                                    {
                                        order = 2,
                                        name = L["Custom name color"],
                                        desc = L["Pick a color for your companions custom names."],
                                        type = "color",
                                        hasAlpha = true,
                                        set = function(info, r, g, b, a)
                                            A.db.profile.petWithCustomNameColor.r = r;
                                            A.db.profile.petWithCustomNameColor.g = g;
                                            A.db.profile.petWithCustomNameColor.b = b;
                                            A.db.profile.petWithCustomNameColor.a = a;
                                            A.db.profile.petWithCustomNameColor.hexa = "|c"..A:PercentToHex(r, g, b, a);
                                        end,
                                        get = function()
                                            return A.db.profile.petWithCustomNameColor.r,
                                            A.db.profile.petWithCustomNameColor.g,
                                            A.db.profile.petWithCustomNameColor.b,
                                            A.db.profile.petWithCustomNameColor.a;
                                        end,
                                    },
                                },
                            },
                        },
                    },
                    --
                    -- Main options tree - Mounts tab
                    --
                    mountsOptions =
                    {
                        order = 300,
                        name = L["Mounts"],
                        type = "group",
                        args =
                        {
                            mountOptions =
                            {
                                order = 0,
                                name = L["Random mount options"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    noHybridWhenGround =
                                    {
                                        order = 0,
                                        name = L["No hybrid (Ground)"],
                                        desc = L["Do not summon an hybrid mount in a ground only area."],
                                        type = "toggle",
                                        set = function() A.db.profile.noHybridWhenGround = not A.db.profile.noHybridWhenGround; end,
                                        get = function() return A.db.profile.noHybridWhenGround; end,
                                    },
                                    noHybridWhenFly =
                                    {
                                        order = 1,
                                        name = L["No hybrid (Fly)"],
                                        desc = L["Do not summon an hybrid mount in a flyable area."],
                                        type = "toggle",
                                        set = function() A.db.profile.noHybridWhenFly = not A.db.profile.noHybridWhenFly; end,
                                        get = function() return A.db.profile.noHybridWhenFly; end,
                                    },
                                    dismountFlying =
                                    {
                                        order = 2,
                                        name = L["Flying dismount"],
                                        desc = L["Using the random mount bind when flying will dismount you."],
                                        type = "toggle",
                                        set = function() A.db.profile.dismountFlying = not A.db.profile.dismountFlying; end,
                                        get = function() return A.db.profile.dismountFlying; end,
                                    },
                                    areaMounts =
                                    {
                                        order = 3,
                                        name = L["Area mounts"],
                                        desc = L["With this enabled it will summon a specific mount according to your current area. Example: the Abyssal Seahorse in Vashj'ir."],
                                        type = "toggle",
                                        set = function() A.db.profile.areaMounts = not A.db.profile.areaMounts; end,
                                        get = function() return A.db.profile.areaMounts; end,
                                    },
                                    classesMacrosEnabled =
                                    {
                                        order = 4,
                                        name = L["Class specific"],
                                        desc = L["With this enabled it will use flying forms for druids (Only class with specific \"mount\" atm)."],
                                        type = "toggle",
                                        set = function() A.db.profile.classesMacrosEnabled = not A.db.profile.classesMacrosEnabled; end,
                                        get = function() return A.db.profile.classesMacrosEnabled; end,
                                    },
                                    surfaceMount =
                                    {
                                        order = 6,
                                        name = L["Surface mount"],
                                        desc = L["If you are in a non flyable area and at the water surface, it will summon a mount able to walk on water. Support Death Knights Path of Frost, Shamans Water Walking and Warlocks glyph."],
                                        type = "toggle",
                                        set = function() A.db.profile.surfaceMount = not A.db.profile.surfaceMount; end,
                                        get = function() return A.db.profile.surfaceMount; end,
                                    },
                                    preferSurfaceSpell =
                                    {
                                        order = 7,
                                        name = L["Prefer surface spell"],
                                        desc = L["If surface mount options is enabled, it will prefer using your water walking spell other the mount. This only works for Death Knights and Shamans."],
                                        type = "toggle",
                                        set = function() A.db.profile.preferSurfaceSpell = not A.db.profile.preferSurfaceSpell; end,
                                        get = function() return A.db.profile.preferSurfaceSpell; end,
                                    },
                                    vehicleExit =
                                    {
                                        order = 8,
                                        name = L["Vehicle exit"],
                                        desc = L["If you are in a vehicle using the random mount will make you leave the vehicle."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.vehicleExit = not A.db.profile.vehicleExit;
                                            A:SetMacroDismountString();
                                            A:SetPostClickMacro();
                                        end,
                                        get = function() return A.db.profile.vehicleExit; end,
                                    },
                                    magicBroom =
                                    {
                                        order = 1000,
                                        name = L["Magic Broom"],
                                        desc = L["Summon the Magic Broom when it is in your bags."],
                                        type = "toggle",
                                        set = function() A.db.profile.magicBroom = not A.db.profile.magicBroom; end,
                                        get = function() return A.db.profile.magicBroom; end,
                                    },
                                    shimmeringMoonstone =
                                    {
                                        order = 1001,
                                        name = L["Shimmering Moonstone"],
                                        desc = L["Summon Moonfang when the Shimmering Moonstone is in your bags."],
                                        type = "toggle",
                                        set = function() A.db.profile.shimmeringMoonstone = not A.db.profile.shimmeringMoonstone; end,
                                        get = function() return A.db.profile.shimmeringMoonstone; end,
                                    },
                                },
                            },
                            mountsSummonFilters =
                            {
                                order = 100,
                                name = L["Random mount summon filters"],
                                type = "group",
                                inline = true,
                                args = {},
                            },
                        },
                    },
                    --
                    -- Main options tree - Bindings tab
                    --
                    bindings =
                    {
                        order = 400,
                        name = L["Bindings"],
                        type = "group",
                        args =
                        {
                            randomPet =
                            {
                                order = 0,
                                name = L["Random companion"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    randomPetKey1 =
                                    {
                                        order = 0,
                                        name = L["Key one"],
                                        desc = L["Bind a key to summon a random companion."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSPET", set);
                                            SaveBindings(set);
                                        end,
                                        get = function() return GetBindingKey("PETSANDMOUNTSPET"); end,
                                    },
                                    randomPetKey2 =
                                    {
                                        order = 1,
                                        name = L["Key two"],
                                        desc = L["Bind a key to summon a random companion."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSPET", set);
                                            SaveBindings(set);
                                        end,
                                        get = function()
                                            local _, key = GetBindingKey("PETSANDMOUNTSPET");
                                            return key;
                                        end,
                                    },
                                },
                            },
                            randomMount =
                            {
                                order = 1,
                                name = L["Random mount"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    randomMountKey1 =
                                    {
                                        order = 0,
                                        name = L["Key one"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNT", set);
                                            SaveBindings(set);
                                        end,
                                        get = function() return GetBindingKey("PETSANDMOUNTSMOUNT"); end,
                                    },
                                    randomMountKey2 =
                                    {
                                        order = 1,
                                        name = L["Key two"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNT", set);
                                            SaveBindings(set);
                                        end,
                                        get = function()
                                            local _, key = GetBindingKey("PETSANDMOUNTSMOUNT");
                                            return key;
                                        end,
                                    },
                                },
                            },
                            randomPassengersMount =
                            {
                                order = 2,
                                name = L["Random passengers mount"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    randomPassengerMountKey1 =
                                    {
                                        order = 0,
                                        name = L["Key one"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTPASSENGERS", set);
                                            SaveBindings(set);
                                        end,
                                        get = function() return GetBindingKey("PETSANDMOUNTSMOUNTPASSENGERS"); end,
                                    },
                                    randomPassengerMountKey2 =
                                    {
                                        order = 1,
                                        name = L["Key two"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTPASSENGERS", set);
                                            SaveBindings(set);
                                        end,
                                        get = function()
                                            local _, key = GetBindingKey("PETSANDMOUNTSMOUNTPASSENGERS");
                                            return key;
                                        end,
                                    },
                                },
                            },
                            randomFlyingMount =
                            {
                                order = 3,
                                name = L["Random flying mount"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    randomFlyMountKey1 =
                                    {
                                        order = 0,
                                        name = L["Key one"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTFLYING", set);
                                            SaveBindings(set);
                                        end,
                                        get = function() return GetBindingKey("PETSANDMOUNTSMOUNTFLYING"); end,
                                    },
                                    randomFlyMountKey2 =
                                    {
                                        order = 1,
                                        name = L["Key two"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTFLYING", set);
                                            SaveBindings(set);
                                        end,
                                        get = function()
                                            local _, key = GetBindingKey("PETSANDMOUNTSMOUNTFLYING");
                                            return key;
                                        end,
                                    },
                                },
                            },
                            randomGroundMount =
                            {
                                order = 4,
                                name = L["Random ground mount"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    randomGroundMountKey1 =
                                    {
                                        order = 0,
                                        name = L["Key one"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTGROUND", set);
                                            SaveBindings(set);
                                        end,
                                        get = function() return GetBindingKey("PETSANDMOUNTSMOUNTGROUND"); end,
                                    },
                                    randomGroundMountKey2 =
                                    {
                                        order = 1,
                                        name = L["Key two"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTGROUND", set);
                                            SaveBindings(set);
                                        end,
                                        get = function()
                                            local _, key = GetBindingKey("PETSANDMOUNTSMOUNTGROUND");
                                            return key;
                                        end,
                                    },
                                },
                            },
                            randomAquaticMount =
                            {
                                order = 5,
                                name = L["Random aquatic mount"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    randomAquaticMountKey1 =
                                    {
                                        order = 0,
                                        name = L["Key one"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTAQUATIC", set);
                                            SaveBindings(set);
                                        end,
                                        get = function() return GetBindingKey("PETSANDMOUNTSMOUNTAQUATIC"); end,
                                    },
                                    randomAquaticMountKey2 =
                                    {
                                        order = 1,
                                        name = L["Key two"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTAQUATIC", set);
                                            SaveBindings(set);
                                        end,
                                        get = function()
                                            local _, key = GetBindingKey("PETSANDMOUNTSMOUNTAQUATIC");
                                            return key;
                                        end,
                                    },
                                },
                            },
                            randomSurfaceMount =
                            {
                                order = 6,
                                name = L["Random surface mount"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    randomSurfaceMountKey1 =
                                    {
                                        order = 0,
                                        name = L["Key one"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTSURFACE", set);
                                            SaveBindings(set);
                                        end,
                                        get = function() return GetBindingKey("PETSANDMOUNTSMOUNTSURFACE"); end,
                                    },
                                    randomSurfaceMountKey2 =
                                    {
                                        order = 1,
                                        name = L["Key two"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTSURFACE", set);
                                            SaveBindings(set);
                                        end,
                                        get = function()
                                            local _, key = GetBindingKey("PETSANDMOUNTSMOUNTSURFACE");
                                            return key;
                                        end,
                                    },
                                },
                            },
                            randomRepairMount =
                            {
                                order = 7,
                                name = L["Random repair mount"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    randomRepairMountKey1 =
                                    {
                                        order = 0,
                                        name = L["Key one"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTREPAIR", set);
                                            SaveBindings(set);
                                        end,
                                        get = function() return GetBindingKey("PETSANDMOUNTSMOUNTREPAIR"); end,
                                    },
                                    randomRepairMountKey2 =
                                    {
                                        order = 1,
                                        name = L["Key two"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTREPAIR", set);
                                            SaveBindings(set);
                                        end,
                                        get = function()
                                            local _, key = GetBindingKey("PETSANDMOUNTSMOUNTREPAIR");
                                            return key;
                                        end,
                                    },
                                },
                            },
                            randomHybridMount =
                            {
                                order = 8,
                                name = L["Random hybrid mount"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    randomRepairMountKey1 =
                                    {
                                        order = 0,
                                        name = L["Key one"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTHYBRID", set);
                                            SaveBindings(set);
                                        end,
                                        get = function() return GetBindingKey("PETSANDMOUNTSMOUNTHYBRID"); end,
                                    },
                                    randomRepairMountKey2 =
                                    {
                                        order = 1,
                                        name = L["Key two"],
                                        desc = L["Bind a key to summon a random mount."],
                                        type = "keybinding",
                                        set = function(info, val)
                                            local set = GetCurrentBindingSet();

                                            SetBinding(val, "PETSANDMOUNTSMOUNTHYBRID", set);
                                            SaveBindings(set);
                                        end,
                                        get = function()
                                            local _, key = GetBindingKey("PETSANDMOUNTSMOUNTHYBRID");
                                            return key;
                                        end,
                                    },
                                },
                            },
                        },
                    },
                    --
                    -- Main options tree - Buttons tab
                    --
                    buttons =
                    {
                        order = 400,
                        name = L["Buttons"],
                        type = "group",
                        args =
                        {
                            petsButton =
                            {
                                order = 0,
                                name = L["Companions button"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    petHide =
                                    {
                                        order = 0,
                                        name = L["Hide"],
                                        desc = L["Hide the companions button."],
                                        type = "toggle",
                                        set = function()
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            A.db.profile.PetsAndMountsSecureButtonPets.hide = not A.db.profile.PetsAndMountsSecureButtonPets.hide;
                                            A:SetButtons();
                                        end,
                                        get = function() return A.db.profile.PetsAndMountsSecureButtonPets.hide; end,
                                    },
                                    petLock =
                                    {
                                        order = 1,
                                        name = L["Lock"],
                                        desc = L["Lock the companions button."],
                                        type = "toggle",
                                        set = function()
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            if ( A.db.profile.dockButton ) then
                                                return;
                                            end

                                            A.db.profile.PetsAndMountsSecureButtonPets.lock = not A.db.profile.PetsAndMountsSecureButtonPets.lock;
                                            A:SetButtons();
                                        end,
                                        get = function() return A.db.profile.PetsAndMountsSecureButtonPets.lock; end,
                                    },
                                    petTooltip =
                                    {
                                        order = 2,
                                        name = L["Tooltip"],
                                        desc = L["Enable the tooltip of the companions button."],
                                        type = "toggle",
                                        set = function() A.db.profile.PetsAndMountsSecureButtonPets.tooltip = not A.db.profile.PetsAndMountsSecureButtonPets.tooltip; end,
                                        get = function() return A.db.profile.PetsAndMountsSecureButtonPets.tooltip; end,
                                    },
                                    petScale =
                                    {
                                        order = 3,
                                        name = L["Scale"],
                                        desc = L["Set the scale of the companions button."],
                                        type = "range",
                                        width = "full",
                                        min = 0.1,
                                        max = 5,
                                        step = 0.1,
                                        set = function(info, val)
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            A.db.profile.PetsAndMountsSecureButtonPets.scale = val;
                                            A:SetButtons();
                                        end,
                                        get = function() return A.db.profile.PetsAndMountsSecureButtonPets.scale; end,
                                    },
                                    petReset =
                                    {
                                        order = 4,
                                        name = L["Reset"],
                                        desc = L["Reset the companions button configuration."],
                                        type = "execute",
                                        func = function()
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            A.db.profile.PetsAndMountsSecureButtonPets =
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
                                                    offX = 0,
                                                    offY = 0,
                                                },
                                            };

                                            A:SetButtons();
                                        end,
                                    },
                                },
                            },
                            mountsButton =
                            {
                                order = 1,
                                name = L["Mounts button"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    mountHide =
                                    {
                                        order = 0,
                                        name = L["Hide"],
                                        desc = L["Hide the mounts button."],
                                        type = "toggle",
                                        set = function()
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            A.db.profile.PetsAndMountsSecureButtonMounts.hide = not A.db.profile.PetsAndMountsSecureButtonMounts.hide;
                                            A:SetButtons();
                                        end,
                                        get = function() return A.db.profile.PetsAndMountsSecureButtonMounts.hide; end,
                                    },
                                    mountLock =
                                    {
                                        order = 1,
                                        name = L["Lock"],
                                        desc = L["Lock the mounts button."],
                                        type = "toggle",
                                        set = function()
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            A.db.profile.PetsAndMountsSecureButtonMounts.lock = not A.db.profile.PetsAndMountsSecureButtonMounts.lock;
                                            A:SetButtons();
                                        end,
                                        get = function() return A.db.profile.PetsAndMountsSecureButtonMounts.lock; end,
                                    },
                                    mountTooltip =
                                    {
                                        order = 2,
                                        name = L["Tooltip"],
                                        desc = L["Enable the tooltip of the mounts button."],
                                        type = "toggle",
                                        set = function() A.db.profile.PetsAndMountsSecureButtonMounts.tooltip = not A.db.profile.PetsAndMountsSecureButtonMounts.tooltip; end,
                                        get = function() return A.db.profile.PetsAndMountsSecureButtonMounts.tooltip; end,
                                    },
                                    mountScale =
                                    {
                                        order = 3,
                                        name = L["Scale"],
                                        desc = L["Set the scale of the mounts button."],
                                        type = "range",
                                        width = "full",
                                        min = 0.1,
                                        max = 5,
                                        step = 0.1,
                                        set = function(info, val)
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            A.db.profile.PetsAndMountsSecureButtonMounts.scale = val;
                                            A:SetButtons();
                                        end,
                                        get = function() return A.db.profile.PetsAndMountsSecureButtonMounts.scale; end,
                                    },
                                    mountReset =
                                    {
                                        order = 4,
                                        name = L["Reset"],
                                        desc = L["Reset the mounts button configuration."],
                                        type = "execute",
                                        func = function()
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            A.db.profile.PetsAndMountsSecureButtonMounts =
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
                                                    offX = 0,
                                                    offY = 0,
                                                },
                                            };

                                            A:SetButtons();
                                        end,
                                    },
                                },
                            },
                            dock =
                            {
                                order = 2,
                                name = L["Dock options"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    dock =
                                    {
                                        order = 0,
                                        name = L["Dock"],
                                        desc = L["Dock companion button to the mount button."],
                                        type = "toggle",
                                        set = function()
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            if ( A.db.profile.PetsAndMountsSecureButtonMounts.hide or A.db.profile.PetsAndMountsSecureButtonPets.hide ) then
                                                A:Message(L["Cannot dock buttons together when at least one of them is hidden."], 1);
                                                return;
                                            end

                                            A.db.profile.dockButton = not A.db.profile.dockButton;

                                            if ( A.db.profile.dockButton ) then
                                                A:DockButton();
                                            else
                                                A:UnDockButton();
                                            end
                                        end,
                                        get = function() return A.db.profile.dockButton; end,
                                    },
                                    dockAnchor =
                                    {
                                        order = 1,
                                        name = L["Dock anchor"],
                                        desc = L["Select on which side of the mounts button the companions button should dock."],
                                        type = "select",
                                        values = dockAnchorsSelect,
                                        set = function(info, val)
                                            if ( InCombatLockdown() ) then
                                                A:Message(L["Unable to edit buttons while in combat."], 1);
                                                return;
                                            end

                                            A.db.profile.dockAnchor = val;
                                            A:DockButton();
                                        end,
                                        get = function() return A.db.profile.dockAnchor; end,
                                    },
                                },
                            },
                        },
                    },
                },
            },
            --
            -- Pets list tree
            --
            pets =
            {
                order = 10,
                name = L["Companions list"],
                type = "group",
                childGroups = "tab",
                args = {},
            },
            --
            -- Mounts list tree
            --
            mounts =
            {
                order = 20,
                name = L["Mounts list"],
                type = "group",
                childGroups = "tab",
                args = {},
            },
            --
            -- Sets tree
            --
            sets =
            {
                order = 30,
                name = L["Sets options"],
                type = "group",
                args =
                {
                    pets =
                    {
                        order = 0,
                        name = L["Companions"],
                        type = "group",
                        inline = true,
                        args =
                        {
                            current =
                            {
                                order = 0,
                                name = function()
                                    local current = A:GetCurrentSet("PET");

                                    return L["Currently using set: %s\n\n"]:format(current);
                                end,
                                type = "description",
                                fontSize = "medium",
                            },
                            load =
                            {
                                order = 10,
                                name = L["Load"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    select =
                                    {
                                        order = 0,
                                        name = L["Load"],
                                        type = "select",
                                        values = function()
                                            local out = {};

                                            for k in pairs(A.db.global.savedSets.pets) do
                                                out[k] = k;
                                            end

                                            return out;
                                        end,
                                        get = function() return nil; end,
                                        set = function(info, val)
                                            if ( A.db.global.savedSets.pets[val] ) then
                                                A.db.profile.favoritePets = {};
                                                A:CopyTable(A.db.global.savedSets.pets[val], A.db.profile.favoritePets);
                                            end
                                        end,
                                    },
                                },
                            },
                            save =
                            {
                                order = 20,
                                name = L["Save"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    input =
                                    {
                                        order = 0,
                                        name = L["Name"],
                                        type = "input",
                                        set = function(info, val) A.newPetSetName = val; end,
                                        get = function() return A.newPetSetName; end,
                                    },
                                    exec =
                                    {
                                        order = 1,
                                        name = L["Save"],
                                        type = "execute",
                                        disabled = function()
                                            if ( A.newPetSetName ) then
                                                return nil;
                                            end

                                            return 1;
                                        end,
                                        func = function()
                                            if ( #A.db.profile.favoritePets == 0 ) then
                                                A:Message(L["You have no favorite selected."], 1);
                                                A.newPetSetName = nil;
                                            elseif ( A.db.global.savedSets.pets[A.newPetSetName] ) then
                                                StaticPopup_Show("PetsAndMountsOverwriteOrChangeNameSet", A.newPetSetName);
                                            else
                                                A.db.global.savedSets.pets[A.newPetSetName] = A:CopyTable(A.db.profile.favoritePets);
                                                A:Message(L["New companions set %s added."]:format(A.newPetSetName));
                                                A.newPetSetName = nil;
                                            end
                                        end,
                                    },
                                },
                            },
                            delete =
                            {
                                order = 30,
                                name = L["Delete"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    select =
                                    {
                                        order = 0,
                                        name = L["Choose"],
                                        type = "select",
                                        values = function()
                                            local out = {};

                                            for k in pairs(A.db.global.savedSets.pets) do
                                                out[k] = k;
                                            end

                                            return out;
                                        end;
                                        get = function() return A.deleteSetPets; end,
                                        set = function(info, val)
                                            A.deleteSetMounts = nil;
                                            A.deleteSetPets = val;
                                        end,
                                    },
                                    exec =
                                    {
                                        order = 1,
                                        name = L["Delete"],
                                        type = "execute",
                                        disabled = function() return not A.deleteSetPets; end,
                                        func = function()
                                            StaticPopup_Show("PetsAndMountsDeleteSet", A.deleteSetPets);
                                        end,
                                    },
                                },
                            },
                        },
                    },
                    mounts =
                    {
                        order = 0,
                        name = L["Mounts"],
                        type = "group",
                        inline = true,
                        args =
                        {
                            current =
                            {
                                order = 0,
                                name = function()
                                    local current = A:GetCurrentSet("MOUNT");

                                    return L["Currently using set: %s\n\n"]:format(current);
                                end,
                                type = "description",
                                fontSize = "medium",
                            },
                            load =
                            {
                                order = 10,
                                name = L["Load"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    select =
                                    {
                                        order = 0,
                                        name = L["Load"],
                                        type = "select",
                                        values = function()
                                            local out = {};

                                            for k in pairs(A.db.global.savedSets.mounts) do
                                                out[k] = k;
                                            end

                                            return out;
                                        end,
                                        get = function() return nil; end,
                                        set = function(info, val)
                                            if ( A.db.global.savedSets.mounts[val] ) then
                                                A.db.profile.favoriteMounts = {};
                                                A:CopyTable(A.db.global.savedSets.mounts[val], A.db.profile.favoriteMounts);
                                            end
                                        end,
                                    },
                                },
                            },
                            save =
                            {
                                order = 30,
                                name = L["Save"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    input =
                                    {
                                        order = 0,
                                        name = L["Name"],
                                        type = "input",
                                        set = function(info, val) A.newMountSetName = val; end,
                                        get = function() return A.newMountSetName; end,
                                    },
                                    exec =
                                    {
                                        order = 1,
                                        name = L["Save"],
                                        type = "execute",
                                        disabled = function() 
                                            if ( A.newMountSetName ) then
                                                return nil;
                                            end

                                            return 1;
                                        end,
                                        func = function()
                                            local gotOne;

                                            for k,v in ipairs(A.db.profile.favoriteMounts) do
                                                if ( #v > 0 ) then gotOne = 1; end
                                            end

                                            if ( not gotOne ) then
                                                A:Message(L["You have no favorite selected."], 1);
                                                A.newMountSetName = nil;
                                            elseif ( A.db.global.savedSets.mounts[A.newMountSetName] ) then
                                                StaticPopup_Show("PetsAndMountsOverwriteOrChangeNameSet", A.newMountSetName);
                                            else
                                                A.db.global.savedSets.mounts[A.newMountSetName] = A:CopyTable(A.db.profile.favoriteMounts);
                                                A:Message(L["New mounts set %s added."]:format(A.newMountSetName));
                                                A.newMountSetName = nil;
                                            end
                                        end,
                                    },
                                },
                            },
                            delete =
                            {
                                order = 40,
                                name = L["Delete"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    select =
                                    {
                                        order = 0,
                                        name = L["Choose"],
                                        type = "select",
                                        values = function()
                                            local out = {};

                                            for k in pairs(A.db.global.savedSets.mounts) do
                                                out[k] = k;
                                            end

                                            return out;
                                        end;
                                        get = function() return A.deleteSetMounts; end,
                                        set = function(info, val)
                                            A.deleteSetPets = nil;
                                            A.deleteSetMounts = val;
                                        end,
                                    },
                                    exec =
                                    {
                                        order = 1,
                                        name = L["Delete"],
                                        type = "execute",
                                        disabled = function() return not A.deleteSetMounts; end,
                                        func = function()
                                            StaticPopup_Show("PetsAndMountsDeleteSet", A.deleteSetMounts);
                                        end,
                                    },
                                },
                            },
                        },
                    },
                },
            },
            --
            -- Favorites override options tree
            --
            favOverride =
            {
                order = 40,
                name = L["Favorites override"],
                type = "group",
                childGroups = "tab",
                args =
                {
                    --
                    -- Favorites override options tree - Force one tab
                    --
                    forceOne =
                    {
                        order = 0,
                        name = L["Force One"],
                        type = "group",
                        args =
                        {
                            pets =
                            {
                                order = 0,
                                name = L["Companions"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    pet =
                                    {
                                        order = 0,
                                        name = L["Companions"],
                                        desc = L["Select the companion to force summon."],
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                        -- Using a string instead of an integer for "None", since blizzard stopped using ID but use GUID for pets
                                        -- Why? Because Ace3 sort keys (btw sorting values would have been better or giving choices)
                                        -- Fu, rewriting SetList method from dropdown widget
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.pets) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.petID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function() return A.db.profile.forceOne.pet; end,
                                        set = function(info, val)
                                            if ( val == 0 ) then
                                                A.db.profile.forceOne.pet = nil;
                                            else
                                                A.db.profile.forceOne.pet = val;
                                            end
                                        end,
                                    },
                                },
                            },
                            mounts =
                            {
                                order = 10,
                                name = L["Mounts"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    aquatic =
                                    {
                                        order = 0,
                                        name = L["Aquatic"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Aquatic"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[4]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function() return A.db.profile.forceOne.mount[4]; end,
                                        set = function(info, val)
                                            if ( val == 0 ) then
                                                A.db.profile.forceOne.mount[4] = nil;
                                            else
                                                A.db.profile.forceOne.mount[4] = val;
                                            end
                                        end,
                                    },
                                    ground =
                                    {
                                        order = 1,
                                        name = L["Ground"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Ground"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[1]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function() return A.db.profile.forceOne.mount[1]; end,
                                        set = function(info, val)
                                            if ( val == 0 ) then
                                                A.db.profile.forceOne.mount[1] = nil;
                                            else
                                                A.db.profile.forceOne.mount[1] = val;
                                            end
                                        end,
                                    },
                                    fly =
                                    {
                                        order = 2,
                                        name = L["Fly"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Fly"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[2]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function() return A.db.profile.forceOne.mount[2]; end,
                                        set = function(info, val)
                                            if ( val == 0 ) then
                                                A.db.profile.forceOne.mount[2] = nil;
                                            else
                                                A.db.profile.forceOne.mount[2] = val;
                                            end
                                        end,
                                    },
                                    hybrid =
                                    {
                                        order = 3,
                                        name = L["Hybrid"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Hybrid"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[3]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function() return A.db.profile.forceOne.mount[3]; end,
                                        set = function(info, val)
                                            if ( val == 0 ) then
                                                A.db.profile.forceOne.mount[3] = nil;
                                            else
                                                A.db.profile.forceOne.mount[3] = val;
                                            end
                                        end,
                                    },
                                    passenger =
                                    {
                                        order = 4,
                                        name = L["Passenger"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Passenger"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[5]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function() return A.db.profile.forceOne.mount[5]; end,
                                        set = function(info, val)
                                            if ( val == 0 ) then
                                                A.db.profile.forceOne.mount[5] = nil;
                                            else
                                                A.db.profile.forceOne.mount[5] = val;
                                            end
                                        end,
                                    },
                                    surface =
                                    {
                                        order = 5,
                                        name = L["Surface"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Surface"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[6]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function() return A.db.profile.forceOne.mount[6]; end,
                                        set = function(info, val)
                                            if ( val == 0 ) then
                                                A.db.profile.forceOne.mount[6] = nil;
                                            else
                                                A.db.profile.forceOne.mount[6] = val;
                                            end
                                        end,
                                    },
                                    repair =
                                    {
                                        order = 6,
                                        name = L["Repair"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Repair"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[7]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function() return A.db.profile.forceOne.mount[7]; end,
                                        set = function(info, val)
                                            if ( val == 0 ) then
                                                A.db.profile.forceOne.mount[7] = nil;
                                            else
                                                A.db.profile.forceOne.mount[7] = val;
                                            end
                                        end,
                                    },
                                },
                            },
                        },
                    },
                    --
                    -- Favorites override options tree - Zone override tab
                    --
                    zoneOverride =
                    {
                        order = 100,
                        name = L["Area override"],
                        type = "group",
                        args =
                        {
                            pets =
                            {
                                order = 0,
                                name = L["Companions"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    zoneSelectHeader =
                                    {
                                        order = 0,
                                        name = L["Area selection"],
                                        type = "header",
                                    },
                                    currentZone =
                                    {
                                        order = 1,
                                        name = function()
                                            local mapID;

                                            if ( A.currentMapIDForPets ) then
                                                mapID = A.currentMapIDForPets;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            return L["Currently working with: %s\n\n"]:format(GetMapNameByID(tonumber(mapID)));
                                        end,
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    zoneSelect =
                                    {
                                        order = 10,
                                        name = L["Area selection"],
                                        desc = L["Select the area you want to work with."],
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            if ( A:TableCount(A.db.global.zonesIDsToName) > 0 ) then
                                                return A.db.global.zonesIDsToName;
                                            else
                                                return {};
                                            end
                                        end,
                                        get = function() return A.currentMapIDForPets; end,
                                        set = function(info, val) A.currentMapIDForPets = val; end,
                                    },
                                    zoneSelectPet =
                                    {
                                        order = 100,
                                        name = L["Companions"],
                                        type = "header",
                                    },
                                    pet =
                                    {
                                        order = 110,
                                        name = L["Companions"],
                                        desc = L["Select the companion to force summon."],
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.pets) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.petID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function()
                                            local mapID;

                                            if ( A.currentMapIDForPets ) then
                                                mapID = A.currentMapIDForPets;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( A.db.profile.petByMapID[tostring(mapID)] ) then
                                                return A.db.profile.petByMapID[tostring(mapID)];
                                            else
                                                return 0;
                                            end
                                        end,
                                        set = function(info, val)
                                            local mapID;

                                            if ( A.currentMapIDForPets ) then
                                                mapID = A.currentMapIDForPets;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( val == 0 ) then
                                                A.db.profile.petByMapID[tostring(mapID)] = nil;
                                            else
                                                A.db.profile.petByMapID[tostring(mapID)] = val;
                                            end
                                        end,
                                    },
                                    zoneSelectReset =
                                    {
                                        order = 200,
                                        name = L["Reset"],
                                        type = "header",
                                    },
                                    zoneReset =
                                    {
                                        order = 201,
                                        name = L["Reset"],
                                        desc = L["Use this to reset the working area to the current area."],
                                        type = "execute",
                                        func = function() A.currentMapIDForPets = nil; end,
                                    },
                                },
                            },
                            mounts =
                            {
                                order = 100,
                                name = L["Mounts"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    zoneSelectHeader =
                                    {
                                        order = 0,
                                        name = L["Area selection"],
                                        type = "header",
                                    },
                                    currentZone =
                                    {
                                        order = 1,
                                        name = function()
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            return L["Currently working with: %s\n\n"]:format(GetMapNameByID(mapID));
                                        end,
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    zoneSelect =
                                    {
                                        order = 10,
                                        name = L["Area selection"],
                                        desc = L["Select the area you want to work with."],
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            if ( A:TableCount(A.db.global.zonesIDsToName) > 0 ) then
                                                return A.db.global.zonesIDsToName;
                                            else
                                                return {};
                                            end
                                        end,
                                        get = function() return A.currentMapIDForMounts; end,
                                        set = function(info, val) A.currentMapIDForMounts = val; end,
                                    },
                                    zoneSelectMounts =
                                    {
                                        order = 100,
                                        name = L["Mounts"],
                                        type = "header",
                                    },
                                    aquatic =
                                    {
                                        order = 101,
                                        name = L["Aquatic"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Aquatic"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[4]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function()
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( A.db.profile.mountByMapID[4][tostring(mapID)] ) then
                                                return A.db.profile.mountByMapID[4][tostring(mapID)];
                                            else
                                                return 0;
                                            end
                                        end,
                                        set = function(info, val)
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( val == 0 ) then
                                                A.db.profile.mountByMapID[4][tostring(mapID)] = nil;
                                            else
                                                A.db.profile.mountByMapID[4][tostring(mapID)] = val;
                                            end
                                        end,
                                    },
                                    ground =
                                    {
                                        order = 110,
                                        name = L["Ground"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Ground"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[1]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function()
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( A.db.profile.mountByMapID[1][tostring(mapID)] ) then
                                                return A.db.profile.mountByMapID[1][tostring(mapID)];
                                            else
                                                return 0;
                                            end
                                        end,
                                        set = function(info, val)
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( val == 0 ) then
                                                A.db.profile.mountByMapID[1][tostring(mapID)] = nil;
                                            else
                                                A.db.profile.mountByMapID[1][tostring(mapID)] = val;
                                            end
                                        end,
                                    },
                                    fly =
                                    {
                                        order = 120,
                                        name = L["Fly"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Fly"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[2]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function()
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( A.db.profile.mountByMapID[2][tostring(mapID)] ) then
                                                return A.db.profile.mountByMapID[2][tostring(mapID)];
                                            else
                                                return 0;
                                            end
                                        end,
                                        set = function(info, val)
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( val == 0 ) then
                                                A.db.profile.mountByMapID[2][tostring(mapID)] = nil;
                                            else
                                                A.db.profile.mountByMapID[2][tostring(mapID)] = val;
                                            end
                                        end,
                                    },
                                    hybrid =
                                    {
                                        order = 130,
                                        name = L["Hybrid"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Hybrid"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[3]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function()
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( A.db.profile.mountByMapID[3][tostring(mapID)] ) then
                                                return A.db.profile.mountByMapID[3][tostring(mapID)];
                                            else
                                                return 0;
                                            end
                                        end,
                                        set = function(info, val)
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( val == 0 ) then
                                                A.db.profile.mountByMapID[3][tostring(mapID)] = nil;
                                            else
                                                A.db.profile.mountByMapID[3][tostring(mapID)] = val;
                                            end
                                        end,
                                    },
                                    passenger =
                                    {
                                        order = 140,
                                        name = L["Passenger"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Passenger"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[5]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function()
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( A.db.profile.mountByMapID[5][tostring(mapID)] ) then
                                                return A.db.profile.mountByMapID[5][tostring(mapID)];
                                            else
                                                return 0;
                                            end
                                        end,
                                        set = function(info, val)
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( val == 0 ) then
                                                A.db.profile.mountByMapID[5][tostring(mapID)] = nil;
                                            else
                                                A.db.profile.mountByMapID[5][tostring(mapID)] = val;
                                            end
                                        end,
                                    },
                                    surface =
                                    {
                                        order = 150,
                                        name = L["Surface"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Surface"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[6]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function()
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( A.db.profile.mountByMapID[6][tostring(mapID)] ) then
                                                return A.db.profile.mountByMapID[6][tostring(mapID)];
                                            else
                                                return 0;
                                            end
                                        end,
                                        set = function(info, val)
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( val == 0 ) then
                                                A.db.profile.mountByMapID[6][tostring(mapID)] = nil;
                                            else
                                                A.db.profile.mountByMapID[6][tostring(mapID)] = val;
                                            end
                                        end,
                                    },
                                    repair =
                                    {
                                        order = 160,
                                        name = L["Repair"],
                                        desc = L["Select the %s mount to force summon."]:format(L["Repair"]),
                                        type = "select",
                                        dialogControl = "Dropdown-SortByValue",
                                        values = function()
                                            local out = { [0] = L["None"] };

                                            for k,v in A:PairsByKeys(A.pamTable.mounts[7]) do
                                                for kk,vv in ipairs(v) do
                                                    out[vv.spellID] = vv.name;
                                                end
                                            end

                                            return out;
                                        end,
                                        get = function()
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( A.db.profile.mountByMapID[7][tostring(mapID)] ) then
                                                return A.db.profile.mountByMapID[7][tostring(mapID)];
                                            else
                                                return 0;
                                            end
                                        end,
                                        set = function(info, val)
                                            local mapID;

                                            if ( A.currentMapIDForMounts ) then
                                                mapID = A.currentMapIDForMounts;
                                            else
                                                mapID = A.currentMapID;
                                            end

                                            if ( val == 0 ) then
                                                A.db.profile.mountByMapID[7][tostring(mapID)] = nil;
                                            else
                                                A.db.profile.mountByMapID[7][tostring(mapID)] = val;
                                            end
                                        end,
                                    },
                                    zoneSelectReset =
                                    {
                                        order = 200,
                                        name = L["Reset"],
                                        type = "header",
                                    },
                                    zoneReset =
                                    {
                                        order = 201,
                                        name = L["Reset"],
                                        desc = L["Use this to reset the working area to the current area."],
                                        type = "execute",
                                        func = function() A.currentMapIDForMounts = nil; end,
                                    },
                                },
                            },
                            common =
                            {
                                order = 200,
                                name = L["Zones database"],
                                type = "group",
                                inline = true,
                                args =
                                {
                                    knownZonesCount =
                                    {
                                        order = 0,
                                        name = function()
                                            local count = A:TableCount(A.db.global.zonesIDsToName);

                                            if ( count > 1 ) then
                                                return L["The add-on currently knows %d areas\n\n"]:format(count);
                                            else
                                                return L["The add-on currently knows %d area\n\n"]:format(count);
                                            end
                                        end,
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    debugInfo =
                                    {
                                        order = 1,
                                        name = A.color.RED..L["Debug is enabled. Building the areas database will reset it first."],
                                        hidden = function() return not A.db.profile.debug; end,
                                        width = "full",
                                        type = "description",
                                        fontSize = "large",
                                    },
                                    blankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        hidden = function() return not A.db.profile.debug; end,
                                        width = "full",
                                        type = "description",
                                        fontSize = "large",
                                    },
                                    buildDB =
                                    {
                                        order = 10,
                                        name = L["Build areas database"],
                                        desc = L["Build the areas database, this is not needed for the addon to work, but it will know the areas without discovering them first."],
                                        type = "execute",
                                        func = function() A:BuildMapIDsDB(); end,
                                    },
                                },
                            },
                        },
                    },
                },
            },
            about =
            {
                order = 50,
                name = L["About"],
                type = "group",
                args =
                {
                    name =
                    {
                        order = 0,
                        name = A.color.WARRIOR..L["Pets & Mounts"],
                        width = "full",
                        type = "description",
                        fontSize = "large",
                    },
                    emptyLine1 =
                    {
                        order = 1,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    desc =
                    {
                        order = 2,
                        name = L["Auto and random summon for your pets and mounts, highly customizable. With Data Broker support."],
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    emptyLine2 =
                    {
                        order = 3,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    author =
                    {
                        order = 4,
                        name = A.color.BLUE..L["Author"]..A.color.RESET..": "..GetAddOnMetadata("PetsAndMounts", "Author"),
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    licence =
                    {
                        order = 5,
                        name = A.color.BLUE..L["Licence"]..A.color.RESET..": BSD",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    version =
                    {
                        order = 6,
                        name = function()
                            local version, revision = A:GetAddonVersion(A.version);
                            local color;

                            if ( A.addonUpdateMessageInfo ) then
                                color = A.color.RED;
                            else
                                color = A.color.GREEN;
                            end

                            return A.color.BLUE..L["Version"]..A.color.RESET..": "..L["You are running Pets & Mounts version %s revision %s %s."]
                            :format(color..tostring(version)..A.color.RESET, color..tostring(revision), L[A.versionStage]..A.color.RESET);
                        end,
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    newVersion =
                    {
                        order = 7,
                        name = function()
                            if ( A.addonUpdateMessageInfo ) then
                                return A.color.BLUE..L["New version"]..A.color.RESET..": "..L["A new version is available, version |cff33ff99%s|r revision |cff33ff99%s %s|r."]
                                :format(tostring(A.addonUpdateMessageInfo[1]), tostring(A.addonUpdateMessageInfo[2]), L[A.addonUpdateMessageInfo[3]]);
                            end
                            return " ";
                        end,
                        width = "full",
                        hidden = function()
                            if ( A.addonUpdateMessageInfo ) then
                                return nil;
                            end
                            return 1;
                        end,
                        type = "description",
                        fontSize = "medium",
                    },
                    emptyLine3 =
                    {
                        order = 8,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    webSiteInput =
                    {
                        order = 9,
                        name = L["Web site"],
                        width = "full",
                        type = "input",
                        set = function() return; end,
                        get = function() return A.addonURL; end,
                    },
                    emptyLine4 =
                    {
                        order = 100,
                        name = " \n",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    credits =
                    {
                        order = 101,
                        name = A.color.WARRIOR..L["Credits"],
                        width = "full",
                        type = "description",
                        fontSize = "large",
                    },
                    emptyLine5 =
                    {
                        order = 102,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    warcraftMounts =
                    {
                        order = 110,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                        image = function() return "Interface\\AddOns\\PetsAndMounts\\Media\\warcraftmounts", 256, 105; end,
                        imageCoords = {0, 1, 0, 0.82},
                    },
                    warcraftMountsWebSite =
                    {
                        order = 111,
                        name = "Warcraft Mounts",
                        width = "full",
                        type = "input",
                        set = function() return; end,
                        get = function() return "http://www.warcraftmounts.com"; end,
                    },
                    emptyLine6 =
                    {
                        order = 112,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    warcraftPets =
                    {
                        order = 120,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                        image = function() return "Interface\\AddOns\\PetsAndMounts\\Media\\warcraftpets", 256, 256; end,
                    },
                    warcraftPetsWebSite =
                    {
                        order = 121,
                        name = "Warcraft Pets",
                        width = "full",
                        type = "input",
                        set = function() return; end,
                        get = function() return "http://www.warcraftpets.com"; end,
                    },
                    emptyLine7 =
                    {
                        order = 122,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                    wowhead =
                    {
                        order = 130,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                        image = function() return "Interface\\AddOns\\PetsAndMounts\\Media\\wowhead", 256, 116; end,
                        imageCoords = {0, 1, 0, 0.9},
                    },
                    wowheadWebSite =
                    {
                        order = 131,
                        name = "Wowhead",
                        width = "full",
                        type = "input",
                        set = function() return; end,
                        get = function() return "http://www.wowhead.com"; end,
                    },
                    emptyLine8 =
                    {
                        order = 132,
                        name = " ",
                        width = "full",
                        type = "description",
                        fontSize = "medium",
                    },
                },
            },
        },
    };

    orderGroup = 0;
    orderItem = 0;
    for k,v in ipairs(A.pamTable.pets) do
        options.args.pets.args[A.petTypes[k]] =
        {
            order = k,
            name = L[A.petTypes[k]],
            type = "group",
            args = {},
        };

        for kk,vv in A:PairsByKeys(v) do
            options.args.pets.args[A.petTypes[k]].args[kk] =
            {
                order = orderGroup,
                name = kk,
                type = "group",
                inline = true,
                args = {},
            };

            orderGroup = orderGroup + 1;

            for kkk,vvv in ipairs(vv) do
                options.args.pets.args[A.petTypes[k]].args[kk].args[vvv.name..vvv.petID] =
                {
                    order = orderItem,
                    name = function()
                        local petName;

                        if ( vvv.defaultName ) then
                            if ( A.db.profile.appendPetDefaultName ) then
                                petName = vvv.name.." ("..vvv.defaultName..")";
                            else
                                petName = vvv.name;
                            end

                            if ( A.db.profile.colorPetWithCustomName ) then
                                petName = A.db.profile.petWithCustomNameColor.hexa..petName;
                            end
                        else
                            petName = vvv.name;
                        end

                        return petName;
                    end,
                    desc = function()
                        -- Model
                        A.configModelFrame.rotation = 0;
                        A.configModelFrame:SetCreature(vvv.creatureID);

                        -- Frame pos
                        A.configModelFrame:ClearAllPoints()
                        A.configModelFrame:SetPoint("TOPLEFT", A.configFrameOptions, "TOPRIGHT", 0, 0);
                        A.configModelFrame:Show();

                        if ( A.db.profile.debug ) then
                            return L["Add %s to favorite."]:format(vvv.name).."\n\n"
                            .."ID: "..vvv.petID.."\n"
                            .."CreatureID: "..vvv.creatureID
                        else
                            return L["Add %s to favorite."]:format(vvv.name);
                        end
                    end,
                    image = vvv.icon,
                    type = "toggle",
                    set = function()
                        if ( tContains(A.db.profile.favoritePets, vvv.petID) ) then
                            A:TableRemove(A.db.profile.favoritePets, vvv.petID);
                        else
                            A.db.profile.favoritePets[#A.db.profile.favoritePets+1] = vvv.petID;
                        end
                    end,
                    get = function()
                        if ( tContains(A.db.profile.favoritePets, vvv.petID) ) then
                            return 1;
                        else
                            return nil;
                        end
                    end,
                };

                orderItem = orderItem + 1;
            end
        end
    end

    orderGroup = 0;
    orderItem = 0;
    for k,v in ipairs(A.pamTable.mounts) do
        if ( A:TableNotEmpty(v) ) then
            options.args.mounts.args[A.mountCat[k]] =
            {
                order = k,
                name = A.mountCat[k],
                type = "group",
                args = {},
            };

            for kk,vv in A:PairsByKeys(v) do
                options.args.mounts.args[A.mountCat[k]].args[kk] =
                {
                    order = orderGroup,
                    name = kk,
                    type = "group",
                    inline = true,
                    args = {},
                };

                orderGroup = orderGroup + 1;

                for kkk,vvv in ipairs(vv) do
                    options.args.mounts.args[A.mountCat[k]].args[kk].args[vvv.name..vvv.id] =
                    {
                        order = orderItem,
                        name = vvv.name,
                        desc = function()
                            -- Model
                            A.configModelFrame.rotation = 0;
                            A.configModelFrame:SetCreature(vvv.creatureID);

                            -- Frame pos
                            A.configModelFrame:ClearAllPoints()
                            A.configModelFrame:SetPoint("TOPLEFT", A.configFrameOptions, "TOPRIGHT", 0, 0);
                            A.configModelFrame:Show();

                            if ( A.db.profile.debug ) then
                                return L["Add %s to favorite."]:format(vvv.name).."\n\n"
                                .."ID: "..vvv.id.."\n"
                                .."CreatureID: "..vvv.creatureID.."\n"
                                .."SpellID: "..vvv.spellID.."\n"
                                .."Type: "..vvv.mountType;
                            else
                                return L["Add %s to favorite."]:format(vvv.name);
                            end
                        end,
                        image = vvv.icon,
                        type = "toggle",
                        set = function()
                            if ( tContains(A.db.profile.favoriteMounts[k], vvv.spellID) ) then
                                A:TableRemove(A.db.profile.favoriteMounts[k], vvv.spellID);
                            else
                                A.db.profile.favoriteMounts[k][#A.db.profile.favoriteMounts[k]+1] = vvv.spellID;
                            end
                        end,
                        get = function()
                            if ( tContains(A.db.profile.favoriteMounts[k], vvv.spellID) ) then
                                return 1;
                            else
                                return nil;
                            end
                        end,
                    };

                    orderItem = orderItem + 1;
                end
            end
        end
    end

    options.args.pets.args.reset =
    {
        order = 1000,
        name = L["Reset"],
        type = "group",
        args =
        {
            toggle =
            {
                order = 0,
                name = L["Enable"],
                type = "toggle",
                get = function() return A.enablePetResetButton; end,
                set = function() A.enablePetResetButton = not A.enablePetResetButton; end,
            },
            exec =
            {
                order = 1,
                name = L["Reset"],
                type = "execute",
                disabled = function() return not A.enablePetResetButton; end,
                func = function()
                    A.db.profile.favoritePets = {};
                    A.enablePetResetButton = nil;
                end,
            },
        },
    };

    options.args.mounts.args.reset =
    {
        order = 1000,
        name = L["Reset"],
        type = "group",
        args =
        {
            toggle =
            {
                order = 0,
                name = L["Enable"],
                type = "toggle",
                get = function() return A.enableMountResetButton; end,
                set = function() A.enableMountResetButton = not A.enableMountResetButton; end,
            },
            exec =
            {
                order = 1,
                name = L["Reset"],
                type = "execute",
                disabled = function() return not A.enableMountResetButton; end,
                func = function()
                    A.db.profile.favoriteMounts =
                    {
                        [1] = {}, -- Ground
                        [2] = {}, -- Fly
                        [3] = {}, -- Hybrid (ground & fly)
                        [4] = {}, -- Aquatic
                        [5] = {}, -- with passengers
                        [6] = {}, -- Water walking
                        [7] = {}, -- Repair
                    };

                    -- Fav mounts reset, deleting cache
                    A.usableMountsCache = nil;
                    A.enableMountResetButton = nil;
                end,
            },
        },
    };

    -- Pets summon filters
    orderItem = 0;
    for k,v in ipairs(A.petsSummonFilters) do
        if ( v.option ) then
            options.args.options.args.petsOptions.args.petsSummonFilters.args[v.name] =
            {
                order = orderItem,
                name = v.name,
                type = "toggle",
                desc = function()
                    if ( v.desc ) then
                        return v.desc;
                    end

                    return L["Prevent companion auto summon when: %s"]:format(v.name);
                end,
                set = function()
                    A.db.profile.petsSummonFilters[k] = not A.db.profile.petsSummonFilters[k];
                    A.petsSummonFiltersCache = nil;
                end,
                get = function() return A.db.profile.petsSummonFilters[k]; end,
            };
            orderItem = orderItem + 1;
        end
    end

    -- Mounts summon filters
    orderItem = 0;
    for k,v in ipairs(A.mountsSummonFilters) do
        if ( v.option ) then
            options.args.options.args.mountsOptions.args.mountsSummonFilters.args[v.name] =
            {
                order = orderItem,
                name = v.name,
                type = "toggle",
                desc = function()
                    if ( v.desc ) then
                        return v.desc;
                    end

                    return L["Prevent mount summon when: %s"]:format(v.name);
                end,
                set = function()
                    A.db.profile.mountsSummonFilters[k] = not A.db.profile.mountsSummonFilters[k];
                    A.mountsSummonFiltersCache = nil;
                end,
                get = function() return A.db.profile.mountsSummonFilters[k]; end,
            };
            orderItem = orderItem + 1;
        end
    end

    -- Profiles
    options.args.options.args.profilesOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(A.db);
    options.args.options.args.profilesOptions.order = 10000;

    return options;
end

local options = A:AceConfig();

-- Register with AceConfig
LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Pets & Mounts"], options.args.options);
LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Pets & Mounts"]..": "..options.args.pets.name, options.args.pets);
LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Pets & Mounts"]..": "..options.args.mounts.name, options.args.mounts);
LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Pets & Mounts"]..": "..options.args.sets.name, options.args.sets);
LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Pets & Mounts"]..": "..options.args.favOverride.name, options.args.favOverride);
LibStub("AceConfig-3.0"):RegisterOptionsTable(L["Pets & Mounts"]..": "..options.args.about.name, options.args.about);

-- Adding addon options to Blizzard UI
A.configFrameOptions = A.AceConfigDialog:AddToBlizOptions(L["Pets & Mounts"],  L["Pets & Mounts"]);
A.configFramePets = A.AceConfigDialog:AddToBlizOptions(L["Pets & Mounts"]..": "..options.args.pets.name, options.args.pets.name, L["Pets & Mounts"]);
A.configFrameMounts = A.AceConfigDialog:AddToBlizOptions(L["Pets & Mounts"]..": "..options.args.mounts.name, options.args.mounts.name, L["Pets & Mounts"]);
A.configFrameSets = A.AceConfigDialog:AddToBlizOptions(L["Pets & Mounts"]..": "..options.args.sets.name, options.args.sets.name, L["Pets & Mounts"]);
A.configFrameFavOverride = A.AceConfigDialog:AddToBlizOptions(L["Pets & Mounts"]..": "..options.args.favOverride.name, options.args.favOverride.name, L["Pets & Mounts"]);
A.configFrameAbout = A.AceConfigDialog:AddToBlizOptions(L["Pets & Mounts"]..": "..options.args.about.name, options.args.about.name, L["Pets & Mounts"]);

-- Hide model frame hooks
A.configFramePets:HookScript("OnHide", function() A.configModelFrame:Hide(); end);
A.configFrameMounts:HookScript("OnHide", function() A.configModelFrame:Hide(); end);

-- NotifyChange method
function A:NotifyChangeForAll()
    A.AceConfigRegistry:NotifyChange(L["Pets & Mounts"], options.args.options);
    A.AceConfigRegistry:NotifyChange(L["Pets & Mounts"]..": "..options.args.pets.name, options.args.pets);
    A.AceConfigRegistry:NotifyChange(L["Pets & Mounts"]..": "..options.args.mounts.name, options.args.mounts);
    A.AceConfigRegistry:NotifyChange(L["Pets & Mounts"]..": "..options.args.sets.name, options.args.sets);
    A.AceConfigRegistry:NotifyChange(L["Pets & Mounts"]..": "..options.args.favOverride.name, options.args.favOverride);
    A.AceConfigRegistry:NotifyChange(L["Pets & Mounts"]..": "..options.args.about.name, options.args.about);
end
