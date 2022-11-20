-- Global animations handling module
local anims = {
	primaryAnimation = nil,
}

local overrideModes = {
	-- No negation: vanilla origin rot is added to animation rot
	NONE = 1,
	-- Completely overrides vanilla origin rot
	OVERRIDE = 2,
	-- Overrides vanilla origin rot, but decreases in influence as the animation progresses, down to 0
	BLEND_OUT = 3
}
local animClass = {
	-- Primary animations take up an "active" slot.
	-- They will stop the previous one if applicable when starting.
	-- The overrideVanillaModes of primary animations takes precedence.
	primary = true,
	-- For each body part, determine how much of the vanilla rotation should be negated.
	overrideVanillaModes = {
		Head = overrideModes.NONE,
		Body = overrideModes.NONE,
		RightArm = overrideModes.NONE,
		LeftArm = overrideModes.NONE,
		RightLeg = overrideModes.NONE,
		LeftLeg = overrideModes.NONE
	},
	-- Actual figura animation component of this class.
	anim = nil, -- [[@as Animation]]
	-- Has any overrideVanillaModes that are overrideModes.BLEND_OUT?
	needsBlendCalc = false,

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
			if anims.primaryAnimation ~= nil then
				anims.primaryAnimation:stop()
			end
			anims.primaryAnimation = self
		end
		self.anim:play()
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
		animClass:new(anims[name] and anims[name] or { anim = anim })
	end
end
modules.events.ENTITY_INIT:register(anims.entityInit)

-- Render event
function anims.render(delta, context)
	if anims.primaryAnimation == nil or anims.primaryAnimation.anim:getPlayState() == "STOPPED" then
		return
	elseif context == "FIRST_PERSON" then
		return
	end

	local blend
	if anims.primaryAnimation.needsBlendCalc then
		blend = 1 - (anims.primaryAnimation.anim.jumpKick:getTime() / anims.primaryAnimation.anim:getLength())
	end

	for partName, overrideMode in pairs(anims.primaryAnimation.overrideVanillaModes) do
		local part = models.cat[partName]
		if overrideMode == overrideModes.OVERRIDE then
			part:setRot(-modules.util.partToVanillaPart(part):getOriginRot())
		elseif overrideMode == overrideModes.BLEND_OUT then
			part:setRot(-modules.util.partToVanillaPart(part):getOriginRot() * blend)
		end
	end
end
modules.events.RENDER:register(anims.render)

return anims
