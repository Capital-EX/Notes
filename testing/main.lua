--[[
#	Text area todo
	Make Movement System    [83%]
	|:::Backspacing             [X]
	|:::Left Movement           [X]
	|:::Right Movement          [X]
	|:::Upward Movement         [X]
	|:::Downward Movement       [X]
	|:::Free-form Movement      [ ]
	
	Make Android Compatable [0%]
	|:::Make way to find touch in text [ ]
	|:::Make Cursor move with touch    [ ]
	|:::Make Cursor move to touch      [ ]
]]

require("./utf8")



function love.load()
	local roundToInt = function(n)
		return n > 0 and math.floor(n+0.5) or math.ceil(n-0.5)
	end

	textBox = {
		new = function(self, text, x, y, wrap, align, font) 
			local tb       = {}
			tb.x           = x or 0
			tb.y           = y or 0
			tb.plainText   = text or ""
			
			tb.font        = font or love.graphics.getFont()
			tb.fontHeight  = tb.font:getHeight()
			
			tb.wrap        =  wrap or tb.font:getWidth("m") * 5   --Defaults to 5 em of space
			tb.align       = align or "left"
			tb.padding     = {
				top    = 0,
				right  = 0,
				bottom = 0,
				left   = 0,
			}
			
			local _, wraps = tb.font:getWrap(tb.plainText,tb.wrap)
			
			tb.drawnText   = love.graphics.newText(tb.font)
			tb.drawnText:addf(tb.plainText, tb.wrap, tb.align,0,0)
			
			tb.trueIndex   = tb.plainText:len()                       --Where we are in the full string of plain text
			tb.wrapIndex   = #wraps == 0 and 0 or wraps[#wraps]:len() --Where we are in the current line of wrapped text
			tb.line        = 1
			--tb.trueLine    
			
			tb.cursorX         = tb.font:getWrap(tb.plainText, tb.wrap)
			tb.cursorY         = tb.fontHeight * math.max(tb.line,1)
			
			tb.showCursor      = true
			tb.blinkDelay      = 0.5
			tb.blinkTimer      = 0
			--tb.curline    = math.floor(tb:drawnText()tb.wrap)
			return setmetatable(tb,{__index = self.meta})
		end
		
	}
	textBox.meta = {}
	textBox.meta.editing = true
	
	textBox.meta.setText = function(self,text)
		self.drawnText:setf(text, self.wrap, self.align)
	end
	
	textBox.meta.isReleased = function(self,x,y)
		mx = x or love.mouse.getX()
		my = y or love.mouse.getY()
		if (mx > self.x and mx < self.x + self.width) and (my > self.y and my < self.y + self.height) then
			love.keyboard.setTextInput(true)
		end
	end
	
	textBox.meta.draw = function(self)
		love.graphics.draw(self.drawnText,self.x,self.y)
		if self.showCursor then
			self:drawCursor()
		end
	end
	
	textBox.meta.update = function(self, dt)
		self.blinkTimer = self.blinkTimer + dt
		if self.blinkTimer > self.blinkDelay then
			self.showCursor = not self.showCursor
			self.blinkTimer = 0
		end
	end
	
	textBox.meta.drawCursor = function(self)
		love.graphics.setLineStyle("rough")
		love.graphics.setLineWidth(2)
		--[[love.graphics.line(
			self.cursorX+self.x, 
			self.cursorY + self.y - self.fontHeight, 
			self.cursorX+self.x, 
			self.cursorY + self.y
		)]]
		love.graphics.points(
			self.cursorX+self.x, 
			self.cursorY + self.y
		)
		love.graphics.setLineStyle("rough")
	end
	
	textBox.meta.moveIndexLeft = function(self, isBS)
		if self.trueIndex - 1 < 0 then return end
			local _, textWrap = self.font:getWrap(self.plainText,self.wrap)
			local textBehind = string.utf8sub(self.plainText, 0, self.trueIndex - 1)
			local _, wrapBehind = self.font:getWrap(textBehind,self.wrap)
			self.trueIndex = self.trueIndex - 1
			if (self.wrapIndex - 1 < 0 and self.trueIndex) or (self.wrapIndex - 1 == 0 and isBS and self.trueIndex ~= 0) then
				self.line      = self.line - 1
				self.wrapIndex = (wrapBehind[self.line] or ""):len()
			else
				self.wrapIndex = self.wrapIndex - 1
			end
		self:updateCursor()
	end
	
	textBox.meta.moveIndexRight = function(self)
		
		if self.trueIndex + 1 > self.plainText:len() then return end
		
		local nextWrapIndex = self.wrapIndex + 1
		local nextIndex     = self.trueIndex + 1
		local plainText     = self.plainText
		local _, textWrap   = self.font:getWrap(self.plainText,self.wrap)
		local _, newLines   = self.plainText:gsub("\n","")
		local line          = textWrap[self.line] or ""
		local nextCharInLine = string.utf8sub(line, nextWrapIndex, nextWrapIndex)
		local nextCharInText = string.utf8sub(plainText, nextIndex, nextIndex)
		local nextNextCharInText = string.utf8sub(plainText, nextIndex + 1, nextIndex + 1)
		
		print(nextCharInText:gsub("\n","~"))
		if nextCharInLine == "" then
			if nextCharInText == "\n" then
				self.trueIndex = self.trueIndex + 1
				self.line      = self.line + 1
				self.wrapIndex = 0
			else
				self.trueIndex = self.trueIndex + 1
				self.line      = self.line + 1
				self.wrapIndex = 1
			end
		else
			print (self.wrapIndex + 1, line:len())
			if self.wrapIndex + 1 >= line:len() and self.line + 1 <= #textWrap and nextNextCharInText ~= "\n" then
				print 'if'
				self.trueIndex = self.trueIndex + 1
				self.line      = self.line + 1
				self.wrapIndex = 0
			else
				print 'else'
				self.trueIndex = self.trueIndex + 1
				self.wrapIndex = self.wrapIndex + 1
			end
		end
		self:updateCursor()
	end
	
	--[[
	textBox.meta.moveIndexHorizontal = function(self, dir, isDel)
		print("Hello: ", self.trueIndex,self.plainText:len())
		if self.trueIndex + dir <= self.plainText:len() and self.trueIndex + dir >= 0 then
			local _, textWrap = self.font:getWrap(self.plainText,self.wrap)
			local textBehind = string.utf8sub(self.plainText, 0, self.trueIndex - 1)
			local _, wrapBehind = self.font:getWrap(textBehind,self.wrap)
			if dir < 0 then --Left logic
				print(self.wrapIndex)
				self.trueIndex = self.trueIndex - 1
				print(self.wrapIndex + dir == 0 and isDel and self.trueIndex + dir ~= 0,self.trueIndex + dir )
				if (self.wrapIndex + dir < 0 and self.trueIndex) or (self.wrapIndex + dir == 0 and isDel and self.trueIndex ~= 0) then
					self.line      = self.line - 1
					self.wrapIndex = (wrapBehind[self.line] or ""):len()
				else
					self.wrapIndex = self.wrapIndex + dir
				end
				
			elseif dir > 0 then --Right logic
				
				local _, textWrap = self.font:getWrap(self.plainText,self.wrap)
				local currentLine = textWrap[self.line] or ""
				--Grade A variable naming
				local nextCharTA, nextCharTB         = string.utf8sub(self.plainText, self.trueIndex + 1, self.trueIndex + 1) ,string.utf8sub(self.plainText, self.trueIndex + 2, self.trueIndex + 2)
				local nextCharWA, nextCharWB         = string.utf8sub(currentLine, self.wrapIndex + 1, self.wrapIndex + 1), string.utf8sub(currentLine, self.wrapIndex + 2, self.wrapIndex + 2)
				
				--print(nextChars[1]:gsub('\n','~'):gsub(' ', '_'),nextChars[2]:gsub('\n','~'):gsub(' ', '_'))
				print(nextCharTA:gsub('\n','~'):gsub(' ', '_'), nextCharTB:gsub('\n','~'):gsub(' ', '_'), nextCharWA, nextCharWB)
				if nextCharTA == '\n' then
					self.wrapIndex = 0
					self.trueIndex = self.trueIndex + 1
					self.line      = self.line + 1					
				elseif nextCharTA ~= "" then
					if nextCharWB == "" and textWrap[self.line+1] and nextCharTB ~= "\n" then
						self.wrapIndex = 0
						self.trueIndex = self.trueIndex + 1
						self.line      = self.line + 1
					else
						self.wrapIndex = self.wrapIndex + 1
						self.trueIndex = self.trueIndex + 1
					end
				end
				
			end
		end
		self:updateCursor()
	end
	]]

	textBox.meta.moveIndexVertical  = function(self, dir)
		local _, textWrap = self.font:getWrap(self.plainText,self.wrap)
		local thisLine    = textWrap[self.line] or ""
		local nextLine    = textWrap[self.line + dir] or ""
		local wrapIndex   = self.wrapIndex
		local newIndex    = 0
		local moveTo      = roundToInt(nextLine:len()*self.cursorX/self.font:getWidth(nextLine))
		local textLength  = self.plainText:len()
		print(moveTo)
		if tostring(moveTo) ~= "nan"  then
			if dir < 0 and self.line > 1 then
				if moveTo > nextLine:len() then
					print'a'
					self.wrapIndex = nextLine:len()
					self.line = self.line - 1
				else
					print'b'
					self.wrapIndex = moveTo
					for i = self.line, 1, -1 do
						print'loop'
						if i == 1 then
							print((textWrap[i] or ""):sub(moveTo, -1))
							newIndex = newIndex + string.utf8sub((textWrap[i] or ""), moveTo, -1):len()
						else
							print((textWrap[i] or ""))
							newIndex = newIndex + (textWrap[i] or ""):len()
						end
						if self.plainText:sub(-(newIndex + 1), -(newIndex + 1)) == "\n" then
							newIndex = newIndex + 1
						end
					end
					if wrapIndex == 0 then
						newIndex = newIndex + 1
					end
					print(-newIndex)
					
					self.trueIndex = string.utf8sub(self.plainText,0,-newIndex):len()
					self.line = self.line - 1
				end
			elseif dir > 0 and self.line < #textWrap then
				if moveTo > nextLine:len() then
					self.wrapIndex = nextLine:len()
				else
					self.wrapIndex = moveTo
					for i = 1, self.line + 1 do
						print'loop'
						if i == self.line then
							print((textWrap[i] or ""):sub(0, moveTo))
							newIndex = newIndex + string.utf8sub((textWrap[i] or ""), 0, moveTo):len()
						else
							print((textWrap[i] or ""))
							newIndex = newIndex + (textWrap[i] or ""):len()
						end
						if self.plainText:sub((newIndex + 1), (newIndex + 1)) == "\n" then
							newIndex = newIndex + 1
						end
					end
					self.trueIndex = string.utf8sub(self.plainText,0,newIndex):len()
					self.line = self.line + 1
				end
			end
		end
		self:updateCursor()
	end
	
	textBox.meta.moveIndexDown = function(self)
		
		
		local plainText    = self.plainText
		local _, textWrap  = self.font:getWrap(plainText,self.wrap)
		local _, lineCount = plainText:gsub("\n","")
		lineCount          = #textWrap + math.min(lineCount - #textWrap, 0)
		
		if self.line > math.max(lineCount,1) then return end  --If we can move down, leave function
		
		local thisLine    = textWrap[self.line] or ""
		local nextLine    = textWrap[self.line + 1] or ""
		
		local nextLineLen = nextLine:len()
		
		local wrapIndex   = self.wrapIndex
		local newIndex    = 0
		
		local moveTo      = roundToInt(nextLineLen*self.cursorX/self.font:getWidth(nextLine))
		
		if tostring(moveTo) == "nan" then -- If moveTo is not a number then
			moveTo = 0                    -- Set moveTo to 0
		end
		
		if moveTo > nextLineLen then      -- If moveTo is past the line length
			moveTo = nextLineLen          -- set MoveTo equal to line length
		end
		
		local thisLineOffSet = string.utf8sub(thisLine, wrapIndex + 1, -1):len()                  --Find the off set within current line; ex: [(xx)|xxx] => offset of 2
		local nextLineOffSet = string.utf8sub(nextLine, 0, moveTo == "nan" and 1 or moveTo):len() --Find the off set within next line; ex: [xx|(xxx)] => offset of 3
		
		
		
		self.line = self.line + 1
		self.trueIndex = self.trueIndex + thisLineOffSet                                -- Move forward by how many chars are ahead of us
		if string.utf8sub(plainText, self.trueIndex + 1, self.trueIndex + 1) == "\n" then  -- If the next char is a new line =>
			self.trueIndex = self.trueIndex + 1                                         -- Move index for on more.
		end                                                                             --
		self.trueIndex = self.trueIndex + nextLineOffSet                                -- Move forward by how many characters are behind moveTo
		self.wrapIndex = moveTo                                                         -- Set wrapped Index to where we moved to
		
		self:updateCursor()
	end
	
	textBox.meta.moveIndexUp = function(self)
		
		if self.line == 1 then return end --If we can't move up leave function
		
		local plainText      = self.plainText
		local _, textWrap    = self.font:getWrap(plainText,self.wrap)
		local thisLine       = textWrap[self.line] or ""
		local nextLine       = textWrap[self.line - 1] or ""
		
		local nextLineLen    = nextLine:len()
		
		local wrapIndex      = self.wrapIndex
		local newIndex       = 0
		
		local moveTo         = roundToInt(nextLineLen*self.cursorX/self.font:getWidth(nextLine))
		
		if tostring(moveTo) == "nan" then  -- If moveTo is not a number then
			moveTo = 0                     -- Set moveTo to 0
		end
		
		if moveTo > nextLineLen then      -- If moveTo is past the line length
			moveTo = nextLineLen          -- set MoveTo equal to line length
		end
		
		
		local thisLineOffSet = string.utf8sub(thisLine, 0, wrapIndex):len()                             --Find the off set within current line; ex: [xx|(xxx)] => offset of 3
		local nextLineOffSet = string.utf8sub(nextLine, moveTo == "nan" and 1 or moveTo + 1, -1):len()  --Find the off set within next line; ex: [(xx)|xxx] => offset of 2
		
		
		
		self.line = self.line - 1
		self.trueIndex = self.trueIndex - thisLineOffSet                           -- Move backwards by how many chars are behind us.
		if string.utf8sub(plainText, self.trueIndex, self.trueIndex) == "\n" then  -- If the next char is a newline =>
			self.trueIndex =self.trueIndex - 1                                     -- Move back one more.
		end                                                                        -- 
		self.trueIndex = self.trueIndex - nextLineOffSet                           -- Move backwards by how many chars are in front of new location.
		self.wrapIndex = moveTo                                                    -- Set wrapped index to moveTo.
		
		self:updateCursor()
	end
	
	
	textBox.meta.addText  = function(self, text)
		local textBefore  = string.utf8sub(self.plainText, 0, self.trueIndex)
		local textAfter   = string.utf8sub(self.plainText, self.trueIndex+1, -1)
		
		self.plainText    = table.concat{textBefore, text, textAfter}
		local _, textWrap = self.font:getWrap(self.plainText, self.wrap)
		print(textWrap[self.line])
		self.trueIndex    = self.trueIndex + 1
		self.wrapIndex    = self.wrapIndex + 1
		
		if self.wrapIndex > textWrap[self.line]:len() then
			
			self.line      = self.line + 1
			self.wrapIndex = 1
			
		end
		self:setText(self.plainText,self.wrapIndex, self.align)
		self:updateCursor()
	end
	
	
	textBox.meta.updateCursor = function(self)
		local _, textWrap = self.font:getWrap(self.plainText, self.wrap)
		self.cursorX = self.font:getWidth(string.utf8sub(textWrap[self.line] or "", 0, self.wrapIndex))
		self.cursorY = self.line * self.fontHeight
	end
	
	textBox.meta.onTextInput = function(self, key, code)
		self:addText(key)
	end
	
	textBox.meta.onReturn = function(self, key)
		local textBefore = string.utf8sub(self.plainText, 1, self.trueIndex)                     --Get text before the current |Plain Text Index| position
		local textAfter  = string.utf8sub(self.plainText, self.trueIndex+1,self.plainText:len()) --Get text after the current |Plain Text Index| position
		self.plainText   = table.concat{textBefore,'\n',textAfter}                               --concatenate table of text, update the |Plain Text|
		self.line        = self.line + 1                                                         --Increament |Cursor's line| position
		self.trueIndex   = self.trueIndex + 1                                                    --Increament |Cursor Index| for |Plain Text| (to account for the '\n' character)
		self.wrapIndex   = 0                                                                     --Rest |Cursor's Wrapped Index| to 1 (to account for the '\n' character)		
		self:updateCursor()                                                                      --Update cursor position
		self:setText(self.plainText,self.wrap,self.align)                                        --Update display text
	end
	
	textBox.meta.onBackspace = function(self, key)
		local textBefore        = string.utf8sub(self.plainText, 0, self.trueIndex - 1)                    --Text before the index
		local textRem           = string.utf8sub(self.plainText, self.trueIndex, self.trueIndex)           --Text removed at index
		local textAfter         = string.utf8sub(self.plainText, self.trueIndex + 1, self.plainText:len()) --Text after the index
		self.plainText     = table.concat{textBefore,textAfter}                                            --Update the plainText string
		self:moveIndexLeft(true)                                                                           --Move cursor back one
		self:setText(self.plainText,self.wrap,self.align)                                                  --Update display text
	end
	
	textBox.meta.onLeft = function(self, key) 
		self:moveIndexLeft()            --Move cursor left
	end
	
	textBox.meta.onRight = function(self, key)
		self:moveIndexRight()
	end
	testerBox = textBox:new("", 100, 100)
