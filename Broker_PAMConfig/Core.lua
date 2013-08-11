--[[-------------------------------------------------------------------------------
    Broker Pets & Mounts
    Data Broker display for easy acces to pets and mounts.
    By: Shenton

    Config.lua
-------------------------------------------------------------------------------]]--

local A = _G["BrokerPAMGlobal"];
local L = A.L;

-- Globals to locals
local ipairs = ipairs;
local pairs = pairs;
local type = type;
local tContains = tContains;
local strtrim = strtrim;

-- GLOBALS: GetCurrentBindingSet, SetBinding, SaveBindings
-- GLOBALS: GetBindingKey, StaticPopup_Show, LibStub

-- Ace3 libs <3
A.AceConfigDialog = LibStub("AceConfigDialog-3.0");
A.AceConfigRegistry = LibStub("AceConfigRegistry-3.0");

-- Init addon databases
A:InitializeDB();

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

-- Set overwrite or dif name popup dialog
StaticPopupDialogs["BrokerPamOverwriteOrChangeNameSet"] =
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
        A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
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

            A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
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

            A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
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

            A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
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

            A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
        end
    end,
    preferredIndex = 3,
};

-- Confirm delete set popup dialog
StaticPopupDialogs["BrokerPamDeleteSet"] =
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
        A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
    end,
    -- EditBoxOnEnterPressed = function(self)
    -- end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
    OnAccept = function(self)
        if ( A.deleteSetPets ) then
            A.db.global.savedSets.pets[A.deleteSetPets] = nil;
        elseif ( A.deleteSetMounts ) then
            A.db.global.savedSets.mounts[A.deleteSetMounts] = nil;
        end

        A.AceConfigRegistry:NotifyChange("BrokerPAMConfig");
    end,
    preferredIndex = 3,
};

