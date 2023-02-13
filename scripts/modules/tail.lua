-- Tail module

local tail = {
	-- Tail segment parts
	parts = {
		models.cat.Body.Tail1,
		models.cat.Body.Tail1.Tail2,
		models.cat.Body.Tail1.Tail2.Tail3,
		models.cat.Body.Tail1.Tail2.Tail3.Tail4,
		models.cat.Body.Tail1.Tail2.Tail3.Tail4.Tail5,
		models.cat.Body.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6,
		models.cat.Body.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7,
		models.cat.Body.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7.Tail8,
		models.cat.Body.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7.Tail8.Tail9
	},
	-- The internal rotations of the tail segments (internal, gets followed by displayedRotations and that's what gets diplayed)
	rotations = {
		vec(-12.5, 0, 0), vec(-12.5, 0, 0), vec(-12.5, 0, 0),
		vec(-12.5, 0, 0), vec(-10, 0, 0), vec(-10, 0, 0),
		vec(7.5, 0, 0), vec(7.5, 0, 0), vec(7.5, 0, 0)
	},
	-- The "displayed rotations" of the tail segments (simply lerps to follow ^)
	displayedRotations = {
		vec(-12.5, 0, 0), vec(-12.5, 0, 0), vec(-12.5, 0, 0),
		vec(-12.5, 0, 0), vec(-10, 0, 0), vec(-10, 0, 0),
		vec(7.5, 0, 0), vec(7.5, 0, 0), vec(7.5, 0, 0)
	},
	-- The values of displayedRotations one tick prior - used for tweening in render code
	lastDisplayedRotations = {
		vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0),
		vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0),
		vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0)
	},
	-- Defines the "resting positions" of the tail, set by certain animations
	intendedRotations = {
		vec(-12.5, 0, 0), vec(-12.5, 0, 0), vec(-12.5, 0, 0),
		vec(-12.5, 0, 0), vec(-10, 0, 0), vec(-10, 0, 0),
		vec(7.5, 0, 0), vec(7.5, 0, 0), vec(7.5, 0, 0)
	},
	-- "Ripples" - little offsets from the intended rotation that start at piece #1 and go through each subsequent one once per tick
	ripples = {
		vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0),
		vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0),
		vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0)
	},

	-- Rate that the displayed tail rotations will lerp towards their destinations
	lerpRate = 0.288,
	-- X and Z sway sine controllers
	swayBaseX = 0,
	swayBaseZ = 0,

	-- Last velocity magnitude (x/z)
	velMag = 0,
	-- Last vertical velocity
	velY = 0,
	-- Last body yaw
	bodyYaw = 0
}

-- Events

function tail.setIntendedRot()
	if previous.vehicle then
		tail.intendedRotations = {
			vec(-30, 0, 0), vec(-12.5, 0, 0), vec(-12.5, 0, 0),
			vec(-12.5, 0, 0), vec(-10, 0, 0), vec(-10, 0, 0),
			vec(7.5, 0, 0), vec(7.5, 0, 0), vec(7.5, 0, 0)
		}
	elseif modules.sit.isSitting then
		tail.intendedRotations = {
			vec(2.5 - 30, 0, 0), vec(-12.5, 0, 0), vec(-12.5, 0, 0),
			vec(-12.5, 0, 0), vec(-10, 0, 0), vec(-10, 0, 0),
			vec(7.5, 0, 0), vec(7.5, 0, 0), vec(7.5, 0, 0)
		}
	elseif previous.elytra then
		tail.intendedRotations = {
			vec(-5, 0, 0), vec(12.5, 0, 0), vec(12.5, 0, 0),
			vec(12.5, 0, 0), vec(7.5, 0, 0), vec(7.5, 0, 0),
			vec(-7.5, 0, 0), vec(-7.5, 0, 0), vec(-7.5, 0, 0)
		}
	elseif previous.pose == "STANDING" then
		tail.intendedRotations = {
			vec(-12.5, 0, 0), vec(-12.5, 0, 0), vec(-12.5, 0, 0),
			vec(-12.5, 0, 0), vec(-10, 0, 0), vec(-10, 0, 0),
			vec(7.5, 0, 0), vec(7.5, 0, 0), vec(7.5, 0, 0)
		}
	elseif previous.pose == "CROUCHING" then
		tail.intendedRotations = {
			vec(2.5, 0, 0), vec(-12.5, 0, 0), vec(-12.5, 0, 0),
			vec(-12.5, 0, 0), vec(-10, 0, 0), vec(-10, 0, 0),
			vec(7.5, 0, 0), vec(7.5, 0, 0), vec(7.5, 0, 0)
		}
	elseif previous.pose == "SWIMMING" then
		tail.intendedRotations = {
			vec(15, 0, 0), vec(15, 0, 0), vec(15, 0, 0),
			vec(15, 0, 0), vec(7.5, 0, 0), vec(7.5, 0, 0),
			vec(-7.5, 0, 0), vec(-7.5, 0, 0), vec(-7.5, 0, 0)
		}
	end
