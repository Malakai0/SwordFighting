local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Component = require(Knit.Util.Component)

local RemoteHandler = require(script.RemoteHandler)
RemoteHandler.Initialize();
shared.RemoteHandler = RemoteHandler;

Knit.AddServices(script.Parent.Services);

Knit.Modules = {}
for _,v in next, script.Parent.Modules:GetChildren() do
    if (v:IsA('ModuleScript')) then
        Knit.Modules[v.Name] = require(v)
    end
end;

Knit.Shared = {}
for _,v in next, game:GetService('ReplicatedStorage').Modules:GetChildren() do
    if (v:IsA('ModuleScript')) then
        Knit.Shared[v.Name] = require(v)
    end
end

Knit.Start():Then(function()
    print('Server started!')
    Component.Auto(script.Parent.Components)

    print('Server running version ' .. Knit.Shared.ServerInfo.Version);
end):Catch(warn);