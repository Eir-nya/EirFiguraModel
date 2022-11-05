-- Extra animations module

local exAnims = {
	newVelY = 0, -- do not use
	lastVelY = 0,

	mult = 0,
	lastMult = 0,
	multLerpRate = 0.2,

	fallThreshold = -0.4, -- When y velocity is below this number, start fall animation
	landHardThreshold = -0.9, -- When landing with y velocity below this number, play "hard" landing animation

	lastOnGround = false,
	lastFlying = false,
	-- lastSprinting = false,

	-- sprintMult = 0,
	-- sprintLastMult = 0,
	-- sprintMultLerpRate = 0.2,

	-- One tick delay for attack anim check thing
	oneTickDelayFunc = nil,
	oneTickDelay = 1,

	cancelSwing = false, -- Set to true when player presses attack, set back to false when player's arm is no longer swinging
	showSwipe = false, -- Set to true before attack anim to show swipe if applicable

	-- What animations are allowed for each item.
	itemAnims = {
		["minecraft:wooden_sword"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = true, ["jumpKick"] = false,
		},
		["minecraft:stone_sword"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = true, ["jumpKick"] = false,
		},
		["minecraft:iron_sword"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = true, ["jumpKick"] = false,
		},
		["minecraft:golden_sword"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = true, ["jumpKick"] = false,
		},
		["minecraft:diamond_sword"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = true, ["jumpKick"] = false,
		},
		["minecraft:netherite_sword"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = true,
		},

		["minecraft:wooden_axe"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = false, ["jumpKick"] = false,
		},
		["minecraft:stone_axe"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = false, ["jumpKick"] = false,
		},
		["minecraft:iron_axe"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = false, ["jumpKick"] = false,
		},
		["minecraft:golden_axe"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = false, ["jumpKick"] = false,
		},
		["minecraft:diamond_axe"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = false, ["jumpKick"] = false,
		},
		["minecraft:netherite_axe"] = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = false, ["jumpKick"] = false,
		},

		["minecraft:trident"] = {
			["swipeR"] = true, ["punchR"] = false, ["thrustR"] = true, ["jumpKick"] = true,
		},
	},
}

-- Subscribable events

modules.events.fall = modules.events:new()

-- Events

function exAnims.init()
	animations["models.cat"].fall:play()
	animations["models.cat"].jump:play()
	animations["models.cat"].climb:play()
	-- animations["models.cat"].run:play()

	animations["models.cat"].swipeR:priority(1)
	animations["models.cat"].swipeD:priority(1)
	animations["models.cat"].jumpKick:priority(1)
	animations["models.cat"].punchR:priority(1)
	animations["models.cat"].thrustR:priority(1)
	animations["models.cat"].thrustR:speed(1.25)

	-- Register invisible keybind for attack anims
	if host:isHost() then
		keybind:create("Attack", keybind:getVanillaKey("key.attack")).onPress = exAnims.attackAnim
	end

	models.cat.RightArm.swipe:setVisible(false)
	models.cat.RightArm.swipe:setLight(15, 15)
end
modules.events.ENTITY_INIT:register(exAnims.init)

