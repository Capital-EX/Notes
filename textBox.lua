require './utf8'
local textBox = {
    new = function(self, id, x, y, wrap, align, font)
        local tb      = {}

        tb.remove     = false
        tb.id         = id
        tb.font       = font or love.graphics.getFont()
        tb.fontHeight = tb.font:getHeight()

        tb.x          = x or 0
        tb.y          = y or 0
        tb.width      = wrap or tb.font:getWidth("m") * 5   --Defaults to 5 em of space
        tb.minHeight  = 5 * tb.fontHeight
        tb.height     = tb.minHeight
        tb.plainText  = text or ""

        tb.handleWidth  = 10 * love.window.getPixelScale()
        tb.handleHeight = 10 * love.window.getPixelScale()

        tb.isEditing    = false
        --tb.enabled    = false
        tb.hasFocus   = false
        tb.isDragging = false

        tb.wrap       =  tb.width
        tb.align      = align or "left"
        tb.padding    = {
            top    = 0,
            right  = 0,
            bottom = 0,
            left   = 0,
        }

        local _, wraps = tb.font:getWrap(tb.plainText,tb.wrap)

        tb.drawnText   = love.graphics.newText(tb.font)
        tb.drawnText:addf(tb.plainText, tb.wrap, tb.align,0,0)

        tb.trueIndex   = tb.plainText:len()                       --Where we are in the full string of plain text
        tb.wrapIndex   = #wraps == 0 and 0 or wraps[#wraps]:len() --Where we are in the current line of wrapped text
        tb.line        = 1

        tb.cursorX         = tb.font:getWrap(tb.plainText, tb.wrap)
        tb.cursorY         = tb.fontHeight * math.max(tb.line,1)

        tb.showCursor      = true
        tb.blinkDelay      = 0.5
        tb.blinkTimer      = 0

        return setmetatable(tb,{__index = self.meta})
    end

}
textBox.meta = {}
textBox.meta.roundToInt = function(n)
    return n > 0 and math.floor(n+0.5) or math.ceil(n-0.5)
end
textBox.meta.setText = function(self,text)
    self.drawnText:setf(text, self.wrap, self.align)
end

textBox.meta.draw = function(self)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.draw(self.drawnText,self.x,self.y)
    if self.showCursor then
        self:drawCursor()
    end
    love.graphics.rectangle("fill", self.width + self.x, self.height + self.y, self.handleWidth, self.handleHeight)
end

textBox.meta.drawCursor = function(self)
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(1)
    love.graphics.line(
        self.cursorX + self.x,
        self.cursorY + self.y,
        self.cursorX + self.x,
        self.cursorY + self.y - self.fontHeight
    )
    love.graphics.setLineStyle("rough")
end

textBox.meta.update = function(self, dt)
    if self.hasFocus then
        self.blinkTimer = self.blinkTimer + dt
        if self.blinkTimer > self.blinkDelay then
            self.showCursor = not self.showCursor
            self.blinkTimer = 0
        end
    else
        self.showCursor = false
        self.isEditing  = false
        self.isDraging  = false
    end
end

