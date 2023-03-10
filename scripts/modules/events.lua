-- Events module

require("scripts/previous")

local events = {
	ENTITY_INIT = events.ENTITY_INIT,
	TICK = events.TICK,
	WORLD_TICK = events.WORLD_TICK,
	RENDER = events.RENDER,
	POST_RENDER = events.POST_RENDER,
	CHAT_RECEIVE_MESSAGE = events.CHAT_RECEIVE_MESSAGE,
}

function events:new(figuraEvent)
	local e = {}
	setmetatable(e, self)
	self.__index = self

	e.callbacks = {}
	if figuraEvent ~= nil then
		figuraEvent:register(function(...) e:run(...) end)
	end

	return e
end

function events:run(...)
	if self.condition ~= nil then
		if not self.condition(...) then
			return
		end
	end

	for i = 1, #self.callbacks do
		self.callbacks[i](...)
	end
end

function events:register(f)
	table.insert(self.callbacks, f)
end



-- Pre-configured events

-- Stat events
events.health = events:new(events.TICK)
events.health.condition = function()
	local lastHealthPercent = previous.healthPercent
	local healthPercent = player:getHealth() / player:getMaxHealth()
	previous.healthPercent = healthPercent
	return healthPercent ~= lastHealthPercent
end
events.food = events:new(events.TICK)
events.food.condition = function()
	local lastFood = previous.food
	local food = player:getFood()
	previous.food = food
	return food ~= lastFood
end
events.xp = events:new(events.TICK)
events.xp.condition = function()
	local lastXP = previous.xp
	local xp = player:getExperienceLevel() + player:getExperienceProgress()
	previous.xp = xp
	return xp ~= lastXP
end

-- Hurt event needs to exist immediately on model load. Condition is set below, after player init
events.hurt = events:new(events.TICK)
events.hurt.condition = function() return false end

events.ENTITY_INIT:register(function()
	-- Hurt event - has different behavior if entity:getNbt is disabled (thanks Requiem/Locki)
	if settings.misc.disableGetNbt then
		local lastHealthPercent = 0
		events.health:register(function()
			if lastHealthPercent > previous.healthPercent then
				previous.hurtTicks = 10
			end
			lastHealthPercent = previous.healthPercent
		end)

		events.hurt.condition = function()
			local lastHurtTicks = previous.hurtTicks
			previous.hurtTicks = math.max(0, previous.hurtTicks - 1)
			return lastHurtTicks == 10 or (previous.hurtTicks < lastHurtTicks and previous.hurtTicks == 0)
		end
	-- Hurt event default behavior
	else
		events.hurt.condition = function()
			local lastHurtTicks = previous.hurtTicks
			local hurtTicks = player:getNbt().HurtTime
			previous.hurtTicks = hurtTicks
			return (hurtTicks > lastHurtTicks and lastHurtTicks == 0) or (hurtTicks < lastHurtTicks and hurtTicks == 0)
		end
	end
end)

events.frozen = events:new(events.TICK)
events.frozen.condition = function()
	local lastFreezeTicks = previous.freezeTicks
	local freezeTicks = player:getFrozenTicks()
	previous.freezeTicks = freezeTicks
	return (freezeTicks > lastFreezeTicks and (lastFreezeTicks == 0 or freezeTicks == 140)) or (freezeTicks < lastFreezeTicks and (freezeTicks == 0 or lastFreezeTicks == 140))
end
events.firstPerson = events:new(events.TICK)
events.firstPerson.condition = function()
	local lastFirstPerson = previous.firstPerson
	local firstPerson = renderer:isFirstPerson()
	previous.firstPerson = firstPerson
	return firstPerson ~= lastFirstPerson
end

-- Player movement events
events.velocity = events:new(events.TICK)
events.velocity.condition = function()
	local lastVel = previous.vel
	local vel = player:getVelocity()
	previous.vel = vel
	previous.velMagXZ = vel.x_z:length()
	return vel ~= lastVel
end
events.lookDir = events:new(events.TICK)
events.lookDir.condition = function()
	local lastLookDir = previous.lookDir
	local lookDir = player:getLookDir()
	previous.lookDir = lookDir
	return lookDir ~= lastLookDir
end

-- Equipped item events
events.mainItem = events:new(events.TICK)
events.mainItem.condition = function()
	local lastMainItemString = previous.mainItemString
	local mainItem = player:getItem(1)
	previous.mainItem = mainItem
	previous.mainItemString = modules.util.asItemStack(mainItem):toStackString()
	return previous.mainItemString ~= lastMainItemString
end
events.offItem = events:new(events.TICK)
events.offItem.condition = function()
	local lastOffItemString = previous.offItemString
	local offItem = player:getItem(2)
	previous.offItem = offItem
	previous.offItemString = modules.util.asItemStack(offItem):toStackString()
	return previous.offItemString ~= lastOffItemString
end
events.helmet = events:new(events.TICK)
events.helmet.condition = function()
	local lastHelmetString = previous.helmetString

	-- Fetch new helmet, prioritizing vanity slot
	local newHelmet
	if settings.armor.vanitySlots then
		local vanityHead = modules.util.getNbtValue("cardinal_components.trinkets:trinkets.head.vanity")
		if vanityHead ~= nil then
			newHelmet = vanityHead.Items[1]
		end
	end
	if newHelmet == nil or newHelmet.id == "minecraft:air" then
		newHelmet = player:getItem(6)
	end
	previous.helmet = newHelmet
	previous.helmetString = modules.util.asItemStack(newHelmet):toStackString()

	return previous.helmetString ~= lastHelmetString