function exAnims.tick()
	-- Handle one tick delay funcs - whoopsies
	if exAnims.oneTickDelayFunc ~= nil then
		if exAnims.oneTickDelay > 0 then
			exAnims.oneTickDelay = exAnims.oneTickDelay - 1
		else
			exAnims.oneTickDelayFunc()
			exAnims.oneTickDelayFunc = nil
			exAnims.oneTickDelay = 1
		end
	end


	exAnims.lastVelY = exAnims.newVelY
	exAnims.newVelY = player:getVelocity().y

	-- Control multiplier for jump/fall animations
	exAnims.lastMult = exAnims.mult
	exAnims.mult = math.lerp(exAnims.mult, player:isOnGround() and 0 or 1, exAnims.multLerpRate)

	if (exAnims.newVelY > exAnims.fallThreshold and exAnims.newVelY <= 0) and not player:isOnGround() then
		exAnims.mult = 0
	end

	if not player:isOnGround() and not player:isFlying() and exAnims.newVelY < exAnims.fallThreshold and exAnims.lastVelY >= exAnims.fallThreshold then
		modules.events.fall:run()
	end

	-- Player just landed
	if player:isOnGround() and not exAnims.lastOnGround then
		modules.events.fall:run()

		-- Land hard
		if exAnims.lastVelY < exAnims.landHardThreshold then
			-- Player wasn't sprinting
			if not player:isSprinting() then
				animations["models.cat"].landHard:play()
				exAnims.mult = 0
			else
				animations["models.cat"].landHardRun:play()
			end
		end
	end
	exAnims.lastOnGround = player:isOnGround()

	-- Player just toggled flight
	if player:isFlying() ~= exAnims.lastFlying then
		modules.events.fall:run()
	end
	exAnims.lastFlying = player:isFlying()

	--[[
	-- Player just toggled sprint
	if player:isSprinting() ~= exAnims.lastSprinting then
		exAnims.sprintMult = 0
	end
	exAnims.lastSprinting = player:isSprinting()
	exAnims.sprintMult = math.lerp(exAnims.sprintMult, exAnims.lastSprinting and 1 or 0, exAnims.sprintMultLerpRate)
	]]--
end
modules.events.TICK:register(exAnims.tick)

function exAnims.cancelSwingFunc()
	if not player:isSwingingArm() then
		exAnims.cancelSwing = false
	end
end
modules.events.TICK:register(exAnims.cancelSwingFunc)

