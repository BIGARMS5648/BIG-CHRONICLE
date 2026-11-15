-- BIG CHRONICLE :: UI 공용 위젯 / 테마
-- 두루마리 양피지 느낌의 대화창 스타일. 외부 텍스처 없이 색 텍스처와 그라데이션만으로 그린다.

local ADDON, ns = ...
local UI = ns.UI or {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
UI.WHITE = WHITE

------------------------------------------------------------------------
-- 테마
------------------------------------------------------------------------
UI.THEMES = {
	light = {
		name = "양피지",
		paperTop = { 0.96, 0.91, 0.79 }, paperBottom = { 0.87, 0.80, 0.64 },
		edge   = { 0.40, 0.27, 0.13 },
		line   = { 0.50, 0.36, 0.20, 0.55 },
		shade  = { 0.45, 0.30, 0.12, 0.07 },
		text   = { 0.20, 0.13, 0.07 },
		sub    = { 0.40, 0.30, 0.20 },
		muted  = { 0.57, 0.50, 0.41 },
		title  = { 0.30, 0.16, 0.05 },
		accent = { 0.56, 0.33, 0.08 },
		hover  = { 0.50, 0.32, 0.10, 0.12 },
		sel    = { 0.55, 0.35, 0.10, 0.20 },
		bar    = { 0.62, 0.40, 0.12 },
		barBg  = { 0.40, 0.28, 0.14, 0.18 },
		creature = { 0.10, 0.36, 0.46 },
		rare   = { 0.46, 0.20, 0.62 },
		good   = { 0.18, 0.46, 0.18 },
		wood1  = { 0.46, 0.28, 0.12 }, wood2 = { 0.19, 0.10, 0.04 },
		knob   = { 0.30, 0.17, 0.07 },
		shadow = { 0, 0, 0, 0.45 },
		fontShadow = false,
		-- 기록에 저장된 강조색(어두운 배경용)을 양피지에서 읽기 좋은 색으로 바꿔 보여 준다
		remap = {
			e6c27a = "8a5a12", ffd100 = "8f6200", ff9940 = "a2470d", ff6060 = "9e1f1f",
			["7fd4ff"] = "1f5f7a", ["9be27a"] = "3d6b1f", c58cff = "6b2fa0", d4af37 = "7a5410",
			e8d9b0 = "4a3520", ["9d9d9d"] = "6f6457", ["8a8070"] = "7d6f5c", ["60ff60"] = "2f7a2f",
			ff5050 = "a02020", f0e6c8 = "4a3520", ffffff = "2a1c0e",
		},
	},
	dark = {
		name = "어둠",
		paperTop = { 0.14, 0.115, 0.09 }, paperBottom = { 0.075, 0.06, 0.05 },
		edge   = { 0.62, 0.48, 0.26 },
		line   = { 0.75, 0.60, 0.35, 0.40 },
		shade  = { 1, 0.9, 0.7, 0.04 },
		text   = { 0.92, 0.87, 0.76 },
		sub    = { 0.72, 0.66, 0.56 },
		muted  = { 0.48, 0.44, 0.38 },
		title  = { 1, 0.86, 0.55 },
		accent = { 0.86, 0.70, 0.36 },
		hover  = { 1, 0.85, 0.5, 0.08 },
		sel    = { 1, 0.8, 0.4, 0.14 },
		bar    = { 0.83, 0.62, 0.22 },
		barBg  = { 0, 0, 0, 0.45 },
		creature = { 0.5, 0.83, 1 },
		rare   = { 0.77, 0.55, 1 },
		good   = { 0.4, 0.9, 0.4 },
		wood1  = { 0.46, 0.28, 0.12 }, wood2 = { 0.19, 0.10, 0.04 },
		knob   = { 0.30, 0.17, 0.07 },
		shadow = { 0, 0, 0, 0.55 },
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
}

local function MakeFont(name, baseNames, size, color, shadow)
	local font = _G[name] or (CreateFont and CreateFont(name))
	if not font then return end
	local base
	for _, b in ipairs(baseNames) do
		if _G[b] then base = _G[b] break end
	end
	if base and font.CopyFontObject then pcall(font.CopyFontObject, font, base) end
	if base and base.GetFont and font.SetFont then
		local ok, path, _, flags = pcall(base.GetFont, base)
		if ok and path then pcall(font.SetFont, font, path, size, flags or "") end
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
	local C, sh = self.COL, theme.fontShadow
	MakeFont(self.F.title,   { "QuestTitleFont", "GameFontNormalHuge" }, 22, C.title, sh)
	MakeFont(self.F.header,  { "QuestTitleFont", "GameFontNormalLarge" }, 17, C.title, sh)
	MakeFont(self.F.heading, { "GameFontNormal" }, 14, C.accent, sh)
	MakeFont(self.F.body,    { "QuestFont", "GameFontHighlight" }, 13, C.text, sh)
	MakeFont(self.F.small,   { "GameFontHighlightSmall" }, 11, C.sub, sh)
	MakeFont(self.F.tiny,    { "GameFontHighlightSmall" }, 10, C.muted, sh)
	MakeFont(self.F.button,  { "GameFontNormal" }, 12, C.accent, sh)
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

------------------------------------------------------------------------
-- 기본 도형
------------------------------------------------------------------------
local function Color(tex, c, a)
	tex:SetColorTexture(c[1], c[2], c[3], a or c[4] or 1)
end
UI.Color = Color

-- 세로 그라데이션 (버전 차이를 고려해 안전하게)
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

-- 양피지 종이: 그라데이션 + 가장자리 그늘 + 테두리
function UI.Paper(frame, opts)
	opts = opts or {}
	local C = UI.COL
	local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	shadow:SetPoint("TOPLEFT", -6, 6)
	shadow:SetPoint("BOTTOMRIGHT", 6, -6)
	Color(shadow, C.shadow)
	local paper = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
	paper:SetAllPoints()
	UI.Gradient(paper, "VERTICAL", C.paperBottom, C.paperTop)
	-- 가장자리를 살짝 어둡게 (오래된 종이 느낌)
	local edge = opts.vignette or 28
	local dark = { C.edge[1], C.edge[2], C.edge[3], UI.theme and UI.theme.fontShadow and 0.25 or 0.16 }
	local clear = { C.edge[1], C.edge[2], C.edge[3], 0 }
	local l = frame:CreateTexture(nil, "BACKGROUND", nil, -5)
	l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT"); l:SetWidth(edge)
	UI.Gradient(l, "HORIZONTAL", dark, clear)
	local r = frame:CreateTexture(nil, "BACKGROUND", nil, -5)
	r:SetPoint("TOPRIGHT"); r:SetPoint("BOTTOMRIGHT"); r:SetWidth(edge)
	UI.Gradient(r, "HORIZONTAL", clear, dark)
	if not opts.noOutline then
		UI.Outline(frame, { C.edge[1], C.edge[2], C.edge[3], 0.85 }, 0)
		UI.Outline(frame, { C.edge[1], C.edge[2], C.edge[3], 0.30 }, 4)
	end
	return paper
end

-- 두루마리 나무 축 (위/아래)
function UI.Roller(frame, where, overhang)
	local C = UI.COL
	overhang = overhang or 16
	local h = 16
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetHeight(h)
	if where == "TOP" then
		holder:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -overhang, -6)
		holder:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", overhang, -6)
	else
		holder:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -overhang, 6)
		holder:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", overhang, 6)
	end
	holder:SetFrameLevel(frame:GetFrameLevel() + 6)
	local upper = holder:CreateTexture(nil, "ARTWORK")
	upper:SetPoint("TOPLEFT", 8, 0); upper:SetPoint("TOPRIGHT", -8, 0); upper:SetHeight(h / 2)
	UI.Gradient(upper, "VERTICAL", C.wood1, C.wood2)
	local lower = holder:CreateTexture(nil, "ARTWORK")
	lower:SetPoint("BOTTOMLEFT", 8, 0); lower:SetPoint("BOTTOMRIGHT", -8, 0); lower:SetHeight(h / 2)
	UI.Gradient(lower, "VERTICAL", C.wood2, C.wood1)
	local shine = holder:CreateTexture(nil, "OVERLAY")
	shine:SetPoint("LEFT", 10, 2); shine:SetPoint("RIGHT", -10, 2); shine:SetHeight(1)
	shine:SetColorTexture(1, 0.85, 0.6, 0.25)
	for _, side in ipairs({ "LEFT", "RIGHT" }) do
		local knob = holder:CreateTexture(nil, "OVERLAY")
		knob:SetSize(12, h + 8)
		knob:SetPoint(side, 0, 0)
		UI.Gradient(knob, "HORIZONTAL", C.wood2, C.knob)
		local cap = holder:CreateTexture(nil, "OVERLAY", nil, 1)
		cap:SetSize(4, h + 12)
		cap:SetPoint(side, side == "LEFT" and -3 or 3, 0)
		Color(cap, C.wood2)
	end
	return holder
