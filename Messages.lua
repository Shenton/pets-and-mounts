--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Messages.lua
-------------------------------------------------------------------------------]]--

local A = _G["PetsAndMountsGlobal"];
local L = A.L;

-- Globals to locals
local type = type;
local table = table;
local strtrim = strtrim;
local unpack = unpack;

-- GLOBALS: PlaySound, DEFAULT_CHAT_FRAME, InCombatLockdown, GetCurrentKeyBoardFocus

--[[-------------------------------------------------------------------------------
    Variables
-------------------------------------------------------------------------------]]--

-- Popup messages, messages container
A.popupMessages = {};

-- Popup stack
A.popupStack = {};

--[[-------------------------------------------------------------------------------
    Text messages methods
-------------------------------------------------------------------------------]]--

--- Send a message to the chat frame with the addon name colored
-- @param text The message to display
-- @param color Bool, if true will color in red
function A:Message(text, color, silent)
    if ( color == "debug" ) then
        color = A.color["BLUE"];
    elseif ( color ) then
        color = A.color["RED"];
    else
        color = A.color["GREEN"];
    end

    if ( not silent ) then
        PlaySound("TellMessage");
    end

    DEFAULT_CHAT_FRAME:AddMessage(color..L["Pets & Mounts"]..": "..A.color["RESET"]..text);
end

--- Debug message methods
function A:DebugMessageDummy()
end
function A:DebugMessageActiv(text)
    A:Message(text, "debug", 1);
end
A.DebugMessage = A.DebugMessageDummy;

--[[-------------------------------------------------------------------------------
    Popup methods
-------------------------------------------------------------------------------]]--

function A:PopMessageFrame(message, strings, args)
    if ( type(message) == "table" ) then
        A.popupMessageFrame.cfg = message;
        A.popupMessageFrame:Show();
    elseif ( A.popupMessages[message] ) then
        local cfg = A:CopyTable(A.popupMessages[message]);

        if ( not cfg.name ) then
            cfg.name = message;
        end

        if ( not cfg.headerText ) then
            cfg.headerText = L["Pets & Mounts"];
        end

        if ( strings ) then
            if ( type(strings) == "table" ) then
                cfg.text = cfg.text:format(unpack(strings));
            else
                cfg.text = cfg.text:format(strings);
            end
        end

        if ( args ) then
            cfg.args = args;
        end

        if ( cfg.enterOK and not cfg.LeftButtonScript ) then
            cfg.LeftButtonScript = function(self) self:Hide(); end
        end

        if ( A.popupMessageFrame:IsVisible() ) then
            if ( A.popupMessageFrame.cfg.name ~= message ) then
                table.insert(A.popupStack, 1, cfg);
            end
        elseif ( InCombatLockdown() ) then
            if ( not A.popMessageCombat ) then
                A.popMessageCombat = cfg;
            end
        else
            A.popupMessageFrame.cfg = cfg;
            A.popupMessageFrame:Show();
        end
    end
end

function A:PopMessageFrameOnHide()
    if ( InCombatLockdown() ) then return; end

    if ( #A.popupStack > 0 ) then
        local cfg = table.remove(A.popupStack);

        A:PopMessageFrame(cfg);
    end
end

function A:PopMessageEnteringCombat()
    if ( A.popupMessageFrame:IsVisible() ) then
        A.popMessageCombat = A.popupMessageFrame.cfg;
        A.popupMessageFrame:Hide();
    end
end

function A:PopMessageLeavingCombat()
    if ( A.popMessageCombat ) then
        A:PopMessageFrame(A.popMessageCombat);
        A.popMessageCombat = nil;
    end
end

--[[-------------------------------------------------------------------------------
    Popup messages
-------------------------------------------------------------------------------]]--

-- New binding system message v1.5.0
A.popupMessages["newBindingsSystemv150"] =
{
    type = "question",
    text = L["The bindings system have been entirely redone.\n\nThe add-on tried to update them, but just in case you should check if everything is in place.\n\nDo you want to open the configuration panel?"],
    icon = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew",
    leftButtonText = L["Yes"],
    rightButtonText = L["No"],
    escapeClose = 1,
    enterOK = 1,
    LeftButtonScript = function(self)
        A:OpenConfigPanel();
        self:Hide();
    end,
};

-- Grief/scam protection message
A.popupMessages["griefScamProtectionMessageMacro"] =
{
    type = "message",
    text = L["|cffff3333Anti grief/scam protection triggered, you should be careful.|r\n\nMessage: |cffff3333%s|r was found in your %s %s custom macro.\n\n|cff33ff99This macro was not used.|r\n\nYou can disable the protection within the configuration panel."],
    icon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
    leftButtonText = L["Ok"],
    escapeClose = 1,
    enterOK = 1,
    LeftButtonScript = function(self)
        self:Hide();
    end,
};

-- Grief/scam protection message
A.popupMessages["griefScamProtectionMessageLUA"] =
{
    type = "message",
    text = L["|cffff3333Anti grief/scam protection triggered, you should be careful.|r\n\nMessage: |cffff3333%s|r was found in your %s %s custom LUA.\n\n|cff33ff99This code was not used.|r\n\nYou can disable the protection within the configuration panel."],
    icon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
    leftButtonText = L["Ok"],
    escapeClose = 1,
    enterOK = 1,
    LeftButtonScript = function(self)
        self:Hide();
    end,
};

-- New filters for companions in 1.6.1 (rarity & level)
A.popupMessages["newCompanionsFilters161"] =
{
    type = "message",
    text = L["New filters added for companions, rarity and level.\n\nThey are enabled by default and could have modified your companions list both in configuration panel and Data Broker menu.\n\nIt did not alter you sets or favorites, but you could want to modify them to use your highest level and rarity companions.\n\nTips: You can disable the \"Filter multiple\" option to see all your companions. Rarity and level are displayed next to their names in the list."],
    icon = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew",
    leftButtonText = L["Ok"],
    escapeClose = 1,
    enterOK = 1,
    LeftButtonScript = function(self)
        self:Hide();
    end,
};

-- 6.0 modifications message v1.7.0
A.popupMessages["wodModifications170"] =
{
    type = "question",
    text = L["WoD (6.02) modified a lot both companions and mounts APIs.\n\nCheck the add-on page on Curse for some explanations on those changes. The link can be found in the About section of the configuration panel.\n\nDo you want to open the configuration panel?"],
    icon = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew",
    leftButtonText = L["Yes"],
    rightButtonText = L["No"],
    escapeClose = 1,
    enterOK = 1,
    LeftButtonScript = function(self)
        A:OpenConfigPanel();
        self:Hide();
    end,
};

-- Draenor isflying always true bug
-- A.popupMessages["wodDraenorIsflyingbug603"] =
-- {
    -- type = "message",
    -- text = L["There is a bug within Draenor areas. The API always return true when asked if you are in a flyable area. As a temporary fix the add-on will check if you are in Draenor and always return false when checking if the zone is flyable.\n\nThe problem is every time you will want to summon a mount it will set your world map to the current one. This is not a big issue but this is something I hate to do as it is a total disrespect to the player. And yes when your world map is automatically set to the current one it is due to an add-on, the default interface do not do that.\n\nIf this is an issue for you just tell me and I will improve that temporary fix."],
    -- icon = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew",
    -- leftButtonText = L["Ok"],
    -- escapeClose = 1,
    -- enterOK = 1,
    -- LeftButtonScript = function(self)
        -- self:Hide();
    -- end,
-- };
