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

local simpleEvent = function(name, figuraEvent, previousVarName, newValueGetter)
	events[name] = events:new(figuraEvent)
	events[name].condition = function()
		local lastVar = previous[previousVarName]
		local newVar = newValueGetter()
		previous[previousVarName] = newVar
		return newVar ~= lastVar
	end
end

-- Stat events
simpleEvent("health", events.TICK, "healthPercent", function() return player:getHealth() / player:getMaxHealth() end)
simpleEvent("food", events.TICK, "food", function() return player:getFood() end)

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
			return (hurtTicks > lastHurtTicks) or (hurtTicks < lastHurtTicks and hurtTicks == 0)
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
if host:isHost() then
	simpleEvent("firstPerson", events.RENDER, "firstPerson", function() return renderer:isFirstPerson() end)
end

-- Player movement data
events.TICK:register(function()
	local newVel = player:getVelocity()
	previous.vel = newVel
	previous.velMagXZ = newVel.x_z:length()
	previous.lookDir = player:getLookDir()
end)

-- Equipped item events
simpleEvent("mainItem", events.TICK, "mainItemString", function()
	local newItem = player:getItem(1)
	previous.mainItem = newItem
	return modules.util.asItemStack(newItem):toStackString()
end)
simpleEvent("offItem", events.TICK, "offItemString", function()
	local newItem = player:getItem(2)
	previous.offItem = newItem
	return modules.util.asItemStack(newItem):toStackString()
end)
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
simpleEvent("invisible", events.TICK, "invisible", function() return player:isInvisible() end)

-- Wet/fire events
simpleEvent("wet", events.TICK, "wet", function() return player:isWet() end)
simpleEvent("underwater", events.TICK, "underwater", function() return player:isUnderwater() end)
simpleEvent("fire", events.TICK, "fire", function() return player:isOnFire() end)

-- Pose event
simpleEvent("pose", events.TICK, "pose", function() return player:getPose() end)

-- Vehicle event
simpleEvent("vehicle", events.TICK, "vehicle", function() return player:getVehicle() ~= nil end)


-- Host only events

-- XP event
events.xp = events:new()
function pings.setXP(newXP)
	previous.xp = newXP
	events.xp:run()
end

if host:isHost() then
	events.TICK:register(function()
		local lastXP = previous.xp
		local xp = player:getExperienceLevel() + player:getExperienceProgress()
		previous.xp = xp
		if xp ~= lastXP then
			pings.setXP(previous.xp)
		end
	end)
end

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
events.air = events:new()
-- Air event
function pings.setAir(newAir)
	previous.airPercent = newAir
	events.air:run()
end
if host:isHost() then
	events.air.condition = function()
		local lastAirPercent = previous.airPercent
		local airPercent = host:getAir() / player:getMaxAir()
		previous.airPercent = airPercent
		if airPercent ~= lastAirPercent then
			pings.setAir(previous.airPercent)
		end
	end
end



return events
