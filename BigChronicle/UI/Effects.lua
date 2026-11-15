-- BIG CHRONICLE :: 화면 연출
-- OnUpdate로 움직이는 작은 연출들:
--   Tween(움직임) · Burst(금가루) · Pulse(은은한 빛) · Stamp(밀랍 인장)
--   ChapterCard(화면 가운데 장 제목) · TurnPage(책장 넘김)

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
	page  = { "bookFlip1.ogg", "bookFlip2.ogg", "bookFlip3.ogg" },
	stamp = { "bookPlace1.ogg" },
}
local SOUNDS = {
	open    = { "IG_QUEST_LOG_OPEN", "IG_SPELLBOOK_OPEN" },
	close   = { "IG_QUEST_LOG_CLOSE", "IG_SPELLBOOK_CLOSE" },
	page    = { "IG_ABILITY_PAGE_TURN", "IG_QUEST_LOG_OPEN" },
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
-- 책장 넘김: 책등을 축으로 양피지 한 장이 실제로 넘어간다
--   앞으로(dir >= 0): 지금 쪽이 오른쪽 끝부터 들려 책등 쪽으로 넘어가고, 그 아래 새 쪽이 드러난다
--   뒤로(dir < 0) : 앞 쪽이 책등 너머에서 넘어와 내려앉은 뒤, 그 쪽의 내용이 나타난다
------------------------------------------------------------------------
function E.MakePageTurn(page)
	local C = UI.COL
	local sheet = CreateFrame("Frame", nil, page)
	sheet:SetPoint("TOPLEFT", page, "TOPLEFT", -3, 3)
	sheet:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", -3, -3)
	sheet:SetWidth(1)
	sheet:SetFrameLevel(page:GetFrameLevel() + 35)
	sheet:EnableMouse(false)
	-- 속지 한 장: 폭이 줄면 통째로 눌려 원근처럼 보인다
	local paper = sheet:CreateTexture(nil, "BACKGROUND", nil, 0)
	paper:SetAllPoints()
	paper:SetTexture(UI.TEX.paper)
	UI.Tint(paper, C.page)
	-- 들릴수록 바깥쪽이 그늘진다
	local shade = sheet:CreateTexture(nil, "ARTWORK")
	shade:SetPoint("TOPLEFT", 3, -4)
	shade:SetPoint("BOTTOMRIGHT", -3, 4)
	UI.Gradient(shade, "HORIZONTAL", { 0, 0, 0, 0 }, { 0, 0, 0, 0.55 })
	-- 말려 올라가는 끝자락이 빛을 받는다
	local curl = sheet:CreateTexture(nil, "ARTWORK", nil, 2)
	curl:SetPoint("TOPRIGHT", -4, -4); curl:SetPoint("BOTTOMRIGHT", -4, 4); curl:SetWidth(40)
	UI.Gradient(curl, "HORIZONTAL", { 1, 0.97, 0.9, 0 }, { 1, 0.97, 0.9, 0.3 })
	-- 책장 끝의 밝은 모서리
	local rim = sheet:CreateTexture(nil, "OVERLAY")
	rim:SetPoint("TOPRIGHT", -3, -4); rim:SetPoint("BOTTOMRIGHT", -3, 4); rim:SetWidth(2)
	rim:SetColorTexture(1, 0.95, 0.85, 0.4)
	-- 아래 쪽에 드리우는 그림자
	local cast = sheet:CreateTexture(nil, "BACKGROUND", nil, -2)
	cast:SetPoint("TOPLEFT", sheet, "TOPRIGHT", -3, -6)
	cast:SetPoint("BOTTOMLEFT", sheet, "BOTTOMRIGHT", -3, 6)
	cast:SetWidth(1)
	UI.Gradient(cast, "HORIZONTAL", { 0, 0, 0, 0.5 }, { 0, 0, 0, 0 })
	sheet.paper, sheet.shade, sheet.rim, sheet.cast, sheet.page, sheet.curl = paper, shade, rim, cast, page, curl
	sheet:Hide()
	return sheet
end

-- 넘기던 책장을 곧바로 끝낸다 (연달아 넘길 때)
function E.FinishTurn(sheet)
	if not sheet or not sheet.busy then return end
	E.Stop("page-turn")
	E.Stop("page-turn-fade")
	local apply = sheet.pending
	sheet.pending, sheet.busy = nil, false
	sheet:Hide()
	if apply then apply() end
end

local function TurnPose(sheet, W, theta)
	-- theta: 0 = 평평하게 누운 쪽, pi/2 = 책등 위에 곧게 선 쪽
	local c, sn = math.cos(theta), math.sin(theta)
	local w = math.max(1, W * c)
	sheet:SetWidth(w)
	sheet.shade:SetAlpha(0.2 + 0.8 * sn)
	sheet.curl:SetWidth(math.max(1, math.min(40, w * 0.3)))
	sheet.curl:SetAlpha(sn)
	sheet.rim:SetAlpha(sn)
	sheet.cast:SetWidth(math.max(1, 90 * sn * c * 2))
	sheet.cast:SetAlpha(math.min(1, c * 2))
end

function E.TurnPage(sheet, dir, apply)
	if not sheet then
		if apply then apply() end
		return
	end
	E.FinishTurn(sheet)
	if not Enabled() then
		if apply then apply() end
		return
	end
	local page = sheet.page
	local W = (page:GetWidth() or 640) + 6
	sheet:SetAlpha(1)
	sheet:Show()
	sheet.busy = true
	E.Sound("page")
	if (dir or 1) >= 0 then
		-- 새 쪽을 먼저 그려 두고, 지금 쪽(종이)이 그 위에서 넘어간다
		if apply then apply() end
		TurnPose(sheet, W, 0)
		E.Tween("page-turn", 0.55, function(p)
			TurnPose(sheet, W, math.pi / 2 * E.Ease.inOut(p))
		end, function()
			sheet.busy = false
			sheet:Hide()
		end)
	else
		-- 앞 쪽이 넘어와 덮은 뒤에 내용을 바꾸고, 종이를 걷어 낸다
		sheet.pending = apply
		TurnPose(sheet, W, math.pi / 2)
		E.Tween("page-turn", 0.5, function(p)
			TurnPose(sheet, W, math.pi / 2 * (1 - E.Ease.inOut(p)))
		end, function()
			local fn = sheet.pending
			sheet.pending = nil
			if fn then fn() end
			E.Tween("page-turn-fade", 0.18, function(p) sheet:SetAlpha(1 - p) end, function()
				sheet.busy = false
				sheet:Hide()
				sheet:SetAlpha(1)
			end)
		end)
	end
end

------------------------------------------------------------------------
-- 장 제목 카드: 화면 가운데에 검은 띠가 펼쳐지고 금박 제목이 떠오른다
------------------------------------------------------------------------
local card
local CARD_W, CARD_H = 820, 170
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
		if ok and p then pcall(font.SetFont, font, p, size, flags or "") end
	end
	if font.SetShadowOffset then
		font:SetShadowOffset(1, -1)
		font:SetShadowColor(0, 0, 0, 0.9)
	end
	if color and font.SetTextColor then font:SetTextColor(color[1], color[2], color[3]) end
end

local function BuildCard()
	if card then return card end
	MakeFont("BigChronicleFontCinematic", "QuestTitleFont", 38, nil, { 0.96, 0.88, 0.70 })
	MakeFont("BigChronicleFontCinematicLabel", "GameFontNormal", 14, nil, { 0.86, 0.70, 0.40 })
	MakeFont("BigChronicleFontCinematicSmall", "GameFontNormal", 13, nil, { 0.78, 0.72, 0.62 })
	local f = CreateFrame("Frame", "BigChronicleChapterCard", UIParent)
	f:SetSize(CARD_W, CARD_H)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 170)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:EnableMouse(false)
	f:Hide()

	-- 가운데가 짙고 양옆으로 사라지는 검은 띠
	local band = CreateFrame("Frame", nil, f)
	band:SetPoint("CENTER")
	band:SetSize(CARD_W, CARD_H - 30)
	local half = CARD_W / 2
	local l = band:CreateTexture(nil, "BACKGROUND")
	l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT"); l:SetWidth(half)
	UI.Gradient(l, "HORIZONTAL", { 0.03, 0.02, 0.015, 0 }, { 0.03, 0.02, 0.015, 0.82 })
	local r = band:CreateTexture(nil, "BACKGROUND")
	r:SetPoint("TOPRIGHT"); r:SetPoint("BOTTOMRIGHT"); r:SetWidth(half)
	UI.Gradient(r, "HORIZONTAL", { 0.03, 0.02, 0.015, 0.82 }, { 0.03, 0.02, 0.015, 0 })
	-- 위아래 금박 실선
	local gold = { 0.86, 0.70, 0.40 }
	for _, side in ipairs({ "TOP", "BOTTOM" }) do
		for _, pair in ipairs({ { "LEFT", half, { gold[1], gold[2], gold[3], 0 }, { gold[1], gold[2], gold[3], 0.8 } },
			{ "RIGHT", half, { gold[1], gold[2], gold[3], 0.8 }, { gold[1], gold[2], gold[3], 0 } } }) do
			local t = band:CreateTexture(nil, "BORDER")
			t:SetHeight(1)
			t:SetWidth(pair[2])
			t:SetPoint(side .. pair[1], band, side .. pair[1], 0, side == "TOP" and -6 or 6)
			UI.Gradient(t, "HORIZONTAL", pair[3], pair[4])
		end
	end
	f.band = band

	local label = f:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematicLabel")
	label:SetPoint("TOP", band, "TOP", 0, -22)
	f.label = label

	local titleHolder = CreateFrame("Frame", nil, f)
	titleHolder:SetSize(CARD_W - 80, 50)
	titleHolder:SetPoint("TOP", label, "BOTTOM", 0, -4)
	local title = titleHolder:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematic")
	title:SetPoint("CENTER")
	f.title, f.titleHolder = title, titleHolder

	local rule = UI.Divider(f, 300, gold)
	rule:SetPoint("TOP", titleHolder, "BOTTOM", 0, -2)
	f.rule = rule

	local sub = f:CreateFontString(nil, "OVERLAY", "BigChronicleFontCinematicSmall")
	sub:SetPoint("TOP", rule, "BOTTOM", 0, -6)
	f.sub = sub
	card = f
	return f
