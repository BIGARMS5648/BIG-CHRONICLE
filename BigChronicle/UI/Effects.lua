-- BIG CHRONICLE :: 화면 연출
-- 외부 텍스처 없이 색 텍스처와 OnUpdate만으로 만든 작은 애니메이션들:
--   Tween(움직임) · Burst(반짝이 입자) · Pulse(은은한 깜빡임) · Stamp(도장 찍기)
--   ChapterCard(화면 가운데 장 제목) · Sweep(책장 넘김)

local ADDON, ns = ...
local UI = ns.UI
local E = {}
ns.Effects = E

local WHITE = "Interface\\Buttons\\WHITE8X8"
local CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local function Enabled()
	return ns.db and ns.db.effects ~= false
end
E.Enabled = Enabled

------------------------------------------------------------------------
-- 이징
------------------------------------------------------------------------
E.Ease = {
	linear = function(t) return t end,
	outCubic = function(t) return 1 - (1 - t) ^ 3 end,
	inCubic = function(t) return t ^ 3 end,
	inOut = function(t) return t < 0.5 and 4 * t ^ 3 or 1 - (-2 * t + 2) ^ 3 / 2 end,
	outBack = function(t)
		local c1 = 1.70158
		local c3 = c1 + 1
		return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
	end,
}

------------------------------------------------------------------------
-- 트윈: 같은 key로 다시 부르면 앞의 것을 대신한다
------------------------------------------------------------------------
local driver = CreateFrame("Frame")
driver:Hide()
local tweens = {}

