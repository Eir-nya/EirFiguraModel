-- Armor module

-- Enum defining which states a helmet may be in to allow ear rotation while worn.
local allowEarRotationEnum = {
	ALWAYS = 1,
	ONLY_DEFAULT = 2,
	ONLY_CUSTOM = 3
}

local armor = {
	-- Original rotation of ear armor
	earArmorRot = vec(-3, 3, 3.75), -- vec(0, 5, 0)
	-- Is ear armor visible?
	earArmorVisible = false,
	-- Whether ears may be rotate or not (only available on leather/chainmail/turtle, or on all helmets if settings.armor.earArmorMovement is enabled)
	canRotateEars = false,
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
	-- Which helmets allow ear rotation while worn?
	earRotationHelmets = {
		["minecraft:leather_helmet"] = allowEarRotationEnum.ALWAYS,
		["minecraft:chainmail_helmet"] = allowEarRotationEnum.ONLY_DEFAULT,
		["minecraft:turtle_helmet"] = allowEarRotationEnum.ONLY_CUSTOM,
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
	models.cat.Head:newItem("headItem")
		:scale(1.1, 1.1, 1.1)
		:pos(-0.05, 7.95, -0.05)
		:enabled(false)
	models.cat.Head:newBlock("headBlock")
		:scale(0.5625, 0.5625, 0.5625)
		:pos(-4.5, -0.5, -4.5)
		:enabled(false)
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

armor["custom model minecraft:leather_chestplate"] = function()
	models.cat.Body["Body Layer Down"]:setVisible(false)
	models.cat.LeftArm.FurUp:setVisible(false)
	models.cat.RightArm.FurUp:setVisible(false)
end


-- Armor equip helpers

function armor.equipEvent(item, slot)
	-- Is item visible?
	if armor.checkItemVisible(item) then
		local material = armor.getItemMaterial(item)

		armor.genericEquip(item)

		if not armor.useCustomModel(item) then
			-- Is material recognized?
			if armor.knownMaterial(material) then
				armor.defaultEquip(item)
			elseif slot == "helmet" then
				-- item/block render tasks
				armor.equipHelmetItem(item)
			end
		else
			-- Custom model displaying

			-- Display all parts defined in getPartsToEdit
			local parts = armor.getPartsToEdit({id = item.id}, "VISIBLE")
			for _, part in pairs(parts) do
				part:setVisible(true)
			end

			-- Function to run on custom model display
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
		if settings.armor.earArmor and armor.knownMaterial(material) then
			models.cat.Head.LeftEar.Ear:setVisible(false)
			models.cat.Head.RightEar.Ear:setVisible(false)
		end
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
		if settings.armor.earArmor and armor.knownMaterial(material) then
			models.cat.Head.LeftEar.Armor.default:setVisible(true)
			models.cat.Head.RightEar.Armor.default:setVisible(true)

			armor.earArmorVisible = true
			armor.canRotateEars = armor.checkCanRotateEars(item)

			-- Set UVs
			local uv = armor.getUVOffset(item, "earArmor")
			models.cat.Head.LeftEar.Armor.default:setUVPixels(uv)
			models.cat.Head.RightEar.Armor.default:setUVPixels(uv)
		end

		models.cat.Head:getTask("headItem"):enabled(false)
		models.cat.Head:getTask("headBlock"):enabled(false)

		models.cat.Head.Armor.default:setVisible(true)
		models.cat.Head.Armor.default:setUVPixels(armor.getUVOffset(item, "helmet"))
	elseif slot == "chestplate" then
		local uv = armor.getUVOffset(item, "chestplate")

		if settings.armor.boobArmor and armor.knownMaterial(material) then
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

	-- If a player head is being worn in the vanity head slot, it *must* be created using world.newItem with the SkullOwner tag.
	if type(item) == "table" then
		if item.id == "minecraft:player_head" then
			if item.tag and item.tag.SkullOwner then
				item = world.newItem("minecraft:player_head{SkullOwner:'" .. item.tag.SkullOwner.Name .. "'}")
			end
		else
			item = modules.util.asItemStack(item)
		end
	end

	models.cat.Head:getTask("headItem"):enabled(not isBlock)
	models.cat.Head:getTask("headBlock"):enabled(isBlock)
	if isBlock then
		models.cat.Head:getTask("headBlock"):block(item.id)
	else
		models.cat.Head:getTask("headItem"):item(item)
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

	armor.earArmorVisible = false
	armor.canRotateEars = false

	modules.util.setChildrenVisible(models.cat.Head.Armor, false)

	models.cat.Head:getTask("headItem"):enabled(false)
	models.cat.Head:getTask("headBlock"):enabled(false)

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
	local underscorePos = item.id:find("_")
	if underscorePos then
		return item.id:sub(underscorePos + 1, -1)
	end
end

function armor.getItemMaterial(item)
	local colonPos = item.id:find(":")
	local underscorePos = item.id:find("_")
	if colonPos and underscorePos then
		return item.id:sub(colonPos + 1, underscorePos - 1)
	end
end

function armor.knownMaterial(material)
	return armor.uvMults[material] ~= nil
end

function armor.checkItemVisible(item)
	return item.id ~= "minecraft:air" and not modules.util.startsWith(item.id, "vanityslots:") and (item.tag == nil or item.tag.PhantomInk == nil)
end

function armor.checkSkull(helmet)
	return modules.util.endsWith(helmet.id, "head") or modules.util.endsWith(helmet.id, "skull")
end

function armor.checkCanRotateEars(item)
	local canRotateEarSettings = armor.earRotationHelmets[item.id]

	if canRotateEarSettings == allowEarRotationEnum.ALWAYS then
		return true
	elseif canRotateEarSettings == allowEarRotationEnum.ONLY_CUSTOM then
		return armor.useCustomModel(item)
	elseif canRotateEarSettings == allowEarRotationEnum.ONLY_DEFAULT then
		return not armor.useCustomModel(item)
	end
	return false
end

return armor
