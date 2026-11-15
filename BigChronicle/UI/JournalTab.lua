-- BIG CHRONICLE :: 모험 일지 탭

local ADDON, ns = ...
local UI = ns.UI
local J = {}
ns.JournalTab = J

local PAGE_SIZE = 80
local NAV_W = 196
-- 타임라인의 세로 위치: 시각 | 아이콘(세로선 위) | 글
local X_ICON, X_TEXT = 52, 80

J.chapter = 0       -- 0 = 전체
J.page = nil        -- nil = 기본(가장 최근 기록이 보이는 쪽)
J.filters = {}

function J:Create(parent)
	local C = ns.Chronicle
	local col = UI.COL
	local pad = UI.PAGE_PAD
	local p = CreateFrame("Frame", nil, parent)
	p:SetAllPoints()
	self.panel = p
	for _, g in ipairs(C.GROUPS) do
		if self.filters[g.id] == nil then self.filters[g.id] = true end
	end

	-- 왼쪽: 장 목록 + 분류
	local nav = CreateFrame("Frame", nil, p)
	nav:SetPoint("TOPLEFT", 0, 0)
	nav:SetPoint("BOTTOMLEFT", 0, 0)
	nav:SetWidth(NAV_W)
	local h1 = UI.Label(nav, "전기의 장")
	h1:SetPoint("TOPLEFT", 0, -6)

	self.chapterButtons = {}
	for i = 0, #C.CHAPTERS do
		local b = UI.NavRow(nav, 28)
		b.label:SetText(i == 0 and "전체 기록" or C.CHAPTERS[i].title)
		b:SetPoint("TOPLEFT", nav, "TOPLEFT", -12, -30 - i * 29)
		b:SetPoint("RIGHT", nav, "RIGHT", -14, 0)
		b.onClick = function()
			UI:FinishTurn(J.turner)
			local cur = J.chapter or 0
			local function apply()
				J.chapter = i
				J.page = nil
				J.scrollPending = true
				J:Refresh()
			end
			if cur == i then
				apply()
			else
				-- 뒤의 장으로 가면 앞으로, 앞의 장으로 가면 뒤로 넘긴다
				UI:TurnPage(J.turner, i > cur and 1 or -1, apply)
			end
		end
		if i > 0 then
			UI.Tooltip(b, C.CHAPTERS[i].title, function()
				local ch = C.CHAPTERS[i]
				local range = ch.max >= 999 and (ch.min .. "레벨 이후") or (ch.min .. "~" .. ch.max .. "레벨")
				return range .. "\n" .. ch.desc
			end)
		end
		self.chapterButtons[i] = b
	end

	local filterTop = -30 - (#C.CHAPTERS + 1) * 29 - 22
	local h2 = UI.Label(nav, "기록 분류")
	h2:SetPoint("TOPLEFT", 0, filterTop)
	self.filterChecks = {}
	for idx, g in ipairs(C.GROUPS) do
		local cb = UI.Check(nav, g.name,
			function() return J.filters[g.id] end,
			function(v) J.filters[g.id] = v; J.page = nil; J.scrollPending = true; J:Refresh() end)
		local colIdx = (idx - 1) % 2
		local rowIdx = math.floor((idx - 1) / 2)
		cb:SetPoint("TOPLEFT", nav, "TOPLEFT", 1 + colIdx * 92, filterTop - 24 - rowIdx * 24)
		self.filterChecks[g.id] = cb
	end

	local sep = UI.VRule(p)
	sep:SetPoint("TOPLEFT", nav, "TOPRIGHT", 0, 0)
	sep:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT", 0, 0)

	local main = CreateFrame("Frame", nil, p)
	main:SetPoint("TOPLEFT", nav, "TOPRIGHT", 26, 0)
	main:SetPoint("BOTTOMRIGHT", 0, 0)
	self.main = main

	-- 오른쪽: 본문. 장을 바꾸거나 쪽을 넘기면 이 자리(페이지 오른쪽 전체) 위로 종이 한 장이 넘어간다.
	local sheet = CreateFrame("Frame", nil, p)
	sheet:SetPoint("TOPLEFT", nav, "TOPRIGHT", 1, pad.top - 1)
	sheet:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", pad.x - 1, -pad.bottom + 1)
	self.sheet = sheet
	self.turner = ns.Effects.MakePageTurn(sheet)

	-- 머리말: 제목과 요약, 오른쪽에 정렬·내보내기
	local title = main:CreateFontString(nil, "OVERLAY", UI.F.title)
	title:SetPoint("TOPLEFT", 0, -2)
	title:SetJustifyH("LEFT")
	self.title = title
	local desc = UI.Text(main, UI.F.small)
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)
	self.desc = desc
	local exportBtn = UI.Button(main, "내보내기", 78, 24, function() UI:ShowExport() end)
	exportBtn:SetPoint("TOPRIGHT", -4, -8)
	UI.Tooltip(exportBtn, "내보내기", "지금까지의 모험 전기 전체를 복사할 수 있는 글로 보여 줍니다.")
	local sortBtn = UI.Button(main, "", 112, 24, function()
		ns.db.newestFirst = not ns.db.newestFirst
		J.page = nil
		J.scrollPending = true
		J:Refresh()
	end)
	sortBtn:SetPoint("RIGHT", exportBtn, "LEFT", -6, 0)
	self.sortBtn = sortBtn
	local rule = UI.Rule(main)
	rule:SetPoint("TOPLEFT", 0, -60)
	rule:SetPoint("TOPRIGHT", 0, -60)

	-- 타임라인
	local scroll = UI.Scroll(main)
	scroll:SetPoint("TOPLEFT", 0, -72)
	scroll:SetPoint("BOTTOMRIGHT", -12, 86)
	self.scroll = scroll
	local spine = scroll.child:CreateTexture(nil, "BACKGROUND")
	spine:SetWidth(1)
	UI.Color(spine, col.line)
	self.spine = spine
	self.pool = UI.Pool(function()
		local fs = scroll.child:CreateFontString(nil, "OVERLAY", UI.F.body)
		fs:SetJustifyH("LEFT")
		fs:SetJustifyV("TOP")
		fs:SetWordWrap(true)
		fs:SetSpacing(3)
		return fs
	end)
	self.iconPool = UI.Pool(function()
		local t = scroll.child:CreateTexture(nil, "ARTWORK")
		t:SetSize(16, 16)
		t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		return t
	end)
	self.dotPool = UI.Pool(function()
		local t = scroll.child:CreateTexture(nil, "ARTWORK")
		t:SetSize(7, 7)
		UI.Color(t, col.accent)
		return t
	end)

	local empty = UI.Text(main, UI.F.body, col.muted)
	empty:SetPoint("CENTER", 0, 20)
	empty:SetJustifyH("CENTER")
	self.empty = empty

	-- 아래쪽: 쪽 넘기기 + 나만의 기록
	local rule2 = UI.Rule(main)
	rule2:SetPoint("BOTTOMLEFT", 0, 76)
	rule2:SetPoint("BOTTOMRIGHT", 0, 76)
	local prevBtn = UI.Button(main, "←  이전 쪽", 92, 24, function() J:TurnPage(-1) end)
	prevBtn:SetPoint("BOTTOMLEFT", 0, 42)
	local nextBtn = UI.Button(main, "다음 쪽  →", 92, 24, function() J:TurnPage(1) end)
	nextBtn:SetPoint("BOTTOMRIGHT", 0, 42)
	local pageText = UI.Text(main, UI.F.small)
	pageText:SetPoint("BOTTOM", 0, 48)
	pageText:SetJustifyH("CENTER")
	self.prevBtn, self.nextBtn, self.pageText = prevBtn, nextBtn, pageText

	local note = UI.EditBox(main, 420, 30, "나만의 기록을 남겨 보세요… (예: 오늘 처음으로 그리핀을 탔다)")
	note:SetPoint("BOTTOMLEFT", 0, 0)
	note:SetPoint("RIGHT", main, "RIGHT", -104, 0)
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
	local addBtn = UI.Button(main, "기록하기", 96, 30, submit, nil, "primary")
	addBtn:SetPoint("LEFT", note, "RIGHT", 8, 0)

	self.scrollPending = true
	return p
