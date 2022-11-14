-- Wavey hair module
-- Based on rope physics demo by GNanimates

local hair = {
	-- Parts for simulation
	simParts = {
		Left = { heights = { 3, 4, 2 }, gravity = -0.4, },
		Right = { heights = { 3, 2 }, gravity = -0.2, },
		Back1 = { heights = { 3, 4, 2 }, gravity = -0.4, },
		Back2 = { heights = { 3, 4, 2 }, gravity = -0.4, },
		Back3 = { heights = { 3, 2 }, gravity = -0.35, },
	},
}

if settings.hair.enabled then
	-- Initialize stuff
	for key, simParts in pairs(hair.simParts) do
		-- Collect model parts
		simParts.pivot = models.cat.Head.Hair[key]
		simParts.hair = { table.unpack(models.cat.Head.Hair[key]:getChildren()) }

		-- Set up tables for values and previous values
		simParts.pointsPos = {}
		simParts.pointsPosLast = {}
		simParts.pivotPos = vec(0, 0, 0)
		simParts.pivotPosLast = vec(0, 0, 0)
	end
end

-- Init event
function hair.initEvent()
	if not settings.hair.enabled then
		models.cat.Head.Hair:setVisible(false)
		return
	end

	-- Make hair start down already
	for key, simParts in pairs(hair.simParts) do
		local startPos = modules.util.partToWorldPos(simParts.pivot) * math.worldScale
		simParts.pivotPos = startPos
		simParts.pivotPosLast = startPos

		for i = 1, #simParts.hair + 1 do
			simParts.pointsPos[i] = startPos
			simParts.pointsPosLast[i] = startPos

			if i <= #simParts.hair then
				startPos = startPos:copy()
				startPos.y = startPos.y - simParts.heights[i]
			end
		end
	end
end
modules.events.ENTITY_INIT:register(hair.initEvent)

-- Tick event
function hair.tickEvent()
	local headRot = vanilla_model.HEAD:getOriginRot() + models.cat.Head:getRot()

	-- Physics?????
	for _, simParts in pairs(hair.simParts) do
		-- Store world position of each pivot
		simParts.pivotPosLast = simParts.pivotPos
		simParts.pivotPos = modules.util.partToWorldPos(simParts.pivot) * math.worldScale

		for i = 1, #simParts.pointsPos do
			-- Verlet Integration
			local posBeforeUpdate = simParts.pointsPos[i]
			simParts.pointsPos[i] = (simParts.pointsPos[i] + simParts.pointsPos[i]) - simParts.pointsPosLast[i]
			-- Gravity
			if i > 1 then
				simParts.pointsPos[i].y = simParts.pointsPos[i].y + simParts.gravity
			end
			simParts.pointsPosLast[i] = posBeforeUpdate
		end

		-- Apply world pos movement
		simParts.pointsPos[1] = simParts.pivotPos

		for i = 1, #simParts.hair do
			-- Constrain to previous point based on hair part heights
			local hairHeight = simParts.heights[i]
			local dir = (simParts.pointsPos[i + 1] - simParts.pointsPos[i]):normalized()
			local center =  simParts.pointsPos[i] + ((dir * hairHeight) / 2)
			simParts.pointsPos[i + 1] = center + (dir * (hairHeight / 2))
			-- if i > 1 then
				-- simParts.pointsPos[i] = center - (dir * (hairHeight / 2))
			-- end
		end
	end
end
if settings.hair.enabled then
	modules.events.TICK:register(hair.tickEvent)
end

-- Render event
function hair.renderEvent(tickProgress)
	-- Make each rod of hair look at the points (and move to them)
	for _, simParts in pairs(hair.simParts) do
		for i = 1, #simParts.hair do
			simParts.hair[i]:setPos(
				modules.util.vecLerp(simParts.pointsPosLast[i], simParts.pointsPos[i], tickProgress)
			  - modules.util.vecLerp(simParts.pivotPosLast, simParts.pivotPos, tickProgress))
			simParts.hair[i]:setRot(hair.pointAt(
				modules.util.vecLerp(simParts.pointsPosLast[i], simParts.pointsPos[i], tickProgress),
				modules.util.vecLerp(simParts.pointsPosLast[i + 1], simParts.pointsPos[i + 1], tickProgress)
			))
		end
	end

	if hair.simParts.Left.hair[1]:getRot().y > 180 then
		print(hair.simParts.Left.hair[1]:getRot().y)
	end
end
if settings.hair.enabled then
	modules.events.RENDER:register(hair.renderEvent)
end


-- Returns a vector representing angles from point a to point b
function hair.pointAt(b, a)
	-- Code by GNanimates
	local offset = b-a
	local y = math.atan2(offset.x,offset.z)
	if y < 0 then
		y = y + math.pi
	end
	if y > math.pi / 2 then
		y = math.pi - y
	end
	local result = vec(math.atan2((math.sin(y)*offset.x)+(math.cos(y)*offset.z),offset.y),y)
	result = result:toDeg()
	return vec(result.x, result.y, 0)
end

return hair
