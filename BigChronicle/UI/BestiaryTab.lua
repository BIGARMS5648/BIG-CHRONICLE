-- BIG CHRONICLE :: 몬스터 도감 탭

local ADDON, ns = ...
local UI = ns.UI
local D = {}
ns.BestiaryTab = D

local LIST_W, CARD_W = 236, 232
local ROW_H = 23
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

D.sel = { kind = "recent" }
D.species = nil
D.search = ""

local function Col(c) return c[1], c[2], c[3] end

local function LevelText(c)
	if c.skull and not c.minL then return "Lv ??" end
	if not c.minL then return "" end
	if c.minL == c.maxL then return "Lv " .. c.minL end
	return "Lv " .. c.minL .. "~" .. c.maxL
end

local function ClsText(c)
	local label = ns.Bestiary.CLS_LABEL[c.cls]
	if not label then return "" end
	if ns.Bestiary.IsRare(c.cls) then return ns.Hex(label, ns.COLOR.rare) end
	if c.cls == "worldboss" then return ns.Hex(label, ns.COLOR.boss) end
	return ns.Hex(label, ns.COLOR.quest)
end

local function SortedZones(zones, limit)
	local list = {}
	for z, n in pairs(zones) do list[#list + 1] = { z = z, n = n } end
	table.sort(list, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.z < b.z end)
	local out = {}
	for i = 1, math.min(#list, limit or #list) do
		out[#out + 1] = list[i].z .. ns.Hex(" (" .. list[i].n .. ")", ns.COLOR.dim)
	end
	return table.concat(out, ",  "), #list
end

------------------------------------------------------------------------
-- 생성
------------------------------------------------------------------------
function D:Create(parent)
	local col = UI.COL
	local p = CreateFrame("Frame", nil, parent)
	p:SetAllPoints()
	self.panel = p

	-- 왼쪽: 완성도 + 검색 + 목록
	local left = UI.Section(p, { tape = true, tapeX = -40 })
	left:SetPoint("TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", 0, 0)
	left:SetWidth(LIST_W)

	local comp = left:CreateFontString(nil, "OVERLAY", UI.F.heading)
	comp:SetPoint("TOPLEFT", 10, -10)
	comp:SetJustifyH("LEFT")
	self.compText = comp
	local bar = UI.Bar(left, LIST_W - 20, 10)
	bar:SetPoint("TOPLEFT", comp, "BOTTOMLEFT", 0, -7)
	self.compBar = bar
	local compSub = UI.Text(left, UI.F.small)
	compSub:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -7)
	compSub:SetWidth(LIST_W - 20)
	compSub:SetSpacing(2)
	self.compSub = compSub

	local search = UI.EditBox(left, LIST_W - 20, 24, "개체·종족 이름 검색")
	search:SetPoint("TOPLEFT", compSub, "BOTTOMLEFT", 0, -10)
	search:HookScript("OnTextChanged", function(self)
		local t = ns.Trim(self:GetText() or "")
		if t ~= D.search then
			D.search = t
			if t ~= "" then
				D.sel = { kind = "search" }
			elseif D.sel.kind == "search" then
				D.sel = { kind = "recent" }
			end
			D:Refresh()
		end
	end)
	search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	self.searchBox = search

	local listScroll = UI.Scroll(left)
	listScroll:SetPoint("TOPLEFT", search, "BOTTOMLEFT", -10, -8)
	listScroll:SetPoint("BOTTOMRIGHT", -12, 6)
	self.listScroll = listScroll
	self.listPool = UI.Pool(function() return D:CreateListRow(listScroll.child) end)

	-- 오른쪽 카드: 테이프로 붙인 폴라로이드 사진 + 개체 메모
	local card = UI.Section(p, { tint = col.page })
	card:SetPoint("TOPRIGHT", 0, 0)
	card:SetPoint("BOTTOMRIGHT", 0, 0)
	card:SetWidth(CARD_W)
	self.card = card

	local polaroid = CreateFrame("Frame", nil, card)
	polaroid:SetPoint("TOPLEFT", 12, -14)
	polaroid:SetPoint("TOPRIGHT", -12, -14)
	polaroid:SetHeight(222)
	UI.Paper(polaroid, { tint = { 1, 1, 0.98 }, shadow = 0.35 })
	self.polaroid = polaroid
	local tape = UI.Tape(polaroid, 86, 22, 0.06)
	tape:SetPoint("CENTER", polaroid, "TOP", 0, 2)
	local clipTex = card:CreateTexture(nil, "OVERLAY", nil, 7)
	clipTex:SetSize(18, 72)
	clipTex:SetPoint("TOPRIGHT", card, "TOPRIGHT", -18, 20)
	clipTex:SetTexture(UI.TEX.clip)

	local stage = CreateFrame("Frame", nil, polaroid)
	stage:SetPoint("TOPLEFT", 10, -10)
	stage:SetPoint("TOPRIGHT", -10, -10)
	stage:SetHeight(172)
	local stageBg = stage:CreateTexture(nil, "BACKGROUND")
	stageBg:SetAllPoints()
	UI.Gradient(stageBg, "VERTICAL", { 0.10, 0.09, 0.08, 1 }, { 0.26, 0.23, 0.20, 1 })
	stage.bg = stageBg
	self.stage = stage

	local ok, model = pcall(CreateFrame, "PlayerModel", nil, stage)
	if ok and model then
		model:SetPoint("TOPLEFT", 2, -2)
		model:SetPoint("BOTTOMRIGHT", -2, 2)
		model:EnableMouse(true)
		model:SetScript("OnMouseDown", function(self, btn)
			if btn == "LeftButton" then self.dragX = GetCursorPosition() end
		end)
		model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
		model:SetScript("OnUpdate", function(self)
			if self.dragX then
				local x = GetCursorPosition()
				local ok2, facing = pcall(self.GetFacing, self)
				if ok2 and facing then pcall(self.SetFacing, self, facing + (x - self.dragX) * 0.015) end
				self.dragX = x
			end
		end)
		model:Hide()
		self.model = model
	end
	local bigIcon = stage:CreateTexture(nil, "ARTWORK")
	bigIcon:SetSize(64, 64)
	bigIcon:SetPoint("CENTER", 0, 12)
	bigIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	self.bigIcon = bigIcon
	local modelHint = UI.Text(stage, UI.F.tiny)
	modelHint:SetPoint("TOP", bigIcon, "BOTTOM", 0, -8)
	modelHint:SetWidth(CARD_W - 50)
	modelHint:SetJustifyH("CENTER")
	modelHint:SetTextColor(0.85, 0.82, 0.76)
	self.modelHint = modelHint
	local rotateHint = UI.Text(stage, UI.F.tiny)
	rotateHint:SetPoint("BOTTOM", 0, 5)
	rotateHint:SetJustifyH("CENTER")
	rotateHint:SetText("드래그하여 돌려 보기")
	rotateHint:SetTextColor(0.85, 0.82, 0.76)
	self.rotateHint = rotateHint

	-- 사진 아래 여백에 손글씨로 이름
	local cardName = polaroid:CreateFontString(nil, "OVERLAY", UI.F.header)
	cardName:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 2, -6)
	cardName:SetPoint("TOPRIGHT", stage, "BOTTOMRIGHT", -2, -6)
	cardName:SetJustifyH("CENTER")
	cardName:SetWordWrap(false)
	self.cardName = cardName

	local reassign = UI.Button(card, "종족 다시 분류", CARD_W - 24, 26, function()
		if D.species then D:ShowReassign(D.species) end
	end)
	reassign:SetPoint("BOTTOM", 0, 12)
	UI.Tooltip(reassign, "종족 다시 분류", "자동 분류가 틀렸다면 이 개체가 속한 종족을 직접 정할 수 있습니다.\n(목록에서 개체를 오른쪽 클릭해도 됩니다)")
	self.reassignBtn = reassign

	local cardInfo = UI.Text(card, UI.F.small, col.text)
	cardInfo:SetPoint("TOPLEFT", polaroid, "BOTTOMLEFT", 2, -12)
	cardInfo:SetPoint("BOTTOMRIGHT", reassign, "TOPRIGHT", -2, 8)
	cardInfo:SetSpacing(3)
	self.cardInfo = cardInfo

	-- 가운데: 상세 (종이 위에 바로)
	local mid = CreateFrame("Frame", nil, p)
	mid:SetPoint("TOPLEFT", left, "TOPRIGHT", 18, 0)
	mid:SetPoint("BOTTOMRIGHT", card, "BOTTOMLEFT", -18, 0)
	mid:EnableMouse(true)
	mid:SetScript("OnMouseDown", function() UI.FinishTyping() end) -- 클릭하면 글을 바로 끝까지 보여 준다
	self.mid = mid
	local stamp = ns.Effects.MakeSeal(mid, 76, "dex")
	stamp:SetPoint("TOPRIGHT", -18, -6)
	stamp:SetFrameLevel(mid:GetFrameLevel() + 30)
	self.stamp = stamp
	local scroll = UI.Scroll(mid)
	scroll:SetPoint("TOPLEFT", 2, -4)
	scroll:SetPoint("BOTTOMRIGHT", -12, 4)
	self.scroll = scroll

	local child = scroll.child
	self.textPool = UI.Pool(function()
		local fs = child:CreateFontString(nil, "OVERLAY", UI.F.body)
		fs:SetJustifyH("LEFT")
		fs:SetJustifyV("TOP")
		fs:SetWordWrap(true)
		return fs
	end)
	self.rowPool = UI.Pool(function() return D:CreateSpeciesRow(child) end)
	self.iconPool = UI.Pool(function()
		local t = child:CreateTexture(nil, "ARTWORK")
		t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		return t
	end)
	self.dividerPool = UI.Pool(function() return UI.Divider(child, 300) end)
	self.detailBar = UI.Bar(child, 200, 12)
	self.detailBar:Hide()

	return p
end

------------------------------------------------------------------------
-- 왼쪽 목록 행
------------------------------------------------------------------------
function D:CreateListRow(parent)
	local b = UI.NavRow(parent, ROW_H)
	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetPoint("LEFT", 8, 0)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	b.icon = icon
	local no = UI.Text(b, UI.F.tiny)
	no:SetPoint("LEFT", icon, "RIGHT", 6, 0)
	no:SetJustifyV("MIDDLE")
	b.no = no
	b.label:ClearAllPoints()
	b.label:SetPoint("LEFT", 66, 0)
	b.label:SetPoint("RIGHT", b.right, "LEFT", -4, 0)
	b.right:SetFontObject(UI.F.small)
	return b
end

function D:RefreshList()
	local B = ns.Bestiary
	local col = UI.COL
	local all = B:CollectAll()
	local pool = self.listPool
	pool:ReleaseAll()
	local width = math.max(100, (self.listScroll:GetWidth() or (LIST_W - 30)))
	self.listScroll.child:SetWidth(width)
	local y = 0
	self.navOrder = {}
	local function add(setup)
		local r = pool:Acquire()
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", self.listScroll.child, "TOPLEFT", 0, -y)
		r:SetWidth(width)
		r.no:SetTextColor(Col(col.muted))
		r.right:SetTextColor(Col(col.accent))
		r.icon:SetDesaturated(false)
		r.icon:SetAlpha(1)
		setup(r)
		y = y + ROW_H
	end

	local rareCount = 0
	for _, s in pairs(all) do rareCount = rareCount + s.rares end

	if self.search ~= "" then
		add(function(r)
			r.icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
			r.no:SetText("")
			r.label:SetText("검색: " .. self.search)
			r.right:SetText("")
			r:SetSelected(self.sel.kind == "search")
			r.onClick = function() D.sel = { kind = "search" }; D:Refresh() end
		end)
	end
	add(function(r)
		r.icon:SetTexture("Interface\\Icons\\INV_Misc_Gem_Ruby_01")
		r.no:SetText("")
		r.label:SetText("희귀 개체 모음")
		r.right:SetText(rareCount > 0 and tostring(rareCount) or "")
		r:SetSelected(self.sel.kind == "rares")
		if self.sel.kind ~= "rares" then r.label:SetTextColor(Col(col.rare)) end
		r.onClick = function() D.sel = { kind = "rares" }; D:Refresh() end
	end)
	add(function(r)
		r.icon:SetTexture("Interface\\Icons\\Ability_EyeOfTheOwl")
		r.no:SetText("")
		r.label:SetText("최근 발견한 개체")
		r.right:SetText("")
		r:SetSelected(self.sel.kind == "recent")
		r.onClick = function() D.sel = { kind = "recent" }; D:Refresh() end
	end)
	y = y + 8

	local q = self.search:lower()
	for _, t in ipairs(B:GetTribeList()) do
		local s = all[t.id]
		local found = B.dex.tribes[t.id] ~= nil and s ~= nil
		local match = true
		if q ~= "" then
			match = found and t.name:lower():find(q, 1, true) ~= nil
			if found and not match then
				for _, n in ipairs(s.list) do
					if n:lower():find(q, 1, true) then match = true break end
				end
			end
		end
		if match then
			self.navOrder[#self.navOrder + 1] = t.id
			add(function(r)
				r.no:SetText((B:FormatNo(t.id):gsub("No%.", "")))
				r:SetSelected(self.sel.kind == "tribe" and self.sel.id == t.id)
				if found then
					r.icon:SetTexture(t.icon)
					r.label:SetText(t.name)
					local isNew = not B.dex.tribes[t.id].viewed
					r.right:SetText((isNew and "|cff3fa83fNEW|r  " or "") .. string.rep("★", s.rankDef.stars))
				else
					r.icon:SetTexture(QUESTION)
					r.icon:SetDesaturated(true)
					r.icon:SetAlpha(0.5)
					r.label:SetText("???")
					r:SetDim()
					r.right:SetText("")
				end
				r.onClick = function()
					D:SelectTribe(t.id)
				end
			end)
		end
	end
	self.listScroll:SetContentHeight(y)

	local foundN, total, species, rares, kills, dynCount = B:Completion()
	self.compText:SetText(string.format("도감 완성도   %d / %d 종족", foundN, total))
	self.compBar:SetMinMaxValues(0, total)
	self.compBar:SetValue(foundN)
	self.compBar.text:SetText(string.format("%d%%", math.floor(foundN / total * 100 + 0.5)))
	self.compSub:SetText(string.format("개체 %s종  ·  희귀 %d  ·  처치 %s\n야수 계통 %d종 발견", ns.Comma(species), rares, ns.Comma(kills), dynCount))
end

-- 알림·검색에서 특정 개체로 바로 이동: 종족을 고르고, 개체를 선택하고, 목록에서 그 줄이 보이게 한다
function D:FocusCreature(name)
	local c = ns.Bestiary.dex.creatures[name]
	if not c then return end
	if self.searchBox and self.search ~= "" then
		self.search = ""
		self.searchBox:SetText("")
	end
	self.sel = { kind = "tribe", id = c.tribe }
	self.species = name
	self.focusY = nil
	self:Refresh()
	if self.focusY then
		self.scroll:ScrollTo(self.focusY - 60)
	end
	-- 왼쪽 종족 목록도 해당 종족이 보이도록
	if self.navOrder then
		for i, id in ipairs(self.navOrder) do
			if id == c.tribe then
				self.listScroll:ScrollTo((i + 2) * ROW_H - 120)
				break
			end
		end
	end
end

function D:SelectTribe(id)
	self.sel = { kind = "tribe", id = id }
	self.species = nil
	self:Refresh()
end

-- ↑/↓ 로 종족을 차례로 넘긴다
function D:OnKey(key)
	if key ~= "UP" and key ~= "DOWN" then return false end
	local order = self.navOrder or {}
	if #order == 0 then return true end
	local idx = 0
	if self.sel.kind == "tribe" then
		for i, id in ipairs(order) do if id == self.sel.id then idx = i break end end
	end
	idx = idx + (key == "DOWN" and 1 or -1)
	if idx < 1 then idx = #order elseif idx > #order then idx = 1 end
	self:SelectTribe(order[idx])
	return true
end

------------------------------------------------------------------------
-- 가운데 상세 레이아웃 도우미
------------------------------------------------------------------------
function D:Begin()
	self.textPool:ReleaseAll()
	self.rowPool:ReleaseAll()
	self.iconPool:ReleaseAll()
	self.dividerPool:ReleaseAll()
	self.detailBar:Hide()
	self.y = 0
	self.width = math.max(200, (self.scroll:GetWidth() or 380) - 6)
	self.scroll.child:SetWidth(self.width)
end

function D:Text(str, font, color, indent, after)
	local fs = self.textPool:Acquire()
	fs:SetFontObject(font or UI.F.body)
	local c = color or UI.COL.text
	fs:SetTextColor(c[1], c[2], c[3])
	fs:SetJustifyH("LEFT")
	fs:SetSpacing(2)
	fs:SetWidth(self.width - (indent or 0))
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", indent or 0, -self.y)
	fs:SetText(UI:Themed(str))
	self.y = self.y + (fs:GetStringHeight() or 14) + (after or 6)
	return fs
end

function D:Heading(str)
	self.y = self.y + 10
	local div = self.dividerPool:Acquire()
	div:ClearAllPoints()
	div:SetWidth(self.width)
	div:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", 0, -self.y)
	self.y = self.y + 16
	local fs = self:Text(str, UI.F.heading, UI.COL.accent, 0, 8)
	fs:SetJustifyH("CENTER")
end

function D:Space(n) self.y = self.y + (n or 6) end

function D:CreateSpeciesRow(parent)
	local b = UI.NavRow(parent, 21)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b.label:SetFontObject(UI.F.body)
	b.onClick = function(self, button)
		if not self.creature then return end
		if button == "RightButton" then
			D:ShowReassign(self.creature)
		else
			D.species = self.creature
			D:RefreshCard()
			D:RefreshDetail(true)
		end
	end
	return b
end

function D:SpeciesRow(name, leftText, rightText, leftColor)
	local r = self.rowPool:Acquire()
	r:ClearAllPoints()
	r:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", 0, -self.y)
	r:SetWidth(self.width)
	r.creature = name
	r:SetSelected(self.species == name)
	if self.species == name and not self.focusY then self.focusY = self.y end
	r.label:SetText(leftText)
	if self.species ~= name then
		local c = leftColor or UI.COL.creature
		r.label:SetTextColor(c[1], c[2], c[3])
	end
	r.right:SetText(UI:Themed(rightText or ""))
	self.y = self.y + 22
	return r
end

------------------------------------------------------------------------
-- 상세 화면
------------------------------------------------------------------------
function D:RefreshDetail(keep)
	self:Begin()
	self.focusY = nil
	local kind = self.sel.kind
	if kind == "rares" then
		self:DrawRares()
	elseif kind == "recent" then
		self:DrawRecent()
	elseif kind == "search" then
		self:DrawSearch()
	else
		self:DrawTribe(self.sel.id)
	end
	self.scroll:SetContentHeight(self.y + 10)
	local key = kind .. ":" .. tostring(self.sel.id)
	if key ~= self.lastView then self.scroll:ScrollToTop() end
	self.lastView = key
end

function D:DrawTribe(id)
	local B = ns.Bestiary
	local col = UI.COL
	local def = ns.GetTribe(id) or ns.TRIBES[1]
	id = def.id
	local s = B:CollectAll()[id]
	local tribeData = B.dex.tribes[id]
	local found = tribeData ~= nil and s ~= nil
	local firstView = self.typedTribe ~= id
	self.typedTribe = id

	-- 머리말: 아이콘 + 번호/이름 (대화창의 NPC 이름처럼)
	local icon = self.iconPool:Acquire()
	icon:SetSize(48, 48)
	icon:ClearAllPoints()
	icon:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", 0, -self.y)
	icon:SetTexture(found and def.icon or QUESTION)
	icon:SetDesaturated(not found)
	icon:SetAlpha(found and 1 or 0.6)

	local no = self.textPool:Acquire()
	no:SetFontObject(UI.F.tiny)
	no:SetTextColor(Col(col.accent))
	no:SetWidth(self.width - 60)
	no:SetJustifyH("LEFT")
	no:ClearAllPoints()
	no:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1)
	no:SetText(B:FormatNo(id) .. (found and def.en and def.en ~= def.name and ("   ·   " .. def.en) or ""))

	local head = self.textPool:Acquire()
	head:SetFontObject(UI.F.title)
	head:SetTextColor(Col(col.title))
	head:SetWidth(self.width - 60)
	head:SetJustifyH("LEFT")
	head:ClearAllPoints()
	head:SetPoint("TOPLEFT", no, "BOTTOMLEFT", 0, -3)
	head:SetText(found and def.name or "???")

	local sub = self.textPool:Acquire()
	sub:SetFontObject(UI.F.small)
	sub:SetWidth(self.width - 60)
	sub:SetJustifyH("LEFT")
	sub:ClearAllPoints()
	sub:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -4)
	if found then
		sub:SetTextColor(Col(col.accent))
		local typeLabel = def.byType and (B.TYPE_LABEL[def.byType] or "") or (def.dynamic and "야수 계통" or "종족 · 세력")
		sub:SetText(B.Stars(s.rankDef.stars) .. "  " .. s.rankDef.name .. "      " .. typeLabel)
	else
		sub:SetTextColor(Col(col.muted))
		sub:SetText("아직 만나지 못한 종족")
	end
	if firstView then
		UI.FadeIn(head, 0.3)
		UI.FadeIn(sub, 0.3, 0.1)
	end
	-- 발견한 뒤 처음 펼쳐 보는 페이지라면 도장을 쾅
	if found and not tribeData.viewed then
		tribeData.viewed = time()
		ns.Effects.Stamp(self.stamp, "dex-stamp", 1.4)
	elseif not found or firstView then
		self.stamp:Hide()
	end
	-- 손글씨 제목은 줄 높이가 커서, 실제 글자 높이로 다음 줄 위치를 잡는다
	local headH = (no:GetStringHeight() or 12) + 3 + (head:GetStringHeight() or 30) + 4 + (sub:GetStringHeight() or 14)
	self.y = self.y + math.max(56, headH) + 12

	if not found then
		local hint = self:Text("“" .. (def.hint or "...") .. "”", UI.F.body, col.sub, 0, 12)
		if firstView then UI.Typewrite(hint, "“" .. (def.hint or "...") .. "”", 70) end
		self:Text("이 종족의 몬스터를 대상으로 지정하거나, 마우스를 올리거나, 이름표가 보이는 거리까지 다가가면 도감에 등록됩니다.",
			UI.F.small, col.muted)
		return
	end

	-- 연구도 막대
	local bar = self.detailBar
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", self.scroll.child, "TOPLEFT", 0, -self.y)
	bar:SetWidth(self.width)
	bar:Show()
	if s.nextDef then
		local lo = s.rankDef.min
		bar:SetMinMaxValues(0, s.nextDef.min - lo)
		bar:SetValue(math.max(0, s.score - lo))
		bar.text:SetText(string.format("연구도 %s / %s   →   다음 등급: %s", ns.Comma(s.score), ns.Comma(s.nextDef.min), s.nextDef.name))
	else
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)
		bar.text:SetText("연구도 " .. ns.Comma(s.score) .. "   ·   최고 등급 달성!")
	end
	self.y = self.y + 18
	self:Text("연구도 = 발견한 종 ×10 + 처치 + 희귀 개체 ×50 + 우두머리 ×20", UI.F.tiny, col.muted, 0, 10)

	self:Text(string.format("발견 %d종   ·   처치 %s%s   ·   희귀 %d   ·   서식지 %d곳",
		s.species, ns.Comma(s.kills), (def.unit and def.unit ~= "마리") and def.unit or "", s.rares, s.zoneCount), UI.F.body, col.text, 0, 4)
	if s.first then
		self:Text(ns.Format("첫 조우  {date}  ·  {zone}  ·  {lvl}레벨  ·  {creature}", {
			date = ns.FormatShortDate(s.first), zone = (s.firstZone and s.firstZone ~= "" and s.firstZone) or "어딘가",
			lvl = s.firstLvl or "?", creature = ns.Quote(s.firstName or "?"),
		}), UI.F.small, col.sub)
	end

	-- 배경 이야기 (처음 펼칠 때 한 글자씩 써진다)
	self:Heading("배경 이야기")
	local delay = 0.15
	for i, para in ipairs(def.lore or {}) do
		local need = B.RANKS[i + 1]
		if s.rank >= i + 1 then
			local fs = self:Text(para, UI.F.body, col.text, 4, 10)
			if firstView then
				delay = delay + UI.Typewrite(fs, para, 110, delay) + 0.1
			end
		else
			self:Text(string.format("[봉인됨]   %s %s 등급에서 해금됩니다.", B.Stars(need.stars), need.name), UI.F.small, col.muted, 4, 10)
		end
	end

	-- 서식지
	self:Heading("서식지")
	local zoneText, zc = SortedZones(s.zones)
	self:Text(zc > 0 and ("발견한 곳:   " .. zoneText) or "발견한 곳:   (아직 기록 없음)", UI.F.small, col.text, 4)
	if def.habitats and #def.habitats > 0 then
		self:Text("알려진 서식지:   " .. table.concat(def.habitats, ", "), UI.F.small, col.sub, 4)
	end

	local creatures = B.dex.creatures
	-- 희귀 개체
	if s.rares > 0 then
		self:Heading(string.format("희귀 개체 (%d)", s.rares))
		for _, name in ipairs(s.rareList) do
			local c = creatures[name]
			local killed = c.rareKilled and ns.Hex("  처치함", ns.COLOR.good) or ""
			self:SpeciesRow(name, "◆ " .. name, LevelText(c) .. "  " .. ClsText(c) .. killed, col.rare)
		end
	end

	-- 발견한 개체
	self:Heading(string.format("발견한 개체 (%d)", s.species))
	for i, name in ipairs(s.list) do
		local c = creatures[name]
		local right = LevelText(c)
		local cls = ClsText(c)
		if cls ~= "" then right = right .. "  " .. cls end
		if c.kills > 0 then right = right .. "  " .. ns.Hex("처치 " .. ns.Comma(c.kills), ns.COLOR.parchment) end
		local color = B.IsRare(c.cls) and col.rare or col.creature
		self:SpeciesRow(name, string.format("%02d   %s", i, name), right, color)
	end
	self:Space(6)
	self:Text("개체를 클릭하면 오른쪽에 모습이 나타나고, 오른쪽 클릭하면 종족을 다시 분류할 수 있습니다.", UI.F.tiny, col.muted)
