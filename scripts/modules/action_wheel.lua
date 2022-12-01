-- Action wheel setup script

if not host:isHost() then
	return
end

local actionsPage = action_wheel:newPage("main")
action_wheel:setPage(actionsPage)

-- Function used to play a client-side click sound upon clicking a button
local playClickSound = function()
	sounds:playSound("minecraft:ui.button.click", player:getPos(), 0.0625, 1)
end
-- Generic emote method
local emoteMethod = function(emoteName, infinite)
	playClickSound()
	if modules.emotes.isEmoting() and modules.emotes.emote == emoteName then
		pings.stopEmote(true)
	elseif not previous.invisible then
		pings.setEmote(emoteName, infinite)
	end
end

-- Action 1: Love
local loveAction = actionsPage:newAction()
	:title("Love")
	:color(1, 0.5, 0.5)
	:hoverColor(250/255, 170/255, 171/255)
	:texture(textures["models.firstPerson.models.ui"], 15, 0, 8, 8, 2)
loveAction.leftClick = function() emoteMethod("love") end
loveAction.rightClick = function() emoteMethod("love", true) end

-- Action 2: Blush
local blushAction = actionsPage:newAction()
	:title("Blush")
	:color(0.8, 0.2, 0.2)
	:hoverColor(0.8, 0.3, 0.3)
	:texture(textures["models.firstPerson.models.ui"], 23, 0, 8, 8, 2)
blushAction.leftClick = function() emoteMethod("blush") end
blushAction.rightClick = function() emoteMethod("blush", true) end

-- Action 3: Rage
local rageAction = actionsPage:newAction()
	:title("Rage")
	:color(0.6, 0.1, 0.1)
	:hoverColor(0.7, 0.2, 0.1)
	:texture(textures["models.firstPerson.models.ui"], 61, 22, 8, 8, 2)
rageAction.leftClick = function() emoteMethod("rage") end
rageAction.rightClick = function() emoteMethod("rage", true) end

-- Action 4: Hug
if avatar:canEditVanillaModel() then
	local hugAction = actionsPage:newAction()
		:title("Hug")
		:color(226/255, 189/255, 110/255)
		:hoverColor(246/255, 229/255, 151/255)
		:texture(textures["models.firstPerson.models.ui"], 0, 17, 11, 13, 2)
	hugAction.leftClick = function()
		playClickSound()
		if modules.emotes.isEmoting() and modules.emotes.emote == "hug" then
			pings.stopEmote(true)
		elseif not previous.invisible and modules.emotes.canHug() then
			-- Cancel sit animation if applicable
			if modules.sit.isSitting then
				pings.sitPose(false)
			end
			pings.setEmote("hug")
		end
	end
end

-- Action 5: Sit and kick legs
if avatar:canEditVanillaModel() then
	local sitAction = actionsPage:newAction()
		:title("Sit")
		:color(87/255, 61/255, 142/255)
		:hoverColor(127/255, 101/255, 182/255)
		:texture(textures["models.firstPerson.models.ui"], 11, 15, 16, 15, 1.5)
	sitAction.leftClick = function()
		playClickSound()
		if modules.sit.isSitting then
			pings.sitPose(false)
		elseif not previous.invisible and modules.sit.canSit() then
			-- Cancel hug animation if applicable
			if modules.emotes.isEmoting() and modules.emotes.emote == "hug" then
				pings.stopEmote(true)
			end
			pings.sitPose(true)
		end
	end
end

-- Action 6: Camera
local cameraAction = actionsPage:newAction()
	:title("Camera")
	:color(32/255, 32/255, 32/255)
	:hoverColor(72/255, 72/255, 72/255)
	:texture(textures["models.firstPerson.models.ui"], 15, 8, 10, 6, 2)
cameraAction.leftClick = function()
	playClickSound()
	-- TODO
	modules.camera.toggleFreeze()
end

-- TODO: third person sleep animation whatever
