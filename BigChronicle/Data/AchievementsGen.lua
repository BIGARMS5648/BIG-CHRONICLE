-- BIG CHRONICLE :: 자동으로 펼쳐지는 업적 (약 1만 개)
--
-- 손으로 쓴 업적(Data/Achievements.lua) 위에, 이 애드온이 실제로 기록하는 값마다 단계별 목표를 만든다.
--   · 종족마다: 처치 수, 발견한 종, 연구 등급, 서식지별 발견·목격
--   · 지역마다: 방문, 머문 시간, 퀘스트, 세부 장소, 발견한 몬스터, 목격, 쓰러짐
--   · 던전·공격대마다: 입장, 원정 완료, 보스 처치, 빠른 원정
--   · 전장, 레벨, 직업·종족별 레벨, 각종 누적 기록, 일지의 시간대·요일·달
-- 같은 값을 쓰는 단계들은 한 '사다리(ladder)'로 묶여, 판정할 때 낮은 단계를 못 넘으면 높은 단계는 건너뛴다.
-- 업적 id는 값의 종류와 목표로 만들어지므로 버전이 바뀌어도 그대로 유지된다.

local ADDON, ns = ...
local I = "Interface\\Icons\\"
local list = ns.ACHIEVEMENTS
local Comma = ns.Comma

