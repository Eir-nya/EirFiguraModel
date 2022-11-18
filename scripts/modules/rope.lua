-- Rope physics module
-- Math adapted from Manuel_'s swinging physics script. The rest is mine.
local rope = {
	-- List of active ropes, indexed by primary segment (eg. "print(modules.rope.ropes[models.cat.Head.Hair.Left])")
	ropes = {},
	ropesCount = 0, -- Number of ropes

	lastMotionAng = vec(0, 0, 0),
	motionAng = 0,
	yVelInfluence = 0, -- y velocity

	windDir = 0, -- Radian angle of wind blowing
	windPower = 0, -- Strength of sky light at player's head determines wind strength (0-15). Also 15 if in dimension "minecraft:the_nether"
	windPowerDiv100 = 0, -- windPower divided by 100. Used to ease up calculations

	-- parentClass instances
	parents = {
		Head = {
			part = models.cat.Head,
			getPartForward = function(self)
				local lookDir = previous.lookDir.x_z:normalized() --[[as @Vector3]]
				local lookAngle = math.deg(math.atan2(lookDir.z, lookDir.x))
				lookAngle = lookAngle - self.localRot.y
				return math.rad(lookAngle)
			end,
		},
		Body = {
			part = models.cat.Body,
			getLocalRot = function(self)
				return self.part:getRot() + self.part:getAnimRot() + vanilla_model.BODY:getOriginRot()
			end,
		},
	},
}

-- Parent types class
parentClass = {
	part = nil, --[[as @ModelPart]]
	lastRot = vec(0, 0, 0),
	rot = vec(0, 0, 0),
	localRot = vec(0, 0, 0),
	partInfluence = vec(0, 0, 0),
	forwardAng = 0,
	xzVelAngX = 0,
	xzVelAngZ = 0,
	windAngX = 0,
	windAngZ = 0,

	-- Gets custom rotation of parent part
	getLocalRot = function(self)
		return self.part:getRot() + self.part:getAnimRot()
	end,
	-- Gets total rotation of parent part
	getTotalRot = function(self)
		if self == rope.parents.Head then
			local r1 = player:getRot()
			local r2 = self.localRot
			return vec(r1.x - r2.x, r1.y - r2.y, -r2.z)
		elseif self == rope.parents.Body then
			return (vec(0, 1, 0) * player:getBodyYaw(1)) - self.localRot
		end
	end,
	-- Returns an angle in radians representing the direction this part is facing globally.
	getPartForward = function(self)
		local bodyAng = player:getBodyYaw(1)
		bodyAng = bodyAng - self.localRot.y
		return math.rad(bodyAng)
	end,
	-- Rotates an angle in radians by this part's facing angle.
	-- Returns -math.cos(result), -math.sin(result)
	rotateAng = function(self, radAng)
		local diff = radAng - self.forwardAng
		return -math.cos(diff), -math.sin(diff)
	end,
	TICK = function(self)
		self.localRot = self:getLocalRot()
		self.lastRot = self.rot
		self.rot = self:getTotalRot()
		self.partInfluence = self.rot - self.lastRot
		self.forwardAng = self:getPartForward()
		self.xzVelAngX, self.xzVelAngZ = self:rotateAng(rope.motionAng)
		self.windAngX, self.windAngZ = self:rotateAng(rope.windDir)
	end,
}

function parentClass:new(parentTable)
	setmetatable(parentTable, parentClass)
	parentClass.__index = parentClass
	modules.events.TICK:register(function() parentTable:TICK() end)
	return parentTable
end

-- Segment class
local segmentClass = {
	lastRot = vec(0, 0, 0),
	rot = vec(0, 0, 0),
	vel = vec(0, 0, 0),
	friction = 0, -- Set in ropeClass:setFriction
	part = nil, --[[@as ModelPart]]
	parent = nil, --[[@as ModelPart]]

	-- Gets a vector to apply to this segment's rotation to gradually make it point straight down
	-- TODO: fix sitting
	getGravity = function(self, thisRope)
		local grav = thisRope.parentType.rot.x_z
		if self.parent ~= nil then
			grav = grav - self.parent:getRot()
		end

		grav = (grav - self.rot) * thisRope.gravity

		return grav
	end
}

