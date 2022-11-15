-- Wavey hair module. Uses rope physics module.
local hair = {
	-- Rope physics
	ropes = {
		Left = {
			gravity = 0.09,
			friction = 0.175,
			facingDir = 24, -- TODO: 45 or -45?
			partInfluence = 1/10,
			xzVelInfluence = 10,
			yVelInfluence = 1.6
		},
		Right = {
			gravity = 0.12,
			friction = 0.225,
			facingDir = -17,
			partInfluence = 1/10,
			xzVelInfluence = 10,
			yVelInfluence = 1.3
		},
		Back1 = {
			gravity = 0.2,
			friction = 0.3,
			facingDir = 164,
			partInfluence = 1/9,
			xzVelInfluence = 18,
			yVelInfluence = 4
		},
		Back2 = {
			gravity = 0.2,
			friction = 0.3,
			facingDir = -10,
			partInfluence = 1/9,
			xzVelInfluence = 18,
			yVelInfluence = 5
		},
		Back3 = {
			gravity = 0.2,
			friction = 0.3,
			facingDir = -20,
			partInfluence = 1/9,
			xzVelInfluence = 18,
			yVelInfluence = 5
		},
	},
}

-- Sets up hair rope physics objects
function hair.init()
	for name, properties in pairs(hair.ropes) do
		local rope = modules.rope:new(models.cat.Head.Hair[name])
		for property, value in pairs(properties) do
			rope[property] = value
		end
		if properties.friction ~= nil then
			rope:setFriction(properties.friction)
		end
		hair.ropes[name] = rope
	end
end
modules.events.ENTITY_INIT:register(hair.init)

-- Runs on helmet equip/unequip. Decides which pieces of hair should be visible.
function hair.helmetEvent()
	-- Only visible items count
	if modules.armor.checkItemVisible(previous.helmet) then
		-- Custom helmets: varies
		if modules.armor.useCustomModel(previous.helmet) then
			-- Leather helmet: hide all rope physics hair
			if previous.helmet.id == "minecraft:leather_helmet" then
				hair.ropes.Left:setVisible(false)
				hair.ropes.Right:setVisible(false)
				hair.ropes.Back1:setVisible(false)
				hair.ropes.Back2:setVisible(false)
				hair.ropes.Back3:setVisible(false)

				-- 3DHair: Hide all except North
				modules.util.setChildrenVisible(models.cat.Head["3DHair"], false)
				models.cat.Head["3DHair"].north:setVisible(true)

				-- TODO: hide hat layer but only if it's being used instead of 3d hair

				-- TODO: set limits on Left and Right
			end
			-- TODO
		-- Default helmet model: disable Left and Back2
		elseif modules.armor.knownMaterial(modules.armor.getItemMaterial(previous.helmet)) then
			hair.ropes.Back2:setVisible(false)
		-- Generic block or item: disable all
		else
			hair.ropes.Left:setVisible(false)
			hair.ropes.Right:setVisible(false)
			hair.ropes.Back1:setVisible(false)
			hair.ropes.Back2:setVisible(false)
			hair.ropes.Back3:setVisible(false)

			modules.util.setChildrenVisible(models.cat.Head["3DHair"], false)
		end
	-- Restore all
	else
		hair.ropes.Left:setVisible(true)
		hair.ropes.Right:setVisible(true)
		hair.ropes.Back1:setVisible(true)
		hair.ropes.Back2:setVisible(true)
		hair.ropes.Back3:setVisible(true)

		modules.util.setChildrenVisible(models.cat.Head["3DHair"], true)
	end
end
modules.events.helmet:register(hair.helmetEvent)

return hair
