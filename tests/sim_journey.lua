-- BIG CHRONICLE :: 1~60레벨 장기 여정 시뮬레이션
-- 한 캐릭터가 여러 지역을 돌며 레벨업·퀘스트·사냥·던전·죽음·접속 종료(/reload)를 겪는 과정을 흉내 내고,
-- 남은 기록이 서로 모순되지 않는지, 문장이 어색하지 않은지 검사한 뒤 전기 전문을 출력한다.
--
-- 사용법 (저장소 루트에서):  lua5.1 tests/sim_journey.lua [seed] [--quiet]

local here = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
package.path = here .. "/?.lua;" .. package.path
local M = require("mockwow")
local addonDir = here .. "/../BigChronicle"
local seed = tonumber(arg[1]) or 7
local quiet = false
for _, a in ipairs(arg) do if a == "--quiet" then quiet = true end end
math.randomseed(seed)

local S = M.state
S.level, S.zone, S.sub, S.money = 1, "엘윈 숲", "북녘골", 0

local issues = {}
local function issue(msg) issues[#issues + 1] = msg end

------------------------------------------------------------------------
-- 저장 변수 흉내: 함수·순환 참조가 있으면 실제 게임에서 저장이 깨진다
------------------------------------------------------------------------
local function deepcopy(v, path, seen)
	local t = type(v)
	if t == "table" then
		seen = seen or {}
		if seen[v] then issue("저장 데이터에 순환 참조: " .. path) return nil end
		seen[v] = true
		local out = {}
		for k, x in pairs(v) do
			local kt = type(k)
			if kt ~= "string" and kt ~= "number" then issue("저장 데이터 키 타입 이상: " .. path .. " " .. kt) end
			out[k] = deepcopy(x, path .. "." .. tostring(k), seen)
		end
		seen[v] = nil
		return out
	elseif t == "function" or t == "userdata" or t == "thread" then
		issue("저장 데이터에 " .. t .. ": " .. path)
		return nil
	end
	return v
end

local ns
local function login()
	M.tickers, M.timers = {}, {}
	ns = M.load(addonDir)
	M.fire("ADDON_LOADED", "BigChronicle")
	M.fire("PLAYER_LOGIN")
	M.fire("PLAYER_ENTERING_WORLD", true, false)
	M.runTimers()
end

local function relog(offlineSeconds)
	BigChronicleDB = deepcopy(BigChronicleDB, "BigChronicleDB")
	BigChronicleCharDB = deepcopy(BigChronicleCharDB, "BigChronicleCharDB")
	M.advance(offlineSeconds or 5)
	login()
end

local function play(seconds)
	local n = math.floor(seconds / 10)
	M.tick(n)
end

------------------------------------------------------------------------
-- 세계
------------------------------------------------------------------------
local ZONES = {
	{ zone = "엘윈 숲", lvl = { 1, 10 }, subs = { "북녘골", "골드샤이어", "제리코 농장" }, mobs = {
		{ "코볼트 부랑자", "인간형" }, { "코볼트 일꾼", "인간형" }, { "어린 늑대", "야수", "늑대" }, { "멀록 약탈자", "인간형" },
		{ "강바닥발톱 놀", "인간형" }, { "강바닥발톱 잡종개", "인간형" }, { "호거", "인간형", nil, "elite" }, { "숲 거미", "야수", "거미" },
		{ "데피아즈 노상강도", "인간형" }, { "토끼", "동물" } } },
	{ zone = "서부 몰락지대", lvl = { 10, 18 }, subs = { "감시의 언덕", "몰딘 농장" }, mobs = {
		{ "수확 골렘", "기계" }, { "데피아즈 약탈자", "인간형" }, { "멀록 파도사냥꾼", "인간형" }, { "얼룩무늬 멧돼지", "야수", "멧돼지" },
		{ "늙은 바위턱", "인간형", nil, "rare" }, { "데피아즈 밀수꾼", "인간형" } } },
	{ zone = "그늘숲", lvl = { 18, 25 }, subs = { "어둠골", "까마귀 언덕" }, mobs = {
		{ "구울", "언데드" }, { "밤의 파멸 그림자술사", "인간형" }, { "검은 새끼용", "용족" }, { "검은 늑대", "야수", "늑대" },
		{ "모르라딤", "언데드", nil, "rare" } } },
	{ zone = "가시덤불 골짜기", lvl = { 30, 36 }, subs = { "무법항", "그롬골 주둔지", "줄구룹 입구" }, mobs = {
		{ "피투성이 사냥꾼", "인간형" }, { "정글 표범", "야수", "살쾡이" }, { "붉은해적단 해적", "인간형" },
		{ "투자개발회사 벌목꾼", "인간형" }, { "가시덤불 랩터", "야수", "랩터" }, { "오우거 집행자", "인간형" } } },
	{ zone = "잊혀진 땅", lvl = { 36, 42 }, subs = { "니젤의 야영지", "마그람 마을" }, mobs = {
		{ "마그람 약탈자", "인간형" }, { "겔키스 궁수", "인간형" }, { "불타는 칼날 광신도", "인간형" }, { "사티로스 악마술사", "인간형" },
		{ "가시채찍 나가", "인간형" }, { "켄타우로스 대장", "인간형", nil, "rareelite" } } },
	{ zone = "타나리스", lvl = { 42, 50 }, subs = { "가젯잔", "모래폭풍 협곡" }, mobs = {
		{ "남쪽바다 해적", "인간형" }, { "모래바람 트롤", "인간형" }, { "실리시드 일벌", "야수" }, { "사막 거미", "야수", "거미" } } },
	{ zone = "여명의 설원", lvl = { 53, 60 }, subs = { "눈망울 마을", "얼음바람 동굴" }, mobs = {
		{ "얼음발톱 예티", "야수" }, { "겨울바람 펄볼그", "인간형" }, { "서리불꽃 정령", "정령" }, { "푸른 용족 수호자", "용족", nil, "elite" } } },
}

local DUNGEONS = {
	{ lvl = 20, zone = "그늘숲", name = "죽음의 폐광", map = 36, bosses = { "루그루그", "스니드의 벌목기", "에드윈 밴클리프" } },
	{ lvl = 38, zone = "잊혀진 땅", name = "마라우돈", map = 349, bosses = { "노크세온", "공주 테라드라스" } },
	{ lvl = 58, zone = "여명의 설원", name = "검은바위 첨탑", map = 229, bosses = { "우로크 둠하울", "대군주 렌드 블랙핸드" }, raid = false },
}

local mobGUID = 0
local npcIds, npcNext = {}, 1000
local function npcId(name)
	if not npcIds[name] then npcNext = npcNext + 1; npcIds[name] = npcNext end
	return npcIds[name]
end

local truth = {}       -- 실제로 죽인 횟수 (이름별)
local deathsTruth = 0

local function spawn(spec, lvl)
	mobGUID = mobGUID + 1
	return {
		name = spec[1], ctype = spec[2], family = spec[3], cls = spec[4] or "normal",
		level = math.max(1, lvl + math.random(-1, 1)),
		guid = string.format("Creature-0-1-0-1-%d-%08X", npcId(spec[1]), mobGUID),
	}
end

local function xpMessage(name)
	return ns.Josa(name, "을") .. " 처치하여 경험치를 " .. math.random(40, 900) .. " 획득했습니다."
end

-- 몬스터 한 마리와 싸운다. 처치 경로를 무작위로 섞는다.
local function fight(spec, lvl)
	local mob = spawn(spec, lvl)
	local route = math.random(1, 4)
	if route == 1 then
		-- 대상 지정 → 죽음 감지 + 경험치 메시지
		M.setUnit("target", mob); M.fire("PLAYER_TARGET_CHANGED")
		M.advance(8)
		mob.dead = true; M.fire("UNIT_HEALTH", "target")
		if S.level < 60 then M.fire("CHAT_MSG_COMBAT_XP_GAIN", xpMessage(mob.name)) end
	elseif route == 2 then
		-- 이름표만 보고 광역으로 잡음
		M.setUnit("nameplate3", mob); M.fire("NAME_PLATE_UNIT_ADDED", "nameplate3")
		M.advance(6)
		mob.dead = true; M.fire("UNIT_HEALTH", "nameplate3")
		M.fire("NAME_PLATE_UNIT_REMOVED", "nameplate3")
		if S.level < 60 then M.fire("CHAT_MSG_COMBAT_XP_GAIN", xpMessage(mob.name)) end
	elseif route == 3 then
		-- 마우스만 올리고 경험치 메시지로만 확인
		M.setUnit("mouseover", mob); M.fire("UPDATE_MOUSEOVER_UNIT")
		M.advance(9)
		if S.level < 60 then
			M.fire("CHAT_MSG_COMBAT_XP_GAIN", xpMessage(mob.name))
		else
			mob.dead = true
			M.setUnit("target", mob); M.fire("PLAYER_TARGET_CHANGED")
			-- 대상이 이미 죽은 상태로 처음 잡히면 처치로 세지 않는다 (실제로도 모름)
			return false
		end
	else
		-- 대상 지정, 경험치 메시지 먼저 도착
		M.setUnit("target", mob); M.fire("PLAYER_TARGET_CHANGED")
		M.advance(7)
		if S.level < 60 then M.fire("CHAT_MSG_COMBAT_XP_GAIN", xpMessage(mob.name)) end
		mob.dead = true; M.fire("UNIT_HEALTH", "target")
	end
	truth[mob.name] = (truth[mob.name] or 0) + 1
	M.advance(4)
	return true
end

local questN = 0
M.questTitles = {}
local function quest(zoneName)
	questN = questN + 1
	local title = zoneName .. "의 부탁 " .. questN
	M.questTitles[5000 + questN] = title
	M.fire("QUEST_ACCEPTED", 5000 + questN)
	M.advance(120)
	M.fire("QUEST_TURNED_IN", 5000 + questN, math.random(200, 3000), math.random(0, 25000))
end

local function levelUp()
	if S.level >= 60 then return end
	S.level = S.level + 1
	M.fire("PLAYER_LEVEL_UP", S.level)
end

local function goZone(z, sub)
	S.inInstance, S.instanceType = false, "none"
	S.zone, S.sub = z, sub or ""
	M.fire("ZONE_CHANGED_NEW_AREA")
end

local function die()
	deathsTruth = deathsTruth + 1
	S.ghost = true
	M.fire("PLAYER_DEAD")
end
local function revive() S.ghost = false end

local instanceSerial = 0
-- 던전 안의 잡몹 하나를 본다 (GUID에 인스턴스 사본 번호가 들어 있다)
local function seeTrash(instKey)
	mobGUID = mobGUID + 1
	local mob = { name = "던전 잡몹", ctype = "인간형", level = S.level, guid = string.format("Creature-0-1-%d-%d-%d-%08X", instKey, instKey + 7, 9999, mobGUID) }
	M.setUnit("mouseover", mob); M.fire("UPDATE_MOUSEOVER_UNIT")
	M.setUnit("mouseover", nil)
end

local dungeonStarts = {}
local function runDungeon(d, opts)
	opts = opts or {}
	instanceSerial = instanceSerial + 1
	local instKey = instanceSerial
	dungeonStarts[d.name] = (dungeonStarts[d.name] or 0) + 1
	S.group = 5
	S.inInstance, S.instanceType, S.instanceName, S.instanceMap = true, "party", d.name, d.map
	M.fire("PLAYER_ENTERING_WORLD", false, false)
	seeTrash(instKey)
	for i, boss in ipairs(d.bosses) do
		play(600)
		if opts.wipe and i == 2 then
			M.fire("ENCOUNTER_END", 900 + i, boss, 1, 5, 0)
			die()
			-- 영혼으로 입구까지 달려 나갔다가 돌아온다 (같은 인스턴스)
			S.inInstance, S.instanceType = false, "none"
			S.zone = d.zone
			M.fire("PLAYER_ENTERING_WORLD", false, false)
			play(240)
			S.inInstance, S.instanceType = true, "party"
			M.fire("PLAYER_ENTERING_WORLD", false, false)
			revive()
			seeTrash(instKey)
			play(300)
		end
		if opts.repairTrip and i == 1 then
			-- 살아서 잠깐 나갔다가 같은 인스턴스로 돌아온다 (수리)
			S.inInstance, S.instanceType = false, "none"
			S.zone = d.zone
			M.fire("PLAYER_ENTERING_WORLD", false, false)
			play(180)
			S.inInstance, S.instanceType = true, "party"
			M.fire("PLAYER_ENTERING_WORLD", false, false)
			seeTrash(instKey)
		end
		if opts.relogInside and i == 1 then relog(30) end
		M.fire("ENCOUNTER_END", 900 + i, boss, 1, 5, 1)
		M.fire("BOSS_KILL", 900 + i, boss)
	end
	play(300)
	S.inInstance, S.instanceType = false, "none"
	S.zone = d.zone
	M.fire("PLAYER_ENTERING_WORLD", false, false)
	S.group = 0
end

------------------------------------------------------------------------
-- 여정
------------------------------------------------------------------------
login()
local expectedStart = "1레벨, 엘윈 숲에서 첫 모험을 시작했다."
if not ns.StripCodes(ns.char.log[1].text):find(expectedStart, 1, true) then issue("첫 문장이 예상과 다름: " .. ns.char.log[1].text) end

local dungeonDone = {}
for zi, Z in ipairs(ZONES) do
	if S.level < Z.lvl[1] then
		while S.level < Z.lvl[1] do levelUp(); play(1800) end
	end
	goZone(Z.zone, Z.subs[1])
	for si = 2, #Z.subs do
		play(300)
		S.sub = Z.subs[si]
		M.fire("ZONE_CHANGED")
	end
	local target = Z.lvl[2]
	while S.level < target do
		for _ = 1, math.random(4, 9) do
			local spec = Z.mobs[math.random(1, #Z.mobs)]
			fight(spec, S.level)
		end
		quest(Z.zone)
		S.money = S.money + math.random(5000, 60000) * math.max(1, math.floor(S.level / 8))
		M.fire("PLAYER_MONEY")
		if math.random() < 0.12 then die(); play(120); revive() end
		for _, d in ipairs(DUNGEONS) do
			if not dungeonDone[d.name] and S.level >= d.lvl and d.zone == Z.zone then
				dungeonDone[d.name] = true
				runDungeon(d, { wipe = d.name == "마라우돈", relogInside = d.name == "검은바위 첨탑", repairTrip = d.name == "검은바위 첨탑" })
				-- 같은 던전을 곧바로 한 번 더 (초기화한 새 인스턴스)
				if d.name == "죽음의 폐광" then play(120); runDungeon(d) end
			end
		end
		levelUp()
		play(1500)
	end
	if zi == 3 then
		M.fire("HEARTHSTONE_BOUND")
		SlashCmdList["BIGCHRONICLEJOURNAL"]("그늘숲의 밤은 생각보다 무서웠다.")
	end
	if zi == 4 then
		-- 하루 쉬고 다시 접속
		relog(20 * 3600)
		S.inInstance, S.instanceType, S.instanceName, S.instanceMap = true, "pvp", "전쟁노래 협곡", 489
		M.fire("PLAYER_ENTERING_WORLD", false, false)
		play(900)
		S.inInstance, S.instanceType = false, "none"
		M.fire("PLAYER_ENTERING_WORLD", false, false)
	end
end
-- 60레벨이 된 뒤의 사냥 (경험치 메시지 없음)
for _ = 1, 30 do fight(ZONES[7].mobs[math.random(1, #ZONES[7].mobs)], 60) end
SlashCmdList["BIGCHRONICLE"]("기록 마침내 60레벨. 이제 진짜 모험이 시작된다.")
relog(60)

------------------------------------------------------------------------
-- 검사
------------------------------------------------------------------------
local db = ns.char
local B = ns.Bestiary

-- 1) 오류
for _, e in ipairs(ns.errors) do issue("런타임 오류: " .. e) end

-- 2) 문장
local seenZone = {}
local lastLevel = 0
local starts, ends = 0, 0
for i, e in ipairs(db.log) do
	local t = ns.StripCodes(e.text)
	if t:find("[{}]") then issue("템플릿 중괄호가 남음: " .. t) end
	if t:find("nil") then issue("nil 이 문장에 섞임: " .. t) end
	if t:find("%(를%)") or t:find("%(가%)") or t:find("%(으%)로") or t:find("%(와%)") or t:find("%(이%)") then
		issue("조사 판별 실패: " .. t)
	end
	if t:find("  %.") or t:find(" ,") then issue("어색한 공백: " .. t) end
	if t:find("0분%)") and t:find("시간 0분") then issue("'0분' 표기: " .. t) end
	if e.cat == "zone" then
		if seenZone[e.zone] then issue("같은 지역을 두 번 '처음' 방문: " .. e.zone) end
		seenZone[e.zone] = true
	end
	if e.cat == "level" then
		if e.lvl <= lastLevel then issue("레벨 기록 순서 이상: " .. e.lvl .. " after " .. lastLevel) end
		lastLevel = e.lvl
	end
	if e.cat == "dungeon" then
		if e.ended then ends = ends + 1 else starts = starts + 1 end
	end
	if e.lvl and (e.lvl < 1 or e.lvl > 60) then issue("레벨 값 이상: " .. tostring(e.lvl)) end
	if i > 1 and e.t < db.log[i - 1].t then issue("기록 시각이 거꾸로: " .. t) end
end
if starts ~= ends then issue(string.format("던전 원정 시작 %d회 / 종료 %d회 불일치", starts, ends)) end
if db.expedition then issue("끝나지 않은 원정이 남음: " .. tostring(db.expedition.name)) end

-- 2-1) 던전별 원정 횟수 / 한 원정의 보스 수
local bossCount = {}
for _, d in ipairs(DUNGEONS) do bossCount[d.name] = #d.bosses end
for name, n in pairs(dungeonStarts) do
	local d = db.dungeons[name]
	if not d or d.runs ~= n then issue(string.format("%s 원정 횟수: 기록 %s / 실제 %d", name, d and d.runs or "없음", n)) end
end
for _, e in ipairs(db.log) do
	if e.cat == "dungeon" and e.ended and e.bosses and bossCount[e.dungeon] and e.bosses > bossCount[e.dungeon] then
		issue("한 원정에 보스가 너무 많음: " .. ns.StripCodes(e.text))
	end
end

-- 3) 원정 시간: 오프라인 시간이 섞이면 안 된다
for _, e in ipairs(db.log) do
	if e.cat == "dungeon" and e.ended then
		local t = ns.StripCodes(e.text)
		if t:find("%d일") then issue("원정 소요 시간에 날짜 단위: " .. t) end
	end
end

-- 4) 처치 수
local recordedTotal = 0
for name, c in pairs(B.dex.creatures) do
	recordedTotal = recordedTotal + c.kills
	local real = truth[name] or 0
	if c.kills ~= real then issue(string.format("처치 수 불일치 %s: 기록 %d / 실제 %d", name, c.kills, real)) end
end
for name, n in pairs(B.dex.pending) do issue("발견되지 않은 처치가 남음: " .. name .. " " .. n) end
if recordedTotal ~= (B.dex.totalKills or 0) then issue(string.format("총 처치 %d ≠ 개체 합 %d", B.dex.totalKills or 0, recordedTotal)) end

-- 5) 죽음 수
if db.deaths ~= deathsTruth then issue(string.format("죽음 %d회 기록 / 실제 %d회", db.deaths, deathsTruth)) end

