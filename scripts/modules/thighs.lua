modules.events.RENDER:register(function(delta, ctx)
	if ctx == "FIRST_PERSON" then
		return
	end

	local vanillaRightPos = vanilla_model.RIGHT_LEG:getOriginPos()
	local vanillaLeftPos = vanilla_model.LEFT_LEG:getOriginPos()
	local vanillaRightRot = vanilla_model.RIGHT_LEG:getOriginRot()
	local vanillaLeftRot = vanilla_model.LEFT_LEG:getOriginRot()
	if settings.model.vanillaMatch then
		if vanilla_model.RIGHT_LEG:getPos() then
			vanillaRightPos = vanillaRightPos + vanilla_model.RIGHT_LEG:getPos()
		end
		if vanilla_model.LEFT_LEG:getPos() then
			vanillaLeftPos = vanillaLeftPos + vanilla_model.LEFT_LEG:getPos()
		end
		if vanilla_model.RIGHT_LEG:getRot() then
			vanillaRightRot = vanillaRightRot + vanilla_model.RIGHT_LEG:getRot()
		end
		if vanilla_model.RIGHT_LEG:getRot() then
			vanillaLeftRot = vanillaLeftRot + vanilla_model.LEFT_LEG:getRot()
		end
	else
		vanillaRightPos = vanillaRightPos + models.cat.RightLeg:getTruePos()
		vanillaLeftPos = vanillaLeftPos + models.cat.LeftLeg:getTruePos()
		vanillaRightRot = vanillaRightRot + models.cat.RightLeg:getTrueRot()
		vanillaLeftRot = vanillaLeftRot + models.cat.LeftLeg:getTrueRot()
	end
	
	models.cat.RightThigh:setPos(vanillaRightPos)
	models.cat.LeftThigh:setPos(vanillaLeftPos)

	if player:isCrouching() then
		models.cat.RightThigh:setPos(models.cat.RightThigh:getPos() + vec(0, 0, 0.5))
		models.cat.LeftThigh:setPos(models.cat.LeftThigh:getPos() + vec(0, 0, 0.5))
		models.cat.RightThigh:setRot(vanilla_model.BODY:getOriginRot() / 1.5)
		models.cat.LeftThigh:setRot(vanilla_model.BODY:getOriginRot() / 1.5)
	else
		models.cat.RightThigh:setRot(vanillaRightRot / 2)
		models.cat.LeftThigh:setRot(vanillaLeftRot / 2)
	end
end)
