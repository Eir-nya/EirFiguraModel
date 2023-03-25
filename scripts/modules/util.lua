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
	if sound then
		sounds:playSound(sound, player:getPos(), vol or nil)
	end
end

function util.getByPath(path, startingTable)
	local searchIn = startingTable or _G
	for key in path:gmatch("([^.]+)") do
		searchIn = searchIn[key]
	end
	return searchIn
end

function util.pickFrom(array)
	if type(array) ~= "table" then
		return nil
	end

	-- There might be inconsistent indexes in the table. Sort them.
	local indexes = {}
	for key in pairs(array) do
		table.insert(indexes, key)
	end

	if #indexes == 0 then
		return nil
	end
	return array[indexes[math.random(#indexes)]]
end

function util.vecLerp(vecIn, vecTarget, delta)
	return vec(math.lerp(vecIn.x, vecTarget.x, delta), math.lerp(vecIn.y, vecTarget.y, delta), math.lerp(vecIn.z, vecTarget.z, delta))
end

-- figura rc14: when your avatar is being rendered by other players, ctx is either "RENDER" OR "OTHER".
function util.renderedInWorld(context)
	if host:isHost() then
		return context == "RENDER"
	else
		return context == "RENDER" or context == "OTHER"
	end
end

function util.collisionAt(pos)
	local block = world.getBlockState(pos)
	if block:hasCollision() then
		if block:isFullCube() then
			return true
		else
			local collision = block:getCollisionShape()
			local posFloor = vec(math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))

			for i = 1, #collision do
				if pos >= collision[i][1] + posFloor and pos < collision[i][2] + posFloor then
					return true
				end
			end
		end
	end
	return false
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
-- tagMode:
--     0 or nil: Only copies "display", "Enchantments", and "phantomInk" fields
--     1: Uses string substitution to copy all tags up to 3 layers deep (heavy)
--     2: Ignore tag
function util.asItemStack(item, tagMode)
	local tagMode = tagMode or 0
	if type(item) == "ItemStack" then
		return item
	else
		local newItemString = item.id
		if item.tag ~= nil and tagMode < 2 then
			-- Only copies "display", "Enchantments", and "phantomInk" fields
			if tagMode == 0 then
				newItemString = newItemString .. "{"

				-- The only properties we are about are "display" and "Enchantments"
				if item.tag.display ~= nil then
					newItemString = newItemString .. "display:{color:" .. display.color .. "},"
				end
				if item.tag.Enchantments ~= nil then
					newItemString = newItemString .. "Enchantments:["
					for i = 1, #item.tag.Enchantments do
						newItemString = newItemString .. "{id:\"" .. item.tag.Enchantments[i].id .. "\","
						newItemString = newItemString .. "lvl:" .. item.tag.Enchantments[i].lvl .. "},"
					end
					newItemString = newItemString .. "],"
				end
				if item.tag.phantomInk then
					newItemString = newItemString .. "phantomInk:1b,"
				end

				newItemString = newItemString .. "}"
			-- Uses string substitution to copy all tags up to 3 layers deep (heavy)
			elseif tagMode == 1 then
				local tagOutput = printTable(item.tag, 3, true)
				tagOutput = tagOutput:gsub("([^%{])\n", "%1,"):gsub("\t", ""):gsub("\n", "")
				tagOutput = tagOutput:gsub("table: ", "")
				tagOutput = tagOutput:gsub("%[\"(.-)\"%]", "%1")
				tagOutput = tagOutput:gsub(" = ", ":")

				-- Formats number-indexed sections of table
				if tagOutput:find("{%[%d+%]:") then
					local start = tagOutput:find("{%[%d+%]:")
					local endOfTable = start
					local braceCount = 0
					for i = start, #tagOutput do
						local char = tagOutput:sub(i, i)
						if char == "{" then
							braceCount = braceCount + 1
						elseif char == "}" then
							braceCount = braceCount - 1
							if braceCount <= 0 then
								endOfTable = i
								break
							end
						end
					end

					tagOutput = tagOutput:sub(0, start - 1) .. "[" .. tagOutput:sub(start + 1, endOfTable - 1) .. "]" .. tagOutput:sub(endOfTable + 1)
				end
				tagOutput = tagOutput:gsub("%[%d+%]:", "")

				newItemString = newItemString .. tagOutput
			end
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
