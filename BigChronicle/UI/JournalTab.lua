-- BIG CHRONICLE :: 모험 일지 탭

local ADDON, ns = ...
local UI = ns.UI
local J = {}
ns.JournalTab = J

local PAGE_SIZE = 80
local NAV_W = 206

J.chapter = 0       -- 0 = 전체
J.page = nil        -- nil = 기본(가장 최근 기록이 보이는 쪽)
J.filters = {}

local function Hex(c)
	return string.format("%02x%02x%02x", math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255))
end

-- 왼쪽 목록의 한 줄 (선택 시 왼쪽에 진한 띠)
function UI.NavRow(parent, height)
	local C = UI.COL
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(height or 24)
	local sel = b:CreateTexture(nil, "BACKGROUND")
	sel:SetPoint("TOPLEFT", 2, -2)
	sel:SetPoint("BOTTOMRIGHT", -4, 1)
	sel:SetTexture(UI.TEX.tape)
	UI.Tint(sel, C.sel)
	sel:Hide()
	-- 선택 표시: 빨간 색연필로 그은 짧은 줄
	local bar = b:CreateTexture(nil, "ARTWORK")
	bar:SetPoint("LEFT", -2, 0)
	bar:SetSize(10, 6)
	bar:SetTexture(UI.TEX.underline)
	UI.Tint(bar, C.accent)
	bar:Hide()
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 2, -2)
	hl:SetPoint("BOTTOMRIGHT", -4, 1)
	hl:SetTexture(UI.TEX.tape)
	UI.Tint(hl, C.hover)
	local label = UI.Text(b, UI.F.body)
	label:SetPoint("LEFT", 10, 0)
	label:SetJustifyV("MIDDLE")
	label:SetWordWrap(false)
	b.label = label
	local right = UI.Text(b, UI.F.small)
	right:SetPoint("RIGHT", -8, 0)
	right:SetJustifyH("RIGHT")
	right:SetJustifyV("MIDDLE")
	b.right = right
	label:SetPoint("RIGHT", right, "LEFT", -4, 0)
	function b:SetSelected(on)
		sel:SetShown(on)
		bar:SetShown(on)
		if on then
			label:SetTextColor(C.title[1], C.title[2], C.title[3])
		else
			label:SetTextColor(C.text[1], C.text[2], C.text[3])
		end
	end
	function b:SetDim()
		label:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
	end
	b:SetScript("OnClick", function(self, button)
		if self.onClick then self.onClick(self, button) end
	end)
	return b
end

