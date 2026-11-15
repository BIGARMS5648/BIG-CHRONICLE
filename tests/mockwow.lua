-- Minimal WoW API mock for exercising BIG CHRONICLE in plain Lua 5.1
local M = {}
_G.MOCK = M

M.chat = {}
M.timers = {}
M.tickers = {}
M.now = 1763200000 -- fixed epoch
M.gt = 1000
M.state = {
	level = 32, zone = "가시덤불 골짜기", sub = "무법항", money = 1234567,
	inInstance = false, instanceType = "none", instanceName = nil, group = 0,
	units = {},
}

function time(t) if t then return os.time(t) end return M.now end
function date(fmt, t) return os.date(fmt, t or M.now) end
function GetTime() return M.gt end
function M.advance(sec) M.now = M.now + sec; M.gt = M.gt + sec end

strsplit = function(sep, s)
	local out = {}
	for piece in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = piece end
	return unpack(out)
end
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
tinsert, tremove = table.insert, table.remove
format = string.format
UNKNOWNOBJECT, UNKNOWN = "알 수 없음", "알 수 없음"

-- 전투 메시지 전역 문자열 (koKR 풍)
COMBATLOG_XPGAIN_FIRSTPERSON = "%s|1을;를; 처치하여 경험치를 %d 획득했습니다."
COMBATLOG_XPGAIN_FIRSTPERSON_GROUP = "%s|1을;를; 처치하여 경험치를 %d 획득했습니다. (+%d 파티 보너스)"
COMBATLOG_XPGAIN_EXHAUSTION1 = "%s|1을;를; 처치하여 경험치를 %d 획득했습니다. (%s 경험치 %s 휴식 보너스)"

---------------------------------------------------------------------
-- universal widget object
---------------------------------------------------------------------
local Obj = {}
local ObjMT = {}
ObjMT.__index = function(t, k)
	local m = Obj[k]
	if m then return m end
	-- WoW API 메서드(대문자로 시작)는 아무것도 하지 않는 함수로, 애드온이 붙인 필드는 nil로
	if type(k) == "string" and k:match("^[A-Z]") then
		return function() return nil end
	end
	return nil
end
M.frames = {}

