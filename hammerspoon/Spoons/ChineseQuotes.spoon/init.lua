--- ChineseQuotes.spoon
--- In Chinese input mode:
---   " → inserts 「」 with cursor placed between them
---   backspace immediately after → deletes both 「 and 」 together

local obj = {}
obj.__index = obj
obj.name = "ChineseQuotes"
obj.version = "1.2"

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
    self._justPaired = false

    self._tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
        local keyCode = e:getKeyCode()
        local flags   = e:getFlags()
        local noMod   = not flags.cmd and not flags.ctrl and not flags.alt

        -- Backspace (key 51): if we just inserted a pair, delete both
        if keyCode == 51 and noMod and self._justPaired then
            self._justPaired = false
            hs.eventtap.keyStroke({}, "forwarddelete")  -- delete 」 on the right
            return false  -- let the original backspace delete 「 on the left
        end

        -- Any other key clears the paired state
        self._justPaired = false

        if not isChineseInput() then return false end

        -- Shift + ' (key 39) = "
        if keyCode == 39 and flags.shift and noMod then
            hs.eventtap.keyStrokes("「」")
            hs.eventtap.keyStroke({}, "left")  -- move cursor between 「 and 」
            self._justPaired = true
            return true
        end

        return false
    end)

    self._tap:start()
    return self
end

function obj:stop()
    if self._tap then
        self._tap:stop()
        self._tap = nil
    end
    return self
end

return obj
