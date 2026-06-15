-- Role Switcher -- per-level role configuration for WotLK 3.3.5a (SetClasslessRole API)

local f = CreateFrame("Frame", "RoleSwitcherFrame", UIParent)
local db  -- saved variables, assigned on ADDON_LOADED

local MIN_LEVEL, MAX_LEVEL = 8, 59  -- swap at L prepares L+1, so 60 prepares nothing

local ROLE_INFO = {
    TANK = { id = 2, label = "|cff00ccffTANK|r", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance", color = {0.00, 0.80, 1.00} },
    HEAL = { id = 4, label = "|cff44ff44HEAL|r", icon = "Interface\\Icons\\Spell_Nature_Rejuvenation",       color = {0.27, 1.00, 0.27} },
    DPS  = { id = 8, label = "|cffff3333DPS|r",  icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice",  color = {1.00, 0.20, 0.20} },
}
local ROLE_ORDER = { "TANK", "HEAL", "DPS" }

local UpdateStatus, UpdateUIAppearance, RefreshConfigPanel

-- Default per-level table: even current level -> DPS, odd -> legacy oddSpec (TANK/HEAL).
local function BuildDefaultLevels(oddSpec)
    local oddRole = (oddSpec == "HEALER" or oddSpec == "HEAL") and "HEAL" or "TANK"
    local t = {}
    for L = MIN_LEVEL, MAX_LEVEL do
        t[L] = ((L + 1) % 2 == 0) and "DPS" or oddRole
    end
    return t
end

local function BuildLetterButton(parent, letter)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropBorderColor(1, 0.82, 0, 1)
    btn:SetBackdropColor(0.08, 0.05, 0.02, 0.95)
    btn.text = btn:CreateFontString(nil, "OVERLAY")
    btn.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText(letter)
    btn.text:SetTextColor(1, 0.82, 0, 1)
    return btn
end

-- Hide the template's parchment textures so the checkbox reads on the dark panel.
local function StyleCheckbox(cb)
    if cb:GetNormalTexture() then cb:GetNormalTexture():Hide() end
    if cb:GetPushedTexture() then cb:GetPushedTexture():Hide() end
    cb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    cb:SetBackdropColor(0.22, 0.20, 0.16, 1)
end

-- Snap a frame back to default only if it is currently fully off-screen.
local function ResetIfOffScreen(frame, defaultX, defaultY)
    local left = frame:GetLeft()
    local sw, sh = GetScreenWidth(), GetScreenHeight()
    if not left or frame:GetRight() <= 0 or left >= sw or frame:GetTop() <= 0 or frame:GetBottom() >= sh then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", defaultX, defaultY)
    end
end

-- Main frame
f:SetSize(116, 50)
f:SetPoint("CENTER", UIParent, "CENTER", 0, -100)  -- default anchor; layout cache overrides after drag
f:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
f:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
f:SetBackdropBorderColor(0, 0, 0, 1)

f:EnableMouse(true)
f:SetMovable(true)
f:SetClampedToScreen(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function(self) if IsControlKeyDown() then self:StartMoving() end end)
f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

f.iconBtn = CreateFrame("Button", nil, f)
f.iconBtn:SetSize(32, 32)
f.iconBtn:SetPoint("LEFT", 7, 0)
f.icon = f.iconBtn:CreateTexture(nil, "OVERLAY")
f.icon:SetAllPoints()
f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
f.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
f.text:SetPoint("LEFT", f.icon, "RIGHT", 9, 0)
f.text:SetJustifyH("LEFT")

-- Pause button (P)
local pauseBtn = BuildLetterButton(f, "P")
pauseBtn:SetPoint("BOTTOMRIGHT", -3, 3)
pauseBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if db and db.isPaused then
        GameTooltip:SetText("|cffffd100Role Switcher|r\n|cffff2020Paused|r - Click to resume", nil, nil, nil, nil, true)
    else
        GameTooltip:SetText("|cffffd100Role Switcher|r\n|cff44ff44Active|r - Click to pause", nil, nil, nil, nil, true)
    end
    GameTooltip:Show()
end)
pauseBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

UpdateUIAppearance = function()
    if not db then return end
    if db.isPaused then
        pauseBtn:SetBackdropColor(0.35, 0.02, 0.02, 0.95)
        pauseBtn.text:SetTextColor(1, 0.25, 0.25, 1)
    else
        pauseBtn:SetBackdropColor(0.08, 0.05, 0.02, 0.95)
        pauseBtn.text:SetTextColor(1, 0.82, 0, 1)
    end
end

-- Config button (C)
local configBtn = BuildLetterButton(f, "C")
configBtn:SetPoint("BOTTOM", pauseBtn, "TOP", 0, 2)
configBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("|cffffd100Role Switcher|r\nClick to open per-level config", nil, nil, nil, nil, true)
    GameTooltip:Show()
end)
configBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Config panel
local panel = CreateFrame("Frame", "RoleSwitcherConfigFrame", UIParent)
panel:SetSize(290, 470)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
panel:SetFrameStrata("DIALOG")
panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
panel:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
panel:Hide()
panel:EnableMouse(true)
panel:SetMovable(true)
panel:SetClampedToScreen(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
panel.title:SetPoint("TOP", 0, -16)
panel.title:SetText("Role Switcher")
panel.title:SetTextColor(1, 0.82, 0, 1)

panel.subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
panel.subtitle:SetPoint("TOP", panel.title, "BOTTOM", 0, -2)
panel.subtitle:SetText("Role applied at each level")
panel.subtitle:SetTextColor(0.85, 0.72, 0.45, 1)

local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -4, -4)

