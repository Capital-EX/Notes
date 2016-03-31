require 'gooi'
require 'save'
require 'load'
tween = require 'tween.tween'
textBox = require 'textBox'
function love.load()
     app = {
        failedToLoad  = false,
        activeFile    = "untitled0",
        unsaved       = true,
        deleteTextBox = false,
        deleteNote    = false,
        pixelScale    = love.window.getPixelScale(),
        height        = love.graphics.getHeight(),
        width         = love.graphics.getWidth(),
        textBoxes = {
            id = 0
        } 
    }
    
    --[[
    ===========================
    |                         |
    |     DRAWING CONFIGS     |
    |                         |
    ===========================
    ]]
   
    love.graphics.setBackgroundColor(232,255,255)
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")
    font = love.graphics.getFont()

    winW, winH  = love.graphics.getWidth(), love.graphics.getHeight()
    --[[
    ===========================
    |                         |
    |          PAPER          |
    |                         |
    ===========================
    ]]
    paper = love.graphics.newCanvas()
    --[[
    ===========================
    |                         |
    |     BRUSH   CONFIGS     |
    |                         |
    ===========================
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
                print(self.oldmx,mx,self.oldmy,my)
                if self.isDown and (self.oldmx ~= mx or self.oldmy ~= my) then
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
    
    --[[
    ===========================
    |                         |
    |     CONTROLLS MENUS     |
    |                         |
    ===========================
    ]]
    controlls = {
        width       = winW*0.25,
        height      = winH*0.5,
        x           = 0,
        y           = 0,
        hidden      = false,
        states  = {"Brush","Text","Closed"},
        state   = "Brush",
        changeState = function(self, state)
            gooi.setGroupEnabled(self.state.."_controlls", false)
            gooi.setGroupVisible(self.state.."_controlls", false)
            self.state = state
            gooi.setGroupEnabled(self.state.."_controlls", true)
            gooi.setGroupVisible(self.state.."_controlls", true)
        end,
        draw       = function(self)
            love.graphics.setColor(100,100,100)
            love.graphics.rectangle("fill",0,0,controlls.width,controlls.height)
            
            if self.state ~= "" then
                gooi.draw(self.state.."_controlls")
            end
            gooi.draw("controll_selector_sidebar")
        end
    }
    gui   = love.graphics.newCanvas()
    
    --[[
    ----------------------------
    |                          |
    |       Text  Menu         |
    |                          |
    ----------------------------
    ]]
    
    controlls.textMenu = gooi.newPanel("textControlls", controlls.x, controlls.y, controlls.width, controlls.height, "grid 9x1", "Text_controlls")
    widgets = {
        gooi.newLabel("fontSizeLabel","Font Size"):setOrientation("center"),
        gooi.newSpinner("fontSizeSpinner",nil,nil,nil,nil,12,12,30,1),
        gooi.newButton("addTextBox","New Text Box"):setOrientation("center"):onRelease(
            function()
                local fontSize = gooi.get("fontSizeSpinner").value * app.pixelScale
                local font = love.graphics.newFont(fontSize)
                app.textBoxes.id = app.textBoxes.id + 1
                local tb = textBox:new(app.textBoxes.id,"", love.graphics.getWidth()/2, love.graphics.getHeight()/2, 20*font:getWidth"M", "left", font, fontSize)
                app.textBoxes[#app.textBoxes + 1] = tb
            end),
    }
    
    for i = 1, #widgets do
        widgets[i].group = "Text_controlls"
        controlls.textMenu:add(widgets[i])
    end
    gooi.setGroupEnabled("Text_controlls", false)
    gooi.setGroupVisible("Text_controlls", false)
    
    --[[
    ----------------------------
    |                          |
    |       Brush Menu         |
    |                          |
    ----------------------------
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
    --[[
    -----------------------------
    |                           |
    |         Save Menu         |
    |                           |
    -----------------------------
    ]]
    controlls.saveMenu = gooi.newPanel("saveControlls", controlls.x, controlls.y, controlls.width, controlls.height, "grid 9x1", "Save_controlls")
    widgets = {
        gooi.newText("saveDirButton",""),
        gooi.newButton("SaveButton", "Save"):setOrientation("center"):onRelease(function(c) 
                local dir = gooi.get("saveDirButton").text
                save(dir, app.textBoxes, paper)
            end),
        gooi.newButton("loadButton","Load"):setOrientation("center"):onRelease(function(c)
                print"Hello"
                local dir = gooi.get("saveDirButton").text
                loadNotes(dir, paper, app)
            end)
    }
    for i = 1,#widgets do
        widgets[i].group = "Save_controlls"
        controlls.saveMenu:add(widgets[i])
    end
    gooi.setGroupEnabled("Save_controlls",false)
    gooi.setGroupVisible("Save_controlls",false)
    
    --[[
    -------------------------------
    |                             |
    |  Controll Selector Sidebar  |
    |                             |
    -------------------------------
    ]]
    controlls.controllSelector = gooi.newPanel("controllSelector",controlls.x+controlls.width,controlls.y,controlls.width/4,controlls.height, "grid 3x1", "controll_selector_sidebar")
    widgets = {
        gooi.newButton("BrushMenuButton","b\nr\nu\ns\nh\n"):setDirection("vertical"):onRelease(function(c) controlls:changeState("Brush") end),
        gooi.newButton("TextMenuButton","t\ne\nx\nt"):setDirection("vertical"):onRelease(function(c) controlls:changeState("Text") end),
        gooi.newButton("SaveMenuButton", "s\na\nv\ne"):setDirection("vertical"):onRelease(function(c) controlls:changeState("Save") end)
    }
    for i = 1, #widgets do
        widgets[i].group = "controll_selector_sidebar"
        controlls.controllSelector:add(widgets[i])
    end
    
    --[[ 
    =============================
    |                           |
    |		POPUP MENUS         |
    |                           |
    =============================
    ]]
    popups             = {}
    popups.width       = app.width/2
    popups.height      = 3*app.height/4
    popups.x           = app.width/2 - popups.width/2
    popups.y           = app.height/2 - popups.height/2
    --popups.width       = 400 * app.pixelScale
    --popups.height      = love.graphics.getHeight() - 100 * app.pixelScale
    popups.isShown     = false
    popups.state       = "confirm_overwrite"
    popups.changeState = function(self, state)
        if self.state == "" then
            self.state =  state
            gooi:setGroupEnabled(self.state.."_popup", true)
            gooi:setGroupVisible(self.state.."_popup", true)
        else
            gooi:setGroupEnabled(self.state.."_popup", false)
            gooi:setGroupVisible(self.state.."_popup", false)
            self.state = state
            gooi:setGroupEnabled(self.state.."_popup", true)
            gooi:setGroupVisible(self.state.."_popup", true)
        end
    end
    
    popups.draw     = function(self)
        love.graphics.setColor(100,100,100)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        if self.state ~= "" then
            love.graphics.setColor(255,255,255)
            gooi.draw(self.state.."_popup")
        end
    end
    --[[
    -------------------------------
    |                             |
    |      Confirm Overwrite      |
    |                             |
    -------------------------------
    ]]
    popups.confirmOverwrite     = gooi.newPanel("confirm_overwrite", popups.x, popups.y, popups.width, popups.height, "grid 5x4", "confirm_overwrite_popup")
        :setRowspan(1, 1, 5)
        :setColspan(1, 1, 3)
    widgets = {
        gooi.newLabel("confirm_overwrite_label", "Are you sure you want to overwrite these notes?\nthis cannot be undone."):setOrientation("center")
    }
    for i = 1, #widgets do
        widgets[i].group = "confirm_overwrite_popup"
        popups.confirmOverwrite:add(widgets[i])
    end
    --[[
    -------------------------------
    |                             |
    |   Confirm Delete Textbox    |
    |                             |
    -------------------------------
    ]]
    popups.confirmDeleteTextBox = gooi.newPanel("confirm_delete_textbox",app.width/4, app.height/8, app.width/2, 3*app.height/4, "grid 4x4", "confirm_delete_textbox_popup")
    --[[
    -------------------------------
    |                             |
    |    Confirm Delete Notes     |
    |                             |
    -------------------------------
    ]]
    popups.confirmDeleteNotes   = gooi.newPanel("confirm_delete_notes",app.width/4, app.height/8, app.width/2, 3*app.height/4, "grid 4x4", "confirm_delete_notes_popup")
end

function love.draw()
    love.graphics.draw(paper,0,0)    
    love.graphics.setColor(0,0,0)
    love.graphics.print(love.timer.getFPS(),200,200)
    for i = 1, #app.textBoxes do
        app.textBoxes[i]:draw()
    end
    controlls:draw()
    popups:draw()
    
    love.graphics.setColor(255,255,255)
    --gooi.draw("controll_selector")
end

function love.update(dt)
    gooi.update(dt)
    brush:update(dt)
    for i = #app.textBoxes, 1, -1 do
        app.textBoxes[i]:update(dt)
        if app.textBoxes[i].remove and app.deleteTextBox then
            table.remove(app.textBoxes, i)
        end
    end

end

function love.textinput(text)
    for _, tb in ipairs(app.textBoxes) do
        tb:textinput(text)
    end
    gooi.textinput(text)
end

function love.keypressed(key,code)
    for _, tb in ipairs(app.textBoxes) do
        tb:keypressed(key)
    end
    gooi.keypressed(key, code)
end
---[[
function love.mousepressed(x,y,m,istouch)
    local isDragging = gooi.pressed()
    for _, tb in ipairs(app.textBoxes) do
        if not isDragging then

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
    for _, tb in ipairs(app.textBoxes) do
        tb:moved(x,y,dx,dy)
    end
end

function love.mousereleased(x,y)
    if brush.isDown and #brush.curLine > 4 then
        brush.curLine[#brush.curLine + 1] = x
        brush.curLine[#brush.curLine + 1] = y
        love.graphics.setCanvas(paper)
            love.graphics.setLineWidth(brush.brushSize)
            if brush.isErase then
                love.graphics.setBlendMode("replace")
                love.graphics.setColor(0,0,0,0)
            else
                love.graphics.setColor(brush.color)
            end
            love.graphics.circle('fill',x,y,math.ceil(brush.brushSize/2))
            love.graphics.line(brush.curLine)
            love.graphics.setColor(255,255,255)
            love.graphics.setBlendMode("alpha")
        love.graphics.setCanvas()
    elseif brush.isDown then
        love.graphics.setCanvas(paper)
            if brush.isErase then
                love.graphics.setBlendMode("replace")
                love.graphics.setColor(0,0,0,0)
            else
                love.graphics.setColor(brush.color)
            end
            love.graphics.circle('fill',x,y,math.ceil(brush.brushSize/2))
            love.graphics.setColor(255,255,255)
            love.graphics.setBlendMode("alpha")
        love.graphics.setCanvas()
    end
    brush.isDown = false
    brush.curLine = {}
    local mouseCaught = gooi.released()
    for _, tb in ipairs(app.textBoxes) do
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
    for _, tb in ipairs(app.textBoxes) do
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
    for _, tb in ipairs(app.textBoxes) do
        tb:moved(x, y, dx, dy)
    end
end

function love.touchreleased(id,x,y)
    brush.isDown = false
    brush.curLine = {}
    local touchCaught = gooi.released(id,x,y)
    for _, tb in ipairs(app.textBoxes) do
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