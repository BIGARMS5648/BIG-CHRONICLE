-- BIG CHRONICLE :: 업적 판정
-- 일지·도감에 쌓인 기록으로 업적 달성 여부를 계산하고, 새로 이룬 업적을 전기에 남긴다.

local ADDON, ns = ...
local A = {}
ns.Achievements = A

local Format = ns.Format

------------------------------------------------------------------------
-- 평판: '확고한 동맹' 세력 수 (지금까지 본 가장 큰 값을 기억한다)
------------------------------------------------------------------------
local function ExaltedNow()
	local n = 0
	if C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex then
		local count = ns.Call(C_Reputation.GetNumFactions) or 0
		for i = 1, count do
			local d = ns.Call(C_Reputation.GetFactionDataByIndex, i)
			if type(d) == "table" and not d.isHeader and d.reaction == 8 then n = n + 1 end
		end
	elseif GetNumFactions and GetFactionInfo then
		local count = ns.Call(GetNumFactions) or 0
		for i = 1, count do
			local _, _, standing, _, _, _, _, _, isHeader = ns.Call(GetFactionInfo, i)
			if not isHeader and standing == 8 then n = n + 1 end
		end
	end
	return n
end

function A:UpdateReputation()
	local ach = ns.char and ns.char.ach
	if not ach then return end
	local n = ExaltedNow()
	if n > (ach.exaltedBest or 0) then
		ach.exaltedBest = n
		self:Queue()
	end
end

------------------------------------------------------------------------
-- 초기화
------------------------------------------------------------------------
function A:Init()
	local on = function(ev, fn) ns:On(ev, function(...) fn(self, ...) end) end
	ns:Listen("LOG_ADDED", function() A:Queue() end)
	ns:Listen("DEX_UPDATED", function() A:Queue() end)
	ns:Listen("EXPEDITION_ENDED", function(_, bosses, _, wipes, deaths, stop) A:OnExpedition(bosses, wipes, deaths, stop) end)
	on("PLAYER_MONEY", self.Queue)
	on("UPDATE_FACTION", self.UpdateReputation)
	if C_Timer and C_Timer.After then
		C_Timer.After(4, function()
			A:UpdateReputation()
			A:Evaluate()
		end)
		if C_Timer.NewTicker then
			C_Timer.NewTicker(60, function() A:Queue() end)
		end
	else
		self:Evaluate()
	end
end

function A:OnReset()
	self.ctx = nil
	self:Evaluate()
end

function A:OnExpedition(bosses, wipes, deaths, stop)
	local ach = ns.char and ns.char.ach
	if not ach then return end
	self.lastExpStop = tonumber(stop)
	bosses, wipes, deaths = tonumber(bosses) or 0, tonumber(wipes) or 0, tonumber(deaths) or 0
	if bosses > 0 and wipes > 0 then ach.flags.comeback = 1 end
	if bosses >= 3 and deaths == 0 then ach.flags.flawless = 1 end
	self:Queue()
end

function A:Queue()
	if self.pending then return end
	self.pending = true
	local run = function()
		A.pending = false
		local ok, err = pcall(A.Evaluate, A)
		if not ok then ns:Error(err) end
	end
	if C_Timer and C_Timer.After then C_Timer.After(1, run) else run() end
end

------------------------------------------------------------------------
-- 판정에 쓰는 값 모으기
------------------------------------------------------------------------
local function count(t)
	local n = 0
	for _ in pairs(t or {}) do n = n + 1 end
	return n
end

