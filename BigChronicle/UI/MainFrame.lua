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

local WIDTH, HEIGHT = 1000, 720
local EDGE, BAR = 8, 16          -- 바깥 가장자리에서 금테까지 / 금테 두께
local CORNER, CORNER_OUT = 104, 4 -- 모서리 장식 크기 / 바깥으로 나오는 만큼
-- 탭 아래 내용이 놓이는 자리
local CONTENT_L, CONTENT_R, CONTENT_T, CONTENT_B = 40, 36, 158, 68

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
	t:SetAllPoints()
	t:SetTexture(UI.TEX.close)
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 4, -4)
	hl:SetPoint("BOTTOMRIGHT", -4, 4)
	hl:SetColorTexture(1, 0.8, 0.5, 0.25)
	pcall(hl.SetBlendMode, hl, "ADD")
	b:SetScript("OnClick", onClick)
	return b
end
UI.CloseButton = CloseButton

-- 가죽 바탕 + 닳은 가장자리 (작은 창과 표지에 함께 쓴다)
local function LeatherBack(frame, tile, fixedW, fixedH)
	local L = UI.LEATHER
	local t
	if fixedW then
		-- 폭이 줄면 질감도 함께 눌리도록 반복 횟수를 고정한다 (넘어가는 표지용)
		t = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
		t:SetAllPoints()
		t:SetTexture(UI.TEX.leather, "REPEAT", "REPEAT")
		t:SetTexCoord(0, fixedW / tile, 0, fixedH / tile)
	else
		t = UI.Tiled(frame, "BACKGROUND", -7, UI.TEX.leather, tile, tile)
	end
	UI.Tint(t, L.cover)
	local wear = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
	wear:SetAllPoints()
	wear:SetTexture(UI.TEX.vignette)
	wear:SetVertexColor(0, 0, 0, 0.7)
	return t
