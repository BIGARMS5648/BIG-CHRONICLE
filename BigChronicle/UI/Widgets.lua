-- BIG CHRONICLE :: UI 공용 위젯 / 테마
-- 가죽 장정의 도감 수첩: 금 모서리 창틀, 사다리꼴 탭, 가죽 버튼, 찢어진 양피지 칸.
-- 그림은 모두 art/ 폴더의 에셋 시트에서 잘라 낸 조각이다 (UI/Atlas.lua, tools/slice_assets.py).
-- 글꼴은 게임 기본 글꼴을 쓴다.

local ADDON, ns = ...
local UI = ns.UI or {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
UI.WHITE = WHITE
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
UI.MEDIA = MEDIA
local ATLAS = UI.ATLAS
local function Tex(name) return MEDIA .. "UI\\" .. name end
UI.Tex = Tex
UI.SCALE = 0.7   -- 조각을 화면에 그리는 기본 배율 (원본 픽셀 대비)

UI.TEX = {
	seal = Tex "Seal", sealDex = Tex "SealDex", sealAch = Tex "SealAch",
	-- 효과 입자 (Kenney Particle Pack, CC0)
	dust = MEDIA .. "FX\\Star", glow = MEDIA .. "FX\\Glow", ink = MEDIA .. "FX\\Crumb", magic = MEDIA .. "FX\\Magic",
}
UI.ICON = setmetatable({}, { __index = function(_, k) return Tex(k) end })

-- 가죽 위 글씨 색 (테마와 상관없이 같다)
UI.LEATHER = {
	text  = { 0.93, 0.87, 0.74 },
	sub   = { 0.80, 0.72, 0.58 },
	muted = { 0.62, 0.54, 0.42 },
	title = { 0.98, 0.84, 0.52 },   -- 금박 글씨
	accent = { 0.98, 0.76, 0.42 },
	bright = { 1.00, 0.96, 0.82 },  -- 금빛 버튼 위 글씨
	ink   = { 0.20, 0.10, 0.04 },   -- 양피지 바탕 위 글씨
	gold  = { 0.90, 0.72, 0.38 },
}

------------------------------------------------------------------------
-- 테마: 양피지 칸의 색 (양피지 한 가지)
------------------------------------------------------------------------
UI.THEMES = {
	light = {
		name = "양피지",
		page   = { 1, 1, 1 },             -- 양피지 그림 그대로
		page2  = { 0.88, 0.80, 0.65 },
		edge   = { 0.36, 0.22, 0.12 },
		line   = { 0.40, 0.26, 0.14, 0.45 },
		shade  = { 0.40, 0.25, 0.10, 0.08 },
		text   = { 0.16, 0.10, 0.06 },
		sub    = { 0.33, 0.23, 0.14 },
		muted  = { 0.48, 0.38, 0.27 },
		title  = { 0.22, 0.10, 0.05 },
		accent = { 0.55, 0.12, 0.07 },
		hover  = { 0.55, 0.35, 0.10, 0.12 },
		sel    = { 0.80, 0.52, 0.12, 0.30 },   -- 금빛 띠
		bar    = { 0.62, 0.16, 0.10 },
		barBg  = { 0.30, 0.18, 0.08, 0.12 },
		creature = { 0.08, 0.28, 0.30 },
		rare   = { 0.40, 0.15, 0.48 },
		good   = { 0.20, 0.36, 0.10 },
		shadow = { 0, 0, 0, 0.55 },
		fontShadow = false,
		-- 기록에 저장된 강조색(어두운 배경용)을 양피지 위에서 읽기 좋은 잉크색으로 바꿔 보여 준다
		remap = {
			e6c27a = "8a5a12", ffd100 = "8f6200", ff9940 = "a2470d", ff6060 = "a31f17",
			["7fd4ff"] = "155f6e", ["9be27a"] = "2f6a1f", c58cff = "6b2fa0", d4af37 = "7a5410",
			e8d9b0 = "4a3520", ["9d9d9d"] = "6f6457", ["8a8070"] = "7d6f5c", ["60ff60"] = "2a7a2f",
			ff5050 = "a02020", f0e6c8 = "4a3520", ffffff = "2a1c0e",
		},
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
	toastName  = "BigChronicleFontToastName",       -- 발견 알림의 몬스터 이름 (크게, 제목 강조 글꼴)
	toastNameS = "BigChronicleFontToastNameSmall",  -- 이름이 길 때
	brandSmall = "BigChronicleFontBrandSmall",
}

-- 제목을 강조하는 게임 기본 글꼴 (한국어 클라이언트의 '굵은 글꼴'). 다른 언어에서는 퀘스트 제목 글꼴을 쓴다.
local TITLE_FILE = { koKR = "Fonts\\2002B.TTF" }
local TITLE_BASE = { "QuestTitleFont", "QuestTitleFontBlackShadow", "GameFontNormalLarge", "GameFontNormal" }

-- 게임 기본 글꼴을 바탕으로 크기와 색만 바꾼 글꼴을 만든다
-- file: 먼저 써 볼 게임 글꼴 파일 (못 쓰면 baseNames 글꼴을 그대로 쓴다)
local function MakeFont(name, baseNames, size, color, shadow, file)
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
	if file and font.SetFont then
		local ok, done = pcall(font.SetFont, font, file, size, "")
		-- 파일을 못 읽으면 SetFont가 false를 돌려준다 → 위에서 정한 글꼴이 그대로 남는다
		if ok and done == false and base and base.GetFont then
			local ok2, p, _, flags = pcall(base.GetFont, base)
			if ok2 and p then pcall(font.SetFont, font, p, size, flags or "") end
		end
	end
	if font.SetTextColor then font:SetTextColor(color[1], color[2], color[3]) end
	if font.SetShadowOffset then
		if shadow then
			font:SetShadowOffset(1, -1)
			font:SetShadowColor(0, 0, 0, 0.9)
		else
			font:SetShadowOffset(0, 0)
			font:SetShadowColor(0, 0, 0, 0)
		end
	end
end

function UI:InitTheme()
	if self.themeReady then return end
	self.themeReady = true
	local theme = self.THEMES.light
	self.theme = theme
	self.themeId = "light"
	for k, v in pairs(theme) do self.COL[k] = v end
	self.COL.paperTop, self.COL.paperBottom = theme.page, theme.page
	local C, L, sh = self.COL, self.LEATHER, theme.fontShadow
	local BASE, STRONG = { "GameFontHighlight", "GameFontNormal" }, { "GameFontNormalLarge", "GameFontNormal" }
	MakeFont(self.F.title,   STRONG, 20, C.title, sh)
	MakeFont(self.F.header,  STRONG, 16, C.title, sh)
	MakeFont(self.F.heading, BASE, 13.5, C.accent, sh)
	MakeFont(self.F.button,  BASE, 12.5, L.title, true)
	-- 탭 이름은 제목 강조 글꼴로
	local locale = GetLocale and GetLocale() or ""
	MakeFont(self.F.tab,     TITLE_BASE, 15, L.text, true, TITLE_FILE[locale])
	-- 발견 알림에서 몬스터 이름을 크고 진하게
	MakeFont(self.F.toastName,  TITLE_BASE, 19, { 0.13, 0.06, 0.03 }, false, TITLE_FILE[locale])
	MakeFont(self.F.toastNameS, TITLE_BASE, 16, { 0.13, 0.06, 0.03 }, false, TITLE_FILE[locale])
	MakeFont(self.F.label,   BASE, 11, C.muted, sh)
	MakeFont(self.F.body,    BASE, 13, C.text, sh)
	MakeFont(self.F.small,   BASE, 11.5, C.sub, sh)
	MakeFont(self.F.tiny,    BASE, 10.5, C.muted, sh)
	MakeFont(self.F.key,     BASE, 10.5, L.text, true)
	MakeFont(self.F.brand,   STRONG, 18, L.title, true)
	MakeFont(self.F.brandSmall, BASE, 10.5, L.sub, true)
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
		fs:SetShadowColor(0, 0, 0, 0.9)
	end
end

-- 금빛·양피지 바탕 위에 놓는 글씨: 짙은 잉크, 그림자 없음
function UI.OnGold(fs, c)
	c = c or UI.LEATHER.ink
	fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
	if fs.SetShadowOffset then
		fs:SetShadowOffset(0, 0)
		fs:SetShadowColor(0, 0, 0, 0)
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

------------------------------------------------------------------------
-- 에셋 조각 그리기
------------------------------------------------------------------------
-- 조각 하나를 그대로 (늘리지 않고) 그리는 텍스처. scale 을 주면 크기도 잡는다.
function UI.Sprite(parent, name, layer, sub, scale)
	local info = ATLAS[name]
	local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
	t:SetTexture(Tex(name))
	if scale and info then t:SetSize(info.w * scale, info.h * scale) end
	return t
end

-- 가로·세로로 반복되는 무늬. inset 만큼 안쪽에 깐다.
function UI.Tile(frame, name, layer, sub, inset, scale)
	local info = ATLAS[name]
	scale = scale or UI.SCALE
	inset = inset or 0
	local tex = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
	tex:SetPoint("TOPLEFT", inset, -inset)
	tex:SetPoint("BOTTOMRIGHT", -inset, inset)
	tex:SetTexture(Tex(name), "REPEAT", "REPEAT")
	local tw, th = info.tile * scale, (info.tileH or info.tile) * scale
	local function update()
		local w, h = (frame:GetWidth() or 0) - inset * 2, (frame:GetHeight() or 0) - inset * 2
		if w > 0 and h > 0 then tex:SetTexCoord(0, w / tw, 0, h / th) end
	end
	frame:HookScript("OnSizeChanged", update)
	update()
	tex.UpdateTiling = update
	return tex
end

-- 늘어나는 조각 (가장자리는 그대로 두고 가운데만 늘린다)
--   가로 3조각: Atlas 에 l, r 만 있는 조각 (버튼·탭·입력칸) — 높이에 맞춰 배율이 정해진다
--   9조각: l, r, t, b 가 모두 있는 조각 (판·틀) — opts.scale 배율로 그린다
-- opts: layer, sub, scale, noCenter(가운데를 비운다)
function UI.Slice(frame, name, opts)
	opts = opts or {}
	local layer, sub = opts.layer or "BACKGROUND", opts.sub or 0
	local s = { name = name }
	local parts = {}
	local function piece(key)
		local t = frame:CreateTexture(nil, layer, nil, sub)
		parts[key] = t
		return t
	end
	local info, nine
	local function layout()
		info = ATLAS[s.name]
		nine = (info.t or 0) > 0
		local w, h = frame:GetWidth() or 0, frame:GetHeight() or 0
		local pad = info.pad or 0
		local sc = opts.scale
		if not sc then sc = h > 0 and h / (info.h - pad * 2) or UI.SCALE end
		local l, r, t, b = (info.l or 0) * sc, (info.r or 0) * sc, (info.t or 0) * sc, (info.b or 0) * sc
		local p = pad * sc
		-- 조각이 프레임보다 작아지지 않도록 끝 조각 폭을 줄인다
		local maxCap = (w + p * 2) / 2
		if l > maxCap then l = maxCap end
		if r > maxCap then r = maxCap end
		local u1, u2 = (info.l or 0) / info.w, 1 - (info.r or 0) / info.w
		local v1, v2 = (info.t or 0) / info.h, 1 - (info.b or 0) / info.h
		local path = Tex(s.name)
		local function set(key, c1, c2, c3, c4)
			local tx = parts[key]
			tx:SetTexture(path)
			tx:SetTexCoord(c1, c2, c3, c4)
			tx:ClearAllPoints()
			return tx
		end
		if nine then
			local tl = set("tl", 0, u1, 0, v1); tl:SetPoint("TOPLEFT", -p, p); tl:SetSize(l, t)
			local tr = set("tr", u2, 1, 0, v1); tr:SetPoint("TOPRIGHT", p, p); tr:SetSize(r, t)
			local bl = set("bl", 0, u1, v2, 1); bl:SetPoint("BOTTOMLEFT", -p, -p); bl:SetSize(l, b)
			local br = set("br", u2, 1, v2, 1); br:SetPoint("BOTTOMRIGHT", p, -p); br:SetSize(r, b)
			local tt = set("t", u1, u2, 0, v1); tt:SetPoint("TOPLEFT", tl, "TOPRIGHT"); tt:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT")
			local bb = set("b", u1, u2, v2, 1); bb:SetPoint("TOPLEFT", bl, "TOPRIGHT"); bb:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
			local ll = set("l", 0, u1, v1, v2); ll:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); ll:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT")
			local rr = set("r", u2, 1, v1, v2); rr:SetPoint("TOPLEFT", tr, "BOTTOMLEFT"); rr:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
			if not opts.noCenter then
				local cc = set("c", u1, u2, v1, v2); cc:SetPoint("TOPLEFT", tl, "BOTTOMRIGHT"); cc:SetPoint("BOTTOMRIGHT", br, "TOPLEFT")
			end
		else
			local ll = set("l", 0, u1, 0, 1); ll:SetPoint("TOPLEFT", -p, p); ll:SetPoint("BOTTOMLEFT", -p, -p); ll:SetWidth(l)
			local rr = set("r", u2, 1, 0, 1); rr:SetPoint("TOPRIGHT", p, p); rr:SetPoint("BOTTOMRIGHT", p, -p); rr:SetWidth(r)
			local cc = set("c", u1, u2, 0, 1); cc:SetPoint("TOPLEFT", ll, "TOPRIGHT"); cc:SetPoint("BOTTOMRIGHT", rr, "BOTTOMLEFT")
		end
	end
	info = ATLAS[name]
	if (info.t or 0) > 0 then
		for _, k in ipairs({ "tl", "tr", "bl", "br", "t", "b", "l", "r" }) do piece(k) end
		if not opts.noCenter then piece("c") end
	else
		piece("l"); piece("r"); piece("c")
	end
	function s:SetSprite(n)
		if n ~= self.name then
			self.name = n
			layout()
		end
	end
	function s:SetVertexColor(...)
		for _, t in pairs(parts) do t:SetVertexColor(...) end
	end
	function s:SetAlpha(a)
		for _, t in pairs(parts) do t:SetAlpha(a) end
	end
	function s:SetShown(v)
		for _, t in pairs(parts) do t:SetShown(v) end
	end
	s.Update = layout
	s.parts = parts
	frame:HookScript("OnSizeChanged", layout)
	layout()
	return s
end

-- 창틀: 금 모서리 + 박음질 가죽 테두리 + 안쪽의 짙은 가죽
-- opts.scale: 배율, opts.ornament: 위아래 가운데 장식 ("top", "bottom", "both")
-- opts.fixedW: 무늬 반복 횟수를 고정할 폭 (선택, 크기가 바뀌어도 무늬가 늘지 않게)
function UI.WindowFrame(frame, opts)
	opts = opts or {}
	local F = ATLAS.Frame
	local sc = opts.scale or UI.SCALE
	local c, tp, sd = F.corner * sc, F.top * sc, F.side * sc
	local out = { squish = {} }
	local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	bg:SetPoint("TOPLEFT", 9, -9)
	bg:SetPoint("BOTTOMRIGHT", -9, 9)
	bg:SetTexture(Tex("LeatherTile"), "REPEAT", "REPEAT")
	local tile = ATLAS.LeatherTile.tile * sc
	local function retile()
		local w, h = opts.fixedW or (frame:GetWidth() or 0), frame:GetHeight() or 0
		if w > 0 and h > 0 then bg:SetTexCoord(0, (w - 18) / tile, 0, (h - 18) / tile) end
	end
	out.bg = bg
	local function corner(name, point)
		local t = frame:CreateTexture(nil, "BORDER", nil, 2)
		t:SetTexture(Tex(name))
		t:SetSize(c, c)
		t:SetPoint(point)
		out.squish[#out.squish + 1] = { t, c }
		return t
	end
	local tl, tr = corner("FrameTL", "TOPLEFT"), corner("FrameTR", "TOPRIGHT")
	local bl, br = corner("FrameBL", "BOTTOMLEFT"), corner("FrameBR", "BOTTOMRIGHT")
	local top = frame:CreateTexture(nil, "BORDER", nil, 1)
	top:SetTexture(Tex("FrameT"), "REPEAT", "REPEAT")
	top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT"); top:SetHeight(tp)
	local bot = frame:CreateTexture(nil, "BORDER", nil, 1)
	bot:SetTexture(Tex("FrameB"), "REPEAT", "REPEAT")
	bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT"); bot:SetHeight(tp)
	local etile = ATLAS.FrameT.tile * sc
	local function reedge()
		local w = (opts.fixedW or (frame:GetWidth() or 0)) - c * 2
		if w > 0 then
			top:SetTexCoord(0, w / etile, 0, 1)
			bot:SetTexCoord(0, w / etile, 0, 1)
		end
	end
	local left = frame:CreateTexture(nil, "BORDER", nil, 1)
	left:SetTexture(Tex("FrameL"))
	left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT"); left:SetWidth(sd)
	local right = frame:CreateTexture(nil, "BORDER", nil, 1)
	right:SetTexture(Tex("FrameR"))
	right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT"); right:SetWidth(sd)
	out.squish[#out.squish + 1] = { left, sd }
	out.squish[#out.squish + 1] = { right, sd }
	if opts.ornament == "top" or opts.ornament == "both" then
		local o = UI.Sprite(frame, "OrnamentTop", "BORDER", 3, sc)
		o:SetPoint("TOP", 0, 0)
		out.squish[#out.squish + 1] = { o, ATLAS.OrnamentTop.w * sc }
	end
	if opts.ornament == "bottom" or opts.ornament == "both" then
		local o = UI.Sprite(frame, "OrnamentBottom", "BORDER", 3, sc)
		o:SetPoint("BOTTOM", 0, 0)
		out.squish[#out.squish + 1] = { o, ATLAS.OrnamentBottom.w * sc }
	end
	local function update() retile(); reedge() end
	if not opts.fixedW then frame:HookScript("OnSizeChanged", update) end
	update()
	return out
end

-- 양피지 칸: 반복되는 양피지 바탕 + 찢기고 그을린 가장자리
function UI.Paper(frame, opts)
	opts = opts or {}
	local C = UI.COL
	local sc = opts.scale or UI.SCALE
	local info = ATLAS.PaperEdge
	local inset = (info.l - 13 - info.pad) * sc
	local tint = opts.tint or C.page
	local tile = UI.Tile(frame, "ParchmentTile", "BACKGROUND", -6, inset, sc)
	UI.Tint(tile, tint)
	local edge = UI.Slice(frame, "PaperEdge", { layer = "BACKGROUND", sub = -5, scale = sc, noCenter = true })
	edge:SetVertexColor(tint[1], tint[2], tint[3])
	frame.paper, frame.paperEdge = tile, edge
	return tile
end

-- 장식 구분선: 가운데 장식과 양 끝은 그대로 두고 선만 늘린다
function UI.Divider(parent, width, color, name, scale)
	name = name or "Divider"
	local info = ATLAS[name]
	local sc = scale or UI.SCALE * 0.9
	local f = CreateFrame("Frame", nil, parent)
	local h = info.h * sc
	f:SetSize(width or 300, h)
	local endW, midW = 34, name == "Divider" and 34 or 50   -- 원본 픽셀
	local w = info.w
	local function part(u0, u1)
		local t = f:CreateTexture(nil, "ARTWORK")
		t:SetTexture(Tex(name))
		t:SetTexCoord(u0 / w, u1 / w, 0, 1)
		t:SetHeight(h)
		if color then UI.Tint(t, color) end
		return t
	end
	local l = part(0, endW); l:SetPoint("LEFT"); l:SetWidth(endW * sc)
	local r = part(w - endW, w); r:SetPoint("RIGHT"); r:SetWidth(endW * sc)
	local m = part(w / 2 - midW, w / 2 + midW); m:SetPoint("CENTER"); m:SetWidth(midW * 2 * sc)
	local ll = part(endW, w / 2 - midW); ll:SetPoint("LEFT", l, "RIGHT"); ll:SetPoint("RIGHT", m, "LEFT")
	local rl = part(w / 2 + midW, w - endW); rl:SetPoint("LEFT", m, "RIGHT"); rl:SetPoint("RIGHT", r, "LEFT")
	f.line, f.orn = ll, m
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
--   기본: 양피지 칸
--   opts.leather: 창의 가죽 바탕 위에 그대로 놓는 빈 자리 (왼쪽 목록용)
function UI.Section(parent, opts)
	opts = opts or {}
	local f = CreateFrame("Frame", nil, parent)
	if opts.leather then
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

-- 아이콘 둘레의 금테
function UI.FrameIcon(icon, pad, parent)
	parent = parent or icon:GetParent()
	local info = ATLAS.IconFrame
	local t = parent:CreateTexture(nil, "OVERLAY", nil, 1)
	local k = (pad or 4) + 2
	t:SetPoint("TOPLEFT", icon, "TOPLEFT", -k, k)
	t:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", k, -k)
	t:SetTexture(Tex("IconFrame"))
	return t
end

------------------------------------------------------------------------
-- 단축키·개수 배지 (금테 두른 짙은 알약 모양)
------------------------------------------------------------------------
function UI.KeyBadge(parent, key)
	local L = UI.LEATHER
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(24, 18)
	UI.Slice(f, "Badge", { layer = "BACKGROUND" })
	local fs = f:CreateFontString(nil, "OVERLAY", UI.F.key)
	fs:SetPoint("CENTER", 0, 0)
	UI.OnLeather(fs, L.text)
	f.text = fs
	function f:SetKey(k)
		fs:SetText(k)
		local w = (fs:GetStringWidth() or 8) + 16
		self:SetWidth(math.max(24, w))
	end
	f:SetKey(key)
	return f
end
UI.Badge = UI.KeyBadge

------------------------------------------------------------------------
-- 버튼: 금테 두른 가죽 버튼. 선택되면(또는 style "primary") 금빛 버튼이 된다.
------------------------------------------------------------------------
function UI.Button(parent, text, w, h, onClick, key, style)
	local L = UI.LEATHER
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w or 80, h or 26)
	local primary = style == "primary" or style == "red"
	local bg = UI.Slice(b, primary and "ButtonGold" or "Button", { layer = "BACKGROUND" })
	b.bg = bg
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 4, -4)
	hl:SetPoint("BOTTOMRIGHT", -4, 4)
	hl:SetColorTexture(1, 0.85, 0.5, 0.12)
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
		local gold = on or primary
		bg:SetSprite(gold and "ButtonGold" or "Button")
		UI.OnLeather(fs, gold and L.bright or L.title)
	end
	b:SetSelected(false)
	b:HookScript("OnEnable", function(self) self:SetAlpha(1) end)
	b:HookScript("OnDisable", function(self) self:SetAlpha(0.45) end)
	return b
end

-- 색인 탭: 사다리꼴 가죽 탭. 고른 탭은 양피지빛으로 바뀐다.
function UI.Tab(parent, text, key, onClick, _, icon)
	local L = UI.LEATHER
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(170, 36)
	local bg = UI.Slice(b, "Tab", { layer = "BACKGROUND" })
	b.bg = bg
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 18, -4)
	hl:SetPoint("BOTTOMRIGHT", -18, 2)
	hl:SetColorTexture(1, 0.85, 0.5, 0.10)
	pcall(hl.SetBlendMode, hl, "ADD")
	local fs = b:CreateFontString(nil, "OVERLAY", UI.F.tab)
	fs:SetPoint("CENTER", icon and 13 or 0, 0)
	fs:SetText(text)
	b.label = fs
	if icon then
		local ic = b:CreateTexture(nil, "ARTWORK")
		ic:SetSize(26, 26)
		ic:SetPoint("RIGHT", fs, "LEFT", -6, 0)
		ic:SetTexture(icon)
		b.icon = ic
	end
	b:SetScript("OnClick", onClick)
	function b:SetSelected(on)
		self.selected = on
		bg:SetSprite(on and "TabActive" or "Tab")
		if on then UI.OnGold(fs) else UI.OnLeather(fs, L.text) end
	end
	b:SetSelected(false)
	return b
end

-- 목록의 한 줄
--   기본: 가죽 버튼 (왼쪽 목록). 고르면 금빛 버튼, opts.badge 면 오른쪽 글자를 배지 안에 넣는다.
--   opts.flat: 양피지 위의 줄. 고르면 금빛 띠.
local function FlatRow(parent, height)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(height or 24)
	local sel = b:CreateTexture(nil, "BACKGROUND")
	sel:SetPoint("TOPLEFT", 0, -1)
	sel:SetPoint("BOTTOMRIGHT", -2, 1)
	UI.Gradient(sel, "HORIZONTAL", { C.sel[1], C.sel[2], C.sel[3], math.min(1, C.sel[4] * 1.8) }, { C.sel[1], C.sel[2], C.sel[3], C.sel[4] * 0.5 })
	sel:Hide()
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 0, -1)
	hl:SetPoint("BOTTOMRIGHT", -2, 1)
	Color(hl, C.hover)
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
	b:SetHeight(height or 28)
	local bg = UI.Slice(b, "Button", { layer = "BACKGROUND" })
	b.bg = bg
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 4, -4)
	hl:SetPoint("BOTTOMRIGHT", -4, 4)
	hl:SetColorTexture(1, 0.85, 0.5, 0.12)
	pcall(hl.SetBlendMode, hl, "ADD")
	local label = UI.Text(b, UI.F.body)
	label:SetPoint("LEFT", 14, 0)
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
		badge:SetSize(34, math.max(14, (height or 28) - 11))
		badge:SetPoint("RIGHT", -8, 0)
		UI.Slice(badge, "Badge", { layer = "BACKGROUND" })
		right:SetParent(badge)
		right:SetPoint("CENTER", badge, "CENTER", 0, 0)
		right:SetJustifyH("CENTER")
		b.badge = badge
		label:SetPoint("RIGHT", badge, "LEFT", -4, 0)
		local origSetText = right.SetText
		right.SetText = function(self, t)
			origSetText(self, t)
			badge:SetShown(t ~= nil and t ~= "")
			badge:SetWidth(math.max(28, (self:GetStringWidth() or 10) + 16))
		end
	else
		right:SetPoint("RIGHT", -12, 0)
		label:SetPoint("RIGHT", right, "LEFT", -4, 0)
	end
	UI.OnLeather(right, L.text)
	function b:SetSelected(on)
		self.selected = on
		bg:SetSprite(on and "ButtonGold" or "Button")
		UI.OnLeather(label, on and L.bright or L.text)
		if not badge then UI.OnLeather(right, on and L.bright or L.accent) end
	end
	function b:SetDim()
		TextColor(label, L.muted)
	end
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
-- 체크박스: 금테 두른 네모 칸. light = 가죽 위에 놓을 때 (밝은 글씨)
------------------------------------------------------------------------
function UI.Check(parent, label, get, set, desc, light)
	local L = UI.LEATHER
	local cb = CreateFrame("Button", nil, parent)
	cb:SetSize(18, 18)
	local box = cb:CreateTexture(nil, "ARTWORK")
	box:SetPoint("TOPLEFT", -3, 3)
	box:SetPoint("BOTTOMRIGHT", 3, -3)
	box:SetTexture(Tex("CheckBox"))
	local hl = cb:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 0.85, 0.5, 0.2)
	pcall(hl.SetBlendMode, hl, "ADD")
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
		box:SetTexture(Tex(self.checked and "CheckBoxOn" or "CheckBox"))
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
	local sf = CreateFrame("ScrollFrame", nil, parent)
	local child = CreateFrame("Frame", nil, sf)
	child:SetSize(10, 10)
	sf:SetScrollChild(child)
	sf.child = child

	-- 금테 스크롤바: 홈은 위 끝 · 반복되는 가운데 · 아래 끝으로 나눠 늘이지 않고 이어 붙인다
	local A = ATLAS
	local W = 18
	local k = W / A.ScrollTrackMid.w
	local arrowW = W * A.ScrollUp.w / A.ScrollTrackMid.w
	local arrowH = arrowW * A.ScrollUp.h / A.ScrollUp.w
	local bar = CreateFrame("Slider", nil, sf)
	bar:SetOrientation("VERTICAL")
	bar:SetWidth(W)
	bar:SetPoint("TOPLEFT", sf, "TOPRIGHT", 4, -(arrowH - 2))
	bar:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 4, arrowH - 2)
	local capTop = bar:CreateTexture(nil, "BACKGROUND", nil, 1)
	capTop:SetTexture(Tex("ScrollTrackTop"))
	capTop:SetPoint("TOPLEFT"); capTop:SetPoint("TOPRIGHT")
	capTop:SetHeight(A.ScrollTrackTop.h * k)
	local capBottom = bar:CreateTexture(nil, "BACKGROUND", nil, 1)
	capBottom:SetTexture(Tex("ScrollTrackBottom"))
	capBottom:SetPoint("BOTTOMLEFT"); capBottom:SetPoint("BOTTOMRIGHT")
	capBottom:SetHeight(A.ScrollTrackBottom.h * k)
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetTexture(Tex("ScrollTrackMid"), "CLAMP", "REPEAT")
	track:SetPoint("TOPLEFT", capTop, "BOTTOMLEFT")
	track:SetPoint("BOTTOMRIGHT", capBottom, "TOPRIGHT")
	local tileH = A.ScrollTrackMid.tileH * k
	local function FitTrack()
		local h = (bar:GetHeight() or 0) - capTop:GetHeight() - capBottom:GetHeight()
		track:SetTexCoord(0, 1, 0, math.max(0.01, h / tileH))
	end
	bar:SetScript("OnSizeChanged", FitTrack)
	FitTrack()
	-- 손잡이는 원래 비율 그대로 (늘이지 않는다)
	local thumb = bar:CreateTexture(nil, "OVERLAY")
	thumb:SetTexture(Tex("ScrollThumb"))
	local thumbW = W * A.ScrollThumb.w / A.ScrollTrackMid.w
	thumb:SetSize(thumbW, thumbW * A.ScrollThumb.h / A.ScrollThumb.w)
	bar:SetThumbTexture(thumb)
	bar:SetMinMaxValues(0, 0)
	bar:SetValue(0)
	bar:SetValueStep(1)
	bar:SetScript("OnValueChanged", function(_, v)
		sf:SetVerticalScroll(v)
		if sf.onScroll then sf.onScroll(v) end   -- 보이는 줄만 그리는 목록이 쓴다
	end)
	sf.bar = bar
	local function arrow(name, point, rel, dir)
		local a = CreateFrame("Button", nil, bar)
		a:SetSize(arrowW, arrowW * A[name].h / A[name].w)
		a:SetPoint(point, bar, rel, 0, 0)
		local t = a:CreateTexture(nil, "ARTWORK")
		t:SetAllPoints()
		t:SetTexture(Tex(name))
		local hl = a:CreateTexture(nil, "HIGHLIGHT")
		hl:SetPoint("TOPLEFT", 3, -3)
		hl:SetPoint("BOTTOMRIGHT", -3, 3)
		hl:SetColorTexture(1, 0.85, 0.5, 0.2)
		pcall(hl.SetBlendMode, hl, "ADD")
		a:SetScript("OnClick", function() sf:ScrollBy(dir * 60) end)
		return a
	end
	arrow("ScrollUp", "BOTTOM", "TOP", -1)
	arrow("ScrollDown", "TOP", "BOTTOM", 1)

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
-- 진행 막대: 가죽 홈 안을 금빛 막대가 채운다
------------------------------------------------------------------------
function UI.Bar(parent, w, h)
	local L = UI.LEATHER
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetSize(w or 100, h or 12)
	bar:SetStatusBarTexture(Tex("BarFill"))
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	UI.Slice(bar, "BarTrack", { layer = "BACKGROUND" })
	local text = bar:CreateFontString(nil, "OVERLAY", UI.F.tiny)
	text:SetPoint("CENTER", 0, 0)
	UI.OnLeather(text, { 1, 0.97, 0.90 })
	bar.text = text
	return bar
