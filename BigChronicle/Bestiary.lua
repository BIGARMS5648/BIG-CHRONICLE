-- BIG CHRONICLE :: 몬스터 도감
-- 처음 본 몬스터를 도감에 등록하고, 종족별로 분류해 서식지·처치 수·희귀 개체를 모은다.

local ADDON, ns = ...
local B = {}
ns.Bestiary = B

local Format, Q = ns.Format, ns.Quote
local time, GetTime, pairs, ipairs, tonumber, lower = time, GetTime, pairs, ipairs, tonumber, string.lower

------------------------------------------------------------------------
-- 생물 유형 식별
------------------------------------------------------------------------
local TYPE_BY_ID = {
	[1] = "beast", [2] = "dragonkin", [3] = "demon", [4] = "elemental", [5] = "giant",
	[6] = "undead", [7] = "humanoid", [8] = "critter", [9] = "mechanical", [10] = "unknown",
	[11] = "totem", [12] = "pet", [13] = "gas", [14] = "wildpet", [15] = "aberration",
}
local TYPE_BY_NAME = {
	Beast = "beast", ["야수"] = "beast",
	Dragonkin = "dragonkin", ["용족"] = "dragonkin",
	Demon = "demon", ["악마"] = "demon",
	Elemental = "elemental", ["정령"] = "elemental",
	Giant = "giant", ["거인"] = "giant",
	Undead = "undead", ["언데드"] = "undead",
	Humanoid = "humanoid", ["인간형"] = "humanoid",
	Critter = "critter", ["동물"] = "critter",
	Mechanical = "mechanical", ["기계"] = "mechanical",
	["Not specified"] = "unknown", ["정보 없음"] = "unknown", ["알 수 없음"] = "unknown",
	Totem = "totem", ["토템"] = "totem",
	["Non-combat Pet"] = "pet", ["애완동물"] = "pet", ["전투 애완동물"] = "pet",
	["Gas Cloud"] = "gas", ["Wild Pet"] = "wildpet", ["야생 애완동물"] = "wildpet",
	Aberration = "aberration",
}
local TYPE_LABEL = {
	beast = "야수", dragonkin = "용족", demon = "악마", elemental = "정령", giant = "거인",
	undead = "언데드", humanoid = "인간형", critter = "동물", mechanical = "기계",
	unknown = "정보 없음", aberration = "돌연변이",
}
B.TYPE_LABEL = TYPE_LABEL
local EXCLUDED_TYPES = { totem = true, pet = true, gas = true, wildpet = true }

-- 분류 등급 (높을수록 희귀/강함)
local CLS_RANK = { minus = 0, trivial = 0, normal = 1, elite = 2, rare = 3, rareelite = 4, worldboss = 5 }
B.CLS_LABEL = { elite = "정예", rare = "희귀", rareelite = "희귀 정예", worldboss = "우두머리" }

local function IsRare(cls) return cls == "rare" or cls == "rareelite" end
B.IsRare = IsRare

------------------------------------------------------------------------
-- 연구 등급
------------------------------------------------------------------------
-- 연구도 = 발견한 종 ×10 + 처치 + 희귀 개체 ×50 + 우두머리 ×20
-- 별이 늘수록 문턱이 가파르게 높아진다. ★★★★★는 한 종족을 오래 쫓아다녀야 겨우 닿는 경지.
B.RANKS = {
	{ min = 0,     name = "미발견",        stars = 0 },
	{ min = 1,     name = "조우",          stars = 1 },
	{ min = 150,   name = "관찰자",        stars = 2 },
	{ min = 1000,  name = "연구자",        stars = 3 },
	{ min = 5000,  name = "권위자",        stars = 4 },
	{ min = 25000, name = "전설의 사냥꾼", stars = 5 },
}

function B.RankFor(score, discovered)
	if not discovered then return 1, B.RANKS[1], B.RANKS[2] end
	local idx = 2
	for i = 2, #B.RANKS do
		if score >= B.RANKS[i].min then idx = i end
	end
	return idx, B.RANKS[idx], B.RANKS[idx + 1]
