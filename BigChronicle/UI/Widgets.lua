-- BIG CHRONICLE :: UI 공용 위젯 / 테마
-- 납작하고 차분한 요즘 게임 UI: 왼쪽 가죽 내비게이션 + 넓은 종이 한 장.
-- 상자와 테두리 대신 여백·가는 선·글자 크기 차이로 구분하고, 강조색은 하나만 쓴다.
-- 표지와 속지는 실제 사진 질감, 글꼴은 게임 기본 글꼴. (출처는 Media/LICENSES.txt)

local ADDON, ns = ...
local UI = ns.UI or {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
UI.WHITE = WHITE
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
UI.MEDIA = MEDIA
local function M(name) return MEDIA .. name end
UI.TEX = {
	leather = M "Leather", paper = M "Paper", panel = M "Paper",
	seal = M "Seal", sealDex = M "SealDex", sealAch = M "SealAch",
	check = "Interface\\Buttons\\UI-CheckBox-Check",
	-- 효과 입자 (Kenney Particle Pack, CC0)
	dust = M "FX\\Star", glow = M "FX\\Glow", ink = M "FX\\Crumb", magic = M "FX\\Magic",
}
UI.ICON = setmetatable({}, { __index = function(_, k) return MEDIA .. "Icons\\" .. k end })

-- 가죽(왼쪽 내비게이션) 위 글씨 색 — 테마와 상관없이 같다
UI.LEATHER = {
	cover = { 0.56, 0.54, 0.52 },   -- 가죽 사진을 조금 어둡게
	text  = { 0.90, 0.87, 0.81 },
	sub   = { 0.72, 0.68, 0.61 },
	muted = { 0.54, 0.50, 0.44 },
	title = { 0.98, 0.95, 0.89 },
	accent = { 0.95, 0.72, 0.40 },
	gold  = { 0.95, 0.72, 0.40 },
	ink   = { 0.14, 0.11, 0.09 },
}

------------------------------------------------------------------------
-- 테마: 속지(페이지)의 색
------------------------------------------------------------------------
UI.THEMES = {
	light = {
		name = "밝은 속지",
		page   = { 0.975, 0.955, 0.915 },
		page2  = { 0.90, 0.88, 0.84 },
		edge   = { 0.20, 0.16, 0.12 },
		line   = { 0.20, 0.16, 0.12, 0.16 },   -- 가는 구분선
		shade  = { 0.20, 0.16, 0.12, 0.05 },
		fill   = { 0.20, 0.16, 0.12, 0.08 },   -- 버튼·입력칸 바탕
		text   = { 0.15, 0.13, 0.11 },
		sub    = { 0.37, 0.34, 0.30 },
		muted  = { 0.55, 0.51, 0.47 },
		title  = { 0.10, 0.085, 0.07 },
		accent = { 0.66, 0.30, 0.10 },         -- 구리빛 강조색
		onAccent = { 1.00, 0.98, 0.95 },
		hover  = { 0.20, 0.16, 0.12, 0.06 },
		sel    = { 0.66, 0.30, 0.10, 0.12 },
		bar    = { 0.72, 0.34, 0.11 },
		barBg  = { 0.20, 0.16, 0.12, 0.16 },
		creature = { 0.09, 0.32, 0.36 },
		rare   = { 0.42, 0.20, 0.55 },
		good   = { 0.20, 0.42, 0.16 },
		shadow = { 0, 0, 0, 0.5 },
		fontShadow = false,
		-- 기록에 저장된 강조색(어두운 배경용)을 밝은 종이 위에서 읽기 좋은 색으로 바꿔 보여 준다
		remap = {
			e6c27a = "8a5a12", ffd100 = "8f6200", ff9940 = "a2470d", ff6060 = "a31f17",
			["7fd4ff"] = "155f6e", ["9be27a"] = "2f6a1f", c58cff = "6b2fa0", d4af37 = "7a5410",
			e8d9b0 = "4a3520", ["9d9d9d"] = "6f6457", ["8a8070"] = "7d6f5c", ["60ff60"] = "2a7a2f",
			ff5050 = "a02020", f0e6c8 = "4a3520", ffffff = "2a1c0e",
		},
	},
	dark = {
		name = "어두운 속지",
		page   = { 0.205, 0.20, 0.195 },
		page2  = { 0.16, 0.155, 0.15 },
		edge   = { 0.85, 0.82, 0.76 },
		line   = { 1, 1, 1, 0.10 },
		shade  = { 1, 1, 1, 0.035 },
		fill   = { 1, 1, 1, 0.08 },
		text   = { 0.90, 0.88, 0.84 },
		sub    = { 0.70, 0.67, 0.62 },
		muted  = { 0.50, 0.48, 0.44 },
		title  = { 0.97, 0.95, 0.91 },
		accent = { 0.93, 0.69, 0.36 },
		onAccent = { 0.12, 0.10, 0.08 },
		hover  = { 1, 1, 1, 0.06 },
		sel    = { 0.93, 0.69, 0.36, 0.14 },
		bar    = { 0.93, 0.69, 0.36 },
		barBg  = { 1, 1, 1, 0.12 },
		creature = { 0.50, 0.80, 0.85 },
		rare   = { 0.78, 0.62, 0.97 },
		good   = { 0.56, 0.84, 0.45 },
		shadow = { 0, 0, 0, 0.7 },
		fontShadow = false,
		remap = {},
	},
}

UI.COL = {}
UI.F = {
	big     = "BigChronicleFontBig",      -- 큰 숫자
	title   = "BigChronicleFontTitle",    -- 화면 제목
	header  = "BigChronicleFontHeader",   -- 항목 제목
	heading = "BigChronicleFontHeading",  -- 강조색 소제목
	body    = "BigChronicleFontBody",
	small   = "BigChronicleFontSmall",
	tiny    = "BigChronicleFontTiny",
	label   = "BigChronicleFontLabel",    -- 작은 머리글
	button  = "BigChronicleFontButton",
	key     = "BigChronicleFontKey",
	tab     = "BigChronicleFontTab",      -- 왼쪽 내비게이션
	brand   = "BigChronicleFontBrand",
	railTitle = "BigChronicleFontRailTitle",
	brandSmall = "BigChronicleFontBrandSmall",
}

-- 게임 기본 글꼴을 바탕으로 크기와 색만 바꾼 글꼴을 만든다
local function MakeFont(name, baseNames, size, color, shadow)
	local font = _G[name] or (CreateFont and CreateFont(name))
	if not font then return end
	local base
	for _, b in ipairs(baseNames) do
		if _G[b] then base = _G[b] break end
	end
	if base and font.CopyFontObject then pcall(font.CopyFontObject, font, base) end
	if base and base.GetFont and font.SetFont then
		local ok, p, _, flags = pcall(base.GetFont, base)
		if ok and p then pcall(font.SetFont, font, p, size, flags or "") end
	end
	if font.SetTextColor then font:SetTextColor(color[1], color[2], color[3]) end
	if font.SetShadowOffset then
		if shadow then
			font:SetShadowOffset(1, -1)
			font:SetShadowColor(0, 0, 0, 0.85)
		else
			font:SetShadowOffset(0, 0)
			font:SetShadowColor(0, 0, 0, 0)
		end
	end
end

function UI:InitTheme()
	if self.themeReady then return end
	self.themeReady = true
	local id = (ns.db and ns.db.theme) or "light"
	local theme = self.THEMES[id] or self.THEMES.light
	self.theme = theme
	self.themeId = self.THEMES[id] and id or "light"
	for k, v in pairs(theme) do self.COL[k] = v end
	self.COL.paperTop, self.COL.paperBottom = theme.page, theme.page
	local C, L, sh = self.COL, self.LEATHER, theme.fontShadow
	local BASE, STRONG = { "GameFontHighlight", "GameFontNormal" }, { "GameFontNormalLarge", "GameFontNormal" }
	MakeFont(self.F.big,     STRONG, 26, C.title, sh)
	MakeFont(self.F.title,   STRONG, 21, C.title, sh)
	MakeFont(self.F.header,  STRONG, 16, C.title, sh)
	MakeFont(self.F.heading, BASE, 13, C.accent, sh)
	MakeFont(self.F.body,    BASE, 13, C.text, sh)
	MakeFont(self.F.small,   BASE, 11.5, C.sub, sh)
	MakeFont(self.F.tiny,    BASE, 10.5, C.muted, sh)
	MakeFont(self.F.label,   BASE, 11, C.muted, sh)
	MakeFont(self.F.button,  BASE, 12, C.text, sh)
	MakeFont(self.F.key,     BASE, 10, C.muted, sh)
	MakeFont(self.F.tab,     BASE, 13.5, L.text, true)
	MakeFont(self.F.brand,   BASE, 11, L.accent, true)
	MakeFont(self.F.railTitle, STRONG, 17, L.title, true)
	MakeFont(self.F.brandSmall, BASE, 10.5, L.muted, true)
end

-- 기록 문장 속 색 코드를 현재 테마에 맞춘다
function UI:Themed(text)
	local remap = self.theme and self.theme.remap
	if not remap or not next(remap) or type(text) ~= "string" then return text end
	return (text:gsub("|c[fF][fF](%x%x%x%x%x%x)", function(hex)
		local r = remap[hex:lower()]
		return "|cff" .. (r or hex)
	end))
end

-- 글자 사이를 띄운다
function UI.Spaced(s, gap)
	if type(s) ~= "string" then return s end
	local sep = string.rep(" ", gap or 1)
	local out = {}
	for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = ch end
	return table.concat(out, sep)
end

------------------------------------------------------------------------
-- 기본 도형
------------------------------------------------------------------------
local function Color(tex, c, a)
	tex:SetColorTexture(c[1], c[2], c[3], a or c[4] or 1)
end
UI.Color = Color

function UI.Tint(tex, c, a)
	tex:SetVertexColor(c[1], c[2], c[3], a or c[4] or 1)
end

local function TextColor(fs, c)
	fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
end
UI.TextColor = TextColor

-- 가죽 위에 놓는 글씨: 밝은 색 + 그림자
function UI.OnLeather(fs, c)
	c = c or UI.LEATHER.text
	fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
	if fs.SetShadowOffset then
		fs:SetShadowOffset(1, -1)
		fs:SetShadowColor(0, 0, 0, 0.85)
	end
end

-- 그라데이션 (버전 차이를 고려해 안전하게)
function UI.Gradient(tex, orientation, c1, c2)
	tex:SetTexture(WHITE)
	local a1, a2 = c1[4] or 1, c2[4] or 1
	if CreateColor then
		local ok = pcall(tex.SetGradient, tex, orientation, CreateColor(c1[1], c1[2], c1[3], a1), CreateColor(c2[1], c2[2], c2[3], a2))
		if ok then return end
	end
	if tex.SetGradientAlpha then
		local ok = pcall(tex.SetGradientAlpha, tex, orientation, c1[1], c1[2], c1[3], a1, c2[1], c2[2], c2[3], a2)
		if ok then return end
	end
	tex:SetColorTexture((c1[1] + c2[1]) / 2, (c1[2] + c2[2]) / 2, (c1[3] + c2[3]) / 2, (a1 + a2) / 2)
end

-- 반복 무늬 텍스처: 프레임 크기가 바뀌면 반복 횟수도 따라 바뀐다
function UI.Tiled(frame, layer, sub, path, tileW, tileH, target)
	local tex = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
	target = target or frame
	tex:SetAllPoints(target)
	tex:SetTexture(path, "REPEAT", "REPEAT")
	local function update()
		local w, h = target:GetWidth() or 0, target:GetHeight() or 0
		if w > 0 and h > 0 then tex:SetTexCoord(0, w / tileW, 0, h / tileH) end
	end
	target:HookScript("OnSizeChanged", update)
	update()
	tex.UpdateTiling = update
	return tex
end

-- 1px 테두리
function UI.Outline(frame, c, inset, layer, sub)
	inset = inset or 0
	local t = {}
	for i = 1, 4 do
		t[i] = frame:CreateTexture(nil, layer or "BORDER", nil, sub or 0)
		Color(t[i], c)
	end
	t[1]:SetPoint("TOPLEFT", inset, -inset); t[1]:SetPoint("TOPRIGHT", -inset, -inset); t[1]:SetHeight(1)
	t[2]:SetPoint("BOTTOMLEFT", inset, inset); t[2]:SetPoint("BOTTOMRIGHT", -inset, inset); t[2]:SetHeight(1)
	t[3]:SetPoint("TOPLEFT", inset, -inset); t[3]:SetPoint("BOTTOMLEFT", inset, inset); t[3]:SetWidth(1)
	t[4]:SetPoint("TOPRIGHT", -inset, -inset); t[4]:SetPoint("BOTTOMRIGHT", -inset, inset); t[4]:SetWidth(1)
	local function set(col)
		for i = 1, 4 do Color(t[i], col) end
	end
	if not frame.SetOutlineColor then
		frame.outline = t
		frame.SetOutlineColor = function(_, col) set(col) end
	end
	t.SetColor = function(_, col) set(col) end
	return t
end

-- 종이 한 장 (창·팝업·알림의 바탕): 종이 질감 + 부드러운 그림자 + 가는 테두리
function UI.Paper(frame, opts)
	opts = opts or {}
	local C = UI.COL
	if opts.shadow ~= false then
		for i = 1, 3 do
			local s = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
			s:SetPoint("TOPLEFT", -i, i - 3)
			s:SetPoint("BOTTOMRIGHT", i, -i - 3)
			s:SetColorTexture(0, 0, 0, 0.14)
		end
	end
	local paper = UI.Tiled(frame, "BACKGROUND", -6, UI.TEX.paper, 512, 512)
	UI.Tint(paper, opts.tint or C.page)
	frame.paper = paper
	UI.Outline(frame, { 0, 0, 0, 0.45 }, 0)
	return paper
end

-- 가로 구분선 (프레임)
function UI.Divider(parent, width, color)
	local C = UI.COL
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(width or 300, 1)
	local l = f:CreateTexture(nil, "ARTWORK")
	l:SetAllPoints()
	if color then
		l:SetColorTexture(color[1], color[2], color[3], 0.35)
	else
		Color(l, C.line)
	end
	f.line = l
	return f
end

-- 가로·세로 가는 선 (텍스처)
function UI.Rule(parent, alpha)
	local C = UI.COL
	local t = parent:CreateTexture(nil, "ARTWORK")
	t:SetColorTexture(C.line[1], C.line[2], C.line[3], C.line[4])
	t:SetHeight(1)
	return t
end

function UI.VRule(parent)
	local C = UI.COL
	local t = parent:CreateTexture(nil, "ARTWORK")
	t:SetColorTexture(C.line[1], C.line[2], C.line[3], C.line[4])
	t:SetWidth(1)
	return t
end

-- 구역: 테두리 없는 빈 자리. opts.card 면 아주 옅은 바탕을 깐다.
function UI.Section(parent, opts)
	opts = opts or {}
	local f = CreateFrame("Frame", nil, parent)
	if opts.card then
		local bg = f:CreateTexture(nil, "BACKGROUND", nil, -6)
		bg:SetAllPoints()
		Color(bg, UI.COL.shade)
		f.bg = bg
	end
	return f
end

function UI.Text(parent, font, color, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY", font or UI.F.body)
	if color then fs:SetTextColor(color[1], color[2], color[3]) end
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	return fs
end

-- 작은 머리글 (구역 이름)
function UI.Label(parent, text)
	local fs = parent:CreateFontString(nil, "OVERLAY", UI.F.label)
	fs:SetJustifyH("LEFT")
	fs:SetText(text or "")
	return fs
end

-- 아이콘 둘레의 가는 테두리
function UI.FrameIcon(icon, pad, parent)
	parent = parent or icon:GetParent()
	local h = CreateFrame("Frame", nil, parent)
	h:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
	h:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
	UI.Outline(h, { 0, 0, 0, 0.7 }, 0)
	return h
end

------------------------------------------------------------------------
-- 버튼: 테두리 없는 납작한 버튼
--   기본: 옅은 바탕 / style "primary"(또는 "red"): 강조색 바탕 / 선택되면 강조색 바탕
------------------------------------------------------------------------
function UI.Button(parent, text, w, h, onClick, key, style)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w or 80, h or 26)
	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	b.bg = bg
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	Color(hl, C.hover)
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.button)
	fs:SetPoint("CENTER", 0, 0)
	b:SetFontString(fs)
	b:SetText(text or "")
	b.label = fs
	local primary = style == "primary" or style == "red"
	function b:SetSelected(on)
		self.selected = on
		if on or primary then
			bg:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.95)
			TextColor(fs, C.onAccent)
		else
			Color(bg, C.fill)
			TextColor(fs, C.text)
		end
	end
	b:SetSelected(false)
	if onClick then b:SetScript("OnClick", onClick) end
	b:HookScript("OnEnable", function(self) self:SetAlpha(1) end)
	b:HookScript("OnDisable", function(self) self:SetAlpha(0.4) end)
	return b
