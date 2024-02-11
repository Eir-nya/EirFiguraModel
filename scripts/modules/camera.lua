-- Client-side script for screwing with the camera

local camera = {
	frozen = false,
	yOffset = 0,
	headYOffset = -1 / 16
}

function camera.init()
	renderer:setEyeOffset(vec(0, camera.headYOffset, 0))
end
modules.events.ENTITY_INIT:register(camera.init)

function camera.render(delta, context)
	if context ~= "RENDER" then
		if context == "FIRST_PERSON" then
			renderer:setCameraPivot()
			renderer:setCameraRot()
			camera.frozen = false
		end
		return
	end

	if camera.frozen then
		renderer:setCameraRot(client:getCameraRot())
	end
end
modules.events.RENDER:register(camera.render)

function camera.renderOffsetPivot(delta, context)
	-- Handle camera offset
	local camOffset = renderer:getCameraOffsetPivot()
	if not camOffset then
		camOffset = vec(0, math.playerScale * camera.headYOffset, 0)
	else
		camOffset = camOffset
	end
	local target = vec(0, camera.headYOffset + camera.yOffset, 0) * math.playerScale
	renderer:offsetCameraPivot(math.lerp(camOffset, target, 5 / math.max(client:getFPS(), 5)))
	if math.abs((renderer:getCameraOffsetPivot() - target).y) < 0.01 then
		renderer:offsetCameraPivot(target)
	end
end
modules.events.POST_RENDER:register(camera.renderOffsetPivot)



function camera.setFreeze(newFrozen)
	camera.frozen = newFrozen
	if camera.frozen then
		renderer:setCameraPivot(client:getCameraPos() + (player:getLookDir() * 4 * (renderer:isCameraBackwards() and -1 or 1)))
		renderer:setFOV(1)
	else
		renderer:setCameraPivot()
		renderer:setCameraRot()
		renderer:setFOV()
	end
end

return camera
