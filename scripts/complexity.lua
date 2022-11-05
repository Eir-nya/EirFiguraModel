-- Script controlling features of the model that can be enabled or disabled.
-- Also disables avatar features based on the maximum allowed complexity.

-- Complexity added by every model part
complexity = {
	-- FEATURES
	skull = 396,
	snoot = 20,
	skullSnoot = 20, -- only if skull is enabled
	earArmor = 72, -- (140 (ear armor) - 104 (ears)) per ear
	chestArmor = 64, -- 16 (torso) + 24 per arm
	legArmor = 60, -- 20 (torso) + 20 per leg
	elytra = 24, -- 12 per wing

	-- EYES
	eyesBack = 4,
	eyes = 8, -- 4 per eye
	eyesGlow = 8, -- 4 per eye

	-- BASE
	head = 376, -- 24 (head) + 20 (hat layer) + 124 (bow) + 104 per ear
	bodyBase = 40, -- 24 (body) + 16 (body layer)
	bodyAdornments = 284, -- 16 (boobs) + 16 (boobs layer) + 252 (tail)
	rightArm = 64, -- 24 (arm) + 20 (fur) + 20 (beans)
	leftArm = 64, -- 24 (arm) + 20 (fur) + 20 (beans)
	rightLeg = 24,
	leftLeg = 24
}

-- Automatically disable features to fit complexity limit
do
	local complexityLimit = avatar:getMaxComplexity()
	local totalComplexity = complexity.head + complexity.bodyAdornments
	-- If vanilla model parts can not be modified, these parts will not be used, so they shouldn't be counted
	if avatar:canEditVanillaModel() then
		totalComplexity = totalComplexity + complexity.bodyBase
		totalComplexity = totalComplexity + complexity.rightArm + complexity.leftArm + complexity.rightLeg + complexity.leftLeg
	end

	totalComplexity = totalComplexity + (settings.skull and complexity.skull or 0)
	totalComplexity = totalComplexity + (settings.snoot and (settings.skull and complexity.skullSnoot + complexity.snoot or complexity.snoot) or 0)
	totalComplexity = totalComplexity + (settings.earArmor and complexity.earArmor or 0)
	totalComplexity = totalComplexity + (settings.customChest and complexity.chestArmor or 0)
	totalComplexity = totalComplexity + (settings.customLegs and complexity.legArmor or 0)
	totalComplexity = totalComplexity + (settings.elytraFix and complexity.elytra or 0)
	if settings.eyes.dynamic.enabled or settings.eyes.glow.enabled then			
		totalComplexity = totalComplexity + complexity.eyesBack
		totalComplexity = totalComplexity + (settings.eyes.dynamic.enabled and complexity.eyes or 0)
		totalComplexity = totalComplexity + (settings.eyes.glow.enabled and complexity.eyesGlow or 0)
	end

	-- Disable features in order of least to most important
	while totalComplexity > complexityLimit do
		-- Skull
		if settings.model.skull then
			settings.model.skull = false
			totalComplexity = totalComplexity - complexity.skull
			if settings.model.snoot then
				totalComplexity = totalComplexity - complexity.skullSnoot
			end
		-- Eyes
		elseif settings.eyes.dynamic.enabled then
			settings.eyes.dynamic.enabled = false
			totalComplexity = totalComplexity - complexity.eyes
			if not settings.eyes.glow.enabled then
				totalComplexity = totalComplexity - complexity.eyesBack
			end
		-- Eyes glint
		elseif settings.eyes.glow.enabled then
			settings.eyes.glow.enabled = false
			totalComplexity = totalComplexity - complexity.eyesGlow
			if not settings.eyes.dynamic.enabled then
				totalComplexity = totalComplexity - complexity.eyesBack
			end
		-- Ear armor
		elseif settings.customArmor.earArmor then
			settings.customArmor.earArmor = false
			totalComplexity = totalComplexity - complexity.earArmor
		-- Snoot
		elseif settings.model.snoot then
			settings.model.snoot = false
			totalComplexity = totalComplexity - complexity.snoot
		-- Chest armor
		elseif settings.customArmor.chest then
			settings.customArmor.chest = false
			totalComplexity = totalComplexity - complexity.chestArmor
		-- Leg armor
		elseif settings.customArmor.legs then
			settings.customArmor.legs = false
			totalComplexity = totalComplexity - complexity.legArmor
		-- Elytra fix
		elseif settings.model.elytra then
			settings.model.elytra = false
			totalComplexity = totalComplexity - complexity.elytra
		else
			break
		end
	end
end
