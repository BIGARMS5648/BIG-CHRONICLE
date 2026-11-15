-- BIG CHRONICLE :: UI 공용 위젯 / 테마
-- 도감 수첩 스타일: 가죽 표지, 모눈종이, 손글씨, 마스킹 테이프, 형광펜.
-- 질감·아이콘·글꼴은 Media 폴더의 무료 에셋을 쓴다 (출처는 Media/LICENSES.txt).

local ADDON, ns = ...
local UI = ns.UI or {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
UI.WHITE = WHITE
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
UI.MEDIA = MEDIA
UI.TEX = {
	paper = MEDIA .. "Paper", leather = MEDIA .. "Leather", grid = MEDIA .. "Grid",
	ring = MEDIA .. "Ring", hole = MEDIA .. "Hole", tape = MEDIA .. "Tape", sticky = MEDIA .. "Sticky",
	torn = MEDIA .. "Torn", underline = MEDIA .. "Underline", check = MEDIA .. "Check", penCircle = MEDIA .. "PenCircle",
	ink = MEDIA .. "Ink", clip = MEDIA .. "Paperclip", stitch = MEDIA .. "Stitch", ribbon = MEDIA .. "Ribbon",
	seal = MEDIA .. "Seal", sealDex = MEDIA .. "SealDex", sealAch = MEDIA .. "SealAch",
}
UI.ICON = setmetatable({}, { __index = function(_, k) return MEDIA .. "Icons\\" .. k end })
UI.PEN_FONT = MEDIA .. "Fonts\\NanumPenScript.ttf"

------------------------------------------------------------------------
-- 테마
------------------------------------------------------------------------
UI.THEMES = {
	light = {
		name = "크림 수첩",
		page   = { 0.99, 0.96, 0.88 },   -- 종이 색
		page2  = { 0.97, 0.93, 0.79 },   -- 색인 카드
		label  = { 1.00, 0.99, 0.95 },   -- 버튼 스티커
		cover  = { 0.52, 0.30, 0.17 },   -- 가죽 표지
		coverDark = { 0.26, 0.14, 0.07 },
		stitch = { 0.95, 0.84, 0.62 },
		gridCol = { 0.42, 0.60, 0.82, 0.28 },
		edge   = { 0.33, 0.26, 0.19 },
		line   = { 0.28, 0.36, 0.56, 0.55 },
		shade  = { 0.40, 0.30, 0.15, 0.06 },
		text   = { 0.16, 0.13, 0.10 },
		sub    = { 0.36, 0.31, 0.26 },
		muted  = { 0.56, 0.51, 0.45 },
		title  = { 0.12, 0.21, 0.44 },   -- 파란 잉크
		accent = { 0.74, 0.18, 0.12 },   -- 빨간 색연필
		hover  = { 1.00, 0.87, 0.30, 0.28 },
		sel    = { 1.00, 0.85, 0.22, 0.62 }, -- 형광펜
		bar    = { 0.22, 0.45, 0.74 },
		barBg  = { 0.25, 0.30, 0.45, 0.10 },
		creature = { 0.05, 0.36, 0.42 },
		rare   = { 0.46, 0.20, 0.62 },
		good   = { 0.14, 0.48, 0.20 },
		tabs   = { { 0.93, 0.47, 0.40 }, { 0.52, 0.76, 0.48 }, { 0.97, 0.80, 0.35 }, { 0.50, 0.68, 0.90 }, { 0.74, 0.70, 0.64 } },
		shadow = { 0, 0, 0, 0.45 },
		fontShadow = false,
		-- 기록에 저장된 강조색(어두운 배경용)을 종이 위에서 읽기 좋은 잉크색으로 바꿔 보여 준다
		remap = {
			e6c27a = "8a5a12", ffd100 = "8f6200", ff9940 = "a2470d", ff6060 = "a31f17",
			["7fd4ff"] = "155f6e", ["9be27a"] = "2f6a1f", c58cff = "6b2fa0", d4af37 = "7a5410",
			e8d9b0 = "4a3520", ["9d9d9d"] = "6f6457", ["8a8070"] = "7d6f5c", ["60ff60"] = "2a7a2f",
			ff5050 = "a02020", f0e6c8 = "4a3520", ffffff = "2a1c0e",
		},
	},
	dark = {
		name = "밤의 수첩",
		page   = { 0.31, 0.30, 0.28 },
		page2  = { 0.27, 0.26, 0.24 },
		label  = { 0.38, 0.36, 0.33 },
		cover  = { 0.22, 0.17, 0.14 },
		coverDark = { 0.10, 0.08, 0.06 },
		stitch = { 0.78, 0.68, 0.52 },
		gridCol = { 0.85, 0.85, 0.85, 0.08 },
		edge   = { 0.70, 0.62, 0.50 },
		line   = { 0.78, 0.74, 0.66, 0.40 },
		shade  = { 1, 1, 1, 0.04 },
		text   = { 0.93, 0.90, 0.84 },
		sub    = { 0.76, 0.72, 0.65 },
		muted  = { 0.56, 0.53, 0.48 },
		title  = { 0.66, 0.80, 1.00 },
		accent = { 1.00, 0.56, 0.45 },
		hover  = { 1, 0.9, 0.4, 0.12 },
		sel    = { 1, 0.85, 0.3, 0.28 },
		bar    = { 0.48, 0.68, 0.96 },
		barBg  = { 0, 0, 0, 0.35 },
		creature = { 0.5, 0.83, 1 },
		rare   = { 0.82, 0.62, 1 },
		good   = { 0.45, 0.9, 0.45 },
		tabs   = { { 0.62, 0.30, 0.27 }, { 0.32, 0.50, 0.30 }, { 0.62, 0.52, 0.22 }, { 0.30, 0.42, 0.60 }, { 0.46, 0.44, 0.40 } },
		shadow = { 0, 0, 0, 0.6 },
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
	pen     = "BigChronicleFontPen",
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
		-- 손글씨 글꼴이 없거나 못 읽으면 게임 기본 글꼴을 그대로 쓴다
		local ok, res = pcall(font.SetFont, font, path, size, "")
		applied = ok and res ~= false
	end
	if not applied and base and base.GetFont and font.SetFont then
		local ok, p, _, flags = pcall(base.GetFont, base)
		if ok and p then pcall(font.SetFont, font, p, path and math.floor(size * 0.72) or size, flags or "") end
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
	self.themeId = id
	for k, v in pairs(theme) do self.COL[k] = v end
	-- 예전 이름을 쓰는 코드를 위해
	self.COL.paperTop, self.COL.paperBottom = theme.page, theme.page
	local C, sh, PEN = self.COL, theme.fontShadow, self.PEN_FONT
	MakeFont(self.F.title,   { "QuestTitleFont", "GameFontNormalHuge" }, 31, C.title, sh, PEN)
	MakeFont(self.F.header,  { "QuestTitleFont", "GameFontNormalLarge" }, 24, C.title, sh, PEN)
	MakeFont(self.F.heading, { "GameFontNormal" }, 20, C.accent, sh, PEN)
	MakeFont(self.F.button,  { "GameFontNormal" }, 18, C.title, sh, PEN)
	MakeFont(self.F.pen,     { "GameFontNormal" }, 19, C.text, sh, PEN)
	MakeFont(self.F.body,    { "QuestFont", "GameFontHighlight" }, 13, C.text, sh)
	MakeFont(self.F.small,   { "GameFontHighlightSmall" }, 11, C.sub, sh)
	MakeFont(self.F.tiny,    { "GameFontHighlightSmall" }, 10, C.muted, sh)
	MakeFont(self.F.key,     { "GameFontHighlightSmall" }, 10, C.text, sh)
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

-- 손글씨 글꼴에 없는 기호를 비슷한 글자로 바꾼다
local PEN_SWAP = { ["·"] = "-", ["「"] = "'", ["」"] = "'", ["…"] = "...", ["★"] = "*", ["☆"] = "-", ["◆"] = "-", ["→"] = ">", ["←"] = "<" }
function UI.PenText(s)
	if type(s) ~= "string" then return s end
	for k, v in pairs(PEN_SWAP) do s = s:gsub(k, v) end
	return s
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

-- 세로로 반복되는 띠 (바느질선 등): 텍스처를 90도 돌려서 붙인다
function UI.TiledVertical(frame, layer, sub, path, tileLen)
	local tex = frame:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
	tex:SetTexture(path, "REPEAT", "REPEAT")
	local function update()
		local h = tex:GetHeight() or 0
		if h > 0 then
			local L = h / tileLen
			tex:SetTexCoord(0, 0, L, 0, 0, 1, L, 1)
		end
	end
	tex.UpdateTiling = update
	frame:HookScript("OnSizeChanged", update)
	return tex
end

-- 1px 테두리
function UI.Outline(frame, c, inset, layer)
	inset = inset or 0
	local t = {}
	for i = 1, 4 do
		t[i] = frame:CreateTexture(nil, layer or "BORDER")
		Color(t[i], c)
	end
	t[1]:SetPoint("TOPLEFT", inset, -inset); t[1]:SetPoint("TOPRIGHT", -inset, -inset); t[1]:SetHeight(1)
	t[2]:SetPoint("BOTTOMLEFT", inset, inset); t[2]:SetPoint("BOTTOMRIGHT", -inset, inset); t[2]:SetHeight(1)
	t[3]:SetPoint("TOPLEFT", inset, -inset); t[3]:SetPoint("BOTTOMLEFT", inset, inset); t[3]:SetWidth(1)
	t[4]:SetPoint("TOPRIGHT", -inset, -inset); t[4]:SetPoint("BOTTOMRIGHT", -inset, inset); t[4]:SetWidth(1)
	frame.outline = t
	function frame:SetOutlineColor(col)
		for i = 1, 4 do Color(t[i], col) end
	end
	return t
end

-- 마스킹 테이프 한 조각 (살짝 비스듬히)
function UI.Tape(parent, w, h, angle, tint)
	local t = parent:CreateTexture(nil, "OVERLAY", nil, 6)
	t:SetSize(w or 70, h or 20)
	t:SetTexture(UI.TEX.tape)
	if tint then UI.Tint(t, tint) end
	if angle and t.SetRotation then pcall(t.SetRotation, t, angle) end
	return t
end

-- 종이 한 장: 종이 질감 + 그림자 (+ 모눈)
function UI.Paper(frame, opts)
	opts = opts or {}
	local C = UI.COL
	local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	shadow:SetPoint("TOPLEFT", 2, -3)
	shadow:SetPoint("BOTTOMRIGHT", 5, -6)
	Color(shadow, { 0, 0, 0, opts.shadow or 0.3 })
	local paper = UI.Tiled(frame, "BACKGROUND", -6, UI.TEX.paper, 512, 512)
	UI.Tint(paper, opts.tint or C.page)
	if opts.grid then
		local grid = UI.Tiled(frame, "BACKGROUND", -5, UI.TEX.grid, 24, 24)
		UI.Tint(grid, C.gridCol)
	end
	UI.Outline(frame, { C.edge[1], C.edge[2], C.edge[3], 0.25 }, 0)
	return paper
end

-- 예전 두루마리 축 자리에 붙이던 장식 → 이제는 위쪽 모서리 테이프
function UI.Roller(frame, where, overhang, anchor)
	if where ~= "TOP" then return end
	anchor = anchor or frame
	local l = UI.Tape(frame, 64, 18, 0.5)
	l:SetPoint("CENTER", anchor, "TOPLEFT", 14, -4)
	local r = UI.Tape(frame, 64, 18, -0.5)
	r:SetPoint("CENTER", anchor, "TOPRIGHT", -14, -4)
	return l, r
end

-- 손으로 그은 밑줄
function UI.Divider(parent, width)
	local C = UI.COL
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(width or 300, 10)
	local t = f:CreateTexture(nil, "ARTWORK")
	t:SetPoint("LEFT", 0, 0)
	t:SetPoint("RIGHT", 0, 0)
	t:SetHeight(8)
	t:SetTexture(UI.TEX.underline)
	UI.Tint(t, C.line)
	f.line = t
	return f
end

-- 가는 연필선
function UI.Rule(parent, alpha)
	local t = parent:CreateTexture(nil, "ARTWORK")
	local C = UI.COL
	t:SetTexture(UI.TEX.underline)
	t:SetVertexColor(C.line[1], C.line[2], C.line[3], alpha or C.line[4] or 0.5)
	t:SetHeight(5)
	return t
end

-- 색인 카드 (살짝 다른 색 종이에 그림자)
function UI.Section(parent, opts)
	opts = opts or {}
	local C = UI.COL
	local f = CreateFrame("Frame", nil, parent)
	local shadow = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	shadow:SetPoint("TOPLEFT", 2, -2)
	shadow:SetPoint("BOTTOMRIGHT", 3, -4)
	Color(shadow, { 0, 0, 0, 0.18 })
	local bg = UI.Tiled(f, "BACKGROUND", -6, UI.TEX.paper, 512, 512)
	UI.Tint(bg, opts.tint or C.page2)
	f.bg = bg
	UI.Outline(f, { C.edge[1], C.edge[2], C.edge[3], 0.18 }, 0)
	if opts.tape then
		local t = UI.Tape(f, 80, 20, opts.tapeAngle or -0.06)
		t:SetPoint("CENTER", f, "TOP", opts.tapeX or 0, 0)
		f.tape = t
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

------------------------------------------------------------------------
-- 단축키 배지  [1]  (작은 종이 스티커)
------------------------------------------------------------------------
function UI.KeyBadge(parent, key)
	local C = UI.COL
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(18, 18)
	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture(UI.TEX.paper)
	UI.Tint(bg, C.label)
	UI.Outline(f, { C.edge[1], C.edge[2], C.edge[3], 0.55 })
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
-- 버튼: 종이 라벨 스티커. 마우스를 올리면 형광펜이 칠해진다.
------------------------------------------------------------------------
function UI.Button(parent, text, w, h, onClick, key)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w or 80, h or 24)
	local shadow = b:CreateTexture(nil, "BACKGROUND", nil, -2)
	shadow:SetPoint("TOPLEFT", 1, -2)
	shadow:SetPoint("BOTTOMRIGHT", 2, -2)
	Color(shadow, { 0, 0, 0, 0.18 })
	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture(UI.TEX.paper)
	UI.Tint(bg, C.label)
	b.bg = bg
	UI.Outline(b, { C.edge[1], C.edge[2], C.edge[3], 0.45 })
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 3, -4)
	hl:SetPoint("BOTTOMRIGHT", -3, 4)
	hl:SetTexture(UI.TEX.tape)
	UI.Tint(hl, C.hover)
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.button)
	fs:SetPoint("CENTER", key and 9 or 0, 1)
	b:SetFontString(fs)
	b:SetText(UI.PenText(text or ""))
	b.label = fs
	if key then
		local badge = UI.KeyBadge(b, key)
		badge:SetPoint("RIGHT", fs, "LEFT", -6, -1)
		b.badge = badge
	end
	if onClick then b:SetScript("OnClick", onClick) end
	local mark = b:CreateTexture(nil, "ARTWORK")
	mark:SetPoint("TOPLEFT", 2, -3)
	mark:SetPoint("BOTTOMRIGHT", -2, 3)
	mark:SetTexture(UI.TEX.tape)
	UI.Tint(mark, C.sel)
	mark:Hide()
	function b:SetSelected(on)
		self.selected = on
		mark:SetShown(on and true or false)
		if on then
			self:SetOutlineColor({ C.accent[1], C.accent[2], C.accent[3], 0.85 })
		else
			self:SetOutlineColor({ C.edge[1], C.edge[2], C.edge[3], 0.45 })
		end
		fs:SetTextColor(C.title[1], C.title[2], C.title[3])
	end
	local origSetText = b.SetText
	function b:SetText(t) origSetText(self, UI.PenText(t)) end
	b:SetSelected(false)
	b:HookScript("OnEnable", function(self) self:SetAlpha(1) end)
	b:HookScript("OnDisable", function(self) self:SetAlpha(0.4) end)
	return b
