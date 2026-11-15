-- BIG CHRONICLE :: UI 공용 위젯 / 테마
-- 금테 장정 스타일: 닳은 가죽, 두꺼운 금테와 모서리 장식, 버클 달린 가죽끈, 붉은 깃발,
-- 금테를 두른 가죽 버튼, 가장자리가 그을린 양피지 칸, 명조·Cinzel 제목.
-- 질감·문장·글꼴은 Media 폴더의 무료 에셋을 쓴다 (출처는 Media/LICENSES.txt).

local ADDON, ns = ...
local UI = ns.UI or {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
UI.WHITE = WHITE
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
UI.MEDIA = MEDIA
local function M(name) return MEDIA .. name end
UI.TEX = {
	paper = M "Parchment", panel = M "Panel", leather = M "Leather", vignette = M "Vignette",
	goldBar = M "GoldBar", corner = M "Corner", laurel = M "Laurel", plaque = M "Plaque",
	banner = M "Banner", strap = M "Strap", medallion = M "Medallion",
	tab = M "Tab", tabActive = M "TabActive", button = M "Button", buttonActive = M "ButtonActive",
	buttonRed = M "ButtonRed", badge = M "Badge", field = M "Field", iconFrame = M "IconFrame",
	close = M "Close", scrollThumb = M "ScrollThumb", scrollArrow = M "ScrollArrow", checkBox = M "CheckBox",
	sketchCastle = M "SketchCastle", sketchCamp = M "SketchCamp",
	ornCorner = M "OrnCorner", fleuron = M "Fleuron", emblem = M "Emblem", dust = M "Dust",
	check = M "Check", ink = M "Ink", ghost = M "PageGhost",
	seal = M "Seal", sealDex = M "SealDex", sealAch = M "SealAch",
}
UI.ICON = setmetatable({}, { __index = function(_, k) return MEDIA .. "Icons\\" .. k end })
UI.SERIF_FONT = M "Fonts\\NanumMyeongjo-ExtraBold.ttf"
UI.SERIF_BODY = M "Fonts\\NanumMyeongjo-Bold.ttf"
UI.CINZEL = M "Fonts\\Cinzel-Bold.ttf"

-- 가죽 위 글씨 색 (테마와 상관없이 같다)
UI.LEATHER = {
	cover = { 0.50, 0.23, 0.14 },   -- 겉가죽
	inset = { 0.30, 0.14, 0.09 },   -- 한 단 짙은 가죽 칸
	dark  = { 0.10, 0.05, 0.03 },
	text  = { 0.94, 0.87, 0.73 },
	sub   = { 0.82, 0.73, 0.58 },
	muted = { 0.64, 0.55, 0.42 },
	title = { 0.97, 0.81, 0.47 },   -- 금박 글씨
	accent = { 0.98, 0.74, 0.42 },
	ink   = { 0.22, 0.11, 0.05 },   -- 금빛 바탕 위 글씨
	gold  = { 0.90, 0.72, 0.38 },
}

------------------------------------------------------------------------
-- 테마: 양피지 칸의 색 (가죽과 금테는 두 테마 모두 같다)
------------------------------------------------------------------------
UI.THEMES = {
	light = {
		name = "양피지",
		page   = { 0.96, 0.90, 0.77 },
		page2  = { 0.88, 0.80, 0.65 },
		edge   = { 0.36, 0.22, 0.12 },
		line   = { 0.40, 0.26, 0.14, 0.55 },
		shade  = { 0.40, 0.25, 0.10, 0.07 },
		text   = { 0.16, 0.10, 0.06 },
		sub    = { 0.34, 0.24, 0.15 },
		muted  = { 0.50, 0.40, 0.29 },
		title  = { 0.22, 0.10, 0.05 },
		accent = { 0.55, 0.12, 0.07 },
		hover  = { 0.70, 0.48, 0.18, 0.12 },
		sel    = { 0.92, 0.70, 0.30, 0.30 },   -- 금빛 띠
		bar    = { 0.62, 0.16, 0.10 },
		barBg  = { 0.30, 0.18, 0.08, 0.12 },
		creature = { 0.10, 0.30, 0.32 },
		rare   = { 0.40, 0.15, 0.48 },
		good   = { 0.22, 0.38, 0.12 },
		shadow = { 0, 0, 0, 0.55 },
		sketch = 0.30,
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
		page   = { 0.30, 0.26, 0.22 },
		page2  = { 0.22, 0.19, 0.16 },
		edge   = { 0.70, 0.58, 0.40 },
		line   = { 0.80, 0.66, 0.44, 0.35 },
		shade  = { 1, 1, 1, 0.035 },
		text   = { 0.92, 0.87, 0.77 },
		sub    = { 0.77, 0.70, 0.60 },
		muted  = { 0.58, 0.52, 0.44 },
		title  = { 0.96, 0.80, 0.50 },
		accent = { 0.95, 0.55, 0.40 },
		hover  = { 1, 0.85, 0.5, 0.07 },
		sel    = { 0.90, 0.68, 0.30, 0.20 },
		bar    = { 0.75, 0.32, 0.20 },
		barBg  = { 0, 0, 0, 0.35 },
		creature = { 0.50, 0.80, 0.85 },
		rare   = { 0.80, 0.62, 0.97 },
		good   = { 0.58, 0.86, 0.45 },
		shadow = { 0, 0, 0, 0.7 },
		sketch = 0.22,
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
	tab     = "BigChronicleFontTab",
	key     = "BigChronicleFontKey",
	label   = "BigChronicleFontLabel",
	brand   = "BigChronicleFontBrand",
	brandSmall = "BigChronicleFontBrandSmall",
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
		-- 동봉한 글꼴을 못 읽으면 게임 기본 글꼴을 그대로 쓴다
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
	for k, v in pairs(self.LEATHER) do self.COL["l" .. k] = v end
	self.COL.paperTop, self.COL.paperBottom = theme.page, theme.page
	local C, L, sh = self.COL, self.LEATHER, theme.fontShadow
	local SERIF, BODY = self.SERIF_FONT, self.SERIF_BODY
	MakeFont(self.F.title,   { "QuestTitleFont", "GameFontNormalHuge" }, 22, C.title, sh, SERIF)
	MakeFont(self.F.header,  { "QuestTitleFont", "GameFontNormalLarge" }, 17, C.title, sh, SERIF)
	MakeFont(self.F.heading, { "GameFontNormal" }, 14, C.accent, sh, SERIF)
	MakeFont(self.F.button,  { "GameFontNormal" }, 13, L.title, true, SERIF)
	MakeFont(self.F.tab,     { "GameFontNormal" }, 15, L.text, true, SERIF)
	MakeFont(self.F.label,   { "GameFontNormalSmall" }, 11, C.muted, sh, SERIF)
	MakeFont(self.F.body,    { "QuestFont", "GameFontHighlight" }, 13, C.text, sh, BODY)
	MakeFont(self.F.small,   { "GameFontHighlightSmall" }, 11.5, C.sub, sh, BODY)
	MakeFont(self.F.tiny,    { "GameFontHighlightSmall" }, 10.5, C.muted, sh, BODY)
	MakeFont(self.F.key,     { "GameFontHighlightSmall" }, 10, L.text, true, BODY)
	MakeFont(self.F.brand,   { "QuestTitleFont", "GameFontNormalHuge" }, 20, L.title, true, self.CINZEL)
	MakeFont(self.F.brandSmall, { "GameFontNormalSmall" }, 10, L.sub, true, self.CINZEL)
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

-- 가로 3조각 텍스처 (양 끝은 비율을 지키고 가운데만 늘어난다)
-- capFrac: 텍스처 폭에 대한 끝 조각 비율, ratio: 텍스처 폭/높이
function UI.Slice3(frame, path, capFrac, ratio, layer, sub, mirror)
	capFrac, ratio = capFrac or 0.16, ratio or 4
	local s = {}
	local l = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
	local m = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
	local r = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
	l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT")
	r:SetPoint("TOPRIGHT"); r:SetPoint("BOTTOMRIGHT")
	m:SetPoint("TOPLEFT", l, "TOPRIGHT"); m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
	local function coords()
		local v0, v1 = 0, 1
		if mirror then v0, v1 = 1, 0 end
		l:SetTexCoord(0, capFrac, v0, v1)
		m:SetTexCoord(capFrac, 1 - capFrac, v0, v1)
		r:SetTexCoord(1 - capFrac, 1, v0, v1)
	end
	function s:SetTexture(p)
		l:SetTexture(p); m:SetTexture(p); r:SetTexture(p)
		coords()
	end
	function s:SetVertexColor(...)
		l:SetVertexColor(...); m:SetVertexColor(...); r:SetVertexColor(...)
	end
	function s:SetShown(v) l:SetShown(v); m:SetShown(v); r:SetShown(v) end
	function s:Update()
		local h = frame:GetHeight() or 0
		local w = frame:GetWidth() or 0
		local cap = math.min(h * capFrac * ratio, w / 2)
		l:SetWidth(math.max(1, cap)); r:SetWidth(math.max(1, cap))
	end
	frame:HookScript("OnSizeChanged", function() s:Update() end)
	s:SetTexture(path)
	s:Update()
	s.l, s.m, s.r = l, m, r
	return s
end

-- 금테 띠: 가로로 반복되는 금테 텍스처를 가로/세로로 붙인다
-- side: "TOP" | "BOTTOM" | "LEFT" | "RIGHT" (바깥쪽 테두리가 그쪽을 향한다)
function UI.GoldStrip(frame, side, thickness, layer, sub)
	local t = frame:CreateTexture(nil, layer or "BORDER", nil, sub or 0)
	t:SetTexture(UI.TEX.goldBar, "REPEAT", "REPEAT")
	local tile = thickness * 8 -- 256x32 텍스처
	local function update()
		local len = (side == "TOP" or side == "BOTTOM") and (t:GetWidth() or 0) or (t:GetHeight() or 0)
		local n = math.max(1, len / tile)
		if side == "TOP" then
			t:SetTexCoord(0, n, 0, 1)
		elseif side == "BOTTOM" then
			t:SetTexCoord(0, n, 1, 0)
		elseif side == "LEFT" then
			t:SetTexCoord(0, 0, n, 0, 0, 1, n, 1)
		else
			t:SetTexCoord(0, 1, n, 1, 0, 0, n, 0)
		end
	end
	frame:HookScript("OnSizeChanged", update)
	t.UpdateTiling = update
	return t
end

-- 두꺼운 금테 + 모서리 장식을 프레임 둘레에 두른다
-- inset: 바깥 가장자리에서 금테까지, thick: 금테 두께, corner: 모서리 장식 크기
function UI.GoldFrame(frame, inset, thick, corner, cornerOut, level)
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetAllPoints(frame)
	if level then holder:SetFrameLevel(level) end
	local top = UI.GoldStrip(holder, "TOP", thick)
	top:SetPoint("TOPLEFT", inset, -inset); top:SetPoint("TOPRIGHT", -inset, -inset); top:SetHeight(thick)
	local bot = UI.GoldStrip(holder, "BOTTOM", thick)
	bot:SetPoint("BOTTOMLEFT", inset, inset); bot:SetPoint("BOTTOMRIGHT", -inset, inset); bot:SetHeight(thick)
	local left = UI.GoldStrip(holder, "LEFT", thick)
	left:SetPoint("TOPLEFT", inset, -inset); left:SetPoint("BOTTOMLEFT", inset, inset); left:SetWidth(thick)
	local right = UI.GoldStrip(holder, "RIGHT", thick)
	right:SetPoint("TOPRIGHT", -inset, -inset); right:SetPoint("BOTTOMRIGHT", -inset, inset); right:SetWidth(thick)
	for _, t in ipairs({ top, bot, left, right }) do t:UpdateTiling() end
	holder.strips = { top, bot, left, right }
	if corner then
		holder.corners = UI.Corners(holder, UI.TEX.corner, corner, -(cornerOut or 0), nil, "OVERLAY", 2)
	end
	return holder
end

-- 양피지 칸: 가장자리가 거칠게 그을린 양피지 한 장 (+ 희미한 잉크 삽화)
function UI.Paper(frame, opts)
	opts = opts or {}
	local C = UI.COL
	if opts.shadow ~= false then
		local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		shadow:SetPoint("TOPLEFT", 1, -2)
		shadow:SetPoint("BOTTOMRIGHT", 4, -6)
		shadow:SetTexture(UI.TEX.panel)
		shadow:SetVertexColor(0, 0, 0, opts.shadow or 0.6)
	end
	local paper = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
	paper:SetPoint("TOPLEFT", -3, 3)
	paper:SetPoint("BOTTOMRIGHT", 3, -3)
	paper:SetTexture(UI.TEX.panel)
	UI.Tint(paper, opts.tint or C.page)
	frame.paper = paper
	if opts.sketch then
		local sk = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
		sk:SetSize(opts.sketchW or 300, (opts.sketchW or 300) / 2)
		sk:SetPoint("BOTTOMRIGHT", -10, 8)
		sk:SetTexture(opts.sketch)
		UI.Tint(sk, C.edge, C.sketch)
		frame.sketch = sk
	end
	return paper
end

-- 장식 구분선: 양끝이 흐려지는 선 가운데에 백합 문장
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
	UI.Gradient(l, "HORIZONTAL", { color[1], color[2], color[3], 0 }, { color[1], color[2], color[3], 0.75 })
	local r = f:CreateTexture(nil, "ARTWORK")
	r:SetHeight(1)
	r:SetPoint("LEFT", orn, "RIGHT", 6, 0)
	r:SetPoint("RIGHT", 0, 0)
	UI.Gradient(r, "HORIZONTAL", { color[1], color[2], color[3], 0.75 }, { color[1], color[2], color[3], 0 })
	f.line, f.orn = l, orn
	return f
end

-- 가는 선
function UI.Rule(parent, alpha)
	local t = parent:CreateTexture(nil, "ARTWORK")
	local C = UI.COL
	t:SetColorTexture(C.line[1], C.line[2], C.line[3], alpha or C.line[4] or 0.5)
	t:SetHeight(1)
	return t
end

-- 칸
--   기본: 양피지 칸 (opts.sketch 로 잉크 삽화를 깔 수 있다)
--   opts.leather: 한 단 짙은 가죽 칸에 가는 금선 (왼쪽 목록용)
function UI.Section(parent, opts)
	opts = opts or {}
	local f = CreateFrame("Frame", nil, parent)
	if opts.leather then
		local L = UI.LEATHER
		local bg = UI.Tiled(f, "BACKGROUND", -6, UI.TEX.leather, 256, 256)
		UI.Tint(bg, L.inset)
		local wear = f:CreateTexture(nil, "BACKGROUND", nil, -5)
		wear:SetAllPoints()
		wear:SetTexture(UI.TEX.vignette)
		wear:SetVertexColor(0, 0, 0, 0.55)
		UI.Outline(f, { 0, 0, 0, 0.8 }, 0)
		UI.Outline(f, { L.gold[1], L.gold[2], L.gold[3], 0.45 }, 2)
		f.leather = true
	else
		UI.Paper(f, opts)
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

-- 아이콘 둘레에 금테 (아이콘과 같은 부모에 붙인다)
function UI.FrameIcon(icon, pad, parent)
	parent = parent or icon:GetParent()
	local t = parent:CreateTexture(nil, "OVERLAY", nil, 1)
	t:SetPoint("TOPLEFT", icon, "TOPLEFT", -(pad or 3), pad or 3)
	t:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", pad or 3, -(pad or 3))
	t:SetTexture(UI.TEX.iconFrame)
	return t
end

------------------------------------------------------------------------
-- 단축키·개수 배지 (짙은 알약 모양에 금테)
------------------------------------------------------------------------
function UI.KeyBadge(parent, key)
	local L = UI.LEATHER
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(22, 18)
	UI.Slice3(f, UI.TEX.badge, 0.32, 2, "BACKGROUND")
	local fs = f:CreateFontString(nil, "OVERLAY", UI.F.key)
	fs:SetPoint("CENTER", 0, 0)
	TextColor(fs, L.text)
	f.text = fs
	function f:SetKey(k)
		fs:SetText(k)
		local w = (fs:GetStringWidth() or 8) + 14
		self:SetWidth(math.max(22, w))
	end
	f:SetKey(key)
	return f
end
UI.Badge = UI.KeyBadge

------------------------------------------------------------------------
-- 버튼: 금테를 두른 가죽 버튼. style "red" 는 붉은 버튼. 선택되면 금빛으로 바뀐다.
------------------------------------------------------------------------
function UI.Button(parent, text, w, h, onClick, key, style)
	local L = UI.LEATHER
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w or 80, h or 24)
	local normal = style == "red" and UI.TEX.buttonRed or UI.TEX.button
	local bg = UI.Slice3(b, normal, 0.12, 4, "BACKGROUND")
	b.bg = bg
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 3, -3)
	hl:SetPoint("BOTTOMRIGHT", -3, 3)
	hl:SetColorTexture(1, 0.85, 0.5, 0.10)
	pcall(hl.SetBlendMode, hl, "ADD")
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.button)
	fs:SetPoint("CENTER", key and 10 or 0, 0)
	b:SetFontString(fs)
	b:SetText(text or "")
	b.label = fs
	if key then
		local badge = UI.KeyBadge(b, key)
		badge:SetPoint("RIGHT", fs, "LEFT", -6, 0)
		b.badge = badge
	end
	if onClick then b:SetScript("OnClick", onClick) end
	function b:SetSelected(on)
		self.selected = on
		bg:SetTexture(on and UI.TEX.buttonActive or normal)
		TextColor(fs, on and L.ink or (style == "red" and L.text or L.title))
		fs:SetShadowOffset(on and 0 or 1, on and 0 or -1)
	end
	b:SetSelected(false)
	b:HookScript("OnEnable", function(self) self:SetAlpha(1) end)
	b:HookScript("OnDisable", function(self) self:SetAlpha(0.45) end)
	return b
