-- Init script 

local init = function()
	-- Error check settings

	-- Check is entity:getNbt works (thanks Requiem/Locki)
	if not pcall(player.getNbt, player) then
		settings.misc.disableGetNbt = true
		settings.armor.vanitySlots = false
	end

	if not settings.misc.disableGetNbt then
		settings.armor.vanitySlots = client.isModLoaded("vanityslots")
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