local generated = 0
local function add(def)
	def.points = def.points or 5
	def.minor = true
	list[#list + 1] = def
	generated = generated + 1
end

-- 손으로 쓴 업적과 겹치는 (값, 목표) 조합은 만들지 않는다
local taken = {}
for _, def in ipairs(list) do
	local key = ns.ACH_FIELD_OF[def.progress]
	if key then taken[key .. ":" .. def.goal] = true end
end

-- 1, 2.5, 5, 10, 25, 50, 100 ... 처럼 두세 배씩 벌어지는 목표 값 (너무 자주 뜨지 않도록)
local function Nice(lo, hi, steps)
	steps = steps or { 1, 2.5, 5 }
	local out = {}
	local base = 1
	while base <= hi do
		for _, m in ipairs(steps) do
			local v = math.floor(m * base + 0.5)
			if v >= lo and v <= hi and v ~= out[#out] then out[#out + 1] = v end
		end
		base = base * 10
	end
	return out
end

-- 업적 하나는 { id, goal, points, L } 네 칸만 가진다. 이름·설명·분류·아이콘·진행도는 사다리(L)에서 꺼낸다.
-- (1만 개를 가볍게 들고 있기 위해서: 이름과 설명은 화면에 보일 때만 만든다)
local DEF_MT = {
	__index = function(t, k)
		local L = rawget(t, "L")
		if k == "name" then return L.nameFn(rawget(t, "goal")) end
		if k == "desc" then return L.descFn(rawget(t, "goal")) end
		return L[k]
	end,
}

-- 사다리 하나 만들기
--   o.id: id 앞부분, o.cat, o.icon, o.goals, o.progress(ctx) → 현재 값
--   o.name(goal) / o.desc(goal) → 문자열, o.flavor, o.format
--   o.key: 손으로 쓴 업적과 겹치는지 값 이름으로 검사, o.skip: 손으로 쓴 업적이 이미 다루는 목표 { [goal] = true }
local function Ladder(o)
	local L = { ladder = o.id, cat = o.cat, icon = o.icon, progress = o.progress, flavor = o.flavor,
		format = o.format, minor = true, nameFn = o.name, descFn = o.desc }
	local n = #o.goals
	for i, goal in ipairs(o.goals) do
		if not (o.key and taken[o.key .. ":" .. goal]) and not (o.skip and o.skip[goal]) then
			-- 사다리 위쪽일수록 점수가 크다
			local r = i / n
			local pts = o.points or (r < 0.4 and 5 or r < 0.75 and 10 or r < 0.95 and 25 or 50)
			list[#list + 1] = setmetatable({ id = o.id .. "_" .. goal, goal = goal, points = pts, L = L }, DEF_MT)
			generated = generated + 1
		end
	end
end

-- 단계마다 붙는 칭호 (목표 값의 크기로 고른다)
local function Band(goal, bands)
	local title = bands[1][2]
	for _, b in ipairs(bands) do
		if goal >= b[1] then title = b[2] end
	end
	return title
end

local function hours(sec) return sec / 3600 end
local function HourText(h)
	if h < 1 then return math.floor(h * 60 + 0.5) .. "분" end
	return (h == math.floor(h) and tostring(h) or string.format("%.1f", h)) .. "시간"
end

------------------------------------------------------------------------
-- 종족 연구
------------------------------------------------------------------------
local KILL_BANDS = { { 1, "사냥" }, { 10, "사냥꾼" }, { 100, "토벌대장" }, { 1000, "학살자" }, { 10000, "멸족의 칼날" }, { 100000, "전설의 천적" } }
local SEEN_BANDS = { { 1, "목격자" }, { 25, "관찰자" }, { 250, "추적자" }, { 2500, "그림자" } }
local RANK_NAMES = { "조우", "관찰자", "연구자", "권위자", "전설의 사냥꾼" }
local function Stars(n) return string.rep("★", n) .. string.rep("☆", 5 - n) end

local Josa = ns.Josa
for _, t in ipairs(ns.TRIBES) do
	local id, tname = t.id, t.name
	local short = t.short or t.name
	local unit = t.unit or "마리"
	-- 첫 만남(조우), ★★★ 연구자, 100마리 처치는 손으로 쓴 종족 업적이 있다
	Ladder({ id = "tk_" .. id, cat = "tribe", icon = t.icon, goals = Nice(250, 50000),   -- 100마리는 손으로 쓴 업적
		name = function(g) return short .. " " .. Band(g, KILL_BANDS) .. " " .. Comma(g) end,
		desc = function(g) return Josa(tname, "을") .. " " .. Comma(g) .. unit .. " 처치하기" end,
		progress = function(ctx) return ctx.tribeKills[id] or 0 end,
		flavor = Josa(tname, "과") .. "의 싸움이 사냥 기록에 또 한 줄 늘었다." })
	Ladder({ id = "ts_" .. id, cat = "tribe", icon = t.icon, goals = { 3, 5, 8, 10 },
		name = function(g) return short .. " 표본 " .. g .. "종" end,
		desc = function(g) return "도감의 " .. tname .. " 항목에 서로 다른 몬스터 " .. g .. "종 올리기" end,
		progress = function(ctx) return ctx.tribeSpecies[id] or 0 end,
		flavor = "도감의 " .. tname .. " 항목에 새 그림이 붙었다." })
	Ladder({ id = "tr_" .. id, cat = "tribe", icon = t.icon, goals = { 3, 5, 6 }, points = 10,
		name = function(g) return short .. " " .. RANK_NAMES[g - 1] end,
		desc = function(g) return tname .. " 연구 등급 " .. Stars(g - 1) .. " " .. RANK_NAMES[g - 1] .. " 달성" end,
		progress = function(ctx) return ctx.tribeRank[id] or 0 end,
		flavor = tname .. "에 대해 아는 것이 한 겹 더 깊어졌다." })
	Ladder({ id = "tw_" .. id, cat = "tribe", icon = t.icon, goals = Nice(100, 10000),
		name = function(g) return short .. " " .. Band(g, SEEN_BANDS) .. " " .. Comma(g) end,
		desc = function(g) return Josa(tname, "을") .. " " .. Comma(g) .. "번 목격하기" end,
		progress = function(ctx) return ctx.tribeSeen[id] or 0 end,
		flavor = "멀리서도 " .. Josa(short, "의") .. " 기척을 알아차리게 되었다." })
	-- 알려진 서식지마다
	for _, zone in ipairs(t.habitats or {}) do
		local key = id .. "|" .. zone
		Ladder({ id = "hz_" .. id .. "_" .. zone, cat = "tribe", icon = t.icon, goals = { 3, 5 },
			name = function(g) return zone .. "의 " .. short .. " " .. g .. "종" end,
			desc = function(g) return zone .. "에서 " .. tname .. " " .. g .. "종 발견하기" end,
			progress = function(ctx) return ctx.habitatSpecies[key] or 0 end,
			flavor = zone .. "의 " .. short .. " 무리를 도감에 옮겨 적었다." })
		Ladder({ id = "hw_" .. id .. "_" .. zone, cat = "tribe", icon = t.icon, goals = { 50, 250, 500 },
			name = function(g) return zone .. "의 " .. short .. " 관찰 " .. Comma(g) end,
			desc = function(g) return zone .. "에서 " .. Josa(tname, "을") .. " " .. Comma(g) .. "번 목격하기" end,
			progress = function(ctx) return ctx.habitatSeen[key] or 0 end,
			flavor = zone .. "의 " .. short .. " 무리가 어디서 무엇을 하는지 이제 눈에 선하다." })
	end
end

------------------------------------------------------------------------
-- 지역 (클래식 지역 40곳)
------------------------------------------------------------------------
local ZONE_ICON = I .. "INV_Misc_Map_01"
for _, z in ipairs(ns.CLASSIC_ZONES) do
	local name = z.name
	Ladder({ id = "zv_" .. z.map, cat = "explore", icon = ZONE_ICON,
		goals = { 10, 25, 50, 100, 250, 500 },
		name = function(g) return g == 1 and (name .. " 첫 발걸음") or (name .. " 단골 " .. g .. "회") end,
		desc = function(g) return g == 1 and (name .. "에 발을 들이기") or (name .. "에 " .. g .. "번 들어서기") end,
		progress = function(ctx) return ctx.zoneVisits[name] or 0 end,
		flavor = name .. "의 바람이 어느새 낯익다." })
	local hs = { 1, 2, 4, 8, 12, 24, 48, 100 }
	local goals = {}
	for i, h in ipairs(hs) do goals[i] = math.floor(h * 3600) end
	Ladder({ id = "zt_" .. z.map, cat = "explore", icon = I .. "INV_Misc_PocketWatch_01", goals = goals, format = "hours",
		name = function(g) return name .. "에서 보낸 " .. HourText(hours(g)) end,
		desc = function(g) return name .. "에서 " .. HourText(hours(g)) .. " 머물기" end,
		progress = function(ctx) return ctx.zoneTime[name] or 0 end,
		flavor = name .. "에서 흘려보낸 시간도 이야기가 되었다." })
	Ladder({ id = "zq_" .. z.map, cat = "quest", icon = I .. "INV_Misc_Note_01",
		goals = z.fewQuests and {} or { 20, 30, 40, 50 },   -- 3·10개는 '이야기꾼' 업적
		name = function(g) return name .. "의 해결사 " .. g end,
		desc = function(g) return name .. "에서 퀘스트 " .. g .. "개 완료하기" end,
		progress = function(ctx) return math.max(ctx.questZone[name] or 0, ctx.questMap[z.map] or 0) end,
		flavor = name .. "의 주민들이 내 이름을 기억한다." })
	Ladder({ id = "zs_" .. z.map, cat = "explore", icon = I .. "Ability_Hunter_Pathfinding",
		goals = { 5, 10, 15, 20 },
		name = function(g) return name .. " 구석구석 " .. g end,
		desc = function(g) return name .. "의 세부 장소 " .. g .. "곳 발견하기" end,
		progress = function(ctx) return ctx.zoneSub[name] or 0 end,
		flavor = name .. "의 이름 없는 길모퉁이까지 기억 속에 있다." })
	Ladder({ id = "zm_" .. z.map, cat = "dex", icon = I .. "Ability_EyeOfTheOwl",
		goals = { 10, 20, 30, 40 },
		name = function(g) return name .. " 생태 조사 " .. g .. "종" end,
		desc = function(g) return name .. "에서 서로 다른 몬스터 " .. g .. "종 발견하기" end,
		progress = function(ctx) return ctx.zoneSpecies[name] or 0 end,
		flavor = name .. "의 생태가 도감 한 장에 빼곡하다." })
	Ladder({ id = "zw_" .. z.map, cat = "dex", icon = I .. "Ability_EyeOfTheOwl", goals = Nice(100, 10000),
		name = function(g) return name .. " 관찰 일지 " .. Comma(g) end,
		desc = function(g) return name .. "에서 몬스터를 " .. Comma(g) .. "번 목격하기" end,
		progress = function(ctx) return ctx.zoneSeen[name] or 0 end,
		flavor = name .. "의 짐승과 괴물들이 이제 낯설지 않다." })
	Ladder({ id = "zd_" .. z.map, cat = "trial", icon = I .. "Spell_Shadow_DeathScream", goals = { 5, 10, 25, 50 },
		name = function(g) return name .. "의 쓰라린 기억 " .. g end,
		desc = function(g) return name .. "에서 " .. g .. "번 쓰러지기" end,
		progress = function(ctx) return ctx.zoneDeaths[name] or 0 end,
		flavor = name .. "의 흙맛을 또 보았다. 그래도 다시 일어섰다." })
end

------------------------------------------------------------------------
-- 던전 · 공격대 · 전장
------------------------------------------------------------------------
local RUN_GOALS = { 3, 10, 25, 50, 100, 250, 500 }
local function Instance(d, cat, icon)
	local name, map = d.name, d.map
	Ladder({ id = "ir_" .. map, cat = cat, icon = icon, goals = RUN_GOALS,
		name = function(g) return name .. " 원정 " .. g .. "회" end,
		desc = function(g) return name .. "에 " .. g .. "번 들어가기" end,
		progress = function(ctx) return math.max(ctx.runCount[map] or 0, ctx.runCountName[name] or 0) end,
		flavor = name .. "의 입구가 이제 집 앞 골목처럼 익숙하다." })
	Ladder({ id = "ic_" .. map, cat = cat, icon = icon, goals = RUN_GOALS,
		name = function(g) return name .. " 정복 " .. g .. "회" end,
		desc = function(g) return name .. "에서 보스를 쓰러뜨리고 원정을 " .. g .. "번 마치기" end,
		progress = function(ctx) return math.max(ctx.clearCount[map] or 0, ctx.clearCountName[name] or 0) end,
		flavor = name .. "의 어둠이 또 한 번 걷혔다." })
	Ladder({ id = "ib_" .. map, cat = cat, icon = I .. "INV_Misc_Bone_HumanSkull_01", goals = { 10, 50, 100, 250, 500, 1000 },
		name = function(g) return name .. " 보스 사냥 " .. Comma(g) end,
		desc = function(g) return name .. "의 보스를 " .. Comma(g) .. "번 쓰러뜨리기" end,
		progress = function(ctx) return ctx.instBossKills[name] or 0 end,
		flavor = name .. "의 주인들이 내 이름을 두려워한다." })
	if cat == "dungeon" then
		for _, m in ipairs({ 60, 45 }) do   -- 30·20분은 너무 하드코어해서 뺐다
			add({ id = "if_" .. map .. "_" .. m, cat = cat, icon = I .. "Spell_Nature_Lightning", goal = 1, points = m <= 45 and 10 or 5,
				name = name .. " 질주 " .. m .. "분", desc = name .. " 원정을 " .. m .. "분 안에 마치기 (보스 1명 이상)",
				progress = function(ctx)
					local best = ctx.bestClear[name]
					return (best and best <= m * 60) and 1 or 0
				end,
				flavor = "숨 돌릴 틈도 없이 " .. Josa(name, "을") .. " 휩쓸고 나왔다." })
		end
	end
end
for _, d in ipairs(ns.CLASSIC_DUNGEONS) do Instance(d, "dungeon", I .. "INV_Misc_Key_03") end
for _, d in ipairs(ns.CLASSIC_RAIDS) do Instance(d, "raid", I .. "INV_Misc_Head_Dragon_01") end
for _, b in ipairs(ns.CLASSIC_BATTLEGROUNDS) do
	local name, map = b.name, b.map
	Ladder({ id = "bg_" .. map, cat = "pvp", icon = I .. "Ability_DualWield", goals = Nice(25, 5000),
		name = function(g) return name .. " 참전 " .. Comma(g) .. "회" end,
		desc = function(g) return name .. "에 " .. Comma(g) .. "번 참전하기" end,
		progress = function(ctx) return math.max(ctx.bgMaps[map] or 0, ctx.bgNames[name] or 0) end,
		flavor = name .. "의 함성이 귓가에 맴돈다." })
end

------------------------------------------------------------------------
-- 성장: 직업·종족별 레벨 (계정 공용이라 부캐릭터를 키울수록 채워진다)
------------------------------------------------------------------------
local CLASSES = {
	{ "WARRIOR", "전사", "INV_Sword_27" }, { "PALADIN", "성기사", "Spell_Holy_HolyBolt" },
	{ "HUNTER", "사냥꾼", "INV_Weapon_Bow_07" }, { "ROGUE", "도적", "Ability_Stealth" },
	{ "PRIEST", "사제", "Spell_Holy_PowerWordShield" }, { "SHAMAN", "주술사", "Spell_Nature_BloodLust" },
	{ "MAGE", "마법사", "Spell_Frost_FrostBolt02" }, { "WARLOCK", "흑마법사", "Spell_Shadow_DeathCoil" },
	{ "DRUID", "드루이드", "Spell_Nature_HealingTouch" },
}
local RACES = {
	{ "Human", "인간", { "WARRIOR", "PALADIN", "ROGUE", "PRIEST", "MAGE", "WARLOCK" } },
	{ "Dwarf", "드워프", { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST" } },
	{ "NightElf", "나이트 엘프", { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "DRUID" } },
	{ "Gnome", "노움", { "WARRIOR", "ROGUE", "MAGE", "WARLOCK" } },
	{ "Orc", "오크", { "WARRIOR", "HUNTER", "ROGUE", "SHAMAN", "WARLOCK" } },
	{ "Scourge", "언데드", { "WARRIOR", "ROGUE", "PRIEST", "MAGE", "WARLOCK" } },
	{ "Tauren", "타우렌", { "WARRIOR", "HUNTER", "SHAMAN", "DRUID" } },
	{ "Troll", "트롤", { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE" } },
}
local CLASS_NAME = {}
for _, c in ipairs(CLASSES) do
	local token, cname = c[1], c[2]
	CLASS_NAME[token] = cname
	Ladder({ id = "cl_" .. token, cat = "growth", icon = I .. c[3], goals = { 20, 40, 60 },
		name = function(g) return cname .. " " .. g .. "레벨" end,
		desc = function(g) return cname .. " 캐릭터로 " .. g .. "레벨에 도달하기" end,
		progress = function(ctx) return ctx.classToken == token and ctx.level or 0 end,
		flavor = cname .. "의 길도 이제 손에 익었다." })
	-- 직업마다 한 캐릭터로 쌓은 처치·퀘스트·도감 (계정 공용이라 여러 직업을 키울수록 채워진다)
	Ladder({ id = "ck_" .. token, cat = "growth", icon = I .. c[3], goals = { 1000, 2500, 5000, 10000, 25000, 50000 },
		name = function(g) return cname .. "의 칼끝 " .. Comma(g) end,
		desc = function(g) return cname .. " 캐릭터로 몬스터 " .. Comma(g) .. "마리 처치하기" end,
		progress = function(ctx) return ctx.classToken == token and ctx.kills or 0 end,
		flavor = cname .. "의 손에 쓰러진 적이 산을 이룬다." })
	Ladder({ id = "cq_" .. token, cat = "growth", icon = I .. c[3], goals = { 100, 250, 500, 1000, 2000 },
		name = function(g) return cname .. "의 해결사 " .. Comma(g) end,
		desc = function(g) return cname .. " 캐릭터로 퀘스트 " .. Comma(g) .. "개 완료하기" end,
		progress = function(ctx) return ctx.classToken == token and ctx.quests or 0 end,
		flavor = cname .. "의 이름으로 맺은 약속을 하나 더 지켰다." })
	Ladder({ id = "cd_" .. token, cat = "growth", icon = I .. c[3], goals = { 50, 100, 200, 300, 500 },
		name = function(g) return cname .. "의 도감 " .. Comma(g) .. "종" end,
		desc = function(g) return cname .. " 캐릭터로 서로 다른 몬스터 " .. Comma(g) .. "종 발견하기" end,
		progress = function(ctx) return ctx.classToken == token and ctx.species or 0 end,
		flavor = cname .. "의 눈으로 본 세상이 도감에 쌓였다." })
end
for _, r in ipairs(RACES) do
	local rtoken, rname = r[1], r[2]
	Ladder({ id = "rc_" .. rtoken, cat = "growth", icon = I .. "Spell_Holy_InnerFire", goals = { 30, 60 },
		name = function(g) return rname .. " " .. g .. "레벨" end,
		desc = function(g) return rname .. " 캐릭터로 " .. g .. "레벨에 도달하기" end,
		progress = function(ctx) return ctx.raceToken == rtoken and ctx.level or 0 end,
		flavor = rname .. "의 피가 흐르는 영웅이 또 하나 자랐다." })
	Ladder({ id = "rk_" .. rtoken, cat = "growth", icon = I .. "Spell_Holy_InnerFire", goals = { 1000, 2500, 5000, 10000, 25000, 50000 },
		name = function(g) return rname .. "의 칼끝 " .. Comma(g) end,
		desc = function(g) return rname .. " 캐릭터로 몬스터 " .. Comma(g) .. "마리 처치하기" end,
		progress = function(ctx) return ctx.raceToken == rtoken and ctx.kills or 0 end,
		flavor = rname .. "의 이름이 전장에 울려 퍼진다." })
	for _, token in ipairs(r[3]) do
		local cname = CLASS_NAME[token]
		Ladder({ id = "rcc_" .. rtoken .. "_" .. token, cat = "growth", icon = I .. "Spell_Holy_InnerFire", goals = { 60 },
			name = function(g) return rname .. " " .. cname .. " " .. g .. "레벨" end,
			desc = function(g) return rname .. " " .. cname .. " 캐릭터로 " .. g .. "레벨에 도달하기" end,
			progress = function(ctx) return (ctx.raceToken == rtoken and ctx.classToken == token) and ctx.level or 0 end,
			flavor = rname .. " " .. cname .. "의 이야기도 전기에 남았다." })
	end
end

------------------------------------------------------------------------
-- 누적 기록
------------------------------------------------------------------------
local TOTALS = {
	-- 값 이름, 분류, 아이콘, 범위, 이름, 설명(목표), 단위
	{ "kills", "dex", "Ability_Warrior_BattleShout", 1000, 500000, "처치", "몬스터 %s마리 처치하기" },
	{ "species", "dex", "Ability_EyeOfTheOwl", 50, 2000, "도감", "서로 다른 몬스터 %s종 발견하기" },
	{ "rares", "dex", "INV_Misc_Gem_Ruby_01", 10, 300, "희귀 개체", "희귀 개체 %s종 발견하기" },
	{ "rareKills", "dex", "INV_Misc_Gem_Ruby_01", 10, 300, "희귀 사냥", "희귀 개체 %s종 쓰러뜨리기" },
	{ "elites", "dex", "Ability_Warrior_Challange", 25, 1000, "정예 도감", "정예 몬스터 %s종 발견하기" },
	{ "critters", "dex", "Ability_Hunter_Pet_Bear", 25, 150, "작은 동물 도감", "작은 동물 %s종 발견하기" },
	{ "families", "dex", "Ability_Hunter_BeastTaming", 10, 30, "야수 계통", "야수 계통 %s가지 발견하기" },
	{ "quests", "quest", "INV_Misc_Note_01", 250, 5000, "퀘스트", "퀘스트 %s개 완료하기" },
	{ "questZones", "quest", "INV_Misc_Map_01", 10, 45, "여러 땅의 해결사", "서로 다른 지역 %s곳에서 퀘스트 완료하기" },
	{ "subzones", "explore", "Ability_Hunter_Pathfinding", 100, 1000, "장소 발견", "세부 장소 %s곳 발견하기" },
	{ "zones", "explore", "INV_Misc_Map_01", 10, 50, "지역 방문", "서로 다른 지역 %s곳 방문하기" },
	{ "deaths", "trial", "Spell_Shadow_DeathScream", 250, 2000, "쓰러짐", "%s번 쓰러지기" },
	{ "deathZones", "trial", "Spell_Shadow_DeathScream", 25, 45, "곳곳의 무덤", "서로 다른 지역 %s곳에서 쓰러지기" },
	{ "goldBest", "growth", "INV_Misc_Coin_01", 10000, 50000, "재산", "%s골드 모으기" },
	{ "days", "fun", "INV_Misc_PocketWatch_02", 250, 1000, "기록한 날", "기록이 남은 날 %s일" },
	{ "logCount", "chronicle", "INV_Misc_Book_09", 1000, 50000, "전기의 두께", "전기에 기록 %s개 남기기 (업적 기록 제외)" },
	{ "notes", "chronicle", "INV_Scroll_03", 25, 5000, "나의 기록", "나만의 기록 %s개 남기기" },
	{ "bossKills", "dungeon", "INV_Misc_Bone_HumanSkull_01", 250, 5000, "보스 처치", "던전·공격대 보스 %s번 쓰러뜨리기" },
	{ "runs", "dungeon", "INV_Misc_Key_03", 250, 2000, "원정", "던전·공격대 원정 %s번 떠나기" },
	{ "raidClears", "raid", "INV_Misc_Head_Dragon_01", 25, 500, "공격대 정복", "공격대 원정 %s번 마치기" },
	{ "bgTotal", "pvp", "Ability_DualWield", 250, 5000, "전장", "전장에 %s번 참전하기" },
	{ "binds", "explore", "INV_Misc_Rune_01", 10, 300, "귀환석", "귀환 장소를 %s번 바꾸기" },
	{ "questMaxDay", "fun", "INV_Misc_Note_01", 30, 40, "바쁜 하루", "하루에 퀘스트 %s개 완료하기" },
	{ "exalted", "rep", "Spell_Holy_HolyBolt", 2, 15, "확고한 동맹", "평판 '확고한 동맹' 세력 %s곳" },
}
for _, tdef in ipairs(TOTALS) do
	local key, cat, icon, lo, hi, title, descFmt = tdef[1], tdef[2], I .. tdef[3], tdef[4], tdef[5], tdef[6], tdef[7]
	Ladder({ id = "t_" .. key, cat = cat, icon = icon, goals = Nice(lo, hi, { 1, 2, 5 }), key = key,
		name = function(g) return title .. " " .. Comma(g) end,
		desc = function(g) return string.format(descFmt, Comma(g)) end,
		progress = function(ctx) return ctx[key] or 0 end,
		flavor = "또 하나의 이정표를 지났다." })
end
do
	local goals = {}
	for _, h in ipairs(Nice(250, 5000, { 1, 2.5, 5 })) do goals[#goals + 1] = h * 3600 end
	Ladder({ id = "t_tracked", cat = "growth", icon = I .. "INV_Misc_PocketWatch_01", goals = goals, key = "tracked", format = "hours",
		name = function(g) return "모험의 시간 " .. Comma(g / 3600) .. "시간" end,
		desc = function(g) return "전기가 기록된 모험 시간 " .. Comma(g / 3600) .. "시간" end,
		progress = function(ctx) return ctx.tracked or 0 end,
		flavor = "시간은 흘러도 이야기는 남는다." })
	Ladder({ id = "t_streak", cat = "fun", icon = I .. "INV_Misc_PocketWatch_01", key = "streak",
		goals = { 14, 21, 60, 100 },   -- 7·30일은 손으로 쓴 업적, 몇 년씩 이어지는 연속 기록은 뺐다
		name = function(g) return "연속 기록 " .. g .. "일" end,
		desc = function(g) return g .. "일 연속으로 전기에 기록 남기기" end,
		progress = function(ctx) return ctx.streak or 0 end,
		flavor = "오늘도 펜을 들었다." })
	Ladder({ id = "t_lvday", cat = "fun", icon = I .. "Spell_Nature_Lightning", key = "levelsMaxDay",
		goals = { 7, 10 },   -- 5번은 손으로 쓴 업적, 그 이상은 너무 하드코어해서 뺐다
		name = function(g) return "하루에 " .. g .. "레벨" end,
		desc = function(g) return "하루에 레벨 " .. g .. "번 올리기" end,
		progress = function(ctx) return ctx.levelsMaxDay or 0 end,
		flavor = "해가 지기 전에 몰라보게 자랐다." })
end

------------------------------------------------------------------------
-- 일지: 기록 종류별, 시간대별, 요일별, 달별
------------------------------------------------------------------------
-- (지역·퀘스트·죽음 등 다른 누적 업적과 같은 것을 세는 종류는 빼고, 겹치지 않는 것만)
local LOG_CATS = {
	{ "milestone", "사냥 이정표", 5000 },
}
for _, c in ipairs(LOG_CATS) do
	local cat, cname, hi = c[1], c[2], c[3]
	Ladder({ id = "lc_" .. cat, cat = "chronicle", icon = I .. "INV_Misc_Book_09", goals = Nice(10, hi),
		name = function(g) return cname .. " 기록 " .. Comma(g) end,
		desc = function(g) return "일지에 '" .. cname .. "' 기록 " .. Comma(g) .. "개 남기기" end,
		progress = function(ctx) return ctx.logCat[cat] or 0 end,
		flavor = "전기의 '" .. cname .. "' 장이 또 두꺼워졌다." })
end
local function HourName(h)
	if h == 0 then return "자정" end
	if h == 12 then return "정오" end
	return (h < 12 and "오전 " .. h or "오후 " .. (h - 12)) .. "시"
end
for h = 0, 23 do
	local hname = HourName(h)
	Ladder({ id = "lh_" .. h, cat = "fun", icon = I .. "INV_Misc_PocketWatch_02", goals = { 50, 250, 1000, 2500 },
		name = function(g) return hname .. "의 모험가 " .. Comma(g) end,
		desc = function(g) return hname .. "부터 한 시간 사이에 기록 " .. Comma(g) .. "개 남기기" end,
		progress = function(ctx) return ctx.logHour[h] or 0 end,
		flavor = hname .. "의 아제로스도 제법 아름답다." })
end
local WDAYS = { "일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일" }
for w = 1, 7 do
	local wname = WDAYS[w]
	Ladder({ id = "lw_" .. w, cat = "fun", icon = I .. "INV_Misc_PocketWatch_02", goals = { 100, 500, 1000, 2500, 5000 },
		name = function(g) return wname .. "의 모험 " .. Comma(g) end,
		desc = function(g) return wname .. "에 기록 " .. Comma(g) .. "개 남기기" end,
		progress = function(ctx) return ctx.logWday[w] or 0 end,
		flavor = wname .. "이 오면 검을 든다." })
end
for m = 1, 12 do
	Ladder({ id = "lm_" .. m, cat = "fun", icon = I .. "INV_Misc_Book_09", goals = { 100, 500, 1000, 2500 },
		name = function(g) return m .. "월의 모험 " .. Comma(g) end,
		desc = function(g) return m .. "월에 기록 " .. Comma(g) .. "개 남기기" end,
		progress = function(ctx) return ctx.logMonth[m] or 0 end,
		flavor = m .. "월의 바람 속에서 또 한 줄을 적었다." })
end

------------------------------------------------------------------------
ns.ACH_GENERATED = generated
ns.ACH_BY_ID = {}
for _, a in ipairs(list) do
	if ns.ACH_BY_ID[a.id] then error("BIG CHRONICLE: duplicate achievement id " .. a.id) end
	ns.ACH_BY_ID[a.id] = a
end
-- 업적 목록이 바뀌면 값이 달라지는 서명 (새로 생긴 업적 가운데 이미 이룬 것을 조용히 처리할 때 쓴다)
ns.ACH_SIGNATURE = #list .. ":" .. list[#list].id
