-- Rope physics module
-- Math adapted from Manuel_'s swinging physics script. The rest is mine.
local rope = {
	-- List of active ropes, indexed by primary segment (eg. "print(modules.rope.ropes[models.cat.Head.Hair.Left])")
	ropes = {},
	ropesCount = 0, -- Number of ropes

	lastMotionAng = vec(0, 0, 0),
	motionAng = 0,
	motionAngSin = 0,
	motionAngCos = 0,
	lastHeadRot = vec(0, 0, 0),
	headRot = vec(0, 0, 0),
	headInfluence = vec(0, 0, 0), -- headRot - lastHeadRot
	yVelInfluence = 0, -- y velocity

	windDir = 0, -- Radian angle of wind blowing
	windDirSin = 0,
	windDirCos = 0,
	windPower = 0, -- Strength of sky light at player's head determines wind strength (0-15). Also 15 if in dimension "minecraft:the_nether"
	windPowerDiv100 = 0, -- windPower divided by 100. Used to ease up calculations
}

local parentTypes = { HEAD = 1, BODY = 2 }

-- Segment class
local segmentClass = {
	lastRot = vec(0, 0, 0),
	rot = vec(0, 0, 0),
	vel = vec(0, 0, 0),
	friction = 0, -- Set in ropeClass:setFriction
	part = nil,
	parent = nil,

	-- Gets a vector to apply to this segment's rotation to gradually make it point straight down
	getGravity = function(self, thisRope)
		local grav
		if thisRope.parentType == parentTypes.HEAD then
			grav = rope.headRot.x_z
		end
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
	gravity = 0.1,
	friction = 0.2,
	facingDir = 0, -- TODO: have this number gradually "sway" up and down on a slow sine wave?
	parentType = parentTypes.HEAD,
	partInfluence = 1/16,
	xzVelInfluence = 6,
	yVelInfluence = 1/4,
	windInfluence = 1/6,

	-- Methods
	setup = function(self, segment)
		-- Set behind-the-scenes values and states
		self.id = rope.ropesCount
		if segment:isChildOf(models.cat.Head) then
			self.parentType = parentTypes.HEAD
		elseif segment:isChildOf(models.cat.Body) then
			self.parentType = parentTypes.BODY
		end
		self.segments = rope.getSegments(segment, segment)
		self.segments[1].parent = nil
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
		self.enabled = enabled
		-- Register and unregister events
		if enabled then
			modules.events.TICK:register(function() self:TICK() end, self.eventName)
			modules.events.RENDER:register(function(delta) self:RENDER(delta) end, self.eventName)
		else
			modules.events.TICK:remove(self.eventName)
			modules.events.RENDER:remove(self.eventName)
		end
	end,

	TICK = function(self)
		-- TODO: rope physics (lol)

		-- How much will the segments be influenced by each factor?
		local partInfluence
		if self.parentType == parentTypes.HEAD then
			partInfluence = rope.headInfluence * self.partInfluence
		end
		local xzVelInfluence = previous.velMagXZ * self.xzVelInfluence
		local yVelInfluence = rope.yVelInfluence * self.yVelInfluence
		local windInfluence = 0
		if rope.windPower > 0 then
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
			velDel.x = velDel.x - yVelInfluence -- Add vertical velocity. TODO: underwater physics?
			velDel.x = velDel.x + partInfluence.x -- Adds part velocity (head rot, body rot?)
			velDel.z = velDel.z - partInfluence.y -- Adds part velocity (head rot, body rot?)
			-- TODO: figure out where this goes
			-- velDel = vectors.rotateAroundAxis(self.facingDir, velDel, vec(0, 1, 0))
			-- Adds x/z velocity influence
			velDel.x = velDel.x - (rope.motionAngCos * xzVelInfluence)
			velDel.z = velDel.z - (rope.motionAngSin * xzVelInfluence)
			-- Adds wind influence
			local windSegmentInfluence = i / #self.segments
			velDel.x = velDel.x - (rope.windDirCos * windInfluence * windSegmentInfluence)
			velDel.z = velDel.z - (rope.windDirSin * windInfluence * windSegmentInfluence)

			segment.vel = (segment.vel + velDel) * (1 - segment.friction)
			-- x rot: + rotates "forward and up", - rotates "back and up"
			-- z rot: + rotates "right", - rotates "left"
			segment.rot = segment.rot + segment.vel

			-- TODO limits

			-- TODO: add swaying/blowing in the wind
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
	rope.lastHeadRot = rope.headRot
	rope.headRot = modules.util.getHeadRotTotal()
	rope.headInfluence = rope.headRot - rope.lastHeadRot
	rope.lastMotionAng = rope.motionAng
	rope.motionAng = rope.getMotionAngRelative()
	rope.motionAngSin = math.sin(rope.motionAng)
	rope.motionAngCos = math.cos(rope.motionAng)
	rope.yVelInfluence = previous.vel.y
end
modules.events.TICK:register(rope.tick)

-- World tick method - gets wind power level and direction based on location
function rope.worldTick()
	if world.exists() and not previous.invisible then
		rope.windDir = math.rad(world.getTime() / 4)
		rope.windDirSin = math.sin(rope.windDir)
		rope.windDirCos = math.cos(rope.windDir)
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

-- Gets degree angle representing lateral rotation of head.
function rope.getHeadForward()
	local lookDir = previous.lookDir.x_z:normalized()
	local lookAngle = math.deg(math.atan2(lookDir.z, lookDir.x))
	lookAngle = lookAngle - modules.util.getHeadRot().y
	return lookAngle
end
-- Fetches the angle in radians that represents the direction of motion relative to the head's facing direction.
function rope.getMotionAngRelative()
	local headForwardAng = math.rad(rope.getHeadForward())
	local motionAng = math.atan2(previous.vel.z, previous.vel.x)
	return motionAng - headForwardAng
end

-- Test function that visually displays rope.getMotionAngRelative()
--[[
function rope.test()
	p1 = particles.smoke:spawn():pos(player:getPos()):lifetime(1):scale(5)
	local ang = math.rad(rope.getHeadForward()) + rope.getMotionAngRelative()
	local offset = vec(math.cos(ang), 0, math.sin(ang)) * 4
	p2 = particles.smoke:spawn():pos(player:getPos() + offset):lifetime(1):scale(5)
end
modules.events.TICK:register(rope.test)
]]--

-- NOTES:
-- math.sin(math.rad(this)) : -1 when facing +x, 1 when facing -x
-- math.cos(math.rad(this)) : 1 when facing +z, -1 when facing -z
function rope.getBodyRot()
	return player:getBodyYaw() + models.cat.Body:getRot().y + models.cat.Body:getAnimRot().y
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

return rope
