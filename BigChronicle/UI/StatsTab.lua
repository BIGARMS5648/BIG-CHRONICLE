-- BIG CHRONICLE :: 연대기 통계 탭

local ADDON, ns = ...
local UI = ns.UI
local S = {}
ns.StatsTab = S

function S:Create(parent)
	local p = CreateFrame("Frame", nil, parent)
	p:SetAllPoints()
	self.panel = p
	local scroll = UI.Scroll(p)
	scroll:SetPoint("TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", -12, 0)
	self.scroll = scroll
	self.pool = UI.Pool(function()
		local fs = scroll.child:CreateFontString(nil, "OVERLAY", UI.F.body)
		fs:SetJustifyH("LEFT")
		fs:SetJustifyV("TOP")
		fs:SetWordWrap(true)
		return fs
	end)
	self.dividerPool = UI.Pool(function() return UI.Divider(scroll.child, 300) end)
	self.shadePool = UI.Pool(function()
		local t = scroll.child:CreateTexture(nil, "BACKGROUND")
		UI.Color(t, UI.COL.shade)
		return t
	end)
	return p
end

function S:OnKey(key)
	if key == "UP" then self.scroll:ScrollBy(-60) return true end
	if key == "DOWN" then self.scroll:ScrollBy(60) return true end
	return false
end

local function Put(self, text, font, color, x, y, w, justify)
	local fs = self.pool:Acquire()
	fs:SetFontObject(font or UI.F.body)
	local c = color or UI.COL.text
	fs:SetTextColor(c[1], c[2], c[3])
	fs:SetJustifyH(justify or "LEFT")
	fs:SetWidth(w or self.width)
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", x or 0, -(y or self.y))
	fs:SetText(UI:Themed(text))
	return fs
end

function S:Line(text, font, color, indent, justify)
	local fs = Put(self, text, font, color, indent or 0, self.y, self.width - (indent or 0), justify)
	self.y = self.y + (fs:GetStringHeight() or 14) + 6
end

-- 소제목: 왼쪽 정렬 강조색 글씨 + 아래 가는 선
function S:Heading(text)
	self.y = self.y + 22
	self:Line(text, UI.F.heading, UI.COL.accent, 0)
	local div = self.dividerPool:Acquire()
	div:ClearAllPoints()
	div:SetWidth(self.width)
	div:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", 0, -self.y)
	self.y = self.y + 12
end

