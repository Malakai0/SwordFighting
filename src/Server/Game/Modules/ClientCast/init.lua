local ClientCast = {}
local Settings = {
	AttachmentName = 'HitPoint', -- The name of the attachment that this network will raycast from
	DebugAttachmentName = 'ClientCast-Debug', -- The name of the debug trail attachment

	FunctionDebug = false,
	DebugMode = true, -- DebugMode visualizes the rays, from last to current position
	DebugColor = Color3.new(1, 0, 0), -- The color of the visualized ray
	DebugLifetime = 1, -- Lifetime of the visualized trail
	AutoSetup = true -- Automatically creates a LocalScript and a RemoteEvent to establish a connection to the server, from the client.
}

if Settings.AutoSetup then
	require(script.ClientConnection)(ClientCast)
end

ClientCast.Settings = Settings
ClientCast.InitiatedCasters = {};
ClientCast.WhitelistedIds = {};
ClientCast.CasterDetectionCooldowns = {};
ClientCast.CompensationCasters = {}; -- for laggier players.

local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ReplicationRemote = ReplicatedStorage:FindFirstChild('ClientCast-Replication')
local PingRemote = ReplicatedStorage:FindFirstChild('ClientCast-Ping')

local Signal = require(script.Signal)
local Wait = require(script.RBXWait)
local RCHB = require(script.RaycastHitboxV4);

local function SafeRemoteInvoke(RemoteFunction, Player, MaxYield)
	local ThreadResumed = false
	local Thread = coroutine.running()

	coroutine.wrap(function()
		local TimestampStart = time()
		RemoteFunction:InvokeClient(Player)
		local TimestampEnd = time()

		ThreadResumed = true
		coroutine.resume(Thread, math.min(TimestampEnd - TimestampStart, MaxYield))
	end)()

	coroutine.wrap(function()
		Wait(MaxYield * 2)
		if not ThreadResumed then
			ThreadResumed = true
			coroutine.resume(Thread, MaxYield)
		end
	end)()
	-- Divide by 2 because this is a two-way trip: server → client → server
	return coroutine.yield() / 2
end

local function SerializeParams(Params)
	return {
		FilterDescendantsInstances = Params.FilterDescendantsInstances,
		FilterType = Params.FilterType.Name,
		IgnoreWater = Params.IgnoreWater,
		CollisionGroup = Params.CollisionGroup
	}
end
local function IsA(Object, Type)
	return typeof(Object) == Type
end
local function AssertType(Object, ExpectedType, Message)
	if not IsA(Object, ExpectedType) then
		error(string.format(Message, ExpectedType, typeof(Object)), 4)
	end
end
local function AssertClass(Object, ExpectedClass, Message)
	AssertType(Object, 'Instance', Message)
	if not Object:IsA(ExpectedClass) then
		error(string.format(Message, ExpectedClass, Object.Class), 4)
	end
end
local function AssertNaN(Object, Message)
	if Object ~= Object then
		error(string.format(Message, 'number', typeof(Object)), 4)
	end
end
local function IsValidOwner(Value)
	local IsInstance = IsA(Value, 'Instance')
	if not IsInstance and Value ~= nil then
		error('Unable to cast value to Object', 4)
	elseif IsInstance and not Value:IsA('Player') then
		error('SetOwner only takes player or \'nil\' instance as an argument.', 4)
	end
end
local function IsValid(SerializedResult)
	if not IsA(SerializedResult, 'table') then
		return false
	end

	return (SerializedResult.Instance == nil or SerializedResult.Instance:IsA('BasePart') or SerializedResult.Instance:IsA('Terrain')) and
		IsA(SerializedResult.Position, 'Vector3') and
		IsA(SerializedResult.Material, 'EnumItem') and
		IsA(SerializedResult.Normal, 'Vector3')
end

local Replication = {}
local ReplicationBase = {}
ReplicationBase.__index = ReplicationBase

