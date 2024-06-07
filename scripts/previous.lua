-- Stores the last-retrieved results of certain values from events

previous = {
	healthPercent = 0, -- Health percent from 0-1
	food = 0, -- Food from 0-20
	airPercent = 1, -- Air percent from 0-1
	xp = 0, -- XP levels + level progress from 0-1
	hurtTicks = 0, -- Hurt ticks
	freezeTicks = 0, -- Freeze ticks
	firstPerson = nil, -- First person

	vel = nil, -- Velocity
	velMagXZ = nil, -- Velocity magnitude (x/z only)
	lookDir = { x = 0, y = 0, z = 1}, -- Look direction

	-- Equipped items (stored as {id = string, tag = {}} or ItemStacks)
	mainItem = { id = "minecraft:bedrock" },
	offItem = { id = "minecraft:bedrock" },
	helmet = { id = "minecraft:bedrock" },
	chestplate = { id = "minecraft:bedrock" },
	leggings = { id = "minecraft:bedrock" },
	boots = { id = "minecraft:bedrock" },
	-- Equipped item stack strings (what actually gets compared)
	mainItemString = nil,
	offItemString = nil,
	helmetString = nil,
	chestplateString = nil,
	leggingsString = nil,
	bootsString = nil,

	elytra = nil, -- Elytra should be displayed
	elytraHide = false, -- An elytra is eqiupped, but the model one should be hidden
	elytraGlint = nil, -- Elytra is enchanted

	invisible = nil, -- Invisible from potion effect or spectator mode
	wet = nil, -- Wet (in water, bubble column, or rain)
	underwater = nil, -- Underwater
	fire = nil, -- On fire
	pose = nil, -- Pose
	vehicle = nil, -- Riding vehicle
	flying = nil, -- Creative flying

	effects = {}, -- Potion effects

	emote = nil, -- Emote (animations, like love, blush, or hug)
	expression = nil, -- Expression (actual facial expressions)
	holdingWeapon = nil, -- Holding weapon
}
