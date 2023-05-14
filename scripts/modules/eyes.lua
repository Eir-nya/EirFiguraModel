-- Eyes module

local eyes = {
	-- Locations of eyes when different facial expressions are used (set up with Blockbench!).
	eyePositions = {
		normal = { r = vec(0, 0), l = vec(0, 0), },
		angry = { r = vec(0, -0.5), l = vec(0, -0.5), },
		sad = { r = vec(0, 0), l = vec(0, 0), },
	},
	eyeBoundaries = {
		normal = {
			r = { x = vec(0, 1), y = vec(-0.5, 1) },
			l = { x = vec(-1, 0), y = vec(-0.5, 1) },
		},
		angry = {
			r = { x = vec(0, 1), y = vec(-1, 0) },
			l = { x = vec(-1, 0), y = vec(-1, 0) },
		},
		sad = {
			r = { x = vec(0, 1), y = vec(-0.5, 1) },
			l = { x = vec(-1, 0), y = vec(-0.5, 1) },
		},
	},
	-- Distance added to left and right dynamic eyes so they won't appear as robotic
	eyeOffset = 0.43,

	-- Priority of stuff to look at, in order of most to least importance
	-- Entities not listed will be treated as if they were marked as 0
	-- The numbers here decide which entities are higher priority (and how far away to track them from)
	eyePriorities = {
		["minecraft:warden"] = 6,
		["minecraft:ender_dragon"] = 6,
		["minecraft:ghast"] = 6,
		["minecraft:wither"] = 4,
		["minecraft:elder_guardian"] = 4,
		["minecraft:giant"] = 4,
		["minecraft:ravager"] = 4,
		["minecraft:skeleton_horse"] = 3,
		["minecraft:zombie_horse"] = 3,
		["minecraft:phantom"] = 3,
		["minecraft:cat"] = 3,
		["minecraft:parrot"] = 3,
		["minecraft:salmon"] = 3,
		["minecraft:cod"] = 3,
		["minecraft:tropical_fish"] = 3,
		["minecraft:vex"] = 3,
		["minecraft:vindicator"] = 3,
		["minecraft:witch"] = 3,
		["minecraft:wither_skeleton"] = 3,
		["minecraft:guardian"] = 3,
		["minecraft:ocelot"] = 3,
		["minecraft:player"] = 3,
		["minecraft:illusioner"] = 3,
		["minecraft:piglin_brute"] = 3,
		["minecraft:shulker"] = 3,
		["minecraft:cave_spider"] = 3,
		["minecraft:creeper"] = 2,
		["minecraft:blaze"] = 2,
		["minecraft:enderman"] = 2,
		["minecraft:skeleton"] = 2,
		["minecraft:pillager"] = 2,
		["minecraft:zombie"] = 2,
		["minecraft:husk"] = 2,
		["minecraft:drowned"] = 2,
		["minecraft:stray"] = 2,
		["minecraft:zombified_piglin"] = 2,
		["minecraft:piglin"] = 2,
		["minecraft:hoglin"] = 2,
		["minecraft:zoglin"] = 2,
		["minecraft:spider"] = 2,
		["minecraft:armor_stand"] = 1,
		["minecraft:item"] = 1
	},
	-- Nearby entities to be tracked by eye movement
	nearbyEntities = {},
	lastEntityRaycast = nil,
	highestPriority = 0,

	-- Controls how much the dynamic eyes will move left or right. Set by other functions.
	move = vec(0, 0),
	lookTooFar = false,

	-- (Set by script)
	rainbowSpeed = 0,
	hasNightVision = false,
	glowColor = vectors.hexToRGB("7965b1"),

	-- Player will be scared and pupils will shrink when at low health or food, freezing, drowning, or having the darkness or wither effects
	scared = false,
	scaredEffects = false, -- Set by event. determines if potion effects are currently applied on the host that should make eyes scared
	-- UV offset for eyes when scared
	scaredUVOffset = vec(3, 0)
}
-- Aliases
eyes.eyePositions.rage = eyes.eyePositions.angry
eyes.eyeBoundaries.rage = eyes.eyeBoundaries.angry

