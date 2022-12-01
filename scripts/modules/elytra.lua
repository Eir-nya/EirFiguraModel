-- Elytra replacement module

local elytra = {
	-- Extra rotation applied to prevent overlap with tail
	extraRotL = vec(-12.25, -12.25, 0),
	extraRotR = vec(-12.25, 12.25, 0),
	-- Extra rotation applied while crouching
	extraRotCrouch = vec(math.deg(0.5), 0, 0),
}

-- Events

function elytra.initEvent()
	if not settings.model.elytra.enabled then
		models.cat.Body.Elytra:setVisible(false)
		return
	end

	vanilla_model.ELYTRA:setVisible(false)

	elytra.reset()
	models.cat.Body.Elytra.left.default:setPrimaryTexture("ELYTRA")
	models.cat.Body.Elytra.right.default:setPrimaryTexture("ELYTRA")
end
modules.events.ENTITY_INIT:register(elytra.initEvent)

-- Show or hide elytra model if it's equipped
function elytra.displayEvent()
	models.cat.Body.Elytra:setVisible(previous.elytra)
	if previous.elytra then
		models.cat.Body.Elytra:setSecondaryRenderType(previous.elytraGlint and "GLINT" or nil)
	end
end
modules.events.TICK:register(elytra.displayEvent)

function elytra.render(delta)
	if previous.elytra then
		local addToBoth = vec(0, 0, 0)
		if previous.pose == "CROUCHING" then
			addToBoth = addToBoth + elytra.extraRotCrouch
		end
		addToBoth = addToBoth + (models.cat.Body:getAnimRot() / -1.75)
		local yVel = math.min(math.lerp(previous.vel.y, player:getVelocity().y, delta), 0)
		addToBoth = addToBoth + vec(yVel * 20, 0, 0)

		local rotL = vanilla_model.LEFT_ELYTRA:getOriginRot()
		rotL = rotL + addToBoth
		rotL = rotL + elytra.extraRotL
		rotL = rotL + vec(0, yVel * 5, 0)
		models.cat.Body.Elytra.left:setRot(rotL)
		
		local rotR = vanilla_model.RIGHT_ELYTRA:getOriginRot()
		rotR = rotR + addToBoth
		rotR = rotR + elytra.extraRotR
		rotR = rotR + vec(0, yVel * -5, 0)
		models.cat.Body.Elytra.right:setRot(rotR)
	end
end
modules.events.RENDER:register(elytra.render)

-- Reset elytra position when exiting sit animation
function elytra.stopSitting()
	if not modules.sit.isSitting then
		elytra.reset()
	end
end
modules.events.sit:register(elytra.stopSitting)

-- Reset elytra position when exiting sleep pose
function elytra.stopSleeping()
	if previous.pose ~= "SLEEPING" then
		elytra.reset()
	end
end
modules.events.sleep:register(elytra.stopSleeping)



-- Resets elytra
function elytra.reset()
	if not settings.model.elytra.enabled then
		return
	end

	-- Set default elytra rotation so tail doesn't clip through
	-- if avatar:canEditVanillaModel() then
	models.cat.Body.Elytra.left:setRot(elytra.extraRotL)
	models.cat.Body.Elytra.right:setRot(elytra.extraRotR)
	-- end
end

return elytra
