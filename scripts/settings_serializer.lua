return function(aw)
	local createPage
	createPage = function(pageTable, suffix)
		for name, value in pairs(pageTable) do
			local newAction = {
				title = name
			}

			local path = "settings" .. suffix .. name

			-- New page
			if type(value) == "table" then
				newAction.texture = { u = 69, v = 8, w = 10, h = 10, s = 2 }
				newAction.leftClick = function(self) aw.playClickSound() aw.setPage(path) end
				aw.getPage("settings" .. suffix)[name] = {
					title = name
				}
				createPage(value, suffix .. name .. ".")
			-- Just action
			else
				-- Bool
				if type(value) == "boolean" then
					newAction.isToggled = value
					newAction.toggle = function(self, newValue) aw.playClickSound() pageTable[name] = newValue end
					newAction.color = vec(0, 1, 0)
					newAction.colorOff = vec(1, 0, 0)
					newAction.hoverColor = vec(0.25, 0.8, 0.25)
					newAction.hoverColorOff = vec(0.8, 0.25, 0.25)
				end
			end

			table.insert(aw.getPage("settings" .. suffix), newAction)
		end
	end

	createPage(settings, ".")
end
