return function(aw)
	local off_uv = { u = 32, v = 15, w = 4, h = 4, s = 3 }
	local on_uv = { u = 27, v = 14, w = 5, h = 5, s = 3 }
	local scroll_uv = { u = 69, v = 25, w = 9, h = 5, s = 3 }

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
					newAction.texture = off_uv
					newAction.toggleTexture = on_uv
					newAction.toggle = function(self, newValue, realAction)
						aw.playClickSound()
						pageTable[name] = newValue
					end
					newAction.color = vec(0, 1, 0)
					newAction.colorOff = vec(0.7, 0, 0)
					newAction.hoverColor = vec(0.25, 0.8, 0.25)
					newAction.hoverColorOff = vec(0.6, 0.25, 0.25)
				-- Number
				elseif type(value) == "number" then
					local originalTitle = pageTable.title or name
					local update = function(self, realAction)
						self.title = '[{"text":"' .. originalTitle .. '"},{"text":"\n  (' .. pageTable[name] .. ')","color":"gray"}' .. ']'
						if realAction then
							realAction:title(self.title)
						end
					end
					newAction.texture = scroll_uv
					newAction.scroll = function(self, scrollAmount, realAction)
						aw.playClickSound()
						pageTable[name] = pageTable[name] + (scrollAmount / 10)
						update(self, realAction)
					end
					newAction.color = vec(0.6, 0.6, 0.6)
					update(newAction)
				end
			end

			table.insert(aw.getPage("settings" .. suffix), newAction)
		end
	end

	createPage(settings, ".")
end
