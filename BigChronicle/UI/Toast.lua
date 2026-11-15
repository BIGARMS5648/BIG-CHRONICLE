-- BIG CHRONICLE :: 알림 팝업
-- 새로운 종족/개체/희귀 개체/업적을 발견하면 화면 위쪽에 테이프 붙은 포스트잇이 툭 떨어진다

local ADDON, ns = ...
local UI = ns.UI
local Toast = {}
ns.Toast = Toast

local STYLE = {
	tribe   = { hold = 5.0, sound = { "UI_EPICLOOT_TOAST", "IG_QUEST_LIST_COMPLETE" } },
	species = { hold = 3.0, sound = { "IG_QUEST_LOG_OPEN" } },
	rare    = { hold = 6.0, sound = { "UI_LEGENDARY_LOOT_TOAST", "UI_EPICLOOT_TOAST", "RAID_WARNING" } },
	rank    = { hold = 5.0, sound = { "UI_EPICLOOT_TOAST", "LEVELUPSOUND" } },
	achievement = { hold = 5.0, sound = { "UI_ALERT_ACHIEVEMENT", "UI_EPICLOOT_TOAST", "LEVELUPSOUND" } },
}

local OPEN, FADE_OUT = 0.35, 0.7
local TOP_Y, DROP = -120, 46

-- 알림 종류별 포스트잇 색
local NOTE = {
	species     = { 1.00, 0.93, 0.52 },
	tribe       = { 0.72, 0.95, 0.68 },
	rare        = { 0.86, 0.76, 1.00 },
	rank        = { 1.00, 0.80, 0.60 },
	achievement = { 1.00, 0.88, 0.55 },
}
-- 알림 종류별로 튀는 조각 (색종이 / 잉크 방울)
local BURST = {
	achievement = { colors = { { 0.93, 0.47, 0.40 }, { 0.97, 0.80, 0.35 }, { 0.50, 0.68, 0.90 }, { 0.52, 0.76, 0.48 } }, count = 30 },
	rank        = { colors = { { 0.97, 0.80, 0.35 }, { 0.93, 0.47, 0.40 } }, count = 20 },
	rare        = { colors = { { 0.42, 0.20, 0.62 }, { 0.30, 0.12, 0.48 } }, count = 18, tex = "ink" },
	tribe       = { colors = { { 0.52, 0.76, 0.48 }, { 0.97, 0.80, 0.35 } }, count = 20 },
	species     = { colors = { { 0.97, 0.85, 0.40 } }, count = 8 },
}
local MAX_QUEUE = 4
local WIDTH, HEIGHT = 350, 98

function Toast:Init()
	self.queue = {}
end

function Toast:Build()
	if self.frame then return end
	UI:InitTheme()
	local f = CreateFrame("Frame", "BigChronicleToast", UIParent)
	f:SetSize(WIDTH, HEIGHT)
	f:SetPoint("TOP", UIParent, "TOP", 0, TOP_Y)
	f:SetFrameStrata("DIALOG")
	f:Hide()

	local note = f:CreateTexture(nil, "BACKGROUND")
	note:SetPoint("TOPLEFT", -8, 6)
	note:SetPoint("BOTTOMRIGHT", 14, -16)
	note:SetTexture(UI.TEX.sticky)
	f.note = note
	local tape = UI.Tape(f, 84, 24, -0.07)
	tape:SetPoint("CENTER", f, "TOP", -6, 2)

	local icon = f:CreateTexture(nil, "ARTWORK")
	icon:SetSize(42, 42)
	icon:SetPoint("LEFT", 16, -4)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.icon = icon
	local frameLine = CreateFrame("Frame", nil, f)
	frameLine:SetPoint("TOPLEFT", icon, -2, 2)
	frameLine:SetPoint("BOTTOMRIGHT", icon, 2, -2)
	UI.Outline(frameLine, { 0.20, 0.14, 0.08, 0.7 })

	local title = UI.Text(f, UI.F.heading)
	title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, 4)
	title:SetPoint("RIGHT", -14, 0)
	f.title = title

	local body = UI.Text(f, UI.F.body)
	body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
	body:SetPoint("RIGHT", -14, 0)
	body:SetWordWrap(false)
	body:SetTextColor(0.16, 0.13, 0.10)
	f.body = body

	local seal = ns.Effects.MakeSeal(f, 60, "ach")
	seal:SetPoint("TOPRIGHT", -10, -6)
	f.seal = seal

	local brand = UI.Text(f, UI.F.tiny)
	brand:SetPoint("BOTTOMRIGHT", -14, 8)
	brand:SetJustifyH("RIGHT")
	brand:SetTextColor(0.35, 0.30, 0.24)
	f.brand = brand

	f:EnableMouse(true)
	-- 누르면 알림에 나온 몬스터(또는 업적)의 페이지로 바로 간다
	f:SetScript("OnMouseUp", function(self, btn)
		if btn == "LeftButton" then Toast:OpenLink(self.link) end
		Toast:Next()
	end)

	local function place(dy)
		f:ClearAllPoints()
		f:SetPoint("TOP", UIParent, "TOP", 0, TOP_Y + dy)
	end
	-- 포스트잇이 툭 떨어져 붙었다가, 잠시 뒤 떼어져 사라진다
	f:SetScript("OnUpdate", function(self, elapsed)
		self.t = (self.t or 0) + elapsed
		local hold = self.hold or 3
		local E = ns.Effects
		if self.t < OPEN then
			local p = self.t / OPEN
			place(DROP * (1 - E.Ease.outBack(p)))
			self:SetAlpha(math.min(1, p * 2))
		elseif self.pendingFX then
			-- 붙는 순간: 조각이 튀고, 업적이면 밀랍 인장이 쾅
			local kind = self.pendingFX
			self.pendingFX = nil
			place(0)
			self:SetAlpha(1)
			local b = BURST[kind]
			if b then
				E.BurstAt(self, { colors = b.colors, count = b.count, speed = 150,
					tex = b.tex == "ink" and UI.TEX.ink or nil, minSize = b.tex and 4 or nil, maxSize = b.tex and 9 or nil })
			end
			if kind == "achievement" then E.Stamp(self.seal, "toast-seal") end
		elseif self.t < OPEN + hold then
			-- 가만히 붙어 있는다
		elseif self.t < OPEN + hold + FADE_OUT then
			local p = (self.t - OPEN - hold) / FADE_OUT
			self:SetAlpha(1 - p)
			place(18 * p)
		else
			Toast:Next()
		end
	end)
	self.frame = f
