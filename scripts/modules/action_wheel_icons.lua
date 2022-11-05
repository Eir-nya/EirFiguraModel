local awi = {
	-- TODO: Set this to a field in settings so the user (me) can match with action wheel size
	scale = 1.0,
	distance = 41,

	-- Keys must be names of action wheel pages to customize
	config = {
		-- Table where keys are the indexes in the action wheel to put icons in and values are the model parts to move there
		main = {
			[1] = models.firstPerson.action_wheel.love,
			[2] = models.firstPerson.action_wheel.blush,
			[3] = models.firstPerson.action_wheel.hug,
			[4] = models.firstPerson.action_wheel.sit,
			[5] = models.firstPerson.action_wheel.camera,
		},
	},

	lastOpen = false,
}

function awi.init()
	models.firstPerson.action_wheel:setParentType("Gui")
	awi.onWheelHidden()
end
modules.events.ENTITY_INIT:register(awi.init)

function awi.onWheelShown()
	-- Move action wheel transform to center of screen
	local windowSize = client.getScaledWindowSize()
	models.firstPerson.action_wheel:setPos(vec(windowSize.x, windowSize.y, 0) / -2)

	local page = action_wheel:getCurrentPage()

	-- Find matching page in config table
	for key, icons in pairs(awi.config) do
		if key == page or action_wheel:getPage(key) == page then
			-- Page has been confirmed. Continue

			-- Show icons one by one
			for i, part in pairs(icons) do
				if page:getAction(i) ~= nil then
					part:setVisible(true)

					local angle = awi.getAngle(page, i)
					angle = angle + math.rad(90)
					part:setPos(vec(math.cos(angle), math.sin(angle), 0) * awi.distance * awi.scale)
				else
					part:setVisible(false)
				end
			end

			break
		end
	end
end

function awi.onWheelHidden()
	for _, part in ipairs(models.firstPerson.action_wheel:getChildren()) do
		part:setVisible(false)
	end
end

function awi.tick()
	local open = action_wheel:isEnabled()

	-- Action wheel just opened or closed
	if open ~= awi.lastOpen then
		if open then
			awi.onWheelShown()
		else
			awi.onWheelHidden()
		end
	end
	awi.lastOpen = open
end
modules.events.TICK:register(awi.tick)



-- Right slots: ceil(size / 2)
-- Left slots: floor(size / 2)
function awi.getSize(page)
	for i = 8, 1, -1 do
		if page:getAction(i) ~= nil then
			return i
		end
	end
	return 0
end

function awi.getAngle(page, index)
	local size = awi.getSize(page)
	local rightSlots = math.ceil(size / 2)

	if rightSlots == 1 and index == 1 then
		return math.rad(0)
	elseif index <= rightSlots then
		return math.rad((90 / rightSlots) + ((index - 1) * (180 / rightSlots)))
	else
		local leftSlots = math.floor(size / 2)
		return math.rad(180 + (90 / leftSlots) + ((index - rightSlots - 1) * (180 / leftSlots)))
	end
end

return awi