end

-- 단축키 표시 (작고 흐린 글씨)
function UI.KeyBadge(parent, key)
	local fs = parent:CreateFontString(nil, "OVERLAY", UI.F.key)
	fs:SetText(key)
	function fs:SetKey(k) self:SetText(k) end
	return fs
end

-- 왼쪽 내비게이션의 한 줄 (가죽 위): 아이콘 + 이름. 고르면 밝아지고 왼쪽에 강조색 띠.
function UI.RailItem(parent, text, key, onClick, icon)
	local L = UI.LEATHER
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(40)
	local sel = b:CreateTexture(nil, "BACKGROUND")
	sel:SetAllPoints()
	UI.Gradient(sel, "HORIZONTAL", { 1, 1, 1, 0.10 }, { 1, 1, 1, 0.02 })
	local bar = b:CreateTexture(nil, "ARTWORK")
	bar:SetPoint("TOPLEFT", 0, 0); bar:SetPoint("BOTTOMLEFT", 0, 0); bar:SetWidth(3)
	Color(bar, L.accent)
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.05)
	local ic = b:CreateTexture(nil, "ARTWORK")
	ic:SetSize(18, 18)
	ic:SetPoint("LEFT", 22, 0)
	if icon then ic:SetTexture(icon) end
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.tab)
	fs:SetPoint("LEFT", ic, "RIGHT", 12, 0)
	fs:SetText(text)
	b.label = fs
	local num = b:CreateFontString(nil, "OVERLAY", UI.F.brandSmall)
	num:SetPoint("RIGHT", -16, 0)
	num:SetText(key or "")
	b:SetScript("OnClick", onClick)
	function b:SetSelected(on)
		self.selected = on
		sel:SetShown(on and true or false)
		bar:SetShown(on and true or false)
		TextColor(fs, on and L.title or L.sub)
		local c = on and L.accent or L.muted
		ic:SetVertexColor(c[1], c[2], c[3], 1)
	end
	b:SetSelected(false)
	return b