end

-- 색인 탭: 수첩 위로 삐죽 나온 색종이. 선택되면 더 높이 올라온다.
function UI.Tab(parent, text, key, onClick, tint, icon)
	local C = UI.COL
	tint = tint or C.label
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(118, 32)
	local shadow = b:CreateTexture(nil, "BACKGROUND", nil, -2)
	shadow:SetPoint("TOPLEFT", 2, -2)
	shadow:SetPoint("BOTTOMRIGHT", 3, 0)
	Color(shadow, { 0, 0, 0, 0.25 })
	local bg = UI.Tiled(b, "BACKGROUND", 0, UI.TEX.paper, 512, 512)
	UI.Tint(bg, tint)
	b.bg = bg
	UI.Outline(b, { 0, 0, 0, 0.25 })
	local ic
	if icon then
		ic = b:CreateTexture(nil, "ARTWORK")
		ic:SetSize(18, 18)
		ic:SetPoint("LEFT", 9, 1)
		ic:SetTexture(icon)
		ic:SetVertexColor(0.15, 0.10, 0.06, 0.85)
	end
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.button)
	fs:SetPoint("LEFT", ic or b, ic and "RIGHT" or "LEFT", ic and 5 or 10, 0)
	fs:SetText(UI.PenText(text))
	fs:SetTextColor(0.13, 0.10, 0.07)
	b.label = fs
	local num = b:CreateFontString(nil, "OVERLAY", UI.F.key)
	num:SetPoint("TOPRIGHT", -6, -4)
	num:SetText(key)
	num:SetTextColor(0.15, 0.10, 0.06, 0.6)
	b:SetWidth(math.max(96, (fs:GetStringWidth() or 60) + (ic and 50 or 30)))
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.15)
	b:SetScript("OnClick", onClick)
	function b:SetSelected(on)
		self:SetHeight(on and 40 or 32)
		bg:SetVertexColor(tint[1] * (on and 1 or 0.86), tint[2] * (on and 1 or 0.86), tint[3] * (on and 1 or 0.86))
		fs:SetAlpha(on and 1 or 0.8)
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
-- 체크박스: 잉크로 그린 네모 + 펜으로 휙 그은 체크
------------------------------------------------------------------------
function UI.Check(parent, label, get, set, desc)
	local C = UI.COL
	local cb = CreateFrame("Button", nil, parent)
	cb:SetSize(16, 16)
	local box = cb:CreateTexture(nil, "BACKGROUND")
	box:SetAllPoints()
	box:SetTexture(UI.TEX.paper)
	UI.Tint(box, C.label)
	UI.Outline(cb, { C.edge[1], C.edge[2], C.edge[3], 0.85 })
	local mark = cb:CreateTexture(nil, "OVERLAY")
	mark:SetSize(24, 24)
	mark:SetPoint("CENTER", 3, 3)
	mark:SetTexture(UI.TEX.check)
	UI.Tint(mark, C.good)
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
-- 스크롤 영역 (마우스 휠 + 연필선 스크롤 막대)
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
	thumb:SetTexture(UI.TEX.tape)
	UI.Tint(thumb, C.accent, 0.8)
	thumb:SetSize(8, 40)
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
-- 진행 막대 (잉크 테두리 안을 색연필로 칠한 듯)
------------------------------------------------------------------------
function UI.Bar(parent, w, h)
	local C = UI.COL
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetSize(w or 100, h or 10)
	bar:SetStatusBarTexture(UI.TEX.tape)
	bar:SetStatusBarColor(C.bar[1], C.bar[2], C.bar[3], 0.85)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, C.barBg)
	UI.Outline(bar, { C.edge[1], C.edge[2], C.edge[3], 0.55 })
	local text = bar:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	text:SetPoint("CENTER", 0, 0)
	text:SetTextColor(C.text[1], C.text[2], C.text[3])
	bar.text = text
	return bar
end

------------------------------------------------------------------------
-- 입력창 (수첩의 빈 줄)
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
	bg:SetTexture(UI.TEX.paper)
	UI.Tint(bg, C.label, 0.65)
	local under = eb:CreateTexture(nil, "ARTWORK")
	under:SetHeight(6)
	under:SetPoint("BOTTOMLEFT", 0, -2); under:SetPoint("BOTTOMRIGHT", 0, -2)
	under:SetTexture(UI.TEX.underline)
	UI.Tint(under, C.line)
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
	eb:SetScript("OnEditFocusGained", function(self) UI.Tint(under, C.accent); sync(self) end)
	eb:SetScript("OnEditFocusLost", function(self) UI.Tint(under, C.line); sync(self) end)
	eb:HookScript("OnTextChanged", sync)
	eb.SyncPlaceholder = sync
	return eb
end
