-- Sit module

local sit = {
	-- Is sitting?
	isSitting = false,
	-- Cycling timer used for sin and cos operations in sit animation
	swayTimer = 0,
	-- Displayed rotations for the legs
	rotLLeg = vec(0, 0, 0),
	rotRLeg = vec(0, 0, 0),
	-- Last displayed rotations for the legs
	lastRotLLeg = vec(0, 0, 0),
	lastRotRLeg = vec(0, 0, 0),
	-- Display rotation for the head
	rotHead = vec(0, 0, 0),
	-- Last displayed rotation for the head
	lastRotHead = vec(0, 0, 0),
	-- Starting rotations for limbs
	legStartL = vec(0, 0, 0),
	legStartR = vec(0, 0, 0),
	armStartL = vec(0, 0, 0),
	armStartR = vec(0, 0, 0),
	-- For each vanilla armor model piece, whether it was enabled before sleeping, to be reapplied upon getting back up
	armorPartsEnabled = {
		HELMET = true,
		HELMET_ITEM = true,
		CHESTPLATE = false,
		LEGGINGS = false,
		BOOTS = true
	}
}

-- Subscribable events

modules.events.sit = modules.events:new()

-- Events

function sit.update()
	if sit.isSitting then
		sit.swayTimer = (sit.swayTimer + 0.15625) % 18.90625
		if modules.emotes.isEmoting() and modules.emotes.emote == "blush" then
			sit.swayTimer = sit.swayTimer + 0.05
		end

		sit.lastRotLLeg = sit.rotLLeg
		sit.rotLLeg = sit.legStartL + vec((math.sin(sit.swayTimer * 2) * 7.5) + 7.5, (math.cos(sit.swayTimer) * 2) + 2, (math.sin(sit.swayTimer) * 2.5) + 20)
		sit.lastRotRLeg = sit.rotRLeg
		sit.rotRLeg = sit.legStartR + vec((-math.sin(sit.swayTimer * 2) * 7.5) + 7.5, (math.cos(sit.swayTimer) * 2) - 4, (math.sin(sit.swayTimer) * 2.5) - 22.5)
		sit.lastRotHead = sit.rotHead
		sit.rotHead = vec(22.5 + math.clamp(previous.lookDir.y * 45, -56.25, 67.5), 0, math.sin(sit.swayTimer * (2/3)) * 22.5f)

		-- Only the model wearer's client decides if they should stop posing
		if host:isHost() then
			if not sit.canSit() then
				pings.sitPose(false)
			end
		end
	end
end
modules.events.TICK:register(sit.update)

function sit.render(tickProgress)
	-- Sit animation interpolation and head facing
	if sit.isSitting then
		models.cat.LeftLeg:setRot(modules.util.vecLerp(sit.lastRotLLeg, sit.rotLLeg, tickProgress))
		models.cat.RightLeg:setRot(modules.util.vecLerp(sit.lastRotRLeg, sit.rotRLeg, tickProgress))
		models.cat.Head:setRot(modules.util.vecLerp(sit.lastRotHead, sit.rotHead, tickProgress))
	end
end
modules.events.RENDER:register(sit.render)



function sit.sitPose(newSit)
	sit.isSitting = newSit
	
	if newSit then
		sit.startSitting()
	else
		sit.stopSitting()
	end
end
pings.sitPose = sit.sitPose

