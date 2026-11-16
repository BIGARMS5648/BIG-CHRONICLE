-- BIG CHRONICLE :: Core
-- 공용 유틸리티, 저장 데이터, 이벤트 디스패처, 슬래시 명령어

local ADDON, ns = ...

ns.TITLE = "BIG CHRONICLE"
ns.ICON = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Icon"  -- 글자 없는 애드온 아이콘 (64×64 TGA)
ns.VERSION = "1.10.9"
_G.BigChronicle = ns

do
	local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
	if getMeta then
		local ok, v = pcall(getMeta, ADDON, "Version")
		if ok and type(v) == "string" and v ~= "" then ns.VERSION = v end
	end
end

local floor, format, tostring, type, pairs, ipairs, select, unpack =
	math.floor, string.format, tostring, type, pairs, ipairs, select, unpack

------------------------------------------------------------------------
-- 색상
------------------------------------------------------------------------
ns.COLOR = {
	gold      = "d4af37",
	parchment = "e8d9b0",
	grey      = "9d9d9d",
	dim       = "8a8070",
	zone      = "e6c27a",
	quest     = "ffd100",
	dungeon   = "ff9940",
	boss      = "ff6060",
	creature  = "7fd4ff",
	tribe     = "9be27a",
	rare      = "c58cff",
	note      = "f0e6c8",
	good      = "60ff60",
	bad       = "ff5050",
}

-- Format()에서 변수 이름별로 자동으로 입힐 강조 색
ns.HL = {
	zone = ns.COLOR.zone, sub = ns.COLOR.zone, place = ns.COLOR.zone,
	quest = ns.COLOR.quest,
	dungeon = ns.COLOR.dungeon, bg = ns.COLOR.dungeon,
	boss = ns.COLOR.boss,
	creature = ns.COLOR.creature,
	tribe = ns.COLOR.tribe,
	rare = ns.COLOR.rare,
	title = ns.COLOR.gold,
	hero = ns.COLOR.parchment,
}

function ns.Hex(text, hex)
	return "|cff" .. hex .. tostring(text) .. "|r"
end

------------------------------------------------------------------------
-- Secret value 안전 처리 (Midnight 계열 API 대비)
------------------------------------------------------------------------
local issecretvalue = _G.issecretvalue

local function pack(...)
	return { n = select("#", ...), ... }
end

-- 비밀 값(secret value)을 nil로 바꿔서 돌려준다
function ns.Safe(...)
	if not issecretvalue then return ... end
	local n = select("#", ...)
	if n == 0 then return end
	local t = { ... }
	for i = 1, n do
		local v = t[i]
		if v ~= nil and issecretvalue(v) then t[i] = nil end
	end
	return unpack(t, 1, n)
end

-- API를 pcall로 감싸 호출하고, 비밀 값은 걸러낸다
function ns.Call(fn, ...)
	if type(fn) ~= "function" then return nil end
	local r = pack(pcall(fn, ...))
	if not r[1] then return nil end
	return ns.Safe(unpack(r, 2, r.n))
end

