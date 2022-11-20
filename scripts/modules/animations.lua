-- Global animations handling module
local overrideModes = {
	-- Completely overrides vanilla origin rot
	OVERRIDE = 1,
	-- Same as overrideModes.OVERRIDE, but is multiplied by animation's blend value
	OVERRIDE_BLEND = 2,
	-- Overrides vanilla origin rot, but decreases in influence as the animation progresses, down to 0
	BLEND_OUT = 3,
}
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
	RightArm = overrideModes.BLEND_OUT,
	LeftArm = overrideModes.BLEND_OUT,
}

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
			RightArm = overrideModes.OVERRIDE_BLEND,
			LeftArm = overrideModes.OVERRIDE_BLEND,
			RightLeg = overrideModes.OVERRIDE_BLEND,
			LeftLeg = overrideModes.OVERRIDE_BLEND,
		}
	},

	-- Landing animations
	landHard = { overrideVanillaModes = allBlendOut },
	landHardRun = { overrideVanillaModes = allBlendOut },

	-- Combat animations
	punchR = { overrideVanillaModes = punchBlend },
	swipeR = { overrideVanillaModes = punchBlend },
	thrustR = { overrideVanillaModes = allBlendOut },
	swipeD = { overrideVanillaModes = allBlendOut },
	jumpKick = { overrideModes = allBlendOut },
	blockR = { overrideVanillaModes = { RightArm = overrideModes.OVERRIDE }, },
	blockL = { overrideVanillaModes = { LeftArm = overrideModes.OVERRIDE }, },
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
	play = function(self)
		if self.primary then
			if anims.primaryAnim ~= nil then
				anims.primaryAnim:stop()
			end
			anims.primaryAnim = self
		else
			if anims.secondaryAnim ~= nil then
				anims.secondaryAnim:stop()
			end
			anims.secondaryAnim = self
		end
		self.anim:play()
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
	if not primaryPlaying and not secondaryPlaying then
		return
	elseif context == "FIRST_PERSON" then
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
		return anims.primaryAnim:getPlayState() == "PLAYING"
	end
	return false
end

function anims.secondaryPlaying()
	if anims.secondaryAnim then
		return anims.secondaryAnim:getPlayState() == "PLAYING"
	end
	return false
end

return anims
