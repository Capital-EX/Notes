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

save = function(dir, textBoxList, lineList)
    saveDir = love.filesystem.getSaveDirectory()
    love.filesystem.createDirectory(saveDir.."/"..dir)
    txt = saveTextBoxes(textBoxList)
    print(table.concat(txt,"\n"))
    print(saveDir, dir)
end