-- 수치 카드: 옅은 바탕 위에 작은 이름과 큰 값. 한 줄에 cols 개씩 놓는다.
function S:Grid(items, cols)
	cols = cols or 4
	local gap = 8
	local tileW = math.floor((self.width - gap * (cols - 1)) / cols)
	local tileH = 56
	local rows = math.ceil(#items / cols)
	for i, it in ipairs(items) do
		local c = (i - 1) % cols
		local r = math.floor((i - 1) / cols)
		local x = c * (tileW + gap)
		local y = self.y + r * (tileH + gap)
		local t = self.shadePool:Acquire()
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", x, -y)
		t:SetSize(tileW, tileH)
		Put(self, it[1], UI.F.label, UI.COL.muted, x + 14, y + 10, tileW - 24)
		Put(self, it[2], UI.F.header, UI.COL.title, x + 14, y + 28, tileW - 24)
	end
	self.y = self.y + rows * (tileH + gap) + 2
end

function S:Refresh()
	if not self.panel then return end
	local db = ns.char
	local B = ns.Bestiary
	local col = UI.COL
	self.pool:ReleaseAll()
	self.dividerPool:ReleaseAll()
	self.shadePool:ReleaseAll()
	self.y = 2
	self.width = math.max(300, (self.scroll:GetWidth() or 800) - 6)
	self.scroll.child:SetWidth(self.width)

	local meta = db.meta or {}
	self:Line((meta.name or ns.PlayerName()) .. "의 연대기", UI.F.title, col.title, 0)
	if db.started then
		self:Line(string.format("%s, %s레벨에 %s에서 기록이 시작되었습니다.", ns.FormatDate(db.started), meta.startLevel or "?",
			meta.startZone or "어딘가"), UI.F.small, col.sub, 0)
	end

	-- 모으기
	local zoneCount, subCount = 0, 0
	for _ in pairs(db.zones) do zoneCount = zoneCount + 1 end
	for _ in pairs(db.subzones) do subCount = subCount + 1 end
	local dungeonKinds, dungeonRuns = 0, 0
	for _, d in pairs(db.dungeons) do
		dungeonKinds = dungeonKinds + 1
		dungeonRuns = dungeonRuns + (d.runs or 0)
	end
	local bossKinds, bossKills = 0, 0
	for _, b in pairs(db.bosses) do
		bossKinds = bossKinds + 1
		bossKills = bossKills + (b.kills or 0)
	end
	local pvp = 0
	for _, n in pairs(db.pvp) do pvp = pvp + n end
	local levelUps, notes = 0, 0
	for _, e in ipairs(db.log) do
		if e.cat == "level" then levelUps = levelUps + 1 end
		if e.cat == "note" then notes = notes + 1 end
	end
	local found, total, species, rares, kills, dynCount = B:Completion()

	self:Heading("모험 요약")
	self:Grid({
		{ "현재 레벨", ns.PlayerLevel() .. "레벨" },
		{ "전기에 남긴 기록", ns.Comma(#db.log) .. "개" },
		{ "기록된 모험 시간", ns.FormatDuration(db.stats.tracked or 0) },
		{ "기록 중 레벨업", levelUps .. "회" },
		{ "방문한 지역", zoneCount .. "곳" },
		{ "발견한 장소", ns.Comma(subCount) .. "곳" },
		{ "완료한 퀘스트", ns.Comma(db.quests.count or 0) .. "개" },
		{ "쓰러진 횟수", (db.deaths or 0) .. "회" },
		{ "던전 원정", string.format("%d회 (%d곳)", dungeonRuns, dungeonKinds) },
		{ "쓰러뜨린 보스", string.format("%d회 (%d명)", bossKills, bossKinds) },
		{ "전장 참전", pvp .. "회" },
		{ "나의 기록", notes .. "개" },
	}, 4)
	if db.stats.played then
		self:Line(string.format("총 플레이 시간 %s   (마지막 /played 확인: %s)", ns.FormatDuration(db.stats.played), ns.FormatDateTime(db.stats.playedAt)),
			UI.F.small, col.sub, 0)
	else
		self:Line("채팅창에 /played 를 입력하면 총 플레이 시간도 함께 기록됩니다.", UI.F.tiny, col.muted, 0)
	end

	self:Heading("몬스터 도감")
	self:Grid({
		{ "발견한 종족", string.format("%d / %d", found, total) },
		{ "발견한 개체", ns.Comma(species) .. "종" },
		{ "희귀 개체", rares .. "종" },
		{ "야수 계통", dynCount .. "종" },
		{ "총 처치", ns.Comma(kills) },
		{ "업적", (function() local d, t, p = ns.Achievements:Summary() return string.format("%d / %d", d, t) end)() },
	}, 3)

	-- 레벨 연대기
	self:Heading("레벨 연대기")
	local lvls = {}
	for l in pairs(db.levels) do lvls[#lvls + 1] = l end
	table.sort(lvls)
	if #lvls == 0 then self:Line("아직 기록이 없습니다.", UI.F.body, col.muted, 0) end
	for i, l in ipairs(lvls) do
		local t = db.levels[l]
		local extra = ""
		local prevLvl = lvls[i - 1]
		local lt, plt = db.levelTracked and db.levelTracked[l], db.levelTracked and prevLvl and db.levelTracked[prevLvl]
		if prevLvl and prevLvl == l - 1 and lt and plt then
			extra = ns.Hex("     이전 레벨부터 " .. ns.FormatDuration(lt - plt) .. " 모험", ns.COLOR.dim)
		elseif i == 1 then
			extra = ns.Hex("     기록 시작", ns.COLOR.dim)
		end
		self:Line(string.format("|cffd4af37%d레벨|r     %s%s", l, ns.FormatDateTime(t), extra), UI.F.body, col.text, 0)
	end

	-- 가장 오래 머문 지역
	self:Heading("가장 오래 머문 지역")
	local zl = {}
	for z, info in pairs(db.zones) do zl[#zl + 1] = { z = z, t = info.time or 0, first = info.first, lvl = info.lvl } end
	table.sort(zl, function(a, b) return a.t > b.t end)
	if #zl == 0 then self:Line("아직 기록이 없습니다.", UI.F.body, col.muted, 0) end
	for i = 1, math.min(8, #zl) do
		local z = zl[i]
		self:Line(string.format("%d.   |cffe6c27a%s|r     %s     %s", i, z.z, ns.FormatDuration(z.t),
			ns.Hex("첫 방문 " .. ns.FormatShortDate(z.first or 0) .. ", " .. (z.lvl or "?") .. "레벨", ns.COLOR.dim)), UI.F.body, col.text, 0)
	end

	-- 가장 많이 쓰러뜨린 몬스터
	self:Heading("가장 많이 쓰러뜨린 몬스터")
	local kl = {}
	for name, c in pairs(B.dex.creatures) do
		if (c.kills or 0) > 0 then kl[#kl + 1] = { name = name, k = c.kills, tribe = c.tribe } end
	end
	table.sort(kl, function(a, b) return a.k > b.k end)
	if #kl == 0 then self:Line("아직 기록이 없습니다.", UI.F.body, col.muted, 0) end
	for i = 1, math.min(8, #kl) do
		local k = kl[i]
		local def = ns.GetTribe(k.tribe)
		self:Line(string.format("%d.   |cff7fd4ff%s|r     %s회     %s", i, k.name, ns.Comma(k.k), ns.Hex(def and def.name or "", ns.COLOR.dim)),
			UI.F.body, col.text, 0)
	end

	-- 던전 원정 기록
	self:Heading("던전 원정 기록")
	local dl = {}
	for name, d in pairs(db.dungeons) do dl[#dl + 1] = { name = name, d = d } end
	table.sort(dl, function(a, b) return (a.d.first or 0) < (b.d.first or 0) end)
	if #dl == 0 then self:Line("아직 원정 기록이 없습니다.", UI.F.body, col.muted, 0) end
	for _, it in ipairs(dl) do
		local d = it.d
		local bossNames = {}
		for bn, n in pairs(d.bosses or {}) do bossNames[#bossNames + 1] = bn .. (n > 1 and ("×" .. n) or "") end
		table.sort(bossNames)
		local best = d.best and ("   ·   최단 " .. ns.FormatDuration(d.best)) or ""
		self:Line(string.format("|cffff9940%s|r     %d회%s     %s", it.name, d.runs or 0, best,
			ns.Hex("첫 원정 " .. ns.FormatShortDate(d.first or 0), ns.COLOR.dim)), UI.F.body, col.text, 0)
		if #bossNames > 0 then
			self:Line("보스: " .. table.concat(bossNames, ", "), UI.F.small, col.sub, 16)
		end
	end

	self.scroll:SetContentHeight(self.y + 10)
end
