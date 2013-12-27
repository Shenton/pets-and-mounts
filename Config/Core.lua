--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Config.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- Init addon databases
A:InitializeDB();

-- Globals to locals
local ipairs = ipairs;
local pairs = pairs;
local string = string;
local tostring = tostring;
local tContains = tContains;
local tonumber = tonumber;
local _G = _G;
local math = math;

-- GLOBALS: LibStub, InCombatLockdown, GetCurrentBindingSet, GetBindingKey, SetBinding, SaveBindings
-- GLOBALS: GetMapNameByID, GetAddOnMetadata, GetMacroItemIcons, GetMacroIcons, FauxScrollFrame_GetOffset
-- GLOBALS: FauxScrollFrame_Update

-- Ace3 libs <3
A.AceConfigDialog = LibStub("AceConfigDialog-3.0");
A.AceConfigRegistry = LibStub("AceConfigRegistry-3.0");

-- Config model frame
A.configModelFrame = PetsAndMountsConfigModelFrame;
A.configModelFrame:SetSize(A.db.profile.configModelFrameWidth, A.db.profile.configModelFrameHeight);

-- Search frame
A.searchFrame = PetsAndMountsSearchFrame;

-- Icon list frame
A.iconFrame = PetsAndMountsSelectIconFrame;

-- Input frame
A.inputFrame = PetsAndMountsInputCodeFrame;

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

local reSummonValues =
{
    --@debug@
    [10] = "10s",
    --@end-debug@
    [600] = L["10m"],
    [1800] = L["30m"],
    [3600] = L["1h"],
    [5400] = L["1h30m"],
    [7200] = L["2h"],
    [10800] = L["3h"],
    [18000] = L["5h"],
};

-- Icon list table
A.iconList = {};

--[[-------------------------------------------------------------------------------
    Icons frame methods
-------------------------------------------------------------------------------]]--

--- Reset and add icons filename to the icons list table
function A:GetIconsList()
    A.iconsList = {};
    A.iconsList[1] = "INV_MISC_QUESTIONMARK";
    GetMacroItemIcons(A.iconsList);
    GetMacroIcons(A.iconsList);
end

