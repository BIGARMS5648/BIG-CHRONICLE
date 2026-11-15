-- BIG CHRONICLE :: UI 공용 위젯 / 테마
-- 단순하고 묵직한 가죽 수첩: 실제 가죽 사진 질감의 표지, 실제 종이 사진 질감의 속지, 가는 선.
-- 장식은 쓰지 않는다. 글꼴은 게임 기본 글꼴 그대로. (질감 출처는 Media/LICENSES.txt)

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
-- 가죽 위 글씨 색 (테마와 상관없이 같다)
UI.LEATHER = {
	cover = { 0.80, 0.78, 0.76 },   -- 가죽 사진에 살짝만 어둡게
	inset = { 0.42, 0.40, 0.38 },   -- 한 단 짙은 가죽 칸
	dark  = { 0.10, 0.05, 0.03 },
	text  = { 0.93, 0.88, 0.78 },
	sub   = { 0.80, 0.73, 0.62 },
	muted = { 0.62, 0.55, 0.45 },
	title = { 0.95, 0.86, 0.66 },
	accent = { 0.95, 0.80, 0.55 },
	ink   = { 0.16, 0.10, 0.06 },
	gold  = { 0.80, 0.68, 0.48 },
}

------------------------------------------------------------------------
-- 테마: 양피지 칸의 색 (가죽과 금테는 두 테마 모두 같다)
------------------------------------------------------------------------
UI.THEMES = {
	light = {
		name = "밝은 속지",
		page   = { 1, 1, 1 },
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
		sel    = { 0.35, 0.20, 0.08, 0.16 },
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
		name = "어두운 속지",
		page   = { 0.34, 0.31, 0.29 },
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
	MakeFont(self.F.title,   { "QuestTitleFont", "GameFontNormalHuge" }, 22, C.title, sh)
	MakeFont(self.F.header,  { "QuestTitleFont", "GameFontNormalLarge" }, 17, C.title, sh)
	MakeFont(self.F.heading, { "GameFontNormal" }, 14, C.accent, sh)
	MakeFont(self.F.button,  { "GameFontNormal" }, 13, L.title, true)
	MakeFont(self.F.tab,     { "GameFontNormal" }, 15, L.text, true)
	MakeFont(self.F.label,   { "GameFontNormalSmall" }, 11, C.muted, sh)
	MakeFont(self.F.body,    { "QuestFont", "GameFontHighlight" }, 13, C.text, sh)
	MakeFont(self.F.small,   { "GameFontHighlightSmall" }, 11.5, C.sub, sh)
	MakeFont(self.F.tiny,    { "GameFontHighlightSmall" }, 10.5, C.muted, sh)
	MakeFont(self.F.key,     { "GameFontHighlightSmall" }, 10, L.text, true)
	MakeFont(self.F.brand,   { "GameFontNormalHuge" }, 20, L.title, true)
	MakeFont(self.F.brandSmall, { "GameFontNormalSmall" }, 10, L.sub, true)
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

-- 가는 이중 테두리 (예전 금테 자리): 바깥 짙은 선 + 안쪽 옅은 선
function UI.GoldFrame(frame, inset, thick, corner, cornerOut, level)
	local L = UI.LEATHER
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetAllPoints(frame)
	if level then holder:SetFrameLevel(level) end
	UI.Outline(holder, { 0, 0, 0, 0.9 }, 0)
	UI.Outline(holder, { L.gold[1], L.gold[2], L.gold[3], 0.22 }, (inset or 0) + 3)
	return holder
end

-- 속지 한 장: 종이 사진 질감 + 그림자 + 가는 테두리
function UI.Paper(frame, opts)
	opts = opts or {}
	local C = UI.COL
	if opts.shadow ~= false then
		local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		shadow:SetPoint("TOPLEFT", 2, -2)
		shadow:SetPoint("BOTTOMRIGHT", 3, -3)
		shadow:SetColorTexture(0, 0, 0, 0.45)
	end
	local paper = UI.Tiled(frame, "BACKGROUND", -6, UI.TEX.paper, 512, 512)
	UI.Tint(paper, opts.tint or C.page)
	frame.paper = paper
	UI.Outline(frame, { 0, 0, 0, 0.55 }, 0)
	-- 삽화는 쓰지 않는다 (자리만 남겨 둔다)
	local sk = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
	sk:Hide()
	frame.sketch = sk
	return paper
end

-- 구분선: 양끝이 흐려지는 가는 선
function UI.Divider(parent, width, color)
	local C = UI.COL
	color = color or C.edge
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(width or 300, 6)
	local l = f:CreateTexture(nil, "ARTWORK")
	l:SetHeight(1)
	l:SetPoint("LEFT", 0, 0); l:SetPoint("RIGHT", f, "CENTER", 0, 0)
	UI.Gradient(l, "HORIZONTAL", { color[1], color[2], color[3], 0 }, { color[1], color[2], color[3], 0.6 })
	local r = f:CreateTexture(nil, "ARTWORK")
	r:SetHeight(1)
	r:SetPoint("LEFT", f, "CENTER", 0, 0); r:SetPoint("RIGHT", 0, 0)
	UI.Gradient(r, "HORIZONTAL", { color[1], color[2], color[3], 0.6 }, { color[1], color[2], color[3], 0 })
	f.line = l
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

-- 칸: 기본은 속지 한 장, opts.leather 는 한 단 짙은 가죽 칸
function UI.Section(parent, opts)
	opts = opts or {}
	local f = CreateFrame("Frame", nil, parent)
	if opts.leather then
		local bg = UI.Tiled(f, "BACKGROUND", -6, UI.TEX.leather, 512, 512)
		UI.Tint(bg, UI.LEATHER.inset)
		UI.Outline(f, { 0, 0, 0, 0.8 }, 0)
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

-- 아이콘 둘레의 가는 테두리
function UI.FrameIcon(icon, pad, parent)
	parent = parent or icon:GetParent()
	local h = CreateFrame("Frame", nil, parent)
	h:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
	h:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
	UI.Outline(h, { 0, 0, 0, 0.85 }, 0)
	return h
end

-- 단축키 배지: 짙은 네모에 글자
function UI.KeyBadge(parent, key)
	local L = UI.LEATHER
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(18, 16)
	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.45)
	local fs = f:CreateFontString(nil, "OVERLAY", UI.F.key)
	fs:SetPoint("CENTER", 0, 0)
	TextColor(fs, L.text)
	f.text = fs
	function f:SetKey(k)
		fs:SetText(k)
		self:SetWidth(math.max(18, (fs:GetStringWidth() or 8) + 10))
	end
	f:SetKey(key)
	return f
end
UI.Badge = UI.KeyBadge

-- 가죽 조각 바탕 (버튼·탭 공용): 가죽 질감 + 짙은 테두리 + 위쪽 옅은 빛
local function Plate(b)
	local bg = UI.Tiled(b, "BACKGROUND", -2, UI.TEX.leather, 512, 512)
	UI.Outline(b, { 0, 0, 0, 0.9 }, 0)
	local top = b:CreateTexture(nil, "BORDER", nil, 1)
	top:SetPoint("TOPLEFT", 1, -1); top:SetPoint("TOPRIGHT", -1, -1); top:SetHeight(1)
	top:SetColorTexture(1, 0.9, 0.75, 0.12)
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 1, -1); hl:SetPoint("BOTTOMRIGHT", -1, 1)
	hl:SetColorTexture(1, 0.9, 0.75, 0.08)
	return bg
