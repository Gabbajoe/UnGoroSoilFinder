local ADDON_NAME = ...

local HBDPins = LibStub("HereBeDragons-Pins-2.0")

local SOIL_ITEM_ID = 11018
local UNGORO_CRATER_MAP_ID = 1449
local ICON_TEXTURE_FALLBACK = "Interface\\Icons\\INV_Misc_Dirt_01"
local PREFIX = "|cff33ff99Un'Goro Soil Finder|r"

-- use the real in-game icon for Un'Goro Soil itself so the pins look like the
-- actual item rather than a generic placeholder
local function GetSoilIcon()
    local icon = GetItemIcon and GetItemIcon(SOIL_ITEM_ID)
    return icon or ICON_TEXTURE_FALLBACK
end

-- squared-distance dedupe radius in normalized map coords (~roughly the size of one node)
local DEDUPE_RADIUS_SQ = 0.0003

-- bump this if UnGoroSoilFinderSeedData ever gets more/better entries and should be re-merged
local SEED_DATA_VERSION = 1

local QSF = CreateFrame("Frame")
local worldPins, minimapPins = {}, {}

local function Print(msg)
    print(PREFIX .. ": " .. msg)
end

-- adds {x,y} into nodes[mapID], merging with anything already within DEDUPE_RADIUS_SQ
local function AddNode(mapID, x, y)
    UnGoroSoilFinderDB.nodes[mapID] = UnGoroSoilFinderDB.nodes[mapID] or {}
    local nodes = UnGoroSoilFinderDB.nodes[mapID]

    for _, node in ipairs(nodes) do
        local dx, dy = node.x - x, node.y - y
        if (dx * dx + dy * dy) < DEDUPE_RADIUS_SQ then
            return false
        end
    end

    table.insert(nodes, { x = x, y = y })
    return true
end

local function EnsureDB()
    UnGoroSoilFinderDB = UnGoroSoilFinderDB or {}
    UnGoroSoilFinderDB.nodes = UnGoroSoilFinderDB.nodes or {}
    if UnGoroSoilFinderDB.enabled == nil then
        UnGoroSoilFinderDB.enabled = true
    end

    if (UnGoroSoilFinderDB.seedVersion or 0) < SEED_DATA_VERSION and UnGoroSoilFinderSeedData then
        local added = 0
        for mapID, nodes in pairs(UnGoroSoilFinderSeedData) do
            for _, node in ipairs(nodes) do
                if AddNode(mapID, node.x, node.y) then
                    added = added + 1
                end
            end
        end
        UnGoroSoilFinderDB.seedVersion = SEED_DATA_VERSION
        if added > 0 then
            Print(("loaded %d known Un'Goro Soil locations from bundled data."):format(added))
        end
    end
end

local PIN_ALPHA = 0.65

local function CreatePinFrame(size)
    local pin = CreateFrame("Frame", nil, UIParent)
    pin:SetSize(size, size)
    pin:SetAlpha(PIN_ALPHA)

    -- thin dark outline just behind the icon edges - enough contrast against the
    -- brown/tan Un'Goro Crater map texture without turning into a solid block
    local outline = pin:CreateTexture(nil, "BORDER")
    outline:SetPoint("CENTER")
    outline:SetSize(size * 1.18, size * 1.18)
    outline:SetColorTexture(0, 0, 0, 0.6)

    -- the actual Un'Goro Soil item icon, so the pin reads as "a dirt pile" like
    -- the rest of WoW Classic's map icons rather than an abstract marker
    local tex = pin:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("CENTER")
    tex:SetSize(size, size)
    tex:SetTexture(GetSoilIcon())
    pin.texture = tex

    pin:EnableMouse(true)
    pin:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Un'Goro Soil")
        GameTooltip:AddLine("Recorded by Un'Goro Soil Finder", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function(self)
        self:SetAlpha(PIN_ALPHA)
        GameTooltip:Hide()
    end)

    return pin
end

local mapToggleButton

local function UpdateMapToggleButton()
    if not mapToggleButton then return end

    if WorldMapFrame:GetMapID() == UNGORO_CRATER_MAP_ID then
        mapToggleButton:SetChecked(UnGoroSoilFinderDB.enabled)
        mapToggleButton:Show()
    else
        mapToggleButton:Hide()
    end
end

