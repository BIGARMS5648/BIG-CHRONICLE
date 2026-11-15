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

local function Acquire(path, blend)
	local tex = table.remove(freeTex)
	if not tex then
		tex = Layer():CreateTexture(nil, "OVERLAY")
	end
	tex:SetTexture(path or WHITE)
	tex:SetBlendMode(blend or "BLEND")
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
	-- 기본은 수첩에 어울리는 색종이 조각
	local colors = opts.colors or { { 0.93, 0.47, 0.40 }, { 0.97, 0.80, 0.35 }, { 0.50, 0.68, 0.90 }, { 0.52, 0.76, 0.48 } }
	local n = opts.count or 24
	Layer()
	for i = 1, n do
		local tex = Acquire(opts.tex, opts.blend)
		local c = colors[(i % #colors) + 1]
		tex:SetVertexColor(c[1], c[2], c[3])
		local size = math.random(opts.minSize or 4, opts.maxSize or 8)
		if opts.tex then
			tex:SetSize(size, size)
		else
			tex:SetSize(size, size * (0.45 + math.random() * 0.6)) -- 납작한 종이 조각
		end
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
	local ended
	for region, cfg in pairs(pulses) do
		if cfg.untilT and clock >= cfg.untilT then
			ended = ended or {}
			ended[#ended + 1] = region
		else
			any = true
			local a = cfg.min + (cfg.max - cfg.min) * (0.5 + 0.5 * math.sin((clock - cfg.start) * cfg.speed - math.pi / 2))
			region:SetAlpha(a)
		end
	end
	if ended then
		for _, region in ipairs(ended) do
			local cfg = pulses[region]
			pulses[region] = nil
			-- 정해진 시간만 깜빡이고, 끝나면 은은하게 남기거나 숨긴다
			if cfg.final and cfg.final > 0 then region:SetAlpha(cfg.final) else region:Hide() end
		end
	end
	if not any then self:Hide() end
end)

function E.Pulse(region, on, cfg)
	if not region then return end
	if on and Enabled() then
		cfg = cfg or {}
		pulses[region] = { min = cfg.min or 0.15, max = cfg.max or 0.9, speed = cfg.speed or 3, start = clock,
			untilT = cfg.duration and (clock + cfg.duration) or nil, final = cfg.final }
		region:Show()
		pulseDriver:Show()
	else
		pulses[region] = nil
		if on then
			region:Show()
			region:SetAlpha(cfg and (cfg.final or cfg.max) or 0.8)
		else
			region:Hide()
		end
	end
end

------------------------------------------------------------------------
-- 도장 찍기: 커다랗게 떨어져 '쿵' 하고 자리 잡는다
------------------------------------------------------------------------
-- kind: "ach"(업적, 월계관 문양) / "dex"(도감, 발바닥 문양) / 그 밖(왕관 문양)
function E.MakeSeal(parent, size, kind)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(size, size)
	local tex = f:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints()
	if kind == "ach" or kind == "업적" then
		tex:SetTexture(UI.TEX.sealAch)
	elseif kind == "dex" or kind == "새 기록" then
		tex:SetTexture(UI.TEX.sealDex)
	else
		tex:SetTexture(UI.TEX.seal)
	end
	f.tex = tex
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
		-- 찍히는 순간 밀랍 부스러기가 튄다
		E.BurstAt(frame, { count = 12, speed = 90, life = 0.6, tex = UI.TEX.ink, minSize = 3, maxSize = 6,
			colors = { { 0.62, 0.10, 0.08 }, { 0.48, 0.06, 0.05 } }, gravity = 160, lift = 40 })
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
local function MakeFont(name, base, size, path, color)
	local font = _G[name] or (CreateFont and CreateFont(name))
	if not font then return end
	local b = _G[base] or _G.GameFontNormalHuge
	if b and font.CopyFontObject then pcall(font.CopyFontObject, font, b) end
	local applied = false
	if path and font.SetFont then
		local ok, res = pcall(font.SetFont, font, path, size, "")
		applied = ok and res ~= false
	end
	if not applied and b and b.GetFont and font.SetFont then
		local ok, p, _, flags = pcall(b.GetFont, b)
		if ok and p then pcall(font.SetFont, font, p, path and math.floor(size * 0.72) or size, flags or "") end
	end
	if font.SetShadowOffset then font:SetShadowOffset(0, 0) end
	if color and font.SetTextColor then font:SetTextColor(color[1], color[2], color[3]) end
end

local function BuildCard()
	if card then return card end
	MakeFont("BigChronicleFontCinematic", "QuestTitleFont", 44, UI.PEN_FONT, { 0.12, 0.18, 0.38 })
	MakeFont("BigChronicleFontCinematicLabel", "GameFontNormal", 22, UI.PEN_FONT, { 0.70, 0.17, 0.12 })
	MakeFont("BigChronicleFontCinematicSmall", "GameFontNormal", 13, nil, { 0.25, 0.20, 0.15 })
	local f = CreateFrame("Frame", "BigChronicleChapterCard", UIParent)
	f:SetSize(640, 160)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 170)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:EnableMouse(false)
	f:Hide()

	-- 수첩에서 찢어 낸 종이 띠 + 양쪽 끝 테이프
	local strip = f:CreateTexture(nil, "BACKGROUND")
	strip:SetAllPoints()
	strip:SetTexture(UI.TEX.torn)
	local grid = f:CreateTexture(nil, "BACKGROUND", nil, 1)
	grid:SetPoint("TOPLEFT", 10, -18)
	grid:SetPoint("BOTTOMRIGHT", -10, 18)
	grid:SetTexture(UI.TEX.grid, "REPEAT", "REPEAT")
	grid:SetTexCoord(0, 620 / 24, 0, 124 / 24)
	grid:SetVertexColor(0.42, 0.60, 0.82, 0.22)
	local tl = UI.Tape(f, 90, 24, 0.55)
	tl:SetPoint("CENTER", f, "LEFT", 18, 30)
	local tr = UI.Tape(f, 90, 24, -0.5)
	tr:SetPoint("CENTER", f, "RIGHT", -18, 30)

	local label = f:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematicLabel")
	label:SetPoint("TOP", 0, -22)
	f.label = label

	local titleHolder = CreateFrame("Frame", nil, f)
	titleHolder:SetSize(600, 56)
	titleHolder:SetPoint("TOP", label, "BOTTOM", 0, -2)
	local title = titleHolder:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematic")
	title:SetPoint("CENTER")
	f.title, f.titleHolder = title, titleHolder

	local under = f:CreateTexture(nil, "ARTWORK")
	under:SetSize(320, 10)
	under:SetPoint("TOP", titleHolder, "BOTTOM", 0, 6)
	under:SetTexture(UI.TEX.underline)
	under:SetVertexColor(0.70, 0.17, 0.12, 0.85)
	f.under = under

	local sub = f:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematicSmall")
	sub:SetPoint("TOP", under, "BOTTOM", 0, -4)
	f.sub = sub
	card = f
	return f
end

-- label: 작은 머리글, title: 큰 제목, sub: 아랫줄
function E.ShowCard(label, title, sub)
	if not Enabled() then return end
	local f = BuildCard()
	f.label:SetText(UI.PenText(label or ""))
	f.title:SetText(UI.PenText(title or ""))
	f.sub:SetText(sub or "")
	f:SetAlpha(0)
	f:Show()
	f.under:SetWidth(1)
	E.Sound("chapter")
	-- 1) 종이 띠가 위에서 툭 떨어져 테이프로 붙는다
	E.Tween("card-in", 0.5, function(p)
		local k = E.Ease.outBack(p)
		f:ClearAllPoints()
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 170 + 50 * (1 - k))
		f:SetAlpha(math.min(1, p * 2))
		f.titleHolder:SetScale(1.08 - 0.08 * math.min(1, p))
	end)
	-- 2) 빨간 색연필로 밑줄을 쭉
	E.Tween("card-under", 0.5, function(p) f.under:SetWidth(1 + 320 * E.Ease.outCubic(p)) end, nil, 0.45)
	-- 3) 잠시 머문 뒤 위로 날아가며 사라진다
	E.Tween("card-out", 0.8, function(p)
		f:SetAlpha(1 - p)
		f:ClearAllPoints()
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 170 + 30 * p)
	end, function() f:Hide() end, 4.4)
end

-- 새 장(章)에 들어섰을 때
function E.ChapterCard(chIdx, isStart)
	local ch = ns.Chronicle.CHAPTERS[chIdx]
	if not ch then return end
	local num, name = ch.title:match("^(.-)%s*·%s*(.+)$")
	num = num or ch.title
	if isStart then
		E.ShowCard("BIG CHRONICLE", ns.PlayerName() .. "의 도감 수첩, 첫 장", ch.title .. "  —  " .. ch.desc)
	else
		E.ShowCard(num:gsub("(%d+)", " %1 "), name or ch.title, ch.desc)
	end
end

ns:Listen("CHAPTER_STARTED", function(chIdx) E.ChapterCard(chIdx, false) end)
ns:Listen("CHRONICLE_BEGUN", function(chIdx) E.ChapterCard(chIdx, true) end)