end
modules.events.vehicle:register(tail.setIntendedRot)
modules.events.chestplate:register(tail.setIntendedRot)
modules.events.pose:register(tail.setIntendedRot)
modules.events.sit:register(tail.setIntendedRot)

function tail.sleepEvent()
	if previous.pose == "SLEEPING" then
		tail.intendedRotations = {
			vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0),
			vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0),
			vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0),
		}
		for i = 1, #modules.tail.rotations do
			modules.tail.rotations[i] = modules.tail.intendedRotations[i]
		end
		for i = 1, #modules.tail.displayedRotations do
			modules.tail.displayedRotations[i] = modules.tail.intendedRotations[i]
		end
		for i = 1, #modules.tail.lastDisplayedRotations do
			modules.tail.lastDisplayedRotations[i] = modules.tail.intendedRotations[i]
		end
	end
end
modules.events.sleep:register(tail.sleepEvent)

function tail.velocityEvent()
	if not tail.canCheckVelocity() then
		return
	end

	tail.velY = previous.vel.y
	tail.velMag = previous.velMagXZ

	-- Torso is turning
	local bodyYaw = player:getBodyYaw()
	local bodyYawVelocity = bodyYaw - tail.bodyYaw
	tail.bodyYaw = bodyYaw
	-- Add torso turning twist/sway
	if bodyYawVelocity ~= 0 then
		local playerRot = player:getRot()
		-- To be perfectly h with you, I don't know how to explain what this does. Something with making the tail offset from body turning work for all angles
		local someVal = (math.cos(math.rad(playerRot.y)) * previous.vel.x) + (math.sin(math.rad(playerRot.y)) * previous.vel.z)

		bodyYawVelocity = bodyYawVelocity + (someVal * 10)
		tail.rotations[1] = tail.rotations[1] + vec(0, bodyYawVelocity, -bodyYawVelocity / 3)
	end

	-- Add horizontal velocity and y velocity change
	if tail.velMag ~= 0 then
		tail.rotations[1].x = tail.rotations[1].x + (tail.velMag * 22.5)
	end
	if tail.velY ~= 0 then
		tail.rotations[1].x = tail.rotations[1].x + (tail.velY * 45)
	end

	-- Clamp tail rotation
	-- Run if one of the above 3 modifications occured
	if bodyYawVelocity ~= 0 or tail.velMag ~= 0 or tail.velY ~= 0 then
		tail.rotations[1] = tail.clampRot(tail.rotations[1])
	end

	-- Do tail ripples
	tail.ripples[1] = (tail.rotations[1] - tail.displayedRotations[1]) / 7.5
	for i = #tail.parts, 1, -1 do
		if i < #tail.parts then
			tail.ripples[i + 1] = tail.ripples[i]
		end
		if i > 1 then
			tail.rotations[i] = tail.rotations[i] + tail.ripples[i]
		end
	end
end
modules.events.TICK:register(tail.velocityEvent)