function segmentClass:new(part, parent)
	local s = {}
	setmetatable(s, segmentClass)
	segmentClass.__index = segmentClass
	s.part = part
	s.parent = parent
	return s
end

-- Rope class
local ropeClass = {
	-- Default values
	enabled = true, -- Setting this does nothing. Is set by setEnabled
	id = 0, -- Set to # of existing ropes on rope creation. Used to offset wind influence for realism
	segmentCount = 0, -- Set to # of segments on creation
	gravity = 0.1,
	friction = 0.2,
	facingDir = 0, -- TODO: have this number gradually "sway" up and down on a slow sine wave?
	parentType = rope.parents.Head,
	partInfluence = 1 / 16,
	xzVelInfluence = 6,
	yVelInfluence = 1 / 4,
	windInfluence = 1 / 6,

	-- Methods
	setup = function(self, segment)
		-- Set behind-the-scenes values and states
		self.id = rope.ropesCount
		for _, parent in pairs(rope.parents) do
			if segment:isChildOf(parent.part) then
				self.parentType = parent
			end
		end
		self.segments = rope.getSegments(segment, segment)
		self.segments[1].parent = nil
		self.segmentCount = #self.segments
		self.eventName = rope.getEventName(segment)
		self:setFriction(self.friction)
		self:setEnabled(true)
	end,
	setFriction = function(self, newFric)
		self.friction = newFric
		for i, segment in ipairs(self.segments) do
			segment.friction = newFric * math.pow(1.5, i - 1)
		end
	end,
	setVisible = function(self, visible)
		for _, part in ipairs(self.segments) do
			part.part:setVisible(visible)
		end
		self:setEnabled(visible)
	end,
	setEnabled = function(self, enabled)
		-- Register and unregister events
		self.enabled = enabled

		modules.events.TICK:remove(self.eventName)
		modules.events.RENDER:remove(self.eventName)

		if enabled then
			modules.events.TICK:register(function() self:TICK() end, self.eventName)
			modules.events.RENDER:register(function(delta) self:RENDER(delta) end, self.eventName)
		end
	end,

	TICK = function(self)
		-- TODO: rope physics (lol)

		-- How much will the segments be influenced by each factor?
		local partInfluence = self.parentType.partInfluence * self.partInfluence
		local xzVelInfluence = previous.velMagXZ * self.xzVelInfluence
		local yVelInfluence = rope.yVelInfluence * self.yVelInfluence
		local windInfluence = 0
		-- 185 (next 7 lines)
		if rope.windPower > 0 and self.windInfluence > 0 then
			windInfluence = rope.windPower * self.windInfluence
			local windMult = math.sin(((world.getTime() / 2) + (self.id * 2.2)) * rope.windPowerDiv100)
			windMult = windMult + (math.cos((world.getTime() + (self.id * 1.5)) * rope.windPowerDiv100) * (rope.windPower / 20))
			windMult = (windMult / 3) + 0.5
			windInfluence = windInfluence * windMult
		end

		-- For each segment...
		for i, segment in ipairs(self.segments) do
			segment.lastRot = segment.rot

			-- Gravity to add: ((angle that would make segment point straight down) - (last Rot)) * "gravity" mult
			local gravity = segment:getGravity(self)

			-- Velocity delta
			local velDel = gravity

			-- Add vertical velocity. TODO: underwater physics?
			if yVelInfluence ~= 0 then
				velDel.x = velDel.x - yVelInfluence
			end
			-- Adds part velocity (head/body rot)
			if partInfluence.x ~= 0 or partInfluence.z ~= 0 then
				velDel.x = velDel.x + partInfluence.x
				velDel.z = velDel.z - partInfluence.y
			end
			-- Adds x/z velocity influence
			if xzVelInfluence ~= 0 then
				velDel.x = velDel.x + (self.parentType.xzVelAngX * xzVelInfluence)
				velDel.z = velDel.z + (self.parentType.xzVelAngZ * xzVelInfluence)
			end
			-- Adds wind influence
			if windInfluence ~= 0 then
				local windSegmentInfluence = (i / self.segmentCount) * windInfluence
				velDel.x = velDel.x + (self.parentType.windAngX * windSegmentInfluence)
				velDel.z = velDel.z + (self.parentType.windAngZ * windSegmentInfluence)
			end

			-- TODO: figure out where this goes
			-- velDel = vectors.rotateAroundAxis(self.facingDir, velDel, vec(0, 1, 0))

			segment.vel = (segment.vel + velDel) * (1 - segment.friction)
			-- x rot: + rotates "forward and up", - rotates "back and up"
			-- z rot: + rotates "right", - rotates "left"
			segment.rot = segment.rot + segment.vel

			-- TODO limits
		end
	end,
	RENDER = function(self, delta)
		if self.enabled then
			for i, segment in ipairs(self.segments) do
				segment.part:setRot(modules.util.vecLerp(segment.lastRot, segment.rot, delta))
			end
		end
	end,
}