local seq = 0
local function New(kind, name, parent)
	seq = seq + 1
	local o = setmetatable({ __kind = kind, __name = name, __parent = parent, __shown = true, __scripts = {},
		__w = 0, __h = 0, __text = "", __points = {}, __children = {}, __value = 0, __min = 0, __max = 0, __seq = seq }, ObjMT)
	if name then _G[name] = o end
	if parent and rawget(parent, "__children") then table.insert(parent.__children, o) end
	M.frames[#M.frames + 1] = o
	return o
end
M.New = New
M.Obj = Obj

function Obj:CreateTexture(name, layer, _, sub) local o = New("Texture", nil, self); o.__layer = layer or "ARTWORK"; o.__sub = sub or 0; return o end
function Obj:CreateFontString(_, layer, font) local o = New("FontString", nil, self); o.__font = font; o.__layer = layer or "OVERLAY"; o.__sub = 0; return o end
function Obj:CreateAnimationGroup() return New("AnimGroup", nil, self) end
function Obj:SetScript(k, fn) self.__scripts[k] = fn end
function Obj:GetScript(k) return self.__scripts[k] end
function Obj:HookScript(k, fn)
	local old = self.__scripts[k]
	if old then self.__scripts[k] = function(...) old(...); fn(...) end else self.__scripts[k] = fn end
end
function Obj:Fire(k, ...) local fn = self.__scripts[k]; if fn then return fn(self, ...) end end
function Obj:Show() local was = self.__shown; self.__shown = true; if not was then self:Fire("OnShow") end end
function Obj:Hide() local was = self.__shown; self.__shown = false; if was then self:Fire("OnHide") end end
function Obj:SetShown(v) if v then self:Show() else self:Hide() end end
function Obj:IsShown() return self.__shown end
function Obj:IsVisible() return self.__shown end
function Obj:SetSize(w, h) self.__w, self.__h = w, h end
function Obj:SetWidth(w) self.__w = w end
function Obj:SetHeight(h) self.__h = h end
function Obj:GetWidth() return self.__w ~= 0 and self.__w or 300 end
function Obj:GetHeight() return self.__h ~= 0 and self.__h or 200 end
function Obj:GetSize() return self:GetWidth(), self:GetHeight() end
function Obj:SetText(t)
	self.__text = t
	local fs = rawget(self, "__fs")
	if fs then fs.__text = t end
end
function Obj:GetText() return self.__text end
function Obj:GetStringHeight()
	local t = tostring(self.__text or "")
	local w = (self.__w and self.__w > 0) and self.__w or 300
	local perLine = math.max(10, math.floor(w / 7))
	return 14 * math.max(1, math.ceil(#t / perLine))
end
function Obj:GetStringWidth() return #tostring(self.__text or "") * 6 end
function Obj:SetPoint(...) self.__points[#self.__points + 1] = { ... } end
function Obj:ClearAllPoints() self.__points = {} end
function Obj:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function Obj:GetName() return self.__name end
function Obj:GetParent() return self.__parent end
function Obj:SetMinMaxValues(a, b) self.__min, self.__max = a, b end
function Obj:GetMinMaxValues() return self.__min, self.__max end
function Obj:SetValue(v)
	self.__value = v
	if self.__scripts.OnValueChanged then self.__scripts.OnValueChanged(self, v) end
end
function Obj:GetValue() return self.__value end
function Obj:SetChecked(v) self.__checked = v end
function Obj:GetChecked() return self.__checked end
function Obj:GetCenter() return 500, 400 end
function Obj:GetEffectiveScale() return 1 end
function Obj:GetFacing() return rawget(self, "__facing") or 0 end
function Obj:SetFacing(f) self.__facing = f end
function Obj:SetCreature(id) self.__creature = id end
function Obj:HasFocus() return false end
function Obj:SetFontString(fs) self.__fs = fs end
function Obj:IsMouseOver() return false end
function Obj:RegisterEvent(ev) M.registered = M.registered or {}; M.registered[ev] = self end
function Obj:AddMessage(msg) M.chat[#M.chat + 1] = msg end
function Obj:SetBackdrop(b) self.__backdrop = b end
function Obj:GetVerticalScroll() return rawget(self, "__vs") or 0 end
function Obj:SetVerticalScroll(v) self.__vs = v end

function CreateFrame(kind, name, parent, template)
	local o = New(kind, name, parent)
	o.__template = template
	return o
end

UIParent = New("Frame", "UIParent")
Minimap = New("Frame", "Minimap"); Minimap.__w = 140
GameTooltip = New("GameTooltip", "GameTooltip")
GameTooltip.lines = {}
function GameTooltip:AddLine(t) self.lines[#self.lines + 1] = t end
function GameTooltip:GetUnit() return M.tooltipUnitName, M.tooltipUnit end
DEFAULT_CHAT_FRAME = New("Frame", "ChatFrame1")
UISpecialFrames = {}
SlashCmdList = {}
StaticPopupDialogs = {}
function StaticPopup_Show(key) M.lastPopup = key; local d = StaticPopupDialogs[key]; if d and M.autoAccept then d.OnAccept() end end
SOUNDKIT = { IG_QUEST_LOG_OPEN = 1, UI_EPICLOOT_TOAST = 2 }
function PlaySound(id) M.lastSound = id end
function GetCursorPosition() return 0, 0 end
function CreateFont(name) local o = New("Font", name); return o end
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a } end
function InCombatLockdown() return M.inCombat or false end
function ReloadUI() M.reloaded = true end
GameFontNormal = New("Font", "GameFontNormal"); GameFontHighlight = New("Font", "GameFontHighlight")
function Obj:GetFont() return "Fonts\\2002.TTF", 12, "" end
function Obj:SetAlpha(a) self.__alpha = a end
function Obj:GetAlpha() return rawget(self, "__alpha") or 1 end
function Obj:GetFrameLevel() return rawget(self, "__level") or 1 end
function Obj:SetFrameLevel(l) self.__level = l end
function Obj:Click() self:Fire("OnClick", "LeftButton") end
function M.runOnUpdate(elapsed)
	for _, f in ipairs(M.frames) do
		local fn = f.__scripts.OnUpdate
		if fn and f.__shown then fn(f, elapsed) end
	end
end

C_Timer = {
	After = function(sec, fn)
		M.timerSeq = (M.timerSeq or 0) + 1
		M.timers[#M.timers + 1] = { due = M.gt + (sec or 0), seq = M.timerSeq, fn = fn }
	end,
	NewTicker = function(sec, fn) local t = { fn = fn, sec = sec }; M.tickers[#M.tickers + 1] = t; return t end,
}
function M.runTimers()
	local guard = 0
	while #M.timers > 0 and guard < 100 do
		local list = M.timers; M.timers = {}
		table.sort(list, function(a, b) if a.due ~= b.due then return a.due < b.due end return a.seq < b.seq end)
		for _, t in ipairs(list) do t.fn() end
		guard = guard + 1
	end
end
function M.tick(n)
	for _ = 1, n or 1 do
		M.advance(10)
		M.runTimers() -- 실제 게임처럼 지연 호출도 흘려보낸다
		for _, t in ipairs(M.tickers) do if t.sec == 10 then t.fn() end end
	end
end

C_AddOns = { GetAddOnMetadata = function() return "1.0.0" end }
C_QuestLog = { GetTitleForQuestID = function(id) return M.questTitles and M.questTitles[id] end }

-- unit API
local S = M.state
local function U(unit) return S.units[unit] end
function UnitExists(u) return u == "player" or U(u) ~= nil end
function UnitLevel(u) if u == "player" then return S.level end local x = U(u); return x and x.level end
function UnitName(u) if u == "player" then return "테스트용사" end local x = U(u); return x and x.name end
function UnitRace() return "인간", "Human" end
function UnitClass() return "전사", "WARRIOR" end
function UnitGUID(u) local x = U(u); return x and x.guid end
function UnitIsPlayer(u) return u == "player" end
function UnitPlayerControlled() return false end
function UnitCanAttack(_, u) local x = U(u); return x and not x.friendly end
function UnitFactionGroup(u) local x = U(u); return x and x.faction end
function UnitCreatureType(u) local x = U(u); return x and x.ctype end
function UnitCreatureFamily(u) local x = U(u); return x and x.family end
function UnitClassification(u) local x = U(u); return x and x.cls or "normal" end
function UnitIsDead(u) local x = U(u); return x and x.dead end
function UnitIsTapDenied() return false end
function UnitIsDeadOrGhost(u) if u == "player" then return S.ghost or false end local x = U(u); return x and x.dead end
function GetZoneText() return S.inInstance and S.instanceName or S.zone end
function GetRealZoneText() return GetZoneText() end
function GetSubZoneText() return S.inInstance and "" or S.sub end
function IsInInstance() return S.inInstance, S.instanceType end
function GetInstanceInfo() return S.instanceName, S.instanceType, 1, "일반", 5, 0, false, S.instanceMap or 0 end
function GetNumGroupMembers() return S.group end
function GetMoney() return S.money end
function GetQuestID() return M.questFrameID end
function GetTitleText() return M.questFrameTitle end
function GetBindLocation() return "무법항" end

-- load addon files
function M.load(dir)
	local ns = {}
	local toc = io.open(dir .. "/BigChronicle.toc"):read("*a")
	for line in toc:gmatch("[^\r\n]+") do
		if not line:match("^##") and line:match("%.lua$") then
			local path = dir .. "/" .. line:gsub("\\", "/")
			local chunk = assert(loadfile(path))
			chunk("BigChronicle", ns)
		end
	end
	M.ns = ns
	return ns
end

function M.fire(event, ...)
	local f = M.ns.eventFrame
	f.__scripts.OnEvent(f, event, ...)
end

function M.setUnit(unit, data)
	S.units[unit] = data
end

local guidN = 0
function M.mob(name, npc, ctype, extra)
	guidN = guidN + 1
	local m = { name = name, ctype = ctype or "인간형", level = 30, guid = string.format("Creature-0-1-0-1-%d-%08X", npc, guidN) }
	for k, v in pairs(extra or {}) do m[k] = v end
	return m
end



---------------------------------------------------------------------
-- 화면 배치 흉내 (미리보기·레이아웃 검사용)
-- 앵커를 실제처럼 풀어서 GetWidth/GetHeight가 진짜 크기를 돌려주게 한다.
---------------------------------------------------------------------
M.ScreenW, M.ScreenH = 1600, 900

local function fontInfo(fs)
	local fo = fs.__font and _G[fs.__font]
	local size = (fo and rawget(fo, "__fontSize")) or 12
	local path = (fo and rawget(fo, "__fontPath")) or ""
	return size, path
end

local function plain(t)
	t = tostring(t or "")
	t = t:gsub("||", "|"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "WW")
	return t
end

local function textWidth(fs, t)
	local size, path = fontInfo(fs)
	local pen = path:find("NanumPen") ~= nil
	local w = 0
	for ch in plain(t):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		if #ch == 1 then w = w + size * (pen and 0.42 or 0.55) else w = w + size * (pen and 0.78 or 0.98) end
	end
	return w
end
M.TextWidth = textWidth

local PT = {
	TOPLEFT = { 0, 1 }, TOP = { 0.5, 1 }, TOPRIGHT = { 1, 1 }, LEFT = { 0, 0.5 }, CENTER = { 0.5, 0.5 },
	RIGHT = { 1, 0.5 }, BOTTOMLEFT = { 0, 0 }, BOTTOM = { 0.5, 0 }, BOTTOMRIGHT = { 1, 0 },
}
M.PT = PT

local resolving = {}
function M.Resolve(o)
	if o == UIParent then return { l = 0, b = 0, w = M.ScreenW, h = M.ScreenH } end
	if resolving[o] then return { l = 0, b = 0, w = 0, h = 0 } end
	resolving[o] = true
	local L, R, T, B, CX, CY
	for _, p in ipairs(o.__points) do
		local point, rel, relPoint, x, y = p[1], p[2], p[3], p[4], p[5]
		if type(rel) == "number" then rel, relPoint, x, y = nil, nil, rel, relPoint end
		if type(rel) == "string" then rel = _G[rel] end
		rel = rel or o.__parent or UIParent
		relPoint = relPoint or point
		x, y = tonumber(x) or 0, tonumber(y) or 0
		local rr = M.Resolve(rel)
		local rp = PT[relPoint] or PT.CENTER
		local ax, ay = rr.l + rr.w * rp[1] + x, rr.b + rr.h * rp[2] + y
		local pp = PT[point] or PT.CENTER
		if pp[1] == 0 then L = ax elseif pp[1] == 1 then R = ax else CX = ax end
		if pp[2] == 0 then B = ay elseif pp[2] == 1 then T = ay else CY = ay end
	end
	local w, h = rawget(o, "__w") or 0, rawget(o, "__h") or 0
	if o.__kind == "FontString" then
		local tw = textWidth(o, o.__text)
		if w == 0 and not (L and R) then w = tw end
		local width = (L and R) and (R - L) or w
		local size = fontInfo(o)
		local lines = 0
		for line in (plain(o.__text) .. "\n"):gmatch("(.-)\n") do
			local lw = textWidth(o, line)
			lines = lines + math.max(1, math.ceil(lw / math.max(1, width) - 0.001))
		end
		if h == 0 and not (T and B) then h = lines * size * 1.2 + (lines - 1) * (rawget(o, "__spacing") or 0) end
	end
	if L and R then w = R - L elseif L then R = L + w elseif R then L = R - w elseif CX then L = CX - w / 2 else L = 0 end
	if T and B then h = T - B elseif B then T = B + h elseif T then B = T - h elseif CY then B = CY - h / 2 else B = 0 end
	resolving[o] = nil
	return { l = L, b = B, w = w, h = h, anchored = #o.__points > 0 }
end

function Obj:GetWidth()
	if #self.__points == 0 then return self.__w ~= 0 and self.__w or (self.__kind == "FontString" and textWidth(self, self.__text) or 0) end
	return M.Resolve(self).w
end
function Obj:GetHeight()
	if #self.__points == 0 and self.__kind ~= "FontString" then return self.__h end
	return M.Resolve(self).h
end
function Obj:GetStringWidth() return textWidth(self, self.__text) end
function Obj:GetStringHeight()
	local saved = self.__h
	self.__h = 0
	local h = M.Resolve(self).h
	self.__h = saved
	return h
end
function Obj:GetCenter()
	local r = M.Resolve(self)
	return r.l + r.w / 2, r.b + r.h / 2
end
function Obj:SetAllPoints(rel)
	self.__points = { { "TOPLEFT", rel or self.__parent, "TOPLEFT", 0, 0 }, { "BOTTOMRIGHT", rel or self.__parent, "BOTTOMRIGHT", 0, 0 } }
end

-- 그리기 정보 기록
function Obj:SetTexture(path, wh, wv) self.__tex = path; self.__wrap = wh; self.__color = nil; self.__grad = nil end
function Obj:SetColorTexture(r, g, b, a) self.__color = { r, g, b, a or 1 }; self.__tex = nil; self.__grad = nil end
function Obj:SetVertexColor(r, g, b, a) self.__vc = { r, g, b, a or 1 } end
function Obj:SetTexCoord(...) self.__tc = { ... } end
function Obj:SetGradient(orient, c1, c2) self.__grad = { orient, { c1.r, c1.g, c1.b, c1.a }, { c2.r, c2.g, c2.b, c2.a } } end
function Obj:SetRotation(r) self.__rot = r end
function Obj:SetDesaturated(v) self.__desat = v end
function Obj:SetFontObject(f) self.__font = f end
function Obj:SetTextColor(r, g, b, a) self.__tcolor = { r, g, b, a or 1 } end
function Obj:SetJustifyH(j) self.__jh = j end
function Obj:SetSpacing(s) self.__spacing = s end
function Obj:SetFrameStrata(s) self.__strata = s end
function Obj:SetScale(s) self.__scale = s end
function Obj:SetClipsChildren(v) self.__clip = v end
function Obj:SetScrollChild(c) self.__scrollChild = c end
function Obj:SetStatusBarColor(r, g, b, a) self.__sbc = { r, g, b, a or 1 } end
function Obj:SetStatusBarTexture(t) self.__sbt = t end
function Obj:SetFont(path, size, flags) self.__fontPath = path; self.__fontSize = size; return true end
function Obj:CopyFontObject(base) self.__fontPath = rawget(base, "__fontPath"); self.__fontSize = rawget(base, "__fontSize") end

-- JSON으로 내보내기 (tests/preview/render.py가 그림으로 그린다)
local function esc(s)
	return '"' .. tostring(s):gsub('[%c"\\]', function(c)
		if c == "\n" then return "\\n" elseif c == '"' then return '\\"' elseif c == "\\" then return "\\\\" end
		return string.format("\\u%04x", c:byte())
	end) .. '"'
end
local function enc(v)
	local t = type(v)
	if t == "table" then
		if #v > 0 or next(v) == nil then
			local out = {}
			for i = 1, #v do out[i] = enc(v[i]) end
			return "[" .. table.concat(out, ",") .. "]"
		end
		local out = {}
		for k, x in pairs(v) do out[#out + 1] = esc(k) .. ":" .. enc(x) end
		return "{" .. table.concat(out, ",") .. "}"
	elseif t == "string" then return esc(v)
	elseif t == "number" then return (v ~= v or v == math.huge or v == -math.huge) and "0" or string.format("%.4f", v)
	elseif t == "boolean" then return tostring(v)
	end
	return "null"
end

function M.Dump(path)
	local nodes = {}
	local function walk(o)
		local kids = {}
		for _, c in ipairs(rawget(o, "__children") or {}) do kids[#kids + 1] = c.__seq end
		local r = M.Resolve(o)
		local fsize, fpath = 0, ""
		if o.__kind == "FontString" or o.__kind == "EditBox" then fsize, fpath = fontInfo(o) end
		local fo = o.__font and _G[o.__font]
		nodes[#nodes + 1] = {
			id = o.__seq, kind = o.__kind, name = o.__name or "", kids = kids,
			shown = o.__shown and true or false, alpha = rawget(o, "__alpha") or 1, level = rawget(o, "__level") or 0,
			strata = rawget(o, "__strata") or "", layer = rawget(o, "__layer") or "", sub = rawget(o, "__sub") or 0,
			l = r.l, b = r.b, w = r.w, h = r.h, anchored = (#o.__points > 0) or o == UIParent,
			tex = rawget(o, "__tex") or "", wrap = rawget(o, "__wrap") or "", color = rawget(o, "__color") or {},
			vc = rawget(o, "__vc") or {}, tc = rawget(o, "__tc") or {}, grad = rawget(o, "__grad") or {},
			rot = rawget(o, "__rot") or 0, desat = rawget(o, "__desat") and true or false,
			text = (o.__kind == "FontString" or o.__kind == "EditBox") and tostring(o.__text or "") or "",
			fsize = fsize, fpath = fpath, fcolor = (fo and rawget(fo, "__tcolor")) or {}, tcolor = rawget(o, "__tcolor") or {},
			fixw = ((rawget(o, "__w") or 0) > 0) or (function()
				local hasL, hasR = false, false
				for _, pt in ipairs(o.__points) do
					if pt[1]:find("LEFT") then hasL = true end
					if pt[1]:find("RIGHT") then hasR = true end
				end
				return hasL and hasR
			end)(),
			pt1 = (o.__points[1] and o.__points[1][1]) or "",
			jh = rawget(o, "__jh") or "", spacing = rawget(o, "__spacing") or 0,
			clip = rawget(o, "__clip") and true or false, scrollChild = rawget(o, "__scrollChild") and o.__scrollChild.__seq or 0,
			vs = rawget(o, "__vs") or 0, sbc = rawget(o, "__sbc") or {}, sbt = rawget(o, "__sbt") or "",
			smin = o.__min or 0, smax = o.__max or 0, sval = o.__value or 0, scale = rawget(o, "__scale") or 1,
		}
		for _, c in ipairs(rawget(o, "__children") or {}) do walk(c) end
	end
	walk(UIParent)
	local f = assert(io.open(path, "w"))
	f:write(enc({ screen = { M.ScreenW, M.ScreenH }, root = UIParent.__seq, nodes = nodes }))
	f:close()
end

return M
