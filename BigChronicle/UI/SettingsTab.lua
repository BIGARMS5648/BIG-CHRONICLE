-- BIG CHRONICLE :: 설정 탭

local ADDON, ns = ...
local UI = ns.UI
local O = {}
ns.SettingsTab = O

local OPTIONS = {
	{ key = "chat",         label = "새 기록을 채팅창에 알리기",       desc = "일지에 기록이 추가될 때 채팅창에도 짧게 출력합니다. (장소 발견 제외)" },
	{ key = "toast",        label = "도감 알림 팝업 보이기",           desc = "새 종족·개체·희귀 개체를 발견하면 화면 위쪽에 두루마리 알림을 띄웁니다." },
	{ key = "sound",        label = "알림 효과음",                     desc = "알림 팝업이 뜰 때 효과음을 재생합니다." },
	{ key = "logSubzones",  label = "세부 장소 발견도 일지에 기록",     desc = "마을·동굴 같은 세부 장소를 처음 찾았을 때도 기록합니다." },
	{ key = "questRewards", label = "퀘스트 기록에 보상 표시",          desc = "퀘스트 완료 기록 끝에 경험치와 골드 보상을 덧붙입니다." },
	{ key = "nameplates",   label = "이름표로도 몬스터 발견",           desc = "적 이름표가 보이는 거리의 몬스터도 도감에 등록합니다." },
	{ key = "tooltip",      label = "몬스터 툴팁에 도감 정보 표시",     desc = "마우스를 올렸을 때 도감 번호, 종족, 처치 수를 보여 줍니다." },
	{ key = "typewriter",   label = "글자가 한 자씩 써지는 연출",       desc = "도감의 배경 이야기가 대화창처럼 차례로 써집니다. (클릭·Space로 건너뛰기)" },
	{ key = "hotkeys",      label = "키보드 단축키 사용",               desc = "창이 열려 있을 때 1~4, 방향키, Space를 사용합니다. 전투 중에는 자동으로 꺼집니다." },
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

	local left = CreateFrame("Frame", nil, p)
	left:SetPoint("TOPLEFT", 30, 0)
	left:SetPoint("BOTTOMLEFT", 30, 0)
	left:SetWidth(470)

	local title = left:CreateFontString(nil, "OVERLAY", UI.F.header)
	title:SetPoint("TOPLEFT", 0, -4)
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
			cb:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -24)
		else
			cb:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 2, -16)
		end
		self.checks[#self.checks + 1] = cb
		prev = cb
	end
	local mm = UI.Check(left, "미니맵 버튼 보이기",
		function() return not ns.db.minimap.hide end,
		function(v) ns.db.minimap.hide = not v; if ns.Minimap then ns.Minimap:Update() end end,
		"왼쪽 클릭: 창 열기 · 오른쪽 클릭: 도감 · 드래그: 위치 옮기기")
	mm:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -24)
	self.checks[#self.checks + 1] = mm

	-- 오른쪽: 테마 / 데이터 관리 / 정보
	local right = UI.Section(p)
	right:SetPoint("TOPRIGHT", -30, 0)
	right:SetPoint("BOTTOMRIGHT", -30, 0)
	right:SetWidth(330)

	local h0 = right:CreateFontString(nil, "OVERLAY", UI.F.header)
	h0:SetPoint("TOP", 0, -12)
	h0:SetText("두루마리 테마")
	local themeNote = UI.Text(right, UI.F.small)
	themeNote:SetPoint("TOP", h0, "BOTTOM", 0, -6)
	themeNote:SetWidth(290)
	themeNote:SetJustifyH("CENTER")
	themeNote:SetText("테마를 바꾸면 UI를 다시 불러옵니다.")

	self.themeButtons = {}
	local tb1 = UI.Button(right, "양피지 (밝게)", 138, 26, function() O:SetTheme("light") end)
	tb1:SetPoint("TOPRIGHT", themeNote, "BOTTOM", -4, -10)
	local tb2 = UI.Button(right, "어둠 (어둡게)", 138, 26, function() O:SetTheme("dark") end)
	tb2:SetPoint("TOPLEFT", themeNote, "BOTTOM", 4, -10)
	self.themeButtons.light, self.themeButtons.dark = tb1, tb2

	local div = UI.Divider(right, 290)
	div:SetPoint("TOP", themeNote, "BOTTOM", 0, -50)

	local h = right:CreateFontString(nil, "OVERLAY", UI.F.header)
	h:SetPoint("TOP", div, "BOTTOM", 0, -8)
	h:SetText("데이터 관리")
	local note = UI.Text(right, UI.F.small)
	note:SetPoint("TOP", h, "BOTTOM", 0, -6)
	note:SetWidth(290)
	note:SetJustifyH("CENTER")
	note:SetText("기록은 캐릭터마다 따로 저장됩니다.\n초기화한 기록은 되돌릴 수 없습니다.")

	local b1 = UI.Button(right, "모험 일지 초기화", 290, 24, function()
		Confirm("BIGCHRONICLE_RESET_JOURNAL", "BIG CHRONICLE\n\n이 캐릭터의 모험 일지와 통계를 모두 지울까요?", function() ns:ResetData("journal") end)
	end)
	b1:SetPoint("TOP", note, "BOTTOM", 0, -12)
	local b2 = UI.Button(right, "몬스터 도감 초기화", 290, 24, function()
		Confirm("BIGCHRONICLE_RESET_DEX", "BIG CHRONICLE\n\n이 캐릭터의 몬스터 도감을 모두 지울까요?", function() ns:ResetData("dex") end)
	end)
	b2:SetPoint("TOP", b1, "BOTTOM", 0, -6)
	local b3 = UI.Button(right, "모든 기록 초기화", 290, 24, function()
		Confirm("BIGCHRONICLE_RESET_ALL", "BIG CHRONICLE\n\n이 캐릭터의 일지와 도감을 모두 지우고 처음부터 다시 기록할까요?", function() ns:ResetData("all") end)
	end)
	b3:SetPoint("TOP", b2, "BOTTOM", 0, -6)
	local b4 = UI.Button(right, "미니맵 버튼 위치 초기화", 290, 24, function()
		ns.db.minimap.angle = ns.DEFAULTS.minimap.angle
		if ns.Minimap then ns.Minimap:Update() end
	end)
	b4:SetPoint("TOP", b3, "BOTTOM", 0, -6)

	local div2 = UI.Divider(right, 290)
	div2:SetPoint("TOP", b4, "BOTTOM", 0, -12)

	local info = UI.Text(right, UI.F.small, col.text)
	info:SetPoint("TOP", div2, "BOTTOM", 0, -8)
	info:SetWidth(290)
	info:SetJustifyH("CENTER")
	info:SetSpacing(3)
	info:SetText(UI:Themed("|cffd4af37BIG CHRONICLE|r  v" .. ns.VERSION .. "\n" ..
		"|cffffd100/bc|r 창 열기   ·   |cffffd100/도감|r 도감 열기\n" ..
		"|cffffd100/일지 <내용>|r 나만의 기록 남기기\n" ..
		"|cffffd100/bc 내보내기|r 일지 전체 복사"))
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
