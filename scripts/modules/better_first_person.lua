local bfp = {}

function bfp.init()
	-- TODO: if custom crosshair/better first person view is disabled, just hide custom croshair
	renderer.renderCrosshair = false
	models.firstPerson.crosshair:setParentType("Gui")

	bfp.setCrosshair(true) -- TODO
end
modules.events.ENTITY_INIT:register(bfp.init)

function bfp.hideArms(delta, context)
	-- TODO: what about armor in first person?
	if context == "FIRST_PERSON" then
		models.cat.LeftArm:setParentType("None")
		models.cat.RightArm:setParentType("None")
	else
		models.cat.LeftArm:setParentType("LeftArm")
		models.cat.RightArm:setParentType("RightArm")
	end
end
modules.events.RENDER:register(bfp.hideArms)

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
		models.firstPerson.crosshair:setRot()
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
	if context == "FIRST_PERSON" then
		local rot = player:getRot(delta)

		modules.animations.jump.anim:blend(modules.animations.jump.anim:getBlend() / 3)

		-- Camera rot
		local add = modules.util.getHeadRot()

		-- Divide add amount based on animation
		if modules.animations.primaryPlaying() then
			add = add * modules.animations.primaryAnim.firstPersonBlend
		elseif modules.animations.secondaryPlaying() then
			add = add * modules.animations.secondaryAnim.firstPersonBlend
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
