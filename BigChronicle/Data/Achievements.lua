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
	{ id = "growth",   name = "성장",       icon = I .. "Spell_Holy_InnerFire" },
	{ id = "explore",  name = "탐험",       icon = I .. "INV_Misc_Map_01" },
	{ id = "quest",    name = "퀘스트",     icon = I .. "INV_Misc_Note_01" },
	{ id = "dungeon",  name = "던전",       icon = I .. "INV_Misc_Key_03" },
	{ id = "raid",     name = "공격대",     icon = I .. "INV_Misc_Head_Dragon_01" },
	{ id = "dex",      name = "몬스터 도감", icon = I .. "Ability_EyeOfTheOwl" },
	{ id = "pvp",      name = "전장",       icon = I .. "Ability_DualWield" },
	{ id = "rep",      name = "평판",       icon = I .. "Spell_Holy_HolyBolt" },
	{ id = "trial",    name = "시련",       icon = I .. "Spell_Shadow_DeathScream" },
	{ id = "chronicle", name = "연대기",    icon = I .. "INV_Misc_Book_09" },
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

local function field(name) return function(ctx) return ctx[name] or 0 end end

------------------------------------------------------------------------
-- 성장
------------------------------------------------------------------------
local LEVELS = {
	{ 10, "모험의 첫 장",       "고향을 떠날 채비가 끝났다. 낯선 길이 나를 부른다." },
	{ 20, "이름을 알리다",     "어느 여관에서 누군가 내 이름을 입에 올렸다. 작은 소문이 시작되었다." },
	{ 30, "검증된 모험가",     "이제 나를 신참이라 부르는 이는 없다." },
	{ 40, "대륙을 달리는 자",  "말발굽 소리와 함께 세상이 한결 가까워졌다." },
	{ 50, "전설의 문턱",       "마지막 관문이 손에 잡힐 듯 가까이 있다." },
	{ 60, "아제로스의 영웅",   "긴 여정의 정점. 하지만 진짜 이야기는 이제부터다." },
}
for _, l in ipairs(LEVELS) do
	add({ id = "level" .. l[1], cat = "growth", name = l[2], desc = l[1] .. "레벨에 도달하기", goal = l[1],
		points = l[1] == 60 and 25 or 10, icon = I .. "Spell_Holy_InnerFire", progress = field("level"), flavor = l[3] })
end

local GOLD = {
	{ 10,   "두둑한 주머니",          "짤랑거리는 소리가 제법 묵직해졌다." },
	{ 100,  "탈것 자금",              "마구간 주인의 눈빛이 달라졌다." },
	{ 1000, "부호",                   "경매장 상인들이 먼저 고개를 숙인다." },
	{ 5000, "고블린도 부러워할 재산", "무법항의 고블린들이 내 금고를 탐낸다는 소문이 돈다." },
}
for _, g in ipairs(GOLD) do
	add({ id = "gold" .. g[1], cat = "growth", name = g[2], desc = ns.Comma(g[1]) .. "골드를 모으기", goal = g[1],
		points = g[1] >= 1000 and 25 or 10, icon = I .. "INV_Misc_Coin_01", progress = field("goldBest"), flavor = g[3] })
end

local HOURS = {
	{ 10,  "열 시간의 여정",       "어느새 열 시간. 길 위의 시간은 빠르게 흐른다." },
	{ 50,  "길 위의 사람",         "집보다 길 위가 더 익숙해졌다." },
	{ 200, "끝나지 않는 이야기",   "이 전기는 이제 두꺼운 책 한 권이 되었다." },
}
for _, h in ipairs(HOURS) do
	add({ id = "time" .. h[1], cat = "growth", name = h[2], desc = "전기가 기록된 모험 시간 " .. h[1] .. "시간",
		goal = h[1] * 3600, icon = I .. "INV_Misc_PocketWatch_01", progress = field("tracked"), flavor = h[3], format = "hours" })
end