function ReplicationBase:Start()
	local Owner = self.Owner
	AssertClass(Owner, 'Player')

	ReplicationRemote:FireClient(Owner, 'Start', {
		Owner = Owner,
		Object = self.Object,
		Debug = self.Caster._Debug,
		RaycastParams = SerializeParams(self.RaycastParams),
		Id = self.Caster._UniqueId,
		HitCool = self.HitCooldown
	})
end

shared.RemoteHandler.AddConnection('Replication', function(Player, UniqueId, Code, Part, Position, Humanoid)
	if (not Player.Character) then return end;
	if (not UniqueId or not Code or not Part or not Position) then return end;
	if (typeof(Position) ~= 'Vector3int16' or typeof(Part) ~= 'Instance') then return end;
	if (not Part:IsA('BasePart')) then return end;

	local OnCool = false;

	local Caster = ClientCast.InitiatedCasters[UniqueId];
	if (not Caster) then return end;

	local HasCooldown = ClientCast.CasterDetectionCooldowns[UniqueId] ~= nil;

	if (HasCooldown and Caster.HitCool) then
		OnCool = tick() - (ClientCast.CasterDetectionCooldowns[UniqueId][Player.UserId] or -math.huge) < Caster.HitCool;
	end

	local ValidCode = (Code == 'Any' or Code == 'Humanoid');
	local isWhitelisted = table.find(ClientCast.WhitelistedIds, UniqueId);

	if isWhitelisted and ValidCode and (not OnCool) then
		local PlayerPosition = Player.Character.HumanoidRootPart.Position;
		local Extra = 10; --// Give em lenience!

		local GivenOffset = Vector3.new(Position.X, Position.Y, Position.Z);
		local GivenPosition = (PlayerPosition + GivenOffset);

		local Object = Caster.Object;

		local GivenDistance = (GivenOffset.Magnitude + Object.Size.Magnitude)
		local ActualDistance = ((PlayerPosition - Object.Position).Magnitude + Object.Size.Magnitude)

		if (GivenDistance > ActualDistance + Object.Velocity.Magnitude + Extra) then
			return
		end

		if (ActualDistance - GivenDistance > 20) then
			return
		end

		if (HasCooldown) then
			ClientCast.CasterDetectionCooldowns[UniqueId][Player.UserId] = tick();
		end
		
		Humanoid = Code == 'Humanoid' and Humanoid
		for Event in next, Caster._CollidedEvents[Code] do
			task.spawn(Event.Invoke, Event, Part, GivenPosition, Humanoid)
		end
	elseif (not isWhitelisted) then
		warn(string.format('%s sent invalid whitelist (%s).', Player.Name, tostring(UniqueId)))
	end
end)

function ReplicationBase:Update(AdditionalData)
	local Data = {
		Owner = self.Owner,
		Object = self.Object,
		Debug = self.Caster._Debug,
		RaycastParams = SerializeParams(self.RaycastParams),
		Id = self.Caster._UniqueId
	}
	ReplicationRemote:FireClient(self.Owner, 'Update', Data, AdditionalData)
end
function ReplicationBase:Stop(Destroy)
	local Owner = self.Owner

	ReplicationRemote:FireClient(Owner, Destroy and 'Destroy' or 'Stop', {
		Owner = Owner,
		Object = self.Object,
		Id = self.Caster._UniqueId
	})

	local ReplicationConn = self.Connection
	if ReplicationConn then
		ReplicationConn:Disconnect()
		ReplicationConn = nil
	end

	if Destroy then
		table.clear(self)
		setmetatable(self, nil)
	end
end
function ReplicationBase:Destroy()
	self:Stop(true)
end

function Replication.new(Player, Object, RaycastParameters, Caster)
	AssertClass(Player, 'Player', 'Unexpected owner in \'ReplicationBase.Stop\' (%s expected, got %s)')
	assert(type(Caster) == 'table' and Caster._Class == 'Caster', 'Unexpect argument #4 - Caster expected')
	
	return setmetatable({
		Owner = Player,
		Object = Object,
		RaycastParams = RaycastParameters,
		Caster = Caster
	}, ReplicationBase)
end

local ClientCaster = {}

local TrailTransparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 1)
})
local AttachmentOffset = Vector3.new(0, 0, 0.1)

function ClientCaster:DisableDebug()
	local ReplicationConnection = self._ReplicationConnection

	if ReplicationConnection then
		ReplicationConnection:Update({
			Debug = false
		})
	end

	self._Debug = false
	for Trail in next, self._DebugTrails do
		Trail.Enabled = false
	end
end
function ClientCaster:StartDebug()
	local ReplicationConnection = self._ReplicationConnection

	if ReplicationConnection then
		ReplicationConnection:Update({
			Debug = true
		})
	end

	self._Debug = true
	for Trail in next, self._DebugTrails do
		Trail.Enabled = true
	end
end

local CollisionBaseName = {
	Collided = 'Any',
	HumanoidCollided = 'Humanoid'
}

function ClientCaster:Start(optional_hit_cooldown)
	self.Disabled = false

	if (optional_hit_cooldown) then
		ClientCast.CasterDetectionCooldowns[self._UniqueId] = {};
		self.HitCooldown = optional_hit_cooldown;
	end

	table.insert(ClientCast.WhitelistedIds, self._UniqueId);
	self.Raycast.RaycastParams = self.RaycastParams;

	self.RaycastConnection = self.Raycast.OnHit:Connect(function(part, humanoid, raycastResult, groupName)
		if raycastResult then
			for CollisionEvent in next, self._CollidedEvents.Any do
				task.spawn(CollisionEvent.Invoke, CollisionEvent, part, raycastResult.Position)
			end
	
			local ModelAncestor = part:FindFirstAncestorOfClass('Model')
			local Humanoid = ModelAncestor and ModelAncestor:FindFirstChildOfClass('Humanoid')
			if Humanoid then
				for HumanoidEvent in next, self._CollidedEvents.Humanoid do
					HumanoidEvent:Invoke(raycastResult.Part, raycastResult.Position, Humanoid)
				end
			end
		end
	end)

	local ReplicationConn = self._ReplicationConnection
	if ReplicationConn then
		ReplicationConn:Start()
	end
end

function ClientCaster:Destroy()
	local ReplicationConn = self._ReplicationConnection
	if ReplicationConn then
		self._ReplicationConnection = nil
		ReplicationConn:Destroy()
	end

	if (self.Raycast) then
		self.Raycast:Destroy()
	end

	-- Let clients catch up before fully removing the global reference to it.
	task.delay(3, function()
		ClientCast.CasterDetectionCooldowns[self._UniqueId] = nil;
		table.remove(ClientCast.WhitelistedIds, table.find(ClientCast.WhitelistedIds, self._UniqueId));
		ClientCast.InitiatedCasters[self._UniqueId] = nil;
	end)

	for Prop, Val in next, self do
		if type(Val) == 'function' then
			self[Prop] = function() end
		end
	end
end

function ClientCaster:Stop()

	if self.Disabled then
		return
	end

	local OldConn = self._ReplicationConnection
	if OldConn then
		OldConn:Stop()
	end

	self.Raycast:HitStop();
	
	local uniqueId = self._UniqueId;
	-- We're letting the client catch up here.
	task.delay(3, function()
		table.remove(ClientCast.WhitelistedIds, table.find(ClientCast.WhitelistedIds, uniqueId));
		ClientCast.CasterDetectionCooldowns[uniqueId] = nil;
	end)

	self.Disabled = true
end
function ClientCaster:SetOwner(NewOwner)
	local Remainder = time() - self._Created
	coroutine.wrap(function()
		if Remainder < 0.1 then
			wait(0.1 - Remainder)
		end

		IsValidOwner(NewOwner)
		local OldConn = self._ReplicationConnection
		local ReplConn = NewOwner ~= nil and Replication.new(NewOwner, self.Object, self.RaycastParams, self)
		self._ReplicationConnection = ReplConn

		if OldConn then
			OldConn:Destroy()
		end
		self.Owner = NewOwner

		if ClientCast.InitiatedCasters[self._UniqueId] then
			if NewOwner ~= nil and ReplConn then
				ReplConn:Start()
			end
		end
	end)()
