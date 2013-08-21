--[[-------------------------------------------------------------------------------
    Broker Pets & Mounts
    Data Broker display for easy acces to pets and mounts.
    By: Shenton

    Zones.lua
-------------------------------------------------------------------------------]]--

local A = _G["BrokerPAMGlobal"];
local L = A.L;

-- Gathered on http://wowpedia.org/MapID
A.zonesIDs = {13, 772, 894, 43, 181, 464, 476, 890, 42, 381, 101, 4, 141, 891, 182, 121, 795, 241, 606, 9, 11, 321, 888, 261, 607, 81, 161, 41, 471, 61, 362, 720, 201, 889, 281, 14, 614, 16, 17, 19, 29, 866, 32,
892, 27, 34, 23, 30, 462, 463, 545, 611, 24, 341, 499, 610, 35, 895, 37, 864, 36, 684, 685, 28, 615, 480, 21, 301, 689, 893, 38, 673, 26, 502, 20, 708, 709, 700, 382, 613, 22, 39, 40, 466, 475, 465, 477, 479,
473, 481, 478, 467, 485, 486, 510, 504, 488, 490, 491, 541, 492, 493, 495, 501, 496, 751, 640, 605, 544, 737, 862, 858, 929, 928, 857, 809, 905, 903, 806, 873, 808, 810, 811, 807, 401, 461, 935, 482, 540, 860,
512, 856, 736, 626, 443, 878, 912, 899, 883, 940, 939, 884, 900, 914, 937, 920, 880, 911, 938, 906, 851, 882, 688, 704, 721, 699, 691, 750, 680, 760, 761, 764, 765, 756, 690, 687, 692, 749, 686, 755, 696, 717,
766, 722, 797, 798, 732, 734, 723, 724, 731, 733, 725, 729, 730, 710, 728, 727, 726, 796, 776, 775, 799, 779, 780, 789, 782, 522, 533, 534, 530, 525, 603, 526, 602, 521, 601, 520, 528, 536, 542, 523, 524, 604,
535, 718, 527, 531, 609, 543, 529, 532, 753, 820, 757, 759, 819, 747, 768, 769, 767, 816, 781, 793, 752, 754, 824, 800, 758, 773, 875, 885, 871, 874, 898, 877, 887, 876, 867, 897, 896, 886, 930};

-- Thanks to those damn scenarios with the same map name
-- Maelstrom got two IDs 751 & 737, just ignore them, I think those two maps are when you arrive to Deepholme and the "dream" when Thrall says you failed
A.zonesIDsOverride =
{
    [751] = "JUSTIGNOREME",
    [737] = "JUSTIGNOREME",
    [939] = L["Blood in the Snow"],
    [937] = L["Dark Heart of Pandaria"],
    [920] = L["Domination Point (H)"],
    [880] = L["Greenstone Village"],
    [911] = L["Lion's Landing (A)"],
    [906] = L["Theramore's Fall (A)"],
    [851] = L["Theramore's Fall (H)"],
};

-- Build the mapIDs DB
function A:BuildMapIDsDB()
    --A.db.global.zonesIDsToName = {};

    for k,v in pairs(A.zonesIDs) do
        if ( A.zonesIDsOverride[v] ) then
            if ( A.zonesIDsOverride[v] == "JUSTIGNOREME" ) then
                A.db.global.zonesIDsToName[tostring(v)] = nil;
            else
                A.db.global.zonesIDsToName[tostring(v)] = A.zonesIDsOverride[v];
            end
        else
            local name = GetMapNameByID(v);

            if ( name ) then
                if ( A.db.profile.debug ) then
                    if ( A:TableValueToKey(A.db.global.zonesIDsToName, name) ) then
                        A:DebugMessage(("BuildMapIDsDB() - %d %s already stored - with ID %s"):format(v, name, A:TableValueToKey(A.db.global.zonesIDsToName, name)));
                    end
                end

                A.db.global.zonesIDsToName[tostring(v)] = name;
            else
                A.db.global.zonesIDsToName[tostring(v)] = nil;
            end
        end
    end
end

-- Hook a script on hide of the worldframe
-- used to update the current mapID without
-- switching it while the player got his map open
WorldMapFrame:HookScript("OnHide", function()
    if ( A.getCurrentMapIDDelayed ) then
        A:GetCurrentMapID();
        A.getCurrentMapIDDelayed = nil;
    end
end);

-- Get the current mapID
-- Postponed it if the map is open
function A:GetCurrentMapID()
    if ( WorldMapFrame:IsVisible() ) then
        A.getCurrentMapIDDelayed = 1;
        return;
    end

    SetMapToCurrentZone();

    local mapID = GetCurrentMapAreaID();

    if ( not mapID ) then return; end

    A.currentMapID = mapID;

    if ( not A.db.global.zonesIDsToName[tostring(mapID)] and GetMapNameByID(mapID) ) then
        A.db.global.zonesIDsToName[tostring(mapID)] = GetMapNameByID(mapID);
        A:DebugMessage(("GetCurrentMapID() - Added %d - %s"):format(mapID, GetMapNameByID(mapID) or "Unavailable"));
    end
end
