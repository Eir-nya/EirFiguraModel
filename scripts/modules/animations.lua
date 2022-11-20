-- Global animations handling module
local overrideModes = {
	-- Completely overrides vanilla origin rot
	OVERRIDE = 1,
	-- Same as overrideModes.OVERRIDE, but is multiplied by animation's blend value
	OVERRIDE_BLEND = 2,
	-- Overrides vanilla origin rot, but decreases in influence as the animation progresses, down to 0
	BLEND_OUT = 3,
}

-- Shortcut tables
-- Note: allOverride is specifically used later, so don't delete or edit it
local allOverride = {
	Head = overrideModes.OVERRIDE,
	Body = overrideModes.OVERRIDE,
	RightArm = overrideModes.OVERRIDE,
	LeftArm = overrideModes.OVERRIDE,
	RightLeg = overrideModes.OVERRIDE,
	LeftLeg = overrideModes.OVERRIDE,
}
local allBlendOut = {
	Head = overrideModes.BLEND_OUT,
	Body = overrideModes.BLEND_OUT,
	RightArm = overrideModes.BLEND_OUT,
	LeftArm = overrideModes.BLEND_OUT,
	RightLeg = overrideModes.BLEND_OUT,
	LeftLeg = overrideModes.BLEND_OUT,
}
local punchBlend = {
	Body = overrideModes.BLEND_OUT,
	RightArm = overrideModes.BLEND_OUT,
	LeftArm = overrideModes.BLEND_OUT,
}
local hideSwipe = function() models.cat.RightArm.swipe:setVisible(false) end

local anims = {
	primaryAnim = nil,
	secondaryAnim = nil,

	-- Animation registry...

	-- Simple poses
	sleepPose = {
		overrideVanillaModes = allOverride
	},
	hug = {
		overrideVanillaModes = {
			RightArm = overrideModes.OVERRIDE,
			LeftArm = overrideModes.OVERRIDE,
		},
	},
	sitPose1 = {
		Body = overrideModes.OVERRIDE,
		RightArm = overrideModes.OVERRIDE,
		LeftArm = overrideModes.OVERRIDE,
		RightLeg = overrideModes.OVERRIDE,
		LeftLeg = overrideModes.OVERRIDE,
	},
	sitPose2 = {
		Body = overrideModes.OVERRIDE,
		RightArm = overrideModes.OVERRIDE,
		LeftArm = overrideModes.OVERRIDE,
		RightLeg = overrideModes.OVERRIDE,
		LeftLeg = overrideModes.OVERRIDE,
	},

	-- Secondary blends
	jump = {
		primary = false,
		overrideVanillaModes = { Head = overrideModes.OVERRIDE_BLEND },
	},
	fall = {
		primary = false,
		overrideVanillaModes = {
			RightArm = overrideModes.OVERRIDE_BLEND,
			LeftArm = overrideModes.OVERRIDE_BLEND,
			RightLeg = overrideModes.OVERRIDE_BLEND,
			LeftLeg = overrideModes.OVERRIDE_BLEND,
		},
	},
	climb = {
		primary = false,
		overrideVanillaModes = {
			RightArm = overrideModes.OVERRIDE,
			LeftArm = overrideModes.OVERRIDE,
			RightLeg = overrideModes.OVERRIDE,
			LeftLeg = overrideModes.OVERRIDE,
		},
	},
	swimIdle = {
		primary = false,
		overrideVanillaModes = {
			Body = overrideModes.OVERRIDE,
			RightArm = overrideModes.OVERRIDE,
			LeftArm = overrideModes.OVERRIDE,
			RightLeg = overrideModes.OVERRIDE,
			LeftLeg = overrideModes.OVERRIDE,
		}
	},

	-- Landing animations
	landHard = { overrideVanillaModes = allBlendOut },
	landHardRun = { overrideVanillaModes = allBlendOut },

	-- Combat animations
	punchR = { overrideVanillaModes = punchBlend, firstPersonBlend = 0.5, onInterrupt = hideSwipe, },
	swipeR = { overrideVanillaModes = punchBlend, firstPersonBlend = 0.5, onInterrupt = hideSwipe, },
	thrustR = { overrideVanillaModes = allBlendOut, firstPersonBlend = 0.5, },
	swipeD = { overrideVanillaModes = allBlendOut, firstPersonBlend = 0.5, onInterrupt = hideSwipe, },
	jumpKick = { overrideModes = allBlendOut, firstPersonBlend = 0.5, },
	blockR = { overrideVanillaModes = { RightArm = overrideModes.OVERRIDE }, firstPersonBlend = 0.5, },
	blockL = { overrideVanillaModes = { LeftArm = overrideModes.OVERRIDE }, firstPersonBlend = 0.5, },
}