end

function B.Stars(n)
	return string.rep("★", n) .. string.rep("☆", 5 - n)
end

local KILL_STEPS = {
	{ n = 50,   title = "{tribe} 사냥꾼" },
	{ n = 100,  title = "{tribe} 토벌자" },
	{ n = 250,  title = "{tribe}의 천적" },
	{ n = 500,  title = "{tribe}의 재앙" },
	{ n = 1000, title = "{tribe}의 악몽" },
}

------------------------------------------------------------------------
-- 초기화
------------------------------------------------------------------------
-- 클라이언트가 알려 주는 현지화된 생물 유형 이름을 표에 더한다 (언어에 상관없이 판별되도록)
function B:LearnTypeNames()
	local api = C_CreatureInfo and C_CreatureInfo.GetCreatureTypeInfo
	if not api then return end
	for id, key in pairs(TYPE_BY_ID) do
		local info = ns.Call(api, id)
		local name = type(info) == "table" and info.name or info
		if type(name) == "string" and name ~= "" and not TYPE_BY_NAME[name] then
			TYPE_BY_NAME[name] = key
		end
	end
end

function B:Init()
	self:LearnTypeNames()
	self.dex = ns.char.dex
	self.recentScan = {}
	self.seenGUID = {}
	self.alive = {}
	self.aliveCount = 0
	self.recentKill = {}
	self:BuildXPPatterns()

	local on = function(ev, fn) ns:On(ev, function(...) fn(self, ...) end) end
	on("PLAYER_TARGET_CHANGED", function() self:SafeScan("target") end)
	on("UPDATE_MOUSEOVER_UNIT", function() self:SafeScan("mouseover") end)
	on("NAME_PLATE_UNIT_ADDED", function(_, _, unit)
		if ns.db.nameplates then self:SafeScan(unit) end
	end)
	on("NAME_PLATE_UNIT_REMOVED", function(_, _, unit) self:CheckDeath(unit) end)
	on("UNIT_HEALTH", self.OnUnitHealth)
	on("CHAT_MSG_COMBAT_XP_GAIN", self.OnXPMessage)

	self:HookTooltip()

	if C_Timer and C_Timer.NewTicker then
		C_Timer.NewTicker(300, function() B:Cleanup() end)
	end
end

function B:OnReset()
	self.dex = ns.char.dex
	wipe(self.recentScan)
	wipe(self.seenGUID)
	wipe(self.alive)
	self.aliveCount = 0
	wipe(self.recentKill)
	self.cache = nil
end

function B:Cleanup()
	local now = GetTime()
	for guid, t in pairs(self.recentScan) do
		if now - t > 60 then self.recentScan[guid] = nil end
	end
	local nowT = time()
	for guid, t in pairs(self.seenGUID) do
		if nowT - t > 1800 then self.seenGUID[guid] = nil end
	end
	if self.aliveCount > 400 then
		wipe(self.alive)
		self.aliveCount = 0
	end
end

