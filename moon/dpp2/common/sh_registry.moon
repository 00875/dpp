
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

import DPP2, type, table, DLib, string, net from _G

if SERVER
	net.pool('dpp2_list_entry_create')
	net.pool('dpp2_list_entry_remove')
	net.pool('dpp2_list_entry_modify')

	net.pool('dpp2_blist_add')
	net.pool('dpp2_blist_remove')
	net.pool('dpp2_blist_replicate')

DPP2.DEF = DPP2.DEF or {}

class DPP2.DEF.RestrictionListEntry
	@nextid = 0

	@ADD_GROUP = 0
	@REMOVE_GROUP = 2
	@UPDATE_WHITELIST_STATE = 1
	@FULL_REPLICATE = 3

	if CLIENT
		net.receive 'dpp2_list_entry_create', ->
			id, list = net.ReadUInt32(), net.ReadString()
			entry = @ReadPayload()
			entry\SetID(id)
			list = assert(DPP2.DEF.RestrictionList\GetByID(list), 'Invalid list received: ' .. list)
			entry\Bind(list)
			list\AddEntry(entry)
			entry.replicated = true

		net.receive 'dpp2_list_entry_remove', ->
			id = net.ReadUInt32()
			entry = assert(DPP2.DEF.RestrictionList\FindEntry(id), 'Unable to find restriction entry with id ' .. id .. ' (for remove)')
			entry.removed = true
			entry.replicated = false
			entry.parent\RemoveEntry(entry) if entry.parent

		net.receive 'dpp2_list_entry_modify', ->
			id = net.ReadUInt32()
			entry = assert(DPP2.DEF.RestrictionList\FindEntry(id), 'Unable to find restriction entry with id ' .. id .. ' (for modify)')
			modif = net.ReadUInt8()

			switch modif
				when @ADD_GROUP
					entry\AddGroup(net.ReadString())
				when @REMOVE_GROUP
					entry\RemoveGroup(net.ReadString())
				when @UPDATE_WHITELIST_STATE
					entry\SwitchIsWhitelist(net.ReadBool())
				when @FULL_REPLICATE
					entry\ReadPayload()
				else
					error('Unknown modify state: ' .. modif)

	new: (strClass, grouplist = {}, isWhitelist = false, parent) =>
		@class = strClass
		@groups = grouplist
		@isWhitelist = isWhitelist
		@id = @@nextid
		@@nextid += 1
		@parent = parent
		@replicated = false
		@locked = false
		@removed = false

		if SERVER
			@Replicate() if parent

	Remove: =>
		return false if @removed
		return false if CLIENT and @replicated

		if SERVER and @replicated
			net.Start('dpp2_list_entry_remove')
			net.WriteUInt32(@id)
			net.Broadcast()

		@removed = true
		@replicated = false
		@parent\RemoveEntry(@) if @parent
		return true

	Bind: (parent) =>
		@parent = parent
		return @

	SwitchIsWhitelist: (isWhitelist = @isWhitelist) =>
		return false if isWhitelist == @isWhitelist
		@isWhitelist = isWhitelist

		if SERVER and @replicated and not @locked
			net.Start('dpp2_list_entry_modify')
			net.WriteUInt32(@id)
			net.WriteUInt8(@@UPDATE_WHITELIST_STATE)
			net.WriteBool(isWhitelist)
			net.Broadcast()

		@parent\CallHook('WhitelistStatusUpdated', group, @isWhitelist) if @parent

		return true

	AddGroup: (group) =>
		assert(type(group) == 'string', 'Group must be a string, ' .. type(group) .. ' given')
		group = group\trim()
		return false if table.qhasValue(@groups, group) or group == ''
		table.insert(@groups, group)

		if SERVER and @replicated and not @locked
			net.Start('dpp2_list_entry_modify')
			net.WriteUInt32(@id)
			net.WriteUInt8(@@ADD_GROUP)
			net.WriteString(group)
			net.Broadcast()

		@parent\CallHook('GroupAdded', group) if @parent

		return true

	HasGroup: (group) => table.qhasValue(@groups, group)
	IsWhitelist: => @isWhitelist

	RemoveGroup: (group) =>
		assert(type(group) == 'string', 'Group must be a string, ' .. type(group) .. ' given')
		group = group\trim()
		return false if not table.qhasValue(@groups, group) or group == ''

		for i, group2 in ipairs(@groups)
			if group == group2
				table.remove(@groups, i)
				break

		if SERVER and @replicated and not @locked
			net.Start('dpp2_list_entry_modify')
			net.WriteUInt32(@id)
			net.WriteUInt8(@@REMOVE_GROUP)
			net.WriteString(group)
			net.Broadcast()

		@parent\CallHook('GroupRemoved', group) if @parent

		return true

	SetGroups: (groups = {}) =>
		toAdd, toRemove = {}, {}

		for group in *groups
			if not table.qhasValue(@groups, group)
				table.insert(toAdd, group)

		for group in *@groups
			if not table.qhasValue(groups, group)
				table.insert(toRemove, group)

		@AddGroup(group) for group in *toAdd
		@RemoveGroup(group) for group in *toRemove

		return @

	Lock: =>
		error('Invalid side') if CLIENT
		@locked = true
		return @

	UnLock: =>
		error('Invalid side') if CLIENT
		@locked = false
		return @

	WritePayload: =>
		net.WriteString(@class)
		net.WriteStringArray(@groups)
		net.WriteBool(@isWhitelist)

	ReadPayload: =>
		@class = net.ReadString()
		@groups = net.ReadStringArray()
		@isWhitelist = net.ReadBool()

	@ReadPayload: =>
		classname = net.ReadString()
		groups = net.ReadStringArray()
		isWhitelist = net.ReadBool()
		return DPP2.DEF.RestrictionListEntry(classname, groups, isWhitelist)

	SetID: (id = @id) =>
		@id = id
		return @

	GetID: => @id

	Replicate: =>
		error('Invalid side') if CLIENT
		error('Removed') if @removed

		if not @replicated
			@replicated = true
			net.Start('dpp2_list_entry_create')
			net.WriteUInt32(@id)
			net.WriteString(@parent.identifier)
			@WritePayload()
			net.Broadcast()
		else
			net.Start('dpp2_list_entry_modify')
			net.WriteUInt32(@id)
			net.WriteUInt8(@@FULL_REPLICATE)
			@WritePayload()
			net.Broadcast()

	Is: (classname) => @class == classname
	Ask: (classname, group, isAdmin) =>
		return if classname ~= @class
		return @isWhitelist if table.qhasValue(@groups, group)

