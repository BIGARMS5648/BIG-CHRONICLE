-- BIG CHRONICLE :: 알림 팝업
-- 새로운 종족/개체/희귀 개체/업적을 발견하면 화면 위쪽에 양피지 전갈이 내려앉고, 붉은 밀랍 인장이 찍힌다

local ADDON, ns = ...
local UI = ns.UI
local Toast = {}
ns.Toast = Toast

-- 알림 종류별로 머무는 시간 (소리는 밀랍 인장이 찍힐 때의 인장 소리 하나뿐)
local STYLE = {
	tribe   = { hold = 5.0 },
	species = { hold = 3.0 },
	rare    = { hold = 6.0 },
	rank    = { hold = 5.0 },
	achievement = { hold = 5.0 },
}

local OPEN, FADE_OUT = 0.45, 0.8
local TOP_Y, DROP = -120, 22

-- 알림 종류별 제목 잉크와 왼쪽 띠 색
local INK = {
	species     = { 0.19, 0.09, 0.04 },
	tribe       = { 0.16, 0.30, 0.12 },
	rare        = { 0.38, 0.14, 0.46 },
	rank        = { 0.52, 0.11, 0.07 },
	achievement = { 0.52, 0.11, 0.07 },
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
local WIDTH, HEIGHT = 460, 96

function Toast:Init()
	self.queue = {}
	-- 위치 옮기기는 그때그때 켜는 것: 접속할 때는 항상 잠긴 상태로 시작한다
	if ns.db then ns.db.toastLocked = true end
end

-- 알림이 놓일 자리 (화면 위쪽 가운데 기준, 옮겼다면 저장된 자리)
local function Anchor()
	local p = ns.db and ns.db.toastPos
	if type(p) == "table" and tonumber(p.x) and tonumber(p.y) then return p.x, p.y end
	return 0, TOP_Y
end

function Toast:Build()
	if self.frame then return end
	UI:InitTheme()
	local f = CreateFrame("Frame", "BigChronicleToast", UIParent)
	f:SetSize(WIDTH, HEIGHT)
	f:SetPoint("TOP", UIParent, "TOP", Anchor())
	f:SetFrameStrata("DIALOG")
	f:SetClampedToScreen(true)
	f:Hide()

	-- 금 모서리 가죽 액자에 든 양피지 한 장
	UI.Slice(f, "Card", { layer = "BACKGROUND", scale = 0.55 })

	local icon = f:CreateTexture(nil, "ARTWORK")
	icon:SetSize(42, 42)
	icon:SetPoint("LEFT", 30, 0)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.icon = icon
	UI.FrameIcon(icon, 4)

	local title = UI.Text(f, UI.F.heading)
	title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, 3)
	title:SetPoint("RIGHT", -88, 0)
	title:SetWordWrap(false)
	f.title = title

	local body = UI.Text(f, UI.F.body)
	body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	body:SetPoint("RIGHT", -88, 0)
	body:SetWordWrap(false)
	body:SetTextColor(0.16, 0.10, 0.06)
	f.body = body

	-- 붉은 밀랍 인장: 업적은 나침반 별, 도감(종족·개체·희귀·연구 등급)은 사자 문장
	local seal = ns.Effects.MakeSeal(f, 62, "ach")
	seal:SetPoint("RIGHT", -22, 0)
	f.seal = seal

	local brand = UI.Text(f, UI.F.tiny)
	brand:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 14, -6)
	brand:SetTextColor(0.42, 0.33, 0.22)
	f.brand = brand

	f:EnableMouse(true)
	-- 누르면 알림에 나온 몬스터(또는 업적)의 페이지로 바로 간다
	f:SetScript("OnMouseUp", function(self, btn)
		if Toast.moving then
			-- 위치를 옮기는 중: 오른쪽 클릭으로 잠근다
			if btn == "RightButton" and not self.dragged then Toast:SetLocked(true) end
			self.dragged = nil
			return
		end
		-- 예시 알림은 눌러도 아무 페이지도 열지 않고 닫히기만 한다
		if btn == "LeftButton" and not self.sample then Toast:OpenLink(self.link) end
		Toast:Next()
	end)
	-- 잠금을 풀면 끌어서 옮길 수 있다
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		if not Toast.moving then return end
		self.dragged = true
		self:SetMovable(true)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if not Toast.moving then return end
		Toast:SavePosition()
	end)

	local function place(dy)
		local x, y = Anchor()
		f:ClearAllPoints()
		f:SetPoint("TOP", UIParent, "TOP", x, y + dy)
	end
	f.place = place
	-- 위에서 천천히 내려앉았다가, 잠시 뒤 조용히 사라진다
	f:SetScript("OnUpdate", function(self, elapsed)
		if Toast.moving then return end
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

-- 옮긴 자리를 화면 위쪽 가운데 기준으로 저장한다 (해상도나 UI 크기가 바뀌어도 비슷한 곳에 오도록)
function Toast:SavePosition()
	local f = self.frame
	local top, cx = f:GetTop(), f:GetCenter()
	local pw, ph = UIParent:GetWidth(), UIParent:GetHeight()
	if top and cx and pw and ph then
		ns.db.toastPos = { x = math.floor(cx - pw / 2 + 0.5), y = math.floor(top - ph + 0.5) }
	end
	f.place(0)
end

-- 기본 위치(화면 위쪽 가운데)로 되돌리고, 그 자리에 예시 알림을 잠깐 띄워 보여 준다
function Toast:ResetPosition()
	ns.db.toastPos = nil
	self:Build()
	self.frame.place(0)
	ns.Print("알림 위치를 기본 위치(화면 위쪽 가운데)로 되돌렸습니다.")
	-- 위치를 옮기는 중이면 예시 알림이 이미 떠 있으니 자리만 옮긴다
	if self.moving then return end
	self.queue = self.queue or {}
	table.insert(self.queue, 1, { title = "알림 위치", body = "기본 위치에 알림이 나타납니다", kind = "species", sample = true })
	if not self.frame:IsShown() then self:Next() end
end

-- 잠금을 풀면 예시 알림이 떠서 끌어 옮길 수 있고, 잠그면 사라진다
function Toast:SetLocked(locked)
	ns.db.toastLocked = locked and true or false
	self:Build()
	local f = self.frame
	if not locked then
		self.moving = true
		f.t, f.pendingFX, f.link = 0, nil, nil
		f.icon:SetTexture(ns.ICON)
		f.title:SetText("알림 위치")
		f.title:SetTextColor(INK.rank[1], INK.rank[2], INK.rank[3])
		f.body:SetText("끌어서 원하는 곳에 놓으세요")
		f.brand:SetText("오른쪽 클릭하거나 설정에서 잠그면 고정됩니다")
		ns.Effects.SetSeal(f.seal, "dex")
		f.seal:SetAlpha(1)
		f.seal:Show()
		f.place(0)
		f:SetAlpha(1)
		f:Show()
	else
		self.moving = false
		f:StopMovingOrSizing()
		f:Hide()
		-- 옮기는 동안 쌓인 알림을 이어서 보여 준다
		if self.queue and #self.queue > 0 then self:Next() end
	end
	if ns.SettingsTab and ns.SettingsTab.Refresh then ns.SettingsTab:Refresh() end
end

function Toast:Next()
	local f = self.frame
	if not f then return end
	if self.moving then return end
	local item = table.remove(self.queue, 1)
	if not item then
		f:Hide()
		return
	end
	local style = STYLE[item.kind] or STYLE.species
	-- 양피지 위의 글씨는 테마와 상관없이 잉크 색
	local ink = INK[item.kind] or INK.species
	f.icon:SetTexture(item.icon or ns.ICON)
	f.title:SetText(item.title)
	f.title:SetTextColor(ink[1], ink[2], ink[3])
	f.body:SetText(item.body)
	-- 아랫줄이 길면 (긴 업적 이름 등) 한 단계 작은 글씨로
	f.body:SetFontObject(UI.F.body)
	local room = WIDTH - 86 - 88
	if (f.body:GetStringWidth() or 0) > room then f.body:SetFontObject(UI.F.small) end
	f.body:SetTextColor(0.16, 0.10, 0.06)
	f.link, f.sample = item.link, item.sample
	f.brand:SetText(item.sample and "BIG CHRONICLE"
		or (item.link and (item.link.ach and "눌러서 업적 보기" or "눌러서 도감 보기") or "BIG CHRONICLE"))
	f.hold = style.hold
	f.t = 0
	f.pendingFX = item.kind
	f.seal:Hide()
	f.seal.kind = item.kind == "achievement" and "ach" or "dex"
	ns.Effects.SetSeal(f.seal, f.seal.kind)
	f:SetAlpha(0)
	f:Show()
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
