-- Script that enables seeing the model's arms while holding an item in first person.
events.ENTITY_INIT:register(function()
	-- TODO
	-- models.cat.RightArm:addItem("item"):scale(0.625, 0.625, 0.625):pos(0.5, -7, -8):rot(270, -39.375, -90)
	-- models.cat.RightArm:addItem("item"):renderType("FIRST_PERSON_RIGHT_HAND"):item("stone_pickaxe")
end, "firstPersonItem.lua INIT - setup render tasks")
