-- BIG CHRONICLE :: 알림 팝업
-- 새로운 종족/개체/희귀 개체/업적을 발견하면 화면 위쪽에 양피지 전갈이 내려앉고, 붉은 밀랍 인장이 찍힌다

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

local OPEN, FADE_OUT = 0.45, 0.8
local TOP_Y, DROP = -120, 22

-- 알림 종류별 제목 잉크와 왼쪽 띠 색
local INK = {
	species     = { 0.10, 0.085, 0.07 },
	tribe       = { 0.16, 0.30, 0.12 },
	rare        = { 0.38, 0.14, 0.46 },
	rank        = { 0.66, 0.30, 0.10 },
	achievement = { 0.66, 0.30, 0.10 },
}
-- 알림 종류별로 피어오르는 빛 (금가루 / 보랏빛 불티)
local BURST = {
	achievement = { count = 28 },
	rank        = { count = 18 },
	rare        = { colors = { { 0.78, 0.55, 1.00 }, { 0.62, 0.40, 0.95 }, { 0.95, 0.85, 1.00 } }, count = 22 },
	tribe       = { count = 18 },
	species     = { count = 6 },
}
local MAX_QUEUE = 4
local WIDTH, HEIGHT = 380, 88

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

	-- 가장자리가 그을린 양피지 한 장
	UI.Paper(f, { tint = UI.THEMES.light.page })   -- 알림은 테마와 상관없이 밝은 종이
	local stripe = f:CreateTexture(nil, "BORDER", nil, 3)
	stripe:SetPoint("TOPLEFT", 0, 0)
	stripe:SetPoint("BOTTOMLEFT", 0, 0)
	stripe:SetWidth(3)
	f.stripe = stripe

	local icon = f:CreateTexture(nil, "ARTWORK")
	icon:SetSize(42, 42)
	icon:SetPoint("LEFT", 16, 0)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.icon = icon
	UI.FrameIcon(icon, 4)

	local title = UI.Text(f, UI.F.heading)
	title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, 3)
	title:SetPoint("RIGHT", -74, 0)
	title:SetWordWrap(false)
	f.title = title

	local body = UI.Text(f, UI.F.body)
	body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	body:SetPoint("RIGHT", -74, 0)
	body:SetWordWrap(false)
	body:SetTextColor(0.16, 0.10, 0.06)
	f.body = body

	-- 붉은 밀랍 인장: 업적은 월계관, 도감(종족·개체·희귀·연구 등급)은 용 문장
	local seal = ns.Effects.MakeSeal(f, 64, "ach")
	seal:SetPoint("TOPRIGHT", -8, -3)
	f.seal = seal

	local brand = UI.Text(f, UI.F.tiny)
	brand:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 14, -6)
	brand:SetTextColor(0.42, 0.33, 0.22)
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
	-- 위에서 천천히 내려앉았다가, 잠시 뒤 조용히 사라진다
	f:SetScript("OnUpdate", function(self, elapsed)
		self.t = (self.t or 0) + elapsed
		local hold = self.hold or 3
		local E = ns.Effects
		if self.t < OPEN then
			local p = self.t / OPEN
			place(DROP * (1 - E.Ease.outCubic(p)))
			self:SetAlpha(math.min(1, p * 1.6))
		elseif self.pendingFX then
			-- 자리 잡는 순간: 금가루가 피어오르고 밀랍 인장이 찍힌다
			local kind = self.pendingFX
			self.pendingFX = nil
			place(0)
			self:SetAlpha(1)
			local b = BURST[kind]
			if b then
				E.BurstAt(self, { colors = b.colors, count = b.count, speed = 45, spreadW = 150, life = 1.8 })
			end
			E.Stamp(self.seal, "toast-seal")
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
	-- 양피지 위의 글씨는 테마와 상관없이 잉크 색
	local ink = INK[item.kind] or INK.species
	f.stripe:SetColorTexture(ink[1], ink[2], ink[3], 0.85)
	f.icon:SetTexture(item.icon or ns.ICON)
	f.title:SetText(item.title)
	f.title:SetTextColor(ink[1], ink[2], ink[3])
	f.body:SetText(item.body)
	f.link = item.link
	f.brand:SetText(item.link and (item.link.ach and "눌러서 업적 보기" or "눌러서 도감 보기") or "BIG CHRONICLE")
	f.hold = style.hold
	f.t = 0
	f.pendingFX = item.kind
	f.seal:Hide()
	f.seal.kind = item.kind == "achievement" and "ach" or "dex"
	f.seal.tex:SetTexture(f.seal.kind == "ach" and UI.TEX.sealAch or UI.TEX.sealDex)
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
