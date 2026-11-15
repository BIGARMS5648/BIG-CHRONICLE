-- BIG CHRONICLE :: 메인 창 (두루마리 전기)

local ADDON, ns = ...
local UI = ns.UI

UI.TABS = {
	{ id = "journal",      name = "모험 일지",   key = "1" },
	{ id = "bestiary",     name = "몬스터 도감", key = "2" },
	{ id = "achievements", name = "업적",        key = "3" },
	{ id = "stats",        name = "연대기 통계", key = "4" },
	{ id = "settings",     name = "설정",        key = "5" },
}

local WIDTH, HEIGHT = 940, 640

function UI:TabModule(id)
	if id == "journal" then return ns.JournalTab end
	if id == "bestiary" then return ns.BestiaryTab end
	if id == "achievements" then return ns.AchievementsTab end
	if id == "stats" then return ns.StatsTab end
	if id == "settings" then return ns.SettingsTab end
end

local function CloseButton(parent, onClick)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(26, 26)
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.header)
	fs:SetPoint("CENTER", 0, 0)
	fs:SetText("X")
	fs:SetTextColor(C.sub[1], C.sub[2], C.sub[3])
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	UI.Color(hl, C.hover)
	b:SetScript("OnEnter", function() fs:SetTextColor(C.title[1], C.title[2], C.title[3]) end)
	b:SetScript("OnLeave", function() fs:SetTextColor(C.sub[1], C.sub[2], C.sub[3]) end)
	b:SetScript("OnClick", onClick)
	return b
end
UI.CloseButton = CloseButton

function UI:Build()
	if self.frame then return self.frame end
	self:InitTheme()
	local C = self.COL
	local f = CreateFrame("Frame", "BigChronicleFrame", UIParent)
	f:SetSize(WIDTH, HEIGHT)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint()
		ns.db.window = { point = point, relPoint = relPoint, x = x, y = y }
	end)
	local w = ns.db and ns.db.window
	if w and w.point then
		f:SetPoint(w.point, UIParent, w.relPoint or w.point, w.x or 0, w.y or 0)
	else
		f:SetPoint("CENTER", 0, 10)
	end
	f:Hide()
	if UISpecialFrames then table.insert(UISpecialFrames, "BigChronicleFrame") end

	UI.Paper(f)
	UI.Roller(f, "TOP", 18)
	UI.Roller(f, "BOTTOM", 18)

	-- 머리말 (대화창의 NPC 이름처럼 가운데 정렬)
	local brand = f:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	brand:SetPoint("TOP", 0, -20)
	brand:SetText("B I G   C H R O N I C L E")
	brand:SetTextColor(C.accent[1], C.accent[2], C.accent[3])

	local title = f:CreateFontString(nil, "OVERLAY", UI.F.title)
	title:SetPoint("TOP", brand, "BOTTOM", 0, -6)
	f.title = title

	local sub = f:CreateFontString(nil, "OVERLAY", UI.F.small)
	sub:SetPoint("TOP", title, "BOTTOM", 0, -6)
	f.subtitle = sub

	local divider = UI.Divider(f, 560)
	divider:SetPoint("TOP", sub, "BOTTOM", 0, -8)

	local close = CloseButton(f, function() f:Hide() end)
	close:SetPoint("TOPRIGHT", -12, -12)

	-- 탭 (가운데 정렬)
	local tabRow = CreateFrame("Frame", nil, f)
	tabRow:SetHeight(28)
	tabRow:SetPoint("TOP", divider, "BOTTOM", 0, -8)
	self.tabButtons = {}
	local total, prev = 0, nil
	for _, tab in ipairs(UI.TABS) do
		local b = UI.Tab(tabRow, tab.name, tab.key, function() UI:SelectTab(tab.id) end)
		if prev then b:SetPoint("LEFT", prev, "RIGHT", 26, 0) else b:SetPoint("LEFT", 0, 0) end
		total = total + b:GetWidth() + (prev and 26 or 0)
		self.tabButtons[tab.id] = b
		prev = b
	end
	tabRow:SetWidth(total)

	local rule = UI.Rule(f, 0.35)
	rule:SetPoint("TOPLEFT", 24, -146)
	rule:SetPoint("TOPRIGHT", -24, -146)

	local content = CreateFrame("Frame", nil, f)
	content:SetPoint("TOPLEFT", 24, -154)
	content:SetPoint("BOTTOMRIGHT", -24, 38)
	self.content = content
	self.panels = {}

	-- 아래쪽 단축키 안내
	local hints = f:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	hints:SetPoint("BOTTOM", 0, 16)
	f.hints = hints

	f:SetScript("OnShow", function(self)
		UI.FadeIn(self, 0.22)
		UI:RefreshHeader()
		UI:RefreshCurrent()
		UI:UpdateKeyboard()
	end)
	f:SetScript("OnHide", function()
		UI.FinishTyping()
	end)
	f:SetScript("OnKeyDown", function(self, key)
		if InCombatLockdown and InCombatLockdown() then return end
		local handled = UI:HandleKey(key)
		pcall(self.SetPropagateKeyboardInput, self, not handled)
	end)
	self.frame = f

	ns:Listen("LOG_ADDED", function() UI:QueueRefresh("log") end)
	ns:Listen("DEX_UPDATED", function() UI:QueueRefresh("dex") end)
	ns:Listen("ACH_UPDATED", function() UI:QueueRefresh("ach") end)
	ns:On("PLAYER_REGEN_DISABLED", function() UI:UpdateKeyboard(true) end)
	ns:On("PLAYER_REGEN_ENABLED", function() UI:UpdateKeyboard() end)
	return f