end
UI.Tab = UI.RailItem

-- 목록의 한 줄 (종이 위): 고르면 옅은 강조색 바탕과 왼쪽 띠
function UI.NavRow(parent, height)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(height or 26)
	local sel = b:CreateTexture(nil, "BACKGROUND")
	sel:SetAllPoints()
	Color(sel, C.sel)
	sel:Hide()
	local bar = b:CreateTexture(nil, "ARTWORK")
	bar:SetPoint("TOPLEFT", 0, 0); bar:SetPoint("BOTTOMLEFT", 0, 0); bar:SetWidth(2)
	Color(bar, C.accent)
	bar:Hide()
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	Color(hl, C.hover)
	local label = UI.Text(b, UI.F.body)
	label:SetPoint("LEFT", 12, 0)
	label:SetJustifyV("MIDDLE")
	label:SetWordWrap(false)
	b.label = label
	local right = UI.Text(b, UI.F.small, C.muted)
	right:SetPoint("RIGHT", -10, 0)
	right:SetJustifyH("RIGHT")
	right:SetJustifyV("MIDDLE")
	b.right = right
	label:SetPoint("RIGHT", right, "LEFT", -6, 0)
	function b:SetSelected(on)
		self.selected = on
		sel:SetShown(on and true or false)
		bar:SetShown(on and true or false)
		TextColor(label, on and C.title or C.text)
	end
	function b:SetDim() TextColor(label, C.muted) end
	b:SetScript("OnClick", function(self, button)
		if self.onClick then self.onClick(self, button) end
	end)
	return b
