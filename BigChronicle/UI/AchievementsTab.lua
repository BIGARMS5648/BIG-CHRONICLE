-- BIG CHRONICLE :: 업적 탭

local ADDON, ns = ...
local UI = ns.UI
local T = {}
ns.AchievementsTab = T

local NAV_W = 196
local ROW_H = 58

T.cat = nil         -- nil = 전체
T.sessionNew = {}   -- 이번에 처음 본 새 업적 (탭을 떠날 때까지 NEW 표시)
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
	-- 업적 탭을 떠나면 NEW 표시를 지운다
	p:SetScript("OnHide", function()
		wipe(T.sessionNew)
		if self.pool then for _, r in ipairs(self.pool.items) do ns.Effects.Pulse(r.glow, false) end end
	end)

	-- 왼쪽: 점수 요약 + 분류 + 보기 방식
	local nav = CreateFrame("Frame", nil, p)
	nav:SetPoint("TOPLEFT", 0, 0)
	nav:SetPoint("BOTTOMLEFT", 0, 0)
	nav:SetWidth(NAV_W)

	local label = UI.Label(nav, "업적 점수")
	label:SetPoint("TOPLEFT", 0, -6)
	local points = nav:CreateFontString(nil, "OVERLAY", UI.F.big)
	points:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
	self.points = points
	local bar = UI.Bar(nav, NAV_W - 26, 4)
	bar:SetPoint("TOPLEFT", points, "BOTTOMLEFT", 0, -12)
	self.bar = bar
	local summary = UI.Text(nav, UI.F.small)
	summary:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -8)
	self.summary = summary

	local h2 = UI.Label(nav, "분류")
	h2:SetPoint("TOPLEFT", 0, -132)
	self.catRows = {}
	local cats = { { id = nil, name = "전체" } }
	for _, c in ipairs(ns.ACH_CATS) do cats[#cats + 1] = c end
	for i, c in ipairs(cats) do
		local r = UI.NavRow(nav, 26)
		r:SetPoint("TOPLEFT", nav, "TOPLEFT", -12, -154 - (i - 1) * 27)
		r:SetPoint("RIGHT", nav, "RIGHT", -14, 0)
		r.label:SetText(c.name)
		r.cat = c.id
		r.onClick = function()
			T.cat = c.id
			T:Refresh(true)
		end
		self.catRows[i] = r
	end

	-- 보기 방식 (전체 / 달성 / 미달성)
	local filters = { { "all", "전체" }, { "done", "달성" }, { "todo", "미달성" } }
	self.filterButtons = {}
	local bw = math.floor((NAV_W - 26 - 4) / 3)
	for i, f in ipairs(filters) do
		local b = UI.Button(nav, f[2], bw, 26, function()
			T.filter = f[1]
			T:Refresh(true)
		end)
		b:SetPoint("BOTTOMLEFT", (i - 1) * (bw + 2), 0)
		self.filterButtons[f[1]] = b
	end

	local sep = UI.VRule(p)
	sep:SetPoint("TOPLEFT", nav, "TOPRIGHT", 0, 0)
	sep:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT", 0, 0)

	-- 오른쪽: 업적 목록
	local main = CreateFrame("Frame", nil, p)
	main:SetPoint("TOPLEFT", nav, "TOPRIGHT", 26, 0)
	main:SetPoint("BOTTOMRIGHT", 0, 0)
	local title = main:CreateFontString(nil, "OVERLAY", UI.F.title)
	title:SetPoint("TOPLEFT", 0, -2)
	self.title = title
	local desc = UI.Text(main, UI.F.small)
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)
	self.desc = desc
	local rule = UI.Rule(main)
	rule:SetPoint("TOPLEFT", 0, -60)
	rule:SetPoint("TOPRIGHT", 0, -60)

	local scroll = UI.Scroll(main)
	scroll:SetPoint("TOPLEFT", 0, -64)
	scroll:SetPoint("BOTTOMRIGHT", -12, 0)
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
	r:SetHeight(ROW_H)
	r:EnableMouse(true)
	local bg = r:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	r.bg = bg
	local glow = r:CreateTexture(nil, "BORDER")
	glow:SetAllPoints()
	glow:SetTexture(UI.WHITE)
	glow:SetVertexColor(col.accent[1], col.accent[2], col.accent[3], 0.35)
	glow:Hide()
	r.glow = glow
	local hl = r:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	UI.Color(hl, col.hover)
	local rule = r:CreateTexture(nil, "BORDER", nil, 1)
	rule:SetPoint("BOTTOMLEFT", 0, 0)
	rule:SetPoint("BOTTOMRIGHT", 0, 0)
	rule:SetHeight(1)
	UI.Color(rule, col.line)
	local icon = r:CreateTexture(nil, "ARTWORK")
	icon:SetSize(36, 36)
	icon:SetPoint("LEFT", 10, 0)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	r.icon = icon
	UI.FrameIcon(icon)
	-- 달성 표시: 아이콘 모서리의 작은 강조색 네모
	local check = r:CreateTexture(nil, "OVERLAY", nil, 3)
	check:SetSize(9, 9)
	check:SetPoint("CENTER", icon, "BOTTOMRIGHT", -1, 1)
	UI.Color(check, col.accent)
	r.check = check
	local name = r:CreateFontString(nil, "OVERLAY", UI.F.body)
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, 1)
	name:SetJustifyH("LEFT")
	name:SetWordWrap(false)
	r.name = name
	local desc = UI.Text(r, UI.F.small)
	desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -5)
	desc:SetWordWrap(false)
	r.desc = desc
	local pts = r:CreateFontString(nil, "OVERLAY", UI.F.body)
	pts:SetPoint("TOPRIGHT", -12, -11)
	pts:SetJustifyH("RIGHT")
	r.pts = pts
	local newTag = r:CreateFontString(nil, "OVERLAY", UI.F.key)
	newTag:SetText("NEW")
	newTag:SetTextColor(col.accent[1], col.accent[2], col.accent[3])
	newTag:SetPoint("RIGHT", pts, "LEFT", -10, 0)
	r.newTag = newTag
	local when = UI.Text(r, UI.F.tiny)
	when:SetPoint("BOTTOMRIGHT", -12, 12)
	when:SetJustifyH("RIGHT")
	r.when = when
	local bar = UI.Bar(r, 150, 4)
	bar:SetPoint("BOTTOMRIGHT", -12, 12)
	r.bar = bar
	name:SetPoint("RIGHT", pts, "LEFT", -48, 0)
	desc:SetPoint("RIGHT", bar, "LEFT", -16, 0)
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
	self.points:SetText(ns.Comma(pts))
	self.bar:SetMinMaxValues(0, total)
	self.bar:SetValue(done)
	self.bar.text:SetText(math.floor(done / math.max(1, total) * 100 + 0.5) .. "%")
	self.summary:SetText(string.format("%d / %d 달성\n최대 %s점", done, total, ns.Comma(maxPts)))
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
			-- 새로 이룬 업적: 처음 보여 줄 때 3초 동안만 반짝이고, NEW 표시는 탭을 떠날 때까지 남는다
			local isNewNow = ach.unseen and ach.unseen[def.id]
			if isNewNow then
				ach.unseen[def.id] = nil
				T.sessionNew[def.id] = true
				ns.Effects.Pulse(r.glow, true, { min = 0.05, max = 0.9, speed = 5, duration = 3, final = 0.35 })
			elseif T.sessionNew[def.id] then
				-- 이미 한 번 반짝인 업적은 다시 그릴 때 은은한 바탕만 남긴다
				ns.Effects.Pulse(r.glow, false)
				r.glow:Show()
				r.glow:SetAlpha(0.35)
			else
				ns.Effects.Pulse(r.glow, false)
			end
			r.newTag:SetShown(T.sessionNew[def.id] and true or false)
			if self.focusId == def.id then
				self.focusRowY = y
				UI.FadeIn(r, 0.6)
			end
			r.icon:SetTexture(def.icon)
			r.icon:SetDesaturated(not isDone)
			r.check:SetShown(isDone)
			r.icon:SetAlpha(isDone and 1 or 0.45)
			r.name:SetText(def.name)
			r.desc:SetText(def.desc)
			r.pts:SetText(def.points .. "점")
			r.desc:SetTextColor(Col(isDone and col.sub or col.muted))
			if isDone then
				r.bg:SetColorTexture(0, 0, 0, 0)
				r.name:SetTextColor(Col(col.title))
				r.pts:SetTextColor(Col(col.accent))
				r.bar:Hide()
				r.when:Show()
				r.when:SetText(ach.retro[def.id] and "기록 이전에 달성" or ns.FormatShortDate(ach.done[def.id]))
			else
				r.bg:SetColorTexture(0, 0, 0, 0)
				r.name:SetTextColor(Col(col.muted))
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
