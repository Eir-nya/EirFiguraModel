-- Rope physics module
-- Math adapted from Manuel_'s swinging physics script. The rest is mine.
local rope = {
	-- List of active ropes, indexed by primary segment (eg. "print(modules.rope.ropes[models.cat.Head.Hair.Left])")
	ropes = {},

	lastMotionAng = vec(0, 0, 0),
	motionAng = vec(0, 0, 0),
}

-- Segment class
local segmentClass = {
	lastRot = vec(0, 0, 0),
	rot = vec(0, 0, 0),
	vel = vec(0, 0, 0),
	part = nil,
	parent = nil,
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
	gravity = 0.08,
	friction = 0.1,

	-- Methods
	setup = function(self, segment)
		-- Set behind-the-scenes values and states
		self.segments = rope.getSegments(segment)
		self.eventName = rope.getEventName(segment)
		self:setFriction(self.friction)
		self:setVisible(true)

		-- TODO: Set starting variables
		-- TODO: set other starting variables
	end,
	setFriction = function(self, newFric)
		self.friction = newFric
		for i, segment in ipairs(self.segments) do
			segment.friction = newFric * math.pow(1.5, i)
		end
	end,
	setVisible = function(self, visible)
		for _, part in ipairs(self.segments) do
			part:setVisible(visible)
		end

		-- Register and unregister events
		if visible then
			modules.events.TICK:register(self.TICK, self.eventName)
			modules.events.RENDER:register(self.RENDER, self.eventName)
		else
			modules.events.TICK:remove(self.eventName)
			modules.events.RENDER:remove(self.eventName)
		end
	end,

	TICK = function(self)
		-- TODO: rope physics (lol)

		-- For each segment...
		for i, segment in ipairs(self.segments) do
			segment.lastRot = segment.rot

			-- Gravity to add: ((angle that would make segment point straight down) - (last Rot)) * "gravity" mult
			local gravity = -modules.util.getHeadRot()
			if segment.parent ~= nil then
				gravity = gravity + segment.parent:getRot()
			end
			gravity = (gravity - segment.rot) * self.gravity

			-- x rot: + rotates "forward and up", - rotates "back and up"
			-- z rot: + rotates "right", - rotates "left"
			local force = vec(0, 0, 0)
			force.x = gravity + (previous.vel.y / 8) -- Add vertical velocity. TODO: underwater physics?
			-- TODO: add swaying/blowing in the wind
			-- TODO: Velocity delta: gravity + vec3(
			--    (change in head rotation / some amount) - cos(relative motion ang) + (cos(rope "forward") * abs(change in head rotation / some amount)),
			--    0
			--    (change in head rotation / some amount) + sin(relative motion ang) - (sin(rope "forward") * abs(change in head rotation / some amount)),
			-- )
			-- segment.vel = 
		end
	end,
	RENDER = function(self, delta)
	end,
}

function rope:new(segment)
	local r = {}
	setmetatable(r, ropeClass)
	ropeClass.__index = ropeClass

	-- Init new rope

	rope.ropes[segment] = r
	return r
end


-- Tick method - keeps track of changes in head rotation and relative motion angle per tick
function rope.tick()
	rope.lastMotionAng = rope.motionAng
	rope.motionAng = rope.getMotionAngRelative
end
modules.events.TICK:register(rope.tick)


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

		local grandchildren = rope.getSegments(child, part)
		if #grandchildren > 0 then
			for _, grandchild in ipairs(grandchildren) do
				table.insert(allParts, segmentClass:new(grandchild, part))
			end
		end
	end

	return allParts
end

-- Gets angle representing lateral rotation of head.
function rope.getHeadForward()
	local lookDir = previous.lookDir.x_z:normalized()
	local lookAngle = math.deg(math.atan2(lookDir.z, lookDir.x))
	lookAngle = lookAngle - modules.util.getHeadRot().y
	return lookAngle
end

-- Fetches the angle in radians that represents the direction of motion relative to the head's facing direction.
function rope.getMotionAngRelative()
	local headForwardAng = rope.getHeadForward()
	local vel = player:getVelocity()
	local motionAng = math.deg(math.atan2(vel.z, vel.x))
	return math.rad(((motionAng + headForwardAng) + 180) % 360)
end
-- NOTES:
-- math.sin(math.rad(this)) : -1 when facing +x, 1 when facing -x
-- math.cos(math.rad(this)) : 1 when facing +z, -1 when facing -z
function rope.getBodyRot()
	return player:getBodyYaw() + models.cat.Body:getRot().y + models.cat.Body:getAnimRot().y
end

return rope
