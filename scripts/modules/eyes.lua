-- Eyes module

local eyes = {
	-- Locations of eyes when different facial expressions are used (set up with Blockbench!).
	-- For use when settings.eyes.glow is enabled, but settings.eyes.dynamic isn't
	eyePositions = {
		normalHole = { r = vec(0, 0), l = vec(0, 0), },
		angryHole = { r = vec(0, -0.5), l = vec(0, -0.5), },
		sadHole = { r = vec(0, 0), l = vec(0, 0), },
	},
	eyeBoundaries = {
		normalHole = {
			r = { x1 = 0, y1 = -0.5, x2 = 1, y2 = 1 },
			l = { x1 = -1, y1 = -0.5, x2 = 0, y2 = 1 },
		},
		angryHole = {
			r = { x1 = 0, y1 = -1, x2 = 1, y2 = 0 },
			l = { x1 = -1, y1 = -1, x2 = 0, y2 = 0 },
		},
		sadHole = {
			r = { x1 = 0, y1 = -0.5, x2 = 1, y2 = 1 },
			l = { x1 = -1, y1 = -0.5, x2 = 0, y2 = 1 },
		},
	},
	-- Distance added to left and right dynamic eyes so they won't appear as robotic
	eyeOffset = 0.5,

	-- Priority of stuff to look at, in order of most to least importance
	-- Entities not listed will be treated as if they were marked as 0
	-- The numbers here decide which entities are higher priority (and how far away to still track them from)
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
	xMove = 0,
	yMove = 0,
	lookTooFar = false,

	-- (Set by script)
	rainbowSpeed = 0,

	-- Player will be scared and pupils will shrink when at low health or food, freezing, drowning, or having the darkness or wither effects
	scared = false,
	scaredEffects = false, -- Set by event. determines if potion effects are currently applied on the host that should make eyes scared
	-- UV offset for eyes when scared
	scaredUVOffset = vec(3, 0)
}
-- Aliases
eyes.eyePositions.rageHole = eyes.eyePositions.angryHole
eyes.eyeBoundaries.rageHole = eyes.eyeBoundaries.angryHole

-- Events

function eyes.trackMobs()
	-- Get entities the player has started to look at
	eyes.lastEntityRaycast = { player:getTargetedEntity(20) }
	local target = eyes.lastEntityRaycast[1]
	if previous.vehicle then
		if target == player:getVehicle():getUUID() then
			target = nil
		end
	end

	-- Hovering over an entity.
	if target ~= nil then
		local priority = eyes.getEntityPriority(target:getType())
		eyes.nearbyEntities[priority] = target

		if eyes.nearest ~= target:getUUID() then
			pings.setNearest(target:getUUID())
		end
		eyes.highestPriority = math.max(priority, eyes.highestPriority)
		-- eyes.xMove = 0
		-- eyes.yMove = 0
	-- Not hovering over any entity in particular
	else
		local nearestSet = false
		-- Iterate through nearby entities in order of decreasing priority, remove ones which shouldn't be looked at
		for i = eyes.highestPriority, 0, -1 do
			local entity = eyes.nearbyEntities[i]
			if entity == nil then
				goto continue
			end

			local distance = entity:getPos() - player:getPos()

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
			if distance:lengthSquared() > maxDist then
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
if host:isHost() and settings.eyes.dynamic.followMobs then
	modules.events.TICK:register(eyes.trackMobs)
end

function eyes.unwatchVehicle()
	if previous.vehicle then
		local vehicle = player:getVehicle()
		-- Iterate through nearby entities in order of decreasing priority, remove ones which shouldn't be looked at
		for i = eyes.highestPriority, 0, -1 do
			if eyes.nearbyEntities[i] == vehicle then
				eyes.nearbyEntities[i] = nil
				break
			end
		end
	end
end
modules.events.vehicle:register(eyes.unwatchVehicle)

function eyes.watchEntity(tickProgress)
	-- Look at nearest entity
	if eyes.nearest ~= nil then
		local target = world.getEntity(eyes.nearest)
		if target ~= nil then
			local playerLook = player:getLookDir() -- Done here so the effect can be framerate independent, instead of using previous.lookDir
			local targetEyesPos = target:getPos() + vec(0, target:getEyeHeight(), 0)
			local distNormal = (targetEyesPos - modules.util.getEyePos()):normalized()
			eyes.yMove = distNormal.y - playerLook.y

			local ang1 = math.atan2(distNormal.x, distNormal.z)
			local ang2 = math.atan2(playerLook.x, playerLook.z)
			eyes.xMove = ang2 - ang1

			-- particles:addParticle("minecraft:crit", vec(target:getPos().x, target:getEyeY() + 1, target:getPos().z), 0)
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
if settings.eyes.dynamic.followMobs then
	modules.events.RENDER:register(eyes.watchEntity)
end

-- Sets initial render settings on glowing eyes
if settings.eyes.glow.enabled then
	function eyes.setupGlow()
		if settings.eyes.glow.xpGlint then
			models.cat.Head.EyesGlint:setSecondaryRenderType("TRANSLUCENT")
		-- If other settings are disabled, use fullbright eyes
		elseif not settings.eyes.glow.nightVision then
			models.cat.Head.EyesGlint:setLight(15)
		end
	end
	modules.events.ENTITY_INIT:register(eyes.setupGlow)
end

-- Toggle eyes
function eyes.init()
	models.cat.Head.eyesBack:setVisible(settings.eyes.dynamic.enabled or settings.eyes.glow.enabled)
	models.cat.Head.Eyes:setVisible(settings.eyes.dynamic.enabled)
	models.cat.Head.EyesGlint:setVisible(settings.eyes.glow.enabled)