class DPP2.DEF.RestrictionList
	@LISTS = {}
	@_LISTS = {}

	@GetByID: (id) => @LISTS[id] or false

	@FindEntry: (id) =>
		for list in *@_LISTS
			entry = list\GetByID(id)
			return entry if entry

		return false

	new: (identifier, autocomplete) =>
		@identifier = identifier
		error('Restriction list ' .. identifier .. ' already exists! Can not redefine existing one.') if @@LISTS[identifier]
		@@LISTS[@identifier] = @
		@listing = {}
		@@_LISTS = [list for key, list in pairs(@@LISTS)]
		self2 = @

		if SERVER
			DPP2.cmd['add_' .. identifier .. '_restriction'] = (args = {}) =>
				prop = args[1]
				groups = args[2] or ''
				isWhitelist = tobool(args[3])
				return 'command.dpp2.lists.arg_empty' if not prop
				prop = prop\trim()
				return 'command.dpp2.lists.arg_empty' if prop == ''

				if entry = self2\Get(prop)
					entry\SetGroups([group\trim() for group in *groups\trim()\split(',')])
					entry\SwitchIsWhitelist(isWhitelist) if args[3] and args[3]\trim() ~= ''
					DPP2.Notify(true, nil, 'command.dpp2.rlists.updated.' .. identifier, @, prop, (#entry.groups ~= 0 and table.concat(entry.groups, ', ') or '<none>'), entry.isWhitelist)
					return

				if not groups or groups\trim() == ''
					self2\CreateEntry(prop)\Replicate()
					DPP2.Notify(true, nil, 'command.dpp2.rlists.added.' .. identifier, @, prop)
					return

				split = [group\trim() for group in *groups\trim()\split(',')]
				split = {} if #split == 1 and split[1] == ''
				self2\CreateEntry(prop, split, isWhitelist)\Replicate()
				DPP2.Notify(true, nil, 'command.dpp2.rlists.added_ext.' .. identifier, @, prop, (#split ~= 0 and table.concat(split, ', ') or '<none>'), isWhitelist)

			DPP2.cmd['remove_' .. identifier .. '_restriction'] = (args = {}) =>
				prop = table.concat(args, ' ')\trim()
				return 'command.dpp2.lists.arg_empty' if prop == ''
				getEntry = self2\Get(prop)
				return 'command.dpp2.lists.already_not' if not getEntry

				getEntry\Remove()
				DPP2.Notify(true, nil, 'command.dpp2.rlists.removed.' .. identifier, @, prop)

		DPP2.cmd_perms['add_' .. identifier .. '_restriction'] = 'superadmin'
		DPP2.cmd_perms['remove_' .. identifier .. '_restriction'] = 'superadmin'

		@has_autocomplete = autocomplete ~= nil

		DPP2.cmd_autocomplete['add_' .. identifier .. '_restriction'] = (args, margs) =>
			split = DPP2.SplitArguments(args)

			if not split[2]
				--return autocomplete(@, split[1] or '', margs, [elem.class for elem in *self2.listing]) if autocomplete
				if autocomplete
					list = autocomplete(@, split[1] or '', margs, nil, false)

					return if not list

					for i, line in ipairs(list)
						if get = self2\Get(line)
							list[i] = string.format('%q', line) .. ' "' .. table.concat(get.groups, ',') .. '" ' .. tostring(get.isWhitelist)
						else
							list[i] = string.format('%q', line)

					return list

				return {string.format('%q', split[1])}

			str = string.format('%q', split[1])
			groupsRaw = split[2]
			groupsSplit = split[2]\split(',')
			lastGroup = table.remove(groupsSplit, #groupsSplit)\trim()
			groups = {string.format('%q', groupsRaw)}

			for group in pairs(CAMI.GetUsergroups())
				if group\startsWith(lastGroup) and not table.qhasValue(groupsSplit, group)
					if #groupsSplit == 0
						table.insert(groups, string.format('%q', group))
					else
						table.insert(groups, string.format('%q', table.concat(groupsSplit, ',') .. ',' .. group))

			if not split[3] and margs[#margs] ~= ' '
				return [str .. ' ' .. group for group in *groups]

			return {str .. ' ' .. string.format('%q', groupsRaw) .. ' true', str .. ' ' .. string.format('%q', groupsRaw) .. ' false'}

		@add_autocomplete = DPP2.cmd_autocomplete['add_' .. identifier .. '_restriction']

		DPP2.cmd_autocomplete['remove_' .. identifier .. '_restriction'] = (args, margs) =>
			return [string.format('%q', elem.class) for elem in *self2.listing] if args == ''
			args = args\lower()

			output = {}

			for elem in *self2.listing
				with lower = elem.class\lower()
					if lower == args
						output = {string.format('%q', elem.class)}
						break

					if \startsWith(args)
						table.insert(output, string.format('%q', elem.class))

			return output

		DPP2.CheckPhrase('command.dpp2.rlists.added.' .. identifier)
		DPP2.CheckPhrase('command.dpp2.rlists.updated.' .. identifier)
		DPP2.CheckPhrase('command.dpp2.rlists.added_ext.' .. identifier)
		DPP2.CheckPhrase('command.dpp2.rlists.removed.' .. identifier)

	CallHook: (name, entry, ...) => hook.Run('DPP2_' .. @identifier .. '_' .. name, @, entry, ...)
	AddEntry: (entry) =>
		return false if table.qhasValue(@listing, entry)
		table.insert(@listing, entry)
		@CallHook('EntryAdded', entry)
		return true

	RemoveEntry: (entry) =>
		for i, entry2 in ipairs(@listing)
			if entry == entry2
				table.remove(@listing, i)
				@CallHook('EntryRemoved', entry2)
				return true

		return false

	CreateEntry: (...) =>
		entry = DPP2.DEF.RestrictionListEntry(...)
		entry\Bind(@)
		@AddEntry(entry)
		return entry

	GetByID: (id) =>
		return entry for entry in *@listing when entry.id == id
		return false

	Ask: (classname, ply) =>
		group, isAdmin = ply\GetUserGroup(), ply\IsAdmin()

		for entry in *@listing
			status = entry\Ask(classname, group, isAdmin)
			return status if status ~= nil

		return true

	Has: (classname) =>
		return true for entry in *@listing when entry\Is(classname)
		return false

	Get: (classname) =>
		return entry for entry in *@listing when entry\Is(classname)
		return false

class DPP2.DEF.Blacklist
	@REGISTRY = {}
	@REGISTRY_ = {}
	@nextid = 0

	if CLIENT
		net.receive 'dpp2_blist_add', ->
			list, entry = assert(@REGISTRY_[net.ReadUInt8()], 'Missing blacklist registry'), net.ReadString()
			list\Add(entry)

		net.receive 'dpp2_blist_remove', ->
			list, entry = assert(@REGISTRY_[net.ReadUInt8()], 'Missing blacklist registry'), net.ReadString()
			list\Remove(entry)

		net.receive 'dpp2_blist_replicate', ->
			list, listing = assert(@REGISTRY_[net.ReadUInt8()], 'Missing blacklist registry'), net.ReadStringArray()
			list.listing = DLib.Set()
			list\Add(val) for val in *listing

	new: (identifier, autocomplete) =>
		assert(identifier, 'Blacklist registry without identifier')
		error('Blacklist ' .. identifier .. ' already exists! Can not redefine existing one.') if @@REGISTRY[identifier]

		@@REGISTRY[identifier] = @
		@id = @@nextid
		@@nextid += 1
		@@REGISTRY_[@id] = @
		@identifier = identifier
		@listing = DLib.Set()
		@listingDef = DLib.Set()
		self2 = @

		if SERVER
			DPP2.cmd['add_' .. identifier .. '_blacklist'] = (args = {}) =>
				val = table.concat(args, ' ')\trim()
				return 'command.dpp2.lists.arg_empty' if val == ''
				return 'command.dpp2.lists.already_in' if self2\Has(val)
				self2\Add(val)
				DPP2.Notify(true, nil, 'command.dpp2.blists.added.' .. identifier, @, val)

			DPP2.cmd['remove_' .. identifier .. '_blacklist'] = (args = {}) =>
				val = table.concat(args, ' ')\trim()
				return 'command.dpp2.lists.arg_empty' if val == ''
				return 'command.dpp2.lists.already_not' if not self2\Has(val)
				self2\Remove(val)
				DPP2.Notify(true, nil, 'command.dpp2.blists.removed.' .. identifier, @, val)

		DPP2.cmd_perms['add_' .. identifier .. '_blacklist'] = 'superadmin'
		DPP2.cmd_perms['remove_' .. identifier .. '_blacklist'] = 'superadmin'

		if autocomplete
			DPP2.cmd_autocomplete['add_' .. identifier .. '_blacklist'] = (args, margs) => autocomplete(@, args, margs, self2.listing\GetValues())
		elseif CLIENT
			DPP2.cmd_existing['add_' .. identifier .. '_blacklist'] = true

		DPP2.cmd_autocomplete['remove_' .. identifier .. '_blacklist'] = (args, margs) =>
			return [string.format('%q', elem) for elem in *self.listing\GetValues()] if args == ''
			args = args\lower()

			output = {}

			for elem in *self.listing\GetValues()
				with lower = elem\lower()
					if lower == args
						output = {string.format('%q', elem)}
						break

					if \startsWith(args)
						table.insert(output, string.format('%q', elem))

			return output

	Add: (entry) =>
		return false if @Has(entry)
		@listing\Add(entry)

		if SERVER
			net.Start('dpp2_blist_add')
			net.WriteUInt8(@id)
			net.WriteString(entry)
			net.Broadcast()

		return true

	AddDefault: (entry) => @listingDef\Add(entry)

	Remove: (entry) =>
		return false if not @Has(entry)

		if SERVER
			net.Start('dpp2_blist_remove')
			net.WriteUInt8(@id)
			net.WriteString(entry)
			net.Broadcast()

		@listing\Remove(entry)
		return true

	RemoveDefault: (entry) => @listingDef\Remove(entry) -- ???
	Has: (entry) => @listing\Has(entry)
	HasDefault: (entry) => @listingDef\Has(entry) -- ???

	Check: (entry) => @Has(entry)

	FullReplicate: (who = player.GetAll()) =>
		error('Invalid side') if CLIENT
		net.Start('dpp2_blist_replicate')
		net.WriteUInt8(@id)
		net.WriteStringArray(@listing\GetValues())
		net.Send(who)