-- 6) 종족 분류 기대값
local expectTribe = {
	["강바닥발톱 잡종개"] = "gnoll", ["호거"] = "gnoll", ["데피아즈 노상강도"] = "defias", ["멀록 파도사냥꾼"] = "murloc",
	["수확 골렘"] = "mechanical", ["구울"] = "undead", ["검은 새끼용"] = "dragonkin", ["붉은해적단 해적"] = "pirate",
	["투자개발회사 벌목꾼"] = "venture", ["마그람 약탈자"] = "centaur", ["겔키스 궁수"] = "centaur", ["불타는 칼날 광신도"] = "orc",
	["사티로스 악마술사"] = "satyr", ["가시채찍 나가"] = "naga", ["남쪽바다 해적"] = "pirate", ["모래바람 트롤"] = "troll",
	["실리시드 일벌"] = "silithid", ["얼음발톱 예티"] = "yeti", ["겨울바람 펄볼그"] = "furbolg", ["서리불꽃 정령"] = "elemental",
	["토끼"] = "critter", ["어린 늑대"] = "beast:늑대", ["오우거 집행자"] = "ogre",
}
for name, want in pairs(expectTribe) do
	local c = B.dex.creatures[name]
	if not c then issue("도감에 없음: " .. name)
	elseif c.tribe ~= want then issue(string.format("분류 %s: %s (기대 %s)", name, c.tribe, want)) end
