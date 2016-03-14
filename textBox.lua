textBox = {
	new = function(x,y) 
		tb = {}
		tb.x = x
		tb.y = y
		tb.plainText
		tb.textDraw = love.graphics.newText("This is a filler string")
		return setmetatable({x = x, y = y, text = love.graphics.newText()},{__index = self.meta})
	end
	meta = {
		x = 0,
		y = 0,
		editing = false,
		setText    = function(self,text)
			self.text = text
		end,
		isReleased = function(self,x,y)
			mx = x or love.mouse.getX()
			my = y or love.mouse.getY()
			if (mx > self.x and mx < self.x + self.width) and (my > self.y and my < self.y + self.height) then
				love.keyboard.setTextInput(true)
			end
		end,
		draw       = function(self)
			love.graphics.draw(self.textDraw)
		end
	}
}