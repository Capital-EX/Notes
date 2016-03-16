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
			
			tb.cursorIndex     = tb.plainText:len()                       --Where we are in the full string of plain text
			tb.cursorWrapIndex = #wraps == 0 and 0 or wraps[#wraps]:len() --Where we are in the current line of wrapped text
			tb.cursorLine      = 0                                        --Current of wrapped text
			
			tb.cursorX         = tb.font:getWrap(tb.plainText, tb.wrap)
			tb.cursorY         = tb.fontHeight * math.max(tb.cursorLine,1)
			
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
	
	textBox.meta.onTextInput = function(self, key, code)
		
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
		local textBefore        = string.utf8sub(self.plainText, 0, self.cursorIndex - 1)                    --Text before the index
		local textRem           = string.utf8sub(self.plainText, self.cursorIndex, self.cursorIndex)         --Text removed at index
		local textAfter         = string.utf8sub(self.plainText, self.cursorIndex + 1, self.plainText:len()) --Text after the index
		local _, textWrapBefore = self.font:getWrap(textBefore,self.wrap)                                    --The wrapping of the text before the index
		self.plainText     = table.concat{textBefore,textAfter}                                              --Update the plainText string
		
		if #textWrapBefore == 0 then            --If no text is behind the |Index|
			self.cursorIndex     = 0       --Set |The Index| equal to zero
			self.cursorWrapIndex = 0       --Set |The Wrap Index| to zero as well
			self.cursorX         = 0       --Set teh |Cursor X| 2 0 plz
			if textRem == '\n' then
				self.cursorY     = self.fontHeight      --Update the |Cursor Y| when a \n is removed
				self.cursorLine  = self.cursorLine - 1  --Update the |Cursor Line|
			end
		else                                                                           --Elsewise
			self.cursorIndex     = self.cursorIndex - 1                                --Decreament |The Index|
			self.cursorWrapIndex = textWrapBefore[#textWrapBefore]:len()               --Set |The Wrap Index| to the legnth of the text behind the absolute index
			if textBefore:sub(-1,-1) ~= '\n' then
				self.cursorX     = self.font:getWidth(textWrapBefore[#textWrapBefore]) --Set the |X| position of the cursor to the pixel width of the text behind the absolute index
				self.cursorLine  = #textWrapBefore                                     --Update |Cursor Line|
				self.cursorY     = math.max(#textWrapBefore,1) * self.fontHeight       --Update the |Y| position
			elseif textRem == '\n' then
				self.cursorLine  = self.cursorLine - 1                                 --Update the |Cursor Y| when a \n is removed
				self.cursorY     = self.cursorY - self.fontHeight                      --Update the |Cursor Line|
			else
				self.cursorX     = self.cursorX - self.font:getWidth(textRem)          --Update |Cursor X|
				self.cursorLine  = #textBefore                                         --Update the |Cursor Line|, _just in case_
			end
		end
		
		self:setText(self.plainText,self.wrap,self.align)
	end
	
	textBox.meta.onLeft = function(self, key) -- |Uses the same logic a backspace, but The Plain Text stays the same|
		local textBefore   = string.utf8sub(self.plainText, 0, self.cursorIndex - 1)
		local previousChar = string.utf8sub(self.plainText, self.cursorIndex, self.cursorIndex)
		
		local _, textWrapBefore = self.font:getWrap(textBefore,self.wrap)
		
		if #textWrapBefore == 0 then
			self.cursorIndex     = 0
			self.cursorWrapIndex = 0
			self.cursorX         = 0
			if previousChar == '\n' then
				self.cursorY     = 0
				self.cursorLine  = self.cursorLine - 1 
			end
		else
			self.cursorIndex     = self.cursorIndex - 1
			self.cursorWrapIndex = textWrapBefore[#textWrapBefore]:len()
			if textBefore:sub(-1,-1) ~= '\n' then
				self.cursorX     = self.font:getWidth(textWrapBefore[#textWrapBefore])
				self.cursorLine  = #textWrapBefore
				self.cursorY     = math.max(#textWrapBefore,1) * self.fontHeight
			elseif previousChar == '\n' then
				self.cursorLine  = self.cursorLine - 1
				self.cursorY     = self.cursorY - self.fontHeight
			else
				self.cursorX     = self.cursorX - self.font:getWidth(previousChar)
				self.cursorLine  = #textBefore
			end
		end	
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
end


function love.textinput(key, code)
	testerBox:onTextInput(key,code)	
end

function love.keypressed(key)
	
	if key == "return" then	
		testerBox:onReturn(key)
	end
	
	if key == "backspace" and testerBox.cursorIndex > 0 then
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
		local textBefore   = string.utf8sub(testerBox.plainText, 0, testerBox.cursorIndex)                      --The text before includes the character directly after the cursor here.
		local previousChar = string.utf8sub(testerBox.plainText, testerBox.cursorIndex, testerBox.cursorIndex)
		
	end
	
	testerBox.blinkTimer = 0
	testerBox.showCursor = true
	print(string.gsub(testerBox.plainText,'\n','\\n'))
end

function love.mousereleased(x, y, button) 
	
end 

function love.mousepressed(x, y, button)  

end

function love.touchpressed(id, x, y, pressure)
	
end

function love.touchreleased(id, x, y, pressure)
	
end