function J:Create(parent)
	local C = ns.Chronicle
	local col = UI.COL
	local p = CreateFrame("Frame", nil, parent)
	p:SetAllPoints()
	self.panel = p
	for _, g in ipairs(C.GROUPS) do
		if self.filters[g.id] == nil then self.filters[g.id] = true end
	end

	-- 왼쪽: 장 목록 + 분류 필터
	local nav = UI.Section(p, { tape = true, tapeX = 20 })
	nav:SetPoint("TOPLEFT", 0, 0)
	nav:SetPoint("BOTTOMLEFT", 0, 0)
	nav:SetWidth(NAV_W)

	local h1 = UI.Text(nav, UI.F.heading)
	h1:SetPoint("TOPLEFT", 12, -12)
	h1:SetText("전기의 장")

	self.chapterButtons = {}
	local prev = h1
	for i = 0, #C.CHAPTERS do
		local b = UI.NavRow(nav, 23)
		b.label:SetText(i == 0 and "전체 기록" or C.CHAPTERS[i].title)
		b:SetPoint("TOPLEFT", nav, "TOPLEFT", 4, -40 - i * 24)
		b:SetPoint("RIGHT", nav, "RIGHT", 0, 0)
		b.onClick = function()
			local changed = J.chapter ~= i
			J.chapter = i
			J.page = nil
			J.scrollPending = true
			J:Refresh()
			if changed then ns.Effects.Sweep(J.sweep, J.scroll, "journal-sweep") end
		end
		if i > 0 then
			UI.Tooltip(b, C.CHAPTERS[i].title, function()
				local ch = C.CHAPTERS[i]
				local range = ch.max >= 999 and (ch.min .. "레벨 이후") or (ch.min .. "~" .. ch.max .. "레벨")
				return range .. "\n" .. ch.desc
			end)
		end
		self.chapterButtons[i] = b
		prev = b
	end

	local h2 = UI.Text(nav, UI.F.heading)
	h2:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 10, -14)
	h2:SetText("기록 분류")
	prev = h2
	self.filterChecks = {}
	for idx, g in ipairs(C.GROUPS) do
		local cb = UI.Check(nav, g.name,
			function() return J.filters[g.id] end,
			function(v) J.filters[g.id] = v; J.page = nil; J.scrollPending = true; J:Refresh() end)
		cb:SetSize(14, 14)
		local colIdx = (idx - 1) % 2
		local rowIdx = math.floor((idx - 1) / 2)
		cb:SetPoint("TOPLEFT", h2, "BOTTOMLEFT", 2 + colIdx * 96, -10 - rowIdx * 22)
		self.filterChecks[g.id] = cb
	end

	local sortBtn = UI.Button(nav, "", NAV_W - 20, 22, function()
		ns.db.newestFirst = not ns.db.newestFirst
		J.page = nil
		J.scrollPending = true
		J:Refresh()
	end)
	sortBtn:SetPoint("BOTTOMLEFT", 10, 10)
	self.sortBtn = sortBtn

	-- 오른쪽: 본문 (종이 위에 바로)
	local main = CreateFrame("Frame", nil, p)
	main:SetPoint("TOPLEFT", nav, "TOPRIGHT", 18, 0)
	main:SetPoint("BOTTOMRIGHT", 0, 0)
	self.main = main

	local title = main:CreateFontString(nil, "OVERLAY", UI.F.header)
	title:SetPoint("TOPLEFT", 4, -4)
	title:SetJustifyH("LEFT")
	self.title = title
	local desc = UI.Text(main, UI.F.small)
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
	self.desc = desc
	local rule = UI.Rule(main, 0.4)
	rule:SetPoint("TOPLEFT", 0, -58)
	rule:SetPoint("TOPRIGHT", 0, -58)

	local scroll = UI.Scroll(main)
	scroll:SetPoint("TOPLEFT", 4, -66)
	scroll:SetPoint("BOTTOMRIGHT", -14, 72)
	self.scroll = scroll
	self.sweep = ns.Effects.MakeSweep(main)
	self.pool = UI.Pool(function()
		local fs = scroll.child:CreateFontString(nil, "OVERLAY", UI.F.body)
		fs:SetJustifyH("LEFT")
		fs:SetJustifyV("TOP")
		fs:SetWordWrap(true)
		fs:SetSpacing(2)
		return fs
	end)

	local empty = UI.Text(main, UI.F.body, col.muted)
	empty:SetPoint("CENTER", 0, 20)
	empty:SetJustifyH("CENTER")
	self.empty = empty

	-- 쪽 넘기기
	local rule2 = UI.Rule(main, 0.4)
	rule2:SetPoint("BOTTOMLEFT", 0, 66)
	rule2:SetPoint("BOTTOMRIGHT", 0, 66)
	local prevBtn = UI.Button(main, "이전 쪽", 104, 22, function() J:TurnPage(-1) end, "←")
	prevBtn:SetPoint("BOTTOMLEFT", 0, 38)
	local nextBtn = UI.Button(main, "다음 쪽", 104, 22, function() J:TurnPage(1) end, "→")
	nextBtn:SetPoint("BOTTOMRIGHT", 0, 38)
	local pageText = UI.Text(main, UI.F.heading)
	pageText:SetPoint("BOTTOM", 0, 43)
	pageText:SetJustifyH("CENTER")
	self.prevBtn, self.nextBtn, self.pageText = prevBtn, nextBtn, pageText

	-- 나만의 기록
	local note = UI.EditBox(main, 420, 26, "나만의 기록을 남겨 보세요… (예: 오늘 처음으로 그리핀을 탔다)")
	note:SetPoint("BOTTOMLEFT", 0, 2)
	note:SetPoint("RIGHT", main, "RIGHT", -196, 0)
	local function submit()
		local t = note:GetText()
		if t and ns.Trim(t) ~= "" then
			ns.Chronicle:AddNote(t)
			note:SetText("")
			note:ClearFocus()
		end
	end
	note:SetScript("OnEnterPressed", submit)
	self.note = note
	local addBtn = UI.Button(main, "기록하기", 90, 26, submit)
	addBtn:SetPoint("LEFT", note, "RIGHT", 8, 0)
	local exportBtn = UI.Button(main, "내보내기", 90, 26, function() UI:ShowExport() end)
	exportBtn:SetPoint("LEFT", addBtn, "RIGHT", 6, 0)
	UI.Tooltip(exportBtn, "내보내기", "지금까지의 모험 전기 전체를 복사할 수 있는 글로 보여 줍니다.")

	self.scrollPending = true
	return p