------------------------------------------------------------------------
-- 탐험 (지역별 탐험 업적은 Forever 공식 업적에 있으므로 여기서는 발자취의 양을 다룬다)
------------------------------------------------------------------------
for _, z in ipairs({
	{ 5,  "길 위의 사람",   "서로 다른 지역 5곳 방문",  "지도 위의 점들이 하나둘 선으로 이어진다." },
	{ 10, "방랑자",         "서로 다른 지역 10곳 방문", "어디가 고향이었는지 가끔 잊는다." },
	{ 20, "세계를 걷는 자", "서로 다른 지역 20곳 방문", "두 대륙의 바람을 모두 맞아 보았다." },
	{ 35, "지도 제작자",    "서로 다른 지역 35곳 방문", "내 지도에는 이제 빈칸이 거의 없다." },
}) do
	add({ id = "zones" .. z[1], cat = "explore", name = z[2], desc = z[3], goal = z[1], icon = I .. "INV_Misc_Map_01",
		progress = field("zones"), flavor = z[4] })
end
for _, z in ipairs({
	{ 25,  "골목대장",            "세부 장소 25곳 발견",  "마을의 뒷골목까지 손바닥 보듯 훤하다." },
	{ 100, "구석구석",            "세부 장소 100곳 발견", "이름 없는 언덕에도 이제 내 발자국이 있다." },
	{ 250, "발길 닿는 모든 곳",   "세부 장소 250곳 발견", "세상의 구석구석이 내 기억 속에 있다." },
}) do
	add({ id = "sub" .. z[1], cat = "explore", name = z[2], desc = z[3], goal = z[1], icon = I .. "Ability_Hunter_Pathfinding",
		progress = field("subzones"), flavor = z[4] })
end
add({ id = "bind5", cat = "explore", name = "정착하지 않는 자", desc = "귀환석의 귀환 장소를 5번 바꾸기", goal = 5,
	icon = I .. "INV_Misc_Rune_01", progress = field("binds"), flavor = "어느 여관이든 하룻밤이면 집이 된다." })

------------------------------------------------------------------------
-- 퀘스트
------------------------------------------------------------------------
for _, q in ipairs({
	{ 10,   "부탁 들어주기",     "누군가의 부탁을 들어주는 일. 영웅의 시작은 늘 이렇게 소박하다." },
	{ 50,   "믿음직한 해결사",   "게시판 앞에 서면 사람들이 먼저 말을 걸어온다." },
	{ 100,  "백 가지 이야기",    "백 개의 부탁, 백 개의 사연. 모두 내 전기의 한 줄이 되었다." },
	{ 250,  "모두의 해결사",     "이 대륙에 내 도움을 받지 않은 마을이 있을까." },
	{ 500,  "전설적인 해결사",   "술집의 음유시인들이 내 이야기를 노래하기 시작했다." },
	{ 1000, "천 개의 이야기",    "천 개의 부탁을 들어준 자. 그것이 나의 또 다른 이름이다." },
}) do
	add({ id = "quest" .. q[1], cat = "quest", name = q[2], desc = "퀘스트 " .. ns.Comma(q[1]) .. "개 완료", goal = q[1],
		points = q[1] >= 500 and 25 or 10, icon = I .. "INV_Misc_Note_01", progress = field("quests"), flavor = q[3] })
end
add({ id = "qzones10", cat = "quest", name = "각지의 해결사", desc = "서로 다른 10개 지역에서 퀘스트 완료", goal = 10,
	icon = I .. "INV_Misc_Note_02", progress = field("questZones"), flavor = "어느 지역에 가도 나를 기다리는 부탁이 있었다." })
add({ id = "qzones25", cat = "quest", name = "온 세상의 부탁", desc = "서로 다른 25개 지역에서 퀘스트 완료", goal = 25,
	icon = I .. "INV_Misc_Note_02", progress = field("questZones"), flavor = "두 대륙 곳곳에 내 이름이 적힌 감사 편지가 남아 있다." })
add({ id = "qzone30", cat = "quest", name = "이 땅의 이야기꾼", desc = "한 지역에서 퀘스트 30개 완료", goal = 30,
	icon = I .. "INV_Misc_Book_11", progress = field("questMaxZone"), flavor = "그 땅의 사람들은 이제 나를 이웃이라 부른다." })

------------------------------------------------------------------------
-- 던전 / 공격대
------------------------------------------------------------------------
for _, d in ipairs(ns.CLASSIC_DUNGEONS) do
	add({ id = "dg" .. d.map, cat = "dungeon", name = d.name .. " 정복", desc = d.name .. "에서 보스를 쓰러뜨리고 원정을 마치기 (" .. d.lv .. "레벨)",
		goal = 1, icon = I .. "INV_Misc_Key_03", dungeon = d,
		progress = function(ctx) return ctx.cleared[d.map] or ctx.clearedName[d.name] or 0 end,
		flavor = d.name .. "의 어둠을 뚫고 살아 돌아왔다. 그곳의 기억은 이제 전기의 한 장이 되었다." })
