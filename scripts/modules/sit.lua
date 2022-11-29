-- Sit module

local sit = {
	-- Is sitting?
	isSitting = false,
}

-- Subscribable events

modules.events.sit = modules.events:new()

-- Events

function sit.update()
	if sit.isSitting then
		if modules.emotes.isEmoting() and modules.emotes.emote == "blush" then
			modules.animations.sit1.anim:speed(1)
		else
			modules.animations.sit1.anim:speed(0.75)
		end

		-- Only the model wearer's client decides if they should stop posing
		if host:isHost() then
			if not sit.canSit() then
				pings.sitPose(false, true)
			end
		end
	end
end
modules.events.TICK:register(sit.update)



function sit.sitPose(newSit, animFast)
	sit.isSitting = newSit
	
	if newSit then
		sit.startSitting(animFast)
	else
		sit.stopSitting(animFast)
	end
end
pings.sitPose = sit.sitPose

function sit.startSitting(animFast)
	modules.animations.sit1:play()
	modules.animations.sit1:fade(modules.animations.fadeModes.FADE_IN_SMOOTH, animFast and 0.6 or 0.4)

	-- TODO
	--[[
	-- Raycast just below where the legs will be dangling, to see if it's OK for them to dangle lower
	-- Converts body yaw angle in degrees into a unit vector
	local direction = vec(-math.sin(math.rad(previous.bodyYaw)), 0, math.cos(math.rad(previous.bodyYaw))).normalized()
	local checkPos1 = player:getPos() + (direction * 0.35)
	local checkPos2 = player:getPos() + (direction * 1.5) + vec(0, -0.24, 0)
	local result = renderer.raycastBlocks(checkPos1, checkPos2, "COLLIDER", "NONE")
	if result == nil then
		local legAddPos = vec(0, 0, -1)
		vanilla_model.LEFT_LEG:setPos(vanilla_model.LEFT_LEG:getPos() + legAddPos)
		vanilla_model.RIGHT_LEG:setPos(vanilla_model.RIGHT_LEG:getPos() + legAddPos)

		local legAddRot = vec(-45, 0, 0):toRad()
		vanilla_model.LEFT_LEG:setRot(vanilla_model.LEFT_LEG:getRot() + legAddRot)
		vanilla_model.RIGHT_LEG:setRot(vanilla_model.RIGHT_LEG:getRot() + legAddRot)

		vanilla_model.TORSO:setPos(vanilla_model.TORSO:getPos() + vec(0, -1.5, -3.5))
		vanilla_model.TORSO:setRot(vanilla_model.TORSO:getRot() + vec(-22.5, 0, 0):toRad())

		local armAddPos = vec(0, -0.5, -2.5)
		vanilla_model.LEFT_ARM:setPos(vanilla_model.LEFT_ARM:getPos() + armAddPos)
		vanilla_model.RIGHT_ARM:setPos(vanilla_model.RIGHT_ARM:getPos() + armAddPos)

		vanilla_model.LEFT_ARM:setRot(vanilla_model.LEFT_ARM:getRot() + vec(-22.5, 0, 11.25):toRad())
		vanilla_model.RIGHT_ARM:setRot(vanilla_model.RIGHT_ARM:getRot() + vec(-22.5, 0, -11.25):toRad())

		vanilla_model.HEAD:setPos(vanilla_model.HEAD:getPos() + vec(0, -1, -2.5))
	end
	]]--

	-- Elytra model manip
	if settings.model.elytra.enabled then
		models.elytra.LEFT_ELYTRA:setPos(models.elytra.LEFT_ELYTRA:getPos() - vec(-2, 15 + 2, -2))
		models.elytra.LEFT_ELYTRA:setRot(models.elytra.LEFT_ELYTRA:getRot() - vec(22.5, 45, 0))
		models.elytra.RIGHT_ELYTRA:setPos(models.elytra.RIGHT_ELYTRA:getPos() - vec(2, 15 + 2, -2))
		models.elytra.RIGHT_ELYTRA:setRot(models.elytra.RIGHT_ELYTRA:getRot() - vec(22.5, -45, 0))
	end

	modules.events.sit:run()
end

function sit.stopSitting(animFast)
	modules.animations.sit1:fade(modules.animations.fadeModes.FADE_OUT_SMOOTH, animFast and 0.6 or 0.2)

	modules.events.sit:run()
end

function sit.canSit()
	return not previous.invisible and previous.velMagXZ < 0.05 and player:isOnGround() and previous.pose == "STANDING"
end

return sit
