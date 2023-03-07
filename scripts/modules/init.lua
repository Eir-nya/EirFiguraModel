-- Init script 

local init = function()
	-- Error check settings

	-- Check is entity:getNbt works (thanks Requiem/Locki)
	if not pcall(player.getNbt, player) then
		settings.misc.disableGetNbt = true
		settings.armor.vanitySlots = false
	end

	if not settings.misc.disableGetNbt then
		-- If VanitySlots is not installed, disable the settings for it
		local testNbt = modules.util.getNbtValue("cardinal_components")
		local disableVanitySlotsSettings = testNbt == nil

		-- Cardinal components mod is installed
		if testNbt ~= nil then
			disableVanitySlotsSettings = testNbt["trinkets:trinkets"] == nil
			-- Trinkets mod is installed
			if testNbt["trinkets:trinkets"] ~= nil then
				disableVanitySlotsSettings = testNbt["trinkets:trinkets"].chest.vanity == nil
			end
		end

		if disableVanitySlotsSettings then
			settings.armor.vanitySlots = false
		end
	end
end
events.ENTITY_INIT:register(init)

-- Disable rendering of vanilla model, because figura tries to render both it and custom models
-- NOTE: When changing the "else" here, also update the complexity limit handler in scripts/complexity
if avatar:canEditVanillaModel() then
	vanilla_model.PLAYER:setVisible(false)
else
	models.cat.RightLeg:setVisible(false)
	models.cat.LeftLeg:setVisible(false)
	models.cat.Body.Body:setVisible(false)
	models.cat.Body["Body Layer"]:setVisible(false)
	models.cat.RightArm["Right Arm"]:setVisible(false)
	models.cat.LeftArm["Left Arm"]:setVisible(false)
end

-- Toggle snout
models.cat.Head.Snoot:setVisible(settings.model.snoot)
if settings.model.skull then
	models.cat.Skull.Snoot:setVisible(settings.model.snoot)
end

-- Set up skull model
if settings.model.skull then
	models.cat.Skull:setParentType("Skull")
else
	models.cat.Skull:setVisible(false)
end

-- Toggle new arms
models.cat.LeftArm.default:setVisible(not settings.model.newArms)
models.cat.RightArm.default:setVisible(not settings.model.newArms)
models.cat.LeftArm.new:setVisible(settings.model.newArms)
models.cat.RightArm.new:setVisible(settings.model.newArms)
