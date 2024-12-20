-- Extra animations module

local exAnims = {
	newVelY = 0, -- do not use
	lastVelY = 0,

	fallThreshold = -0.4, -- When y velocity is below this number, start fall animation
	landHardThreshold = -0.9, -- When landing with y velocity below this number, play "hard" landing animation

	lastOnGround = false,
	lastClimbing = false,
	climbingFaceDir = nil,
	lastFlying = false,
	lastBlocking = false,

	-- Idle animation timer
	idleTimer = 0,
	idleTime = 75 * 20,

	-- One tick delay for attack anim check thing
	oneTickDelayFunc = nil,
	oneTickDelay = 1,

	showSwipe = false, -- Set to true before attack anim to show swipe if applicable

	-- What animations are allowed for each item.
	itemAnims = {
		default = {
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = false, ["jumpKick"] = true,
		},

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
			["swipeR"] = true, ["punchR"] = true, ["thrustR"] = true, ["jumpKick"] = false,
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
	-- Anim time to start blending out swipe, if applicable
	swipeBlendOutStart = {
		swipeR = 0.08,
		swipeD = 0.12,
		punchR = 0.08,
	},
}

-- Subscribable events

modules.events.fall = modules.events:new()

modules.events.block = modules.events:new(events.TICK)
modules.events.block.condition = function()
	local lastBlocking = exAnims.lastBlocking
	local blocking = player:isUsingItem() and player:getActiveItem():getUseAction() == "BLOCK" and not previous.vehicle and player:isAlive()
	exAnims.lastBlocking = blocking
	return blocking ~= lastBlocking
end

-- Events

function exAnims.init()
	modules.animations.thrustR.anim:speed(1.1875)
	modules.animations.blockR.anim:speed(1.1)
	modules.animations.blockL.anim:speed(1.1)

	-- Register invisible keybind for attack anims
	if host:isHost() then
		keybinds:newKeybind("Attack", keybinds:getVanillaKey("key.attack")).press = exAnims.attackAnim
	end

	models.cat.RightArm.swipe:setVisible(false)
	models.cat.RightArm.swipe:setPrimaryRenderType("TRANSLUCENT")
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

	-- Start and stop jump animation when moving up or down
	if exAnims.newVelY > 0 and exAnims.lastVelY <= 0 then
		if not exAnims.lastFlying then
			modules.animations.jump:play()
			modules.animations.jump:fade(modules.animations.fadeModes.FADE_IN_FIXED, 0.75)
		end
	elseif exAnims.newVelY > exAnims.lastVelY then
		if not modules.animations.jump:isFading() then
			modules.animations.jump:fade(modules.animations.fadeModes.FADE_OUT_FIXED, 0.4)
		end
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
			else
				modules.animations.landHardRun:play()
			end
		end
	end
	exAnims.lastOnGround = onGround

	-- Player just toggled flight
	if previous.flying ~= exAnims.lastFlying then
		if modules.animations.jump.anim:getPlayState() == "PLAYING" then
			modules.animations.jump:fade(modules.animations.fadeModes.FADE_OUT_FIXED, 0.4)
		end
	end
	exAnims.lastFlying = previous.flying

	-- Player just mounted or dismounted a ladder
	local isClimbing = player:isClimbing() and not previous.vehicle
	if isClimbing ~= exAnims.lastClimbing then
		if not exAnims.lastClimbing then
			modules.animations.climb:play()
			modules.animations.climb:fade(modules.animations.fadeModes.FADE_IN_SMOOTH, 0.4)

			-- Get ladder/vine state, attempt to find facing direction
			local ladderState = world.getBlockState(player:getPos())
			exAnims.climbingFaceDir = exAnims.pickClimbDirection(ladderState)
		else
			-- modules.animations.climb:stop()
			modules.animations.climb:fade(modules.animations.fadeModes.FADE_OUT_SMOOTH, 0.6)
		end
	end
	exAnims.lastClimbing = isClimbing
end
modules.events.TICK:register(exAnims.tick)

function exAnims.fallEvent()
	if exAnims.isFalling() then
		-- Check collision of the space immediately below the player
		if not modules.util.collisionAt(player:getPos(0) + vec(0, -1.6, 0)) then
			modules.animations.fall:play()
			modules.animations.fall:fade(modules.animations.fadeModes.FADE_IN_SMOOTH, 0.4)
		end
	else
		if modules.animations.fall.fadeMode ~= modules.animations.fadeModes.FADE_OUT_SMOOTH then
			local _fadeProgress, _lastFadeProgress = modules.animations.fall.fadeProgress, modules.animations.fall.lastFadeProgress
			modules.animations.fall:fade(modules.animations.fadeModes.FADE_OUT_SMOOTH, 0.3)
			modules.animations.fall.fadeProgress, modules.animations.fall.lastFadeProgress = 1 - _fadeProgress, 1 - _lastFadeProgress
		end
	end
end
modules.events.fall:register(exAnims.fallEvent)

-- Runs when blocking with a shield
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

	pings.stopEmote(true)
end
modules.events.block:register(exAnims.blockEvent)

-- Controls swim idle animation
function exAnims.underwaterEvent()
	if previous.underwater and not player:isOnGround() and (previous.pose == "STANDING" or previous.pose == "CROUCHING") then
		modules.animations.swimIdle:play()
		modules.animations.swimIdle:fade(modules.animations.fadeModes.FADE_IN_SMOOTH, 0.1)
	else
		modules.animations.swimIdle:fade(modules.animations.fadeModes.FADE_OUT_SMOOTH, 0.4)
	end
end
modules.events.underwater:register(exAnims.underwaterEvent)
modules.events.fall:register(exAnims.underwaterEvent)
modules.events.pose:register(exAnims.underwaterEvent)

-- Idle animation
function exAnims.idleController()
	local isIdle = avatar:canEditVanillaModel() and not previous.invisible and modules.sit.canSit() and not modules.sit.isSitting and not (modules.emotes.isEmoting() and modules.emotes.emote == "hug") and not player:isUsingItem()

	if isIdle then
		if host:isHost() and not client:isPaused() then
			exAnims.idleTimer = exAnims.idleTimer + 1
		end
		if exAnims.idleTimer >= exAnims.idleTime and modules.animations.idle1.anim:getPlayState() ~= "PLAYING" then
			exAnims.idleTimer = 0
			modules.animations.idle1:play()
		end
	else
		exAnims.idleTimer = 0
		if modules.animations.idle1.anim:getPlayState() == "PLAYING" and not modules.animations.idle1:isFading() then
			modules.animations.idle1:fade(modules.animations.fadeModes.FADE_OUT_SMOOTH, 0.55)
		end
	end
end
modules.events.TICK:register(exAnims.idleController)

function exAnims.render(tickProgress, context)
	local velY = math.lerp(exAnims.lastVelY, exAnims.newVelY, tickProgress)

	-- Only blend animations once per render event
	if context == "FIRST_PERSON" or modules.util.renderedInWorld(context) then
		if modules.animations.jump.anim:getPlayState() == "PLAYING" then
			modules.animations.jump:blend(math.clamp(velY, 0, 1))
		end

		-- Climb animation blend
		if modules.animations.climb.anim:getPlayState() == "PLAYING" then
			-- Set climbing anim speed based on vertical movement
			if exAnims.lastClimbing then
				modules.animations.climb.anim:speed(math.clamp(math.abs(velY * 3), 0, 1))
			end

			-- TODO: Restore once a vanilla model-compatible method for this exists
			if not settings.model.vanillaMatch then
				-- Rotate to face direction, if set
				if exAnims.climbingFaceDir then
					local animFade = 1
					if modules.animations.climb:isFading() then
						animFade = modules.animations.climb:getFadeBlend(tickProgress)
					end

					local shortAngle = math.shortAngle(player:getBodyYaw(tickProgress), exAnims.climbingFaceDir)
					local diff = exAnims.climbingFaceDir - (player:getBodyYaw(tickProgress) % 360)
					models.cat:setRot(vec(0, -shortAngle * animFade, 0))
				end
			end
		else
			if not settings.model.vanillaMatch then
				models.cat:setRot()
			end
		end
	end
end
modules.events.RENDER:register(exAnims.render)



function exAnims.isFalling()
	return exAnims.newVelY <= exAnims.fallThreshold and not player:isOnGround() and not previous.flying and not previous.vehicle
end

-- Attack anim code
if host:isHost() then
	function exAnims.attackAnim()
		if action_wheel:isEnabled() or exAnims.lastBlocking then
			return
		end

		local e = player:getTargetedEntity(host:getReachDistance())
		if e == nil then
			if player:getTargetedBlock(true, host:getReachDistance()).id ~= "minecraft:air" then
				return
			end
		end
		local wasAlive = e and e:isAlive() or nil
		local g = player:isOnGround()
		local s = player:isSprinting()
		local sw = player:isSwingingArm()
		exAnims.oneTickDelayFunc = function()
			exAnims.attackAnimCheck(e, wasAlive, g, s, sw)
		end
	end

	-- Check is delayed by one tick
	function exAnims.attackAnimCheck(e, wasAlive, onGround, sprinting, swingingArm)
		-- Get targeted entity and check health
		if e ~= nil and (e:isLoaded() or wasAlive) then
			exAnims.showSwipe = false
			if (type(e) == "LivingEntityAPI" and e:getHealth() == 0) or (wasAlive and not e:isAlive()) then
				exAnims.showSwipe = exAnims.itemAnims[previous.mainItem.id] ~= nil
				pings.attackAnim("swipeD", e.getDeathTime and e:getDeathTime() == 0 or (wasAlive and not e:isAlive()))
				return
			end

			local entityHurting = false
			if type(e) == "LivingEntityAPI" then
				if not settings.misc.disableGetNbt then
					entityHurting = modules.util.getNbtValue(e:getNbt(), "HurtTime") > 0
				end
			end

			-- Standard attack

			-- Sprinting jump attack: drop kick
			if not onGround and sprinting and exAnims.canAnim("jumpKick") then
				pings.attackAnim("jumpKick", not entityHurting)
			-- Sprinting ground attack: sword
			elseif onGround and sprinting and exAnims.canAnim("thrustR") and (exAnims.itemAnims[previous.mainItem.id] ~= nil or exAnims.itemAnims.default["thrustR"]) then
				pings.attackAnim("thrustR", not entityHurting)
			-- Standard sword swing
			elseif exAnims.canAnim("swipeR") then
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
		if exAnims.canAnim("swipeR") then
			exAnims.showSwipe = true
			pings.attackAnim("swipeR", not swingingArm)
		end
	end
end

function pings.attackAnim(anim, forceStart)
	modules.animations[anim]:play(forceStart)
	if exAnims.showSwipe then
		models.cat.RightArm.swipe:setVisible(true)
		models.cat.RightArm.swipe:setOpacity(1)
	end
end

function exAnims.renderSwipe(tickProgress, ctx)
	if not modules.util.renderedInWorld(ctx) then
		if host:isHost() and renderer:isFirstPerson() then
			models.cat.RightArm.swipe:setVisible(false)
		end
		return
	end

	if models.cat.RightArm.swipe:getVisible() then
		local animName = modules.animations[1].anim:getName()
		if exAnims.swipeBlendOutStart[animName] then
			local timeSince = math.max(modules.animations[1].anim:getTime() - exAnims.swipeBlendOutStart[animName], 0)
			models.cat.RightArm.swipe:setOpacity(1 - (timeSince / 0.33))
			if models.cat.RightArm.swipe:getOpacity() <= 0 then
				models.cat.RightArm.swipe:setVisible(false)
			end
		end
	end
end
modules.events.RENDER:register(exAnims.renderSwipe)

-- Returns true if the animation should be played, based on the player's held main item.
function exAnims.canAnim(anim)
	local key = previous.mainItem.id
	if not exAnims.itemAnims[key] and previous.holdingWeapon then
		key = "default"
	end

	-- Item found in table
	if exAnims.itemAnims[key] ~= nil then
		-- Animation is defined
		if exAnims.itemAnims[key][anim] ~= nil then
			return exAnims.itemAnims[key][anim]
		end
	end

	-- Item was not found in table, or animation is not defined in item's table
	return false
end

-- Table that converts cardinal directions to vec3s.
local cardinalToVec = {
	north = vec(0, 0, -1),
	east = vec(1, 0, 0),
	south = vec(0, 0, 1),
	west = vec(-1, 0, 0)
}

-- Picks a direction to face when beginning to climb a ladder or vine
function exAnims.pickClimbDirection(blockState)
	local ladderProps = (blockState ~= nil and blockState.properties ~= nil) and blockState.properties or nil
	local resultantVec
	if ladderProps ~= nil then
		-- "facing" exists: this is a ladder. face opposite of its "facing" direction
		if ladderProps.facing ~= nil then
			resultantVec = -cardinalToVec[ladderProps.facing]
		-- "south"/"west"/"east"/"north" exists: this is a vine. try to find the "middle" or pick one.
		elseif ladderProps.north and ladderProps.south then
			-- Combine opposite vectors from all enabled sides
			local result = vec(0, 0, 0)

			for dirName, enabled in pairs(ladderProps) do
				if dirName ~= "up" then
					if enabled == "true" then
						result = result + cardinalToVec[dirName]
					end
				end
			end

			-- If resulting vector is 0, just return nil
			resultantVec = result ~= vec(0, 0, 0) and result or nil
		end
	end

	-- Convert to degree measure
	if resultantVec then
		return math.deg(math.atan2(resultantVec.z, resultantVec.x)) - 90
	end
end

return exAnims
