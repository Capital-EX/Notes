require("./utf8")
--[[
	
	todo, as late as possible: change the text area to allow for free form editing.
	
]]


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
			tb.cursorY         = tb.fontHeight * tb.cursorIndex
			
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
			self.cursorY + self.y - self.fontHeight
		)
		love.graphics.setLineStyle("rough")
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
	testerBox.plainText   = table.concat{textBefore,key,textAfter}                                                 --Put the new string together; Update plain text
	testerBox.cursorIndex = testerBox.cursorIndex + 1                                                              --Increment the cursor index
	
	testerBox.cursorX     = testerBox.font:getWidth(textWrapBefore[#textWrapBefore])                               --Set the wrap index to the legnth of the text behind the absolute index
	
	testerBox:setText(testerBox.plainText,testerBox.wrap,testerBox.align)                                          --Set the text to the updated string
	testerBox.blinkTimer = 0
	testerBox.showCursor = true
	
end

function love.keypressed(key)
	
	if key == "return" then
		local textBefore = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex)                          --Get text before the current plain text index position
		local textAfter  = string.utf8sub(testerBox.plainText, testerBox.cursorIndex+1,testerBox.plainText:len()) --Get text after the current plain text index position
		
		testerBox.plainText       = table.concat{textBefore,'\n',textAfter}                                       --concatenate table of text, update the plain text
		testerBox.cursorX         = 0                                                                             --Set cursor X to 0 when starting a newline
		testerBox.cursorLine      = testerBox.cursorLine + 1                                                      --Increament cursor's line position
		testerBox.cursorY         = testerBox.cursorY + testerBox.fontHeight                                      --Increament cursor's Y position by the font height
		testerBox.cursorIndex     = testerBox.cursorIndex + 1                                                     --Increament cursor index for plain text (to account for the '\n' character)
		testerBox.wrapIndex       = 0                                                                             --Rest cursor's wrapped index to 1 (to account for the '\n' character)
		
	end
	
	
	if key == "backspace" then
		local textBefore        = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex - 1)                         --Text before the index
		local textRem           = string.utf8sub(testerBox.plainText, testerBox.cursorIndex, testerBox.cursorIndex)         --Text removed at index
		local textAfter         = string.utf8sub(testerBox.plainText, testerBox.cursorIndex + 1, testerBox.plainText:len()) --Text after the index
		local _, textWrapBefore = testerBox.font:getWrap(textBefore,testerBox.wrap)                                         --The wrapping of the text before the index
		testerBox.plainText     = table.concat{textBefore,textAfter}                                                        --Update the plainText string
		--[[
			**I S S U E S**
			:: Cursor does not align with text when textBefor is empty
			**T O D O S**
			:: CursorY need to update with text
		]]
		if #textWrapBefore == 0 then                                                                --If no text is behind the index
			testerBox.cursorIndex     = 0                                                           --Set the index equal to zero
			testerBox.cursorWrapIndex = 0                                                           --Set the wrap index to zero as well
			testerBox.cursorX         = 0
		else                                                                                        --Elsewise
			testerBox.cursorIndex     = testerBox.cursorIndex - 1                                   --Decreament the index
			testerBox.cursorWrapIndex = textWrapBefore[#textWrapBefore]:len()                       --Set the wrap index to the legnth of the text behind the absolute index
			testerBox.cursorX         = testerBox.font:getWidth(textWrapBefore[#textWrapBefore])    --Set the X position of the cursor to the pixel width of the text behind the absolute index
		end
		
		testerBox:setText(testerBox.plainText,testerBox.wrap,testerBox.align)
		
	end
	
	if key == "left" and testerBox.cursorIndex - 1 >= 0 then
		
	end
	
	if key == "right" and testerBox.cursorIndex + 1 <= testerBox.plainText:len() then
		
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