end

-- 7) 연구 등급 저장값과 계산값
local all = B:CollectAll()
for id, t in pairs(B.dex.tribes) do
	local s = all[id]
	if s and (t.rank or 2) < s.rank then issue("연구 등급 상승이 기록되지 않음: " .. id) end
end

-- 8) 기록 시간 = 접속해 있던 시간
local tracked = db.stats.tracked
if tracked <= 0 then issue("기록된 모험 시간이 0") end

-- 8-1) 업적
M.runTimers()
local expectAch = { "level10", "level20", "level30", "level40", "level50", "level60", "quest10", "quest50", "dg36", "dg349", "dg229",
	"death1", "note1", "tribes5", "tribes10", "tribes20", "species10", "rares1", "rarekills1", "kills100", "bg1", "bgm489",
	"comeback", "flawless", "zones5", "gold10", "gold100", "boss10" }
for _, id in ipairs(expectAch) do
	if not db.ach.done[id] then issue("업적 미달성: " .. id .. " (" .. (ns.ACH_BY_ID[id] and ns.ACH_BY_ID[id].name or "?") .. ")") end
end
for _, id in ipairs({ "dg389", "rd409", "tribes34", "quest1000" }) do
	if db.ach.done[id] then issue("달성하면 안 되는 업적이 달성됨: " .. id) end
