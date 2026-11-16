-- BIG CHRONICLE :: 미니맵 버튼

local ADDON, ns = ...
local M = {}
ns.Minimap = M

local RADIUS_PAD = 10

function M:Init()
	if not Minimap then return end
	local b = CreateFrame("Button", "BigChronicleMinimapButton", Minimap)
	b:SetSize(31, 31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local hl = b.GetHighlightTexture and b:GetHighlightTexture()
	if hl then
		hl:ClearAllPoints()
		hl:SetPoint("CENTER")
		hl:SetSize(34, 34)
	end

	-- 금테를 두른 B.C 메달 (테두리가 그림에 들어 있어서 기본 미니맵 테두리는 쓰지 않는다)
	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetSize(30, 30)
	icon:SetPoint("CENTER")
	icon:SetTexture(ns.ICON)
	b.icon = icon
	-- 새 소식이 있으면 은은하게 빛난다
	local glow = b:CreateTexture(nil, "OVERLAY", nil, 2)
	glow:SetSize(34, 34)
	glow:SetPoint("CENTER", icon, "CENTER", 0, 0)
	glow:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	glow:SetBlendMode("ADD")
	glow:SetVertexColor(1, 0.85, 0.4)
	glow:Hide()
	b.glow = glow

	b:SetScript("OnClick", function(_, btn)
		if not ns.UI then return end
		if btn == "RightButton" then ns.UI:Toggle("bestiary") else ns.UI:Toggle() end
	end)
	b:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			cx, cy = cx / scale, cy / scale
			ns.db.minimap.angle = math.deg(math.atan2(cy - my, cx - mx))
			M:Update()
		end)
	end)
	b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	b:SetScript("OnEnter", function(self)
		if not GameTooltip then return end
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("BIG CHRONICLE", 0.83, 0.69, 0.22)
		if ns.char then
			local found, total, species = ns.Bestiary:Completion()
			GameTooltip:AddLine(string.format("기록 %s개 · 도감 %d/%d 종족 · %s종", ns.Comma(#ns.char.log), found, total, ns.Comma(species)), 1, 1, 1)
		end
		if (M.news or 0) > 0 then
			GameTooltip:AddLine(string.format("새 소식 %d개 — 눌러서 확인하세요", M.news), 0.4, 1, 0.4)
		end
		GameTooltip:AddLine("왼쪽 클릭: 모험 일지", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("오른쪽 클릭: 몬스터 도감", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("드래그: 위치 옮기기", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
	self.button = b
	self:Update()
end

function M:Update()
	local b = self.button
	if not b then return end
	if ns.db.minimap.hide then
		b:Hide()
		return
	end
	b:Show()
	local angle = math.rad(ns.db.minimap.angle or 215)
	local r = (Minimap:GetWidth() or 140) / 2 + RADIUS_PAD
	b:ClearAllPoints()
	b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

function M:Toggle()
	ns.db.minimap.hide = not ns.db.minimap.hide
	self:Update()
	ns.Print("미니맵 버튼: " .. (ns.db.minimap.hide and "숨김" or "보임"))
end

-- 창이 닫혀 있는 동안 생긴 중요한 기록 수 (도감·희귀·업적·연구 등급)
local NEWS = { dex = true, rare = true, achievement = true, milestone = true }
ns:Listen("LOG_ADDED", function(e)
	if not e or not NEWS[e.cat] then return end
	local UI = ns.UI
	if UI and UI.frame and UI.frame:IsShown() then return end
	M.news = (M.news or 0) + 1
	if M.button then ns.Effects.Pulse(M.button.glow, true, { min = 0.15, max = 0.95, speed = 3.2 }) end
end)

function M:ClearNews()
	self.news = 0
	if self.button then ns.Effects.Pulse(self.button.glow, false) end
end
