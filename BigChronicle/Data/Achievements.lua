-- BIG CHRONICLE :: 업적 정의
--
-- 리치 왕의 분노 시절 클래식(1~60) 콘텐츠 업적을 참고해, Forever 공식 업적(레거시 도전 과제·지역 탐험)과
-- 겹치지 않는 부분을 중심으로 이 애드온의 기록(일지·도감)으로 판정할 수 있는 업적을 모았다.
-- 비교 내용은 docs/achievements.md 참고.
--
-- 항목: id, cat(분류), name, desc, points, icon, goal, progress(ctx) → 현재 값, flavor(달성 문장, 선택)

local ADDON, ns = ...
local I = "Interface\\Icons\\"

ns.ACH_CATS = {
	{ id = "growth",    name = "성장",        icon = I .. "Spell_Holy_InnerFire" },
	{ id = "explore",   name = "탐험",        icon = I .. "INV_Misc_Map_01" },
	{ id = "quest",     name = "퀘스트",      icon = I .. "INV_Misc_Note_01" },
	{ id = "dungeon",   name = "던전",        icon = I .. "INV_Misc_Key_03" },
	{ id = "raid",      name = "공격대",      icon = I .. "INV_Misc_Head_Dragon_01" },
	{ id = "dex",       name = "몬스터 도감", icon = I .. "Ability_EyeOfTheOwl" },
	{ id = "tribe",     name = "종족 연구",   icon = I .. "INV_Misc_Book_11" },
	{ id = "pvp",       name = "전장",        icon = I .. "Ability_DualWield" },
	{ id = "rep",       name = "평판",        icon = I .. "Spell_Holy_HolyBolt" },
	{ id = "trial",     name = "시련",        icon = I .. "Spell_Shadow_DeathScream" },
	{ id = "chronicle", name = "연대기",      icon = I .. "INV_Misc_Book_09" },
	{ id = "fun",       name = "소소한 재미", icon = I .. "INV_Misc_PocketWatch_01" },
}

-- 클래식 지역 (uiMapID, 이름). 지역 이름이나 지도 ID 가운데 하나만 맞아도 인정한다.
ns.CLASSIC_ZONES = {
	-- 동부 왕국
	{ map = 1429, name = "엘윈 숲",            ek = true },
	{ map = 1426, name = "던 모로",            ek = true },
	{ map = 1420, name = "티리스팔 숲",        ek = true },
	{ map = 1436, name = "서부 몰락지대",      ek = true },
	{ map = 1432, name = "모단 호수",          ek = true },
	{ map = 1421, name = "은빛소나무 숲",      ek = true },
	{ map = 1433, name = "붉은마루 산맥",      ek = true },
	{ map = 1431, name = "그늘숲",             ek = true },
	{ map = 1437, name = "저습지",             ek = true },
	{ map = 1424, name = "힐스브래드 구릉지",  ek = true },
	{ map = 1416, name = "알터랙 산맥",        ek = true },
	{ map = 1417, name = "아라시 고원",        ek = true },
	{ map = 1434, name = "가시덤불 골짜기",    ek = true },
	{ map = 1418, name = "황야의 땅",          ek = true },
	{ map = 1435, name = "슬픔의 늪",          ek = true },
	{ map = 1425, name = "동부 내륙지",        ek = true },
	{ map = 1427, name = "이글거리는 협곡",    ek = true },
	{ map = 1419, name = "저주받은 땅",        ek = true },
	{ map = 1428, name = "불타는 평원",        ek = true },
	{ map = 1422, name = "서부 역병지대",      ek = true },
	{ map = 1423, name = "동부 역병지대",      ek = true },
	{ map = 1430, name = "죽음의 고개",        ek = true, fewQuests = true },
	-- 칼림도어
	{ map = 1411, name = "듀로타" },
	{ map = 1412, name = "멀고어" },
	{ map = 1438, name = "텔드랏실" },
	{ map = 1439, name = "어둠해안" },
	{ map = 1413, name = "불모의 땅" },
	{ map = 1442, name = "돌발톱 산맥" },
	{ map = 1440, name = "잿빛 골짜기" },
	{ map = 1441, name = "버섯구름 봉우리" },
	{ map = 1443, name = "잊혀진 땅" },
	{ map = 1445, name = "먼지진흙 습지대" },
	{ map = 1444, name = "페랄라스" },
	{ map = 1446, name = "타나리스" },
	{ map = 1447, name = "아즈샤라" },
	{ map = 1448, name = "악령의 숲" },
	{ map = 1449, name = "운고로 분화구" },
	{ map = 1450, name = "달의 숲", fewQuests = true },
	{ map = 1451, name = "실리더스" },
	{ map = 1452, name = "여명의 설원" },
}

-- 클래식 던전 / 공격대 (지도 ID는 GetInstanceInfo의 여덟 번째 값)
ns.CLASSIC_DUNGEONS = {
	{ map = 389, name = "성난불길 협곡",       lv = "13~18" },
	{ map = 43,  name = "통곡의 동굴",         lv = "17~24" },
	{ map = 36,  name = "죽음의 폐광",         lv = "17~26" },
	{ map = 33,  name = "그림자송곳니 성채",   lv = "22~30" },
	{ map = 48,  name = "검은심연의 나락",     lv = "24~32" },
	{ map = 34,  name = "스톰윈드 지하감옥",   lv = "24~32" },
	{ map = 90,  name = "놈리건",              lv = "29~38" },
	{ map = 47,  name = "가시덩굴 우리",       lv = "29~38" },
	{ map = 189, name = "붉은십자군 수도원",   lv = "34~45" },
	{ map = 129, name = "가시덩굴 구릉",       lv = "37~46" },
	{ map = 70,  name = "울다만",              lv = "41~51" },
	{ map = 209, name = "줄파락",              lv = "42~52" },
	{ map = 349, name = "마라우돈",            lv = "46~55" },
	{ map = 109, name = "아탈학카르 신전",     lv = "50~60" },
	{ map = 230, name = "검은바위 나락",       lv = "52~60" },
	{ map = 229, name = "검은바위 첨탑",       lv = "55~60" },
	{ map = 429, name = "혈투의 전장",         lv = "55~60" },
	{ map = 289, name = "스칼로맨스",          lv = "58~60" },
	{ map = 329, name = "스트라솔름",          lv = "58~60" },
}
ns.CLASSIC_RAIDS = {
	{ map = 309, name = "줄구룹",          size = 20 },
	{ map = 409, name = "화산 심장부",     size = 40 },
	{ map = 249, name = "오닉시아의 둥지", size = 40 },
	{ map = 469, name = "검은날개 둥지",   size = 40 },
	{ map = 509, name = "안퀴라즈 폐허",   size = 20 },
	{ map = 531, name = "안퀴라즈 사원",   size = 40 },
	{ map = 533, name = "낙스라마스",      size = 40 },
}
ns.CLASSIC_BATTLEGROUNDS = {
	{ map = 489, name = "전쟁노래 협곡" },
	{ map = 529, name = "아라시 분지" },
	{ map = 30,  name = "알터랙 계곡" },
}