local options, orderGroup, orderItem, petName, petAutoSummonOverrideSelected;
local optionsOverrideHeaderText = L["None"];
function A:AceConfig()
    options =
    {
        name = L["Pets & Mounts"],
        type = "group",
        childGroups = "tab",
        args =
        {
            options =
            {
                order = 0,
                name = L["Options"],
                type = "group",
                args =
                {
                    petOptions =
                    {
                        order = 0,
                        name = L["Auto pet options"],
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
                                set = function(info, val)
                                    A.db.profile.autoPet = not A.db.profile.autoPet;
                                    A:SetMainTimer();
                                end,
                                get = function(info) return A.db.profile.autoPet; end,
                            },
                            alreadyGotPet =
                            {
                                order = 2,
                                name = L["Not with a companion"],
                                desc = L["Auto summon will not work if you already have a companion, or it will summon a random favorite companion."],
                                type = "toggle",
                                set = function(info, val) A.db.profile.alreadyGotPet = not A.db.profile.alreadyGotPet; end,
                                get = function(info) return A.db.profile.alreadyGotPet; end,
                            },
                            notWhenStealthed =
                            {
                                order = 3,
                                name = L["Revoke when stealthed"],
                                desc = L["If you got a companion it will dismiss it when going stealthed."],
                                type = "toggle",
                                set = function(info, val)
                                    A.db.profile.notWhenStealthed = not A.db.profile.notWhenStealthed;
                                    A:SetStealthEvents();
                                end,
                                get = function(info) return A.db.profile.notWhenStealthed; end,
                            },
                            filters =
                            {
                                order = 10,
                                name = L["Filters"],
                                type = "header",
                            },
                            filterMultiple =
                            {
                                order = 11,
                                name = L["Filter multiple"],
                                desc = L["This will prevent adding to the list all the companions with same names."],
                                type = "toggle",
                                set = function(info, val)
                                    A.db.profile.filterMultiple = not A.db.profile.filterMultiple;
                                    A:BuildPetsTable();
                                end,
                                get = function(info) return A.db.profile.filterMultiple; end,
                            },
                            noFilterCustom =
                            {
                                order = 12,
                                name = L["Do not filter named companions"],
                                desc = L["If the companion got a custom name it will not be filtered."],
                                type = "toggle",
                                set = function(info, val)
                                    A.db.profile.noFilterCustom = not A.db.profile.noFilterCustom;
                                    A:BuildPetsTable();
                                end,
                                get = function(info) return A.db.profile.noFilterCustom; end,
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
                                get = function(info) return A.db.profile.mainTimer; end,
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
                                get = function(info) return A.db.profile.shiftTimer; end,
                            },
                        },
                    },
                    petAutoSummonOverride =
                    {
                        order = 1,
                        name = L["Auto pet options override"],
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
                                set = function(info, val)
                                    A.db.profile.enableAutoSummonOverride = not A.db.profile.enableAutoSummonOverride;
                                end,
                                get = function(info) return A.db.profile.enableAutoSummonOverride; end,
                            },
                            areaSelectHeader =
                            {
                                order = 10,
                                name = L["Zone type"],
                                type = "header",
                            },
                            areaSelect =
                            {
                                order = 11,
                                name = L["Zone type"],
                                desc = L["Select witch type of zone to work with."],
                                type = "select",
                                disabled = not A.db.profile.enableAutoSummonOverride,
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
                                set = function(info, val)
                                    if ( not petAutoSummonOverrideSelected ) then return; end

                                    if ( not A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] ) then
                                        A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] = {};
                                    end

                                    A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].autoPet = not A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].autoPet;
                                end,
                                get = function(info)
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
                                set = function(info, val)
                                    if ( not petAutoSummonOverrideSelected ) then return; end

                                    if ( not A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] ) then
                                        A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] = {};
                                    end

                                    A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].notWhenStealthed = not A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].notWhenStealthed;
                                end,
                                get = function(info)
                                    if ( A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected] ) then
                                        return A.db.profile.autoSummonOverride[petAutoSummonOverrideSelected].notWhenStealthed;
                                    else
                                        return nil;
                                    end
                                end,
                            },
                        },
                    },
                    mountOptions =
                    {
                        order = 10,
                        name = L["Random mount options"],
                        type = "group",
                        inline = true,
                        args =
                        {
                            noHybridWhenGround =
                            {
                                order = 0,
                                name = L["No hybrid"],
                                desc = L["Do not summon an hybrid mount in a ground only area."],
                                type = "toggle",
                                set = function(info, val) A.db.profile.noHybridWhenGround = not A.db.profile.noHybridWhenGround; end,
                                get = function(info) return A.db.profile.noHybridWhenGround; end,
                            },
                            dismountFlying =
                            {
                                order = 1,
                                name = L["Flying dismount"],
                                desc = L["Using the random mount bind when flying will dismount you."],
                                type = "toggle",
                                set = function(info, val) A.db.profile.dismountFlying = not A.db.profile.dismountFlying; end,
                                get = function(info) return A.db.profile.dismountFlying; end,
                            },
                            areaMounts =
                            {
                                order = 1,
                                name = L["Zone mounts"],
                                desc = L["With this enabled it will summon a specific mount according to your current zone. Exemple: the Abyssal Seahorse in Vashj'ir"],
                                type = "toggle",
                                set = function(info, val) A.db.profile.areaMounts = not A.db.profile.areaMounts; end,
                                get = function(info) return A.db.profile.areaMounts; end,
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
                                set = function(info, val)
                                    A.db.profile.configModelRotation = not A.db.profile.configModelRotation;

                                    if ( not A.db.profile.configModelRotation ) then
                                        A.modelFrameConfig.rotation = 0;
                                        A.modelFrameConfig:SetRotation(A.modelFrameConfig.rotation);
                                    end
                                end,
                                get = function(info) return A.db.profile.configModelRotation; end,
                            },
                            configSize =
                            {
                                order = 2,
                                name = L["Size"],
                                desc = L["Select the model frame size."],
                                type = "select",
                                values = modelFrameSizeSelect,
                                get = function() return A.db.profile.configModelFrameWidth; end,
                                set = function(self, val)
                                    A.db.profile.configModelFrameWidth = val;
                                    A.db.profile.configModelFrameHeight = val;
                                    A.modelFrameConfig:SetSize(A.db.profile.configModelFrameWidth, A.db.profile.configModelFrameHeight);
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
                                set = function(info, val) A.db.profile.modelRotation = not A.db.profile.modelRotation; end,
                                get = function(info) return A.db.profile.modelRotation; end,
                            },
                            menuSize =
                            {
                                order = 12,
                                name = L["Size"],
                                desc = L["Select the model frame size."],
                                type = "select",
                                values = modelFrameSizeSelect,
                                get = function() return A.db.profile.modelFrameWidth; end,
                                set = function(self, val)
                                    A.db.profile.modelFrameWidth = val;
                                    A.db.profile.modelFrameHeight = val;
                                    A.modelFrameConfig:SetSize(A.db.profile.modelFrameWidth, A.db.profile.modelFrameHeight);
                                end
                            },
                        },
                    },
                    binding =
                    {
                        order = 100,
                        name = L["Binding"],
                        type = "group",
                        inline = true,
                        args =
                        {
                            randomMount =
                            {
                                order = 0,
                                name = L["Random mount"],
                                type = "header",
                            },
                            randomMountKey1 =
                            {
                                order = 1,
                                name = L["Key one"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNT", set);
                                    SaveBindings(set);
                                end,
                                get = function(info) return GetBindingKey("BROKERPAMMOUNT"); end,
                            },
                            randomMountKey2 =
                            {
                                order = 2,
                                name = L["Key two"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNT", set);
                                    SaveBindings(set);
                                end,
                                get = function(info)
                                    local _, key = GetBindingKey("BROKERPAMMOUNT");
                                    return key;
                                end,
                            },
                            randomPassengerMount =
                            {
                                order = 10,
                                name = L["Random passengers mount"],
                                type = "header",
                            },
                            randomPassengerMountKey1 =
                            {
                                order = 11,
                                name = L["Key one"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNTPASSENGERS", set);
                                    SaveBindings(set);
                                end,
                                get = function(info) return GetBindingKey("BROKERPAMMOUNTPASSENGERS"); end,
                            },
                            randomPassengerMountKey2 =
                            {
                                order = 12,
                                name = L["Key two"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNTPASSENGERS", set);
                                    SaveBindings(set);
                                end,
                                get = function(info)
                                    local _, key = GetBindingKey("BROKERPAMMOUNTPASSENGERS");
                                    return key;
                                end,
                            },
                            randomFlyMount =
                            {
                                order = 20,
                                name = L["Random flying mount"],
                                type = "header",
                            },
                            randomFlyMountKey1 =
                            {
                                order = 21,
                                name = L["Key one"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNTFLYING", set);
                                    SaveBindings(set);
                                end,
                                get = function(info) return GetBindingKey("BROKERPAMMOUNTFLYING"); end,
                            },
                            randomFlyMountKey2 =
                            {
                                order = 22,
                                name = L["Key two"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNTFLYING", set);
                                    SaveBindings(set);
                                end,
                                get = function(info)
                                    local _, key = GetBindingKey("BROKERPAMMOUNTFLYING");
                                    return key;
                                end,
                            },
                            randomGroundMount =
                            {
                                order = 30,
                                name = L["Random ground mount"],
                                type = "header",
                            },
                            randomGroundMountKey1 =
                            {
                                order = 31,
                                name = L["Key one"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNTGROUND", set);
                                    SaveBindings(set);
                                end,
                                get = function(info) return GetBindingKey("BROKERPAMMOUNTGROUND"); end,
                            },
                            randomGroundMountKey2 =
                            {
                                order = 32,
                                name = L["Key two"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNTGROUND", set);
                                    SaveBindings(set);
                                end,
                                get = function(info)
                                    local _, key = GetBindingKey("BROKERPAMMOUNTGROUND");
                                    return key;
                                end,
                            },
                            randomAquaticMount =
                            {
                                order = 40,
                                name = L["Random aquatic mount"],
                                type = "header",
                            },
                            randomAquaticMountKey1 =
                            {
                                order = 41,
                                name = L["Key one"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNTAQUATIC", set);
                                    SaveBindings(set);
                                end,
                                get = function(info) return GetBindingKey("BROKERPAMMOUNTAQUATIC"); end,
                            },
                            randomAquaticMountKey2 =
                            {
                                order = 42,
                                name = L["Key two"],
                                desc = L["Bind a key to summon a random mount."],
                                type = "keybinding",
                                set = function(info, val)
                                    local set = GetCurrentBindingSet();

                                    SetBinding(val, "BROKERPAMMOUNTAQUATIC", set);
                                    SaveBindings(set);
                                end,
                                get = function(info)
                                    local _, key = GetBindingKey("BROKERPAMMOUNTAQUATIC");
                                    return key;
                                end,
                            },
                        },
                    },
                    minimap =
                    {
                        order = 110,
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
                                set = function(info, val)
                                    A.db.profile.ldbi.hide = not A.db.profile.ldbi.hide;
                                    A:ShowHideMinimap();
                                end,
                                get = function(info) return not A.db.profile.ldbi.hide; end,
                            },
                        },
                    },
                    debug =
                    {
                        order = 200,
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
                                set = function(info, val) A.db.profile.debug = not A.db.profile.debug; end,
                                get = function(info) return A.db.profile.debug; end,
                            },
                        },
                    },
                },
            },
            pets =
            {
                order = 10,
                name = L["Companions"],
                type = "group",
                args = {},
            },
            mounts =
            {
                order = 20,
                name = L["Mounts"],
                type = "group",
                args = {},
            },
            sets =
            {
                order = 30,
                name = L["Sets"],
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

                                    return L["Currently using set: %s"]:format(current);
                                end,
                                type = "description",
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
                                        end;
                                        get = nil,
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
                                    },
                                    exec =
                                    {
                                        order = 1,
                                        name = L["Save"],
                                        type = "execute",
                                        disabled = not A.newPetSetName,
                                        func = function()
                                            if ( A.db.global.savedSets.pets[A.newPetSetName] ) then
                                                StaticPopup_Show("BrokerPamOverwriteOrChangeNameSet", A.newPetSetName);
                                            else
                                                A.db.global.savedSets.pets[A.newPetSetName] = A:CopyTable(A.db.profile.favoritePets);
                                                A.newPetSetName = nil;
                                            end
                                        end;
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
                                        get = nil,
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
                                        disabled = not A.deleteSetPets,
                                        func = function()
                                            StaticPopup_Show("BrokerPamDeleteSet", A.deleteSetPets);
                                        end;
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

                                    return L["Currently using set: %s"]:format(current);
                                end,
                                type = "description",
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
                                        end;
                                        get = nil,
                                        set = function(info, val)
                                            if ( A.db.global.savedSets.mounts[val] ) then
                                                A.db.profile.favoriteMounts = {};
                                                A:CopyTable(A.db.global.savedSets.mounts[val], A.db.profile.favoriteMounts);
                                            end
                                        end,
                                    },
                                },
                            },
                            -- new =
                            -- {
                                -- order = 20,
                                -- name = L["New"],
                                -- type = "group",
                                -- inline = true,
                                -- args =
                                -- {
                                    -- input =
                                    -- {
                                        -- order = 0,
                                        -- name = L["Name"],
                                        -- type = "input",
                                        -- set = function(info, val) A.newMountSetName = val; end,
                                        -- get = function() return A.newMountSetName; end,
                                    -- },
                                    -- exec =
                                    -- {
                                        -- order = 1,
                                        -- name = L["Save"],
                                        -- type = "execute",
                                        -- disabled = not A.newMountSetName,
                                        -- func = function()
                                            -- if ( A.db.global.savedSets.mounts[A.newMountSetName] ) then
                                                -- StaticPopup_Show("BrokerPamOverwriteOrChangeNameSet", A.newMountSetName);
                                            -- else
                                                -- A.db.global.savedSets.mounts[A.newMountSetName] = {};
                                                -- A.newMountSetName = nil;
                                            -- end
                                        -- end;
                                    -- },
                                -- },
                            -- },
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
                                    },
                                    exec =
                                    {
                                        order = 1,
                                        name = L["Save"],
                                        type = "execute",
                                        disabled = not A.newMountSetName,
                                        func = function()
                                            if ( A.db.global.savedSets.mounts[A.newMountSetName] ) then
                                                StaticPopup_Show("BrokerPamOverwriteOrChangeNameSet", A.newMountSetName);
                                            else
                                                A.db.global.savedSets.mounts[A.newMountSetName] = A:CopyTable(A.db.profile.favoriteMounts);
                                                A.newMountSetName = nil;
                                            end
                                        end;
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
                                        get = nil,
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
                                        disabled = not A.deleteSetMounts,
                                        func = function()
                                            StaticPopup_Show("BrokerPamDeleteSet", A.deleteSetMounts);
                                        end;
                                    },
                                },
                            },
                        },
                    },
                },
            },
            forceOne =
            {
                order = 40,
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
                                -- Using a string instead of an integer for "None", since blizzard stoped using ID but use GUID for pets
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
                                set = function(self, val)
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
                                            out[vv.spellId] = vv.name;
                                        end
                                    end

                                    return out;
                                end,
                                get = function() return A.db.profile.forceOne.mount[4]; end,
                                set = function(self, val)
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
                                            out[vv.spellId] = vv.name;
                                        end
                                    end

                                    return out;
                                end,
                                get = function() return A.db.profile.forceOne.mount[1]; end,
                                set = function(self, val)
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
                                            out[vv.spellId] = vv.name;
                                        end
                                    end

                                    return out;
                                end,
                                get = function() return A.db.profile.forceOne.mount[2]; end,
                                set = function(self, val)
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
                                            out[vv.spellId] = vv.name;
                                        end
                                    end

                                    return out;
                                end,
                                get = function() return A.db.profile.forceOne.mount[3]; end,
                                set = function(self, val)
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
                                            out[vv.spellId] = vv.name;
                                        end
                                    end

                                    return out;
                                end,
                                get = function() return A.db.profile.forceOne.mount[5]; end,
                                set = function(self, val)
                                    if ( val == 0 ) then
                                        A.db.profile.forceOne.mount[5] = nil;
                                    else
                                        A.db.profile.forceOne.mount[5] = val;
                                    end
                                end,
                            },
                        },
                    },
                },
            },
        },
    };

    orderGroup = 0;
    orderItem = 0;
    for k,v in A:PairsByKeys(A.pamTable.pets) do
        options.args.pets.args[k] =
        {
            order = orderGroup,
            name = k,
            type = "group",
            inline = true,
            args = {},
        };

        orderGroup = orderGroup + 1;

        for _,vv in ipairs(v) do
            if ( vv.customName ) then
                petName = vv.customName;
            else
                petName = vv.name;
            end

            options.args.pets.args[k].args[vv.name..vv.petID] =
            {
                order = orderItem,
                name = petName,
                desc = function(self)
                    -- Model
                    A.modelFrameConfig.rotation = 0;
                    A.modelFrameConfig:SetCreature(vv.creatureID);

                    -- Frame pos
                    A.modelFrameConfig:ClearAllPoints()
                    A.modelFrameConfig:SetPoint("TOPLEFT", A.configFrame, "TOPRIGHT", 0, 0);
                    A.modelFrameConfig:Show();

                    if ( A.db.profile.debug ) then
                        return L["Add %s to favorite."]:format(vv.name).."\n\n"
                        .."ID: "..vv.petID.."\n"
                        .."CreatureID: "..vv.creatureID
                    else
                        return L["Add %s to favorite."]:format(vv.name);
                    end
                end,
                --icon = string.gsub(vv.icon, "\\", "\\\\"),
                image = vv.icon,
                type = "toggle",
                set = function(info, val)
                    if ( tContains(A.db.profile.favoritePets, vv.petID) ) then
                        A:TableRemove(A.db.profile.favoritePets, vv.petID);
                    else
                        A.db.profile.favoritePets[#A.db.profile.favoritePets+1] = vv.petID;
                    end
                end,
                get = function(info)
                    if ( tContains(A.db.profile.favoritePets, vv.petID) ) then
                        return 1;
                    else
                        return nil;
                    end
                end,
            };

            orderItem = orderItem + 1;
        end
    end

    orderGroup = 0;
    orderItem = 0;
    --[1] = {}, -- Ground
    --[2] = {}, -- Fly
    --[3] = {}, -- Hybrid (ground & fly)
    --[4] = {}, -- Aquatic
    --[5] = {}, -- with passengers
    for k,v in ipairs(A.pamTable.mounts) do
        --print(#v)
        --if ( #v > 0 ) then
        --if 1 then
        if ( A:TableNotEmpty(v) ) then
            options.args.mounts.args[A.mountCat[k]] =
            {
                --order = k,
                name = A.mountCat[k],
                type = "group",
                childGroups = "tab",
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
                        desc = function(self)
                            -- Model
                            A.modelFrameConfig.rotation = 0;
                            A.modelFrameConfig:SetCreature(vvv.creatureID);

                            -- Frame pos
                            A.modelFrameConfig:ClearAllPoints()
                            A.modelFrameConfig:SetPoint("TOPLEFT", A.configFrame, "TOPRIGHT", 0, 0);
                            A.modelFrameConfig:Show();

                            if ( A.db.profile.debug ) then
                                return L["Add %s to favorite."]:format(vvv.name).."\n\n"
                                .."ID: "..vvv.id.."\n"
                                .."CreatureID: "..vvv.creatureID.."\n"
                                .."SpellID: "..vvv.spellId.."\n"
                                .."Type: "..vvv.mountType;
                            else
                                return L["Add %s to favorite."]:format(vvv.name);
                            end
                        end,
                        image = vvv.icon,
                        type = "toggle",
                        set = function(info, val)
                            if ( tContains(A.db.profile.favoriteMounts[k], vvv.spellId) ) then
                                A:TableRemove(A.db.profile.favoriteMounts[k], vvv.spellId);
                            else
                                A.db.profile.favoriteMounts[k][#A.db.profile.favoriteMounts[k]+1] = vvv.spellId;
                            end
                        end,
                        get = function(info)
                            if ( tContains(A.db.profile.favoriteMounts[k], vvv.spellId) ) then
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

    options.args.mounts.args.reset =
    {
        order = 1000,
        name = L["Reset"],
        type = "group",
        --inline = true,
        args =
        {
            toggle =
            {
                order = 0,
                name = L["Enable"],
                type = "toggle",
                get = A.enableMountResetButton,
                set = function() A.enableMountResetButton = not A.enableMountResetButton; end,
            },
            exec =
            {
                order = 1,
                name = L["Reset"],
                type = "execute",
                disabled = not A.enableMountResetButton,
                func = function()
                    A.db.profile.favoriteMounts =
                    {
                        [1] = {}, -- Ground
                        [2] = {}, -- Fly
                        [3] = {}, -- Hybrid (ground & fly)
                        [4] = {}, -- Aquatic
                        [5] = {}, -- with passengers
                    };

                    A.enableMountResetButton = nil;
                end,
            },
        },
    };

    -- Profiles
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(A.db);
    options.args.profile.order = 1000;

    return options;
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("BrokerPAMConfig", A.AceConfig);
--A.AceConfigDialog:SetDefaultSize("BrokerPAMConfig", 800, 500);
A.configFrame = A.AceConfigDialog:AddToBlizOptions("BrokerPAMConfig", L["Pets & Mounts"]);
A.configFrame:HookScript("OnHide", function() A.modelFrameConfig:Hide(); end);
