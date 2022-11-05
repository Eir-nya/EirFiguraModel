local bfp = {}

function bfp.init()
	-- TODO: if custom crosshair/better first person view is disabled, just hide custom croshair
	renderer.renderCrosshair = false
	models.firstPerson.crosshair:setParentType("Gui")

	bfp.setCrosshair(true) -- TODO
end
modules.events.ENTITY_INIT:register(bfp.init)

function bfp.hideArms(delta, context)
	if context == "FIRST_PERSON" then
		models.cat.LeftArm:setVisible(false)
		models.cat.RightArm:setVisible(false)
	else
		models.cat.LeftArm:setVisible(true)
		models.cat.RightArm:setVisible(true)
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
	models.firstPerson.crosshair:setVisible(not player:isUsingItem() or player:getItem(1).id == "minecraft:bow" or player:getItem(1).id == "minecraft:trident")

	local playerEyePos = player:getPos(delta):add(0, player:getEyeHeight(), 0)
	playerEyePos:add(player:getLookDir() * 5)

	-- Translate coords to screen space; center crosshair
	local screenSpace = vectors.worldToScreenSpace(playerEyePos)
	local coords = screenSpace.xy + vec(1, 1)
	coords = (coords * client.getScaledWindowSize()) / -2
	models.firstPerson.crosshair:setPos(coords.xy_)
end
modules.events.POST_RENDER:register(bfp.crosshairRender)

function bfp.render(delta, context)
	if context == "FIRST_PERSON" then
		local rot = player:getRot(delta)

		animations["models.cat"].jump:blend(animations["models.cat"].jump:getBlend() / 3)

		-- Camera rot
		local add = (modules.util.getHeadRot() - vanilla_model.HEAD:getOriginRot())

		-- Divide add amount based on animation
		if modules.extra_animations.attackAnimPlaying() then
			add = add / 2
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
