-- Emotes module

local emotes = {
	-- Snout UV offsets
	addUVs = {
		normal = vec(0, 0),
		normalHole = vec(0, 8),
		blink = vec(32, 0),
		hurt = vec(40, 0),
		love = vec(8, 0),
		hug = vec(8, 0), -- uses love
		blush = vec(16, 0),
		sleep = vec(24, 0),
		angry = vec(48, 0),
		angryHole = vec(48, 8)
	},
	-- Name of expression model part to enable for each expression
	parts = {
		normal = "normal",
		normalHole = "normalHole",
		blink = "blink",
		hurt = "hurt",
		love = "love",
		hug = "love", -- uses love
		blush = "blush",
		sleep = "sleep",
		angry = "angry",
		angryHole = "angryHole",
		rage = "angry", -- uses angry
		rageHole = "angryHole",
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
				settings.sound.damage.hiss and "minecraft:entity.cat.hiss" or nil
			}))
		end
	-- Play death sound
	else
		if math.random() < settings.sound.death.chance then
			modules.util.soundAtPlayer("minecraft:entity.cat.death")
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

if host:isHost() then
	function emotes.hugFirstPerson()
		vanilla_model.HELD_ITEMS:setVisible(emotes.emotes ~= "hug" or not previous.firstPerson)
	end
	modules.events.firstPerson:register(emotes.hugFirstPerson)
	modules.events.emote:register(emotes.hugFirstPerson)
end

-- Set first expression (hides other expression groups)
function emotes.init()
	modules.emotes.setExpression("normal")
end
modules.events.ENTITY_INIT:register(emotes.init)



function emotes.setEmote(animation, infinite)
	emotes.stopEmote(false)
	emotes.emote = animation

	-- Set remaining time
	emotes.ticksLeft = infinite and math.huge or emotes.ticks[animation]
	emotes.particleTimer = 0

	-- Change facial expression
	emotes.setExpression(animation)

	-- SFX ("hurt" sfx is in emotes.hurtEvent)
	if animation == "love" or animation == "blush" or animation == "hug" then
		modules.util.soundAtPlayer(modules.util.pickFrom({
			settings.sound.emotes[animation].purr and "minecraft:entity.cat.purr" or nil,
			settings.sound.emotes[animation].purreow and "minecraft:entity.cat.purreow" or nil
		}))
	elseif animation == "rage" then
		modules.util.soundAtPlayer(modules.util.pickFrom({settings.sound.emotes[animation].hiss and "minecraft:entity.cat.hiss" or nil}))
		-- Also spawn specific amount of particles here
		for i = 1, math.random(6, 9) do
			emotes.randomRageParticle()
		end
	end

	-- Hugging
	if animation == "hug" then
		animations["models.cat"].hug:play()
	end
end
pings.setEmote = emotes.setEmote

function emotes.stopEmote(resetExpression)
	if emotes.emote == "hug" then
		animations["models.cat"].hug:stop()
	end

	emotes.ticksLeft = 0
	if resetExpression then
		emotes.setExpression((previous.holdingWeapon and not modules.eyes.scared) and "angry" or "normal")
	end
end
pings.stopEmote = emotes.stopEmote

function emotes.setExpression(expression)
	if emotes.parts[expression] == nil then
		return
	end

	-- If dynamic eyes is enabled, use overlaid eyes
	if settings.eyes.dynamic.enabled or settings.eyes.glow.enabled then
		if emotes.parts[expression .. "Hole"] ~= nil then
			expression = expression .. "Hole"
			-- TODO
			-- models.cat.Head.eyesBack:setVisible(true)
			-- models.cat.Head.Eyes:setVisible(settings.eyes.dynamic.enabled)
			-- models.cat.Head.EyesGlint:setVisible(settings.eyes.glow.enabled)
		else
			-- models.cat.Head.eyesBack:setVisible(false)
			-- TODO
			-- models.cat.Head.Eyes:setVisible(false)
			-- models.cat.Head.EyesGlint:setVisible(false)
		end
	end

	-- Enable distinct head part (saves on texture size)
	for _, part in pairs(models.cat.Head.Expressions:getChildren()) do
		part:setVisible(part:getName() == emotes.parts[expression])
	end

	-- Manipulate snout UVs (saves on number of snouts)
	if settings.model.snoot then
		if emotes.addUVs[expression] then
			models.cat.Head.Snoot:setUVPixels(emotes.addUVs[expression])
		end
	end

	previous.expression = expression
	modules.events.expression:run(expression)
	-- TODO
	-- -- Update dynamic eyes if applicable
	-- if settings.eyes or settings.eyesGlint then
		-- moveEyes()
	-- end
end

function emotes.isEmoting()
	return emotes.ticksLeft > 0
end

function emotes.canBlink()
	return previous.pose ~= "SLEEPING" and emotes.emote ~= "hurt"
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
	end
end

function emotes.canHug()
	return not previous.invisible and (previous.velMagXZ < 0.15 or previous.vehicle) and ((player:isOnGround() or player:isFlying()) or previous.vehicle) and (previous.pose == "STANDING" or previous.pose == "CROUCHING")
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
