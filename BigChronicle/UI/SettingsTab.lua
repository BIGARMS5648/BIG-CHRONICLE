-- BIG CHRONICLE :: 설정 탭

local ADDON, ns = ...
local UI = ns.UI
local O = {}
ns.SettingsTab = O

local OPTIONS = {
	{ key = "chat",         label = "새 기록을 채팅창에 알리기",   desc = "장소 발견을 뺀 새 기록을 채팅창에도 짧게 보여 줍니다." },
	{ key = "toast",        label = "도감 알림 팝업",              desc = "새 종족·개체·희귀 개체를 발견하면 화면 위쪽에 알림을 띄웁니다." },
	{ key = "sound",        label = "알림 효과음",                 desc = "알림 팝업이 뜰 때 효과음을 재생합니다." },
	{ key = "logSubzones",  label = "세부 장소 발견도 기록",       desc = "마을·동굴 같은 세부 장소를 처음 찾았을 때도 남깁니다." },
	{ key = "questRewards", label = "퀘스트 보상 표시",            desc = "퀘스트 기록 끝에 경험치와 골드 보상을 덧붙입니다." },
	{ key = "nameplates",   label = "이름표로도 몬스터 발견",      desc = "적 이름표가 보이는 거리의 몬스터도 도감에 등록합니다." },
	{ key = "tooltip",      label = "툴팁에 도감 정보 표시",       desc = "몬스터 툴팁에 도감 번호, 종족, 처치 수를 붙입니다." },
	{ key = "typewriter",   label = "한 글자씩 써지는 연출",       desc = "배경 이야기가 차례로 써집니다. 클릭·Space로 건너뜁니다." },
	{ key = "effects",      label = "화면 연출",                   desc = "표지 넘김, 새 장 제목, 금가루, 밀랍 인장, 책장 넘김 효과를 보여 줍니다." },
	{ key = "hotkeys",      label = "키보드 단축키",               desc = "창이 열려 있을 때 1~4, 방향키, Space를 씁니다. (전투 중 꺼짐)" },
}

