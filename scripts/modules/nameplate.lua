local name = {
	originalColor = avatar:getColor(),
	nameSearch = nil,
	colorDelay = 0,
}

-- Changes the wearer's nameplate to a custom value, if possible
function name.init()
	if avatar:canEditNameplate() then
		if settings.misc.useCustomName then
			nameplate.ENTITY:setText(settings.misc.customNameEntity)
			nameplate.CHAT:setText(settings.misc.customNameChat)
			nameplate.LIST:setText(settings.misc.customNameChat)
		end
		nameplate.ENTITY:setLight(15)
		nameplate.ENTITY:setShadow(true)
	end
end
modules.events.ENTITY_INIT:register(name.init)

-- Makes avatar color change to rainbow colors over time
function name.rainbowColor()
	if name.colorDelay > 0 then
		name.colorDelay = name.colorDelay - 1
	else
		avatar:setColor(modules.util.rainbow(1))
	end
end
modules.events.TICK:register(name.rainbowColor)

if host:isHost() then
	-- Resets avatar color when receiving a chat message that mentions player
	function name.chatReceive(msg)
		if msg:find(name.nameSearch) then
			name.resetColor(1)
		end
	end
	modules.events.CHAT_RECEIVE_MESSAGE:register(name.chatReceive)

	-- Resets avatar color on death
	function name.onDeath()
		if player:getHealth() <= 0 then
			name.resetColor(1)
		end
	end
	modules.events.hurt:register(name.onDeath)
end

-- Makes the nameplate follow the model head
function name.renderNameplate(delta, context)
	if context ~= "RENDER" then
		return
	end

	local nameplatePos = modules.util.partToWorldPos(models.cat.Head.NAMEPLATE_PIVOT)
	nameplatePos = nameplatePos - player:getPos(delta)
	if previous.pose == "SWIMMING" or previous.pose == "FALL_FLYING" then
		nameplatePos = nameplatePos - vec(0, 0.75, 0)
	elseif previous.pose == "CROUCHING" then
		nameplatePos = nameplatePos - vec(0, 1.5, 0)
	else
		nameplatePos = nameplatePos - vec(0, 1.916, 0)
	end
	nameplate.ENTITY:setPos(nameplatePos)
end
modules.events.POST_RENDER:register(name.renderNameplate)


-- Parses settings.misc.customNameChat into a cohesive string to use string.find for
function name.parseCustomName()
	local jsonAsTable = world.newItem("minecraft:air{'name':" .. settings.misc.customNameChat .. "}").tag.name
	if type(jsonAsTable) == "string" then
		name.nameSearch = jsonAsTable
	elseif type(jsonAsTable == "table") then
		name.nameSearch = ""
		for i = 1, #jsonAsTable do
			name.nameSearch = name.nameSearch .. jsonAsTable[i].text
		end
	end
end
name.parseCustomName()

function name.resetColor(delay)
	avatar:setColor(vectors.hexToRGB(name.originalColor))
	name.colorDelay = delay
end

return name
