wait() -- Necessary wait because the Parent property is locked for a split moment
local ThisScript = script -- script.Parent = x makes selene mad :Z
ThisScript.Parent = game:GetService('Players').LocalPlayer:FindFirstChildOfClass('PlayerScripts')

local RCHB = require(ThisScript:WaitForChild'RaycastHitboxV4');

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local ReplicationRemote = ReplicatedStorage:WaitForChild('ClientCast-Replication')
local PingRemote = ReplicatedStorage:WaitForChild('ClientCast-Ping')

PingRemote.OnClientInvoke = function() end

local ClientCast = {}
local Settings = {
	AttachmentName = 'HitPoint', -- The name of the attachment that this network will raycast from
	DebugAttachmentName = 'ClientCast-Debug', -- The name of the debug trail attachment

	DebugMode = false, -- DebugMode visualizes the rays, from last to current position
	DebugColor = Color3.new(1, 0, 0), -- The color of the visualized ray
	DebugLifetime = 1, -- Lifetime of the visualized trail
}

ClientCast.Settings = Settings
ClientCast.InitiatedCasters = {}

local TrailTransparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 1)
})
local AttachmentOffset = Vector3.new(0, 0, 0.1)

local Signal = require(script.Signal)

local function AssertType(Object, ExpectedType, Message)
	if typeof(Object) ~= ExpectedType then
		error(string.format(Message, ExpectedType, typeof(Object)), 3)
	end
end

local function SerializeResult(Result)
	return {
		Instance = Result.Instance,
		Position = Result.Position,
		Material = Result.Material,
		Normal = Result.Normal
	}
end

local function DeserializeParams(Input)
	local Params = RaycastParams.new()
	for Key, Value in next, Input do
		if Key == 'FilterType' then
			Value = Enum.RaycastFilterType[Value]
		end
		Params[Key] = Value
	end

	return Params
end

local ClientCaster = {}

local CollisionBaseName = {
	Collided = 'Any',
	HumanoidCollided = 'Humanoid'
}

local limiter = {};

function ClientCaster:Start()
	self.Disabled = false

	self.Raycast.RaycastParams = self.RaycastParams

	self.Raycast.OnHit:Connect(function(part, humanoid, raycastResult, groupName)
		if (not limiter[part]) then
			limiter[part] = 0;
		end
		if raycastResult and (tick() - limiter[part] >= 0.05) then
			limiter[part] = tick();

			local Character = game:GetService'Players'.LocalPlayer.Character
			if (not Character) then return end;
			local Relative = Character.HumanoidRootPart.Position - raycastResult.Position;
			if (Relative.Magnitude > 32767 or Relative.Magnitude < -32768) then return end;
			local Position = Vector3int16.new(Relative.X, Relative.Y, Relative.Z);

			shared.Fire('Replication', self.Id, 'Any', part, Position);

			local ModelAncestor = part:FindFirstAncestorOfClass('Model')
			local Humanoid = ModelAncestor and ModelAncestor:FindFirstChildOfClass('Humanoid')
			if Humanoid then
				shared.Fire('Replication', self.Id, 'Humanoid', part, Position, Humanoid);
			end
		end
	end)

	self.Raycast:HitStart();
end

function ClientCaster:Destroy()
	self.Disabled = true

	self.Raycast:Destroy();
end
function ClientCaster:Stop()
	self.Disabled = true

	self.Raycast:HitStop();
end
function ClientCaster:__index(Index)
	local CollisionIndex = CollisionBaseName[Index]
	if CollisionIndex then
		local CollisionEvent = Signal.new()
		self._CollidedEvents[CollisionIndex][CollisionEvent] = true

		return CollisionEvent.Invoked
	end

	return rawget(ClientCaster, Index)
end

function ClientCast.new(Object, RaycastParameters, Id)
	AssertType(Object, 'Instance', 'Unexpected argument #1 to \'CastObject.new\' (%s expected, got %s)')

	local HitboxObject = RCHB.new(Object);
	HitboxObject.DetectionMode = 2
	HitboxObject.RaycastParams = RaycastParameters;

	return setmetatable({
		Raycast = HitboxObject;

		RaycastParams = RaycastParameters,
		Object = Object,
		Disabled = true,
		Recursive = false,

		_CollidedEvents = {
			Humanoid = {},
			Any = {}
		},
		_DamagePoints = {},
		_Debug = false,
		_ToClean = {},
		_DebugTrails = {},
		Id = Id;
	}, ClientCaster)
end

local ClientCasters = {}

ReplicationRemote.OnClientEvent:Connect(function(Status, Data, AdditionalData)
	if Status == 'Start' then
		local Caster = ClientCasters[Data.Id]

		if not Caster then
			Caster = ClientCast.new(Data.Object, DeserializeParams(Data.RaycastParams), Data.Id)

			ClientCasters[Data.Id] = Caster
			Caster._Debug = Data.Debug
		end
		Caster:Start()

	elseif Status == 'Destroy' then
		local Caster = ClientCasters[Data.Id]

		if Caster then
			Caster:Destroy()
			Caster = nil
			ClientCasters[Data.Id] = nil
		end

	elseif Status == 'Stop' then
		local Caster = ClientCasters[Data.Id]

		if Caster then
			Caster:Stop()
		end
	elseif Status == 'Update' then
		local Caster = ClientCasters[Data.Id]

		if Caster then
			for Name, Value in next, AdditionalData do
				if Name == 'Object' then
					Caster:SetObject(Value)
				elseif Name == 'Debug' then
					
				else
					Caster[Name] = Value
				end
			end
		end
	end
end)