end
events.chestplate = events:new(events.TICK)
events.chestplate.condition = function()
	local lastChestplateString = previous.chestplateString

	-- Fetch new chestplate, prioritizing vanity slot
	local newChestplate
	if settings.armor.vanitySlots then
		local vanityChest = modules.util.getNbtValue("cardinal_components.trinkets:trinkets.chest.vanity")
		if vanityChest ~= nil then
			newChestplate = vanityChest.Items[1]
		end
	end
	if newChestplate == nil or newChestplate.id == "minecraft:air" then
		newChestplate = player:getItem(5)
	end
	previous.elytra, previous.elytraHide = modules.elytra.isElytra(player:getItem(5))
	previous.elytraGlint = modules.util.asItemStack(newChestplate):hasGlint()
	previous.chestplate = newChestplate
	previous.chestplateString = modules.util.asItemStack(newChestplate):toStackString()

	return previous.chestplateString ~= lastChestplateString
end
events.leggings = events:new(events.TICK)
events.leggings.condition = function()
	local lastLeggingsString = previous.leggingsString

	-- Fetch new leggings, prioritizing vanity slot
	local newLeggings
	if settings.armor.vanitySlots then
		local vanityLegs = modules.util.getNbtValue("cardinal_components.trinkets:trinkets.legs.vanity")
		if vanityLegs ~= nil then
			newLeggings = vanityLegs.Items[1]
		end
	end
	if newLeggings == nil or newLeggings.id == "minecraft:air" then
		newLeggings = player:getItem(4)
	end
	previous.leggings = newLeggings
	previous.leggingsString = modules.util.asItemStack(newLeggings):toStackString()

	return previous.leggingsString ~= lastLeggingsString
end
events.boots = events:new(events.TICK)
events.boots.condition = function()
	local lastBootsString = previous.bootsString

	-- Fetch new boots, prioritizing vanity slot
	local newBoots
	if settings.armor.vanitySlots then
		local vanityBoots = modules.util.getNbtValue("cardinal_components.trinkets:trinkets.feet.vanity")
		if vanityBoots ~= nil then
			newBoots = vanityBoots.Items[1]
		end
	end
	if newBoots == nil or newBoots.id == "minecraft:air" then
		newBoots = player:getItem(3)
	end
	previous.boots = newBoots
	previous.bootsString = modules.util.asItemStack(newBoots):toStackString()

	return previous.bootsString ~= lastBootsString
end

-- Invisible event
events.invisible = events:new(events.TICK)
events.invisible.condition = function()
	local lastInvisible = previous.invisible
	local invisible = player:isInvisible()
	previous.invisible = invisible
	return invisible ~= lastInvisible
end

-- Wet/fire events
events.wet = events:new(events.TICK)
events.wet.condition = function()
	local lastWet = previous.wet
	local wet = player:isWet()
	previous.wet = wet
	return wet ~= lastWet
end
events.underwater = events:new(events.TICK)
events.underwater.condition = function()
	local lastUnderwater = previous.underwater
	local underwater = player:isUnderwater()
	previous.underwater = underwater
	return underwater ~= lastUnderwater
end
events.fire = events:new(events.TICK)
events.fire.condition = function()
	local lastFire = previous.fire
	local fire = player:isOnFire()
	previous.fire = fire
	return fire ~= lastFire
end

-- Pose event
events.pose = events:new(events.TICK)
events.pose.condition = function()
	local lastPose = previous.pose
	local pose = player:getPose()
	previous.pose = pose
	return pose ~= lastPose
end

-- Vehicle event
events.vehicle = events:new(events.TICK)
events.vehicle.condition = function()
	local lastVehicle = previous.vehicle
	local vehicle = player:getVehicle() ~= nil
	previous.vehicle = vehicle
	return vehicle ~= lastVehicle
end


-- Host only events

-- Effects event
function pings.setEffects(newEffects)
	previous.effects = newEffects
end

if host:isHost() then
	events.effects = events:new(events.TICK)
	events.effects.condition = function()
		local lastEffects = previous.effects
		local effects = host:getStatusEffects()
		previous.effects = effects
		return modules.util.statusEffectsString(effects) ~= modules.util.statusEffectsString(lastEffects)
	end
	events.effects:register(function() pings.setEffects(previous.effects) end)


	-- Flying event
	function pings.setFlying(newFlying)
		previous.flying = newFlying
	end
	events.flying = events:new(events.TICK)
	events.flying.condition = function()
		local lastFlying = previous.flying
		local flying = host:isFlying()
		previous.flying = flying
		return flying ~= lastFlying
	end
	events.flying:register(function() pings.setFlying(previous.flying) end)
end

-- As of figura rc14, player:getAir has been moved to host:getAir
events.air = events:new(events.TICK)
if host.getAir then
	-- Air event
	function pings.setAir(newAir)
		previous.airPercent = newAir
	end
	if host:isHost() then
		events.air.condition = function()
			local lastAirPercent = previous.airPercent
			local airPercent = host:getAir() / player:getMaxAir()
			previous.airPercent = airPercent
			return airPercent ~= lastAirPercent
		end
		events.air:register(function() pings.setAir(previous.airPercent) end)
	end
else
	events.air.condition = function()
		local lastAirPercent = previous.airPercent
		local airPercent = player:getAir() / player:getMaxAir()
		previous.airPercent = airPercent
		return airPercent ~= lastAirPercent
	end
end



return events
