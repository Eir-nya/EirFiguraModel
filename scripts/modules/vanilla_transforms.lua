local vt = {
	originalPos = {},
	originalRot = {},
}

if not settings.model.vanillaMatch then
	return
end

function vt.init()
	vanilla_model.HELMET:pos(vec(0, -1, 0))
	vanilla_model.CHESTPLATE:scale(vec(1, 1 - (1 / 12), 1))
	vanilla_model.CHESTPLATE:pos(vec(0, -1, 0))
	vanilla_model.CHESTPLATE_LEFT_ARM:scale(vec(0.75, 1 - (1 / 12), 1))
	vanilla_model.CHESTPLATE_LEFT_ARM:pos(vec(0, -1, 0))
	vanilla_model.CHESTPLATE_RIGHT_ARM:scale(vec(0.75, 1 - (1 / 12), 1))
	vanilla_model.CHESTPLATE_RIGHT_ARM:pos(vec(0, -1, 0))
end
modules.events.ENTITY_INIT:register(vt.init)

function vt.render(delta, ctx)
	if ctx ~= "RENDER" then
		return
	end

	vt.applyToVanillaPart(models.cat.Head, vanilla_model.HEAD, vanilla_model.HAT)
	vt.applyToVanillaPart(models.cat.Body, vanilla_model.BODY, vanilla_model.JACKET)
	vt.applyToVanillaPart(models.cat.LeftArm, vanilla_model.LEFT_ARM, vanilla_model.LEFT_SLEEVE)
	vt.applyToVanillaPart(models.cat.RightArm, vanilla_model.RIGHT_ARM, vanilla_model.RIGHT_SLEEVE)
	vt.applyToVanillaPart(models.cat.LeftLeg, vanilla_model.LEFT_LEG, vanilla_model.LEFT_PANTS)
	vt.applyToVanillaPart(models.cat.RightLeg, vanilla_model.RIGHT_LEG, vanilla_model.RIGHT_PANTS)

	if previous.elytra then
		vanilla_model.LEFT_ELYTRA:setPos(models.cat.Body.Elytra:getTruePos() + models.cat.Body.Elytra.left:getTruePos() + vanilla_model.BODY:getPos())
		vanilla_model.LEFT_ELYTRA:setRot(models.cat.Body.Elytra:getTrueRot() + models.cat.Body.Elytra.left:getTrueRot() + vanilla_model.BODY:getRot())
		vanilla_model.RIGHT_ELYTRA:setPos(models.cat.Body.Elytra:getTruePos() + models.cat.Body.Elytra.right:getTruePos() + vanilla_model.BODY:getPos())
		vanilla_model.RIGHT_ELYTRA:setRot(models.cat.Body.Elytra:getTrueRot() + models.cat.Body.Elytra.right:getTrueRot() + vanilla_model.BODY:getRot())
	end
end
modules.events.RENDER:register(vt.render)

function vt.postRender(delta, ctx)
	if modules.util.renderedInWorld(ctx) then
		vt.restorePart(models.cat.Head, vanilla_model.HEAD, vanilla_model.HAT)
		vt.restorePart(models.cat.Body, vanilla_model.BODY, vanilla_model.JACKET)
		vt.restorePart(models.cat.LeftArm, vanilla_model.LEFT_ARM, vanilla_model.LEFT_SLEEVE)
		vt.restorePart(models.cat.RightArm, vanilla_model.RIGHT_ARM, vanilla_model.RIGHT_SLEEVE)
		vt.restorePart(models.cat.LeftLeg, vanilla_model.LEFT_LEG, vanilla_model.LEFT_PANTS)
		vt.restorePart(models.cat.RightLeg, vanilla_model.RIGHT_LEG, vanilla_model.RIGHT_PANTS)

		if previous.elytra then
			vt.restorePart(models.cat.Body.Elytra.left, vanilla_model.LEFT_ELYTRA)
			vt.restorePart(models.cat.Body.Elytra.right, vanilla_model.RIGHT_ELYTRA)
		end
	else
		vt.restoreVanillaParts(vanilla_model.HEAD, vanilla_model.HAT)
		vt.restoreVanillaParts(vanilla_model.BODY, vanilla_model.JACKET)
		vt.restoreVanillaParts(vanilla_model.LEFT_ARM, vanilla_model.LEFT_SLEEVE)
		vt.restoreVanillaParts(vanilla_model.RIGHT_ARM, vanilla_model.RIGHT_SLEEVE)
		vt.restoreVanillaParts(vanilla_model.LEFT_LEG, vanilla_model.LEFT_PANTS)
		vt.restoreVanillaParts(vanilla_model.RIGHT_LEG, vanilla_model.RIGHT_PANTS)

		if previous.elytra then
			vt.restoreVanillaParts(vanilla_model.LEFT_ELYTRA)
			vt.restoreVanillaParts(vanilla_model.RIGHT_ELYTRA)
		end
	end
end
modules.events.POST_RENDER:register(vt.postRender)


function vt.applyToVanillaPart(modelPart, ...)
	vt.originalPos[modelPart] = modelPart:getPos()
	vt.originalRot[modelPart] = modelPart:getRot()

	local vanillaParts = {...}

	for _, vanillaPart in pairs(vanillaParts) do
		vanillaPart:setPos(modelPart:getTruePos())
		vanillaPart:setRot(vanillaPart:getOriginRot() + modelPart:getTrueRot())
	end
	modelPart:setPos(-modelPart:getTruePos())
	modelPart:setRot(0, 0, 0)
	modelPart:setRot(-modelPart:getTrueRot())
end

function vt.restorePart(modelPart)
	modelPart:setPos(vt.originalPos[modelPart])
	modelPart:setRot(vt.originalRot[modelPart])
end

function vt.restoreVanillaParts(...)
	for _, vanillaPart in pairs({...}) do
		vanillaPart:setPos()
		vanillaPart:setRot()
	end
end

return vt