end

function UI.Tooltip(frame, title, body)
	frame:HookScript("OnEnter", function(self)
		if not GameTooltip then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(type(title) == "function" and title(self) or title, 1, 0.85, 0.4)
		local b = type(body) == "function" and body(self) or body
		if b then GameTooltip:AddLine(b, 1, 1, 1, true) end
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

------------------------------------------------------------------------
-- 체크박스: 가는 네모 칸. 켜면 안쪽이 강조색으로 채워진다.
------------------------------------------------------------------------
function UI.Check(parent, label, get, set, desc)
	local C = UI.COL
	local cb = CreateFrame("Button", nil, parent)
	cb:SetSize(14, 14)
	UI.Outline(cb, { C.edge[1], C.edge[2], C.edge[3], 0.5 })
	local mark = cb:CreateTexture(nil, "ARTWORK")
	mark:SetPoint("TOPLEFT", 3, -3)
	mark:SetPoint("BOTTOMRIGHT", -3, 3)
	Color(mark, C.accent)
	local hl = cb:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	Color(hl, C.hover)
	local fs = UI.Text(cb, UI.F.body)
	fs:SetPoint("LEFT", cb, "RIGHT", 8, 0)
	fs:SetJustifyV("MIDDLE")
	fs:SetText(label)
	cb.label = fs
	if desc then
		local d = UI.Text(cb, UI.F.small, C.muted)
		d:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -3)
		d:SetText(desc)
		cb.desc = d
	end
	cb.checked = false
	function cb:SetChecked(v)
		self.checked = v and true or false
		mark:SetShown(self.checked)
	end
	function cb:GetChecked() return self.checked end
	cb.Sync = function(self) self:SetChecked(get()) end
	cb:SetScript("OnShow", cb.Sync)
	cb:SetScript("OnClick", function(self)
		self:SetChecked(not self.checked)
		set(self.checked)
	end)
	local hit = CreateFrame("Button", nil, cb)
	hit:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
	hit:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2, -2)
	hit:SetScript("OnClick", function() cb:Click() end)
	cb:SetChecked(false)
	return cb
