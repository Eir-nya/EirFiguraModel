local vt = {
    originalPos = {},
    originalRot = {},
}

function vt.render(delta, ctx)
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
    vt.restorePart(models.cat.Head)
    vt.restorePart(models.cat.Body)
    vt.restorePart(models.cat.LeftArm)
    vt.restorePart(models.cat.RightArm)
    vt.restorePart(models.cat.LeftLeg)
    vt.restorePart(models.cat.RightLeg)

    if previous.elytra then
        vt.restorePart(models.cat.Body.Elytra.left)
        vt.restorePart(models.cat.Body.Elytra.right)
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
    modelPart:setRot(-modelPart:getTrueRot())
end

function vt.restorePart(modelPart)
    modelPart:setPos(vt.originalPos[modelPart])
    modelPart:setRot(vt.originalRot[modelPart])
end

return vt
