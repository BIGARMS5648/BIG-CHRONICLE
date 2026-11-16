-- BIG CHRONICLE :: 화면 연출
-- OnUpdate로 움직이는 작은 연출들:
--   Tween(움직임) · Burst(금가루) · Pulse(은은한 빛) · Stamp(밀랍 인장)
--   ChapterCard(화면 가운데 장 제목)

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
-- 동봉한 효과음 (Kenney RPG Audio, CC0). 못 틀면 게임 기본 효과음으로 대신한다.
local SND = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Sounds\\"
local FILES = {
	open  = { "bookOpen.ogg" },
	close = { "bookClose.ogg" },
	stamp = { "bookPlace1.ogg" },
}
local SOUNDS = {
	open    = { "IG_QUEST_LOG_OPEN", "IG_SPELLBOOK_OPEN" },
	close   = { "IG_QUEST_LOG_CLOSE", "IG_SPELLBOOK_CLOSE" },
	stamp   = { "UI_EPICLOOT_TOAST", "IG_QUEST_LIST_COMPLETE" },
	chapter = { "UI_LEGENDARY_LOOT_TOAST", "UI_EPICLOOT_TOAST", "LEVELUPSOUND" },
}
function E.Sound(kind)
	if not (ns.db and ns.db.sound) then return end
	local files = FILES[kind]
	if files and PlaySoundFile then
		local ok, played = pcall(PlaySoundFile, SND .. files[math.random(#files)], "SFX")
		if ok and played then return end
	end
	if not SOUNDKIT or not PlaySound then return end
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
-- 기본은 천천히 떠오르며 사그라드는 금가루 (빛을 더하는 방식으로 그린다)
local GOLD = { { 1.00, 0.84, 0.48 }, { 0.95, 0.74, 0.36 }, { 1.00, 0.92, 0.70 } }
function E.Burst(x, y, opts)
	if not Enabled() or not x or not y then return end
	opts = opts or {}
	local colors = opts.colors or GOLD
	local n = opts.count or 24
	local tex = opts.tex or UI.TEX.dust
	local blend = opts.blend or (opts.tex and "BLEND" or "ADD")
	Layer()
	for i = 1, n do
		local t = Acquire(tex, blend)
		local c = colors[(i % #colors) + 1]
		t:SetVertexColor(c[1], c[2], c[3])
		local size = math.random(opts.minSize or 5, opts.maxSize or 12)
		t:SetSize(size, size)
		local ang = math.random() * math.pi * 2
		local speed = (opts.speed or 60) * (0.3 + math.random() * 0.9)
		particles[#particles + 1] = {
			tex = t, x = x + math.random(-(opts.spreadW or 40), opts.spreadW or 40), y = y + math.random(-8, 8),
			vx = math.cos(ang) * speed * (opts.spreadX or 1.4), vy = math.sin(ang) * speed * 0.5 + (opts.lift or 30),
			gravity = opts.gravity or -12, age = 0, life = (opts.life or 1.6) * (0.6 + math.random() * 0.7),
			rot = 0, spin = opts.tex and (math.random() - 0.5) * 6 or 0,
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
-- kind: "ach"(업적, 리본 달린 나침반 별) / "dex"(도감, 사자 문장) / 그 밖(백합 문장)
-- 인장 그림을 바꾼다 (그림마다 가로세로 비율이 달라 크기도 다시 잡는다)
function E.SetSeal(f, kind)
	local name = (kind == "ach" or kind == "업적") and "SealAch" or ((kind == "dex" or kind == "새 기록") and "SealDex" or "Seal")
	local info = UI.ATLAS[name]
	local size = f.size
	f.tex:SetTexture(UI.Tex(name))
	f.tex:ClearAllPoints()
	f.tex:SetPoint("TOP", 0, 0)
	f.tex:SetSize(size * info.w / 110, size * info.h / 110)
	f.kind = kind
end

function E.MakeSeal(parent, size, kind)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(size, size)
	f.size = size
	f.tex = f:CreateTexture(nil, "OVERLAY")
	E.SetSeal(f, kind)
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
		E.BurstAt(frame, { count = 10, speed = 80, life = 0.55, tex = UI.TEX.ink, minSize = 3, maxSize = 6, spreadW = 6,
			colors = { { 0.55, 0.09, 0.07 }, { 0.42, 0.05, 0.04 } }, gravity = 170, lift = 40 })
		E.BurstAt(frame, { count = 8, speed = 30, life = 1.2, spreadW = 20 })
		E.BurstAt(frame, { count = 1, speed = 0, life = 0.7, spreadW = 0, tex = UI.TEX.glow, blend = "ADD",
			minSize = 110, maxSize = 110, lift = 0, gravity = 0, colors = { { 1, 0.75, 0.5 } } })
		E.Sound("stamp")
		if holdFor then
			E.Tween((key or tostring(frame)) .. "-out", 0.6, function(p) frame:SetAlpha(1 - p) end,
				function() frame:Hide() end, holdFor)
		end
	end)
end

------------------------------------------------------------------------
-- 장 제목 카드: 화면 가운데에 양피지 두루마리가 펼쳐지고 장 제목이 떠오른다
------------------------------------------------------------------------
local card
local CARD_W, SCROLL_H = 620, 124
local TITLE_W = CARD_W - 200   -- 두루마리 양 끝의 말린 부분을 뺀, 글씨가 들어갈 폭
local TITLE_FONTS = { "BigChronicleFontCinematic", "BigChronicleFontCinematicMid", "BigChronicleFontCinematicFit" }
local function MakeFont(name, base, size, color, shadow)
	local font = _G[name] or (CreateFont and CreateFont(name))
	if not font then return end
	local b = _G[base] or _G.GameFontNormalLarge or _G.GameFontNormal
	if b and font.CopyFontObject then pcall(font.CopyFontObject, font, b) end
	if b and b.GetFont and font.SetFont then
		local ok, p, _, flags = pcall(b.GetFont, b)
		if ok and p then pcall(font.SetFont, font, p, size, flags or "") end
	end
	if font.SetShadowOffset then
		if shadow then
			font:SetShadowOffset(1, -1)
			font:SetShadowColor(0, 0, 0, 0.9)
		else
			font:SetShadowOffset(0, 0)
			font:SetShadowColor(0, 0, 0, 0)
		end
	end
	if color and font.SetTextColor then font:SetTextColor(color[1], color[2], color[3]) end
end

local function BuildCard()
	if card then return card end
	-- 두루마리 위의 글씨는 테마와 상관없이 잉크 색
	MakeFont("BigChronicleFontCinematic", "GameFontNormalLarge", 30, { 0.22, 0.10, 0.05 }, false)
	-- 제목이 길면 (캐릭터 이름이 긴 첫 장 카드 등) 한 단계씩 작은 글씨로 줄인다
	MakeFont("BigChronicleFontCinematicMid", "GameFontNormalLarge", 25, { 0.22, 0.10, 0.05 }, false)
	MakeFont("BigChronicleFontCinematicFit", "GameFontNormalLarge", 21, { 0.22, 0.10, 0.05 }, false)
	MakeFont("BigChronicleFontCinematicLabel", "GameFontNormal", 13, { 0.55, 0.12, 0.07 }, false)
	MakeFont("BigChronicleFontCinematicSmall", "GameFontNormal", 13, { 0.95, 0.88, 0.74 }, true)
	local f = CreateFrame("Frame", "BigChronicleChapterCard", UIParent)
	f:SetSize(CARD_W, SCROLL_H + 34)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 170)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:EnableMouse(false)
	f:Hide()

	-- 양 끝이 말린 양피지 두루마리 (가운데만 늘어난다)
	local band = CreateFrame("Frame", nil, f)
	band:SetPoint("TOP", 0, 0)
	band:SetSize(CARD_W, SCROLL_H)
	UI.Slice(band, "Scroll", { layer = "BACKGROUND" })
	f.band = band

	-- 글씨는 두루마리(자식 프레임)보다 위 프레임 레벨에 둔다
	local ink = CreateFrame("Frame", nil, f)
	ink:SetAllPoints(f)
	if ink.SetFrameLevel and f.GetFrameLevel then ink:SetFrameLevel((f:GetFrameLevel() or 0) + 5) end

	local label = ink:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematicLabel")
	label:SetPoint("TOP", band, "TOP", 10, -30)
	f.label = label

	local titleHolder = CreateFrame("Frame", nil, ink)
	titleHolder:SetSize(TITLE_W, 40)
	local title = titleHolder:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematic")
	title:SetPoint("CENTER")
	f.title, f.titleHolder = title, titleHolder

	local sub = ink:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematicSmall")
	sub:SetPoint("TOP", band, "BOTTOM", 0, -8)
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
	-- 머리글이 없으면 제목을 두루마리 가운데에, 있으면 머리글 아래에 놓는다
	f.titleHolder:ClearAllPoints()
	if (label or "") == "" then
		f.titleHolder:SetPoint("CENTER", f.band, "CENTER", 0, 3)
	else
		f.titleHolder:SetPoint("TOP", f.label, "BOTTOM", 0, -2)
	end
	-- 두루마리 폭을 넘으면 글씨를 줄인다
	for _, font in ipairs(TITLE_FONTS) do
		if _G[font] then f.title:SetFontObject(font) end
		local w = f.title:GetStringWidth() or 0
		if w <= TITLE_W then break end
	end
	f:SetAlpha(1)
	f:Show()
	local minW = 230
	f.band:SetWidth(minW)
	f.label:SetAlpha(0); f.titleHolder:SetAlpha(0); f.sub:SetAlpha(0)
	E.Sound("chapter")
	-- 1) 말려 있던 두루마리가 좌우로 펼쳐진다
	E.Tween("card-band", 0.65, function(p)
		f.band:SetWidth(minW + (CARD_W - minW) * E.Ease.outCubic(p))
		f:SetAlpha(math.min(1, p * 3))
	end)
	-- 2) 머리글과 제목이 잉크가 번지듯 떠오른다
	E.Tween("card-text", 0.8, function(p)
		local k = E.Ease.outCubic(p)
		f.label:SetAlpha(k)
		f.titleHolder:SetAlpha(k)
		f.sub:SetAlpha(k)
	end, function()
		-- 제목이 자리 잡으면 금가루가 흩날린다
		E.BurstAt(f.titleHolder, { count = 22, speed = 40, life = 2.2, spreadW = 200, lift = 18 })
	end, 0.45)
	-- 3) 잠시 머문 뒤 조용히 사라진다
	E.Tween("card-out", 1.0, function(p)
		f:SetAlpha(1 - p)
	end, function() f:Hide() end, 4.6)
end

-- 새 장(章)에 들어섰을 때
function E.ChapterCard(chIdx, isStart)
	local ch = ns.Chronicle.CHAPTERS[chIdx]
	if not ch then return end
	local num, name = ch.title:match("^(.-)%s*·%s*(.+)$")
	num = num or ch.title
	if isStart then
		E.ShowCard(nil, ns.PlayerName() .. "의 도감 수첩, 첫 장", ch.title .. "  —  " .. ch.desc)
	else
		E.ShowCard((num:gsub("%s+", "")), name or ch.title, ch.desc)
	end
end

ns:Listen("CHAPTER_STARTED", function(chIdx) E.ChapterCard(chIdx, false) end)
ns:Listen("CHRONICLE_BEGUN", function(chIdx) E.ChapterCard(chIdx, true) end)
