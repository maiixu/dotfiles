--- ChineseQuotes.spoon
--- Replaces " with 「」 when Chinese input method is active.
--- Opening 「 and closing 」 are toggled on each press.

local obj = {}
obj.__index = obj
obj.name = "ChineseQuotes"
obj.version = "1.0"

obj._open = true  -- next quote is opening (「) or closing (」)

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

-- Reset toggle to opening bracket whenever input source switches to Chinese
local function onSourceChange()
    if isChineseInput() then
        obj._open = true
    end
end

function obj:start()
    -- Intercept Shift + ' (the " key) in Chinese input mode
    self._tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
        if not isChineseInput() then return false end

        local keyCode = e:getKeyCode()
        local flags   = e:getFlags()

        -- key 39 = apostrophe/quote key; Shift makes it "
        if keyCode == 39 and flags.shift
            and not flags.cmd and not flags.ctrl and not flags.alt then
            local bracket = self._open and "「" or "」"
            self._open = not self._open
            hs.eventtap.keyStrokes(bracket)
            return true  -- consume original event
        end

        return false
    end)

    self._tap:start()
    self._sourceWatcher = hs.keycodes.inputSourceChanged(onSourceChange)
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
