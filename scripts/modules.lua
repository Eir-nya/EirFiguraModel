-- Loads all modules

modules = {
	"util",
	"init",
	"events",
	"sync",
	"vertexes",

	"nameplate",
	"animations",
	"extra_animations",
	"sit",
	"sleep",
	"emotes",
	"elytra",
	"clothes",
	"armor",
	"ears",
	"tail",
	"eyes",
	"rope",
	"hair",

	"modelOffset",
	"vanilla_transforms",
	"thighs",

	host:isHost() and "camera" or nil,
	host:isHost() and "action_wheel" or nil,
	-- host:isHost() and "action_wheel_icons" or nil,
	host:isHost() and "better_first_person" or nil,
}



-- Module loader
for _, file in ipairs(modules) do
	modules[file] = require("scripts/modules/" .. file)
end
