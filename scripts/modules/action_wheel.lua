-- Action wheel setup script

if not host:isHost() then
	return
end

local actionsPage = action_wheel:createPage("main")
action_wheel:setPage(actionsPage)

-- Function used to play a client-side click sound upon clicking a button
local playClickSound = function()
	sounds:playSound("minecraft:ui.button.click", player:getPos(), 0.0625, 1)
end

-- Action 1: Love
local loveAction = actionsPage:newAction():title("Love"):color(1, 0.5, 0.5):hoverColor(250/255, 170/255, 171/255)
loveAction.leftClick = function()
	playClickSound()
	if modules.emotes.isEmoting() and modules.emotes.emote == "love" then
		pings.stopEmote(true)
	elseif not previous.invisible then
		pings.setEmote("love")
	end
end

-- Action 2: Blush
local blushAction = actionsPage:newAction():title("Blush"):color(0.8, 0.1, 0.1):hoverColor(0.8, 0.2, 0.2)
blushAction.leftClick = function()
	playClickSound()
	if modules.emotes.isEmoting() and modules.emotes.emote == "blush" then
		pings.stopEmote(true)
	elseif not previous.invisible then
		pings.setEmote("blush")
	end
end

-- Action 3: Hug
if avatar:canEditVanillaModel() then
	local hugAction = actionsPage:newAction():title("Hug"):color(226/255, 189/255, 110/255):hoverColor(246/255, 229/255, 151/255)
	hugAction.leftClick = function()
		playClickSound()
		if modules.emotes.isEmoting() and modules.emotes.emote == "hug" then
			pings.stopEmote(true)
		elseif modules.emotes.canHug() then
			-- Cancel sit animation if applicable
			if modules.sit.isSitting then
				pings.sitPose(false)
			end
			pings.setEmote("hug")
		end
	end
end

-- Action 4: Sit and kick legs
if avatar:canEditVanillaModel() then
	local sitAction = actionsPage:newAction():title("Sit"):color(87/255, 61/255, 142/255):hoverColor(127/255, 101/255, 182/255)
	sitAction.leftClick = function()
		playClickSound()
		if modules.sit.isSitting then
			pings.sitPose(false)
		elseif modules.sit.canSit() then
			-- Cancel hug animation if applicable
			if modules.emotes.isEmoting() and modules.emotes.emote == "hug" then
				pings.stopEmote(true)
			end
			pings.sitPose(true)
		end
	end
end

-- Action 5: Camera
local cameraAction = actionsPage:newAction():title("Camera"):color(32/255, 32/255, 32/255):hoverColor(72/255, 72/255, 72/255)
cameraAction.leftClick = function()
	playClickSound()
	-- TODO
	modules.camera.toggleFreeze()
end

-- TODO: third person sleep animation whatever