------------------------------------------------------------------------
-- 한국어 조사 처리
------------------------------------------------------------------------
local JOSA = {
	["을"] = { "을", "를" }, ["를"] = { "을", "를" },
	["이"] = { "이", "가" }, ["가"] = { "이", "가" },
	["은"] = { "은", "는" }, ["는"] = { "은", "는" },
	["과"] = { "과", "와" }, ["와"] = { "과", "와" },
	["아"] = { "아", "야" }, ["야"] = { "아", "야" },
	["이라"] = { "이라", "라" }, ["이나"] = { "이나", "나" },
	["이며"] = { "이며", "며" }, ["이다"] = { "이다", "다" },
	["이여"] = { "이여", "여" },
	["으로"] = { "으로", "로" }, ["로"] = { "으로", "로" },
}
local JOSA_KEYS = {}
for k in pairs(JOSA) do JOSA_KEYS[#JOSA_KEYS + 1] = k end
table.sort(JOSA_KEYS, function(a, b) return #a > #b end)

local TRAILING = { "」", "』", "”", "’", ")", "]", "\"", "'", " ", ".", "!", "?", "…" }

local function StripCodes(s)
	s = s:gsub("||", "\001")
	s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	s = s:gsub("|T.-|t", ""):gsub("|A.-|a", "")
	s = s:gsub("\001", "|")
	return s
end
ns.StripCodes = StripCodes

local function LastCodepoint(s)
	local i = #s
	while i > 0 do
		local b = s:byte(i)
		if b < 0x80 or b >= 0xC0 then break end
		i = i - 1
	end
	if i < 1 then return nil end
	local b1 = s:byte(i)
	if b1 < 0x80 then return b1 end
	local b2, b3 = s:byte(i + 1), s:byte(i + 2)
	if b1 >= 0xE0 and b1 < 0xF0 and b2 and b3 then
		return (b1 - 0xE0) * 4096 + (b2 - 0x80) * 64 + (b3 - 0x80)
	elseif b1 >= 0xC0 and b1 < 0xE0 and b2 then
		return (b1 - 0xC0) * 64 + (b2 - 0x80)
	end
	return nil
end

-- 받침 여부, ㄹ받침 여부 (판단 불가 시 nil)
local DIGIT_JONG = { [48] = true, [49] = "r", [50] = false, [51] = true, [52] = false,
	[53] = false, [54] = true, [55] = "r", [56] = "r", [57] = false }

local function JongInfo(word)
	local s = StripCodes(tostring(word or ""))
	local changed = true
	while changed and #s > 0 do
		changed = false
		for _, t in ipairs(TRAILING) do
			if #s >= #t and s:sub(-#t) == t then
				s = s:sub(1, #s - #t)
				changed = true
			end
		end
	end
	local cp = LastCodepoint(s)
	if not cp then return nil end
	if cp >= 0xAC00 and cp <= 0xD7A3 then
		local jong = (cp - 0xAC00) % 28
		return jong > 0, jong == 8
	end
	local d = DIGIT_JONG[cp]
	if d ~= nil then
		if d == "r" then return true, true end
		return d, false
	end
	return nil
end

function ns.Particle(word, spec)
	for _, key in ipairs(JOSA_KEYS) do
		if spec:sub(1, #key) == key then
			local pair = JOSA[key]
			local rest = spec:sub(#key + 1)
			local has, rieul = JongInfo(word)
			local p
			if has == nil then
				if key == "으로" or key == "로" then
					p = "(으)로"
				elseif pair[1]:sub(-#pair[2]) == pair[2] and #pair[1] > #pair[2] then
					p = "(" .. pair[1]:sub(1, #pair[1] - #pair[2]) .. ")" .. pair[2]
				else
					p = pair[1] .. "(" .. pair[2] .. ")"
				end
			elseif key == "으로" or key == "로" then
				p = (has and not rieul) and "으로" or "로"
			else
				p = has and pair[1] or pair[2]
			end
			return p .. rest
		end
	end
	return spec
end

function ns.Josa(word, spec)
	return tostring(word) .. ns.Particle(word, spec)
end

-- "{zone:에서} {quest}" 같은 템플릿을 채운다. 변수 이름이 ns.HL에 있으면 색을 입힌다.
function ns.Format(tpl, vars)
	vars = vars or {}
	return (tpl:gsub("{([%w_]+):?([^}]*)}", function(key, spec)
		local v = vars[key]
		if v == nil then return "" end
		v = tostring(v)
		local hl = ns.HL[key]
		local shown = hl and ("|cff" .. hl .. v .. "|r") or v
		if spec ~= "" then
			return shown .. ns.Particle(v, spec)
		end
		return shown
	end))
end

function ns.Quote(name)
	return "「" .. tostring(name) .. "」"
end

function ns.Pick(list)
	return list[math.random(1, #list)]
end

------------------------------------------------------------------------
-- 숫자 / 시간 / 돈 포맷
------------------------------------------------------------------------
function ns.Comma(n)
	n = floor(tonumber(n) or 0)
	local s = tostring(n)
	local neg = s:sub(1, 1) == "-"
	if neg then s = s:sub(2) end
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then out = out:sub(2) end
	return (neg and "-" or "") .. out
end

local WDAY = { "일", "월", "화", "수", "목", "금", "토" }

function ns.FormatDate(t)
	local d = date("*t", t)
	return format("%d년 %d월 %d일 (%s)", d.year, d.month, d.day, WDAY[d.wday])
end

function ns.FormatShortDate(t)
	return date("%Y.%m.%d", t)
end

function ns.FormatDateTime(t)
	return date("%Y.%m.%d %H:%M", t)
end

function ns.FormatClock(t)
	return date("%H:%M", t)
end

function ns.DayKey(t)
	return date("%Y%m%d", t)
end

function ns.FormatDuration(sec)
	sec = floor(tonumber(sec) or 0)
	if sec < 0 then sec = 0 end
	local d = floor(sec / 86400)
	local h = floor((sec % 86400) / 3600)
	local m = floor((sec % 3600) / 60)
	local s = sec % 60
	if d > 0 then return h > 0 and format("%d일 %d시간", d, h) or format("%d일", d) end
	if h > 0 then return m > 0 and format("%d시간 %d분", h, m) or format("%d시간", h) end
	if m > 0 then return format("%d분", m) end
	return format("%d초", s)
end

function ns.FormatMoney(copper)
	copper = floor(tonumber(copper) or 0)
	local g = floor(copper / 10000)
	local s = floor((copper % 10000) / 100)
	local c = copper % 100
	local parts = {}
	if g > 0 then parts[#parts + 1] = ns.Comma(g) .. "골드" end
	if s > 0 then parts[#parts + 1] = s .. "실버" end
	if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "코퍼" end
	return table.concat(parts, " ")
end

------------------------------------------------------------------------
-- 플레이어 / 지역 정보
------------------------------------------------------------------------
function ns.PlayerLevel()
	return ns.Call(UnitLevel, "player") or 1
end

function ns.Zone()
	local z = ns.Call(GetZoneText)
	if not z or z == "" then z = ns.Call(GetRealZoneText) end
	return z or ""
end

function ns.SubZone()
	return ns.Call(GetSubZoneText) or ""
end

-- 비행 조련사의 와이번·그리핀을 타고 날아가는 중인가
-- (하늘에서 내려다본 곳과 몬스터는 '발견'으로 치지 않는다 — 직접 찾아가야 진짜 발견이다)
function ns.OnTaxi()
	return ns.Call(UnitOnTaxi, "player") and true or false
end

function ns.PlayerName()
	return ns.Call(UnitName, "player") or "모험가"
end

------------------------------------------------------------------------
-- 출력 / 오류
------------------------------------------------------------------------
function ns.Print(msg)
	local cf = DEFAULT_CHAT_FRAME
	if cf and cf.AddMessage then
		cf:AddMessage("|cffd4af37[BIG CHRONICLE]|r " .. tostring(msg))
	end
end

ns.errors = {}
function ns:Error(err)
	local list = self.errors
	list[#list + 1] = tostring(err)
	if #list > 20 then table.remove(list, 1) end
	if self.db and self.db.debug then
		self.Print("|cffff5050오류:|r " .. tostring(err))
	end
end

------------------------------------------------------------------------
-- 내부 메시지 버스
------------------------------------------------------------------------
local listeners = {}

function ns:Listen(msg, fn)
	listeners[msg] = listeners[msg] or {}
	table.insert(listeners[msg], fn)
end

function ns:Fire(msg, ...)
	local list = listeners[msg]
	if not list then return end
	for i = 1, #list do
		local ok, err = pcall(list[i], ...)
		if not ok then ns:Error(err) end
	end
end

------------------------------------------------------------------------
-- 게임 이벤트 디스패처
------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
ns.eventFrame = eventFrame
local handlers = {}

local function EventIsValid(event)
	if C_EventUtils and C_EventUtils.IsEventValid then
		local ok, valid = pcall(C_EventUtils.IsEventValid, event)
		if ok and valid == false then return false end
	end
	return true
end

-- 이벤트 등록. 존재하지 않는 이벤트면 조용히 false를 돌려준다.
function ns:On(event, fn)
	if not handlers[event] then
		if not EventIsValid(event) then return false end
		local ok = pcall(eventFrame.RegisterEvent, eventFrame, event)
		if not ok then return false end
		handlers[event] = {}
	end
	table.insert(handlers[event], fn)
	return true
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local list = handlers[event]
	if not list then return end
	for i = 1, #list do
		local ok, err = pcall(list[i], event, ...)
		if not ok then ns:Error(event .. ": " .. tostring(err)) end
	end
end)

------------------------------------------------------------------------
-- 저장 데이터
------------------------------------------------------------------------
ns.DEFAULTS = {
	chat = true,          -- 새 기록을 채팅창에 알림
	toast = true,         -- 도감 등록 알림 팝업
	toastLocked = true,   -- 알림 위치 잠금 (풀면 끌어서 옮길 수 있다)
	-- toastPos = { x, y }: 옮긴 알림 위치 (화면 위쪽 가운데 기준)
	sound = true,         -- 알림 효과음
	logSubzones = true,   -- 세부 장소 발견도 일지에 기록
	questRewards = true,  -- 퀘스트 기록에 보상 표시
	nameplates = true,    -- 이름표로도 몬스터 발견
	tooltip = true,       -- 몬스터 툴팁에 도감 정보 표시
	newestFirst = false,  -- 일지 정렬
	typewriter = true,    -- 배경 이야기가 한 자씩 써지는 연출
	hotkeys = true,       -- 창이 열려 있을 때 키보드 단축키
	effects = true,       -- 화면 연출 (두루마리 펼침, 장 제목, 반짝이, 도장)
	debug = false,
	minimap = { hide = false, angle = 215 },
	window = {},
}

local function CharDefaults()
	return {
		version = 1,
		log = {},
		zones = {},
		subzones = {},
		levels = {},
		levelTracked = {},  -- 레벨에 도달했을 때까지 접속해 있던 누적 시간(초)
		quests = { count = 0, ids = {}, zones = {}, maps = {} },
		dungeons = {},
		bosses = {},
		pvp = {},
		pvpMaps = {},
		deaths = 0,
		money = {},
		stats = { tracked = 0 },
		ach = { done = {}, retro = {}, flags = {} },  -- 업적
		dex = {
			creatures = {},   -- [이름] = 개체 정보
			tribes = {},      -- [종족 id] = 발견 정보
			dyn = {},         -- [동적 종족 id] = 번호 (야수 계열)
			overrides = {},   -- [이름] = 사용자가 지정한 종족
			prefixes = {},    -- 학습된 이름 접두어 → 종족
			pending = {},     -- 아직 발견 전에 집계된 처치
			order = 0,
			tribeOrder = 0,
			dynOrder = 0,
			totalKills = 0,
		},
	}
end
ns.CharDefaults = CharDefaults

local function Merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			Merge(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
	return dst
end
ns.Merge = Merge

ns:On("ADDON_LOADED", function(_, name)
	if name ~= ADDON then return end
	BigChronicleDB = BigChronicleDB or {}
	BigChronicleDB.settings = Merge(BigChronicleDB.settings or {}, ns.DEFAULTS)
	ns.db = BigChronicleDB.settings
	ns.db.theme = nil   -- 테마 선택은 없어졌다 (양피지 한 가지)

	BigChronicleCharDB = Merge(BigChronicleCharDB or {}, CharDefaults())
	ns.char = BigChronicleCharDB
end)

ns:On("PLAYER_LOGIN", function()
	if not ns.char then
		BigChronicleDB = BigChronicleDB or {}
		BigChronicleDB.settings = Merge(BigChronicleDB.settings or {}, ns.DEFAULTS)
		ns.db = BigChronicleDB.settings
		BigChronicleCharDB = Merge(BigChronicleCharDB or {}, CharDefaults())
		ns.char = BigChronicleCharDB
	end
	ns.ready = true
	for _, mod in ipairs({ ns.Bestiary, ns.Chronicle, ns.Achievements, ns.Toast, ns.Minimap }) do
		if mod and mod.Init then
			local ok, err = pcall(mod.Init, mod)
			if not ok then ns:Error(err) end
		end
	end
	ns:Fire("READY")
end)

-- 데이터 초기화 (설정 탭에서 사용)
function ns:ResetData(what)
	local fresh = CharDefaults()
	local c = self.char
	if what == "journal" or what == "all" then
		for _, k in ipairs({ "log", "zones", "subzones", "levels", "levelTracked", "quests", "dungeons", "bosses", "pvp", "pvpMaps", "money", "stats" }) do
			c[k] = fresh[k]
		end
		c.deaths = 0
		c.started = nil
		c.expedition = nil
	end
	if what == "dex" or what == "all" then
		c.dex = fresh.dex
	end
	c.ach = fresh.ach -- 업적은 남은 기록으로 다시 판정한다 (이미 이룬 것은 조용히 정리)
	if self.Bestiary and self.Bestiary.OnReset then self.Bestiary:OnReset() end
	if (what == "journal" or what == "all") and self.Chronicle and self.Chronicle.OnReset then self.Chronicle:OnReset() end
	if self.Achievements and self.Achievements.OnReset then self.Achievements:OnReset() end
	self:Fire("LOG_ADDED")
	self:Fire("DEX_UPDATED")
end

------------------------------------------------------------------------
-- 슬래시 명령어
------------------------------------------------------------------------
local function Trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end
ns.Trim = Trim

local function ShowHelp()
	local P = ns.Print
	P("사용법 — |cffffd100/bc|r 또는 |cffffd100/연대기|r")
	P("  |cffffd100/bc|r : 창 열기/닫기")
	P("  |cffffd100/bc 일지|r · |cffffd100/bc 도감|r · |cffffd100/bc 업적|r · |cffffd100/bc 통계|r · |cffffd100/bc 설정|r")
	P("  |cffffd100/bc 기록 <내용>|r : 나만의 기록을 일지에 남기기  (|cffffd100/일지 <내용>|r 도 가능)")
	P("  |cffffd100/bc 내보내기|r : 일지 전체를 복사 가능한 글로 보기")
	P("  |cffffd100/bc 미니맵|r : 미니맵 버튼 보이기/숨기기")
	P("  |cffffd100/bc 알림|r : 알림 위치 잠금 풀기/잠그기 (끌어서 옮기기)")
	P("  |cffffd100/bc 알림 초기화|r : 알림을 기본 위치(화면 위쪽 가운데)로 되돌리기")
	P("  Special thanks to 루마 · 절미 · 판초네 콘체타 · KLEROS")
end

function ns:HandleSlash(msg)
	msg = Trim(msg)
	local cmd, rest = msg:match("^(%S+)%s*(.-)$")
	cmd = cmd and cmd:lower() or ""
	local UI = ns.UI
	if cmd == "" then
		if UI then UI:Toggle() end
	elseif cmd == "일지" or cmd == "journal" or cmd == "log" then
		if UI then UI:Open("journal") end
	elseif cmd == "도감" or cmd == "dex" or cmd == "bestiary" then
		if UI then UI:Open("bestiary") end
	elseif cmd == "업적" or cmd == "achievements" or cmd == "ach" then
		if UI then UI:Open("achievements") end
	elseif cmd == "통계" or cmd == "stats" then
		if UI then UI:Open("stats") end
	elseif cmd == "설정" or cmd == "config" or cmd == "options" then
		if UI then UI:Open("settings") end
	elseif cmd == "기록" or cmd == "note" or cmd == "메모" then
		if rest == "" then
			ns.Print("기록할 내용을 함께 적어 주세요. 예) |cffffd100/bc 기록 오늘 처음으로 그리핀을 탔다|r")
		else
			ns.Chronicle:AddNote(rest)
		end
	elseif cmd == "내보내기" or cmd == "export" then
		if UI then UI:ShowExport() end
	elseif cmd == "미니맵" or cmd == "minimap" then
		if ns.Minimap then ns.Minimap:Toggle() end
	elseif (cmd == "알림" or cmd == "toast") and (rest == "초기화" or rest:lower() == "reset") then
		-- 알림 위치를 기본 위치로
		if ns.Toast then ns.Toast:ResetPosition() end
	elseif cmd == "알림" or cmd == "toast" then
		-- 알림 위치 잠금 켜고 끄기
		if ns.Toast then
			local unlock = ns.db.toastLocked ~= false
			ns.Toast:SetLocked(not unlock)
			ns.Print(unlock and "알림 위치 잠금을 풀었습니다. 예시 알림을 끌어 옮긴 뒤 오른쪽 클릭으로 잠그세요." or "알림 위치를 잠갔습니다.")
		end
	elseif cmd == "debug" then
		ns.db.debug = not ns.db.debug
		ns.Print("디버그 모드: " .. (ns.db.debug and "켜짐" or "꺼짐"))
		for _, e in ipairs(ns.errors) do ns.Print("|cffff5050" .. e .. "|r") end
	else
		ShowHelp()
	end
end

SLASH_BIGCHRONICLE1 = "/bc"
SLASH_BIGCHRONICLE2 = "/bigchronicle"
SLASH_BIGCHRONICLE3 = "/chronicle"
SLASH_BIGCHRONICLE4 = "/연대기"
SlashCmdList["BIGCHRONICLE"] = function(msg) ns:HandleSlash(msg) end

SLASH_BIGCHRONICLEJOURNAL1 = "/일지"
SlashCmdList["BIGCHRONICLEJOURNAL"] = function(msg)
	msg = Trim(msg)
	if msg ~= "" then
		ns.Chronicle:AddNote(msg)
	elseif ns.UI then
		ns.UI:Open("journal")
	end
end

SLASH_BIGCHRONICLEDEX1 = "/도감"
SlashCmdList["BIGCHRONICLEDEX"] = function()
	if ns.UI then ns.UI:Open("bestiary") end
end

-- 애드온 보관함(미니맵 옆 애드온 목록)에서 클릭했을 때
function BigChronicle_OnAddonCompartmentClick(_, button)
	if not ns.UI then return end
	if button == "RightButton" then
		ns.UI:Open("bestiary")
	else
		ns.UI:Toggle()
	end
end
