modules.events.RENDER:register(function(delta, ctx)
	if previous.firstPerson then
		return
	end

	models.cat.RightThigh:setPos(vanilla_model.RIGHT_LEG:getOriginPos() + vanilla_model.RIGHT_LEG:getPos())
	models.cat.LeftThigh:setPos(vanilla_model.LEFT_LEG:getOriginPos() + vanilla_model.LEFT_LEG:getPos())

	if previous.pose == "CROUCHING" then
		models.cat.RightThigh:setPos(models.cat.RightThigh:getPos() + vec(0, 0, 1.5))
		models.cat.LeftThigh:setPos(models.cat.LeftThigh:getPos() + vec(0, 0, 1.5))
		models.cat.RightThigh:setRot(vanilla_model.BODY:getOriginRot() / 1.5)
		models.cat.LeftThigh:setRot(vanilla_model.BODY:getOriginRot() / 1.5)
	else
		if settings.model.vanillaMatch then
			models.cat.RightThigh:setRot((vanilla_model.RIGHT_LEG:getOriginRot() + vanilla_model.RIGHT_LEG:getRot()) / 2)
			models.cat.LeftThigh:setRot((vanilla_model.LEFT_LEG:getOriginRot() + vanilla_model.LEFT_LEG:getRot()) / 2)
		else
			models.cat.RightThigh:setRot(vanilla_model.RIGHT_LEG:getOriginRot() + models.cat.RightLeg:getTrueRot() / 2)
			models.cat.LeftThigh:setRot(vanilla_model.LEFT_LEG:getOriginRot() + models.cat.LeftLeg:getTrueRot() / 2)
		end
	end
end)
