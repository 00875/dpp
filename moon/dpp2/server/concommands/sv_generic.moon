
-- Copyright (C) 2018-2020 DBotThePony

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

import DPP2, DLib from _G
import net from DLib

net.pool('dpp2_cleardecals')
net.pool('dpp2_cleargibs')
net.pool('dpp2_inspect')

cmds = {
	cleanup: (args = {}, message) =>
		str = table.concat(args, ' ')

		switch str\lower()
			when 'disconnected'
				return DPP2.cmd_remap.cleanupdisconnected(@)
			when 'npc'
				return DPP2.cmd_remap.cleanupallnpcs(@)
			when 'vehicles'
				return DPP2.cmd_remap.cleanupallvehicles(@)

		plyID = DPP2.FindPlayerUserIDInCommand(str, true)
		return 'command.dpp2.generic.notarget' if not plyID

		findProps = DPP2.GetAllEntsByPID(plyID)
		return 'command.dpp2.generic.notarget' if #findProps == 0

		ply = Player(plyID)
		findInfo = DPP2.GetAllKnownPlayersInfo(plyID) if not IsValid(ply)

		for ent in *findProps
			if not ent\IsWeapon() or not IsValid(ent\GetOwner())
				SafeRemoveEntity(ent)

		if findInfo
			DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanup_plain', @, findInfo.name, findInfo.steamid, findInfo.pid)
		else
			DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanup', @, ply)

	cleanupnpcs: (args = {}, message) =>
		str = table.concat(args, ' ')

		plyID = DPP2.FindPlayerUserIDInCommand(str, true)
		return 'command.dpp2.generic.notarget' if not plyID

		findProps = DPP2.GetAllEntsByPID(plyID)
		return 'command.dpp2.generic.notarget' if #findProps == 0

		ply = Player(plyID)
		findInfo = DPP2.GetAllKnownPlayersInfo(plyID) if not IsValid(ply)

		SafeRemoveEntity(ent) for ent in *findProps when ent\IsNPC() or type(ent) == 'NextBot'

		if findInfo
			DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanupnpcs_plain', @, findInfo.name, findInfo.steamid, findInfo.pid)
		else
			DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanupnpcs', @, ply)

	cleanupvehicles: (args = {}, message) =>
		str = table.concat(args, ' ')

		plyID = DPP2.FindPlayerUserIDInCommand(str, true)
		return 'command.dpp2.generic.notarget' if not plyID

		findProps = DPP2.GetAllEntsByPID(plyID)
		return 'command.dpp2.generic.notarget' if #findProps == 0

		ply = Player(plyID)
		findInfo = DPP2.GetAllKnownPlayersInfo(plyID) if not IsValid(ply)

		SafeRemoveEntity(ent) for ent in *findProps when ent\IsVehicle()

		if findInfo
			DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanupvehicles_plain', @, findInfo.name, findInfo.steamid, findInfo.pid)
		else
			DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanupvehicles', @, ply)

	cleanupallnpcs: (args = {}, message) =>
		SafeRemoveEntity(ent) for ent in *DPP2.FindOwned() when ent\IsNPC() or type(ent) == 'NextBot'
		DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanupallnpcs', @)

	cleanupall: (args = {}, message) =>
		for ent in *DPP2.FindOwned()
			if not ent\IsWeapon() or not IsValid(ent\GetOwner())
				SafeRemoveEntity(ent)

		DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanupall', @)

	cleanupallvehicles: (args = {}, message) =>
		SafeRemoveEntity(ent) for ent in *DPP2.FindOwned() when ent\IsVehicle()
		DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanupallvehicles', @)

	cleanupdisconnected: (args = {}) =>
		SafeRemoveEntity(ent) for ent in *DPP2.FindOwned() when not ent\DPP2OwnerIsValid()
		DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanupdisconnected', @)

	freezephys: (args = {}, message) =>
		str = table.concat(args, ' ')

		plyID = DPP2.FindPlayerUserIDInCommand(str, true)
		return 'command.dpp2.generic.notarget' if not plyID

		findProps = DPP2.GetAllEntsByPID(plyID)
		return 'command.dpp2.generic.notarget' if #findProps == 0

		ply = Player(plyID)
		findInfo = DPP2.GetAllKnownPlayersInfo(plyID) if not IsValid(ply)

		for ent in *findProps
			if phys = ent\DPP2GetPhys()
				if type(phys) == 'table'
					phys2\EnableMotion(false) for phys2 in *phys
				else
					phys\EnableMotion(false)

		DPP2.Notify(true, nil, 'command.dpp2.freezephys', @, ply)

	freezephysall: (args = {}, message) =>
		for ent in *DPP2.FindOwned()
			if phys = ent\DPP2GetPhys()
				if type(phys) == 'table'
					phys2\EnableMotion(false) for phys2 in *phys
				else
					phys\EnableMotion(false)

		DPP2.Notify(true, nil, 'command.dpp2.freezephysall', @)

	freezephyspanic: (args = {}, message) =>
		for ent in *ents.GetAll()
			if phys = ent\DPP2GetPhys()
				if type(phys) == 'table'
					phys2\EnableMotion(false) for phys2 in *phys
				else
					phys\EnableMotion(false)

		DPP2.Notify(true, nil, 'command.dpp2.freezephyspanic', @)

	setvar: (args = {}) =>
		return 'command.dpp2.setvar.none' if not args[1]
		return 'command.dpp2.setvar.no_arg' if not args[2]
		cvar = table.remove(args, 1)\sub(6)

		for entry in *DPP2.CVarsRegistry
			if entry.cvarName == cvar
				entry.cvar\SetString(table.concat(args, ' '))
				DPP2.Notify(true, nil, 'command.dpp2.setvar.changed', @, cvar)
				return

		return 'command.dpp2.setvar.invalid', cvar

	cleardecals: (args = {}) =>
		net.Start('dpp2_cleardecals')
		net.WriteBool(IsValid(@))
		net.WriteEntity(@) if IsValid(@)
		net.Broadcast()

	cleanupgibs: (args = {}) =>
		net.Start('dpp2_cleargibs')
		net.Broadcast()

		num = 0

		for ent in *ents.GetAll()
			if ent\GetClass() == 'gib' and ent\EntIndex() > 0
				SafeRemoveEntity(ent)
				num += 1

			if ent.GetModel and ent\GetModel() and ent\GetModel()\startsWith('models/gibs/')
				SafeRemoveEntity(ent)
				num += 1

		DPP2.NotifyCleanup(true, nil, 'command.dpp2.cleanupgibs', @, num)

	inspect: (args = {}) =>
		return 'command.dpp2.generic.invalid_side' if not IsValid(@)

		tr = util.TraceLine({
			start: @EyePos()
			endpos: @EyePos() + @EyeAngles()\Forward() * 32000
			mask: MASK_ALL
			filter: @
		})

		ent = tr.Entity

		net.Start('dpp2_inspect')
		net.WriteBool(IsValid(ent))
		net.WriteEntity(ent) if IsValid(ent)
		net.Send(@)

		DPP2.Notify(@, nil, 'message.dpp2.inspect.check_console')
		DPP2.LMessagePlayer(@, 'message.dpp2.inspect.serverside')
		DPP2.SpewEntityInspectionOutput(@, ent)
		DPP2.LMessagePlayer(@, 'message.dpp2.inspect.footer')
}

DPP2.cmd[k] = v for k, v in pairs(cmds)
