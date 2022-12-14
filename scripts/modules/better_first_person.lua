local bfp = {
	lastLeftArmRot = nil,
	lastLeftArmPos = nil,
	lastRightArmRot = nil,
	lastRightArmPos = nil,
}

function bfp.init()
	-- TODO: if custom crosshair/better first person view is disabled, just hide custom croshair
	renderer.renderCrosshair = false
	models.firstPerson.crosshair:setParentType("Gui")

	bfp.setCrosshair(true) -- TODO
end
modules.events.ENTITY_INIT:register(bfp.init)

function bfp.updateArms(delta, context)
	-- FIRST_PERSON render context always comes first.
	if context == "FIRST_PERSON" then
		models.cat:setRot()

		bfp.lastLeftArmRot = models.cat.LeftArm:getRot()
		bfp.lastLeftArmPos = models.cat.LeftArm:getPos()
		bfp.lastRightArmRot = models.cat.RightArm:getRot()
		bfp.lastRightArmPos = models.cat.RightArm:getPos()

		models.cat.LeftArm:setRot(-models.cat.LeftArm:getAnimRot() / 1.375)
		models.cat.RightArm:setRot(-models.cat.RightArm:getAnimRot() / 1.375)
		models.cat.LeftArm:setPos(-models.cat.LeftArm:getAnimPos() / 1.25)
		models.cat.RightArm:setPos(-models.cat.RightArm:getAnimPos() / 1.25)
	elseif renderer:isFirstPerson() then
		models.cat.LeftArm:setRot(bfp.lastLeftArmRot)
		models.cat.RightArm:setRot(bfp.lastRightArmRot)

		if not modules.sit.isSitting then
			models.cat.LeftArm:setPos(bfp.lastLeftArmPos)
			models.cat.RightArm:setPos(bfp.lastRightArmPos)
		else
			models.cat.LeftArm:setPos()
			models.cat.RightArm:setPos()
		end
	elseif bfp.lastLeftArmRot ~= nil then
		bfp.lastLeftArmRot = nil
		bfp.lastLeftArmPos = nil
		bfp.lastRightArmRot = nil
		bfp.lastRightArmPos = nil

		models.cat.LeftArm:setRot()
		models.cat.LeftArm:setPos()
		models.cat.RightArm:setRot()
		models.cat.RightArm:setPos()
	end
end
modules.events.RENDER:register(bfp.updateArms)

function bfp.crosshairRender(delta, context)
	-- Allow viewing in third person with camera frozen
	if context ~= "FIRST_PERSON" and not (context == "RENDER" and modules.camera.frozen) then
		if context == "RENDER" then
			models.firstPerson.crosshair:setVisible(false)
		end
		return
	end
	models.firstPerson.crosshair:setVisible(true)

	-- Fades out slightly in first person when using items or aiming
	if context == "FIRST_PERSON" then
		if not player:isUsingItem() or player:getItem(1).id == "minecraft:bow" or player:getItem(1).id == "minecraft:trident" then
			models.firstPerson.crosshair:setOpacity(1)
		else
			models.firstPerson.crosshair:setOpacity(0.25)
		end
	end

	-- Set position for the crosshair to go to
	local crosshairWorldPos
	if context == "RENDER" then
		local e, ePos = player:getTargetedEntity(5)
		local b, bPos = player:getTargetedBlock(true, 5)
		if e ~= nil then
			crosshairWorldPos = ePos
		elseif b ~= nil and b.id ~= "minecraft:air" then
			crosshairWorldPos = bPos
		end
	end
	-- Default crosshair values
	if not crosshairWorldPos then
		crosshairWorldPos = player:getPos(delta):add(0, player:getEyeHeight(), 0)
		crosshairWorldPos = crosshairWorldPos + (player:getLookDir() * 5)
	end

	-- Third person only: crosshair rotates back to face player
	if context == "RENDER" then
		local r2 = player:getRot(delta)
		local r3 = vec(-r2.x, r2.y, 0)
		models.firstPerson.crosshair:setRot(client.getCameraRot() - r3)
		-- local crosshairDist = 25
		-- if renderer:getCameraPivot() ~= nil then
			-- crosshairDist = (crosshairWorldPos - renderer:getCameraPivot()):lengthSquared()
			-- local scale = math.min(2, 50 / crosshairDist)
			-- models.firstPerson.crosshair:setScale(vec(1, 1, 1) * scale)
		-- end
	else
		if renderer:getCameraOffsetRot() then
			models.firstPerson.crosshair:setRot(-renderer:getCameraOffsetRot().__z)
		end
		-- models.firstPerson.crosshair:setScale()
	end

	-- Translate coords to screen space; center crosshair
	local screenSpace = vectors.worldToScreenSpace(crosshairWorldPos)
	local coords = screenSpace.xy + vec(1, 1)
	coords = (coords * client.getScaledWindowSize()) / -2
	models.firstPerson.crosshair:setPos(coords.xy_)
end
modules.events.POST_RENDER:register(bfp.crosshairRender)

function bfp.render(delta, context)
	if context == "FIRST_PERSON" and previous.pose ~= "SLEEPING" then
		local rot = player:getRot(delta)

		-- Camera rot
		local add = modules.util.getHeadRot()

		-- Divide add amount based on animation
		for i = 1, 3 do
			if modules.animations.playing(i) then
				add = add * modules.animations[i].firstPersonBlend
				break
			end
		end

		add = add / 8
		add.z = add.z * 2
		renderer:offsetCameraRot(-add)

		-- -- Camera pos
		-- local add = models.cat.Head:getPos() + models.cat.Head:getAnimPos()
		-- vectors.rotateAroundAxis(-rot.x, add, vec(0, 0, 1))
		-- vectors.rotateAroundAxis(-rot.y, add, vec(0, 1, 0))
		-- renderer:setCameraPos(add * math.playerScale)
	elseif context == "RENDER" then
		renderer:offsetCameraRot()
		-- renderer:setCameraPos()
	end
end
modules.events.RENDER:register(bfp.render)



function bfp.setCrosshair(custom)
	if not custom then
		local oldTextureSize = models.firstPerson.crosshair:getTextureSize()
		local newTextureSize = vec(256, 256)
		models.firstPerson.crosshair:setPrimaryTexture("RESOURCE", "minecraft:textures/gui/icons.png")
		local scale = oldTextureSize / newTextureSize
		models.firstPerson.crosshair:getUVMatrix():scale(vec(scale.x, scale.y, 1))
	else
		models.firstPerson.crosshair:setPrimaryTexture("PRIMARY")
		models.firstPerson.crosshair:getUVMatrix():reset()
	end
end

return bfp
