require 'gooi'
require 'utils.save'
require 'utils.load'
tween = require 'tween.tween'
textBox = require 'utils.textBox'
function love.load()
     app = {
        failedToLoad  = false,
        activeFile    = "untitled_",
        --unsaved       = true,
        samefile      = false,
        deleteTextBox = false,
        deleteNote    = false,
        pixelScale    = love.window.getPixelScale(),
        height        = love.graphics.getHeight(),
        width         = love.graphics.getWidth(),
        textBoxes = {
            id = 0
        },
        paper = love.graphics.newCanvas(),
        WHITE   = {255,255,255}
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
                        love.graphics.setCanvas(app.paper)
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
                    love.graphics.setCanvas(app.paper)
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
    |     controlS MENUS      |
    |                         |
    ===========================
    ]]
    controls = {
        width       = winW*0.25,
        height      = winH*0.5,
        x           = -winW*0.25,
        y           = 0,
        isShown     = false,
        tweenState  = "",
        menuStates  = {"brush","text","save"},
        state       = "brush",
        changeState = function(self, state)
            if state == "" then self.state = state; return end
            gooi.setGroupEnabled(self.state.."_controls", false)
            gooi.setGroupVisible(self.state.."_controls", false)
            self.state = state
            gooi.setGroupEnabled(self.state.."_controls", true)
            gooi.setGroupVisible(self.state.."_controls", true)
            if not self.isShown then
                self:show()
            end
        end,
        
        update  = function(self,dt)
            if self.tweens then
                for i = #self.tweens, 1, -1 do
                    local done = self.tweens[i]:update(dt)
                    if done then
                        if self.tweens[i].subject.rebuild then
                            if self.tweens[i].subject.type == "spinner" then
                                self.tweens[i].subject:rebuild()
                            end
                        end
                        table.remove(self.tweens,i)
                    end
                    if #self.tweens == 0 then
                        self.tweens = nil
                        self.isShown = ("Show" == self.tweenState)
                    end
                end
            end
        end,
        
        draw   = function(self)
            love.graphics.setColor(100,100,100)
            love.graphics.rectangle("fill",self.x,self.y,controls.width,controls.height)
            
            if self.state ~= "" then
                gooi.draw(self.state.."_controls")
            end
            gooi.draw("control_sidebar")
        end,
        
        hide = function(self)
            local sideBar   = gooi.getByGroup("control_sidebar")
            self.tweens     = {}
            self.tweenState = "Hide"
            for i = 1, #self.menuStates do
                local group = gooi.getByGroup(self.menuStates[i].."_controls")
                if self.state == self.menuStates[i] then
                    for i = 1, #group do
                        self.tweens[i] = tween.new(0.25, group[i], {x = -(self.width - group[i].x) }, "outCubic")
                    end
                else
                    for i = 1, #group do
                        group[i].x = -(self.width - group[i].x)
                    end
                end 
            end
            
            for i = 1, #sideBar do
                self.tweens[#self.tweens + 1] = tween.new(0.25, sideBar[i], {x = -(self.width - sideBar[i].x)}, "outCubic")
            end
            gooi.get("CloseMenuButton").text = ">"
            self.tweens[#self.tweens + 1] = tween.new(0.25, self, {x=-self.width}, "outCubic")
        end,
        
        show  = function(self)
            local sideBar = gooi.getByGroup("control_sidebar")
            self.tweens = {}
            self.tweenState = "Show"
            for i = 1, #self.menuStates do
                local group = gooi.getByGroup(self.menuStates[i].."_controls")
                if self.state == self.menuStates[i] then
                    for i = 1, #group do
                        self.tweens[#self.tweens + 1] = tween.new(0.25, group[i], {x = group[i].x + self.width}, "outCubic")
                    end
                else
                    for i = 1, #group do
                        group[i].x = group[i].x + self.width
                        if group[i].rebuild then group[i]:rebuild() end
                    end
                end                
            end
            
            for i = 1, #sideBar do
                self.tweens[#self.tweens + 1] = tween.new(0.25, sideBar[i], {x = sideBar[i].x + self.width}, "outCubic")
            end
            gooi.get("CloseMenuButton").text = "<"
            self.tweens[#self.tweens + 1] = tween.new(0.25, self, {x = 0}, "outCubic")
        end
    }
    
    
    --[[
    ----------------------------
    |                          |
    |       Text  Menu         |
    |                          |
    ----------------------------
    ]]
    
    controls.textMenu = gooi.newPanel("textcontrols", controls.x, controls.y, controls.width, controls.height, "grid 9x1", "text_controls")
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
        widgets[i].group = "text_controls"
        controls.textMenu:add(widgets[i])
    end
    gooi.setGroupEnabled("text_controls", false)
    gooi.setGroupVisible("text_controls", false)
    
    --[[
    ----------------------------
    |                          |
    |       Brush Menu         |
    |                          |
    ----------------------------
    ]]
    controls.brushMenu = gooi.newPanel("brushcontrols",controls.x,controls.y,controls.width,controls.height, "grid 9x1", "brush_controls")
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
        widgets[i].group = "brush_controls"
        controls.brushMenu:add(widgets[i])
    end
    
    --[[
    -----------------------------
    |                           |
    |         Save Menu         |
    |                           |
    -----------------------------
    ]]
    controls.saveMenu = gooi.newPanel("savecontrols", controls.x, controls.y, controls.width, controls.height, "grid 9x1", "save_controls")
    widgets = {
        gooi.newText("saveDirText",""),
        gooi.newButton("SaveButton", "Save"):setOrientation("center"):onRelease(function(c)      
                local dir = gooi.get("saveDirText").text
                if dir == "" and app.activeFile == "untitled_" then
                    popups:setState "save_as_unnamed"
                elseif activeFile ~= dir and dir ~= "" then 
                    popups:setState "confirm_overwrite"
                else
                    gooi.get("saveDirText").text = ""
                    save(dir, app.textBoxes, app.paper)
                end
            end),
        gooi.newButton("loadButton","Load"):setOrientation("center"):onRelease(function(c)
                local dir = gooi.get("saveDirText").text
                loadNotes(dir, app.paper, app)
            end)
    }
    do 
        local clear
        clear = gooi.newButton("clear_button", "clear all")
            :onRelease(function(c)
                popups:setState "confirm_paper_clear"
            end)
        clear.group = "save_controls"
        controls.saveMenu:add(clear, "8,1")
    end
    for i = 1,#widgets do
        widgets[i].group = "save_controls"
        controls.saveMenu:add(widgets[i])
    end
    gooi.setGroupEnabled("save_controls",false)
    gooi.setGroupVisible("save_controls",false)
    
    --[[
    -------------------------------
    |                             |
    |  control Selector Sidebar   |
    |                             |
    -------------------------------
    ]]
    local brushMenuButton, textMenuButton, saveMenuButton, closeMenuButton
    controls.controlSelector = gooi.newPanel("controlSelector",controls.x+controls.width,controls.y,controls.width/4,controls.height, "grid 7x1", "control_sidebar")
        :setRowspan(1,1,2)
        :setRowspan(3,1,2)
        :setRowspan(5,1,2)
    brushMenuButton = gooi.newButton("BrushMenuButton","b\nr\nu\ns\nh\n")
        :setDirection("vertical")
        :onRelease(function(c) controls:changeState("brush") end)
    brushMenuButton.group = "control_sidebar"
    
    textMenuButton = gooi.newButton("TextMenuButton","t\ne\nx\nt")
        :setDirection("vertical")
        :onRelease(function(c) controls:changeState("text") end)
    textMenuButton.group = "control_sidebar"
    
    saveMenuButton = gooi.newButton("SaveMenuButton","s\na\nv\ne")
        :setDirection("vertical")
        :onRelease(function(c) controls:changeState("save") end)
    saveMenuButton.group = "control_sidebar"
    
    toggleMenuButton = gooi.newButton("CloseMenuButton",">")
        :setDirection("veritcal")
        :onRelease(function(c)
            if controls.isShown then
                controls.isShown = false
                controls:hide()
            else
                controls.isShown = true
                controls:show()
            end
        end)
    toggleMenuButton.group = "control_sidebar"
    controls.controlSelector:add(brushMenuButton, "1,1")
    controls.controlSelector:add(textMenuButton, "3,1")
    controls.controlSelector:add(saveMenuButton, "5,1")
    controls.controlSelector:add(toggleMenuButton, "7,1")
    
    --[[ 
    =============================
    |                           |
    |		POPUP MENUS         |
    |                           |
    =============================
    ]]
    popups             = {}
    popups.width       = app.width/2
    popups.height      = 2*app.height/5
    popups.x           = app.width/2 - popups.width/2
    popups.y           = app.height/2 - popups.height/2
    popups.isShown     = false
    popups.state       = ""
    popups.alertText   = ""
    popups.setState = function(self, state)
        print(state)
        if state == "" then
            gooi.setGroupEnabled(self.state.."_popup", false)
            gooi.setGroupVisible(self.state.."_popup", false)
            self.state = state
            self.isShown = false
        elseif self.state == "" then
            self.state =  state
            print("enabling!")
            gooi.setGroupEnabled(self.state.."_popup", true)
            gooi.setGroupVisible(self.state.."_popup", true)
            self.isShown = true
        else
            gooi.setGroupEnabled(self.state.."_popup", false)
            gooi.setGroupVisible(self.state.."_popup", false)
            self.state = state
            gooi.setGroupEnabled(self.state.."_popup", true)
            gooi.setGroupVisible(self.state.."_popup", true)
            self.isShown = true
        end
        if popups.isShown then
            gooi.setGroupEnabled("brush_controls", false)
            gooi.setGroupEnabled("text_controls", false)
            gooi.setGroupEnabled("save_controls", false)
            gooi.setGroupEnabled("control_sidebar", false)
        else
            gooi.setGroupEnabled("brush_controls", true)
            gooi.setGroupEnabled("text_controls", true)
            gooi.setGroupEnabled("save_controls", true)
            gooi.setGroupEnabled("control_sidebar", true)
        end
    end
    popups.draw = function(self)
        if self.isShown and self.state ~= "" then
            love.graphics.setColor(50, 50, 50, 150)
            love.graphics.rectangle("fill",0,0,app.width,app.height)
            love.graphics.setColor(100,100,100)
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            love.graphics.setColor(255,255,255)
            gooi.draw(self.state.."_popup")
        end
    end
    
    --[[
    ------------------------------
    |                            |
    |      Alert     Popup       |
    |                            |
    ------------------------------
    ]]
    do
        local label, okay
        popups.alert = gooi.newPanel("alert", popups.x, popups.y, popups.width, popups.height, "grid 5x5", "alert_popup")
            :setRowspan(1, 1, 4)
            :setColspan(1, 1, 5)
        label = gooi.newLabel("alert_label", popups.alertText)
            :setOrientation("center")
        label.group = "alert_popup"
        
        okay  = gooi.newButton("alert_okay", "Okay")
            :onRelease(function(c)
                popups:setState("")
                gooi.get("alert_label").text = ""
            end)
        okay.group = "alert_popup"
        popups.alert:add(okay, "5,3")
        popups.alert:add(label, "1,1")
        gooi.setGroupEnabled("alert_popup", false)
    end
    
    --[[
    ------------------------------
    |                            |
    |    Confirm Clear Paper     |
    |                            |
    ------------------------------
    ]]
    do
        local yes, no, label
        popups.confirmClearPaper = gooi.newPanel("confirm_paper_clear", popups.x, popups.y, popups.width, popups.height, "grid 5x4", "confirm_paper_clear_popup")
            :setRowspan(1, 1, 4)
            :setColspan(1, 1, 4)
        label = gooi.newLabel("confirm_paper_clear_label", "Are you sure you want to delete these notes?")
            :setOrientation("center")
        label.group = "confirm_paper_clear_popup"
        popups.confirmClearPaper:add(label)

        yes = gooi.newButton("confirm_delete_notesconfirm_paper_clear_yes", "Yes")
            :onRelease(function(c)
                app.textBoxes = {}
                love.graphics.setCanvas(app.paper)
                    love.graphics.clear()
                love.graphics.setCanvas()
                popups:setState("")
            end)
        yes.group = "confirm_paper_clear_popup"
        popups.confirmClearPaper:add(yes,"5,1")
        
        no = gooi.newButton("confirm_paper_clear_no", "No")
            :onRelease(function(c)
                popups:setState("")
            end)
        no.group = "confirm_paper_clear_popup"
        popups.confirmClearPaper:add(no, "5,4")
        gooi.setGroupEnabled("confirm_paper_clear_popup", false)
    end
    
    --[[
    -------------------------------
    |                             |
    |      Confirm Overwrite      |
    |                             |
    -------------------------------
    ]]
    do
        local yes, no, label
        popups.confirmOverWrite = gooi.newPanel("confirm_overwrite", popups.x, popups.y, popups.width, popups.height, "grid 5x4", "confirm_overwrite_popup")
            :setRowspan(1, 1, 4)
            :setColspan(1, 1, 4)
        label = gooi.newLabel("confirm_overwrite_label", "Are you sure you want to overwrite these notes?")
            :setOrientation("center")
        label.group = "confirm_overwrite_popup"
        popups.confirmOverWrite:add(label)

        yes = gooi.newButton("confirm_overwrite_yes", "Yes")
            :onRelease(function(c)
                local dir = gooi.get("saveDirText").text
                gooi.get("saveDirText").text = ""
                save(dir, app.textBoxes, app.paper)
                popups:setState("")
            end)
        yes.group = "confirm_overwrite_popup"
        popups.confirmOverWrite:add(yes,"5,1")

        no = gooi.newButton("confirm_overwrite_no", "No")
            :onRelease(function(c)
                popups:setState("")
            end)
        no.group = "confirm_overwrite_popup"
        popups.confirmOverWrite:add(no, "5,4")
        gooi.setGroupEnabled("confirm_overwrite_popup", false)
    end
    
     --[[
    -------------------------------
    |                             |
    |       Save as Unnamed       |
    |                             |
    -------------------------------
    ]]
    do
        local yes, no, label
        popups.confirmOverWrite = gooi.newPanel("save_as_unnamed", popups.x, popups.y, popups.width, popups.height, "grid 5x4", "save_as_unnamed_popup")
            :setRowspan(1, 1, 4)
            :setColspan(1, 1, 4)
        label = gooi.newLabel("save_as_unnamed_label", "Are you sure you want to save unnamed notes?")
            :setOrientation("center")
        label.group = "save_as_unnamed_popup"
        popups.confirmOverWrite:add(label)

        yes = gooi.newButton("save_as_unnamed_yes", "Yes")
            :onRelease(function(c)
                save("", app.textBoxes, app.paper)
                popups:setState("")
            end)
        yes.group = "save_as_unnamed_popup"
        popups.confirmOverWrite:add(yes,"5,1")

        no = gooi.newButton("save_as_unnamed_no", "No")
            :onRelease(function(c)
                popups:setState("")
            end)
        no.group = "save_as_unnamed_popup"
        popups.confirmOverWrite:add(no, "5,4")
        gooi.setGroupEnabled("save_as_unnamed_popup", false)
    end
    
    --[[
    -------------------------------
    |                             |
    |    Confirm Delete Note      |
    |                             |
    -------------------------------
    ]]
    do
        local yes, no, label
        popups.confirmDeleteNotes = gooi.newPanel("confirm_delete_notes",app.width/4, app.height/8, app.width/2, 3*app.height/4, "grid 5x4", "confirm_delete_notes_popup")
            :setRowspan(1, 1, 4)
            :setColspan(1, 1, 4)
        label = gooi.newLabel("confirm_delete_notes_label", "Are you sure you want to delete these notes?")
            :setOrientation("center")
        label.group = "confirm_delete_notes_popup"
        popups.confirmDeleteNotes:add(label)

        yes = gooi.newButton("confirm_delete_notes_yes", "Yes")
            :onRelease(function(c)
                --Code for button here
                popups:setState("")
            end)
        yes.group = "confirm_delete_notes_popup"
        popups.confirmDeleteNotes:add(yes,"5,1")
        
        no = gooi.newButton("confirm_delete_notes_no", "No")
            :onRelease(function(c)
                popups:setState("")
            end)
        no.group = "confirm_delete_notes_popup"
        popups.confirmDeleteNotes:add(no, "5,4")
        gooi.setGroupEnabled("confirm_delete_notes_popup", false)
    end
    --popups.confirmOverWrite.layout.debug = true
    widgets = nil
end

function love.draw()
    love.graphics.draw(app.paper,0,0)    
    love.graphics.setColor(0,0,0)
    --love.graphics.print(love.timer.getFPS(),200,200)
    for i = 1, #app.textBoxes do
        app.textBoxes[i]:draw()
    end
    love.graphics.setColor(app.WHITE)
    controls:draw()
    popups:draw()
    love.graphics.setColor(app.WHITE)
    --gooi.draw("control_selector")
end

function love.update(dt)
    gooi.update(dt)
    brush:update(dt)
    for i = #app.textBoxes, 1, -1 do
        app.textBoxes[i]:update(dt)
        if app.textBoxes[i].remove then
            table.remove(app.textBoxes, i)
        end
    end
    controls:update(dt)
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
    local caught = false
    caught = gooi.pressed()
    for _, tb in ipairs(app.textBoxes) do
        if not caught then
            caught = tb:pressed()
        else
            tb.hasFocus = false
        end
    end

    if not ((controls.x < x and x < controls.width + controls.x ) and 
    (controls.y < y and y < controls.y + controls.brushMenu.h )) and 
    not caught and not popups.isShown then
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
        love.graphics.setCanvas(app.paper)
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
        love.graphics.setCanvas(app.paper)
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
    local caught = false 
    caught = gooi.released()
    for _, tb in ipairs(app.textBoxes) do
        if not caught then
            caught = tb:released()
        else
            tb.hasFocus = false
        end
        tb.isDragging = false
    end
    if not caught then
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

    if not ((controls.x < x and x < controls.width + controls.x ) and 
    (controls.y < y and y < controls.y + controls.brushMenu.h )) and 
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