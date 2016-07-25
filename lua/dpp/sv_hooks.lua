
--[[
Copyright (C) 2016 DBot

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

--HOOKS
local SpawnFunctions = {}
DPP.SpawnFunctions = SpawnFunctions

local function Spawned(ply, ent)
	DPP.SetOwner(ent, ply)
end

local IgnoreSpawn = {
	['env_spritetrail'] = true, --Using E2 to spawn prop with effect, it just fills up console
}

local GRAY = Color(200, 200, 200)
local RED = Color(255, 0, 0)

local LogIntoFile = DPP.LogIntoFile
local SimpleLog = DPP.SimpleLog

local SPACE = {type = 'Spacing', length = 50}
local SPACE2 = {type = 'Spacing', length = 100}
SpawnFunctions.SPACE = SPACE
SpawnFunctions.SPACE2 = SPACE2

local function LogSpawn(ply, ent, type)
	if not DPP.GetConVar('log_spawns') then return end
	if IgnoreSpawn[ent:GetClass()] then return end
	SimpleLog(ply, SPACE, GRAY, ' spawned ', color_white, SPACE2, ent:GetClass(), GRAY, string.format(' <%s | %s> (%s)', tostring(ent), ent:GetModel(), type or 'N/A'))
end

local function LogSpawnC(ply, class, type, model)
	if not DPP.GetConVar('log_spawns') then return end
	if IgnoreSpawn[class] then return end
	SimpleLog(ply, SPACE, GRAY, ' spawned ', color_white, SPACE2, class, GRAY, string.format(' <%s | %s> (%s)', class, model or 'N/A', type or 'N/A'))
end

local function LogTry(ply, type, model, class)
	if not DPP.GetConVar('log_spawns') then return end
	if IgnoreSpawn[class] then return end
	SimpleLog(ply, SPACE, RED, ' tried ', GRAY, 'to spawn', SPACE2, string.format(' %s <%s | %s> (%s)', class or 'N/A', class or 'N/A', model or 'N/A', type or 'N/A'))
end

local function LogTryPost(ply, type, ent)
	if not DPP.GetConVar('log_spawns') then return end
	if IgnoreSpawn[ent:GetClass()] then return end
	SimpleLog(ply, SPACE, RED, ' tried ', GRAY, 'to spawn', SPACE2, string.format(' %s <%s | %s> (%s)', ent:GetClass(), tostring(ent), ent:GetModel(), type or 'N/A'))
end

--god
local function LogTryPostInv(ply, ent, type)
	LogTryPost(ply, type, ent)
end

local function StuckCheckDelay(ply, ent)
	if not IsValid(ent) then return end
	
	timer.Simple(0, function()
		if not IsValid(ent) then return end
		for k, v in pairs(ents.FindInSphere(ent:GetPos(), 32)) do
			if DPP.GetGhosted(v) then continue end
			if DPP.CheckStuck(ply, ent, v) then break end
		end
	end)
end

local function LogConstraint(ply, ent)
	if not DPP.GetConVar('log_spawns') then return end
	if not DPP.GetConVar('log_constraints') then return end
	if IgnoreSpawn[ent:GetClass()] then return end
	local ent1, ent2 = DPP.GetConstrainedEntities(ent)
	
	if not IsValid(ent1) then
		ent1 = '<unknown>'
	end
	
	if not IsValid(ent2) then
		ent2 = '<unknown>'
	end
	
	SimpleLog(ply, SPACE, GRAY, ' created constraint ', SPACE2, color_white, DPP.GetContstrainType(ent), ' <' .. tostring(ent) .. '>', GRAY, string.format(' between %s and %s', tostring(ent1), tostring(ent2)))
end

local function LogConstraintTry(ply, ent)
	if not DPP.GetConVar('log_spawns') then return end
	if not DPP.GetConVar('log_constraints') then return end
	if IgnoreSpawn[ent:GetClass()] then return end
	local ent1, ent2 = DPP.GetConstrainedEntities(ent)
	
	if not IsValid(ent1) then
		ent1 = '<unknown>'
	end
	
	if not IsValid(ent2) then
		ent2 = '<unknown>'
	end
	
	SimpleLog(ply, SPACE, RED, ' tried ', GRAY, SPACE2, 'to create constraint ', color_white, DPP.GetContstrainType(ent), ' <' .. tostring(ent) .. '>', GRAY, string.format(' between %s and %s', tostring(ent1), tostring(ent2)))
end

local function CheckEntityLimit(ply, class)
	if not DPP.IsEnabled() then return end
	local limit = DPP.GetEntityLimit(class, ply:GetUserGroup())
	if limit <= 0 then return false end

	local count = #DPP.FindEntitiesByClass(ply,	class)
	local status = count + 1 > limit
	if status then
		DPP.Notify(ply, 'You hit ' .. class .. ' limit!', 1)
	end
	
	return status
end

local function CheckBlocked(ply, ent)
	local Mod = ent:GetModel()
	if not Mod then return end
	local model = string.lower(Mod)
	
	if DPP.IsRestrictedModel(model, ply) then 
		SafeRemoveEntity(ent)
		
		if ply then
			DPP.Notify(ply, 'Model of that entity is restricted', 1)
		end
		
		return false
	end
	
	if DPP.IsModelBlocked(model, ply) then
		SafeRemoveEntity(ent)
	end
end

local function CheckBlocked2(ply, model)
	model = string.lower(model) --Fucking upper case
	
	if DPP.IsRestrictedModel(model, ply) then
		if ply then
			DPP.Notify(ply, 'Model of that entity is restricted', 1)
		end
		
		return false
	end
	
	if DPP.IsModelBlocked(model, ply) then
		return false
	end
	
	return true
end

function SpawnFunctions.PlayerSpawnedNPC(ply, ent, shouldHideLog)
	if ent.DPP_SpawnTime  == CurTime() then return end
	ent.DPP_SpawnTime = CurTime()
	
	if DPP.IsRestrictedNPC(ent:GetClass(), ply) then 
		LogTryPost(ply, 'NPC', ent)
		DPP.Notify(ply, 'That entity is restricted', 1)
		SafeRemoveEntity(ent)
		return false
	end
	
	if CheckEntityLimit(ply, ent:GetClass()) then 
		LogTryPost(ply, 'NPC', ent)
		SafeRemoveEntity(ent)
		return false
	end
	
	if DPP.GetConVar('check_stuck') then
		StuckCheckDelay(ply, ent)
	end
	
	Spawned(ply, ent)
	if not shouldHideLog then LogSpawn(ply, ent, 'NPC') end
	
	DPP.CheckAntispamDelay(ply, ent)
	DPP.CheckDroppedEntity(ply, ent)
	CheckBlocked(ply, ent)
end

function SpawnFunctions.PlayerSpawnedEffect(ply, model, ent, shouldHideLog)
	Spawned(ply, ent)
	if not shouldHideLog then LogSpawn(ply, ent, 'Effect') end
	
	DPP.CheckAntispamDelay(ply, ent)
	CheckBlocked(ply, ent)
end

local PENDING, PENDING_PLY
DPP.oldCleanupAdd = DPP.oldCleanupAdd or cleanup.Add
DPP.oldUndoAddEntity = DPP.oldUndoAddEntity or undo.AddEntity
DPP.oldUndoFinish = DPP.oldUndoFinish or undo.Finish

local function CheckBefore(ply, ent, forceVerbose, ignoreAntispam)
	local hide = not forceVerbose and not DPP.GetConVar('verbose_logging')
	if not ent then return end
	if IsValid(ent) and not DPP.IsOwned(ent) or not IsValid(DPP.GetOwner(ent)) then --Wow, we spawned entity without calling spawning hook!
		if ent:GetClass() == 'prop_physics' then
			SpawnFunctions.PlayerSpawnedProp(ply, ent:GetModel(), ent, hide, ignoreAntispam)
		elseif ent:IsNPC() then
			SpawnFunctions.PlayerSpawnedNPC(ply, ent, hide, ignoreAntispam)
		elseif ent:IsRagdoll() then
			SpawnFunctions.PlayerSpawnedRagdoll(ply, ent:GetModel(), ent, hide, ignoreAntispam)
		elseif ent:IsVehicle() then
			SpawnFunctions.PlayerSpawnedVehicle(ply, ent, hide, ignoreAntispam)
		elseif ent:IsWeapon() then
			SpawnFunctions.PlayerSpawnedSWEP(ply, ent, hide, ignoreAntispam)
		--elseif not ent:IsConstraint() then
		elseif DPP.IsConstraint(ent) then
			timer.Simple(0, function() SpawnFunctions.PlayerSpawnedConstraint(ply, ent, hide, ignoreAntispam) end)
		else
			SpawnFunctions.PlayerSpawnedSENT(ply, ent, hide, ignoreAntispam)
		end
	end
end

SpawnFunctions.CheckBefore = CheckBefore

local function undo_Finish(name)
	local name, val = debug.getupvalue(DPP.oldUndoFinish, 1)
	
	if name == 'Current_Undo' and val then
		local owner = val.Owner
		if IsValid(owner) then
			for k, v in pairs(val.Entities) do
				if not IsValid(v) then continue end
				if DPP.IsOwned(v) then continue end
				
				CheckBefore(owner, v, true) --HOLY FUCK
			end
		end
	end
	
	return DPP.oldUndoFinish(name)
end

local function cleanup_Add(ply, type, ent)
	DPP.AssertPlayer(ply)
	if PENDING ~= ent then
		if IsValid(PENDING_PLY) then DPP.CheckAntispam(PENDING_PLY, PENDING) end
		PENDING = nil
		PENDING_PLY = nil
	end
	
	local check = true
	
	if DPP.DTypes[type] then
		check = false
	end
	
	if PENDING == ent then
		if check then
			if IsValid(PENDING_PLY) then DPP.CheckAntispam(PENDING_PLY, PENDING) end
		end
		
		PENDING = nil
		PENDING_PLY = nil
	end
	
	if IsValid(ent) then
		if not DPP.IsOwned(ent) then
			CheckBefore(ply, ent)
			PENDING = nil
			PENDING_PLY = nil
		end
		
		DPP.SetOwner(ent, ply)
	end
	
	return DPP.oldCleanupAdd(ply, type, ent)
end

function SpawnFunctions.PlayerSpawnedProp(ply, model, ent, shouldHideLog, ignoreAntispam)
	if ent.DPP_SpawnTime  == CurTime() then return end
	ent.DPP_SpawnTime = CurTime()
	
	if CheckEntityLimit(ply, ent:GetClass()) then 
		LogTryPost(ply, 'Prop', ent)
		SafeRemoveEntity(ent)
		return false
	end
	
	Spawned(ply, ent)
	if not ignoreAntispam then DPP.CheckSizesDelay(ent, ply) end
	if not DPP.CheckAutoBlock(ent, ply) then if not shouldHideLog then LogTryPostInv(ply, ent, 'Prop') end return end
	if DPP.GetConVar('check_stuck') then
		StuckCheckDelay(ply, ent)
	end
	
	if not shouldHideLog then LogSpawn(ply, ent, 'Prop') end
	
	PENDING = ent
	PENDING_PLY = ply
	
	DPP.CheckDroppedEntity(ply, ent)
	CheckBlocked(ply, ent)
end

local ropesConstraints = {
	['rope'] = true,
	['pulley'] = true,
	['slider'] = true,
	['weld'] = true,
	['hydraulic'] = true,
	['elastic'] = true,
	['muscle'] = true,
}

function SpawnFunctions.PlayerSpawnedConstraint(ply, ent, hide, ignoreAntispam)
	DPP.AssertPlayer(ply)
	if not IsValid(ply) then return end
	if not IsValid(ent) then return end
	Spawned(ply, ent)
	
	local type = DPP.GetContstrainType(ent)
	
	local spawned = true
	if DPP.IsConstraintLimitReached(ply, type) then spawned = false end
	
	local ent1, ent2 = DPP.GetConstrainedEntities(ent)
	local V1, V2 = IsValid(ent1), IsValid(ent2)
	
	if V1 and V2 then
		if ent1:GetClass() ~= 'gmod_anchor' and ent2:GetClass() ~= 'gmod_anchor' then
			local can1 = DPP.CanTool(ply, ent1, '') ~= false
			local can2 = DPP.CanTool(ply, ent2,  '') ~= false
			
			if not can1 or not can2 then
				spawned = false
			end
		elseif DPP.GetConVar('no_rope_world') then
			if ropesConstraints[type] and not (not DPP.GetConVar('no_rope_world_weld') and type == 'weld') then
				spawned = false
			end
		end
	elseif DPP.GetConVar('no_rope_world') and ((V1 and not V2) or (not V1 and V2)) then
		if ropesConstraints[type] and not (not DPP.GetConVar('no_rope_world_weld') and type == 'weld') then
			spawned = false
		end
	end
	
	if spawned then
		LogConstraint(ply, ent)
	else
		LogConstraintTry(ply, ent)
		SafeRemoveEntity(ent)
	end
end

function SpawnFunctions.PlayerSpawnedRagdoll(ply, model, ent, shouldHideLog, ignoreAntispam)
	DPP.AssertPlayer(ply)
	if ent.DPP_SpawnTime  == CurTime() then return end
	ent.DPP_SpawnTime = CurTime()
	
	if CheckEntityLimit(ply, ent:GetClass()) then 
		LogTryPost(ply, 'Ragdoll', ent)
		SafeRemoveEntity(ent)
		return false
	end
	
	if DPP.GetConVar('check_stuck') then
		StuckCheckDelay(ply, ent)
	end
	
	Spawned(ply, ent)
	if not ignoreAntispam then DPP.CheckSizesDelay(ent, ply) end
	if not DPP.CheckAutoBlock(ent, ply) then if not shouldHideLog then LogTryPostInv(ply, ent, 'Ragdoll') end return end
	if not shouldHideLog then LogSpawn(ply, ent, 'Ragdoll') end
	
	PENDING = ent
	PENDING_PLY = ply
	
	CheckBlocked(ply, ent)
end

function SpawnFunctions.PlayerSpawnedSENT(ply, ent, shouldHideLog, ignoreAntispam)
	DPP.AssertPlayer(ply)
	if ent.DPP_SpawnTime  == CurTime() then return end
	ent.DPP_SpawnTime = CurTime()
	
	if DPP.IsRestrictedSENT(ent:GetClass(), ply) then 
		LogTryPost(ply, 'SENT', ent)
		DPP.Notify(ply, 'That entity is restricted', 1)
		SafeRemoveEntity(ent)
		return false
	end
	
	if CheckEntityLimit(ply, ent:GetClass()) then 
		LogTryPost(ply, 'SENT', ent)
		SafeRemoveEntity(ent)
		return false
	end
	
	if DPP.GetConVar('check_stuck') then
		StuckCheckDelay(ply, ent)
	end
	
	Spawned(ply, ent)
	if not ignoreAntispam then DPP.CheckSizesDelay(ent, ply) end
	if not DPP.CheckAutoBlock(ent, ply) then if not shouldHideLog then LogTryPostInv(ply, ent, 'SENT') end return end
	if not shouldHideLog then LogSpawn(ply, ent, 'SENT') end
	
	PENDING = ent
	PENDING_PLY = ply
	
	CheckBlocked(ply, ent)
end

function SpawnFunctions.PlayerSpawnedSWEP(ply, ent, shouldHideLog, ignoreAntispam)
	DPP.AssertPlayer(ply)
	if ent.DPP_SpawnTime  == CurTime() then return end
	ent.DPP_SpawnTime = CurTime()
	
	if DPP.IsRestrictedSWEP(ent:GetClass(), ply) then 
		LogTryPost(ply, 'SWEP', ent)
		DPP.Notify(ply, 'That SWEP is restricted', 1)
		SafeRemoveEntity(ent)
		return false
	end
	
	if CheckEntityLimit(ply, ent:GetClass()) then 
		LogTryPost(ply, 'SWEP', ent)
		SafeRemoveEntity(ent)
		return false
	end
	
	if DPP.GetConVar('check_stuck') then
		StuckCheckDelay(ply, ent)
	end
	
	Spawned(ply, ent)
	if not shouldHideLog then LogSpawn(ply, ent, 'SWEP') end
	
	PENDING = ent
	PENDING_PLY = ply
	
	CheckBlocked(ply, ent)
end

function SpawnFunctions.PlayerSpawnedVehicle(ply, ent, shouldHideLog, ignoreAntispam)
	DPP.AssertPlayer(ply)
	if ent.DPP_SpawnTime  == CurTime() then return end
	ent.DPP_SpawnTime = CurTime()
	
	if DPP.IsRestrictedVehicle(ent:GetClass(), ply) then 
		LogTryPost(ply, 'Vehicle', ent)
		DPP.Notify(ply, 'That vehicle is restricted', 1)
		SafeRemoveEntity(ent)
		return false
	end

	if CheckEntityLimit(ply, ent:GetClass()) then 
		LogTryPost(ply, 'Vehicle', ent)
		SafeRemoveEntity(ent)
		return false
	end
	
	if not DPP.CheckAutoBlock(ent, ply) then if not shouldHideLog then LogTryPostInv(ply, ent, 'Vehicle') end return end
	
	if DPP.GetConVar('check_stuck') then
		StuckCheckDelay(ply, ent)
	end
	
	Spawned(ply, ent)
	if not shouldHideLog then LogSpawn(ply, ent, 'Vehicle') end
	
	PENDING = ent
	PENDING_PLY = ply
	
	CheckBlocked(ply, ent)
end

function SpawnFunctions.PlayerSpawnProp(ply, model)
	DPP.AssertPlayer(ply)
	if DPP.IsModelBlocked(model, ply) then 
		LogTry(ply, 'Prop', model)
		return false 
	end
	
	if CheckEntityLimit(ply, 'prop_physics') then 
		LogTry(ply, 'Prop', model)
		return false 
	end
	
	if DPP.CheckAntispam_NoEnt(ply, false, true) == DPP.ANTISPAM_INVALID then 
		LogTry(ply, 'Object/Generic', model)
		DPP.Notify(ply, 'Entity is removed due to spam', 1)
		return false 
	end
	
	if not CheckBlocked2(ply, model) then 
		LogTry(ply, 'Object/Generic', model)
		return false 
	end
end

function SpawnFunctions.PlayerSpawnObject(ply, model)
	DPP.AssertPlayer(ply)
	if DPP.IsModelBlocked(model, ply) then 
		LogTry(ply, 'Object/Generic', model)
		return false 
	end
	
	if DPP.CheckAntispam_NoEnt(ply, false, true) == DPP.ANTISPAM_INVALID then 
		LogTry(ply, 'Object/Generic', model)
		DPP.Notify(ply, 'Entity is removed due to spam', 1)
		return false 
	end
	
	if not CheckBlocked2(ply, model) then 
		LogTry(ply, 'Object/Generic', model)
		return false 
	end
end

function SpawnFunctions.PlayerSpawnRagdoll(ply, model)
	DPP.AssertPlayer(ply)
	if DPP.IsModelBlocked(model, ply) then 
		LogTry(ply, 'Ragdoll', model)
		return false 
	end
	
	if DPP.CheckAntispam_NoEnt(ply, false, true) == DPP.ANTISPAM_INVALID then 
		LogTry(ply, 'Object/Generic', model)
		DPP.Notify(ply, 'Entity is removed due to spam', 1)
		return false 
	end
	
	if not CheckBlocked2(ply, model) then 
		LogTry(ply, 'Object/Generic', model)
		return false 
	end
end

function SpawnFunctions.PlayerSpawnVehicle(ply, model, class)
	DPP.AssertPlayer(ply)
	if DPP.IsModelBlocked(model, ply) then 
		LogTry(ply, 'Vehicle', model)
		return false 
	end
	
	if CheckEntityLimit(ply, class) then 
		LogTry(ply, 'Vehicle', model)
		return false 
	end
	
	if DPP.CheckAntispam_NoEnt(ply, false, true) == DPP.ANTISPAM_INVALID then 
		LogTry(ply, 'Vehicle', model)
		DPP.Notify(ply, 'Entity is removed due to spam', 1)
		return false 
	end
	
	if not CheckBlocked2(ply, model) then 
		LogTry(ply, 'Vehicle', model)
		return false 
	end
	
	if DPP.IsRestrictedVehicle(class, ply) then 
		LogTry(ply, 'Vehicle', class)
		DPP.Notify(ply, 'That vehicle is restricted', 1)
		return false 
	end
end

function SpawnFunctions.PlayerSpawnSENT(ply, ent)
	DPP.AssertPlayer(ply)
	if DPP.IsRestrictedSENT(ent, ply) then 
		LogTry(ply, 'SENT', 'N/A', ent)
		DPP.Notify(ply, 'That entity is restricted', 1)
		return false 
	end
	
	if CheckEntityLimit(ply, ent) then 
		LogTry(ply, 'SENT', model)
		return false 
	end
end

function SpawnFunctions.PlayerSpawnSWEP(ply, ent)
	DPP.AssertPlayer(ply)
	if DPP.IsRestrictedSWEP(ent, ply) then 
		LogTry(ply, 'SWEP', 'N/A', ent)
		DPP.Notify(ply, 'That swep is restricted', 1)
		return false 
	end
	
	if CheckEntityLimit(ply, ent) then 
		LogTry(ply, 'SWEP', model)
		return false 
	end
end

function SpawnFunctions.PlayerGiveSWEP(ply, class, tab)
	DPP.AssertPlayer(ply)
	local can = SpawnFunctions.PlayerSpawnSWEP(ply, class)
	if can == false then return false end
	LogSpawnC(ply, class, 'SWEP', tab and (tab.Model or tab.WorldModel) or 'N/A')
end

function SpawnFunctions.PlayerSpawnNPC(ply, ent)
	DPP.AssertPlayer(ply)
	if DPP.IsRestrictedNPC(ent, ply) then 
		LogTry(ply, 'NPC', 'N/A', ent)
		DPP.Notify(ply, 'That entity is restricted', 1)
		return false 
	end
	
	if CheckEntityLimit(ply, ent) then 
		LogTry(ply, 'NPC', model)
		return false 
	end
end

for k, v in pairs(SpawnFunctions) do
	hook.Add(k, '!DPP.SpawnHooks', v, -1)
end

function DPP.CanPickupItem(ply, ent)
	if not DPP.GetConVar('enable_pickup') then return end
	
	local class = ent:GetClass()
	
	if DPP.IsEntityBlockedPickup(class) then return false end
	if DPP.IsRestrictedPickup(class, ply) then return false end
	if DPP.IsEntityWhitelistedPickup(eclass) then return false end
	
	if not DPP.IsOwned(ent) then return end
	local can = DPP.CanTouch(ply, ent, 'pickup')
	if not can then return can end
end

hook.Add('PlayerCanPickupItem', 'DPP.ProtectionHooks', DPP.CanPickupItem)
hook.Add('PlayerCanPickupWeapon', 'DPP.ProtectionHooks', DPP.CanPickupItem)

local function EntityRemoved(ent)
	if ent.IsConstraint and ent:IsConstraint() then
		local ent1, ent2 = DPP.GetConstrainedEntities(ent)
		
		timer.Simple(0, function()
			if IsValid(ent1) and IsValid(ent2) then
				local o1 = DPP.GetOwner(ent1)
				local o2 = DPP.GetOwner(ent2)
				
				if o1 ~= o2 or not DPP.IsSingleOwner(ent1, o2) or not DPP.IsSingleOwner(ent2, o1) then
					DPP.RecalcConstraints(ent1)
					DPP.RecalcConstraints(ent2)
				end
			end
			
			if IsValid(ent1) then
				ent1.DPP_ConstrainedWith = ent1.DPP_ConstrainedWith or {}
				ent1.DPP_ConstrainedWith[ent2] = nil
				DPP.SendConstrainedWith(ent1)
			end
			
			if IsValid(ent2) then
				ent2.DPP_ConstrainedWith = ent2.DPP_ConstrainedWith or {}
				ent2.DPP_ConstrainedWith[ent1] = nil
				DPP.SendConstrainedWith(ent2)
			end
		end)
	end
end

local Timestamps = {}

timer.Create('DPP.ClearTimestamps', 30, 0, function()
	for k, v in pairs(Timestamps) do
		if IsValid(k) then continue end
		Timestamps[k] = nil
	end
end)

local function DPP_ReplacedSetPlayer(self, ply)
	if DPP.GetConVar('experemental_spawn_checks') then
		DPP.SetOwner(self, ply)
		return self.__DPP_OldSetPlayer(self, ply)
	else
		return self.__DPP_OldSetPlayer(self, ply)
	end
end

local PostEntityCreated

local function OnEntityCreated(ent)
	local Timestamp = CurTime()
	Timestamps[ent] = Timestamp
	
	timer.Simple(0, function()
		PostEntityCreated(ent, Timestamp)
	end)
end

local RECURSIVE_MEM = {}
local MEM_TABLE_CACHE = {}

local function HaveValueLight(tab, val)
	for k = 1, #tab do
		if tab[k] == val then return true end
	end
	
	return false
end

local function FindEntitiesRecursiveFunc(tab)
	for k, v in pairs(tab) do
		local t = type(v)
		
		if t == 'Entity' or t == 'Vehicle' then
			if HaveValueLight(RECURSIVE_MEM, v) then continue end --Prevent recursion
			table.insert(RECURSIVE_MEM, v)
			FindEntitiesRecursiveFunc(tab)
		end
		
		if t == 'table' then
			if MEM_TABLE_CACHE[v] then continue end --Prevent recursion
			MEM_TABLE_CACHE[v] = true
			FindEntitiesRecursiveFunc(v)
		end
	end
end

local function FindEntitiesRecursive(tab)
	FindEntitiesRecursiveFunc(tab)
	local reply = RECURSIVE_MEM
	RECURSIVE_MEM = {}
	MEM_TABLE_CACHE = {}
	return reply
end

function PostEntityCreated(ent, Timestamp)
	if not IsValid(ent) then return end
	local Timestamp2 = CurTime()
	
	if ent.IsConstraint and ent:IsConstraint() then
		local ent1, ent2 = DPP.GetConstrainedEntities(ent)
		
		if IsValid(ent1) and IsValid(ent2) then
			local o1, o2 = DPP.GetOwner(ent1), DPP.GetOwner(ent2)
			
			if DPP.GetConVar('advanced_spawn_checks') then
				local t1 = Timestamps[ent1]
				local t2 = Timestamps[ent2]
				
				if t1 == Timestamp and not IsValid(o1) and IsValid(o2) then --Because we are running on next frame
					o1 = o2
					CheckBefore(o2, ent1)
				end
				
				if t2 == Timestamp and not IsValid(o2) and IsValid(o1) then
					o2 = o1
					CheckBefore(o1, ent2)
				end
			end
			
			if o1 ~= o2 or not DPP.IsSingleOwner(ent1, o2) or not DPP.IsSingleOwner(ent2, o1) then
				DPP.RecalcConstraints(ent1) --Recalculating only for one entity, because second is constrained with first
			end
			
			if o1 == o2 and not DPP.IsOwned(ent) and (IsValid(o1) or IsValid(o2)) then
				SpawnFunctions.PlayerSpawnedConstraint(IsValid(o1) and o1 or o2, ent)
			end
		end
		
		if IsValid(ent1) then
			ent1.DPP_ConstrainedWith = ent1.DPP_ConstrainedWith or {}
			ent1.DPP_ConstrainedWith[ent2] = true
			DPP.SendConstrainedWith(ent1)
		end
		
		if IsValid(ent2) then
			ent2.DPP_ConstrainedWith = ent2.DPP_ConstrainedWith or {}
			ent2.DPP_ConstrainedWith[ent1] = true
			DPP.SendConstrainedWith(ent2)
		end
	end
	
	if DPP.GetConVar('strict_spawn_checks') then
		local get = DPP.GetOwner(ent)
		
		if IsValid(get) then
			local Ents = FindEntitiesRecursive(ent:GetTable())
			
			for k, v in ipairs(Ents) do
				if Timestamps[v] ~= Timestamp then continue end
				if DPP.IsOwned(v) then continue end
				CheckBefore(get, v, false, true)
			end
		end
	end
	
	if DPP.GetConVar('experemental_spawn_checks') then
		local nent
		
		if isentity(ent.EntOwner) then
			nent = ent.SpawnedBy
		end
		
		if isentity(ent.SpawnedBy) then
			nent = ent.SpawnedBy
		end
		
		if nent then
			local owner = not nent:IsPlayer() and DPP.GetOwner(nent) or nent
			
			if isentity(nent) and not nent:IsPlayer() then
				DPP.SetConstrainedBetween(ent, nent, true)
				
				DPP.SendConstrainedWith(ent)
				DPP.SendConstrainedWith(nent)
			end
			
			if IsValid(owner) and owner:IsPlayer() then
				CheckBefore(owner, ent)
				--DPP.SetOwner(ent, owner)
			end
		end
		
		if ent.GetPlayer and ent.SetPlayer ~= DPP.SetPlayerMeta then --Wee, entity have player tracking!
			ent.__DPP_OldSetPlayer = ent.SetPlayer
			
			local owner = ent:GetPlayer()
			if IsValid(owner) then
				CheckBefore(owner, ent)
			end
			
			ent.SetPlayer = DPP_ReplacedSetPlayer
		end
	end
end

hook.Add('OnEntityCreated', 'DPP.OnEntityCreated', OnEntityCreated)
hook.Add('EntityRemoved', 'DPP.EntityRemoved', EntityRemoved)

function DPP.SetPlayerMeta(self, ply)
	--Compability
	
	if not IsValid(ply) then 
		if not DPP.GetConVar('advanced_spawn_checks') then return end
		local name, Ent = debug.getlocal(2, 1)
		
		timer.Simple(0, function() --Wait before entity is initialized and owner is defined
			if IsValid(Ent) then
				local owner = DPP.GetOwner(Ent)
				if not DLog then
					SimpleLog(RED, 'That should never happen: Entity:SetPlayer() is called without player argument! Entity: ' .. tostring(self) .. '. I detected real owner: ' .. (IsValid(owner) and owner:Nick() or 'World') .. '\nTO USERS: Yes, this is a BUG in ' .. tostring(self) .. ' and you should report it to author!')
				else
					DLog.Log('DPP', 3, 'That should never happen: Entity:SetPlayer() is called without player argument! Entity: ' .. tostring(self) .. '. I detected real owner: ', owner, '\nTO USERS: Yes, this is a BUG in ' .. tostring(self) .. ' and you should report it to author!')
				end
				
				CheckBefore(owner, self)
				--DPP.SetOwner(self, owner)
			else
				if not DLog then
					SimpleLog(RED, 'That should never happen: Entity:SetPlayer() is called without player argument! Entity: ' .. tostring(self) .. '.\nTO USERS: Yes, this is a BUG in ' .. tostring(self) .. ' and you should report it to author!')
				else
					DLog.Log('DPP', 3, 'That should never happen: Entity:SetPlayer() is called without player argument! Entity: ' .. tostring(self) .. '.\nTO USERS: Yes, this is a BUG in ' .. tostring(self) .. ' and you should report it to author!')
				end
			end
		end)
		
		return 
	end
	
	CheckBefore(ply, self)
	
	self:SetVar("Founder", ply)
	self:SetVar("FounderIndex", ply:UniqueID())
	self:SetNetworkedString("FounderName", ply:Nick())
	
	return DPP.SetOwner(self, ply)
end

function DPP.GetPlayerMeta(self, ply)
	return DPP.GetOwner(self, ply)
end

local entMeta = FindMetaTable('Entity')
DPP.oldSetOwnerFunc = DPP.oldSetOwnerFunc or entMeta.SetOwner

function DPP.OverrideE2()
	if not Compiler then return end
	DPP.Message('Detected E2, overriding.')
	--Hello, Wiremod
	
	DPP.__oldCompilerFunc = DPP.__oldCompilerFunc or Compiler.GetFunction
	
	function Compiler:GetFunction(instr, Name, Args)
		if self.DPly then
			if DPP.IsRestrictedE2Function(Name, self.DPly) then
				SimpleLog(team.GetColor(self.DPly:Team()), self.DPly:Nick(), color_white, '<' .. self.DPly:SteamID() .. '>', RED, ' tried ', GRAY, string.format('to use E2 function %s', Name))
				self:Error('DPP: Restricted Function: ' .. Name, instr)
				return
			end
		end
		
		return DPP.__oldCompilerFunc(self, instr, Name, Args)
	end
	
	function Compiler.Execute(...)
		-- instantiate Compiler
		local instance = setmetatable({}, Compiler)
		
		local Name, Ent = debug.getlocal(2, 1) --Getting our entity
		
		if IsValid(Ent) then
			instance.DPly = DPP.GetOwner(Ent)
		end
		
		-- and pcall the new instance's Process method.
		return pcall(Compiler.Process, instance, ...)
	end
end

function DPP.OverrideGMODEntity()
	local ent = scripted_ents.Get('base_gmodentity')
	if not ent then return end
	
	DPP.Message('Detected base_gmodentity')
	
	ent.SetPlayer = DPP.SetPlayerMeta
	ent.GetPlayer = DPP.GetPlayerMeta
	scripted_ents.Register(ent, 'base_gmodentity')
	
	function entMeta:SetOwner(ent)
		timer.Simple(0, function()
			if not IsValid(self) then return end
			if not IsValid(ent) then return end
			local owner = DPP.GetOwner(ent)
			if IsValid(owner) then
				DPP.SetOwner(self, owner)
			end
		end)
		return DPP.oldSetOwnerFunc(self, ent)
	end
end

--Just make it better
local function ReceiveProperty(len, ply)
	if DPP.GetConVar('strict_property') then return end
	if isfunction(DPP._OldPropertiesReceive) then
		DPP._OldPropertiesReceive(len, ply)
	end
end

local function NetMessageErr(err)
	MsgC('[DPP Error]: Property is broken! ' .. err .. '\n')
end

local RED = Color(255, 0, 0)
local GRAY = Color(200, 200, 200)

local function ReceiveProperty_DPP(len, ply)
	if not IsValid(ply) then return end
	
	local name = net.ReadString()
	if not name or name == '' then return end
	
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end
	
	local obj = properties.List[name]
	if not obj then return end
	if not isfunction(obj.Filter) then return end
	if not isfunction(obj.Receive) then return end
	
	if DPP.CanProperty(ply, name, ent) == false then return end
	if not obj:Filter(ent, ply) then return end
	
	local oldReadEntity = net.ReadEntity
	
	function net.ReadEntity()
		net.ReadEntity = oldReadEntity
		local oldEnt = oldReadEntity() --Call the old function to proceed message correctly
		
		if oldEnt ~= ent then
			SimpleLog(RED, 'ATTENTION ', GRAY, string.format('I don\'t really know, is that hacks or not, but player opened property menu on %s, but server received that target entity is %s. ', tostring(ent), tostring(oldEnt)), 'Player ', ply, color_white, '<' .. ply:SteamID() .. '>')
		end

		return ent
	end
	
	xpcall(obj.Receive, NetMessageErr, obj, len, ply)
	
	net.ReadEntity = oldReadEntity
end

function DPP.ReplaceFunctions()
	DPP.Message('Overriding server functions.')
	
	DPP.OverrideGMODEntity()
	DPP.OverrideE2()
	
	cleanup.Add = cleanup_Add
	undo.Finish = undo_Finish
	
	DPP._OldPropertiesReceive = DPP._OldPropertiesReceive or net.Receivers.properties
	
	net.Receive("properties", ReceiveProperty)
	net.Receive("properties_dpp", ReceiveProperty_DPP)
end

timer.Simple(0, DPP.ReplaceFunctions)

local EmptyVector = Vector(0, 0, 0)

function DPP.HandleTakeDamage(ent, dmg)
	if ent:IsPlayer() then return end
	local a = dmg:GetAttacker()
	if not IsValid(a) then return end
	
	local reply
	
	if a:IsPlayer() then
		reply = DPP.CanDamage(a, ent)
	elseif a:IsNPC() then
		local owner = DPP.GetOwner(a)
		if not IsValid(owner) then return end
		reply = DPP.CanDamage(owner, ent)
	end
	
	if reply ~= false then return end
	
	dmg:SetDamage(0)
	dmg:SetDamageForce(EmptyVector)
	dmg:SetDamageBonus(0)
	dmg:SetDamageType(0)
	local isOnFire = ent:IsOnFire()
	
	timer.Simple(0.1, function()
		if IsValid(ent) and not isOnFire then
			ent:Extinguish() --Prevent burning weapons
		end
	end)
	
	return false
end

hook.Add('EntityTakeDamage', 'DPP.Hooks', DPP.HandleTakeDamage, -2)

function DPP.CheckDroppedStuck(ply, ent)
	if not DPP.GetConVar('check_stuck') then return end
	
	--I think if entity have MOVETYPE_NONE it can not create lags because moving is not calculated
	if ent:GetSolid() == SOLID_NONE then return end
	if ent:GetMoveType() == MOVETYPE_NONE then return end
	
	for k, v in pairs(ents.FindInSphere(ent:GetPos(), 32)) do
		if v:IsPlayer() then continue end
		if DPP.GetGhosted(v) then continue end
		if DPP.CheckStuck(ply, ent, v) then break end
	end
end

hook.Add('PhysgunDrop', 'DPP.PreventPropStuck', DPP.CheckDroppedStuck)

local function OnPhysgunReload(weapon, ply)
	local ent = ply:GetEyeTrace().Entity
	if not IsValid(ent) then return end
	
	if DPP.GetConVar('disable_unfreeze') then
		DPP.Notify(ply, 'Physgun reload is disabled on this server', NOTIFY_ERROR)
		return false
	end
	
	ply.DPP_LastUnfreezeTry = ply.DPP_LastUnfreezeTry or 0
	
	if ply.DPP_LastUnfreezeTry > CurTime() then
		DPP.Notify(ply, 'You must wait ' .. math.floor(ply.DPP_LastUnfreezeTry - CurTime()) .. ' seconds before trying to unfreeze again', NOTIFY_ERROR)
		return false
	end
	
	if DPP.GetConVar('unfreeze_antispam') then
		ply.DPP_LastUnfreezeTry = CurTime() + DPP.GetConVar('unfreeze_antispam_delay')
	end
	
	if not DPP.GetConVar('unfreeze_restrict') then return end
	local num = DPP.GetConVar('unfreeze_restrict_num')
	
	local result = DPP.RecalcConstraints(ent)
	if #result <= num then return end
	
	local i = 0
	
	for k, v in ipairs(result) do
		if DPP.IsConstraint(v) then continue end
		i = i + 1
	end
	
	if i > num then
		ply.DPP_LastUnfreezeTry = CurTime() + math.Clamp(i / 5, math.min(DPP.GetConVar('unfreeze_antispam_delay'), 5), 15)
		DPP.Notify(ply, 'Unable to unfreeze: You are trying un freeze ' .. i .. ' entities (' .. num .. ' max)!', NOTIFY_ERROR)
		return false
	end
end

hook.Add('OnPhysgunReload', 'DPP.BlockReload', OnPhysgunReload)
