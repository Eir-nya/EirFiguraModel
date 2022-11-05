-- Armor module

local armor = {
	-- (When ear armor is enabled) Original position of the ears
	originEarPosL = vec(0, 0, 0),
	originEarPosR = vec(0, 0, 0),
	-- (When ear armor is enabled) How much the ears should be offset while wearing a (displayed) helmet
	earOffset = vec(0, -0.5, 0),
	-- Original rotation of ear armor
	originEarArmor = vec(0, 5, 0),
	-- Whether or not the ear armor is currently visible
	earArmorVisible = false,
	-- Whether or not the ear armor should rotate to match ear rotation
	rotateArmor = false,
	-- Original position of the bow
	originBowPos = vec(0, 0, 0),
	-- How much the bow should be offset by while wearing a (displayed) helmet
	bowOffset = vec(0, 0, -0.5),
	-- Default color for leather armor
	leatherColor = vec(160/255, 101/255, 64/255),

	helmetUVs = {
		-- Ear armor UV offsets
		ears = {
			["minecraft:leather_helmet"] = vec(0, 0),
			["minecraft:chainmail_helmet"] = vec(14, 0),
			["minecraft:iron_helmet"] = vec(14, 0),
			["minecraft:golden_helmet"] = vec(28, 0),
			["minecraft:diamond_helmet"] = vec(42, 0),
			["minecraft:netherite_helmet"] = vec(56, 0),
			["minecraft:turtle_helmet"] = vec(70, 0)
		},
		-- TODO helmet
	},
	-- Chestplate armor UV offsets
	chestAddUVs = {
		body = {
			["minecraft:leather_chestplate"] = vec(0, 0),
			["minecraft:chainmail_chestplate"] = vec(24, 0),
			["minecraft:iron_chestplate"] = vec(48, 0),
			["minecraft:golden_chestplate"] = vec(72, 0),
			["minecraft:diamond_chestplate"] = vec(96, 0),
			["minecraft:netherite_chestplate"] = vec(120, 0)
		},
		arms = {
			["minecraft:leather_chestplate"] = vec(0, 0),
			["minecraft:chainmail_chestplate"] = vec(17, 0),
			["minecraft:iron_chestplate"] = vec(34, 0),
			["minecraft:golden_chestplate"] = vec(51, 0),
			["minecraft:diamond_chestplate"] = vec(68, 0),
			["minecraft:netherite_chestplate"] = vec(85, 0)
		},
	},
	-- Leggings armor UV offsets
	legsAddUVs = {
		bodyBottom = {
			["minecraft:leather_leggings"] = vec(0, 0),
			["minecraft:chainmail_leggings"] = vec(24, 0),
			["minecraft:iron_leggings"] = vec(48, 0),
			["minecraft:golden_leggings"] = vec(72, 0),
			["minecraft:diamond_leggings"] = vec(96, 0),
			["minecraft:netherite_leggings"] = vec(120, 0)
		},
		legs = {
			["minecraft:leather_leggings"] = vec(0, 0),
			["minecraft:chainmail_leggings"] = vec(16, 0),
			["minecraft:iron_leggings"] = vec(32, 0),
			["minecraft:golden_leggings"] = vec(48, 0),
			["minecraft:diamond_leggings"] = vec(64, 0),
			["minecraft:netherite_leggings"] = vec(80, 0)
		},
	}
}

-- Events

function armor.helmetEvent()
	-- Move bow forward if wearing displayed armor
	local shouldMoveAdornments = armor.checkMoveBow(previous.helmet)
	models.cat.Head.Bow:setPos(armor.originBowPos + (shouldMoveAdornments and armor.bowOffset or vec(0, 0, 0)))

	-- Check if ear armor should be moved
	if not settings.customArmor.earArmor then
		models.cat.Head.LeftEar:setPos(armor.originEarPosL + (shouldMoveAdornments and armor.earOffset or vec(0, 0, 0)))
		models.cat.Head.RightEar:setPos(armor.originEarPosR + (shouldMoveAdornments and armor.earOffset or vec(0, 0, 0)))
	end

	-- Check if vanilla head should be re-enabled + snoot hidden
	local isSkull = armor.checkSkull(previous.helmet)
	vanilla_model.HEAD:setVisible(isSkull)
	if settings.model.snoot then
		models.cat.Head.Snoot:setVisible(not isSkull)
	end

	-- Show/hide ear armor (controllable with settings)
	armor.showEarArmor(previous.helmet)
