-- BIG CHRONICLE :: UI 공용 위젯 / 테마
-- 고서(古書) 스타일: 무두질한 가죽 장정, 놋쇠 모서리, 금박 선, 바랜 양피지, 명조 제목, 잉크.
-- 질감·문장·글꼴은 Media 폴더의 무료 에셋을 쓴다 (출처는 Media/LICENSES.txt).

local ADDON, ns = ...
local UI = ns.UI or {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
UI.WHITE = WHITE
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
UI.MEDIA = MEDIA
UI.TEX = {
	paper = MEDIA .. "Parchment", leather = MEDIA .. "Leather", vignette = MEDIA .. "Vignette",
	corner = MEDIA .. "Corner", band = MEDIA .. "SpineBand", ornCorner = MEDIA .. "OrnCorner",
	fleuron = MEDIA .. "Fleuron", emblem = MEDIA .. "Emblem", dust = MEDIA .. "Dust",
	check = MEDIA .. "Check", ink = MEDIA .. "Ink", ribbon = MEDIA .. "Ribbon",
	seal = MEDIA .. "Seal", sealDex = MEDIA .. "SealDex", sealAch = MEDIA .. "SealAch",
}
UI.ICON = setmetatable({}, { __index = function(_, k) return MEDIA .. "Icons\\" .. k end })
UI.SERIF_FONT = MEDIA .. "Fonts\\NanumMyeongjo-ExtraBold.ttf"

------------------------------------------------------------------------
-- 테마
------------------------------------------------------------------------
UI.THEMES = {
	light = {
		name = "양피지",
		page   = { 0.95, 0.89, 0.76 },   -- 양피지
		page2  = { 0.86, 0.78, 0.63 },   -- 한 단 짙은 양피지 (칸)
		cover  = { 0.34, 0.17, 0.10 },   -- 소가죽 장정
		coverDark = { 0.12, 0.06, 0.035 },
		gold   = { 0.86, 0.70, 0.40 },   -- 금박
		goldDim = { 0.62, 0.48, 0.25 },
		burn   = { 0.36, 0.21, 0.09 },   -- 그을린 가장자리
		edge   = { 0.30, 0.19, 0.11 },   -- 잉크 테두리
		line   = { 0.34, 0.22, 0.12, 0.55 },
		shade  = { 0.35, 0.22, 0.10, 0.07 },
		text   = { 0.15, 0.10, 0.06 },
		sub    = { 0.33, 0.24, 0.15 },
		muted  = { 0.49, 0.40, 0.29 },
		title  = { 0.19, 0.09, 0.04 },   -- 짙은 세피아 잉크
		accent = { 0.52, 0.11, 0.07 },   -- 검붉은 잉크
		hover  = { 0.42, 0.25, 0.10, 0.09 },
		sel    = { 0.42, 0.22, 0.08, 0.17 },
		bar    = { 0.50, 0.13, 0.08 },
		barBg  = { 0.30, 0.18, 0.08, 0.12 },
		creature = { 0.10, 0.30, 0.32 },
		rare   = { 0.40, 0.15, 0.48 },
		good   = { 0.20, 0.36, 0.12 },
		shadow = { 0, 0, 0, 0.55 },
		vignette = 0.5,
		fontShadow = false,
		-- 기록에 저장된 강조색(어두운 배경용)을 양피지 위에서 읽기 좋은 잉크색으로 바꿔 보여 준다
		remap = {
			e6c27a = "8a5a12", ffd100 = "8f6200", ff9940 = "a2470d", ff6060 = "a31f17",
			["7fd4ff"] = "155f6e", ["9be27a"] = "2f6a1f", c58cff = "6b2fa0", d4af37 = "7a5410",
			e8d9b0 = "4a3520", ["9d9d9d"] = "6f6457", ["8a8070"] = "7d6f5c", ["60ff60"] = "2a7a2f",
			ff5050 = "a02020", f0e6c8 = "4a3520", ffffff = "2a1c0e",
		},
	},
	dark = {
		name = "흑단",
		page   = { 0.23, 0.21, 0.19 },
		page2  = { 0.17, 0.155, 0.14 },
		cover  = { 0.12, 0.105, 0.095 },
		coverDark = { 0.04, 0.035, 0.03 },
		gold   = { 0.82, 0.67, 0.40 },
		goldDim = { 0.55, 0.44, 0.26 },
		burn   = { 0, 0, 0 },
		edge   = { 0.62, 0.52, 0.38 },
		line   = { 0.72, 0.60, 0.42, 0.35 },
		shade  = { 1, 1, 1, 0.035 },
		text   = { 0.90, 0.85, 0.75 },
		sub    = { 0.74, 0.68, 0.58 },
		muted  = { 0.55, 0.50, 0.42 },
		title  = { 0.90, 0.76, 0.48 },
		accent = { 0.88, 0.45, 0.34 },
		hover  = { 1, 0.85, 0.5, 0.06 },
		sel    = { 0.85, 0.65, 0.30, 0.15 },
		bar    = { 0.70, 0.30, 0.20 },
		barBg  = { 0, 0, 0, 0.35 },
		creature = { 0.50, 0.80, 0.85 },
		rare   = { 0.78, 0.60, 0.95 },
		good   = { 0.55, 0.85, 0.45 },
		shadow = { 0, 0, 0, 0.7 },
		vignette = 0.65,
		fontShadow = true,
		remap = {},
	},
}

UI.COL = {}
UI.F = {
	title   = "BigChronicleFontTitle",
	header  = "BigChronicleFontHeader",
	heading = "BigChronicleFontHeading",
	body    = "BigChronicleFontBody",
	small   = "BigChronicleFontSmall",
	tiny    = "BigChronicleFontTiny",
	button  = "BigChronicleFontButton",
	key     = "BigChronicleFontKey",
	label   = "BigChronicleFontLabel",
}

local function MakeFont(name, baseNames, size, color, shadow, path)
	local font = _G[name] or (CreateFont and CreateFont(name))
	if not font then return end
	local base
	for _, b in ipairs(baseNames) do
		if _G[b] then base = _G[b] break end
	end
	if base and font.CopyFontObject then pcall(font.CopyFontObject, font, base) end
	local applied = false
	if path and font.SetFont then
		-- 명조 글꼴을 못 읽으면 게임 기본 글꼴을 그대로 쓴다
		local ok, res = pcall(font.SetFont, font, path, size, "")
		applied = ok and res ~= false
	end
	if not applied and base and base.GetFont and font.SetFont then
		local ok, p, _, flags = pcall(base.GetFont, base)
		if ok and p then pcall(font.SetFont, font, p, size, flags or "") end
	end
	if font.SetTextColor then font:SetTextColor(color[1], color[2], color[3]) end
	if font.SetShadowOffset then
		if shadow then
			font:SetShadowOffset(1, -1)
			font:SetShadowColor(0, 0, 0, 0.8)
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
	-- 예전 이름을 쓰는 코드를 위해
	self.COL.paperTop, self.COL.paperBottom = theme.page, theme.page
	local C, sh, SERIF = self.COL, theme.fontShadow, self.SERIF_FONT
	MakeFont(self.F.title,   { "QuestTitleFont", "GameFontNormalHuge" }, 23, C.title, sh, SERIF)
	MakeFont(self.F.header,  { "QuestTitleFont", "GameFontNormalLarge" }, 18, C.title, sh, SERIF)
	MakeFont(self.F.heading, { "GameFontNormal" }, 14, C.accent, sh, SERIF)
	MakeFont(self.F.button,  { "GameFontNormal" }, 12, C.gold, true, SERIF)
	MakeFont(self.F.label,   { "GameFontNormalSmall" }, 11, C.muted, sh, SERIF)
	MakeFont(self.F.body,    { "QuestFont", "GameFontHighlight" }, 13, C.text, sh)
	MakeFont(self.F.small,   { "GameFontHighlightSmall" }, 11, C.sub, sh)
	MakeFont(self.F.tiny,    { "GameFontHighlightSmall" }, 10, C.muted, sh)
	MakeFont(self.F.key,     { "GameFontHighlightSmall" }, 10, C.gold, true)
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

-- 글자 사이를 띄운다 (금박 제목·머리글용)
function UI.Spaced(s, gap)
	if type(s) ~= "string" then return s end
	local sep = string.rep(" ", gap or 1)
	local out = {}
	for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		out[#out + 1] = ch
	end
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

-- 왼쪽 위 기준 텍스처를 네 모서리에 뒤집어 붙인다
local CORNER_COORDS = {
	TOPLEFT = { 0, 1, 0, 1 }, TOPRIGHT = { 1, 0, 0, 1 },
	BOTTOMLEFT = { 0, 1, 1, 0 }, BOTTOMRIGHT = { 1, 0, 1, 0 },
}
function UI.Corners(frame, path, size, inset, color, layer, sub)
	local out = {}
	for point, tc in pairs(CORNER_COORDS) do
		local t = frame:CreateTexture(nil, layer or "OVERLAY", nil, sub or 0)
		t:SetSize(size, size)
		local dx = point:find("LEFT") and (inset or 0) or -(inset or 0)
		local dy = point:find("TOP") and -(inset or 0) or (inset or 0)
		t:SetPoint(point, frame, point, dx, dy)
		t:SetTexture(path)
		t:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
		if color then UI.Tint(t, color) end
		out[point] = t
	end
	return out
end

-- 양피지 한 장: 질감 + 그을린 가장자리 + 그림자
function UI.Paper(frame, opts)
	opts = opts or {}
	local C = UI.COL
	if opts.shadow ~= false then
		local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		shadow:SetPoint("TOPLEFT", 2, -3)
		shadow:SetPoint("BOTTOMRIGHT", 5, -6)
		Color(shadow, { 0, 0, 0, opts.shadow or 0.35 })
	end
	local paper = UI.Tiled(frame, "BACKGROUND", -6, UI.TEX.paper, opts.tile or 512, opts.tile or 512)
	UI.Tint(paper, opts.tint or C.page)
	local vig = frame:CreateTexture(nil, "BACKGROUND", nil, -5)
	vig:SetAllPoints()
	vig:SetTexture(UI.TEX.vignette)
	UI.Tint(vig, C.burn, opts.vignette or C.vignette)
	frame.vignette = vig
	UI.Outline(frame, { C.edge[1], C.edge[2], C.edge[3], 0.45 }, 0)
	return paper
end

-- 장식 구분선: 양끝이 흐려지는 잉크선 가운데에 백합 문장
function UI.Divider(parent, width, color)
	local C = UI.COL
	color = color or C.edge
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(width or 300, 14)
	local orn = f:CreateTexture(nil, "ARTWORK")
	orn:SetSize(14, 14)
	orn:SetPoint("CENTER")
	orn:SetTexture(UI.TEX.fleuron)
	UI.Tint(orn, color, 0.85)
	local l = f:CreateTexture(nil, "ARTWORK")
	l:SetHeight(1)
	l:SetPoint("LEFT", 0, 0)
	l:SetPoint("RIGHT", orn, "LEFT", -6, 0)
	UI.Gradient(l, "HORIZONTAL", { color[1], color[2], color[3], 0 }, { color[1], color[2], color[3], 0.7 })
	local r = f:CreateTexture(nil, "ARTWORK")
	r:SetHeight(1)
	r:SetPoint("LEFT", orn, "RIGHT", 6, 0)
	r:SetPoint("RIGHT", 0, 0)
	UI.Gradient(r, "HORIZONTAL", { color[1], color[2], color[3], 0.7 }, { color[1], color[2], color[3], 0 })
	f.line, f.orn = l, orn
	return f
end

-- 가는 잉크선
function UI.Rule(parent, alpha)
	local t = parent:CreateTexture(nil, "ARTWORK")
	local C = UI.COL
	t:SetColorTexture(C.line[1], C.line[2], C.line[3], alpha or C.line[4] or 0.5)
	t:SetHeight(1)
	return t
end

-- 칸: 한 단 짙은 양피지에 잉크 이중 테두리와 모서리 장식
function UI.Section(parent, opts)
	opts = opts or {}
	local C = UI.COL
	local f = CreateFrame("Frame", nil, parent)
	local bg = f:CreateTexture(nil, "BACKGROUND", nil, -6)
	bg:SetAllPoints()
	Color(bg, opts.tint or C.page2, opts.alpha or 0.45)
	f.bg = bg
	local inner = f:CreateTexture(nil, "BACKGROUND", nil, -5)
	inner:SetPoint("TOPLEFT", 1, -1); inner:SetPoint("BOTTOMRIGHT", -1, 1)
	UI.Gradient(inner, "VERTICAL", { 0, 0, 0, 0 }, { C.shade[1], C.shade[2], C.shade[3], (C.shade[4] or 0.07) * 1.6 })
	UI.Outline(f, { C.edge[1], C.edge[2], C.edge[3], 0.55 }, 0)
	UI.Outline(f, { C.edge[1], C.edge[2], C.edge[3], 0.22 }, 3)
	f.corners = UI.Corners(f, UI.TEX.ornCorner, 18, -1, { C.edge[1], C.edge[2], C.edge[3], 0.75 }, "BORDER", 2)
	return f
end

function UI.Text(parent, font, color, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY", font or UI.F.body)
	if color then fs:SetTextColor(color[1], color[2], color[3]) end
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	return fs
end

------------------------------------------------------------------------
-- 단축키 배지  [1]  (가죽 조각에 금박 숫자)
------------------------------------------------------------------------
function UI.KeyBadge(parent, key)
	local C = UI.COL
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(18, 18)
	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, C.coverDark, 0.85)
	UI.Outline(f, { C.gold[1], C.gold[2], C.gold[3], 0.55 })
	local fs = f:CreateFontString(nil, "OVERLAY", UI.F.key)
	fs:SetPoint("CENTER", 0, 0)
	fs:SetText(key)
	f.text = fs
	function f:SetKey(k)
		fs:SetText(k)
		local w = (fs:GetStringWidth() or 8) + 10
		self:SetWidth(math.max(18, w))
	end
	f:SetKey(key)
	return f
end

------------------------------------------------------------------------
-- 버튼: 가죽 명판에 금박 글씨. 마우스를 올리면 금테가 밝아진다.
------------------------------------------------------------------------
local function LeatherPlate(b, C)
	local shadow = b:CreateTexture(nil, "BACKGROUND", nil, -3)
	shadow:SetPoint("TOPLEFT", 1, -2)
	shadow:SetPoint("BOTTOMRIGHT", 2, -2)
	Color(shadow, { 0, 0, 0, 0.35 })
	local bg = UI.Tiled(b, "BACKGROUND", -2, UI.TEX.leather, 128, 128)
	UI.Tint(bg, C.cover)
	local gloss = b:CreateTexture(nil, "BACKGROUND", nil, -1)
	gloss:SetAllPoints()
	UI.Gradient(gloss, "VERTICAL", { 0, 0, 0, 0.25 }, { 1, 0.9, 0.7, 0.10 })
	UI.Outline(b, { C.coverDark[1], C.coverDark[2], C.coverDark[3], 1 }, 0)
	local inner = UI.Outline(b, { C.gold[1], C.gold[2], C.gold[3], 0.45 }, 2, "BORDER", 1)
	return bg, inner
end

function UI.Button(parent, text, w, h, onClick, key)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w or 80, h or 24)
	local bg, inner = LeatherPlate(b, C)
	b.bg = bg
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 3, -3)
	hl:SetPoint("BOTTOMRIGHT", -3, 3)
	hl:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.12)
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.button)
	fs:SetPoint("CENTER", key and 9 or 0, 0)
	b:SetFontString(fs)
	b:SetText(text or "")
	b.label = fs
	if key then
		local badge = UI.KeyBadge(b, key)
		badge:SetPoint("RIGHT", fs, "LEFT", -6, 0)
		b.badge = badge
	end
	if onClick then b:SetScript("OnClick", onClick) end
	local mark = b:CreateTexture(nil, "ARTWORK")
	mark:SetPoint("TOPLEFT", 3, -3)
	mark:SetPoint("BOTTOMRIGHT", -3, 3)
	UI.Gradient(mark, "VERTICAL", { C.gold[1], C.gold[2], C.gold[3], 0.05 }, { C.gold[1], C.gold[2], C.gold[3], 0.22 })
	mark:Hide()
	function b:SetSelected(on)
		self.selected = on
		mark:SetShown(on and true or false)
		inner:SetColor({ C.gold[1], C.gold[2], C.gold[3], on and 1 or 0.45 })
		local k = on and 1.12 or 0.92
		fs:SetTextColor(math.min(1, C.gold[1] * k), math.min(1, C.gold[2] * k), math.min(1, C.gold[3] * k))
	end
	b:HookScript("OnEnter", function(self) if not self.selected then inner:SetColor({ C.gold[1], C.gold[2], C.gold[3], 0.8 }) end end)
	b:HookScript("OnLeave", function(self) if not self.selected then inner:SetColor({ C.gold[1], C.gold[2], C.gold[3], 0.45 }) end end)
	b:SetSelected(false)
	b:HookScript("OnEnable", function(self) self:SetAlpha(1) end)
	b:HookScript("OnDisable", function(self) self:SetAlpha(0.45) end)
	return b
