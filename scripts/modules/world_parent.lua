local wp = {
	enabled = false
}

function wp.toggle(delta, ctx)
	if ctx == "FIRST_PERSON" or ctx == "PAPERDOLL" or ctx == "OTHER" then
		wp.setRenderType(false)
	else
		wp.setRenderType(true)
	end
end
modules.events.RENDER:register(wp.toggle)

function wp.update(delta, ctx)
	if not wp.enabled then
		return
	end

	models.cat:setPos(player:getPos(delta):scale(16) + vec(0, 0, 0))
	models.cat:setRot(vec(0, -player:getBodyYaw(delta) + 180, 0))

	models.cat:setLight(world.getBlockLightLevel(player:getPos(delta)), world.getSkyLightLevel(player:getPos(delta)))
end
modules.events.RENDER:register(wp.update)



function wp.setRenderType(parentToWorld)
	wp.enabled = parentToWorld
	if parentToWorld then
		models.cat:setParentType("WORLD")
		models.cat:setScale(vec(1, 1, 1):scale(math.playerScale))
	else
		models.cat:setParentType("NONE")
		models.cat:setScale()
		models.cat:setPos()
		models.cat:setRot()
	end
end

return wp
