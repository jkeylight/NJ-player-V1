-- ============================================================
--  NJ PLAYER — VLC-style right-click menu
--
--  RIGHT-CLICK the video to open it.
--    ↑/↓     move          ENTER   select / open submenu
--    →       open submenu  ←/ESC   back / close
--    right-click again     close
--
--  Covers the everyday VLC menu actions: play/pause, stop,
--  jump, speed, A-B loop, audio / video / subtitle tracks,
--  aspect ratio, deinterlace, snapshot, video adjustments
--  and media info.
-- ============================================================

local mp = require "mp"

-- ------------------------------------------------------------
--  OSD overlay (same look as the F2 quality menu)
-- ------------------------------------------------------------
local ov = mp.create_osd_overlay("ass-events")
ov.res_x = 1280
ov.res_y = 720
ov.z = 2100

local stack = nil      -- menu frame stack (nil = closed)
local info_timer = nil -- media-info auto-hide timer

local C_ACCENT = "{\\c&HFFD400&}"
local C_WHITE  = "{\\c&HFFFFFF&}"
local C_DIM    = "{\\c&H9A9AA5&}"
local C_FAINT  = "{\\c&H55555F&}"

local S_BASE = "{\\an7\\pos(90,140)\\fnConsolas\\bord2\\shad1\\3c&H000000&\\c&HFFFFFF&}"
local S_HDR  = "{\\fs34\\b1\\bord2\\shad1\\3c&H000000&}"
local S_HELP = "{\\fs20\\b0\\bord2\\shad1\\3c&H000000&}"
local S_ROW  = "{\\fs30\\b0\\bord2\\shad1\\3c&H000000&}"

-- forward declarations (assigned below, in dependency order)
local close_menu, pop_frame, show_media_info, bind_keys, unbind_keys