end
for _, m in ipairs({
	{ 5,  "던전 탐험가",       "서로 다른 클래식 던전 5곳 정복",  10, "던전의 습한 공기가 이제는 낯설지 않다." },
	{ 10, "던전 정복자",       "서로 다른 클래식 던전 10곳 정복", 10, "횃불 하나 들고 미궁에 들어서는 일이 일상이 되었다." },
	{ #ns.CLASSIC_DUNGEONS, "고전 던전의 지배자", "클래식 던전 " .. #ns.CLASSIC_DUNGEONS .. "곳을 모두 정복", 50,
		"성난불길 협곡에서 스트라솔름까지. 아제로스의 모든 어둠이 내 발아래 있었다." },
}) do
	add({ id = "dgmeta" .. m[1], cat = "dungeon", name = m[2], desc = m[3], goal = m[1], points = m[4],
		icon = I .. "INV_Misc_Key_04", progress = field("dungeonsCleared"), flavor = m[5] })
end
add({ id = "runs25", cat = "dungeon", name = "던전 단골", desc = "던전 원정 25회", goal = 25, icon = I .. "INV_Misc_Key_05",
	progress = field("runs"), flavor = "던전 입구의 경비병이 내 얼굴을 기억한다." })
add({ id = "runs100", cat = "dungeon", name = "던전에서 산다", desc = "던전 원정 100회", goal = 100, icon = I .. "INV_Misc_Key_05",
	progress = field("runs"), flavor = "햇빛보다 횃불 빛이 더 익숙해졌다." })
add({ id = "boss10", cat = "dungeon", name = "보스 사냥꾼", desc = "보스 10번 처치", goal = 10, icon = I .. "INV_Misc_Bone_HumanSkull_01",
	progress = field("bossKills"), flavor = "강한 자를 쓰러뜨릴 때마다 나도 조금씩 강해진다." })
add({ id = "boss100", cat = "dungeon", name = "보스의 악몽", desc = "보스 100번 처치", goal = 100, icon = I .. "INV_Misc_Bone_HumanSkull_01",
	progress = field("bossKills"), flavor = "던전의 주인들은 이제 내 발소리만 들어도 떨고 있으리라." })
add({ id = "comeback", cat = "dungeon", name = "넘어져도 다시", desc = "전멸한 원정에서 끝내 보스를 쓰러뜨리기", goal = 1,
	icon = I .. "Spell_Holy_Resurrection", progress = field("comeback"), flavor = "쓰러진 자리에서 다시 일어섰다. 그것이 승리보다 값진 기억이다." })
add({ id = "flawless", cat = "dungeon", name = "무사 귀환", desc = "한 번도 쓰러지지 않고 보스 3명 이상을 쓰러뜨린 원정", goal = 1,
	icon = I .. "Spell_Holy_DivineIntervention", progress = field("flawless"), flavor = "상처 하나 없이 돌아온 원정. 동료들과 나눈 술이 유난히 달았다." })

for _, r in ipairs(ns.CLASSIC_RAIDS) do
	add({ id = "rd" .. r.map, cat = "raid", name = r.name .. " 공략", desc = r.name .. "에서 보스를 쓰러뜨리기 (" .. r.size .. "인 공격대)",
		goal = 1, points = 25, icon = I .. "INV_Misc_Head_Dragon_01", dungeon = r,
		progress = function(ctx) return ctx.cleared[r.map] or ctx.clearedName[r.name] or 0 end,
		flavor = r.name .. "의 문턱을 넘어 살아 돌아왔다. 공격대의 함성이 아직도 귓가에 울린다." })
end
add({ id = "raid1", cat = "raid", name = "공격대의 일원", desc = "어느 공격대에서든 보스를 쓰러뜨리기", goal = 1,
	icon = I .. "INV_Misc_Head_Dragon_Black", progress = field("raidClears"), flavor = "수십 명이 한 사람처럼 움직였다. 나는 그 거대한 이야기의 일부였다." })

