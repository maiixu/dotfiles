--- ChineseQuotes.spoon
--- In Chinese input mode:
---   " → inserts 「」 with cursor placed between them
--- In any mode:
---   backspace with cursor between 「」 → deletes both

local obj = {}
obj.__index = obj
obj.name = "ChineseQuotes"
obj.version = "2.0"

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

-- Returns the characters immediately before and after the cursor
-- via the macOS Accessibility API. Works in most native text fields.
local function charsAroundCursor()
    local focused = hs.axuielement.focusedElement()
    if not focused then return nil, nil end

    local value = focused:attributeValue("AXValue")
    local range  = focused:attributeValue("AXSelectedTextRange")

    if type(value) ~= "string" or type(range) ~= "table" then return nil, nil end

    -- range.location is a 0-indexed UTF-16 offset; BMP characters (including
    -- all common CJK chars) each occupy exactly 1 UTF-16 unit, so this equals
    -- their Unicode codepoint index.
    local pos = range.location

    -- Build a 1-indexed array of Unicode codepoints from the UTF-8 string
    local codepoints = {}
    for _, cp in utf8.codes(value) do
        table.insert(codepoints, cp)
    end

    local before = pos >= 1           and utf8.char(codepoints[pos])     or nil
    local after  = pos < #codepoints  and utf8.char(codepoints[pos + 1]) or nil

    return before, after
end

function obj:start()
    self._tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
        local keyCode = e:getKeyCode()
        local flags   = e:getFlags()
        local noMod   = not flags.cmd and not flags.ctrl and not flags.alt

        -- Backspace: delete both brackets if cursor sits between 「 and 」
        if keyCode == 51 and noMod then
            local before, after = charsAroundCursor()
            if before == "「" and after == "」" then
                hs.eventtap.keyStroke({}, "forwarddelete")  -- delete 」 on the right
                return false  -- let original backspace delete 「 on the left
            end
            return false
        end

        if not isChineseInput() then return false end

        -- Shift + ' (key 39) = " → insert pair with cursor in the middle
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

function obj:stop()
    if self._tap then
        self._tap:stop()
        self._tap = nil
    end
    return self
end

return obj