local function pad(s, n)
    s = tostring(s)
    return s .. string.rep(" ", math.max(0, n - #s))
end

local function ass_escape(s)
    return (tostring(s):gsub("[\\{}]", "\\%0"))
end

local function fmt_time(t)
    if not t or t <= 0 then return "0:00" end
    t = math.floor(t)
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = t % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

local function onoff(prop)
    return mp.get_property_bool(prop, false) and "ON" or "OFF"
end

-- ------------------------------------------------------------
--  Actions
-- ------------------------------------------------------------
local function act(fn)
    -- VLC-style: close the menu, then run the action
    return function()
        close_menu()
        fn()
    end
end

local aspect_label = "Original"

local function set_aspect(label, value)
    aspect_label = label
    mp.commandv("set", "video-aspect-override", value)
    mp.osd_message("NJ Player: aspect ratio " .. label, 1.5)
end

local function ab_status()
    local a = mp.get_property_number("ab-loop-a")
    local b = mp.get_property_number("ab-loop-b")
    if a and b then return "A-B" end
    if a then return "A " .. fmt_time(a) end
    return "off"
end

local function take_snapshot()
    mp.commandv("screenshot")
    mp.osd_message("NJ Player: snapshot saved", 1.5)
end

local function open_quality_menu()
    mp.commandv("script-binding", "nj-quality/menu")
end

local function open_stream_menu()
    mp.commandv("script-binding", "nj-quality/stream")
end

-- ------------------------------------------------------------
--  Submenu builders (fresh labels/status on every draw)
-- ------------------------------------------------------------
local function build_back()
    return { label = "◂ Back", status = "ESC", fn = function() pop_frame() end }
end

local function build_jump()
    return { title = "JUMP", items = {
        build_back(),
        { label = "- 5 min",  fn = act(function() mp.commandv("seek", "-300") end) },
        { label = "- 1 min",  fn = act(function() mp.commandv("seek", "-60") end) },
        { label = "- 10 sec", fn = act(function() mp.commandv("seek", "-10") end) },
        { label = "+ 10 sec", fn = act(function() mp.commandv("seek", "10") end) },
        { label = "+ 1 min",  fn = act(function() mp.commandv("seek", "60") end) },
        { label = "+ 5 min",  fn = act(function() mp.commandv("seek", "300") end) },
        { sep = true },
        { label = "Previous chapter", fn = act(function() mp.commandv("add", "chapter", "-1") end) },
        { label = "Next chapter",     fn = act(function() mp.commandv("add", "chapter", "1") end) },
        { sep = true },
        { label = "Previous in playlist", fn = act(function() mp.commandv("playlist-prev") end) },
        { label = "Next in playlist",     fn = act(function() mp.commandv("playlist-next") end) },
    } }
end

local SPEEDS = { 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0 }

local function build_speed()
    local cur = mp.get_property_number("speed", 1)
    local items = { build_back() }
    for _, v in ipairs(SPEEDS) do
        local label = (v == 1.0) and "Normal (1.00x)" or string.format("%.2fx", v)
        items[#items + 1] = {
            label  = label,
            status = (math.abs(cur - v) < 0.001) and "●" or "",
            fn     = act(function()
                mp.commandv("set", "speed", string.format("%.2f", v))
                mp.osd_message("NJ Player: speed " .. string.format("%.2fx", v), 1.5)
            end),
        }
    end
    return { title = "SPEED", items = items }
end

local function build_abloop()
    local pos = mp.get_property_number("time-pos") or 0
    return { title = "A-B LOOP", items = {
        build_back(),
        { label = "Set A point", status = fmt_time(pos),
          fn = act(function()
              mp.set_property("ab-loop-a", tostring(mp.get_property_number("time-pos") or 0))
              mp.osd_message("NJ Player: A-B loop A set", 1.5)
          end) },
        { label = "Set B point", status = fmt_time(pos),
          fn = act(function()
              mp.set_property("ab-loop-b", tostring(mp.get_property_number("time-pos") or 0))
              mp.osd_message("NJ Player: A-B loop B set", 1.5)
          end) },
        { label = "Clear loop", status = ab_status(),
          fn = act(function()
              mp.set_property("ab-loop-a", "no")
              mp.set_property("ab-loop-b", "no")
              mp.osd_message("NJ Player: A-B loop cleared", 1.5)
          end) },
    } }
end

local function build_audio()
    local vol  = string.format("%.0f", mp.get_property_number("volume", 100))
    local del  = mp.get_property_number("audio-delay", 0) or 0
    local dstr = string.format("%+.2fs", del)
    return { title = "AUDIO", items = {
        build_back(),
        { label = "Next audio track", status = "b", fn = act(function() mp.commandv("cycle", "audio") end) },
        { label = "Mute", status = onoff("mute"), fn = act(function() mp.commandv("cycle", "mute") end) },
        { label = "Volume down", status = vol, fn = act(function() mp.commandv("add", "volume", "-5") end) },
        { label = "Volume up",   status = vol, fn = act(function() mp.commandv("add", "volume", "5") end) },
        { sep = true },
        { label = "Audio delay down", fn = act(function() mp.commandv("add", "audio-delay", "-0.05") end) },
        { label = "Audio delay up",   fn = act(function() mp.commandv("add", "audio-delay", "0.05") end) },
        { label = "Reset audio delay", status = dstr, fn = act(function() mp.commandv("set", "audio-delay", "0") end) },
    } }
end

local ASPECTS = {
    { label = "Original", value = "no" },
    { label = "4:3",      value = "4:3" },
    { label = "16:9",     value = "16:9" },
    { label = "2.35:1",   value = "2.35:1" },
    { label = "1.85:1",   value = "1.85:1" },
}

local function build_aspect()
    local items = { build_back() }
    for _, a in ipairs(ASPECTS) do
        items[#items + 1] = {
            label  = a.label,
            status = (aspect_label == a.label) and "●" or "",
            fn     = act(function() set_aspect(a.label, a.value) end),
        }
    end
    return { title = "ASPECT RATIO", items = items }
end

local function build_video()
    return { title = "VIDEO", items = {
        build_back(),
        { label = "Fullscreen",    status = onoff("fullscreen"), fn = act(function() mp.commandv("cycle", "fullscreen") end) },
        { label = "Always on Top", status = onoff("ontop"),      fn = act(function() mp.commandv("cycle", "ontop") end) },
        { label = "Aspect Ratio",  status = aspect_label, sub = build_aspect },
        { label = "Deinterlace",   status = onoff("deinterlace"), fn = act(function() mp.commandv("cycle", "deinterlace") end) },
        { sep = true },
        { label = "Take Snapshot", status = "s", fn = act(take_snapshot) },
        { label = "Video Adjustments", status = "F2", fn = act(open_quality_menu) },
        { label = "Stream Quality",    status = "F3", fn = act(open_stream_menu) },
    } }
end

local function build_subs()
    local del  = mp.get_property_number("sub-delay", 0) or 0
    local dstr = string.format("%+.2fs", del)
    local sc   = mp.get_property_number("sub-scale", 1) or 1
    local sstr = string.format("x%.1f", sc)
    return { title = "SUBTITLES", items = {
        build_back(),
        { label = "Next subtitle track", status = "v", fn = act(function() mp.commandv("cycle", "sub") end) },
        { label = "Show subtitles", status = onoff("sub-visibility"),
          fn = act(function() mp.commandv("cycle", "sub-visibility") end) },
        { sep = true },
        { label = "Subtitle delay down", fn = act(function() mp.commandv("add", "sub-delay", "-0.5") end) },
        { label = "Subtitle delay up",   fn = act(function() mp.commandv("add", "sub-delay", "0.5") end) },
        { label = "Reset subtitle delay", status = dstr, fn = act(function() mp.commandv("set", "sub-delay", "0") end) },
        { sep = true },
        { label = "Subtitle size down", fn = act(function() mp.commandv("add", "sub-scale", "-0.1") end) },
        { label = "Subtitle size up",   fn = act(function() mp.commandv("add", "sub-scale", "0.1") end) },
        { label = "Reset subtitle size", status = sstr, fn = act(function() mp.commandv("set", "sub-scale", "1") end) },
    } }
end

local function build_top()
    local paused = mp.get_property_bool("pause", false)
    local speed  = string.format("%.2fx", mp.get_property_number("speed", 1))
    return { title = "NJ PLAYER", items = {
        { label = paused and "Play" or "Pause", status = "Space",
          fn = act(function() mp.commandv("cycle", "pause") end) },
        { label = "Stop", fn = act(function() mp.commandv("stop") end) },
        { sep = true },
        { label = "Jump",     status = "▸", sub = build_jump },
        { label = "Speed",    status = speed, sub = build_speed },
        { label = "A-B Loop", status = ab_status(), sub = build_abloop },
        { sep = true },
        { label = "Audio",     status = "▸", sub = build_audio },
        { label = "Video",     status = "▸", sub = build_video },
        { label = "Subtitles", status = "▸", sub = build_subs },
        { sep = true },
        { label = "Video Adjustments", status = "F2", fn = act(open_quality_menu) },
        { label = "Stream Quality",    status = "F3", fn = act(open_stream_menu) },
        { label = "Media Info", fn = act(show_media_info) },
    } }
end

-- ------------------------------------------------------------
--  Media info panel (auto-hides after 6 seconds)
-- ------------------------------------------------------------
show_media_info = function()
    local function g(name, def)
        local v = mp.get_property(name)
        if v == nil or v == "" then return def or "?" end
        return v
    end
    local w = mp.get_property_number("width", 0)
    local h = mp.get_property_number("height", 0)
    local fps = mp.get_property_number("container-fps") or mp.get_property_number("fps")
    local vcodec = g("video-codec", g("video-format"))
    local acodec = g("audio-codec-name")
    local title = g("media-title", g("filename"))
    local dur = fmt_time(mp.get_property_number("duration", 0))

    local L = {}
    local function add(s) L[#L + 1] = s end
    add(S_HDR .. C_DIM .. "NJ PLAYER" .. C_ACCENT .. "  ·  MEDIA INFO")
    add("")
    add(S_ROW .. C_WHITE .. pad("Title", 12) .. ass_escape(title))
    add(S_ROW .. C_WHITE .. pad("Duration", 12) .. dur)
    add(S_ROW .. C_WHITE .. pad("Video", 12) ..
        string.format("%s  %dx%d", vcodec, w, h) ..
        (fps and string.format("  %.2f fps", fps) or ""))
    add(S_ROW .. C_WHITE .. pad("Audio", 12) .. ass_escape(acodec))
    add(S_ROW .. C_WHITE .. pad("Container", 12) .. ass_escape(g("file-format")))

    ov.data = S_BASE .. table.concat(L, "\\N")
    ov:update()

    if info_timer then info_timer:kill() end
    info_timer = mp.add_timeout(6, function()
        info_timer = nil
        if not stack then ov:remove() end
    end)
end

-- ------------------------------------------------------------
--  Menu engine
-- ------------------------------------------------------------
local function current_frame()
    return stack[#stack].builder()
end

local function draw()
    if not stack then return end
    local frame = current_frame()
    local f = stack[#stack]

    local crumb = stack[1].title or "NJ PLAYER"
    for i = 2, #stack do crumb = crumb .. "  ·  " .. (stack[i].title or "") end

    local L = {}
    local function add(s) L[#L + 1] = s end
    add(S_HDR .. C_DIM .. crumb)
    add(S_HELP .. C_DIM .. "↑↓ select    ENTER open    ← back    ESC / right-click close")
    add("")

    for i, it in ipairs(frame.items) do
        if it.sep then
            add(S_ROW .. C_FAINT .. "  " .. string.rep("─", 40))
        else
            local sel = (f.sel == i)
            local status = it.status or ""
            local text = pad(it.label, 22) .. pad(status, 8) .. (it.hint or "")
            local prefix = sel and (C_ACCENT .. "▸ ") or (C_WHITE .. "  ")
            add(S_ROW .. prefix .. text)
        end
    end

    ov.data = S_BASE .. table.concat(L, "\\N")
    ov:update()
end

local function move(d)
    if not stack then return end
    local items = current_frame().items
    local n = #items
    if n == 0 then return end
    local f = stack[#stack]
    for _ = 1, n do
        f.sel = ((f.sel - 1 + d) % n) + 1
        if not items[f.sel].sep then break end
    end
    draw()
end

pop_frame = function()
    if not stack then return end
    if #stack > 1 then
        stack[#stack] = nil
        draw()
    else
        close_menu()
    end
end

local function activate(right_only)
    if not stack then return end
    local frame = current_frame()
    local f = stack[#stack]
    local it = frame.items[f.sel]
    if not it or it.sep then return end
    if it.sub then
        stack[#stack + 1] = { title = it.label, builder = it.sub, sel = 1 }
        draw()
    elseif it.fn and not right_only then
        it.fn()
    end
end

-- ------------------------------------------------------------
--  Key bindings (forced while the menu is open)
-- ------------------------------------------------------------
local menu_keys = {
    { "UP",         "up",     function() move(-1) end, "repeatable" },
    { "DOWN",       "down",   function() move(1) end,  "repeatable" },
    { "LEFT",       "left",   function() pop_frame() end },
    { "RIGHT",      "right",  function() activate(true) end },
    { "ENTER",      "enter",  function() activate(false) end },
    { "ESC",        "esc",    function() close_menu() end },
    { "MBTN_RIGHT", "rclick", function() close_menu() end },
}
local bound = false

bind_keys = function()
    if bound then return end
    bound = true
    for _, k in ipairs(menu_keys) do
        if k[4] then
            mp.add_forced_key_binding(k[1], "nj-menu-" .. k[2], k[3], k[4])
        else
            mp.add_forced_key_binding(k[1], "nj-menu-" .. k[2], k[3])
        end
    end
end

unbind_keys = function()
    if not bound then return end
    bound = false
    for _, k in ipairs(menu_keys) do
        mp.remove_key_binding("nj-menu-" .. k[2])
    end
end

close_menu = function()
    if not stack then return end
    stack = nil
    ov:remove()
    unbind_keys()
end

local function open_menu()
    if info_timer then info_timer:kill(); info_timer = nil end
    mp.commandv("script-message", "nj-quality-close")  -- never fight over keys
    stack = { { title = "NJ PLAYER", builder = build_top, sel = 1 } }
    bind_keys()
    draw()
end

local function toggle_menu()
    if stack then
        close_menu()
    else
        open_menu()
    end
end

-- right-click the video = VLC-style context menu
mp.add_key_binding("MBTN_RIGHT", "context-menu", toggle_menu)

-- let the quality menu (nj-quality.lua) close this menu
mp.register_script_message("nj-menu-close", function()
    close_menu()
end)
