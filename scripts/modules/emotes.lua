-- Emotes module

local emotes = {
	-- Snout UV offsets
	addUVs = {
		normal = vec(0, 0),
		blink = vec(0, 8),
		hurt = vec(8, 8),
		love = vec(8, 0),
		hug = vec(8, 0), -- uses love
		blush = vec(16, 0),
		sleep = vec(24, 0),
		angry = vec(16, 8),
		sad = vec(24, 8),
	},
	-- Name of expression model part to enable for each expression
	parts = {
		normal = "normal",
		blink = "blink",
		hurt = "hurt",
		love = "love",
		hug = "love", -- uses love
		blush = "blush",
		sleep = "sleep",
		angry = "angry",
		rage = "angry", -- uses angry
		sad = "sad",
	},
	-- Current emote type
	emote = "normal",
	-- Time left in this emote
	ticksLeft = 0,
	-- Ticks left between blinks
	blinkTicks = 1,
	-- Particle timer
	particleTimer = 0,
	-- Ticks that each emote will last for
	ticks = {
		blink = 4,
		hurt = 10,
		love = 60,
		hug = math.huge,
		blush = 100,
		sleep = math.huge,
		rage = 50,
		sad = 140,
	},

	-- Substrings that, when present at the start or end of an item name, indicate it is a weapon and the "angry" expression should be switched to
	-- True indicates it has to be an exact match
	weaponStrings = {
		bow = true,
		_bow = false,
		crossbow = false,
		sword = false,
		_axe = false,
		trident = false
	}
}

-- Subscribable events

modules.events.emote = modules.events:new()
modules.events.expression = modules.events:new()

-- Events

function emotes.mainItemEvent()
	emotes.weaponTest(previous.mainItem)
end
modules.events.mainItem:register(emotes.mainItemEvent)
-- function emotes.offItemEvent()
	-- emotes.weaponTest(previous.offItem)
-- end
-- modules.events.offItem:register(emotes.offItemEvent)

function emotes.hurtEvent()
	if previous.hurtTicks == 0 then
		return
	end
	if not previous.invisible then
		emotes.setEmote("hurt")
	end

	-- Play hurt sound
	if previous.healthPercent > 0 then
		if math.random() < settings.sound.damage.chance then
			modules.util.soundAtPlayer(modules.util.pickFrom({
				settings.sound.damage.hurt and "minecraft:entity.cat.hurt" or nil,
				settings.sound.damage.hiss and "minecraft:entity.cat.hiss" or nil,
				(settings.sound.damage.squeak and math.random() < settings.sound.damage.squeakChance) and "squeak" or nil,
			}))
		end
	-- Play death sound
	else
		if math.random() < settings.sound.death.chance then
			modules.util.soundAtPlayer(modules.util.pickFrom({
				settings.sound.death.death and "minecraft:entity.cat.death" or nil,
				(settings.sound.death.squeak and math.random() < settings.sound.death.squeakChance) and "squeak" or nil,
			}))
		end
	end
end
modules.events.hurt:register(emotes.hurtEvent)

function emotes.tickEvent()
	-- Emotes
	if emotes.isEmoting() then
		emotes.ticksLeft = emotes.ticksLeft - 1

		emotes.update(emotes.emote)

		-- End emote animation
		if not emotes.isEmoting() then
			emotes.stopEmote(true)
		end
	end

	-- Blink
	if emotes.canBlink() then
		if not emotes.isEmoting() then
			emotes.blinkTicks = emotes.blinkTicks - 1

			-- Blink
			if emotes.blinkTicks == 0 then
				emotes.setExpression("blink")
			-- Unblink
			elseif emotes.blinkTicks <= -emotes.ticks.blink then
				emotes.stopEmote(true)
				emotes.blinkTicks = math.random(3, 8) * 20
			end
		end
	end
end
modules.events.TICK:register(emotes.tickEvent)

function emotes.hugHideItems(emote)
	vanilla_model.HELD_ITEMS:setVisible(emote ~= "hug")
end
modules.events.emote:register(emotes.hugHideItems)

-- Set first expression (hides other expression groups)
function emotes.init()
	modules.emotes.setExpression("normal")
end
modules.events.ENTITY_INIT:register(emotes.init)



function emotes.setEmote(animation, infinite)
	emotes.stopEmote(false)
	emotes.emote = animation

	-- Set remaining time
	emotes.ticksLeft = infinite and math.huge or (emotes.ticks[animation] and emotes.ticks[animation] or 0)
	emotes.particleTimer = 0

	-- Change facial expression
	emotes.setExpression(animation)
	modules.events.emote:run(animation, infinite)

	-- SFX ("hurt" sfx is in emotes.hurtEvent)
	if animation == "love" or animation == "blush" or animation == "hug" then
		modules.util.soundAtPlayer(modules.util.pickFrom({
			settings.sound.emotes[animation].purr and "minecraft:entity.cat.purr" or nil,
			settings.sound.emotes[animation].purreow and "minecraft:entity.cat.purreow" or nil
		}))
	elseif animation == "rage" then
		modules.util.soundAtPlayer(modules.util.pickFrom({settings.sound.emotes[animation].hiss and "minecraft:entity.cat.hiss" or nil}), 0.25)
		-- Also spawn specific amount of particles here
		for i = 1, math.random(6, 9) do
			emotes.randomRageParticle()
		end
	elseif animation == "sad" then
		modules.util.soundAtPlayer(modules.util.pickFrom({settings.sound.emotes[animation].beg_for_food and "minecraft:entity.cat.beg_for_food" or nil}), 1)
	end

	-- Hugging
	if animation == "hug" then
		-- Cancel sit animation if applicable
		if modules.sit.isSitting then
			pings.stopSitting(false)
		end
		animations["cat"].hug:play()
	end
