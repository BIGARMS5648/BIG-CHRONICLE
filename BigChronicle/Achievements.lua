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
	self:MergeCharacter()
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

-- 일지(로그)에서 뽑는 값은 기록 수가 바뀔 때만 다시 계산한다
local function LogStats(db)
	local log = db.log
	local key = #log .. ":" .. tostring(log[1] and log[1].t)
	if A.logCache and A.logCache.key == key then return A.logCache end
	local st = { key = key, notes = 0, binds = 0, nightEntries = 0, morningEntries = 0, midnightNotes = 0, newYear = 0,
		weekendLevels = 0, levelsMaxDay = 0, questMaxDay = 0, days = 0, streak = 0, deathZones = 0,
		logCat = {}, logHour = {}, logWday = {}, logMonth = {}, zoneDeaths = {}, entries = 0 }
	local logCat, logHour, logWday, logMonth = st.logCat, st.logHour, st.logWday, st.logMonth
	local dayLevels, dayQuests, daySet, deathZoneSet = {}, {}, {}, {}
	for _, e in ipairs(log) do
		local d = date("*t", e.t)
		local dayIdx = math.floor(time({ year = d.year, month = d.month, day = d.day, hour = 12 }) / 86400)
		daySet[dayIdx] = true
		-- 업적이 남긴 기록은 세지 않는다 (업적이 업적을 부르는 일이 없도록)
		if e.cat ~= "achievement" then
			st.entries = st.entries + 1
			if e.cat then logCat[e.cat] = (logCat[e.cat] or 0) + 1 end
			logHour[d.hour] = (logHour[d.hour] or 0) + 1
			logWday[d.wday] = (logWday[d.wday] or 0) + 1
			logMonth[d.month] = (logMonth[d.month] or 0) + 1
		end
		if e.cat == "death" then
			if not st.firstDeathLvl then st.firstDeathLvl = e.lvl end
			if e.zone and e.zone ~= "" then
				deathZoneSet[e.zone] = true
				st.zoneDeaths[e.zone] = (st.zoneDeaths[e.zone] or 0) + 1
			end
		elseif e.cat == "note" then
			st.notes = st.notes + 1
			if d.hour < 4 then st.midnightNotes = st.midnightNotes + 1 end
		elseif e.cat == "bind" then
			st.binds = st.binds + 1
		elseif e.cat == "level" then
			dayLevels[dayIdx] = (dayLevels[dayIdx] or 0) + 1
			if dayLevels[dayIdx] > st.levelsMaxDay then st.levelsMaxDay = dayLevels[dayIdx] end
			if d.wday == 1 or d.wday == 7 then st.weekendLevels = st.weekendLevels + 1 end
		elseif e.cat == "quest" then
			dayQuests[dayIdx] = (dayQuests[dayIdx] or 0) + 1
			if dayQuests[dayIdx] > st.questMaxDay then st.questMaxDay = dayQuests[dayIdx] end
		end
		if e.cat ~= "achievement" then
			if d.hour < 4 then st.nightEntries = st.nightEntries + 1 end
			if d.hour >= 6 and d.hour < 9 then st.morningEntries = st.morningEntries + 1 end
		end
		if d.month == 1 and d.day == 1 then st.newYear = 1 end
	end
	for _ in pairs(deathZoneSet) do st.deathZones = st.deathZones + 1 end
	-- 기록이 남은 날 수와 가장 긴 연속 기록
	local days = {}
	for idx in pairs(daySet) do days[#days + 1] = idx end
	table.sort(days)
	st.days = #days
	local run = 0
	for i, idx in ipairs(days) do
		if i > 1 and idx == days[i - 1] + 1 then run = run + 1 else run = 1 end
		if run > st.streak then st.streak = run end
	end
	A.logCache = st
	return st
end

function A:Context()
	local db = ns.char
	local B = ns.Bestiary
	local ach = db.ach
	local ctx = { clearCount = {}, clearCountName = {}, tribeKills = {}, tribeFound = {}, tribeRank = {}, bgMaps = {}, bgNames = {},
		questZone = db.quests.zones or {}, questMap = db.quests.maps or {}, todSpecies = {},
		tribeSpecies = {}, tribeSeen = {}, habitatSpecies = {}, habitatSeen = {}, zoneSpecies = {}, zoneSeen = {},
		zoneVisits = {}, zoneTime = {}, zoneSub = {}, runCount = {}, runCountName = {}, instBossKills = {}, bestClear = {} }

	ctx.level = ns.PlayerLevel()
	ctx.classToken = select(2, ns.Call(UnitClass, "player"))
	ctx.raceToken = select(2, ns.Call(UnitRace, "player"))
	local money = ns.Call(GetMoney) or 0
	ach.goldBest = math.max(ach.goldBest or 0, math.floor(money / 10000))
	ctx.goldBest = ach.goldBest
	ctx.tracked = db.stats.tracked or 0

	-- 탐험
	ctx.zones, ctx.subzones, ctx.maxZoneTime = 0, count(db.subzones), 0
	local zoneMaps = {}
	for name, z in pairs(db.zones) do
		ctx.zoneVisits[name] = z.visits or 0
		ctx.zoneTime[name] = z.time or 0
		ctx.zones = ctx.zones + 1
		if (z.time or 0) > ctx.maxZoneTime then ctx.maxZoneTime = z.time end
		if z.map then zoneMaps[z.map] = true end
	end
	ctx.ekVisited, ctx.kalVisited = 0, 0
	local loreEK, loreKal = 0, 0
	for _, z in ipairs(ns.CLASSIC_ZONES) do
		if db.zones[z.name] or zoneMaps[z.map] then
			if z.ek then ctx.ekVisited = ctx.ekVisited + 1 else ctx.kalVisited = ctx.kalVisited + 1 end
		end
		local q = math.max(ctx.questZone[z.name] or 0, ctx.questMap[z.map] or 0)
		if q >= (z.fewQuests and 3 or 10) then
			if z.ek then loreEK = loreEK + 1 else loreKal = loreKal + 1 end
		end
	end
	ctx.allVisited = ctx.ekVisited + ctx.kalVisited
	for key in pairs(db.subzones) do
		local zone = key:match("^(.-)|")
		if zone then ctx.zoneSub[zone] = (ctx.zoneSub[zone] or 0) + 1 end
	end
	ctx.loreEK, ctx.loreKal = loreEK, loreKal
	ctx.loreBoth = (loreEK >= 15 and 1 or 0) + (loreKal >= 12 and 1 or 0)

	-- 퀘스트
	ctx.quests = db.quests.count or 0
	ctx.questZones, ctx.questMaxZone = 0, 0
	for _, n in pairs(ctx.questZone) do
		ctx.questZones = ctx.questZones + 1
		if n > ctx.questMaxZone then ctx.questMaxZone = n end
	end

	-- 던전 / 공격대
	ctx.runs, ctx.raidClears = 0, 0
	for name, d in pairs(db.dungeons) do
		ctx.runs = ctx.runs + (d.runs or 0)
		ctx.runCountName[name] = d.runs or 0
		if d.mapID then ctx.runCount[d.mapID] = math.max(ctx.runCount[d.mapID] or 0, d.runs or 0) end
		local bk = 0
		for _, n in pairs(d.bosses or {}) do bk = bk + n end
		ctx.instBossKills[name] = bk
		if d.best and (d.bestBosses or 0) > 0 then ctx.bestClear[name] = d.best end
		local cleared = d.cleared or 0
		if cleared > 0 then
			ctx.clearCountName[name] = cleared
			if d.mapID then ctx.clearCount[d.mapID] = math.max(ctx.clearCount[d.mapID] or 0, cleared) end
			if d.kind == "raid" then ctx.raidClears = ctx.raidClears + cleared end
		end
	end
	ctx.dungeonsCleared = 0
	for _, d in ipairs(ns.CLASSIC_DUNGEONS) do
		if (ctx.clearCount[d.map] or 0) > 0 or (ctx.clearCountName[d.name] or 0) > 0 then ctx.dungeonsCleared = ctx.dungeonsCleared + 1 end
	end
	ctx.bossKills = 0
	for _, b in pairs(db.bosses) do ctx.bossKills = ctx.bossKills + (b.kills or 0) end
	ctx.comeback = ach.flags.comeback or 0
	ctx.flawless = ach.flags.flawless or 0
	ctx.maxBossesRun = db.stats.maxBossesRun or 0
	ctx.fastRun = (db.stats.fastRun and db.stats.fastRun <= 1800) and 1 or 0
	ctx.wipes = db.stats.wipes or 0
	ctx.dungeonDeaths = db.stats.dungeonDeaths or 0

	-- 도감
	local found, _, species, rares, kills, families = B:Completion()
	ctx.tribes, ctx.species, ctx.rares, ctx.kills, ctx.families = found, species, rares, kills, families
	ctx.rareKills, ctx.worldBossKills, ctx.critters, ctx.elites = 0, 0, 0, 0
	local tribeSeen, habSp, habSeen, zoneSp, zoneSeen = ctx.tribeSeen, ctx.habitatSpecies, ctx.habitatSeen, ctx.zoneSpecies, ctx.zoneSeen
	for _, c in pairs(B.dex.creatures) do
		local tribe = c.tribe
		if tribe then tribeSeen[tribe] = (tribeSeen[tribe] or 0) + (c.seen or 0) end
		for z, n in pairs(c.zones or {}) do
			zoneSp[z] = (zoneSp[z] or 0) + 1
			zoneSeen[z] = (zoneSeen[z] or 0) + n
			if tribe then
				local k = tribe .. "|" .. z
				habSp[k] = (habSp[k] or 0) + 1
				habSeen[k] = (habSeen[k] or 0) + n
			end
		end
		if c.rareKilled then ctx.rareKills = ctx.rareKills + 1 end
		if c.bossKilled then ctx.worldBossKills = ctx.worldBossKills + 1 end
		if c.tribe == "critter" then ctx.critters = ctx.critters + 1 end
		if c.cls == "elite" or c.cls == "rareelite" then ctx.elites = ctx.elites + 1 end
		if c.tod then ctx.todSpecies[c.tod] = (ctx.todSpecies[c.tod] or 0) + 1 end
	end
	ctx.maxRank, ctx.rank4Count, ctx.rank6Count = 0, 0, 0
	for id, s in pairs(B:CollectAll()) do
		ctx.tribeKills[id] = s.kills
		ctx.tribeSpecies[id] = s.species
		if s.discovered then
			ctx.tribeFound[id] = 1
			ctx.tribeRank[id] = s.rank
			if s.rank > ctx.maxRank then ctx.maxRank = s.rank end
			if s.rank >= 4 then ctx.rank4Count = ctx.rank4Count + 1 end
			if s.rank >= 6 then ctx.rank6Count = ctx.rank6Count + 1 end
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

	-- 시련 / 연대기 / 소소한 재미
	ctx.deaths = db.deaths or 0
	local st = LogStats(db)
	for k, v in pairs(st) do if k ~= "key" and ctx[k] == nil then ctx[k] = v end end
	ctx.notes = st.notes
	ctx.logCount = st.entries   -- 업적 기록을 뺀 전기의 기록 수
	ctx.exported = db.stats.exported or 0
	ctx.daysSinceStart = db.started and math.floor((time() - db.started) / 86400) or 0
	return ctx
end

------------------------------------------------------------------------
-- 계정 공용 업적: 한 캐릭터가 이룬 업적은 같은 계정의 모든 캐릭터에서 달성으로 보인다
--   BigChronicleDB.ach.done[id] = { t = 달성 시각, by = 이룬 캐릭터, retro = 기록 이전에 이룬 것 }
------------------------------------------------------------------------
function A:Account()
	BigChronicleDB = BigChronicleDB or {}
	local acc = BigChronicleDB.ach
	if type(acc) ~= "table" then
		acc = {}
		BigChronicleDB.ach = acc
	end
	acc.done = acc.done or {}
	return acc
end

-- 가장 먼저 이룬 기록을 남긴다
function A:Record(id, t, retro)
	local all = self:Account().done
	local e = all[id]
	if not e or (t and e.t and t < e.t) then
		all[id] = { t = t, by = ns.PlayerName(), retro = retro and true or nil }
	end
end

-- 이 캐릭터가 이미 이룬 업적을 계정 기록에 합친다 (예전 버전의 캐릭터별 기록 포함)
function A:MergeCharacter()
	local ach = ns.char and ns.char.ach
	if not ach then return end
	for id, t in pairs(ach.done) do self:Record(id, t, ach.retro[id]) end
end

-- 달성 기록 (계정 공용). 없으면 nil
function A:Earned(id)
	local e = self:Account().done[id]
	if e then return e end
	local ach = ns.char and ns.char.ach
	if ach and ach.done[id] then
		return { t = ach.done[id], by = ns.PlayerName(), retro = ach.retro[id] }
	end
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

local function RawProgress(def, ctx)
	local ok, cur = pcall(def.progress, ctx)
	return ok and tonumber(cur) or 0
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
	-- 처음 켰을 때, 또는 업데이트로 업적 목록이 바뀐 뒤 처음 판정할 때 이미 만족한 것은 '이전에 이룬 업적'으로 조용히 남긴다
	-- (애드온을 1레벨에 처음 켠 캐릭터는 '이전에 이룬 것'이 없으니 그냥 새 업적으로 다룬다)
	local fresh = not ach.initialized and ((db.meta and db.meta.startLevel) or 1) <= 1
	local quiet = not fresh and (not ach.initialized or ach.sig ~= ns.ACH_SIGNATURE)
	local account = self:Account().done
	local newly, retro = {}, {}
	-- 같은 사다리(같은 값)의 단계는 값을 한 번만 읽고, 낮은 단계를 못 넘으면 높은 단계는 건너뛴다
	local ladderCur, ladderMiss = {}, {}
	for _, def in ipairs(ns.ACHIEVEMENTS) do
		-- 다른 캐릭터가 이미 이룬 업적은 이 캐릭터에서도 달성된 것으로 친다 (다시 알리지 않는다)
		local id = def.id
		if not ach.done[id] and not account[id] then
			local L = def.ladder
			if not (L and ladderMiss[L]) then
				local cur
				if L then
					cur = ladderCur[L]
					if cur == nil then
						cur = RawProgress(def, ctx)
						ladderCur[L] = cur
					end
				else
					cur = RawProgress(def, ctx)
				end
				if cur >= def.goal then
					ach.done[id] = time()
					if quiet then
						retro[#retro + 1] = def
						ach.retro[id] = true
					else
						newly[#newly + 1] = def
					end
					self:Record(id, ach.done[id], ach.retro[id])
				elseif L then
					ladderMiss[L] = true
				end
			end
		end
	end
	ach.sig = ns.ACH_SIGNATURE
	ach.seen = nil   -- 예전 버전의 '본 업적' 목록 (서명으로 바뀌었다)

	if #retro > 0 then
		local pts = 0
		for _, def in ipairs(retro) do pts = pts + def.points end
		local tpl = ach.initialized
			and "새로 펼친 업적의 페이지를 넘겨 보니, 이미 이룬 것이 {n}개나 있었다. 그 이름들이 조용히 전기에 새겨졌다."
			or "지난 여정의 발자취를 되짚어 보니, 이미 이룬 업적이 {n}개나 되었다. 그 이름들이 전기의 첫머리에 조용히 새겨졌다."
		ns.Chronicle:Add("achievement", Format(tpl, { n = ns.Comma(#retro) }) .. ns.Hex("  — 업적 " .. ns.Comma(#retro) .. "개 · +" .. ns.Comma(pts) .. "점", ns.COLOR.dim),
			{ retro = #retro })
	end
	ach.initialized = true
	if #newly > 0 then self:Announce(newly) end
	if #newly > 0 or #retro > 0 then ns:Fire("ACH_UPDATED", newly) end
end

-- 한 번의 판정에서 새로 이룬 업적들을 알린다
--   전기: 손으로 쓴 업적만 남긴다. 여럿이면 가장 큰 업적의 문장으로 한 줄에 묶는다.
--         자동 업적(단계별 이정표)은 전기에 따로 쓰지 않고, 같은 줄의 '외 N개'에만 더한다.
--   알림: 한 번에 한 장 (하나면 그 업적, 여럿이면 '업적 N개 달성!')
function A:Announce(list)
	local ach = ns.char.ach
	ach.unseen = ach.unseen or {}
	local major, minor, pts = {}, {}, 0
	for _, def in ipairs(list) do
		ach.unseen[def.id] = true
		pts = pts + def.points
		if def.minor then minor[#minor + 1] = def else major[#major + 1] = def end
	end
	local byPoints = function(a, b) return a.points > b.points end
	table.sort(major, byPoints)
	table.sort(minor, byPoints)
	-- 같은 사다리의 여러 단계는 가장 높은 단계 하나만 이름으로 보여 준다
	local shown, seenLadder = {}, {}
	local function pick(def)
		local L = def.ladder
		if L then
			if seenLadder[L] then
				if def.goal > seenLadder[L].goal then
					for i, d in ipairs(shown) do if d == seenLadder[L] then shown[i] = def end end
					seenLadder[L] = def
				end
				return
			end
			seenLadder[L] = def
		end
		shown[#shown + 1] = def
	end
	for _, def in ipairs(major) do pick(def) end
	for _, def in ipairs(minor) do pick(def) end
	local top = shown[1]

	if #major > 0 then
		local data = { ach = major[1].id, major = #major, count = #list }
		-- 던전·공격대 업적은 원정이 끝난 시각에 맞춰 적는다 (원정 정리는 던전을 나온 뒤 늦게 이루어질 수 있다)
		for _, def in ipairs(major) do
			if (def.cat == "dungeon" or def.cat == "raid") and self.lastExpStop and time() - self.lastExpStop < 3600 then
				data.t = self.lastExpStop
				ach.done[def.id] = self.lastExpStop
				local e = self:Account().done[def.id]
				if e and e.by == ns.PlayerName() then e.t = self.lastExpStop end
			end
		end
		local names = {}
		for i = 1, math.min(3, #major) do names[i] = "「" .. major[i].name .. "」" end
		local rest = #list - #names
		local tail = "  — 업적 " .. table.concat(names, ", ") .. (rest > 0 and (" 외 " .. rest .. "개") or "") .. " 달성 · +" .. pts .. "점"
		ns.Chronicle:Add("achievement", (major[1].flavor or "또 하나의 이야기가 완성되었다.") .. ns.Hex(tail, ns.COLOR.dim), data)
	end
	if ns.Toast then
		-- 점수는 제목 줄에, 업적 이름은 아랫줄에 (이름이 길어도 점수가 잘리지 않도록)
		if #list == 1 then
			ns.Toast:Show("업적 달성!   +" .. top.points .. "점", "「" .. top.name .. "」", top.icon, "achievement", { ach = top.id })
		else
			ns.Toast:Show("업적 " .. #list .. "개 달성!   +" .. pts .. "점", "「" .. top.name .. "」",
				top.icon, "achievement", { ach = top.id })
		end
	end
end

-- 분류마다 한 번에 세기 (업적 탭이 열릴 때 쓴다): sums[cat 또는 "all"] = { done, total, pts, maxPts }
function A:SummaryAll()
	local sums = { all = { 0, 0, 0, 0 } }
	local account = self:Account().done
	local mine = ns.char and ns.char.ach and ns.char.ach.done or {}
	for _, def in ipairs(ns.ACHIEVEMENTS) do
		local c = def.cat
		local s = sums[c]
		if not s then s = { 0, 0, 0, 0 }; sums[c] = s end
		local all = sums.all
		local p = def.points
		s[2], all[2] = s[2] + 1, all[2] + 1
		s[4], all[4] = s[4] + p, all[4] + p
		if account[def.id] or mine[def.id] then
			s[1], all[1] = s[1] + 1, all[1] + 1
			s[3], all[3] = s[3] + p, all[3] + p
		end
	end
	return sums
end

-- 요약: 달성 수, 전체 수, 점수, 전체 점수
function A:Summary(cat)
	local done, total, pts, maxPts = 0, 0, 0, 0
	for _, def in ipairs(ns.ACHIEVEMENTS) do
		if not cat or def.cat == cat then
			total = total + 1
			maxPts = maxPts + def.points
			if self:Earned(def.id) then
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
