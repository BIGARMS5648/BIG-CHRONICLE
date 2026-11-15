-- BIG CHRONICLE :: 모험 일지
-- 지역 탐험, 레벨업, 퀘스트, 던전 원정, 죽음, 재물, 나만의 기록을 RPG 전기처럼 남긴다.

local ADDON, ns = ...
local C = {}
ns.Chronicle = C

local Format, Pick, Q = ns.Format, ns.Pick, ns.Quote
local time, max = time, math.max

local I = "Interface\\Icons\\"

------------------------------------------------------------------------
-- 분류 / 장(章)
------------------------------------------------------------------------
C.CATS = {
	start     = { name = "모험의 시작", group = "growth",  icon = I .. "INV_Misc_Book_09" },
	zone      = { name = "지역 탐험",   group = "explore", icon = I .. "INV_Misc_Map_01" },
	subzone   = { name = "장소 발견",   group = "explore", icon = I .. "Ability_Hunter_Pathfinding" },
	level     = { name = "레벨업",      group = "growth",  icon = I .. "Spell_Holy_InnerFire" },
	quest     = { name = "퀘스트",      group = "quest",   icon = I .. "INV_Misc_Note_01" },
	dungeon   = { name = "던전 원정",   group = "dungeon", icon = I .. "INV_Misc_Key_03" },
	boss      = { name = "보스 처치",   group = "dungeon", icon = I .. "INV_Misc_Bone_HumanSkull_01" },
	pvp       = { name = "전장",        group = "dungeon", icon = I .. "Ability_DualWield" },
	death     = { name = "죽음",        group = "trial",   icon = I .. "Spell_Shadow_DeathScream" },
	dex       = { name = "도감",        group = "dex",     icon = I .. "Ability_EyeOfTheOwl" },
	rare      = { name = "희귀 개체",   group = "dex",     icon = I .. "INV_Misc_Gem_Ruby_01" },
	milestone = { name = "업적",        group = "dex",     icon = I .. "Ability_Warrior_BattleShout" },
	money     = { name = "재물",        group = "growth",  icon = I .. "INV_Misc_Coin_01" },
	bind      = { name = "귀환석",      group = "growth",  icon = I .. "INV_Misc_Rune_01" },
	note      = { name = "나의 기록",   group = "note",    icon = I .. "INV_Scroll_03" },
}

C.GROUPS = {
	{ id = "explore", name = "탐험" },
	{ id = "growth",  name = "성장" },
	{ id = "quest",   name = "퀘스트" },
	{ id = "dungeon", name = "던전·전장" },
	{ id = "dex",     name = "도감" },
	{ id = "trial",   name = "시련" },
	{ id = "note",    name = "나의 기록" },
}

C.CHAPTERS = {
	{ min = 1,  max = 9,   title = "제1장 · 첫걸음",         desc = "고향 땅에서 처음 무기를 쥐던 시절" },
	{ min = 10, max = 19,  title = "제2장 · 모험가의 길",     desc = "세상이 생각보다 넓다는 것을 알게 된 시절" },
	{ min = 20, max = 29,  title = "제3장 · 넓어지는 세계",   desc = "낯선 땅과 첫 던전의 기억" },
	{ min = 30, max = 39,  title = "제4장 · 시련의 대지",     desc = "위험한 땅에서 이름을 단련하던 시절" },
	{ min = 40, max = 49,  title = "제5장 · 이름을 떨치다",   desc = "탈것에 올라 대륙을 누비던 시절" },
	{ min = 50, max = 59,  title = "제6장 · 전설의 문턱",     desc = "정점을 향한 마지막 여정" },
	{ min = 60, max = 999, title = "제7장 · 아제로스의 영웅", desc = "전설이 된 이후의 이야기" },
}

function C:ChapterIndex(lvl)
	lvl = lvl or 1
	for i, ch in ipairs(self.CHAPTERS) do
		if lvl >= ch.min and lvl <= ch.max then return i end
	end
	return 1
end

