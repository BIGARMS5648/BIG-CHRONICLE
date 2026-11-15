-- BIG CHRONICLE :: 업적 탭

local ADDON, ns = ...
local UI = ns.UI
local T = {}
ns.AchievementsTab = T

local NAV_W = 206
local ROW_H = 52

T.cat = nil         -- nil = 전체
T.filter = "all"    -- all / done / todo

local function Col(c) return c[1], c[2], c[3] end

local function ValueText(def, cur)
	if def.format == "hours" then
		return string.format("%d / %d시간", math.floor(cur / 3600), math.floor(def.goal / 3600))
	end
	return ns.Comma(cur) .. " / " .. ns.Comma(def.goal)
end

function T:Create(parent)
	local col = UI.COL
	local p = CreateFrame("Frame", nil, parent)
	p:SetAllPoints()
	self.panel = p

	-- 왼쪽: 점수와 분류
	local nav = UI.Section(p)
	nav:SetPoint("TOPLEFT", 0, 0)
	nav:SetPoint("BOTTOMLEFT", 0, 0)
	nav:SetWidth(NAV_W)

	local label = UI.Text(nav, UI.F.tiny)
	label:SetPoint("TOP", 0, -12)
	label:SetJustifyH("CENTER")
	label:SetText("업적 점수")
	local points = nav:CreateFontString(nil, "OVERLAY", UI.F.title)
	points:SetPoint("TOP", label, "BOTTOM", 0, -4)
	self.points = points
	local bar = UI.Bar(nav, NAV_W - 24, 10)
	bar:SetPoint("TOP", points, "BOTTOM", 0, -8)
	self.bar = bar
	local summary = UI.Text(nav, UI.F.small)
	summary:SetPoint("TOP", bar, "BOTTOM", 0, -6)
	summary:SetJustifyH("CENTER")
	self.summary = summary

	self.catRows = {}
	local cats = { { id = nil, name = "전체" } }
	for _, c in ipairs(ns.ACH_CATS) do cats[#cats + 1] = c end
	for i, c in ipairs(cats) do
		local r = UI.NavRow(nav, 22)
		r:SetPoint("TOPLEFT", nav, "TOPLEFT", 0, -92 - (i - 1) * 23)
		r:SetPoint("RIGHT", nav, "RIGHT", 0, 0)
		r.label:SetText(c.name)
		r.cat = c.id
		r.onClick = function()
			T.cat = c.id
			T:Refresh(true)
		end
		self.catRows[i] = r
	end

	local filters = { { "all", "전체" }, { "done", "달성" }, { "todo", "미달성" } }
	self.filterButtons = {}
	local bw = math.floor((NAV_W - 24 - 8) / 3)
	for i, f in ipairs(filters) do
		local b = UI.Button(nav, f[2], bw, 22, function()
			T.filter = f[1]
			T:Refresh(true)
		end)
		b:SetPoint("BOTTOMLEFT", 12 + (i - 1) * (bw + 4), 10)
		self.filterButtons[f[1]] = b
	end

	-- 오른쪽: 목록
	local main = CreateFrame("Frame", nil, p)
	main:SetPoint("TOPLEFT", nav, "TOPRIGHT", 18, 0)
	main:SetPoint("BOTTOMRIGHT", 0, 0)
	local title = main:CreateFontString(nil, "OVERLAY", UI.F.header)
	title:SetPoint("TOPLEFT", 4, -4)
	self.title = title
	local desc = UI.Text(main, UI.F.small)
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
	self.desc = desc
	local rule = UI.Rule(main, 0.4)
	rule:SetPoint("TOPLEFT", 0, -46)
	rule:SetPoint("TOPRIGHT", 0, -46)

	local scroll = UI.Scroll(main)
	scroll:SetPoint("TOPLEFT", 0, -54)
	scroll:SetPoint("BOTTOMRIGHT", -14, 4)
	self.scroll = scroll
	self.pool = UI.Pool(function() return T:CreateRow(scroll.child) end)

	local empty = UI.Text(main, UI.F.body, col.muted)
	empty:SetPoint("CENTER", 0, 0)
	empty:SetJustifyH("CENTER")
	self.empty = empty
	return p
end

function T:CreateRow(parent)
	local col = UI.COL
	local r = CreateFrame("Frame", nil, parent)
	r:SetHeight(ROW_H - 4)
	r:EnableMouse(true)
	local bg = r:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	r.bg = bg
	local hl = r:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	UI.Color(hl, col.hover)
	local icon = r:CreateTexture(nil, "ARTWORK")
	icon:SetSize(36, 36)
	icon:SetPoint("LEFT", 8, 0)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	r.icon = icon
	local name = r:CreateFontString(nil, "OVERLAY", UI.F.heading)
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
	name:SetJustifyH("LEFT")
	r.name = name
	local desc = UI.Text(r, UI.F.small)
	desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
	desc:SetWordWrap(false)
	r.desc = desc
	local pts = r:CreateFontString(nil, "OVERLAY", UI.F.heading)
	pts:SetPoint("TOPRIGHT", -10, -6)
	pts:SetJustifyH("RIGHT")
	r.pts = pts
	local when = UI.Text(r, UI.F.tiny)
	when:SetPoint("BOTTOMRIGHT", -10, 7)
	when:SetJustifyH("RIGHT")
	r.when = when
	local bar = UI.Bar(r, 140, 9)
	bar:SetPoint("BOTTOMRIGHT", -10, 8)
	r.bar = bar
	name:SetPoint("RIGHT", pts, "LEFT", -10, 0)
	desc:SetPoint("RIGHT", bar, "LEFT", -10, 0)
	r:SetScript("OnEnter", function(self)
		if not GameTooltip or not self.def then return end
		local def = self.def
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(def.name, 1, 0.85, 0.4)
		GameTooltip:AddLine(def.desc, 1, 1, 1, true)
		if self.done then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("“" .. (def.flavor or "") .. "”", 0.9, 0.8, 0.6, true)
		else
			local cur = ns.Achievements:Progress(def)
			GameTooltip:AddLine("진행: " .. ValueText(def, cur), 0.7, 0.7, 0.7)
		end
		GameTooltip:Show()
	end)
	r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
	return r
end

function T:OnKey(key)
	if key == "UP" then self.scroll:ScrollBy(-60) return true end
	if key == "DOWN" then self.scroll:ScrollBy(60) return true end
	return false
end

function T:Refresh(resetScroll)
	if not self.panel or not ns.char then return end
	local A = ns.Achievements
	local col = UI.COL
	local ach = ns.char.ach
	if not A.ctx then A.ctx = A:Context() end

	-- 왼쪽
	local done, total, pts, maxPts = A:Summary()
	self.points:SetText(ns.Comma(pts) .. "점")
	self.bar:SetMinMaxValues(0, total)
	self.bar:SetValue(done)
	self.bar.text:SetText(math.floor(done / math.max(1, total) * 100 + 0.5) .. "%")
	self.summary:SetText(string.format("달성 %d / %d   ·   최대 %s점", done, total, ns.Comma(maxPts)))
	for _, r in ipairs(self.catRows) do
		local d, t = A:Summary(r.cat)
		r.right:SetText(d .. "/" .. t)
		r:SetSelected(r.cat == self.cat)
	end
	for id, b in pairs(self.filterButtons) do b:SetSelected(id == self.filter) end

	-- 제목
	local catName = "전체 업적"
	for _, c in ipairs(ns.ACH_CATS) do if c.id == self.cat then catName = c.name end end
	self.title:SetText(catName)
	local d, t, p = A:Summary(self.cat)
	self.desc:SetText(string.format("달성 %d / %d   ·   %s점", d, t, ns.Comma(p)))

	-- 목록
	self.pool:ReleaseAll()
	local width = math.max(200, (self.scroll:GetWidth() or 600) - 6)
	self.scroll.child:SetWidth(width)
	local y = 0
	local shown = 0
	for _, def in ipairs(ns.ACHIEVEMENTS) do
		local isDone = ach.done[def.id] ~= nil
		local pass = (not self.cat or def.cat == self.cat)
			and (self.filter == "all" or (self.filter == "done") == isDone)
		if pass then
			shown = shown + 1
			local r = self.pool:Acquire()
			r:ClearAllPoints()
			r:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", 0, -y)
			r:SetWidth(width)
			r.def, r.done = def, isDone
			if self.focusId == def.id then
				self.focusRowY = y
				UI.FadeIn(r, 0.6)
			end
			r.icon:SetTexture(def.icon)
			r.icon:SetDesaturated(not isDone)
			r.icon:SetAlpha(isDone and 1 or 0.55)
			r.name:SetText(def.name)
			r.desc:SetText(def.desc)
			r.pts:SetText(def.points .. "점")
			if isDone then
				UI.Color(r.bg, col.sel, (col.sel[4] or 0.2) * 0.6)
				r.name:SetTextColor(Col(col.title))
				r.pts:SetTextColor(Col(col.accent))
				r.bar:Hide()
				r.when:Show()
				r.when:SetText(ach.retro[def.id] and "기록 이전에 달성" or ns.FormatShortDate(ach.done[def.id]))
			else
				UI.Color(r.bg, col.shade)
				r.name:SetTextColor(Col(col.sub))
				r.pts:SetTextColor(Col(col.muted))
				r.when:Hide()
				local cur = A:Progress(def, A.ctx)
				if def.goal > 1 then
					r.bar:Show()
					r.bar:SetMinMaxValues(0, def.goal)
					r.bar:SetValue(cur)
					r.bar.text:SetText(ValueText(def, cur))
				else
					r.bar:Hide()
				end
			end
			y = y + ROW_H
		end
	end
	self.scroll:SetContentHeight(y)
	if resetScroll then self.scroll:ScrollToTop() end
	if self.focusId and self.focusRowY then
		self.scroll:ScrollTo(self.focusRowY - 60)
	end
	self.focusId, self.focusRowY = nil, nil
	if shown == 0 then
		self.empty:SetText(self.filter == "done" and "아직 달성한 업적이 없습니다." or "모든 업적을 달성했습니다!")
		self.empty:Show()
	else
		self.empty:Hide()
	end
end

-- 알림에서 특정 업적으로 바로 이동
function T:Focus(id)
	local def = ns.ACH_BY_ID[id]
	if not def or not self.panel then return end
	self.cat = def.cat
	self.filter = "all"
	self.focusId = id
	self:Refresh(true)
end