function exAnims.render(tickProgress, context)
	local velY = math.lerp(exAnims.lastVelY, exAnims.newVelY, tickProgress)
	local mult = math.lerp(exAnims.lastMult, exAnims.mult, tickProgress)

	-- TODO: smooth exit when falling into water
	-- Only blend animations once per render event
	if context == "FIRST_PERSON" or context == "RENDER" then
		animations["models.cat"].fall:blend(player:isOnGround() and mult or (exAnims.newVelY <= exAnims.fallThreshold and mult or 0))
		animations["models.cat"].jump:blend(not player:isFlying() and math.clamp(velY, 0, 1) or 0)
		animations["models.cat"].climb:blend(player:isClimbing() and 1 or 0)
		animations["models.cat"].climb:speed(math.clamp(math.abs(velY * 3), 0, 1))
	end
	-- animations["models.cat"].run:blend(exAnims.sprintMult
	  -- * (1 - animations["models.cat"].jump:getBlend())
	  -- * (1 - animations["models.cat"].fall:getBlend()))

	if (not modules.emotes.isEmoting() or modules.emotes.emote ~= "hug") and not modules.sit.isSitting then
		-- Attack anims
		if exAnims.attackAnimPlaying() then
			if animations["models.cat"].thrustR:getPlayState() == "PLAYING" then
				local blend = 1 - (animations["models.cat"].jumpKick:getTime() / animations["models.cat"].thrustR:getLength())

				models.cat.RightLeg:setRot(-vanilla_model.RIGHT_LEG:getOriginRot() * blend)
				models.cat.LeftLeg:setRot(-vanilla_model.LEFT_LEG:getOriginRot() * blend)
				-- models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot() * blend)
				-- models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot() * blend)
				models.cat.Body:setRot(-vanilla_model.BODY:getOriginRot() * blend)
				models.cat.Head:setRot(-vanilla_model.HEAD:getOriginRot() * blend)
			elseif animations["models.cat"].jumpKick:getPlayState() == "PLAYING" then
				local blend = 1 - (animations["models.cat"].jumpKick:getTime() / animations["models.cat"].jumpKick:getLength())

				models.cat.RightLeg:setRot(-vanilla_model.RIGHT_LEG:getOriginRot() * blend)
				models.cat.LeftLeg:setRot(-vanilla_model.LEFT_LEG:getOriginRot() * blend)
				-- models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot() * blend)
				-- models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot() * blend)
				models.cat.Body:setRot(-vanilla_model.BODY:getOriginRot() * blend)
				models.cat.Head:setRot(-vanilla_model.HEAD:getOriginRot() * blend)
			-- elseif animations["models.cat"].swipeR:getPlayState() == "PLAYING" or animations["models.cat"].punchR:getPlayState() == "PLAYING" then
				-- models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot())
				-- models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot())
			elseif animations["models.cat"].swipeD:getPlayState() == "PLAYING" then	
				local blend = 1 - (animations["models.cat"].swipeD:getTime() / animations["models.cat"].swipeD:getLength())

				models.cat.RightLeg:setRot(-vanilla_model.RIGHT_LEG:getOriginRot() * blend)
				models.cat.LeftLeg:setRot(-vanilla_model.LEFT_LEG:getOriginRot() * blend)
				-- models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot() * blend)
				-- models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot() * blend)
				models.cat.Body:setRot(-vanilla_model.BODY:getOriginRot() * blend)
				models.cat.Head:setRot(-vanilla_model.HEAD:getOriginRot() * blend)
			end
		-- Land hard animation
		elseif animations["models.cat"].landHard:getPlayState() == "PLAYING" then
			local blend = 1 - (animations["models.cat"].landHard:getTime() / animations["models.cat"].landHard:getLength())

			models.cat.RightLeg:setRot(-vanilla_model.RIGHT_LEG:getOriginRot() * blend)
			models.cat.LeftLeg:setRot(-vanilla_model.LEFT_LEG:getOriginRot() * blend)
			models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot() * blend)
			models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot() * blend)
			models.cat.Body:setRot(-vanilla_model.BODY:getOriginRot() * blend)
			models.cat.Head:setRot(-vanilla_model.HEAD:getOriginRot() * blend)
		-- Land hard run animation
		elseif animations["models.cat"].landHardRun:getPlayState() == "PLAYING" then
			local blend = 1 - (animations["models.cat"].landHardRun:getTime() / animations["models.cat"].landHardRun:getLength())

			models.cat.RightLeg:setRot(-vanilla_model.RIGHT_LEG:getOriginRot() * blend)
			models.cat.LeftLeg:setRot(-vanilla_model.LEFT_LEG:getOriginRot() * blend)
			models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot() * blend)
			models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot() * blend)
			models.cat.Body:setRot(-vanilla_model.BODY:getOriginRot() * blend)
			models.cat.Head:setRot(-vanilla_model.HEAD:getOriginRot() * blend)
		-- Falling
		elseif previous.pose == "STANDING" and velY < 0 then
			models.cat.RightLeg:setRot(-vanilla_model.RIGHT_LEG:getOriginRot() * animations["models.cat"].fall:getBlend())
			models.cat.LeftLeg:setRot(-vanilla_model.LEFT_LEG:getOriginRot() * animations["models.cat"].fall:getBlend())
			models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot() * animations["models.cat"].fall:getBlend())
			models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot() * animations["models.cat"].fall:getBlend())
		-- Flying - lean model, don't kick legs
		elseif previous.pose == "STANDING" and player:isFlying() then
			-- models.cat.RightLeg:setRot(-vanilla_model.RIGHT_LEG:getOriginRot())
			-- models.cat.LeftLeg:setRot(-vanilla_model.LEFT_LEG:getOriginRot())
			-- models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot())
			-- models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot())
			-- models.cat:setRot(vec(-modules.tail.velMag, 0, 0) * 16)
		--[[
		-- Sprinting
		elseif previous.pose == "STANDING" and player:isSprinting() then
			models.cat.RightLeg:setRot(-vanilla_model.RIGHT_LEG:getOriginRot() * animations["models.cat"].run:getBlend())
			models.cat.LeftLeg:setRot(-vanilla_model.LEFT_LEG:getOriginRot() * animations["models.cat"].run:getBlend())
			models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot() * animations["models.cat"].run:getBlend())
			models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot() * animations["models.cat"].run:getBlend())
			models.cat.Body:setRot(-vanilla_model.BODY:getOriginRot() * animations["models.cat"].run:getBlend())
			models.cat.Head:setRot(-vanilla_model.HEAD:getOriginRot() * animations["models.cat"].run:getBlend())
		]]--
		else
			models.cat.RightLeg:setRot()
			models.cat.LeftLeg:setRot()
			models.cat.RightArm:setRot()
			models.cat.LeftArm:setRot()
			models.cat.Body:setRot()
			models.cat.Head:setRot()
			-- models.cat:setRot()
		end

		-- Cancel swinging if applicable
		if exAnims.cancelSwing then
			models.cat.RightArm:setRot(-vanilla_model.RIGHT_ARM:getOriginRot())
			models.cat.LeftArm:setRot(-vanilla_model.LEFT_ARM:getOriginRot())
			models.cat.Body:setRot(-vanilla_model.BODY:getOriginRot())
		end
	end