end

------------------------------------------------------------------------
-- 스크롤 영역 (마우스 휠 + 가느다란 손잡이)
------------------------------------------------------------------------
function UI.Scroll(parent)
	local C = UI.COL
	local sf = CreateFrame("ScrollFrame", nil, parent)
	local child = CreateFrame("Frame", nil, sf)
	child:SetSize(10, 10)
	sf:SetScrollChild(child)
	sf.child = child

	local bar = CreateFrame("Slider", nil, sf)
	bar:SetOrientation("VERTICAL")
	bar:SetWidth(8)
	bar:SetPoint("TOPLEFT", sf, "TOPRIGHT", 4, 0)
	bar:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 4, 0)
	local thumb = bar:CreateTexture(nil, "OVERLAY")
	thumb:SetColorTexture(C.edge[1], C.edge[2], C.edge[3], 0.28)
	thumb:SetSize(3, 48)
	bar:SetThumbTexture(thumb)
	bar:SetMinMaxValues(0, 0)
	bar:SetValue(0)
	bar:SetValueStep(1)
	bar:SetScript("OnValueChanged", function(_, v) sf:SetVerticalScroll(v) end)
	sf.bar = bar

	sf:EnableMouseWheel(true)
	sf:SetScript("OnMouseWheel", function(_, delta)
		local lo, hi = bar:GetMinMaxValues()
		local v = (bar:GetValue() or 0) - delta * 48
		if v < lo then v = lo elseif v > hi then v = hi end
		bar:SetValue(v)
	end)
	sf:SetScript("OnSizeChanged", function(self, w)
		if w and w > 0 then child:SetWidth(w) end
		self:UpdateRange()
	end)

	function sf:UpdateRange()
		local range = math.max(0, (child:GetHeight() or 0) - (self:GetHeight() or 0))
		bar:SetMinMaxValues(0, range)
		if (bar:GetValue() or 0) > range then bar:SetValue(range) end
		bar:SetShown(range > 0)
		self:SetVerticalScroll(math.min(bar:GetValue() or 0, range))
	end
	function sf:SetContentHeight(h)
		child:SetHeight(math.max(1, h))
		self:UpdateRange()
	end
	function sf:ScrollToTop() bar:SetValue(0) end
	function sf:ScrollToBottom()
		local _, hi = bar:GetMinMaxValues()
		bar:SetValue(hi or 0)
	end
	function sf:ScrollTo(y)
		local lo, hi = bar:GetMinMaxValues()
		local v = y or 0
		if v < lo then v = lo elseif v > hi then v = hi end
		bar:SetValue(v)
	end
	function sf:ScrollBy(dy)
		local lo, hi = bar:GetMinMaxValues()
		local v = (bar:GetValue() or 0) + dy
		if v < lo then v = lo elseif v > hi then v = hi end
		bar:SetValue(v)
	end
	return sf