end
function ClientCaster:GetOwner()
	return self.Owner
end
function ClientCaster:SetMaxPingExhaustion(Time)
	AssertType(Time, 'number', 'Unexpected argument #1 to \'ClientCaster.SetMaxPingExhaustion\' (%s expected, got %s)')
	AssertNaN(Time, 'Unexpected argument #1 to \'ClientCaster.SetMaxPingExhaustion\' (%s expected, got NaN)')
	if Time < 0.1 then
		error('The max ping exhaustion time passed to \'ClientCaster.SetMaxPingExhaustion\' must be longer than 0.1', 3)
		return
	end

	self._ExhaustionTime = Time
end
function ClientCaster:GetMaxPingExhaustion()
	return self._ExhaustionTime
end
function ClientCaster:GetPing()
	if self.Owner == nil then
		return 0
	end

	return SafeRemoteInvoke(PingRemote, self.Owner, self._ExhaustionTime)
end
function ClientCaster:GetObject()
	return self.Object
end
function ClientCaster:EditRaycastParams(RaycastParameters)
	self.RaycastParams = RaycastParameters
	self.Raycast.RaycastParams = RaycastParameters
	local ReplicationConnection = self._ReplicationConnection
	if ReplicationConnection then
		local Remainder = time() - self._Created

		task.spawn(function()
			if Remainder < 1 then
				task.wait(1 - Remainder)
			end
			ReplicationConnection:Update({
				RaycastParams = RaycastParameters
			})
		end)
	end
end
function ClientCaster:SetRecursive(Bool)
	AssertType(Bool, 'boolean', 'Unexpected argument #1 to \'ClientCaster.SetRecursive\' (%s expected, got %s)')
	self.Recursive = Bool

	local Remainder = time() - self._Created
	coroutine.wrap(function()
		if Remainder < 0.1 then
			wait(0.1 - Remainder)
		end

		local ReplicationConnection = self._ReplicationConnection
		if ReplicationConnection then
			ReplicationConnection:Update({
				Recursive = Bool
			})
		end
	end)()
end
function ClientCaster:__index(Index)
	local CollisionIndex = CollisionBaseName[Index]
	if CollisionIndex then
		local CollisionEvent = Signal.new()
		self._CollidedEvents[CollisionIndex][CollisionEvent] = true

		return CollisionEvent.Invoked
	end

	local Value = ClientCaster[Index]
	return (type(Value) == 'function' and not Settings.FunctionDebug) and coroutine.wrap(Value) or Value
end

local function GenerateId()
	local Ids = game:GetService("HttpService"):GenerateGUID(false):split('-');
	return Ids[#Ids];
end

function ClientCast.new(Object, RaycastParameters, NetworkOwner)
	IsValidOwner(NetworkOwner)
	AssertType(Object, 'Instance', 'Unexpected argument #2 to \'CastObject.new\' (%s expected, got %s)')
	AssertType(RaycastParameters, 'RaycastParams', 'Unexpected argument #3 to \'CastObject.new\' (%s expected, got %s)')
	local CasterObject

	local HB = RCHB.new(Object);
	HB.DetectionMode = 2
	HB.RaycastParams = RaycastParameters
	
	CasterObject = setmetatable({
		Raycast = HB;
		RaycastParams = RaycastParameters,
		Object = Object,
		Owner = NetworkOwner,
		Disabled = true,
		Recursive = false,

		_CollidedEvents = {
			Humanoid = {},
			Any = {}
		},
		_Created = time(),
		_ReplicationConnection = false,
		_Debug = Settings.DebugMode,
		_ExhaustionTime = 1,
		_UniqueId = GenerateId(),
		_Class = 'Caster'
	}, ClientCaster)

	ClientCast.InitiatedCasters[CasterObject._UniqueId] = CasterObject;

	CasterObject._ReplicationConnection = NetworkOwner ~= nil and
		Replication.new(NetworkOwner, Object, RaycastParameters, CasterObject)
	return CasterObject
end

return ClientCast