-- Client-side script for screwing with the camera

local camera = {
	frozen = false,
	yOffset = 0
}

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
	if camera.yOffset == 0 and (renderer:getCameraOffsetPivot() == nil or renderer:getCameraOffsetPivot().y == 0) then
		return
	end

	-- Handle camera offset
	local camOffset = renderer:getCameraOffsetPivot()
	if not camOffset then
		camOffset = 0
	else
		camOffset = camOffset.y
	end
	renderer:offsetCameraPivot(0, math.lerp(camOffset, camera.yOffset, 5 / client:getFPS()), 0)
	if math.abs(renderer:getCameraOffsetPivot().y) < 0.01 then
		renderer:offsetCameraPivot()
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