end
modules.events.helmet:register(armor.helmetEvent)
modules.events.invisible:register(armor.helmetEvent)
modules.events.sleep:register(armor.helmetEvent)
modules.events.sit:register(armor.helmetEvent)

-- Shows or hides chestplate and arm armor for a given chestplate ItemStack
function armor.showChestArmor()
	-- Toggle rendering of vanilla armor model, because figura tries to render both it and custom armor
	local show = armor.checkShowChestplate(previous.chestplate)
	vanilla_model.CHESTPLATE:setVisible(not show and previous.pose ~= "SLEEPING")

	models.cat.Body.Armor:setVisible(show)
	models.cat.Body.BoobArmor:setVisible(show and settings.boobArmor)
	models.cat.Body["Body Layer"]:setVisible(not show)
	models.cat.LeftArm.Armor:setVisible(show)
	models.cat.RightArm.Armor:setVisible(show)

	-- Show chest armor
	if show then
		-- Set UVs
		models.cat.Body.Armor:setUVPixels(armor.chestAddUVs.body[previous.chestplate.id])
		models.cat.Body.BoobArmor:setUVPixels(armor.chestAddUVs.body[previous.chestplate.id])
		models.cat.LeftArm.Armor:setUVPixels(armor.chestAddUVs.arms[previous.chestplate.id])
		models.cat.RightArm.Armor:setUVPixels(armor.chestAddUVs.arms[previous.chestplate.id])

		-- Colorize if leather armor
		local color = vec(1, 1, 1)
		if previous.chestplate.id == "minecraft:leather_chestplate" then
			color = armor.leatherColor
			if previous.chestplate.tag ~= nil and previous.chestplate.tag.display ~= nil then
				color = vectors.intToRGB(previous.chestplate.tag.display.color)
			end
		end
		models.cat.Body.Armor:setColor(color)
		models.cat.Body.BoobArmor:setColor(color)
		models.cat.LeftArm.Armor:setColor(color)
		models.cat.RightArm.Armor:setColor(color)

		-- Enable glint if applicable
		local shader = modules.util.asItemStack(previous.chestplate):hasGlint() and "Glint" or nil
		models.cat.Body.Armor:setSecondaryRenderType(shader)
		models.cat.Body.BoobArmor:setSecondaryRenderType(shader)
		models.cat.LeftArm.Armor:setSecondaryRenderType(shader)
		models.cat.RightArm.Armor:setSecondaryRenderType(shader)
	end

	-- Show or hide boobs if applicable
	local showBoobs = armor.checkShowBoobs(previous.chestplate)
	models.cat.Body.Boob:setVisible(showBoobs)
	models.cat.Body["Boob Layer"]:setVisible(showBoobs)
end
modules.events.chestplate:register(armor.showChestArmor)
modules.events.invisible:register(armor.showChestArmor)
modules.events.sleep:register(armor.showChestArmor)
modules.events.sit:register(armor.showChestArmor)

function armor.showPantsArmor()
	if previous.invisible then
		return
	end

	-- Toggle rendering of vanilla armor model, because figura tries to render both it and custom armor
	local show = armor.checkShowLeggings(previous.leggings)
	vanilla_model.LEGGINGS:setVisible(not show and previous.pose ~= "SLEEPING")

	models.cat.Body.ArmorBottom:setVisible(show)
	models.cat.LeftLeg.Armor:setVisible(show)
	models.cat.RightLeg.Armor:setVisible(show)

	-- Show booty shorts armor
	if show then
		-- Set UVs
		models.cat.Body.ArmorBottom:setUVPixels(armor.legsAddUVs.bodyBottom[previous.leggings.id])
		models.cat.LeftLeg.Armor:setUVPixels(armor.legsAddUVs.legs[previous.leggings.id])
		models.cat.RightLeg.Armor:setUVPixels(armor.legsAddUVs.legs[previous.leggings.id])

		-- Colorize if leather armor
		local color = vec(1, 1, 1)
		if previous.leggings.id == "minecraft:leather_leggings" then
			color = armor.leatherColor
			if previous.leggings.tag ~= nil and previous.leggings.tag.display ~= nil then
				color = vectors.intToRGB(previous.leggings.tag.display.color)
			end
		end
		models.cat.Body.ArmorBottom:setColor(color)
		models.cat.LeftLeg.Armor:setColor(color)
		models.cat.RightLeg.Armor:setColor(color)

		-- Enable glint if applicable
		local shader = modules.util.asItemStack(previous.leggings):hasGlint() and "Glint" or nil
		models.cat.Body.ArmorBottom:setSecondaryRenderType(shader)
		models.cat.LeftLeg.Armor:setSecondaryRenderType(shader)
		models.cat.RightLeg.Armor:setSecondaryRenderType(shader)
	end
