-- Armor module

-- These ones are accessed by other scripts and should be kept:
-- armor.earArmorVisible
-- armor.rotateEarArmor

-- TODO: add a render task to models.cat.Head that renders an item or block in the head slot or head vanity slot
local armor = {
	-- Original rotation of ear armor
	earArmorRot = vec(-3, 3, 3.75), -- vec(0, 5, 0)
	-- Is ear armor visible?
	earArmorVisible = false,
	-- Whether ear armor should be able to rotate or not (only available on leather/chainmail, or on all helmets if settings.armor.earArmorMovement is enabled)
	rotateEarArmor = false,
	-- Default color for leather armor
	leatherColor = vec(160/255, 101/255, 64/255),


	-- Lookup tables

	-- Multiply uv functions by these amounts to display the desired armor type
	uvMults = {
		leather = 0,
		chainmail = 1,
		iron = 2,
		golden = 3,
		diamond = 4,
		netherite = 5,
		turtle = 6
	},
	-- Widths of different texture patterns in armor.png
	uvWidths = {
		earArmor = 14,
		helmet = 40,
		chestplate = 24,
		arms = 17,
		chestplateBottom = 24,
		leggings = 16,
		boots = 20
	},
}

-- Events

function armor.init()
	vanilla_model.HELMET:setVisible(false)
	vanilla_model.HELMET_ITEM:setVisible(false)
	vanilla_model.CHESTPLATE:setVisible(false)
	vanilla_model.LEGGINGS:setVisible(false)
	vanilla_model.BOOTS:setVisible(false)

	-- Set up render task to render items and blocks such as skulls
	-- TODO: use player:getItem(6):isBlockItem()
	models.cat.Head:addItem("headItem"):pos(0, 8, 0):enabled(false)
	models.cat.Head:addBlock("headBlock"):scale(0.5, 0.5, 0.5):pos(-4, 0, -4.1):enabled(false)
end
modules.events.ENTITY_INIT:register(armor.init)

function armor.helmetEvent()
	armor.unequipHelmet()
	armor.equipEvent(previous.helmet, "helmet")
end
function armor.chestplateEvent()
	armor.unequipChestplate()
	armor.equipEvent(previous.chestplate, "chestplate")
end
function armor.leggingsEvent()
	armor.unequipLeggings()
	armor.equipEvent(previous.leggings, "leggings")
end
function armor.bootsEvent()
	armor.unequipBoots()
	armor.equipEvent(previous.boots, "boots")
end
modules.events.helmet:register(armor.helmetEvent)
modules.events.chestplate:register(armor.chestplateEvent)
modules.events.leggings:register(armor.leggingsEvent)
modules.events.boots:register(armor.bootsEvent)
-- modules.events.invisible:register(armor.helmetEvent)
-- modules.events.invisible:register(armor.chestplateEvent)
-- modules.events.invisible:register(armor.leggingsEvent)
-- modules.events.invisible:register(armor.bootsEvent)



-- Custom armor model functions

armor["custom model minecraft:leather_helmet"] = function()
	modules.util.setChildrenVisible(models.cat.Head["3DHair"], false)
	models.cat.Head["3DHair"].north:setVisible(true)

	local parts = armor.getPartsToEdit({id = "minecraft:leather_helmet"}, "VISIBLE")
	for _, part in pairs(parts) do
		part:setVisible(true)
	end
end
armor["custom model minecraft:leather_chestplate"] = function()
	models.cat.Body["Body Layer Down"]:setVisible(false)
	models.cat.LeftArm.FurUp:setVisible(false)
	models.cat.RightArm.FurUp:setVisible(false)

	local parts = armor.getPartsToEdit({id = "minecraft:leather_chestplate"}, "VISIBLE")
	for _, part in pairs(parts) do
		part:setVisible(true)
	end
end
armor["custom model minecraft:leather_leggings"] = function()
	local parts = armor.getPartsToEdit({id = "minecraft:leather_leggings"}, "VISIBLE")
	for _, part in pairs(parts) do
		part:setVisible(true)
	end
end
armor["custom model minecraft:leather_boots"] = function()
	local parts = armor.getPartsToEdit({id = "minecraft:leather_boots"}, "VISIBLE")
	for _, part in pairs(parts) do
		part:setVisible(true)
	end
