
DPP.SettingsClass = DPP.SettingsClass or {}

local SettingsClass = DPP.SettingsClass
local FUNCTIONS = {}
DPP.SettingsClass.FUNCTIONS = FUNCTIONS

function FUNCTIONS.CheckBoxThink(self)
	local val = DPP.GetConVar(self.val)
	self:SetChecked(val)
	self.LastVal = val
end

function FUNCTIONS.CheckBoxDoClick(self)
	if not LocalPlayer():IsSuperAdmin() then return end
	
	RunConsoleCommand('dpp_setvar', self.val, tobool(self.LastVal) and '0' or '1')
end

function FUNCTIONS.CCheckBoxThink(self)
	local val = DPP.PlayerConVar(LocalPlayer(), self.val)
	self:SetChecked(val)
	self.LastVal = val
end

function FUNCTIONS.CCheckBoxDoClick(self)
	RunConsoleCommand('dpp_' .. self.val, (not self.LastVal) == false and '0' or '1')
end

function DPP.OpenFriendEditMenu(steamid)
	steamid = string.upper(steamid)
	local t = DPP.ClientFriends[steamid] or {
		nick = '',
	}
	
	DPP.CheckFriendArgs(t)
	
	local height = 50
	
	local frame = vgui.Create('DFrame')
	frame:SetTitle('Modifying ' .. steamid)
	SettingsClass.ApplyFrameStyle(frame)
	
	local groups = DPP.GetGroups()
	local Panels = {}
	
	for k, v in pairs(t) do
		if k == 'nick' then continue end
		height = height + 20
		
		local p = frame:Add('DCheckBoxLabel')
		Panels[k] = p
		p:Dock(TOP)
		p:SetText(string.gsub(k, '^.', string.upper) .. ' buddy')
		p:SetChecked(v)
		p.Type = k
	end
	
	height = height + 30
	
	local apply = frame:Add('DButton')
	apply:Dock(BOTTOM)
	apply:SetText('Apply')
	SettingsClass.ApplyButtonStyle(apply)
	
	function apply.DoClick()
		local t = {}
		
		for k, v in pairs(Panels) do
			t[k] = v:GetChecked()
		end
		
		DPP.AddFriendBySteamID(steamid, t)
		frame:Close()
	end
	
	local discard = frame:Add('DButton')
	discard:Dock(BOTTOM)
	discard:SetText('Discard')
	SettingsClass.ApplyButtonStyle(discard)
	
	function discard.DoClick()
		frame:Close()
	end
	
	frame:SetHeight(height)
	frame:SetWidth(200)
	frame:Center()
	frame:MakePopup()
end

function DPP.OpenShareMenu(ent)
	if DPP.GetOwner(ent) ~= LocalPlayer() then return end
	local t = DPP.GetSharedTable(ent)
	
	local height = 50
	
	local frame = vgui.Create('DFrame')
	frame:SetTitle('Share of ' .. tostring(ent))
	SettingsClass.ApplyFrameStyle(frame)
	
	local groups = DPP.GetGroups()
	local Panels = {}
	
	for k, v in pairs(DPP.ShareTypes) do
		height = height + 20
		
		local p = frame:Add('DCheckBoxLabel')
		Panels[k] = p
		p:Dock(TOP)
		p:SetText(v .. ' share')
		p:SetChecked(t[k])
		p.Type = k
	end
	
	height = height + 50
	
	local apply = frame:Add('DButton')
	apply:Dock(BOTTOM)
	apply:SetText('Apply')
	SettingsClass.ApplyButtonStyle(apply)
	
	function apply.DoClick()
		if IsValid(ent) then
			local inx = ent:EntIndex()
			for k, v in pairs(Panels) do
				RunConsoleCommand('dpp_share', inx, k, v:GetChecked() and '1' or '0')
			end
		end
		
		frame:Close()
	end
	
	local discard = frame:Add('DButton')
	discard:Dock(BOTTOM)
	discard:SetText('Discard')
	SettingsClass.ApplyButtonStyle(discard)
	
	function discard.DoClick()
		frame:Close()
	end
	
	local unselectall = frame:Add('DButton')
	unselectall:Dock(BOTTOM)
	unselectall:SetText('Unshare')
	SettingsClass.ApplyButtonStyle(unselectall)
	
	function unselectall.DoClick()
		if IsValid(ent) then
			local inx = ent:EntIndex()
			for k, v in pairs(Panels) do
				RunConsoleCommand('dpp_share', inx, k, '0')
			end
		end
		
		frame:Close()
	end
	
	frame:SetHeight(height)
	frame:SetWidth(400)
	frame:Center()
	frame:MakePopup()
end

SettingsClass.Styles = SettingsClass.Styles or {}
local Style = SettingsClass.Styles

SettingsClass.Background = Color(65, 65, 65)
SettingsClass.Glow = Color(125, 125, 125)
SettingsClass.Checked = Color(105, 255, 250)
SettingsClass.UnChecked = Color(255, 148, 148)
SettingsClass.CheckBox = Color(50, 50, 50)
SettingsClass.FrameColor = SettingsClass.Background
SettingsClass.TextColor = color_white
SettingsClass.Chars = {'!','@','#','$','%','^','&','*','(',')'}

function Style.ScramblingCharsThink(self)
	if DPP.PlayerConVar(nil, 'no_scrambling_text') then return end
	local isHovered = IsValid(hoverPanel) and hoverPanel:IsHovered() or IsValid(hoverPanel2) and hoverPanel2:IsHovered() or self:IsHovered()
	
	if isHovered and not self.IsScrambling and not self.AfterScramble then
		self.IsScrambling = true
		self.OriginalText = self:GetText()
		self.CurrentChar = 1
		self.Chars = #self.OriginalText
		self.NextChar = CurTime() + 0.1
	end
	
	if not isHovered and self.AfterScramble then
		self.AfterScramble = false
	end
	
	if self.IsScrambling and self.NextChar < CurTime() then
		if self.Chars >= self.CurrentChar then
			local t = string.sub(self.OriginalText, 1, self.CurrentChar) .. table.Random(SettingsClass.Chars) .. table.Random(SettingsClass.Chars) .. table.Random(SettingsClass.Chars) .. string.sub(self.OriginalText, self.CurrentChar + 3)
			self:SetText(t)
			self:SizeToContents()
			self.CurrentChar = self.CurrentChar + 1
		else
			self:SetText(self.OriginalText)
			self.IsScrambling = false
			self.AfterScramble = true
			self:SizeToContents()
		end
	end
	
	if self.oldThink then self.oldThink(self) end
end

function Style.ScramblingCharsThinkButton(self)
	if DPP.PlayerConVar(nil, 'no_scrambling_text') then return end
	local isHovered = IsValid(hoverPanel) and hoverPanel:IsHovered() or IsValid(hoverPanel2) and hoverPanel2:IsHovered() or self:IsHovered()
	
	if isHovered and not self.IsScrambling and not self.AfterScramble then
		self.IsScrambling = true
		self.OriginalText = self:GetText()
		self.CurrentChar = 1
		self.Chars = #self.OriginalText
		self.NextChar = CurTime() + 0.1
	end
	
	if not isHovered and self.AfterScramble then
		self.AfterScramble = false
	end
	
	if self.IsScrambling and self.NextChar < CurTime() then
		if self.Chars >= self.CurrentChar then
			local t = string.sub(self.OriginalText, 1, self.CurrentChar) .. table.Random(SettingsClass.Chars) .. table.Random(SettingsClass.Chars) .. table.Random(SettingsClass.Chars) .. string.sub(self.OriginalText, self.CurrentChar + 3)
			self:SetText(t)
			--self:SizeToContents()
			self.CurrentChar = self.CurrentChar + 1
		else
			self:SetText(self.OriginalText)
			self.IsScrambling = false
			self.AfterScramble = true
			--self:SizeToContents()
		end
	end
	
	if self.oldThink then self.oldThink(self) end
end

function SettingsClass.AddScramblingChars(panel, hoverPanel, hoverPanel2)
	local oldThink = panel.Think
	panel.hoverPanel = hoverPanel
	panel.hoverPanel2 = hoverPanel2
	panel.Think = Style.ScramblingCharsThink
end

function Style.NeonButtonPaint(self, w, h)
	self.Neon = self.Neon or 0
	
	if not self:IsDown() then
		draw.RoundedBox(0, 0, 0,w, h,Color(self.Neon, self.Neon, self.Neon, 150))
	else
		draw.RoundedBox(0, 0, 0,w, h,Color(200, 200, 200, 150))
	end
	
	if self:IsHovered() then
		self.Neon = math.min(self.Neon + 5 * (66 / (1/FrameTime())), 150)
	else
		self.Neon = math.max(self.Neon - 5 * (66 / (1/FrameTime())), 0)
	end
