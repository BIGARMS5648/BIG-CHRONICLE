-- BIG CHRONICLE :: 메인 창 (가죽 표지의 도감 수첩)

local ADDON, ns = ...
local UI = ns.UI

UI.TABS = {
	{ id = "journal",      name = "모험 일지",   key = "1", icon = "scroll-quill" },
	{ id = "bestiary",     name = "몬스터 도감", key = "2", icon = "paw-print" },
	{ id = "achievements", name = "업적",        key = "3", icon = "laurels-trophy" },
	{ id = "stats",        name = "연대기 통계", key = "4", icon = "histogram" },
	{ id = "settings",     name = "설정",        key = "5", icon = "cog" },
}

local WIDTH, HEIGHT = 980, 660
-- 표지 안쪽의 종이 페이지 여백 (왼쪽은 스프링 링 자리)
local PAGE_L, PAGE_R, PAGE_T, PAGE_B = 44, 24, 16, 16

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
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.title)
	fs:SetPoint("CENTER", 0, 1)
	fs:SetText("X")
	fs:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 2, -4)
	hl:SetPoint("BOTTOMRIGHT", -2, 4)
	hl:SetTexture(UI.TEX.tape)
	UI.Tint(hl, C.hover)
	b:SetScript("OnEnter", function() fs:SetTextColor(C.title[1], C.title[2], C.title[3]) end)
	b:SetScript("OnLeave", function() fs:SetTextColor(C.accent[1], C.accent[2], C.accent[3]) end)
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

	local C2 = UI.COL
	-- ① 가죽 표지
	local coverShadow = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	coverShadow:SetPoint("TOPLEFT", 4, -6)
	coverShadow:SetPoint("BOTTOMRIGHT", 8, -10)
	coverShadow:SetColorTexture(0, 0, 0, 0.5)
	local cover = UI.Tiled(f, "BACKGROUND", -7, UI.TEX.leather, 256, 256)
	UI.Tint(cover, C2.cover)
	UI.Outline(f, { C2.coverDark[1], C2.coverDark[2], C2.coverDark[3], 0.9 }, 0)
	-- 가장자리를 따라 바느질선
	local function stitchH(y, point)
		local t = UI.Tiled(f, "BORDER", 1, UI.TEX.stitch, 32, 8, nil)
		t:ClearAllPoints()
		t:SetPoint(point .. "LEFT", 10, y)
		t:SetPoint(point .. "RIGHT", -10, y)
		t:SetHeight(6)
		t:SetTexCoord(0, (WIDTH - 20) / 32, 0, 1)
		UI.Tint(t, C2.stitch, 0.85)
	end
	stitchH(-6, "TOP")
	stitchH(6, "BOTTOM")
	for _, side in ipairs({ "LEFT", "RIGHT" }) do
		local t = UI.TiledVertical(f, "BORDER", 1, UI.TEX.stitch, 32)
		t:SetPoint("TOP" .. side, side == "LEFT" and 6 or -6, -10)
		t:SetPoint("BOTTOM" .. side, side == "LEFT" and 6 or -6, 10)
		t:SetWidth(6)
		t:SetTexCoord(0, 0, (HEIGHT - 20) / 32, 0, 0, 1, (HEIGHT - 20) / 32, 1)
		UI.Tint(t, C2.stitch, 0.85)
	end
	-- 오른쪽 고무줄 밴드
	local band = f:CreateTexture(nil, "BORDER", nil, 2)
	band:SetPoint("TOPRIGHT", -9, 0)
	band:SetPoint("BOTTOMRIGHT", -9, 0)
	band:SetWidth(9)
	UI.Gradient(band, "HORIZONTAL", { C2.coverDark[1] * 0.6, C2.coverDark[2] * 0.6, C2.coverDark[3] * 0.6, 1 },
		{ C2.coverDark[1] * 1.6, C2.coverDark[2] * 1.6, C2.coverDark[3] * 1.6, 1 })

	-- ② 종이 페이지 (모눈)
	local page = CreateFrame("Frame", nil, f)
	page:SetPoint("TOPLEFT", PAGE_L, -PAGE_T)
	page:SetPoint("BOTTOMRIGHT", -PAGE_R, PAGE_B)
	page:SetFrameLevel(f:GetFrameLevel() + 1)
	UI.Paper(page, { grid = true, shadow = 0.4 })
	f.page = page
	-- 제본 쪽 그늘
	local gutter = page:CreateTexture(nil, "BACKGROUND", nil, -4)
	gutter:SetPoint("TOPLEFT"); gutter:SetPoint("BOTTOMLEFT"); gutter:SetWidth(46)
	UI.Gradient(gutter, "HORIZONTAL", { 0, 0, 0, 0.22 }, { 0, 0, 0, 0 })
	-- 펀치 구멍과 스프링 링
	local rings = CreateFrame("Frame", nil, f)
	rings:SetAllPoints(f)
	rings:SetFrameLevel(page:GetFrameLevel() + 30)
	local count = 12
	local span = HEIGHT - 70
	for i = 1, count do
		local y = -35 - (i - 1) * span / (count - 1)
		local hole = page:CreateTexture(nil, "BORDER", nil, 2)
		hole:SetSize(13, 13)
		hole:SetPoint("CENTER", page, "TOPLEFT", 13, y + PAGE_T)
		hole:SetTexture(UI.TEX.hole)
		local ring = rings:CreateTexture(nil, "OVERLAY")
		ring:SetSize(22, 36)
		ring:SetPoint("CENTER", page, "TOPLEFT", 3, y + PAGE_T + 2)
		ring:SetTexture(UI.TEX.ring)
		if ring.SetRotation then pcall(ring.SetRotation, ring, math.pi / 2) end
	end

	-- ③ 위로 삐죽 나온 색인 탭
	self.tabButtons = {}
	local x = 70
	for i, tab in ipairs(UI.TABS) do
		local b = UI.Tab(f, tab.name, tab.key, function() UI:SelectTab(tab.id) end, C2.tabs[i], UI.ICON[tab.icon])
		b:SetPoint("BOTTOMLEFT", f, "TOPLEFT", x, -3)
		b:SetFrameLevel(math.max(1, f:GetFrameLevel() - 1))
		x = x + b:GetWidth() + 6
		self.tabButtons[tab.id] = b
	end

	-- ④ 머리말: 손글씨 제목
	local body = CreateFrame("Frame", nil, page)
	body:SetAllPoints(page)
	body:SetFrameLevel(page:GetFrameLevel() + 2)
	f.body = body
	local paw = body:CreateTexture(nil, "ARTWORK")
	paw:SetSize(30, 30)
	paw:SetPoint("TOPLEFT", 30, -14)
	paw:SetTexture(UI.ICON["paw-print"])
	UI.Tint(paw, C2.accent, 0.85)
	if paw.SetRotation then pcall(paw.SetRotation, paw, -0.2) end
	local title = body:CreateFontString(nil, "OVERLAY", UI.F.title)
	title:SetPoint("LEFT", paw, "RIGHT", 8, -2)
	title:SetJustifyH("LEFT")
	f.title = title
	local sub = body:CreateFontString(nil, "OVERLAY", UI.F.small)
	sub:SetPoint("TOPLEFT", paw, "BOTTOMLEFT", 2, -8)
	sub:SetJustifyH("LEFT")
	f.subtitle = sub
	local brand = body:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	brand:SetPoint("TOPRIGHT", -54, -18)
	brand:SetText("B I G   C H R O N I C L E")
	brand:SetTextColor(C2.muted[1], C2.muted[2], C2.muted[3])
	local divider = UI.Divider(body, 400)
	divider:SetPoint("TOPLEFT", 26, -78)
	divider:SetPoint("TOPRIGHT", -26, -78)
	-- 책갈피 리본 (머리말 오른쪽으로 늘어진다)
	local ribbon = body:CreateTexture(nil, "OVERLAY", nil, 3)
	ribbon:SetSize(16, 70)
	ribbon:SetPoint("TOP", page, "TOPRIGHT", -232, 6)
	ribbon:SetTexture(UI.TEX.ribbon)
	UI.Tint(ribbon, C2.accent)

	local close = CloseButton(body, function() f:Hide() end)
	close:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -10)

	local content = CreateFrame("Frame", nil, body)
	content:SetPoint("TOPLEFT", 30, -92)
	content:SetPoint("BOTTOMRIGHT", -18, 30)
	self.content = content
	self.panels = {}

	-- 아래쪽 단축키 안내
	local hints = body:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	hints:SetPoint("BOTTOM", 0, 10)
	f.hints = hints

	-- ⑤ 창을 열 때 표지가 넘어가는 연출용 덮개
	local flap = CreateFrame("Frame", nil, f)
	flap:SetPoint("TOPLEFT", f, "TOPLEFT")
	flap:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT")
	flap:SetWidth(WIDTH)
	flap:SetFrameLevel(page:GetFrameLevel() + 60)
	local flapTex = UI.Tiled(flap, "ARTWORK", 0, UI.TEX.leather, 256, 256)
	UI.Tint(flapTex, C2.cover)
	local flapEdge = flap:CreateTexture(nil, "OVERLAY")
	flapEdge:SetPoint("TOPRIGHT"); flapEdge:SetPoint("BOTTOMRIGHT"); flapEdge:SetWidth(40)
	UI.Gradient(flapEdge, "HORIZONTAL", { 0, 0, 0, 0 }, { 0, 0, 0, 0.55 })
	local flapTitle = flap:CreateFontString(nil, "OVERLAY", UI.F.title)
	flapTitle:SetPoint("CENTER")
	flapTitle:SetTextColor(C2.stitch[1], C2.stitch[2], C2.stitch[3])
	flapTitle:SetText("BIG CHRONICLE")
	f.flap, f.flapTitle = flap, flapTitle
	flap:Hide()

	f:SetScript("OnShow", function(self)
		UI:Unroll()
		if ns.Minimap and ns.Minimap.ClearNews then ns.Minimap:ClearNews() end
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
-- 창을 열 때 가죽 표지가 왼쪽으로 넘어가며 수첩이 펼쳐진다
function UI:Unroll()
	local f = self.frame
	if not f then return end
	local E = ns.Effects
	if not (ns.db and ns.db.effects) or not E then
		f.flap:Hide()
		UI.FadeIn(f, 0.2)
		return
	end
	f:SetAlpha(1)
	f.flap:Show()
	f.flap:SetWidth(WIDTH)
	f.flapTitle:SetAlpha(1)
	E.Tween("main-open", 0.55, function(p)
		local k = E.Ease.inOut(p)
		f.flap:SetWidth(math.max(1, WIDTH * (1 - k)))
		f.flapTitle:SetAlpha(1 - math.min(1, p * 2.5))
	end, function() f.flap:Hide() end)
	E.Sound("open")
end

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
	f.title:SetText(UI.PenText(name .. "의 도감 수첩"))
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
