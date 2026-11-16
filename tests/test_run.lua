-- Scenario test for BIG CHRONICLE in the WoW mock
-- 사용법 (저장소 루트에서):  lua5.1 tests/test_run.lua
local here = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local scratch = arg[1] or here
local addonDir = arg[2] or (here .. "/../BigChronicle")
package.path = scratch .. "/?.lua;" .. package.path
local M = require("mockwow")
math.randomseed(1)

local failures = 0
local function check(cond, msg)
	if cond then print("  ok   " .. msg) else failures = failures + 1; print("  FAIL " .. msg) end
end

local ns = M.load(addonDir)
local S = M.state

-- login (예전에 저장된 테마 설정은 지워진다)
BigChronicleDB = { settings = { theme = "dark" } }
M.fire("ADDON_LOADED", "BigChronicle")
M.fire("PLAYER_LOGIN")
M.fire("PLAYER_ENTERING_WORLD", true, false)
M.runTimers()

local db = ns.char
print("== start")
check(db.log[1] and db.log[1].cat == "start", "first entry recorded")
check(#db.log == 2 and db.log[2].cat == "achievement", "achievements already earned before install are summarized in one line")
print("    " .. ns.StripCodes(db.log[1].text))
check(ns.StripCodes(db.log[1].text):find("^32레벨, 가시덤불 골짜기에서 첫 모험을 시작했다%.") ~= nil, "start sentence matches example")

-- josa
print("== josa")
check(ns.Josa("가시덤불 골짜기", "를") == "가시덤불 골짜기를", "골짜기를")
check(ns.Josa("잊혀진 땅", "을") == "잊혀진 땅을", "땅을")
check(ns.Josa("「호거」", "을") == "「호거」를", "quoted 호거를")
check(ns.Josa("무법항", "으로") == "무법항으로", "무법항으로")
check(ns.Josa("서부 몰락지대", "으로") == "서부 몰락지대로", "몰락지대로")
check(ns.Josa("그늘숲", "로") == "그늘숲으로", "그늘숲으로")
check(ns.Josa("레벨 1", "이") == "레벨 1이", "digit batchim")
check(ns.Josa("Westfall", "을") == "Westfall을(를)", "latin fallback")
check(ns.Josa("늑대", "이라도") == "늑대라도", "늑대라도")
check(ns.Josa("곰", "이라도") == "곰이라도", "곰이라도")

-- zone change
print("== zone")
S.zone, S.sub = "잊혀진 땅", "니젤의 야영지"
M.fire("ZONE_CHANGED_NEW_AREA")
check(db.zones["잊혀진 땅"] ~= nil, "new zone saved")
local last2 = {}
for i = #db.log - 1, #db.log do last2[#last2 + 1] = ns.StripCodes(db.log[i].text) end
print("    " .. table.concat(last2, "\n    "))
check(db.log[#db.log].cat == "subzone", "subzone logged after zone")

-- level up
print("== level")
M.advance(3600)
S.level = 33
M.fire("PLAYER_LEVEL_UP", 33)
print("    " .. ns.StripCodes(db.log[#db.log].text))
check(db.log[#db.log].cat == "level" and db.log[#db.log].lvl == 33, "level entry")
S.level = 40
M.fire("PLAYER_LEVEL_UP", 40)
print("    " .. ns.StripCodes(db.log[#db.log].text))
check(ns.StripCodes(db.log[#db.log].text):find("탈것") ~= nil, "milestone 40 text")

-- quest
print("== quest")
M.questTitles = { [1234] = "켄타우로스의 위협" }
M.fire("QUEST_TURNED_IN", 1234, 2450, 12345)
print("    " .. ns.StripCodes(db.log[#db.log].text))
check(db.quests.count == 1, "quest counted")
M.questFrameID, M.questFrameTitle = 999, "잃어버린 편지"
M.fire("QUEST_COMPLETE")
M.fire("QUEST_TURNED_IN", 999, 0, 0)
check(ns.StripCodes(db.log[#db.log].text):find("잃어버린 편지") ~= nil, "quest title from cache")

-- bestiary discovery
print("== bestiary")
local magram = M.mob("마그람 약탈자", 4640, "인간형", { level = 33 })
M.setUnit("target", magram)
M.fire("PLAYER_TARGET_CHANGED")
local c = ns.Bestiary.dex.creatures["마그람 약탈자"]
check(c ~= nil and c.tribe == "centaur", "centaur classified by keyword (마그람)")
print("    " .. ns.StripCodes(db.log[#db.log].text))
check(db.log[#db.log].cat == "dex", "new tribe journal entry")

-- prefix learning: english gnolls
local g1 = M.mob("Riverpaw Gnoll", 117, "Humanoid")
M.setUnit("mouseover", g1)
M.fire("UPDATE_MOUSEOVER_UNIT")
check(ns.Bestiary.dex.creatures["Riverpaw Gnoll"].tribe == "gnoll", "Riverpaw Gnoll -> gnoll")
-- korean gnoll token
local g2 = M.mob("강바닥발톱 놀", 118, "인간형")
M.setUnit("mouseover", g2); M.fire("UPDATE_MOUSEOVER_UNIT")
local g3 = M.mob("강바닥발톱 잡종개", 119, "인간형")
M.setUnit("mouseover", g3); M.fire("UPDATE_MOUSEOVER_UNIT")
check(ns.Bestiary.dex.creatures["강바닥발톱 잡종개"].tribe == "gnoll", "prefix-learned 강바닥발톱 잡종개 -> gnoll")
-- reclassify existing on learn
local h1 = M.mob("어둠가죽 주술사", 120, "인간형")
M.setUnit("mouseover", h1); M.fire("UPDATE_MOUSEOVER_UNIT")
check(ns.Bestiary.dex.creatures["어둠가죽 주술사"].tribe == "humanoid", "unknown humanoid -> 기타 인간형")
local h2 = M.mob("어둠가죽 놀", 121, "인간형")
M.setUnit("mouseover", h2); M.fire("UPDATE_MOUSEOVER_UNIT")
check(ns.Bestiary.dex.creatures["어둠가죽 주술사"].tribe == "gnoll", "existing creature moved after prefix learned")
-- "놀" exact token only
local n1 = M.mob("놀라운 마법사", 122, "인간형")
M.setUnit("mouseover", n1); M.fire("UPDATE_MOUSEOVER_UNIT")
check(ns.Bestiary.dex.creatures["놀라운 마법사"].tribe ~= "gnoll", "'놀라운' is not a gnoll")

-- beast family dynamic tribe
local wolf = M.mob("굶주린 회색늑대", 525, "야수", { family = "늑대" })
M.setUnit("target", wolf); M.fire("PLAYER_TARGET_CHANGED")
check(ns.Bestiary.dex.creatures["굶주린 회색늑대"].tribe == "beast:늑대", "beast family tribe")
check(ns.Bestiary:FormatNo("beast:늑대") == string.format("No.%03d", #ns.TRIBES + 1), "dynamic tribe number")
local def = ns.GetTribe("beast:늑대")
print("    lore2: " .. def.lore[2])
-- dragonkin by type
local whelp = M.mob("검은 새끼용", 7047, "용족")
M.setUnit("target", whelp); M.fire("PLAYER_TARGET_CHANGED")
check(ns.Bestiary.dex.creatures["검은 새끼용"].tribe == "dragonkin", "dragonkin by type")
-- excluded: guard with faction
local guard = M.mob("오그리마 경비병", 3296, "인간형", { faction = "Horde" })
M.setUnit("target", guard); M.fire("PLAYER_TARGET_CHANGED")
check(ns.Bestiary.dex.creatures["오그리마 경비병"] == nil, "faction guard excluded")
-- friendly excluded
local vendor = M.mob("상인", 1, "인간형", { friendly = true })
M.setUnit("target", vendor); M.fire("PLAYER_TARGET_CHANGED")
check(ns.Bestiary.dex.creatures["상인"] == nil, "friendly npc excluded")
-- totem excluded
local totem = M.mob("수호의 토템", 2, "토템")
M.setUnit("target", totem); M.fire("PLAYER_TARGET_CHANGED")
check(ns.Bestiary.dex.creatures["수호의 토템"] == nil, "totem excluded")

-- rare
local rare = M.mob("늙은 바위턱", 1000, "인간형", { cls = "rare", level = 35 })
M.setUnit("target", rare); M.fire("PLAYER_TARGET_CHANGED")
local gotRare=false; for i=math.max(1,#db.log-3),#db.log do if db.log[i].cat=="rare" then gotRare=true end end
check(gotRare, "rare journal entry")
print("    " .. ns.StripCodes(db.log[#db.log].text))

-- 비행 조련사로 날아가는 동안에는 지역도 몬스터도 발견되지 않는다
print("== flight path")
do
	local logN = #db.log
	local homeZone, homeSub = S.zone, S.sub
	S.onTaxi = true
	S.zone, S.sub = "버섯구름 봉우리", "얼음바람 야영지"
	M.fire("ZONE_CHANGED_NEW_AREA"); M.fire("ZONE_CHANGED")
	check(db.zones["버섯구름 봉우리"] == nil, "no zone discovered while flying")
	check(db.subzones["버섯구름 봉우리|얼음바람 야영지"] == nil, "no subzone discovered while flying")
	local wyvernView = M.mob("하늘에서 본 켄타우로스", 4000, "인간형", { level = 30 })
	M.setUnit("target", wyvernView); M.fire("PLAYER_TARGET_CHANGED")
	M.setUnit("mouseover", wyvernView); M.fire("UPDATE_MOUSEOVER_UNIT")
	check(ns.Bestiary.dex.creatures["하늘에서 본 켄타우로스"] == nil, "no creature discovered while flying")
	check(#db.log == logN, "nothing written to the journal while flying")
	-- 내린 곳은 직접 밟은 땅이니 기록된다
	S.zone, S.sub = "잊혀진 땅", "그림자 그늘 마을"
	S.onTaxi = false
	M.fire("PLAYER_CONTROL_GAINED")
	check(db.subzones["잊혀진 땅|그림자 그늘 마을"] ~= nil, "landing spot is recorded after the flight")
	check(db.zones["버섯구름 봉우리"] == nil, "zones flown over stay undiscovered")
	M.setUnit("mouseover", nil)
	S.zone, S.sub = homeZone, homeSub
	M.fire("ZONE_CHANGED_NEW_AREA")
end

-- kills: death detection + xp dedupe
print("== kills")
M.advance(10)
magram.dead = true
M.fire("UNIT_HEALTH", "target")  -- target is the rare now; set target back
M.setUnit("target", magram)
magram.dead = false
M.advance(5); M.fire("PLAYER_TARGET_CHANGED") -- rescan alive
magram.dead = true
M.fire("UNIT_HEALTH", "target")
check(ns.Bestiary.dex.creatures["마그람 약탈자"].kills == 1, "death detection kill")
M.fire("CHAT_MSG_COMBAT_XP_GAIN", "마그람 약탈자를 처치하여 경험치를 450 획득했습니다.")
check(ns.Bestiary.dex.creatures["마그람 약탈자"].kills == 1, "xp message deduped with death detection")
M.advance(10)
M.fire("CHAT_MSG_COMBAT_XP_GAIN", "마그람 약탈자를 처치하여 경험치를 450 획득했습니다. (+45 파티 보너스)")
check(ns.Bestiary.dex.creatures["마그람 약탈자"].kills == 2, "xp group message counted")
M.fire("CHAT_MSG_COMBAT_XP_GAIN", "처음보는 몬스터를 처치하여 경험치를 100 획득했습니다.")
check(ns.Bestiary.dex.pending["처음보는 몬스터"] == 1, "unknown kill pending")
M.advance(10)
M.fire("CHAT_MSG_COMBAT_XP_GAIN", "마그람 약탈자|1을;를; 처치하여 경험치를 450 획득했습니다.")
check(ns.Bestiary.dex.creatures["마그람 약탈자"].kills == 3, "unresolved grammar code handled")
-- mass kills to trigger milestone/rank
for i = 1, 150 do
	M.advance(5)
	M.fire("CHAT_MSG_COMBAT_XP_GAIN", "마그람 약탈자를 처치하여 경험치를 450 획득했습니다.")
end
local foundMilestone, foundRank = false, false
for _, e in ipairs(db.log) do
	if e.cat == "milestone" then
		local t = ns.StripCodes(e.text)
		print("    " .. t)
		if t:find("50마리째") then foundMilestone = true end
		if t:find("관찰자") then foundRank = true end
	end
end
check(foundMilestone, "kill milestone 50마리")
check(foundRank, "rank up to 관찰자")

-- dungeon expedition
print("== dungeon")
S.inInstance, S.instanceType, S.instanceName, S.group = true, "party", "마라우돈", 5
M.fire("PLAYER_ENTERING_WORLD", false, false)
print("    " .. ns.StripCodes(db.log[#db.log].text))
check(db.expedition ~= nil, "expedition started")
M.tick(30)
M.fire("ENCOUNTER_END", 422, "노크세온", 1, 5, 1)
M.fire("BOSS_KILL", 422, "노크세온")
check(#db.expedition.bosses == 1, "boss counted once")
print("    " .. ns.StripCodes(db.log[#db.log].text))
M.fire("ENCOUNTER_END", 423, "공주 테라드라스", 1, 5, 0)
M.fire("PLAYER_DEAD")
print("    " .. ns.StripCodes(db.log[#db.log].text))
-- leave (ghost run) and come back
S.inInstance, S.instanceType = false, "none"
S.zone = "잊혀진 땅"
M.fire("PLAYER_ENTERING_WORLD", false, false)
check(db.expedition ~= nil and db.expedition.left ~= nil, "expedition paused while outside")
M.tick(6)
S.inInstance, S.instanceType = true, "party"
M.fire("PLAYER_ENTERING_WORLD", false, false)
check(db.expedition ~= nil and db.expedition.left == nil, "expedition resumed")
M.tick(30)
M.fire("ENCOUNTER_END", 423, "공주 테라드라스", 1, 5, 1)
S.inInstance, S.instanceType = false, "none"
M.fire("PLAYER_ENTERING_WORLD", false, false)
M.tick(100) -- > 15 min
check(db.expedition == nil, "expedition ended after grace")
print("    " .. ns.StripCodes(db.log[#db.log].text))
local endedEntry = false
for i = math.max(1, #db.log - 10), #db.log do if db.log[i].ended then endedEntry = true end end
check(endedEntry, "expedition end entry")

-- battleground
S.inInstance, S.instanceType, S.instanceName = true, "pvp", "전쟁노래 협곡"
M.fire("PLAYER_ENTERING_WORLD", false, false)
check(db.log[#db.log].cat == "pvp", "pvp entry")
S.inInstance, S.instanceType = false, "none"
M.fire("PLAYER_ENTERING_WORLD", false, false)

-- money
print("== money")
S.money = 2000000 -- 200g (already had 123g at start)
M.fire("PLAYER_MONEY")
local moneyEntries = 0
for _, e in ipairs(db.log) do if e.cat == "money" then moneyEntries = moneyEntries + 1; print("    " .. ns.StripCodes(e.text)) end end
check(moneyEntries == 0, "no money entry below new threshold (250g)")
S.money = 2600000
M.fire("PLAYER_MONEY")
check(db.log[#db.log].cat == "money", "250g milestone")
print("    " .. ns.StripCodes(db.log[#db.log].text))

-- hearth
M.fire("HEARTHSTONE_BOUND")
print("    " .. ns.StripCodes(db.log[#db.log].text))
check(db.log[#db.log].cat == "bind", "bind entry")

-- note via slash
SlashCmdList["BIGCHRONICLE"]("기록 오늘 처음으로 그리핀을 탔다 |cffff0000hack|r")
print("    " .. db.log[#db.log].text)
check(db.log[#db.log].cat == "note", "note via slash")
SlashCmdList["BIGCHRONICLEJOURNAL"]("두 번째 메모")
check(db.log[#db.log].text:find("두 번째 메모") ~= nil, "/일지 note")

-- tooltip
M.tooltipUnitName, M.tooltipUnit = "마그람 약탈자", "mouseover"
M.setUnit("mouseover", magram)
GameTooltip.lines = {}
ns.Bestiary:AddTooltipInfo(GameTooltip)
print("    tooltip: " .. tostring(GameTooltip.lines[1]))
check(GameTooltip.lines[1] ~= nil, "tooltip line")

-- reassign
ns.Bestiary:SetTribe("놀라운 마법사", "defias")
check(ns.Bestiary.dex.creatures["놀라운 마법사"].tribe == "defias", "manual reassign")
check(ns.Bestiary.dex.tribes["defias"] ~= nil, "reassign creates tribe entry")
ns.Bestiary:SetTribe("놀라운 마법사", nil)
check(ns.Bestiary.dex.creatures["놀라운 마법사"].tribe == "humanoid", "auto reclassify")

-- UI
print("== UI")
local ok, err = pcall(function()
	SlashCmdList["BIGCHRONICLE"]("")
	M.runTimers()
	for _, tab in ipairs({ "journal", "bestiary", "stats", "settings" }) do
		ns.UI:SelectTab(tab)
	end
	local D = ns.BestiaryTab
	D.sel = { kind = "tribe", id = "centaur" }; D:Refresh()
	D.species = "마그람 약탈자"; D:RefreshCard(); D:RefreshDetail()
	D.sel = { kind = "tribe", id = "beast:늑대" }; D:Refresh()
	D.sel = { kind = "tribe", id = "naga" }; D:Refresh()
	D.sel = { kind = "rares" }; D:Refresh()
	D.sel = { kind = "recent" }; D:Refresh()
	D.searchBox:SetText("놀"); D.searchBox:Fire("OnTextChanged", true); D:Refresh()
	D:ShowReassign("마그람 약탈자")
	local J = ns.JournalTab
	J.chapter = 4; J:Refresh()
	J.chapter = 0; J.page = 1; J:Refresh(true)
	ns.db.newestFirst = true; J.page = nil; J:Refresh()
	J.note:SetText("UI로 남긴 기록"); J.note:Fire("OnEnterPressed")
	ns.UI:ShowExport()
	ns.Minimap.button:Fire("OnEnter")
	ns.Minimap.button:Fire("OnClick", "RightButton")
	ns.Toast:Show("테스트", "본문", nil, "rare")
	ns.Toast.frame:Fire("OnUpdate", 10)
	ns.Toast.frame:Fire("OnUpdate", 10)
	-- settings toggles
	for _, cb in ipairs(ns.SettingsTab.checks) do cb:SetChecked(not cb:GetChecked()); cb:Fire("OnClick") end
	for _, cb in ipairs(ns.SettingsTab.checks) do cb:SetChecked(not cb:GetChecked()); cb:Fire("OnClick") end
	BigChronicle_OnAddonCompartmentClick("BigChronicle", "LeftButton")
	-- 알림을 누르면 그 몬스터 / 업적 페이지로 간다
	ns.db.toast = true
	ns.Toast.queue = {}
	if ns.Toast.frame then ns.Toast.frame:Hide() end
	ns.Toast:Show("도감 등록", "켄타우로스 · 마그람 약탈자", nil, "species", { creature = "마그람 약탈자" })
	ns.Toast.frame:Fire("OnMouseUp", "LeftButton")
	assert(ns.UI.current == "bestiary", "toast click opens bestiary")
	assert(ns.BestiaryTab.sel.kind == "tribe" and ns.BestiaryTab.sel.id == "centaur", "toast click selects the creature's tribe")
	assert(ns.BestiaryTab.species == "마그람 약탈자", "toast click selects the creature")
	ns.Toast.frame:Hide()
	ns.Toast:Show("업적 달성!", "「모험의 첫 장」", nil, "achievement", { ach = "level10" })
	ns.Toast.frame:Fire("OnMouseUp", "LeftButton")
	assert(ns.UI.current == "achievements" and ns.AchievementsTab.cat == "growth", "toast click opens the achievement's category")
	-- hotkeys / typewriter
	ns.UI:Open("bestiary")
	local f = ns.UI.frame
	f:Fire("OnKeyDown", "DOWN"); f:Fire("OnKeyDown", "DOWN"); f:Fire("OnKeyDown", "UP")
	assert(ns.BestiaryTab.sel.kind == "tribe", "arrow selects tribe")
	ns.BestiaryTab:SelectTribe("centaur")
	assert(ns.UI.IsTyping(), "lore typewriter running")
	M.runOnUpdate(0.05)
	f:Fire("OnKeyDown", "SPACE")
	assert(not ns.UI.IsTyping(), "space finishes typing")
	f:Fire("OnKeyDown", "1"); assert(ns.UI.current == "journal", "key 1 -> journal")
	f:Fire("OnKeyDown", "LEFT"); f:Fire("OnKeyDown", "RIGHT")
	f:Fire("OnKeyDown", "3"); assert(ns.UI.current == "achievements", "key 3 -> achievements")
	f:Fire("OnKeyDown", "4"); assert(ns.UI.current == "stats", "key 4 -> stats")
	f:Fire("OnKeyDown", "5"); assert(ns.UI.current == "settings", "key 5 -> settings")
	M.inCombat = true; f:Fire("OnKeyDown", "2"); assert(ns.UI.current == "settings", "no hotkeys in combat"); M.inCombat = false
	for i = 1, 40 do M.runOnUpdate(0.1) end
	-- new entry while journal open fades in
	ns.UI:SelectTab("journal")
	ns.Chronicle:AddNote("열린 창에서 추가된 기록")
	M.runTimers()
end)
check(ok, "UI flows ran without error " .. tostring(err))
local uiNote = false
for i = math.max(1, #db.log - 3), #db.log do if db.log[i].text:find("UI로 남긴 기록") then uiNote = true end end
check(uiNote, "note via UI")
local openNote = false
for i = math.max(1, #db.log - 3), #db.log do if db.log[i].text:find("열린 창에서 추가된 기록") then openNote = true end end
check(openNote, "note while window open")
local exportText = ns.UI.exportFrame.text
check(exportText:find("■ 제4장") ~= nil, "export has chapters")
print("---- export excerpt ----")
local n = 0
for line in exportText:gmatch("[^\n]+") do n = n + 1; if n <= 40 then print(line) end end

-- 연출
print("== effects")
local okFx, errFx = pcall(function()
	local function run(sec) for _ = 1, math.floor(sec / 0.05) do M.runOnUpdate(0.05) end end
	local f = ns.UI.frame
	f:Hide(); ns.db.effects = true
	-- 창이 닫혀 있을 때 생긴 소식 → 미니맵 버튼이 빛난다
	ns.Chronicle:Add("rare", "테스트 희귀 소식")
	assert((ns.Minimap.news or 0) >= 1 and ns.Minimap.button.glow:IsShown(), "minimap glows for news")
	ns.UI:Open("journal")
	assert((ns.Minimap.news or 0) == 0 and not ns.Minimap.button.glow:IsShown(), "opening clears news")
	-- 표지 로고 화면은 없다: 창이 바로 열린다
	assert(f.cover == nil and f:IsShown(), "the book opens without a logo cover")
	-- 장 제목 카드
	ns:Fire("CHAPTER_STARTED", 2)
	local card = _G.BigChronicleChapterCard
	assert(card and card:IsShown(), "chapter card shown")
	assert(card.title:GetText() == "모험가의 길", "chapter card title: " .. tostring(card.title:GetText()))
	run(7)
	assert(not card:IsShown(), "chapter card hides")
	-- 업적 알림: 도장 + 반짝이
	ns.Toast.queue = {}; ns.Toast.frame:Hide()
	ns.Toast:Show("업적 달성!", "「테스트」", nil, "achievement", { ach = "level10" })
	run(0.5)
	assert(ns.Toast.frame.seal:IsShown(), "achievement toast stamps a seal")
	assert(ns.Toast.frame.seal.kind == "ach", "achievement toast uses the laurel seal")
	assert(_G.BigChronicleFX ~= nil, "particles burst")
	run(8)
	-- 도감 발견 알림에도 붉은 밀랍 인장이 찍힌다 (종족·개체·희귀·연구 등급 모두)
	for _, kind in ipairs({ "tribe", "species", "rare", "rank" }) do
		ns.Toast.queue = {}; ns.Toast.frame:Hide()
		ns.Toast:Show("새로운 발견!", "테스트 개체", nil, kind, { tribe = "centaur" })
		assert(not ns.Toast.frame.seal:IsShown(), kind .. " toast: seal waits until the note lands")
		run(0.6)
		assert(ns.Toast.frame.seal:IsShown(), kind .. " toast stamps a wax seal")
		assert(ns.Toast.frame.seal.kind == "dex", kind .. " toast uses the bestiary seal")
		run(8)
	end
	-- 도감: 처음 펼치면 '본 페이지'가 되지만, 도장은 찍지 않는다 (인장은 발견 알림에서만)
	local B = ns.Bestiary
	B.dex.tribes.centaur.viewed = nil
	ns.UI:SelectTab("bestiary")
	ns.BestiaryTab:SelectTribe("centaur")
	assert(B.dex.tribes.centaur.viewed and ns.BestiaryTab.stamp == nil, "first view marks the page seen without a stamp")
	-- 일지: 장을 바꾸면 곧바로 바뀐다 (책장 넘김 연출 없음)
	ns.UI:SelectTab("journal")
	local J = ns.JournalTab
	J.chapter = 0; J:Refresh()
	J.chapterButtons[2].onClick()
	assert(J.chapter == 2, "chapter switches at once")
	J.chapterButtons[3].onClick(); J.chapterButtons[4].onClick(); J.chapterButtons[0].onClick()
	assert(J.chapter == 0, "rapid chapter clicks settle on the last one")
	J.chapter = 0; J:Refresh()
	-- 업적 NEW: 3초만 반짝이고 멈춘다, 다시 그려도 다시 깜빡이지 않는다
	ns.char.ach.unseen = { level10 = true }
	ns.UI:SelectTab("achievements")
	ns.AchievementsTab.cat = "growth"; ns.AchievementsTab:Refresh(true)
	local row
	for _, r in ipairs(ns.AchievementsTab.pool.items) do if r:IsShown() and r.def and r.def.id == "level10" then row = r end end
	assert(row and row.newTag:IsShown() and row.glow:IsShown(), "new achievement shows NEW and glows")
	run(1)
	local mid = row.glow:GetAlpha()
	run(3)
	assert(math.abs(row.glow:GetAlpha() - 0.35) < 0.001, "blink stops after 3 seconds (alpha " .. tostring(row.glow:GetAlpha()) .. ")")
	ns.AchievementsTab:Refresh()
	run(1)
	assert(math.abs(row.glow:GetAlpha() - 0.35) < 0.001 and row.newTag:IsShown(), "refresh does not restart the blink")
	ns.UI:SelectTab("journal")
	assert(next(ns.AchievementsTab.sessionNew) == nil, "leaving the tab clears NEW")
	-- 연출을 끄면 바로 펼쳐진다
	ns.db.effects = false
	f:Hide(); ns.UI:Open("journal")
	assert(f:IsShown(), "opens when effects are off")
	ns:Fire("CHAPTER_STARTED", 3)
	ns.db.effects = true
end)
check(okFx, "effects run without error " .. tostring(errFx))

print("== theme: " .. tostring(ns.UI.themeId))
local themed = ns.UI:Themed("|cffe6c27a잊혀진 땅|r")
print("    themed: " .. themed)
check(ns.UI.themeId == "light" and ns.db.theme == nil, "parchment is the only theme")
check(themed:find("8a5a12") ~= nil, "parchment theme remaps colors")

-- reset
-- 알림 위치: 잠금을 풀면 예시 알림을 끌어 옮기고, 오른쪽 클릭으로 잠근다
print("== toast position")
do
	local T = ns.Toast
	ns.db.toast = true
	T.queue = {}
	if T.frame then T.frame:Hide() end
	check(ns.db.toastLocked == true, "toast position starts locked")
	T:SetLocked(false)
	check(T.moving and T.frame:IsShown() and T.frame.title:GetText() == "알림 위치", "unlocking shows a sample toast to drag")
	T:Show("업적 달성!", "「테스트」", nil, "achievement")
	check(#T.queue == 1 and T.frame.title:GetText() == "알림 위치", "real toasts wait while moving")
	T.frame:Fire("OnUpdate", 30)
	check(T.frame:IsShown(), "the sample toast stays until locked")
	T.frame:Fire("OnDragStart")
	T.frame:Fire("OnDragStop")
	local pos = ns.db.toastPos
	check(type(pos) == "table" and pos.x and pos.y, "dragging saves the position")
	T.frame:Fire("OnMouseUp", "LeftButton")    -- 끌기를 마친 왼쪽 버튼
	T.frame:Fire("OnMouseUp", "RightButton")   -- 오른쪽 클릭으로 잠그기
	check(not T.moving and ns.db.toastLocked == true, "right click locks the position")
	check(T.frame:IsShown() and T.frame.title:GetText() == "업적 달성!", "queued toast shows after locking")
	local p = T.frame.__points[#T.frame.__points]
	check(p and p[1] == "TOP" and p[4] == pos.x, "toast uses the saved position")
	for _ = 1, 4 do T.frame:Fire("OnUpdate", 30) end   -- 앞의 알림을 끝낸다
	check(not T.frame:IsShown(), "earlier toast finished")
	ns.db.toastPos = { x = 120, y = -300 }
	T:ResetPosition()
	check(ns.db.toastPos == nil, "position reset")
	local rp = T.frame.__points[#T.frame.__points]
	check(rp and rp[4] == 0 and rp[5] <= -100, "toast goes back to the top center")
	check(T.frame:IsShown() and T.frame.sample and T.frame.title:GetText() == "알림 위치", "a sample toast shows the default spot")
	ns.UI:SelectTab("settings")
	T.frame:Fire("OnMouseUp", "LeftButton")
	check(ns.UI.current == "settings" and not T.frame:IsShown(), "clicking the sample just closes it")
	ns.db.toastPos = { x = 50, y = -200 }
	ns:HandleSlash("알림 초기화")
	check(ns.db.toastPos == nil, "/bc 알림 초기화 resets the position")
	T.frame:Hide(); T.queue = {}
	ns:HandleSlash("알림")
	check(T.moving, "/bc 알림 unlocks")
	ns:HandleSlash("알림")
	check(not T.moving, "/bc 알림 locks again")
	T.frame:Hide(); T.queue = {}
end

-- 업적은 계정 공용: 본캐가 이룬 업적은 부캐에서도 달성으로 보인다
print("== account-wide achievements")
do
	local A = ns.Achievements
	A:Evaluate()   -- 본캐의 판정을 먼저 마친다
	local acc = A:Account().done
	local n, anyId = 0, nil
	for id, e in pairs(acc) do n = n + 1; anyId = anyId or id end
	check(n > 0 and acc[anyId].by == "테스트용사", "earned achievements are stored for the account with who earned them")
	local mainDone = A:Summary()
	check(mainDone == n, "summary counts the account record")
	-- 부캐릭터로 접속한 것처럼: 이 캐릭터의 업적 기록을 비우고 이름을 바꾼다
	local realAch, realName = ns.char.ach, UnitName
	local seen = {}
	for k in pairs(realAch.seen or {}) do seen[k] = true end
	ns.char.ach = { done = {}, retro = {}, flags = {}, initialized = true, sig = ns.ACH_SIGNATURE }
	UnitName = function(u) if u == "player" then return "부캐릭터" end return realName(u) end
	local logN = #ns.char.log
	A:Evaluate()
	check(#ns.char.log == logN, "the alt does not re-announce achievements the main already earned")
	check(A:Summary() == n and A:Earned(anyId) ~= nil, "the alt sees the main's achievements as earned")
	check(ns.char.ach.done[anyId] == nil, "the alt's own record stays empty")
	ns.UI:SelectTab("achievements")
	ns.AchievementsTab.cat = nil; ns.AchievementsTab.filter = "done"; ns.AchievementsTab:Refresh(true)
	local tagged = false
	for _, r in ipairs(ns.AchievementsTab.pool.items) do
		if r:IsShown() and r.done and (r.when:GetText() or ""):find("테스트용사", 1, true) then tagged = true end
	end
	check(tagged, "rows show which character earned it")
	ns.AchievementsTab.filter = "all"
	-- 예전 버전의 캐릭터별 기록은 접속할 때 계정 기록에 합쳐진다
	UnitName = realName
	ns.char.ach = realAch
	BigChronicleDB.ach = nil
	A:MergeCharacter()
	local m = 0
	for _ in pairs(A:Account().done) do m = m + 1 end
	check(m == n, "old per-character achievements merge into the account record")
end

print("== reset")
M.autoAccept = true
ns:ResetData("all")
M.runTimers()
check(ns.char.log[1] and ns.char.log[1].cat == "start" and #ns.char.log <= 2, "reset restarts chronicle")
check(next(ns.char.dex.creatures) == nil, "dex cleared")

-- errors captured?
print("== captured errors: " .. #ns.errors)
for _, e in ipairs(ns.errors) do print("   ERR " .. e) end
check(#ns.errors == 0, "no runtime errors captured")

print(failures == 0 and "ALL PASSED" or (failures .. " FAILURES"))
os.exit(failures == 0 and 0 or 1)