------------------------------------------------------------------------
-- 문장 템플릿
------------------------------------------------------------------------
local T = {}
C.TEMPLATES = T

T.start = "{lvl}레벨, {zone:에서} 첫 모험을 시작했다. {hero}의 전기가 이곳에서부터 기록된다."

T.zone = {
	"{lvl}레벨, 처음으로 {zone:에} 발을 들였다.",
	"{lvl}레벨, 낯선 땅 {zone:에} 도착했다. 새로운 이야기가 기다리고 있을 것만 같다.",
	"{lvl}레벨, 지도 위의 빈칸이던 {zone:을} 마침내 밟았다.",
	"{lvl}레벨, {zone:으로} 향하는 길에 올랐다. 이곳에서는 어떤 모험이 펼쳐질까.",
}

T.subzone = {
	"{zone}의 {sub:을} 발견했다.",
	"{zone:을} 헤매다 {sub:에} 이르렀다.",
	"{sub:이라는} 곳을 처음으로 찾아냈다. ({zone})",
}

T.level = {
	"{lvl}레벨 달성! {zone:에서} 한층 더 강해졌다.",
	"{lvl}레벨이 되었다. {zone}의 바람이 축하해 주는 듯하다.",
	"{lvl}레벨에 올랐다. 몸 깊은 곳에서 새로운 힘이 솟구친다.",
	"{lvl}레벨 달성! 지난 전투의 상처가 어느새 단단한 근육이 되었다.",
}

T.levelMilestone = {
	[10] = "{lvl}레벨 달성! 이제 진정한 모험가로 인정받기 시작했다. 나만의 길이 더욱 깊어진다.",
	[20] = "{lvl}레벨 달성! {zone:에서} 이름을 알리기 시작한 모험가가 되었다.",
	[30] = "{lvl}레벨 달성! 숱한 전투를 거치며 어엿한 베테랑의 반열에 들어섰다.",
	[40] = "{lvl}레벨 달성! 드디어 탈것을 몰고 대륙을 누빌 자격을 얻었다.",
	[50] = "{lvl}레벨 달성! 전설로 향하는 마지막 관문이 눈앞에 보인다.",
	[60] = "{lvl}레벨 달성! 마침내 아제로스의 영웅으로서 정점에 올랐다. 이제 진짜 전설이 시작된다.",
}

T.quest = {
	"{lvl}레벨, {zone:에서} {quest} 임무를 완수했다.",
	"{lvl}레벨, {quest} 의뢰를 무사히 마쳤다.",
	"{lvl}레벨, {zone:에서} {quest}의 이야기에 마침표를 찍었다.",
}

T.dungeonFirst = "{lvl}레벨, {party} 던전 {dungeon} 원정에 처음으로 나섰다."
T.dungeonAgain = "{lvl}레벨, {party} {dungeon:에} 다시 발을 들였다. ({n}번째 원정)"
T.raidFirst    = "{lvl}레벨, {n}명의 공격대와 함께 {dungeon} 공략에 처음으로 나섰다."
T.raidAgain    = "{lvl}레벨, {n}명의 공격대와 함께 다시 {dungeon:에} 도전했다. ({runs}번째 도전)"
T.dungeonEnd   = "{dungeon} 원정을 마쳤다. — 소요 시간 {dur}, 쓰러뜨린 보스 {k}명{extra}"
T.bossFirst    = "{boss:을} 처음으로 쓰러뜨렸다! ({dungeon})"
T.bossAgain    = "{boss:을} 다시 쓰러뜨렸다. (통산 {n}회)"
T.pvp          = "{lvl}레벨, 전장 {bg:에} 참전했다."

T.death = {
	"{lvl}레벨, {zone:에서} 쓰러졌다… 영혼이 되어 시체를 찾아 헤맸다.",
	"{lvl}레벨, {zone:에서} 쓰디쓴 패배를 맛보았다. 다음엔 더 강해지리라.",
	"{lvl}레벨, {zone:에서} 정신을 잃었다. 영혼의 치유사가 조용히 손을 내민다.",
}