end

-- 장식 구분선:  ──── ◆ ────
function UI.Divider(parent, width)
	local C = UI.COL
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(width or 300, 12)
	-- 가운데 마름모: 45도 돌린 작은 사각형 (글꼴에 ◆ 문자가 없어도 보이도록)
	local mid = f:CreateTexture(nil, "OVERLAY")
	mid:SetSize(7, 7)
	mid:SetPoint("CENTER", 0, 0)
	Color(mid, C.accent)
	if mid.SetRotation then pcall(mid.SetRotation, mid, math.pi / 4) end
	local c1 = { C.line[1], C.line[2], C.line[3], 0 }
	local c2 = { C.line[1], C.line[2], C.line[3], C.line[4] or 0.6 }
	local l = f:CreateTexture(nil, "ARTWORK")
	l:SetHeight(1); l:SetPoint("LEFT", 0, 0); l:SetPoint("RIGHT", mid, "LEFT", -8, 0)
	UI.Gradient(l, "HORIZONTAL", c1, c2)
	local r = f:CreateTexture(nil, "ARTWORK")
	r:SetHeight(1); r:SetPoint("RIGHT", 0, 0); r:SetPoint("LEFT", mid, "RIGHT", 8, 0)
	UI.Gradient(r, "HORIZONTAL", c2, c1)
	return f