local animClass = {
	-- Primary animations take up an "active" slot.
	-- They will stop the previous one if applicable when starting.
	-- The overrideVanillaModes of primary animations takes precedence, if playing.
	-- Otherwise, this one's settings are used.
	primary = true,
	-- For each body part, determine how much of the vanilla rotation should be negated.
	overrideVanillaModes = {},
	-- Actual figura animation component of this class.
	anim = nil, -- [[@as Animation]]
	-- Has any overrideVanillaModes that are overrideModes.BLEND_OUT?
	needsBlendCalc = false,
	-- Last result of blend calculation, if the above is true.
	lastBlend = nil,
	-- Blend in first person. See better_first_person.lua
	firstPersonBlend = 1,

	-- Overrideable method that runs when animation is interrupted by another animation replacing it
	onInterrupt = function(self) end,

	setup = function(self)
		anims[self.anim.name] = self

		-- If there are any overrideVanillaModes with overrideModes.BLEND_OUT, set a bool
		for _, overrideMode in pairs(self.overrideVanillaModes) do
			if overrideMode == overrideModes.BLEND_OUT then
				self.needsBlendCalc = true
				break
			end
		end
	end,
	play = function(self, forceStart)
		if self.primary then
			if anims.primaryAnim ~= self then
				if anims.primaryPlaying() then
					anims.primaryAnim:stop()
					anims.primaryAnim:onInterrupt()
				end
			end
			anims.primaryAnim = self
		else
			if anims.secondaryAnim ~= self then
				if anims.secondaryAnim ~= nil then
					anims.secondaryAnim:stop()
					anims.secondaryAnim:onInterrupt()
				end
			end
			anims.secondaryAnim = self
		end
		if forceStart then
			self.anim:stop()
		end
		self.anim:play()
	end,
	stop = function(self)
		self.anim:stop()
	end,
	calcBlend = function(self)
		self.lastBlend = 1 - (self.anim:getTime() / self.anim:getLength())
	end,
	applyToPart = function(self, index, overrideMode)
		local part = models.cat[index]
		if overrideMode == overrideModes.OVERRIDE then
			part:setRot(-modules.util.partToVanillaPart(part):getOriginRot())
		elseif overrideMode == overrideModes.OVERRIDE_BLEND then
			part:setRot(-modules.util.partToVanillaPart(part):getOriginRot() * self.anim:getBlend())
		elseif overrideMode == overrideModes.BLEND_OUT then
			part:setRot(-modules.util.partToVanillaPart(part):getOriginRot() * self.lastBlend)
		end
	end,
}
function animClass:new(t)
	local anim = t and t or {}
	setmetatable(anim, animClass)
	animClass.__index = animClass
	anim:setup()
	return anim
end

-- Entity init event
function anims.entityInit()
	for name, anim in pairs(animations["models.cat"]) do
		local t = anims[name] and anims[name] or {}
		t.anim = anim
		animClass:new(t)
	end
end
modules.events.ENTITY_INIT:register(anims.entityInit)

-- Render event
function anims.render(delta, context)
	local primaryPlaying = anims.primaryPlaying()
	local secondaryPlaying = anims.secondaryPlaying()

	-- Don't animate in first person
	if context ~= "FIRST_PERSON" and context ~= "RENDER" then
		return
	end

	local prim = anims.primaryAnim
	local sec = anims.secondaryAnim
	local partsOverridden = {}

	if primaryPlaying then
		if prim.needsBlendCalc then
			prim:calcBlend()
		end
		for partName, overrideMode in pairs(prim.overrideVanillaModes) do
			prim:applyToPart(partName, overrideMode)
			partsOverridden[partName] = true
		end
	end
	if secondaryPlaying then
		if sec.needsBlendCalc then
			sec:calcBlend()
		end
		for partName, overrideMode in pairs(sec.overrideVanillaModes) do
			if not partsOverridden[partName] then
				sec:applyToPart(partName, overrideMode)
			end
		end
	end

	-- Reset parts not touched by animations
	for index in pairs(allOverride) do
		if not partsOverridden[index] then
			models.cat[index]:setRot()
		end
	end
end
modules.events.RENDER:register(anims.render)

-- Additional render method that makes the nameplate follow the model head
function anims.renderNameplate(delta, context)
	if context ~= "RENDER" then
		return
	end

	nameplate.ENTITY:setPos(vectors.rotateAroundAxis(-player:getBodyYaw(delta) + 180, models.cat.Head:getAnimPos() / 16, vec(0, 1, 0)))
end
modules.events.RENDER:register(anims.renderNameplate)


function anims.primaryPlaying()
	if anims.primaryAnim then
		return anims.primaryAnim.anim:getPlayState() == "PLAYING"
	end
	return false
end

function anims.secondaryPlaying()
	if anims.secondaryAnim then
		return anims.secondaryAnim.anim:getPlayState() == "PLAYING"
	end
	return false
end

return anims