end

-- 버튼: 납작한 가죽 조각. style "red" 는 주된 동작(조금 붉게). 선택되면 밝아진다.
function UI.Button(parent, text, w, h, onClick, key, style)
	local L = UI.LEATHER
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w or 80, h or 24)
	local bg = Plate(b)
	b.bg = bg
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
		if on then
			bg:SetVertexColor(1.0, 0.95, 0.88)
		elseif style == "red" then
			bg:SetVertexColor(0.95, 0.55, 0.48)
		else
			bg:SetVertexColor(0.72, 0.69, 0.66)
		end
		TextColor(fs, on and L.title or L.text)
	end
	b:SetSelected(false)
	b:HookScript("OnEnable", function(self) self:SetAlpha(1) end)
	b:HookScript("OnDisable", function(self) self:SetAlpha(0.45) end)
	return b
end

-- 색인 탭: 납작한 가죽 조각. 고른 탭은 밝아지고 아래에 선이 그어진다.
function UI.Tab(parent, text, key, onClick, _, icon)
	local L = UI.LEATHER
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(150, 30)
	local bg = Plate(b)
	b.bg = bg
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.tab)
	fs:SetPoint("CENTER", icon and 10 or 0, 0)
	fs:SetText(text)
	b.label = fs
	local ic
	if icon then
		ic = b:CreateTexture(nil, "ARTWORK")
		ic:SetSize(16, 16)
		ic:SetPoint("RIGHT", fs, "LEFT", -6, 0)
		ic:SetTexture(icon)
	end
	local mark = b:CreateTexture(nil, "ARTWORK")
	mark:SetPoint("BOTTOMLEFT", 1, 1); mark:SetPoint("BOTTOMRIGHT", -1, 1); mark:SetHeight(2)
	mark:SetColorTexture(L.title[1], L.title[2], L.title[3], 0.9)
	b:SetScript("OnClick", onClick)
	function b:SetSelected(on)
		if on then bg:SetVertexColor(1.0, 0.95, 0.88) else bg:SetVertexColor(0.62, 0.59, 0.56) end
		TextColor(fs, on and L.title or L.sub)
		if ic then
			local c = on and L.title or L.muted
			ic:SetVertexColor(c[1], c[2], c[3], 1)
		end
		mark:SetShown(on and true or false)
	end
	b:SetSelected(false)
	return b