------------------------------------------------------------------------
-- 몬스터 도감
------------------------------------------------------------------------
for _, t in ipairs({
	{ 5,  "도감 수집가", 10, "도감의 첫 페이지들이 채워지기 시작했다." },
	{ 10, "종족 학자",   10, "아제로스에 사는 종족들의 이름을 이제 제법 외우고 있다." },
	{ 20, "박물학자",    25, "학자들이 내 도감을 빌려 가고 싶어 한다." },
	{ 34, "도감 완성",   50, "서른네 개의 종족, 서른네 개의 이야기. 도감의 마지막 장을 덮었다." },
}) do
	add({ id = "tribes" .. t[1], cat = "dex", name = t[2], desc = "도감 종족 " .. t[1] .. "개 발견", goal = t[1], points = t[3],
		icon = I .. "Ability_EyeOfTheOwl", progress = field("tribes"), flavor = t[4] })
end
for _, s in ipairs({
	{ 10,  "관찰 일지",        "작은 수첩이 이름으로 가득 찼다." },
	{ 50,  "살아 있는 백과사전", "어떤 몬스터 이름을 대도 나는 대답할 수 있다." },
	{ 100, "백 가지 얼굴",      "백 가지 생김새, 백 가지 울음소리. 모두 기억하고 있다." },
	{ 250, "도감의 주인",       "내 도감은 이제 어느 도서관의 책보다 두껍다." },
	{ 500, "만물박사",          "아제로스의 거의 모든 생명이 내 기록 속에 있다." },
}) do
	add({ id = "species" .. s[1], cat = "dex", name = s[2], desc = "도감 개체 " .. s[1] .. "종 등록", goal = s[1],
		points = s[1] >= 250 and 25 or 10, icon = I .. "INV_Misc_Book_09", progress = field("species"), flavor = s[3] })
end
for _, r in ipairs({
	{ 1,  "희귀한 만남",   "은빛 테두리. 그 첫 목격의 떨림을 잊을 수 없다." },
	{ 5,  "희귀 사냥꾼",   "희귀한 존재를 찾는 눈이 생겼다." },
	{ 10, "은빛 추적자",   "모험가들이 희귀 개체의 위치를 내게 묻는다." },
	{ 25, "전설 수집가",   "전설로만 듣던 존재들이 내 도감 속에 나란히 있다." },
}) do
	add({ id = "rares" .. r[1], cat = "dex", name = r[2], desc = "희귀 개체 " .. r[1] .. "종 발견", goal = r[1],
		points = r[1] >= 25 and 25 or 10, icon = I .. "INV_Misc_Gem_Ruby_01", progress = field("rares"), flavor = r[3] })
end
for _, r in ipairs({ { 1, "첫 번째 전리품", "희귀한 사냥감을 쓰러뜨린 손이 아직도 떨린다." }, { 10, "은빛 사냥꾼", "희귀 개체를 쓰러뜨리는 일이 이제 익숙하다." } }) do
	add({ id = "rarekills" .. r[1], cat = "dex", name = r[2], desc = "희귀 개체 " .. r[1] .. "종 처치", goal = r[1],
		icon = I .. "INV_Misc_Gem_Diamond_01", progress = field("rareKills"), flavor = r[3] })
end
for _, k in ipairs({
	{ 100,   "첫 백 번의 싸움", "백 번의 싸움을 지나며 검이 손에 익었다." },
	{ 1000,  "천 번의 승리",    "천 번을 이기고 나서야 비로소 싸움을 알게 되었다." },
	{ 5000,  "전장의 그림자",   "내가 지나간 자리에는 고요만 남는다." },
	{ 10000, "만 번의 전설",    "만 번의 승리. 이 숫자 앞에서 누구도 함부로 말하지 못한다." },
}) do
	add({ id = "kills" .. k[1], cat = "dex", name = k[2], desc = "몬스터 " .. ns.Comma(k[1]) .. "마리 처치", goal = k[1],
		points = k[1] >= 5000 and 25 or 10, icon = I .. "Ability_Warrior_BattleShout", progress = field("kills"), flavor = k[3] })
end
add({ id = "rank4", cat = "dex", name = "첫 연구 논문", desc = "한 종족의 연구 등급을 ★★★ 연구자까지 올리기", goal = 4,
	icon = I .. "INV_Misc_Book_11", progress = field("maxRank"), flavor = "한 종족에 대한 연구가 마침내 한 권의 책이 되었다." })
