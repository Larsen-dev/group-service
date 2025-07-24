--[=[
Created by @Larsen264
	--GroupService--
	GroupService is a service used to create and handle groups of players.
	
	DEPENDECIES:
		- Knit
		- Promise
]=]

--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Modules.Knit.Packages.Knit) --Provide valid path to Knit
local Signal = require(Knit.Util.Signal)
local Promise = require(ReplicatedStorage.Modules.Promise) --Provide valid path to Promise

--Group
local Group = {}
Group.__index = Group

Group._members = {}
Group._owner = {}
Group.MemberAdded = {}
Group.MemberLeaved = {}
Group.OwnerChanged = {}
Group.Disbanding = {}

export type Group = {
	_members: {Player},
	_owner: Player,
	
	MemberAdded: Signal.Signal,
	MemberLeaved: Signal.Signal,
	OwnerChanged: Signal.Signal,
	Disbanding: Signal.Signal,
}

function Group:Disband()
	assert(not game:GetService("RunService"):IsClient(), "Can't use \"Group\" methods from client side.")
	
	self.Disbanding:Fire()
	
	Knit.OnStart():await()
	local GroupService = Knit.GetService("GroupService")
	
	GroupService[self._owner.UserId] = nil
	
	GroupService.GroupDisbanded:Fire(self)
	
	table.clear(self)
	self = nil
end

function Group:AddMember(member: Player)
	assert(not game:GetService("RunService"):IsClient(), "Can't use \"Group\" methods from client side.")
	assert(table.find(self._members, member) ~= nil, `Player: {member} is already a group's member.`)
	
	table.insert(self._members, member)
	
	Group.MemberAdded:Fire(member)
end

function Group:KickMember(member: Player)
	assert(not game:GetService("RunService"):IsClient(), "Can't use \"Group\" methods from client side.")
	assert(self._owner ~= member, "Impossible to kick the group's owner.")
	
	Promise.try(function()
		table.remove(self._members, table.find(self._members, member))
		
		Group.MemberLeaved:Fire(member)
	end):catch(function(errorMessage)
		warn(tostring(errorMessage))
	end)
end

function Group:TeleportGroup(placeId: number, teleportOptions: TeleportOptions)
	Promise.try(function()
		TeleportService:TeleportAsync(placeId, self._members, teleportOptions)
	end):catch(function(errorMessage)
		warn(tostring(errorMessage))
	end)
end

--Service
local GroupService = Knit.CreateService {
	Name = "GroupService",
	
	Client = {
		GroupCreated = Knit.CreateSignal(),
		GroupDisbanded = Knit.CreateSignal(),
	}
}
GroupService.GroupCreated = Signal.new()
GroupService.GroupDisbanded = Signal.new()
GroupService.Groups = {}

function GroupService:CreateGroup(owner: Player)
	assert(not game:GetService("RunService"):IsClient(), "Can't use \"Group\" methods from client side.")
	assert(self:GetGroupFromOwner(owner) == nil, `Player: {owner} already owns a group.`)
	
	local group = setmetatable(Group, {
		__index = function(_, key)
			error(string.format("%s is not valid member of group", key))
		end,		
		__newindex = function(_, key, value)
			error("Creating new members don't allowed!")
		end,
	}) :: Group
	group._members = {owner}
	group._owner = owner
	
	group.MemberAdded = Signal.new()
	group.MemberLeaved = Signal.new()
	group.OwnerChanged = Signal.new()
	group.Disbanding = Signal.new()
	GroupService.Groups[owner.UserId] = group
	
	return group
end

local function _getGroupFromOwner(owner)
	if Promise.try(function()
		return GroupService.Groups[owner.UserId]
	end):await() then
		return GroupService.Groups[owner.UserId]
	else
		return nil
	end
end

function GroupService:GetGroupFromOwner(owner): Group
	return _getGroupFromOwner(owner)
end

function GroupService.Client:GetGroupFromOwner(owner: Player): Group
	return self.Server:GetGroupFromOwner(owner)
end

function GroupService:GetGroupMembers(group: Group): {Player}
	return group._members
end

function GroupService.Client:GetGroupMembers(group: Group): {Player}
	return self.Server:GetGroupMembers(group)
end

function GroupService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		local playerGroup = self:GetGroupFromOwner(player)
		
		if playerGroup then
			playerGroup._owner = playerGroup._members[2]
			GroupService.Groups[player.UserId] = nil
			GroupService.Groups[playerGroup._owner.UserId] = playerGroup
			playerGroup.OwnerChanged:Fire(playerGroup._owner)
			
			playerGroup:KickMember(player)
		end
	end)
end

function GroupService:KnitStart()
	
end

return GroupService
