-- Sit module

local sit = {
	-- Is sitting?
	isSitting = false,
	facingDir = nil,
	anim = modules.animations.sit1,
}

-- Subscribable events

modules.events.sit = modules.events:new()

-- Events

function sit.update()
	if sit.isSitting then
		if modules.emotes.isEmoting() and modules.emotes.emote == "blush" then
			sit.anim.anim:speed(1)
		else
			sit.anim.anim:speed(0.75)
		end

		-- Only the model wearer's client decides if they should stop posing
		if host:isHost() then
			if not sit.canSit() then
				pings.stopSitting(true)
			end
		end
	end
end
modules.events.TICK:register(sit.update)



function pings.sitSetFacingDir(dir)
	sit.facingDir = dir
end

if host:isHost() then
	function sit.pickSitAnim()
		-- "Raycast" a bit in front of the player to decide which animation to play
		local bodyYaw = player:getBodyYaw()
		local direction = vec(-math.sin(math.rad(bodyYaw)), 0, math.cos(math.rad(bodyYaw))):normalized()
		local checkPos1 = player:getPos() + (direction * 0.4) + vec(0, -0.01, 0)
		local checkPos2 = player:getPos() + (direction * 1.5) + vec(0, -0.24, 0)

		local raycastClean = not modules.util.collisionAt(checkPos1)
		if raycastClean then
			raycastClean = not modules.util.collisionAt(checkPos2)
		end

		pings.sitSetFacingDir(bodyYaw)

		return raycastClean and "sit2" or "sit1"
	end
end

function sit.startSitting(anim)
	if sit.isSitting then
		return
	end
	sit.isSitting = true

	-- Cancel hug animation if applicable
	if modules.emotes.isEmoting() and modules.emotes.emote == "hug" then
		pings.stopEmote(true)
	end

	sit.anim = modules.animations[anim]
	sit.anim:play()
	sit.anim:fade(modules.animations.fadeModes.FADE_IN_SMOOTH, 0.4)

	modules.events.sit:run()
end
pings.startSitting = sit.startSitting

function sit.stopSitting(animFast)
	sit.isSitting = false
	sit.anim:fade(modules.animations.fadeModes.FADE_OUT_SMOOTH, animFast and 0.6 or 0.2)
	-- models.cat:setRot()

	modules.events.sit:run()
end
pings.stopSitting = sit.stopSitting

-- Host only: Camera offset when sitting
if host:isHost() then
	modules.events.sit:register(function()
		modules.camera.yOffset = modules.sit.isSitting and -0.5 or 0
	end)
end

function sit.faceSameDirection(delta, ctx)
	--TODO: Restore once a vanilla model-compatible method for this exists
	if not modules.util.renderedInWorld(ctx) or settings.model.vanillaMatch then
		return
	end

	if sit.anim.anim:isPlaying() or sit.anim:isFading() then
		local animFade = 1
		if sit.anim:isFading() then
			animFade = sit.anim:getFadeBlend(delta)
		end

		local shortAngle = math.shortAngle(player:getBodyYaw(delta), sit.facingDir)
		local diff = sit.facingDir - (player:getBodyYaw(delta) % 360)
		models.cat:setRot(vec(0, -shortAngle * animFade, 0))
	end
end
modules.events.RENDER:register(sit.faceSameDirection)

function sit.canSit()
	return not previous.invisible and previous.velMagXZ < 0.05 and player:isOnGround() and previous.pose == "STANDING"
end

return sit