T.money = {
	[1]    = "{lvl}레벨, 처음으로 {gold}골드를 모았다. 주머니에서 짤랑거리는 소리가 난다.",
	[10]   = "{lvl}레벨, 처음으로 {gold}골드를 모았다. 주머니가 제법 묵직해졌다.",
	[50]   = "{lvl}레벨, 처음으로 {gold}골드를 모았다. 상인들의 눈빛이 달라졌다.",
	[100]  = "{lvl}레벨, 처음으로 {gold}골드를 모았다! 이제 탈것도 꿈이 아니다.",
	[250]  = "{lvl}레벨, 처음으로 {gold}골드를 모았다. 꽤 이름난 부자가 되었다.",
	[500]  = "{lvl}레벨, 처음으로 {gold}골드를 모았다. 경매장의 큰손이라 불릴 만하다.",
	[1000] = "{lvl}레벨, 처음으로 {gold}골드를 모았다! 전설적인 부호의 반열에 올랐다.",
	[5000] = "{lvl}레벨, 처음으로 {gold}골드를 모았다. 고블린 재벌도 고개를 숙일 재산이다.",
}
C.MONEY_STEPS = { 1, 10, 50, 100, 250, 500, 1000, 5000 }

T.bind = "{lvl}레벨, 귀환석의 귀환 장소를 {place:으로} 정했다."
T.note = "“{text}”"

------------------------------------------------------------------------
-- 기록 추가
------------------------------------------------------------------------
local CHAT_SKIP = { subzone = true }