-- Events

function eyes.trackMobs()
	-- Get entities the player has started to look at
	local target = ({ player:getTargetedEntity(20) })[1]
	eyes.lastEntityRaycast = target
	-- if previous.vehicle then
	-- 	if target == player:getVehicle() then
	-- 		target = nil
	-- 	end
	-- end

	-- Hovering over an entity.
	if target ~= nil then
		local priority = eyes.getEntityPriority(target:getType())
		eyes.nearbyEntities[priority] = target

		if eyes.nearest ~= target:getUUID() then
			pings.setNearest(target:getUUID())
		end
		eyes.highestPriority = math.max(priority, eyes.highestPriority)
	-- Not hovering over any entity in particular
	else
		local nearestSet = false
		-- Iterate through nearby entities in order of decreasing priority, remove ones which shouldn't be looked at
		for i = eyes.highestPriority, 0, -1 do
			local entity = eyes.nearbyEntities[i]
			if entity == nil then
				goto continue
			end

			-- Check if entity is loaded
			if not entity:isLoaded() then
				eyes.nearbyEntities[i] = nil
				goto continue
			end

			-- Check if entity is too far away
			local maxDist = 67.5 + 10
			if eyes.eyePriorities[entity:getType()] ~= nil then
				maxDist = maxDist + (eyes.eyePriorities[entity:getType()] * 30)
			end
			if (entity:getPos() - player:getPos()):lengthSquared() > maxDist then
				eyes.nearbyEntities[i] = nil
				goto continue
			end

			if eyes.nearest ~= entity:getUUID() then
				pings.setNearest(entity:getUUID())
			end
			nearestSet = true
			break
			::continue::
		end

		-- No entity targeted, unset
		if not nearestSet and eyes.nearest ~= nil then
			pings.setNearest(nil)
		end
	end
end
if host:isHost() then
	modules.events.TICK:register(eyes.trackMobs)

	-- Don't watch player's own vehicle
	function eyes.unwatchVehicle()
		if previous.vehicle then
			local vehicle = player:getVehicle()
			-- Iterate through nearby entities in order of decreasing priority, remove ones which shouldn't be looked at
			for i = eyes.highestPriority, 0, -1 do
				if eyes.nearbyEntities[i] == vehicle then
					eyes.nearbyEntities[i] = nil
					if eyes.nearest == vehicle:getUUID() then
						pings.setNearest(nil)
					end
					break
				end
			end
		end
	end
	modules.events.vehicle:register(eyes.unwatchVehicle)
end

function eyes.watchEntity(tickProgress)
	-- Look at nearest entity
	if eyes.nearest ~= nil then
		local target = world.getEntity(eyes.nearest)
		if target ~= nil then
			local playerLook = player:getLookDir() -- Done here so the effect can be framerate independent, instead of using previous.lookDir
			local targetEyesPos = target:getPos() + vec(0, target:getEyeHeight(), 0)
			local distNormal = (targetEyesPos - modules.util.getEyePos()):normalized()
			eyes.move.y = distNormal.y - playerLook.y

			local ang1 = math.atan2(distNormal.x, distNormal.z)
			local ang2 = math.atan2(playerLook.x, playerLook.z)
			eyes.move.x = ang2 - ang1

			eyes.moveEyes(false)
		-- Entity doesn't exist anymore
		else
			eyes.nearest = nil
		end
	end

	-- Reset eyes if nearest entity has been lost
	if eyes.nearest == nil then
		eyes.moveEyes(true)
	end
end
modules.events.RENDER:register(eyes.watchEntity)

-- Sets initial render settings on glowing eyes
if settings.eyes.glow.enabled then
	function eyes.setupGlow()
		models.cat.Head.EyesGlint:setPrimaryRenderType("TRANSLUCENT_CULL")
		-- If other settings are disabled, use fullbright eyes
		if not settings.eyes.glow.xpGlint and not settings.eyes.glow.nightVision then
			models.cat.Head.EyesGlint:setOpacity(1)
			models.cat.Head.EyesGlint:setLight(15)
			models.cat.Head.EyesGlint:setColor(eyes.glowColor)
		end
	end
	modules.events.ENTITY_INIT:register(eyes.setupGlow)
