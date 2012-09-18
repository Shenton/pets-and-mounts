-- ********************************************************************************
-- Broker Pets & Mounts
-- Data Broker display for easy acces to pets and mounts.
-- By: Shenton
--
-- Config.lua
-- ********************************************************************************

local A = _G["BrokerPAMGlobal"];
local L = A.L;

A.AceConfigDialog = LibStub("AceConfigDialog-3.0");

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

local options, orderGroup, orderItem, petName;
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

                                    if ( not A.db.profile.autoPet ) then
                                        A:CancelTimer(A.mainTimer, 1);
                                    else
                                        A:CancelTimer(A.mainTimer, 1);
                                        A.mainTimer = A:ScheduleRepeatingTimer("AutoPet", A.db.profile.mainTimer);
                                    end
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
                                name = L["Not when stealthed"],
                                desc = L["If you got a companion it will dismiss it when going stealthed."],
                                type = "toggle",
                                set = function(info, val) A.db.profile.notWhenStealthed = not A.db.profile.notWhenStealthed; end,
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
                                    A:CancelTimer(A.mainTimer, 1);
                                    A.mainTimer = A:ScheduleRepeatingTimer("AutoPet", A.db.profile.mainTimer);
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
                                set = function(info, val)
                                    A.db.profile.shiftTimer = val;
                                    A:CancelTimer(A.shiftTimer, 1);
                                    A.shiftTimer = A:ScheduleRepeatingTimer("AutoPet", A.db.profile.shiftTimer);
                                end,
                                get = function(info) return A.db.profile.shiftTimer; end,
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
                                desc = A.L["Select the model frame size."],
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
                                desc = A.L["Select the model frame size."],
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
                args =
                {
                },
            },
            mounts =
            {
                order = 20,
                name = L["Mounts"],
                type = "group",
                args =
                {
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

                    return L["Add %s to favorite."]:format(vv.name);
                end,
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

                            return L["Add %s to favorite."]:format(vvv.name);
                        end,
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

    -- Profiles
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(A.db);
    options.args.profile.order = 1000;

    return options;
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("BrokerPAMConfig", A.AceConfig);
A.AceConfigDialog:SetDefaultSize("BrokerPAMConfig", 800, 500);
A.configFrame = A.AceConfigDialog:AddToBlizOptions("BrokerPAMConfig", L["Pets & Mounts"]);
A.configFrame:HookScript("OnHide", function() A.modelFrameConfig:Hide(); end);
