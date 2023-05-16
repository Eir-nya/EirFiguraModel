-- Library that pings data every 20 seconds to keep other clients up-to-date with host-only data when joining or reloading this avatar.
local sync = {
	timer = 1,
	maxTimer = 20 * 20,
}

function sync.DoSync()
	pings.setArmorVisible(modules.armor.display)
	for slot, clothes in pairs(modules.clothes) do
		if type(clothes) == "table" then
			pings.setClothes(slot, modules.clothes.getClothes(slot))
		end
	end
	pings.setXP(previous.xp)
	pings.setEffects(previous.effects)
	pings.setFlying(previous.flying)
	pings.setAir(previous.airPercent)
	pings.setNearest(modules.eyes.nearest)
	modules.eyes.checkNightVision()
	modules.eyes.checkScaredEffects()
	if modules.sit.isSitting then
		pings.startSitting(modules.sit.anim.anim:getName())
	end
end

if host:isHost() then
	modules.events.TICK:register(function()
		sync.timer = sync.timer - 1
		if sync.timer == 0 then
			sync.timer = sync.maxTimer
			sync.DoSync()
		end
	end)
end

return sync
