local clothes = {
	head = {
		current = 1,
		"None",
		"Fluffy hood"
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

function clothes.showClothes(slot, clothing)
	if slot == "head" then
		models.cat.Head.LeftEar.Ear:setVisible(clothing ~= "Fluffy hood")
		models.cat.Head.RightEar.Ear:setVisible(clothing ~= "Fluffy hood")
		models.cat.Head.LeftEar.FluffyHood:setVisible(clothing == "Fluffy hood")
		models.cat.Head.RightEar.FluffyHood:setVisible(clothing == "Fluffy hood")
		models.cat.Head.FluffyHood:setVisible(clothing == "Fluffy hood")
	elseif slot == "top" then
		models.cat.Body.Boobs.Shirt:setVisible(clothing == "Shirt")
		models.cat.Body.Boobs.BikiniTop:setVisible(clothing == "Bikini (top)")
		models.cat.Body.Boobs.FluffyJacket:setVisible(clothing == "Fluffy jacket")
		models.cat.Body["3DShirt"]:setVisible(clothing == "Shirt")
		models.cat.Body["3DBikiniTop"]:setVisible(clothing == "Bikini (top)")
		models.cat.Body["FluffyJacket"]:setVisible(clothing == "Fluffy jacket")
		models.cat.Body["Body Layer Down"]:setVisible(clothing ~= "Fluffy jacket")
		models.cat.LeftArm.FurUp:setVisible(clothing ~= "Fluffy jacket")
		models.cat.LeftArm.FluffyJacket:setVisible(clothing == "Fluffy jacket")
		models.cat.LeftArm.Forearm.FluffyJacket:setVisible(clothing == "Fluffy jacket")
		models.cat.RightArm.FurUp:setVisible(clothing ~= "Fluffy jacket")
		models.cat.RightArm.FluffyJacket:setVisible(clothing == "Fluffy jacket")
		models.cat.RightArm.Forearm.FluffyJacket:setVisible(clothing == "Fluffy jacket")
	elseif slot == "bottom" then
		models.cat.Body["3DShorts"]:setVisible(clothing == "Purple shorts")
		models.cat.Body["3DBikiniBottom"]:setVisible(clothing == "Bikini (bottom)")
		models.cat.Body.FluffyLeggings:setVisible(clothing == "Fluffy shorts")
		models.cat.LeftLeg["3DShorts"]:setVisible(clothing == "Purple shorts")
		models.cat.LeftLeg["3DBikiniBottom"]:setVisible(clothing == "Bikini (bottom)")
		models.cat.LeftLeg.FluffyLeggings:setVisible(clothing == "Fluffy shorts")
		models.cat.RightLeg["3DShorts"]:setVisible(clothing == "Purple shorts")
		models.cat.RightLeg["3DBikiniBottom"]:setVisible(clothing == "Bikini (bottom)")
		models.cat.RightLeg.FluffyLeggings:setVisible(clothing == "Fluffy shorts")
	elseif slot == "feet" then
		models.cat.LeftLeg["3DEnbySocks"]:setVisible(clothing == "Enby socks")
		models.cat.LeftLeg["3DCatSocks"]:setVisible(clothing == "Cat socks")
		models.cat.LeftLeg.FluffyBoots:setVisible(clothing == "Fluffy boots")
		models.cat.RightLeg["3DEnbySocks"]:setVisible(clothing == "Enby socks")
		models.cat.RightLeg["3DCatSocks"]:setVisible(clothing == "Cat socks")
		models.cat.RightLeg.FluffyBoots:setVisible(clothing == "Fluffy boots")
	end
end

function clothes.equip(slot, clothing)
	local shouldChangeClothes = not modules.armor.display
	if not shouldChangeClothes then
		local itemToCheck = ({ head = previous.helmet, top = previous.chestplate, bottom = previous.leggings, feet = previous.boots })[slot]
		if slot == "top" and previous.elytra then
			shouldChangeClothes = true
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
		models.cat.Head.Bow:setPos(vec(0, 0, -0.5))
	else
		models.cat.Head.Bow:setPos()
	end
end
modules.events.helmet:register(clothes.bowFunction)
modules.events.clothes:register(clothes.bowFunction)

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