end

-- 색인 탭: 사다리꼴 가죽 탭. 고른 탭은 금빛으로 빛난다.
function UI.Tab(parent, text, key, onClick, _, icon)
	local L = UI.LEATHER
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(170, 36)
	local bg = UI.Slice3(b, UI.TEX.tab, 0.17, 4, "BACKGROUND")
	b.bg = bg
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 16, -4)
	hl:SetPoint("BOTTOMRIGHT", -16, 2)
	hl:SetColorTexture(1, 0.85, 0.5, 0.08)
	pcall(hl.SetBlendMode, hl, "ADD")
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.tab)
	fs:SetPoint("CENTER", icon and 12 or 0, -1)
	fs:SetText(text)
	b.label = fs
	local ic
	if icon then
		ic = b:CreateTexture(nil, "ARTWORK")
		ic:SetSize(20, 20)
		ic:SetPoint("RIGHT", fs, "LEFT", -8, 0)
		ic:SetTexture(icon)
	end
	b:SetScript("OnClick", onClick)
	function b:SetSelected(on)
		bg:SetTexture(on and UI.TEX.tabActive or UI.TEX.tab)
		TextColor(fs, on and L.ink or L.text)
		fs:SetShadowOffset(on and 0 or 1, on and 0 or -1)
		if ic then
			local c = on and L.ink or L.gold
			ic:SetVertexColor(c[1], c[2], c[3], 1)
		end
	end
	b:SetSelected(false)
	return b
