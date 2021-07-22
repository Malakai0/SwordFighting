local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Component = require(Knit.Util.Component)

Knit.AddControllers(script.Parent.Controllers);

Knit.Modules = {}
for _,v in next, script.Parent.ClientModules:GetChildren() do
    if (v:IsA('ModuleScript')) then
        Knit.Modules[v.Name] = require(v)
    end
end

Knit.Shared = {}
for _,v in next, game:GetService('ReplicatedStorage').Modules:GetChildren() do
    if (v:IsA('ModuleScript')) then
        Knit.Shared[v.Name] = require(v)
    end
end

Knit.Start():Then(function()
    print('Client started!')
    Component.Auto(script.Parent.ClientComponents)

    print(string.format((
        '\nWelcome to %s! Running on version %s.\n' ..
        'Exploiting is strictly prohibited, if caught exploiting, you will be permanently banned.\n' ..
        'Please report any and all bugs you find to the devs! Have fun!'
    ), Knit.Shared.ServerInfo.GameName, Knit.Shared.ServerInfo.Version))
end):Catch(warn);