end


-- Armor equip helpers

function armor.equipEvent(item, slot)
	-- Is item visible?
	if armor.checkItemVisible(item) then
		local material = armor.getItemMaterial(item)

		armor.genericEquip(item)

		if not armor.useCustomModel(item) then
			-- Is helmet in recognized list of materials?
			local isKnownMaterial = armor.uvMults[material] ~= nil

			if isKnownMaterial then
				armor.defaultEquip(item)
			elseif slot == "helmet" then
				-- item/block render tasks
				armor.equipHelmetItem(item)
			end
		else
			-- Custom model displaying
			if armor["custom model " .. item.id] ~= nil then
				armor["custom model " .. item.id]()
			end
		end

		-- Colorize if leather armor
		if material == "leather" then
			armor.colorizeLeather(item)
		end
		armor.setGlint(item)
		if slot == "helmet" then
			models.cat.Head.Bow:setPos(vec(0, 0, -0.5))
		end
	end
end

function armor.genericEquip(item)
	local material = armor.getItemMaterial(item)
	local slot = armor.getItemSlot(item)

	if slot == "helmet" then
		if settings.armor.earArmor and armor.uvMults[material] ~= nil then
			models.cat.Head.LeftEar.Ear:setVisible(false)
			models.cat.Head.RightEar.Ear:setVisible(false)
		end
		modules.util.setChildrenVisible(models.cat.Head["3DHair"], false)
	elseif slot == "chestplate" then
		models.cat.Body["3DShirt"]:setVisible(false)
	elseif slot == "leggings" then
		models.cat.Body.Body:setVisible(false)
		models.cat.Body.Body2:setVisible(true)
		models.cat.LeftLeg.LeftLeg:setVisible(false)
		models.cat.LeftLeg.LeftLeg2:setVisible(true)
		models.cat.LeftLeg.LeftLeg3:setVisible(false)
		models.cat.RightLeg.RightLeg:setVisible(false)
		models.cat.RightLeg.RightLeg2:setVisible(true)
		models.cat.RightLeg.RightLeg3:setVisible(false)
	end
end

function armor.defaultEquip(item)
	local material = armor.getItemMaterial(item)
	local slot = armor.getItemSlot(item)

	if slot == "helmet" then
		if settings.armor.earArmor and armor.uvMults[material] ~= nil then
			models.cat.Head.LeftEar.Armor.default:setVisible(true)
			models.cat.Head.RightEar.Armor.default:setVisible(true)

			-- Set UVs
			local uv = armor.getUVOffset(item, "earArmor")
			models.cat.Head.LeftEar.Armor.default:setUVPixels(uv)
			models.cat.Head.RightEar.Armor.default:setUVPixels(uv)
		end

		-- TODO: disable 3d hair as well
		models.cat.Head:getTask("headItem"):enabled(false)
		models.cat.Head:getTask("headBlock"):enabled(false)

		models.cat.Head.Armor.default:setVisible(true)
		models.cat.Head.Armor.default:setUVPixels(armor.getUVOffset(item, "helmet"))
	elseif slot == "chestplate" then
		local uv = armor.getUVOffset(item, "chestplate")

		if settings.armor.boobArmor and armor.uvMults[material] ~= nil then
			models.cat.Body.Boobs.Armor.default:setVisible(true)
			models.cat.Body.Boobs.Armor.default:setUVPixels(uv)
		end
		models.cat.Body.Armor.default:setVisible(true)
		models.cat.Body.Armor.default:setUVPixels(uv)

		models.cat.LeftArm.Armor.default:setVisible(true)
		models.cat.RightArm.Armor.default:setVisible(true)

		uv = armor.getUVOffset(item, "arms")
		models.cat.LeftArm.Armor.default:setUVPixels(uv)
		models.cat.RightArm.Armor.default:setUVPixels(uv)
	elseif slot == "leggings" then
		models.cat.Body.ArmorBottom.default:setVisible(true)
		models.cat.LeftLeg.ArmorLeggings.default:setVisible(true)
		models.cat.RightLeg.ArmorLeggings.default:setVisible(true)

		local uv = armor.getUVOffset(item, "leggings")
		models.cat.Body.ArmorBottom.default:setUVPixels(armor.getUVOffset(item, "chestplateBottom"))
		models.cat.LeftLeg.ArmorLeggings.default:setUVPixels(uv)
		models.cat.RightLeg.ArmorLeggings.default:setUVPixels(uv)
	elseif slot == "boots" then
		models.cat.LeftLeg.ArmorBoots.default:setVisible(true)
		models.cat.RightLeg.ArmorBoots.default:setVisible(true)

		local uv = armor.getUVOffset(item, "boots")
		models.cat.LeftLeg.ArmorBoots.default:setUVPixels(uv)
		models.cat.RightLeg.ArmorBoots.default:setUVPixels(uv)
	end