local LABEL_WIDTH = 50
local CB_X = { 70, 126, 182 }  -- left-edge x for TANK / HEAL / DPS

local scrollFrame = CreateFrame("ScrollFrame", "RoleSwitcherConfigScrollFrame", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -94)
scrollFrame:SetPoint("BOTTOMRIGHT", -32, 50)

-- Assign role to every level matching parity (1 = odd, 0 = even).
local function SetAllOfParity(role, parity)
    if not db or not db.levels then return end
    for L = MIN_LEVEL, MAX_LEVEL do
        if (L % 2) == parity then db.levels[L] = role end
    end
    RefreshConfigPanel()
    UpdateStatus(f)
end

-- Header row: role name plus O / E quick-apply buttons per column.
local headerRow = CreateFrame("Frame", nil, panel)
headerRow:SetSize(220, 40)
headerRow:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 4, 2)

for j, role in ipairs(ROLE_ORDER) do
    local h = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOP", headerRow, "TOPLEFT", CB_X[j] + 9, -2)
    h:SetText(role)
    local c = ROLE_INFO[role].color
    h:SetTextColor(c[1], c[2], c[3], 1)

    local oddBtn = BuildLetterButton(headerRow, "O")
    oddBtn:SetPoint("BOTTOM", headerRow, "BOTTOMLEFT", CB_X[j] + 9 - 11, 2)
    oddBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cffffd100Set all |r|cff888888Odd|r|cffffd100 levels to|r " .. ROLE_INFO[role].label, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    oddBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    oddBtn:SetScript("OnClick", function() SetAllOfParity(role, 1) end)

    local evenBtn = BuildLetterButton(headerRow, "E")
    evenBtn:SetPoint("BOTTOM", headerRow, "BOTTOMLEFT", CB_X[j] + 9 + 11, 2)
    evenBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cffffd100Set all |r|cff888888Even|r|cffffd100 levels to|r " .. ROLE_INFO[role].label, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    evenBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    evenBtn:SetScript("OnClick", function() SetAllOfParity(role, 0) end)
end

local rowHeight = 22
local rowCount = MAX_LEVEL - MIN_LEVEL + 1
local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(220, rowCount * rowHeight)
scrollFrame:SetScrollChild(content)

local checkboxes = {}  -- checkboxes[level][role]

