--[[-------------------------------------------------------------------------------
    Pets & Mounts
    Auto and random summon highly customizable for your pets and mounts, with Data Broker support.
    By: Shenton

    Loader.lua
-------------------------------------------------------------------------------]]--

--GLOBALS: IsAddOnLoaded, LoadAddOn, DEFAULT_CHAT_FRAME

local A = CreateFrame("Frame");

A.errorMessage = "An error occurred while loading the add-on Blizzard_Collections which is required for Pets & Mounts to load. Manually opening your collections panel can fix that. For reporting purpose, this is the error returned by the UI: %s";

A:RegisterEvent("PLAYER_ENTERING_WORLD");

A:SetScript("OnEvent", function(self, event)
    if ( event == "PLAYER_ENTERING_WORLD" ) then
        if ( IsAddOnLoaded("Blizzard_Collections") ) then return; end

        local loaded, reason = LoadAddOn("Blizzard_Collections");

        if ( not loaded ) then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Pets & Mounts: |r"..(A.errorMessage):format(reason or "None"));
        end

        A:UnregisterEvent(event);
    end
end);