end

------------------------------------------------------------------------
-- 단축키 (전투 중에는 꺼진다)
------------------------------------------------------------------------
function UI:UpdateKeyboard(entering)
	local f = self.frame
	if not f then return end
	local inCombat = entering or (InCombatLockdown and InCombatLockdown())
	local want = f:IsShown() and ns.db.hotkeys and not inCombat
	pcall(f.EnableKeyboard, f, want and true or false)
	if want then pcall(f.SetPropagateKeyboardInput, f, true) end
	f.hints:SetText(ns.db.hotkeys and "1~5 탭 전환   ·   ←/→ 쪽 넘기기   ·   ↑/↓ 도감 넘기기   ·   Space 글 바로 보기   ·   Esc 닫기"
		or "Esc 닫기")
end

function UI:HandleKey(key)
	if not ns.db.hotkeys then return false end
	for _, tab in ipairs(self.TABS) do
		if key == tab.key then
			self:SelectTab(tab.id)
			return true
		end
	end
	if key == "SPACE" and UI.IsTyping() then
		UI.FinishTyping()
		return true
	end
	local mod = self:TabModule(self.current)
	if mod and mod.OnKey then
		return mod:OnKey(key) and true or false
	end
	return false
end

------------------------------------------------------------------------
function UI:RefreshHeader()
	local f = self.frame
	if not f or not ns.char then return end
	local meta = ns.char.meta or {}
	local name = ns.PlayerName()
	local race = ns.Call(UnitRace, "player") or meta.race or ""
	local class = ns.Call(UnitClass, "player") or meta.class or ""
	f.title:SetText(name .. "의 모험 전기")
	local found, total, species = ns.Bestiary:Completion()
	local aDone, aTotal, aPts = ns.Achievements:Summary()
	f.subtitle:SetText(string.format("%s  ·  %d레벨  ·  기록 %s개  ·  도감 %d/%d 종족, %s종  ·  업적 %d/%d (%s점)",
		ns.Trim(race .. " " .. class), ns.PlayerLevel(), ns.Comma(#ns.char.log), found, total, ns.Comma(species), aDone, aTotal, ns.Comma(aPts)))
end

function UI:SelectTab(id)
	self:Build()
	local changed = self.current ~= id
	self.current = id
	for tid, b in pairs(self.tabButtons) do b:SetSelected(tid == id) end
	for pid, p in pairs(self.panels) do p:SetShown(pid == id) end
	local mod = self:TabModule(id)
	if mod and not self.panels[id] then
		self.panels[id] = mod:Create(self.content)
		self.panels[id]:Show()
	end
	if changed and self.panels[id] then UI.FadeIn(self.panels[id], 0.18) end
	self:RefreshCurrent()
end

function UI:RefreshCurrent(reason)
	if not self.frame or not self.frame:IsShown() or not ns.char then return end
	local mod = self:TabModule(self.current)
	if mod and mod.Refresh and self.panels[self.current] then
		local ok, err = pcall(mod.Refresh, mod, nil, reason)
		if not ok then ns:Error(err) end
	end
end

-- 기록이 연달아 들어올 때 한 번만 다시 그리도록 모은다. 관계없는 탭은 다시 그리지 않는다.
local RELEVANT = {
	log = { journal = true, stats = true, achievements = true },
	dex = { bestiary = true, stats = true },
	ach = { achievements = true },
}

function UI:QueueRefresh(kind)
	if not self.frame or not self.frame:IsShown() then return end
	self.pendingKinds = self.pendingKinds or {}
	self.pendingKinds[kind or "log"] = true
	if self.refreshPending then return end
	self.refreshPending = true
	local run = function()
		UI.refreshPending = false
		local kinds = UI.pendingKinds
		UI.pendingKinds = {}
		UI:RefreshHeader()
		for k in pairs(kinds) do
			if RELEVANT[k] and RELEVANT[k][UI.current] then
				UI:RefreshCurrent(k)
				return
			end
		end
	end
	if C_Timer and C_Timer.After then C_Timer.After(0.25, run) else run() end
end

function UI:Open(tab)
	if not ns.char then return end
	self:Build()
	self.frame:Show()
	self:SelectTab(tab or self.current or "journal")
end

function UI:Toggle(tab)
	self:Build()
	if self.frame:IsShown() and (not tab or tab == self.current) then
		self.frame:Hide()
	else
		self:Open(tab)
	end
end

------------------------------------------------------------------------
-- 내보내기 창
------------------------------------------------------------------------
function UI:ShowExport()
	if not ns.char then return end
	self:InitTheme()
	local C = self.COL
	if not self.exportFrame then
		local f = CreateFrame("Frame", "BigChronicleExport", UIParent)
		f:SetSize(640, 500)
		f:SetPoint("CENTER")
		f:SetFrameStrata("DIALOG")
		f:SetMovable(true)
		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)
		f:SetClampedToScreen(true)
		UI.Paper(f)
		UI.Roller(f, "TOP", 14)
		UI.Roller(f, "BOTTOM", 14)
		if UISpecialFrames then table.insert(UISpecialFrames, "BigChronicleExport") end

		local title = f:CreateFontString(nil, "OVERLAY", UI.F.header)
		title:SetPoint("TOP", 0, -20)
		title:SetText("모험 전기 내보내기")
		local hint = f:CreateFontString(nil, "OVERLAY", UI.F.small)
		hint:SetPoint("TOP", title, "BOTTOM", 0, -6)
		hint:SetText("Ctrl+A 로 전체 선택한 뒤 Ctrl+C 로 복사하세요.")
		local div = UI.Divider(f, 420)
		div:SetPoint("TOP", hint, "BOTTOM", 0, -6)

		local close = CloseButton(f, function() f:Hide() end)
		close:SetPoint("TOPRIGHT", -10, -10)

		local box = UI.Section(f)
		box:SetPoint("TOPLEFT", 22, -80)
		box:SetPoint("BOTTOMRIGHT", -22, 22)

		local scroll = UI.Scroll(box)
		scroll:SetPoint("TOPLEFT", 10, -10)
		scroll:SetPoint("BOTTOMRIGHT", -20, 10)

		local eb = CreateFrame("EditBox", nil, scroll.child)
		eb:SetMultiLine(true)
		eb:SetAutoFocus(false)
		eb:SetFontObject(UI.F.body)
		eb:SetTextColor(C.text[1], C.text[2], C.text[3])
		eb:SetWidth(560)
		eb:SetPoint("TOPLEFT")
		eb:SetMaxLetters(0)
		eb:SetScript("OnEscapePressed", function() f:Hide() end)
		eb:SetScript("OnTextChanged", function(self, userInput)
			if userInput and f.text then self:SetText(f.text) self:HighlightText() end
		end)
		eb:SetScript("OnSizeChanged", function(self)
			scroll:SetContentHeight(self:GetHeight() or 1)
		end)
		f.editBox = eb
		f.scroll = scroll
		self.exportFrame = f
	end
	local f = self.exportFrame
	f.text = ns.Chronicle:ExportText()
	if ns.Achievements then ns.Achievements:NoteExport() end
	f.editBox:SetText(f.text)
	f:Show()
	UI.FadeIn(f, 0.2)
	f.scroll:SetContentHeight(f.editBox:GetHeight() or 1)
	f.scroll:ScrollToTop()
	f.editBox:SetFocus()
	f.editBox:HighlightText()
end
