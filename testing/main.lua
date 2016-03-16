--[[
#	Text area todo
	Backspacing         [X]
	Left Movement       [X]
	Right Movement      [ ]
	Free-form Movement  [ ]
	Upward Movement     [ ]
	Downward Movement   [ ]
	
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
	
	textBox.meta.onReturn = function(self, key)
		
		
	end
	
	textBox.meta.onBackspace = function(self, key)
		
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
	local textBefore      = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex)                          --Get the text behind the index
	local textAfter       = string.utf8sub(testerBox.plainText, testerBox.cursorIndex+1,testerBox.plainText:len()) --Get the text after the index
	local _, textWrapBefore = testerBox.font:getWrap(textBefore..key,testerBox.wrap)                               --Get the wrapping of the text behind the index
	testerBox.plainText   = table.concat{textBefore,key,textAfter}                                                 --Put the new string together; Update |Plain Text|
	testerBox.cursorIndex = testerBox.cursorIndex + 1                                                              --Increment the |Cursor Index|
	
	testerBox.cursorX     = testerBox.font:getWidth(textWrapBefore[#textWrapBefore])                               --Set the |Wrap Index| to the legnth of the text behind the absolute index
	testerBox.cursorY     = math.max(#textWrapBefore,1) * testerBox.fontHeight
	testerBox.cursorLine  = #textWrapBefore
	testerBox:setText(testerBox.plainText,testerBox.wrap,testerBox.align)                                          --Set the text to the updated string
	testerBox.blinkTimer = 0                                                                                       --Prevent cursor from blinking
	testerBox.showCursor = true
	
end

function love.keypressed(key)
	
	if key == "return" then		
		local textBefore = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex)                          --Get text before the current |Plain Text Index| position
		local textAfter  = string.utf8sub(testerBox.plainText, testerBox.cursorIndex+1,testerBox.plainText:len()) --Get text after the current |Plain Text Index| position
		
		testerBox.plainText       = table.concat{textBefore,'\n',textAfter}                                       --concatenate table of text, update the |Plain Text|
		testerBox.cursorX         = 0                                                                             --Set |Cursor X| to 0 when starting a newline
		testerBox.cursorLine      = testerBox.cursorLine + 1                                                      --Increament |Cursor's line| position
		testerBox.cursorY         = testerBox.cursorY + testerBox.fontHeight                                      --Increament |Cursor's Y| position by the font height
		testerBox.cursorIndex     = testerBox.cursorIndex + 1                                                     --Increament |Cursor Index| for |Plain Text| (to account for the '\n' character)
		testerBox.wrapIndex       = 0                                                                             --Rest |Cursor's Wrapped Index| to 1 (to account for the '\n' character)
	end
	
	
	if key == "backspace" and testerBox.cursorIndex > 0 then
		local textBefore        = string.utf8sub(testerBox.plainText, 0, testerBox.cursorIndex - 1)                         --Text before the index
		local textRem           = string.utf8sub(testerBox.plainText, testerBox.cursorIndex, testerBox.cursorIndex)         --Text removed at index
		local textAfter         = string.utf8sub(testerBox.plainText, testerBox.cursorIndex + 1, testerBox.plainText:len()) --Text after the index
		local _, textWrapBefore = testerBox.font:getWrap(textBefore,testerBox.wrap)                                         --The wrapping of the text before the index
		testerBox.plainText     = table.concat{textBefore,textAfter}                                                        --Update the plainText string
		
		if #textWrapBefore == 0 then            --If no text is behind the |Index|
			testerBox.cursorIndex     = 0       --Set |The Index| equal to zero
			testerBox.cursorWrapIndex = 0       --Set |The Wrap Index| to zero as well
			testerBox.cursorX         = 0       --Set teh |Cursor X| 2 0 plz
			if textRem == '\n' then
				testerBox.cursorY     = testerBox.fontHeight      --Update the |Cursor Y| when a \n is removed
				testerBox.cursorLine  = testerBox.cursorLine - 1  --Update the |Cursor Line|
			end
		else                                                                                     --Elsewise
			testerBox.cursorIndex     = testerBox.cursorIndex - 1                                --Decreament |The Index|
			testerBox.cursorWrapIndex = textWrapBefore[#textWrapBefore]:len()                    --Set |The Wrap Index| to the legnth of the text behind the absolute index
			if textBefore:sub(-1,-1) ~= '\n' then
				testerBox.cursorX     = testerBox.font:getWidth(textWrapBefore[#textWrapBefore]) --Set the |X| position of the cursor to the pixel width of the text behind the absolute index
				testerBox.cursorLine  = #textWrapBefore                                          --Update |Cursor Line|
				testerBox.cursorY     = math.max(#textWrapBefore,1) * testerBox.fontHeight       --Update the |Y| position
			elseif textRem == '\n' then
				testerBox.cursorLine  = testerBox.cursorLine - 1                                 --Update the |Cursor Y| when a \n is removed
				testerBox.cursorY     = testerBox.cursorY - testerBox.fontHeight                 --Update the |Cursor Line|
			else
				testerBox.cursorX     = testerBox.cursorX - testerBox.font:getWidth(textRem)     --Update |Cursor X|
				testerBox.cursorLine  = #textBefore                                              --Update the |Cursor Line|, _just in case_
			end
		end
		
		testerBox:setText(testerBox.plainText,testerBox.wrap,testerBox.align)
		
	end
	
	
	if key == "left" then  -- |Uses the same logic a backspace, but The Plain Text stays the same|
		local textBefore   = string.utf8sub(testerBox.plainText, 0, testerBox.cursorIndex - 1)
		local previousChar = string.utf8sub(testerBox.plainText, testerBox.cursorIndex, testerBox.cursorIndex)
		
		local _, textWrapBefore = testerBox.font:getWrap(textBefore,testerBox.wrap)
		
		if #textWrapBefore == 0 then
			testerBox.cursorIndex     = 0
			testerBox.cursorWrapIndex = 0
			testerBox.cursorX         = 0
			if previousChar == '\n' then
				testerBox.cursorY     = 0
				testerBox.cursorLine  = testerBox.cursorLine - 1 
			end
		else
			testerBox.cursorIndex     = testerBox.cursorIndex - 1
			testerBox.cursorWrapIndex = textWrapBefore[#textWrapBefore]:len()
			if textBefore:sub(-1,-1) ~= '\n' then
				testerBox.cursorX     = testerBox.font:getWidth(textWrapBefore[#textWrapBefore])
				testerBox.cursorLine  = #textWrapBefore
				testerBox.cursorY     = math.max(#textWrapBefore,1) * testerBox.fontHeight
			elseif previousChar == '\n' then
				testerBox.cursorLine  = testerBox.cursorLine - 1
				testerBox.cursorY     = testerBox.cursorY - testerBox.fontHeight
			else
				testerBox.cursorX     = testerBox.cursorX - testerBox.font:getWidth(previousChar)
				testerBox.cursorLine  = #textBefore
			end
		end		
	end
	
	--[[
		**Text States**
		
		_State I:_   [ABCD] [E]|(F) (G)[HIJ], ... ======> Move right;  Cursor x += nextChar_width; Cursor index++;
		_State II:_  [ABCD] [E]|(H) (\n), [...] ========> Move cursor(X,Y) to start of next line; Cursor_Index++; Cursor_Line++;
		_State III:_ [ABCDEFGH] [I]|(J) (nil), [...] ===> Same as State II;
		State IV:  [ABCDEFGHI] [J]|(nil) (nil) ========> Do nothing;
		
	]]
	
	if key == "right" then
		local textBefore   = string.utf8sub(testerBox.plainText, 0, testerBox.cursorIndex)                      --The text before includes the character directly after the cursor here.
		local previousChar = string.utf8sub(testerBox.plainText, testerBox.cursorIndex, testerBox.cursorIndex)
		
		
	end
	
	testerBox:setText(testerBox.plainText,testerBox.wrap,testerBox.align)
	testerBox.blinkTimer = 0
	testerBox.showCursor = true
	print(string.gsub(testerBox.plainText,'\n','\\n'))
end

function love.mousereleased(x, y, button) 
	
end 
function love.mousepressed(x, y, button)  

end