end

-- label: 작은 머리글, title: 큰 제목, sub: 아랫줄
function E.ShowCard(label, title, sub)
	if not Enabled() then return end
	local f = BuildCard()
	f.label:SetText(UI.Spaced(label or "", 1))
	f.title:SetText(title or "")
	f.sub:SetText(sub or "")
	f:SetAlpha(1)
	f:Show()
	f.band:SetWidth(1)
	f.label:SetAlpha(0); f.titleHolder:SetAlpha(0); f.rule:SetAlpha(0); f.sub:SetAlpha(0)
	f.rule:SetWidth(1)
	E.Sound("chapter")
	-- 1) 검은 띠가 가운데에서 좌우로 펼쳐진다
	E.Tween("card-band", 0.6, function(p)
		f.band:SetWidth(math.max(1, CARD_W * E.Ease.outCubic(p)))
	end)
	-- 2) 머리글과 제목이 천천히 떠오른다
	E.Tween("card-text", 0.9, function(p)
		local k = E.Ease.outCubic(p)
		f.label:SetAlpha(k)
		f.titleHolder:SetAlpha(k)
		f.titleHolder:SetScale(1.04 - 0.04 * k)
	end, function()
		-- 제목이 자리 잡으면 금가루가 흩날린다
		E.BurstAt(f.titleHolder, { count = 26, speed = 40, life = 2.2, spreadW = 220, lift = 18 })
	end, 0.35)
	-- 3) 장식선이 그어지고 아랫줄이 나타난다
	E.Tween("card-rule", 0.7, function(p)
		local k = E.Ease.outCubic(p)
		f.rule:SetAlpha(1)
		f.rule:SetWidth(1 + 300 * k)
		f.sub:SetAlpha(k)
	end, nil, 0.9)
	-- 4) 잠시 머문 뒤 조용히 사라진다
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
		E.ShowCard("BIG CHRONICLE", ns.PlayerName() .. "의 모험 수첩, 첫 장", ch.title .. "  —  " .. ch.desc)
	else
		E.ShowCard((num:gsub("%s+", "")), name or ch.title, ch.desc)
	end
end

ns:Listen("CHAPTER_STARTED", function(chIdx) E.ChapterCard(chIdx, false) end)
ns:Listen("CHRONICLE_BEGUN", function(chIdx) E.ChapterCard(chIdx, true) end)