end

-- 색인 탭: 장정 위로 나온 가죽 탭. 선택되면 더 높이 올라오고 금박이 밝아진다.
function UI.Tab(parent, text, key, onClick, _, icon)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(118, 30)
	local shadow = b:CreateTexture(nil, "BACKGROUND", nil, -3)
	shadow:SetPoint("TOPLEFT", 2, -2)
	shadow:SetPoint("BOTTOMRIGHT", 3, 0)
	Color(shadow, { 0, 0, 0, 0.4 })
	local bg = UI.Tiled(b, "BACKGROUND", -2, UI.TEX.leather, 128, 128)
	b.bg = bg
	local gloss = b:CreateTexture(nil, "BACKGROUND", nil, -1)
	gloss:SetAllPoints()
	UI.Gradient(gloss, "VERTICAL", { 0, 0, 0, 0.35 }, { 1, 0.9, 0.7, 0.08 })
	UI.Outline(b, { C.coverDark[1], C.coverDark[2], C.coverDark[3], 1 })
	local rule = b:CreateTexture(nil, "BORDER", nil, 1)
	rule:SetPoint("TOPLEFT", 4, -3); rule:SetPoint("TOPRIGHT", -4, -3); rule:SetHeight(1)
	local ic
	if icon then
		ic = b:CreateTexture(nil, "ARTWORK")
		ic:SetSize(16, 16)
		ic:SetPoint("LEFT", 10, -1)
		ic:SetTexture(icon)
	end
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.button)
	fs:SetPoint("LEFT", ic or b, ic and "RIGHT" or "LEFT", ic and 6 or 12, 0)
	fs:SetText(text)
	b.label = fs
	local num = b:CreateFontString(nil, "OVERLAY", UI.F.key)
	num:SetPoint("TOPRIGHT", -6, -5)
	num:SetText(key)
	b:SetWidth(math.max(96, (fs:GetStringWidth() or 60) + (ic and 52 or 32)))
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.08)
	b:SetScript("OnClick", onClick)
	function b:SetSelected(on)
		self:SetHeight(on and 38 or 30)
		local k = on and 1.35 or 0.95
		bg:SetVertexColor(C.cover[1] * k, C.cover[2] * k, C.cover[3] * k)
		local g = on and 1 or 0.62
		fs:SetTextColor(C.gold[1] * (on and 1.1 or 0.8), C.gold[2] * (on and 1.1 or 0.8), C.gold[3] * (on and 1.1 or 0.8))
		if ic then ic:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], g + 0.2) end
		rule:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], on and 0.8 or 0.3)
		num:SetAlpha(on and 0.9 or 0.45)
	end
	b:SetSelected(false)
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
-- 체크박스: 잉크로 그은 네모 칸 + 깃펜 체크
------------------------------------------------------------------------
function UI.Check(parent, label, get, set, desc)
	local C = UI.COL
	local cb = CreateFrame("Button", nil, parent)
	cb:SetSize(16, 16)
	local box = cb:CreateTexture(nil, "BACKGROUND")
	box:SetAllPoints()
	Color(box, C.page2, 0.6)
	UI.Outline(cb, { C.edge[1], C.edge[2], C.edge[3], 0.9 })
	UI.Outline(cb, { C.edge[1], C.edge[2], C.edge[3], 0.25 }, 2)
	local mark = cb:CreateTexture(nil, "OVERLAY")
	mark:SetSize(22, 22)
	mark:SetPoint("CENTER", 2, 2)
	mark:SetTexture(UI.TEX.check)
	UI.Tint(mark, C.accent)
	local hl = cb:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	UI.Color(hl, C.hover)
	local fs = UI.Text(cb, UI.F.body)
	fs:SetPoint("LEFT", cb, "RIGHT", 8, 0)
	fs:SetJustifyV("MIDDLE")
	fs:SetText(label)
	cb.label = fs
	if desc then
		local d = UI.Text(cb, UI.F.small)
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
-- 스크롤 영역 (마우스 휠 + 가는 잉크선 스크롤 막대)
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
	bar:SetPoint("TOPLEFT", sf, "TOPRIGHT", 5, 0)
	bar:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 5, 0)
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetPoint("TOP"); track:SetPoint("BOTTOM"); track:SetWidth(1)
	Color(track, C.line)
	local thumb = bar:CreateTexture(nil, "OVERLAY")
	thumb:SetColorTexture(C.edge[1], C.edge[2], C.edge[3], 0.75)
	thumb:SetSize(4, 40)
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