end

------------------------------------------------------------------------
-- 입력창 (금테 두른 짙은 칸에 밝은 글씨). search = 돋보기가 그려진 검색칸
------------------------------------------------------------------------
function UI.EditBox(parent, w, h, placeholder, search)
	local L = UI.LEATHER
	local eb = CreateFrame("EditBox", nil, parent)
	eb:SetSize(w or 200, h or 26)
	eb:SetAutoFocus(false)
	eb:SetFontObject(UI.F.body)
	eb:SetTextColor(L.text[1], L.text[2], L.text[3])
	local left = search and 30 or 12
	eb:SetTextInsets(left, 10, 2, 2)
	eb:SetMaxLetters(240)
	UI.Slice(eb, search and "FieldSearch" or "Field", { layer = "BACKGROUND" })
	local ph = UI.Text(eb, UI.F.small)
	ph:SetPoint("LEFT", left + 1, 0)
	ph:SetJustifyV("MIDDLE")
	ph:SetText(placeholder or "")
	UI.OnLeather(ph, L.muted)
	eb.placeholder = ph
	local function sync(self)
		local t = self:GetText()
		ph:SetShown((t == nil or t == "") and not self:HasFocus())
	end
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	eb:SetScript("OnEditFocusGained", sync)
	eb:SetScript("OnEditFocusLost", sync)
	eb:HookScript("OnTextChanged", sync)
	eb.SyncPlaceholder = sync
	return eb
end
