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
ClientCast.InitiatedCasters = {}
ClientCast.WhitelistedIds = {};

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

	ClientCast.WhitelistedIds[self.Caster._UniqueId] = Owner;

	ReplicationRemote:FireClient(Owner, 'Start', {
		Owner = Owner,
		Object = self.Object,
		Debug = self.Caster._Debug,
		RaycastParams = SerializeParams(self.RaycastParams),
		Id = self.Caster._UniqueId
	})
end

shared.RemoteHandler.AddConnection('Replication', function(Player, UniqueId, Code, Part, Position, Humanoid)
	if (not Player.Character) then return end;

	if ClientCast.WhitelistedIds[UniqueId] == Player and (Code == 'Any' or Code == 'Humanoid') and (ClientCast.InitiatedCasters[UniqueId]) then
		local Caster;

		if (typeof(Position) ~= 'Vector3int16' or typeof(Part) ~= 'Instance') then return end;
		if (not Part:IsA('BasePart')) then return end;

		local PlayerPosition = Player.Character.HumanoidRootPart.Position;
		local Extra = 10; --// Give em lenience!
		local Object = ClientCast.InitiatedCasters[UniqueId];

		local Given = Vector3.new(Position.X, Position.Y, Position.Z);
		local GivenPosition = (PlayerPosition + Given);

		local GivenDistance = ((PlayerPosition - GivenPosition).Magnitude + Object.Object.Size.Magnitude)
		local ActualDistance = ((PlayerPosition - Object.Object.Position).Magnitude + Object.Object.Size.Magnitude + Extra)

		if (GivenDistance > ActualDistance) then
			return
		end
		
		Humanoid = Code == 'Humanoid' and Humanoid or nil
		for Event in next, Object._CollidedEvents[Code] do
			task.spawn(Event.Invoke, Event, Part, GivenPosition, Humanoid)
		end
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

	ClientCast.WhitelistedIds[self.Caster._UniqueId] = nil;

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
	
	ClientCast.WhitelistedIds[Caster._UniqueId] = Player;

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

function ClientCaster:Start()
	self.Disabled = false

	self.Raycast.RaycastParams = self.RaycastParams;

	self.RaycastConnection = self.Raycast.OnHit:Connect(function(part, humanoid, raycastResult, groupName)
		if raycastResult then
			for CollisionEvent in next, self._CollidedEvents.Any do
				CollisionEvent:Invoke(raycastResult.Part, raycastResult.Position)
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

	self.Raycast:Destroy()
	ClientCast.InitiatedCasters[self._UniqueId] = nil;

	for Prop, Val in next, self do
		if type(Val) == 'function' then
			self[Prop] = function() end
		end
	end
end

function ClientCaster:Stop()
	local OldConn = self._ReplicationConnection
	if OldConn then
		OldConn:Stop()
	end

	self.Raycast:HitStop();

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
	local ReplicationConnection = self._ReplicationConnection
	if ReplicationConnection then
		local Remainder = time() - self._Created

		task.spawn(function()
			if Remainder < 1 then
				wait(1 - Remainder)
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