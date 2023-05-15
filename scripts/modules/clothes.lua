local clothes = {
	head = {
		current = 1,
		"None",
		"Fluffy hood"
	},
	bow = {
		current = 2,
		"None",
		"Bow",
		"Flower crown"
	},
	mask = {
		current = 1,
		"None",
		"Cat mask"
	},
	top = {
		current = 2,
		"None",
		"Shirt",
		"Fluffy jacket",
		"Bikini (top)"
	},
	bottom = {
		current = 2,
		"None",
		"Purple shorts",
		"Fluffy shorts",
		"Bikini (bottom)"
	},
	feet = {
		current = 3,
		"None",
		"Enby socks",
		"Cat socks",
		"Fluffy boots"
	},
}

-- Subscribable events

modules.events.clothes = modules.events:new()

-- Events

function clothes.init()
	models.cat.Head.FlowerCrown:setPrimaryRenderType("CUTOUT")
	local maskIndexes = {
		{[1] = vec(-0.375, 0, 0), [2] = vec(0.375, 0, 0), [3] = vec(0, 0, -0.25), [4] = vec(0, 0, -0.25)},
		{[1] = vec(-0.5, 0, 0.5), [2] = vec(-0.5, -0.5, 0), [3] = vec(0, 0, -0.25), [4] = vec(0, 0, 0.5)},
		{[1] = vec(0.5, -0.5, 0), [2] = vec(0.5, 0, 0.5), [3] = vec(0, 0, 0.5), [4] = vec(0, 0, -0.25)}
	}
	for i, maskPart in pairs(models.cat.Head.Mask:getChildren()) do
		local _, vertexes = next(maskPart:getAllVertices())
		for j, offset in pairs(maskIndexes[i]) do
			vertexes[j]:pos(vertexes[j]:getPos() + offset)
		end
	end
end
modules.events.ENTITY_INIT:register(clothes.init)

local parts = {
	head = {
		["Head.FluffyHood"] = "Fluffy hood",
		["Head.LeftEar.Ear"] = "*~Fluffy hood",
		["Head.LeftEar.FluffyHood"] = "Fluffy hood",
		["Head.RightEar.Ear"] = "*~Fluffy hood",
		["Head.RightEar.FluffyHood"] = "Fluffy hood",
	},
	bow = {
		["Head.Bow"] = "Bow",
		["Head.FlowerCrown"] = "Flower crown"
	},
	mask = {
		["Head.Mask"] = "Cat mask"
	},
	top = {
		["Body.Boobs.Shirt"] = "ShirtFluffy jacket",
		["Body.Boobs.BikiniTop"] = "Bikini (top)",
		["Body.Boobs.FluffyJacket"] = "Fluffy jacket",
		["Body.3DShirt"] = "ShirtFluffy jacket",
		["Body.3DBikiniTop"] = "Bikini (top)",
		["Body.FluffyJacket"] = "Fluffy jacket",
		["Body.Body Layer Down"] = "~Fluffy jacket",
		["LeftArm.FurUp"] = "~Fluffy jacket",
		["LeftArm.FluffyJacket"] = "Fluffy jacket",
		["LeftArm.Forearm.FluffyJacket"] = "Fluffy jacket",
		["RightArm.FurUp"] = "~Fluffy jacket",
		["RightArm.FluffyJacket"] = "Fluffy jacket",
		["RightArm.Forearm.FluffyJacket"] = "Fluffy jacket",
	},
	bottom = {
		["Body.3DShorts"] = "Purple shortsFluffy shorts",
		["Body.3DBikiniBottom"] = "Bikini (bottom)",
		["Body.FluffyLeggings"] = "Fluffy shorts",
		["LeftLeg.3DShorts"] = "Purple shorts",
		["LeftLeg.3DBikiniBottom"] = "Bikini (bottom)",
		["LeftLeg.FluffyLeggings"] = "Fluffy shorts",
		["RightLeg.3DShorts"] = "Purple shorts",
		["RightLeg.3DBikiniBottom"] = "Bikini (bottom)",
		["RightLeg.FluffyLeggings"] = "Fluffy shorts",
	},
	feet = {
		["LeftLeg.3DEnbySocks"] = "Enby socks",
		["LeftLeg.3DCatSocks"] = "Cat socks",
		["LeftLeg.FluffyBoots"] = "Fluffy boots",
		["RightLeg.3DEnbySocks"] = "Enby socks",
		["RightLeg.3DCatSocks"] = "Cat socks",
		["RightLeg.FluffyBoots"] = "Fluffy boots",
	}
}

function clothes.showClothes(slot, clothing)
	for path, s in pairs(parts[slot]) do
		modules.util.getByPath("models.cat." .. path):setVisible((s:find(clothing, nil, true) ~= nil or s:find("*") ~= nil) and s:find("~" .. clothing, nil, true) == nil)
	end
end

function clothes.equip(slot, clothing)
	local shouldChangeClothes = not modules.armor.display
	if not shouldChangeClothes then
		local itemToCheck = ({
			head = previous.helmet,
			bow = previous.helmet,
			top = previous.chestplate,
			bottom = previous.leggings,
			feet = previous.boots
		})[slot]
		if slot == "top" and previous.elytra then
			shouldChangeClothes = true
		elseif slot == "bow" then
			shouldChangeClothes = true
		elseif slot == "mask" then
			shouldChangeClothes = models.cat.Head.Snoot:getVisible()
		else
			shouldChangeClothes = not modules.armor.checkItemVisible(itemToCheck)
		end
	end
	if shouldChangeClothes then
		clothes.showClothes(slot, clothing)
	end

	-- Find value in array
	for i, clothesName in ipairs(clothes[slot]) do
		if clothing == clothesName then
			clothes[slot].current = i
			break
		end
	end

	if shouldChangeClothes then
		modules.events.clothes:run(slot, clothing)
	end
end
pings.setClothes = clothes.equip

function clothes.bowFunction()
	if (modules.armor.display and modules.armor.checkItemVisible(previous.helmet))
		or clothes.head[clothes.get("head")] == "Fluffy hood" then
		if clothes.getClothes("bow") == "Bow" then
			models.cat.Head.Bow:setPos(vec(0, 0, -0.5))
		else
			models.cat.Head.FlowerCrown:setVisible(false)
		end
	else
		if clothes.getClothes("bow") == "Bow" then
			models.cat.Head.Bow:setPos()
		else
			models.cat.Head.FlowerCrown:setVisible(clothes.getClothes("bow") == "Flower crown")
		end
	end
end
modules.events.helmet:register(clothes.bowFunction)
modules.events.clothes:register(clothes.bowFunction)

-- Register after armor's helmet event
modules.events.ENTITY_INIT:register(function()
	function clothes.maskFunction()
		if clothes.getClothes("mask") == "Cat mask" then
			models.cat.Head.Mask:setVisible(models.cat.Head.Snoot:getVisible())
		end
	end
	modules.events.helmet:register(clothes.maskFunction)
end)

function clothes.setVisible(slot, visible)
	clothes.showClothes(slot, visible and clothes.getClothes(slot) or clothes[slot][1])
end

function clothes.get(slot)
	return clothes[slot].current
end

function clothes.getClothes(slot)
	return clothes[slot][clothes.get(slot)]
end

return clothes