end
pings.setEmote = emotes.setEmote

function emotes.stopEmote(resetExpression)
	if emotes.emote == "hug" then
		animations["cat"].hug:stop()
	end

	emotes.emote = nil
	modules.events.emote:run(nil)

	emotes.ticksLeft = 0
	if resetExpression then
		if not modules.eyes.scared then
			if modules.extra_animations.lastBlocking then
				emotes.setExpression("hurt")
			elseif previous.holdingWeapon then
				emotes.setExpression("angry")
			else
				emotes.setExpression("normal")
			end
		else
			emotes.setExpression("normal")
		end
	end
end
pings.stopEmote = emotes.stopEmote

function emotes.setExpression(expression)
	if emotes.parts[expression] == nil then
		return
	end

	-- Enable distinct head part (saves on texture size)
	for _, part in pairs(models.cat.Head.Expressions:getChildren()) do
		part:setVisible(part:getName() == emotes.parts[expression])
	end

	-- Manipulate snout UVs (saves on number of snouts)
	if emotes.addUVs[expression] then
		models.cat.Head.Snoot.Snoot:setUVPixels(emotes.addUVs[expression])
	end

	previous.expression = expression
	modules.events.expression:run(expression)
end

function emotes.isEmoting()
	return emotes.ticksLeft > 0
end

function emotes.canBlink()
	return previous.pose ~= "SLEEPING" and previous.expression ~= "hurt"
end

function emotes.update(emote)
	-- Love
	if emote == "love" then
		emotes.particleTimer = emotes.particleTimer - 1
		if emotes.particleTimer <= 0 then
			emotes.particleTimer = emotes.particleTimer + 4
			emotes.randomHeartParticle()
		end
	-- Blush
	elseif emote == "blush" then
		emotes.particleTimer = emotes.particleTimer - 1
		if emotes.particleTimer <= 0 then
			emotes.particleTimer = emotes.particleTimer + 2
			emotes.randomHeartParticle()
		end
	-- Hug
	elseif emote == "hug" then
		emotes.particleTimer = emotes.particleTimer - 1
		if emotes.particleTimer <= 0 then
			emotes.particleTimer = emotes.particleTimer + 60
			emotes.randomHeartParticle()
		end

		-- Force-cancel hug animation if certain conditions are met
		-- Only the model wearer's client decides if they should stop posing
		if host:isHost() then
			if not emotes.canHug() then
				pings.stopEmote(true)
			end
		end
	-- Sad
	elseif emote == "sad" then
		emotes.particleTimer = emotes.particleTimer - 1
		if emotes.particleTimer <= 0 then
			emotes.particleTimer = emotes.particleTimer + math.random(15, 25)
			particles.falling_water
				:pos(modules.util.pickFrom({ models.cat.Head.Eyes.left, models.cat.Head.Eyes.right }):partToWorldMatrix():apply(vec(0, -4, -2)))
				:lifetime(60)
				:spawn()
		end
	end
end

function emotes.canHug()
	return not previous.invisible and (previous.velMagXZ < 0.15 or previous.vehicle) and ((player:isOnGround() or previous.flying) or previous.vehicle) and (previous.pose == "STANDING" or previous.pose == "CROUCHING")
end

function emotes.weaponTest(item)
	local suffix = string.gsub(item.id, "[^:]+:", "")

	local holdingWeapon = false
	for weapon, exact in pairs(emotes.weaponStrings) do
		local matches = false

		if exact then
			matches = suffix == weapon
		else
			matches = modules.util.startsWith(suffix, weapon) or modules.util.endsWith(suffix, weapon)
		end

		-- Reset expressions so "angry" expression shows
		if matches then
			holdingWeapon = true
			previous.holdingWeapon = true
			if not emotes.isEmoting() then
				emotes.stopEmote(true)
			end
			break
		end
	end

	-- Not holding weapon - undo glare if applicable
	if not holdingWeapon then
		if previous.holdingWeapon then
			previous.holdingWeapon = false
			if not emotes.isEmoting() then
				emotes.stopEmote(true)
			end
		end
	end
end
modules.events.ENTITY_INIT:register(function() emotes.weaponTest(player:getItem(1)) end)

function emotes.randomHeartParticle()
	local pos = modules.util.getEyePos()
	pos = pos + vec((math.random() - 0.5) / 1.5, math.random() + 0.125, (math.random() - 0.5) / 1.5)
	particles.heart:spawn()
		:pos(pos)
		:gravity(0.25)
		:lifetime(12)
		:scale((math.random() / 3) + 0.5)
end

function emotes.randomRageParticle()
	local pos = modules.util.getEyePos()
	pos = pos + vec(math.random() - 0.5, (math.random() + 0.125) * 1.25, math.random() - 0.5)
	particles.angry_villager:spawn()
		:pos(pos)
		:gravity(0.0625)
		:lifetime(40)
		:scale((math.random() / 3) + 0.5)
end

return emotes