end

------------------------------------------------------------------------
-- 페이드 인 / 타자기 효과
------------------------------------------------------------------------
local animator = CreateFrame("Frame")
animator:Hide()
local fades, typing = {}, {}

local function Utf8Prefix(s, n)
	local count, i, len = 0, 1, #s
	while i <= len do
		local b = s:byte(i)
		local size = b < 0x80 and 1 or (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or (b >= 0xC0 and 2) or 1
		count = count + 1
		if count > n then return s:sub(1, i - 1) end
		i = i + size
	end
	return s
end

local function Utf8Len(s)
	local n = 0
	for i = 1, #s do
		local b = s:byte(i)
		if b < 0x80 or b >= 0xC0 then n = n + 1 end
	end
	return n
end

animator:SetScript("OnUpdate", function(self, elapsed)
	local busy = false
	for region, job in pairs(fades) do
		job.t = job.t + elapsed
		local a = job.t <= 0 and 0 or math.min(1, job.t / job.dur)
		region:SetAlpha(a)
		if a >= 1 then fades[region] = nil else busy = true end
	end
	for fs, job in pairs(typing) do
		job.t = job.t + elapsed
		local n = math.floor(math.max(0, job.t) * job.cps)
		if n >= job.len then
			fs:SetText(job.full)
			typing[fs] = nil
		else
			if n ~= job.shown then
				job.shown = n
				fs:SetText(Utf8Prefix(job.full, n))
			end
			busy = true
		end
	end
	if not busy then self:Hide() end
end)

function UI.FadeIn(region, dur, delay)
	if not region then return end
	region:SetAlpha(0)
	fades[region] = { t = -(delay or 0), dur = dur or 0.25 }
	animator:Show()
end

-- 진행 중인 페이드를 모두 끝낸다
function UI.FinishFades()
	for region in pairs(fades) do region:SetAlpha(1) end
	wipe(fades)
end

function UI.CancelFade(region)
	if fades[region] then
		fades[region] = nil
		region:SetAlpha(1)
	end
end

-- 글자가 한 자씩 써지는 효과 (색 코드가 없는 문장에만 사용)
-- 반환값: 다 써지기까지 걸리는 시간(초)
function UI.Typewrite(fs, text, cps, delay)
	if not ns.db or ns.db.typewriter == false then
		fs:SetText(text)
		return 0
	end
	local job = { full = text, len = Utf8Len(text), t = -(delay or 0), cps = cps or 90, shown = -1 }
	typing[fs] = job
	fs:SetText("")
	animator:Show()
	return job.len / job.cps
end

function UI.IsTyping()
	return next(typing) ~= nil
end

function UI.FinishTyping()
	for fs, job in pairs(typing) do fs:SetText(job.full) end
	wipe(typing)
end

function UI.CancelTyping(fs)
	local job = typing[fs]
	if job then
		typing[fs] = nil
		fs:SetText(job.full)
	end
end

------------------------------------------------------------------------
-- 재사용 풀
------------------------------------------------------------------------
function UI.Pool(create)
	local pool = { items = {}, used = 0 }
	function pool:Acquire()
		self.used = self.used + 1
		local it = self.items[self.used]
		if not it then
			it = create()
			self.items[self.used] = it
		end
		it:Show()
		return it
	end
	function pool:ReleaseAll()
		for i = 1, #self.items do
			local it = self.items[i]
			UI.CancelFade(it)
			if typing[it] then typing[it] = nil end
			it:Hide()
		end
		self.used = 0
	end
	return pool
end

------------------------------------------------------------------------
-- 진행 막대: 가늘고 납작한 막대. 글씨(bar.text)는 막대 오른쪽 위에 놓인다.
------------------------------------------------------------------------
function UI.Bar(parent, w, h)
	local C = UI.COL
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetSize(w or 100, h or 4)
	bar:SetStatusBarTexture(WHITE)
	bar:SetStatusBarColor(C.bar[1], C.bar[2], C.bar[3], 1)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, C.barBg)
	local text = bar:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	text:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 4)
	text:SetJustifyH("RIGHT")
	TextColor(text, C.sub)
	bar.text = text
	return bar