end

-- 왼쪽 목록의 한 줄: 금테 두른 가죽 버튼. 고르면 금빛, 오른쪽에 개수 배지.
-- opts.badge: 오른쪽 글자를 배지 안에 넣는다
local function FlatRow(parent, height)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(height or 24)
	local sel = b:CreateTexture(nil, "BACKGROUND")
	sel:SetPoint("TOPLEFT", 0, -1)
	sel:SetPoint("BOTTOMRIGHT", -2, 1)
	UI.Gradient(sel, "HORIZONTAL", { C.sel[1], C.sel[2], C.sel[3], math.min(1, C.sel[4] * 2) }, { C.sel[1], C.sel[2], C.sel[3], C.sel[4] * 0.6 })
	sel:Hide()
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 0, -1)
	hl:SetPoint("BOTTOMRIGHT", -2, 1)
	UI.Gradient(hl, "HORIZONTAL", { C.hover[1], C.hover[2], C.hover[3], C.hover[4] * 1.6 }, { C.hover[1], C.hover[2], C.hover[3], C.hover[4] * 0.4 })
	local rule = b:CreateTexture(nil, "BORDER")
	rule:SetPoint("BOTTOMLEFT", 4, 0)
	rule:SetPoint("BOTTOMRIGHT", -6, 0)
	rule:SetHeight(1)
	rule:SetColorTexture(C.line[1], C.line[2], C.line[3], 0.18)
	local label = UI.Text(b, UI.F.body)
	label:SetPoint("LEFT", 10, 0)
	label:SetJustifyV("MIDDLE")
	label:SetWordWrap(false)
	b.label = label
	local right = UI.Text(b, UI.F.small)
	right:SetPoint("RIGHT", -8, 0)
	right:SetJustifyH("RIGHT")
	right:SetJustifyV("MIDDLE")
	b.right = right
	label:SetPoint("RIGHT", right, "LEFT", -4, 0)
	function b:SetSelected(on)
		self.selected = on
		sel:SetShown(on and true or false)
		TextColor(label, on and C.title or C.text)
	end
	function b:SetDim()
		TextColor(label, C.muted)
	end
	b:SetScript("OnClick", function(self, button)
		if self.onClick then self.onClick(self, button) end
	end)
	return b
