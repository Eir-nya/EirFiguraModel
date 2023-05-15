modules.events.RENDER:register(function(delta, ctx)
	local offset = vec(0, previous.pose == "CROUCHING" and 2.25 or 0, 0)
	models.cat:setPos(offset)
	models.cat.Body:setPos(offset)
	models.cat.RightArm:setPos(offset)
	models.cat.LeftArm:setPos(offset)
	models.cat.Head:setPos(offset)
end)
