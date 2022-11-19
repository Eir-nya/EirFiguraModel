-- Module for both wavey (rope physics) hair and 3d (modeled) hair.
local hair = {
	-- Rope physics
	ropes = {
		Left = {
			gravity = 0.1,
			friction = 0.175,
			facingDir = 180 - 32, -- TODO: + or -?
			partInfluence = 1 / 10,
			xzVelInfluence = 10,
			yVelInfluence = 3.2,
			limits = {
				{ xMin = 0, xMax = 45, zMin = -22.5, zMax = 22.5, },
				{ xMin = -8.4375, xMax = 11.25, zMax = 22.5, },
				{ xMin = -11.25, xMax = 11.25, zMax = 11.25, }
			},
		},
		Right = {
			gravity = 0.12,
			friction = 0.225,
			facingDir = 180 + 68,
			partInfluence = 1 / 10,
			xzVelInfluence = 10,
			yVelInfluence = 3.2,
			limits = {
				{ xMin = 1, zMin = -22.5 },
				{ xMin = 0, zMin = -11.25 },
			},
		},
		Back1 = {
			gravity = 0.1625,
			friction = 0.3,
			facingDir = 16 * 3,
			partInfluence = 1 / 9,
			xzVelInfluence = 18,
			yVelInfluence = 8,
			limits = {
				{ xMax = 0, xMin = -112.5, zMax = 11.25 },
				{ xMin = -22.5, xMax = 22.5, zMax = 0 },
				{ xMin = -11.25, xMax = 0 },
			},
		},
		Back2 = {
			gravity = 0.1625,
			friction = 0.3,
			facingDir = -10,
			partInfluence = 1 / 9,
			xzVelInfluence = 18,
			yVelInfluence = 10,
			limits = {
				{ xMax = 0, xMin = -112.5 },
				{ xMax = 0, xMin = -22.5 },
				{ xMin = -11.25 },
			},
		},
		Back3 = {
			gravity = 0.1625,
			friction = 0.3,
			facingDir = -45,
			partInfluence = 1 / 9,
			xzVelInfluence = 18,
			yVelInfluence = 10,
			limits = {
				{ xMax = 22.5, xMin = -112.5, zMin = -11.25 },
				{ xMax = 22.5, xMin = -22.5, zMin = 0, },
			},
		},
	},
}

-- Sets up hair rope physics objects
function hair.init()
	for name, properties in pairs(hair.ropes) do
		local rope = modules.rope:new(properties, models.cat.Head.Hair[name])
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
				-- Frilly: Hide
				models.cat.Head.Frilly:setVisible(false)

				-- TODO: hide hat layer but only if it's being used instead of 3d hair

				-- TODO: set limits on Left and Right wavey hair
			end
			-- TODO
		-- Default helmet model: disable Left and Back2, move down Frilly
		elseif modules.armor.knownMaterial(modules.armor.getItemMaterial(previous.helmet)) then
			hair.ropes.Back2:setVisible(false)
			models.cat.Head.Frilly:setPos(vec(0, -1.5, -1))
		-- Generic block or item: disable all
		else
			hair.ropes.Left:setVisible(false)
			hair.ropes.Right:setVisible(false)
			hair.ropes.Back1:setVisible(false)
			hair.ropes.Back2:setVisible(false)
			hair.ropes.Back3:setVisible(false)

			models.cat.Head.Frilly:setVisible(false)
			modules.util.setChildrenVisible(models.cat.Head["3DHair"], false)
		end
	-- Restore all
	else
		hair.ropes.Left:setVisible(true)
		hair.ropes.Right:setVisible(true)
		hair.ropes.Back1:setVisible(true)
		hair.ropes.Back2:setVisible(true)
		hair.ropes.Back3:setVisible(true)

		models.cat.Head.Frilly:setPos()
		models.cat.Head.Frilly:setVisible(true)
		modules.util.setChildrenVisible(models.cat.Head["3DHair"], true)
	end
end
modules.events.helmet:register(hair.helmetEvent)

return hair