end

function SettingsClass.ApplyButtonStyle(panel)
	panel.Paint = Style.NeonButtonPaint
	panel.Think = Style.ScramblingCharsThinkButton
	
	timer.Simple(0, function() if IsValid(panel) then panel:SetTextColor(Color(255, 255, 255)) end end)
end

function Style.FramePaint(self, w, h)
	draw.RoundedBox(0, 0, 0, w, h, SettingsClass.FrameColor)
end

function SettingsClass.ApplyFrameStyle(frame)
	frame.Paint = Style.FramePaint
end

surface.CreateFont('DPP.CheckBox', {
	font = 'Tahoma',
	weight = 800,
	size = 24,
})

SettingsClass.CheckBoxShift = -5

function Style.CheckBoxThink(self)
	local isHovered = self.Label:IsHovered() or self.Button:IsHovered() or self:IsHovered()
	
	self.IMyX = self:GetSize()
	if isHovered then
		self.CurrentArrowMove = math.Clamp(self.CurrentArrowMove + 1000 / (1/FrameTime()), -10, self.IMyX)
	else
		self.CurrentArrowMove = math.Clamp(self.CurrentArrowMove - 1000 / (1/FrameTime()), -10, self.IMyX)
	end
	
	if self.oldThink then self.oldThink() end
end

function Style.CheckBoxPaint(self, w, h)
	surface.SetDrawColor(SettingsClass.Glow)
	surface.DrawRect(0, 0, self.CurrentArrowMove, 30)
	
	--[[surface.DrawPoly{
		{x = x, y = 0},
		{x = x + 15, y = 0},
		{x = x - 2, y = 6},
		{x = x + 15, y = 12},
		{x = x, y = 12},
		{x = x - 15, y = 6},
	}]]
	
	self.oldPaint(w, h)
end

function Style.CheckBoxButtonPaint(self, w, h)
	local isChecked = self:GetChecked()
	
	surface.SetDrawColor(SettingsClass.CheckBox)
	surface.DrawRect(0, 0, w, h)
	
	surface.SetDrawColor(isChecked and SettingsClass.Checked or SettingsClass.UnChecked)
	surface.DrawRect(2, 2, w - 4, h - 4)
end

function SettingsClass.MakeCheckboxBetter(panel)
	panel.oldThink = panel.Think
	panel.oldPaint = panel.Paint
	
	panel.CurrentArrowMove = 0
	panel.SizeOfArrow = 0
	
	panel.Label:SetTextColor(SettingsClass.TextColor)
	panel.Think = Style.CheckBoxThink
	panel.Paint = Style.CheckBoxPaint
	
	panel.Button.Paint = Style.CheckBoxButtonPaint
end

function SettingsClass.PaintBackground(s, w, h)
	surface.SetDrawColor(SettingsClass.Background)
	surface.DrawRect(0, 0, w, h)
end

function SettingsClass.SetupBackColor(Panel)
	Panel.Paint = SettingsClass.PaintBackground
end

function SettingsClass.ApplySliderStyle(Slider)
	Slider.Label:SetTextColor(SettingsClass.TextColor)
	Slider.TextArea:SetTextColor(SettingsClass.TextColor)
end

local SortedConVars = {
	'enable',
	'enable_lists',
	'enable_blocked',
	'enable_tool',
	'enable_physgun',
	'enable_gravgun',
	'enable_veh',
	'enable_use',
	'enable_pickup',
	'enable_damage',
	'enable_drive',
	'toolgun_player',
	'toolgun_player_admin',
	'can_admin_touch_world',
	'admin_can_everything',
	'can_touch_world',
	
	'clear_disconnected',
	'clear_disconnected_admin',
	
	'grabs_disconnected',
	'grabs_disconnected_admin',
}

local MiscConVars = {
	'check_stuck',
	'no_rope_world',
	'log_spawns',
	'log_constraints',
	'verbose_logging',
	'no_tool_log',
	'no_tool_fail_log',
	'player_cant_punt',
	'prevent_explosions_crash',
	'advanced_spawn_checks',
	'experemental_spawn_checks',
	'allow_damage_vehicles',
	'allow_damage_sent',
	'allow_damage_npc',
}

function SettingsClass.ConVarSlider(Panel, var)
	local v = DPP.Settings[var]
	
	local Slider = Panel:NumSlider(v.desc, nil, v.min or 0, v.max or 100, 1)
	SettingsClass.ApplySliderStyle(Slider)
	Slider:SetTooltip(v.desc)
	Slider:SetValue(DPP.GetConVar(var))
	Slider.OnValueChanged = function()
		local val = tonumber(Slider:GetValue())
		
		if v.int then
			val = math.floor(val)
		else
			val = math.floor(val * 1000) / 1000
		end
		
		timer.Create('DPP.Change' .. var, 1, 1, function()
			RunConsoleCommand('dpp_setvar', var, tostring(val))
			if IsValid(Slider) then
				Slider:SetValue(val)
			end
		end)
	end
	
	return Slider
end

function SettingsClass.ConVarCheckbox(Panel, idx)
	local val = tobool(DPP.GetConVar(idx))
	local checkbox = Panel:CheckBox(DPP.Settings[idx].desc)
	checkbox:SetChecked(val)
	checkbox.Button.LastVal = val
	checkbox.Button.val = idx
	checkbox.Button.DoClick = FUNCTIONS.CheckBoxDoClick
	checkbox.Button.Think = FUNCTIONS.CheckBoxThink
	checkbox:SetTooltip(DPP.Settings[idx].desc)
	SettingsClass.AddScramblingChars(checkbox.Label, checkbox, checkbox.Button)
	SettingsClass.MakeCheckboxBetter(checkbox)
end

local ConVarSlider = SettingsClass.ConVarSlider
local ConVarCheckbox = SettingsClass.ConVarCheckbox

local APropKillVars = {
	'apropkill_enable',
	'apropkill_nopush',
	'apropkill_vehicle',
	'apropkill_damage',
	'prevent_prop_throw',
	'prevent_player_stuck',
	'apropkill_clampspeed',
}

local PlacedCVars = {}

