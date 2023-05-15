modules.events.RENDER:register(function(delta, ctx)
	if previous.firstPerson then
		return
	end

	local vanillaRightPos = vanilla_model.RIGHT_LEG:getOriginPos()
	if vanilla_model.RIGHT_LEG:getPos() then
		vanillaRightPos = vanillaRightPos + vanilla_model.RIGHT_LEG:getPos()
	end
	local vanillaLeftPos = vanilla_model.LEFT_LEG:getOriginPos()
	if vanilla_model.LEFT_LEG:getPos() then
		vanillaLeftPos = vanillaLeftPos + vanilla_model.LEFT_LEG:getPos()
	end
	local vanillaRightRot = vanilla_model.RIGHT_LEG:getOriginRot()
	if vanilla_model.RIGHT_LEG:getRot() then
		vanillaRightRot = vanillaRightRot + vanilla_model.RIGHT_LEG:getRot()
	end
	local vanillaLeftRot = vanilla_model.LEFT_LEG:getOriginRot()
	if vanilla_model.RIGHT_LEG:getRot() then
		vanillaLeftRot = vanillaLeftRot + vanilla_model.LEFT_LEG:getRot()
	end

	
	models.cat.RightThigh:setPos(vanillaRightPos)
	models.cat.LeftThigh:setPos(vanillaLeftPos)

	if previous.pose == "CROUCHING" then
		models.cat.RightThigh:setPos(models.cat.RightThigh:getPos() + vec(0, 0, 1.5))
		models.cat.LeftThigh:setPos(models.cat.LeftThigh:getPos() + vec(0, 0, 1.5))
		models.cat.RightThigh:setRot(vanilla_model.BODY:getOriginRot() / 1.5)
		models.cat.LeftThigh:setRot(vanilla_model.BODY:getOriginRot() / 1.5)
	else
		if settings.model.vanillaMatch then
			models.cat.RightThigh:setRot(vanillaRightRot / 2)
			models.cat.LeftThigh:setRot(vanillaLeftRot / 2)
		else
			models.cat.RightThigh:setRot(vanilla_model.RIGHT_LEG:getOriginRot() + models.cat.RightLeg:getTrueRot() / 2)
			models.cat.LeftThigh:setRot(vanilla_model.LEFT_LEG:getOriginRot() + models.cat.LeftLeg:getTrueRot() / 2)
		end
	end
end)