------------------------------------------------------------------------
-- 분류
------------------------------------------------------------------------
local function Tokenize(name)
	local tokens = {}
	for tok in name:gmatch("[^%s]+") do tokens[#tokens + 1] = lower(tok) end
	return tokens
end

local function MatchKeyword(lname, tokens, kw)
	if kw:sub(1, 1) == "=" then
		local w = kw:sub(2)
		for _, tok in ipairs(tokens) do
			if tok == w then return true end
		end
		return false
	end
	return lname:find(kw, 1, true) ~= nil
end

local function TypeOK(def, typeKey)
	if not def or not def.types then return true end
	if not typeKey then return true end -- 유형을 모를 때는 허용
	return def.types[typeKey] == true
end

-- 이름과 생물 유형으로 종족을 판정한다
function B:Classify(name, typeKey, family)
	local d = self.dex
	local o = d.overrides[name]
	if o and ns.GetTribe(o) then return o end

	local lname = lower(name)
	local tokens = Tokenize(name)
	for _, t in ipairs(ns.TRIBES) do
		if t.keywords and TypeOK(t, typeKey) then
			for _, kw in ipairs(t.keywords) do
				if MatchKeyword(lname, tokens, kw) then
					self:LearnPrefix(tokens, kw, t)
					return t.id
				end
			end
		end
	end

	-- 같은 이름 접두어를 가진 동족 (예: "강바닥발톱 놀" → "강바닥발톱 잡종개"도 놀)
	if #tokens >= 2 then
		local p = d.prefixes[tokens[1]]
		if p and TypeOK(ns.GetTribe(p), typeKey) and typeKey then
			return p
		end
	end

	if typeKey == "beast" and family and family ~= "" then
		return "beast:" .. family
	end
	return ns.TYPE_TRIBE[typeKey or "unknown"] or "mystery"
end

function B:LearnPrefix(tokens, kw, tribe)
	if not tribe.types or #tokens < 2 then return end
	local first = tokens[1]
	local plain = kw:gsub("^=", "")
	if first:find(plain, 1, true) then return end
	local d = self.dex
	local cur = d.prefixes[first]
	if cur == nil then
		d.prefixes[first] = tribe.id
		self:ReclassifyPrefix(first, tribe.id)
	elseif cur ~= tribe.id and cur ~= false then
		d.prefixes[first] = false -- 여러 종족에서 쓰이는 접두어는 학습하지 않는다
	end
end

-- 새로 배운 접두어로, 기타 분류에 있던 개체를 옮긴다
function B:ReclassifyPrefix(first, tribeId)
	local def = ns.GetTribe(tribeId)
	for name, c in pairs(self.dex.creatures) do
		if (c.tribe == "humanoid" or c.tribe == "mystery") and not self.dex.overrides[name] and c.ctype and TypeOK(def, c.ctype) then
			local tokens = Tokenize(name)
			if #tokens >= 2 and tokens[1] == first then
				c.tribe = tribeId
				self:EnsureTribe(tribeId, name, c, true)
			end
		end
	end
end

------------------------------------------------------------------------
-- 발견
------------------------------------------------------------------------
function B:SafeScan(unit)
	if not ns.char or not unit then return end
	if ns.OnTaxi() then return end   -- 날아가며 내려다본 몬스터는 도감에 올리지 않는다
	local ok, err = pcall(self.ScanUnit, self, unit)
	if not ok then ns:Error(err) end
end

function B:ScanUnit(unit)
	local Call = ns.Call
	if not Call(UnitExists, unit) then return end
	if Call(UnitIsPlayer, unit) or Call(UnitPlayerControlled, unit) then return end
	local guid = Call(UnitGUID, unit)
	if type(guid) ~= "string" then return end

	local now = GetTime()
	local last = self.recentScan[guid]
	if last and now - last < 3 then return end
	self.recentScan[guid] = now

	local gtype, _, _, _, _, npcID = strsplit("-", guid)
	if gtype ~= "Creature" and gtype ~= "Vehicle" then return end
	if ns.Chronicle.NoteInstanceGUID then ns.Chronicle:NoteInstanceGUID(guid) end
	if not Call(UnitCanAttack, "player", unit) then return end
	local faction = Call(UnitFactionGroup, unit)
	if faction == "Alliance" or faction == "Horde" then return end -- 경비병 등 진영 NPC 제외

	local name = Call(UnitName, unit)
	if type(name) ~= "string" or name == "" or name == UNKNOWNOBJECT or name == UNKNOWN then return end

	local typeName, typeID = Call(UnitCreatureType, unit)
	local typeKey = (typeName and TYPE_BY_NAME[typeName]) or (tonumber(typeID) and TYPE_BY_ID[typeID])
	if not typeKey and typeName then typeKey = "unknown" end
	if typeKey and EXCLUDED_TYPES[typeKey] then return end

	local level = Call(UnitLevel, unit)
	local cls = Call(UnitClassification, unit) or "normal"
	local isBoss = level == -1 or cls == "worldboss" or Call(UnitIsBossMob, unit) == true

	self:Record(name, {
		npcID = tonumber(npcID), typeKey = typeKey, typeName = typeName,
		family = Call(UnitCreatureFamily, unit), cls = cls, level = level, boss = isBoss, guid = guid,
	})

	if not Call(UnitIsDead, unit) then
		if not self.alive[guid] then self.aliveCount = self.aliveCount + 1 end
		self.alive[guid] = name
	end
end

function B:EnsureTribe(id, byName, c, silent)
	local d = self.dex
	local t = d.tribes[id]
	if t then return t, false end
	d.tribeOrder = d.tribeOrder + 1
	t = {
		first = (c and c.first) or time(), zone = (c and c.zone) or ns.Zone(), plvl = (c and c.plvl) or ns.PlayerLevel(),
		by = byName, order = d.tribeOrder, rank = 2, km = 0,
	}
	d.tribes[id] = t
	if id:find("^beast:") and not d.dyn[id] then
		d.dynOrder = d.dynOrder + 1
		d.dyn[id] = d.dynOrder
	end
	return t, true
end

function B:Record(name, info)
	local d = self.dex
	local c = d.creatures[name]
	local zone = ns.Zone()
	local now = time()
	local isNew = false

	if not c then
		isNew = true
		d.order = d.order + 1
		c = {
			tribe = self:Classify(name, info.typeKey, info.family),
			first = now, zone = zone, sub = ns.SubZone(), plvl = ns.PlayerLevel(), order = d.order, tod = ns.TimeOfDay(),
			ctype = info.typeKey, tname = info.typeName, family = info.family,
			cls = info.cls or "normal", kills = 0, seen = 0, zones = {}, ids = {},
		}
		if d.pending[name] then
			c.kills = d.pending[name]
			d.pending[name] = nil
		end
		d.creatures[name] = c
	end

	-- 갱신 (화면을 다시 그릴 만한 변화가 있었는지 함께 기록)
	local changed = isNew
	if not c.ctype and info.typeKey then c.ctype, c.tname = info.typeKey, info.typeName; changed = true end
	if not c.family and info.family then c.family = info.family; changed = true end
	if info.guid and not self.seenGUID[info.guid] then
		self.seenGUID[info.guid] = now
		c.seen = c.seen + 1
		if zone ~= "" then c.zones[zone] = (c.zones[zone] or 0) + 1 end
		changed = true
	end
	local lvl = tonumber(info.level)
	if lvl and lvl > 0 then
		if not c.minL or lvl < c.minL then c.minL = lvl; changed = true end
		if not c.maxL or lvl > c.maxL then c.maxL = lvl; changed = true end
	elseif lvl == -1 and not c.skull then
		c.skull = true
		changed = true
	end
	if info.npcID and not c.ids[info.npcID] then
		c.ids[info.npcID] = true
		c.npc = c.npc or info.npcID
		changed = true
	end
	if info.boss and not c.boss then c.boss = true; changed = true end

	local wasRare = IsRare(c.cls)
	if (CLS_RANK[info.cls] or 1) > (CLS_RANK[c.cls] or 1) then c.cls = info.cls; changed = true end
	local becameRare = not isNew and not wasRare and IsRare(c.cls)

	if not changed then return end
	self.cache = nil
	if isNew then
		self:OnNewCreature(name, c)
	elseif becameRare then
		self:OnRare(name, c)
	end
	ns:Fire("DEX_UPDATED", name)
end

function B:TribeNo(id)
	if ns.TRIBE_INDEX[id] then return ns.TRIBE_INDEX[id] end
	local dyn = self.dex.dyn[id]
	if dyn then return #ns.TRIBES + dyn end
	return 0
end

function B:FormatNo(id)
	return string.format("No.%03d", self:TribeNo(id))
end

-- 서술 문장에 쓰는 변수 (시간대·지역·종족)
local function Scene(extra)
	local zone = ns.Zone()
	local v = { time = ns.TimeOfDay(), zone = zone ~= "" and zone or "이름 모를 땅", lvl = ns.PlayerLevel() }
	for k, x in pairs(extra or {}) do v[k] = x end
	return v
end

-- 문장 끝에 붙는 작은 꼬리말: — 도감 No.008 켄타우로스 · 36레벨
local function Tail(self, tribeId, extra)
	local def = ns.GetTribe(tribeId)
	local parts = { "도감 " .. self:FormatNo(tribeId) .. " " .. (def and def.name or "?") }
	if extra then parts[#parts + 1] = extra end
	parts[#parts + 1] = ns.PlayerLevel() .. "레벨"
	return ns.Hex("  — " .. table.concat(parts, " · "), ns.COLOR.dim)
end
B.Tail = Tail

function B:OnNewCreature(name, c)
	local def = ns.GetTribe(c.tribe)
	local tribeData, newTribe = self:EnsureTribe(c.tribe, name, c)
	tribeData.rank = tribeData.rank or 2
	local lvl, zone = ns.PlayerLevel(), ns.Zone()
	local no = self:FormatNo(c.tribe)

	local N = ns.NARRATIVE
	if newTribe then
		local tpl = N.FirstEncounter(c.tribe, def)
		local text = Format(tpl, Scene({ tribe = def.phrase or def.name, creature = Q(name) }))
		ns.Chronicle:Add("dex", text .. Tail(self, c.tribe, "새 항목"), { tribe = c.tribe, creature = name })
	end

	if IsRare(c.cls) then
		self:OnRare(name, c, true)
	elseif c.cls == "worldboss" then
		ns.Chronicle:Add("rare", Format(ns.Pick(N.bossSeen), Scene({ creature = Q(name) })) .. Tail(self, c.tribe, "우두머리"),
			{ creature = name })
	end

	if ns.Toast and not IsRare(c.cls) then
		-- 몬스터 이름을 크게 강조하고, 도감 번호와 종족은 아랫줄에
		if newTribe then
			ns.Toast:Show("새로운 종족 발견!", name, def.icon, "tribe", { creature = name }, no .. "  " .. def.name)
		else
			ns.Toast:Show("새로운 생물 발견!", name, def.icon, "species", { creature = name }, no .. "  " .. def.name)
		end
	end
	if ns.db.chat and not ns.db.toast and not newTribe and not IsRare(c.cls) then -- 팝업을 끈 경우에만 채팅으로 알림
		local lv = c.minL and (" · " .. c.minL .. "레벨") or ""
		ns.Print(Format("도감 등록: {creature} ({tribe}{lv})", { creature = name, tribe = def.name, lv = lv }))
	end
	self:CheckRank(c.tribe)
end

function B:OnRare(name, c, isNew)
	ns.Chronicle:Add("rare", Format(ns.Pick(ns.NARRATIVE.rareSeen), Scene({ rare = Q(name) })) .. Tail(self, c.tribe, "희귀 개체"),
		{ creature = name })
	local def = ns.GetTribe(c.tribe)
	if ns.Toast then
		ns.Toast:Show("희귀 개체 발견!", name, def.icon, "rare", { creature = name }, self:FormatNo(c.tribe) .. "  " .. def.name)
	end
	self:CheckRank(c.tribe)
end

------------------------------------------------------------------------
-- 처치 집계
------------------------------------------------------------------------
-- 같은 처치가 '죽음 감지'와 '경험치 메시지' 두 경로로 들어올 수 있어 짧은 시간 안의 중복을 상쇄한다
function B:CountKill(name, src)
	if not ns.char or not name or name == "" then return end
	local now = GetTime()
	local r = self.recentKill[name]
	if r and now - r.t < 4 and r.src ~= src and r.n > 0 then
		r.n = r.n - 1
		return
	end
	if r and now - r.t < 4 and r.src == src then
		r.n, r.t = r.n + 1, now
	else
		self.recentKill[name] = { t = now, src = src, n = 1 }
	end

	local d = self.dex
	local c = d.creatures[name]
	if not c then
		d.pending[name] = (d.pending[name] or 0) + 1
		d.totalKills = (d.totalKills or 0) + 1
		return
	end
	c.kills = c.kills + 1
	c.lastKill = time()
	d.totalKills = (d.totalKills or 0) + 1
	self.cache = nil

	if IsRare(c.cls) and not c.rareKilled then
		c.rareKilled = time()
		ns.Chronicle:Add("rare", Format(ns.Pick(ns.NARRATIVE.rareKilled), Scene({ rare = Q(name) })) .. Tail(self, c.tribe, "희귀 개체 처치"),
			{ creature = name })
	elseif c.cls == "worldboss" and not c.bossKilled then
		c.bossKilled = time()
		ns.Chronicle:Add("rare", Format(ns.Pick(ns.NARRATIVE.bossKilled), Scene({ creature = Q(name) })) .. Tail(self, c.tribe, "우두머리 처치"),
			{ creature = name })
	end
	self:CheckMilestones(c.tribe)
	self:CheckRank(c.tribe)
	ns:Fire("DEX_UPDATED", name)
end

function B:OnUnitHealth(_, unit)
	if unit == "target" or (type(unit) == "string" and unit:find("^nameplate")) then
		self:CheckDeath(unit)
	end
end

function B:CheckDeath(unit)
	if not unit or not ns.char then return end
	local Call = ns.Call
	local guid = Call(UnitGUID, unit)
	if not guid then return end
	local name = self.alive[guid]
	if not name then return end
	if not Call(UnitIsDead, unit) then return end
	self.alive[guid] = nil
	self.aliveCount = math.max(0, self.aliveCount - 1)
	if Call(UnitIsTapDenied, unit) then return end -- 다른 사람이 선점한 몬스터
	self:CountKill(name, "death")
end

-- 전역 문자열("%s|1을;를; 처치하여 ...")을 Lua 패턴으로 바꾼다.
-- %s 바로 뒤의 조사 코드는 패턴에서 빼고, 캡처한 이름 끝에서 떼어 낼 조사 목록으로 돌려준다.
local function GlobalToPattern(fmt)
	local p = fmt:gsub("%%%d%$", "%%")
	local suffixes = {}
	p = p:gsub("%%s|1([^;]*);([^;]*);", function(a, b)
		suffixes[#suffixes + 1] = a
		suffixes[#suffixes + 1] = b
		return "%s"
	end)
	p = p:gsub("|1[^;]*;[^;]*;", "\001"):gsub("|4[^;]*;", "\001")
	p = p:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
	p = p:gsub("%%s", "\002"):gsub("%%d", "\003")
	p = p:gsub("\001", ".-"):gsub("\002", "(.-)"):gsub("\003", "[%%d,%%.]+")
	return "^" .. p .. "$", suffixes
end
B.GlobalToPattern = GlobalToPattern

function B:BuildXPPatterns()
	local list = {}
	local bases = { "COMBATLOG_XPGAIN_FIRSTPERSON", "COMBATLOG_XPGAIN_EXHAUSTION1", "COMBATLOG_XPGAIN_EXHAUSTION2",
		"COMBATLOG_XPGAIN_EXHAUSTION4", "COMBATLOG_XPGAIN_EXHAUSTION5" }
	for _, base in ipairs(bases) do
		for _, suffix in ipairs({ "", "_GROUP", "_RAID" }) do
			local s = _G[base .. suffix]
			if type(s) == "string" and s:find("%%s") then
				local pattern, suffixes = GlobalToPattern(s)
				list[#list + 1] = { p = pattern, suffixes = suffixes }
			end
		end
	end
	table.sort(list, function(a, b) return #a.p > #b.p end)
	self.xpPatterns = list
end

-- 경험치 메시지에서 뽑은 이름을 정리한다 (조사 떼기)
function B:CleanXPName(name, suffixes)
	name = name:gsub("|1[^;]*;[^;]*;$", "")
	local d = self.dex
	if d.creatures[name] then return name end
	for _, suf in ipairs(suffixes) do
		if suf ~= "" and #name > #suf and name:sub(-#suf) == suf then
			return (name:sub(1, #name - #suf):gsub("%s+$", ""))
		end
	end
	return name
end

function B:OnXPMessage(_, msg)
	msg = ns.Safe(msg)
	if type(msg) ~= "string" then return end
	for _, entry in ipairs(self.xpPatterns) do
		local name = msg:match(entry.p)
		if name then
			name = self:CleanXPName(name, entry.suffixes)
			if name ~= "" then self:CountKill(name, "xp") end
			return
		end
	end
end

------------------------------------------------------------------------
-- 통계 / 등급
------------------------------------------------------------------------
local function NewStats(id)
	return { id = id, species = 0, kills = 0, rares = 0, bosses = 0, elites = 0, zones = {}, zoneCount = 0, list = {}, rareList = {} }
end

local function AddToStats(s, name, c)
	s.species = s.species + 1
	if not s.first or (c.first or 0) < s.first then
		s.first, s.firstName, s.firstZone, s.firstLvl = c.first, name, c.zone, c.plvl
	end
	s.kills = s.kills + (c.kills or 0)
	if IsRare(c.cls) then
		s.rares = s.rares + 1
		s.rareList[#s.rareList + 1] = name
	end
	if c.cls == "elite" or c.cls == "rareelite" then s.elites = s.elites + 1 end
	if c.boss or c.cls == "worldboss" then s.bosses = s.bosses + 1 end
	for z, n in pairs(c.zones) do
		if not s.zones[z] then s.zoneCount = s.zoneCount + 1 end
		s.zones[z] = (s.zones[z] or 0) + n
	end
	s.list[#s.list + 1] = name
end

local function Finish(self, s)
	s.score = s.species * 10 + s.kills + s.rares * 50 + s.bosses * 20
	s.discovered = self.dex.tribes[s.id] ~= nil and s.species > 0
	s.rank, s.rankDef, s.nextDef = B.RankFor(s.score, s.discovered)
	local creatures = self.dex.creatures
	table.sort(s.list, function(a, b) return (creatures[a].order or 0) < (creatures[b].order or 0) end)
	return s
end

function B:CollectTribe(id)
	local s = NewStats(id)
	for name, c in pairs(self.dex.creatures) do
		if c.tribe == id then AddToStats(s, name, c) end
	end
	return Finish(self, s)
end

-- 모든 종족의 통계 (UI용, 변경 시까지 캐시)
function B:CollectAll()
	if self.cache then return self.cache end
	local all = {}
	for name, c in pairs(self.dex.creatures) do
		local s = all[c.tribe]
		if not s then
			s = NewStats(c.tribe)
			all[c.tribe] = s
		end
		AddToStats(s, name, c)
	end
	for _, s in pairs(all) do Finish(self, s) end
	self.cache = all
	return all
end

function B:CheckRank(id)
	local t = self.dex.tribes[id]
	if not t then return end
	local s = self:CollectTribe(id)
	local old = t.rank or 2
	if s.rank > old then
		t.rank = s.rank
		local def = ns.GetTribe(id)
		local N = ns.NARRATIVE
		local stars = B.Stars(s.rankDef.stars)
		local prose = N.rankUp[s.rank] and Format(ns.Pick(N.rankUp[s.rank]), { tribe = def.phrase or def.name }) or ""
		local text = prose .. " " .. Format(N.rankUpTail, { tribe = def.name, stars = stars, rank = s.rankDef.name })
		if s.rank == 3 or s.rank == 4 then text = text .. " " .. N.loreUnlocked end
		ns.Chronicle:Add("milestone", ns.Trim(text), { tribe = id })
		if ns.Toast then
			ns.Toast:Show("연구 등급 상승!", def.name .. "  " .. B.Stars(s.rankDef.stars) .. "  " .. s.rankDef.name, def.icon, "rank", { tribe = id })
		end
	end
end

function B:CheckMilestones(id)
	local t = self.dex.tribes[id]
	if not t then return end
	local s = self:CollectTribe(id)
	local def = ns.GetTribe(id)
	local km = t.km or 0
	for i = km + 1, #KILL_STEPS do
		local step = KILL_STEPS[i]
		if s.kills >= step.n then
			t.km = i
			local short = def.short or def.name
			local title = step.title:gsub("{tribe}", short)
			local tpl = ns.NARRATIVE.killStep[i] or ns.NARRATIVE.killStep[1]
			ns.Chronicle:Add("milestone", Format(tpl, {
				tribe = short, n = ns.Comma(step.n), unit = def.unit or "마리", title = Q(title),
			}) .. Tail(self, id, "처치 " .. ns.Comma(step.n)), { tribe = id, killStep = step.n })
		else
			break
		end
	end
end

------------------------------------------------------------------------
-- 종족 목록 / 재분류
------------------------------------------------------------------------
-- 도감 순서대로 (정적 종족 → 발견한 야수 계통)
function B:GetTribeList()
	local list = {}
	for _, t in ipairs(ns.TRIBES) do list[#list + 1] = t end
	local dyn = {}
	for id in pairs(self.dex.dyn) do dyn[#dyn + 1] = id end
	table.sort(dyn, function(a, b) return self.dex.dyn[a] < self.dex.dyn[b] end)
	for _, id in ipairs(dyn) do
		local t = ns.GetTribe(id)
		if t then list[#list + 1] = t end
	end
	return list
end

function B:Completion()
	local found = 0
	local all = self:CollectAll()
	for _, t in ipairs(ns.TRIBES) do
		if self.dex.tribes[t.id] and all[t.id] then found = found + 1 end
	end
	local species, rares = 0, 0
	for _, c in pairs(self.dex.creatures) do
		species = species + 1
		if IsRare(c.cls) then rares = rares + 1 end
	end
	local dynCount = 0
	for _ in pairs(self.dex.dyn) do dynCount = dynCount + 1 end
	return found, #ns.TRIBES, species, rares, self.dex.totalKills or 0, dynCount
end

-- 사용자가 종족을 직접 지정 (tribeId가 nil이면 자동 분류로 되돌림)
function B:SetTribe(name, tribeId)
	local d = self.dex
	local c = d.creatures[name]
	if not c then return end
	if tribeId then
		d.overrides[name] = tribeId
		c.tribe = tribeId
	else
		d.overrides[name] = nil
		c.tribe = self:Classify(name, c.ctype, c.family)
	end
	self:EnsureTribe(c.tribe, name, c, true)
	self.cache = nil
	ns:Fire("DEX_UPDATED", name)
end

------------------------------------------------------------------------
-- 툴팁
------------------------------------------------------------------------
function B:AddTooltipInfo(tooltip)
	if not ns.char or not ns.db.tooltip then return end
	local _, unit = ns.Call(tooltip.GetUnit, tooltip)
	if not unit then return end
	if ns.Call(UnitIsPlayer, unit) then return end
	self:SafeScan(unit)
	local name = ns.Call(UnitName, unit)
	local c = name and self.dex.creatures[name]
	if not c then return end
	local def = ns.GetTribe(c.tribe)
	if not def then return end
	local line = "|cffd4af37[도감]|r " .. self:FormatNo(c.tribe) .. " " .. def.name
	if c.kills > 0 then line = line .. "  ·  처치 " .. ns.Comma(c.kills) end
	tooltip:AddLine(line, 0.9, 0.85, 0.7)
end

function B:HookTooltip()
	local function handler(tooltip)
		if tooltip ~= GameTooltip then return end
		local ok, err = pcall(B.AddTooltipInfo, B, tooltip)
		if not ok then ns:Error(err) end
	end
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, handler)
	elseif GameTooltip and GameTooltip.HookScript then
		pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", handler)
	end
end
