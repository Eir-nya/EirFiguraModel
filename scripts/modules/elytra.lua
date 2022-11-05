-- Elytra replacement module

local elytra = {}

-- Events

function elytra.initEvent()
	if not settings.model.elytra.enabled then
		models.elytra:setVisible(false)
		return
	end

	vanilla_model.ELYTRA:setVisible(false)

	elytra.reset()
	models.elytra:setPrimaryTexture("ELYTRA")
end
modules.events.ENTITY_INIT:register(elytra.initEvent)

-- Show or hide elytra model if it's equipped
function elytra.displayEvent()
	models.elytra:setVisible(previous.elytra)
	models.elytra:setSecondaryRenderType(previous.elytraGlint and "GLINT" or nil)
end
modules.events.chestplate:register(elytra.displayEvent)

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

	models.elytra.LEFT_ELYTRA:setPivot(-10, 24, -2)
	models.elytra.RIGHT_ELYTRA:setPivot(10, 24, -2)
	models.elytra.LEFT_ELYTRA:setPos(3, -0.5, -0.85)
	models.elytra.RIGHT_ELYTRA:setPos(-2, -0.5, -0.85)

	-- Set default elytra rotation so tail doesn't clip through
	-- if avatar:canEditVanillaModel() then
	models.elytra.LEFT_ELYTRA:setRot(vec(-2.5, -7.5, 0))
	models.elytra.RIGHT_ELYTRA:setRot(vec(-2.5, 7.5, 0))
	-- end
end

return elytra
