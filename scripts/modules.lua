-- Loads all modules

modules = {
	"util",
	"events",

	"init",
	"extra_animations",
	"sit",
	"sleep",
	"emotes",
	"elytra",
	"armor",
	"ears",
	"tail",
	"eyes",
	"rope", -- "hair",

	host:isHost() and "camera" or nil,
	host:isHost() and "action_wheel" or nil,
	host:isHost() and "action_wheel_icons" or nil,
	host:isHost() and "better_first_person" or nil,
}



-- Module loader
for _, file in ipairs(modules) do
	modules[file] = require("scripts/modules/" .. file)
end
