-- BIG CHRONICLE :: 메인 창 (가죽 장정의 고서)

local ADDON, ns = ...
local UI = ns.UI

UI.TABS = {
	{ id = "journal",      name = "모험 일지",   key = "1", icon = "quill-ink" },
	{ id = "bestiary",     name = "몬스터 도감", key = "2", icon = "dragon-head" },
	{ id = "achievements", name = "업적",        key = "3", icon = "laurel-crown" },
	{ id = "stats",        name = "연대기 통계", key = "4", icon = "hourglass" },
	{ id = "settings",     name = "설정",        key = "5", icon = "cog" },
}

local WIDTH, HEIGHT = 980, 660
-- 장정 안쪽의 양피지 페이지 여백 (왼쪽은 책등 자리)
local PAGE_L, PAGE_R, PAGE_T, PAGE_B = 46, 26, 18, 20

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
	fs:SetText("×")
	fs:SetTextColor(C.sub[1], C.sub[2], C.sub[3])
	b:SetScript("OnEnter", function() fs:SetTextColor(C.accent[1], C.accent[2], C.accent[3]) end)
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

	local C2 = UI.COL
	-- ① 가죽 장정
	local coverShadow = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	coverShadow:SetPoint("TOPLEFT", 3, -5)
	coverShadow:SetPoint("BOTTOMRIGHT", 9, -11)
	coverShadow:SetColorTexture(0, 0, 0, 0.6)
	local cover = UI.Tiled(f, "BACKGROUND", -7, UI.TEX.leather, 256, 256)
	UI.Tint(cover, C2.cover)
	local coverWear = f:CreateTexture(nil, "BACKGROUND", nil, -6)
	coverWear:SetAllPoints()
	coverWear:SetTexture(UI.TEX.vignette)
	coverWear:SetVertexColor(0, 0, 0, 0.55)
	UI.Outline(f, { C2.coverDark[1], C2.coverDark[2], C2.coverDark[3], 1 }, 0)
	-- 가장자리를 따라 금박으로 찍은 이중선
	UI.Outline(f, { C2.gold[1], C2.gold[2], C2.gold[3], 0.55 }, 6, "BORDER", 1)
	UI.Outline(f, { C2.gold[1], C2.gold[2], C2.gold[3], 0.28 }, 9, "BORDER", 1)

	-- 책등: 짙은 가죽 띠에 볼록한 띠 여섯 개, 띠마다 금박 선
	local spine = f:CreateTexture(nil, "BORDER", nil, 2)
	spine:SetPoint("TOPLEFT", 0, 0)
	spine:SetPoint("BOTTOMLEFT", 0, 0)
	spine:SetWidth(PAGE_L - 6)
	UI.Gradient(spine, "HORIZONTAL", { 0, 0, 0, 0.55 }, { 0, 0, 0, 0.12 })
	local spineEdge = f:CreateTexture(nil, "BORDER", nil, 3)
	spineEdge:SetPoint("TOPLEFT", PAGE_L - 7, 0)
	spineEdge:SetPoint("BOTTOMLEFT", PAGE_L - 7, 0)
	spineEdge:SetWidth(1)
	spineEdge:SetColorTexture(C2.gold[1], C2.gold[2], C2.gold[3], 0.35)
	local bands = 6
	for i = 1, bands do
		local y = -HEIGHT * i / (bands + 1)
		local band = f:CreateTexture(nil, "BORDER", nil, 4)
		band:SetSize(PAGE_L - 10, 13)
		band:SetPoint("CENTER", f, "TOPLEFT", (PAGE_L - 6) / 2, y)
		band:SetTexture(UI.TEX.band)
		band:SetVertexColor(C2.cover[1] * 1.5, C2.cover[2] * 1.5, C2.cover[3] * 1.5)
		for _, dy in ipairs({ 9, -9 }) do
			local g = f:CreateTexture(nil, "BORDER", nil, 5)
			g:SetSize(PAGE_L - 16, 1)
			g:SetPoint("CENTER", f, "TOPLEFT", (PAGE_L - 6) / 2, y + dy)
			g:SetColorTexture(C2.gold[1], C2.gold[2], C2.gold[3], 0.6)
		end
	end

	-- ② 양피지 페이지 (오른쪽·아래로 겹겹이 쌓인 책장 끝이 보인다)
	local page = CreateFrame("Frame", nil, f)
	page:SetPoint("TOPLEFT", PAGE_L, -PAGE_T)
	page:SetPoint("BOTTOMRIGHT", -PAGE_R, PAGE_B)
	page:SetFrameLevel(f:GetFrameLevel() + 1)
	for i = 3, 1, -1 do
		local leaf = page:CreateTexture(nil, "BACKGROUND", nil, -8)
		leaf:SetPoint("TOPLEFT", 0, -i)
		leaf:SetPoint("BOTTOMRIGHT", i * 2, -i * 2)
		local k = 0.78 - i * 0.06
		leaf:SetColorTexture(C2.page[1] * k, C2.page[2] * k, C2.page[3] * k, 1)
	end
	UI.Paper(page, { shadow = false })
	f.page = page
	-- 제본 쪽 그늘
	local gutter = page:CreateTexture(nil, "BACKGROUND", nil, -4)
	gutter:SetPoint("TOPLEFT"); gutter:SetPoint("BOTTOMLEFT"); gutter:SetWidth(56)
	UI.Gradient(gutter, "HORIZONTAL", { 0, 0, 0, 0.32 }, { 0, 0, 0, 0 })

	-- ③ 장정 위로 나온 가죽 색인 탭
	self.tabButtons = {}
	local x = 64
	for _, tab in ipairs(UI.TABS) do
		local b = UI.Tab(f, tab.name, tab.key, function() UI:SelectTab(tab.id) end, nil, UI.ICON[tab.icon])
		b:SetPoint("BOTTOMLEFT", f, "TOPLEFT", x, -3)
		b:SetFrameLevel(math.max(1, f:GetFrameLevel() - 1))
		x = x + b:GetWidth() + 4
		self.tabButtons[tab.id] = b
	end

	-- ④ 머리말: 문장 + 명조 제목
	local body = CreateFrame("Frame", nil, page)
	body:SetAllPoints(page)
	body:SetFrameLevel(page:GetFrameLevel() + 2)
	f.body = body
	local crest = body:CreateTexture(nil, "ARTWORK")
	crest:SetSize(38, 38)
	crest:SetPoint("TOPLEFT", 26, -14)
	crest:SetTexture(UI.ICON["griffin-symbol"])
	UI.Tint(crest, C2.accent, 0.9)
	local title = body:CreateFontString(nil, "OVERLAY", UI.F.title)
	title:SetPoint("TOPLEFT", crest, "TOPRIGHT", 10, -2)
	title:SetJustifyH("LEFT")
	f.title = title
	local sub = body:CreateFontString(nil, "OVERLAY", UI.F.small)
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -6)
	sub:SetJustifyH("LEFT")
	f.subtitle = sub
	local brand = body:CreateFontString(nil, "OVERLAY", UI.F.label)
	brand:SetPoint("TOPRIGHT", -54, -20)
	brand:SetText(UI.Spaced("BIG CHRONICLE", 1))
	brand:SetTextColor(C2.muted[1], C2.muted[2], C2.muted[3])
	local divider = UI.Divider(body, 400)
	divider:SetPoint("TOPLEFT", 24, -72)
	divider:SetPoint("TOPRIGHT", -24, -72)
	-- 책갈피 끈 (머리말 오른쪽으로 늘어진다)
	local ribbon = body:CreateTexture(nil, "OVERLAY", nil, 3)
	ribbon:SetSize(14, 74)
	ribbon:SetPoint("TOP", page, "TOPRIGHT", -232, 4)
	ribbon:SetTexture(UI.TEX.ribbon)
	ribbon:SetVertexColor(0.42, 0.07, 0.06)

	local close = CloseButton(body, function() f:Hide() end)
	close:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -10)

	local content = CreateFrame("Frame", nil, body)
	content:SetPoint("TOPLEFT", 28, -90)
	content:SetPoint("BOTTOMRIGHT", -18, 30)
	self.content = content
	self.panels = {}

	-- 아래쪽 단축키 안내
	local hints = body:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	hints:SetPoint("BOTTOM", 0, 12)
	hints:SetTextColor(UI.COL.sub[1], UI.COL.sub[2], UI.COL.sub[3])
	f.hints = hints

	-- 놋쇠 모서리 (페이지 위로 살짝 걸친다)
	local metal = CreateFrame("Frame", nil, f)
	metal:SetAllPoints(f)
	metal:SetFrameLevel(page:GetFrameLevel() + 40)
	UI.Corners(metal, UI.TEX.corner, 50, -3)

	-- ⑤ 창을 열 때 넘어가는 앞표지
	local flap = CreateFrame("Frame", nil, f)
	flap:SetPoint("TOPLEFT", f, "TOPLEFT")
	flap:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT")
	flap:SetWidth(WIDTH)
	flap:SetFrameLevel(page:GetFrameLevel() + 60)
	pcall(flap.SetClipsChildren, flap, true)
	local face = CreateFrame("Frame", nil, flap)
	face:SetPoint("TOPLEFT")
	face:SetSize(WIDTH, HEIGHT)
	local flapTex = UI.Tiled(face, "BACKGROUND", 0, UI.TEX.leather, 256, 256)
	UI.Tint(flapTex, C2.cover)
	local flapWear = face:CreateTexture(nil, "BACKGROUND", nil, 1)
	flapWear:SetAllPoints()
	flapWear:SetTexture(UI.TEX.vignette)
	flapWear:SetVertexColor(0, 0, 0, 0.6)
	UI.Outline(face, { C2.coverDark[1], C2.coverDark[2], C2.coverDark[3], 1 }, 0)
	UI.Outline(face, { C2.gold[1], C2.gold[2], C2.gold[3], 0.7 }, 22, "BORDER")
	UI.Outline(face, { C2.gold[1], C2.gold[2], C2.gold[3], 0.4 }, 27, "BORDER")
	UI.Corners(face, UI.TEX.ornCorner, 34, 30, { C2.gold[1], C2.gold[2], C2.gold[3], 0.85 }, "BORDER", 2)
	UI.Corners(face, UI.TEX.corner, 50, -3)
	local emblem = face:CreateTexture(nil, "ARTWORK")
	emblem:SetSize(170, 170)
	emblem:SetPoint("CENTER", 0, 50)
	emblem:SetTexture(UI.TEX.emblem)
	emblem:SetVertexColor(C2.gold[1], C2.gold[2], C2.gold[3], 0.9)
	local flapTitle = face:CreateFontString(nil, "OVERLAY", UI.F.title)
	flapTitle:SetPoint("TOP", emblem, "BOTTOM", 0, -16)
	flapTitle:SetTextColor(C2.gold[1], C2.gold[2], C2.gold[3])
	flapTitle:SetText(UI.Spaced("BIG CHRONICLE", 1))
	local flapRule = UI.Divider(face, 260, C2.gold)
	flapRule:SetPoint("TOP", flapTitle, "BOTTOM", 0, -8)
	local flapShade = flap:CreateTexture(nil, "OVERLAY", nil, 7)
	flapShade:SetAllPoints()
	flapShade:SetColorTexture(0, 0, 0, 0)
	local flapEdge = flap:CreateTexture(nil, "OVERLAY", nil, 6)
	flapEdge:SetPoint("TOPRIGHT"); flapEdge:SetPoint("BOTTOMRIGHT"); flapEdge:SetWidth(46)
	UI.Gradient(flapEdge, "HORIZONTAL", { 0, 0, 0, 0 }, { 0, 0, 0, 0.6 })
	f.flap, f.flapTitle, f.flapShade = flap, flapTitle, flapShade
	f.flapFace = face
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
-- 창을 열 때 무거운 앞표지가 왼쪽으로 넘어가며 책이 펼쳐진다
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
	f.flapFace:SetAlpha(1)
	f.flapShade:SetColorTexture(0, 0, 0, 0)
	-- 잠깐 표지를 보여 준 뒤, 묵직하게 넘긴다
	E.Tween("main-open", 0.75, function(p)
		local k = E.Ease.inOut(p)
		f.flap:SetWidth(math.max(1, WIDTH * (1 - k)))
		f.flapFace:SetAlpha(1 - math.max(0, (p - 0.35) / 0.65))
		f.flapShade:SetColorTexture(0, 0, 0, 0.65 * k)
	end, function() f.flap:Hide() end, 0.25)
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
	f.title:SetText(name .. "의 연대기")
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
		UI.Corners(f, UI.TEX.ornCorner, 20, 5, { C.edge[1], C.edge[2], C.edge[3], 0.7 })
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