local function BuildSVarPanel(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	Panel:Dock(FILL)
	SettingsClass.SetupBackColor(Panel)
	
	local Lab = vgui.Create('DLabel', Panel)
	Panel:AddItem(Lab)
	local TopText = 'DPP was created by DBot\nNOTE "Main Power Switch" disables blacklists \nand protection modules, but not restrictions.'
	Lab:SetText(TopText)
	Lab:SetTextColor(SettingsClass.TextColor)
	Lab:SizeToContents()
	Lab:SetTooltip(TopText)
	
	for a, b in pairs(SortedConVars) do
		ConVarCheckbox(Panel, b)
	end
	
	ConVarSlider(Panel, 'clear_timer')
	ConVarSlider(Panel, 'grabs_timer')
end

local function BuildCVarPanel(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	
	for k, v in pairs(DPP.CSettings) do
		if not v.bool then continue end
		local val = DPP.PlayerConVar(LocalPlayer(), k)
		
		local checkbox = Panel:CheckBox(v.desc)
		checkbox:SetChecked(val)
		checkbox.Button.LastVal = val
		checkbox.Button.val = k
		checkbox.Button.DoClick = FUNCTIONS.CCheckBoxDoClick
		checkbox.Button.Think = FUNCTIONS.CCheckBoxThink
		checkbox:SetTooltip(v.desc)
		SettingsClass.AddScramblingChars(checkbox.Label, checkbox, checkbox.Button)
		SettingsClass.MakeCheckboxBetter(checkbox)
	end
	
	local FontBox = Panel:ComboBox('Font')
	for k, v in pairs(DPP.Fonts) do
		FontBox:AddChoice(v.name)
	end
	FontBox:SetValue(DPP.GetFont(true))
	FontBox:SetHeight(20)
	FontBox.OnSelect = function(self, i, num)
		RunConsoleCommand('dpp_font', i)
	end
end

local function BuildMiscVarsPanel(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	
	for a, b in pairs(MiscConVars) do
		ConVarCheckbox(Panel, b)
	end
end

local function BuildAPropKillVarsPanel(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	
	for a, b in pairs(APropKillVars) do
		ConVarCheckbox(Panel, b)
	end
	
	ConVarSlider(Panel, 'apropkill_clampspeed_val')
end

local function BuildAntispamPanel(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	
	SettingsClass.ConVarCheckbox(Panel, 'check_sizes')
	SettingsClass.ConVarCheckbox(Panel, 'stuck_ignore_frozen')
	SettingsClass.ConVarCheckbox(Panel, 'check_stuck')
	SettingsClass.ConVarSlider(Panel, 'max_size')
	SettingsClass.ConVarCheckbox(Panel, 'antispam')
	SettingsClass.ConVarSlider(Panel, 'antispam_delay')
	SettingsClass.ConVarSlider(Panel, 'antispam_remove')
	SettingsClass.ConVarSlider(Panel, 'antispam_ghost')
	SettingsClass.ConVarSlider(Panel, 'antispam_max')
	SettingsClass.ConVarSlider(Panel, 'antispam_cooldown_divider')
	SettingsClass.ConVarCheckbox(Panel, 'antispam_toolgun_enable')
	SettingsClass.ConVarSlider(Panel, 'antispam_toolgun')
end

local function BuildPlayerList(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	
	DPP.SettingsClass.PlayerPanel = Panel
	
	SettingsClass.ApplyButtonStyle(Panel:Button('Clear decals', 'dpp_cleardecals'))
	SettingsClass.ApplyButtonStyle(Panel:Button('Delete all player entities', 'dpp_clearmap'))
	SettingsClass.ApplyButtonStyle(Panel:Button('Freeze all player entities', 'dpp_freezeall'))
	SettingsClass.ApplyButtonStyle(Panel:Button('Delete disconnected player entities', 'dpp_cleardisconnected'))
	
	for k, v in pairs(DPP.GetPlayerList()) do
		local pnl = vgui.Create('EditablePanel')
		Panel:AddItem(pnl)
		local lab = Label(v.Name)
		lab:SetParent(pnl)
		lab:Dock(LEFT)
		lab:SetTextColor(SettingsClass.TextColor)
		
		local Button = vgui.Create('DButton', pnl)
		Button:Dock(RIGHT)
		Button:SetWidth(48)
		Button:SetText('UF')
		Button:SetConsoleCommand('dpp_unfreezebyuid', v.UID)
		SettingsClass.ApplyButtonStyle(Button)
		
		local Button = vgui.Create('DButton', pnl)
		Button:Dock(RIGHT)
		Button:SetWidth(48)
		Button:SetText('F')
		Button:SetConsoleCommand('dpp_freezebyuid', v.UID)
		SettingsClass.ApplyButtonStyle(Button)
		
		local Button = vgui.Create('DButton', pnl)
		Button:Dock(RIGHT)
		Button:SetWidth(48)
		Button:SetText('D')
		Button:SetConsoleCommand('dpp_clearbyuid', v.UID)
		SettingsClass.ApplyButtonStyle(Button)
	end
end

local function BuildModelsList(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	DPP.SettingsClass.ModelPanel = Panel
	
	local list = vgui.Create('DListView', Panel)
	Panel:AddItem(list)
	
	list:SetHeight(600)
	list:AddColumn('Model')

	local L = DPP.BlockedModels
	
	for k, v in pairs(L) do
		list:AddLine(k)
	end
	
	list.OnRowRightClick = function(self, line)
		local val = self:GetLine(line):GetValue(1)
		local menu = vgui.Create('DMenu')
		menu:AddOption('Copy model to clipboard', function()
			SetClipboardText(val)
		end)
		
		menu:AddOption('Remove from blacklist', function()
			RunConsoleCommand('dpp_removeblockedmodel', val)
		end)
		menu:Open()
	end
	
	local entry = vgui.Create('DTextEntry', Panel)
	Panel:AddItem(entry)
	local Apply = Panel:Button('Add model')
	Apply.DoClick = function()
		RunConsoleCommand('dpp_addblockedmodel', entry:GetText())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	local Apply = Panel:Button('Remove model')
	Apply.DoClick = function()
		RunConsoleCommand('dpp_removeblockedmodel', entry:GetText())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	local Apply = Panel:Button('Add model of entity that you are looking at')
	Apply.DoClick = function()
		local ent = LocalPlayer():GetEyeTrace().Entity
		if not IsValid(ent) then return end
		RunConsoleCommand('dpp_addblockedmodel', ent:GetModel())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	local Apply = Panel:Button('Remove model of entity that you are looking at')
	Apply.DoClick = function()
		local ent = LocalPlayer():GetEyeTrace().Entity
		if not IsValid(ent) then return end
		RunConsoleCommand('dpp_removeblockedmodel', ent:GetModel())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	ConVarCheckbox(Panel, 'model_blacklist')
end

local function OpenLimitEditPanel(class)
	local t = DPP.EntsLimits[class] or {}
	
	local height = 50
	
	local frame = vgui.Create('DFrame')
	frame:SetTitle('Modifying ' .. class)
	SettingsClass.ApplyFrameStyle(frame)
	
	local groups = DPP.GetGroups()
	local Panels = {}
	
	for k, v in pairs(groups) do
		height = height + 50
		local l = frame:Add('DLabel')
		local p = frame:Add('DTextEntry')
		table.insert(Panels, p)
		p.Group = v
		l:Dock(TOP)
		l:SetText(v)
		l:SetTextColor(SettingsClass.TextColor)
		p:Dock(TOP)
		p:SetText(t[v] or '-1')
		p.OriginalValue = (t[v] or '-1')
	end
	
	local apply = frame:Add('DButton')
	apply:Dock(BOTTOM)
	apply:SetText('Apply')
	SettingsClass.ApplyButtonStyle(apply)
	
	function apply.DoClick()
		t = {}
		
		for k, v in pairs(Panels) do
			local n = tonumber(v:GetText())
			if not n then continue end
			if tonumber(v.OriginalValue) == n then continue end
			
			if n > 0 then
				RunConsoleCommand('dpp_addentitylimit', class, v.Group, n)
			else
				RunConsoleCommand('dpp_removeentitylimit', class, v.Group)
			end
		end
		
		frame:Close()
	end
	
	local discard = frame:Add('DButton')
	discard:Dock(BOTTOM)
	discard:SetText('Discard')
	SettingsClass.ApplyButtonStyle(discard)
	
	function discard.DoClick()
		frame:Close()
	end
	
	frame:SetHeight(height)
	frame:SetWidth(300)
	frame:Center()
	frame:MakePopup()
end

local function BuildLimitsList(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	DPP.SettingsClass.LimitsPanel = Panel
	
	local Lab = vgui.Create('DLabel', Panel)
	Panel:AddItem(Lab)
	Lab:SetTextColor(SettingsClass.TextColor)
	Lab:SetText('NOTE: This just prevents the player from spawning\n entities with the given class if the player spawned\n the given amount of entities within this class.\nThat means it DOES NOT allow groups to spawn\n unlimited amounts of entities within that\n type. For that use the Sandbox limits\n instead.')
	Lab:SizeToContents()
	
	local list = vgui.Create('DListView', Panel)
	Panel:AddItem(list)
	
	list:SetHeight(600)
	list:AddColumn('Class')
	list:AddColumn('Group')
	list:AddColumn('Limit')

	local L = DPP.EntsLimits
	
	for k, v in pairs(L) do
		for group, limit in pairs(v) do
			list:AddLine(k, group, limit)
		end
	end
	
	list.OnRowRightClick = function(self, line)
		local val = self:GetLine(line):GetValue(1)
		local group = self:GetLine(line):GetValue(2)
		local limit = self:GetLine(line):GetValue(3)
		
		local menu = vgui.Create('DMenu')
		menu:AddOption('Copy class to clipboard', function()
			SetClipboardText(val)
		end)
		
		menu:AddOption('Edit limit...', function()
			OpenLimitEditPanel(val)
		end)
		
		menu:AddOption('Remove this limit', function()
			RunConsoleCommand('dpp_removeentitylimit', val, group)
		end)
		
		menu:Open()
	end
	
	local entry = vgui.Create('DTextEntry', Panel)
	Panel:AddItem(entry)
	local Apply = Panel:Button('Add/Edit limit')
	Apply.DoClick = function()
		OpenLimitEditPanel(entry:GetText())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	local Apply = Panel:Button('Remove limit')
	Apply.DoClick = function()
		RunConsoleCommand('dpp_removeentitylimit', entry:GetText())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	local Apply = Panel:Button('Add a limit for the entity you\'re looking at')
	Apply.DoClick = function()
		local ent = LocalPlayer():GetEyeTrace().Entity
		if not IsValid(ent) then return end
		OpenLimitEditPanel(ent:GetClass())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	local Apply = Panel:Button('Remove the limit for the entity you\'re looking at')
	Apply.DoClick = function()
		local ent = LocalPlayer():GetEyeTrace().Entity
		if not IsValid(ent) then return end
		RunConsoleCommand('dpp_removeentitylimit', ent:GetClass())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	ConVarCheckbox(Panel, 'ent_limits_enable')
end

local function RemoveAllSLimits(class)
	for k, v in pairs(DPP.GetGroups()) do
		RunConsoleCommand('dpp_removesboxlimit', class, v)
	end
end

local function RemoveAllCLimits(class)
	for k, v in pairs(DPP.GetGroups()) do
		RunConsoleCommand('dpp_removeconstlimit', class, v)
	end
end

local function OpenSLimitEditPanel(class)
	local t = DPP.SBoxLimits[class] or {}
	
	local height = 90
	
	local frame = vgui.Create('DFrame')
	frame:SetTitle('Modifying ' .. class)
	SettingsClass.ApplyFrameStyle(frame)
	
	local lab = frame:Add('DLabel')
	lab:SetTextColor(SettingsClass.TextColor)
	lab:SetText('Unlimited: -1\n0 - removes limit from db\nAny values higher than 0 is a limit')
	lab:Dock(TOP)
	lab:SizeToContents()
	
	local groups = DPP.GetGroups()
	local Panels = {}
	
	for k, v in pairs(groups) do
		height = height + 50
		local l = frame:Add('DLabel')
		local p = frame:Add('DTextEntry')
		table.insert(Panels, p)
		p.Group = v
		l:Dock(TOP)
		l:SetText(v)
		l:SetTextColor(SettingsClass.TextColor)
		p:Dock(TOP)
		p:SetText(t[v] or '0')
		p.OriginalValue = (t[v] or '0')
	end
	
	local apply = frame:Add('DButton')
	apply:Dock(BOTTOM)
	apply:SetText('Apply')
	SettingsClass.ApplyButtonStyle(apply)
	
	function apply.DoClick()
		t = {}
		
		for k, v in pairs(Panels) do
			local n = tonumber(v:GetText())
			if not n then continue end
			if tonumber(v.OriginalValue) == n then continue end
			
			if n ~= 0 then
				RunConsoleCommand('dpp_addsboxlimit', class, v.Group, n)
			else
				RunConsoleCommand('dpp_removesboxlimit', class, v.Group)
			end
		end
		
		frame:Close()
	end
	
	local discard = frame:Add('DButton')
	discard:Dock(BOTTOM)
	discard:SetText('Discard')
	SettingsClass.ApplyButtonStyle(discard)
	
	function discard.DoClick()
		frame:Close()
	end
	
	frame:SetHeight(height)
	frame:SetWidth(300)
	frame:Center()
	frame:MakePopup()
end

local function OpenCLimitEditPanel(class)
	local t = DPP.ConstrainsLimits[class] or {}
	
	local height = 90
	
	local frame = vgui.Create('DFrame')
	frame:SetTitle('Modifying ' .. class)
	SettingsClass.ApplyFrameStyle(frame)
	
	local lab = frame:Add('DLabel')
	lab:SetTextColor(SettingsClass.TextColor)
	lab:SetText('Unlimited: -1\n0 - removes limit from db\nAny values higher than 0 is a limit')
	lab:Dock(TOP)
	lab:SizeToContents()
	
	local groups = DPP.GetGroups()
	local Panels = {}
	
	for k, v in pairs(groups) do
		height = height + 50
		local l = frame:Add('DLabel')
		local p = frame:Add('DTextEntry')
		table.insert(Panels, p)
		p.Group = v
		l:Dock(TOP)
		l:SetText(v)
		l:SetTextColor(SettingsClass.TextColor)
		p:Dock(TOP)
		p:SetText(t[v] or '0')
		p.OriginalValue = (t[v] or '0')
	end
	
	local apply = frame:Add('DButton')
	apply:Dock(BOTTOM)
	apply:SetText('Apply')
	SettingsClass.ApplyButtonStyle(apply)
	
	function apply.DoClick()
		t = {}
		
		for k, v in pairs(Panels) do
			local n = tonumber(v:GetText())
			if not n then continue end
			if tonumber(v.OriginalValue) == n then continue end
			
			if n ~= 0 then
				RunConsoleCommand('dpp_addconstlimit', class, v.Group, n)
			else
				RunConsoleCommand('dpp_removeconstlimit', class, v.Group)
			end
		end
		
		frame:Close()
	end
	
	local discard = frame:Add('DButton')
	discard:Dock(BOTTOM)
	discard:SetText('Discard')
	SettingsClass.ApplyButtonStyle(discard)
	
	function discard.DoClick()
		frame:Close()
	end
	
	frame:SetHeight(height)
	frame:SetWidth(300)
	frame:Center()
	frame:MakePopup()
end

local function BuildSLimitsList(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	DPP.SettingsClass.SLimitsPanel = Panel
	
	local Lab = vgui.Create('DLabel', Panel)
	Panel:AddItem(Lab)
	local t = 'WHAT THIS DOES:\nIt\'s the console variable sbox_max<...> overrides for user groups.\nTo add values, you must know the console variable you\'re changing.\nExample: Modifying prop limits would be "props" (sbox_maxprops).\nA value of -1 is unlimited, and 0 leaves the limit unmodified.'
	Lab:SetTextColor(SettingsClass.TextColor)
	Lab:SetText(t)
	Lab:SizeToContents()
	Lab:SetTooltip(t)
	
	local list = vgui.Create('DListView', Panel)
	Panel:AddItem(list)
	
	list:SetHeight(600)
	list:AddColumn('sbox_max...')
	list:AddColumn('Group')
	list:AddColumn('Limit')

	local L = DPP.SBoxLimits
	
	for k, v in pairs(L) do
		for group, limit in pairs(v) do
			list:AddLine(k, group, limit)
		end
	end
	
	list.OnRowRightClick = function(self, line)
		local val = self:GetLine(line):GetValue(1)
		local group = self:GetLine(line):GetValue(2)
		local limit = self:GetLine(line):GetValue(3)
		
		local menu = vgui.Create('DMenu')
		menu:AddOption('Copy cvar name to clipboard', function()
			SetClipboardText('sbox_max' .. val)
		end)
		
		menu:AddOption('Edit limit...', function()
			OpenSLimitEditPanel(val)
		end)
		
		menu:AddOption('Remove this limit', function()
			RunConsoleCommand('dpp_removesboxlimit', val, group)
		end)
		
		menu:AddOption('Remove this limit for all groups', function()
			RemoveAllSLimits(val)
		end)
		
		menu:Open()
	end
	
	local entry = vgui.Create('DTextEntry', Panel)
	Panel:AddItem(entry)
	local Apply = Panel:Button('Add/Edit/Remove limit')
	Apply.DoClick = function()
		OpenSLimitEditPanel(entry:GetText())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	ConVarCheckbox(Panel, 'sbox_limits_enable')
end

local function BuildCLimitsList(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	DPP.SettingsClass.CLimitsPanel = Panel
	
	local Lab = vgui.Create('DLabel', Panel)
	Panel:AddItem(Lab)
	local t = 'You can see type of constraints in DPP logs\nATTENTION: Because of nature of rope constraints\nDPP thinks that keyframe_rope is a "vrope"\nconstraint because rope (and related) constraints\n creating keyframe_rope too to show visual rope.'
	Lab:SetTextColor(SettingsClass.TextColor)
	Lab:SetText(t)
	Lab:SizeToContents()
	Lab:SetTooltip(t)
	
	local list = vgui.Create('DListView', Panel)
	Panel:AddItem(list)
	
	list:SetHeight(600)
	list:AddColumn('Class')
	list:AddColumn('Group')
	list:AddColumn('Limit')

	local L = DPP.ConstrainsLimits
	
	for k, v in pairs(L) do
		for group, limit in pairs(v) do
			list:AddLine(k, group, limit)
		end
	end
	
	list.OnRowRightClick = function(self, line)
		local val = self:GetLine(line):GetValue(1)
		local group = self:GetLine(line):GetValue(2)
		local limit = self:GetLine(line):GetValue(3)
		
		local menu = vgui.Create('DMenu')
		menu:AddOption('Copy class to clipboard', function()
			SetClipboardText(val)
		end)
		
		menu:AddOption('Edit limit...', function()
			OpenCLimitEditPanel(val)
		end)
		
		menu:AddOption('Remove this limit', function()
			RunConsoleCommand('dpp_removeconstlimit', val, group)
		end)
		
		menu:AddOption('Remove this limit for all groups', function()
			RemoveAllCLimits(val)
		end)
		
		menu:Open()
	end
	
	local entry = vgui.Create('DTextEntry', Panel)
	Panel:AddItem(entry)
	local Apply = Panel:Button('Add/Edit/Remove limit')
	Apply.DoClick = function()
		OpenCLimitEditPanel(entry:GetText())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	ConVarCheckbox(Panel, 'const_limits_enable')
end

local PanelsFunctions = {}
local PanelsFunctions2 = {}
DPP.SettingsClass.ValidPanels = DPP.SettingsClass.ValidPanels or {}
DPP.SettingsClass.ValidPanels2 = DPP.SettingsClass.ValidPanels2 or {}
local ValidPanels = DPP.SettingsClass.ValidPanels
local ValidPanels2 = DPP.SettingsClass.ValidPanels2

local function REMOVE_ALL(class)
	for k, v in pairs(DPP.BlockTypes) do
		RunConsoleCommand('dpp_removeblockedentity' .. k, class)
	end
end

local function ADD_ALL(class)
	for k, v in pairs(DPP.BlockTypes) do
		RunConsoleCommand('dpp_addblockedentity' .. k, class)
	end
end

local function SORTER(a, b)
	return a < b
end

local CustomBlockMenus = {}

--Too lazy for adding new panel
function CustomBlockMenus.toolworld(Panel)
	local k = 'toolworld'
	local v = 'ToolgunWorld'
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	ValidPanels[k] = Panel
	
	local list = vgui.Create('DListView', Panel)
	Panel:AddItem(list)
	
	list:SetHeight(600)
	list:AddColumn('Entity')
	
	local L = DPP.BlockedEntities[k]
	local New = {}
	for k, v in pairs(L) do
		table.insert(New, k)
	end
	
	table.sort(New, SORTER)
	
	for k, v in pairs(New) do
		list:AddLine(v)
	end
	
	list.OnRowRightClick = function(self, line)
		local val = self:GetLine(line):GetValue(1)
		local menu = vgui.Create('DMenu')
		menu:AddOption('Copy tool mode to clipboard', function()
			SetClipboardText(val)
		end)
		
		menu:AddOption('Remove from blacklist', function()
			RunConsoleCommand('dpp_removeblockedentity' .. k, val)
		end)
		menu:Open()
	end
	
	local entry = vgui.Create('DTextEntry', Panel)
	Panel:AddItem(entry)
	local Apply = Panel:Button('Add tool mode')
	Apply.DoClick = function()
		RunConsoleCommand('dpp_addblockedentity' .. k, entry:GetText())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	local Apply = Panel:Button('Remove tool mode')
	Apply.DoClick = function()
		RunConsoleCommand('dpp_removeblockedentity' .. k, entry:GetText())
	end
	SettingsClass.ApplyButtonStyle(Apply)
	
	ConVarCheckbox(Panel, 'blacklist_' .. k)
	ConVarCheckbox(Panel, 'blacklist_' .. k .. '_white')
	ConVarCheckbox(Panel, 'blacklist_' .. k .. '_player_can')
	ConVarCheckbox(Panel, 'blacklist_' .. k .. '_admin_can')
end

for k, v in pairs(DPP.BlockTypes) do
	if CustomBlockMenus[k] then
		PanelsFunctions[k] = CustomBlockMenus[k]
		continue
	end
	
	PanelsFunctions[k] = function(Panel)
		if not IsValid(Panel) then return end
		Panel:Clear()
		SettingsClass.SetupBackColor(Panel)
		ValidPanels[k] = Panel
		
		local list = vgui.Create('DListView', Panel)
		Panel:AddItem(list)
		
		list:SetHeight(600)
		list:AddColumn('Entity')
		
		local L = DPP.BlockedEntities[k]
		local New = {}
		for k, v in pairs(L) do
			table.insert(New, k)
		end
		
		table.sort(New, SORTER)
		
		for k, v in pairs(New) do
			list:AddLine(v)
		end
		
		list.OnRowRightClick = function(self, line)
			local val = self:GetLine(line):GetValue(1)
			local menu = vgui.Create('DMenu')
			menu:AddOption('Copy class to clipboard', function()
				SetClipboardText(val)
			end)
			
			menu:AddOption('Remove from blacklist', function()
				RunConsoleCommand('dpp_removeblockedentity' .. k, val)
			end)
			
			menu:AddOption('Add that entity to ALL blacklists', function()
				ADD_ALL(val)
			end)
			
			menu:AddOption('Remove that entity to ALL blacklists', function()
				REMOVE_ALL(val)
			end)
			menu:Open()
		end
		
		local entry = vgui.Create('DTextEntry', Panel)
		Panel:AddItem(entry)
		local Apply = Panel:Button('Add entity')
		Apply.DoClick = function()
			RunConsoleCommand('dpp_addblockedentity' .. k, entry:GetText())
		end
		SettingsClass.ApplyButtonStyle(Apply)
		
		local Apply = Panel:Button('Remove entity')
		Apply.DoClick = function()
			RunConsoleCommand('dpp_removeblockedentity' .. k, entry:GetText())
		end
		SettingsClass.ApplyButtonStyle(Apply)
		
		local Apply = Panel:Button('Add this entity to ALL blacklists')
		Apply.DoClick = function()
			ADD_ALL(entry:GetText())
		end
		SettingsClass.ApplyButtonStyle(Apply)
		
		local Apply = Panel:Button('Remove this entity from ALL blacklists')
		Apply.DoClick = function()
			REMOVE_ALL(entry:GetText())
		end
		SettingsClass.ApplyButtonStyle(Apply)
		
		local Apply = Panel:Button('Add the entity you\'re looking at to the blacklist')
		Apply.DoClick = function()
			local ent = LocalPlayer():GetEyeTrace().Entity
			if not IsValid(ent) then return end
			RunConsoleCommand('dpp_addblockedentity' .. k, ent:GetClass())
		end
		SettingsClass.ApplyButtonStyle(Apply)
		
		local Apply = Panel:Button('Remove the entity you\'re looking at to the blacklist')
		Apply.DoClick = function()
			local ent = LocalPlayer():GetEyeTrace().Entity
			if not IsValid(ent) then return end
			RunConsoleCommand('dpp_removeblockedentity' .. k, ent:GetClass())
		end
		SettingsClass.ApplyButtonStyle(Apply)
		
		local Apply = Panel:Button('Add the entity you\'re looking at to ALL blacklists')
		Apply.DoClick = function()
			local ent = LocalPlayer():GetEyeTrace().Entity
			if not IsValid(ent) then return end
			ADD_ALL(ent:GetClass())
		end
		SettingsClass.ApplyButtonStyle(Apply)
		
		local Apply = Panel:Button('Remove the entity you\'re looking at to ALL blacklists')
		Apply.DoClick = function()
			local ent = LocalPlayer():GetEyeTrace().Entity
			if not IsValid(ent) then return end
			REMOVE_ALL(ent:GetClass())
		end
		SettingsClass.ApplyButtonStyle(Apply)
		
		ConVarCheckbox(Panel, 'blacklist_' .. k)
		ConVarCheckbox(Panel, 'blacklist_' .. k .. '_white')
		ConVarCheckbox(Panel, 'blacklist_' .. k .. '_player_can')
		ConVarCheckbox(Panel, 'blacklist_' .. k .. '_admin_can')
	end
end

local function SORTER(a, b)
	local a = a.class
	local b = b.class
	return a < b
end

for k, v in pairs(DPP.RestrictTypes) do
	local function OpenModifyPanel(class, isNew)
		local t = DPP.RestrictedTypes[k][class] or {
			groups = {},
			iswhite = false
		}
		
		local height = 50
		
		local frame = vgui.Create('DFrame')
		frame:SetTitle('Modifying ' .. class)
		SettingsClass.ApplyFrameStyle(frame)
		
		local groups = DPP.GetGroups()
		local Panels = {}
		
		for k, v in pairs(groups) do
			height = height + 20
			local p = frame:Add('DCheckBoxLabel')
			table.insert(Panels, p)
			p:Dock(TOP)
			p:SetText(v)
			p:SetChecked(table.HasValue(t.groups, v))
			p.Group = v
		end
		
		height = height + 30
		local iswhite = frame:Add('DCheckBoxLabel')
		iswhite:Dock(TOP)
		iswhite:SetText('Is White List')
		iswhite:SetChecked(t.iswhite)
		
		local apply = frame:Add('DButton')
		apply:Dock(BOTTOM)
		apply:SetText('Apply')
		SettingsClass.ApplyButtonStyle(apply)
		
		function apply.DoClick()
			t.groups = {}
			for k, v in pairs(Panels) do
				if v:GetChecked() then
					table.insert(t.groups, v.Group)
				end
			end
			t.iswhite = iswhite:GetChecked()
			
			RunConsoleCommand('dpp_restrict' .. k, class, table.concat(t.groups, ','), t.iswhite and '1' or '0')
			frame:Close()
		end
		
		local discard = frame:Add('DButton')
		discard:Dock(BOTTOM)
		discard:SetText('Discard')
		SettingsClass.ApplyButtonStyle(discard)
		
		function discard.DoClick()
			frame:Close()
		end
		
		frame:SetHeight(height)
		frame:SetWidth(200)
		frame:Center()
		frame:MakePopup()
	end
	
	PanelsFunctions2[k] = function(Panel)
		if not IsValid(Panel) then return end
		Panel:Clear()
		SettingsClass.SetupBackColor(Panel)
		
		ValidPanels2[k] = Panel
		
		local list = vgui.Create('DListView', Panel)
		Panel:AddItem(list)
		
		list:SetHeight(600)
		list:AddColumn('Class')
		list:AddColumn('Groups')
		list:AddColumn('Is Whitelist')
		
		local L = DPP.RestrictedTypes[k]
		local New = {}
		for k, v in pairs(L) do
			table.insert(New, {class = k, groups = v.groups, iswhite = v.iswhite})
		end
		
		table.sort(New, SORTER)
		
		for k, v in pairs(New) do
			list:AddLine(v.class, table.concat(v.groups, ','), v.iswhite)
		end
		
		list.OnRowRightClick = function(self, line)
			local class = self:GetLine(line):GetValue(1)
			local groups = self:GetLine(line):GetValue(2)
			local iswhite = self:GetLine(line):GetValue(3)
			
			local menu = vgui.Create('DMenu')
			menu:AddOption('Copy class to clipboard', function()
				SetClipboardText(class)
			end)
			
			menu:AddOption('Remove from list', function()
				RunConsoleCommand('dpp_unrestrict' .. k, class)
			end)
			
			menu:AddOption('Modify...', function()
				OpenModifyPanel(class)
			end)
			
			menu:Open()
		end
		
		local entry = vgui.Create('DTextEntry', Panel)
		Panel:AddItem(entry)
		
		local Apply = Panel:Button('Add...')
		Apply.DoClick = function()
			OpenModifyPanel(entry:GetText(), true)
		end
		SettingsClass.ApplyButtonStyle(Apply)
		
		ConVarCheckbox(Panel, 'restrict_' .. k)
		ConVarCheckbox(Panel, 'restrict_' .. k .. '_white')
		ConVarCheckbox(Panel, 'restrict_' .. k .. '_white_bypass')
	end
end

local function BuildFriendsPanel(Panel)
	if not IsValid(Panel) then return end
	Panel:Clear()
	SettingsClass.SetupBackColor(Panel)
	
	DPP.SettingsClass.FriendPanel = Panel
	
	local list = vgui.Create('DListView', Panel)
	Panel:AddItem(list)
	
	list:SetHeight(300)
	list:AddColumn('Nick')
	list:AddColumn('SteamID')
	
	for k, v in pairs(DPP.GetLocalFriends()) do
		list:AddLine(v.nick, k)
	end
	
	list.OnRowRightClick = function(self, line)
		local name = self:GetLine(line):GetValue(1)
		local steamid = self:GetLine(line):GetValue(2)
		local menu = vgui.Create('DMenu')
		
		menu:AddOption('Copy Name to clipboard', function()
			SetClipboardText(name)
		end)
		
		menu:AddOption('Copy SteamID to clipboard', function()
			SetClipboardText(steamid)
		end)
		
		menu:AddOption('Edit...', function()
			DPP.OpenFriendEditMenu(steamid)
		end)
		
		menu:AddOption('Remove from friends', function()
			DPP.RemoveFriendBySteamID(steamid)
		end)
		
		menu:Open()
	end
	
	local plys = player.GetAll()
	local active = DPP.GetActiveFriends()
	
	for k, v in pairs(plys) do
		if v == LocalPlayer() then continue end
		if active[v] then continue end
		local b = Panel:Button('Add ' .. v:Nick() .. ' to friends list')
		SettingsClass.ApplyButtonStyle(b)
		b.DoClick = function()
			DPP.OpenFriendEditMenu(v:SteamID())
		end
	end
	
	local entry = vgui.Create('DTextEntry', Panel)
	Panel:AddItem(entry)
	local Apply = Panel:Button('Add by SteamID')
	Apply.DoClick = function()
		DPP.OpenFriendEditMenu(entry:GetText())
	end
	SettingsClass.ApplyButtonStyle(Apply)
end

local function PopulateToolMenu()
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.SVars', 'Server Variables', '', '', BuildSVarPanel)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.Players', 'Player Controls', '', '', BuildPlayerList)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.Misc', 'Secondary Server Variables', '', '', BuildMiscVarsPanel)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.APropKill', 'Anti-PropKill', '', '', BuildAPropKillVarsPanel)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.CVars', 'Client Variables', '', '', BuildCVarPanel)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.APanel', 'Antispam Settings', '', '', BuildAntispamPanel)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.Limits', 'Entity Limits', '', '', BuildLimitsList)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.SLimits', 'Sandbox Limits', '', '', BuildSLimitsList)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.CLimits', 'Constraints Limits', '', '', BuildCLimitsList)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP Blacklists', 'DPP.ModelList', 'Model blacklist', '', '', BuildModelsList)
	spawnmenu.AddToolMenuOption('Utilities', 'DPP', 'DPP.Friends', 'Friends', '', '', BuildFriendsPanel)
	
	for k, v in pairs(DPP.BlockTypes) do
		spawnmenu.AddToolMenuOption('Utilities', 'DPP Blacklists', 'DPP.' .. k, v .. ' blacklist', '', '', PanelsFunctions[k])
	end

	for k, v in pairs(DPP.RestrictTypes) do
		spawnmenu.AddToolMenuOption('Utilities', 'DPP Restrictions', 'DPP.restrict' .. k, v .. ' Restrictions', '', '', PanelsFunctions2[k])
	end
end

hook.Add('DPP.BlockedEntitiesChanged', 'DPP.Menu', function(s1, s2, b)
	if PanelsFunctions[s1] then
		PanelsFunctions[s1](DPP.SettingsClass.ValidPanels[s1])
	end
end)

hook.Add('DPP.EntsLimitsUpdated', 'DPP.Menu', function()
	BuildLimitsList(DPP.SettingsClass.LimitsPanel)
end)

hook.Add('DPP.EntsLimitsReloaded', 'DPP.Menu', function()
	BuildLimitsList(DPP.SettingsClass.LimitsPanel)
end)

hook.Add('DPP.SBoxLimitsUpdated', 'DPP.Menu', function()
	BuildSLimitsList(DPP.SettingsClass.SLimitsPanel)
end)

hook.Add('DPP.ConstrainsLimitsUpdated', 'DPP.Menu', function()
	BuildCLimitsList(DPP.SettingsClass.CLimitsPanel)
end)

hook.Add('DPP.ConstrainsLimitsReloaded', 'DPP.Menu', function()
	BuildCLimitsList(DPP.SettingsClass.CLimitsPanel)
end)

hook.Add('DPP.SBoxLimitsReloaded', 'DPP.Menu', function()
	BuildSLimitsList(DPP.SettingsClass.SLimitsPanel)
end)

hook.Add('DPP.ConstLimitsReloaded', 'DPP.Menu', function()
	BuildSLimitsList(DPP.SettingsClass.SLimitsPanel)
end)

hook.Add('DPP.FriendsChanged', 'DPP.Menu', function()
	BuildFriendsPanel(DPP.SettingsClass.FriendPanel)
end)

hook.Add('DPP.BlockedEntitiesReloaded', 'DPP.Menu', function(s1)
	if PanelsFunctions[s1] then
		PanelsFunctions[s1](DPP.SettingsClass.ValidPanels[s1])
	end
end)

hook.Add('DPP.RestrictedTypesUpdated', 'DPP.Menu', function(s1)
	if PanelsFunctions2[s1] then
		PanelsFunctions2[s1](DPP.SettingsClass.ValidPanels2[s1])
	end
end)

hook.Add('DPP.RestrictedTypesReloaded', 'DPP.Menu', function(s1)
	if PanelsFunctions2[s1] then
		PanelsFunctions2[s1](DPP.SettingsClass.ValidPanels2[s1])
	end
end)

hook.Add('DPP.BlockedModelListChanged', 'DPP.Menu', function(s1)
	BuildModelsList(DPP.SettingsClass.ModelPanel)
end)

hook.Add('DPP.BlockedModelListReloaded', 'DPP.Menu', function(s1)
	BuildModelsList(DPP.SettingsClass.ModelPanel)
end)

hook.Add('PopulateToolMenu', 'DPP.Menu', PopulateToolMenu)

net.Receive('DPP.RefreshPlayerList', function()
	BuildFriendsPanel(DPP.SettingsClass.FriendPanel)
	BuildPlayerList(DPP.SettingsClass.PlayerPanel)
end)

hook.Add('DPP.PlayerListChanged', 'DPP.Menu', function()
	BuildPlayerList(DPP.SettingsClass.PlayerPanel)
end)

local AddToBlocked = {
	MenuLabel = "Add to DPP Blocked Models",
	Order = 2500,
	MenuIcon = "icon16/cross.png",

	Filter = function(self, ent, ply)
		if not IsValid(ent) then return false end
		if not ply:IsSuperAdmin() then return false end
		if DPP.IsModelEvenBlocked(ent:GetModel()) then return false end
		return true
	end,
	
	Action = function(self, ent)
		RunConsoleCommand('dpp_addblockedmodel', ent:GetModel())
	end,
}

local RemoveFromlocked = {
	MenuLabel = "Remove from DPP Blocked Models",
	Order = 2501,
	MenuIcon = "icon16/accept.png",

	Filter = function(self, ent, ply)
		if not IsValid(ent) then return false end
		if not ply:IsSuperAdmin() then return false end
		if not DPP.IsModelEvenBlocked(ent:GetModel()) then return false end
		return true
	end,
	
	Action = function(self, ent)
		RunConsoleCommand('dpp_removeblockedmodel', ent:GetModel())
	end,
}

properties.Add("dpp.addblockedmodel", AddToBlocked)
properties.Add("dpp.delblockedmodel", RemoveFromlocked)

local CleanupPlayer = {
	MenuLabel = "Cleanup props of owner",
	Order = 2400,
	MenuIcon = "icon16/brick_delete.png",

	Filter = function(self, ent, ply)
		if not IsValid(ent) then return false end
		if not ply:IsAdmin() then return false end
		if not DPP.IsOwned(ent) then return false end
		return true
	end,
	
	Action = function(self, ent)
		local Name, UID = DPP.GetOwnerDetails(ent)
		RunConsoleCommand('dpp_clearbyuid', UID)
	end,
}
properties.Add("dpp.clearbyuid", CleanupPlayer)

local ShareMenu = {
	MenuLabel = "Share this prop",
	Order = 2400,
	MenuIcon = "icon16/brick_edit.png",

	Filter = function(self, ent, ply)
		if not IsValid(ent) then return false end
		return DPP.GetOwner(ent) == ply
	end,
	
	Action = function(self, ent)
		DPP.OpenShareMenu(ent)
	end,
}

properties.Add("dpp.share", ShareMenu)

local transfertoworld = {
	MenuLabel = "Transfer ownership to world",
	Order = 2700,
	MenuIcon = "icon16/world.png",

	Filter = function(self, ent, ply)
		return IsValid(ent) and ply:IsAdmin() and DPP.IsOwned(ent)
	end,
	
	Action = function(self, ent)
		RunConsoleCommand('dpp_transfertoworld', ent:EntIndex())
	end,
}

properties.Add("dpp.transfertoworld", transfertoworld)

for k, v in pairs(DPP.BlockTypes) do
	local Add = {
		MenuLabel = "Add to DPP " .. v .. ' blacklist',
		Order = 2503,
		MenuIcon = 'icon16/cross.png',

		Filter = function(self, ent, ply)
			if not IsValid(ent) then return false end
			if not ply:IsSuperAdmin() then return false end
			if DPP['IsEvenBlocked' .. v](ent:GetClass(), ply) then return false end
			return true
		end,
		
		Action = function(self, ent)
			RunConsoleCommand('dpp_addblockedentity' .. k, ent:GetClass())
		end,
	}
	
	local Remove = {
		MenuLabel = "Remove from DPP " .. v .. ' blacklist',
		Order = 2503,
		MenuIcon = 'icon16/accept.png',

		Filter = function(self, ent, ply)
			if not IsValid(ent) then return false end
			if not ply:IsSuperAdmin() then return false end
			if not DPP['IsEvenBlocked' .. v](ent:GetClass(), ply) then return false end
			return true
		end,
		
		Action = function(self, ent)
			RunConsoleCommand('dpp_removeblockedentity' .. k, ent:GetClass())
		end,
	}

	properties.Add("dpp.addblocked" .. k, Add)
	properties.Add("dpp.removeblocked" .. k, Remove)
end

for k, v in pairs(DPP.RestrictTypes) do
	local function OpenModifyPanel(class, isNew)
		local t = DPP.RestrictedTypes[k][class] or {
			groups = {},
			iswhite = false
		}
		
		local height = 50
		
		local frame = vgui.Create('DFrame')
		frame:SetTitle('Modifying' .. class)
		SettingsClass.ApplyFrameStyle(frame)
		
		local groups = DPP.GetGroups()
		local Panels = {}
		
		for k, v in pairs(groups) do
			height = height + 20
			local p = frame:Add('DCheckBoxLabel')
			table.insert(Panels, p)
			p:Dock(TOP)
			p:SetText(v)
			p:SetChecked(table.HasValue(t.groups, v))
			p.Group = v
		end
		
		height = height + 30
		local iswhite = frame:Add('DCheckBoxLabel')
		iswhite:Dock(TOP)
		iswhite:SetText('Is White List')
		iswhite:SetChecked(t.iswhite)
		
		local apply = frame:Add('DButton')
		apply:Dock(BOTTOM)
		apply:SetText('Apply')
		SettingsClass.ApplyButtonStyle(apply)
		
		function apply.DoClick()
			t.groups = {}
			for k, v in pairs(Panels) do
				if v:GetChecked() then
					table.insert(t.groups, v.Group)
				end
			end
			t.iswhite = iswhite:GetChecked()
			
			RunConsoleCommand('dpp_restrict' .. k, class, table.concat(t.groups, ','), t.iswhite and '1' or '0')
			frame:Close()
		end
		
		local discard = frame:Add('DButton')
		discard:Dock(BOTTOM)
		discard:SetText('Discard')
		SettingsClass.ApplyButtonStyle(discard)
		
		function discard.DoClick()
			frame:Close()
		end
		
		frame:SetHeight(height)
		frame:SetWidth(200)
		frame:Center()
		frame:MakePopup()
	end
	
	local Add = {
		MenuLabel = "Add to DPP " .. v .. ' restrict black/white list',
		Order = 2520,
		MenuIcon = 'icon16/cross.png',

		Filter = function(self, ent, ply)
			if not IsValid(ent) then return false end
			if not ply:IsSuperAdmin() then return false end
			local type = DPP.GetEntityType(ent)
			if type ~= k then return false end
			if DPP['IsEvenRestricted' .. v](ent:GetClass()) then return false end
			return true
		end,
		
		Action = function(self, ent)
			OpenModifyPanel(ent:GetClass(), true)
		end,
	}
	
	local Remove = {
		MenuLabel = "Remove from DPP " .. v .. ' restrict black/white list',
		Order = 2520,
		MenuIcon = 'icon16/accept.png',

		Filter = function(self, ent, ply)
			if not IsValid(ent) then return false end
			if not ply:IsSuperAdmin() then return false end
			local type = DPP.GetEntityType(ent)
			if type ~= k then return false end
			if not DPP['IsEvenRestricted' .. v](ent:GetClass()) then return false end
			return true
		end,
		
		Action = function(self, ent)
			RunConsoleCommand('dpp_unrestrict' .. k, ent:GetClass())
		end,
	}

	local Modify = {
		MenuLabel = "Modify DPP " .. v .. ' restriction...',
		Order = 2520,
		MenuIcon = 'icon16/pencil.png',

		Filter = function(self, ent, ply)
			if not IsValid(ent) then return false end
			if not ply:IsSuperAdmin() then return false end
			local type = DPP.GetEntityType(ent)
			if type ~= k then return false end
			if not DPP['IsEvenRestricted' .. v](ent:GetClass()) then return false end
			return true
		end,
		
		Action = function(self, ent)
			OpenModifyPanel(ent:GetClass(), false)
		end,
	}

	properties.Add("dpp.addrestricted" .. k, Add)
	properties.Add("dpp.removerestricted" .. k, Remove)
	properties.Add("dpp.modifyrestricted" .. k, Modify)
end

--Copy paste
do
	local k = 'model'
	local v = 'Model'
	
	local function OpenModifyPanel(class, isNew)
		local t = DPP.RestrictedTypes[k][class] or {
			groups = {},
			iswhite = false
		}
		
		local height = 50
		
		local frame = vgui.Create('DFrame')
		frame:SetTitle('Modifying ' .. class)
		SettingsClass.ApplyFrameStyle(frame)
		
		local groups = DPP.GetGroups()
		local Panels = {}
		
		for k, v in pairs(groups) do
			height = height + 20
			local p = frame:Add('DCheckBoxLabel')
			table.insert(Panels, p)
			p:Dock(TOP)
			p:SetText(v)
			p:SetChecked(table.HasValue(t.groups, v))
			p.Group = v
		end
		
		height = height + 30
		local iswhite = frame:Add('DCheckBoxLabel')
		iswhite:Dock(TOP)
		iswhite:SetText('Is White List')
		iswhite:SetChecked(t.iswhite)
		
		local apply = frame:Add('DButton')
		apply:Dock(BOTTOM)
		apply:SetText('Apply')
		SettingsClass.ApplyButtonStyle(apply)
		
		function apply.DoClick()
			t.groups = {}
			for k, v in pairs(Panels) do
				if v:GetChecked() then
					table.insert(t.groups, v.Group)
				end
			end
			t.iswhite = iswhite:GetChecked()
			
			RunConsoleCommand('dpp_restrict' .. k, class, table.concat(t.groups, ','), t.iswhite and '1' or '0')
			frame:Close()
		end
		
		local discard = frame:Add('DButton')
		discard:Dock(BOTTOM)
		discard:SetText('Discard')
		SettingsClass.ApplyButtonStyle(discard)
		
		function discard.DoClick()
			frame:Close()
		end
		
		frame:SetHeight(height)
		frame:SetWidth(400)
		frame:Center()
		frame:MakePopup()
	end
	
	local Add = {
		MenuLabel = "Add to DPP " .. v .. ' restrict black/white list',
		Order = 2520,
		MenuIcon = 'icon16/cross.png',

		Filter = function(self, ent, ply)
			if not IsValid(ent) then return false end
			if not ply:IsSuperAdmin() then return false end
			if DPP['IsEvenRestricted' .. v](ent:GetModel()) then return false end
			return true
		end,
		
		Action = function(self, ent)
			OpenModifyPanel(ent:GetModel(), true)
		end,
	}
	
	local Remove = {
		MenuLabel = "Remove from DPP " .. v .. ' restrict black/white list',
		Order = 2520,
		MenuIcon = 'icon16/accept.png',

		Filter = function(self, ent, ply)
			if not IsValid(ent) then return false end
			if not ply:IsSuperAdmin() then return false end
			if not DPP['IsEvenRestricted' .. v](ent:GetModel()) then return false end
			return true
		end,
		
		Action = function(self, ent)
			RunConsoleCommand('dpp_unrestrict' .. k, ent:GetModel())
		end,
	}

	local Modify = {
		MenuLabel = "Modify DPP " .. v .. ' restriction...',
		Order = 2520,
		MenuIcon = 'icon16/pencil.png',

		Filter = function(self, ent, ply)
			if not IsValid(ent) then return false end
			if not ply:IsSuperAdmin() then return false end
			if not DPP['IsEvenRestricted' .. v](ent:GetModel()) then return false end
			return true
		end,
		
		Action = function(self, ent)
			OpenModifyPanel(ent:GetModel(), false)
		end,
	}

	properties.Add("dpp.addrestricted" .. k, Add)
	properties.Add("dpp.removerestricted" .. k, Remove)
	properties.Add("dpp.modifyrestricted" .. k, Modify)
end

DPP.OldContentTypes = DPP.OldContentTypes or {}

--[[ --Can break spawnmenu
local function OpenMenu(self)
	if LocalPlayer():IsSuperAdmin() then
		local name, obj = debug.getupvalue(self.openFunc, 1)
		
		local menu = DermaMenu()
		
		menu:AddOption( "Copy to Clipboard", function() SetClipboardText( obj.spawnname ) end )
		menu:AddOption( "Spawn Using Toolgun", function() RunConsoleCommand( "gmod_tool", "creator" ) RunConsoleCommand( "creator_type", "0" ) RunConsoleCommand( "creator_name", obj.spawnname ) end )
		menu:AddSpacer()
		
		for k, v in pairs(DPP.BlockTypes) do
			menu:AddOption('Add to ' .. v .. ' blocked list', function()
				RunConsoleCommand('dpp_addblockedentity' .. k, obj.spawnname)
			end)
		end
		
		menu:AddSpacer()
		menu:AddOption( "Delete", function() icon:Remove() hook.Run( "SpawnlistContentChanged", icon ) end )
		
		menu:Open()
	else
		self.openFunc(self)
	end
end

--That's bad
local function OverrideSpawnMenuIcons()
	if not spawnmenu then return end --Not sandbox
	DPP.OldContentTypes.entity = DPP.OldContentTypes.entity or spawnmenu.GetContentType('entity')
	
	spawnmenu.AddContentType('entity', function(container, obj)
		local icon = DPP.OldContentTypes.entity(container, obj)
		local openFunc = icon.OpenMenu
		icon.openFunc = openFunc
		icon.OpenMenu = OpenMenu
		
		return icon
	end)
end

timer.Simple(0, OverrideSpawnMenuIcons)
]]

--[[ -- Fucking slow
local CachedMaterials = {}

local function Exists(class)
	return file.Exists("materials/entities/" .. class .. ".png", 'GAME')
end

local function OpenRestrictionMenu()
	local frame = vgui.Create('DFrame')
	SettingsClass.ApplyFrameStyle(frame)
	frame:SetSize(ScrW() - 200, ScrH() - 200)
	frame:SetPos(100, 100)
	frame:MakePopup()
	frame:SetTitle('DPP Restriction Menu')
	
	local w = ScrW() - 200
	
	local sheet = frame:Add('DPropertySheet')
	sheet:Dock(FILL)
	
	local NPCs = list.Get('NPC')
	local NPCsPanel = sheet:Add('DScrollPanel')
	sheet:AddSheet('NPCs', NPCsPanel)
	NPCsPanel:Dock(FILL)
	NPCsPanel:SetBackgroundColor(Color(0, 0, 0, 0))
	
	local SortedNPC = {}
	
	for k, v in pairs(NPCs) do
		SortedNPC[v.Category] = SortedNPC[v.Category] or {}
		SortedNPC[v.Category][k] = v
	end
	
	local CurrentLine = 0
	local CurrentColumn = 0
	local IWidth, IHeight = 128, 128
	
	local PanelsCateg = {}
	local i = 0
	
	for category, data in pairs(SortedNPC) do
		PanelsCateg[category] = NPCsPanel:Add('DCollapsibleCategory')
		PanelsCateg[category]:SetLabel(category)
		CurrentColumn = 0
		CurrentLine = 0
		
		for class, v in pairs(data) do
			local iW, iH = CurrentColumn * IWidth, CurrentLine * IHeight
			if ((CurrentColumn + 1) * IWidth) > w then
				CurrentLine = CurrentLine + 1
				CurrentColumn = 0
				iW, iH = CurrentColumn * IWidth, CurrentLine * IHeight
			end
			
			i = i + 1
			
			local icon = NPCsPanel:Add('ContentIcon')
			icon:SetContentType("vehicle")
			icon:SetSpawnName(v.Class)
			icon:SetName(v.Name)
			icon:SetPos(iW, iH)
			icon.SetIconAt = CurTime() + i * 0.05
			icon.Think = function(self)
				if self.SetIconAt < CurTime() and not self.IconSettedUp then
					self:SetMaterial("materials/entities/" .. v.Class .. ".png")
					self.IconSettedUp = true
				end
			end
			
			icon:SetColor(color_black)
			
			CurrentColumn = CurrentColumn + 1
		end
	end
end

OpenRestrictionMenu()
]]