function tail.movementEvent()
	local swayAdd = 0
	if tail.canSway() then
		-- Calculate how much distance the swaying tail should cover, and how fast it should sway
		local swayByVel = 0
		if math.abs(tail.velY) > tail.velMag then
			swayByVel = tail.velY * 8
		else
			swayByVel = tail.velMag * 8
		end

		-- Swaying when crouching (or blushing) is boosted
		if previous.pose == "CROUCHING" or ((modules.emotes.emote == "blush" or modules.emotes.emote == "hug") and modules.emotes.isEmoting()) or player:isUsingItem() then
			swayByVel = (swayByVel + 1) * 2
		-- Swaying when swimming is lessened with speed
		elseif previous.pose == "SWIMMING" or previous.pose == "FALL_FLYING" then
			swayByVel = swayByVel / 4
		end
		swayByVel = math.clamp(swayByVel, 0.75, 2)

		-- Swaying when freezing slows to a halt
		if player:getFrozenTicks() > 0 then
			swayByVel = math.max(swayByVel * (1 - (player:getFrozenTicks() / 140)), 0)
		end

		local swayDistX = 0.144 * swayByVel
		local swayDistZ = 1.584 * swayByVel

		-- Apply swaying
		local increaseTimersBy = swayByVel / 160
		tail.swayBaseX = (tail.swayBaseX + ((0.0125 + increaseTimersBy) * (144/20))) % (math.pi * 2)
		tail.swayBaseZ = (tail.swayBaseZ + ((0.0175 + increaseTimersBy) * (144/20))) % (math.pi * 8)

		swayAdd = vec(math.sin(tail.swayBaseX) * swayDistX, math.cos(tail.swayBaseZ) * swayDistZ, 0)
	end

	for i = 1, #tail.parts do
		-- Store previous values of displayedRotations
		tail.lastDisplayedRotations[i] = tail.displayedRotations[i]

		tail.rotations[i] = modules.util.vecLerp(tail.rotations[i], tail.intendedRotations[i], tail.lerpRate)
		tail.displayedRotations[i] = modules.util.vecLerp(tail.displayedRotations[i], tail.rotations[i], tail.lerpRate)

		-- Don't sway if sleeping
		if previous.pose ~= "SLEEPING" then
			tail.displayedRotations[i] = tail.displayedRotations[i] + swayAdd
		end
	end
end
modules.events.TICK:register(tail.movementEvent)

function tail.renderEvent(tickProgress)
	for i = 1, #tail.parts do
		tail.parts[i]:setRot(modules.util.vecLerp(tail.lastDisplayedRotations[i], tail.displayedRotations[i], tickProgress))
	end
end
modules.events.RENDER:register(tail.renderEvent)



function tail.clampRot(rot)
	-- Clamp x (tail up/down)
	-- Different for elytra flying
	if previous.pose == "FALL_FLYING" then
		rot.x = math.clamp(rot.x, 10, 30)
	-- Different for swimming
	elseif previous.pose == "SWIMMING" then
		rot.x = math.clamp(rot.x, -20, 25)
	-- Elytra equipped, normal poses
	elseif previous.elytra then
		rot.x = math.clamp(rot.x, -15, 0)
	-- Standard clamping
	else
		rot.x = math.clamp(rot.x, -20, 45)
	end

	-- Clamp y (tail forward/back)
	-- Different for elytra flying
	if previous.pose == "FALL_FLYING" then
		rot.y = math.clamp(rot.y, -30, 30)
	-- Different for swimming
	elseif previous.pose == "SWIMMING" then
		rot.y = math.clamp(rot.y, -25, 25)
	-- Standard clamping
	else
		rot.y = math.clamp(rot.y, -70, 70)
	end

	rot.z = math.clamp(rot.z, -50, 50)

	return rot
end

function tail.canSway()
	return previous.pose ~= "SLEEPING" and not previous.invisible
end

function tail.canCheckVelocity()
	return not previous.vehicle and previous.freezeTicks == 0 and not previous.invisible
end

return tail