end
-- 무사 업적은 첫 죽음의 레벨과 맞아야 한다
local firstDeath
for _, e in ipairs(db.log) do if e.cat == "death" then firstDeath = e.lvl break end end
for _, lv in ipairs({ 10, 20, 30, 40, 50, 60 }) do
	local should = (not firstDeath) or firstDeath >= lv
	if (db.ach.done["deathless" .. lv] ~= nil) ~= should then
		issue(string.format("무사 업적 %d 판정 이상 (첫 죽음 %s레벨)", lv, tostring(firstDeath)))
	end
end
local achEntries = 0
for _, e in ipairs(db.log) do if e.cat == "achievement" then achEntries = achEntries + (e.retro or e.many or 1) end end
local doneCount = 0
for _ in pairs(db.ach.done) do doneCount = doneCount + 1 end
if achEntries ~= doneCount then issue(string.format("업적 기록 %d줄 / 달성 %d개 불일치", achEntries, doneCount)) end

-- 9) UI를 모두 열어 본다 (큰 데이터에서 오류가 없는지)
local ok, err = pcall(function()
	ns.UI:Open("journal")
	for ch = 0, 7 do ns.JournalTab.chapter = ch; ns.JournalTab.page = nil; ns.JournalTab:Refresh() end
	ns.UI:SelectTab("bestiary")
	for _, t in ipairs(B:GetTribeList()) do ns.BestiaryTab:SelectTribe(t.id) end
	for name in pairs(B.dex.creatures) do ns.BestiaryTab.species = name; ns.BestiaryTab:RefreshCard() end
	ns.UI:SelectTab("achievements")
	for _, c in ipairs(ns.ACH_CATS) do ns.AchievementsTab.cat = c.id; ns.AchievementsTab:Refresh(true) end
	for _, f in ipairs({ "done", "todo", "all" }) do ns.AchievementsTab.filter = f; ns.AchievementsTab:Refresh(true) end
	ns.UI:SelectTab("stats")
	ns.UI:SelectTab("settings")
	ns.UI:ShowExport()
end)
if not ok then issue("UI 오류: " .. tostring(err)) end
for _, e in ipairs(ns.errors) do issue("런타임 오류(UI): " .. e) end

