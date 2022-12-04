models.cat:setOverlay(-1)
models.cat.Head.Eyes.rightDoodle:setVisible(true)
models.cat.Head.Eyes.rightDoodle:setOverlay(0, 15)
models.cat.Head.Eyes.leftDoodle:setVisible(true)
models.cat.Head.Eyes.leftDoodle:setOverlay(0, 15)

models.cat.Head.Eyes.rightDoodle:setUVPixels(vec(0, 0))
models.cat.Head.Eyes.leftDoodle:setUVPixels(vec(0, 0))

local t = 0
local x = 0
local y = 0
local amount = vec(58, 58)
local rate = 3

function events.TICK()
	t = t + 1
	if t % rate == 0 then
		x = (x + 1) % 6
		if x == 0 then
			y = (y + 1) % 2
		end

		models.cat.Head.Eyes.rightDoodle:setUVPixels(amount * vec(x, y))
		models.cat.Head.Eyes.leftDoodle:setUVPixels(amount * vec(5 - x, 1 - y))
	end

	local pos = player:getPos() + vec((math.random() * 2) - 1, (math.random() * 3) + 1/3, (math.random() * 2) - 1)
	local dir = pos - (player:getPos() + vec(0, 1, 0))
	particles.smoke:spawn()
		:pos(pos)
		:velocity(dir / 10)
end

function events.RENDER()
	-- models.cat.Head.Eyes.rightDoodle:setPos(models.cat.Head.Eyes.right:getPos())
	-- models.cat.Head.Eyes.leftDoodle:setPos(models.cat.Head.Eyes.left:getPos())
end
