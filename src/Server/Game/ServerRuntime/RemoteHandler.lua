local module = {}

module.NumEventHandlers = 10; --// Number of event handlers. Reduces remote throttling.

module.Called = {};

module.Remotes = {};

module.Connections = {};

module.Info = {
	PlayerEventKeys  = {};
	PlayerTickets    = {};
	PlayerUsableKeys = {};
}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local FakeRemotes = ReplicatedStorage:WaitForChild'Remotes'

local SharedModules = ReplicatedStorage:WaitForChild('MainModules')
local SharedRemote = SharedModules:WaitForChild'Remote'
local Hashing = require(SharedModules.Hashing)
local MD5 = require(SharedModules.MD5)
local Promise = require(SharedModules.Promise)

local function DecodeValue(Player, Value, Recursive)

	local Invalid = Value[1] and type(Value[1]) ~= 'string'
	if ((not Value[1]) or (Invalid)) then
		Player:Kick('Error Code 1')
	end

	if (not Value[4]) then
		return; --// Prone to failure when passing instances, no kicking necessary.
	end

	local TypeString = MD5.Decode(Value[1])

	local Whitelist = {'string','boolean','number','table'};

	if (table.find(Whitelist, TypeString)) then

		if (TypeString == 'table') then
			return Recursive(Player, Value[4]);
		else

			if (type(Value[4]) ~= 'string') then
				Player:Kick('Error Code 3')
			end

			if (not Value[4]:find('^')) then
				Player:Kick('Error Code 4')
			end

			local DecodedValue = MD5.Decode(Value[4]:split('^')[2])

			if (TypeString == 'string') then
				return DecodedValue
			elseif (TypeString == 'number') then
				return tonumber(DecodedValue)
			elseif (TypeString == 'boolean') then
				return DecodedValue == 'true'
			end

		end
	else
		return Value[4]
	end
end

local function DecodeData(Player, Args)
	local Data = {};

	for index = 1, #Args do
		local Value = Args[index]
		if (Value) then
			Data[index] = DecodeValue(Player, Value, DecodeData)
		end
	end

	return Data
end

function module.GetClientExposedKeys(Player)
	local Keys = {}
	for Key, Event in next, module.Info.PlayerEventKeys[Player] do
		if Event then
			Keys[Event] = Key
		end
	end
	return Keys;
end

function module.GetValidKey(ProjectedTime)
	local RemoteLib = require(SharedRemote)
	local Clock = RemoteLib:DynamicClock(ProjectedTime)

	--// While this key is shared on the client/server, it is only the first layer of protection.
	return (Clock * 5.343 % 50) * 2.21243;
end

function module.GenerateName(Name)
	return Name .. module.GetValidKey();
end

function module.CheckCall(Player, Key)
	local SecondsOutOfSync = math.abs(module.GetValidKey(tick()) - Key);
	if (SecondsOutOfSync < 25) then
		return true
	else
		warn(string.format('%s is out of sync.', Player.Name));
		return false
	end
end

function module.GrabEvent(Player, EventKey)
	return module.Info.PlayerEventKeys[Player][EventKey] or
		module.Info.PlayerUsableKeys[Player][EventKey];
end

function module.CreateRemote(Name, Callback, Type)

	Promise.new(function(resolve)

		Type = Type or 'RemoteFunction'
		local Remote = Instance.new(Type)

		if (Type == 'RemoteFunction') then
			Remote.OnServerInvoke = Callback
		else
			Remote.OnServerEvent:Connect(Callback)
		end

		Remote.Name = Hashing.SHA256(module.GenerateName(Name))
		Remote.Parent = SharedRemote;

		module.Remotes[Name] = Remote;

		resolve()
	end)

end

function module.FireClient(Player, Name, ...)
	module.Remotes.CLIENT:FireClient(Player, Name, ...);
end

function module.FireAllClients(Name, ...)
	module.Remotes.CLIENT:FireAllClients(Name, ...)
end

function module.AddConnection(Name, Function)
	task.spawn(function()
		--// Designed to trick exploiters.
		if (not FakeRemotes:FindFirstChild(Name)) then
			local FakeRemote = Instance.new('RemoteFunction')
			FakeRemote.Name = Name;
			FakeRemote.OnServerInvoke = (function(Player)
				Player:Kick("Invalid remote call.")
			end)
			FakeRemote.Parent = FakeRemotes
		end
	end)

	module.Connections[Name] = Function;

	for Index, _ in next, module.Info.PlayerEventKeys do
		local randomizedKey = tostring(math.random()*150000)
		local Encrypted = Hashing.SHA256(randomizedKey);
		module.Info.PlayerEventKeys[Index][Encrypted:sub(1, 12)] = Name;

		Promise.async(function(resolve, reject)
			local new_tbl = module.GetClientExposedKeys(Index)
			local ok, res = pcall(module.FireClient, Index, 'CON', new_tbl)
			if (ok) then
				resolve(res)
			else
				reject(res)
			end
		end):catch(function(err)
			warn('Failed to update client keys: ', err);
		end)
	end
end

