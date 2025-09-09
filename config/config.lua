Config = {}

Config.Debug = true              -- Enable debug prints

Config.RequireMeleeWeapon = true -- Require a melee weapon to slash tires

Config.Blades =                  -- List of weapons that can slash tires
{
	`WEAPON_KNIFE`,
	`WEAPON_SWITCHBLADE`,
	`WEAPON_BOTTLE`,
	`WEAPON_DAGGER`,
	`WEAPON_MACHETE`,
	`WEAPON_HATCHET`,
}

Config.ActionMs = 3000       -- Time it takes to slash a tire in milliseconds

Config.SlashDistance = 2.5   -- Distance to slash tires

Config.PoliceRequired = 0    -- Number of police required to slash tires

Config.SlashableVehicles = { -- List of vehicles that can have their tires slashed, leave empty to allow all vehicles
	"car",
	"bike",
	"bicycle",
	"boat",
	"heli",
	"plane",
	"train"
}

Config.WHEEL_BONES = {
	"wheel_lf", -- Left Front
	"wheel_rf", -- Right Front
	"wheel_lr", -- Left Rear
	"wheel_rr", -- Right Rear
	"wheel_lm", -- Left Middle (if applicable)
	"wheel_rm" -- Right Middle (if applicable)
}

Config.BONE_TO_TYRE = {
	["wheel_lf"] = 0, --bike front as well
	["wheel_rf"] = 1,
	["wheel_lm"] = 2,
	["wheel_rm"] = 3,
	["wheel_lr"] = 4, --bike rear as well
	["wheel_rr"] = 5,
}

Config.HoverTextEnabled = true                      -- Enable hover text on target
Config.HoverText = "Pinchar Rueda"                  -- Hover text to display on target
Config.TargetDistance = Config.SlashDistance or 2.5 -- Distance for target interaction