end

function J:TurnPage(dir)
	local pages = self.pages or 1
	local page = math.max(1, math.min(pages, (self.curPage or 1) + dir))
	if page == self.curPage then return false end
	self.page = page
	self:Refresh(true)
	ns.Effects.Sweep(self.sweep, self.scroll, "journal-sweep")
	return true
end

function J:OnKey(key)
	if key == "LEFT" then return self:TurnPage(-1) or true end
	if key == "RIGHT" then return self:TurnPage(1) or true end
	if key == "UP" then self.scroll:ScrollBy(-60) return true end
	if key == "DOWN" then self.scroll:ScrollBy(60) return true end
	return false
end

function J:Filtered()
	local C = ns.Chronicle
	local list = {}
	local counts = { [0] = 0 }
	for i = 1, #C.CHAPTERS do counts[i] = 0 end
	for idx, e in ipairs(ns.char.log) do
		local cat = C.CATS[e.cat]
		local group = cat and cat.group or "growth"
		if self.filters[group] ~= false then
			local ch = C:ChapterIndex(e.lvl)
			counts[0] = counts[0] + 1
			counts[ch] = counts[ch] + 1
			if self.chapter == 0 or self.chapter == ch then
				list[#list + 1] = { e = e, idx = idx }
			end
		end
	end
	if ns.db.newestFirst then
		local n = #list
		for i = 1, math.floor(n / 2) do list[i], list[n - i + 1] = list[n - i + 1], list[i] end
	end
	return list, counts
end

function J:Refresh(keepScroll, reason)
	if not self.panel then return end
	local C = ns.Chronicle
	local col = UI.COL
	local list, counts = self:Filtered()
	local logCount = #ns.char.log
	local grew = self.seenCount and logCount > self.seenCount
	local fadeFrom = grew and self.seenCount or nil
	self.seenCount = logCount

	for i, b in pairs(self.chapterButtons) do
		b:SetSelected(i == self.chapter)
		b.right:SetText(counts[i] > 0 and ns.Comma(counts[i]) or "")
		if i > 0 and counts[i] == 0 and i ~= self.chapter then b:SetDim() end
	end
	for _, cb in pairs(self.filterChecks) do cb:Sync() end
	self.sortBtn:SetText(ns.db.newestFirst and "정렬: 최신 기록부터" or "정렬: 오래된 기록부터")

	-- 제목
	if self.chapter == 0 then
		self.title:SetText("전체 기록")
	else
		self.title:SetText(UI.PenText(C.CHAPTERS[self.chapter].title))
	end
	if #list > 0 then
		local first, last = list[1].e, list[#list].e
		if ns.db.newestFirst then first, last = last, first end
		local sub = self.chapter > 0 and (C.CHAPTERS[self.chapter].desc .. "   ·   ") or ""
		self.desc:SetText(string.format("%s기록 %s개   ·   %s ~ %s", sub, ns.Comma(#list),
			ns.FormatShortDate(first.t), ns.FormatShortDate(last.t)))
	else
		self.desc:SetText(self.chapter > 0 and C.CHAPTERS[self.chapter].desc or "")
	end

	-- 쪽 계산
	local pages = math.max(1, math.ceil(#list / PAGE_SIZE))
	local page = self.page
	local defaultPage = page == nil
	if defaultPage then page = ns.db.newestFirst and 1 or pages end
	if page > pages then page = pages end
	if page < 1 then page = 1 end
	self.curPage, self.pages = page, pages
	self.pageText:SetText(string.format("%d / %d 쪽", page, pages))
	self.prevBtn:SetEnabled(page > 1)
	self.nextBtn:SetEnabled(page < pages)

	-- 본문
	self.pool:ReleaseAll()
	local width = math.max(200, (self.scroll:GetWidth() or 600) - 8)
	self.scroll.child:SetWidth(width)
	local timeHex = Hex(col.muted)
	local y = 0
	local lastDay
	local stagger = 0
	local startIdx = (page - 1) * PAGE_SIZE + 1
	local endIdx = math.min(#list, page * PAGE_SIZE)
	for i = startIdx, endIdx do
		local item = list[i]
		local e = item.e
		local day = ns.DayKey(e.t)
		if day ~= lastDay then
			local h = self.pool:Acquire()
			h:SetFontObject(UI.F.heading)
			h:SetTextColor(col.accent[1], col.accent[2], col.accent[3])
			h:SetJustifyH("CENTER")
			h:SetWidth(width)
			h:ClearAllPoints()
			local gap = lastDay and 10 or 2
			h:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", 0, -(y + gap))
			h:SetText("─────   " .. ns.FormatDate(e.t) .. "   ─────")
			y = y + gap + (h:GetStringHeight() or 14) + 8
			lastDay = day
		end
		local cat = C.CATS[e.cat] or C.CATS.start
		local fs = self.pool:Acquire()
		fs:SetFontObject(UI.F.body)
		if e.cat == "note" then
			fs:SetTextColor(col.accent[1], col.accent[2], col.accent[3])
		else
			fs:SetTextColor(col.text[1], col.text[2], col.text[3])
		end
		fs:SetJustifyH("LEFT")
		fs:SetWidth(width - 6)
		fs:ClearAllPoints()
		fs:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", 6, -y)
		fs:SetText(string.format("|cff%s%s|r   |T%s:16:16:0:-1:64:64:5:59:5:59|t  %s",
			timeHex, ns.FormatClock(e.t), cat.icon, UI:Themed(e.text)))
		if fadeFrom and item.idx > fadeFrom then
			UI.FadeIn(fs, 0.45, stagger)
			stagger = math.min(stagger + 0.1, 0.6)
		end
		y = y + (fs:GetStringHeight() or 14) + 9
	end
	self.scroll:SetContentHeight(y + 6)

	if #list == 0 then
		self.empty:SetText(logCount == 0 and "아직 기록이 없습니다.\n모험을 떠나면 이곳에 이야기가 쌓여 갑니다."
			or "이 장에는 아직 기록이 없습니다.")
		self.empty:Show()
	else
		self.empty:Hide()
	end

	-- 스크롤 위치: 쪽을 넘기면 맨 위로, 새 기록이 생겼거나 처음 열면 가장 최근 기록으로
	if keepScroll == true then
		self.scroll:ScrollToTop()
	elseif defaultPage and (self.scrollPending or grew) then
		if ns.db.newestFirst then self.scroll:ScrollToTop() else self.scroll:ScrollToBottom() end
	end
	self.scrollPending = false
end
