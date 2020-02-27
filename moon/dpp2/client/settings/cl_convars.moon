
-- Copyright (C) 2018-2019 DBotThePony

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

import DPP2 from _G
import Menus from DPP2

Menus.SecondaryMenu = =>
	return if not IsValid(@)

	Menus.QCheckBox(@, 'no_tool_player')
	Menus.QCheckBox(@, 'no_tool_player_admin')

Menus.AntispamMenu = =>
	return if not IsValid(@)

	Menus.QCheckBox(@, 'antispam')
	Menus.QCheckBox(@, 'antispam_collisions')
	Menus.QCheckBox(@, 'antispam_spam')
	Menus.QSlider(@, 'antispam_spam_threshold', 0.1, 50, 2)
	Menus.QSlider(@, 'antispam_spam_threshold2', 0.1, 50, 2)
	Menus.QCheckBox(@, 'antispam_spam_cooldown')
	Menus.QSlider(@, 'antispam_vol_aabb_div', 1, 10000)
	Menus.QCheckBox(@, 'antispam_spam_vol')
	Menus.QCheckBox(@, 'antispam_spam_vol_aabb')
	Menus.QSlider(@, 'antispam_spam_vol_threshold', 1, 1000000000)
	Menus.QSlider(@, 'antispam_spam_vol_threshold2', 1, 1000000000)
	Menus.QSlider(@, 'antispam_spam_vol_cooldown', 1, 1000000000)
	Menus.QCheckBox(@, 'antispam_ghost_by_size')
	Menus.QSlider(@, 'antispam_ghost_size', 1, 1000000)
	Menus.QCheckBox(@, 'antispam_ghost_aabb')
	Menus.QSlider(@, 'antispam_ghost_aabb_size', 1, 10000000)

Menus.AntipropkillMenu = =>
	return if not IsValid(@)

	Menus.QCheckBox(@, 'apropkill')
	Menus.QCheckBox(@, 'apropkill_damage')
	Menus.QCheckBox(@, 'apropkill_damage_nworld')
	Menus.QCheckBox(@, 'apropkill_damage_nveh')
	Menus.QCheckBox(@, 'apropkill_trap')
	Menus.QCheckBox(@, 'apropkill_push')
	Menus.QCheckBox(@, 'apropkill_throw')
	Menus.QCheckBox(@, 'apropkill_punt')

Menus.PrimaryMenu = =>
	return if not IsValid(@)

	Menus.QCheckBox(@, 'protection')

	for name in *{'physgun', 'gravgun', 'toolgun', 'use', 'pickup', 'damage', 'vehicle', 'drive'}
		Menus.QCheckBox(@, name .. '_protection')
		Menus.QCheckBox(@, name .. '_touch_any')
		Menus.QCheckBox(@, name .. '_no_world')
		Menus.QCheckBox(@, name .. '_no_world_admin')
		Menus.QCheckBox(@, name .. '_no_map')
		Menus.QCheckBox(@, name .. '_no_map_admin')

Menus.ClientProtectionModulesMenu = =>
	return if not IsValid(@)

	@CheckBox('gui.dpp2.cvars.cl_protection', 'dpp2_cl_protection')

	for name in *{'physgun', 'gravgun', 'toolgun', 'use', 'pickup', 'damage', 'vehicle', 'drive'}
		@CheckBox('gui.dpp2.cvars.' .. 'cl_' .. name .. '_protection', 'dpp2_cl_' .. name .. '_protection')
		@CheckBox('gui.dpp2.cvars.' .. 'cl_' .. name .. '_no_other', 'dpp2_cl_' .. name .. '_no_other')
		@CheckBox('gui.dpp2.cvars.' .. 'cl_' .. name .. '_no_players', 'dpp2_cl_' .. name .. '_no_players')
		@CheckBox('gui.dpp2.cvars.' .. 'cl_' .. name .. '_no_world', 'dpp2_cl_' .. name .. '_no_world')
		@CheckBox('gui.dpp2.cvars.' .. 'cl_' .. name .. '_no_map', 'dpp2_cl_' .. name .. '_no_map')