end
UI.LeatherBack = LeatherBack

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
	-- ① 닳은 가죽 장정
	local coverShadow = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	coverShadow:SetPoint("TOPLEFT", 2, -4)
	coverShadow:SetPoint("BOTTOMRIGHT", 10, -12)
	coverShadow:SetColorTexture(0, 0, 0, 0.6)
	LeatherBack(f, 512)

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

	-- ③ 사다리꼴 가죽 탭 (고른 탭은 금빛)
	self.tabButtons = {}
	local tabW, tabOverlap = 182, -3
	local x = CONTENT_L + 2
	for _, tab in ipairs(UI.TABS) do
		local b = UI.Tab(body, tab.name, tab.key, function() UI:SelectTab(tab.id) end, nil, UI.ICON[tab.icon])
		b:SetWidth(tabW)
		b:SetPoint("BOTTOMLEFT", f, "TOPLEFT", x, -(CONTENT_T - 4))
		x = x + tabW - tabOverlap
		self.tabButtons[tab.id] = b
	end
	local tabRule = body:CreateTexture(nil, "ARTWORK")
	tabRule:SetPoint("TOPLEFT", f, "TOPLEFT", CONTENT_L - 6, -(CONTENT_T - 4))
	tabRule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(CONTENT_R - 6), -(CONTENT_T - 4))
	tabRule:SetHeight(2)
	UI.Gradient(tabRule, "VERTICAL", { 0.35, 0.22, 0.08, 0.9 }, { L.gold[1], L.gold[2], L.gold[3], 0.9 })

	-- ④ 두꺼운 금테와 모서리 장식, 가죽끈과 버클, 붉은 깃발, 제목 명판
	local trim = UI.GoldFrame(f, EDGE, BAR, CORNER, CORNER_OUT, body:GetFrameLevel() + 40)
	f.trim = trim
	for _, frac in ipairs({ 0.33, 0.55, 0.77 }) do
		local strap = trim:CreateTexture(nil, "ARTWORK", nil, 3)
		strap:SetSize(54, 47)
		strap:SetPoint("LEFT", f, "TOPLEFT", -14, -HEIGHT * frac)
		strap:SetTexture(UI.TEX.strap)
		strap:SetTexCoord(0.42, 1, 0, 1)
	end
	local banner = trim:CreateTexture(nil, "ARTWORK", nil, 4)
	banner:SetSize(62, 124)
	banner:SetPoint("TOP", f, "TOPLEFT", 150, -2)
	banner:SetTexture(UI.TEX.banner)
	local plaque = trim:CreateTexture(nil, "ARTWORK", nil, 5)
	plaque:SetSize(420, 210)
	plaque:SetPoint("TOP", f, "TOP", 0, 68)
	plaque:SetTexture(UI.TEX.plaque)
	f.plaque = plaque
	local brand = trim:CreateFontString(nil, "OVERLAY", UI.F.brand)
	brand:SetPoint("CENTER", plaque, "TOP", 0, -131)
	brand:SetText("BIG CHRONICLE")
	local title = trim:CreateFontString(nil, "OVERLAY", UI.F.label)
	title:SetPoint("TOP", brand, "BOTTOM", 0, -3)
	UI.OnLeather(title, L.sub)
	f.title = title
	for _, side in ipairs({ "LEFT", "RIGHT" }) do
		local laurel = trim:CreateTexture(nil, "ARTWORK", nil, 3)
		laurel:SetSize(92, 46)
		laurel:SetPoint("BOTTOM" .. side, f, "BOTTOM" .. side, side == "LEFT" and 96 or -96, 22)
		laurel:SetTexture(UI.TEX.laurel)
		if side == "LEFT" then laurel:SetTexCoord(1, 0, 0, 1) end
	end
	local close = CloseButton(trim, function() f:Hide() end, 34)
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -34, -34)

	-- ⑤ 아래쪽: 모험 요약과 단축키 안내
	local sub = trim:CreateFontString(nil, "OVERLAY", UI.F.small)
	sub:SetPoint("BOTTOM", f, "BOTTOM", 0, 46)
	sub:SetJustifyH("CENTER")
	UI.OnLeather(sub, L.text)
	f.subtitle = sub
	local hints = trim:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	hints:SetPoint("BOTTOM", f, "BOTTOM", 0, 30)
	UI.OnLeather(hints, L.muted)
	f.hints = hints

	-- ⑥ 창을 열 때 넘어가는 앞표지
	-- 책등(왼쪽 끝)을 축으로 돈다. 폭이 cos(각도)만큼 줄며 원근처럼 눌리고,
	-- 똑바로 선 뒤에는 표지 안쪽(면지)이 책 왼쪽으로 넘어가며 사라진다.
	local squish = {}
	local function Squish(region, w)
		region:SetWidth(w)
		squish[#squish + 1] = { region, w }
	end
	-- 넘어가는 표지의 금테: 무늬가 폭과 함께 눌리도록 반복 횟수를 고정한다
	local function FixedTrim(frame)
		local tile = BAR * 8
		local top = frame:CreateTexture(nil, "BORDER")
		top:SetTexture(UI.TEX.goldBar, "REPEAT", "REPEAT")
		top:SetPoint("TOPLEFT", 0, -EDGE); top:SetPoint("TOPRIGHT", 0, -EDGE); top:SetHeight(BAR)
		top:SetTexCoord(0, WIDTH / tile, 0, 1)
		local bot = frame:CreateTexture(nil, "BORDER")
		bot:SetTexture(UI.TEX.goldBar, "REPEAT", "REPEAT")
		bot:SetPoint("BOTTOMLEFT", 0, EDGE); bot:SetPoint("BOTTOMRIGHT", 0, EDGE); bot:SetHeight(BAR)
		bot:SetTexCoord(0, WIDTH / tile, 1, 0)
		local n = (HEIGHT - EDGE * 2) / tile
		local left = frame:CreateTexture(nil, "BORDER", nil, 1)
		left:SetTexture(UI.TEX.goldBar, "REPEAT", "REPEAT")
		left:SetPoint("TOPLEFT", 0, -EDGE); left:SetPoint("BOTTOMLEFT", 0, EDGE)
		left:SetTexCoord(0, 0, n, 0, 0, 1, n, 1)
		Squish(left, BAR)
		local right = frame:CreateTexture(nil, "BORDER", nil, 1)
		right:SetTexture(UI.TEX.goldBar, "REPEAT", "REPEAT")
		right:SetPoint("TOPRIGHT", 0, -EDGE); right:SetPoint("BOTTOMRIGHT", 0, EDGE)
		right:SetTexCoord(0, 1, n, 1, 0, 0, n, 0)
		Squish(right, BAR)
		for _, t in pairs(UI.Corners(frame, UI.TEX.corner, CORNER, -CORNER_OUT, nil, "OVERLAY", 2)) do Squish(t, CORNER) end
	end

	local flap = CreateFrame("Frame", nil, f)
	flap:SetPoint("TOPLEFT", f, "TOPLEFT")
	flap:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT")
	flap:SetWidth(WIDTH)
	flap:SetFrameLevel(trim:GetFrameLevel() + 20)
	LeatherBack(flap, 512, WIDTH, HEIGHT)
	FixedTrim(flap)
	local inner = UI.Outline(flap, { L.gold[1], L.gold[2], L.gold[3], 0.55 }, 44, "BORDER")
	local medal = flap:CreateTexture(nil, "ARTWORK")
	medal:SetHeight(230)
	Squish(medal, 230)
	medal:SetPoint("CENTER", 0, 44)
	medal:SetTexture(UI.TEX.medallion)
	local flapTitle = flap:CreateFontString(nil, "OVERLAY", UI.F.brand)
	flapTitle:SetPoint("TOP", medal, "BOTTOM", 0, -18)
	flapTitle:SetText(UI.Spaced("BIG CHRONICLE", 1))
	local flapRule = UI.Divider(flap, 300, L.gold)
	flapRule:SetPoint("TOP", flapTitle, "BOTTOM", 0, -10)
	Squish(flapRule, 300)
	-- 들릴수록 표지 끝이 그늘지고, 모서리가 빛을 받는다
	local flapShade = flap:CreateTexture(nil, "OVERLAY", nil, 6)
	flapShade:SetAllPoints()
	UI.Gradient(flapShade, "HORIZONTAL", { 0, 0, 0, 0.1 }, { 0, 0, 0, 0.7 })
	local flapRim = flap:CreateTexture(nil, "OVERLAY", nil, 7)
	flapRim:SetPoint("TOPRIGHT"); flapRim:SetPoint("BOTTOMRIGHT"); flapRim:SetWidth(3)
	flapRim:SetColorTexture(L.gold[1], L.gold[2], L.gold[3], 0.7)
	-- 아래 책장 위로 드리우는 그림자
	local flapCast = flap:CreateTexture(nil, "BACKGROUND", nil, -8)
	flapCast:SetPoint("TOPLEFT", flap, "TOPRIGHT")
	flapCast:SetPoint("BOTTOMLEFT", flap, "BOTTOMRIGHT")
	flapCast:SetWidth(1)
	UI.Gradient(flapCast, "HORIZONTAL", { 0, 0, 0, 0.6 }, { 0, 0, 0, 0 })

	-- 표지 안쪽: 가죽 테두리 안에 면지가 붙어 있다 (책 왼쪽 바깥으로 넘어간다)
	local inside = CreateFrame("Frame", nil, f)
	inside:SetPoint("TOPRIGHT", f, "TOPLEFT")
	inside:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT")
	inside:SetWidth(1)
	inside:SetFrameLevel(trim:GetFrameLevel() + 20)
	LeatherBack(inside, 512, WIDTH, HEIGHT)
	UI.Outline(inside, { 0, 0, 0, 1 }, 0)
	local endpaper = inside:CreateTexture(nil, "BORDER")
	endpaper:SetTexture(UI.TEX.panel)
	endpaper:SetVertexColor(C.page2[1] * 0.92, C.page2[2] * 0.88, C.page2[3] * 0.8)
	local endShade = inside:CreateTexture(nil, "OVERLAY", nil, 6)
	endShade:SetAllPoints()
	UI.Gradient(endShade, "HORIZONTAL", { 0, 0, 0, 0.7 }, { 0, 0, 0, 0.1 })
	local insideRim = inside:CreateTexture(nil, "OVERLAY", nil, 7)
	insideRim:SetPoint("TOPLEFT"); insideRim:SetPoint("BOTTOMLEFT"); insideRim:SetWidth(3)
	insideRim:SetColorTexture(L.gold[1], L.gold[2], L.gold[3], 0.5)
	inside:Hide()

	f.flap, f.flapTitle, f.flapRule, f.flapInside = flap, flapTitle, flapRule, inside
	-- theta: 0 = 덮인 표지, pi/2 = 책등 위에 곧게 선 표지, pi = 왼쪽으로 완전히 펼친 표지
	function f:PoseCover(theta)
		local c, sn = math.cos(theta), math.sin(theta)
		if c >= 0 then
			inside:Hide()
			flap:Show()
			flap:SetWidth(math.max(1, WIDTH * c))
			for _, it in ipairs(squish) do it[1]:SetWidth(math.max(1, it[2] * c)) end
			-- 글씨는 눌릴 수 없으니, 표지가 들리기 시작하면 금방 흐려진다
			local textA = math.max(0, 1 - theta / 0.55)
			flapTitle:SetAlpha(textA)
			flapRule:SetAlpha(textA)
			for i = 1, 4 do inner[i]:SetAlpha(textA) end
			flapShade:SetAlpha(0.1 + 0.9 * sn)
			flapRim:SetAlpha(sn)
			flapCast:SetWidth(math.max(1, 140 * sn * c * 2))
			flapCast:SetAlpha(math.min(1, c * 3))
			-- 창 위로 솟은 명판 장식은 표지가 들리면서 나타난다
			plaque:SetAlpha(math.min(1, theta / 0.9))
		else
			flap:Hide()
			inside:Show()
			plaque:SetAlpha(1)
			local k = -c
			inside:SetWidth(math.max(1, WIDTH * k))
			endpaper:ClearAllPoints()
			endpaper:SetPoint("TOPLEFT", 26 * k, -26)
			endpaper:SetPoint("BOTTOMRIGHT", -26 * k, 26)
			endShade:SetAlpha(0.1 + 0.9 * sn)
			insideRim:SetAlpha(sn)
			-- 왼쪽으로 눕기 시작하면 서서히 사라진다
			inside:SetAlpha(math.max(0, 1 - (theta - math.pi / 2) / (math.pi * 0.38)))
		end
	end
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
-- 창을 열 때 무거운 앞표지가 책등을 축으로 넘어가며 책이 펼쳐진다
function UI:Unroll()
	local f = self.frame
	if not f then return end
	local E = ns.Effects
	if not (ns.db and ns.db.effects) or not E then
		if E then E.Stop("main-open") end
		f.flap:Hide()
		f.flapInside:Hide()
		f.plaque:SetAlpha(1)
		UI.FadeIn(f, 0.2)
		return
	end
	f:SetAlpha(1)
	f:PoseCover(0)
	-- 잠깐 표지를 보여 준 뒤, 묵직하게 넘긴다 (끝까지 펼쳐지기 직전에 사라진다)
	E.Tween("main-open", 0.95, function(p)
		f:PoseCover(math.pi * 0.88 * E.Ease.inOut(p))
	end, function()
		f.flap:Hide()
		f.flapInside:Hide()
		f.plaque:SetAlpha(1)
	end, 0.25)
	E.Sound("open")
end

-- 책장을 넘기며 내용을 바꾼다. sheet: 넘어갈 양피지(탭이 만든 것), apply: 내용을 바꾸는 함수
function UI:TurnPage(sheet, dir, apply)
	local f = self.frame
	if not f or not f:IsShown() or not ns.Effects or not sheet then
		if apply then apply() end
		return
	end
	ns.Effects.TurnPage(sheet, dir, apply)
end

function UI:FinishTurn(sheet)
	if sheet and ns.Effects then ns.Effects.FinishTurn(sheet) end
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
	f.title:SetText(UI.Spaced(name .. "의 연대기", 1))
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
		local L = UI.LEATHER
		LeatherBack(f, 512)
		UI.GoldFrame(f, 4, 12, 64, 3)
		if UISpecialFrames then table.insert(UISpecialFrames, "BigChronicleExport") end

		local title = f:CreateFontString(nil, "OVERLAY", UI.F.header)
		title:SetPoint("TOP", 0, -26)
		title:SetText("모험 전기 내보내기")
		UI.OnLeather(title, L.title)
		local hint = f:CreateFontString(nil, "OVERLAY", UI.F.small)
		hint:SetPoint("TOP", title, "BOTTOM", 0, -6)
		hint:SetText("Ctrl+A 로 전체 선택한 뒤 Ctrl+C 로 복사하세요.")
		UI.OnLeather(hint, L.sub)
		local div = UI.Divider(f, 420, L.gold)
		div:SetPoint("TOP", hint, "BOTTOM", 0, -6)

		local close = CloseButton(f, function() f:Hide() end, 28)
		close:SetPoint("TOPRIGHT", -22, -22)
		close:SetFrameLevel(f:GetFrameLevel() + 10)

		local box = UI.Section(f)
		box:SetPoint("TOPLEFT", 30, -92)
		box:SetPoint("BOTTOMRIGHT", -30, 30)

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
