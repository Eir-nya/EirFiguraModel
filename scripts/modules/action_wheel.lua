-- Action wheel setup script
local aw = {
	default = settings.actionWheel.defaultPage,

	lastEnabled = false,

	-- Colors
	disabledColor = vec(0.2, 0.2, 0.2),
	toggleColorOn = vec(0, 1, 0),
	toggleColorOff = vec(0.7, 0, 0),
	toggleHoverColorOn = vec(0.25, 0.8, 0.25),
	toggleHoverColorOff = vec(0.6, 0.25, 0.25),

	disabled = '{"text":"* ","font":"figura:ui"},',
	pawL = ',{"text":"\n  <:furry:","color":"gray","font":"figura:ui"},',
	pawR = ',{"text":"\n  :furry:>","color":"gray","font":"figura:ui"},',
}

if not host:isHost() then
	return
end

-- Makes a "scrollable list" action
aw.scrollableListAction = function(baseTable, title, getListAndSelectedFunc, onScroll1, onScroll2)
	baseTable.onShow = function(self, realAction)
		self.title = '[' .. title .. ',{"text":"\n"},' .. aw.listDisplay(getListAndSelectedFunc()) .. ']'
		realAction:title(self.title)
	end
	baseTable.scroll = function(self, dir, realAction)
		local list, current = getListAndSelectedFunc()
		current = current - dir
		current = ((current - 1) % #list) + 1
		onScroll1(list[current])
		self:onShow(realAction)
		onScroll2(list[current])
	end
	return baseTable
end

-- Actions and pages database
aw.pages = {
	special = {
		back = {
			title = '{"text":"Back"}',
			color = vec(0.3, 0.3, 0.3),
			texture = { u = 15, v = 8, w = 9, h = 7, s = 2 },
			leftClick = function() aw.back() end,
		}
	},

	main = {
		title = '{"text":"Main","bold":"true","color":"yellow"}',
		noBack = true,
		{
			title = '{"text":"Emotes...","color":"yellow"}',
			color = vectors.hexToRGB("faaaab"),
			hoverColor = vec(1, 0.5, 0.5),
			texture = { u = 0, v = 17, w = 11, h = 13, s = 2 },
			leftClick = function() aw.setPage("emotes") end,
		},
		{
			title = '{"text":"Wardrobe...","color":"gold"}',
			color = vectors.hexToRGB("ccb79c"),
			hoverColor = vectors.hexToRGB("dfc7a7"),
			item = world.newItem("minecraft:armor_stand"),
			leftClick = function() aw.setPage("wardrobe") end,
		},
		{
			title = '{"text":"Freeze camera"}',
			disabledTitle = '[' .. aw.disabled .. '{"text":"Freeze Camera","color":"gray","font":"default"}]',
			isToggled = modules.camera.frozen,
			texture = { u = 39, v = 9, w = 10, h = 9, s = 2 },
			textureOff = { u = 39, v = 0, w = 10, h = 9, s = 2 },
			toggle = function(self, newValue, realAction)
				modules.camera.setFreeze(not modules.camera.frozen)
			end,
			enabledFunc = function() return not renderer:isFirstPerson() end,
		}
	},
	emotes = {
		title = '{"text":"Emotes","color":"yellow"}',
		{
			title = '[{"text":"Love","color":"#faaaab"}' .. aw.pawL .. '{"text":": 3 seconds","color":"gray"}' .. aw.pawR .. '{"text":": Infinite","color":"gray"}]',
			disabledTitle = '[' .. aw.disabled .. '{"text":"Love","color":"gray","font":"default"}]',
			color = vec(1, 0.5, 0.5),
			hoverColor = vec(250 / 255, 170 / 255, 171 / 255),
			texture = { u = 15, v = 0, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "love") end,
			rightClick = function(self) aw.emoteMethod(self, "love", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("love") end,
		},
		{
			title = '[{"text":"Blush","color":"#cc3333"}' .. aw.pawL .. '{"text":": 5 seconds","color":"gray"}' .. aw.pawR .. '{"text":": Infinite","color":"gray"}]',
			disabledTitle = '[' .. aw.disabled .. '{"text":"Blush","color":"gray","font":"default"}]',
			color = vec(0.8, 0.2, 0.2),
			hoverColor = vec(0.8, 0.3, 0.3),
			texture = { u = 23, v = 0, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "blush") end,
			rightClick = function(self) aw.emoteMethod(self, "blush", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("blush") end,
		},
		{
			title = '[{"text":"Rage","color":"#991919"}' .. aw.pawL .. '{"text":": 2.5 seconds","color":"gray"}' .. aw.pawR .. '{"text":": Infinite","color":"gray"}]',
			disabledTitle = '[' .. aw.disabled .. '{"text":"Rage","color":"gray","font":"default"}]',
			color = vec(0.6, 0.1, 0.1),
			hoverColor = vec(0.7, 0.2, 0.1),
			texture = { u = 31, v = 8, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "rage") end,
			rightClick = function(self) aw.emoteMethod(self, "rage", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("rage") end,
		},
		{
			title = '[{"text":"Sad","color":"blue"}' .. aw.pawL .. '{"text":": 7 seconds","color":"gray"}' .. aw.pawR .. '{"text":": Infinite","color":"gray"}]',
			disabledTitle = '[' .. aw.disabled .. '{"text":"Sad","color":"gray","font":"default"}]',
			color = vec(0.1, 0.1, 0.4),
			hoverColor = vec(0.3, 0.3, 0.5),
			texture = { u = 31, v = 0, w = 8, h = 8, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "sad") end,
			rightClick = function(self) aw.emoteMethod(self, "sad", true) end,
			enabledFunc = function() return aw.enableEmoteMethod("sad") end,
		},
		{
			title = '{"text":"Hug","color":"yellow"}',
			disabledTitle = '[' .. aw.disabled .. '{"text":"Hug","color":"gray","font":"default"}]',
			color = vec(226 / 255, 189 / 255, 110 / 255),
			hoverColor = vec(246 /255, 229 / 255, 151 / 255),
			texture = { u = 0, v = 17, w = 11, h = 13, s = 2 },
			leftClick = function(self) aw.emoteMethod(self, "hug") end,
			enabledFunc = function() return avatar:canEditVanillaModel() and aw.enableEmoteMethod("hug") and modules.emotes.canHug() and not modules.sit.isSitting end,
		},
		aw.scrollableListAction({
				disabledTitle = '[' .. aw.disabled .. '{"text":"Sit","color":"gray","font":"default"}]',
				color = vec(87 / 255, 61 / 255, 142 / 255),
				hoverColor = vec(127 / 255, 101 / 255, 182 / 255),
				texture = { u = 11, v = 15, w = 16, h = 15, s = 1.5 },
				leftClick = function(self)
					if modules.sit.isSitting then
						pings.stopSitting(false)
					elseif self.enabledFunc() then
						pings.startSitting(modules.sit.pickSitAnim())
					end
					aw.emoteMethod(self, "sit")
				end,
				enabledFunc = function() return avatar:canEditVanillaModel() and not previous.invisible and modules.sit.canSit() and not (modules.emotes.isEmoting() and modules.emotes.emote == "hug") end,
			},
			'{"text":"Sit","color":"#7f65b6"}',
			function() return modules.sit.anims, modules.sit.anims.current end,
			function(index) modules.sit.anims.current = modules.sit.anims[index] end,
			function() end
		),
	},
	wardrobe = {
		title = '{"text":"Wardrobe","color":"gold"}',
		aw.scrollableListAction({
				color = vectors.hexToRGB("aca06a"),
				hoverColor = vectors.hexToRGB("f6e597"),
				item = world.newItem("minecraft:leather_helmet"),
			},
			'{"text":"Head","color":"yellow"}',
			function() return modules.clothes.head, modules.clothes.get("head") end,
			function(new) modules.clothes.equip("head", new) end,
			function(new) pings.setClothes("head", new) end
		),
		aw.scrollableListAction({
				color = vectors.hexToRGB("faaaab"),
				hoverColor = vec(1, 0.5, 0.5),
				item = world.newItem("minecraft:leather_chestplate"),
			},
			'{"text":"Top","color":"yellow"}',
			function() return modules.clothes.top, modules.clothes.get("top") end,
			function(new) modules.clothes.equip("top", new) end,
			function(new) pings.setClothes("top", new) end
		),
		aw.scrollableListAction({
				color = vectors.hexToRGB("9382c3"),
				hoverColor = vectors.hexToRGB("ab98e3"),
				item = world.newItem("minecraft:leather_leggings"),
			},
			'{"text":"Bottom","color":"yellow"}',
			function() return modules.clothes.bottom, modules.clothes.get("bottom") end,
			function(new) modules.clothes.equip("bottom", new) end,
			function(new) pings.setClothes("bottom", new) end
		),
		aw.scrollableListAction({
				color = vectors.hexToRGB("5e4a64"),
				hoverColor = vectors.hexToRGB("8b6d93"),
				item = world.newItem("minecraft:leather_boots"),
			},
			'{"text":"Feet","color":"yellow"}',
			function() return modules.clothes.feet, modules.clothes.get("feet") end,
			function(new) modules.clothes.equip("feet", new) end,
			function(new) pings.setClothes("feet", new) end
		),
		{
			isToggled = modules.armor.display,
			item = world.newItem("minecraft:ender_pearl"),
			toggleItem = world.newItem("minecraft:ender_eye"),
			onShow = function(self, realAction)
				realAction:title('[{"text":"Armor visible","color":"green"},{"text":"\n  (' .. (modules.armor.display and "Yes" or "No").. ')","color":"gray"}]')
			end,
			toggle = function(self, newValue, realAction)
				modules.armor.setVisible(newValue)
				self:onShow(realAction)
				pings.setArmorVisible(newValue)
			end,
		},
		nil,
		nil,
		aw.scrollableListAction({
				color = vectors.hexToRGB("faaaab"),
				hoverColor = vec(1, 0.5, 0.5),
				texture = { u = 1, v = 22, w = 8, h = 6, s = 2.5 },
			},
			'{"text":"Bow","color":"#faaaab"}',
			function() return modules.clothes.bow, modules.clothes.get("bow") end,
			function(new) modules.clothes.equip("bow", new) end,
			function(new) pings.setClothes("bow", new) end
		),
		aw.scrollableListAction({
				color = vectors.hexToRGB("aca06a"),
				hoverColor = vectors.hexToRGB("f6e597"),
				texture = { u = 24, v = 8, w = 7, h = 6, s = 2.5 },
			},
			'{"text":"Mask","color":"#ffcede"}',
			function() return modules.clothes.mask, modules.clothes.get("mask") end,
			function(new) modules.clothes.equip("mask", new) end,
			function(new) pings.setClothes("mask", new) end
		),
		{
			isToggled = modules.clothes.nsfw,
			texture = { u = 27, v = 16, w = 6, h = 4, s = 2.5 },
			onShow = function(self, realAction)
				realAction:title('[{"text":"Armor visible","color":"green"},{"text":"\n  (' .. (modules.armor.display and "Yes" or "No").. ')","color":"gray"}]')
				realAction:title(modules.clothes.nsfw and ":owo:" or ":raised_eyebrow:")
			end,
			toggle = function(self, newValue, realAction)
				modules.clothes.nsfw = newValue
				self:onShow(realAction)
				pings.setNSFW(newValue)
			end,
		}
	}
}

local actionsPage = action_wheel:newPage("main")
action_wheel:setPage(actionsPage)

-- Enables or disables an action based on its enabledFunc
local updateAction = function(actionTable, action)
	if actionTable.enabledFunc then
		local shouldBeEnabled = actionTable.enabledFunc(actionTable)
		if shouldBeEnabled then
			action:title(actionTable.title)
			action:color(not actionTable.toggle and actionTable.color or (action:isToggled() and aw.toggleColorOn or aw.toggleColorOff))
			action:hoverColor(not actionTable.toggle and actionTable.hoverColor or (action:isToggled() and aw.toggleHoverColorOn or aw.toggleHoverColorOff))
			action.leftClick = actionTable.originalLeftClick
			action.rightClick = actionTable.originalRightClick
			action.toggle = actionTable.originalToggle
			action.scroll = actionTable.originalScroll
		else
			action:title(actionTable.disabledTitle)
			action:color(aw.disabledColor)
			action:hoverColor(aw.disabledColor)
			action.leftClick = nil
			action.rightClick = nil
			action.toggle = nil
			action.scroll = nil
		end
	end
end

-- Function used to play a client-side click sound upon clicking a button
aw.playClickSound = function(self, isRight)
	if self.clickSound then
		if isRight and self.rightClickSound then
			sounds:playSound(self.rightClickSound, player:getPos(), 0.75, 1)
		else
			sounds:playSound(self.clickSound, player:getPos(), 0.75, 1)
		end
	elseif settings.actionWheel.sounds then
		sounds:playSound("minecraft:ui.button.click", player:getPos(), 0.125, 1)
	end
end
aw.playToggleSound = function(self, on)
	if self.toggleSound and self.toggleSoundOff then
		sounds:playSound(on and self.toggleSound or self.toggleSoundOff, player:getPos(), 0.75, 1)
	elseif settings.actionWheel.sounds then
		sounds:playSound("minecraft:block.wooden_button.click_on", player:getPos(), 0.5, on and 1 or 0.8)
	end
end
aw.playScrollSound = function(self, dir)
	if self.scrollSound then
		sounds:playSound(self.scrollSound, player:getPos(), 0.75, dir == 1 and 1.5 or 0.75)
	elseif settings.actionWheel.sounds then
		sounds:playSound("minecraft:item.spyglass.use", player:getPos(), 0.5, dir == 1 and 1.5 or 0.75)
	end
end
-- Generic emote methods
aw.emoteMethod = function(self, emoteName, infinite)
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

	-- Run onShow
	local page = action_wheel:getCurrentPage()
	for i, action in pairs(page:getActions()) do
		local actionTable = aw.pages[page][i]

		if actionTable.onShow then
			actionTable.onShow(actionTable, action)
		end
		updateAction(actionTable, action)
	end
end
-- Retrieve page by name (with .)
aw.getPage = function(pageName)
	return modules.util.getByPath(pageName, aw.pages)
end

-- Icon texture
local iconTex = textures["firstPerson.ui"]
if not iconTex then
	iconTex = textures["textures.ui"]
end



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
	local t
	if actionTable.texture then
		t = actionTable.texture
		action:texture(iconTex, t.u, t.v, t.w, t.h, t.s)
	end
	if actionTable.toggleTexture then
		t = actionTable.toggleTexture
		action:toggleTexture(iconTex, t.u, t.v, t.w, t.h, t.s)
	end
	if actionTable.item then
		action:item(actionTable.item)
	end
	if actionTable.toggleItem then
		action:toggleItem(actionTable.toggleItem)
	end
	if actionTable.leftClick then
		action.leftClick = function(realAction) aw.playClickSound(actionTable, false) actionTable.leftClick(actionTable, realAction) end
	end
	if actionTable.rightClick then
		action.rightClick = function(realAction) aw.playClickSound(actionTable, true) actionTable.rightClick(actionTable, realAction) end
	end
	if actionTable.toggle then
		action:setToggled(actionTable.isToggled)
		action.toggle = function(newValue, realAction)
			aw.playToggleSound(actionTable, newValue)
			actionTable.toggle(actionTable, newValue, realAction)

			-- Set colors
			if newValue then
				action:color(aw.toggleColorOn)
				action:hoverColor(aw.toggleHoverColorOn)
			else
				action:color(aw.toggleColorOff)
				action:hoverColor(aw.toggleHoverColorOff)
			end
			-- Texture
			if actionTable.texture and actionTable.textureOff then
				if newValue then
					t = actionTable.texture
					action:texture(iconTex, t.u, t.v, t.w, t.h, t.s)
				else
					t = actionTable.textureOff
					action:texture(iconTex, t.u, t.v, t.w, t.h, t.s)
				end
			end
		end
		-- Started as false
		if not actionTable.isToggled then
			action:color(aw.toggleColorOff)
			action:hoverColor(aw.toggleHoverColorOff)
			if actionTable.textureOff then
				t = actionTable.textureOff
				action:texture(iconTex, t.u, t.v, t.w, t.h, t.s)
			end
		end
	end
	if actionTable.scroll then
		action.scroll = function(scrollAmount, realAction) aw.playScrollSound(actionTable, scrollAmount) actionTable.scroll(actionTable, scrollAmount, realAction) end
	end

	actionTable.originalLeftClick = action.leftClick
	actionTable.originalRightClick = action.rightClick
	actionTable.originalToggle = action.toggle
	actionTable.originalScroll = action.scroll
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

			updateAction(actionTable, action)
		end
	end
end)

-- Initial page
action_wheel:setPage(aw.default)


-- Utility
function aw.listDisplay(list, selected)
	local s = ""
	for i, value in ipairs(list) do
		if i > 1 then
			s = s .. ',{"text":"\n"},'
		end

		local isSelected = i == selected
		s = s .. '{"text":"  ' .. (isSelected and '"},{"text":"★","font":"figura:ui","color":"white"},{"text":"' or '-') .. ' ' .. tostring(value) .. '","color":"' .. (isSelected and 'white' or 'gray') .. '","font":"default"}'
	end
	return s
end


return aw
