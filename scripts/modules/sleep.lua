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

	animations["models.cat"].sleepPose:play()

	-- Undo head parenting, undoes initial rotation when entering bed
	models.cat.Head:setParentType("BODY")

	-- Stop arm swaying
	models.cat.LeftArm:setParentType("BODY")
	models.cat.LeftArm:setPos(vanilla_model.LEFT_ARM:getOriginPos())
	models.cat.RightArm:setParentType("BODY")
	models.cat.RightArm:setPos(vanilla_model.RIGHT_ARM:getOriginPos())

	-- TODO!!!!!
	-- Elytra model manip
	if settings.model.elytra.enabled then
		models.elytra.LEFT_ELYTRA:setPos(models.elytra.LEFT_ELYTRA:getPos() - vec(-6, 3, -1))
		models.elytra.LEFT_ELYTRA:setRot(models.elytra.LEFT_ELYTRA:getRot() + vec(8, 180 + 12, -60))
		models.elytra.RIGHT_ELYTRA:setPos(models.elytra.RIGHT_ELYTRA:getPos() - vec(11, 2, -3))
		models.elytra.RIGHT_ELYTRA:setRot(models.elytra.RIGHT_ELYTRA:getRot() + vec(-12, 180 + 12, 50))
	end

	-- Set tail position and rotation
	modules.tail.intendedRotations = {
		vec(82, -22, -22), vec(-20, -22, 6), vec(-20, -22, 6),
		vec(-12, -1, 8), vec(-3, -22, 0), vec(-13, -15, -13),
		vec(5, -13, -1), vec(5, -3, 10), vec(0, 0, 0)
	}
	for i = 1, #modules.tail.rotations do
		modules.tail.rotations[i] = modules.tail.intendedRotations[i]
	end
	for i = 1, #modules.tail.displayedRotations do
		modules.tail.displayedRotations[i] = modules.tail.intendedRotations[i]
	end
	for i = 1, #modules.tail.lastDisplayedRotations do
		modules.tail.lastDisplayedRotations[i] = modules.tail.intendedRotations[i]
	end

	-- Fixes a minecraft issue where the client-side specifically renders the model slightly lower than other players see it
	if settings.sleep.clientHeightFix then
		if host:isHost() then
			local raiseAmount = vec(0, 3, 0)

			models.cat.LeftLeg:setPos(models.cat.LeftLeg:getPos() + raiseAmount)
			models.cat.RightLeg:setPos(models.cat.RightLeg:getPos() + raiseAmount)
			models.cat.Body:setPos(models.cat.Body:getPos() + raiseAmount)
			models.cat.LeftArm:setPos(models.cat.LeftArm:getPos() + raiseAmount)
			models.cat.RightArm:setPos(models.cat.RightArm:getPos() + raiseAmount)
			models.cat.Head:setPos(models.cat.Head:getPos() + raiseAmount)

			-- Elytra
			if settings.elytraFix then
				models.elytra.LEFT_ELYTRA:setPos(models.elytra.LEFT_ELYTRA:getPos() + raiseAmount)
				models.elytra.RIGHT_ELYTRA:setPos(models.elytra.RIGHT_ELYTRA:getPos() + raiseAmount)
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

	animations["models.cat"].sleepPose:stop()

	-- Redo body part parenting
	models.cat.Head:setParentType("Head")
	models.cat.LeftArm:setParentType("LeftArm")
	models.cat.RightArm:setParentType("RightArm")

	-- Undo part rotations and offsets
	models.cat.LeftLeg:setPos(vec(0, 0, 0))
	models.cat.LeftLeg:setRot(vec(0, 0, 0))
	models.cat.RightLeg:setPos(vec(0, 0, 0))
	models.cat.RightLeg:setRot(vec(0, 0, 0))
	models.cat.Body:setPos(vec(0, 0, 0))
	models.cat.Body:setRot(vec(0, 0, 0))
	models.cat.LeftArm:setPos(vec(0, 0, 0))
	models.cat.LeftArm:setRot(vec(0, 0, 0))
	models.cat.RightArm:setPos(vec(0, 0, 0))
	models.cat.RightArm:setRot(vec(0, 0, 0))
	models.cat.Head:setPos(vec(0, 0, 0))
	models.cat.Head:setRot(vec(0, 0, 0))

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