end

-- Toggle eyes
function eyes.init()
	models.cat.Head.EyesGlint:setVisible(settings.eyes.glow.enabled)
end
modules.events.ENTITY_INIT:register(eyes.init)

-- Decorate glowing eyes
function eyes.decorateEyes()
	models.cat.Head.EyesGlint:setLight(nil)

	-- Prioritize night vision glow over xp glint rainbow
	if settings.eyes.glow.nightVision and eyes.hasNightVision then
		models.cat.Head.EyesGlint:setOpacity(1)
		models.cat.Head.EyesGlint:setLight(15)
		models.cat.Head.EyesGlint:setColor(eyes.glowColor)
	elseif settings.eyes.glow.xpGlint then
		eyes.rainbowSpeed = math.min(previous.xp / 9, 3 + (1 / 3))
		models.cat.Head.EyesGlint:setOpacity(math.min(previous.xp / 30, 1) * 0.625)
		models.cat.Head.EyesGlint:setLight(math.min(previous.xp / 45, 30 / 45) * 16)
	end

	-- Enchantment sheen on eyes if applicable
	if settings.eyes.glow.xpGlint then
		models.cat.Head.EyesGlint:setSecondaryRenderType(previous.xp >= 30 and "GLINT" or "TRANSLUCENT_CULL")
	end
end
-- Use a ping because only the host has access to current effects
function pings.setNightVision(hasNightVision)
	eyes.hasNightVision = hasNightVision
	eyes.decorateEyes()
end
if host:isHost() then
	function eyes.checkNightVision()
		if settings.eyes.glow.nightVision then
			if modules.util.getEffect("effect.minecraft.night_vision") then
				pings.setNightVision(true)
			else
				pings.setNightVision(false)
			end
		end
	end
	modules.events.effects:register(eyes.checkNightVision)
end
modules.events.xp:register(eyes.decorateEyes)

-- Rainbow animation on eyes with xp
function eyes.rainbow(tickProgress)
	if not (settings.eyes.glow.nightVision and eyes.hasNightVision) then
		models.cat.Head.EyesGlint:setColor(modules.util.rainbow(eyes.rainbowSpeed))
	end
end
if settings.eyes.glow.xpGlint then
	modules.events.RENDER:register(eyes.rainbow)
end

-- Hide overlay eyes when not in RENDER context
function eyes.hideOverlayEyesNotRender(delta, ctx)
	models.cat.Head.EyesGlint:setVisible(modules.util.renderedInWorld(ctx))
end
if settings.eyes.glow.enabled then
	modules.events.RENDER:register(eyes.hideOverlayEyesNotRender)
end

-- Determines if player should look scared
function eyes.setScared()
	local lastScared = eyes.scared
	eyes.scared = previous.healthPercent <= 0.2
		or previous.food <= 6
		or previous.freezeTicks >= 140
		or previous.airPercent <= 0.2
		or previous.fire
		or eyes.scaredEffects
		or (modules.extra_animations.isFalling() and (modules.animations.fall:isFading() and modules.animations.fall.fadeMode == modules.animations.fadeModes.FADE_IN_SMOOTH))

	-- Update eyes
	if eyes.scared ~= lastScared then
		-- Change eye size
		models.cat.Head.Eyes:setScale(eyes.scared and vec(0.75, 0.75, 1) or vec(1, 1, 1))
		if settings.eyes.glow.enabled then
			models.cat.Head.EyesGlint:setScale(eyes.scared and vec(0.75, 0.75, 1) or vec(1, 1, 1))
		end

		-- Change eye display
		models.cat.Head.Eyes.left:setUVPixels(eyes.scared and eyes.scaredUVOffset or vec(0, 0))
		models.cat.Head.Eyes.right:setUVPixels(eyes.scared and eyes.scaredUVOffset or vec(0, 0))

		eyes.moveEyes(not eyes.scared)
		modules.emotes.stopEmote(true)
	end