-- adds a checkbox to the world map, only visible while the Un'Goro Crater zone
-- map itself is open, to toggle the soil pins without needing the slash command
local function CreateMapToggleButton()
    if mapToggleButton or not WorldMapFrame then return end

    mapToggleButton = CreateFrame("CheckButton", "UnGoroSoilFinderToggle", WorldMapFrame, "UICheckButtonTemplate")
    mapToggleButton:SetSize(22, 22)
    mapToggleButton:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -50, -62)
    -- force this above the map canvas (ScrollContainer), which otherwise sits in a
    -- higher strata and both visually covers and eats clicks meant for our checkbox
    mapToggleButton:SetFrameStrata("DIALOG")
    mapToggleButton:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 50)
    mapToggleButton:Hide()

    local label = mapToggleButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("RIGHT", mapToggleButton, "LEFT", -2, 1)
    label:SetText("Soil")

    mapToggleButton:SetScript("OnClick", function(self)
        UnGoroSoilFinderDB.enabled = self:GetChecked() and true or false
        QSF:RefreshPins()
    end)
    mapToggleButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Un'Goro Soil Finder")
        GameTooltip:AddLine("Toggle Un'Goro Soil pile pins", 1, 1, 1)
        GameTooltip:Show()
    end)
    mapToggleButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    hooksecurefunc(WorldMapFrame, "SetMapID", UpdateMapToggleButton)
    WorldMapFrame:HookScript("OnShow", UpdateMapToggleButton)
    UpdateMapToggleButton()
end

function QSF:RefreshPins()
    HBDPins:RemoveAllWorldMapIcons(ADDON_NAME)
    HBDPins:RemoveAllMinimapIcons(ADDON_NAME)
    wipe(worldPins)
    wipe(minimapPins)

    UpdateMapToggleButton()

    if not UnGoroSoilFinderDB.enabled then
        return
    end

    for mapID, nodes in pairs(UnGoroSoilFinderDB.nodes) do
        for _, node in ipairs(nodes) do
            local worldPin = CreatePinFrame(10)
            -- SHOW_PARENT: only render while the Un'Goro Crater zone map itself is open,
            -- not when zoomed out to the continent/world map (avoids hundreds of pins
            -- piling up into one solid blob that blocks clicks on the continent view)
            HBDPins:AddWorldMapIconMap(ADDON_NAME, worldPin, mapID, node.x, node.y, HBD_PINS_WORLDMAP_SHOW_PARENT)
            table.insert(worldPins, worldPin)

            local minimapPin = CreatePinFrame(8)
            HBDPins:AddMinimapIconMap(ADDON_NAME, minimapPin, mapID, node.x, node.y, false)
            table.insert(minimapPins, minimapPin)
        end
    end
end

function QSF:RecordNode()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end

    local x, y = pos:GetXY()
    if not x or not y then return end

    if AddNode(mapID, x, y) then
        Print(("new Un'Goro Soil spot recorded (%d known)."):format(#UnGoroSoilFinderDB.nodes[mapID]))
        QSF:RefreshPins()
    end
end

local function OnChatMsgLoot(message)
    if not message then return end
    local itemID = tonumber(message:match("item:(%d+)"))
    if itemID == SOIL_ITEM_ID then
        QSF:RecordNode()
    end
end

QSF:RegisterEvent("ADDON_LOADED")
QSF:RegisterEvent("PLAYER_ENTERING_WORLD")
QSF:RegisterEvent("CHAT_MSG_LOOT")
QSF:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            EnsureDB()
            QSF:RefreshPins()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CreateMapToggleButton()
        QSF:RefreshPins()
    elseif event == "CHAT_MSG_LOOT" then
        OnChatMsgLoot(arg1)
    end
end)

SLASH_UNGOROSOILFINDER1 = "/soilfinder"
SLASH_UNGOROSOILFINDER2 = "/soil"
SlashCmdList["UNGOROSOILFINDER"] = function(msg)
    msg = (msg or ""):trim():lower()

    if msg == "reset" then
        wipe(UnGoroSoilFinderDB.nodes)
        QSF:RefreshPins()
        Print("all recorded locations cleared.")
    elseif msg == "toggle" or msg == "hide" or msg == "show" then
        if msg == "toggle" then
            UnGoroSoilFinderDB.enabled = not UnGoroSoilFinderDB.enabled
        else
            UnGoroSoilFinderDB.enabled = (msg == "show")
        end
        QSF:RefreshPins()
        Print("pins " .. (UnGoroSoilFinderDB.enabled and "shown" or "hidden") .. ".")
    else
        local count = 0
        for _, nodes in pairs(UnGoroSoilFinderDB.nodes) do
            count = count + #nodes
        end
        Print(count .. " Un'Goro Soil location(s) known (includes bundled data + anything you've looted yourself).")
        Print("Any new pile you loot is learned automatically and shown even without the quest active.")
        print(PREFIX .. ": commands: /soil reset, /soil show, /soil hide")
    end
end