--- Scroll frame update method
function A:IconsFrameScrollUpdate()
    local icons, icon, button, index, texture;
    local popupOffset = FauxScrollFrame_GetOffset(A.iconFrame.scrollFrame);

    if ( A.iconsListSearch ) then
        icons = A.iconsListSearch;
    else
        icons = A.iconsList;
    end

    for i=1,64 do
        icon = _G["PetsAndMountsSelectIconFrameButton"..i.."Icon"];
        button = _G["PetsAndMountsSelectIconFrameButton"..i];
        index = (popupOffset * 8) + i;

        if ( index ) then
            texture = icons[index];
        else
            texture = nil;
        end

        if ( texture ) then
            icon:SetTexture("INTERFACE\\ICONS\\"..texture);
            button.textureName = texture;
            button:Show();
        else
            icon:SetTexture("");
            button.textureName = nil;
            button:Hide();
        end

        if ( A.iconFrame.selectedTexture == texture ) then
            button:SetChecked(1);
        else
            button:SetChecked(nil);
        end
    end

    FauxScrollFrame_Update(A.iconFrame.scrollFrame, math.ceil(#icons / 8) , 8, 36);
end

--- OnCLick callback
function A.IconsFrameButtonOnClick(_, self)
    A.iconFrame.selectedTexture = self.textureName;
    A.iconFrame.selectedIcon:SetText(L["Selected: %s"]:format("|TINTERFACE\\ICONS\\"..self.textureName..":32|t "..self.textureName));
    A.iconFrame.acceptButton:Enable();
    A:IconsFrameScrollUpdate();
end

--- OnTextChanged callback
function A:IconsFrameTextChanged(self)
    if ( self.clearButton:IsVisible() and self:GetText() ~= "" ) then
        A:IconSearch(self:GetText());
    else
        A:IconSearch(nil);
    end
end

--- Icon search method
function A:IconSearch(text)
    if ( not text or text == "" ) then
        A.iconsListSearch = nil;
        A.iconFrame.searchCount:SetText("");
        A:IconsFrameScrollUpdate();
        return;
    end

    A.iconsListSearch = {};

    text = string.lower(text);

    for k,v in pairs(A.iconsList) do
        if ( string.find(string.lower(v), text) ) then
            A.iconsListSearch[#A.iconsListSearch+1] = v;
        end
    end

    if ( #A.iconsListSearch == 0 ) then
        A.iconFrame.searchCount:SetText(L["Found %d icon"]:format(0));
    elseif ( #A.iconsListSearch == 1 ) then
        A.iconFrame.searchCount:SetText(L["Found %d icon"]:format(1));
    else
        A.iconFrame.searchCount:SetText(L["Found %d icons"]:format(#A.iconsListSearch));
    end

    A:IconsFrameScrollUpdate();
end

function A:OnClickAccept(self)
    if ( self:GetParent().type == "databroker" ) then
        A.db.profile.dataBrokerIcon = self:GetParent().selectedTexture;
        A:SetDataBroker();
    elseif ( self:GetParent().type == "petbutton" ) then
        A.db.profile.petButtonIcon = self:GetParent().selectedTexture;
        A:SetCurrentPetInfos();
        A:SetButtonsIcons();
    elseif ( self:GetParent().type == "mountbutton" ) then
        A.db.profile.mountButtonIcon = self:GetParent().selectedTexture;
        A:SetCurrentMountInfos();
        A:SetButtonsIcons();
    else
        return;
    end

    A:NotifyChangeForAll();
    self:GetParent():Hide();
end

function A:OnClickDefault(self)
    if ( self:GetParent().type == "databroker" ) then
        A.db.profile.dataBrokerIcon = A.defaultDataBrokerIcon;
        A:SetDataBroker();
    elseif ( self:GetParent().type == "petbutton" ) then
        A.db.profile.petButtonIcon = A.defaultPetButtonIcon;
        A:SetCurrentPetInfos();
        A:SetButtonsIcons();
    elseif ( self:GetParent().type == "mountbutton" ) then
        A.db.profile.mountButtonIcon = A.defaultMountButtonIcon;
        A:SetCurrentMountInfos();
        A:SetButtonsIcons();
    else
        return;
    end

    A:NotifyChangeForAll();
    self:GetParent():Hide();
end

--[[-------------------------------------------------------------------------------
    Pets and mounts list search methods
-------------------------------------------------------------------------------]]--

--- Called by the search frame OnTextChanged
-- Set the correct var and refresh the config
-- @param searchType PETS or MOUNTS
-- @param searchText The string to search for
function A:SearchListCallback(searchType, searchText)
    if ( searchType == "PETS" ) then
        if ( not searchText or searchText == "" ) then
            A.petsListSearchText = nil;
        else
            A.petsListSearchText = searchText;
        end
    elseif ( searchType == "MOUNTS" ) then
        if ( not searchText or searchText == "" ) then
            A.mountsListSearchText = nil;
        else
            A.mountsListSearchText = searchText;
        end
    else
        A.petsListSearchText = nil;
        A.mountsListSearchText = nil;
    end

    A:NotifyChangeForAll();
end

--- Return the pets list according to search string
function A:GetPetsTable()
    if ( A.petsListSearchText ) then
        local out =
        {
            [1] = {}, -- Humanoid
            [2] = {}, -- Dragonkin
            [3] = {}, -- Flying
            [4] = {}, -- Undead
            [5] = {}, -- Critter
            [6] = {}, -- Magic
            [7] = {}, -- Elemental
            [8] = {}, -- Beast
            [9] = {}, -- Aquatic
            [10] = {}, -- Mechanical
            --[11] = {}, -- None
        };

        for k,v in ipairs(A.pamTable.pets) do
            for kk,vv in pairs(v) do
                for kkk,vvv in ipairs(vv) do
                    if ( string.find(string.lower(vvv.name), string.lower(A.petsListSearchText)) or
                    (vvv.defaultName and string.find(string.lower(vvv.defaultName), string.lower(A.petsListSearchText))) ) then
                        if ( not out[k][kk] ) then out[k][kk] = {}; end
                        out[k][kk][#out[k][kk]+1] = vvv;
                    end
                end
            end
        end

        return out;
    else
        return A.pamTable.pets;
    end
end

--- Return the mounts list according to search string
function A:GetMountsTable()
    if ( A.mountsListSearchText ) then
        local out =
        {
            [1] = {}, -- Ground
            [2] = {}, -- Fly
            [3] = {}, -- Hybrid (ground & fly)
            [4] = {}, -- Aquatic
            [5] = {}, -- with passengers
            [6] = {}, -- Water walking
            [7] = {}, -- Repair
        };

        for k,v in ipairs(A.pamTable.mounts) do
            for kk,vv in pairs(v) do
                for kkk,vvv in ipairs(vv) do
                    if ( string.find(string.lower(vvv.name), string.lower(A.mountsListSearchText)) ) then
                        if ( not out[k][kk] ) then out[k][kk] = {}; end
                        out[k][kk][#out[k][kk]+1] = vvv;
                    end
                end
            end
        end

        return out;
    else
        return A.pamTable.mounts;
    end
end

--[[-------------------------------------------------------------------------------
    Input code frame methods
-------------------------------------------------------------------------------]]--

--- OnClick callback
function A:OnClickAcceptInputCode(frame)
    if ( not frame.content or not frame.where or not frame.mode or not frame.click ) then
        return;
    end

    frame.content = A:StringTrim(frame.content);
    A.db.profile.customMountMacros[frame.where][frame.mode][frame.click] = frame.content;
    frame:Hide();
    A:SetPostClickMacro();
    A:SetPreClickFunction();
    A:NotifyChangeForAll();
end

--[[-------------------------------------------------------------------------------
    Config table methods
-------------------------------------------------------------------------------]]--

local orderGroup, orderItem, petAutoSummonOverrideSelected;
local optionsOverrideHeaderText = L["None"];

function A:OptionsRoot()
    local root =
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
                    dataBroker =
                    {
                        order = 100,
                        name = L["Data Broker"],
                        type = "group",
                        inline = true,
                        args =
                        {
                            advice =
                            {
                                order = 0,
                                name = L["The main icon and the label should be disabled within your Data Broker display options. If you are not given the choice to disable both of them, you should consider using another Data Broker display.\n\nThose two options are here just in case. If it mess things up /reload is your friend.\n\n"],
                                type = "description",
                                fontSize = "medium",
                            },
                            mainIconEnable =
                            {
                                order = 1,
                                name = L["Main icon"],
                                desc = L["Enable the main icon."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.dataBrokerDisplayIcon = not A.db.profile.dataBrokerDisplayIcon;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerDisplayIcon; end,
                            },
                            label =
                            {
                                order = 2,
                                name = L["Label"],
                                desc = L["Display the label. Which is: %s"]:format(L["Pets & Mounts"]),
                                type = "toggle",
                                set = function()
                                    A.db.profile.dataBrokerDisplayLabel = not A.db.profile.dataBrokerDisplayLabel;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerDisplayLabel; end,
                            },
                            mainIconHeader =
                            {
                                order = 100,
                                name = L["Main icon"],
                                type = "header",
                            },
                            iconMode =
                            {
                                order = 101,
                                name = L["Mode"],
                                desc = L["Select the main icon mode. None will use the default one or the one you selected. Companion will use your current companion one. Mount will use your current mount one."],
                                disabled = function() return not A.db.profile.dataBrokerDisplayIcon; end,
                                type = "select",
                                values = {["none"] = L["None"], ["CURRENT_PET"] = L["Companion"], ["CURRENT_MOUNT"] = L["Mount"]},
                                set = function(info, val)
                                    A.db.profile.dataBrokerIconMode = val;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerIconMode; end,
                            },
                            selectIcon =
                            {
                                order = 102,
                                name = L["Select Icon"],
                                desc = L["Select the Data Broker main icon. This also set the minimap icon."],
                                type = "execute",
                                image = function() return "Interface\\ICONS\\"..A.db.profile.dataBrokerIcon, 36, 36; end,
                                func = function()
                                    if ( A.iconFrame:IsVisible() ) then
                                        A.iconFrame:Hide();
                                    else
                                        A.iconFrame.type = "databroker";
                                        A.iconFrame:ClearAllPoints();
                                        A.iconFrame:SetPoint("TOPLEFT", A.configFocusFrame, "TOPRIGHT", 0, 0);
                                        A.iconFrame.currentTexture = A.db.profile.dataBrokerIcon;
                                        A.iconFrame:Show();
                                    end
                                end
                            },
                            textHeader =
                            {
                                order = 200,
                                name = L["Text options"],
                                type = "header",
                            },
                            petName =
                            {
                                order = 201,
                                name = L["Companion name"],
                                desc = L["Enable the current companion name on the Data Broker display."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.dataBrokerTextPet = not A.db.profile.dataBrokerTextPet;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerTextPet; end,
                            },
                            petIcon =
                            {
                                order = 202,
                                name = L["Companion icon"],
                                desc = L["Add the current companion icon before the name."],
                                disabled = function() return not A.db.profile.dataBrokerTextPet; end,
                                type = "toggle",
                                set = function()
                                    A.db.profile.dataBrokerTextPetIcon = not A.db.profile.dataBrokerTextPetIcon;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerTextPetIcon; end,
                            },
                            blankLine1 = 
                            {
                                order = 300,
                                name = " ",
                                width = "full",
                                type = "description",
                            },
                            mountName =
                            {
                                order = 301,
                                name = L["Mount name"],
                                desc = L["Enable the current mount name on the Data Broker display."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.dataBrokerTextMount = not A.db.profile.dataBrokerTextMount;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerTextMount; end,
                            },
                            mountIcon =
                            {
                                order = 302,
                                name = L["Mount icon"],
                                desc = L["Add the current mount icon before the name."],
                                disabled = function() return not A.db.profile.dataBrokerTextMount; end,
                                type = "toggle",
                                set = function()
                                    A.db.profile.dataBrokerTextMountIcon = not A.db.profile.dataBrokerTextMountIcon;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerTextMountIcon; end,
                            },
                            blankLine2 = 
                            {
                                order = 350,
                                name = " ",
                                width = "full",
                                type = "description",
                            },
                            prependDefaultIcon =
                            {
                                order = 351,
                                name = L["Prepend default icon"],
                                desc = L["Prepend the default icon when you have no companion or mount."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.dataBrokerPrependDefaultIcon = not A.db.profile.dataBrokerPrependDefaultIcon;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerPrependDefaultIcon; end,
                            },
                            textIconSize =
                            {
                                order = 361,
                                name = L["Icon size"],
                                desc = L["Select the text icon size."],
                                type = "range",
                                min = 8,
                                max = 64,
                                step = 2,
                                width = "full",
                                set = function(info, val)
                                    A.db.profile.dataBrokerTextIconSize = val;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerTextIconSize; end,
                            },
                            textIconVerticalOffset =
                            {
                                order = 362,
                                name = L["Icon vertical offset"],
                                desc = L["Select the text icon vertical offset."],
                                type = "range",
                                min = -32,
                                max = 32,
                                step = 1,
                                width = "full",
                                set = function(info, val)
                                    A.db.profile.dataBrokerTextIconVerticalOffset = val;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerTextIconVerticalOffset; end,
                            },
                            blankLine3 = 
                            {
                                order = 370,
                                name = " ",
                                width = "full",
                                type = "description",
                            },
                            separator =
                            {
                                order = 371,
                                name = L["Separator"],
                                desc = L["Define the separator between current companion and mount."],
                                type = "input",
                                set = function(info, val)
                                    A.db.profile.dataBrokerTextSeparator = val;
                                    A:SetDataBroker();
                                end,
                                get = function() return A.db.profile.dataBrokerTextSeparator; end,
                            },
                            miscHeader =
                            {
                                order = 400,
                                name = L["Miscellaneous"],
                                type = "header",
                            },
                            minimapIcon =
                            {
                                order = 401,
                                name = L["Minimap icon"],
                                desc = L["Display the minimap icon."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.ldbi.hide = not A.db.profile.ldbi.hide;
                                    A:ShowHideMinimap();
                                end,
                                get = function() return not A.db.profile.ldbi.hide; end,
                            },
                        },
                    },
                    model =
                    {
                        order = 200,
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
                            configEnable =
                            {
                                order = 1,
                                name = L["Enable"],
                                desc = L["Enable the model frame on the configuration panel."],
                                width = "full",
                                type = "toggle",
                                set = function() A.db.profile.showConfigModelFrame = not A.db.profile.showConfigModelFrame; end,
                                get = function() return A.db.profile.showConfigModelFrame; end,
                            },
                            configRotation =
                            {
                                order = 2,
                                name = L["Model rotation"],
                                desc = L["Activate the model rotation in the frame."],
                                disabled = function() return not A.db.profile.showConfigModelFrame; end,
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
                                order = 3,
                                name = L["Size"],
                                desc = L["Select the model frame size."],
                                disabled = function() return not A.db.profile.showConfigModelFrame; end,
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
                            menuEnable =
                            {
                                order = 11,
                                name = L["Enable"],
                                desc = L["Enable the model frame on the menu."],
                                width = "full",
                                type = "toggle",
                                set = function() A.db.profile.showMenuModelFrame = not A.db.profile.showMenuModelFrame; end,
                                get = function() return A.db.profile.showMenuModelFrame; end,
                            },
                            menuRotation =
                            {
                                order = 12,
                                name = L["Model rotation"],
                                desc = L["Activate the model rotation in the frame."],
                                disabled = function() return not A.db.profile.showMenuModelFrame; end,
                                type = "toggle",
                                set = function() A.db.profile.modelRotation = not A.db.profile.modelRotation; end,
                                get = function() return A.db.profile.modelRotation; end,
                            },
                            menuSize =
                            {
                                order = 13,
                                name = L["Size"],
                                desc = L["Select the model frame size."],
                                disabled = function() return not A.db.profile.showMenuModelFrame; end,
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
                            reSummon =
                            {
                                order = 20,
                                name = L["Re-Summon"],
                                type = "header",
                            },
                            reSummonEnable =
                            {
                                order = 21,
                                name = L["Enable"],
                                desc = L["With this enabled, the add-on will summon another pet after a defined time. See next option to define the time."],
                                type = "toggle",
                                set = function() A.db.profile.petReSummon = not A.db.profile.petReSummon; end,
                                get = function() return A.db.profile.petReSummon; end,
                            },
                            reSummonTime =
                            {
                                order = 22,
                                name = L["Time"],
                                desc = L["Define re-summon time."],
                                type = "select",
                                values = reSummonValues,
                                set = function(info, val) A.db.profile.petReSummonTime = val; end,
                                get = function() return A.db.profile.petReSummonTime; end,
                            },
                            timers =
                            {
                                order = 30,
                                name = L["Timers"],
                                type = "header",
                            },
                            mainTimer =
                            {
                                order = 31,
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
                                order = 32,
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
                                desc = L["If you are in a vehicle, using the random mount will make you leave the vehicle."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.vehicleExit = not A.db.profile.vehicleExit;
                                    A:SetMacroDismountString();
                                    A:SetPostClickMacro();
                                end,
                                get = function() return A.db.profile.vehicleExit; end,
                            },
                            copyTargetMount =
                            {
                                order = 9,
                                name = L["Copy target mount"],
                                desc = L["If you target someone and he/she is on a mount, it will summon it if you have it. This have priority other copy mouse hover."],
                                type = "toggle",
                                set = function() A.db.profile.copyTargetMount = not A.db.profile.copyTargetMount; end,
                                get = function() return A.db.profile.copyTargetMount; end,
                            },
                            copyMouseoverMount =
                            {
                                order = 10,
                                name = L["Copy mouse hover mount"],
                                desc = L["If you mouse hover someone and he/she is on a mount, it will summon it if you have it. Target copy have priority other this."],
                                type = "toggle",
                                set = function() A.db.profile.copyMouseoverMount = not A.db.profile.copyMouseoverMount; end,
                                get = function() return A.db.profile.copyMouseoverMount; end,
                            },
                            noMountAfterCancelForm =
                            {
                                order = 11,
                                name = L["No mount after cancel form"],
                                desc = L["This will prevent summoning a mount after cancelling a form. Works for Druids and Shamans."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.noMountAfterCancelForm = not A.db.profile.noMountAfterCancelForm;
                                    A:SetPreClickFunction();
                                end,
                                get = function() return A.db.profile.noMountAfterCancelForm; end,
                            },
                            specialMountsHeader =
                            {
                                order = 1000,
                                name = L["Special mounts"],
                                type = "header",
                            },
                            magicBroom =
                            {
                                order = 1001,
                                name = L["Magic Broom"],
                                desc = L["Summon the Magic Broom when it is in your bags."],
                                type = "toggle",
                                set = function() A.db.profile.magicBroom = not A.db.profile.magicBroom; end,
                                get = function() return A.db.profile.magicBroom; end,
                            },
                            shimmeringMoonstone =
                            {
                                order = 1002,
                                name = L["Shimmering Moonstone"],
                                desc = L["Summon Moonfang when the Shimmering Moonstone is in your bags."],
                                type = "toggle",
                                set = function() A.db.profile.shimmeringMoonstone = not A.db.profile.shimmeringMoonstone; end,
                                get = function() return A.db.profile.shimmeringMoonstone; end,
                            },
                            swimmingOptionsHeader =
                            {
                                order = 2000,
                                name = L["Swimming options"],
                                type = "header",
                            },
                            isSwimmingMountCat =
                            {
                                order = 2001,
                                name = L["Underwater mount category"],
                                desc = L["Choose which mount category to summon when under water. This do not impact druid forms."],
                                type = "select",
                                values = function() return A.mountCat; end,
                                set = function(info, val) A.db.profile.isSwimmingMountCat = val; end,
                                get = function() return A.db.profile.isSwimmingMountCat; end,
                            },
                            customMacrosHeader =
                            {
                                order = 3000,
                                name = L["Custom macros"],
                                type = "header",
                            },
                            customMacrosEnabled =
                            {
                                order = 3002,
                                name = L["Enable"],
                                desc = L["Enable the mount button/bind custom macros."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.customMountMacrosEnabled = not A.db.profile.customMountMacrosEnabled;
                                    A:SetPostClickMacro();
                                    A:SetPreClickFunction();
                                end,
                                get = function() return A.db.profile.customMountMacrosEnabled; end,
                            },
                            customMacrosMacroProtection =
                            {
                                order = 3003,
                                name = L["Macro protection"],
                                desc = L["Enable the anti grief/scam protection. This a basic protection, the best one is still your brain."],
                                disabled = function() return not A.db.profile.customMountMacrosEnabled; end,
                                type = "toggle",
                                set = function()
                                    A.db.profile.customMacrosMacroProtectionEnabled = not A.db.profile.customMacrosMacroProtectionEnabled;
                                    A:SetPostClickMacro();
                                    A:SetPreClickFunction();
                                end,
                                get = function() return A.db.profile.customMacrosMacroProtectionEnabled; end,
                            },
                            customMacrosLUAProtection =
                            {
                                order = 3004,
                                name = L["LUA protection"],
                                desc = L["Enable the anti grief/scam protection. This a basic protection, the best one is still your brain."],
                                disabled = function() return not A.db.profile.customMountMacrosEnabled; end,
                                type = "toggle",
                                set = function()
                                    A.db.profile.customMacrosLUAProtectionEnabled = not A.db.profile.customMacrosLUAProtectionEnabled;
                                    A:SetPostClickMacro();
                                    A:SetPreClickFunction();
                                end,
                                get = function() return A.db.profile.customMacrosLUAProtectionEnabled; end,
                            },
                            
                        },
                    },
                    classSpecific =
                    {
                        order = 100,
                        name = L["Class specific"],
                        disabled = function() return A.db.profile.customMountMacrosEnabled; end,
                        type = "group",
                        inline = true,
                        args =
                        {
                            enable =
                            {
                                order = 0,
                                name = L["Enable"],
                                desc = L["Enable class specific mount button options."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.classesMacrosEnabled = not A.db.profile.classesMacrosEnabled;
                                    A:SetPostClickMacro();
                                    A:SetPreClickFunction();
                                end,
                                get = function() return A.db.profile.classesMacrosEnabled; end,
                            },
                            hideOthers =
                            {
                                order = 1,
                                name = L["Hide other classes"],
                                desc = L["Only show options for your current class."],
                                type = "toggle",
                                set = function() A.db.profile.hideOtherClasses = not A.db.profile.hideOtherClasses; end,
                                get = function() return A.db.profile.hideOtherClasses; end,
                            },
                            aWordHeader =
                            {
                                order = 10,
                                name = L["A word"],
                                type = "header",
                            },
                            aWord =
                            {
                                order = 11,
                                name = L["Out of combat: standing still will summon a random mount, moving will cast a spell for you class.\nIn combat: if you are mounted it will dismount you first, then it will cast a spell for your class, moving or not."],
                                type = "description",
                                fontSize = "medium",
                            },
                            aWordBlankLine =
                            {
                                order = 12,
                                name = " ",
                                type = "description",
                            },
                            -- Death Knight 1xx
                            deathKnight =
                            {
                                order = 100,
                                name = A.color.DEATHKNIGHT..L["Death Knight"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "DEATHKNIGHT" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    deathKnightDescription =
                                    {
                                        order = 1,
                                        name = L["For Death Knights it handles Death's Advance and Unholy Presence when moving."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    deathKnightBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    deathKnightHeader =
                                    {
                                        order = 10,
                                        name = L["Options"],
                                        type = "header",
                                    },
                                    deathKnightPreferUnholy =
                                    {
                                        order = 20,
                                        name = L["Prefer Unholy Presence"],
                                        desc = L["Prioritise Unholy Presence other Death's Advance. If Death's Advance is not selected and this option either, it will still use Unholy Presence."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.deathKnightPreferUnholy = not A.db.profile.deathKnightPreferUnholy;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.deathKnightPreferUnholy; end,
                                    },
                                },
                            },
                            -- Druid 2xx
                            druid =
                            {
                                order = 200,
                                name = A.color.DRUID..L["Druid"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "DRUID" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    druidDescription =
                                    {
                                        order = 1,
                                        name = L["For Druids it handles aquatic, travel and both flight forms."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    druidBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    druidHeader =
                                    {
                                        order = 10,
                                        name = L["Options"],
                                        type = "header",
                                    },
                                    druidWantFormsOnMove =
                                    {
                                        order = 20,
                                        name = L["Forms on move"],
                                        desc = L["Instead of just using forms, this will only use forms when moving and regular mounts when standing still. This is only affecting out of combat macro."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.druidWantFormsOnMove = not A.db.profile.druidWantFormsOnMove;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.druidWantFormsOnMove; end,
                                    },
                                },
                            },
                            -- Hunter 3xx
                            hunter =
                            {
                                order = 300,
                                name = A.color.HUNTER..L["Hunter"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "HUNTER" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    hunterDescription =
                                    {
                                        order = 1,
                                        name = L["For Hunters it handles Aspect of the Cheetah and Aspect of the Pack when moving."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    hunterBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    hunterHeader =
                                    {
                                        order = 10,
                                        name = L["Options"],
                                        type = "header",
                                    },
                                    hunterPreferPack =
                                    {
                                        order = 20,
                                        name = L["Prefer Aspect of the Pack"],
                                        desc = L["Prioritise Aspect of the Pack other Aspect of the Cheetah."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.hunterPreferPack = not A.db.profile.hunterPreferPack;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.hunterPreferPack; end,
                                    },
                                    hunterWantModifier =
                                    {
                                        order = 21,
                                        name = L["Use a modifier"],
                                        desc = L["Use a modifier to disable the aspect, this will also prevent the spell toggle.\n Be aware that if a bind is set to the modifier plus the button bind this will not work."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.hunterWantModifier = not A.db.profile.hunterWantModifier;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.hunterWantModifier; end,
                                    },
                                    hunterModifier =
                                    {
                                        order = 22,
                                        name = L["Modifier"],
                                        desc = L["Select which modifier to use for cancelling aspect."],
                                        disabled = function()
                                            if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled or not A.db.profile.hunterWantModifier ) then
                                                return 1;
                                            end

                                            return nil;
                                        end,
                                        type = "select",
                                        values = A.modifiersList,
                                        set = function(info, val)
                                            A.db.profile.hunterModifier = val;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.hunterModifier; end,
                                    },
                                },
                            },
                            blankFix = -- Dunno why but the next group name after the hunter's one is sticked to its bottom
                            {
                                order = 399,
                                name = " ",
                                type = "description",
                            },
                            -- Mage 4xx
                            mage =
                            {
                                order = 400,
                                name = A.color.MAGE..L["Mage"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "MAGE" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    mageDescription =
                                    {
                                        order = 1,
                                        name = L["For Mages it handles Blazing Speed and Blink when moving. Slow Fall when falling."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    mageBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    mageHeader =
                                    {
                                        order = 10,
                                        name = L["Options"],
                                        type = "header",
                                    },
                                    magePreferBlink =
                                    {
                                        order = 20,
                                        name = L["Prefer Blink"],
                                        desc = L["Prioritise Blink other Blazing Speed. If Blazing Speed is not selected and this option either, it will still use Blink."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.magePreferBlink = not A.db.profile.magePreferBlink;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.magePreferBlink; end,
                                    },
                                    mageSlowFall =
                                    {
                                        order = 21,
                                        name = L["Slow Fall"],
                                        desc = L["Use Slow Fall when falling. IMPORTANT: This will not work when in combat, this is why there is an option to disable it."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.mageSlowFall = not A.db.profile.mageSlowFall;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.mageSlowFall; end,
                                    },
                                    mageForceSlowFall =
                                    {
                                        order = 22,
                                        name = L["Force Slow Fall"],
                                        desc = L["Force Slow Fall when in combat. This will obviously make Blazing Speed or Blink unavailable in combat."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.mageForceSlowFall = not A.db.profile.mageForceSlowFall;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.mageForceSlowFall; end,
                                    },
                                },
                            },
                            -- Monk 5xx
                            monk =
                            {
                                order = 500,
                                name = A.color.MONK..L["Monk"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "MONK" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    monkDescription =
                                    {
                                        order = 1,
                                        name = L["For Monks it handles Flying Serpent Kick and Roll when moving. Zen Flight when falling."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    monkBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    monkHeader =
                                    {
                                        order = 10,
                                        name = L["Options"],
                                        type = "header",
                                    },
                                    monkPreferFlyingSerpentKick =
                                    {
                                        order = 20,
                                        name = L["Prefer Flying Serpent Kick"],
                                        desc = L["Prioritise Flying Serpent Kick other Roll."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.monkPreferSerpentKick = not A.db.profile.monkPreferSerpentKick;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.monkPreferSerpentKick; end,
                                    },
                                    monkModifier =
                                    {
                                        order = 21,
                                        name = L["Modifier"],
                                        desc = L["Select which modifier to use for cancelling Zen Flight."],
                                        type = "select",
                                        values = A.modifiersList,
                                        set = function(info, val)
                                            A.db.profile.monkModifier = val;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.monkModifier; end,
                                    },
                                },
                            },
                            -- Paladin 6xx
                            paladin =
                            {
                                order = 600,
                                name = A.color.PALADIN..L["Paladin"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "PALADIN" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    paladinDescription =
                                    {
                                        order = 1,
                                        name = L["For Paladins it handles Speed of Light when moving."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    paladinBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    -- paladinHeader =
                                    -- {
                                        -- order = 10,
                                        -- name = L["Options"],
                                        -- type = "header",
                                    -- },
                                },
                            },
                            -- Priest 7xx
                            priest =
                            {
                                order = 700,
                                name = A.color.PRIEST..L["Priest"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "PRIEST" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    priestDescription =
                                    {
                                        order = 1,
                                        name = L["For Priests it handles Body and Soul and Angelic Feather when moving."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    priestBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    priestHeader =
                                    {
                                        order = 10,
                                        name = L["Options"],
                                        type = "header",
                                    },
                                    priestLevitate =
                                    {
                                        order = 20,
                                        name = L["Levitate"],
                                        desc = L["Use Levitate when falling. IMPORTANT: This will not work when in combat, this is why there is an option to disable it."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.priestLevitate = not A.db.profile.priestLevitate;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.priestLevitate; end,
                                    },
                                    priestForceLevitate =
                                    {
                                        order = 21,
                                        name = L["Force Levitate"],
                                        desc = L["Force Levitate when in combat. This will obviously make Body and Soul or Angelic Feather unavailable in combat."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.priestForceLevitate = not A.db.profile.priestForceLevitate;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.priestForceLevitate; end,
                                    },
                                },
                            },
                            -- Rogue 8xx
                            rogue =
                            {
                                order = 800,
                                name = A.color.ROGUE..L["Rogue"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "ROGUE" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    rogueDescription =
                                    {
                                        order = 1,
                                        name = L["For Rogues it handles Sprint when moving."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    rogueBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    -- rogueHeader =
                                    -- {
                                        -- order = 10,
                                        -- name = L["Options"],
                                        -- type = "header",
                                    -- },
                                },
                            },
                            -- Shaman 9xx
                            shaman =
                            {
                                order = 900,
                                name = A.color.SHAMAN..L["Shaman"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "SHAMAN" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    shamanDescription =
                                    {
                                        order = 1,
                                        name = L["For Shamans it handles Ghost Wolf when moving."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    shamanBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    -- shamanHeader =
                                    -- {
                                        -- order = 10,
                                        -- name = L["Options"],
                                        -- type = "header",
                                    -- },
                                },
                            },
                            -- Warlock 10xx
                            warlock =
                            {
                                order = 1000,
                                name = A.color.WARLOCK..L["Warlock"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "WARLOCK" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args =
                                {
                                    warlockDescription =
                                    {
                                        order = 1,
                                        name = L["For Warlocks it handles Burning Rush and Demonic Circle: Teleport when moving."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    warlockBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    warlockHeader =
                                    {
                                        order = 10,
                                        name = L["Options"],
                                        type = "header",
                                    },
                                    warlockPreferTeleport =
                                    {
                                        order = 20,
                                        name = L["Prefer Teleport"],
                                        desc = L["Prioritise Demonic Circle: Teleport other Burning Rush. If Burning Rush is not selected and this option either, it will still use Demonic Circle: Teleport."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.warlockPreferTeleport = not A.db.profile.warlockPreferTeleport;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.warlockPreferTeleport; end,
                                    },
                                    warlockWantModifier =
                                    {
                                        order = 21,
                                        name = L["Use a modifier"],
                                        desc = L["Use a modifier to disable Burning Rush, this will also prevent the spell toggle.\n Be aware that if a bind is set to the modifier plus the button bind this will not work."],
                                        disabled = function()
                                            if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled or A.db.profile.warlockPreferTeleport ) then
                                                return 1;
                                            end

                                            return nil;
                                        end,
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.warlockWantModifier = not A.db.profile.warlockWantModifier;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.warlockWantModifier; end,
                                    },
                                    warlockModifier =
                                    {
                                        order = 22,
                                        name = L["Modifier"],
                                        desc = L["Select which modifier to use for cancelling Burning Rush."],
                                        disabled = function()
                                            if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled or not A.db.profile.warlockWantModifier or A.db.profile.warlockPreferTeleport ) then
                                                return 1;
                                            end

                                            return nil;
                                        end,
                                        type = "select",
                                        values = A.modifiersList,
                                        set = function(info, val)
                                            A.db.profile.warlockModifier = val;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.warlockModifier; end,
                                    },
                                },
                            },
                            -- Warrior 11xx
                            warrior =
                            {
                                order = 1100,
                                name = A.color.WARRIOR..L["Warrior"],
                                type = "group",
                                inline = true,
                                disabled = function()
                                    if ( A.db.profile.customMountMacrosEnabled or not A.db.profile.classesMacrosEnabled ) then
                                        return 1;
                                    end

                                    return nil;
                                end,
                                hidden = function()
                                    if ( A.playerClass == "WARRIOR" or not A.db.profile.hideOtherClasses ) then
                                        return nil;
                                    end

                                    return 1;
                                end,
                                args = -- warriorForceHeroicLeap
                                {
                                    warriorDescription =
                                    {
                                        order = 1,
                                        name = L["For Warriors it handles Heroic Leap when moving and out of combat. Charge with a hostile target and Intervene with a friendly target when in combat."],
                                        type = "description",
                                        fontSize = "medium",
                                    },
                                    warriorBlankLine =
                                    {
                                        order = 2,
                                        name = " ",
                                        width = "full",
                                        type = "description",
                                    },
                                    warriorHeader =
                                    {
                                        order = 10,
                                        name = L["Options"],
                                        type = "header",
                                    },
                                    warriorPreferTeleport =
                                    {
                                        order = 20,
                                        name = L["Force Heroic Leap"],
                                        desc = L["This will force Heroic Leap when in combat."],
                                        type = "toggle",
                                        set = function()
                                            A.db.profile.warriorForceHeroicLeap = not A.db.profile.warriorForceHeroicLeap;
                                            A:SetPostClickMacro();
                                            A:SetPreClickFunction();
                                        end,
                                        get = function() return A.db.profile.warriorForceHeroicLeap; end,
                                    },
                                },
                            },
                        },
                    },
                    mountsSummonFilters =
                    {
                        order = 200,
                        name = L["Random mount summon filters"],
                        type = "group",
                        inline = true,
                        args = {},
                    },
                },
            },
            --
            -- Main options tree - Custom macros tab
            --
            customMacros =
            {
                order = 400,
                name = L["Custom macros"],
                type = "group",
                hidden = function() return not A.db.profile.customMountMacrosEnabled; end,
                args =
                {
                    summary =
                    {
                        order = 0,
                        name = L["Summary"],
                        type = "group",
                        args =
                        {
                            explanations =
                            {
                                order = 0,
                                name = L["CUSTOM_MACROS_EXLANATIONS"],
                                type = "description",
                                fontSize = "medium",
                            },
                        },
                    },
                    default =
                    {
                        order = 50,
                        name = L["Macro: %s"]:format(L["Default"]),
                        type = "group",
                        args =
                        {
                            luaMode =
                            {
                                order = 0,
                                name = L["LUA mode"],
                                desc = L["Use LUA code instead of macro syntax."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.customMountMacros.default.luaMode = not A.db.profile.customMountMacros.default.luaMode;
                                    A:SetPreClickFunction();
                                    A:SetPostClickMacro();
                                end,
                                get = function() return A.db.profile.customMountMacros.default.luaMode; end,
                            },
                            preClickHeader =
                            {
                                order = 100,
                                name = L["Pre Click"],
                                type = "header",
                            },
                            preClickInput =
                            {
                                order = 101,
                                name = L["Pre Click"],
                                width = "full",
                                type = "input",
                                multiline = 5,
                                set = function(info, val)
                                    if ( A.db.profile.customMountMacros.default.luaMode ) then
                                        A.db.profile.customMountMacros.default.lua.pre = val;
                                    else
                                        A.db.profile.customMountMacros.default.macro.pre = val;
                                    end
                                    A:SetPostClickMacro();
                                    A:SetPreClickFunction();
                                end,
                                get = function()
                                    if ( A.db.profile.customMountMacros.default.luaMode ) then
                                        return A.db.profile.customMountMacros.default.lua.pre;
                                    else
                                        return A.db.profile.customMountMacros.default.macro.pre;
                                    end
                                end,
                            },
                            expandPreClick =
                            {
                                order = 102,
                                name = L["Expand"],
                                desc = L["Expand the text editor."],
                                type = "execute",
                                func = function()
                                    if ( A.db.profile.customMountMacros.default.luaMode ) then
                                        A.inputFrame.where = "default";
                                        A.inputFrame.mode = "lua";
                                        A.inputFrame.click = "pre";
                                        A.inputFrame.content = A.db.profile.customMountMacros.default.lua.pre;
                                    else
                                        A.inputFrame.where = "default";
                                        A.inputFrame.mode = "macro";
                                        A.inputFrame.click = "pre";
                                        A.inputFrame.content = A.db.profile.customMountMacros.default.macro.pre;
                                    end

                                    if ( A.inputFrame:IsVisible() ) then
                                        A.inputFrame:Hide();
                                    else
                                        A.inputFrame:ClearAllPoints();
                                        A.inputFrame:SetPoint("TOP", A.configFocusFrame, "TOP", 0, 0);
                                        A.inputFrame:Show();
                                    end
                                end,
                            },
                            postClickHeader =
                            {
                                order = 200,
                                name = L["Post Click"],
                                type = "header",
                            },
                            postClickInput =
                            {
                                order = 201,
                                name = L["Post Click"],
                                width = "full",
                                type = "input",
                                multiline = 5,
                                set = function(info, val)
                                    if ( A.db.profile.customMountMacros.default.luaMode ) then
                                        A.db.profile.customMountMacros.default.lua.post = val;
                                    else
                                        A.db.profile.customMountMacros.default.macro.post = val;
                                    end
                                    A:SetPostClickMacro();
                                    A:SetPreClickFunction();
                                end,
                                get = function()
                                    if ( A.db.profile.customMountMacros.default.luaMode ) then
                                        return A.db.profile.customMountMacros.default.lua.post;
                                    else
                                        return A.db.profile.customMountMacros.default.macro.post;
                                    end
                                end,
                            },
                            expandPostClick =
                            {
                                order = 202,
                                name = L["Expand"],
                                desc = L["Expand the text editor."],
                                type = "execute",
                                func = function()
                                    if ( A.db.profile.customMountMacros.default.luaMode ) then
                                        A.inputFrame.where = "default";
                                        A.inputFrame.mode = "lua";
                                        A.inputFrame.click = "post";
                                        A.inputFrame.content = A.db.profile.customMountMacros.default.lua.post;
                                    else
                                        A.inputFrame.where = "default";
                                        A.inputFrame.mode = "macro";
                                        A.inputFrame.click = "post";
                                        A.inputFrame.content = A.db.profile.customMountMacros.default.macro.post;
                                    end

                                    if ( A.inputFrame:IsVisible() ) then
                                        A.inputFrame:Hide();
                                    else
                                        A.inputFrame:ClearAllPoints();
                                        A.inputFrame:SetPoint("TOP", A.configFocusFrame, "TOP", 0, 0);
                                        A.inputFrame:Show();
                                    end
                                end,
                            },
                        },
                    },
                },
            },
            --
            -- Main options tree - Bindings tab
            --
            bindings =
            {
                order = 500,
                name = L["Bindings"],
                type = "group",
                args = {},
            },
            --
            -- Main options tree - Buttons tab
            --
            buttons =
            {
                order = 600,
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
                                desc = L["Reset the companions button position."],
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
                            iconHeader =
                            {
                                order = 100,
                                name = L["Icon"],
                                type = "header",
                            },
                            useCurrent =
                            {
                                order = 101,
                                name = L["Use current"],
                                desc = L["The companion button will use the current summoned companion icon."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.petButtonIconCurrent = not A.db.profile.petButtonIconCurrent;
                                    A:ApplyCurrentPetInfos();
                                end,
                                get = function() return A.db.profile.petButtonIconCurrent; end,
                            },
                            selectIcon =
                            {
                                order = 102,
                                name = L["Select Icon"],
                                desc = L["Select the companion button main icon."],
                                type = "execute",
                                image = function() return "Interface\\ICONS\\"..A.db.profile.petButtonIcon, 36, 36; end,
                                func = function()
                                    if ( A.iconFrame:IsVisible() ) then
                                        A.iconFrame:Hide();
                                    else
                                        A.iconFrame.type = "petbutton";
                                        A.iconFrame:ClearAllPoints();
                                        A.iconFrame:SetPoint("TOPLEFT", A.configFocusFrame, "TOPRIGHT", 0, 0);
                                        A.iconFrame.currentTexture = A.db.profile.petButtonIcon;
                                        A.iconFrame:Show();
                                    end
                                end
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
                                desc = L["Reset the mounts button position."],
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
                            iconHeader =
                            {
                                order = 100,
                                name = L["Icon"],
                                type = "header",
                            },
                            useCurrent =
                            {
                                order = 101,
                                name = L["Use current"],
                                desc = L["The mount button will use the current summoned mount icon."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.mountButtonIconCurrent = not A.db.profile.mountButtonIconCurrent;
                                    A:ApplyCurrentMountInfos();
                                end,
                                get = function() return A.db.profile.mountButtonIconCurrent; end,
                            },
                            selectIcon =
                            {
                                order = 102,
                                name = L["Select Icon"],
                                desc = L["Select the mount button main icon."],
                                type = "execute",
                                image = function() return "Interface\\ICONS\\"..A.db.profile.mountButtonIcon, 36, 36; end,
                                func = function()
                                    if ( A.iconFrame:IsVisible() ) then
                                        A.iconFrame:Hide();
                                    else
                                        A.iconFrame.type = "mountbutton";
                                        A.iconFrame:ClearAllPoints();
                                        A.iconFrame:SetPoint("TOPLEFT", A.configFocusFrame, "TOPRIGHT", 0, 0);
                                        A.iconFrame.currentTexture = A.db.profile.mountButtonIcon;
                                        A.iconFrame:Show();
                                    end
                                end
                            },
                            clickBehavior =
                            {
                                order = 200,
                                name = L["Click behavior"],
                                type = "header",
                            },
                            shiftClick =
                            {
                                order = 201,
                                name = L["Shift+Click"],
                                desc = L["Choose which mount category to summon when using %s"]:format(L["Shift+Click"]),
                                type = "select",
                                values = function() return A.mountCat; end,
                                set = function(info, val) A.db.profile.mountButtonshiftClickCat = val; end,
                                get = function() return A.db.profile.mountButtonshiftClickCat; end,
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

                                    if ( not A.db.profile.dockButton ) then
                                        A:Message(L["Cannot modify buttons anchors when they are not docked."], 1);
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
    }; -- / root table

    -- Pets summon filters
    orderItem = 0;
    for k,v in ipairs(A.petsSummonFilters) do
        if ( v.option ) then
            root.args.petsOptions.args.petsSummonFilters.args[v.name] =
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
            root.args.mountsOptions.args.mountsSummonFilters.args[v.name] =
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

    -- Bindings
    orderGroup = 0;
    for k,v in ipairs(A.bindingsTable) do
        root.args.bindings.args[tostring(k)] =
        {
            order = orderGroup,
            name = v.localized,
            type = "group",
            inline = true,
            args =
            {
                randomPetKey1 =
                {
                    order = 0,
                    name = L["Key one"],
                    desc = v.configDesc,
                    type = "keybinding",
                    set = function(info, val)
                        local set = GetCurrentBindingSet();
                        local key1, key2 = GetBindingKey(v.name, set);

                        if ( key1 ) then SetBinding(key1, nil, set); end
                        if ( key2 ) then SetBinding(key2, nil, set); end

                        if ( val == "" ) then
                            if ( key2 ) then SetBinding(key2, v.name, set); end
                        else
                            SetBinding(val, v.name, set);

                            if ( key2 ) then SetBinding(key2, v.name, set); end
                        end

                        SaveBindings(set);
                    end,
                    get = function()
                        local set = GetCurrentBindingSet();
                        return GetBindingKey(v.name, set);
                    end,
                },
                randomPetKey2 =
                {
                    order = 1,
                    name = L["Key two"],
                    desc = v.configDesc,
                    type = "keybinding",
                    set = function(info, val)
                        local set = GetCurrentBindingSet();
                        local key1, key2 = GetBindingKey(v.name, set);

                        if ( key1 ) then SetBinding(key1, nil, set); end
                        if ( key2 ) then SetBinding(key2, nil, set); end

                        if ( val == "" ) then
                            if ( key1 ) then SetBinding(key1, v.name, set); end
                        else
                            if ( key1 ) then SetBinding(key1, v.name, set); end

                            SetBinding(val, v.name, set);
                        end

                        SaveBindings(set);
                    end,
                    get = function()
                        local set = GetCurrentBindingSet();
                        local _, key = GetBindingKey(v.name, set);
                        return key;
                    end,
                },
            },
        };

        orderGroup = orderGroup + 1;
    end

    -- Custom macros
    orderGroup = 100;
    for k,v in ipairs(A.areaTypes) do
        root.args.customMacros.args[v] =
        {
            order = orderGroup,
            name = L["Macro: %s"]:format(A.areaTypesLocales[v]),
            type = "group",
            args =
            {
                luaMode =
                {
                    order = 0,
                    name = L["LUA mode"],
                    desc = L["Use LUA code instead of macro syntax."],
                    type = "toggle",
                    set = function()
                        A.db.profile.customMountMacros[v].luaMode = not A.db.profile.customMountMacros[v].luaMode;
                        A:SetPreClickFunction();
                        A:SetPostClickMacro();
                    end,
                    get = function() return A.db.profile.customMountMacros[v].luaMode; end,
                },
                preClickHeader =
                {
                    order = 100,
                    name = L["Pre Click"],
                    type = "header",
                },
                preClickInput =
                {
                    order = 101,
                    name = L["Pre Click"],
                    width = "full",
                    type = "input",
                    multiline = 5,
                    set = function(info, val)
                        if ( A.db.profile.customMountMacros[v].luaMode ) then
                            A.db.profile.customMountMacros[v].lua.pre = val;
                        else
                            A.db.profile.customMountMacros[v].macro.pre = val;
                        end
                        A:SetPostClickMacro();
                        A:SetPreClickFunction();
                    end,
                    get = function()
                        if ( A.db.profile.customMountMacros.default.luaMode ) then
                            return A.db.profile.customMountMacros[v].lua.pre;
                        else
                            return A.db.profile.customMountMacros[v].macro.pre;
                        end
                    end,
                },
                expandPreClick =
                {
                    order = 102,
                    name = L["Expand"],
                    desc = L["Expand the text editor."],
                    type = "execute",
                    func = function()
                        if ( A.db.profile.customMountMacros[v].luaMode ) then
                            A.inputFrame.where = v;
                            A.inputFrame.mode = "lua";
                            A.inputFrame.click = "pre";
                            A.inputFrame.content = A.db.profile.customMountMacros[v].lua.pre;
                        else
                            A.inputFrame.where = v;
                            A.inputFrame.mode = "macro";
                            A.inputFrame.click = "pre";
                            A.inputFrame.content = A.db.profile.customMountMacros[v].macro.pre;
                        end

                        if ( A.inputFrame:IsVisible() ) then
                            A.inputFrame:Hide();
                        else
                            A.inputFrame:ClearAllPoints();
                            A.inputFrame:SetPoint("TOP", A.configFocusFrame, "TOP", 0, 0);
                            A.inputFrame:Show();
                        end
                    end,
                },
                postClickHeader =
                {
                    order = 200,
                    name = L["Post Click"],
                    type = "header",
                },
                postClickInput =
                {
                    order = 201,
                    name = L["Post Click"],
                    width = "full",
                    type = "input",
                    multiline = 5,
                    set = function(info, val)
                        if ( A.db.profile.customMountMacros[v].luaMode ) then
                            A.db.profile.customMountMacros[v].lua.post = val;
                        else
                            A.db.profile.customMountMacros[v].macro.post = val;
                        end
                        A:SetPostClickMacro();
                        A:SetPreClickFunction();
                    end,
                    get = function()
                        if ( A.db.profile.customMountMacros[v].luaMode ) then
                            return A.db.profile.customMountMacros[v].lua.post;
                        else
                            return A.db.profile.customMountMacros[v].macro.post;
                        end
                    end,
                },
                expandPostClick =
                {
                    order = 202,
                    name = L["Expand"],
                    desc = L["Expand the text editor."],
                    type = "execute",
                    func = function()
                        if ( A.db.profile.customMountMacros[v].luaMode ) then
                            A.inputFrame.where = v;
                            A.inputFrame.mode = "lua";
                            A.inputFrame.click = "post";
                            A.inputFrame.content = A.db.profile.customMountMacros[v].lua.post;
                        else
                            A.inputFrame.where = v;
                            A.inputFrame.mode = "macro";
                            A.inputFrame.click = "post";
                            A.inputFrame.content = A.db.profile.customMountMacros[v].macro.post;
                        end

                        if ( A.inputFrame:IsVisible() ) then
                            A.inputFrame:Hide();
                        else
                            A.inputFrame:ClearAllPoints();
                            A.inputFrame:SetPoint("TOP", A.configFocusFrame, "TOP", 0, 0);
                            A.inputFrame:Show();
                        end
                    end,
                },
            },
        };
        orderGroup = orderGroup + 1;
    end

    -- Profiles
    root.args.profilesOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(A.db);
    root.args.profilesOptions.order = 10000;

    return root;
end

-- function A:OptionsCustomMacros()
    -- local customMacros =
    -- {
        -- order = 0,
        -- name = L["Custom macros"],
        -- disabled = function() return not A.db.profile.customMountMacrosEnabled; end,
        -- type = "group",
        -- childGroups = "tab",
        -- args = {},
    -- };

    -- return customMacros;
-- end

function A:OptionsPetsList()
    local pets =
    {
        order = 0,
        name = L["Companions list"],
        type = "group",
        childGroups = "tab",
        args = {},
    };

    -- Pets list
    orderGroup = 0;
    orderItem = 0;
    for k,v in ipairs(A:GetPetsTable()) do
        if ( A:TableCount(v) > 0 )then
            pets.args[A.petTypes[k]] =
            {
                order = k,
                name = L[A.petTypes[k]],
                type = "group",
                args = {},
            };

            for kk,vv in A:PairsByKeys(v) do
                pets.args[A.petTypes[k]].args[kk] =
                {
                    order = orderGroup,
                    name = kk,
                    type = "group",
                    inline = true,
                    args = {},
                };

                orderGroup = orderGroup + 1;

                for kkk,vvv in ipairs(vv) do
                    pets.args[A.petTypes[k]].args[kk].args[vvv.name..vvv.petID] =
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
                            if ( A.db.profile.showConfigModelFrame ) then
                                A.configModelFrame.rotation = 0;
                                A.configModelFrame:SetCreature(vvv.creatureID);

                                -- Frame pos
                                A.configModelFrame:ClearAllPoints()
                                A.configModelFrame:SetPoint("TOPLEFT", A.configFocusFrame, "TOPRIGHT", 0, 0);
                                A.configModelFrame:Show();
                            else
                                A.configModelFrame:Hide();
                            end

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

                            A.usablePetsCache = nil;
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
    end

    -- Pets mass actions tab
    pets.args.massActions =
    {
        order = 1000,
        name = L["Mass actions"],
        type = "group",
        args =
        {
            selectedFav =
            {
                order = 0,
                name = function()
                    local count = #A.db.profile.favoritePets;

                    return L["You currently have %d selected favorites.\n\n"]:format(count);
                end,
                type = "description",
                fontSize = "medium",
            },
            selectAllByCat =
            {
                order = 100,
                name = L["Select all by category"],
                type = "group",
                inline = true,
                args = {},
            },
            selectNoneByCat =
            {
                order = 200,
                name = L["Select none by category"],
                type = "group",
                inline = true,
                args = {},
            },
            selectAll =
            {
                order = 1000,
                name = L["Select all"],
                type = "group",
                inline = true,
                args =
                {
                    toggle =
                    {
                        order = 0,
                        name = L["Enable"],
                        type = "toggle",
                        get = function() return A.enablePetSelectAllButton; end,
                        set = function() A.enablePetSelectAllButton = not A.enablePetSelectAllButton; end,
                    },
                    exec =
                    {
                        order = 1,
                        name = L["Select all"],
                        type = "execute",
                        disabled = function() return not A.enablePetSelectAllButton; end,
                        func = function()
                            A.db.profile.favoritePets = {};

                            for k,v in ipairs(A.pamTable.pets) do
                                for kk,vv in pairs(v) do
                                    for kkk,vvv in ipairs(vv) do
                                        A.db.profile.favoritePets[#A.db.profile.favoritePets+1] = vvv.petID;
                                    end
                                end
                            end

                            A.usablePetsCache = nil;
                            A.enablePetSelectAllButton = nil;
                        end,
                    },
                },
            },
            selectNone =
            {
                order = 1001,
                name = L["Select none"],
                type = "group",
                inline = true,
                args =
                {
                    toggle =
                    {
                        order = 0,
                        name = L["Enable"],
                        type = "toggle",
                        get = function() return A.enablePetSelectNoneButton; end,
                        set = function() A.enablePetSelectNoneButton = not A.enablePetSelectNoneButton; end,
                    },
                    exec =
                    {
                        order = 1,
                        name = L["Select none"],
                        type = "execute",
                        disabled = function() return not A.enablePetSelectNoneButton; end,
                        func = function()
                            A.db.profile.favoritePets = {};
                            A.usablePetsCache = nil;
                            A.enablePetSelectNoneButton = nil;
                        end,
                    },
                },
            },
        },
    };

    orderItem = 0;
    for k,v in ipairs(A.pamTable.pets) do
        pets.args.massActions.args.selectAllByCat.args[A.petTypes[k]] =
        {
            order = orderItem,
            name = L["Select all: %s"]:format(L[A.petTypes[k]]),
            type = "execute",
            func = function()
                local count = 0;

                for kk,vv in pairs(v) do
                    for kkk,vvv in ipairs(vv) do
                        if ( not tContains(A.db.profile.favoritePets, vvv.petID) ) then
                            A.db.profile.favoritePets[#A.db.profile.favoritePets+1] = vvv.petID;
                            count = count + 1;
                        end
                    end
                end

                if ( count > 1 ) then
                    A:Message(L["Added %d entries."]:format(count));
                else
                    A:Message(L["Added %d entry."]:format(count));
                end
            end,
        };

        pets.args.massActions.args.selectNoneByCat.args[A.petTypes[k]] =
        {
            order = orderItem,
            name = L["Select none: %s"]:format(L[A.petTypes[k]]),
            type = "execute",
            func = function()
                local count = 0;

                for kk,vv in pairs(v) do
                    for kkk,vvv in ipairs(vv) do
                        if ( A:TableRemove(A.db.profile.favoritePets, vvv.petID) ) then
                            count = count + 1;
                        end
                    end
                end

                if ( count > 1 ) then
                    A:Message(L["Removed %d entries."]:format(count));
                else
                    A:Message(L["Removed %d entry."]:format(count));
                end
            end,
        };

        orderItem = orderItem + 1;
    end

    return pets;
end

function A:OptionsMountsList()
    local mounts =
    {
        order = 0,
        name = L["Mounts list"],
        type = "group",
        childGroups = "tab",
        args = {},
    };

    -- Mounts list
    orderGroup = 0;
    orderItem = 0;
    for k,v in ipairs(A:GetMountsTable()) do
        if ( A:TableCount(v) > 0 ) then
            mounts.args[A.mountCat[k]] =
            {
                order = k,
                name = A.mountCat[k],
                type = "group",
                args = {},
            };

            for kk,vv in A:PairsByKeys(v) do
                mounts.args[A.mountCat[k]].args[kk] =
                {
                    order = orderGroup,
                    name = kk,
                    type = "group",
                    inline = true,
                    args = {},
                };

                orderGroup = orderGroup + 1;

                for kkk,vvv in ipairs(vv) do
                    mounts.args[A.mountCat[k]].args[kk].args[vvv.name..vvv.id] =
                    {
                        order = orderItem,
                        name = vvv.name,
                        desc = function()
                            -- Model
                            if ( A.db.profile.showConfigModelFrame ) then
                                A.configModelFrame.rotation = 0;
                                A.configModelFrame:SetCreature(vvv.creatureID);

                                -- Frame pos
                                A.configModelFrame:ClearAllPoints()
                                A.configModelFrame:SetPoint("TOPLEFT", A.configFocusFrame, "TOPRIGHT", 0, 0);
                                A.configModelFrame:Show();
                            else
                                A.configModelFrame:Hide();
                            end

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

                            A.usableMountsCache = nil;
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

    -- Mounts mass actions tab
    mounts.args.massActions =
    {
        order = 1000,
        name = L["Mass actions"],
        type = "group",
        args =
        {
            selectedFav =
            {
                order = 0,
                name = function()
                    local count = 0;

                    for k,v in ipairs(A.db.profile.favoriteMounts) do
                        count = count + #v;
                    end

                    return L["You currently have %d selected favorites.\n\n"]:format(count);
                end,
                type = "description",
                fontSize = "medium",
            },
            selectAllByCat =
            {
                order = 100,
                name = L["Select all by category"],
                type = "group",
                inline = true,
                args = {},
            },
            selectNoneByCat =
            {
                order = 200,
                name = L["Select none by category"],
                type = "group",
                inline = true,
                args = {},
            },
            selectAll =
            {
                order = 1000,
                name = L["Select all"],
                type = "group",
                inline = true,
                args =
                {
                    toggle =
                    {
                        order = 0,
                        name = L["Enable"],
                        type = "toggle",
                        get = function() return A.enableMountSelectAllButton; end,
                        set = function() A.enableMountSelectAllButton = not A.enableMountSelectAllButton; end,
                    },
                    exec =
                    {
                        order = 1,
                        name = L["Select all"],
                        type = "execute",
                        disabled = function() return not A.enableMountSelectAllButton; end,
                        func = function()
                            A.db.profile.favoriteMounts = {};

                            for k,v in ipairs(A.pamTable.mounts) do
                                for kk,vv in pairs(v) do
                                    for kkk,vvv in ipairs(vv) do
                                        A.db.profile.favoriteMounts[k][#A.db.profile.favoriteMounts[k]+1] = vvv.spellID;
                                    end
                                end
                            end

                            A.usableMountsCache = nil;
                            A.enableMountSelectAllButton = nil;
                        end,
                    },
                },
            },
            selectNone =
            {
                order = 1001,
                name = L["Select none"],
                type = "group",
                inline = true,
                args =
                {
                    toggle =
                    {
                        order = 0,
                        name = L["Enable"],
                        type = "toggle",
                        get = function() return A.enableMountSelectNoneButton; end,
                        set = function() A.enableMountSelectNoneButton = not A.enableMountSelectNoneButton; end,
                    },
                    exec =
                    {
                        order = 1,
                        name = L["Select none"],
                        type = "execute",
                        disabled = function() return not A.enableMountSelectNoneButton; end,
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
                            A.usableMountsCache = nil;
                            A.enableMountSelectNoneButton = nil;
                        end,
                    },
                },
            },
        },
    };

    orderItem = 0;
    for k,v in ipairs(A.pamTable.mounts) do
        mounts.args.massActions.args.selectAllByCat.args[A.mountCat[k]] =
        {
            order = orderItem,
            name = L["Select all: %s"]:format(A.mountCat[k]),
            type = "execute",
            func = function()
                local count = 0;

                for kk,vv in pairs(A.pamTable.mounts[k]) do
                    for kkk,vvv in ipairs(vv) do
                        if ( not tContains(A.db.profile.favoriteMounts[k], vvv.spellID) ) then
                            A.db.profile.favoriteMounts[k][#A.db.profile.favoriteMounts[k]+1] = vvv.spellID;
                            count = count + 1;
                        end
                    end
                end

                if ( count > 1 ) then
                    A:Message(L["Added %d entries."]:format(count));
                else
                    A:Message(L["Added %d entry."]:format(count));
                end
            end,
        };

        mounts.args.massActions.args.selectNoneByCat.args[A.mountCat[k]] =
        {
            order = orderItem,
            name = L["Select none: %s"]:format(A.mountCat[k]),
            type = "execute",
            func = function()
                local count = 0;

                for kk,vv in pairs(A.pamTable.mounts[k]) do
                    for kkk,vvv in ipairs(vv) do
                        if ( A:TableRemove(A.db.profile.favoriteMounts[k], vvv.spellID) ) then
                            count = count + 1;
                        end
                    end
                end

                if ( count > 1 ) then
                    A:Message(L["Removed %d entries."]:format(count));
                else
                    A:Message(L["Removed %d entry."]:format(count));
                end
            end,
        };

        orderItem = orderItem + 1;
    end

    return mounts;
end

function A:OptionsSets()
    local sets =
    {
        order = 0,
        name = L["Sets options"],
        type = "group",
        childGroups = "tab",
        args =
        {
            pets =
            {
                order = 0,
                name = L["Companions"],
                type = "group",
                args =
                {
                    selectedFav =
                    {
                        order = 0,
                        name = function()
                            local count = #A.db.profile.favoritePets;

                            return L["You currently have %d selected favorites.\n\n"]:format(count);
                        end,
                        type = "description",
                        fontSize = "medium",
                    },
                    select =
                    {
                        order = 10,
                        name = L["Select"],
                        type = "multiselect",
                        values = function()
                            local out = {};

                            for k in pairs(A.db.global.savedSets.pets) do
                                out[k] = k;
                            end

                            return out;
                        end,
                        get = function(info, name)
                            if ( tContains(A.db.profile.enabledSets.pets, name) ) then
                                return 1;
                            end

                            return nil;
                        end,
                        set = function(info, name, val)
                            if ( val ) then
                                A.db.profile.enabledSets.pets[#A.db.profile.enabledSets.pets+1] = name;
                            else
                                A:TableRemove(A.db.profile.enabledSets.pets, name);
                            end

                            A:SetGlobalPetsSets();
                        end,
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
                                        A:PopMessageFrame("overwriteOrChangeNameSet", A.newPetSetName);
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
                                    A:PopMessageFrame("deleteSet", A.deleteSetPets);
                                end,
                            },
                        },
                    },
                },
            },
            mounts =
            {
                order = 1,
                name = L["Mounts"],
                type = "group",
                args =
                {
                    selectedFav =
                    {
                        order = 0,
                        name = function()
                            local count = 0;

                            for k,v in ipairs(A.db.profile.favoriteMounts) do
                                count = count + #v;
                            end

                            return L["You currently have %d selected favorites.\n\n"]:format(count);
                        end,
                        type = "description",
                        fontSize = "medium",
                    },
                    select =
                    {
                        order = 10,
                        name = L["Select"],
                        type = "multiselect",
                        values = function()
                            local out = {};

                            for k in pairs(A.db.global.savedSets.mounts) do
                                out[k] = k;
                            end

                            return out;
                        end,
                        get = function(info, name)
                            if ( tContains(A.db.profile.enabledSets.mounts, name) ) then
                                return 1;
                            end

                            return nil;
                        end,
                        set = function(info, name, val)
                            if ( val ) then
                                A.db.profile.enabledSets.mounts[#A.db.profile.enabledSets.mounts+1] = name;
                            else
                                A:TableRemove(A.db.profile.enabledSets.mounts, name);
                            end

                            A:SetGlobalMountsSets();
                        end,
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
                                        A:PopMessageFrame("overwriteOrChangeNameSet", A.newMountSetName);
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
                                    A:PopMessageFrame("deleteSet", A.deleteSetMounts);
                                end,
                            },
                        },
                    },
                },
            },
            areaPets =
            {
                order = 2,
                name = L["Area companions"],
                type = "group",
                args =
                {
                    enabled =
                    {
                        order = 0,
                        name = L["Enable"],
                        type = "toggle",
                        set = function() A.db.profile.petsZoneSets = not A.db.profile.petsZoneSets; end,
                        get = function() return A.db.profile.petsZoneSets; end,
                    },
                    zoneSelectGroup =
                    {
                        order = 100,
                        name = L["Area selection"],
                        type = "group",
                        inline = true,
                        disabled = function() return not A.db.profile.petsZoneSets; end,
                        args =
                        {
                            currentZone =
                            {
                                order = 0,
                                name = function()
                                    local mapID;

                                    if ( A.currentMapIDForPetsSets ) then
                                        mapID = A.currentMapIDForPetsSets;
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
                                order = 1,
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
                                get = function() return A.currentMapIDForPetsSets; end,
                                set = function(info, val) A.currentMapIDForPetsSets = val; end,
                            },
                        },
                    },
                    select =
                    {
                        order = 200,
                        name = L["Select"],
                        type = "multiselect",
                        disabled = function() return not A.db.profile.petsZoneSets; end,
                        values = function()
                            local out = {};

                            for k in pairs(A.db.global.savedSets.pets) do
                                out[k] = k;
                            end

                            return out;
                        end,
                        get = function(info, name)
                            local mapID;

                            if ( A.currentMapIDForPetsSets ) then
                                mapID = A.currentMapIDForPetsSets;
                            else
                                mapID = A.currentMapID;
                            end

                            if ( A.db.profile.petsSetsByMapID[mapID] and tContains(A.db.profile.petsSetsByMapID[mapID], name) ) then
                                return 1;
                            end

                            return nil;
                        end,
                        set = function(info, name, val)
                            local mapID;

                            if ( A.currentMapIDForPetsSets ) then
                                mapID = A.currentMapIDForPetsSets;
                            else
                                mapID = A.currentMapID;
                            end

                            if ( val ) then
                                if ( not A.db.profile.petsSetsByMapID[mapID] ) then
                                    A.db.profile.petsSetsByMapID[mapID] = {};
                                end

                                A.db.profile.petsSetsByMapID[mapID][#A.db.profile.petsSetsByMapID[mapID]+1] = name;
                            else
                                if ( A.db.profile.petsSetsByMapID[mapID] ) then
                                    A:TableRemove(A.db.profile.petsSetsByMapID[mapID], name);
                                end
                            end

                            if ( mapID == A.currentMapID ) then
                                A:SetZonePetsSets(1);
                            end
                        end,
                    },
                    zoneResetGroup =
                    {
                        order = 300,
                        name = L["Reset"],
                        type = "group",
                        inline = true,
                        disabled = function() return not A.db.profile.petsZoneSets; end,
                        args =
                        {
                            zoneReset =
                            {
                                order = 0,
                                name = L["Reset"],
                                desc = L["Use this to reset the working area to the current area."],
                                type = "execute",
                                func = function() A.currentMapIDForPetsSets = nil; end,
                            },
                        },
                    },
                    zoneInUse =
                    {
                        order = 400,
                        name = L["Areas in use"],
                        type = "group",
                        inline = true,
                        disabled = function() return not A.db.profile.petsZoneSets; end,
                        args =
                        {
                            desc =
                            {
                                order = 0,
                                name = L["List of the areas you are currently using:"],
                                width = "full",
                                type = "description",
                            },
                            list =
                            {
                                order = 1,
                                name = function()
                                    local list = "";

                                    for k in pairs(A.db.profile.petsSetsByMapID) do
                                        list = list..", "..GetMapNameByID(tonumber(k));
                                    end

                                    if ( list == "" ) then list = L["None"]; end

                                    return A:StringTrim(list, "%s,");
                                end,
                                width = "full",
                                type = "description",
                            }
                        },
                    },
                },
            },
            areaMounts =
            {
                order = 3,
                name = L["Area mounts"],
                type = "group",
                args =
                {
                    enabled =
                    {
                        order = 0,
                        name = L["Enable"],
                        type = "toggle",
                        set = function() A.db.profile.mountsZoneSets = not A.db.profile.mountsZoneSets; end,
                        get = function() return A.db.profile.mountsZoneSets; end,
                    },
                    zoneSelectGroup =
                    {
                        order = 100,
                        name = L["Area selection"],
                        type = "group",
                        inline = true,
                        disabled = function() return not A.db.profile.mountsZoneSets; end,
                        args =
                        {
                            currentZone =
                            {
                                order = 0,
                                name = function()
                                    local mapID;

                                    if ( A.currentMapIDForMountsSets ) then
                                        mapID = A.currentMapIDForMountsSets;
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
                                order = 1,
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
                                get = function() return A.currentMapIDForMountsSets; end,
                                set = function(info, val) A.currentMapIDForMountsSets = val; end,
                            },
                        },
                    },
                    select =
                    {
                        order = 200,
                        name = L["Select"],
                        type = "multiselect",
                        disabled = function() return not A.db.profile.mountsZoneSets; end,
                        values = function()
                            local out = {};

                            for k in pairs(A.db.global.savedSets.mounts) do
                                out[k] = k;
                            end

                            return out;
                        end,
                        get = function(info, name)
                            local mapID;

                            if ( A.currentMapIDForMountsSets ) then
                                mapID = A.currentMapIDForMountsSets;
                            else
                                mapID = A.currentMapID;
                            end

                            if ( A.db.profile.mountsSetsByMapID[mapID] and tContains(A.db.profile.mountsSetsByMapID[mapID], name) ) then
                                return 1;
                            end

                            return nil;
                        end,
                        set = function(info, name, val)
                            local mapID;

                            if ( A.currentMapIDForMountsSets ) then
                                mapID = A.currentMapIDForMountsSets;
                            else
                                mapID = A.currentMapID;
                            end

                            if ( val ) then
                                if ( not A.db.profile.mountsSetsByMapID[mapID] ) then
                                    A.db.profile.mountsSetsByMapID[mapID] = {};
                                end

                                A.db.profile.mountsSetsByMapID[mapID][#A.db.profile.mountsSetsByMapID[mapID]+1] = name;
                            else
                                if ( A.db.profile.mountsSetsByMapID[mapID] ) then
                                    A:TableRemove(A.db.profile.mountsSetsByMapID[mapID], name);
                                end
                            end

                            if ( mapID == A.currentMapID ) then
                                A:SetZoneMountsSets(1);
                            end
                        end,
                    },
                    zoneResetGroup =
                    {
                        order = 300,
                        name = L["Reset"],
                        type = "group",
                        inline = true,
                        disabled = function() return not A.db.profile.mountsZoneSets; end,
                        args =
                        {
                            zoneReset =
                            {
                                order = 0,
                                name = L["Reset"],
                                desc = L["Use this to reset the working area to the current area."],
                                type = "execute",
                                func = function() A.currentMapIDForMountsSets = nil; end,
                            },
                        },
                    },
                    zoneInUse =
                    {
                        order = 400,
                        name = L["Areas in use"],
                        type = "group",
                        inline = true,
                        disabled = function() return not A.db.profile.mountsZoneSets; end,
                        args =
                        {
                            desc =
                            {
                                order = 0,
                                name = L["List of the areas you are currently using:"],
                                width = "full",
                                type = "description",
                            },
                            list =
                            {
                                order = 1,
                                name = function()
                                    local list = "";

                                    for k in pairs(A.db.profile.mountsSetsByMapID) do
                                        list = list..", "..GetMapNameByID(tonumber(k));
                                    end

                                    if ( list == "" ) then list = L["None"]; end

                                    return A:StringTrim(list, "%s,");
                                end,

                                width = "full",
                                type = "description",
                            }
                        },
                    },
                },
            },
        },
    };

    return sets;
end

function A:OptionsFavOverride()
    local favOverride =
    {
        order = 0,
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
                        args = {},
                    },
                    mounts =
                    {
                        order = 10,
                        name = L["Mounts"],
                        type = "group",
                        inline = true,
                        args = {},
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
                            -- Pets dropdowns goes here
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
                                get = function() return A.currentMapIDForMounts; end,
                                set = function(info, val) A.currentMapIDForMounts = val; end,
                            },
                            zoneSelectMounts =
                            {
                                order = 100,
                                name = L["Mounts"],
                                type = "header",
                            },
                            -- Mounts dropdowns goes here
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
    };

    -- Force one pets
    orderItem = 0;
    for k,v in ipairs(A.pamTable.pets) do
        favOverride.args.forceOne.args.pets.args[A.petTypes[k]] =
        {
            order = orderItem,
            name = L[A.petTypes[k]],
            desc = L["Select the companion to force summon."],
            type = "select",
            dialogControl = "Dropdown-SortByValue",
            values = function()
                local out = { [0] = L["None"] };

                for kk,vv in A:PairsByKeys(v) do
                    for kkk,vvv in ipairs(vv) do
                        if ( A.db.profile.forceOne.pet == vvv.petID ) then
                            A.forcedPetType = k;
                        end

                        out[vvv.petID] = vvv.name;
                    end
                end

                return out;
            end,
            get = function() return A.db.profile.forceOne.pet or nil; end, 
            set = function(info, val)
                if ( val == 0 ) then
                    if ( A.forcedPetType == k ) then
                        A.db.profile.forceOne.pet = nil;
                    end
                else
                    A.db.profile.forceOne.pet = val;
                    A.forcedPetType = k;
                end
            end,
        };

        orderItem = orderItem + 1;
    end

    -- Force one mounts
    orderItem = 0;
    for k,v in ipairs(A.pamTable.mounts) do
        favOverride.args.forceOne.args.mounts.args[A.mountCat[k]] =
        {
            order = orderItem,
            name = A.mountCat[k],
            desc = L["Select the %s mount to force summon."]:format(A.mountCat[k]),
            type = "select",
            dialogControl = "Dropdown-SortByValue",
            values = function()
                local out = { [0] = L["None"] };

                for kk,vv in A:PairsByKeys(A.pamTable.mounts[k]) do
                    for kkk,vvv in ipairs(vv) do
                        out[vvv.spellID] = vvv.name;
                    end
                end

                return out;
            end,
            get = function() return A.db.profile.forceOne.mount[k] or nil; end,
            set = function(info, val)
                if ( val == 0 ) then
                    A.db.profile.forceOne.mount[k] = nil;
                else
                    A.db.profile.forceOne.mount[k] = val;
                end
            end,
        };

        orderItem = orderItem + 1;
    end

    -- Area override pets
    orderItem = 110;
    for k,v in ipairs(A.pamTable.pets) do
        favOverride.args.zoneOverride.args.pets.args[A.petTypes[k]] =
        {
            order = orderItem,
            name = L[A.petTypes[k]],
            desc = L["Select the companion to force summon."],
            type = "select",
            dialogControl = "Dropdown-SortByValue",
            values = function()
                local out = { [0] = L["None"] };
                local mapID;

                if ( A.currentMapIDForPets ) then
                    mapID = A.currentMapIDForPets;
                else
                    mapID = A.currentMapID;
                end

                for kk,vv in A:PairsByKeys(A.pamTable.pets[k]) do
                    for kkk,vvv in ipairs(vv) do
                        if ( A.db.profile.petByMapID[mapID] == vvv.petID ) then
                            A.zonePetType = k;
                        end

                        out[vvv.petID] = vvv.name;
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

                return A.db.profile.petByMapID[mapID] or nil;
            end,
            set = function(info, val)
                local mapID;

                if ( A.currentMapIDForPets ) then
                    mapID = A.currentMapIDForPets;
                else
                    mapID = A.currentMapID;
                end

                if ( val == 0 ) then
                    if ( A.zonePetType == k ) then
                        A.db.profile.petByMapID[mapID] = nil;
                    end
                else
                    A.db.profile.petByMapID[mapID] = val;
                    A.zonePetType = k;
                end
            end,
        };

        orderItem = orderItem + 1;
    end

     -- Area override mounts
    orderItem = 110;
    for k,v in ipairs(A.pamTable.mounts) do
        favOverride.args.zoneOverride.args.mounts.args[A.mountCat[k]] =
        {
            order = orderItem,
            name = A.mountCat[k],
            desc = L["Select the %s mount to force summon."]:format(A.mountCat[k]),
            type = "select",
            dialogControl = "Dropdown-SortByValue",
            values = function()
                local out = { [0] = L["None"] };

                for k,v in A:PairsByKeys(A.pamTable.mounts[k]) do
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

                return A.db.profile.mountByMapID[k][mapID] or nil;
            end,
            set = function(info, val)
                local mapID;

                if ( A.currentMapIDForMounts ) then
                    mapID = A.currentMapIDForMounts;
                else
                    mapID = A.currentMapID;
                end

                if ( val == 0 ) then
                    A.db.profile.mountByMapID[k][mapID] = nil;
                else
                    A.db.profile.mountByMapID[k][mapID] = val;
                end
            end,
        };

        orderItem = orderItem + 1;
    end

    return favOverride;
end

function A:OptionsAbout()
    local about =
    {
        order = 0,
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
                order = 110,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
            },
            curse =
            {
                order = 111,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
                image = function() return "Interface\\AddOns\\PetsAndMounts\\Media\\curse", 256, 106; end,
                imageCoords = {0, 1, 0, 0.82},
            },
            curseWebSite =
            {
                order = 112,
                name = "Curse",
                width = "full",
                type = "input",
                set = function() return; end,
                get = function() return "http://www.curse.com"; end,
            },
            emptyLine6 =
            {
                order = 120,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
            },
            warcraftMounts =
            {
                order = 121,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
                image = function() return "Interface\\AddOns\\PetsAndMounts\\Media\\warcraftmounts", 256, 105; end,
                imageCoords = {0, 1, 0, 0.82},
            },
            warcraftMountsWebSite =
            {
                order = 122,
                name = "Warcraft Mounts",
                width = "full",
                type = "input",
                set = function() return; end,
                get = function() return "http://www.warcraftmounts.com"; end,
            },
            emptyLine7 =
            {
                order = 130,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
            },
            warcraftPets =
            {
                order = 131,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
                image = function() return "Interface\\AddOns\\PetsAndMounts\\Media\\warcraftpets", 256, 256; end,
            },
            warcraftPetsWebSite =
            {
                order = 132,
                name = "Warcraft Pets",
                width = "full",
                type = "input",
                set = function() return; end,
                get = function() return "http://www.warcraftpets.com"; end,
            },
            emptyLine8 =
            {
                order = 140,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
            },
            wowAce =
            {
                order = 141,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
                image = function() return "Interface\\AddOns\\PetsAndMounts\\Media\\wowace", 256, 51; end,
                imageCoords = {0, 1, 0, 0.39},
            },
            wowAceWebSite =
            {
                order = 142,
                name = "WowAce",
                width = "full",
                type = "input",
                set = function() return; end,
                get = function() return "http://www.wowace.com"; end,
            },
            emptyLine9 =
            {
                order = 150,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
            },
            wowhead =
            {
                order = 151,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
                image = function() return "Interface\\AddOns\\PetsAndMounts\\Media\\wowhead", 256, 116; end,
                imageCoords = {0, 1, 0, 0.9},
            },
            wowheadWebSite =
            {
                order = 152,
                name = "Wowhead",
                width = "full",
                type = "input",
                set = function() return; end,
                get = function() return "http://www.wowhead.com"; end,
            },
            emptyLine10 =
            {
                order = 160,
                name = " ",
                width = "full",
                type = "description",
                fontSize = "medium",
            },
        },
    };

    return about;
end

-- Register with AceConfig
LibStub("AceConfig-3.0"):RegisterOptionsTable("PAMOptionsRoot", A.OptionsRoot);
--LibStub("AceConfig-3.0"):RegisterOptionsTable("PAMOptionsCustomMacros", A.OptionsCustomMacros);
LibStub("AceConfig-3.0"):RegisterOptionsTable("PAMOptionsPetsList", A.OptionsPetsList);
LibStub("AceConfig-3.0"):RegisterOptionsTable("PAMOptionsMountsList", A.OptionsMountsList);
LibStub("AceConfig-3.0"):RegisterOptionsTable("PAMOptionsSets", A.OptionsSets);
LibStub("AceConfig-3.0"):RegisterOptionsTable("PAMOptionsFavOverride", A.OptionsFavOverride);
LibStub("AceConfig-3.0"):RegisterOptionsTable("PAMOptionsAbout", A.OptionsAbout);

-- Adding add-on options to Blizzard UI
A.configFrameOptions = A.AceConfigDialog:AddToBlizOptions("PAMOptionsRoot",  L["Pets & Mounts"]);
--A.configFrameCustomMacros = A.AceConfigDialog:AddToBlizOptions("PAMOptionsCustomMacros", L["Custom macros"], L["Pets & Mounts"]);
A.configFramePets = A.AceConfigDialog:AddToBlizOptions("PAMOptionsPetsList", L["Companions list"], L["Pets & Mounts"]);
A.configFrameMounts = A.AceConfigDialog:AddToBlizOptions("PAMOptionsMountsList", L["Mounts list"], L["Pets & Mounts"]);
A.configFrameSets = A.AceConfigDialog:AddToBlizOptions("PAMOptionsSets", L["Sets options"], L["Pets & Mounts"]);
A.configFrameFavOverride = A.AceConfigDialog:AddToBlizOptions("PAMOptionsFavOverride", L["Favorites override"], L["Pets & Mounts"]);
A.configFrameAbout = A.AceConfigDialog:AddToBlizOptions("PAMOptionsAbout", L["About"], L["Pets & Mounts"]);

-- Config frames OnShow
A.configFrameOptions:HookScript("OnShow", function(self) A.configFocusFrame = self; end);
--A.configFrameCustomMacros:HookScript("OnShow", function(self) A.configFocusFrame = self; end);
A.configFramePets:HookScript("OnShow", function(self)
    A.configFocusFrame = self;

    A.searchFrame.searchBox.searchType = "PETS";
    A.searchFrame:ClearAllPoints();
    A.searchFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 0);
    A.searchFrame:Show();
end);
A.configFrameMounts:HookScript("OnShow", function(self)
    A.configFocusFrame = self;

    A.searchFrame.searchBox.searchType = "MOUNTS";
    A.searchFrame:ClearAllPoints();
    A.searchFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 0);
    A.searchFrame:Show();
end);
A.configFrameSets:HookScript("OnShow", function(self) A.configFocusFrame = self; end);
A.configFrameFavOverride:HookScript("OnShow", function(self) A.configFocusFrame = self; end);
A.configFrameAbout:HookScript("OnShow", function(self) A.configFocusFrame = self; end);

-- Config frames OnHide
A.configFrameOptions:HookScript("OnHide", function(self)
    A.iconFrame:Hide();
    A.inputFrame:Hide();
end);
--A.configFrameCustomMacros:HookScript("OnHide", function(self) A.iconFrame:Hide(); end);
A.configFramePets:HookScript("OnHide", function()
    A.configModelFrame:Hide();
    A.searchFrame:Hide();
end);
A.configFrameMounts:HookScript("OnHide", function()
    A.configModelFrame:Hide();
    A.searchFrame:Hide();
end);
A.configFrameFavOverride:HookScript("OnHide", function() A.configModelFrame:Hide(); end);

-- NotifyChange method
function A:NotifyChangeForAll()
    if ( A.configFrameOptions:IsVisible() ) then
        A.AceConfigRegistry:NotifyChange("PAMOptionsRoot", A.OptionsRoot);
    -- elseif ( A.configFrameCustomMacros:IsVisible() ) then
        -- A.AceConfigRegistry:NotifyChange("PAMOptionsCustomMacros", A.OptionsCustomMacros);
    elseif ( A.configFramePets:IsVisible() ) then
        A.AceConfigRegistry:NotifyChange("PAMOptionsPetsList", A.OptionsPetsList);
    elseif ( A.configFrameMounts:IsVisible() ) then
        A.AceConfigRegistry:NotifyChange("PAMOptionsMountsList", A.OptionsMountsList);
    elseif ( A.configFrameSets:IsVisible() ) then
        A.AceConfigRegistry:NotifyChange("PAMOptionsSets", A.OptionsSets);
    elseif ( A.configFrameFavOverride:IsVisible() ) then
        A.AceConfigRegistry:NotifyChange("PAMOptionsFavOverride", A.OptionsFavOverride);
    elseif ( A.configFrameAbout:IsVisible() ) then
        A.AceConfigRegistry:NotifyChange("PAMOptionsAbout", A.OptionsAbout);
    end
end