end

function D:DrawRares()
	local B = ns.Bestiary
	local col = UI.COL
	local creatures = B.dex.creatures
	local list = {}
	for name, c in pairs(creatures) do
		if B.IsRare(c.cls) then list[#list + 1] = name end
	end
	table.sort(list, function(a, b) return (creatures[a].order or 0) < (creatures[b].order or 0) end)
	self:Text("희귀 개체 모음", UI.F.title, col.rare, 0, 4)
	local killed = 0
	for _, n in ipairs(list) do if creatures[n].rareKilled then killed = killed + 1 end end
	self:Text(string.format("발견 %d   ·   처치 %d", #list, killed), UI.F.small, col.sub, 0, 6)
	self:Heading("수집 목록")
	if #list == 0 then
		self:Text("아직 발견한 희귀 개체가 없습니다.\n은빛 용 테두리를 두른 몬스터를 찾아 아제로스를 누벼 보세요.", UI.F.body, col.muted)
		return
	end
	for _, name in ipairs(list) do
		local c = creatures[name]
		local def = ns.GetTribe(c.tribe)
		local zone = c.zone ~= "" and c.zone or "?"
		local mark = c.rareKilled and ns.Hex("  처치함", ns.COLOR.good) or ns.Hex("  미처치", ns.COLOR.dim)
		self:SpeciesRow(name, "◆ " .. name, (def and def.name or "?") .. " · " .. zone .. mark, col.rare)
	end
end

function D:DrawRecent()
	local B = ns.Bestiary
	local col = UI.COL
	local creatures = B.dex.creatures
	local list = {}
	for name in pairs(creatures) do list[#list + 1] = name end
	table.sort(list, function(a, b) return (creatures[a].order or 0) > (creatures[b].order or 0) end)
	self:Text("최근 발견한 개체", UI.F.title, col.title, 0, 4)
	self:Text("가장 최근에 도감에 등록된 개체 40종", UI.F.small, col.sub, 0, 6)
	self:Heading("발견 순서")
	if #list == 0 then
		self:Text("아직 도감에 등록된 개체가 없습니다.\n몬스터를 대상으로 지정하거나 마우스를 올리면 자동으로 등록됩니다.", UI.F.body, col.muted)
		return
	end
	for i = 1, math.min(40, #list) do
		local name = list[i]
		local c = creatures[name]
		local def = ns.GetTribe(c.tribe)
		self:SpeciesRow(name, name, (def and def.name or "?") .. " · " .. ns.FormatShortDate(c.first),
			B.IsRare(c.cls) and col.rare or col.creature)
	end
end

function D:DrawSearch()
	local B = ns.Bestiary
	local col = UI.COL
	local creatures = B.dex.creatures
	local q = self.search:lower()
	local list = {}
	for name, c in pairs(creatures) do
		local def = ns.GetTribe(c.tribe)
		if name:lower():find(q, 1, true) or (def and def.name:lower():find(q, 1, true)) then
			list[#list + 1] = name
		end
	end
	table.sort(list)
	self:Text("검색: " .. self.search, UI.F.title, col.title, 0, 4)
	self:Text(string.format("%d종을 찾았습니다", #list), UI.F.small, col.sub, 0, 6)
	self:Heading("검색 결과")
	for _, name in ipairs(list) do
		local c = creatures[name]
		local def = ns.GetTribe(c.tribe)
		self:SpeciesRow(name, name, (def and def.name or "?") .. "  " .. LevelText(c), B.IsRare(c.cls) and col.rare or col.creature)
	end
end

------------------------------------------------------------------------
-- 오른쪽 카드
------------------------------------------------------------------------
function D:RefreshCard()
	local B = ns.Bestiary
	local col = UI.COL
	local name = self.species
	local c = name and B.dex.creatures[name]
	if not c then
		self.species = nil
		local def = self.sel.kind == "tribe" and ns.GetTribe(self.sel.id)
		local found = def and B.dex.tribes[def.id]
		if self.model then self.model:Hide() end
		self.rotateHint:Hide()
		self.bigIcon:Show()
		self.bigIcon:SetTexture(found and def.icon or QUESTION)
		self.bigIcon:SetDesaturated(not found)
		self.modelHint:Show()
		self.modelHint:SetText(found and "개체를 선택하면\n그 모습이 이곳에 나타납니다." or "")
		self.cardName:SetText(UI.PenText(found and def.name or (def and "???" or "도감")))
		self.cardName:SetTextColor(0.12, 0.21, 0.44) -- 폴라로이드는 늘 흰 종이라 잉크 색 고정
		local info = ""
		if found then
			local s = B:CollectAll()[def.id]
			if s then
				info = string.format("연구 등급   %s\n%s\n\n발견 %d종  ·  처치 %s", B.Stars(s.rankDef.stars), s.rankDef.name, s.species, ns.Comma(s.kills))
			end
		elseif not def then
			info = "왼쪽 목록에서 종족을 고르거나,\n↑/↓ 키로 도감을 넘겨 보세요."
		end
		self.cardInfo:SetText(info)
		self.reassignBtn:Hide()
		return
	end

	local def = ns.GetTribe(c.tribe)
	local showedModel = false
	if self.model and c.npc then
		self.model:Show()
		pcall(self.model.ClearModel, self.model)
		showedModel = pcall(self.model.SetCreature, self.model, c.npc)
		pcall(self.model.SetFacing, self.model, 0.6)
		if not showedModel then self.model:Hide() end
		if showedModel and self.lastModel ~= name then UI.FadeIn(self.model, 0.35) end
	elseif self.model then
		self.model:Hide()
	end
	self.lastModel = name
	self.rotateHint:SetShown(showedModel)
	self.bigIcon:SetShown(not showedModel)
	self.bigIcon:SetTexture(def and def.icon or QUESTION)
	self.bigIcon:SetDesaturated(false)
	self.modelHint:SetShown(not showedModel)
	self.modelHint:SetText(showedModel and "" or "모습을 불러올 수 없습니다.")

	self.cardName:SetText(UI.PenText(name))
	if B.IsRare(c.cls) then
		self.cardName:SetTextColor(0.42, 0.16, 0.58)
	else
		self.cardName:SetTextColor(0.05, 0.33, 0.40)
	end

	local lines = {}
	local typeText = c.tname and ("  (" .. c.tname .. (c.family and not (def and def.dynamic) and (" · " .. c.family) or "") .. ")") or ""
	lines[#lines + 1] = "종족   " .. (def and def.name or "?") .. typeText
	local lv = LevelText(c)
	local cls = ClsText(c)
	if lv ~= "" or cls ~= "" then lines[#lines + 1] = "레벨   " .. (lv ~= "" and lv:gsub("^Lv ", "") or "-") .. (cls ~= "" and ("   " .. cls) or "") end
	lines[#lines + 1] = string.format("처치 %s   ·   목격 %s", ns.Comma(c.kills), ns.Comma(c.seen))
	local place = (c.zone ~= "" and c.zone) or "?"
	if c.sub and c.sub ~= "" and c.sub ~= c.zone then place = place .. " · " .. c.sub end
	lines[#lines + 1] = string.format("첫 발견   %s  (내 레벨 %s)", ns.FormatShortDate(c.first), c.plvl or "?")
	lines[#lines + 1] = "              " .. place
	local zoneText, zc = SortedZones(c.zones, 3)
	if zc > 0 then lines[#lines + 1] = "서식지   " .. zoneText end
	if c.rareKilled then
		lines[#lines + 1] = ns.Hex("희귀 개체 처치  " .. ns.FormatShortDate(c.rareKilled), ns.COLOR.good)
	end
	if B.dex.overrides[name] then
		lines[#lines + 1] = ns.Hex("직접 분류한 개체", ns.COLOR.dim)
	end
	self.cardInfo:SetText(UI:Themed(table.concat(lines, "\n")))
	self.reassignBtn:Show()
end

------------------------------------------------------------------------
-- 종족 다시 분류 팝업
------------------------------------------------------------------------
function D:ShowReassign(name)
	local B = ns.Bestiary
	local col = UI.COL
	local c = B.dex.creatures[name]
	if not c then return end
	if not self.popup then
		local f = CreateFrame("Frame", "BigChronicleReassign", UIParent)
		f:SetSize(260, 430)
		f:SetFrameStrata("DIALOG")
		f:EnableMouse(true)
		f:SetClampedToScreen(true)
		UI.Paper(f, { vignette = 18 })
		UI.Roller(f, "TOP", 10)
		UI.Roller(f, "BOTTOM", 10)
		if UISpecialFrames then table.insert(UISpecialFrames, "BigChronicleReassign") end
		local title = f:CreateFontString(nil, "OVERLAY", UI.F.heading)
		title:SetPoint("TOP", 0, -18)
		title:SetWidth(220)
		title:SetJustifyH("CENTER")
		f.title = title
		local close = UI.CloseButton(f, function() f:Hide() end)
		close:SetPoint("TOPRIGHT", -6, -6)
		local auto = UI.Button(f, "자동 분류로 되돌리기", 228, 24, function()
			B:SetTribe(f.creature, nil)
			f:Hide()
			D:AfterReassign(f.creature)
		end)
		auto:SetPoint("TOP", 0, -44)
		f.auto = auto
		local scroll = UI.Scroll(f)
		scroll:SetPoint("TOPLEFT", 16, -78)
		scroll:SetPoint("BOTTOMRIGHT", -24, 16)
		f.scroll = scroll
		f.pool = UI.Pool(function()
			local b = UI.NavRow(scroll.child, 21)
			b.icon = b:CreateTexture(nil, "ARTWORK")
			b.icon:SetSize(16, 16)
			b.icon:SetPoint("LEFT", 8, 0)
			b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			b.label:ClearAllPoints()
			b.label:SetPoint("LEFT", b.icon, "RIGHT", 6, 0)
			b.label:SetPoint("RIGHT", -4, 0)
			b.onClick = function(self)
				B:SetTribe(f.creature, self.tribe)
				f:Hide()
				D:AfterReassign(f.creature)
			end
			return b
		end)
		self.popup = f
	end
	local f = self.popup
	f.creature = name
	f.title:SetText(ns.Quote(name) .. "의 종족")
	f:ClearAllPoints()
	if self.card and self.card:IsVisible() then
		f:SetPoint("TOPRIGHT", self.card, "TOPLEFT", -14, 0)
	else
		f:SetPoint("CENTER")
	end
	f.pool:ReleaseAll()
	local y = 0
	local width = 214
	f.scroll.child:SetWidth(width)
	for _, t in ipairs(B:GetTribeList()) do
		local b = f.pool:Acquire()
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", f.scroll.child, "TOPLEFT", 0, -y)
		b:SetWidth(width)
		b.tribe = t.id
		b.icon:SetTexture(t.icon)
		b.label:SetText(t.name)
		b:SetSelected(c.tribe == t.id)
		y = y + 22
	end
	f.scroll:SetContentHeight(y)
	f.scroll:ScrollToTop()
	f:Show()
	UI.FadeIn(f, 0.18)
end

function D:AfterReassign(name)
	local c = ns.Bestiary.dex.creatures[name]
	if c and self.sel.kind == "tribe" then
		self.sel = { kind = "tribe", id = c.tribe }
	end
	self.species = name
	self:Refresh()
end

------------------------------------------------------------------------
function D:Refresh(_, reason)
	if not self.panel then return end
	if self.sel.kind == "tribe" and not ns.GetTribe(self.sel.id) then
		self.sel = { kind = "recent" }
	end
	self:RefreshList()
	if reason == "dex" and UI.IsTyping() then return end -- 글이 써지는 중이면 목록만 갱신
	self:RefreshDetail(true)
	self:RefreshCard()
end
