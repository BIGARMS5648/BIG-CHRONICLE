-- BIG CHRONICLE :: 메인 창 (가죽 장정의 도감 수첩)

local ADDON, ns = ...
local UI = ns.UI

UI.TABS = {
	{ id = "journal",      name = "모험 일지",   key = "1", icon = "IconJournal" },
	{ id = "bestiary",     name = "몬스터 도감", key = "2", icon = "IconBestiary" },
	{ id = "achievements", name = "업적",        key = "3", icon = "IconAchievements" },
	{ id = "stats",        name = "연대기 통계", key = "4", icon = "IconStats" },
	{ id = "settings",     name = "설정",        key = "5", icon = "Gear" },
}

local WIDTH, HEIGHT = 1014, 724
-- 탭 아래 내용이 놓이는 자리 (창틀 안쪽)
local CONTENT_L, CONTENT_R, CONTENT_T, CONTENT_B = 46, 46, 134, 60

function UI:TabModule(id)
	if id == "journal" then return ns.JournalTab end
	if id == "bestiary" then return ns.BestiaryTab end
	if id == "achievements" then return ns.AchievementsTab end
	if id == "stats" then return ns.StatsTab end
	if id == "settings" then return ns.SettingsTab end
end

-- 붉은 바탕에 금테를 두른 닫기 버튼
local function CloseButton(parent, onClick, size)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(size or 32, size or 32)
	local t = b:CreateTexture(nil, "ARTWORK")
	t:SetPoint("TOPLEFT", -2, 2)
	t:SetPoint("BOTTOMRIGHT", 2, -2)
	t:SetTexture(UI.Tex("Close"))
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 5, -5)
	hl:SetPoint("BOTTOMRIGHT", -5, 5)
	hl:SetColorTexture(1, 0.8, 0.5, 0.25)
	pcall(hl.SetBlendMode, hl, "ADD")
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

	local L = UI.LEATHER
	local A = UI.ATLAS
	local SC = UI.SCALE
	-- ① 창틀: 금 모서리 + 박음질 가죽 테두리 + 짙은 가죽 바탕, 아래 가운데에 나침반 장식
	for i = 1, 3 do
		local sh = f:CreateTexture(nil, "BACKGROUND", nil, -8)
		sh:SetPoint("TOPLEFT", 14 - i * 3, -14 + i * 3 - 6)
		sh:SetPoint("BOTTOMRIGHT", -14 + i * 3, 14 - i * 3 - 6)
		sh:SetColorTexture(0, 0, 0, 0.16)
	end
	UI.WindowFrame(f, { ornament = "bottom" })

	-- ② 내용이 놓이는 자리
	local body = CreateFrame("Frame", nil, f)
	body:SetAllPoints(f)
	body:SetFrameLevel(f:GetFrameLevel() + 2)
	f.body = body
	local content = CreateFrame("Frame", nil, body)
	content:SetPoint("TOPLEFT", CONTENT_L, -CONTENT_T)
	content:SetPoint("BOTTOMRIGHT", -CONTENT_R, CONTENT_B)
	self.content = content
	self.panels = {}

	-- ③ 사다리꼴 가죽 탭 (고른 탭은 양피지빛)
	self.tabButtons = {}
	local tabW, tabGap = 180, 4
	local x = CONTENT_L + 2
	for _, tab in ipairs(UI.TABS) do
		local b = UI.Tab(body, tab.name, tab.key, function() UI:SelectTab(tab.id) end, nil, UI.ICON[tab.icon])
		b:SetWidth(tabW)
		b:SetPoint("BOTTOMLEFT", f, "TOPLEFT", x, -(CONTENT_T - 5))
		x = x + tabW + tabGap
		self.tabButtons[tab.id] = b
	end
	local tabRule = body:CreateTexture(nil, "ARTWORK")
	tabRule:SetPoint("TOPLEFT", f, "TOPLEFT", CONTENT_L - 4, -(CONTENT_T - 5))
	tabRule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(CONTENT_R - 4), -(CONTENT_T - 5))
	tabRule:SetHeight(2)
	UI.Gradient(tabRule, "VERTICAL", { 0.30, 0.18, 0.06, 0.9 }, { L.gold[1], L.gold[2], L.gold[3], 0.85 })

	-- ④ 제목 명판, 깃발, 닫기 버튼 (탭 내용보다 위에)
	local trim = CreateFrame("Frame", nil, f)
	trim:SetAllPoints(f)
	trim:SetFrameLevel(body:GetFrameLevel() + 40)
	f.trim = trim
	local plaque = UI.Sprite(trim, "Plaque", "ARTWORK", 5, 0.66)
	plaque:SetPoint("TOP", f, "TOP", 0, 20)
	f.plaque = plaque
	-- 명판 가운데의 금빛 BIG CHRONICLE 글자 (그림이 없으면 글꼴로 대신 쓴다)
	local plaqueMidY = -A.Plaque.h * 0.66 * 0.60
	if A.Title then
		local word = UI.Sprite(trim, "Title", "OVERLAY", 2)
		local h = 27
		word:SetSize(h * A.Title.w / A.Title.h, h)
		word:SetPoint("CENTER", plaque, "TOP", 0, plaqueMidY)
		f.brand = word
	else
		local brand = trim:CreateFontString(nil, "OVERLAY", UI.F.brand)
		brand:SetPoint("CENTER", plaque, "TOP", 0, plaqueMidY)
		brand:SetText("BIG CHRONICLE")
		f.brand = brand
	end
	local banner = UI.Sprite(trim, "Banner", "ARTWORK", 4, 0.74)
	banner:SetPoint("TOP", f, "TOPLEFT", 112, -6)
	local close = CloseButton(trim, function() f:Hide() end, 34)
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -40, -38)

	-- ⑤ 아래쪽 장식 양옆에 단축키 안내
	local hints = trim:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	hints:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 64, 40)
	UI.OnLeather(hints, L.muted)
	f.hints = hints
	local hints2 = trim:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	hints2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -64, 40)
	hints2:SetJustifyH("RIGHT")
	UI.OnLeather(hints2, L.muted)
	f.hints2 = hints2

	f:SetScript("OnShow", function(self)
		UI:Unroll()
		if ns.Minimap and ns.Minimap.ClearNews then ns.Minimap:ClearNews() end
		UI:RefreshCurrent()
		UI:UpdateKeyboard()
	end)
	f:SetScript("OnHide", function()
		UI.FinishTyping()
		if ns.Effects and ns.Effects.Enabled() then ns.Effects.Sound("close") end
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
-- 창을 열면 책이 살짝 떠오르듯 나타난다 (표지 연출 없음)
function UI:Unroll()
	local f = self.frame
	if not f then return end
	f.trim:SetAlpha(1)
	UI.FadeIn(f, 0.2)
	if ns.db and ns.db.effects and ns.Effects then ns.Effects.Sound("open") end
end

function UI:UpdateKeyboard(entering)
	local f = self.frame
	if not f then return end
	local inCombat = entering or (InCombatLockdown and InCombatLockdown())
	local want = f:IsShown() and ns.db.hotkeys and not inCombat
	pcall(f.EnableKeyboard, f, want and true or false)
	if want then pcall(f.SetPropagateKeyboardInput, f, true) end
	f.hints:SetText(ns.db.hotkeys and "1~5 탭 전환   ·   ←/→ 쪽 넘기기   ·   ↑/↓ 도감 넘기기" or "")
	f.hints2:SetText(ns.db.hotkeys and "Space 글 바로 보기   ·   Esc 닫기" or "Esc 닫기")
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
		local L = UI.LEATHER
		UI.WindowFrame(f, { scale = 0.5 })
		if UISpecialFrames then table.insert(UISpecialFrames, "BigChronicleExport") end

		local title = f:CreateFontString(nil, "OVERLAY", UI.F.header)
		title:SetPoint("TOP", 0, -34)
		title:SetText("모험 전기 내보내기")
		UI.OnLeather(title, L.title)
		local hint = f:CreateFontString(nil, "OVERLAY", UI.F.small)
		hint:SetPoint("TOP", title, "BOTTOM", 0, -6)
		hint:SetText("Ctrl+A 로 전체 선택한 뒤 Ctrl+C 로 복사하세요.")
		UI.OnLeather(hint, L.sub)

		local close = CloseButton(f, function() f:Hide() end, 28)
		close:SetPoint("TOPRIGHT", -30, -28)
		close:SetFrameLevel(f:GetFrameLevel() + 10)

		local box = UI.Section(f)
		box:SetPoint("TOPLEFT", 34, -86)
		box:SetPoint("BOTTOMRIGHT", -34, 36)

		local scroll = UI.Scroll(box)
		scroll:SetPoint("TOPLEFT", 16, -14)
		scroll:SetPoint("BOTTOMRIGHT", -28, 14)

		local eb = CreateFrame("EditBox", nil, scroll.child)
		eb:SetMultiLine(true)
		eb:SetAutoFocus(false)
		eb:SetFontObject(UI.F.body)
		eb:SetTextColor(C.text[1], C.text[2], C.text[3])
		eb:SetWidth(520)
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
