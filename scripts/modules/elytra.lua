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
	models.cat.Body.Elytra:setVisible(settings.model.elytra.custom)
	vanilla_model.ELYTRA:setVisible(not settings.model.elytra.custom)
	models.cat.Body.Elytra.left.default:setPrimaryTexture("ELYTRA")
	models.cat.Body.Elytra.right.default:setPrimaryTexture("ELYTRA")
	models.cat.Body.Elytra:setPrimaryRenderType("CUTOUT")

	elytra.reset()
end
modules.events.ENTITY_INIT:register(elytra.initEvent)

-- Show or hide elytra model if it's equipped
function elytra.displayEvent()
	models.cat.Body.Elytra:setVisible(previous.elytra and not previous.elytraHide)
	if previous.elytra and not previous.elytraHide then
		models.cat.Body.Elytra:setSecondaryRenderType(previous.elytraGlint and "GLINT" or nil)
	end
end
if settings.model.elytra.custom then
	modules.events.TICK:register(elytra.displayEvent)
end

function elytra.render(delta)
	if not settings.model.elytra.custom or previous.elytra then
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

		if previous.pose == "SLEEPING" then
			models.cat.Body.Elytra.left:setRot()
			models.cat.Body.Elytra.right:setRot()
		end
	end
end
modules.events.RENDER:register(elytra.render)



-- Checks if an item qualifies as an elytra
function elytra.isElytra(item)
	if item.id == "minecraft:elytra" then
		return true, false
	else
		local pos = item.id:find("_elytra")
		if pos ~= nil and pos > -1 then
			return item.id:sub(pos, -1) == "_elytra", true
		end
	end
	return false, false
end

-- Resets elytra
function elytra.reset()
	-- Set default elytra rotation so tail doesn't clip through
	models.cat.Body.Elytra.left:setRot(elytra.extraRotL)
	models.cat.Body.Elytra.right:setRot(elytra.extraRotR)
end

return elytra
