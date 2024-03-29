-- Armor module

local armor = {
	-- Display armor
	display = true,
	-- Is ear armor visible?
	earArmorVisible = false,
	-- Whether ears may be rotate or not (only available on leather/chainmail, or on all helmets if settings.armor.earArmorMovement is enabled)
	canRotateEars = false,
	-- Default color for leather armor
	leatherColor = vec(160/255, 101/255, 64/255),

	-- Size of armor.png
	armorTexOriginalSize = models.cat.Body.Armor:getTextureSize(),


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
		["minecraft:leather_helmet"] = true,
		["minecraft:chainmail_helmet"] = true
	},
}

-- Subscriable events

modules.events.armorVisible = modules.events:new()

-- Events

function armor.init()
	vanilla_model.ARMOR:setVisible(false)
	vanilla_model.HELMET_ITEM:setVisible(false)

	-- Set up render task to render items and blocks such as skulls
	models.cat.Head:newItem("headItem")
		:scale(1.1, 1.1, 1.1)
		:pos(-0.05, 7.95, -0.05)
		:setVisible(false)
	models.cat.Head:newBlock("headBlock")
		:scale(0.5625, 0.5625, 0.5625)
		:pos(-4.5, -0.5, -4.5)
		:setVisible(false)
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



-- Armor equip helpers

function armor.equipEvent(item, slot)
	-- Is item visible?
	if armor.checkItemVisible(item) then
		if slot == "chestplate" and previous.elytra then
			return
		end

		local material = armor.getItemMaterial(item)

		armor.genericEquip(item)

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

		-- Colorize if leather armor
		armor.colorizeLeather(item, material == "leather")
		armor.setGlint(item)
	end
end

function armor.genericEquip(item)
	local material = armor.getItemMaterial(item)
	local slot = armor.getItemSlot(item)

	if slot == "helmet" then
		if modules.clothes.getClothes("head") == "Fluffy hood" then
			modules.clothes.setVisible("head", false)
		end
		if settings.armor.earArmor and armor.knownMaterial(material) then
			models.cat.Head.LeftEar.Ear:setVisible(false)
			models.cat.Head.RightEar.Ear:setVisible(false)
		end
	elseif slot == "chestplate" then
		modules.clothes.setVisible("top", false)
	elseif slot == "leggings" then
		modules.clothes.setVisible("bottom", false)
		models.cat.Body.FatCock:setVisible(false)
	elseif slot == "boots" then
		modules.clothes.setVisible("feet", false)
	end
end

