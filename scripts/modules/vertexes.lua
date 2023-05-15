-- Vector2 point name structure:
-- V*|part path to modify|list of point indexes to move here

--[[
	1-4: front face
		1: bottom left
		2: bottom right
		3: top right
		4: top left
	5-8: back face
	9-12: east face
	13-16: west face
	17-20: top face
		17: south west
		18: south east
		19: north east
		20: north west
	21-24: bottom face
]]--

local vPoints = {}

local recurse
recurse = function(parent)
	for _, part in pairs(parent:getChildren()) do
		recurse(part)
		if part:getVisible() then
			if part:getName():sub(0, 3) == "V__" then
				vPoints[part] = true
			end
		end
	end
end
recurse(models.cat)

modules.events.ENTITY_INIT:register(function()
	for vPoint in pairs(vPoints) do
		local words = {}
		local lastWordStart = 0
		local last_ = 0
		for i = 0, #vPoint:getName() do
			if vPoint:getName():sub(i, i) == "_" then
				if last_ == i - 1 then
					table.insert(words, vPoint:getName():sub(lastWordStart, i - 2))
					lastWordStart = i + 1
				end
				last_ = i
			end
		end
		table.remove(words, 1)

		local part = modules.util.getByPath(words[1]:gsub("_", "."), vPoint:getParent())
		local _, vertexes = next(part:getAllVertices())
		for num in words[2]:gmatch("[^_]+") do
			num = tonumber(num)
			local vertexToMove = vertexes[num]
			local worldSpaceTarget = part:partToWorldMatrix():apply(part:getPositionMatrix():apply(vPoint:getPivot()))
			particles.end_rod:pos(worldSpaceTarget):spawn()
			vertexToMove:pos(part:partToWorldMatrix():inverted():apply(worldSpaceTarget))
		end
	end
end)
