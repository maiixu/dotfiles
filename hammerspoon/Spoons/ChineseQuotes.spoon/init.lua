--- ChineseQuotes.spoon
--- In Chinese input mode, pressing " inserts 「」 with cursor placed between them.

local obj = {}
obj.__index = obj
obj.name = "ChineseQuotes"
obj.version = "1.1"

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
    self._tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
        if not isChineseInput() then return false end

        local keyCode = e:getKeyCode()
        local flags   = e:getFlags()

        -- Shift + ' (key 39) = " → insert 「」 with cursor in the middle
        if keyCode == 39 and flags.shift
            and not flags.cmd and not flags.ctrl and not flags.alt then
            hs.eventtap.keyStrokes("「」")
            hs.eventtap.keyStroke({}, "left")
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