function A:Context()
	local db = ns.char
	local B = ns.Bestiary
	local ach = db.ach
	local ctx = { cleared = {}, clearedName = {}, tribeKills = {}, bgMaps = {}, bgNames = {}, deathless = {} }

	ctx.level = ns.PlayerLevel()
	local money = ns.Call(GetMoney) or 0
	ach.goldBest = math.max(ach.goldBest or 0, math.floor(money / 10000))
	ctx.goldBest = ach.goldBest
	ctx.tracked = db.stats.tracked or 0

	ctx.zones = count(db.zones)
	ctx.subzones = count(db.subzones)

	ctx.quests = db.quests.count or 0
	ctx.questZones, ctx.questMaxZone = 0, 0
	for _, n in pairs(db.quests.zones or {}) do
		ctx.questZones = ctx.questZones + 1
		if n > ctx.questMaxZone then ctx.questMaxZone = n end
	end

	-- 던전 / 공격대
	ctx.runs, ctx.raidClears = 0, 0
	for name, d in pairs(db.dungeons) do
		ctx.runs = ctx.runs + (d.runs or 0)
		if (d.cleared or 0) > 0 then
			ctx.clearedName[name] = 1
			if d.mapID then ctx.cleared[d.mapID] = 1 end
			if d.kind == "raid" then ctx.raidClears = ctx.raidClears + 1 end
		end
	end
	ctx.dungeonsCleared = 0
	for _, d in ipairs(ns.CLASSIC_DUNGEONS) do
		if ctx.cleared[d.map] or ctx.clearedName[d.name] then ctx.dungeonsCleared = ctx.dungeonsCleared + 1 end
	end
	ctx.bossKills = 0
	for _, b in pairs(db.bosses) do ctx.bossKills = ctx.bossKills + (b.kills or 0) end
	ctx.comeback = ach.flags.comeback or 0
	ctx.flawless = ach.flags.flawless or 0

	-- 도감
	local found, _, species, rares, kills, families = B:Completion()
	ctx.tribes, ctx.species, ctx.rares, ctx.kills, ctx.families = found, species, rares, kills, families
	ctx.rareKills, ctx.worldBossKills, ctx.critters = 0, 0, 0
	for _, c in pairs(B.dex.creatures) do
		if c.rareKilled then ctx.rareKills = ctx.rareKills + 1 end
		if c.bossKilled then ctx.worldBossKills = ctx.worldBossKills + 1 end
		if c.tribe == "critter" then ctx.critters = ctx.critters + 1 end
	end
	ctx.maxRank, ctx.rank4Count = 0, 0
	for id, s in pairs(B:CollectAll()) do
		ctx.tribeKills[id] = s.kills
		if s.discovered then
			if s.rank > ctx.maxRank then ctx.maxRank = s.rank end
			if s.rank >= 4 then ctx.rank4Count = ctx.rank4Count + 1 end
		end
	end

	-- 전장 / 평판
	ctx.bgTotal = 0
	for name, n in pairs(db.pvp) do
		ctx.bgTotal = ctx.bgTotal + n
		ctx.bgNames[name] = n
	end
	for map, n in pairs(db.pvpMaps or {}) do ctx.bgMaps[map] = n end
	ctx.exalted = ach.exaltedBest or 0

	-- 시련 / 연대기
	ctx.deaths = db.deaths or 0
	local firstDeathLvl
	ctx.notes, ctx.binds = 0, 0
	for _, e in ipairs(db.log) do
		if e.cat == "death" and not firstDeathLvl then firstDeathLvl = e.lvl end
		if e.cat == "note" then ctx.notes = ctx.notes + 1 end
		if e.cat == "bind" then ctx.binds = ctx.binds + 1 end
	end
	local startLvl = (db.meta and db.meta.startLevel) or ctx.level
	for _, lv in ipairs({ 10, 20, 30, 40, 50, 60 }) do
		ctx.deathless[lv] = startLvl < lv and ctx.level >= lv and (not firstDeathLvl or firstDeathLvl >= lv)
	end
	ctx.logCount = #db.log
	ctx.exported = db.stats.exported or 0
	return ctx
end

------------------------------------------------------------------------
-- 판정
------------------------------------------------------------------------
function A:Progress(def, ctx)
	ctx = ctx or self.ctx or self:Context()
	local ok, cur = pcall(def.progress, ctx)
	cur = ok and tonumber(cur) or 0
	return math.min(cur, def.goal), def.goal
end

function A:Evaluate()
	local db = ns.char
	if not db then return end
	if not (ns.Chronicle and ns.Chronicle.started) then
		-- 첫 기록(모험의 시작)이 남기 전에는 판정하지 않는다
		self:Queue()
		return
	end
	local ach = db.ach
	local ctx = self:Context()
	self.ctx = ctx
	local newly = {}
	for _, def in ipairs(ns.ACHIEVEMENTS) do
		if not ach.done[def.id] then
			local cur = self:Progress(def, ctx)
			if cur >= def.goal then
				ach.done[def.id] = time()
				newly[#newly + 1] = def
			end
		end
	end

	if not ach.initialized then
		-- 애드온을 처음 켠 시점에 이미 이룬 업적은 한 줄로만 정리한다
		ach.initialized = true
		if #newly > 0 then
			local pts = 0
			for _, def in ipairs(newly) do
				ach.retro[def.id] = true
				pts = pts + def.points
			end
			ns.Chronicle:Add("achievement", Format("지난 여정의 발자취를 되짚어 보니, 이미 이룬 업적이 {n}개나 되었다. 그 이름들이 전기의 첫머리에 조용히 새겨졌다.", { n = #newly })
				.. ns.Hex("  — 업적 " .. #newly .. "개 · +" .. pts .. "점", ns.COLOR.dim), { retro = #newly })
		end
	else
		for _, def in ipairs(newly) do self:Announce(def) end
	end
	if #newly > 0 then ns:Fire("ACH_UPDATED") end
end

function A:Announce(def)
	local flavor = def.flavor or "또 하나의 이야기가 완성되었다."
	local data = { ach = def.id }
	-- 던전·공격대 업적은 원정이 끝난 시각에 맞춰 적는다 (원정 정리는 던전을 나온 뒤 늦게 이루어질 수 있다)
	local cat = def.cat
	if (cat == "dungeon" or cat == "raid") and self.lastExpStop and time() - self.lastExpStop < 3600 then
		data.t = self.lastExpStop
		ns.char.ach.done[def.id] = self.lastExpStop
	end
	ns.Chronicle:Add("achievement", flavor .. ns.Hex("  — 업적 「" .. def.name .. "」 달성 · +" .. def.points .. "점", ns.COLOR.dim), data)
	if ns.Toast then
		ns.Toast:Show("업적 달성!", "「" .. def.name .. "」   +" .. def.points .. "점", def.icon, "achievement")
	end
end

-- 요약: 달성 수, 전체 수, 점수, 전체 점수
function A:Summary(cat)
	local done, total, pts, maxPts = 0, 0, 0, 0
	local ach = ns.char and ns.char.ach
	for _, def in ipairs(ns.ACHIEVEMENTS) do
		if not cat or def.cat == cat then
			total = total + 1
			maxPts = maxPts + def.points
			if ach and ach.done[def.id] then
				done = done + 1
				pts = pts + def.points
			end
		end
	end
	return done, total, pts, maxPts
end

function A:NoteExport()
	local db = ns.char
	if not db then return end
	db.stats.exported = (db.stats.exported or 0) + 1
	self:Queue()
end