end

------------------------------------------------------------------------
-- 입력창: 옅은 바탕에 밑줄 하나. 글을 쓰는 동안 밑줄이 강조색으로 바뀐다.
------------------------------------------------------------------------
function UI.EditBox(parent, w, h, placeholder)
	local C = UI.COL
	local eb = CreateFrame("EditBox", nil, parent)
	eb:SetSize(w or 200, h or 26)
	eb:SetAutoFocus(false)
	eb:SetFontObject(UI.F.body)
	eb:SetTextColor(C.text[1], C.text[2], C.text[3])
	eb:SetTextInsets(10, 8, 2, 2)
	eb:SetMaxLetters(240)
	local bg = eb:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, C.fill)
	local under = eb:CreateTexture(nil, "ARTWORK")
	under:SetPoint("BOTTOMLEFT", 0, 0); under:SetPoint("BOTTOMRIGHT", 0, 0)
	under:SetHeight(1)
	under:SetColorTexture(C.edge[1], C.edge[2], C.edge[3], 0.35)
	local ph = UI.Text(eb, UI.F.small, C.muted)
	ph:SetPoint("LEFT", 11, 0)
	ph:SetJustifyV("MIDDLE")
	ph:SetText(placeholder or "")
	eb.placeholder = ph
	local function sync(self)
		local t = self:GetText()
		ph:SetShown((t == nil or t == "") and not self:HasFocus())
	end
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	eb:SetScript("OnEditFocusGained", function(self) Color(under, C.accent, 1); under:SetHeight(2); sync(self) end)
	eb:SetScript("OnEditFocusLost", function(self) under:SetColorTexture(C.edge[1], C.edge[2], C.edge[3], 0.35); under:SetHeight(1); sync(self) end)
	eb:HookScript("OnTextChanged", sync)
	eb.SyncPlaceholder = sync
	return eb
end