end

function armor.equipHelmetItem(item)
	local isBlock = modules.util.asItemStack(item):isBlockItem() and not armor.checkSkull(item)

	models.cat.Head:getTask("headItem"):enabled(not isBlock)
	models.cat.Head:getTask("headBlock"):enabled(isBlock)
	if isBlock then
		models.cat.Head:getTask("headBlock"):block(item.id)
	else
		models.cat.Head:getTask("headItem"):item(item.id)
	end

	if settings.model.snoot then
		models.cat.Head.Snoot:setVisible(false)
	end
end


function armor.unequipHelmet()
	models.cat.Head.LeftEar.Ear:setVisible(true)
	models.cat.Head.RightEar.Ear:setVisible(true)

	modules.util.setChildrenVisible(models.cat.Head.LeftEar.Armor, false)
	modules.util.setChildrenVisible(models.cat.Head.RightEar.Armor, false)
	modules.util.setChildrenVisible(models.cat.Head.Armor, false)

	models.cat.Head:getTask("headItem"):enabled(false)
	models.cat.Head:getTask("headBlock"):enabled(false)

	-- TODO: re-enable rope physics hair if it's been hidden
	modules.util.setChildrenVisible(models.cat.Head["3DHair"])
	models.cat.Head.Bow:setVisible(true)
	models.cat.Head.Bow:setPos()
	if settings.model.snoot then
		models.cat.Head.Snoot:setVisible(true)
	end
end

function armor.unequipChestplate()
	models.cat.Body["Body Layer Down"]:setVisible(true)
	models.cat.Body["3DShirt"]:setVisible(true)
	models.cat.Body.Boobs.Armor:setVisible(false)
	models.cat.LeftArm.FurUp:setVisible(true)
	models.cat.RightArm.FurUp:setVisible(true)

	modules.util.setChildrenVisible(models.cat.Body.Armor, false)
	modules.util.setChildrenVisible(models.cat.Body.Boobs.Armor, false)
	modules.util.setChildrenVisible(models.cat.LeftArm.Armor, false)
	modules.util.setChildrenVisible(models.cat.RightArm.Armor, false)
end

function armor.unequipLeggings()
	models.cat.Body.Body:setVisible(true)
	models.cat.Body.Body2:setVisible(false)
	models.cat.LeftLeg.LeftLeg:setVisible(true)
	models.cat.LeftLeg.LeftLeg2:setVisible(false)
	models.cat.LeftLeg.LeftLeg3:setVisible(false)
	models.cat.RightLeg.RightLeg:setVisible(true)
	models.cat.RightLeg.RightLeg2:setVisible(false)
	models.cat.RightLeg.RightLeg3:setVisible(false)

	modules.util.setChildrenVisible(models.cat.Body.ArmorBottom, false)
	modules.util.setChildrenVisible(models.cat.LeftLeg.ArmorLeggings, false)
	modules.util.setChildrenVisible(models.cat.RightLeg.ArmorLeggings, false)
end

function armor.unequipBoots()
	modules.util.setChildrenVisible(models.cat.LeftLeg.ArmorBoots, false)
	modules.util.setChildrenVisible(models.cat.RightLeg.ArmorBoots, false)
end

function armor.colorizeLeather(item)
	local color = armor.leatherColor
	if item.tag ~= nil and item.tag.display ~= nil then
		color = vectors.intToRGB(item.tag.display.color)
	end

	local parts = armor.getPartsToEdit(item, "COLOR")
	for _, part in pairs(parts) do
		part:setColor(color)
	end
end