end

-- 목록의 한 줄
--   opts.flat: 속지 위의 줄 (고르면 옅은 잉크 띠)
--   기본: 가죽 칸 위의 줄 (고르면 밝은 띠와 왼쪽 표시)
local function FlatRow(parent, height)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(height or 24)
	local sel = b:CreateTexture(nil, "BACKGROUND")
	sel:SetPoint("TOPLEFT", 0, -1); sel:SetPoint("BOTTOMRIGHT", -2, 1)
	sel:SetColorTexture(C.sel[1], C.sel[2], C.sel[3], C.sel[4])
	sel:Hide()
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 0, -1); hl:SetPoint("BOTTOMRIGHT", -2, 1)
	hl:SetColorTexture(C.hover[1], C.hover[2], C.hover[3], C.hover[4])
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
	function b:SetDim() TextColor(label, C.muted) end
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
	local sel = b:CreateTexture(nil, "BACKGROUND")
	sel:SetAllPoints()
	sel:SetColorTexture(1, 0.9, 0.75, 0.13)
	sel:Hide()
	local bar = b:CreateTexture(nil, "ARTWORK")
	bar:SetPoint("TOPLEFT", 0, 0); bar:SetPoint("BOTTOMLEFT", 0, 0); bar:SetWidth(2)
	bar:SetColorTexture(L.title[1], L.title[2], L.title[3], 0.9)
	bar:Hide()
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 0.9, 0.75, 0.07)
	local label = UI.Text(b, UI.F.body)
	label:SetPoint("LEFT", 12, 0)
	label:SetJustifyV("MIDDLE")
	label:SetWordWrap(false)
	b.label = label
	local right = UI.Text(b, UI.F.small)
	right:SetPoint("RIGHT", -10, 0)
	right:SetJustifyH("RIGHT")
	right:SetJustifyV("MIDDLE")
	b.right = right
	label:SetPoint("RIGHT", right, "LEFT", -4, 0)
	UI.OnLeather(label, L.text)
	UI.OnLeather(right, L.muted)
	function b:SetSelected(on)
		self.selected = on
		sel:SetShown(on and true or false)
		bar:SetShown(on and true or false)
		TextColor(label, on and L.title or L.text)
	end
	function b:SetDim() TextColor(label, L.muted) end
	b:SetScript("OnClick", function(self, button)
		if self.onClick then self.onClick(self, button) end
	end)
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
	box:SetAllPoints()
	box:SetColorTexture(0, 0, 0, light and 0.45 or 0.12)
	UI.Outline(cb, light and { L.gold[1], L.gold[2], L.gold[3], 0.6 } or { C.edge[1], C.edge[2], C.edge[3], 0.8 })
	local mark = cb:CreateTexture(nil, "OVERLAY")
	mark:SetSize(22, 22)
	mark:SetPoint("CENTER", 0, 0)
	mark:SetTexture(UI.TEX.check)
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
	track:SetPoint("TOP", 0, 14); track:SetPoint("BOTTOM", 0, -14); track:SetWidth(4)
	track:SetColorTexture(0, 0, 0, 0.25)
	local thumb = bar:CreateTexture(nil, "OVERLAY")
	thumb:SetColorTexture(0.30, 0.20, 0.12, 0.85)
	thumb:SetSize(6, 44)
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
	local bg = eb:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.13, 0.09, 0.06, 0.88)
	UI.Outline(eb, { 0, 0, 0, 0.9 }, 0)
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