add({ id = "rank6", cat = "dex", name = "살아 있는 전설", desc = "한 종족의 연구 등급을 ★★★★★ 전설의 사냥꾼까지 올리기", goal = 6,
	points = 25, icon = I .. "INV_Misc_Book_11", progress = field("maxRank"), flavor = "그 종족의 역사 속에 내 이름이 새겨졌다." })
add({ id = "rank4x5", cat = "dex", name = "다재다능한 학자", desc = "종족 5개의 연구 등급을 ★★★ 연구자 이상으로 올리기", goal = 5,
	icon = I .. "INV_Misc_Book_11", progress = field("rank4Count"), flavor = "한 종족만 아는 학자는 반쪽짜리다. 이제 나는 여러 종족의 말을 알아듣는다." })
add({ id = "families5", cat = "dex", name = "야수 관찰자", desc = "야수 계통 5종 발견", goal = 5, icon = I .. "Ability_Hunter_BeastTaming",
	progress = field("families"), flavor = "늑대, 거미, 멧돼지… 야생은 생각보다 훨씬 다채롭다." })
add({ id = "families12", cat = "dex", name = "야생의 친구", desc = "야수 계통 12종 발견", goal = 12, icon = I .. "Ability_Hunter_BeastTaming",
	progress = field("families"), flavor = "어떤 사냥꾼보다 많은 짐승의 이름을 알고 있다." })
add({ id = "critters10", cat = "dex", name = "작은 친구들", desc = "작은 동물 10종 발견", goal = 10, icon = I .. "Spell_Nature_Polymorph",
	progress = field("critters"), flavor = "모험이 늘 피와 칼로만 이루어지는 것은 아니다." })
add({ id = "worldboss", cat = "dex", name = "거인 사냥꾼", desc = "우두머리급 존재 처치", goal = 1, points = 25, icon = I .. "INV_Misc_Head_Dragon_01",
	progress = field("worldBossKills"), flavor = "산처럼 거대한 존재가 무너지던 그날의 굉음을 잊지 못한다." })
for _, t in ipairs({
	{ "murloc", "므르글!", "멀록 100마리 처치" }, { "gnoll", "하이에나 웃음은 이제 그만", "놀 100마리 처치" },
	{ "kobold", "양초는 내가 가져간다", "코볼트 100마리 처치" }, { "defias", "붉은 두건 사냥꾼", "데피아즈 형제단 100명 처치" },
	{ "scarlet", "광신의 끝", "붉은십자군 100명 처치" }, { "undead", "안식을 주는 자", "언데드 100마리 처치" },
}) do
	add({ id = "tk_" .. t[1], cat = "dex", name = t[2], desc = t[3], goal = 100, icon = (ns.TRIBE_BY_ID[t[1]] or {}).icon or I .. "Ability_Warrior_BattleShout",
		progress = function(ctx) return ctx.tribeKills[t[1]] or 0 end, flavor = "백 번째 싸움이 끝나자, 그들의 무리가 내 이름을 수군대기 시작했다." })
end

------------------------------------------------------------------------
-- 전장 (계급·평판은 Forever 레거시 도전 과제에 있으므로 참전 기록만)
------------------------------------------------------------------------
for _, b in ipairs({ { 1, "첫 참전", "나팔 소리와 함께 처음으로 전장에 섰다." }, { 10, "전장의 단골", "전투 지휘관이 내 이름을 부른다." },
	{ 50, "백전노장", "전장의 흙냄새가 이제는 고향 냄새 같다." } }) do
	add({ id = "bg" .. b[1], cat = "pvp", name = b[2], desc = "전장 " .. b[1] .. "회 참전", goal = b[1], icon = I .. "Ability_DualWield",
		progress = field("bgTotal"), flavor = b[3] })
end
for _, bg in ipairs(ns.CLASSIC_BATTLEGROUNDS) do
	add({ id = "bgm" .. bg.map, cat = "pvp", name = bg.name .. "의 병사", desc = bg.name .. "에 참전하기", goal = 1, icon = I .. "Ability_Warrior_BattleShout",
		progress = function(ctx) return ctx.bgMaps[bg.map] or ctx.bgNames[bg.name] or 0 end, flavor = bg.name .. "의 함성 속에 내 목소리도 섞여 있었다." })
end