end

-- 가는 가로선
function UI.Rule(parent, alpha)
	local t = parent:CreateTexture(nil, "ARTWORK")
	local C = UI.COL
	t:SetColorTexture(C.line[1], C.line[2], C.line[3], alpha or C.line[4] or 0.5)
	t:SetHeight(1)
	return t
end

-- 살짝 어두운 영역 (구획)
function UI.Section(parent)
	local f = CreateFrame("Frame", nil, parent)
	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, UI.COL.shade)
	f.bg = bg
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
-- 단축키 배지  [1]
------------------------------------------------------------------------
function UI.KeyBadge(parent, key)
	local C = UI.COL
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(18, 18)
	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, C.shade, 0.18)
	UI.Outline(f, { C.edge[1], C.edge[2], C.edge[3], 0.7 })
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
-- 버튼 (대화 선택지처럼: 테두리 얇게, 마우스를 올리면 진하게)
------------------------------------------------------------------------
function UI.Button(parent, text, w, h, onClick, key)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w or 80, h or 22)
	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, C.shade)
	b.bg = bg
	UI.Outline(b, { C.edge[1], C.edge[2], C.edge[3], 0.55 })
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	Color(hl, C.hover)
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
	function b:SetSelected(on)
		self.selected = on
		if on then
			Color(bg, C.sel)
			self:SetOutlineColor({ C.edge[1], C.edge[2], C.edge[3], 0.95 })
			fs:SetTextColor(C.title[1], C.title[2], C.title[3])
		else
			Color(bg, C.shade)
			self:SetOutlineColor({ C.edge[1], C.edge[2], C.edge[3], 0.55 })
			fs:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
		end
	end
	b:SetSelected(false)
	b:HookScript("OnEnable", function(self) self:SetAlpha(1) end)
	b:HookScript("OnDisable", function(self) self:SetAlpha(0.4) end)
	return b
