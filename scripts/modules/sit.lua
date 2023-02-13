-- Sit module

local sit = {
	-- Is sitting?
	isSitting = false,
	facingDir = nil,
	anim = modules.animations.sit1,
}

-- Subscribable events

modules.events.sit = modules.events:new()

-- Events

function sit.update()
	if sit.isSitting then
		if modules.emotes.isEmoting() and modules.emotes.emote == "blush" then
			sit.anim.anim:speed(1)
		else
			sit.anim.anim:speed(0.75)
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
	-- "Raycast" a bit in front of the player to decide which animation to play
	local bodyYaw = player:getBodyYaw()
	local direction = vec(-math.sin(math.rad(bodyYaw)), 0, math.cos(math.rad(bodyYaw))):normalized()
	local checkPos1 = player:getPos() + (direction * 0.35)
	local checkPos2 = player:getPos() + (direction * 1.5) + vec(0, -0.24, 0)

	local raycastClean = true

	local block1 = world.getBlockState(checkPos1)
	if block1:isSolidBlock() and block1:hasCollision() then
		local collision1 = block1:getCollisionShape()
		local pos1Floor = vec(math.floor(checkPos1.x), math.floor(checkPos1.y), math.floor(checkPos1.z))

		for i = 1, #collision1 do
			if checkPos1 >= collision1[i][1] + pos1Floor and checkPos1 < collision1[i][2] + pos1Floor then
				raycastClean = false
				break
			end
		end
	end

	if raycastClean then
		local block2 = world.getBlockState(checkPos2)
		if block2:isSolidBlock() and block2:hasCollision() then
			local collision2 = block2:getCollisionShape()
			local pos2Floor = vec(math.floor(checkPos2.x), math.floor(checkPos2.y), math.floor(checkPos2.z))

			for i = 1, #collision2 do
				if checkPos2 >= collision2[i][1] + pos2Floor and checkPos2 < collision2[i][2] + pos2Floor then
					raycastClean = false
					break
				end
			end
		end
	end


	sit.anim = raycastClean and modules.animations.sit2 or modules.animations.sit1
	sit.anim:play()
	sit.anim:fade(modules.animations.fadeModes.FADE_IN_SMOOTH, animFast and 0.6 or 0.4)

	sit.facingDir = bodyYaw
	modules.events.sit:run()
end

function sit.stopSitting(animFast)
	sit.anim:fade(modules.animations.fadeModes.FADE_OUT_SMOOTH, animFast and 0.6 or 0.2)
	models.cat:setRot()

	modules.events.sit:run()
end

function sit.faceSameDirection(delta, ctx)
	if ctx ~= "RENDER" then
		return
	end

	if sit.anim.anim:isPlaying() or sit.anim:isFading() then
		local animFade = 1
		if sit.anim:isFading() then
			animFade = sit.anim:getFadeBlend(delta)
		end

		local shortAngle = math.shortAngle(player:getBodyYaw(delta), sit.facingDir)
		local diff = sit.facingDir - (player:getBodyYaw(delta) % 360)
		models.cat:setRot(vec(0, -shortAngle * animFade, 0))
	end
end
modules.events.RENDER:register(sit.faceSameDirection)

function sit.canSit()
	return not previous.invisible and previous.velMagXZ < 0.05 and player:isOnGround() and previous.pose == "STANDING"
end

return sit