end
modules.events.ENTITY_INIT:register(eyes.init)

-- Decorate glowing eyes
function eyes.decorateEyes()
	models.cat.Head.EyesGlint:setLight(nil)

	-- Prioritize night vision glow over xp glint rainbow
	-- TODO: use host to sync night vision effects or not
	if settings.eyes.glow.nightVision and modules.util.getEffect("effect.minecraft.night_vision") then
		models.cat.Head.EyesGlint:setOpacity(1)
		models.cat.Head.EyesGlint:setLight(15)
		models.cat.Head.EyesGlint:setColor(1, 1, 1)
	elseif settings.eyes.glow.xpGlint then
		eyes.rainbowSpeed = math.min(previous.xp / 9, 3 + (1 / 3))
		models.cat.Head.EyesGlint:setOpacity(math.min(previous.xp / 30, 1) * 0.625)
		models.cat.Head.EyesGlint:setLight(math.min(previous.xp / 45, 30 / 45) * 16)
	end

	-- Enchantment sheen on eyes if applicable
	if settings.eyes.glow.xpGlint then
		models.cat.Head.EyesGlint:setSecondaryRenderType(previous.xp >= 30 and "GLINT" or "TRANSLUCENT")
	end
end
-- Use a ping because only the host has access to current effects
if host:isHost() and settings.eyes.glow.nightVision then
	function pings.decorateEyes()
		eyes.decorateEyes()
	end
	modules.events.effects:register(pings.decorateEyes)
end
if settings.eyes.glow.xpGlint then
	modules.events.xp:register(eyes.decorateEyes)
end

-- Rainbow animation on eyes with xp
function eyes.rainbow(tickProgress)
	models.cat.Head.EyesGlint:setColor(modules.util.rainbow(eyes.rainbowSpeed)) -- vectors.rainbow(eyes.rainbowSpeed)
end
if settings.eyes.glow.xpGlint then
	modules.events.RENDER:register(eyes.rainbow)
end

-- Hide overlay eyes when not in RENDER context
function eyes.hideOverlayEyesNotRender(delta, ctx)
	models.cat.Head.EyesGlint:setVisible(modules.util.renderedInWorld(context))
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
		or modules.extra_animations.isFalling()

	-- Update eyes
	if eyes.scared ~= lastScared then
		-- Change eye size
		if settings.eyes.dynamic.enabled then
			models.cat.Head.Eyes:setScale(eyes.scared and vec(0.75, 0.75, 1) or vec(1, 1, 1))
		end
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
if settings.eyes.dynamic.fear then
	modules.events.health:register(eyes.setScared)
	modules.events.food:register(eyes.setScared)
	modules.events.frozen:register(eyes.setScared)
	modules.events.air:register(eyes.setScared)
	modules.events.fire:register(eyes.setScared)
	modules.events.fall:register(eyes.setScared)
end

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
	eyes.lookTooFar = math.abs(eyes.xMove) >= 1.75
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
		if settings.eyes.dynamic.followHead then
			local headRot = modules.util.getHeadRot() + vanilla_model.HEAD:getOriginRot()
			local headRotationX = headRot.y
			headRotationX = headRotationX / 100
			eyes.xMove = -headRotationX
			eyes.yMove = headRot.x / 180
		else
			eyes.xMove = 0
			eyes.yMove = 0
		end
	end

	local rightEyePos = vec(eyes.eyePositions[previous.expression].r.x, eyes.eyePositions[previous.expression].r.y, models.cat.Head.Eyes.right:getPos().z)
	local leftEyePos = vec(eyes.eyePositions[previous.expression].l.x, eyes.eyePositions[previous.expression].l.y, models.cat.Head.Eyes.left:getPos().z)
	local bounds = eyes.eyeBoundaries[previous.expression]

	if eyes.scared then
		eyes.xMove = 0
		eyes.yMove = 0
	end


	-- Only add eye offset if eyes are dynamic
	if settings.eyes.dynamic.enabled and not (settings.eyes.dynamic.enabled and not settings.eyes.dynamic.followHead and getHeadTilt) then
		rightEyePos.x = rightEyePos.x + eyes.eyeOffset
		leftEyePos.x = leftEyePos.x - eyes.eyeOffset
	end

	rightEyePos.x = math.clamp(rightEyePos.x + eyes.xMove * 2, bounds.r.x1, bounds.r.x2)
	rightEyePos.y = math.clamp(rightEyePos.y + eyes.yMove * 2, bounds.r.y1, bounds.r.y2)
	leftEyePos.x = math.clamp(leftEyePos.x + eyes.xMove * 2, bounds.l.x1, bounds.l.x2)
	leftEyePos.y = math.clamp(leftEyePos.y + eyes.yMove * 2, bounds.l.y1, bounds.l.y2)

	-- Move eyes to specific position if scared
	if eyes.scared then
		rightEyePos.x = rightEyePos.x - 0.125
		rightEyePos.y = rightEyePos.y + 0.5
		leftEyePos.x = leftEyePos.x + 0.125
		leftEyePos.y = leftEyePos.y + 0.5
	end

	if settings.eyes.dynamic.enabled then
		models.cat.Head.Eyes.right:setPos(rightEyePos)
		models.cat.Head.Eyes.left:setPos(leftEyePos)
	end
	if settings.eyes.glow.enabled then
		models.cat.Head.EyesGlint.right:setPos(rightEyePos)
		models.cat.Head.EyesGlint.left:setPos(leftEyePos)
	end
end

return eyes
