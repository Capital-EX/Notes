require 'gooi'
tween = require 'tween.tween'
textBox = require 'textBox'
function love.load()
	--[[
		Draw Formating
	]]
	love.graphics.setBackgroundColor(232,255,255)
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineJoin("bevel")
	font = love.graphics.getFont()
	
	winW, winH  = love.graphics.getWidth(), love.graphics.getHeight()
	--[[
		Paper is the drawing surface
	]]
	paper = love.graphics.newCanvas()
	
	textBoxes = {
		id = 0
	}
	
	--[[
		Brush Stuff
	]]
	brush = {
		color     = {1,1,1,1},
		mode      = "draw",
		isErase   = false,
		isDown    = false,
		brushSize = 4,
		oldmx     = 0,
		oldmy     = 0,
		maxSize   = 20,
		curLine   = {},
		update    = function(self, dt)
			local mx, my = love.mouse.getX(), love.mouse.getY()
			if self.isDown then
				
				print(#self.curLine)
				if self.isDown and self.oldmx ~= mx and self.oldmy ~= my then
					print(mx,my)
					if #self.curLine == 0 then
						love.graphics.setCanvas(paper)
							love.graphics.setLineStyle("smooth")
							love.graphics.setColor(brush.color)
							love.graphics.circle('fill',mx,my,math.ceil(brush.brushSize/2))
							love.graphics.setColor(255,255,255)
						love.graphics.setCanvas()
					end
					self.curLine[#self.curLine + 1] = mx
					self.curLine[#self.curLine + 1] = my
				end
				if #self.curLine > 4 then
					if self.isErase then
						love.graphics.setBlendMode("replace")
						love.graphics.setColor(0,0,0,0)
					else
						love.graphics.setColor(self.color)
					end
					love.graphics.setCanvas(paper)
						love.graphics.setLineWidth(self.brushSize)
						print(#self.curLine)
						love.graphics.line(self.curLine)
						love.graphics.setColor(255,255,255)
					love.graphics.setCanvas()
				end
				love.graphics.setBlendMode("alpha")	
			end
			
			self.color = {gooi.get("redSlider").value*255, gooi.get("greenSlider").value*255, gooi.get("blueSlider").value*255}
			self.brushSize  = gooi.get("sizeSlider").value * self.maxSize
			self.isErase = gooi.get("toggleErase").checked
			self.oldmx, self.oldmy = mx,my
		end,
		moved    = function(self,x,y,dx,dy)
			self.curLine[#self.curLine+1] = x
			self.curLine[#self.curLine+1] = y
		end
		
	}
	
	controlls = {
		width      = winW*0.25,
		height     = winH*0.5,
		x          = 0,
		y          = 0,
		hidden     = false,
		menuStates = {"Brush","Text","Closed"},
		menuState  = "Brush",
		changeState  = function(self, state)
			gooi.setGroupEnabled(self.menuState.."_controlls", false)
			gooi.setGroupVisible(self.menuState.."_controlls", false)
			self.menuState = state
			gooi.setGroupEnabled(self.menuState.."_controlls", true)
			gooi.setGroupVisible(self.menuState.."_controlls", true)
		end
	}
	gui   = love.graphics.newCanvas()
	--[[
		Drawing Controlls
	]]
	
	controlls.brushMenu = gooi.newPanel("brushControlls",controlls.x,controlls.y,controlls.width,controlls.height, "grid 9x1", "Brush_controlls")
	local widgets = {
		gooi.newLabel("redLabel", "Red"):setOrientation("left"),
		gooi.newSlider("redSlider"):setValue(2),
		gooi.newLabel("greenLabel", "Green"):setOrientation("left"),
		gooi.newSlider("greenSlider"):setValue(2),
		gooi.newLabel("blueLabel", "Blue"):setOrientation("left"),
		gooi.newSlider("blueSlider"):setValue(2),
		gooi.newLabel("sizeLabel", "Size"):setOrientation("left"),
		gooi.newSlider("sizeSlider"):setValue(2),
		gooi.newCheck("toggleErase","Erase Mode"),
	}
	for i = 1, #widgets do
		widgets[i].group = "Brush_controlls"
		controlls.brushMenu:add(widgets[i])
	end
	
	controlls.controllSelector = gooi.newPanel("controllSelector",controlls.x+controlls.width,controlls.y,controlls.width/4,controlls.height, "grid 3x1", "controll_selector")
	widgets = {
		gooi.newButton("BrushMenuButton","b\nr\nu\ns\nh\n"):setDirection("vertical"):onRelease(function(c) controlls:changeState("Brush") end),
		gooi.newButton("TextMenuButton","t\ne\nx\nt"):setDirection("vertical"):onRelease(function(c) controlls:changeState("Text") end),
	}
	for i = 1, #widgets do
		widgets[i].group = "controll_selector"
		controlls.controllSelector:add(widgets[i])
	end
	
	controlls.textMenu = gooi.newPanel("textControlls", controlls.x, controlls.y, controlls.width, controlls.height, "grid 9x1", "Text_controlls")
	widgets = {
		gooi.newLabel("fontSizeLabel","Font Size"):setOrientation("center"),
		gooi.newSlider("fontSizeSlider"),
		gooi.newButton("addTextBox","New Text Box"):setOrientation("center"):onRelease(
			function() 
				local font = love.graphics.newFont(gooi.get("fontSizeSlider").value * 30 + 12)
				textBoxes.id = textBoxes.id + 1
				local tb = textBox:new(textBoxes.id, love.graphics.getWidth()/2, love.graphics.getHeight()/2, 20*font:getWidth"M", "left", font)
				textBoxes[#textBoxes + 1] = tb
			end	
			),
	}
	for i = 1, #widgets do
		widgets[i].group = "Text_controlls"
		controlls.textMenu:add(widgets[i])
	end
	--[[
	controlls.controllSelector.layout.debug = true
	controlls.textMenu.layout.debug = true
	--]]
end

function love.draw()
	love.graphics.print(love.timer.getFPS(),500,500)
	love.graphics.draw(paper,0,0)
	love.graphics.setColor(100,100,100)
	love.graphics.rectangle("fill",0,0,controlls.width,controlls.height)
	love.graphics.setColor(0,0,0)
	for i = 1, #textBoxes do
		textBoxes[i]:draw()
	end
	love.graphics.setColor(255,255,255)
	gooi.draw(controlls.menuState.."_controlls")
	gooi.draw("controll_selector")
end

function love.update(dt)
	gooi.update(dt)
	brush:update(dt)
	for i = #textBoxes, 1, -1 do
		textBoxes[i]:update(dt)
		if textBoxes[i].remove then
			print("removing text box ", i)
		end
	end
	
end

function love.textinput(text)
	for _, tb in ipairs(textBoxes) do
		tb:textinput(text)
	end
end

function love.keypressed(key,code)
	for _, tb in ipairs(textBoxes) do
		tb:keypressed(key)
	end
end
---[[
function love.mousepressed(x,y,m,istouch)
	--gooi.pressed(nil,x-controlls.x,y)
	local isDragging = gooi.pressed()
	for _, tb in ipairs(textBoxes) do
		if not isDragging then
			print("trying!")
			isDragging = tb:pressed()
		else
			tb.hasFocus = false
		end
	end
	
	if not ((controlls.x < x and x < controlls.width + controlls.x ) and 
	(controlls.y < y and y < controlls.y + controlls.brushMenu.h )) and 
	not isDragging then
		brush.isDown = true
	end
	
end

function love.mousemoved(x,y,dx,dy)
	for _, tb in ipairs(textBoxes) do
		tb:moved(x,y,dx,dy)
	end
end

function love.mousereleased(x,y)
	if brush.isDown and #brush.curLine > 4 then
		brush.curLine[#brush.curLine + 1] = x
		brush.curLine[#brush.curLine + 1] = y
		love.graphics.setCanvas(paper)
			love.graphics.setLineWidth(brush.brushSize)
			love.graphics.setColor(brush.color)
			love.graphics.circle('fill',x,y,math.ceil(brush.brushSize/2))
			love.graphics.line(brush.curLine)
			love.graphics.setColor(255,255,255)
		love.graphics.setCanvas()
	elseif brush.isDown then
		love.graphics.setCanvas(paper)
			love.graphics.setColor(brush.color)
			love.graphics.circle('fill',x,y,math.ceil(brush.brushSize/2))
			love.graphics.setColor(255,255,255)
		love.graphics.setCanvas()
	end
	brush.isDown = false
	brush.curLine = {}
	local mouseCaught = gooi.released()
	for _, tb in ipairs(textBoxes) do
		if not mouseCaught then
			mouseCaught = tb:released()
		else
			tb.hasFocus = false
		end
		tb.isDragging = false
	end
	if not mouseCaught then
		love.keyboard.setTextInput(false)
	end
end
--]]
--[[
function love.touchpressed(id, x, y)
	local isDragging = gooi.pressed(id, x, y)
	for _, tb in ipairs(textBoxes) do
		if not isDragging then
			isDragging = tb:pressed(id, x, y)
		else
			tb.hasFocus = false
		end
	end
	
	if not ((controlls.x < x and x < controlls.width + controlls.x ) and 
	(controlls.y < y and y < controlls.y + controlls.brushMenu.h )) and 
	not isDragging then
		brush.isDown = true
	end
end

function love.touchmoved(id, x, y, dx, dy)
	gooi.moved(id, x, y)
	if brush.isDown and #brush.curLine >= 4 then
		brush:moved(x,y,dx,dy)
	end
	for _, tb in ipairs(textBoxes) do
		tb:moved(x, y, dx, dy)
	end
end

function love.touchreleased(id,x,y)
	brush.isDown = false
	brush.curLine = {}
	local touchCaught = gooi.released(id,x,y)
	for _, tb in ipairs(textBoxes) do
		if not mouseCaught then
			mouseCaught = tb:released(x, y)
		else
			tb.hasFocus = false
		end
		tb.isDragging = false
	end
	if not mouseCaught then
		love.keyboard.setTextInput(false)
	end
end
--]]