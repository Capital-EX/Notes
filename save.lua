saveTextBoxes = function(textBoxList)
    local saved = {}
    for k, tb in ipairs(textBoxList) do
        savePos  = "@pos{"..tb.x..","..tb.y.."}"
        saveText = "@text{"..tb.plainText.."}"
        saveWrap = "@wrap{"..tb.wrap.."}"
        saveFontSize = "@fontSize{"..tb.fontSize.."}"
        saved[#saved + 1]    = "@textBox{"..savePos..saveWrap..saveFontSize..saveText.."}"
    end
    return saved
end

saveLines = function(lineList)
    local saved = {}
    for k, line in ipairs(lineList) do
        saved[#saved + 1] = "@line{"..table.concat(line,',').."}"
    end
    return saved
end

save = function(dir, textBoxList, canvas)
    saveDir = love.filesystem.getSaveDirectory()
    dir = dir:gsub("[|\\*?:<>\"/]","")
    if not love.filesystem.exists(dir) then
        print"Making dir!"
        love.filesystem.createDirectory(dir)
    end
    
    textBoxFile, err = love.filesystem.newFile(dir.."/".."text.txt","w")
    txt = saveTextBoxes(textBoxList)
    if #txt == 0 then
       textBoxFile:write("") 
    end
    for k, textbox in ipairs(txt) do
        textBoxFile:write(textbox)
        textBoxFile:write('\n')
    end
    textBoxFile:close()
    --notePaperImg, err = love.filesystem.newFile(dir.."/".."paper.png","w")
    paperData = canvas:newImageData():encode("png",dir.."/".."paper.png")
    --notePaperImg:write(paperData)
    --notePaperImg:close()
    --print(table.concat(txt,"\n"))
    print(saveDir, dir)
end