driver:SetScript("OnUpdate", function(self, elapsed)
	local finished
	for key, tw in pairs(tweens) do
		tw.t = tw.t + elapsed
		if tw.t >= 0 then
			local p = tw.dur > 0 and math.min(1, tw.t / tw.dur) or 1
			local ok, err = pcall(tw.step, p)
			if not ok then ns:Error(err); p = 1 end
			if p >= 1 then
				finished = finished or {}
				finished[#finished + 1] = key
			end
		end
	end
	if finished then
		for _, key in ipairs(finished) do
			local tw = tweens[key]
			tweens[key] = nil
			if tw and tw.done then
				local ok, err = pcall(tw.done)
				if not ok then ns:Error(err) end
			end
		end
	end
	if not next(tweens) then self:Hide() end
end)

function E.Tween(key, dur, step, done, delay)
	tweens[key] = { t = -(delay or 0), dur = dur, step = step, done = done }
	driver:Show()
end

function E.Stop(key)
	tweens[key] = nil
end

------------------------------------------------------------------------
-- 효과음
------------------------------------------------------------------------
local SOUNDS = {
	open    = { "IG_QUEST_LOG_OPEN", "IG_SPELLBOOK_OPEN" },
	page    = { "IG_ABILITY_PAGE_TURN", "IG_QUEST_LOG_OPEN" },
	stamp   = { "UI_EPICLOOT_TOAST", "IG_QUEST_LIST_COMPLETE" },
	chapter = { "UI_LEGENDARY_LOOT_TOAST", "UI_EPICLOOT_TOAST", "LEVELUPSOUND" },
}
function E.Sound(kind)
	if not (ns.db and ns.db.sound) or not SOUNDKIT or not PlaySound then return end
	for _, key in ipairs(SOUNDS[kind] or {}) do
		local id = SOUNDKIT[key]
		if id then
			pcall(PlaySound, id)
			return
		end
	end
end

------------------------------------------------------------------------
-- 반짝이 입자
------------------------------------------------------------------------
local fxLayer, particles, freeTex = nil, {}, {}
local pdriver = CreateFrame("Frame")
pdriver:Hide()

local function Layer()
	if fxLayer then return fxLayer end
	fxLayer = CreateFrame("Frame", "BigChronicleFX", UIParent)
	fxLayer:SetAllPoints(UIParent)
	fxLayer:SetFrameStrata("FULLSCREEN_DIALOG")
	fxLayer:EnableMouse(false)
	return fxLayer
end

local function Acquire()
	local tex = table.remove(freeTex)
	if not tex then
		tex = Layer():CreateTexture(nil, "OVERLAY")
		tex:SetTexture(WHITE)
		tex:SetBlendMode("ADD")
	end
	tex:Show()
	return tex
end

pdriver:SetScript("OnUpdate", function(self, dt)
	local alive = 0
	for i = #particles, 1, -1 do
		local p = particles[i]
		p.age = p.age + dt
		if p.age >= p.life then
			p.tex:Hide()
			freeTex[#freeTex + 1] = p.tex
			table.remove(particles, i)
		else
			alive = alive + 1
			p.vy = p.vy - p.gravity * dt
			p.vx = p.vx * (1 - 1.5 * dt)
			p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
			local k = p.age / p.life
			p.tex:ClearAllPoints()
			p.tex:SetPoint("CENTER", fxLayer, "BOTTOMLEFT", p.x, p.y)
			p.tex:SetAlpha((1 - k) * (k < 0.1 and k * 10 or 1))
			p.rot = p.rot + p.spin * dt
			if p.tex.SetRotation then p.tex:SetRotation(p.rot) end
		end
	end
	if alive == 0 then self:Hide() end
end)

-- x, y: UIParent 기준 좌표. colors: { {r,g,b}, ... }
function E.Burst(x, y, opts)
	if not Enabled() or not x or not y then return end
	opts = opts or {}
	local colors = opts.colors or { { 1, 0.85, 0.4 }, { 1, 0.95, 0.7 }, { 0.95, 0.65, 0.25 } }
	local n = opts.count or 24
	Layer()
	for i = 1, n do
		local tex = Acquire()
		local c = colors[(i % #colors) + 1]
		tex:SetVertexColor(c[1], c[2], c[3])
		local size = math.random(3, opts.maxSize or 7)
		tex:SetSize(size, size)
		local ang = math.random() * math.pi * 2
		local speed = (opts.speed or 140) * (0.4 + math.random() * 0.8)
		particles[#particles + 1] = {
			tex = tex, x = x + math.random(-6, 6), y = y + math.random(-4, 4),
			vx = math.cos(ang) * speed * (opts.spreadX or 1.6), vy = math.sin(ang) * speed + (opts.lift or 60),
			gravity = opts.gravity or 120, age = 0, life = (opts.life or 1.1) * (0.6 + math.random() * 0.6),
			rot = math.pi / 4, spin = (math.random() - 0.5) * 8,
		}
	end
	pdriver:Show()
end

-- 프레임 가운데에서 터뜨린다
function E.BurstAt(frame, opts)
	if not frame or not frame.GetCenter then return end
	local x, y = frame:GetCenter()
	if not x then return end
	local s = (frame.GetEffectiveScale and frame:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
	E.Burst(x * s, y * s, opts)
end

------------------------------------------------------------------------
-- 은은한 깜빡임 (미니맵 버튼, 새 업적 표시)
------------------------------------------------------------------------
local pulses = {}
local pulseDriver = CreateFrame("Frame")
pulseDriver:Hide()
local clock = 0
pulseDriver:SetScript("OnUpdate", function(self, dt)
	clock = clock + dt
	local any = false
	for region, cfg in pairs(pulses) do
		any = true
		local a = cfg.min + (cfg.max - cfg.min) * (0.5 + 0.5 * math.sin(clock * cfg.speed))
		region:SetAlpha(a)
	end
	if not any then self:Hide() end
end)

function E.Pulse(region, on, cfg)
	if not region then return end
	if on and Enabled() then
		cfg = cfg or {}
		pulses[region] = { min = cfg.min or 0.15, max = cfg.max or 0.9, speed = cfg.speed or 3 }
		region:Show()
		pulseDriver:Show()
	else
		pulses[region] = nil
		if on then region:Show(); region:SetAlpha(cfg and cfg.max or 0.8) else region:Hide() end
	end
end

------------------------------------------------------------------------
-- 도장 찍기: 커다랗게 떨어져 '쿵' 하고 자리 잡는다
------------------------------------------------------------------------
function E.MakeSeal(parent, size, text)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(size, size)
	local disc = f:CreateTexture(nil, "ARTWORK")
	disc:SetAllPoints()
	disc:SetTexture(WHITE)
	disc:SetVertexColor(0.62, 0.10, 0.07)
	if disc.SetMask then pcall(disc.SetMask, disc, CIRCLE_MASK) end
	local ring = f:CreateTexture(nil, "OVERLAY")
	ring:SetPoint("TOPLEFT", 4, -4)
	ring:SetPoint("BOTTOMRIGHT", -4, 4)
	ring:SetTexture(WHITE)
	ring:SetVertexColor(0.85, 0.35, 0.28, 0.35)
	if ring.SetMask then pcall(ring.SetMask, ring, CIRCLE_MASK) end
	local inner = f:CreateTexture(nil, "OVERLAY", nil, 1)
	inner:SetPoint("TOPLEFT", 7, -7)
	inner:SetPoint("BOTTOMRIGHT", -7, 7)
	inner:SetTexture(WHITE)
	inner:SetVertexColor(0.55, 0.08, 0.05)
	if inner.SetMask then pcall(inner.SetMask, inner, CIRCLE_MASK) end
	local fs = f:CreateFontString(nil, "OVERLAY", UI.F.key)
	fs:SetPoint("CENTER", 0, 0)
	fs:SetTextColor(1, 0.82, 0.72)
	fs:SetText(text or "")
	f.text = fs
	f:Hide()
	return f
end

function E.Stamp(frame, key, holdFor)
	if not frame then return end
	if not Enabled() then
		frame:SetScale(1)
		frame:SetAlpha(1)
		frame:Show()
		return
	end
	frame:Show()
	frame:SetAlpha(0)
	E.Tween(key or tostring(frame), 0.32, function(p)
		local s = 2.4 - 1.4 * E.Ease.outBack(p)
		frame:SetScale(math.max(0.2, s))
		frame:SetAlpha(math.min(1, p * 2.5))
	end, function()
		frame:SetScale(1)
		E.BurstAt(frame, { count = 14, speed = 90, life = 0.7, colors = { { 1, 0.4, 0.3 }, { 1, 0.8, 0.5 } }, gravity = 60, lift = 20 })
		E.Sound("stamp")
		if holdFor then
			E.Tween((key or tostring(frame)) .. "-out", 0.6, function(p) frame:SetAlpha(1 - p) end,
				function() frame:Hide() end, holdFor)
		end
	end)
end

------------------------------------------------------------------------
-- 책장 넘김: 종이빛 띠가 왼쪽에서 오른쪽으로 쓸고 지나간다
------------------------------------------------------------------------
function E.MakeSweep(parent)
	local band = CreateFrame("Frame", nil, parent)
	band:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
	band:SetWidth(140)
	local C = UI.COL
	local c0 = { C.paperTop[1], C.paperTop[2], C.paperTop[3], 0 }
	local c1 = { C.paperTop[1], C.paperTop[2], C.paperTop[3], 0.95 }
	local l = band:CreateTexture(nil, "OVERLAY")
	l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT"); l:SetWidth(70)
	UI.Gradient(l, "HORIZONTAL", c0, c1)
	local r = band:CreateTexture(nil, "OVERLAY")
	r:SetPoint("TOPRIGHT"); r:SetPoint("BOTTOMRIGHT"); r:SetWidth(70)
	UI.Gradient(r, "HORIZONTAL", c1, c0)
	local edge = band:CreateTexture(nil, "OVERLAY", nil, 1)
	edge:SetPoint("TOP"); edge:SetPoint("BOTTOM"); edge:SetWidth(1)
	edge:SetColorTexture(C.edge[1], C.edge[2], C.edge[3], 0.35)
	band:Hide()
	return band
end

function E.Sweep(band, area, key)
	if not band or not area then return end
	if not Enabled() then return end
	local w = area:GetWidth() or 500
	band:ClearAllPoints()
	band:SetPoint("TOP", area, "TOP")
	band:SetPoint("BOTTOM", area, "BOTTOM")
	band:Show()
	E.Sound("page")
	E.Tween(key or "sweep", 0.4, function(p)
		local x = -140 + (w + 140) * E.Ease.inOut(p)
		band:ClearAllPoints()
		band:SetPoint("TOPLEFT", area, "TOPLEFT", x, 0)
		band:SetPoint("BOTTOMLEFT", area, "BOTTOMLEFT", x, 0)
		band:SetAlpha(1 - math.max(0, p - 0.8) * 5)
	end, function() band:Hide() end)
end

------------------------------------------------------------------------
-- 장 제목 카드: 화면 가운데 영화 자막처럼 떠오른다
------------------------------------------------------------------------
local card
local function MakeFont(name, base, size)
	local font = _G[name] or (CreateFont and CreateFont(name))
	if not font then return end
	local b = _G[base] or _G.GameFontNormalHuge
	if b and font.CopyFontObject then pcall(font.CopyFontObject, font, b) end
	if b and b.GetFont and font.SetFont then
		local ok, path, _, flags = pcall(b.GetFont, b)
		if ok and path then pcall(font.SetFont, font, path, size, flags or "") end
	end
	if font.SetShadowOffset then font:SetShadowOffset(2, -2); font:SetShadowColor(0, 0, 0, 1) end
end

local function BuildCard()
	if card then return card end
	MakeFont("BigChronicleFontCinematic", "QuestTitleFont", 34)
	MakeFont("BigChronicleFontCinematicSmall", "GameFontNormal", 14)
	local f = CreateFrame("Frame", "BigChronicleChapterCard", UIParent)
	f:SetSize(900, 170)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:EnableMouse(false)
	f:Hide()

	local shade = { 0, 0, 0, 0.6 }
	local clear = { 0, 0, 0, 0 }
	local bl = f:CreateTexture(nil, "BACKGROUND")
	bl:SetPoint("TOPLEFT"); bl:SetPoint("BOTTOMRIGHT", f, "BOTTOM")
	UI.Gradient(bl, "HORIZONTAL", clear, shade)
	local br = f:CreateTexture(nil, "BACKGROUND")
	br:SetPoint("TOPRIGHT"); br:SetPoint("BOTTOMLEFT", f, "BOTTOM")
	UI.Gradient(br, "HORIZONTAL", shade, clear)
	f.bg = { bl, br }

	local label = f:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematicSmall")
	label:SetPoint("TOP", 0, -26)
	label:SetTextColor(0.95, 0.78, 0.4)
	f.label = label

	local titleHolder = CreateFrame("Frame", nil, f)
	titleHolder:SetSize(880, 50)
	titleHolder:SetPoint("TOP", label, "BOTTOM", 0, -8)
	local title = titleHolder:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematic")
	title:SetPoint("CENTER")
	title:SetTextColor(1, 0.9, 0.62)
	f.title, f.titleHolder = title, titleHolder

	local gold = { 0.95, 0.75, 0.35, 0.9 }
	local goldClear = { 0.95, 0.75, 0.35, 0 }
	local ll = f:CreateTexture(nil, "ARTWORK")
	ll:SetHeight(1)
	ll:SetPoint("RIGHT", f, "CENTER", -14, -20)
	UI.Gradient(ll, "HORIZONTAL", goldClear, gold)
	local lr = f:CreateTexture(nil, "ARTWORK")
	lr:SetHeight(1)
	lr:SetPoint("LEFT", f, "CENTER", 14, -20)
	UI.Gradient(lr, "HORIZONTAL", gold, goldClear)
	local gem = f:CreateTexture(nil, "OVERLAY")
	gem:SetSize(8, 8)
	gem:SetPoint("CENTER", f, "CENTER", 0, -20)
	gem:SetColorTexture(1, 0.82, 0.45)
	if gem.SetRotation then pcall(gem.SetRotation, gem, math.pi / 4) end
	f.lines, f.gem = { ll, lr }, gem
	ll:SetWidth(1); lr:SetWidth(1)

	local sub = f:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematicSmall")
	sub:SetPoint("TOP", f, "CENTER", 0, -32)
	sub:SetTextColor(0.92, 0.88, 0.8)
	f.sub = sub
	card = f
	return f
end

-- label: 작은 머리글, title: 큰 제목, sub: 아랫줄
function E.ShowCard(label, title, sub)
	if not Enabled() then return end
	local f = BuildCard()
	f.label:SetText(label or "")
	f.title:SetText(title or "")
	f.sub:SetText(sub or "")
	f:SetAlpha(1)
	f:Show()
	for _, t in ipairs(f.bg) do t:SetAlpha(0) end
	f.label:SetAlpha(0); f.title:SetAlpha(0); f.sub:SetAlpha(0); f.gem:SetAlpha(0)
	f.titleHolder:SetScale(1.15)
	E.Sound("chapter")
	-- 1) 어두운 띠
	E.Tween("card-bg", 0.4, function(p) for _, t in ipairs(f.bg) do t:SetAlpha(p) end end)
	-- 2) 금빛 선이 가운데에서 양쪽으로
	E.Tween("card-lines", 0.7, function(p)
		local w = 1 + 300 * E.Ease.outCubic(p)
		f.lines[1]:SetWidth(w); f.lines[2]:SetWidth(w)
		f.gem:SetAlpha(p)
	end, nil, 0.15)
	-- 3) 글자
	E.Tween("card-label", 0.4, function(p) f.label:SetAlpha(p) end, nil, 0.3)
	E.Tween("card-title", 0.7, function(p)
		f.title:SetAlpha(p)
		f.titleHolder:SetScale(1.15 - 0.15 * E.Ease.outCubic(p))
	end, nil, 0.45)
	E.Tween("card-sub", 0.6, function(p) f.sub:SetAlpha(p) end, nil, 0.9)
	-- 4) 잠시 머문 뒤 사라진다
	E.Tween("card-out", 1.0, function(p) f:SetAlpha(1 - p) end, function() f:Hide() end, 4.6)
end

-- 새 장(章)에 들어섰을 때
function E.ChapterCard(chIdx, isStart)
	local ch = ns.Chronicle.CHAPTERS[chIdx]
	if not ch then return end
	local num, name = ch.title:match("^(.-)%s*·%s*(.+)$")
	num = num or ch.title
	if isStart then
		E.ShowCard("B I G   C H R O N I C L E", ns.PlayerName() .. "의 이야기가 시작됩니다", ch.title .. "  —  " .. ch.desc)
	else
		E.ShowCard(num:gsub("(%d+)", " %1 "), name or ch.title, ch.desc)
	end
end

ns:Listen("CHAPTER_STARTED", function(chIdx) E.ChapterCard(chIdx, false) end)
ns:Listen("CHRONICLE_BEGUN", function(chIdx) E.ChapterCard(chIdx, true) end)