function C:Add(cat, text, data)
	local db = ns.char
	if not db or not text then return end
	local e = { t = time(), lvl = ns.PlayerLevel(), cat = cat, text = text, zone = ns.Zone() }
	if data then
		for k, v in pairs(data) do e[k] = v end
	end
	db.log[#db.log + 1] = e
	if ns.db and ns.db.chat and not CHAT_SKIP[cat] then
		ns.Print(text)
	end
	ns:Fire("LOG_ADDED", e)
	return e
end

function C:AddNote(text)
	text = ns.Trim(text)
	if text == "" then return end
	text = text:gsub("|", "||") -- 이스케이프 코드 무력화
	self:Add("note", Format(T.note, { text = text }), { user = true })
	if not (ns.db and ns.db.chat) then ns.Print("일지에 기록했습니다.") end
end

------------------------------------------------------------------------
-- 시작
------------------------------------------------------------------------
function C:Init()
	self.titleCache = {}
	local on = function(ev, fn) ns:On(ev, function(...) fn(self, ...) end) end
	on("PLAYER_ENTERING_WORLD", self.OnEnteringWorld)
	on("ZONE_CHANGED_NEW_AREA", self.OnZoneChanged)
	on("ZONE_CHANGED", self.OnSubZoneChanged)
	on("ZONE_CHANGED_INDOORS", self.OnSubZoneChanged)
	on("PLAYER_LEVEL_UP", self.OnLevelUp)
	on("QUEST_ACCEPTED", self.OnQuestAccepted)
	on("QUEST_DETAIL", self.OnQuestFrame)
	on("QUEST_PROGRESS", self.OnQuestFrame)
	on("QUEST_COMPLETE", self.OnQuestFrame)
	on("QUEST_TURNED_IN", self.OnQuestTurnedIn)
	on("ENCOUNTER_END", self.OnEncounterEnd)
	on("BOSS_KILL", self.OnBossKill)
	on("PLAYER_DEAD", self.OnPlayerDead)
	on("PLAYER_MONEY", self.CheckMoney)
	on("HEARTHSTONE_BOUND", self.OnHearthBound)
	on("TIME_PLAYED_MSG", self.OnTimePlayed)
end

function C:OnEnteringWorld()
	if not self.started then
		if C_Timer and C_Timer.After then
			C_Timer.After(1.5, function() C:Start() end)
		else
			self:Start()
		end
	else
		self:OnZoneChanged()
	end
end

function C:Start()
	local db = ns.char
	if not db then return end
	local zone = ns.Zone()
	if zone == "" then
		self.retries = (self.retries or 0) + 1
		if self.retries < 10 and C_Timer then
			C_Timer.After(2, function() C:Start() end)
			return
		end
	end
	if self.started then return end
	self.started = true

	local lvl = ns.PlayerLevel()
	local now = time()
	if not db.started then
		db.started = now
		local name = ns.PlayerName()
		local race = ns.Call(UnitRace, "player") or ""
		local class = ns.Call(UnitClass, "player") or ""
		db.meta = { name = name, race = race, class = class, startLevel = lvl, startZone = zone }
		local hero = ns.Trim(race .. " " .. class .. " " .. name)

		local inInst = ns.Call(IsInInstance)
		if zone ~= "" and not inInst then
			db.zones[zone] = { first = now, lvl = lvl, time = 0, visits = 1 }
			local sub = ns.SubZone()
			if sub ~= "" and sub ~= zone then db.subzones[zone .. "|" .. sub] = now end
		end
		db.levels[lvl] = now
		-- 이미 가진 돈은 '처음 모은 것'이 아니므로 조용히 표시만 해 둔다
		local money = ns.Call(GetMoney) or 0
		for _, g in ipairs(self.MONEY_STEPS) do
			if money >= g * 10000 then db.money[g] = 0 end
		end
		self:Add("start", Format(T.start, { lvl = lvl, zone = zone ~= "" and zone or "어딘가", hero = hero }))
	end

	db.meta = db.meta or {}
	db.meta.level = lvl

	self:OnZoneChanged()
	self:CheckMoney()

	if C_Timer and C_Timer.NewTicker and not self.ticker then
		self.ticker = C_Timer.NewTicker(10, function()
			local ok, err = pcall(C.Tick, C)
			if not ok then ns:Error(err) end
		end)
	end
end

function C:OnReset()
	self.started = false
	self.currentZone = nil
	self:Start()
end

------------------------------------------------------------------------
-- 지역
------------------------------------------------------------------------
local function InWorldInstance()
	local inInst, itype = ns.Call(IsInInstance)
	if inInst and itype and itype ~= "none" then return true, itype end
	return false, itype
end

function C:OnZoneChanged()
	local db = ns.char
	if not db or not self.started then return end
	self:CheckInstance()

	local zone = ns.Zone()
	if zone == "" then return end
	if InWorldInstance() then
		self.currentZone = nil
		return
	end

	local now = time()
	local z = db.zones[zone]
	if not z then
		local lvl = ns.PlayerLevel()
		db.zones[zone] = { first = now, lvl = lvl, time = 0, visits = 1 }
		self:Add("zone", Format(Pick(T.zone), { lvl = lvl, zone = zone }))
	elseif self.currentZone ~= zone then
		z.visits = (z.visits or 0) + 1
	end
	self.currentZone = zone
	self:OnSubZoneChanged()
end

function C:OnSubZoneChanged()
	local db = ns.char
	if not db or not self.started then return end
	if InWorldInstance() then return end
	local zone, sub = ns.Zone(), ns.SubZone()
	if zone == "" or sub == "" or sub == zone then return end
	if not db.zones[zone] then return self:OnZoneChanged() end
	local key = zone .. "|" .. sub
	if db.subzones[key] then return end
	db.subzones[key] = time()
	if ns.db.logSubzones then
		self:Add("subzone", Format(Pick(T.subzone), { zone = zone, sub = sub }))
	end
end

function C:Tick()
	local db = ns.char
	if not db then return end
	local now = time()
	db.stats.tracked = (db.stats.tracked or 0) + 10
	local zone = self.currentZone
	if zone and db.zones[zone] then
		db.zones[zone].time = (db.zones[zone].time or 0) + 10
	end
	local exp = db.expedition
	if exp then
		if InWorldInstance() then
			exp.lastSeen = now
		else
			self:CheckInstance()
		end
	end
end

------------------------------------------------------------------------
-- 던전 원정 / 전장
------------------------------------------------------------------------
local LEAVE_GRACE = 15 * 60 -- 던전 밖으로 나가도 15분 안에 돌아오면 같은 원정

function C:CheckInstance()
	local db = ns.char
	if not db then return end
	local now = time()
	local inInst, itype = InWorldInstance()
	local exp = db.expedition

	if inInst and (itype == "party" or itype == "raid") then
		local name, _, _, _, maxPlayers = ns.Call(GetInstanceInfo)
		if not name or name == "" then return end
		if exp and exp.name == name then
			local away = exp.left or exp.lastSeen
			if exp.left and now - exp.left > LEAVE_GRACE then
				self:EndExpedition()
				exp = nil
			elseif not exp.left and away and now - away > LEAVE_GRACE * 4 then
				-- 오래전에 접속을 끊은 원정 (다른 날 다시 들어온 경우)
				self:EndExpedition()
				exp = nil
			else
				exp.left = nil
				exp.lastSeen = now
				return
			end
		end
		if exp then self:EndExpedition() end

		local d = db.dungeons[name]
		if not d then
			d = { runs = 0, first = now, bosses = {}, kind = itype }
			db.dungeons[name] = d
		end
		d.runs = d.runs + 1
		d.last = now

		local lvl = ns.PlayerLevel()
		local group = ns.Call(GetNumGroupMembers) or 0
		db.expedition = { name = name, kind = itype, start = now, lastSeen = now, bosses = {}, deaths = 0, wipes = 0, lvl = lvl, group = group }

		local text
		if itype == "raid" then
			local n = group > 0 and group or (maxPlayers or 40)
			text = Format(d.runs == 1 and T.raidFirst or T.raidAgain, { lvl = lvl, n = n, dungeon = Q(name), runs = d.runs })
		else
			local party = group > 1 and (group .. "인 일행과 함께") or "홀로"
			text = Format(d.runs == 1 and T.dungeonFirst or T.dungeonAgain, { lvl = lvl, party = party, dungeon = Q(name), n = d.runs })
		end
		self:Add("dungeon", text, { dungeon = name })

	elseif inInst and (itype == "pvp" or itype == "arena") then
		if exp then self:EndExpedition() end
		local name = ns.Call(GetInstanceInfo)
		if name and name ~= "" and (self.lastBG ~= name or now - (self.lastBGTime or 0) > 600) then
			db.pvp[name] = (db.pvp[name] or 0) + 1
			self:Add("pvp", Format(T.pvp, { lvl = ns.PlayerLevel(), bg = Q(name) }), { bg = name })
		end
		self.lastBG, self.lastBGTime = name, now

	elseif exp then
		if not exp.left then
			-- 접속 종료 후 오랜만에 다시 들어온 경우엔 마지막으로 던전에 있던 시각을 기준으로 한다
			if exp.lastSeen and now - exp.lastSeen > 120 then
				exp.left = exp.lastSeen
			else
				exp.left = now
			end
		end
		if now - exp.left > LEAVE_GRACE then
			self:EndExpedition()
		end
	end
end

function C:EndExpedition()
	local db = ns.char
	local exp = db and db.expedition
	if not exp then return end
	db.expedition = nil
	local stop = exp.left or exp.lastSeen or time()
	local dur = max(0, stop - (exp.start or stop))
	local k = #exp.bosses
	if dur < 60 and k == 0 then return end -- 입구만 들렀다 나온 경우

	local d = db.dungeons[exp.name]
	if d then
		d.time = (d.time or 0) + dur
		if k > 0 and (not d.best or dur < d.best) and k >= (d.bestBosses or 0) then
			d.best, d.bestBosses = dur, k
		end
	end

	local extra = {}
	if exp.deaths > 0 then extra[#extra + 1] = "쓰러짐 " .. exp.deaths .. "회" end
	if exp.wipes > 0 then extra[#extra + 1] = "전멸 " .. exp.wipes .. "회" end
	local extraText = #extra > 0 and (", " .. table.concat(extra, ", ")) or ""
	self:Add("dungeon", Format(T.dungeonEnd, { dungeon = Q(exp.name), dur = ns.FormatDuration(dur), k = k, extra = extraText }),
		{ dungeon = exp.name, ended = true })
end

function C:RecordBoss(encounterID, bossName)
	local db = ns.char
	if not db or not bossName or bossName == "" then return end
	local now = GetTime()
	if self.lastBoss == (encounterID or bossName) and now - (self.lastBossTime or 0) < 30 then return end
	self.lastBoss, self.lastBossTime = encounterID or bossName, now

	local b = db.bosses[bossName]
	if not b then
		b = { first = time(), kills = 0 }
		db.bosses[bossName] = b
	end
	b.kills = b.kills + 1
	b.last = time()

	local exp = db.expedition
	local dungeonName = (exp and exp.name) or ns.Zone()
	b.dungeon = b.dungeon or dungeonName
	if exp then
		table.insert(exp.bosses, bossName)
		local d = db.dungeons[exp.name]
		if d then d.bosses[bossName] = (d.bosses[bossName] or 0) + 1 end
	end

	local text
	if b.kills == 1 then
		text = Format(T.bossFirst, { boss = Q(bossName), dungeon = dungeonName })
	else
		text = Format(T.bossAgain, { boss = Q(bossName), n = b.kills })
	end
	self:Add("boss", text, { boss = bossName, dungeon = dungeonName })
end

function C:OnEncounterEnd(_, encounterID, encounterName, _, _, success)
	if success == 1 or success == true then
		self:RecordBoss(encounterID, encounterName)
	else
		local exp = ns.char and ns.char.expedition
		if exp then exp.wipes = exp.wipes + 1 end
	end
end

function C:OnBossKill(_, encounterID, encounterName)
	self:RecordBoss(encounterID, encounterName)
end

------------------------------------------------------------------------
-- 레벨업
------------------------------------------------------------------------
function C:OnLevelUp(_, newLevel)
	local db = ns.char
	if not db then return end
	local lvl = tonumber(newLevel) or (ns.PlayerLevel() + 1)
	local now = time()
	local prev = db.levels[lvl - 1]
	db.levels[lvl] = now
	if db.meta then db.meta.level = lvl end

	local zone = ns.Zone()
	local tpl = T.levelMilestone[lvl] or Pick(T.level)
	local text = Format(tpl, { lvl = lvl, zone = zone ~= "" and zone or "이곳" })
	if prev and now - prev > 0 then
		text = text .. ns.Hex(" (지난 레벨 이후 " .. ns.FormatDuration(now - prev) .. ")", ns.COLOR.dim)
	end
	-- 레벨업 순간에는 UnitLevel이 아직 이전 값일 수 있으므로 새 레벨로 기록한다
	self:Add("level", text, { lvl = lvl })
end

------------------------------------------------------------------------
-- 퀘스트
------------------------------------------------------------------------
function C:CacheTitle(questID, title)
	if questID and title and title ~= "" then
		self.titleCache[questID] = title
	end
end

function C:OnQuestAccepted(_, a, b)
	local questID = b or a -- 구버전은 (logIndex, questID), 현행은 (questID)
	if type(questID) ~= "number" then return end
	if C_QuestLog and C_QuestLog.GetTitleForQuestID then
		self:CacheTitle(questID, ns.Call(C_QuestLog.GetTitleForQuestID, questID))
	end
end

function C:OnQuestFrame()
	local id = ns.Call(GetQuestID)
	local title = ns.Call(GetTitleText)
	self:CacheTitle(id, title)
end

function C:OnQuestTurnedIn(_, questID, xpReward, moneyReward)
	local db = ns.char
	if not db then return end
	local title
	if C_QuestLog and C_QuestLog.GetTitleForQuestID then
		title = ns.Call(C_QuestLog.GetTitleForQuestID, questID)
	end
	title = (title and title ~= "") and title or self.titleCache[questID] or "이름 모를 의뢰"

	db.quests.count = (db.quests.count or 0) + 1
	if questID then db.quests.ids[questID] = time() end

	local zone = ns.Zone()
	local lvl = ns.PlayerLevel()
	local text = Format(Pick(T.quest), { lvl = lvl, zone = zone ~= "" and zone or "어딘가", quest = Q(title) })

	if ns.db.questRewards then
		local parts = {}
		if tonumber(xpReward) and xpReward > 0 then parts[#parts + 1] = "경험치 +" .. ns.Comma(xpReward) end
		if tonumber(moneyReward) and moneyReward > 0 then parts[#parts + 1] = ns.FormatMoney(moneyReward) end
		if #parts > 0 then
			text = text .. ns.Hex(" (" .. table.concat(parts, " · ") .. ")", ns.COLOR.dim)
		end
	end
	self:Add("quest", text, { quest = title, qid = questID })
end

------------------------------------------------------------------------
-- 죽음
------------------------------------------------------------------------
function C:OnPlayerDead()
	local db = ns.char
	if not db then return end
	db.deaths = (db.deaths or 0) + 1
	if db.expedition then db.expedition.deaths = db.expedition.deaths + 1 end

	local zone = ns.Zone()
	local text = Format(Pick(T.death), { lvl = ns.PlayerLevel(), zone = zone ~= "" and zone or "어딘가" })
	-- 마지막으로 맞서던 상대
	local Call = ns.Call
	if Call(UnitExists, "target") and not Call(UnitIsPlayer, "target") and Call(UnitCanAttack, "player", "target") then
		local foe = Call(UnitName, "target")
		if foe and foe ~= "" then
			text = text .. ns.Format(" — 마지막 상대: {creature}", { creature = Q(foe) })
		end
	end
	self:Add("death", text)
end

------------------------------------------------------------------------
-- 재물 / 귀환석 / 플레이 시간
------------------------------------------------------------------------
function C:CheckMoney()
	local db = ns.char
	if not db or not db.started then return end
	local money = ns.Call(GetMoney)
	if not money then return end
	for _, g in ipairs(self.MONEY_STEPS) do
		if not db.money[g] and money >= g * 10000 then
			db.money[g] = time()
			self:Add("money", Format(T.money[g], { lvl = ns.PlayerLevel(), gold = ns.Comma(g) }))
		end
	end
end

function C:OnHearthBound()
	local place = ns.Call(GetBindLocation)
	if not place or place == "" then return end
	local db = ns.char
	if db.lastBind == place then return end
	db.lastBind = place
	self:Add("bind", Format(T.bind, { lvl = ns.PlayerLevel(), place = place }))
end

function C:OnTimePlayed(_, total, thisLevel)
	local db = ns.char
	if not db or not tonumber(total) then return end
	db.stats.played = total
	db.stats.playedLevel = thisLevel
	db.stats.playedAt = time()
end

------------------------------------------------------------------------
-- 내보내기
------------------------------------------------------------------------
function C:ExportText()
	local db = ns.char
	if not db then return "" end
	local out = {}
	local meta = db.meta or {}
	out[#out + 1] = "BIG CHRONICLE — " .. (meta.name or ns.PlayerName()) .. "의 모험 전기"
	out[#out + 1] = ns.Trim((meta.race or "") .. " " .. (meta.class or "")) .. " · 현재 " .. ns.PlayerLevel() .. "레벨"
	out[#out + 1] = ""
	local lastChapter, lastDay
	for _, e in ipairs(db.log) do
		local ch = self:ChapterIndex(e.lvl)
		if ch ~= lastChapter then
			out[#out + 1] = ""
			out[#out + 1] = "■ " .. self.CHAPTERS[ch].title
			lastChapter = ch
			lastDay = nil
		end
		local day = ns.DayKey(e.t)
		if day ~= lastDay then
			out[#out + 1] = "  [" .. ns.FormatDate(e.t) .. "]"
			lastDay = day
		end
		out[#out + 1] = "  " .. ns.FormatClock(e.t) .. "  " .. ns.StripCodes(e.text)
	end
	return table.concat(out, "\n")
end
