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

modules.events.ENTITY_INIT:register(function()
	function camera.renderOffsetPivot(delta, context)
		-- Handle camera offset
		local camOffset = renderer:getCameraOffsetPivot()
		if not camOffset then
			camOffset = 0
		else
			camOffset = camOffset.y
		end
		renderer:offsetCameraPivot(0, math.lerp(camOffset, camera.yOffset, 5 / client:getFPS()), 0)
	end
	modules.events.RENDER:register(camera.renderOffsetPivot)
end)



function camera.toggleFreeze()
	camera.frozen = not camera.frozen
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
