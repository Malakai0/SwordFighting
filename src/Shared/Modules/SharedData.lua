local SharedData = {}

local Cfr = CFrame.new;
local Angle = CFrame.Angles;
local Rad = math.rad;

local CommonValues = {
    SheathAngle = Angle(Rad(0), Rad(-90), Rad(-15));
}

--// These offsets are kind of ugly, but it's col.
SharedData.Offsets = {

    -- Right Arm -> Hitbox - Equipped
    ['RightArmSword'] = Cfr(-0.25, -1, -2) * Angle(Rad(0), Rad(90), Rad(0));

    -- Torso -> Sheath - Always
    ['TorsoSheath'] = Cfr(-1, -1, 1.5) * CommonValues.SheathAngle;

    -- Hitbox -> Sheath - Unequipped
    ['SwordSheath'] = Cfr(1, 0, 0);

    -- Torso -> Hitbox - Unequipped
    ['TorsoSword'] = Cfr(-1, -0.9, 0.5) * CommonValues.SheathAngle;

}

SharedData.AnimationStates = {
    Active = 0;
    Inactive = 1;
}

SharedData.BaseDamageValues = {
    ['NormalAttack'] = {
        ['Head'] = 40;
        ['Torso'] = 30;
        ['Arm'] = 25;
        ['Leg'] = 25;
    };
}

function SharedData.GetLimbTypeFromInstance(Limb: Instance)
    local LimbName = tostring(Limb.Name):lower()
    return  LimbName:find('arm') and 'Arm' or
            LimbName:find('leg') and 'Leg' or
            LimbName:find('head') and 'Head' or
            LimbName:find('torso') and 'Torso' or
            LimbName:find('rootpart') and 'Torso';
end

function SharedData.GenerateHitData(Key, Attacker, Recipient, Damage)

end

return SharedData