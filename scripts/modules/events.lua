-- Events module

require("scripts/previous")

local events = {
	ENTITY_INIT = events.ENTITY_INIT,
	TICK = events.TICK,
	RENDER = events.RENDER,
	POST_RENDER = events.POST_RENDER
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
events.air = events:new(events.TICK)
events.air.condition = function()
	local lastAirPercent = previous.airPercent
	local airPercent = player:getAir() / player:getMaxAir()
	previous.airPercent = airPercent
	return airPercent ~= lastAirPercent
end
events.xp = events:new(events.TICK)
events.xp.condition = function()
	local lastXP = previous.xp
	local xp = player:getExperienceLevel() + player:getExperienceProgress()
	previous.xp = xp
	return xp ~= lastXP
end
events.hurt = events:new(events.TICK)
events.hurt.condition = function()
	local lastHurtTicks = previous.hurtTicks
	local hurtTicks = player:getNbt().HurtTime
	previous.hurtTicks = hurtTicks
	return (hurtTicks > lastHurtTicks and lastHurtTicks == 0) or (hurtTicks < lastHurtTicks and hurtTicks == 0)
end
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
	local lastMainItem = previous.mainItem
	local mainItem = player:getItem(1)
	previous.mainItem = mainItem
	return modules.util.asItemStack(mainItem):toStackString() ~= modules.util.asItemStack(lastMainItem):toStackString()
end
events.offItem = events:new(events.TICK)
events.offItem.condition = function()
	local lastOffItem = previous.offItem
	local offItem = player:getItem(2)
	previous.offItem = offItem
	return modules.util.asItemStack(offItem):toStackString() ~= modules.util.asItemStack(lastOffItem):toStackString()
end
events.helmet = events:new(events.TICK)
events.helmet.condition = function()
	local lastHelmet = previous.helmet

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

	return modules.util.asItemStack(newHelmet):toStackString() ~= modules.util.asItemStack(lastHelmet):toStackString()
end
events.chestplate = events:new(events.TICK)
events.chestplate.condition = function()
	local lastChestplate = previous.chestplate

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
	previous.elytra = newChestplate.id == "minecraft:elytra"
	previous.elytraGlint = modules.util.asItemStack(newChestplate):hasGlint()
	previous.chestplate = newChestplate

	return modules.util.asItemStack(newChestplate):toStackString() ~= modules.util.asItemStack(lastChestplate):toStackString()
end
events.leggings = events:new(events.TICK)
events.leggings.condition = function()
	local lastLeggings = previous.leggings

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

	return modules.util.asItemStack(newLeggings):toStackString() ~= modules.util.asItemStack(lastLeggings):toStackString()
end
events.boots = events:new(events.TICK)
events.boots.condition = function()
	local lastBoots = previous.boots

	-- Fetch new boots, prioritizing vanity slot
	local newBoots
	if settings.armor.vanitySlots then
		local vanityBoots = modules.util.getNbtValue("cardinal_components.trinkets:trinkets.boots.vanity")
		if vanityBoots ~= nil then
			newBoots = vanityBoots.Items[1]
		end
	end
	if newBoots == nil or newBoots.id == "minecraft:air" then
		newBoots = player:getItem(3)
	end
	previous.boots = newBoots

	return modules.util.asItemStack(newBoots):toStackString() ~= modules.util.asItemStack(lastBoots):toStackString()
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
	local vehicle = player:getVehicle() ~=  nil
	previous.vehicle = vehicle
	return vehicle ~= lastVehicle
end

-- Effects event
events.effects = events:new(events.TICK)
events.effects.condition = function()
	local lastEffects = previous.effects
	local effects = player:getStatusEffects()
	previous.effects = effects
	return modules.util.statusEffectsString(effects) ~= modules.util.statusEffectsString(lastEffects)
end

-- Open air event
events.openSky = events:new(events.TICK)
events.openSky.condition = function()
	local lastOpenSky = previous.openSky
	local openSky = world.isOpenSky(modules.util.getEyePos())
	previous.openSky = openSky
end



return events
