-- Action wheel setup script
local aw = {
	default = settings.actionWheel.defaultPage,

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
			leftClick = function() aw.playClickSound() aw.back() end,
		}
	},

	main = {
		title = "Main",
		noBack = true,
		{
			title = '{"text":"Emotes..."}',
			color = vectors.hexToRGB("faaaab"),
			hoverColor = vec(1, 0.5, 0.5),
			texture = { u = 0, v = 17, w = 11, h = 13, s = 2 },
			leftClick = function() aw.playClickSound() aw.setPage("emotes") end,
		},
		{
			title = '{"text":"Camera..."}',
			color = vectors.hexToRGB("c9a363"),
			hoverColor = vectors.hexToRGB("f4e295"),
			texture = { u = 15, v = 8, w = 10, h = 6, s = 2 },
			leftClick = function() aw.playClickSound() aw.setPage("camera") end,
		},
		{
			title = '{"text":"Settings..."}',
			color = vec(0.3, 0.3, 0.3),
			texture = { u = 69, v = 8, w = 10, h = 10, s = 2 },
			leftClick = function() aw.playClickSound() aw.setPage("settings") end,
		},
	},
	emotes = {
		title = "Emotes",
		{
			title = '{"text":"Love"}',
			disabledTitle = '[{"text":"* ","font":"figura:ui"},{"text":"Love","color":"gray","font":"default"}]',
			color = vec(1, 0.5, 0.5),
			hoverColor = vec(250 / 255, 170 / 255, 171 / 255),
			texture = { u = 15, v = 0, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "love") end,
			rightClick = function(self) aw.emoteMethod(self, "love", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("love") end,
		},
		{
			title = '{"text":"Blush"}',
			disabledTitle = '[{"text":"* ","font":"figura:ui"},{"text":"Blush","color":"gray","font":"default"}]',
			color = vec(0.8, 0.2, 0.2),
			hoverColor = vec(0.8, 0.3, 0.3),
			texture = { u = 23, v = 0, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "blush") end,
			rightClick = function(self) aw.emoteMethod(self, "blush", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("blush") end,
		},
		{
			title = '{"text":"Rage"}',
			disabledTitle = '[{"text":"* ","font":"figura:ui"},{"text":"Rage","color":"gray","font":"default"}]',
			color = vec(0.6, 0.1, 0.1),
			hoverColor = vec(0.7, 0.2, 0.1),
			texture = { u = 61, v = 22, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "rage") end,
			rightClick = function(self) aw.emoteMethod(self, "rage", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("rage") end,
		},
		{
			title = '{"text":"Hug"}',
			disabledTitle = '[{"text":"* ","font":"figura:ui"},{"text":"Hug","color":"gray","font":"default"}]',
			color = vec(226 / 255, 189 / 255, 110 / 255),
			hoverColor = vec(246 /255, 229 / 255, 151 / 255),
			texture = { u = 0, v = 17, w = 11, h = 13, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "hug") end,
			enabledFunc = function() return avatar:canEditVanillaModel() and aw.enableEmoteMethod("hug") and modules.emotes.canHug() and not modules.sit.isSitting end,
		},
		{
			title = '{"text":"Sit"}',
			disabledTitle = '[{"text":"* ","font":"figura:ui"},{"text":"Sit","color":"gray","font":"default"}]',
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
			disabledTitle = '[{"text":"* ","font":"figura:ui"},{"text":"Freeze Camera","color":"gray","font":"default"}]',
			color = vectors.hexToRGB("c9a363"),
			hoverColor = vectors.hexToRGB("f4e295"),
			texture = { u = 15, v = 8, w = 10, h = 6, s = 2 },
			leftClick = function(self)
				aw.playClickSound()
				-- TODO
				modules.camera.toggleFreeze()
			end,
			enabledFunc = function() return not renderer:isFirstPerson() end,
		}
	},
	settings = {
		title = "Settings",
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
aw.back = function()
	local pageName = action_wheel:getCurrentPage():getTitle()
	local dotFound, lastDot = pageName:find(".*%.")
	if dotFound then
		aw.setPage(pageName:sub(0, lastDot - 1))
	else
		aw.setPage("main")
	end
end
-- Page setting
aw.setPage = function(pageName)
	action_wheel:setPage(pageName)
	host:setActionbar(aw.getPage(pageName).title)
end
-- Retrieve page by name (with .)
aw.getPage = function(pageName)
	local found = aw.pages
	for key in pageName:gmatch("([^.]+)") do
		found = found[key]
	end
	return found
end

-- Icon texture
local iconTex = textures["models.firstPerson.models.ui"]
if not iconTex then
	iconTex = textures["textures.ui"]
end

-- Disabled color
local disabledColor = vec(0.2, 0.2, 0.2)



-- Automatically generate "Settings" page and content
local settingsGenerator = require("scripts/settings_serializer")
settingsGenerator(aw)

-- Create pages and actions
local createPage, createAction, isAction
createPage = function(pageName, pageTable)
	if type(pageTable) ~= "table" or isAction(pageTable) then
		return
	end

	local page = action_wheel:newPage(pageName)

	local actionList = {}
	local actions = 0
	for _, actionTable in pairs(pageTable) do
		-- Action: create action
		if isAction(actionTable) then
			if not pageTable.noBack then
				if actions % 8 == 7 then
					actions = actions + 1
					actionList[actions] = aw.pages.special.back
				end
			end

			actions = actions + 1
			actionList[actions] = actionTable
		-- Not action - just add if not already in table
		elseif not actionList[_] then
			actionList[_] = actionTable
		end
	end

	-- Add final "back" option, if possible
	if not pageTable.noBack then
		actions = actions + 1
		actionList[math.ceil(actions / 8) * 8] = aw.pages.special.back
	end

	-- Update pageTable to actionList - preserves indexes for runtime
	actionList.title = pageTable.title
	aw.pages[pageName] = actionList
	pageTable = actionList

	-- Create actions
	for i = 1, (math.ceil(actions / 8) * 8) do
		if actionList[i] then
			createAction(actionList[i], page, i)
		end
	end

	-- Store created page for runtime indexing
	aw.pages[page] = pageTable
end

createAction = function(actionTable, page, i)
	local action = page:newAction(i)
	action:title(actionTable.title)
	action:color(actionTable.color)
	action:hoverColor(actionTable.hoverColor)
	if actionTable.texture then
		action:texture(iconTex, actionTable.texture.u, actionTable.texture.v, actionTable.texture.w, actionTable.texture.h, actionTable.texture.s)
	end
	if actionTable.toggleTexture then
		action:toggleTexture(iconTex, actionTable.toggleTexture.u, actionTable.toggleTexture.v, actionTable.toggleTexture.w, actionTable.toggleTexture.h, actionTable.toggleTexture.s)
	end
	if actionTable.item then
		action:item(actionTable.item)
	end
	if actionTable.leftClick then
		action.leftClick = function(realAction) actionTable.leftClick(actionTable, realAction) end
	end
	if actionTable.rightClick then
		action.rightClick = function(realAction) actionTable.rightClick(actionTable, realAction) end
	end
	if actionTable.toggle then
		action:setToggled(action.isToggled)
		action.toggle = function(newValue, realAction)
			actionTable.toggle(actionTable, newValue, realAction)

			-- Set colors ("color" for on, "colorOff" for off)
			if actionTable.color and actionTable.colorOff then
				if newValue then
					action:color(actionTable.color)
				else
					action:color(actionTable.colorOff)
				end
			end
			-- Set hover colors ("hoverColor" for on, "hoverColorOff" for off)
			if actionTable.hoverColor and actionTable.hoverColorOff then
				if newValue then
					action:hoverColor(actionTable.hoverColor)
				else
					action:hoverColor(actionTable.hoverColorOff)
				end
			end
		end
		if action.color and action.colorOff and not action.isToggled then
			action:color(action.colorOff)
		end
	end
	if actionTable.scroll then
		action.scroll = function(scrollAmount, realAction) actionTable.scroll(actionTable, scrollAmount, realAction) end
	end

	actionTable.originalLeftClick = action.leftClick
	actionTable.originalRightClick = action.rightClick
end

isAction = function(t)
	if type(t) ~= "table" then
		return false
	end
	return t.color or t.texture or t.leftClick or t.toggle or t.scroll
end


-- Generate pages
local recurse
recurse = function(t, prefix)
	if type(t) == "table" then
		for pageName, pageTable in pairs(t) do
			if pageName ~= "special" and type(pageName) == "string" and not isAction(t) then
				createPage(prefix .. pageName, pageTable)
				recurse(pageTable, prefix .. pageName .. ".")
			end
		end
	end
end

-- Make a copy of the initial table, since it gets modified during action
local pagesTableCopy = {}
for k, v in pairs(aw.pages) do
	pagesTableCopy[k] = v
end
recurse(pagesTableCopy, "")

-- Watch action wheel
modules.events.TICK:register(function()
	if action_wheel:isEnabled() ~= aw.lastEnabled then
		aw.lastEnabled = action_wheel:isEnabled()

		-- Reset to default page, show action bar text
		if settings.actionWheel.openToDefault then
			aw.setPage(aw.default)
		end

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

-- TODO: third person sleep animation whatever
return aw
