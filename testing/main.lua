--[[
#	Text area todo
	Make Movement System    [33%]
	|:::Backspacing             [X]
	|:::Left Movement           [X]
	|:::Right Movement          [ ]
	|:::Upward Movement         [ ]
	|:::Downward Movement       [ ]
	|:::Free-form Movement      [ ]
	
	Make Android Compatable [0%]
	|:::Make way to find touch in text [ ]
	|:::Make Cursor move with touch    [ ]
	|:::Make Cursor move to touch      [ ]
]]

require("./utf8")



function love.load()
	
	textBox = {
		new = function(self, text, x, y, wrap, align, font) 
			local tb       = {}
			tb.x           = x or 0
			tb.y           = y or 0
			tb.plainText   = text or ""
			
			tb.font        = font or love.graphics.getFont()
			tb.fontHeight  = tb.font:getHeight()
			
			tb.wrap        =  wrap or tb.font:getWidth("m") * 10          --Defaults to 10 em of space
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
			
			tb.trueIndex = tb.plainText:len()                       --Where we are in the full string of plain text
			tb.wrapIndex = #wraps == 0 and 0 or wraps[#wraps]:len() --Where we are in the current line of wrapped text
			tb.line      = 1                                        --Current of wrapped text
			
			tb.cursorX         = tb.font:getWrap(tb.plainText, tb.wrap)
			tb.cursorY         = tb.fontHeight * math.max(tb.line,1)
			
			tb.showCursor      = true
			tb.blinkDelay      = 0.5
			tb.blinkTimer      = 0
			--tb.curline    = math.floor(tb:drawnText()tb.wrap)
			return setmetatable(tb,{__index = self.meta})
		end
		
	}
	textBox.meta ={}
	textBox.meta.editing = false
	
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
	
	textBox.meta.moveIndexHorizontal = function(self, dir, key)
		local _, textWrap = self.font:getWrap(self.plainText,self.wrap)
		
		
		print("Hello: ", self.trueIndex,self.plainText:len())
		if self.trueIndex + dir <= self.plainText:len() and self.trueIndex + dir >= 0 then
			if dir < 0 then --Left logic
				
				if self.wrapIndex + dir < 0 then
					
					self.line      = self.line - 1
					local chars   = (textWrap[self.line] or ""):len()
					self.wrapIndex = chars - 1
					self.trueIndex = self.trueIndex - 1
					
				else
					
					self.wrapIndex = self.wrapIndex - 1
					self.trueIndex = self.trueIndex - 1
					
				end
				
			elseif dir > 0 then --Right logic
				
				if self.wrapIndex + dir > (textWrap[self.line] or ""):len() then
					
					self.wrapIndex = key and 1 or 0
					self.trueIndex = self.trueIndex + 1
					self.line      = self.line + 1
					
				else
					if self.wrapIndex == (textWrap[self.line] or ""):len() then
						
					end
					self.wrapIndex = self.wrapIndex + 1
					self.trueIndex = self.trueIndex + 1
					
				end
				
			end
		end
		self:updateCursor()
	end
	
	textBox.meta.moveVerticalIndex = function(self, dir)
		local _, textWrap = self.font:getWrap(self.plainText,self.wrap)
		
		--if self.wrapIndex
		
		
	end
	
	textBox.meta.updateCursor = function(self)
		local _, textWrap = self.font:getWrap(self.plainText, self.wrap)
		self.cursorX = self.font:getWidth(string.utf8sub( textWrap[self.line] or "", 0, self.wrapIndex))
		self.cursorY = self.line * self.fontHeight
	end
	
	textBox.meta.onTextInput = function(self, key, code)
		local textBefore  = string.utf8sub(self.plainText, 0, self.trueIndex)
		local textAfter   = string.utf8sub(self.plainText, self.trueIndex+1, -1)
		self.plainText     = table.concat{textBefore, key, textAfter}
		print(self.plainText:len())
		self:moveIndexHorizontal(1, key)
		self:setText(self.plainText,self.wrap,self.align)
		--[[
		local textBefore      = string.utf8sub(self.plainText, 1, self.cursorIndex)                      --Get the text behind the index
		local textAfter       = string.utf8sub(self.plainText, self.cursorIndex+1, self.plainText:len()) --Get the text after the index
		local _, textWrapBefore = self.font:getWrap(textBefore..key,self.wrap)                           --Get the wrapping of the text behind the index
		self.plainText   = table.concat{textBefore,key,textAfter}                                        --Put the new string together; Update |Plain Text|
		self.cursorIndex = self.cursorIndex + 1                                                          --Increment the |Cursor Index|
		self.cursorX     = self.font:getWidth(textWrapBefore[#textWrapBefore])                           --Set the |Wrap Index| to the legnth of the text behind the absolute index
		self.cursorY     = math.max(#textWrapBefore,1) * self.fontHeight
		self.cursorLine  = #textWrapBefore
		
		self:setText(self.plainText,self.wrap,self.align)                                                --Set the text to the updated string
		self.blinkTimer = 0                                                                              --Prevent cursor from blinking
		self.showCursor = true
		--]]
	end
	
	textBox.meta.onReturn = function(self, key)
		local textBefore = string.utf8sub(self.plainText, 1, self.cursorIndex)                     --Get text before the current |Plain Text Index| position
		local textAfter  = string.utf8sub(self.plainText, self.cursorIndex+1,self.plainText:len()) --Get text after the current |Plain Text Index| position
		
		self.plainText       = table.concat{textBefore,'\n',textAfter}                             --concatenate table of text, update the |Plain Text|
		self.cursorX         = 0                                                                   --Set |Cursor X| to 0 when starting a newline
		self.cursorLine      = self.cursorLine + 1                                                 --Increament |Cursor's line| position
		self.cursorY         = self.cursorY + self.fontHeight                                      --Increament |Cursor's Y| position by the font height
		self.cursorIndex     = self.cursorIndex + 1                                                --Increament |Cursor Index| for |Plain Text| (to account for the '\n' character)
		self.wrapIndex       = 0                                                                   --Rest |Cursor's Wrapped Index| to 1 (to account for the '\n' character)		
		self:setText(self.plainText,self.wrap,self.align)
	end
	
	textBox.meta.onBackspace = function(self, key)
		local textBefore        = string.utf8sub(self.plainText, 0, self.trueIndex - 1)                    --Text before the index
		local textRem           = string.utf8sub(self.plainText, self.trueIndex, self.trueIndex)         --Text removed at index
		local textAfter         = string.utf8sub(self.plainText, self.trueIndex + 1, self.plainText:len()) --Text after the index
		self.plainText     = textBefore
		self:moveIndexHorizontal(-1)
		self.plainText     = table.concat{textBefore,textAfter}                                              --Update the plainText string
		
		
		
		
		
		self:setText(self.plainText,self.wrap,self.align)
	end
	
	textBox.meta.onLeft = function(self, key) -- |Uses the same logic a backspace, but The Plain Text stays the same|
		self:moveIndexHorizontal(-1)
	end
	
	textBox.meta.onRight = function(self, key)
		self:moveIndexHorizontal(1)
	end
	testerBox = textBox:new("", 100, 100)
	
	font = love.graphics.getFont()
	fontHeight = font:getHeight()
	wrap = 100
	plainText = ""
	formatedText = love.graphics.newText(font)
	formatedText:setf(plainText, wrap, "left")
	
	cursorTextIndex = 0
	cursorPos = 0
	cursorLine = 1
	
end


function love.draw()
	testerBox:draw()
	--[[
	love.graphics.draw(formatedText)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(2)
	love.graphics.line(cursorPos, formatedText:getHeight() - fontHeight, cursorPos, fontHeight*cursorLine)
	love.graphics.setLineStyle("rough")
	]]
end

function love.update(dt)
	testerBox:update(dt)
	--print(testerBox.cursorWrapIndex)
	local out = string.gsub(testerBox.plainText,'\n','~')
	print(string.utf8sub(out, 0, testerBox.trueIndex).."|"..string.utf8sub(out,testerBox.trueIndex + 1, -1))
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
	
	--[[
#		Text States
		
		_State I:_   [ABCD] [E]|(F) (G)[HIJ], ... ======> Move right;  Cursor x += nextChar_width; Cursor index++;
		_State II:_  [ABCD] [E]|(H) (\n), [...] ========> Move cursor(X,Y) to start of next line; Cursor_Index++; Cursor_Line++;
		_State III:_ [ABCDEFGH] [I]|(J) (nil), [...] ===> Same as State II;
		State IV:  [ABCDEFGHI] [J]|(nil) (nil) ========> Do nothing;
		
	]]
	
	if key == "right" then		
		
		testerBox:onRight(key)
		
	end
	
	if key == "up" then
		
	end
	
	if key == "down" then
		
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
