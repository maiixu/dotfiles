--- ChineseQuotes.spoon
--- In Chinese input mode:
---   " → inserts 「」 with cursor placed between them
--- In any mode:
---   backspace with cursor between 「」 → deletes both brackets
---
--- Cursor context is detected by briefly selecting chars around the cursor
--- via Shift+arrow + Cmd+C, then restoring. Works in Electron and native apps.

local obj = {}
obj.__index = obj
obj.name = "ChineseQuotes"
obj.version = "3.0"

local function isChineseInput()
    local source = hs.keycodes.currentSourceID() or ""
    return source:find("SCIM")    ~= nil  -- Apple Pinyin / Simplified Chinese
        or source:find("TCIM")    ~= nil  -- Apple Traditional Chinese
        or source:find("sogou")   ~= nil  -- Sogou Pinyin
        or source:find("baidu")   ~= nil  -- Baidu IME
        or source:lower():find("chinese") ~= nil
        or source:lower():find("pinyin")  ~= nil
        or source:lower():find("cangjie") ~= nil
        or source:lower():find("wubi")    ~= nil
end

function obj:start()
    self._skipBackspace = 0

    self._tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
        local keyCode = e:getKeyCode()
        local flags   = e:getFlags()
        local noMod   = not flags.cmd and not flags.ctrl and not flags.alt

        -- Skip backspaces we re-inject ourselves
        if keyCode == 51 and self._skipBackspace > 0 then
            self._skipBackspace = self._skipBackspace - 1
            return false
        end

        -- Backspace: consume and check cursor context asynchronously
        if keyCode == 51 and noMod then
            self:_checkPairAndDelete()
            return true
        end

        if not isChineseInput() then return false end

        -- Shift + ' (key 39) = " → insert 「」 with cursor in the middle
        if keyCode == 39 and flags.shift and noMod then
            hs.eventtap.keyStrokes("「」")
            hs.eventtap.keyStroke({}, "left")
            return true
        end

        return false
    end)

    self._tap:start()
    return self
end

-- Read chars around cursor by selecting them and copying to clipboard.
-- Restores both cursor position and clipboard when done.
-- Calls back with (charBefore, charAfter).
function obj:_checkPairAndDelete()
    local saved = hs.pasteboard.getContents()

    -- 1. Select char to the right
    hs.eventtap.keyStroke({"shift"}, "right")

    hs.timer.doAfter(0.02, function()
        hs.eventtap.keyStroke({"cmd"}, "c")

        hs.timer.doAfter(0.02, function()
            local after = hs.pasteboard.getContents()
            -- Collapse selection → cursor back to original position
            hs.eventtap.keyStroke({}, "left")

            hs.timer.doAfter(0.01, function()
                -- 2. Select char to the left
                hs.eventtap.keyStroke({"shift"}, "left")

                hs.timer.doAfter(0.02, function()
                    hs.eventtap.keyStroke({"cmd"}, "c")

                    hs.timer.doAfter(0.02, function()
                        local before = hs.pasteboard.getContents()
                        -- Restore cursor to original position
                        hs.eventtap.keyStroke({}, "right")

                        -- Restore clipboard
                        hs.pasteboard.setContents(saved or "")

                        -- Act: delete pair or normal backspace
                        self._skipBackspace = 1
                        if before == "「" and after == "」" then
                            hs.eventtap.keyStroke({}, "forwarddelete")  -- delete 」
                            hs.eventtap.keyStroke({}, "delete")          -- delete 「
                        else
                            hs.eventtap.keyStroke({}, "delete")          -- normal backspace
                        end
                    end)
                end)
            end)
        end)
    end)
end

function obj:stop()
    if self._tap then
        self._tap:stop()
        self._tap = nil
    end
    return self
end

return obj
