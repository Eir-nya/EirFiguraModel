-- Utility module

local util = {}

models = models.models

function util.startsWith(s1, s2)
	return s1:sub(0, #s2) == s2
end

function util.endsWith(s1, s2)
	return s1:sub(#s1 - (#s2 - 1), #s1) == s2
end

function util.soundAtPlayer(sound, vol)
	sounds:playSound(sound, player:getPos(), vol or nil)
end

function util.pickFrom(array)
	return array[math.random(#array)]
end

function util.vecLerp(vecIn, vecTarget, delta)
	return vec(math.lerp(vecIn.x, vecTarget.x, delta), math.lerp(vecIn.y, vecTarget.y, delta), math.lerp(vecIn.z, vecTarget.z, delta))
end

function util.setChildrenVisible(part, visible)
	for _, child in pairs(part:getChildren()) do
		child:setVisible(nil)
	end
	part:setVisible(visible)
end

-- rip vectors.rainbow
function util.rainbow(speed)
	local t = world.getTime()
	t = ((t * speed) % 255) / 255
	return vectors.hsvToRGB(t, 1, 1)
end


-- Takes an item in the format {id = string, tag = {}}
function util.asItemStack(item)
	if type(item) == "ItemStack" then
		return item
	else
		local newItemString = item.id
		if item.tag ~= nil then
			local tagOutput = printTable(item.tag, 2, true)
			tagOutput = tagOutput:gsub("\n", ""):gsub("\t", "")
			tagOutput = tagOutput:gsub("table: ", "")
			tagOutput = tagOutput:gsub("%[\"(.-)\"%]", "%1")
			tagOutput = tagOutput:gsub(" = ", ":")
			tagOutput = tagOutput:gsub("}", "},")
			tagOutput = tagOutput:sub(0, #tagOutput - 1)

			newItemString = newItemString .. tagOutput
		end

		return world.newItem(newItemString)
	end
end

function util.statusEffectsString(effects)
	local statusString = "{"
	for i, effect in ipairs(effects) do
		if i > 1 then
			statusString = statusString .. ", "
		end
		statusString = statusString .. effect.name
	end
	statusString = statusString .. "}"
	return statusString
end

function util.getNbtValue(start, key)
	if key == nil then
		key = start
		start = player:getNbt()
	end
	for subkey in string.gmatch(key, "[^.]+") do
		if start[subkey] ~= nil then
			start = start[subkey]
		else
			return nil
		end
	end
	return start
end

function util.getEffect(effectType)
	for _, effect in ipairs(previous.effects) do
		if effect.name == effectType then
			return effect
		end
	end
end

local partToVanillaPartTable = {
	Head = vanilla_model.HEAD,
	Body = vanilla_model.BODY,
	RightArm = vanilla_model.RIGHT_ARM,
	LeftArm = vanilla_model.LEFT_ARM,
	RightLeg = vanilla_model.RIGHT_LEG,
	LeftLeg = vanilla_model.LEFT_LEG
}
function util.partToVanillaPart(modelPart)
	return partToVanillaPartTable[modelPart:getName()]
end

-- Note: these DO account for animations, *including* animations that are blended in and out with animation:blend
function util.partToWorldPos(modelPart)
	return modelPart:partToWorldMatrix():apply(modelPart:getPos())
end
function util.getHeadRot()
	return models.cat.Head:getRot() + models.cat.Head:getAnimRot()
end
function util.getEyePos()
	return util.partToWorldPos(models.cat.Head.eyesBack)
end

return util
