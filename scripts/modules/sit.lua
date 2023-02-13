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


	local anim = raycastClean and modules.animations.sit2 or modules.animations.sit1
	anim:play()
	anim:fade(modules.animations.fadeModes.FADE_IN_SMOOTH, animFast and 0.6 or 0.4)

	modules.events.sit:run()
end

function sit.stopSitting(animFast)
	local anim = modules.animations.sit1.anim:isPlaying() and modules.animations.sit1 or modules.animations.sit2
	anim:fade(modules.animations.fadeModes.FADE_OUT_SMOOTH, animFast and 0.6 or 0.2)

	modules.events.sit:run()
end

function sit.canSit()
	return not previous.invisible and previous.velMagXZ < 0.05 and player:isOnGround() and previous.pose == "STANDING"
end

return sit
