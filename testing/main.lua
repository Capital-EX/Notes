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
			
			tb.wrap        =  wrap or tb.font:getWidth("m") * 10 --Defaults to 50 em of space
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
			
			tb.cursorIndex     = tb.plainText:len()
			tb.cursorWrapIndex = #wraps == 0 and 0 or wraps[#wraps]:len()
			
			tb.cursorX         = tb.font:getWrap(tb.plainText, tb.wrap)
			tb.cursorY         = tb.fontHeight
			
			tb.cursorLine      = 1
			
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
	local textBefore = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex) 
	local textAfter  = string.utf8sub(testerBox.plainText, testerBox.cursorIndex+1,testerBox.plainText:len())
	testerBox.plainText = table.concat{textBefore,key,textAfter}
	testerBox:setText(testerBox.plainText,testerBox.wrap,testerBox.align)
	testerBox.cursorIndex = testerBox.cursorIndex + 1
	
	local width, wrapedLines = font:getWrap(testerBox.plainText, testerBox.wrap)
	print(wrapedLines[#wrapedLines].."ENDL")
	if not (key == " " and testerBox.font:getWidth(wrapedLines[testerBox.cursorLine]) > testerBox.wrap) then
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
		local textBefore = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex) 
		local textAfter  = string.utf8sub(testerBox.plainText, testerBox.cursorIndex+1,testerBox.plainText:len())
		
		testerBox.plainText = table.concat{textBefore,"\n",textAfter}
		testerBox.cursorX = 0
		testerBox.cursorLine = testerBox.cursorLine + 1
		testerBox.cursorY = testerBox.cursorY + testerBox.fontHeight
		testerBox.cursorIndex = testerBox.cursorIndex + 1
	end
	
	if key == "backspace" then
		if testerBox.cursorIndex ~= 0 then
			local textBefore = string.utf8sub(testerBox.plainText, 1, testerBox.cursorIndex - 1) 
			local textAfter  = string.utf8sub(testerBox.plainText, testerBox.cursorIndex + 1,testerBox.plainText:len())
			
			testerBox.plainText = table.concat{textBefore,textAfter}
			testerBox.cursorIndex = testerBox.cursorIndex - 1
			
			local width, wrapedLines = testerBox.font:getWrap(testerBox.plainText, testerBox.wrap)
			textBehindCursor = wrapedLines[testerBox.cursorLine]:sub(1, testerBox.cursorIndex)
			
			if testerBox.cursorLine > 1 then
				testerBox.cursorLine = testerBox.cursorLine - 1
				testerBox.cursorY = testerBox.cursorLine * testerBox.fontHeight
				width = testerBox.font:getWidth(textBehindCursor)
				testerBox.cursorX = math.min(width, testerBox.wrap)
			else
				testerBox.cursorX = 0
			end
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