for i = 1, rowCount do
    local level = MIN_LEVEL + i - 1
    checkboxes[level] = {}

    local row = CreateFrame("Frame", nil, content)
    row:SetSize(220, rowHeight)
    row:SetPoint("TOPLEFT", 4, -(i - 1) * rowHeight)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetText("Lvl " .. level)
    label:SetTextColor(1, 0.82, 0, 1)

    for j, role in ipairs(ROLE_ORDER) do
        local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("LEFT", CB_X[j], 0)
        StyleCheckbox(cb)
        cb._role = role
        cb._level = level
        cb:SetScript("OnClick", function(self)
            if not db then return end
            self:SetChecked(true)  -- exactly one role per level; can't uncheck without picking another
            db.levels[self._level] = self._role
            for r, sib in pairs(checkboxes[self._level]) do
                if r ~= self._role then sib:SetChecked(false) end
            end
            UpdateStatus(f)
        end)
        checkboxes[level][role] = cb
    end
end

RefreshConfigPanel = function()
    if not db or not db.levels then return end
    for L = MIN_LEVEL, MAX_LEVEL do
        local role = db.levels[L]
        if checkboxes[L] then
            for r, cb in pairs(checkboxes[L]) do
                cb:SetChecked(r == role)
            end
        end
    end
end

local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetSize(140, 22)
resetBtn:SetPoint("BOTTOM", 0, 16)
resetBtn:SetText("Reset to default")
resetBtn:SetScript("OnClick", function()
    if not db then return end
    db.levels = BuildDefaultLevels("TANK")
    RefreshConfigPanel()
    UpdateStatus(f)
end)

configBtn:SetScript("OnClick", function()
    if panel:IsShown() then
        panel:Hide()
    else
        ResetIfOffScreen(panel, 0, 0)
        RefreshConfigPanel()
        panel:Show()
    end
end)

-- Main update / event handler
UpdateStatus = function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "RoleSwitcher" then
        if _G.RoleSwitcher == nil then _G.RoleSwitcher = { isPaused = false } end
        db = _G.RoleSwitcher
        if db.levels == nil then db.levels = BuildDefaultLevels(db.oddSpec) end  -- migrate legacy oddSpec
        db.oddSpec = nil
        db.levels[60] = nil  -- level 60 not configurable
        UpdateUIAppearance()
        RefreshConfigPanel()
    end

    if not db then return end

    local currentLevel = (event == "PLAYER_LEVEL_UP") and arg1 or UnitLevel("player")

    if currentLevel >= 60 then
        f:Hide()
        return
    end
    f:Show()

    if currentLevel < MIN_LEVEL then
        f.icon:SetTexture(nil)
        f.text:SetText("LVL: " .. currentLevel .. "\n|cff888888Pending|r")
        return
    end

    local roleName = (db.levels and db.levels[currentLevel]) or "TANK"
    local info = ROLE_INFO[roleName] or ROLE_INFO.TANK

    if _G.SetClasslessRole and not db.isPaused and event ~= "ADDON_LOADED" then
        _G.SetClasslessRole(info.id)
    end

    f.icon:SetTexture(info.icon)
    local statusPrefix = db.isPaused and "|cffff3333[P]|r " or ""
    f.text:SetText(statusPrefix .. "LVL: " .. currentLevel .. "\n" .. info.label)
end

pauseBtn:SetScript("OnClick", function()
    if not db then return end
    db.isPaused = not db.isPaused
    UpdateUIAppearance()
    UpdateStatus(f)
end)

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:SetScript("OnEvent", UpdateStatus)

-- One-shot after load: layout cache restores positions after Lua runs, so wait a
-- tick then snap either frame back if it ended up off-screen.
local positionResetTicker = CreateFrame("Frame")
positionResetTicker:SetScript("OnUpdate", function(self)
    ResetIfOffScreen(f, 0, -100)
    ResetIfOffScreen(panel, 0, 0)
    self:SetScript("OnUpdate", nil)
end)