end

function J:TurnPage(dir)
	UI:FinishTurn(self.turner)
	local pages = self.pages or 1
	local page = math.max(1, math.min(pages, (self.curPage or 1) + dir))
	if page == self.curPage then return false end
	UI:TurnPage(self.turner, dir, function()
		self.page = page
		self:Refresh(true)
	end)
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
	self.sortBtn:SetText(ns.db.newestFirst and "최신 기록부터" or "오래된 기록부터")

	-- 제목
	if self.chapter == 0 then
		self.title:SetText("전체 기록")
	else
		self.title:SetText(C.CHAPTERS[self.chapter].title)
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

	-- 본문: 날짜별로 묶은 타임라인 (시각 | 아이콘 | 글)
	self.pool:ReleaseAll()
	self.iconPool:ReleaseAll()
	self.dotPool:ReleaseAll()
	local child = self.scroll.child
	local width = math.max(200, (self.scroll:GetWidth() or 600) - 4)
	child:SetWidth(width)
	local y = 4
	local lastDay
	local stagger = 0
	local startIdx = (page - 1) * PAGE_SIZE + 1
	local endIdx = math.min(#list, page * PAGE_SIZE)
	for i = startIdx, endIdx do
		local item = list[i]
		local e = item.e
		local day = ns.DayKey(e.t)
		if day ~= lastDay then
			if lastDay then y = y + 14 end
			local dot = self.dotPool:Acquire()
			dot:ClearAllPoints()
			dot:SetPoint("CENTER", child, "TOPLEFT", X_ICON + 8, -(y + 8))
			local h = self.pool:Acquire()
			h:SetFontObject(UI.F.heading)
			h:SetTextColor(col.accent[1], col.accent[2], col.accent[3])
			h:SetJustifyH("LEFT")
			h:SetWidth(width - X_TEXT)
			h:ClearAllPoints()
			h:SetPoint("TOPLEFT", child, "TOPLEFT", X_TEXT, -y)
			h:SetText(ns.FormatDate(e.t))
			y = y + (h:GetStringHeight() or 14) + 12
			lastDay = day
		end
		local cat = C.CATS[e.cat] or C.CATS.start
		local tm = self.pool:Acquire()
		tm:SetFontObject(UI.F.small)
		tm:SetTextColor(col.muted[1], col.muted[2], col.muted[3])
		tm:SetJustifyH("RIGHT")
		tm:SetWidth(X_ICON - 10)
		tm:ClearAllPoints()
		tm:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(y + 1))
		tm:SetText(ns.FormatClock(e.t))
		local ic = self.iconPool:Acquire()
		ic:ClearAllPoints()
		ic:SetPoint("TOPLEFT", child, "TOPLEFT", X_ICON, -y)
		ic:SetTexture(cat.icon)
		local fs = self.pool:Acquire()
		fs:SetFontObject(UI.F.body)
		if e.cat == "note" then
			fs:SetTextColor(col.accent[1], col.accent[2], col.accent[3])
		else
			fs:SetTextColor(col.text[1], col.text[2], col.text[3])
		end
		fs:SetJustifyH("LEFT")
		fs:SetWidth(width - X_TEXT - 6)
		fs:ClearAllPoints()
		fs:SetPoint("TOPLEFT", child, "TOPLEFT", X_TEXT, -y)
		fs:SetText(UI:Themed(e.text))
		if fadeFrom and item.idx > fadeFrom then
			UI.FadeIn(fs, 0.45, stagger)
			stagger = math.min(stagger + 0.1, 0.6)
		end
		y = y + math.max(16, fs:GetStringHeight() or 14) + 11
	end
	self.spine:ClearAllPoints()
	self.spine:SetPoint("TOPLEFT", child, "TOPLEFT", X_ICON + 8, -8)
	self.spine:SetPoint("BOTTOMLEFT", child, "TOPLEFT", X_ICON + 8, -math.max(8, y - 10))
	self.spine:SetShown(#list > 0)
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