function armor.defaultEquip(item)
	local material = armor.getItemMaterial(item)
	local slot = armor.getItemSlot(item)

	if slot == "helmet" then
		if settings.armor.earArmor and armor.knownMaterial(material) then
			models.cat.Head.LeftEar.Armor:setVisible(true)
			models.cat.Head.RightEar.Armor:setVisible(true)

			armor.earArmorVisible = true
			armor.canRotateEars = armor.checkCanRotateEars(item)

			-- Set UVs
			local uv = armor.getUVOffset(item, "earArmor")
			models.cat.Head.LeftEar.Armor:setUVPixels(uv)
			models.cat.Head.RightEar.Armor:setUVPixels(uv)
		end

		models.cat.Head:getTask("headItem"):setVisible(false)
		models.cat.Head:getTask("headBlock"):setVisible(false)

		armor.useDefaultTexture(item, slot)
	elseif slot == "chestplate" then
		local uv = armor.getUVOffset(item, "chestplate")

		if settings.armor.boobArmor and armor.knownMaterial(material) then
			models.cat.Body.Boobs.Armor:setVisible(true)
			models.cat.Body.Boobs.Armor:setPrimaryTexture("PRIMARY")
			models.cat.Body.Boobs.Armor:setUVPixels(uv)
		end
		models.cat.Body.Armor:setVisible(true)
		models.cat.Body.Armor:setPrimaryTexture("PRIMARY")
		models.cat.Body.Armor:getUVMatrix():reset()
		models.cat.Body.Armor:setUVPixels(uv)

		-- Get array of ModelParts to apply operations to
		local armArmorParts = {
			[models.cat.LeftArm.Armor] = true,
			[models.cat.LeftArm.Forearm.Armor] = true,
			[models.cat.RightArm.Armor] = true,
			[models.cat.RightArm.Forearm.Armor] = true,
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
		armor.useDefaultTexture(item, slot)
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
		resourcePath = resourcePath .. (slot == "leggings" and "_layer_2" or "_layer_1")
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
		models.cat.Body.Boobs.Armor:setUVPixels(16, -6 + 20)
		models.cat.Body.Armor:setUVPixels(16, -6 + 20)
		models.cat.LeftArm.Armor:setUVPixels(40, -16 + 16)
		models.cat.RightArm.Armor:setUVPixels(40, -16 + 16)
		models.cat.LeftArm.Forearm.Armor:setUVPixels(40, -16 + 16)
		models.cat.RightArm.Forearm.Armor:setUVPixels(40, -16 + 16)
	end

	-- Apply UV scale
	if slot == "chestplate" then
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

	models.cat.Head:getTask("headItem"):setVisible(not isBlock)
	models.cat.Head:getTask("headBlock"):setVisible(isBlock)
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

	modules.clothes.setVisible("head", true)

	models.cat.Head.LeftEar.Armor:setVisible(false)
	models.cat.Head.RightEar.Armor:setVisible(false)

	armor.earArmorVisible = false
	armor.canRotateEars = false

	models.cat.Head.Armor:setVisible(false)

	models.cat.Head:getTask("headItem"):setVisible(false)
	models.cat.Head:getTask("headBlock"):setVisible(false)

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

	models.cat.Body.Boobs.Armor:setVisible(false)
	models.cat.Body.Armor:setVisible(false)
	models.cat.LeftArm.Armor:setVisible(false)
	models.cat.LeftArm.Forearm.Armor:setVisible(false)
	models.cat.RightArm.Armor:setVisible(false)
	models.cat.RightArm.Forearm.Armor:setVisible(false)
end

function armor.unequipLeggings()
	modules.clothes.setVisible("bottom", true)

	vanilla_model.LEGGINGS:setVisible(false)

	models.cat.Body.ArmorBottom:setVisible(false)
	models.cat.Body.ArmorBottom:setVisible(false)
	models.cat.LeftThigh.ArmorLeggings:setVisible(false)
	models.cat.RightThigh.ArmorLeggings:setVisible(false)
	modules.util.setChildrenVisible(models.cat.LeftLeg.ArmorLeggings, false)
	modules.util.setChildrenVisible(models.cat.RightLeg.ArmorLeggings, false)
end

function armor.unequipBoots()
	modules.clothes.setVisible("feet", true)

	vanilla_model.BOOTS:setVisible(false)

	modules.util.setChildrenVisible(models.cat.LeftLeg.ArmorBoots, false)
	modules.util.setChildrenVisible(models.cat.RightLeg.ArmorBoots, false)
end

function armor.colorizeLeather(item, shouldColorize)
	local color = armor.leatherColor
	if shouldColorize then
		if item.tag ~= nil and item.tag.display ~= nil then
			color = vectors.intToRGB(item.tag.display.color)
		end
	else
		color = nil
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

	if slot == "helmet" then
		if armor.knownMaterial(armor.getItemMaterial(item)) and mode ~= "EXCLUDE_EARS" then
			table.insert(parts, models.cat.Head.LeftEar.Armor)
			table.insert(parts, models.cat.Head.RightEar.Armor)
		end
		table.insert(parts, models.cat.Head.Armor)
	elseif slot == "chestplate" then
		table.insert(parts, models.cat.Body.Boobs.Armor)
		table.insert(parts, models.cat.Body.Armor)
		table.insert(parts, models.cat.LeftArm.Armor)
		table.insert(parts, models.cat.RightArm.Armor)
		table.insert(parts, models.cat.LeftArm.Forearm.Armor)
		table.insert(parts, models.cat.RightArm.Forearm.Armor)
	elseif slot == "leggings" then
		table.insert(parts, models.cat.Body.ArmorBottom)
		table.insert(parts, models.cat.LeftThigh.ArmorLeggings)
		table.insert(parts, models.cat.RightThigh.ArmorLeggings)
		table.insert(parts, models.cat.LeftLeg.ArmorLeggings)
		table.insert(parts, models.cat.RightLeg.ArmorLeggings)
	elseif slot == "boots" then
		table.insert(parts, models.cat.LeftLeg.ArmorBoots)
		table.insert(parts, models.cat.RightLeg.ArmorBoots)
	end

	return parts
end

function armor.setVisible(visible)
	if armor.display == visible then
		return
	end
	armor.display = visible
	modules.events.armorVisible:run(visible)
end
pings.setArmorVisible = armor.setVisible

function armor.armorVisibleEvent(newVisible)
	armor.helmetEvent()
	armor.chestplateEvent()
	armor.leggingsEvent()
	armor.bootsEvent()
end
modules.events.armorVisible:register(armor.armorVisibleEvent)


-- Utility functions

function armor.getUVOffset(item, armorPiece)
	if armor.uvMults[armor.getItemMaterial(item)] then
		return armor.uvMults[armor.getItemMaterial(item)] * armor.uvWidths[armorPiece]
	end
	return 0
end

function armor.getItemSlot(item)
	if item:getEquipmentSlot() then
		return ({HEAD = "helmet", CHEST = "chestplate", LEGS = "leggings", FEET = "boots"})[item:getEquipmentSlot()]
	end

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
	if settings.armor.earArmorMovement then
		return true
	end

	return armor.earRotationHelmets[item.id] or false
end

return armor