function sit.startSitting()
	sit.swayTimer = 0
	animations["models.cat"].sitPose1:play()

	-- TODO
	--[[
	-- Raycast just below where the legs will be dangling, to see if it's OK for them to dangle lower
	-- Converts body yaw angle in degrees into a unit vector
	local direction = vec(-math.sin(math.rad(previous.bodyYaw)), 0, math.cos(math.rad(previous.bodyYaw))).normalized()
	local checkPos1 = player:getPos() + (direction * 0.35)
	local checkPos2 = player:getPos() + (direction * 1.5) + vec(0, -0.24, 0)
	local result = renderer.raycastBlocks(checkPos1, checkPos2, "COLLIDER", "NONE")
	if result == nil then
		local legAddPos = vec(0, 0, -1)
		vanilla_model.LEFT_LEG:setPos(vanilla_model.LEFT_LEG:getPos() + legAddPos)
		vanilla_model.RIGHT_LEG:setPos(vanilla_model.RIGHT_LEG:getPos() + legAddPos)

		local legAddRot = vec(-45, 0, 0):toRad()
		vanilla_model.LEFT_LEG:setRot(vanilla_model.LEFT_LEG:getRot() + legAddRot)
		vanilla_model.RIGHT_LEG:setRot(vanilla_model.RIGHT_LEG:getRot() + legAddRot)

		vanilla_model.TORSO:setPos(vanilla_model.TORSO:getPos() + vec(0, -1.5, -3.5))
		vanilla_model.TORSO:setRot(vanilla_model.TORSO:getRot() + vec(-22.5, 0, 0):toRad())

		local armAddPos = vec(0, -0.5, -2.5)
		vanilla_model.LEFT_ARM:setPos(vanilla_model.LEFT_ARM:getPos() + armAddPos)
		vanilla_model.RIGHT_ARM:setPos(vanilla_model.RIGHT_ARM:getPos() + armAddPos)

		vanilla_model.LEFT_ARM:setRot(vanilla_model.LEFT_ARM:getRot() + vec(-22.5, 0, 11.25):toRad())
		vanilla_model.RIGHT_ARM:setRot(vanilla_model.RIGHT_ARM:getRot() + vec(-22.5, 0, -11.25):toRad())

		vanilla_model.HEAD:setPos(vanilla_model.HEAD:getPos() + vec(0, -1, -2.5))
	end
	]]--

	-- Unparent custom parts
	models.cat.RightLeg:setParentType("None")
	models.cat.LeftLeg:setParentType("None")
	models.cat.Body:setParentType("None")
	models.cat.RightArm:setParentType("None")
	models.cat.LeftArm:setParentType("None")
	models.cat.Head:setParentType("None")

	-- Set starting angles
	sit.armStartL = models.cat.LeftArm:getRot()
	sit.armStartR = models.cat.RightArm:getRot()
	sit.legStartL = models.cat.LeftLeg:getRot()
	sit.rotLLeg = models.cat.LeftLeg:getRot()
	sit.lastRotLLeg = models.cat.LeftLeg:getRot()
	sit.legStartR = models.cat.RightLeg:getRot()
	sit.rotRLeg = models.cat.RightLeg:getRot()
	sit.lastRotRLeg = models.cat.RightLeg:getRot()

	-- Unfortunately, vanilla armor cannot be forced to match up with the custom rotations and positions.
	-- Instead, it will all be disabled.
	-- TODO: Implement if/when individual armor piece manipulation is added to Figura
	-- previous.vanity.head = {id = "minecraft:air"}
	-- showEarArmor("minecraft:air")
	-- previous.elytra = settings.elytraFix and previous.elytra
	-- previous.vanity.chest = {id = "minecraft:air"}
	-- showChestArmor("minecraft:air")
	-- previous.vanity.pants = {id = "minecraft:air"}
	-- showPantsArmor("minecraft:air")
	for k, v in pairs(sit.armorPartsEnabled) do
		sit.armorPartsEnabled[k] = vanilla_model[k]:getVisible()
		vanilla_model[k]:setVisible(false)
	end

	-- Elytra model manip
	if settings.model.elytra.enabled then
		models.elytra.LEFT_ELYTRA:setPos(models.elytra.LEFT_ELYTRA:getPos() - vec(-2, 15 + 2, -2))
		models.elytra.LEFT_ELYTRA:setRot(models.elytra.LEFT_ELYTRA:getRot() - vec(22.5, 45, 0))
		models.elytra.RIGHT_ELYTRA:setPos(models.elytra.RIGHT_ELYTRA:getPos() - vec(2, 15 + 2, -2))
		models.elytra.RIGHT_ELYTRA:setRot(models.elytra.RIGHT_ELYTRA:getRot() - vec(22.5, -45, 0))
	end

	modules.events.sit:run()
end

function sit.stopSitting()
	animations["models.cat"].sitPose1:stop()

	-- Reparent custom parts
	models.cat.LeftLeg:setParentType("LeftLeg")
	models.cat.RightLeg:setParentType("RightLeg")
	models.cat.Body:setParentType("Body")
	models.cat.LeftArm:setParentType("LeftArm")
	models.cat.RightArm:setParentType("RightArm")
	models.cat.Head:setParentType("Head")

	-- Undo part rotations and offsets
	models.cat.LeftLeg:setPos(vec(0, 0, 0))
	models.cat.LeftLeg:setRot(vec(0, 0, 0))
	models.cat.RightLeg:setPos(vec(0, 0, 0))
	models.cat.RightLeg:setRot(vec(0, 0, 0))
	models.cat.Body:setPos(vec(0, 0, 0))
	models.cat.Body:setRot(vec(0, 0, 0))
	models.cat.LeftArm:setPos(vec(0, 0, 0))
	models.cat.LeftArm:setRot(vec(0, 0, 0))
	models.cat.RightArm:setPos(vec(0, 0, 0))
	models.cat.RightArm:setRot(vec(0, 0, 0))
	models.cat.Head:setPos(vec(0, 0, 0))
	models.cat.Head:setRot(vec(0, 0, 0))

	-- Restore vanilla armor
	for k, v in pairs(sit.armorPartsEnabled) do
		vanilla_model[k]:setVisible(v)
	end

	modules.events.sit:run()
end

function sit.canSit()
	return not previous.invisible and previous.vel:length() < 0.05 and player:isOnGround() and previous.pose == "STANDING"
end

return sit