end
modules.events.RENDER:register(exAnims.render)



function exAnims.isFalling()
	return exAnims.newVelY <= exAnims.fallThreshold and not player:isOnGround() and not player:isFlying() and not previous.vehicle
end

function exAnims.attackAnimPlaying()
	return animations["models.cat"].swipeR:getPlayState() == "PLAYING"
		or animations["models.cat"].swipeD:getPlayState() == "PLAYING"
		or animations["models.cat"].punchR:getPlayState() == "PLAYING"
		or animations["models.cat"].thrustR:getPlayState() == "PLAYING"
		or animations["models.cat"].jumpKick:getPlayState() == "PLAYING"
end

-- Attack anim code
if host:isHost() then
	function exAnims.attackAnim()
		if action_wheel:isEnabled() then
			return
		end

		local e = host:getTargetedEntity()
		local g = player:isOnGround()
		local s = player:isSprinting()
		local sw = player:isSwingingArm()
		exAnims.oneTickDelayFunc = function()
			exAnims.attackAnimCheck(e, g, s, sw)
			exAnims.cancelSwing = exAnims.shouldCancelSwing()
		end
	end

	-- Check is delayed by one tick
	function exAnims.attackAnimCheck(e, onGround, sprinting, swingingArm)
		-- Get targeted entity and check health
		if e ~= nil and e:isLoaded() then
			exAnims.showSwipe = false
			if type(e) == "LivingEntityAPI" then
				if e:getHealth() == 0 then
					exAnims.showSwipe = exAnims.itemAnims[previous.mainItem.id] ~= nil
					pings.attackAnim("swipeD", true)
					return
				end
			end

			-- Standard attack

			-- Sprinting jump attack: drop kick
			if not onGround and sprinting and exAnims.canAnim("jumpKick") then
				pings.attackAnim("jumpKick", true)
			-- Sprinting ground attack: sword
			elseif onGround and sprinting and exAnims.canAnim("thrustR") then
				pings.attackAnim("thrustR", true)
			-- Standard sword swing
			elseif exAnims.itemAnims[previous.mainItem.id] ~= nil then
				exAnims.showSwipe = true
				pings.attackAnim(modules.util.pickFrom({
					exAnims.canAnim("swipeR") and "swipeR" or nil,
					exAnims.canAnim("punchR") and "punchR" or nil
				}), true)
			-- Punch animation
			else
				pings.attackAnim("punchR", true)
			end

			return
		end

		-- Attacking nothing
		if exAnims.itemAnims[previous.mainItem.id] ~= nil and exAnims.canAnim("swipeR") then
			exAnims.showSwipe = exAnims.itemAnims[previous.mainItem.id] ~= nil
			pings.attackAnim("swipeR", not swingingArm)
		end
	end
end

function pings.attackAnim(anim, forceStart)
	if forceStart then
		animations["models.cat"][anim]:stop()
	end
	animations["models.cat"][anim]:play()
end

-- Returns true if the animation should be played, based on the player's held main item.
function exAnims.canAnim(anim)
	-- Item found in table
	if exAnims.itemAnims[previous.mainItem.id] ~= nil then
		-- Animation is defined
		if exAnims.itemAnims[previous.mainItem.id][anim] ~= nil then
			return exAnims.itemAnims[previous.mainItem.id][anim]
		end
	end

	-- Item was not found in table, or animation is not defined in item's table
	return true
end

function exAnims.shouldCancelSwing()
	return exAnims.itemAnims[previous.mainItem.id] ~= nil and (exAnims.canAnim("swipeR") or exAnims.canAnim("punchR"))
end

return exAnims
