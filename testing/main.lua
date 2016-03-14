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
			tb.cursorLine      = #wraps and math.max(#wraps, 1) or 1      --Current of wrapped text
			
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
		love.graphics.line(
			self.cursorX+self.x, 
			math.max(self.cursorY,self.fontHeight) + self.y - self.fontHeight, 
			self.cursorX+self.x, 
			self.fontHeight * (math.max(self.cursorLine,1)) + self.y
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
end


function love.textinput(key, code)
	local textBefore      = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex)                           --Get the text behind the cursor
	local textAfter       = string.utf8sub(testerBox.plainText, testerBox.cursorIndex+1,testerBox.plainText:len())  --Get the text before the cursor
	testerBox.plainText   = table.concat{textBefore,key,textAfter}                                                  --Put the new string together; Update plain text
	testerBox.cursorIndex = testerBox.cursorIndex + 1                                                               --Increment the cursor index
	testerBox:setText(testerBox.plainText,testerBox.wrap,testerBox.align)                                           --Set the text to the updated string
	
	
	local width, wrapedLines = font:getWrap(testerBox.plainText, testerBox.wrap)
	print(#wrapedLines,testerBox.cursorLine)
	if not (key == " " and testerBox.font:getWidth(wrapedLines[testerBox.cursorLine]) > testerBox.wrap) then
		print(key)
		testerBox.cursorX = testerBox.cursorX + testerBox.font:getWidth(key)
		--testerBox.cursorWrapIndex
	end
	
	if testerBox.cursorX + testerBox.font:getWidth(key) > testerBox.wrap then
		if key ~= " " then
			testerBox.cursorLine = testerBox.cursorLine + 1
			testerBox.cursorY = testerBox.cursorLine * testerBox.fontHeight
			testerBox.cursorX = 0
		end		
	end
	
	
	
	testerBox.blinkTimer = 0
	testerBox.showCursor = true
end

function love.keypressed(key)
	if key == "return" then
		local textBefore = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex)                           --Get text before the current plain text index position
		local textAfter  = string.utf8sub(testerBox.plainText, testerBox.cursorIndex+1,testerBox.plainText:len())  --Get text after the current plain text index position
		
		testerBox.plainText       = table.concat{textBefore,"\n",textAfter}   --concatenate table of text, update the plain text
		testerBox.cursorX         = 0                                         --Set cursor X to 0 when starting a newline
		testerBox.cursorLine      = testerBox.cursorLine + 1                  --Increament cursor's line position
		testerBox.cursorY         = testerBox.cursorY + testerBox.fontHeight  --Increament cursor's Y position by the font height
		testerBox.cursorIndex     = testerBox.cursorIndex + 1                 --Increament cursor index for plain text (to account for the '\n' character)
		testerBox.cursorWrapIndex = 1                                         --Rest cursor's wrapped index to 1 (to account for the '\n' character)
	end
	
	if key == "backspace" then
		if testerBox.cursorIndex ~= 0 then
			local textBefore  = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex - 1)                        --Get the text behind the character to be removed
			local deletedChar = string.utf8sub(testerBox.plainText,testerBox.cursorIndex,testerBox.cursorIndex)          --Get the character to be removed; Used to catch when a newline is deleted
			local textAfter   = string.utf8sub(testerBox.plainText, testerBox.cursorIndex + 1,testerBox.plainText:len()) --Get the text ahead of the current plain text index position
			
			testerBox.plainText   = table.concat{textBefore,textAfter} --Update plain text to remove deleted character
			testerBox.cursorIndex = testerBox.cursorIndex - 1          --Decreament cursor text index
			
			local _, wrappedText  = testerBox.font:getWrap(testerBox.plainText, testerBox.wrap)
			if deleteChar == '\n' or testerBox.cursorWrapIndex == 0 then                                --If the character deleted is a newline or the cursor wrap index is 0
				testerBox.cursorLine      = testerBox.cursorLine - 1                                    --Move cursor up a line
				testerBox.cursorWrapIndex = wrappedText[testerBox.cursorLine]:len()                     --Set the wrapped index to the current lines length
				testerBox.cursorX         = testerBox.font:getWidth(wrappedText[testerBox.cursorLine])  --Set the cursor x to the width of the current line of wrapped text
			else
				testerBox.cursorWrapIndex = testerBox.cursorWrapIndex - 1                               --Continue back like usual 
				testerBox.cursorX         = testerBox.cursorX - testerBox.font:getWidth(deletedChar)    --But move the cursor back by the character width
			end
			
			--[[ |O L D   C O D E|
			testerBox.plainText   = table.concat{textBefore,textAfter}  --Update plain text to remove deleted character
			testerBox.cursorIndex = testerBox.cursorIndex - 1           --Decreament cursor text index
			
			local width, wrappedLines = testerBox.font:getWrap(testerBox.plainText, testerBox.wrap)         --Get the table of wrapped text; each index of wrappedLines a line of wrapped text
			textBehindCursor         = wrapedLines[testerBox.cursorLine]:sub(0, testerBox.cursorWrapIndex)  --Get 
			
			if testerBox.cursorLine > 1 then
				testerBox.cursorLine = testerBox.cursorLine - 1                 --
				testerBox.cursorY = testerBox.cursorLine * testerBox.fontHeight --
				width = testerBox.font:getWidth(textBehindCursor)
				testerBox.cursorX = math.min(width, testerBox.wrap)
			else
				testerBox.cursorX = 0
			end
			--]]
			
		end
	end
	
	if key == "left" and testerBox.cursorIndex - 1 >= 0 then
		local previousChar = string.utf8sub(testerBox.plainText,testerBox.cursorIndex,testerBox.cursorIndex)
		local charWidth    = testerBox.font:getWidth(previousChar)
		local width, wrapedLines = testerBox.font:getWrap(testerBox.plainText, testerBox.wrap)
		
		testerBox.cursorIndex = testerBox.cursorIndex - 1
		testerBox.cursorX     = testerBox.cursorX - testerBox.font:getWidth(previousChar)
		
		if previousChar == "\n" or testerBox.cursorX < 0 then
			
			testerBox.cursorLine   = testerBox.cursorLine - 1
			
			testerBox.cursorY      = testerBox.cursorY    - testerBox.fontHeight
			testerBox.cursorX      = testerBox.font:getWidth(wrapedLines[testerBox.cursorLine]) - charWidth
			
		end
	end
	
	if key == "right" and testerBox.cursorIndex + 1 <= testerBox.plainText:len() then
		local nextChar = string.utf8sub(testerBox.plainText,testerBox.cursorIndex,testerBox.cursorIndex)
		testerBox.cursorIndex = testerBox.cursorIndex + 1
		testerBox.cursorX     = testerBox.cursorX + testerBox.font:getWidth(nextChar)
	end
	
	testerBox:setText(testerBox.plainText,testerBox.wrap,testerBox.align)
	testerBox.blinkTimer = 0
	testerBox.showCursor = true
end

function love.mousereleased(x, y, button) 
	
end 
function love.mousepressed(x, y, button)  

end