end

-- 탭: 글자만 있고 선택되면 밑줄이 생긴다 (단축키 배지 포함)
function UI.Tab(parent, text, key, onClick)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(26)
	local badge = UI.KeyBadge(b, key)
	badge:SetPoint("LEFT", 0, 0)
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.heading)
	fs:SetPoint("LEFT", badge, "RIGHT", 7, 0)
	fs:SetText(text)
	b.label = fs
	b:SetWidth((fs:GetStringWidth() or 60) + 32)
	local under = b:CreateTexture(nil, "ARTWORK")
	under:SetHeight(2)
	under:SetPoint("BOTTOMLEFT", fs, "BOTTOMLEFT", 0, -5)
	under:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 0, -5)
	Color(under, C.accent)
	b.under = under
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", -4, 2)
	hl:SetPoint("BOTTOMRIGHT", 4, -2)
	Color(hl, C.hover)
	b:SetScript("OnClick", onClick)
	function b:SetSelected(on)
		under:SetShown(on)
		if on then
			fs:SetTextColor(C.title[1], C.title[2], C.title[3])
		else
			fs:SetTextColor(C.sub[1], C.sub[2], C.sub[3])
		end
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
-- 체크박스 (직접 그린 네모)
------------------------------------------------------------------------
function UI.Check(parent, label, get, set, desc)
	local C = UI.COL
	local cb = CreateFrame("Button", nil, parent)
	cb:SetSize(18, 18)
	local box = cb:CreateTexture(nil, "BACKGROUND")
	box:SetAllPoints()
	Color(box, C.shade, 0.15)
	UI.Outline(cb, { C.edge[1], C.edge[2], C.edge[3], 0.8 })
	local mark = cb:CreateTexture(nil, "ARTWORK")
	mark:SetPoint("TOPLEFT", 4, -4)
	mark:SetPoint("BOTTOMRIGHT", -4, 4)
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
	-- 글자를 눌러도 체크되도록
	local hit = CreateFrame("Button", nil, cb)
	hit:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
	hit:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2, -2)
	hit:SetScript("OnClick", function() cb:Click() end)
	cb:SetChecked(false)
	return cb
end

------------------------------------------------------------------------
-- 스크롤 영역 (마우스 휠 + 가는 스크롤 막대)
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
	bar:SetWidth(6)
	bar:SetPoint("TOPLEFT", sf, "TOPRIGHT", 6, 0)
	bar:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 6, 0)
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetPoint("TOP"); track:SetPoint("BOTTOM"); track:SetWidth(1)
	Color(track, C.line)
	local thumb = bar:CreateTexture(nil, "OVERLAY")
	Color(thumb, C.edge, 0.75)
	thumb:SetSize(6, 40)
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
-- 진행 막대
------------------------------------------------------------------------
function UI.Bar(parent, w, h)
	local C = UI.COL
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetSize(w or 100, h or 10)
	bar:SetStatusBarTexture(WHITE)
	bar:SetStatusBarColor(C.bar[1], C.bar[2], C.bar[3])
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	Color(bg, C.barBg)
	UI.Outline(bar, { C.edge[1], C.edge[2], C.edge[3], 0.5 })
	local text = bar:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	text:SetPoint("CENTER", 0, 0)
	text:SetTextColor(C.text[1], C.text[2], C.text[3])
	bar.text = text
	return bar
end

------------------------------------------------------------------------
-- 입력창 (밑줄만 있는 노트 줄)
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
	Color(bg, C.shade)
	local under = eb:CreateTexture(nil, "ARTWORK")
	under:SetHeight(1)
	under:SetPoint("BOTTOMLEFT"); under:SetPoint("BOTTOMRIGHT")
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