end

function UI.NavRow(parent, height, opts)
	local L = UI.LEATHER
	opts = opts or {}
	if opts.flat then return FlatRow(parent, height) end
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(height or 26)
	local bg = UI.Slice3(b, UI.TEX.button, 0.12, 4, "BACKGROUND")
	b.bg = bg
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 3, -3)
	hl:SetPoint("BOTTOMRIGHT", -3, 3)
	hl:SetColorTexture(1, 0.85, 0.5, 0.10)
	pcall(hl.SetBlendMode, hl, "ADD")
	local label = UI.Text(b, UI.F.body)
	label:SetPoint("LEFT", 12, 0)
	label:SetJustifyV("MIDDLE")
	label:SetWordWrap(false)
	b.label = label
	local right = UI.Text(b, UI.F.small)
	right:SetJustifyH("RIGHT")
	right:SetJustifyV("MIDDLE")
	b.right = right
	local badge
	if opts.badge then
		badge = CreateFrame("Frame", nil, b)
		badge:SetSize(34, math.max(14, (height or 26) - 10))
		badge:SetPoint("RIGHT", -6, 0)
		UI.Slice3(badge, UI.TEX.badge, 0.32, 2, "BACKGROUND")
		right:SetParent(badge)
		right:SetPoint("CENTER", badge, "CENTER", 0, 0)
		right:SetJustifyH("CENTER")
		b.badge = badge
		label:SetPoint("RIGHT", badge, "LEFT", -4, 0)
		local origSetText = right.SetText
		right.SetText = function(self, t)
			origSetText(self, t)
			badge:SetShown(t ~= nil and t ~= "")
			badge:SetWidth(math.max(26, (self:GetStringWidth() or 10) + 14))
		end
	else
		right:SetPoint("RIGHT", -10, 0)
		label:SetPoint("RIGHT", right, "LEFT", -4, 0)
	end
	function b:SetSelected(on)
		self.selected = on
		bg:SetTexture(on and UI.TEX.buttonActive or UI.TEX.button)
		TextColor(label, on and L.ink or L.text)
		label:SetShadowOffset(on and 0 or 1, on and 0 or -1)
		if not badge then TextColor(right, on and L.ink or L.accent) end
	end
	function b:SetDim()
		TextColor(label, L.muted)
	end
	b:SetScript("OnClick", function(self, button)
		if self.onClick then self.onClick(self, button) end
	end)
	TextColor(right, L.text)
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
-- 체크박스: 양피지 색 네모 칸 + 깃펜 체크. light = 가죽 위에 놓을 때 (밝은 글씨)
------------------------------------------------------------------------
function UI.Check(parent, label, get, set, desc, light)
	local C, L = UI.COL, UI.LEATHER
	local cb = CreateFrame("Button", nil, parent)
	cb:SetSize(16, 16)
	local box = cb:CreateTexture(nil, "BACKGROUND")
	box:SetPoint("TOPLEFT", -3, 3)
	box:SetPoint("BOTTOMRIGHT", 3, -3)
	box:SetTexture(UI.TEX.checkBox)
	local mark = cb:CreateTexture(nil, "OVERLAY")
	mark:SetSize(22, 22)
	mark:SetPoint("CENTER", 2, 2)
	mark:SetTexture(UI.TEX.check)
	mark:SetVertexColor(0.34, 0.10, 0.05)
	local hl = cb:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 0.85, 0.5, 0.25)
	local fs = UI.Text(cb, UI.F.body)
	fs:SetPoint("LEFT", cb, "RIGHT", 8, 0)
	fs:SetJustifyV("MIDDLE")
	fs:SetText(label)
	if light then UI.OnLeather(fs, L.text) end
	cb.label = fs
	if desc then
		local d = UI.Text(cb, UI.F.small)
		d:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -3)
		d:SetText(desc)
		if light then UI.OnLeather(d, L.sub) end
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
-- 스크롤 영역 (마우스 휠 + 금빛 손잡이와 위아래 화살표가 달린 스크롤 막대)
------------------------------------------------------------------------
function UI.Scroll(parent)
	local L = UI.LEATHER
	local sf = CreateFrame("ScrollFrame", nil, parent)
	local child = CreateFrame("Frame", nil, sf)
	child:SetSize(10, 10)
	sf:SetScrollChild(child)
	sf.child = child

	local bar = CreateFrame("Slider", nil, sf)
	bar:SetOrientation("VERTICAL")
	bar:SetWidth(14)
	bar:SetPoint("TOPLEFT", sf, "TOPRIGHT", 3, -15)
	bar:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 3, 15)
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetPoint("TOP", 0, 2); track:SetPoint("BOTTOM", 0, -2); track:SetWidth(8)
	track:SetColorTexture(0.10, 0.055, 0.03, 0.85)
	for _, side in ipairs({ "LEFT", "RIGHT" }) do
		local e = bar:CreateTexture(nil, "BORDER")
		e:SetPoint("TOP" .. side, track, "TOP" .. side); e:SetPoint("BOTTOM" .. side, track, "BOTTOM" .. side)
		e:SetWidth(1)
		e:SetColorTexture(L.gold[1], L.gold[2], L.gold[3], 0.7)
	end
	local thumb = bar:CreateTexture(nil, "OVERLAY")
	thumb:SetTexture(UI.TEX.scrollThumb)
	thumb:SetSize(16, 44)
	bar:SetThumbTexture(thumb)
	bar:SetMinMaxValues(0, 0)
	bar:SetValue(0)
	bar:SetValueStep(1)
	bar:SetScript("OnValueChanged", function(_, v) sf:SetVerticalScroll(v) end)
	sf.bar = bar
	local function arrow(point, rel, dir)
		local a = CreateFrame("Button", nil, bar)
		a:SetSize(15, 15)
		a:SetPoint(point, bar, rel, 0, 0)
		local t = a:CreateTexture(nil, "ARTWORK")
		t:SetAllPoints()
		t:SetTexture(UI.TEX.scrollArrow)
		if dir > 0 then t:SetTexCoord(0, 1, 1, 0) end
		local hl = a:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 0.85, 0.5, 0.25)
		a:SetScript("OnClick", function() sf:ScrollBy(dir * 60) end)
		return a
	end
	arrow("BOTTOM", "TOP", -1)
	arrow("TOP", "BOTTOM", 1)

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
-- 진행 막대 (금테 두른 짙은 홈을 붉은 빛으로 채운다)
------------------------------------------------------------------------
function UI.Bar(parent, w, h)
	local C, L = UI.COL, UI.LEATHER
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetSize(w or 100, h or 10)
	bar:SetStatusBarTexture(WHITE)
	bar:SetStatusBarColor(C.bar[1], C.bar[2], C.bar[3], 0.95)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.10, 0.055, 0.03, 0.85)
	local gloss = bar:CreateTexture(nil, "ARTWORK", nil, 2)
	gloss:SetAllPoints()
	UI.Gradient(gloss, "VERTICAL", { 0, 0, 0, 0.28 }, { 1, 0.9, 0.7, 0.14 })
	UI.Outline(bar, { L.gold[1], L.gold[2], L.gold[3], 0.9 }, -1)
	UI.Outline(bar, { 0, 0, 0, 0.75 }, -2)
	local text = bar:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	text:SetPoint("CENTER", 0, 0)
	UI.OnLeather(text, L.text)
	bar.text = text
	return bar