------------------------------------------------------------------------
-- 평판
------------------------------------------------------------------------
for _, r in ipairs({ { 1, "누군가의 영웅", "한 세력이 나를 형제처럼 받아들였다." }, { 3, "여러 깃발 아래", "세 세력이 나를 영웅이라 부른다." },
	{ 5, "모두의 친구", "어느 세력의 진영에 가도 환대를 받는다." }, { 10, "아제로스의 대사", "열 개의 세력이 나를 최고의 벗으로 여긴다." } }) do
	add({ id = "exalted" .. r[1], cat = "rep", name = r[2], desc = "평판 확고한 동맹 " .. r[1] .. "개", goal = r[1], points = r[1] >= 5 and 25 or 10,
		icon = I .. "Spell_Holy_HolyBolt", progress = field("exalted"), flavor = r[3] })
end

------------------------------------------------------------------------
-- 시련
------------------------------------------------------------------------
add({ id = "death1", cat = "trial", name = "죽음은 끝이 아니다", desc = "처음으로 쓰러지기", goal = 1, points = 5, icon = I .. "Spell_Shadow_DeathScream",
	progress = field("deaths"), flavor = "차가운 영혼의 길을 처음 걸었다. 돌아왔을 때, 세상이 조금 다르게 보였다." })
add({ id = "death25", cat = "trial", name = "영혼의 치유사 단골", desc = "25번 쓰러지기", goal = 25, points = 5, icon = I .. "Spell_Holy_Resurrection",
	progress = field("deaths"), flavor = "영혼의 치유사가 이제 나를 보면 한숨부터 쉰다." })
add({ id = "death100", cat = "trial", name = "불사조", desc = "100번 쓰러지기", goal = 100, points = 10, icon = I .. "Spell_Fire_Fire",
	progress = field("deaths"), flavor = "백 번 쓰러지고 백 번 일어났다. 그게 나다." })
for _, lv in ipairs({ 10, 20, 30, 40, 50, 60 }) do
	add({ id = "deathless" .. lv, cat = "trial", name = "흔들림 없는 발걸음 " .. lv, desc = "기록이 시작된 뒤 한 번도 쓰러지지 않고 " .. lv .. "레벨 도달",
		goal = 1, points = lv >= 40 and 25 or 10, icon = I .. "Spell_Holy_DivineIntervention",
		progress = function(ctx) return ctx.deathless[lv] and 1 or 0 end,
		flavor = lv .. "레벨이 될 때까지 단 한 번도 무릎 꿇지 않았다." })
end

------------------------------------------------------------------------
-- 연대기
------------------------------------------------------------------------
for _, n in ipairs({ { 1, "첫 문장", 5, "펜을 들었다. 내 이야기를 내 손으로 쓰기 시작했다." }, { 10, "작가의 습관", 10, "하루를 마치면 일지를 펴는 것이 습관이 되었다." },
	{ 50, "모험 작가", 25, "이 전기는 이제 나만의 문장으로 가득하다." } }) do
	add({ id = "note" .. n[1], cat = "chronicle", name = n[2], desc = "나만의 기록 " .. n[1] .. "개 남기기", goal = n[1], points = n[3],
		icon = I .. "INV_Scroll_03", progress = field("notes"), flavor = n[4] })
end
for _, n in ipairs({ { 100, "두꺼워진 전기", "어느새 백 줄. 내 이야기가 이렇게 길어졌다." }, { 500, "대하소설", "누군가 이 전기를 읽는다면 밤을 새워야 하리라." },
	{ 1000, "살아 있는 역사서", "천 줄의 기록. 이것은 한 사람의 역사이자, 아제로스의 역사다." } }) do
	add({ id = "log" .. n[1], cat = "chronicle", name = n[2], desc = "전기에 기록 " .. ns.Comma(n[1]) .. "개 쌓기", goal = n[1],
		icon = I .. "INV_Misc_Book_09", progress = field("logCount"), flavor = n[3] })
end
add({ id = "export1", cat = "chronicle", name = "필사본", desc = "전기를 내보내기로 옮겨 적기", goal = 1, points = 5, icon = I .. "INV_Scroll_05",
	progress = field("exported"), flavor = "전기를 옮겨 적었다. 이 이야기는 이제 게임 밖에서도 살아 숨 쉰다." })

ns.ACH_BY_ID = {}
for _, a in ipairs(list) do ns.ACH_BY_ID[a.id] = a end