function module.UpdateEvent(Player, Event)
	if (not module.Info.PlayerEventKeys[Player]) then
		module.Info.PlayerEventKeys[Player] = {}
		module.Info.PlayerUsableKeys[Player] = {}
	end

	local RandomKey = tostring(math.random()*150000)
	local EncryptedKey = Hashing.SHA256(RandomKey):sub(1, 12)

	--table.insert(module.Info.PlayerEventKeys[Player], EncryptedKey)
	module.Info.PlayerEventKeys[Player][EncryptedKey] = Event;
	module.Info.PlayerUsableKeys[Player][EncryptedKey] = Event;

	return EncryptedKey;
end

function module.UpdateAndApplyEvent(Player, Event)
	local EncryptedKey = module.UpdateEvent(Player, Event)

	local Count = 0;
	local KeyIndex;
	for Index, Key in next, module.Info.PlayerUsableKeys[Player] do
		if Key ~= nil then
			KeyIndex = Index
		end
		Count += 1
	end

	if (Count > 100) then
		module.Info.PlayerUsableKeys[KeyIndex] = nil;
	end

	return EncryptedKey
end

function module.AddPlayerTicket(Player, Event)
	if (not module.Info.PlayerTickets[Player]) then
		module.Info.PlayerTickets[Player] = {}
	end

	local ID = game:GetService("HttpService"):GenerateGUID(false)
	module.Info.PlayerTickets[Player][ID] = Event

	return ID;
end

function module.GetPlayerTicket(Player, TicketID)
	if (not module.Info.PlayerTickets[Player]) then
		return
	end

	return module.Info.PlayerTickets[Player][TicketID]
end

function module.EventFunction(RemoteKey, Player, Arguments)
	if (type(Arguments) ~= 'table') then return end;

	Arguments = DecodeData(Player, Arguments)
	local EventName, Key = Arguments[1], Arguments[2];

	if (typeof(Key) ~= 'number') then return end;

	if (module.CheckCall(Player, Key)) then
		local ActualEvent = module.GrabEvent(Player, EventName)

		local Cancel = false;

		if (not ActualEvent) then
			warn('Failed to find player key: ' .. tostring(EventName))
			Cancel = true;
		end

		if (not Cancel and not module.Connections[ActualEvent]) then
			warn('Invalid event name for player: ' .. ActualEvent);
			Cancel = true;
		end

		if (Cancel) then
			return 'FAILED'
		end

		module.Info.PlayerEventKeys[Player][EventName] = nil;
		local UpdatedKey = module.UpdateAndApplyEvent(Player, ActualEvent)

		table.remove(Arguments, 1);table.remove(Arguments, 1);

		return 'SUCCESS', UpdatedKey, module.Connections[ActualEvent](Player, unpack(Arguments))
	else
		warn('Invalid call by ' .. Player.Name)
	end

	return 'FAILED', EventName
end

function module.Initialize()

	Promise.new(function(resolve, reject)
		local Function = Instance.new('RemoteFunction')
		Function.Name = 'Ping'
		Function.OnServerInvoke = function(player, optional_argument)
			if (optional_argument == MD5.Encode('#ChariotAntiCheat'):sub(1,6)) then
				return module.NumEventHandlers;
			end
			return tick()
		end;
		Function.Parent = FakeRemotes;
		resolve()
	end)

	for i = 1, module.NumEventHandlers do
		local Key = 'EVENT' .. i;
		module.CreateRemote(Key, function(...)
			return module.EventFunction(Key, ...)
		end)
	end

	module.CreateRemote('TICKET', function(Player, Arguments)
		if (type(Arguments) ~= 'table') then return end;

		Arguments = DecodeData(Player, Arguments)

		if (#Arguments < 1) then
			return;
		end

		local TicketID = Arguments[1]

		if (TicketID == 'CON') then
			if (module.Called[Player]) then
				Player:Kick('Error Code 5')
			else
				module.Called[Player] = true;
				for Name, _ in next, module.Connections do
					module.UpdateEvent(Player, Name);
				end

				return module.GetClientExposedKeys(Player);
			end
		end
	end)

	module.CreateRemote('CLIENT', function(Player)
		Player:Kick('Error Code 6')
	end, 'RemoteEvent'); -- Client Connections.

	game:GetService("Players").PlayerAdded:Connect(function(Player: Player)

		repeat task.wait() until Player.Character or Player.CharacterAdded:Wait();

		for Name, _ in next, module.Connections do
			module.UpdateEvent(Player, Name);
		end

		module.FireClient(Player, 'CON', module.GetClientExposedKeys(Player))
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(Player: Player)
		for _, TBL in next, module.Info do
			if (TBL[Player]) then
				TBL[Player] = nil
			end
		end
	end)

	Promise.async(function()
		while task.wait(.5) do
			for Name, Remote in next, module.Remotes do
				Remote.Name = Hashing.SHA256(module.GenerateName(Name));
			end
		end
	end):catch(function(err)
		warn('Error changing remote names: ', err);
	end)

end

function module.ImpenetrableAntiCheat()
	local ServiceIterator = function()
		local Index = 0;
		local Services = {
			'Workspace', 'ReplicatedStorage', 'StarterGui', 'StarterPack', 'Players', 'SoundService',
			'Lighting', 'Teams', 'StarterPlayer', 'ReplicatedFirst'
		}

		local function Iterate()
			Index = Index + 1;
			return Services[Index]
		end

		return Iterate
	end


	for Service in ServiceIterator() do
		local Success, ServiceInstance = pcall(game.GetService, game, Service)
		if (Success) then
			ServiceInstance.Name = math.random()
		end
	end
end

return module