return function(aw)
	local off_uv = { u = 32, v = 15, w = 4, h = 4, s = 3 }
	local on_uv = { u = 27, v = 14, w = 5, h = 5, s = 3 }
	local scroll_uv = { u = 69, v = 25, w = 9, h = 5, s = 3 }

	local createPage
	createPage = function(pageTable, suffix)
		local itemsCount = 0
		for name, value in pairs(pageTable) do
			local newAction = {
				title = name
			}

			local path = "settings" .. suffix .. name

			-- New page
			if type(value) == "table" then
				newAction.texture = { u = 69, v = 8, w = 10, h = 10, s = 2 }
				newAction.leftClick = function(self) aw.playClickSound() aw.setPage(path) end
				newAction.color = vectors.hsvToRGB((itemsCount / 7) % 1, 0.4, 0.6)
				newAction.hoverColor = vectors.hsvToRGB((itemsCount / 7) % 1, 0.6, 1)
				aw.getPage("settings" .. suffix)[name] = {
					title = name
				}
				createPage(value, suffix .. name .. ".")
			-- Just action
			else
				local originalTitle = pageTable.title or name

				-- Bool
				if type(value) == "boolean" then
					local update = function(self, realAction)
						self.title = '[{"text":"' .. (pageTable[name] and "+" or "*") .. ' ","font":"figura:ui"},{"text":"' .. originalTitle .. '","font":"default"}]'
						if realAction then
							realAction:title(self.title)
						end
					end

					newAction.isToggled = value
					newAction.texture = off_uv
					newAction.toggleTexture = on_uv
					newAction.toggle = function(self, newValue, realAction)
						aw.playClickSound()
						pageTable[name] = newValue
						update(self, realAction)
						pings.settingSync(path, newValue)
					end
					newAction.color = vec(0, 1, 0)
					newAction.colorOff = vec(0.7, 0, 0)
					newAction.hoverColor = vec(0.25, 0.8, 0.25)
					newAction.hoverColorOff = vec(0.6, 0.25, 0.25)
					update(newAction)
				-- Number
				elseif type(value) == "number" then
					local update = function(self, realAction)
						self.title = '[{"text":"- ","font":"figura:ui"},{"text":"' .. originalTitle .. '","font":"default"},{"text":"\n  (' .. pageTable[name] .. ')","color":"gray","font":"default"}' .. ']'
						if realAction then
							realAction:title(self.title)
						end
					end

					newAction.texture = scroll_uv
					newAction.scroll = function(self, scrollAmount, realAction)
						aw.playClickSound()
						pageTable[name] = pageTable[name] + (scrollAmount / 10)
						update(self, realAction)
						pings.settingSync(path, pageTable[name])
					end
					newAction.color = vec(0.6, 0.6, 0.6)
					update(newAction)
				-- Unsupported
				else
					newAction = nil
				end
			end

			if newAction ~= nil then
				itemsCount = itemsCount + 1
				table.insert(aw.getPage("settings" .. suffix), newAction)
			end
		end
	end

	createPage(settings, ".")
end
