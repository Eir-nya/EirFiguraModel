-- Client-side script for screwing with the camera

local camera = {
	frozen = false,
}

function camera.render(delta, context)
	if context ~= "FIRST_PERSON" and context ~= "RENDER" then
		return
	end

	if camera.frozen then
		renderer:setCameraRot(client:getCameraRot())
	end
end
modules.events.RENDER:register(camera.render)



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