------------------------------------------------------------------------
-- 진행 막대 (잉크 테두리 안을 검붉은 잉크로 채운다)
------------------------------------------------------------------------
function UI.Bar(parent, w, h)
	local C = UI.COL
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetSize(w or 100, h or 10)
	bar:SetStatusBarTexture(WHITE)
	bar:SetStatusBarColor(C.bar[1], C.bar[2], C.bar[3], 0.85)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, C.barBg)
	local gloss = bar:CreateTexture(nil, "ARTWORK", nil, 2)
	gloss:SetAllPoints()
	UI.Gradient(gloss, "VERTICAL", { 0, 0, 0, 0.18 }, { 1, 1, 1, 0.08 })
	UI.Outline(bar, { C.edge[1], C.edge[2], C.edge[3], 0.7 })
	local text = bar:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	text:SetPoint("CENTER", 0, 0)
	text:SetTextColor(C.text[1], C.text[2], C.text[3])
	bar.text = text
	return bar
end

------------------------------------------------------------------------
-- 입력창 (양피지 위의 빈 줄)
------------------------------------------------------------------------
function UI.EditBox(parent, w, h, placeholder)
	local C = UI.COL
	local eb = CreateFrame("EditBox", nil, parent)
	eb:SetSize(w or 200, h or 24)
	eb:SetAutoFocus(false)
	eb:SetFontObject(UI.F.body)
	eb:SetTextColor(C.text[1], C.text[2], C.text[3])
	eb:SetTextInsets(6, 6, 2, 2)
	eb:SetMaxLetters(240)
	local bg = eb:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, C.page2, 0.45)
	UI.Outline(eb, { C.edge[1], C.edge[2], C.edge[3], 0.3 })
	local under = eb:CreateTexture(nil, "ARTWORK")
	under:SetHeight(1)
	under:SetPoint("BOTTOMLEFT", 0, 0); under:SetPoint("BOTTOMRIGHT", 0, 0)
	Color(under, C.edge, 0.8)
	local ph = UI.Text(eb, UI.F.small, C.muted)
	ph:SetPoint("LEFT", 7, 0)
	ph:SetJustifyV("MIDDLE")
	ph:SetText(placeholder or "")
	eb.placeholder = ph
	local function sync(self)
		local t = self:GetText()
		ph:SetShown((t == nil or t == "") and not self:HasFocus())
	end
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	eb:SetScript("OnEditFocusGained", function(self) Color(under, C.accent, 1); sync(self) end)
	eb:SetScript("OnEditFocusLost", function(self) Color(under, C.edge, 0.8); sync(self) end)
	eb:HookScript("OnTextChanged", sync)
	eb.SyncPlaceholder = sync
	return eb
end