function armor.setGlint(item)
	local shader = modules.util.asItemStack(item):hasGlint() and "Glint" or nil

	local parts = armor.getPartsToEdit(item, "GLINT")
	for _, part in pairs(parts) do
		part:setSecondaryRenderType(shader)
	end
end

-- mode: COLOR or GLINT
function armor.getPartsToEdit(item, mode)
	local parts = {}

	local slot = armor.getItemSlot(item)

	-- Custom models
	if armor.useCustomModel(item) then
		local material = armor.getItemMaterial(item)

		if material == "leather" then
			if slot == "helmet" then
				if settings.armor.earArmor then
					table.insert(parts, models.cat.Head.LeftEar.Armor.FluffyHood)
					table.insert(parts, models.cat.Head.RightEar.Armor.FluffyHood)
				end
				if mode == "COLOR" then
					table.insert(parts, models.cat.Head.Armor.FluffyHood.leather)
				else
					table.insert(parts, models.cat.Head.Armor.FluffyHood)
				end
			elseif slot == "chestplate" then
				if mode == "COLOR" then
					table.insert(parts, models.cat.Body.Boobs.Armor.FluffyJacket.leather)
					table.insert(parts, models.cat.Body.Armor.FluffyJacket.leather)
					table.insert(parts, models.cat.LeftArm.Armor.FluffyJacket.leather)
					table.insert(parts, models.cat.RightArm.Armor.FluffyJacket.leather)
				else
					table.insert(parts, models.cat.Body.Boobs.Armor.FluffyJacket)
					table.insert(parts, models.cat.Body.Armor.FluffyJacket)
					table.insert(parts, models.cat.LeftArm.Armor.FluffyJacket)
					table.insert(parts, models.cat.RightArm.Armor.FluffyJacket)
				end
			elseif slot == "leggings" then
				table.insert(parts, models.cat.Body.ArmorBottom.FluffyLeggings)
				if mode == "COLOR" then
					table.insert(parts, models.cat.LeftLeg.ArmorLeggings.FluffyLeggings.leather)
					table.insert(parts, models.cat.RightLeg.ArmorLeggings.FluffyLeggings.leather)
				else
					table.insert(parts, models.cat.LeftLeg.ArmorLeggings.FluffyLeggings)
					table.insert(parts, models.cat.RightLeg.ArmorLeggings.FluffyLeggings)
				end
			elseif slot == "boots" then
				if mode == "COLOR" then
					table.insert(parts, models.cat.LeftLeg.ArmorBoots.FluffyBoots.leather)
					table.insert(parts, models.cat.RightLeg.ArmorBoots.FluffyBoots.leather)
				else
					table.insert(parts, models.cat.LeftLeg.ArmorBoots.FluffyBoots)
					table.insert(parts, models.cat.RightLeg.ArmorBoots.FluffyBoots)
				end
			end
		end
	else
		if slot == "helmet" then
			table.insert(parts, models.cat.Head.LeftEar.Armor.default)
			table.insert(parts, models.cat.Head.RightEar.Armor.default)
			table.insert(parts, models.cat.Head.Armor.default)
		elseif slot == "chestplate" then
			table.insert(parts, models.cat.Body.Boobs.Armor.default)
			table.insert(parts, models.cat.Body.Armor.default)
			table.insert(parts, models.cat.LeftArm.Armor.default)
			table.insert(parts, models.cat.RightArm.Armor.default)
		elseif slot == "leggings" then
			table.insert(parts, models.cat.Body.ArmorBottom.default)
			table.insert(parts, models.cat.LeftLeg.ArmorLeggings.default)
			table.insert(parts, models.cat.RightLeg.ArmorLeggings.default)
		elseif slot == "boots" then
			table.insert(parts, models.cat.LeftLeg.ArmorBoots.default)
			table.insert(parts, models.cat.RightLeg.ArmorBoots.default)
		end
	end

	return parts
end


-- Utility functions

function armor.useCustomModel(item)
	return settings.armor.customModel[armor.getItemMaterial(item)]
end

function armor.getUVOffset(item, armorPiece)
	return armor.uvMults[armor.getItemMaterial(item)] * armor.uvWidths[armorPiece]
end

function armor.getItemSlot(item)
	return item.id:sub(item.id:find("_") + 1, -1)
