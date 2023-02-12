local name = {
	originalColor = avatar:getColor(),
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
		if msg:find(player:getName()) then
			name.resetColor(0)
		end
	end
	modules.events.CHAT_RECEIVE_MESSAGE:register(name.chatReceive)

	-- Resets avatar color on death
	function name.onDeath()
		if player:getHealth() <= 0 then
			name.resetColor(0)
		end
	end
	modules.events.hurt:register(name.onDeath)
end

-- Makes the nameplate follow the model head
function name.renderNameplate(delta, context)
	if context ~= "RENDER" then
		return
	end

	local nameplatePivot = modules.util.partToWorldPos(models.cat.Head.NAMEPLATE_PIVOT)
	nameplatePivot = nameplatePivot - player:getPos(delta)
	nameplatePivot = nameplatePivot + vec(0, 0.375, 0)
	nameplate.ENTITY:setPivot(nameplatePivot)
end
modules.events.POST_RENDER:register(name.renderNameplate)

function name.resetColor(delay)
	avatar:setColor(vectors.hexToRGB(name.originalColor))
	name.colorDelay = delay
end

return name
