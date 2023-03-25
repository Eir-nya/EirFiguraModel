-- Init script 

local init = function()
	-- Error check settings

	-- Check is entity:getNbt works (thanks Requiem/Locki)
	if not pcall(player.getNbt, player) then
		settings.misc.disableGetNbt = true
	end
	if settings.misc.disableGetNbt then
		settings.armor.vanitySlots = false
	else
		settings.armor.vanitySlots = client.isModLoaded("vanityslots")
	end

	-- Sync settings table on ENTITY_INIT so new players receive settings data
	if not host:isHost() then
		pings.requestSettings()
	end
end
events.ENTITY_INIT:register(init)

-- Disable rendering of vanilla model, because figura tries to render both it and custom models
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

models.cat:setPrimaryRenderType("CUTOUT_CULL")
