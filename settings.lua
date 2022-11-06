-- Settings for the model

settings = {
	-- Custom armor settings
	customArmor = {
		earArmor = true,			-- Ear armor when wearing vanilla helmets
		earArmorMovement = false,	-- Should all ear armor allow ear movements? (Otherwise, only leather and chainmail helmets will)
		boobArmor = true,			-- Boob armor when wearing vanilla chestplates
		chest = true,				-- Custom armor for vanilla chestplates (crop top + gloves)
		legs = true,				-- Custom armor for vanilla leggings (booty shorts)
		vanitySlots = {				-- Check for armor in VanitySlots' vanity slots (https://modrinth.com/mod/vanity)
			head = true,
			chest = true,
			legs = true
		}
	},

	-- Sound settings
	sound = {
		damage = {
			chance = 0.1,			-- Chance to play a sound on damage
			hurt = true,			-- Use minecraft:entity.cat.hurt
			hiss = true				-- Use minecraft:entity.cat.hiss
		},
		death = {
			chance = 1				-- Chance to play a sound on death
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
		},
		sleep = {
			purr = true,			-- Use minecraft:entity.cat.purr
			purreow = true			-- Use minecraft:entity.cat.purreow
		}
	},

	-- Eye settings
	eyes = {
		dynamic = {
			enabled = true,			-- Enables dynamic eyes that slide gradually, independent of face texture
			followHead = true,		-- When player head is rotated, eyes will follow head's rotation left/right and up/down
			followMobs = true,		-- Tracks entities your cursor passes over using a priority system, watches them when nearby
			fear = true				-- Pupils shrink when "scared" (low hp, low hunger, freezing, drowning, has darkness or wither effect)
		},
		glow = {
			enabled = true,			-- Eyes glow somewhat in the dark
			nightVision = true,		-- Eyes will glow at full brightness when player has night vision effect (always otherwise)
			xpGlint = true			-- Makes eyes turn rainbow with xp levels, and glint at 30 levels or higher
		},
	},

	-- Hair settings
	hair = {
		enabled = true				-- Enables modeled, moving hair to attempt realism
	},

	-- Sleep settings
	sleep = {
		enabled = true,				-- Plays a custom animation when player is sleeping
		clientHeightFix = true		-- Fixes minecraft bug causing the player's body to render 3 units lower client-side while asleep
	},

	-- Model settings
	model = {
		skull = true,				-- Player skull replacement
		snoot = true,				-- 3d snout
		elytra = {
			enabled = true,			-- Elytra mimic model (Copies vanilla elytra. Required for elytra compatibility with poses)
			wings = false			-- Custom angel wings-style elytra
		}
	},

	-- Misc settings
	misc = {
		useCustomName = true,		-- Changes nameplates to a custom name (set below)
		customName = [[ [ "§9Eir ", {"text":"\u16B3","font":"\u0066igura:default"} ] ]]
	}
}



-- Settings verification

if not avatar:canEditVanillaModel() then
	settings.sleep.enabled = false
	settings.customArmor.chest = false
	settings.customArmor.legs = false
	settings.customArmor.boobArmor = false
	settings.model.elytra = false
	settings.eyes.dynamic.enabled = false
	settings.eyes.glow.enabled = false
end

require("scripts/complexity")

if not settings.eyes.dynamic.enabled then
	settings.eyes.dynamic.followHead = false
	settings.eyes.dynamic.followMobs = false
	settings.eyes.dynamic.fear = false
end
if not settings.eyes.glow.enabled then
	settings.eyes.glow.nightVision = false
	settings.eyes.glow.xpGlint = false
end