function rope:new(segment)
	local r = {}
	setmetatable(r, ropeClass)
	ropeClass.__index = ropeClass

	-- Init new rope
	r:setup(segment)

	rope.ropes[segment] = r
	rope.ropesCount = rope.ropesCount + 1
	return r
end


-- Tick method - keeps track of changes in head rotation and relative motion angle per tick
function rope.tick()
	rope.lastMotionAng = rope.motionAng
	rope.motionAng = rope.getMotionAng()
	rope.yVelInfluence = previous.vel.y
end
modules.events.TICK:register(rope.tick)

-- Register parent type tick methods here. they need to come after rope.tick
for parentName, parent in pairs(rope.parents) do
	rope.parents[parentName] = parentClass:new(parent)
end

-- World tick method - gets wind power level and direction based on location
function rope.worldTick()
	-- 210 (next 5 lines)
	if world.exists() and not previous.invisible then
		rope.windDir = math.rad(world.getTime() / 4)
		rope.windPower = rope.getWindPower()
		rope.windPowerDiv100 = rope.windPower / 100
	end
end
modules.events.WORLD_TICK:register(rope.worldTick)


-- Fetches the full path of a model part, as a string.
function rope.getEventName(part)
	local path = part:getName()
	local parent = part:getParent()

	while parent ~= nil do
		path = parent:getName() .. "." .. path
		parent = parent:getParent()
	end

	path = path .. " (Rope)"

	return path
end

-- Recursively fetches all segments (groups) that are descendant of a given group (includes given group).
function rope.getSegments(part, parent)
	local allParts = {}

	for i, child in ipairs(part:getChildren()) do
		if i == 1 then
			table.insert(allParts, segmentClass:new(part, parent))
		end

		local grandchildren = rope.getSegments(child, parent)--part)
		if #grandchildren > 0 then
			for _, grandchild in ipairs(grandchildren) do
				table.insert(allParts, grandchild)
			end
		end
	end

	return allParts
end

-- Fetches the angle in radians that represents the direction of motion
-- Subtract head's facing angle from this to get relative motion ang.
function rope.getMotionAng()
	local motionAng = math.atan2(previous.vel.z, previous.vel.x)
	return motionAng
end

-- Gets the wind power at the current block.
function rope.getWindPower()
	local dim = player:getDimensionName()
	if dim == "minecraft:the_nether" or dim == "minecraft:the_end" or previous.fire then
		return 15
	elseif previous.wet then
		return 0
	end

	return world.getSkyLightLevel(player:getPos())
end

-- Test function that visually displays rope.getMotionAngRelative()
--[[
function rope.test()
	p1 = particles.smoke:spawn():pos(player:getPos()):lifetime(1):scale(5)
	local ang = rope.motionAng + rope.parents.Head.forwardAng
	local offset = vec(math.cos(ang), 0, math.sin(ang)) * 4
	p2 = particles.smoke:spawn():pos(player:getPos() + offset):lifetime(1):scale(5)
end
modules.events.TICK:register(rope.test)
]]--

return rope