end

function armor.getItemMaterial(item)
	return item.id:sub(item.id:find(":") + 1, item.id:find("_") - 1)
end

function armor.checkItemVisible(item)
	return item.id ~= "minecraft:air" and not modules.util.startsWith(item.id, "vanityslots:") and (item.tag == nil or item.tag.PhantomInk == nil)
end

function armor.checkSkull(helmet)
	return modules.util.endsWith(helmet.id, "head") or modules.util.endsWith(helmet.id, "skull")
end

return armor

--[[
local armor = {
	-- (When ear armor is enabled) How much the ears should be offset while wearing a (displayed) helmet
	earOffset = vec(0, -0.5, 0),
	-- Original rotation of ear armor
	originEarArmor = vec(0, 5, 0),
	-- Whether or not the ear armor is currently visible
	earArmorVisible = false,
	-- Whether or not the ear armor should rotate to match ear rotation
	rotateEarArmor = false,
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
	models.cat.Head.Bow:setPos(shouldMoveAdornments and armor.bowOffset or nil)

	-- Check if ear armor should be moved
	if not settings.armor.earArmor then
		models.cat.Head.LeftEar:setPos(armor.originEarPosL + (shouldMoveAdornments and armor.earOffset or vec(0, 0, 0)))
		models.cat.Head.RightEar:setPos(armor.originEarPosR + (shouldMoveAdornments and armor.earOffset or vec(0, 0, 0)))
	end

	-- Check if vanilla head should be re-enabled + snoot hidden
	-- TODO
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

-- Shows or hides chestplate and arm armor for a given chestplate ItemStack
function armor.showChestArmor()
	-- Toggle rendering of vanilla armor model, because figura tries to render both it and custom armor
	local show = armor.checkShowChestplate(previous.chestplate)
	vanilla_model.CHESTPLATE:setVisible(not show and previous.pose ~= "SLEEPING")

	models.cat.Body.Armor.default:setVisible(show)
	models.cat.Body["3DShirt"]:setVisible(not show)
	models.cat.Body.Boobs.Armor.default:setVisible(show and settings.armor.boobArmor)
	models.cat.Body["Body Layer Up"]:setVisible(not show)
	models.cat.Body["Body Layer Down"]:setVisible(not show)
	models.cat.LeftArm.Armor.default:setVisible(show)
	models.cat.RightArm.Armor.default:setVisible(show)

	-- Show chest armor
	if show then
		-- Set UVs
		models.cat.Body.Armor.default:setUVPixels(armor.chestAddUVs.body[previous.chestplate.id])
		models.cat.Body.Boobs.Armor.default:setUVPixels(armor.chestAddUVs.body[previous.chestplate.id])
		models.cat.LeftArm.Armor.default:setUVPixels(armor.chestAddUVs.arms[previous.chestplate.id])
		models.cat.RightArm.Armor.default:setUVPixels(armor.chestAddUVs.arms[previous.chestplate.id])

		-- Colorize if leather armor
		local color = vec(1, 1, 1)
		if previous.chestplate.id == "minecraft:leather_chestplate" then
			color = armor.leatherColor
			if previous.chestplate.tag ~= nil and previous.chestplate.tag.display ~= nil then
				color = vectors.intToRGB(previous.chestplate.tag.display.color)
			end
		end
		models.cat.Body.Armor.default:setColor(color)
		models.cat.Body.Boobs.Armor.default:setColor(color)
		models.cat.LeftArm.Armor.default:setColor(color)
		models.cat.RightArm.Armor.default:setColor(color)

		-- Enable glint if applicable
		local shader = modules.util.asItemStack(previous.chestplate):hasGlint() and "Glint" or nil
		models.cat.Body.Armor.default:setSecondaryRenderType(shader)
		models.cat.Body.Boobs.Armor.default:setSecondaryRenderType(shader)
		models.cat.LeftArm.Armor.default:setSecondaryRenderType(shader)
		models.cat.RightArm.Armor.default:setSecondaryRenderType(shader)
	end

	-- Show or hide boobs if applicable
	local showBoobs = armor.checkShowBoobs(previous.chestplate)
	models.cat.Body.Boobs.default:setVisible(showBoobs)
end
modules.events.chestplate:register(armor.showChestArmor)
modules.events.invisible:register(armor.showChestArmor)

function armor.showPantsArmor()
	if previous.invisible then
		return
	end

	-- Toggle rendering of vanilla armor model, because figura tries to render both it and custom armor
	local show = armor.checkShowLeggings(previous.leggings)
	vanilla_model.LEGGINGS:setVisible(not show and previous.pose ~= "SLEEPING")

	models.cat.Body.ArmorBottom.default:setVisible(show)
	models.cat.LeftLeg.Armor.default:setVisible(show)
	models.cat.RightLeg.Armor.default:setVisible(show)

	-- Show booty shorts armor
	if show then
		-- Set UVs
		models.cat.Body.ArmorBottom.default:setUVPixels(armor.legsAddUVs.bodyBottom[previous.leggings.id])
		models.cat.LeftLeg.Armor.default:setUVPixels(armor.legsAddUVs.legs[previous.leggings.id])
		models.cat.RightLeg.Armor.default:setUVPixels(armor.legsAddUVs.legs[previous.leggings.id])

		-- Colorize if leather armor
		local color = vec(1, 1, 1)
		if previous.leggings.id == "minecraft:leather_leggings" then
			color = armor.leatherColor
			if previous.leggings.tag ~= nil and previous.leggings.tag.display ~= nil then
				color = vectors.intToRGB(previous.leggings.tag.display.color)
			end
		end
		models.cat.Body.ArmorBottom.default:setColor(color)
		models.cat.LeftLeg.Armor.default:setColor(color)
		models.cat.RightLeg.Armor.default:setColor(color)

		-- Enable glint if applicable
		local shader = modules.util.asItemStack(previous.leggings):hasGlint() and "Glint" or nil
		models.cat.Body.ArmorBottom.default:setSecondaryRenderType(shader)
		models.cat.LeftLeg.Armor.default:setSecondaryRenderType(shader)
		models.cat.RightLeg.Armor.default:setSecondaryRenderType(shader)
	end
end
modules.events.leggings:register(armor.showPantsArmor)
modules.events.invisible:register(armor.showPantsArmor)



function armor.showEarArmor(helmet)
	armor.earArmorVisible = armor.checkShowEarArmor(helmet)

	models.cat.Head.LeftEar.Ear:setVisible(not armor.earArmorVisible)
	models.cat.Head.LeftEar.Armor.default:setVisible(armor.earArmorVisible)
	models.cat.Head.RightEar.Ear:setVisible(not armor.earArmorVisible)
	models.cat.Head.RightEar.Armor.default:setVisible(armor.earArmorVisible)

	-- Show ear armor, hide ears
	if armor.earArmorVisible then
		-- Set rotation variables (based on ear armor settings)
		-- Ear armor should rotate
		armor.rotateEarArmor = settings.armor.earArmorMovement or helmet.id == "minecraft:leather_helmet" or helmet.id == "minecraft:chainmail_helmet"

		-- Set UVs
		models.cat.Head.LeftEar.Armor.default:setUVPixels(armor.helmetUVs.ears[helmet.id])
		models.cat.Head.RightEar.Armor.default:setUVPixels(armor.helmetUVs.ears[helmet.id])

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
	local show = settings.armor.earArmor
	show = show and not previous.invisible
	show = show and armor.helmetUVs.ears[helmet.id] ~= nil
	show = show and helmet.id ~= "vanityslots:familiar_wig"
	show = show and (helmet.tag == nil or helmet.tag.PhantomInk == nil)
	return show
end

function armor.checkShowChestplate(chestplate)
	local show = not previous.invisible
	show = show and armor.chestAddUVs.body[chestplate.id] ~= nil
	show = show and chestplate.id ~= "vanityslots:familiar_shirt"
	show = show and (chestplate.tag == nil or chestplate.tag.PhantomInk == nil)
	return show
end

function armor.checkShowLeggings(leggings)
	local show = not previous.invisible
	show = show and armor.legsAddUVs.legs[leggings.id] ~= nil
	show = show and leggings.id ~= "vanityslots:familiar_pants"
	show = show and (leggings.tag == nil or leggings.tag.PhantomInk == nil)
	return show
end

return armor
]]--