------------------------------------------------------------------------
-- 미리보기 장면 저장 (PREVIEW_DIR 가 있으면 화면마다 JSON을 남긴다 → tests/preview/render.py)
------------------------------------------------------------------------
local pdir = os.getenv("PREVIEW_DIR")
if pdir then
	local function step(n) for _ = 1, n do M.runOnUpdate(0.05) end end
	local function settle() step(80); M.runTimers(); ns.UI.FinishTyping(); ns.UI.FinishFades() end
	-- 앞선 재접속 시험에서 남은 프레임까지 모두 숨기고, 지금 창만 남긴다
	local function clean()
		if ns.Toast.frame then ns.Toast.queue = {} end
		for _, c in ipairs(UIParent.__children) do
			if c ~= ns.UI.frame then c:Hide() end
		end
	end
	local function dump(name) clean(); M.Dump(pdir .. "/" .. name .. ".json") end
	clean()
	ns.UI:Open("journal")
	local f = ns.UI.frame
	f:Hide(); ns.UI:Open("journal"); settle(); dump("journal")
	ns.JournalTab.chapterButtons[#ns.JournalTab.chapterButtons].onClick(); settle()
	ns.UI:SelectTab("bestiary")
	ns.BestiaryTab:SelectTribe("centaur")
	for name, c in pairs(ns.Bestiary.dex.creatures) do if c.tribe == "centaur" then ns.BestiaryTab.species = name end end
	ns.BestiaryTab:Refresh(); settle(); dump("bestiary")
	ns.UI:SelectTab("achievements"); ns.AchievementsTab.cat = nil; ns.AchievementsTab:Refresh(true); settle(); dump("achievements")
	ns.UI:SelectTab("stats"); settle(); dump("stats")
	ns.UI:SelectTab("settings"); settle(); dump("settings")
	f:Hide(); ns.UI:Open("journal"); step(5); dump("opening"); settle()
	f:Hide()
	ns.Toast:Show("업적 달성!", "「백 가지 이야기」   +10점", "Interface\\Icons\\INV_Misc_Note_01", "achievement", { ach = "quest100" })
	step(14); M.Dump(pdir .. "/toast.json"); settle()
	-- 도감 발견 알림 (용 문장 밀랍 인장)
	ns.Toast.queue = {}; ns.Toast.frame:Hide()
	ns.Toast:Show("새로운 종족 발견!", "No.008  켄타우로스  —  켈키스 궁수", "Interface\\Icons\\Ability_Mount_WhiteDireWolf", "tribe", { creature = "켈키스 궁수" })
	step(14); M.Dump(pdir .. "/toastdex.json"); settle()
	ns.Toast.queue = {}; ns.Toast.frame:Hide()
	ns:Fire("CHAPTER_STARTED", 4); step(40); M.Dump(pdir .. "/chapter.json"); settle()
	-- 작은 창들: 내보내기, 종족 다시 분류
	clean()
	ns.UI:ShowExport(); settle(); M.Dump(pdir .. "/export.json"); ns.UI.exportFrame:Hide()
	for name, c in pairs(ns.Bestiary.dex.creatures) do
		if c.tribe == "centaur" then ns.BestiaryTab:ShowReassign(name); break end
	end
	settle(); M.Dump(pdir .. "/reassign.json")
	print("== 미리보기 장면 저장: " .. pdir)
end

------------------------------------------------------------------------
-- 출력
------------------------------------------------------------------------
if not quiet then
	print(ns.UI.exportFrame.text)
	print("")
end
local found, total, species, rares, kills = B:Completion()
print(string.format("== 요약: 기록 %d개, 지역 %d곳, 퀘스트 %d, 죽음 %d, 도감 %d/%d 종족 %d종, 희귀 %d, 처치 %d, 추적 시간 %s",
	#db.log, (function() local n = 0 for _ in pairs(db.zones) do n = n + 1 end return n end)(), db.quests.count, db.deaths,
	found, total, species, rares, kills, ns.FormatDuration(tracked)))
if #issues == 0 then
	print("== 문제 없음")
	os.exit(0)
else
	print("== 발견한 문제 " .. #issues .. "건")
	for _, m in ipairs(issues) do print("  - " .. m) end
	os.exit(1)
end