end
modules.events.health:register(eyes.setScared)
modules.events.food:register(eyes.setScared)
modules.events.frozen:register(eyes.setScared)
modules.events.air:register(eyes.setScared)
modules.events.fire:register(eyes.setScared)
modules.events.fall:register(eyes.setScared)

function pings.setScaredEffects(x)
	eyes.scaredEffects = x
	eyes.setScared()
end
if host:isHost() then
	function eyes.checkScaredEffects()
		pings.setScaredEffects(modules.util.getEffect("effect.minecraft.darkness")
			or modules.util.getEffect("effect.minecraft.wither")
			or modules.util.getEffect("effect.minecraft.poison"))
	end
	modules.events.effects:register(eyes.checkScaredEffects)
end



function eyes.setNearest(newNearest)
	eyes.nearest = newNearest
end
pings.setNearest = eyes.setNearest

function eyes.getEntityPriority(entityType)
	if eyes.eyePriorities[entityType] ~= nil then
		return eyes.eyePriorities[entityType]
	else
		return 0
	end
end

function eyes.moveEyes(getHeadTilt)
	if eyes.eyePositions[previous.expression] == nil then
		return
	end

	-- If object is behind player, just face forward instead
	local lastLookTooFar = eyes.lookTooFar
	eyes.lookTooFar = math.abs(eyes.move.x) >= 1.75
	if eyes.lookTooFar then
		getHeadTilt = true

		-- Blink if player just looked away from a target
		if not lastLookTooFar then
			if modules.emotes.emote ~= "blink" then
				if modules.emotes.canBlink() then
					modules.emotes.blinkTicks = 0
					modules.emotes.setExpression("blink")
					return
				end
			end
		end
	end

	-- Fetch player's head tilt instead of distance to target entity's eyes
	if getHeadTilt then
		local headRot = modules.util.getHeadRot() + vanilla_model.HEAD:getOriginRot()
		eyes.move = vec(headRot.y / -100, headRot.x / 180)
	end

	local r = eyes.eyePositions[previous.expression].r:copy()
	local l = eyes.eyePositions[previous.expression].l:copy()
	local bounds = eyes.eyeBoundaries[previous.expression]

	if eyes.scared then
		eyes.move = vec(0, 0)
	end


	-- Only add eye offset if eyes are dynamic
	-- if settings.eyes.dynamic.enabled and not (settings.eyes.dynamic.enabled and not settings.eyes.dynamic.followHead and getHeadTilt) then
	r.x = r.x + eyes.eyeOffset
	l.x = l.x - eyes.eyeOffset

	r.x = math.clamp(r.x + eyes.move.x * 2, bounds.r.x:unpack())
	r.y = math.clamp(r.y + eyes.move.y * 2, bounds.r.y:unpack())
	l.x = math.clamp(l.x + eyes.move.x * 2, bounds.l.x:unpack())
	l.y = math.clamp(l.y + eyes.move.y * 2, bounds.l.y:unpack())

	-- Move eyes to specific position if scared
	if eyes.scared then
		r.x = r.x - 0.125
		r.y = r.y + 0.5
		l.x = l.x + 0.125
		l.y = l.y + 0.5
	end

	models.cat.Head.Eyes.right:setPos(r.x, r.y, models.cat.Head.Eyes.right:getPos().z)
	models.cat.Head.Eyes.left:setPos(l.x, l.y, models.cat.Head.Eyes.left:getPos().z)
	if settings.eyes.glow.enabled then
		models.cat.Head.EyesGlint.right:setPos(r.x, r.y, models.cat.Head.Eyes.right:getPos().z)
		models.cat.Head.EyesGlint.left:setPos(l.x, l.y, models.cat.Head.Eyes.left:getPos().z)
	end
end

return eyes