textBox.meta.updateCursor = function(self)
    local _, textWrap = self.font:getWrap(self.plainText, self.wrap)
    self.cursorX = self.font:getWidth(string.utf8sub(textWrap[self.line] or "", 0, self.wrapIndex))
    self.cursorY = self.line * self.fontHeight
    local _, lineCount = self.plainText:gsub("\n","")
    lineCount          = #textWrap + lineCount - (lineCount - #textWrap > 0 and lineCount - #textWrap or 0)
    print(lineCount * self.fontHeight, #textWrap)
    if lineCount * self.fontHeight > self.minHeight then
        self.height = lineCount * self.fontHeight
    else
        self.height = self.minHeight
    end
end

textBox.meta.keypressed = function(self, key)
    if self.isEditing then
        if key == "return" then
            self:onReturn(key)
        end
        if key == "backspace" and self.trueIndex > 0 then
        self:onBackspace(key)
        end
        if key == "left" then
            self:moveIndexLeft()
        end
        if key == "right" then
            self:moveIndexRight()
        end
        if key == "up" then
            self:moveIndexUp()
        end
        if key == "down" then
            self:moveIndexDown()
        end
        self.blinkTimer = 0
        self.showCursor = true
    end
end

textBox.meta.moveIndexLeft = function(self, isBS)
    if self.trueIndex - 1 < 0 then return end
        local textBehind = string.utf8sub(self.plainText, 0, self.trueIndex - 1)
        local _, wrapBehind = self.font:getWrap(textBehind,self.wrap)
        self.trueIndex = self.trueIndex - 1
        if (self.wrapIndex - 1 < 0 and self.trueIndex) or
        (self.wrapIndex - 1 == 0 and isBS and self.trueIndex ~= 0) then
            self.line      = self.line - 1
            self.wrapIndex = (wrapBehind[self.line] or ""):len()
        else
            self.wrapIndex = self.wrapIndex - 1
        end
    self:updateCursor()
end

textBox.meta.moveIndexRight = function(self)
    if self.trueIndex + 1 > self.plainText:len() then return end

    local nextWrapIndex = self.wrapIndex + 1
    local nextIndex     = self.trueIndex + 1
    local plainText     = self.plainText
    local _, textWrap   = self.font:getWrap(self.plainText,self.wrap)

    local line          = textWrap[self.line] or ""
    local nextCharInLine = string.utf8sub(line, nextWrapIndex, nextWrapIndex)
    local nextCharInText = string.utf8sub(plainText, nextIndex, nextIndex)
    local nextNextCharInText = string.utf8sub(plainText, nextIndex + 1, nextIndex + 1)

    if nextCharInLine == "" then                -- If there isn't a next char in the current line
        if nextCharInText == "\n" then          -- |::If the next char in text is newline =>
            self.trueIndex = self.trueIndex + 1 -- |::::Move true index right
            self.line      = self.line + 1      -- |::::Move down a line
            self.wrapIndex = 0                  -- |::::Set wrapped index to 0
        else                                    -- |::Else =>
            self.trueIndex = self.trueIndex + 1 -- |::::Move true index right
            self.line      = self.line + 1      -- |::::Move down a line
            self.wrapIndex = 1                  -- |::::Move in front of next char
        end                                     -- |
    else                                        -- Else
        if self.wrapIndex + 1 >= line:len() and -- |::If the next index is past cur line;
        self.line + 1 <= #textWrap and          -- |::And line-count is less than textwrap;
        nextNextCharInText ~= "\n" then         -- |::And the next next char is not a newline  =>
            self.line      = self.line + 1      -- |::::Move Down a line
            self.trueIndex = self.trueIndex + 1 -- |::::
            self.wrapIndex = 0                  -- |::::Set index to zero
        else                                    -- |::Else
            self.trueIndex = self.trueIndex + 1 -- |::::Move right
            self.wrapIndex = self.wrapIndex + 1
        end
    end
    self:updateCursor()
end

textBox.meta.moveIndexDown = function(self)

    local plainText    = self.plainText
    local _, textWrap  = self.font:getWrap(plainText,self.wrap)
    local _, lineCount = plainText:gsub("\n","")
    lineCount          = #textWrap + (lineCount - #textWrap > 0 and lineCount - #textWrap or 0)

    if self.line > math.max(lineCount,1) then return end  --If we can move down, leave function

    local thisLine    = textWrap[self.line] or ""
    local nextLine    = textWrap[self.line + 1] or ""
    local nextLineLen = nextLine:len()

    local wrapIndex   = self.wrapIndex
    local moveTo      = self.roundToInt(nextLineLen*self.cursorX/self.font:getWidth(nextLine))

    if tostring(moveTo) == "nan" then -- If moveTo is not a number then
        moveTo = 0                    -- |::Set moveTo to 0
    end

    if moveTo > nextLineLen then      -- If moveTo is past the line length
        moveTo = nextLineLen          -- |::set MoveTo equal to line length
    end

    local thisLineOffSet = string.utf8sub(thisLine, wrapIndex + 1, -1):len()                  --Find the off set within current line; ex: [(xx)|xxx] => offset of 2
    local nextLineOffSet = string.utf8sub(nextLine, 0, moveTo == "nan" and 1 or moveTo):len() --Find the off set within next line; ex: [xx|(xxx)] => offset of 3

    self.line = self.line + 1
    self.trueIndex = self.trueIndex + thisLineOffSet                                          -- Move forward by how many chars are ahead of us
    if string.utf8sub(plainText, self.trueIndex + 1, self.trueIndex + 1) == "\n" then         -- If the next char is a new line =>
        self.trueIndex = self.trueIndex + 1                                                   -- |::Move index for on more.
    end                                                                                       --
    self.trueIndex = self.trueIndex + nextLineOffSet                                          -- Move forward by how many characters are behind moveTo
    self.wrapIndex = moveTo                                                                   -- Set wrapped Index to where we moved to

    self:updateCursor()
end

textBox.meta.moveIndexUp = function(self)
    if self.line == 1 then return end --If we can't move up leave function

    local plainText      = self.plainText
    local _, textWrap    = self.font:getWrap(plainText,self.wrap)
    local thisLine       = textWrap[self.line] or ""
    local nextLine       = textWrap[self.line - 1] or ""

    local nextLineLen    = nextLine:len()

    local wrapIndex      = self.wrapIndex

    local moveTo         = self.roundToInt(nextLineLen*self.cursorX/self.font:getWidth(nextLine))

    if tostring(moveTo) == "nan" then  -- If moveTo is not a number then
        moveTo = 0                     -- |::Set moveTo to 0
    end

    if moveTo > nextLineLen then -- If moveTo is past the line length
        moveTo = nextLineLen     -- |::set MoveTo equal to line length
    end

    local thisLineOffSet = string.utf8sub(thisLine, 0, wrapIndex):len()                             --Find the off set within current line; ex: [xx|(xxx)] => offset of 3
    local nextLineOffSet = string.utf8sub(nextLine, moveTo == "nan" and 1 or moveTo + 1, -1):len()  --Find the off set within next line; ex: [(xx)|xxx] => offset of 2

    self.line = self.line - 1
    self.trueIndex = self.trueIndex - thisLineOffSet                           -- Move backwards by how many chars are behind us.
    if string.utf8sub(plainText, self.trueIndex, self.trueIndex) == "\n" then  -- If the next char is a newline =>
        self.trueIndex =self.trueIndex - 1                                     -- |::Move back one more.
    end                                                                        --
    self.trueIndex = self.trueIndex - nextLineOffSet                           -- Move backwards by how many chars are in front of new location.
    self.wrapIndex = moveTo                                                    -- Set wrapped index to moveTo.

    self:updateCursor()
end

textBox.meta.onReturn = function(self)
    local textBefore = string.utf8sub(self.plainText, 1, self.trueIndex)                     --Get text before the current |Plain Text Index| position
    local textAfter  = string.utf8sub(self.plainText, self.trueIndex+1,self.plainText:len()) --Get text after the current |Plain Text Index| position
    self.plainText   = table.concat{textBefore,'\n',textAfter}                               --concatenate table of text, update the |Plain Text|
    self.line        = self.line + 1                                                         --Increament |Cursor's line| position
    self.trueIndex   = self.trueIndex + 1                                                    --Increament |Cursor Index| for |Plain Text| (to account for the '\n' character)
    self.wrapIndex   = 0                                                                     --Rest |Cursor's Wrapped Index| to 1 (to account for the '\n' character)
    self:updateCursor()                                                                      --Update cursor position
    self:setText(self.plainText,self.wrap,self.align)                                        --Update display text
end

textBox.meta.onBackspace = function(self)
    local textBefore        = string.utf8sub(self.plainText, 0, self.trueIndex - 1)                    --Text before the index
    local textAfter         = string.utf8sub(self.plainText, self.trueIndex + 1, self.plainText:len()) --Text after the index
    self.plainText     = table.concat{textBefore,textAfter}                                            --Update the plainText string
    self:moveIndexLeft(true)                                                                           --Move cursor back one
    self:setText(self.plainText,self.wrap,self.align)                                                  --Update display text
end

textBox.meta.textinput = function(self, text)
    if self.isEditing then
        local textBefore  = string.utf8sub(self.plainText, 0, self.trueIndex)
        local textAfter   = string.utf8sub(self.plainText, self.trueIndex+1, -1)

        self.plainText    = table.concat{textBefore, text, textAfter}
        local _, textWrap = self.font:getWrap(self.plainText, self.wrap)
        print(textWrap[self.line])
        self.trueIndex    = self.trueIndex + 1
        self.wrapIndex    = self.wrapIndex + 1

        if self.wrapIndex > textWrap[self.line]:len() then
            self.line      = self.line + 1
            self.wrapIndex = 1
        end
        self:setText(self.plainText,self.wrapIndex, self.align)
        self:updateCursor()
    end
end

textBox.meta.pressed  = function(self,x,y)
    local mx = x or love.mouse.getX()
    local my = y or love.mouse.getY()
    if (mx > self.x + self.width and mx < self.x + self.width + self.handleWidth) and
    (my > self.y + self.height and my < self.y + self.height + self.handleHeight) then
        print("yo")
        self.isDragging = true
    end
    return self.isDragging
end

textBox.meta.moved = function(self,dx,dy)
    if self.isDragging then
        print("YO")
        self.x = self.x + dx
        self.y = self.y + dy
    end
end

textBox.meta.released = function(self, x, y)
    local mx = x or love.mouse.getX()
    local my = y or love.mouse.getY()
    if (mx > self.x and mx < self.x + self.width) and (my > self.y and my < self.y + self.height) then
        print(self.x,self.y)
        love.keyboard.setTextInput(true)
        self.hasFocus = true
        self.isEditing = true
        self.showCursor = true
        local line, char
        line, char = self:getTextCollide(mx,my)
        print("pre:", self.wrapIndex, self.trueIndex)
        if char == 0 and line == 0 then
            self.trueIndex = 0
            self.wrapIndex = 0
        else
            local lineDistance = line - self.line 
            if lineDistance > 0 then
                for i = 1, lineDistance do
                    self:moveIndexDown()
                end
            else
                for i = 1, math.abs(lineDistance) do
                    self:moveIndexUp()
                end
            end
            local charDistance = char - self.wrapIndex
            if charDistance > 0 then
                for i = 1, charDistance do
                    self:moveIndexRight()
                end
            else
                for i = 1, math.abs(charDistance) do
                    self:moveIndexLeft()
                end
            end
            print("post:", self.wrapIndex, self.trueIndex)
        end
    else
        self.hasFocus = false
    end
    self.isDragging = false
    return self.hasFocus
end

textBox.meta.getTextCollide = function(self, x, y)
    local _, textWrap  = self.font:getWrap(self.plainText,self.wrap)
    local _, lineCount = self.plainText:gsub("\n","")
    lineCount          = #textWrap + (lineCount - #textWrap > 0 and lineCount - #textWrap or 0)
    local line         =  math.ceil(lineCount * (y - self.y)/(lineCount*self.fontHeight))
    if line > lineCount then
        line = lineCount
    end
    if tostring(line) == "nan" then
        line = 0
    end
    local char
    if not textWrap[line] then
        char = 0
    else
        local loc = self.roundToInt(textWrap[line]:len()*(x - self.x)/self.font:getWidth(textWrap[line]))
        if loc > textWrap[line]:len() then
            loc = textWrap[line]:len()
        end
        char = loc 
    end

    return line, char
end
return textBox