-- Armor module

-- Enum defining which states a helmet may be in to allow ear rotation while worn.
local allowEarRotationEnum = {
	ALWAYS = 1,
	ONLY_DEFAULT = 2,
	ONLY_CUSTOM = 3
}

local armor = {
	-- Display armor
	display = true,
	-- Is ear armor visible?
	earArmorVisible = false,
	-- Whether ears may be rotate or not (only available on leather/chainmail/turtle, or on all helmets if settings.armor.earArmorMovement is enabled)
	canRotateEars = false,
	-- Default color for leather armor
	leatherColor = vec(160/255, 101/255, 64/255),

	-- Size of armor.png
	armorTexOriginalSize = models.cat.Body.Armor.default:getTextureSize(),


	-- Lookup tables

	-- Override texture sizes for modded armor texture images
	textureSizes = {
		-- gilded_netherite_layer_1 = vec(64, 32),
	},
	-- Override texture paths for armor pieces (starts in "textures/models/armor/", "_layer_1/2.png" is appended later)
	texturePaths = {
		golden = "gold",
		diving = { prefix = "copper", appendLayer = false, namespace = "create", hideSnout = true },
		copper = { prefix = "copper", appendLayer = false, namespace = "create", hideSnout = true },
		ferocious = "gemstone",
		sylph = "gemstone",
		oread = "gemstone",
		crystalite = "broken", -- Broken intentionally. The texture sucks for some reason.
		olvite = "paradise_lost_olvite",
		phoenix = "paradise_lost_phoenix",
	},

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
		helmet = 32,
		chestplate = 24,
		arms = 16,
		chestplateBottom = 24,
		leggings = 16,
		boots = 16
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
	vanilla_model.ARMOR:setVisible(false)
	vanilla_model.HELMET_ITEM:setVisible(false)

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
	if armor.display then
		armor.equipEvent(previous.helmet, "helmet")
	end
end
function armor.chestplateEvent()
	armor.unequipChestplate()
	if armor.display then
		armor.equipEvent(previous.chestplate, "chestplate")
	end
end
function armor.leggingsEvent()
	armor.unequipLeggings()
	if armor.display then
		armor.equipEvent(previous.leggings, "leggings")
	end
end
function armor.bootsEvent()
	armor.unequipBoots()
	if armor.display then
		armor.equipEvent(previous.boots, "boots")
	end
end
modules.events.helmet:register(armor.helmetEvent)
modules.events.chestplate:register(armor.chestplateEvent)
modules.events.leggings:register(armor.leggingsEvent)
modules.events.boots:register(armor.bootsEvent)



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
			if armor.knownMaterial(material) or (slot == "chestplate" and previous.elytra) then
				armor.defaultEquip(item)
			-- If not, assume it's a modded armor, and try to equip that
			else
				local isModdedArmor = armor.useDefaultTexture(item, slot)
				if not isModdedArmor then
					-- If all else fails, assume that an unrecognized helmet is, in fact, an item or block
					if slot == "helmet" and not modules.util.asItemStack(item, 2):isArmor() then
						-- item/block render tasks
						armor.equipHelmetItem(item)
					-- Use vanilla armor piece if applicable
					elseif settings.model.vanillaMatch then
						vanilla_model[slot]:setVisible(true)
						if slot == "chestplate" then
							models.cat.Body.Boobs:setVisible(false)
							models.cat.Body["3DHairBoobs"]:setVisible(false)
						end
					end
				end
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
		modules.clothes.setVisible("top", false)
	elseif slot == "leggings" then
		modules.clothes.setVisible("bottom", false)
	elseif slot == "boots" then
		modules.clothes.setVisible("feet", false)
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

		armor.useDefaultTexture(item, slot)
	elseif slot == "chestplate" then
		local uv = armor.getUVOffset(item, "chestplate")

		if settings.armor.boobArmor and armor.knownMaterial(material) then
			models.cat.Body.Boobs.Armor.default:setVisible(true)
			models.cat.Body.Boobs.Armor.default:setPrimaryTexture("PRIMARY")
			models.cat.Body.Boobs.Armor.default:setUVPixels(uv)
		end
		models.cat.Body.Armor.default:setVisible(true)
		models.cat.Body.Armor.default:setPrimaryTexture("PRIMARY")
		models.cat.Body.Armor.default:getUVMatrix():reset()
		models.cat.Body.Armor.default:setUVPixels(uv)

		-- Get array of ModelParts to apply operations to
		local armArmorParts = {
			[models.cat.LeftArm.Armor.default] = true,
			[models.cat.LeftArm.Forearm.Armor.default] = true,
			[models.cat.RightArm.Armor.default] = true,
			[models.cat.RightArm.Forearm.Armor.default] = true,
		}

		for modelPart in pairs(armArmorParts) do
			modelPart:setVisible(true)
			modelPart:setPrimaryTexture("PRIMARY")
			modelPart:getUVMatrix():reset()
		end

		uv = armor.getUVOffset(item, "arms")
		for modelPart in pairs(armArmorParts) do
			modelPart:setUVPixels(uv)
		end
	elseif slot == "leggings" then
		models.cat.Body.ArmorBottom.default:setVisible(true)
		models.cat.Body.ArmorBottom.default:setPrimaryTexture("PRIMARY")
		models.cat.Body.ArmorBottom.default:getUVMatrix():reset()
		models.cat.LeftLeg.ArmorLeggings.default:setVisible(true)
		models.cat.LeftLeg.ArmorLeggings.default:setPrimaryTexture("PRIMARY")
		models.cat.LeftLeg.ArmorLeggings.default:getUVMatrix():reset()
		models.cat.RightLeg.ArmorLeggings.default:setVisible(true)
		models.cat.RightLeg.ArmorLeggings.default:setPrimaryTexture("PRIMARY")
		models.cat.RightLeg.ArmorLeggings.default:getUVMatrix():reset()

		local uv = armor.getUVOffset(item, "leggings")
		models.cat.Body.ArmorBottom.default:setUVPixels(armor.getUVOffset(item, "chestplateBottom"))
		models.cat.LeftLeg.ArmorLeggings.default:setUVPixels(uv)
		models.cat.RightLeg.ArmorLeggings.default:setUVPixels(uv)
	elseif slot == "boots" then
		armor.useDefaultTexture(item, slot)
	end
end

-- Returns bool: true if texture is found, false if not
function armor.useDefaultTexture(item, slot)
	local underscoreFound, lastUnderscore = item.id:find(".*_")
	if not underscoreFound then
		return false
	end

	-- Fetch resource prefix with string substitution
	local prefix = item.id:sub(item.id:find(":") + 1, lastUnderscore - 1)
	-- Test if resource exists
	local imageName = armor.texturePaths[prefix]
	if not imageName then
		imageName = prefix
	end
	if type(imageName) == "table" then
		imageName = armor.texturePaths[prefix].prefix
	end
	local resourcePath = "textures/models/armor/" .. imageName
	if type(armor.texturePaths[prefix]) ~= "table" or armor.texturePaths[prefix].appendLayer then
		resourcePath = resourcePath.. (slot == "leggings" and "_layer_2" or "_layer_1")
	end
	resourcePath = resourcePath .. ".png"
	if type(armor.texturePaths[prefix]) == "table" and armor.texturePaths[prefix].namespace then
		resourcePath = armor.texturePaths[prefix].namespace .. ":" .. resourcePath
	end
	if not client.hasResource(resourcePath) then
		resourcePath = "textures/models/armor/" .. imageName .. ".png"
		if not client.hasResource(resourcePath) then
			return false
		end
	end

	-- Client has resource. Proceed to apply them.
	local newTextureSize = armor.textureSizes[imageName]
	if not newTextureSize then
		newTextureSize = vec(64, 32) -- Default armor texture size, unless otherwise specified
	end
	local texScale = armor.armorTexOriginalSize / newTextureSize
	texScale = vec(texScale.x, texScale.y, 1)

	local partsToShow = armor.getPartsToEdit(item, "EXCLUDE_EARS")
	for _, part in pairs(partsToShow) do
		part:setVisible(true)
		part:setPrimaryTexture("RESOURCE", resourcePath)
	end

	-- Hide snout
	if slot == "helmet" then
		models.cat.Head.Snoot:setVisible(type(armor.texturePaths[prefix]) ~= "table" or not armor.texturePaths[prefix].hideSnout)
	end

	if slot == "chestplate" then
		models.cat.Body.Boobs.Armor.default:setUVPixels(16, -6 + 20)
		models.cat.Body.Armor.default:setUVPixels(16, -6 + 20)
		models.cat.LeftArm.Armor.default:setUVPixels(40, -16 + 16)
		models.cat.RightArm.Armor.default:setUVPixels(40, -16 + 16)
		models.cat.LeftArm.Forearm.Armor.default:setUVPixels(40, -16 + 16)
		models.cat.RightArm.Forearm.Armor.default:setUVPixels(40, -16 + 16)
	elseif slot == "leggings" then
		models.cat.Body.ArmorBottom.default:setUVPixels(16, -32 + 16)
		models.cat.LeftLeg.ArmorLeggings.default:setUVPixels(0, -48 + 16)
		models.cat.RightLeg.ArmorLeggings.default:setUVPixels(0, -48 + 16)
	end

	-- Apply UV scale
	if slot ~= "helmet" and slot ~= "boots" then
		for _, part in pairs(partsToShow) do
			part:getUVMatrix():scale(texScale)
		end
	end

	return true
end

function armor.equipHelmetItem(item)
	local isBlock = modules.util.asItemStack(item, 2):isBlockItem() and not armor.checkSkull(item)

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
	models.cat.Head.Snoot:setVisible(not isBlock)
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
	models.cat.Head.Snoot:setVisible(true)
end

function armor.unequipChestplate()
	modules.clothes.setVisible("top", true)

	models.cat.Body["Body Layer Down"]:setVisible(true)
	models.cat.Body.Boobs:setVisible(true)
	models.cat.Body["3DHairBoobs"]:setVisible(true)
	models.cat.Body.Boobs.Armor:setVisible(false)
	models.cat.LeftArm.FurUp:setVisible(true)
	models.cat.RightArm.FurUp:setVisible(true)

	vanilla_model.CHESTPLATE:setVisible(false)

	modules.util.setChildrenVisible(models.cat.Body.Armor, false)
	modules.util.setChildrenVisible(models.cat.Body.Boobs.Armor, false)
	modules.util.setChildrenVisible(models.cat.LeftArm.Armor, false)
	modules.util.setChildrenVisible(models.cat.RightArm.Armor, false)
	modules.util.setChildrenVisible(models.cat.LeftArm.Forearm.Armor, false)
	modules.util.setChildrenVisible(models.cat.RightArm.Forearm.Armor, false)
end

function armor.unequipLeggings()
	modules.clothes.setVisible("bottom", true)

	vanilla_model.LEGGINGS:setVisible(false)

	modules.util.setChildrenVisible(models.cat.Body.ArmorBottom, false)
	modules.util.setChildrenVisible(models.cat.LeftLeg.ArmorLeggings, false)
	modules.util.setChildrenVisible(models.cat.RightLeg.ArmorLeggings, false)
end

function armor.unequipBoots()
	modules.clothes.setVisible("feet", true)

	vanilla_model.BOOTS:setVisible(false)

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
					table.insert(parts, models.cat.LeftArm.Forearm.Armor.FluffyJacket.leather)
					table.insert(parts, models.cat.RightArm.Forearm.Armor.FluffyJacket.leather)
				else
					table.insert(parts, models.cat.Body.Boobs.Armor.FluffyJacket)
					table.insert(parts, models.cat.Body.Armor.FluffyJacket)
					table.insert(parts, models.cat.LeftArm.Armor.FluffyJacket)
					table.insert(parts, models.cat.RightArm.Armor.FluffyJacket)
					table.insert(parts, models.cat.LeftArm.Forearm.Armor.FluffyJacket)
					table.insert(parts, models.cat.RightArm.Forearm.Armor.FluffyJacket)
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
	-- Default
	else
		if slot == "helmet" then
			if armor.knownMaterial(armor.getItemMaterial(item)) and mode ~= "EXCLUDE_EARS" then
				table.insert(parts, models.cat.Head.LeftEar.Armor.default)
				table.insert(parts, models.cat.Head.RightEar.Armor.default)
			end
			table.insert(parts, models.cat.Head.Armor.default)
		elseif slot == "chestplate" then
			table.insert(parts, models.cat.Body.Boobs.Armor.default)
			table.insert(parts, models.cat.Body.Armor.default)
			table.insert(parts, models.cat.LeftArm.Armor.default)
			table.insert(parts, models.cat.RightArm.Armor.default)
			table.insert(parts, models.cat.LeftArm.Forearm.Armor.default)
			table.insert(parts, models.cat.RightArm.Forearm.Armor.default)
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

function armor.setVisible(visible)
	armor.display = visible
	armor.helmetEvent()
	armor.chestplateEvent()
	armor.leggingsEvent()
	armor.bootsEvent()
end
pings.setArmorVisible = armor.setVisible


-- Utility functions

function armor.useCustomModel(item)
	return settings.armor.customModel[armor.getItemMaterial(item)]
end

function armor.getUVOffset(item, armorPiece)
	return armor.uvMults[armor.getItemMaterial(item)] * armor.uvWidths[armorPiece]
end

function armor.getItemSlot(item)
	local underscoreFind, lastPos = item.id:find(".*_")
	if underscoreFind then
		return item.id:sub(lastPos + 1, -1)
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
	return item.id ~= "minecraft:air" and not modules.util.startsWith(item.id, "vanityslots:") and (item.tag == nil or item.tag.phantomInk == nil)
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
