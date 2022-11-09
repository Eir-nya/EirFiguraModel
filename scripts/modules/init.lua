-- Init script 

local init = function()
	-- Error check settings
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
		models.skull.Skull.Snoot:setVisible(settings.model.snoot)
	end

	-- Set up skull model
	if settings.model.skull then
		models.skull.Skull:setParentType("Skull")
	else
		models.skull.Skull:setVisible(false)
	end

	-- Changes the wearer's nameplate to simply "Eir" if applicable
	if avatar:canEditNameplate() then
		if settings.misc.useCustomName then
			nameplate.ENTITY:setText(settings.misc.customName)
			nameplate.CHAT:setText(settings.misc.customName)
			nameplate.LIST:setText(settings.misc.customName)
		end
	end
end
modules.events.ENTITY_INIT:register(init)
