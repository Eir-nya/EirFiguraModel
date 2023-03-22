-- Action wheel setup script
local aw = {
	default = "emotes",

	lastEnabled = false,
}

if not host:isHost() then
	return
end

-- Actions and pages database
aw.pages = {
	special = {
		back = {
			title = '{"text":"Back"}',
			color = vec(0.3, 0.3, 0.3),
			texture = { u = 69, v = 18, w = 9, h = 7, s = 2 },
			leftClick = function() aw.back() end,
		}
	},

	main = {
		title = "Main",
		{
			title = '{"text":"Emotes..."}',
			texture = { u = 0, v = 17, w = 11, h = 13, s = 2 },
			leftClick = function() aw.setPage("emotes") end,
		},
		{
			title = '{"text":"Camera..."}',
			texture = { u = 15, v = 8, w = 10, h = 6, s = 2 },
			leftClick = function() aw.setPage("camera") end,
		},
		{
			title = '{"text":"Settings..."}',
			texture = { u = 69, v = 8, w = 10, h = 10, s = 2 },
			leftClick = function() aw.setPage("settings") end,
		},
	},
	emotes = {
		title = "Emotes",
		{
			title = '{"text":"Love"}',
			disabledTitle = '[{"text":"❌ ","font":"figura:badges"},{"text":"Love","color":"gray","font":"default"}]',
			color = vec(1, 0.5, 0.5),
			hoverColor = vec(250 / 255, 170 / 255, 171 / 255),
			texture = { u = 15, v = 0, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "love") end,
			rightClick = function(self) aw.emoteMethod(self, "love", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("love") end,
		},
		{
			title = '{"text":"Blush"}',
			disabledTitle = '[{"text":"❌ ","font":"figura:badges"},{"text":"Blush","color":"gray","font":"default"}]',
			color = vec(0.8, 0.2, 0.2),
			hoverColor = vec(0.8, 0.3, 0.3),
			texture = { u = 23, v = 0, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "blush") end,
			rightClick = function(self) aw.emoteMethod(self, "blush", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("blush") end,
		},
		{
			title = '{"text":"Rage"}',
			disabledTitle = '[{"text":"❌ ","font":"figura:badges"},{"text":"Rage","color":"gray","font":"default"}]',
			color = vec(0.6, 0.1, 0.1),
			hoverColor = vec(0.7, 0.2, 0.1),
			texture = { u = 61, v = 22, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "rage") end,
			rightClick = function(self) aw.emoteMethod(self, "rage", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("rage") end,
		},
		{
			title = '{"text":"Hug"}',
			disabledTitle = '[{"text":"❌ ","font":"figura:badges"},{"text":"Hug","color":"gray","font":"default"}]',
			color = vec(226 / 255, 189 / 255, 110 / 255),
			hoverColor = vec(246 /255, 229 / 255, 151 / 255),
			texture = { u = 0, v = 17, w = 11, h = 13, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "hug") end,
			enabledFunc = function() return avatar:canEditVanillaModel() and aw.enableEmoteMethod("hug") and modules.emotes.canHug() and not modules.sit.isSitting end,
		},
		{
			title = '{"text":"Sit"}',
			disabledTitle = '[{"text":"❌ ","font":"figura:badges"},{"text":"Sit","color":"gray","font":"default"}]',
			color = vec(87 / 255, 61 / 255, 142 / 255),
			hoverColor = vec(127 / 255, 101 / 255, 182 / 255),
			texture = { u = 11, v = 15, w = 16, h = 15, s = 1.5 },
			leftClick = function(self)
				aw.playClickSound()
				if modules.sit.isSitting then
					pings.stopSitting(false)
				elseif self.enabledFunc() then
					pings.startSitting(modules.sit.pickSitAnim())
				end
				aw.emoteMethod(self, "sit")
			end,
			enabledFunc = function() return avatar:canEditVanillaModel() and not previous.invisible and modules.sit.canSit() and not (modules.emotes.isEmoting() and modules.emotes.emote == "hug") end,
		},
	},
	camera = {
		title = "Camera",
		{
			title = '{"text":"Freeze Camera"}',
			disabledTitle = '[{"text":"❌ ","font":"figura:badges"},{"text":"Freeze Camera","color":"gray","font":"default"}]',
			color = vec(32 / 255, 32 / 255, 32 / 255),
			hoverColor = vec(72 / 255, 72 / 255, 72 / 255),
			texture = { u = 15, v = 8, w = 10, h = 6, s = 2 },
			leftClick = function(self)
				aw.playClickSound()
				-- TODO
				modules.camera.toggleFreeze()
			end,
			enabledFunc = function() return not renderer:isFirstPerson() end,
		}
	},
}

local actionsPage = action_wheel:newPage("main")
action_wheel:setPage(actionsPage)

-- Function used to play a client-side click sound upon clicking a button
aw.playClickSound = function()
	sounds:playSound("minecraft:ui.button.click", player:getPos(), 0.0625, 1)
end
-- Generic emote methods
aw.emoteMethod = function(self, emoteName, infinite)
	aw.playClickSound()
	if modules.emotes.isEmoting() and modules.emotes.emote == emoteName then
		pings.stopEmote(true)
	elseif self.enabledFunc and self.enabledFunc() or true then
		pings.setEmote(emoteName, infinite)
	end
end
aw.stopEmoteMethod = function() pings.stopEmote(true) end
aw.enableEmoteMethod = function(emote) return (not modules.emotes.isEmoting() or modules.emotes.emote == emote) and not previous.invisible end
-- "Back" method
aw.back = function() aw.setPage("main") end
-- Page setting
aw.setPage = function(pageName)
	action_wheel:setPage(pageName)
	host:setActionbar(aw.pages[pageName].title)
end

-- Icon texture
local iconTex = textures["models.firstPerson.models.ui"]
if not iconTex then
	iconTex = textures["textures.ui"]
end

-- Disabled color
local disabledColor = vec(0.2, 0.2, 0.2)

-- Create pages
for pageName, pageTable in pairs(aw.pages) do
	if pageName ~= "special" and type(pageName) == "string" then
		local page = action_wheel:newPage(pageName)

		local actionList = {}
		local actions = 0
		for _, actionTable in pairs(pageTable) do
			if type(actionTable) == "table" then
				if pageName ~= "main" then
					if actions % 8 == 7 then
						actions = actions + 1
						actionList[actions] = aw.pages.special.back
					end
				end

				actions = actions + 1
				actionList[actions] = actionTable
			end
		end

		-- Add final "back" option, if possible
		if pageName ~= "main" then
			if actions % 8 < 7 then
				actions = actions + 1
				actionList[actions] = aw.pages.special.back
			end
		end

		-- Update pageTable to actionList - preserves indexes for runtime
		actionList.title = pageTable.title
		aw.pages[pageName] = actionList
		pageTable = actionList

		-- Create page, actions
		for i = 1, #pageTable do
			local actionTable = actionList[i]
			local action = page:newAction(i)
			action:title(actionTable.title)
			action:color(actionTable.color)
			action:hoverColor(actionTable.hoverColor)
			if actionTable.texture then
				action:texture(iconTex, actionTable.texture.u, actionTable.texture.v, actionTable.texture.w, actionTable.texture.h, actionTable.texture.s)
			end
			if actionTable.leftClick then
				action.leftClick = function() actionTable.leftClick(actionTable) end
			end
			if actionTable.rightClick then
				action.rightClick = function() actionTable.rightClick(actionTable) end
			end

			actionTable.originalLeftClick = action.leftClick
			actionTable.originalRightClick = action.rightClick
		end

		-- Store created page for runtime indexing
		aw.pages[page] = pageTable
	end
end

-- Watch action wheel
modules.events.TICK:register(function()
	if action_wheel:isEnabled() ~= aw.lastEnabled then
		aw.lastEnabled = action_wheel:isEnabled()
		-- Reset to default page, show action bar text
		aw.setPage(aw.default)
		-- When action wheel closed, reset actionbar
		if not aw.lastEnabled then
			host:setActionbar("")
		end
	end

	-- Enable/disable actions
	if aw.lastEnabled then
		local page = action_wheel:getCurrentPage()
		-- TODO: only process visible actions?
		for i, action in pairs(page:getActions()) do
			local actionTable = aw.pages[page][i]

			if actionTable.enabledFunc then
				local shouldBeEnabled = actionTable.enabledFunc()
				if shouldBeEnabled then
					action:title(actionTable.title)
					action:color(actionTable.color)
					action:hoverColor(actionTable.hoverColor)
					action.leftClick = actionTable.originalLeftClick
					action.rightClick = actionTable.originalRightClick
				else
					action:title(actionTable.disabledTitle)
					action:color(disabledColor)
					action:hoverColor(disabledColor)
					action.leftClick = nil
					action.rightClick = nil
				end
			end
		end
	end
end)

-- Initial page
action_wheel:setPage(aw.default)

-- -- Action 6: Camera
-- local cameraAction = actionsPage:newAction()
-- 	:title("Camera")
-- 	:color(32/255, 32/255, 32/255)
-- 	:hoverColor(72/255, 72/255, 72/255)
-- 	:texture(iconTex, 15, 8, 10, 6, 2)
-- cameraAction.leftClick = function()
-- 	playClickSound()
-- 	-- TODO
-- 	modules.camera.toggleFreeze()
-- end

-- TODO: third person sleep animation whatever
return aw