local list = {}
ns.ACHIEVEMENTS = list

local function add(def)
	def.points = def.points or 10
	list[#list + 1] = def
end

-- 값 이름으로 진행도를 읽는 함수. 자동 생성 업적이 같은 값·같은 목표를 겹쳐 만들지 않도록 이름을 기억해 둔다.
ns.ACH_FIELD_OF = setmetatable({}, { __mode = "k" })
local function field(name)
	local f = function(ctx) return ctx[name] or 0 end
	ns.ACH_FIELD_OF[f] = name
	return f
end

-- 숫자 단계형 업적을 한꺼번에 만든다: steps = { { 값, 이름, 문장, 점수(선택) }, ... }
local function tiers(prefix, cat, icon, key, descFn, steps, defaultPts)
	for _, s in ipairs(steps) do
		add({ id = prefix .. s[1], cat = cat, name = s[2], desc = descFn(s[1]), goal = s[1], icon = icon,
			points = s[4] or defaultPts or 10, progress = field(key), flavor = s[3] })
	end
end

------------------------------------------------------------------------
-- 성장
------------------------------------------------------------------------
local LEVELS = {
	{ 5,  "첫 번째 고비",       "갓 쥔 무기가 조금은 손에 익었다.", 5 },
	{ 10, "모험의 첫 장",       "고향을 떠날 채비가 끝났다. 낯선 길이 나를 부른다." },
	{ 15, "길 위의 신참",       "여관 주인이 내 얼굴을 기억하기 시작했다.", 5 },
	{ 20, "이름을 알리다",     "어느 여관에서 누군가 내 이름을 입에 올렸다. 작은 소문이 시작되었다." },
	{ 25, "단단해진 발걸음",   "어지간한 길은 이제 혼자서도 걷는다.", 5 },
	{ 30, "검증된 모험가",     "이제 나를 신참이라 부르는 이는 없다." },
	{ 35, "중견 모험가",       "젊은 모험가들이 길을 묻는다.", 5 },
	{ 40, "대륙을 달리는 자",  "말발굽 소리와 함께 세상이 한결 가까워졌다." },
	{ 45, "노련한 칼끝",       "싸움의 흐름이 눈에 보이기 시작했다.", 5 },
	{ 50, "전설의 문턱",       "마지막 관문이 손에 잡힐 듯 가까이 있다." },
	{ 55, "정점을 향해",       "정상까지 몇 걸음 남지 않았다.", 5 },
	{ 60, "아제로스의 영웅",   "긴 여정의 정점. 하지만 진짜 이야기는 이제부터다.", 25 },
}
for _, l in ipairs(LEVELS) do
	add({ id = "level" .. l[1], cat = "growth", name = l[2], desc = l[1] .. "레벨에 도달하기", goal = l[1],
		points = l[4] or 10, icon = I .. "Spell_Holy_InnerFire", progress = field("level"), flavor = l[3] })
end

tiers("gold", "growth", I .. "INV_Misc_Coin_01", "goldBest", function(v) return ns.Comma(v) .. "골드를 모으기" end, {
	{ 10,   "두둑한 주머니",          "짤랑거리는 소리가 제법 묵직해졌다." },
	{ 50,   "든든한 비상금",          "이제 수리비 걱정은 하지 않아도 된다." },
	{ 100,  "탈것 자금",              "마구간 주인의 눈빛이 달라졌다." },
	{ 250,  "상인의 친구",            "경매장 상인들이 나에게 먼저 인사를 건넨다." },
	{ 500,  "작은 재산가",            "은행 금고 앞에 서면 괜히 어깨가 펴진다." },
	{ 1000, "부호",                   "경매장 상인들이 먼저 고개를 숙인다.", 25 },
	{ 2500, "황금의 손",              "손대는 일마다 금화가 따라온다.", 25 },
	{ 5000, "고블린도 부러워할 재산", "무법항의 고블린들이 내 금고를 탐낸다는 소문이 돈다.", 25 },
})

for _, h in ipairs({
	{ 1,   "첫 한 시간",           "첫 한 시간이 흘렀다. 이야기는 이제 막 시작되었다.", 5 },
	{ 10,  "열 시간의 여정",       "어느새 열 시간. 길 위의 시간은 빠르게 흐른다." },
	{ 24,  "꼬박 하루",            "꼬박 하루를 아제로스에서 보냈다. 해가 몇 번 졌는지도 모르겠다." },
	{ 50,  "길 위의 나날",         "집보다 길 위가 더 익숙해졌다." },
	{ 100, "백 시간의 동행",       "백 시간. 이 세계가 또 하나의 고향이 되었다." },
	{ 200, "끝나지 않는 이야기",   "이 전기는 이제 두꺼운 책 한 권이 되었다.", 25 },
	{ 500, "아제로스의 주민",      "오백 시간. 나는 이 세계의 일부가 되었다.", 25 },
}) do
	add({ id = "time" .. h[1], cat = "growth", name = h[2], desc = "전기가 기록된 모험 시간 " .. h[1] .. "시간",
		goal = h[1] * 3600, points = h[4] or 10, icon = I .. "INV_Misc_PocketWatch_01", progress = field("tracked"), flavor = h[3], format = "hours" })
end

------------------------------------------------------------------------
-- 탐험 (지역별 탐험 업적은 Forever 공식 업적에 있으므로 여기서는 발자취의 양과 일주를 다룬다)
------------------------------------------------------------------------
tiers("zones", "explore", I .. "INV_Misc_Map_01", "zones", function(v) return "서로 다른 지역 " .. v .. "곳 방문" end, {
	{ 5,  "길 위의 사람",   "지도 위의 점들이 하나둘 선으로 이어진다." },
	{ 10, "방랑자",         "어디가 고향이었는지 가끔 잊는다." },
	{ 15, "떠돌이 학자",    "가는 곳마다 새로운 이야기가 기다린다." },
	{ 20, "세계를 걷는 자", "두 대륙의 바람을 모두 맞아 보았다." },
	{ 25, "지평선 너머",    "지평선 너머에 무엇이 있는지 이제는 안다." },
	{ 30, "발 닿는 대로",   "발길 닿는 곳이 곧 길이 되었다." },
	{ 35, "지도 제작자",    "내 지도에는 이제 빈칸이 거의 없다." },
	{ 40, "땅의 끝까지",    "아제로스의 끝과 끝을 모두 밟았다.", 25 },
})
tiers("sub", "explore", I .. "Ability_Hunter_Pathfinding", "subzones", function(v) return "세부 장소 " .. v .. "곳 발견" end, {
	{ 25,  "골목대장",          "마을의 뒷골목까지 손바닥 보듯 훤하다." },
	{ 50,  "호기심 많은 여행자", "이름 없는 오솔길이 자꾸만 나를 부른다." },
	{ 100, "구석구석",          "이름 없는 언덕에도 이제 내 발자국이 있다." },
	{ 250, "발길 닿는 모든 곳", "세상의 구석구석이 내 기억 속에 있다." },
	{ 500, "살아 있는 지도",    "누가 길을 물으면 지도 없이도 대답할 수 있다.", 25 },
})
add({ id = "tour_ek", cat = "explore", name = "동부 왕국 일주", desc = "동부 왕국의 지역 22곳을 모두 방문", goal = 22, points = 25,
	icon = I .. "INV_Misc_Map_02", progress = field("ekVisited"), flavor = "엘윈 숲의 풀내음부터 역병지대의 잿빛 하늘까지, 동부 왕국을 모두 걸었다." })
add({ id = "tour_kal", cat = "explore", name = "칼림도어 일주", desc = "칼림도어의 지역 18곳을 모두 방문", goal = 18, points = 25,
	icon = I .. "INV_Misc_Map_02", progress = field("kalVisited"), flavor = "듀로타의 붉은 흙부터 여명의 설원의 눈발까지, 칼림도어를 모두 걸었다." })
add({ id = "tour_all", cat = "explore", name = "아제로스 일주", desc = "클래식 지역 40곳을 모두 방문", goal = 40, points = 50,
	icon = I .. "INV_Misc_Map_02", progress = field("allVisited"), flavor = "두 대륙의 모든 땅이 내 발자국을 기억한다." })
add({ id = "bind5", cat = "explore", name = "정착하지 않는 자", desc = "귀환석의 귀환 장소를 5번 바꾸기", goal = 5,
	icon = I .. "INV_Misc_Rune_01", progress = field("binds"), flavor = "어느 여관이든 하룻밤이면 집이 된다." })
add({ id = "bind15", cat = "explore", name = "떠도는 별", desc = "귀환석의 귀환 장소를 15번 바꾸기", goal = 15,
	icon = I .. "INV_Misc_Rune_01", progress = field("binds"), flavor = "여관 주인들 사이에서 '그 떠돌이'로 통한다." })
add({ id = "zonetime5", cat = "explore", name = "정든 땅", desc = "한 지역에서 5시간 머물기", goal = 5 * 3600, format = "hours",
	icon = I .. "Spell_Nature_EarthBind", progress = field("maxZoneTime"), flavor = "이 땅의 바람 냄새만 맡아도 어디인지 알 수 있다." })
add({ id = "zonetime20", cat = "explore", name = "제2의 고향", desc = "한 지역에서 20시간 머물기", goal = 20 * 3600, format = "hours",
	icon = I .. "Spell_Nature_EarthBind", progress = field("maxZoneTime"), flavor = "이곳 사람들은 이제 나를 이웃이라 부른다." })

------------------------------------------------------------------------
-- 퀘스트
------------------------------------------------------------------------
tiers("quest", "quest", I .. "INV_Misc_Note_01", "quests", function(v) return "퀘스트 " .. ns.Comma(v) .. "개 완료" end, {
	{ 10,   "부탁 들어주기",     "누군가의 부탁을 들어주는 일. 영웅의 시작은 늘 이렇게 소박하다.", 5 },
	{ 25,   "동네 해결사",       "마을 아이들이 내 이름을 부르며 따라다닌다." },
	{ 50,   "믿음직한 해결사",   "게시판 앞에 서면 사람들이 먼저 말을 걸어온다." },
	{ 75,   "바쁜 하루하루",     "쉴 틈 없이 부탁이 이어진다. 그래도 싫지 않다." },
	{ 100,  "백 가지 이야기",    "백 개의 부탁, 백 개의 사연. 모두 내 전기의 한 줄이 되었다." },
	{ 150,  "이름난 해결사",     "편지 속에 '부디 그분께'라는 말이 늘어 간다." },
	{ 200,  "두 대륙의 해결사",  "어느 대륙에 가도 나를 기다리는 부탁이 있다." },
	{ 250,  "모두의 해결사",     "이 대륙에 내 도움을 받지 않은 마을이 있을까." },
	{ 300,  "끝없는 의뢰",       "의뢰서 더미가 줄지 않는다. 그게 바로 영웅의 일이다." },
	{ 400,  "전설로 가는 길",    "누군가 내 이야기를 모아 책으로 엮겠다고 한다." },
	{ 500,  "전설적인 해결사",   "술집의 음유시인들이 내 이야기를 노래하기 시작했다.", 25 },
	{ 750,  "걸어 다니는 전설",  "마을마다 내 이름을 딴 이야기가 하나씩 있다.", 25 },
	{ 1000, "천 개의 이야기",    "천 개의 부탁을 들어준 자. 그것이 나의 또 다른 이름이다.", 50 },
})
tiers("qzones", "quest", I .. "INV_Misc_Note_02", "questZones", function(v) return "서로 다른 " .. v .. "개 지역에서 퀘스트 완료" end, {
	{ 5,  "이웃 마을의 부탁", "옆 마을에서도 내 이름을 안다." },
	{ 10, "각지의 해결사",    "어느 지역에 가도 나를 기다리는 부탁이 있었다." },
	{ 15, "발 넓은 모험가",   "여러 땅의 사람들과 인연을 맺었다." },
	{ 20, "두 대륙의 손님",   "두 대륙의 여관 주인들이 나를 반긴다." },
	{ 25, "온 세상의 부탁",   "두 대륙 곳곳에 내 이름이 적힌 감사 편지가 남아 있다." },
	{ 30, "어디에나 있는 자", "내가 가 보지 않은 마을의 부탁 게시판은 거의 없다.", 25 },
})
add({ id = "qzone30", cat = "quest", name = "이 땅의 이야기꾼", desc = "한 지역에서 퀘스트 30개 완료", goal = 30,
	icon = I .. "INV_Misc_Book_11", progress = field("questMaxZone"), flavor = "그 땅의 사람들은 이제 나를 이웃이라 부른다." })
tiers("qday", "quest", I .. "INV_Misc_Note_03", "questMaxDay", function(v) return "하루에 퀘스트 " .. v .. "개 완료" end, {
	{ 20, "하루치 일당", "해가 지기 전에 스무 개의 부탁을 해결했다. 오늘 밤은 푹 잘 수 있겠다." },
	{ 50, "일 중독",     "하루에 쉰 개. 의뢰인들이 오히려 나를 걱정한다.", 25 },
})
-- 지역별 이야기꾼 (로어마스터 비슷한 업적)
for _, z in ipairs(ns.CLASSIC_ZONES) do
	local goal = z.fewQuests and 3 or 10
	add({ id = "lore_" .. z.map, cat = "quest", name = z.name .. "의 이야기꾼", desc = z.name .. "에서 퀘스트 " .. goal .. "개 완료", goal = goal,
		icon = I .. "INV_Misc_Book_08", zone = z,
		progress = function(ctx) return math.max(ctx.questZone[z.name] or 0, ctx.questMap[z.map] or 0) end,
		flavor = z.name .. "의 사람들이 나를 기억한다. 그 땅의 이야기 몇 편에 내 이름이 들어갔다." })
end
add({ id = "lore_ek", cat = "quest", name = "동부 왕국의 이야기꾼", desc = "동부 왕국의 지역별 이야기꾼 업적 15개 달성", goal = 15, points = 25,
	icon = I .. "INV_Misc_Book_07", progress = field("loreEK"), flavor = "동부 왕국의 수많은 마을이 내 이야기를 품고 있다." })
add({ id = "lore_kal", cat = "quest", name = "칼림도어의 이야기꾼", desc = "칼림도어의 지역별 이야기꾼 업적 12개 달성", goal = 12, points = 25,
	icon = I .. "INV_Misc_Book_07", progress = field("loreKal"), flavor = "칼림도어의 초원과 사막에 내 발자취가 이야기로 남았다." })
add({ id = "lore_all", cat = "quest", name = "아제로스의 이야기꾼", desc = "두 대륙의 이야기꾼 업적을 모두 달성", goal = 2, points = 50,
	icon = I .. "INV_Misc_Book_07", progress = field("loreBoth"), flavor = "두 대륙의 이야기가 한 사람의 전기 속에서 만났다." })

------------------------------------------------------------------------
-- 던전
------------------------------------------------------------------------
for _, d in ipairs(ns.CLASSIC_DUNGEONS) do
	add({ id = "dg" .. d.map, cat = "dungeon", name = d.name .. " 정복", desc = d.name .. "에서 보스를 쓰러뜨리고 원정을 마치기 (" .. d.lv .. "레벨)",
		goal = 1, icon = I .. "INV_Misc_Key_03", dungeon = d,
		progress = function(ctx) return math.max(ctx.clearCount[d.map] or 0, ctx.clearCountName[d.name] or 0) end,
		flavor = d.name .. "의 어둠을 뚫고 살아 돌아왔다. 그곳의 기억은 이제 전기의 한 장이 되었다." })
	add({ id = "dgx" .. d.map, cat = "dungeon", name = d.name .. " 단골", desc = d.name .. " 원정을 5번 성공하기", goal = 5, points = 5,
		icon = I .. "INV_Misc_Key_04", dungeon = d,
		progress = function(ctx) return math.max(ctx.clearCount[d.map] or 0, ctx.clearCountName[d.name] or 0) end,
		flavor = d.name .. "의 함정 위치까지 외워 버렸다. 문지기 몬스터가 나를 알아보는 것 같다." })
end
for _, m in ipairs({
	{ 3,  "첫 번째 미궁들",     "서로 다른 클래식 던전 3곳 정복",  5,  "던전의 습한 공기에 조금은 익숙해졌다." },
	{ 5,  "던전 탐험가",        "서로 다른 클래식 던전 5곳 정복",  10, "던전의 습한 공기가 이제는 낯설지 않다." },
	{ 10, "던전 정복자",        "서로 다른 클래식 던전 10곳 정복", 10, "횃불 하나 들고 미궁에 들어서는 일이 일상이 되었다." },
	{ 15, "미궁의 주인",        "서로 다른 클래식 던전 15곳 정복", 25, "지하의 어둠이 더는 두렵지 않다." },
	{ #ns.CLASSIC_DUNGEONS, "고전 던전의 지배자", "클래식 던전 " .. #ns.CLASSIC_DUNGEONS .. "곳을 모두 정복", 50,
		"성난불길 협곡에서 스트라솔름까지. 아제로스의 모든 어둠이 내 발아래 있었다." },
}) do
	add({ id = "dgmeta" .. m[1], cat = "dungeon", name = m[2], desc = m[3], goal = m[1], points = m[4],
		icon = I .. "INV_Misc_Key_04", progress = field("dungeonsCleared"), flavor = m[5] })
end
tiers("runs", "dungeon", I .. "INV_Misc_Key_05", "runs", function(v) return "던전 원정 " .. v .. "회" end, {
	{ 10,  "던전 나들이",   "던전에 들어서는 발걸음이 가벼워졌다.", 5 },
	{ 25,  "던전 단골",     "던전 입구의 경비병이 내 얼굴을 기억한다." },
	{ 50,  "어둠의 순례자", "어둠 속에서 보낸 시간이 햇빛 아래보다 길다." },
	{ 100, "던전에서 산다", "햇빛보다 횃불 빛이 더 익숙해졌다.", 25 },
})
tiers("boss", "dungeon", I .. "INV_Misc_Bone_HumanSkull_01", "bossKills", function(v) return "보스 " .. v .. "번 처치" end, {
	{ 10,  "보스 사냥꾼",     "강한 자를 쓰러뜨릴 때마다 나도 조금씩 강해진다." },
	{ 50,  "왕관 수집가",     "쓰러뜨린 군주들의 이름을 외우는 것만으로도 숨이 차다." },
	{ 100, "보스의 악몽",     "던전의 주인들은 이제 내 발소리만 들어도 떨고 있으리라.", 25 },
	{ 500, "군주들의 무덤",   "오백 명의 군주가 내 앞에서 무너졌다. 내 이름은 그들의 마지막 기억이다.", 50 },
})
add({ id = "comeback", cat = "dungeon", name = "넘어져도 다시", desc = "전멸한 원정에서 끝내 보스를 쓰러뜨리기", goal = 1,
	icon = I .. "Spell_Holy_Resurrection", progress = field("comeback"), flavor = "쓰러진 자리에서 다시 일어섰다. 그것이 승리보다 값진 기억이다." })
add({ id = "flawless", cat = "dungeon", name = "무사 귀환", desc = "한 번도 쓰러지지 않고 보스 3명 이상을 쓰러뜨린 원정", goal = 1,
	icon = I .. "Spell_Holy_DivineIntervention", progress = field("flawless"), flavor = "상처 하나 없이 돌아온 원정. 동료들과 나눈 술이 유난히 달았다." })
add({ id = "bigrun", cat = "dungeon", name = "대청소", desc = "한 번의 원정에서 보스 5명 이상 쓰러뜨리기", goal = 5,
	icon = I .. "INV_Misc_Bone_HumanSkull_01", progress = field("maxBossesRun"), flavor = "던전 구석구석을 비웠다. 다음 모험가에게는 먼지밖에 남지 않았을 것이다." })
add({ id = "fastrun", cat = "dungeon", name = "속전속결", desc = "보스 3명 이상을 쓰러뜨린 원정을 30분 안에 마치기", goal = 1,
	icon = I .. "Ability_Rogue_Sprint", progress = field("fastRun"), flavor = "숨 돌릴 틈도 없었다. 들어갔다 나오니 모래시계가 절반도 내려가지 않았다." })
add({ id = "wipes10", cat = "dungeon", name = "전멸도 경험이다", desc = "던전·공격대에서 전멸 10번 겪기", goal = 10, points = 5,
	icon = I .. "Spell_Shadow_DeathScream", progress = field("wipes"), flavor = "쓰러질 때마다 하나씩 배웠다. 이제는 어디서 쓰러지는지도 안다." })

------------------------------------------------------------------------
-- 공격대
------------------------------------------------------------------------
for _, r in ipairs(ns.CLASSIC_RAIDS) do
	add({ id = "rd" .. r.map, cat = "raid", name = r.name .. " 공략", desc = r.name .. "에서 보스를 쓰러뜨리기 (" .. r.size .. "인 공격대)",
		goal = 1, points = 25, icon = I .. "INV_Misc_Head_Dragon_01", dungeon = r,
		progress = function(ctx) return math.max(ctx.clearCount[r.map] or 0, ctx.clearCountName[r.name] or 0) end,
		flavor = r.name .. "의 문턱을 넘어 살아 돌아왔다. 공격대의 함성이 아직도 귓가에 울린다." })
	add({ id = "rdx" .. r.map, cat = "raid", name = r.name .. " 정예 대원", desc = r.name .. " 공략을 5번 성공하기", goal = 5,
		icon = I .. "INV_Misc_Head_Dragon_Red", dungeon = r,
		progress = function(ctx) return math.max(ctx.clearCount[r.map] or 0, ctx.clearCountName[r.name] or 0) end,
		flavor = r.name .. "의 공략 순서를 눈 감고도 읊을 수 있다." })
end
add({ id = "raid1", cat = "raid", name = "공격대의 일원", desc = "어느 공격대에서든 보스를 쓰러뜨리기", goal = 1,
	icon = I .. "INV_Misc_Head_Dragon_Black", progress = field("raidClears"), flavor = "수십 명이 한 사람처럼 움직였다. 나는 그 거대한 이야기의 일부였다." })
add({ id = "raid10", cat = "raid", name = "공격대의 기둥", desc = "공격대 공략 10번 성공", goal = 10,
	icon = I .. "INV_Misc_Head_Dragon_Black", progress = field("raidClears"), flavor = "공격대장이 출석부에서 가장 먼저 내 이름을 확인한다." })

------------------------------------------------------------------------
-- 몬스터 도감
------------------------------------------------------------------------
tiers("tribes", "dex", I .. "Ability_EyeOfTheOwl", "tribes", function(v) return "도감 종족 " .. v .. "개 발견" end, {
	{ 5,  "도감 수집가", "도감의 첫 페이지들이 채워지기 시작했다." },
	{ 10, "종족 학자",   "아제로스에 사는 종족들의 이름을 이제 제법 외우고 있다." },
	{ 15, "종족 탐구가", "도감의 절반 가까이가 채워졌다.", 10 },
	{ 20, "박물학자",    "학자들이 내 도감을 빌려 가고 싶어 한다.", 25 },
	{ 25, "현장 연구자", "남은 빈칸이 손에 꼽을 만큼 줄었다.", 25 },
	{ 30, "도감의 끝이 보인다", "마지막 몇 페이지만이 비어 있다.", 25 },
	{ 34, "도감 완성",   "서른네 개의 종족, 서른네 개의 이야기. 도감의 마지막 장을 덮었다.", 50 },
})
tiers("species", "dex", I .. "INV_Misc_Book_09", "species", function(v) return "도감 개체 " .. ns.Comma(v) .. "종 등록" end, {
	{ 10,   "관찰 일지",          "작은 수첩이 이름으로 가득 찼다.", 5 },
	{ 25,   "부지런한 관찰자",    "새로운 얼굴을 보면 수첩부터 꺼낸다." },
	{ 50,   "살아 있는 백과사전", "어떤 몬스터 이름을 대도 나는 대답할 수 있다." },
	{ 100,  "백 가지 얼굴",       "백 가지 생김새, 백 가지 울음소리. 모두 기억하고 있다." },
	{ 250,  "도감의 주인",        "내 도감은 이제 어느 도서관의 책보다 두껍다.", 25 },
	{ 500,  "만물박사",           "아제로스의 거의 모든 생명이 내 기록 속에 있다.", 25 },
	{ 750,  "걸어 다니는 도서관", "학자들이 내 수첩을 베끼러 줄을 선다.", 50 },
	{ 1000, "천 개의 이름",       "천 개의 생명, 천 개의 이름. 나는 그 모두를 만났다.", 50 },
})
tiers("rares", "dex", I .. "INV_Misc_Gem_Ruby_01", "rares", function(v) return "희귀 개체 " .. v .. "종 발견" end, {
	{ 1,  "희귀한 만남",   "은빛 테두리. 그 첫 목격의 떨림을 잊을 수 없다." },
	{ 3,  "운 좋은 여행자", "희귀한 존재들이 자꾸만 내 앞에 나타난다." },
	{ 5,  "희귀 사냥꾼",   "희귀한 존재를 찾는 눈이 생겼다." },
	{ 10, "은빛 추적자",   "모험가들이 희귀 개체의 위치를 내게 묻는다." },
	{ 25, "전설 수집가",   "전설로만 듣던 존재들이 내 도감 속에 나란히 있다.", 25 },
	{ 50, "은빛 도감",     "희귀 개체만으로 도감 한 권을 채울 수 있겠다.", 50 },
})
tiers("rarekills", "dex", I .. "INV_Misc_Gem_Diamond_01", "rareKills", function(v) return "희귀 개체 " .. v .. "종 처치" end, {
	{ 1,  "첫 번째 전리품", "희귀한 사냥감을 쓰러뜨린 손이 아직도 떨린다." },
	{ 5,  "은빛 사냥 기록", "희귀한 사냥감의 전리품이 가방 한 칸을 차지했다." },
	{ 10, "은빛 사냥꾼",    "희귀 개체를 쓰러뜨리는 일이 이제 익숙하다." },
	{ 25, "전설 사냥꾼",    "전설로 불리던 존재들이 하나둘 내 앞에서 무너졌다.", 25 },
})
tiers("kills", "dex", I .. "Ability_Warrior_BattleShout", "kills", function(v) return "몬스터 " .. ns.Comma(v) .. "마리 처치" end, {
	{ 100,   "첫 백 번의 싸움", "백 번의 싸움을 지나며 검이 손에 익었다." },
	{ 500,   "단련된 칼날",     "싸움이 끝나면 숨을 고르는 시간이 점점 짧아진다." },
	{ 1000,  "천 번의 승리",    "천 번을 이기고 나서야 비로소 싸움을 알게 되었다." },
	{ 2500,  "전장의 사신",     "몬스터들 사이에서 내 이름이 저주처럼 퍼졌다." },
	{ 5000,  "전장의 그림자",   "내가 지나간 자리에는 고요만 남는다.", 25 },
	{ 10000, "만 번의 전설",    "만 번의 승리. 이 숫자 앞에서 누구도 함부로 말하지 못한다.", 25 },
	{ 25000, "끝없는 사냥",     "이만 오천. 이제는 숫자를 세는 것조차 의미가 없다.", 50 },
})
add({ id = "rank4", cat = "dex", name = "첫 연구 논문", desc = "한 종족의 연구 등급을 ★★★ 연구자까지 올리기", goal = 4,
	icon = I .. "INV_Misc_Book_11", progress = field("maxRank"), flavor = "한 종족에 대한 연구가 마침내 한 권의 책이 되었다." })
add({ id = "rank5", cat = "dex", name = "그 분야의 권위자", desc = "한 종족의 연구 등급을 ★★★★ 권위자까지 올리기", goal = 5,
	icon = I .. "INV_Misc_Book_11", progress = field("maxRank"), flavor = "학회에 초대받았다. 나는 한 종족의 전문가가 되었다." })
add({ id = "rank6", cat = "dex", name = "살아 있는 전설", desc = "한 종족의 연구 등급을 ★★★★★ 전설의 사냥꾼까지 올리기", goal = 6,
	points = 25, icon = I .. "INV_Misc_Book_11", progress = field("maxRank"), flavor = "그 종족의 역사 속에 내 이름이 새겨졌다." })
add({ id = "rank4x5", cat = "dex", name = "다재다능한 학자", desc = "종족 5개의 연구 등급을 ★★★ 연구자 이상으로 올리기", goal = 5,
	icon = I .. "INV_Misc_Book_11", progress = field("rank4Count"), flavor = "한 종족만 아는 학자는 반쪽짜리다. 이제 나는 여러 종족의 말을 알아듣는다." })
add({ id = "rank4x10", cat = "dex", name = "도감 교수", desc = "종족 10개의 연구 등급을 ★★★ 연구자 이상으로 올리기", goal = 10, points = 25,
	icon = I .. "INV_Misc_Book_11", progress = field("rank4Count"), flavor = "도감 강의를 하겠다고 하면 강의실이 꽉 찰 것이다." })
add({ id = "rank6x3", cat = "dex", name = "전설의 박물학자", desc = "종족 3개의 연구 등급을 ★★★★★ 전설의 사냥꾼까지 올리기", goal = 3, points = 50,
	icon = I .. "INV_Misc_Book_11", progress = field("rank6Count"), flavor = "세 종족의 역사가 나를 기억한다." })
tiers("families", "dex", I .. "Ability_Hunter_BeastTaming", "families", function(v) return "야수 계통 " .. v .. "종 발견" end, {
	{ 5,  "짐승 관찰자", "늑대, 거미, 멧돼지… 야생은 생각보다 훨씬 다채롭다." },
	{ 12, "야생의 친구", "어떤 사냥꾼보다 많은 짐승의 이름을 알고 있다." },
	{ 20, "야생의 학자", "짐승의 발자국만 보고도 계통을 맞힐 수 있다.", 25 },
})
tiers("critters", "dex", I .. "Spell_Nature_Polymorph", "critters", function(v) return "작은 동물 " .. v .. "종 발견" end, {
	{ 10, "작은 친구들", "모험이 늘 피와 칼로만 이루어지는 것은 아니다." },
	{ 25, "다람쥐도 내 친구", "풀숲의 작은 생명들까지 하나하나 이름을 불러 줄 수 있다.", 25 },
})
tiers("elites", "dex", I .. "Ability_Warrior_DefensiveStance", "elites", function(v) return "정예 몬스터 " .. v .. "종 발견" end, {
	{ 10, "정예와의 조우", "황금 용 테두리가 이제는 두렵지 않다." },
	{ 50, "정예 수집가",   "강한 자들만 모아 놓은 페이지가 따로 생겼다.", 25 },
})
tiers("wboss", "dex", I .. "INV_Misc_Head_Dragon_01", "worldBossKills", function(v) return "우두머리급 존재 " .. v .. "번 처치" end, {
	{ 1, "거인 사냥꾼",   "산처럼 거대한 존재가 무너지던 그날의 굉음을 잊지 못한다.", 25 },
	{ 3, "재앙을 막는 자", "세상을 위협하던 존재들이 하나둘 쓰러졌다.", 50 },
})
add({ id = "night25", cat = "dex", name = "밤의 관찰자", desc = "깊은 밤에 도감 개체 25종 발견", goal = 25,
	icon = I .. "Spell_Shadow_Twilight", progress = function(ctx) return ctx.todSpecies["깊은 밤"] or 0 end,
	flavor = "어둠이 내려앉은 뒤에야 모습을 드러내는 것들이 있다. 나는 그들을 기록했다." })
add({ id = "dawn10", cat = "dex", name = "새벽의 관찰자", desc = "새벽녘에 도감 개체 10종 발견", goal = 10,
	icon = I .. "Spell_Holy_HolyBolt", progress = function(ctx) return ctx.todSpecies["새벽녘"] or 0 end,
	flavor = "동이 트기 전, 세상이 가장 조용할 때 그들을 만났다." })

------------------------------------------------------------------------
-- 종족 연구 (종족마다: 첫 만남 · 연구자 · 100마리 처치)
------------------------------------------------------------------------
local KILL_NAMES = {
	murloc = "므르글!", gnoll = "하이에나 웃음은 이제 그만", kobold = "양초는 내가 가져간다",
	defias = "붉은 두건 사냥꾼", scarlet = "광신의 끝", undead = "안식을 주는 자",
	critter = "작은 생명들에게 미안해", mystery = "미지와의 백 번의 조우", humanoid = "무법자 소탕",
	dragonkin = "용 사냥꾼", demon = "악마 퇴치사", elemental = "정령 봉인자", giant = "거인 쓰러뜨리기",
	beast = "야생의 포식자", mechanical = "고철 수집가", silithid = "벌집 소탕", pirate = "해적 소탕",
}
for _, t in ipairs(ns.TRIBES) do
	local short = t.short or t.name
	local unit = t.unit or "마리"
	add({ id = "tf_" .. t.id, cat = "tribe", name = ns.Josa(t.name, "과") .. "의 첫 만남", desc = "도감에 " .. t.name .. " 종족 등록하기",
		goal = 1, points = 5, icon = t.icon, tribe = t.id,
		progress = function(ctx) return ctx.tribeFound[t.id] or 0 end,
		flavor = t.name .. " 항목의 첫 장이 펼쳐졌다." })
	add({ id = "tr_" .. t.id, cat = "tribe", name = short .. " 연구자", desc = t.name .. " 연구 등급 ★★★ 연구자 달성", goal = 4,
		icon = t.icon, tribe = t.id,
		progress = function(ctx) return ctx.tribeRank[t.id] or 0 end,
		flavor = t.name .. "에 대해서라면 밤새 이야기할 수 있게 되었다." })
	add({ id = "tk_" .. t.id, cat = "tribe", name = KILL_NAMES[t.id] or (short .. " 토벌"), desc = t.name .. " 100" .. unit .. " 처치",
		goal = 100, icon = t.icon, tribe = t.id,
		progress = function(ctx) return ctx.tribeKills[t.id] or 0 end,
		flavor = "백 번째 싸움이 끝나자, " .. ns.Josa(short, "의") .. " 무리가 내 이름을 수군대기 시작했다." })
end

------------------------------------------------------------------------
-- 전장 (계급·평판은 Forever 레거시 도전 과제에 있으므로 참전 기록만)
------------------------------------------------------------------------
tiers("bg", "pvp", I .. "Ability_DualWield", "bgTotal", function(v) return "전장 " .. v .. "회 참전" end, {
	{ 1,   "첫 참전",    "나팔 소리와 함께 처음으로 전장에 섰다." },
	{ 10,  "전장의 단골", "전투 지휘관이 내 이름을 부른다." },
	{ 50,  "백전노장",   "전장의 흙냄새가 이제는 고향 냄새 같다." },
	{ 100, "전장의 전설", "백 번의 전장. 깃발이 오를 때마다 내 함성도 함께 올랐다.", 25 },
})
for _, bg in ipairs(ns.CLASSIC_BATTLEGROUNDS) do
	add({ id = "bgm" .. bg.map, cat = "pvp", name = bg.name .. "의 병사", desc = bg.name .. "에 참전하기", goal = 1, icon = I .. "Ability_Warrior_BattleShout",
		progress = function(ctx) return math.max(ctx.bgMaps[bg.map] or 0, ctx.bgNames[bg.name] or 0) end, flavor = bg.name .. "의 함성 속에 내 목소리도 섞여 있었다." })
	add({ id = "bgx" .. bg.map, cat = "pvp", name = bg.name .. "의 고참", desc = bg.name .. "에 10번 참전하기", goal = 10, icon = I .. "Ability_Warrior_BattleShout",
		progress = function(ctx) return math.max(ctx.bgMaps[bg.map] or 0, ctx.bgNames[bg.name] or 0) end, flavor = bg.name .. "의 지형이라면 눈을 감고도 그릴 수 있다." })
end

------------------------------------------------------------------------
-- 평판
------------------------------------------------------------------------
tiers("exalted", "rep", I .. "Spell_Holy_HolyBolt", "exalted", function(v) return "평판 확고한 동맹 " .. v .. "개" end, {
	{ 1,  "누군가의 영웅",    "한 세력이 나를 형제처럼 받아들였다." },
	{ 3,  "여러 깃발 아래",   "세 세력이 나를 영웅이라 부른다." },
	{ 5,  "모두의 친구",      "어느 세력의 진영에 가도 환대를 받는다.", 25 },
	{ 10, "아제로스의 대사",  "열 개의 세력이 나를 최고의 벗으로 여긴다.", 25 },
	{ 15, "모든 깃발의 벗",   "열다섯 개의 깃발이 나를 위해 휘날린다.", 50 },
})

------------------------------------------------------------------------
-- 시련
------------------------------------------------------------------------
tiers("death", "trial", I .. "Spell_Shadow_DeathScream", "deaths", function(v) return v == 1 and "처음으로 쓰러지기" or (v .. "번 쓰러지기") end, {
	{ 1,   "죽음은 끝이 아니다", "차가운 영혼의 길을 처음 걸었다. 돌아왔을 때, 세상이 조금 다르게 보였다.", 5 },
	{ 25,  "영혼의 치유사 단골", "영혼의 치유사가 이제 나를 보면 한숨부터 쉰다.", 5 },
	{ 100, "불사조",             "백 번 쓰러지고 백 번 일어났다. 그게 나다." },
})
add({ id = "deathzones", cat = "trial", name = "곳곳에 남긴 묘비", desc = "서로 다른 10개 지역에서 쓰러지기", goal = 10, points = 5,
	icon = I .. "INV_Misc_Bone_Skull_01", progress = field("deathZones"), flavor = "아제로스 곳곳의 영혼의 치유사가 내 얼굴을 안다." })
add({ id = "dgdeaths", cat = "trial", name = "던전의 희생양", desc = "던전·공격대 안에서 10번 쓰러지기", goal = 10, points = 5,
	icon = I .. "INV_Misc_Bone_HumanSkull_01", progress = field("dungeonDeaths"), flavor = "던전 입구까지 영혼으로 달리는 길이 지름길처럼 익숙하다." })
for _, lv in ipairs({ 10, 20, 30, 40, 50, 60 }) do
	add({ id = "deathless" .. lv, cat = "trial", name = "흔들림 없는 발걸음 " .. lv, desc = "기록이 시작된 뒤 한 번도 쓰러지지 않고 " .. lv .. "레벨 도달",
		goal = 1, points = lv >= 40 and 25 or 10, icon = I .. "Spell_Holy_DivineIntervention",
		progress = function(ctx) return ctx.deathless[lv] and 1 or 0 end,
		flavor = lv .. "레벨이 될 때까지 단 한 번도 무릎 꿇지 않았다." })
end

------------------------------------------------------------------------
-- 연대기
------------------------------------------------------------------------
tiers("note", "chronicle", I .. "INV_Scroll_03", "notes", function(v) return "나만의 기록 " .. v .. "개 남기기" end, {
	{ 1,   "첫 문장",     "펜을 들었다. 내 이야기를 내 손으로 쓰기 시작했다.", 5 },
	{ 10,  "작가의 습관", "하루를 마치면 일지를 펴는 것이 습관이 되었다." },
	{ 25,  "일기장",      "내 문장이 전기 곳곳에 별처럼 박혀 있다." },
	{ 50,  "모험 작가",   "이 전기는 이제 나만의 문장으로 가득하다.", 25 },
	{ 100, "문장가",      "언젠가 이 기록이 누군가에게 모험을 떠날 용기를 주기를.", 25 },
})
tiers("log", "chronicle", I .. "INV_Misc_Book_09", "logCount", function(v) return "전기에 기록 " .. ns.Comma(v) .. "개 쌓기" end, {
	{ 100,  "두꺼워진 전기",    "어느새 백 줄. 내 이야기가 이렇게 길어졌다." },
	{ 500,  "대하소설",         "누군가 이 전기를 읽는다면 밤을 새워야 하리라." },
	{ 1000, "살아 있는 역사서", "천 줄의 기록. 이것은 한 사람의 역사이자, 아제로스의 역사다.", 25 },
	{ 2000, "전집",             "한 권으로는 모자라 여러 권으로 나누어야 할 지경이다.", 25 },
	{ 5000, "끝나지 않는 대서사시", "오천 줄. 이 전기는 이제 하나의 세계다.", 50 },
})
tiers("export", "chronicle", I .. "INV_Scroll_05", "exported", function(v) return v == 1 and "전기를 내보내기로 옮겨 적기" or ("전기를 " .. v .. "번 옮겨 적기") end, {
	{ 1,  "필사본",     "전기를 옮겨 적었다. 이 이야기는 이제 게임 밖에서도 살아 숨 쉰다.", 5 },
	{ 10, "열 권의 필사본", "친구들에게 나눠 줄 만큼 필사본이 쌓였다.", 5 },
})

------------------------------------------------------------------------
-- 소소한 재미 (현실의 시각과 날짜로 판정)
------------------------------------------------------------------------
add({ id = "streak7", cat = "fun", name = "개근상", desc = "7일 연속으로 전기에 기록 남기기", goal = 7,
	icon = I .. "INV_Misc_PocketWatch_01", progress = field("streak"), flavor = "하루도 빠짐없이 모험을 떠났다. 성실함도 영웅의 자질이다." })
add({ id = "streak30", cat = "fun", name = "한 달의 개근", desc = "30일 연속으로 전기에 기록 남기기", goal = 30, points = 25,
	icon = I .. "INV_Misc_PocketWatch_01", progress = field("streak"), flavor = "한 달 동안 하루도 쉬지 않았다. 아제로스가 나를 기다린 것인지, 내가 아제로스를 기다린 것인지." })
tiers("days", "fun", I .. "INV_Misc_PocketWatch_02", "days", function(v) return "기록이 남은 날 " .. v .. "일" end, {
	{ 10,  "열흘의 동행",  "열흘. 이 세계와 제법 가까워졌다.", 5 },
	{ 30,  "한 달의 동행", "한 달 동안 쌓인 이야기가 제법 두툼하다." },
	{ 100, "백일의 동행",  "백일. 아제로스와 함께한 시간이 하나의 계절이 되었다.", 25 },
	{ 365, "일 년의 동행", "사계절을 모두 이 세계와 함께 보냈다.", 50 },
})
add({ id = "anniv", cat = "fun", name = "전기 일주년", desc = "기록을 시작한 지 1년", goal = 365, points = 25,
	icon = I .. "INV_Misc_Gift_01", progress = field("daysSinceStart"), flavor = "꼭 일 년 전 오늘, 이 전기의 첫 줄이 쓰였다." })
add({ id = "storm5", cat = "fun", name = "폭풍 성장", desc = "하루에 레벨 5번 올리기", goal = 5,
	icon = I .. "Spell_Nature_Lightning", progress = field("levelsMaxDay"), flavor = "아침에 본 거울 속 얼굴과 저녁의 얼굴이 다르다." })
add({ id = "weekend10", cat = "fun", name = "주말 전사", desc = "토요일·일요일에 레벨 10번 올리기", goal = 10,
	icon = I .. "Ability_Warrior_BattleShout", progress = field("weekendLevels"), flavor = "주말이 오면 검을 든다. 평일의 나는 잠시 잊는다." })
add({ id = "owl100", cat = "fun", name = "올빼미 모험가", desc = "자정부터 새벽 4시 사이에 기록 100개 남기기", goal = 100,
	icon = I .. "Ability_Hunter_Pet_Owl", progress = field("nightEntries"), flavor = "모두가 잠든 시간, 나의 모험은 깨어 있었다." })
add({ id = "lark50", cat = "fun", name = "아침형 모험가", desc = "아침 6시부터 9시 사이에 기록 50개 남기기", goal = 50,
	icon = I .. "Spell_Holy_SurgeOfLight", progress = field("morningEntries"), flavor = "아침 햇살과 함께 모험을 시작하는 것만큼 상쾌한 일은 없다." })
add({ id = "midnightnote", cat = "fun", name = "자정의 작가", desc = "자정부터 새벽 4시 사이에 나만의 기록 남기기", goal = 1, points = 5,
	icon = I .. "INV_Scroll_03", progress = field("midnightNotes"), flavor = "촛불 아래에서 펜을 들었다. 밤의 문장은 유난히 솔직하다." })
add({ id = "newyear", cat = "fun", name = "새해 첫 모험", desc = "1월 1일에 전기에 기록 남기기", goal = 1, points = 5,
	icon = I .. "INV_Misc_Gift_02", progress = field("newYear"), flavor = "새해 첫날에도 길 위에 있었다. 올해의 이야기도 이렇게 시작된다." })

-- ACH_BY_ID 는 자동 생성 업적까지 더한 뒤 Data/AchievementsGen.lua 에서 만든다