end
modules.events.leggings:register(armor.showPantsArmor)
modules.events.invisible:register(armor.showPantsArmor)
modules.events.sleep:register(armor.showPantsArmor)
modules.events.sit:register(armor.showPantsArmor)



function armor.showEarArmor(helmet)
	armor.earArmorVisible = armor.checkShowEarArmor(helmet)

	models.cat.Head.LeftEar.Ear:setVisible(not armor.earArmorVisible)
	models.cat.Head.LeftEar.Armor:setVisible(armor.earArmorVisible)
	models.cat.Head.RightEar.Ear:setVisible(not armor.earArmorVisible)
	models.cat.Head.RightEar.Armor:setVisible(armor.earArmorVisible)

	-- Show ear armor, hide ears
	if armor.earArmorVisible then
		-- Set rotation variables (based on ear armor settings)
		-- Ear armor should rotate
		armor.rotateEarArmor = settings.customArmor.earArmorMovement or helmet.id == "minecraft:leather_helmet" or helmet.id == "minecraft:chainmail_helmet"

		-- Set UVs
		models.cat.Head.LeftEar.Armor:setUVPixels(armor.helmetUVs.ears[helmet.id])
		models.cat.Head.RightEar.Armor:setUVPixels(armor.helmetUVs.ears[helmet.id])

		-- Colorize if leather armor
		local color = vec(1, 1, 1)
		if helmet.id == "minecraft:leather_helmet" then
			color = armor.leatherColor
			if helmet.tag ~= nil and helmet.tag.display ~= nil then
				color = vectors.intToRGB(helmet.tag.display.color)
			end
		end
		models.cat.Head.LeftEar.Armor:setColor(color)
		models.cat.Head.RightEar.Armor:setColor(color)

		-- Enable glint if applicable
		local shader = modules.util.asItemStack(helmet):hasGlint() and "Glint" or nil
		models.cat.Head.LeftEar.Armor:setSecondaryRenderType(shader)
		models.cat.Head.RightEar.Armor:setSecondaryRenderType(shader)
	end
end

function armor.checkMoveBow(helmet)
	return helmet.id ~= "minecraft:air" and helmet.id ~= "vanityslots:familiar_wig" and (helmet.tag == nil or helmet.tag.PhantomInk == nil)
end

function armor.checkSkull(helmet)
	return modules.util.endsWith(helmet.id, "head") or modules.util.endsWith(helmet.id, "skull")
end

function armor.checkShowBoobs(chestplate)
	return chestplate.id == "minecraft:air" or chestplate.id == "minecraft:elytra" or chestplate.id == "vanityslots:familiar_shirt" or (chestplate.tag ~= nil and chestplate.tag.PhantomInk ~= nil)
end

function armor.checkShowEarArmor(helmet)
	local show = settings.customArmor.earArmor
	show = show and not previous.invisible
	show = show and previous.pose ~= "SLEEPING"
	show = show and not modules.sit.sitting
	show = show and armor.helmetUVs.ears[helmet.id] ~= nil
	show = show and helmet.id ~= "vanityslots:familiar_wig"
	show = show and (helmet.tag == nil or helmet.tag.PhantomInk == nil)
	return show
end

function armor.checkShowChestplate(chestplate)
	local show = settings.customArmor.chest
	show = show and not previous.invisible
	show = show and previous.pose ~= "SLEEPING"
	show = show and not modules.sit.sitting
	show = show and armor.chestAddUVs.body[chestplate.id] ~= nil
	show = show and chestplate.id ~= "vanityslots:familiar_shirt"
	show = show and (chestplate.tag == nil or chestplate.tag.PhantomInk == nil)
	return show
end

function armor.checkShowLeggings(leggings)
	local show = settings.customArmor.legs
	show = show and not previous.invisible
	show = show and previous.pose ~= "SLEEPING"
	show = show and not modules.sit.sitting
	show = show and armor.legsAddUVs.legs[leggings.id] ~= nil
	show = show and leggings.id ~= "vanityslots:familiar_pants"
	show = show and (leggings.tag == nil or leggings.tag.PhantomInk == nil)
	return show
end

return armor