end

local function PlayStyleSound(style)
	if not (ns.db and ns.db.sound) or not SOUNDKIT or not PlaySound then return end
	for _, key in ipairs(style.sound) do
		local id = SOUNDKIT[key]
		if id then
			pcall(PlaySound, id)
			return
		end
	end
end

-- link: { creature = 이름 } / { tribe = 종족 id } / { ach = 업적 id }
function Toast:Show(title, body, icon, kind, link)
	if not (ns.db and ns.db.toast) then return end
	self.queue = self.queue or {}
	if #self.queue >= MAX_QUEUE then
		-- 대기열이 넘치면 평범한 개체 알림부터 버린다
		for i = 1, #self.queue do
			if self.queue[i].kind == "species" then
				table.remove(self.queue, i)
				break
			end
		end
		if #self.queue >= MAX_QUEUE then
			if kind == "species" then return end
			table.remove(self.queue, 1)
		end
	end
	table.insert(self.queue, { title = title, body = body, icon = icon, kind = kind or "species", link = link })
	self:Build()
	if not self.frame:IsShown() then self:Next() end
end

function Toast:Next()
	local f = self.frame
	if not f then return end
	local item = table.remove(self.queue, 1)
	if not item then
		f:Hide()
		return
	end
	local style = STYLE[item.kind] or STYLE.species
	local tint = NOTE[item.kind] or NOTE.species
	f.note:SetVertexColor(tint[1], tint[2], tint[3])
	f.icon:SetTexture(item.icon or ns.ICON)
	f.title:SetText(UI.PenText(item.title))
	-- 포스트잇 위의 글씨는 테마와 상관없이 잉크 색
	if item.kind == "rare" then
		f.title:SetTextColor(0.42, 0.16, 0.58)
	elseif item.kind == "achievement" or item.kind == "rank" then
		f.title:SetTextColor(0.66, 0.16, 0.10)
	else
		f.title:SetTextColor(0.12, 0.21, 0.44)
	end
	f.body:SetText(item.body)
	f.link = item.link
	f.brand:SetText(item.link and (item.link.ach and "눌러서 업적 보기" or "눌러서 도감 보기") or "BIG CHRONICLE")
	f.hold = style.hold
	f.t = 0
	f.pendingFX = item.kind
	f.seal:Hide()
	f.body:SetPoint("RIGHT", item.kind == "achievement" and -70 or -14, 0)
	f.title:SetPoint("RIGHT", item.kind == "achievement" and -70 or -14, 0)
	f:SetAlpha(0)
	f:Show()
	PlayStyleSound(style)
end

function Toast:OpenLink(link)
	local UI = ns.UI
	if not UI or not UI.Open then return end
	if link and link.ach then
		UI:Open("achievements")
		if ns.AchievementsTab.Focus then ns.AchievementsTab:Focus(link.ach) end
	elseif link and link.creature then
		UI:Open("bestiary")
		ns.BestiaryTab:FocusCreature(link.creature)
	elseif link and link.tribe then
		UI:Open("bestiary")
		ns.BestiaryTab:SelectTribe(link.tribe)
	else
		UI:Open("bestiary")
	end
end
