-- Ears module

local ears = {
	-- Rate the ears will lerp towards the target rotation by; affected by health and if in water
	lerpRate = 0.5,
	-- Default origin that the ears should be rotated at
	origin = vec(-3, 3, 3.75),
	-- Offset to add to ears when flicking them
	flickOffset = vec(-7.5, -12.5, 11),
	-- Target rotation for left and right ears post-calculation to use in rendering
	targetRotL = vec(-3, 3, 3.75),
	targetRotR = vec(-3, -3, -3.75),
	-- Left and right ear current positions that will lerp towards ^
	rotL = vec(-3, 3, 3.75),
	rotR = vec(-3, -3, -3.75),
	-- The values of ^ rotL and rotR one tick prior - used for tweening in render code
	lastRotL = vec(-3, 3, 3.75),
	lastRotR = vec(-3, -3, -3.75),
	-- Timers (in ticks) that determine when next to flick the left or right ear
	flickL = 0,
	flickR = 0
}

-- Events

function ears.helmetEvent()
	if not ears.canMove() then
		-- Force move LeftEar and RightEar rotations to the ear armor origins
		ears.lastRotL = vec(0, 0, 0)
		ears.lastRotR = vec(0, 0, 0)
		ears.rotL = ears.lastRotL
		ears.rotR = ears.lastRotR

		models.cat.Head.LeftEar:setRot(ears.rotL)
		models.cat.Head.RightEar:setRot(ears.rotR)
	end
end
modules.events.helmet:register(ears.helmetEvent)
modules.events.sleep:register(ears.helmetEvent)

function ears.positionEvent()
	if not ears.canMove() then
		return
	end

	-- Set lerp rate (ears move slower toward intended positions)
	ears.lerpRate = 0.15
	if not previous.wet and previous.freezeTicks == 0 then
		ears.lerpRate = ears.lerpRate + (previous.healthPercent * 0.35)
	end
	if previous.freezeTicks > 0 then
		ears.lerpRate = math.max(ears.lerpRate * (1 - (previous.freezeTicks / 140)), 0)
	end
	if modules.emotes.isEmoting() and modules.emotes.emote == "sad" then
		ears.lerpRate = ears.lerpRate / 2
	end

	-- Set intended ear positions
	local lower = 0.85 - (math.min(previous.healthPercent, previous.food / 20) * 0.85)
	if previous.wet then
		lower = 1 -- Same as no health
	elseif modules.emotes.isEmoting() and modules.emotes.emote == "sad" then
		lower = 1
	elseif previous.freezeTicks > 0 then
		lower = math.max(lower, lower + ((1 - lower) * previous.freezeTicks / 140))
	end
	ears.targetRotL = vec(ears.origin[1] - (lower * 20), ears.origin[2] + (lower * 20), ears.origin[3] + (lower * 25))
	ears.targetRotR = vec(ears.targetRotL[1], -ears.targetRotL[2], -ears.targetRotL[3])
end
modules.events.TICK:register(ears.positionEvent)
-- modules.events.helmet:register(ears.positionEvent)
-- modules.events.health:register(ears.positionEvent)
-- modules.events.wet:register(ears.positionEvent)
-- modules.events.frozen:register(ears.positionEvent)

function ears.motionEvent()
	if not ears.canMove() then
		return
	end

	-- Ear flick
	if ears.canFlickTimer() then
		ears.flickL = ears.flickL - 1
		if ears.flickL <= 0 then
			ears.flick(true)
		end
		ears.flickR = ears.flickR - 1
		if ears.flickR <= 0 then
			ears.flick(false)
		end
	end

	-- Store previous values of rotL and rotR
	ears.lastRotL = ears.rotL
	ears.lastRotR = ears.rotR

	-- Move ears
	ears.rotL = modules.util.vecLerp(ears.rotL, ears.targetRotL, ears.lerpRate)
	ears.rotR = modules.util.vecLerp(ears.rotR, ears.targetRotR, ears.lerpRate)
end
modules.events.TICK:register(ears.motionEvent)

function ears.renderEvent(tickProgress)
	models.cat.Head.LeftEar:setRot(modules.util.vecLerp(ears.lastRotL, ears.rotL, tickProgress))
	models.cat.Head.RightEar:setRot(modules.util.vecLerp(ears.lastRotR, ears.rotR, tickProgress))
end
modules.events.RENDER:register(ears.renderEvent)



function ears.flick(left)
	-- Calculate new position to flick the ear toward, and how many ticks until the next flick
	local newTimer = (math.random() * 300)
	newTimer = newTimer + ((1 - previous.healthPercent) * 125)

	if modules.emotes.isEmoting() then
		newTimer = newTimer - 100
	end
	if modules.sit.isSitting then
		newTimer = newTimer - 50
	end
	-- Predicted next rotation
	local targetRot = vec(ears.rotL[1] + ears.flickOffset[1], ears.rotL[2] + ears.flickOffset[2], ears.rotL[3] + ears.flickOffset[3])

	-- Set next flick timer, move ear
	if left then
		ears.rotL = targetRot
		ears.flickL = newTimer
	else
		targetRot[2] = -targetRot[2]
		targetRot[3] = -targetRot[3]
		ears.rotR = targetRot
		ears.flickR = newTimer
	end
end

function ears.canFlickTimer()
	return not previous.invisible and previous.freezeTicks < 140
end

function ears.canMove()
	return not modules.armor.earArmorVisible or modules.armor.canRotateEars
end

return ears
