-- BIG CHRONICLE :: 알림 팝업
-- 새로운 종족/개체/희귀 개체 발견 시 화면 위쪽에 작은 두루마리가 펼쳐지듯 나타난다

local ADDON, ns = ...
local UI = ns.UI
local Toast = {}
ns.Toast = Toast

local STYLE = {
	tribe   = { hold = 5.0, sound = { "UI_EPICLOOT_TOAST", "IG_QUEST_LIST_COMPLETE" } },
	species = { hold = 3.0, sound = { "IG_QUEST_LOG_OPEN" } },
	rare    = { hold = 6.0, sound = { "UI_LEGENDARY_LOOT_TOAST", "UI_EPICLOOT_TOAST", "RAID_WARNING" } },
	rank    = { hold = 5.0, sound = { "UI_EPICLOOT_TOAST", "LEVELUPSOUND" } },
}

local OPEN, FADE_OUT = 0.3, 0.8
local MAX_QUEUE = 4
local HEIGHT = 66

function Toast:Init()
	self.queue = {}
end

function Toast:Build()
	if self.frame then return end
	UI:InitTheme()
	local col = UI.COL
	local f = CreateFrame("Frame", "BigChronicleToast", UIParent)
	f:SetSize(360, HEIGHT)
	f:SetPoint("TOP", UIParent, "TOP", 0, -140)
	f:SetFrameStrata("DIALOG")
	f:SetClipsChildren(true)
	UI.Paper(f, { vignette = 16 })
	f:Hide()

	local holder = CreateFrame("Frame", nil, UIParent)
	holder:SetFrameStrata("DIALOG")
	holder:SetAllPoints(f)
	local topRoller = UI.Roller(holder, "TOP", 10)
	local bottomRoller = UI.Roller(holder, "BOTTOM", 10)
	holder:Hide()
	f.holder = holder

	local icon = f:CreateTexture(nil, "ARTWORK")
	icon:SetSize(40, 40)
	icon:SetPoint("LEFT", 16, 0)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.icon = icon
	local ring = CreateFrame("Frame", nil, f)
	ring:SetPoint("TOPLEFT", icon, -2, 2)
	ring:SetPoint("BOTTOMRIGHT", icon, 2, -2)
	UI.Outline(ring, { col.edge[1], col.edge[2], col.edge[3], 0.8 })

	local title = UI.Text(f, UI.F.heading)
	title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, 0)
	title:SetPoint("RIGHT", -14, 0)
	f.title = title

	local body = UI.Text(f, UI.F.body)
	body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	body:SetPoint("RIGHT", -14, 0)
	body:SetWordWrap(false)
	f.body = body

	local brand = UI.Text(f, UI.F.tiny)
	brand:SetPoint("BOTTOMRIGHT", -12, 7)
	brand:SetJustifyH("RIGHT")
	brand:SetText("BIG CHRONICLE")

	f:EnableMouse(true)
	f:SetScript("OnMouseUp", function(_, btn)
		if btn == "LeftButton" and ns.UI and ns.UI.Open then ns.UI:Open("bestiary") end
		Toast:Next()
	end)

	-- 두루마리가 위아래로 펼쳐졌다가 사라진다
	f:SetScript("OnUpdate", function(self, elapsed)
		self.t = (self.t or 0) + elapsed
		local hold = self.hold or 3
		if self.t < OPEN then
			local k = self.t / OPEN
			k = 1 - (1 - k) * (1 - k)
			self:SetHeight(math.max(4, HEIGHT * k))
			self:SetAlpha(1)
			self.holder:SetAlpha(1)
		elseif self.t < OPEN + hold then
			self:SetHeight(HEIGHT)
			self:SetAlpha(1)
		elseif self.t < OPEN + hold + FADE_OUT then
			local a = 1 - (self.t - OPEN - hold) / FADE_OUT
			self:SetAlpha(a)
			self.holder:SetAlpha(a)
		else
			Toast:Next()
		end
	end)
	f:SetScript("OnShow", function(self) self.holder:Show() end)
	f:SetScript("OnHide", function(self) self.holder:Hide() end)
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

function Toast:Show(title, body, icon, kind)
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
	table.insert(self.queue, { title = title, body = body, icon = icon, kind = kind or "species" })
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
	local col = UI.COL
	local style = STYLE[item.kind] or STYLE.species
	f.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_Book_09")
	f.title:SetText(item.title)
	local tc = (item.kind == "rare" and col.rare) or (item.kind == "tribe" and col.good) or col.accent
	f.title:SetTextColor(tc[1], tc[2], tc[3])
	f.body:SetText(item.body)
	f.hold = style.hold
	f.t = 0
	f:SetHeight(4)
	f:Show()
	PlayStyleSound(style)
end