end


function love.draw()
	testerBox:draw()
	str = "("..testerBox.trueIndex..", "..testerBox.wrapIndex..", "..testerBox.line..")"
	love.graphics.print(str,0,100)
end

function love.update(dt)
	testerBox:update(dt)
	local out = testerBox.plainText:gsub('\n','~'):gsub(' ', '_')
	local _, wrap = testerBox.font:getWrap(testerBox.plainText, testerBox.wrap)
	--[[
	print("____________________")
	print(testerBox.line,testerBox.wrapIndex)
	print((wrap[testerBox.line] or "-\\_(o_o)_/-"):gsub('\n','~'):gsub(' ', '_'))
	print(string.utf8sub(out, 0, testerBox.trueIndex).."|"..string.utf8sub(out,testerBox.trueIndex + 1, -1))
	--]]
end


function love.textinput(key, code)
	testerBox:onTextInput(key,code)	
end

function love.keypressed(key)
	
	if key == "return" then	
		testerBox:onReturn(key)
	end
	
	if key == "backspace" and testerBox.trueIndex > 0 then
		testerBox:onBackspace(key)
	end
	
	if key == "left" then 
		testerBox:onLeft(key)
	end
	
	if key == "right" then		
		
		testerBox:onRight(key)
		
	end
	
	if key == "up" then
		testerBox:moveIndexUp()
	end
	
	if key == "down" then
		testerBox:moveIndexDown()
	end
	
	testerBox.blinkTimer = 0
	testerBox.showCursor = true	
end

function love.mousereleased(x, y, button) 
	
end 

function love.mousepressed(x, y, button)  

end

function love.touchpressed(id, x, y, pressure)
	
end

function love.touchreleased(id, x, y, pressure)
	
end