local function Confirm(key, text, onAccept)
	if not StaticPopupDialogs or not StaticPopup_Show then
		onAccept()
		return
	end
	StaticPopupDialogs[key] = {
		text = text,
		button1 = "확인",
		button2 = "취소",
		OnAccept = onAccept,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show(key)
end
O.Confirm = Confirm

function O:Create(parent)
	local col = UI.COL
	local p = CreateFrame("Frame", nil, parent)
	p:SetAllPoints()
	self.panel = p

	local RIGHT_W = 320
	-- 왼쪽: 설정 항목
	local left = CreateFrame("Frame", nil, p)
	left:SetPoint("TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMRIGHT", -(RIGHT_W + 52), 0)

	local title = left:CreateFontString(nil, "OVERLAY", UI.F.title)
	title:SetPoint("TOPLEFT", 0, -2)
	title:SetText("기록과 알림")

	self.checks = {}
	local prev
	for _, opt in ipairs(OPTIONS) do
		local cb = UI.Check(left, opt.label,
			function() return ns.db[opt.key] end,
			function(v)
				ns.db[opt.key] = v
				if opt.key == "hotkeys" then UI:UpdateKeyboard() end
			end,
			opt.desc)
		if prev then
			cb:SetPoint("TOPLEFT", prev.desc, "BOTTOMLEFT", -22, -9)
		else
			cb:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -18)
		end
		cb.desc:SetWidth(430)
		self.checks[#self.checks + 1] = cb
		prev = cb
	end
	local mm = UI.Check(left, "미니맵 버튼 보이기",
		function() return not ns.db.minimap.hide end,
		function(v) ns.db.minimap.hide = not v; if ns.Minimap then ns.Minimap:Update() end end,
		"왼쪽 클릭: 창 열기 · 오른쪽 클릭: 도감 · 드래그: 위치 옮기기")
	mm:SetPoint("TOPLEFT", prev.desc, "BOTTOMLEFT", -22, -9)
	mm.desc:SetWidth(430)
	self.checks[#self.checks + 1] = mm

	-- 오른쪽: 테마 / 데이터 관리 / 정보
	local right = CreateFrame("Frame", nil, p)
	right:SetPoint("TOPRIGHT", 0, 0)
	right:SetPoint("BOTTOMRIGHT", 0, 0)
	right:SetWidth(RIGHT_W)
	local sep = UI.VRule(p)
	sep:SetPoint("TOPRIGHT", right, "TOPLEFT", -26, 0)
	sep:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", -26, 0)

	local h0 = UI.Label(right, "속지 테마")
	h0:SetPoint("TOPLEFT", 0, -8)
	self.themeButtons = {}
	local half = math.floor((RIGHT_W - 2) / 2)
	local tb1 = UI.Button(right, "밝은 속지", half, 28, function() O:SetTheme("light") end)
	tb1:SetPoint("TOPLEFT", h0, "BOTTOMLEFT", 0, -10)
	local tb2 = UI.Button(right, "어두운 속지", half, 28, function() O:SetTheme("dark") end)
	tb2:SetPoint("LEFT", tb1, "RIGHT", 2, 0)
	self.themeButtons.light, self.themeButtons.dark = tb1, tb2
	local themeNote = UI.Text(right, UI.F.tiny)
	themeNote:SetPoint("TOPLEFT", tb1, "BOTTOMLEFT", 0, -8)
	themeNote:SetText("테마를 바꾸면 UI를 다시 불러옵니다.")

	local h = UI.Label(right, "데이터 관리")
	h:SetPoint("TOPLEFT", themeNote, "BOTTOMLEFT", 0, -30)
	local note = UI.Text(right, UI.F.tiny)
	note:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -8)
	note:SetWidth(RIGHT_W)
	note:SetSpacing(2)
	note:SetText("기록은 캐릭터마다 따로 저장됩니다. 초기화한 기록은 되돌릴 수 없습니다.")

	local b1 = UI.Button(right, "모험 일지 초기화", RIGHT_W, 28, function()
		Confirm("BIGCHRONICLE_RESET_JOURNAL", "BIG CHRONICLE\n\n이 캐릭터의 모험 일지와 통계를 모두 지울까요?", function() ns:ResetData("journal") end)
	end)
	b1:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -12)
	local b2 = UI.Button(right, "몬스터 도감 초기화", RIGHT_W, 28, function()
		Confirm("BIGCHRONICLE_RESET_DEX", "BIG CHRONICLE\n\n이 캐릭터의 몬스터 도감을 모두 지울까요?", function() ns:ResetData("dex") end)
	end)
	b2:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -4)
	local b3 = UI.Button(right, "모든 기록 초기화", RIGHT_W, 28, function()
		Confirm("BIGCHRONICLE_RESET_ALL", "BIG CHRONICLE\n\n이 캐릭터의 일지와 도감을 모두 지우고 처음부터 다시 기록할까요?", function() ns:ResetData("all") end)
	end)
	b3:SetPoint("TOPLEFT", b2, "BOTTOMLEFT", 0, -4)
	local b4 = UI.Button(right, "미니맵 버튼 위치 초기화", RIGHT_W, 28, function()
		ns.db.minimap.angle = ns.DEFAULTS.minimap.angle
		if ns.Minimap then ns.Minimap:Update() end
	end)
	b4:SetPoint("TOPLEFT", b3, "BOTTOMLEFT", 0, -4)

	local h3 = UI.Label(right, "명령어")
	h3:SetPoint("TOPLEFT", b4, "BOTTOMLEFT", 0, -30)

	local info = UI.Text(right, UI.F.small, col.text)
	info:SetPoint("TOPLEFT", h3, "BOTTOMLEFT", 0, -10)
	info:SetWidth(RIGHT_W)
	info:SetJustifyH("LEFT")
	info:SetSpacing(5)
	info:SetText(UI:Themed("|cffffd100/bc|r   창 열기\n" ..
		"|cffffd100/도감|r   도감 열기\n" ..
		"|cffffd100/bc 업적|r   업적 보기\n" ..
		"|cffffd100/일지 <내용>|r   나만의 기록 남기기\n" ..
		"|cffffd100/bc 내보내기|r   일지 전체 복사"))

	local credit = UI.Text(right, UI.F.tiny)
	credit:SetPoint("BOTTOMLEFT", 0, 0)
	credit:SetWidth(RIGHT_W)
	credit:SetSpacing(3)
	credit:SetText("BIG CHRONICLE  v" .. ns.VERSION .. "\nSpecial thanks to  루마 · 절미 · 판초네 콘체타 · KLEROS")
	return p
end

function O:SetTheme(id)
	if id == (ns.db.theme or "light") then return end
	Confirm("BIGCHRONICLE_THEME", "BIG CHRONICLE\n\n테마를 바꾸려면 UI를 다시 불러와야 합니다.\n지금 다시 불러올까요?", function()
		ns.db.theme = id
		if ReloadUI then ReloadUI() end
	end)
end

function O:Refresh()
	if not self.checks then return end
	for _, cb in ipairs(self.checks) do cb:Sync() end
	local cur = ns.db.theme or "light"
	for id, b in pairs(self.themeButtons) do b:SetSelected(id == cur) end
end
