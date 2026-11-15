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
	return function() return nil end
end
M.frames = {}

local function New(kind, name, parent)
	local o = setmetatable({ __kind = kind, __name = name, __parent = parent, __shown = true, __scripts = {},
		__w = 0, __h = 0, __text = "", __points = {}, __children = {}, __value = 0, __min = 0, __max = 0 }, ObjMT)
	if name then _G[name] = o end
	M.frames[#M.frames + 1] = o
	return o
end
M.New = New

function Obj:CreateTexture() return New("Texture", nil, self) end
function Obj:CreateFontString(_, _, font) local o = New("FontString", nil, self); o.__font = font; return o end
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
function Obj:SetText(t) self.__text = t end
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
	After = function(sec, fn) M.timers[#M.timers + 1] = fn end,
	NewTicker = function(sec, fn) local t = { fn = fn, sec = sec }; M.tickers[#M.tickers + 1] = t; return t end,
}
function M.runTimers()
	local guard = 0
	while #M.timers > 0 and guard < 100 do
		local list = M.timers; M.timers = {}
		for _, fn in ipairs(list) do fn() end
		guard = guard + 1
	end
end
function M.tick(n)
	for _ = 1, n or 1 do
		M.advance(10)
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
function GetZoneText() return S.inInstance and S.instanceName or S.zone end
function GetRealZoneText() return GetZoneText() end
function GetSubZoneText() return S.inInstance and "" or S.sub end
function IsInInstance() return S.inInstance, S.instanceType end
function GetInstanceInfo() return S.instanceName, S.instanceType, 1, "일반", 5, 0, false, 33 end
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

return M
