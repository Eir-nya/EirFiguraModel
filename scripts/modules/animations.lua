-- Global animations handling module

-- Enum defining the ways that animations will override vanilla part rotation.
local overrideModes = {
	-- Completely overrides vanilla origin rot
	OVERRIDE = 1,
	-- Same as overrideModes.OVERRIDE, but is multiplied by animation's blend value
	OVERRIDE_BLEND = 2,
	-- Overrides vanilla origin rot, but decreases in influence as the animation progresses, down to 0
	BLEND_OUT = 3,
}
-- All active animations are handled in order of rank.
-- Animations that are handled first get first pick on blend modes for body parts.
-- Secondary animations have their blend modes ignored if primary anims already applied theirs.
local animRanks = {
	PRIMARY = 1,
	SECONDARY = 2,
	TERTIARY = 3,
}
-- Controls the way that animations in higher ranks will be prioritized over lesser ranked ones.
local blendWeightModes = {
	-- Lesser animations are blended by what's left of higher-rank blend weight,
	-- but this amount decreases as the animation progresses. Similar to overrideModes.BLEND_OUT.
	BLEND_OUT = 1,
}
-- Fade modes. Used for fading in and out animations gradually.
local fadeModes = {
	-- Fades in at a fixed linear rate.
	FADE_IN_FIXED = 1,
	-- Fades in at a smooth rate using lerp.
	FADE_IN_SMOOTH = 2,
	-- Fades out at a fixed linear rate.
	FADE_OUT_FIXED = 3,
	-- Fades out at a smooth rate using lerp.
	FADE_OUT_SMOOTH = 4,
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
local stopSit = function() modules.sit.stopSitting(true) end

local anims = {
	[1] = nil, -- Primary animation
	[2] = nil, -- Secondary animation
	[3] = nil, -- Tertiary animation

	fadeModes = fadeModes,

	-- Animation registry...

	-- Simple poses
	sleepPose = {
		overrideVanillaModes = allOverride,
		blendWeight = 1,
	},
	hug = {
		overrideVanillaModes = {
			RightArm = overrideModes.OVERRIDE,
			LeftArm = overrideModes.OVERRIDE,
		},
		blendWeight = 0.75,
	},
	sit1 = {
		length = 2.2,
		overrideVanillaModes = {
			Body = overrideModes.OVERRIDE,
			RightArm = overrideModes.OVERRIDE,
			LeftArm = overrideModes.OVERRIDE,
			RightLeg = overrideModes.OVERRIDE,
			LeftLeg = overrideModes.OVERRIDE,
		},
		onInterrupt = stopSit,
	},
	sitPose2 = {
		overrideVanillaModes = {
			Body = overrideModes.OVERRIDE,
			RightArm = overrideModes.OVERRIDE,
			LeftArm = overrideModes.OVERRIDE,
			RightLeg = overrideModes.OVERRIDE,
			LeftLeg = overrideModes.OVERRIDE,
		},
		onInterrupt = stopSit,
	},

	-- Secondary blends
	jump = { rank = animRanks.TERTIARY, firstPersonBlend = 1 / 2.5 },
	fall = {
		rank = animRanks.TERTIARY,
		overrideVanillaModes = {
			RightArm = overrideModes.OVERRIDE_BLEND,
			LeftArm = overrideModes.OVERRIDE_BLEND,
			RightLeg = overrideModes.OVERRIDE_BLEND,
			LeftLeg = overrideModes.OVERRIDE_BLEND,
		},
	},
	climb = {
		rank = animRanks.SECONDARY,
		overrideVanillaModes = {
			RightArm = overrideModes.OVERRIDE,
			LeftArm = overrideModes.OVERRIDE,
			RightLeg = overrideModes.OVERRIDE,
			LeftLeg = overrideModes.OVERRIDE,
		},
	},
	swimIdle = {
		rank = animRanks.SECONDARY,
		overrideVanillaModes = {
			-- Body = overrideModes.OVERRIDE,
			RightArm = overrideModes.OVERRIDE,
			LeftArm = overrideModes.OVERRIDE,
			RightLeg = overrideModes.OVERRIDE,
			LeftLeg = overrideModes.OVERRIDE,
		}
	},

	-- Landing animations
	landHard = { overrideVanillaModes = allBlendOut, blendWeight = 1, blendWeightMode = blendWeightModes.BLEND_OUT, },
	landHardRun = { overrideVanillaModes = allBlendOut, blendWeight = 1, blendWeightMode = blendWeightModes.BLEND_OUT, },

	-- Combat animations
	punchR = {
		overrideVanillaModes = punchBlend,
		firstPersonBlend = 0.5,
		blendWeight = 1,
		blendWeightMode = blendWeightModes.BLEND_OUT,
		onInterrupt = hideSwipe,
	},
	swipeR = {
		overrideVanillaModes = punchBlend,
		firstPersonBlend = 0.5,
		blendWeight = 1,
		blendWeightMode = blendWeightModes.BLEND_OUT,
		onInterrupt = hideSwipe,
	},
	thrustR = {
		overrideVanillaModes = allBlendOut,
		firstPersonBlend = 0.5,
		blendWeight = 0.7,
		blendWeightMode = blendWeightModes.BLEND_OUT,
	},
	swipeD = {
		overrideVanillaModes = allBlendOut,
		firstPersonBlend = 0.5,
		blendWeight = 1,
		blendWeightMode = blendWeightModes.BLEND_OUT,
		onInterrupt = hideSwipe,
	},
	jumpKick = {
		overrideModes = allBlendOut,
		firstPersonBlend = 0.5,
		blendWeight = 0.875,
		blendWeightMode = blendWeightModes.BLEND_OUT,
	},
	blockR = {
		overrideVanillaModes = { RightArm = overrideModes.OVERRIDE },
		firstPersonBlend = 0.5,
		blendWeight = 0.8,
	},
	blockL = {
		overrideVanillaModes = { LeftArm = overrideModes.OVERRIDE },
		firstPersonBlend = 0.5,
		blendWeight = 0.8,
	},
}

local animClass = {
	-- See animRanks
	rank = animRanks.PRIMARY,
	-- For each body part, determine how much of the vanilla rotation should be negated.
	overrideVanillaModes = {},
	-- Actual figura animation component of this class.
	anim = nil, -- [[@as Animation]]
	-- If set, this will automatically be ran through anim.anim:length(length) on setup.
	length = nil,
	-- Has any overrideVanillaModes that are overrideModes.BLEND_OUT?
	needsBlendCalc = false,
	-- Last result of inverse anim progress calculation, if the above is true.
	lastInvProgress = nil,
	-- Blend in first person. See better_first_person.lua. Unrelated to other blend vars.
	firstPersonBlend = 1,
	-- Lesser-ranked animations than this one will have their effective blend reduced by this much.
	blendWeight = 0,
	-- Defines how this animation's blendWeight value will be applied to lesser-ranked animations.
	-- If nil, blendWeight is simply subtracted from lesser-ranked animations' effective blend amounts.
	blendWeightMode = nil,
	-- Base "blend" amount. Set in :blend. used when blending multiple ranks of anims at once.
	baseBlend = 1,

	-- Current fade in/out operation. See fadeModes.
	-- If nil, no fading is occuring.
	fadeMode = nil,
	-- Progress for fade operation if fading presently.
	fadeProgress = 0,
	-- Previous value of fadeProgress, used for render.
	lastFadeProgress = 0,
	-- For linear fade operations, add this amount per tick.
	fadeLinearRate = nil,
	-- Lerp rate used for fade operations that use smooth lerping.
	fadeSmoothLerpRate = nil,

	-- Overrideable method that runs when animation is interrupted by another animation replacing it
	onInterrupt = function(self) end,

	setup = function(self)
		anims[self.anim.name] = self

		if self.length then
			self.anim:length(self.length)
		end

		-- If there are any overrideVanillaModes with overrideModes.BLEND_OUT, set a bool
		for _, overrideMode in pairs(self.overrideVanillaModes) do
			if overrideMode == overrideModes.BLEND_OUT then
				self.needsBlendCalc = true
				break
			end
		end
		-- If blendWeightMode is blendWeightModes.BLEND_OUT, same bool should also be set
		if self.blendWeightMode == blendWeightModes.BLEND_OUT then
			self.needsBlendCalc = true
		end
	end,
	play = function(self, forceStart)
		-- Rank handling
		if anims[self.rank] ~= self then
			if anims.playing(self.rank) then
				anims[self.rank]:stop()
				anims[self.rank]:onInterrupt()
			end
			anims[self.rank] = self
		end

		if forceStart then
			self.anim:stop()
		end
		self.anim:play()

		-- Reset fade
		self.fadeMode = nil
	end,
	stop = function(self)
		self.anim:stop()
	end,
	fade = function(self, fadeMode, rate)
		self.fadeMode = fadeMode
		self.fadeProgress = 0
		self.lastFadeProgress = 0
		if fadeMode == anims.fadeModes.FADE_IN_FIXED or fadeMode == anims.fadeModes.FADE_OUT_FIXED then
			self.fadeLinearRate = rate
		else
			self.fadeSmoothLerpRate = rate
		end
	end,
	isFading = function(self)
		return self.fadeMode ~= nil
	end,
	getFadeBlend = function(self, delta)
		if anims.isFadeIn(self.fadeMode) then
			return math.lerp(self.lastFadeProgress, self.fadeProgress, delta)
		else
			return 1 - math.lerp(self.lastFadeProgress, self.fadeProgress, delta)
		end
	end,
	-- Calculates progress of animation, with 1 being the start and 0 being the end of the animation
	getInverseProgress = function(self)
		self.lastInvProgress = 1 - (self.anim:getTime() / self.anim:getLength())
	end,
	-- Sets base animation blend value that will be referred to while blending w/ other ranks of animations
	blend = function(self, value)
		self.baseBlend = value
		-- self.anim:blend(value)
	end,
	applyToPart = function(self, index, overrideMode, delta)
		local part = models.cat[index]
		local fadeMult = 1

		if self:isFading() then
			fadeMult = self:getFadeBlend(delta)
		end

		local vanillaPart = modules.util.partToVanillaPart(part)
		if overrideMode == overrideModes.OVERRIDE then
			part:setRot(-vanillaPart:getOriginRot() * fadeMult)
		elseif overrideMode == overrideModes.OVERRIDE_BLEND then
			part:setRot(-vanillaPart:getOriginRot() * fadeMult * self.anim:getBlend())
		elseif overrideMode == overrideModes.BLEND_OUT then
			part:setRot(-vanillaPart:getOriginRot() * fadeMult * self.lastInvProgress)
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
	anims.breatheIdle = nil
	animations["models.cat"].breatheIdle:play()
end
modules.events.ENTITY_INIT:register(anims.entityInit)

-- Tick event
function anims.fadeInOut()
	-- Fades in and out animations that are set to do so.
	for i = 1, 3 do
		if anims.playing(i) then
			local anim = anims[i]
			if anim:isFading() then
				anim.lastFadeProgress = anim.fadeProgress

				if anim.fadeMode == anims.fadeModes.FADE_IN_FIXED or anim.fadeMode == anims.fadeModes.FADE_OUT_FIXED then
					anim.fadeProgress = anim.fadeProgress + anim.fadeLinearRate
					anim.fadeProgress = math.min(anim.fadeProgress, 1)
				else
					anim.fadeProgress = math.lerp(anim.fadeProgress, 1, anim.fadeSmoothLerpRate)
					if anim.fadeProgress > 0.9875 then
						anim.fadeProgress = 1
					end
				end

				-- End fade
				if anim.fadeProgress >= 1 then
					-- Fading out: run stop() when done
					if not anims.isFadeIn(anim.fadeMode) then
						anim:stop()
					end
					anim.fadeMode = nil
				end
			end
		end
	end
end
modules.events.TICK:register(anims.fadeInOut)

-- Render event
function anims.render(delta, context)
	-- Don't apply part rot needlessly on other render modes
	if context ~= "FIRST_PERSON" and context ~= "RENDER" then
		return
	end

	local partsOverridden = {}
	local blendWeightRemaining = 1

	-- Handle active animations
	for i = 1, 3 do
		if anims.playing(i) then
			blendWeightRemaining = anims.handleAnimations(i, partsOverridden, blendWeightRemaining, delta)
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

	local nameplatePos = modules.util.partToWorldPos(models.cat.Head.NAMEPLATE_PIVOT)
	nameplatePos = nameplatePos - player:getPos(delta)
	if previous.pose == "SWIMMING" or previous.pose == "FALL_FLYING" then
		nameplatePos = nameplatePos - vec(0, 0.75, 0)
	else
		nameplatePos = nameplatePos - vec(0, 1.916, 0)
	end
	nameplate.ENTITY:setPos(nameplatePos)
end
modules.events.POST_RENDER:register(anims.renderNameplate)


function anims.handleAnimations(rank, partsOverridden, blendWeightRemaining, delta)
	local anim = anims[rank]
	if anim.needsBlendCalc then
		anim:getInverseProgress()
	end

	for partName, overrideMode in pairs(anim.overrideVanillaModes) do
		if not partsOverridden[partName] then
			anim:applyToPart(partName, overrideMode, blendWeightRemaining, delta)
			partsOverridden[partName] = true
		end
	end

	-- Blend animation - also accounts for fade operations
	if anim:isFading() then
		anim.anim:blend(anim.baseBlend * anim:getFadeBlend(delta) * blendWeightRemaining)
	else
		anim.anim:blend(anim.baseBlend * blendWeightRemaining)
	end

	if anim.blendWeightMode == blendWeightModes.BLEND_OUT then
		blendWeightRemaining = blendWeightRemaining - (anim.blendWeight * anim.lastInvProgress)
	else
		blendWeightRemaining = blendWeightRemaining - anim.blendWeight
	end

	return blendWeightRemaining
end

function anims.playing(rank)
	if anims[rank] then
		return anims[rank].anim:getPlayState() == "PLAYING"
	end
	return false
end

-- Returns if a given fade mode is fading in or fading out
function anims.isFadeIn(fadeMode)
	return fadeMode == anims.fadeModes.FADE_IN_FIXED or fadeMode == anims.fadeModes.FADE_IN_SMOOTH
end

return anims
