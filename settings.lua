-- Settings for the model

settings = {
	-- Armor settings
	armor = {
		earArmor = true,			-- Ear armor replaces ears when wearing any vanilla helmet
		earArmorMovement = false,	-- Should all ear armor allow ear movements? (Otherwise, only leather and chainmail helmets will)
		boobArmor = true,			-- Boob armor when wearing any vanilla chestplate
		vanitySlots = true,			-- Compatibility with VanitySlots fabric mod
	},

	-- Sound settings
	sound = {
		damage = {
			chance = 0.1,			-- Chance to play a sound on damage
			hurt = true,			-- Use minecraft:entity.cat.hurt
			hiss = true,			-- Use minecraft:entity.cat.hiss
			squeak = true,			-- Use squeak (custom sound)
			squeakChance = 0.2,		-- Chance to play squeak
		},
		death = {
			chance = 1,				-- Chance to play a sound on death
			death = true,			-- Use minecraft:entity.cat.death
			squeak = true,			-- Use squeak (custom sound)
			squeakChance = 0.2,		-- Chance to play squeak
		},
		emotes = {					-- Settings for emote actions
			love = {
				purr = true,		-- Use minecraft:entity.cat.purr
				purreow = true		-- Use minecraft:entity.cat.purreow
			},
			blush = {
				purr = true,		-- Use minecraft:entity.cat.purr
				purreow = true		-- Use minecraft:entity.cat.purreow
			},
			hug = {
				purr = true,		-- Use minecraft:entity.cat.purr
				purreow = true		-- Use minecraft:entity.cat.purreow
			},
			rage = {
				hiss = true,		-- Use minecraft:entity.cat.hiss
			},
			sad = {
				beg_for_food = true,	-- Use minecraft:entity.cat.beg_for_food
			}
		},
		sleep = {
			purr = true,			-- Use minecraft:entity.cat.purr
			purreow = true			-- Use minecraft:entity.cat.purreow
		}
	},

	-- Eye settings
	eyes = {
		glow = {
			enabled = true,			-- Eyes glow somewhat in the dark
			nightVision = true,		-- Eyes will glow at full brightness when player has night vision effect (always otherwise)
			xpGlint = true			-- Makes eyes turn rainbow with xp levels, and glint at 30 levels or higher
		},
	},

	-- Rope physics
	rope = {
		enabled = true,				-- Enables rope physics. Set to false to force-disable for everything that uses rope physics
		windInfluence = true,		-- Enables wind influence over rope physics parts, eg. swaying hair
	},

	-- Hair settings
	hair = {
		physics = true,				-- Adds some dangly strands of hair that use rope physics. Requires rope.enabled
	},

	-- Sleep settings
	sleep = {
		enabled = true,				-- Plays a custom animation when player is sleeping
		clientHeightFix = true		-- Fixes minecraft bug causing the player's body to render 3 units lower client-side while asleep
	},

	-- Model settings
	model = {
		elytra = {
			custom = true,			-- Elytra mimic model (Copies vanilla elytra. Required for model.elytra.wings)
			-- wings = false			-- Custom angel wings-style elytra
		},
		vanillaMatch = true,		-- Attempts to make vanilla model parts match custom model parts visually, for maximum mod compatibility.
	},

	-- Action wheel settings
	actionWheel = {
		openToDefault = true,		-- When action wheel is opened, always open to the same page (defined below)
		defaultPage = "emotes",		-- Default page to open action wheel to when actionWheel.openToDefault is true
		sounds = true,				-- Adds default sounds to Actions
	},

	-- Misc settings
	misc = {
		useCustomName = true,		-- Changes nameplates to a custom name (set below)
		customNameEntity = '[{"text":":zzz::cat3::sparkles::trans:"}'
			.. ',{"text":"\nEir","color":"#8ecbea"}]',
		customNameChat = '[{"text":":cat:Eir","color":"#8ecbea"}]',

		disableGetNbt = false,		-- Disables uses of entity:getNbt() for compatibility with Requiem/Locki mod. Disables vanity aror.
		customCrosshair = true,		-- Use custom crosshair
	}
}


-- Settings verification

if not avatar:canEditVanillaModel() then
	settings.sleep.enabled = false
	settings.armor.boobArmor = false
	settings.model.elytra.custom = false
	settings.eyes.glow.enabled = false
end

if not settings.rope.enabled then
	settings.hair.physics = false
end

if not settings.eyes.glow.enabled then
	settings.eyes.glow.nightVision = false
	settings.eyes.glow.xpGlint = false
end

settings.model.vanillaMatchOriginal = settings.model.vanillaMatch
if client.compareVersions(client:getFiguraVersion():sub(0, client:getFiguraVersion():find("+") - 1), "0.1.0-rc.13") < 1
  or client.hasShaderPackMod() then
	settings.model.vanillaMatch = false
end
