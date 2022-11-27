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
	lastClimbing = false,
	lastFlying = false,
	-- lastSprinting = false,
	lastBlocking = false,

	-- sprintMult = 0,
	-- sprintLastMult = 0,
	-- sprintMultLerpRate = 0.2,

	-- One tick delay for attack anim check thing
	oneTickDelayFunc = nil,
	oneTickDelay = 1,

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

modules.events.block = modules.events:new(events.TICK)
modules.events.block.condition = function()
	local lastBlocking = exAnims.lastBlocking
	local blocking = player:isUsingItem() and player:getActiveItem().id == "minecraft:shield"
	exAnims.lastBlocking = blocking
	return blocking ~= lastBlocking
end

-- Events

function exAnims.init()
	-- animations["models.cat"].fall:play()
	-- animations["models.cat"].jump:play()
	-- animations["models.cat"].climb:play()
	-- animations["models.cat"].run:play()

	modules.animations.thrustR.anim:speed(1.1875)
	modules.animations.blockR.anim:speed(1.1)
	modules.animations.blockL.anim:speed(1.1)

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

	-- Start and stop jump animation when moving up or down
	-- TODO: make jump a tertiary animation so it doesn't override stuff like ladder climbing...?
	if exAnims.newVelY > 0 and exAnims.lastVelY <= 0 then
		modules.animations.jump:play()
	elseif exAnims.newVelY > exAnims.lastVelY then
		modules.animations.jump:stop()
	end

	if exAnims.newVelY < exAnims.fallThreshold and exAnims.lastVelY >= exAnims.fallThreshold then
		modules.events.fall:run()
	elseif exAnims.newVelY >= exAnims.fallThreshold and exAnims.lastVelY < exAnims.fallThreshold then
		modules.events.fall:run()
	end

	-- Player just landed
	local onGround = player:isOnGround()
	if onGround ~= exAnims.lastOnGround then
		modules.events.fall:run()
	end
	if onGround and not exAnims.lastOnGround then
		-- Land hard
		if exAnims.lastVelY < exAnims.landHardThreshold then
			-- Player wasn't sprinting
			if not player:isSprinting() then
				modules.animations.landHard:play()
				exAnims.mult = 0
			else
				modules.animations.landHardRun:play()
			end
		end
	end
	exAnims.lastOnGround = onGround

	-- Player just toggled flight
	if player:isFlying() ~= exAnims.lastFlying then
		-- modules.events.fall:run()
		if modules.animations.jump.anim:getPlayState() == "PLAYING" then
			modules.animations.jump:stop()
		end
	end
	exAnims.lastFlying = player:isFlying()

	-- Player just mounted or dismounted a ladder
	if player:isClimbing() ~= exAnims.lastClimbing then
		if not exAnims.lastClimbing then
			modules.animations.climb:play()
		else
			modules.animations.climb:stop()
		end
	end
	exAnims.lastClimbing = player:isClimbing()

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

function exAnims.fallEvent()
	if exAnims.isFalling() then
		modules.animations.fall:play()
	else
		modules.animations.fall:stop()
	end
end
modules.events.fall:register(exAnims.fallEvent)

function exAnims.blockEvent()
	local hands = { "R", "L" }
	local activeHand = player:getActiveHand() == "MAIN_HAND" and 1 or 2
	if player:isLeftHanded() then
		activeHand = 3 - activeHand
	end
	activeHand = hands[activeHand]

	local anim = modules.animations["block" .. activeHand]

	if exAnims.lastBlocking then
		anim:play()
	else
		anim:stop()
	end
end
modules.events.block:register(exAnims.blockEvent)

function exAnims.underwaterEvent()
	if previous.underwater and not player:isOnGround() and (previous.pose == "STANDING" or previous.pose == "CROUCHING") then
		modules.animations.swimIdle:play()
	else
		modules.animations.swimIdle:stop()
	end
end
modules.events.underwater:register(exAnims.underwaterEvent)
modules.events.fall:register(exAnims.underwaterEvent)
modules.events.pose:register(exAnims.underwaterEvent)

function exAnims.render(tickProgress, context)
	local velY = math.lerp(exAnims.lastVelY, exAnims.newVelY, tickProgress)
	local mult = math.lerp(exAnims.lastMult, exAnims.mult, tickProgress)

	-- TODO: smooth exit when falling into water
	-- Only blend animations once per render event
	if context == "FIRST_PERSON" or context == "RENDER" then
		if modules.animations.fall.anim:getPlayState() == "PLAYING" then
			modules.animations.fall:blend(player:isOnGround() and mult or (exAnims.newVelY <= exAnims.fallThreshold and mult or 0))
		end
		if modules.animations.jump.anim:getPlayState() == "PLAYING" then
			modules.animations.jump:blend(not player:isFlying() and math.clamp(velY, 0, 1) or 0)
		end
		if modules.animations.climb.anim:getPlayState() == "PLAYING" then
			modules.animations.climb.anim:speed(math.clamp(math.abs(velY * 3), 0, 1))
		end
	end
	-- animations["models.cat"].run:blend(exAnims.sprintMult
	  -- * (1 - animations["models.cat"].jump:getBlend())
	  -- * (1 - animations["models.cat"].fall:getBlend()))
end
modules.events.RENDER:register(exAnims.render)



function exAnims.isFalling()
	return exAnims.newVelY <= exAnims.fallThreshold and not player:isOnGround() and not player:isFlying() and not previous.vehicle
end

-- Attack anim code
if host:isHost() then
	function exAnims.attackAnim()
		if action_wheel:isEnabled() or exAnims.lastBlocking then
			return
		end

		local e = player:getTargetedEntity(5)
		local g = player:isOnGround()
		local s = player:isSprinting()
		local sw = player:isSwingingArm()
		exAnims.oneTickDelayFunc = function()
			exAnims.attackAnimCheck(e, g, s, sw)
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
					pings.attackAnim("swipeD", e:getDeathTime() == 0)
					return
				end
			end

			local entityHurting = not (type(e) == "LivingEntityAPI" and (modules.util.getNbtValue(e:getNbt(), "HurtTime") == 0) or false)

			-- Standard attack

			-- Sprinting jump attack: drop kick
			if not onGround and sprinting and exAnims.canAnim("jumpKick") then
				pings.attackAnim("jumpKick", not entityHurting)
			-- Sprinting ground attack: sword
			elseif onGround and sprinting and exAnims.canAnim("thrustR") then
				pings.attackAnim("thrustR", not entityHurting)
			-- Standard sword swing
			elseif exAnims.itemAnims[previous.mainItem.id] ~= nil then
				exAnims.showSwipe = true
				pings.attackAnim(modules.util.pickFrom({
					exAnims.canAnim("swipeR") and "swipeR" or nil,
					exAnims.canAnim("punchR") and "punchR" or nil
				}), not entityHurting)
			-- Punch animation
			else
				pings.attackAnim("punchR", not entityHurting)
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
	modules.animations[anim]:play(forceStart)
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

return exAnims