end

------------------------------------------------------------------------
-- 입력창 (금테 두른 짙은 칸에 밝은 글씨)
------------------------------------------------------------------------
function UI.EditBox(parent, w, h, placeholder)
	local L = UI.LEATHER
	local eb = CreateFrame("EditBox", nil, parent)
	eb:SetSize(w or 200, h or 24)
	eb:SetAutoFocus(false)
	eb:SetFontObject(UI.F.body)
	eb:SetTextColor(L.text[1], L.text[2], L.text[3])
	eb:SetTextInsets(10, 8, 2, 2)
	eb:SetMaxLetters(240)
	UI.Slice3(eb, UI.TEX.field, 0.14, 4, "BACKGROUND")
	local glow = eb:CreateTexture(nil, "BORDER")
	glow:SetPoint("TOPLEFT", 3, -3)
	glow:SetPoint("BOTTOMRIGHT", -3, 3)
	glow:SetColorTexture(1, 0.8, 0.4, 0.08)
	glow:Hide()
	local ph = UI.Text(eb, UI.F.small, L.muted)
	ph:SetPoint("LEFT", 11, 0)
	ph:SetJustifyV("MIDDLE")
	ph:SetText(placeholder or "")
	eb.placeholder = ph
	local function sync(self)
		local t = self:GetText()
		ph:SetShown((t == nil or t == "") and not self:HasFocus())
	end
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	eb:SetScript("OnEditFocusGained", function(self) glow:Show(); sync(self) end)
	eb:SetScript("OnEditFocusLost", function(self) glow:Hide(); sync(self) end)
	eb:HookScript("OnTextChanged", sync)
	eb.SyncPlaceholder = sync
	return eb
end
