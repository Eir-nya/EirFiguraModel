-- Sleep module

local sleep = {
	-- Stored rotation of the 3rd person camera to rotate over time when enabled
	cameraRotation = vec(0, 0, 0),
	-- Bool to determine if the 3rd person camera should rotate while sleeping
	cameraRotate = true,
}

-- Subscribable events

modules.events.sleep = modules.events:new()

-- Events

function sleep.autoState()
	if previous.pose == "SLEEPING" then
		sleep.startSleeping()
	elseif previous.expression == "sleep" then
		sleep.stopSleeping()
	end
end
modules.events.pose:register(sleep.autoState)



function sleep.startSleeping()
	-- Change expression
	modules.emotes.setEmote("sleep")

	if not settings.sleep.enabled then
		return
	end

	-- Camera setup on model wearer's client only
	if host:isHost() then
		sleep.cameraSetup()
	end

	modules.animations.sleepPose:play()
	animations["models.cat"].breatheIdle:speed(0.5)

	-- Fixes a minecraft issue where the client-side specifically renders the model slightly lower than other players see it
	if host:isHost() then
		if settings.sleep.clientHeightFix then
			local raiseAmount = vec(0, 3, 0)

			models.cat.LeftLeg:setPos(models.cat.LeftLeg:getPos() + raiseAmount)
			models.cat.RightLeg:setPos(models.cat.RightLeg:getPos() + raiseAmount)
			models.cat.Body:setPos(models.cat.Body:getPos() + raiseAmount)
			models.cat.LeftArm:setPos(models.cat.LeftArm:getPos() + raiseAmount)
			models.cat.RightArm:setPos(models.cat.RightArm:getPos() + raiseAmount)
			models.cat.Head:setPos(models.cat.Head:getPos() + raiseAmount)

			-- Elytra
			if settings.model.elytra.enabled then
				models.cat.Body.Elytra:setPos(raiseAmount)
			end
		end
	end

	modules.events.sleep:run()
end

function sleep.stopSleeping()
	-- Change expression back
	modules.emotes.stopEmote(true)

	if not settings.sleep.enabled then
		return
	end

	-- Revert camera on model wearer's client only
	if host:isHost() then
		renderer:offsetCameraPivot(0, 0, 0)
		renderer:offsetCameraRot(0, 0, 0)
	end

	modules.animations.sleepPose:stop()
	animations["models.cat"].breatheIdle:speed(1)

	if host:isHost() then
		if settings.sleep.clientHeightFix then
			-- Undo part raise offset
			models.cat.LeftLeg:setPos()
			models.cat.RightLeg:setPos()
			models.cat.Body:setPos()
			models.cat.LeftArm:setPos()
			models.cat.RightArm:setPos()
			models.cat.Head:setPos()

			if settings.model.elytra.enabled then
				models.cat.Body.Elytra:setPos()
			end
		end
	end

	modules.events.sleep:run()
end

function sleep.cameraSetup()
	-- TODO
	-- -- Code that moves the model wearer's camera to various positions
	-- local lookDir = player:getLookDir()
	-- local angle = math.deg(math.atan2(lookDir.z, lookDir.x))
	-- local distance = 2

	-- local baseRotation = not renderer:isFirstPerson() and vec(0, -angle + (not renderer:isCameraBackwards() and 180 or 0), 0) or vec(0, 0, 0)
	-- local basePos = not renderer:isFirstPerson() and vec(0, 0, -4) or vec(0, 0, 0)
	-- local cam = not renderer:isFirstPerson() and camera.THIRD_PERSON or camera.FIRST_PERSON

	-- -- Attempt to fetch the way the player is facing by checking position of the head and foot of their bed
	-- local direction = vec(-math.sin(math.rad(angle)), 0, math.cos(math.rad(angle))).normalized() -- Really poor failsafe
	-- local bedBlock = world:getBlockState(player:getPos())
	-- for i = 0, 3 do
		-- local nextPos = player:getPos() + vec((math.sin(math.rad(i * 90))), 0, math.cos(math.rad(i * 90)))
		-- local bedBlock2 = world:getBlockState(nextPos)
		-- if bedBlock2.name == bedBlock.name then
			-- direction = nextPos - player:getPos()
		-- end
	-- end

	-- -- Make first/third person camera watch the player from a slight distance
	-- local useFirstPerson = not (sleep.cameraWatch or not renderer:isFirstPerson())
	-- if sleep.cameraWatch or not renderer:isFirstPerson() then
		-- -- Raycast in front of player to make sure they would be visible
		-- for i = 1, 4 do
			-- local angleTest = angle
			-- local distanceTest = distance
			-- local flipped = i % 2 == 0
			-- direction = vec(0, 0, 0) - direction
			-- if i > 2 then
				-- distanceTest = distance / 2
			-- end

			-- -- Positions to raycast check to
			-- local checkPos1 = player:getPos() + (direction * 0.25) + vec(0, 0.1, 0)
			-- local checkPos2 = player:getPos() + (direction * 0.25) + (direction * (distanceTest + (flipped and 0.7 or 0))) + vec(0, 0.1 + (0.25 * distanceTest), 0)
			-- local result = renderer.raycastBlocks(checkPos1, checkPos2, "COLLIDER", "NONE")

			-- -- particle.addParticle("minecraft:end_rod", checkPos1)
			-- -- particle.addParticle("minecraft:end_rod", checkPos2)

			-- -- No hit, it's safe to use the camera from here
			-- if result == nil then
				-- cam:setRot(baseRotation + vec(10, (flipped and 180 or 0) - 5, 0))
				-- cam:setPos(basePos + vec(0, 0.125 * distanceTest, distanceTest))
				-- break
			-- -- Emergency fallback: Use first person camera position and rotation instead
			-- elseif i == 4 then
				-- useFirstPerson = true
			-- end
		-- end
	-- end

	-- -- Make first person view simply show top of bed instead
	-- if useFirstPerson then
		-- if avatar:canEditVanillaModel() then
			-- cam:setRot(baseRotation + vec(10, 180 - 5, 0))
			-- cam:setPos(basePos)
			-- models.cat.Head:setVisible(false)
			-- models.cat.Body:setVisible(false)
			-- models.cat.LeftArm:setVisible(false)
			-- models.cat.RightArm:setVisible(false)
		-- end
	-- end

	-- -- -- Move third person camera to a specific angle in front of the player (even if camera is backwards)
	-- -- camera.THIRD_PERSON:setRot(vec(20, -angle + 135 + (renderer:isCameraBackwards() and 180 or 0), 0))
	-- -- camera.THIRD_PERSON:setPos(vec(0, 0, 0))
	-- -- sleep.cameraRotation = camera.THIRD_PERSON:getRot()
end

return sleep
