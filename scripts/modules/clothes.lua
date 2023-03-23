local clothes = {
	head = {
		current = 1,
		"None",
	},
	top = {
		current = 2,
		"None",
		"Shirt",
		"Bikini (top)"
	},
	bottom = {
		current = 2,
		"None",
		"Purple shorts",
		"Bikini (bottom)"
	},
	feet = {
		current = 2,
		"None",
		"Enby socks"
	},
}

function clothes.showClothes(slot, clothing)
	if slot == "head" then
		-- TODO
	elseif slot == "top" then
		models.cat.Body.Boobs.Shirt:setVisible(clothing == "Shirt")
		models.cat.Body.Boobs.BikiniTop:setVisible(clothing == "Bikini (top)")
		models.cat.Body["3DShirt"]:setVisible(clothing == "Shirt")
		models.cat.Body["3DBikiniTop"]:setVisible(clothing == "Bikini (top)")
	elseif slot == "bottom" then
		models.cat.Body["3DShorts"]:setVisible(clothing == "Purple shorts")
		models.cat.Body["3DBikiniBottom"]:setVisible(clothing == "Bikini (bottom)")
		models.cat.LeftLeg["3DShorts"]:setVisible(clothing == "Purple shorts")
		models.cat.LeftLeg["3DBikiniBottom"]:setVisible(clothing == "Bikini (bottom)")
		models.cat.RightLeg["3DShorts"]:setVisible(clothing == "Purple shorts")
		models.cat.RightLeg["3DBikiniBottom"]:setVisible(clothing == "Bikini (bottom)")
	elseif slot == "feet" then
		models.cat.LeftLeg["3DEnbySocks"]:setVisible(clothing == "Enby socks")
		models.cat.RightLeg["3DEnbySocks"]:setVisible(clothing == "Enby socks")
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
end
pings.setClothes = clothes.equip

function clothes.setVisible(slot, visible)
	clothes.showClothes(slot, visible and clothes[slot][clothes[slot].current] or 1)
end

function clothes.get(slot)
	return clothes[slot].current
end

return clothes
