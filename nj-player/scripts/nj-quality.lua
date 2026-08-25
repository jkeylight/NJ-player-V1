-- ============================================================
--  NJ PLAYER — video quality controls
--
--  During playback:
--    F2              picture menu (brightness / contrast /
--                    saturation / gamma / hue) — arrows + ENTER
--    F3              stream quality menu (web links only)
--    ALT+UP/DOWN     pick a picture parameter
--    ALT+LEFT/RIGHT  adjust it (+/- 5)
--    ALT+0           reset picture to neutral
--    ALT+B           toggle the NJ color boost
--
--  The same values are adjustable in the NJ Player GUI
--  (PICTURE button) and persist in ~~/.quality.txt
-- ============================================================

local mp    = require "mp"
local utils = require "mp.utils"
local msg   = require "mp.msg"

-- ------------------------------------------------------------
--  Picture parameters (mpv equalizer properties, -100..100)
--  Factory defaults = the classic NJ Player color boost.
-- ------------------------------------------------------------
local PARAMS = {
    { key = "brightness", label = "Brightness"  },
    { key = "contrast",   label = "Contrast"    },
    { key = "saturation", label = "Saturation"  },
    { key = "gamma",      label = "Gamma"       },
    { key = "hue",        label = "Hue"         },
}

local BOOST = { brightness = 5, contrast = 15, saturation = 20, gamma = 10, hue = 0 }
local values = { brightness = 5, contrast = 15, saturation = 20, gamma = 10, hue = 0 }

local STEP = 5

local function clamp(v) return math.max(-100, math.min(100, v)) end

-- ------------------------------------------------------------
--  Persistence — ~~/.quality.txt (shared with the GUI)
-- ------------------------------------------------------------
local function config_dir()
    local ok, dir = pcall(mp.commandv, "expand-path", "~~/")
    if ok and type(dir) == "string" and dir ~= "" then
        return (dir:gsub("[/\\]+$", ""))
    end
    return nil
end

local function quality_path()
    local dir = config_dir()
    if not dir then return nil end
    return utils.join_path(dir, ".quality.txt")
end

local function load_values()
    local path = quality_path()
    if not path then return end
    local fh = io.open(path, "r")
    if not fh then return end
    for line in fh:lines() do
        local k, v = line:match("^%s*([%a_]+)%s*=%s*(-?%d+)")
        if k and values[k] ~= nil then
            values[k] = clamp(tonumber(v) or 0)
        end
    end
    fh:close()
end

local function save_values()
    local path = quality_path()
    if not path then return end
    local fh = io.open(path, "w")
    if not fh then return end
    for _, p in ipairs(PARAMS) do
        fh:write(string.format("%s=%d\n", p.key, values[p.key]))
    end
    fh:close()
end

local function apply_values()
    for _, p in ipairs(PARAMS) do
        mp.set_property(p.key, values[p.key])
    end
end

local function is_boost_on()
    for _, p in ipairs(PARAMS) do
        if values[p.key] ~= BOOST[p.key] then return false end
    end
    return true
end

local function set_all(t)
    for _, p in ipairs(PARAMS) do
        values[p.key] = t[p.key] or 0
    end
    apply_values()
    save_values()
end

-- ------------------------------------------------------------
--  OSD overlay menu
-- ------------------------------------------------------------
local ov = mp.create_osd_overlay("ass-events")
ov.res_x = 1280
ov.res_y = 720
ov.z = 2000

local menu = nil          -- active menu state
local pending_seek = nil  -- resume position after a stream-quality switch

local C_ACCENT = "{\\c&HFFD400&}"   -- cyan #00D4FF (ASS colors are BGR)
local C_WHITE  = "{\\c&HFFFFFF&}"
local C_DIM    = "{\\c&H9A9AA5&}"
local C_FAINT  = "{\\c&H55555F&}"

local S_BASE = "{\\an7\\pos(90,140)\\fnConsolas\\bord2\\shad1\\3c&H000000&\\c&HFFFFFF&}"
local S_HDR  = "{\\fs34\\b1\\bord2\\shad1\\3c&H000000&}"
local S_HELP = "{\\fs20\\b0\\bord2\\shad1\\3c&H000000&}"
local S_ROW  = "{\\fs30\\b0\\bord2\\shad1\\3c&H000000&}"

local function ass_escape(s)
    return (tostring(s):gsub("[\\{}]", "\\%0"))
end

local function pad(s, n)
    s = tostring(s)
    return s .. string.rep(" ", math.max(0, n - #s))
end

local function fmt_val(v)
    return string.format("%+4d", v)
end

local function bar(v, w)
    v = clamp(v)
    local pos = math.floor((v + 100) / 200 * (w - 1) + 0.5)
    local t = {}
    for i = 0, w - 1 do
        t[#t + 1] = (i == pos) and "●" or "─"
    end
    return table.concat(t)
end

local function row_text(sel, text)
    local prefix = sel and (C_ACCENT .. "▸ ") or (C_WHITE .. "  ")
    return S_ROW .. prefix .. text
end

local function draw()
    if not menu then return end
    local L = {}
    local function add(s) L[#L + 1] = s end

    if menu.kind == "picture" then
        add(S_HDR .. C_DIM .. "NJ PLAYER" .. C_ACCENT .. "  ·  VIDEO QUALITY")
        add(S_HELP .. C_DIM .. "↑↓ select    ←→ adjust ±" .. STEP ..
            "    ENTER action    ESC close")
        add("")
        for i, p in ipairs(PARAMS) do
            local text = pad(p.label, 14) .. bar(values[p.key], 22) .. "  " .. fmt_val(values[p.key])
            add(row_text(menu.sel == i, text))
        end
        add(S_ROW .. C_FAINT .. "  " .. string.rep("─", 42))
        local actions = {
            pad("Color Boost", 15)    .. pad("5 / 15 / 20 / 10", 21) .. "  " .. (is_boost_on() and "ON" or "OFF"),
            pad("Reset Picture", 15)  .. pad("set all to 0", 21),
            pad("Stream Quality", 15) .. pad("links (F3)", 21)       .. "  ▸",
        }
        for i, a in ipairs(actions) do
            add(row_text(menu.sel == #PARAMS + i, a))
        end
    else
        local title = mp.get_property("media-title") or menu.url or ""
        if #title > 60 then title = title:sub(1, 57) .. "..." end
        add(S_HDR .. C_DIM .. "NJ PLAYER" .. C_ACCENT .. "  ·  STREAM QUALITY")
        add(S_HELP .. C_DIM .. ass_escape(title))
        add(S_HELP .. C_DIM .. "↑↓ select    ENTER switch    ESC close")
        add("")
        if menu.fetching then
            add(S_ROW .. C_WHITE .. "  Fetching available formats...")
        elseif menu.error then
            add(S_ROW .. C_WHITE .. "  Couldn't read formats.")
            add(S_ROW .. C_DIM .. "  (needs mpv\\yt-dlp.exe and a supported link)")
        else
            for i, it in ipairs(menu.items or {}) do
                add(row_text(menu.sel == i, pad(it.label, 12) .. (it.info or "")))
            end
        end
    end

    ov.data = S_BASE .. table.concat(L, "\\N")
    ov:update()
end

-- ------------------------------------------------------------
--  Menu plumbing
-- ------------------------------------------------------------
local menu_binds = {
    { "UP",    "up",    false },
    { "DOWN",  "down",  false },
    { "LEFT",  "left",  false },
    { "RIGHT", "right", false },
    { "ENTER", "enter", false },
    { "ESC",   "esc",   false },
}
local menu_fns = {}
local menu_bound = false

local function bind_menu_keys()
    if menu_bound then return end
    menu_bound = true
    for _, b in ipairs(menu_binds) do
        local key, name = b[1], "nj-quality-" .. b[2]
        if b[4] then
            mp.add_forced_key_binding(key, name, menu_fns[b[2]], b[4])
        else
            mp.add_forced_key_binding(key, name, menu_fns[b[2]])
        end
    end
end

local function unbind_menu_keys()
    if not menu_bound then return end
    menu_bound = false
    for _, b in ipairs(menu_binds) do
        mp.remove_key_binding("nj-quality-" .. b[2])
    end
end

local function close_menu()
    if not menu then return end
    menu = nil
    ov:remove()
    unbind_menu_keys()
end

local function item_count()
    if not menu then return 0 end
    if menu.kind == "picture" then return #PARAMS + 3 end
    if menu.fetching or menu.error or not menu.items then return 0 end
    return #menu.items
end

-- ------------------------------------------------------------
--  yt-dlp format parsing (stream quality)
-- ------------------------------------------------------------
local function format_score(f)
    local s = tonumber(f.tbr) or 0
    if tostring(f.vcodec or ""):find("avc1", 1, true) then s = s + 100000 end
    if tostring(f.ext or "") == "mp4" then s = s + 50000 end
    return s
end

local function parse_formats(info)
    if type(info) ~= "table" then return nil end
    if type(info.entries) == "table" and type(info.entries[1]) == "table" then
        info = info.entries[1]
    end
    local fmts = info.formats
    if type(fmts) ~= "table" then return nil end

    local best = {}
    for _, f in ipairs(fmts) do
        if type(f) == "table" then
            local h = tonumber(f.height)
            local vc = tostring(f.vcodec or "")
            if h and h > 0 and vc ~= "" and vc ~= "none" then
                local cur = best[h]
                if not cur or format_score(f) > format_score(cur) then
                    best[h] = f
                end
            end
        end
    end

    local heights = {}
    for h in pairs(best) do heights[#heights + 1] = h end
    table.sort(heights, function(a, b) return a > b end)

    local items = {}
    for _, h in ipairs(heights) do
        local f = best[h]
        local parts = {}
        local codec = tostring(f.vcodec or ""):match("^([%w]+)")
        if codec then parts[#parts + 1] = codec end
        local fps = tonumber(f.fps)
        if fps then parts[#parts + 1] = string.format("%gp", math.floor(fps + 0.5)) end
        local tbr = tonumber(f.tbr)
        if tbr then parts[#parts + 1] = string.format("%.0f kbps", tbr) end
        items[#items + 1] = {
            label  = string.format("%dp", h),
            height = h,
            info   = (#parts > 0) and ("  " .. table.concat(parts, " · ")) or "",
        }
    end
    if #items == 0 then return nil end

    table.insert(items, 1, { label = "Auto", height = nil, info = "  player default" })
    return items
end

local function fetch_formats()
    local dir = config_dir()
    local ytdlp = dir and utils.join_path(dir, "mpv/yt-dlp.exe") or "yt-dlp"
    local url = menu.url
    msg.info("fetching formats: " .. tostring(url))
    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = { ytdlp, "-J", "--no-playlist", url },
    }, function(ok, result)
        -- ignore stale callbacks (menu closed or URL changed meanwhile)
        if not menu or menu.kind ~= "stream" or menu.url ~= url then return end
        menu.fetching = false
        local items = nil
        if ok and type(result) == "table" and result.status == 0
           and type(result.stdout) == "string" and result.stdout ~= "" then
            local jok, json = pcall(utils.parse_json, result.stdout)
            if jok then items = parse_formats(json) end
        end
        if items then
            menu.items = items
            menu.sel = 1
        else
            menu.error = true
        end
        draw()
    end)
end

local function apply_stream_quality(item)
    local path = mp.get_property("path")
    if not path then return end
    local pos = mp.get_property_number("time-pos", 0) or 0
    local fmt
    if item.height then
        fmt = string.format(
            "bestvideo[height<=%d][ext=mp4]+bestaudio[ext=m4a]/" ..
            "bestvideo[height<=%d]+bestaudio/best[height<=%d]",
            item.height, item.height, item.height)
    else
        fmt = "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
    end
    close_menu()
    if pos > 2 then pending_seek = math.floor(pos) end
    mp.osd_message("NJ Player: switching to " .. item.label .. " ...", 2)
    mp.commandv("loadfile", path, "replace", "ytdl-format=" .. fmt)
end

local function open_stream_menu()
    local path = mp.get_property("path")
    if not path or not (path:find("^https?://") or path:find("^ytdl://")) then
        close_menu()
        mp.osd_message("NJ Player: Stream Quality works on web links (YouTube etc.)", 2.5)
        return
    end
    mp.commandv("script-message", "nj-menu-close")  -- close the right-click menu
    menu = { kind = "stream", sel = 1, url = path, fetching = true, items = nil, error = false }
    bind_menu_keys()
    draw()
    fetch_formats()
end

-- ------------------------------------------------------------
--  Menu actions
-- ------------------------------------------------------------
function menu_fns.up()          -- luacheck: ignore
    local n = item_count()
    if n == 0 then return end
    menu.sel = ((menu.sel - 2) % n) + 1
    draw()
end

function menu_fns.down()        -- luacheck: ignore
    local n = item_count()
    if n == 0 then return end
    menu.sel = (menu.sel % n) + 1
    draw()
end

function menu_fns.left()        -- luacheck: ignore
    if menu and menu.kind == "picture" and menu.sel >= 1 and menu.sel <= #PARAMS then
        local p = PARAMS[menu.sel]
        values[p.key] = clamp(values[p.key] - STEP)
        apply_values()
        save_values()
        draw()
    end
end

function menu_fns.right()       -- luacheck: ignore
    if menu and menu.kind == "picture" and menu.sel >= 1 and menu.sel <= #PARAMS then
        local p = PARAMS[menu.sel]
        values[p.key] = clamp(values[p.key] + STEP)
        apply_values()
        save_values()
        draw()
    end
end

function menu_fns.enter()       -- luacheck: ignore
    if not menu then return end
    if menu.kind == "picture" then
        local idx = menu.sel - #PARAMS
        if idx == 1 then
            if is_boost_on() then
                set_all({ brightness = 0, contrast = 0, saturation = 0, gamma = 0 })
            else
                set_all(BOOST)
            end
            draw()
        elseif idx == 2 then
            set_all({ brightness = 0, contrast = 0, saturation = 0, gamma = 0 })
            draw()
        elseif idx == 3 then
            open_stream_menu()
        end
    else
        local items = menu.items
        if items and items[menu.sel] then
            apply_stream_quality(items[menu.sel])
        end
    end
end

function menu_fns.esc()         -- luacheck: ignore
    close_menu()
end

-- mark arrow keys repeatable so holding them sweeps the value
menu_binds[1][4] = "repeatable"
menu_binds[2][4] = "repeatable"
menu_binds[3][4] = "repeatable"
menu_binds[4][4] = "repeatable"

local function toggle_picture_menu()
    if menu then
        close_menu()
    else
        mp.commandv("script-message", "nj-menu-close")  -- close the right-click menu
        menu = { kind = "picture", sel = 1 }
        bind_menu_keys()
        draw()
    end
end

-- ------------------------------------------------------------
--  Quick hotkeys (no menu needed)
-- ------------------------------------------------------------
local quick_idx = 1

local function quick_show(extra)
    local p = PARAMS[quick_idx]
    local s = p.label .. ": " .. fmt_val(values[p.key])
    if extra then s = s .. "  " .. extra end
    mp.osd_message("NJ Player: " .. s, 1.2)
    if menu then draw() end
end

mp.add_key_binding("F2", "menu", toggle_picture_menu)
mp.add_key_binding("F3", "stream", function() open_stream_menu() end)

mp.add_key_binding("alt+UP", "quick-prev", function()
    quick_idx = ((quick_idx - 2) % #PARAMS) + 1
    quick_show("ALT+←/→ adjust")
end)

mp.add_key_binding("alt+DOWN", "quick-next", function()
    quick_idx = (quick_idx % #PARAMS) + 1
    quick_show("ALT+←/→ adjust")
end)

mp.add_key_binding("alt+LEFT", "quick-down", function()
    local p = PARAMS[quick_idx]
    values[p.key] = clamp(values[p.key] - STEP)
    apply_values()
    save_values()
    quick_show()
end, "repeatable")

mp.add_key_binding("alt+RIGHT", "quick-up", function()
    local p = PARAMS[quick_idx]
    values[p.key] = clamp(values[p.key] + STEP)
    apply_values()
    save_values()
    quick_show()
end, "repeatable")

mp.add_key_binding("alt+0", "reset", function()
    set_all({ brightness = 0, contrast = 0, saturation = 0, gamma = 0 })
    mp.osd_message("NJ Player: picture reset to neutral", 1.5)
    if menu then draw() end
end)

mp.add_key_binding("alt+b", "boost", function()
    if is_boost_on() then
        set_all({ brightness = 0, contrast = 0, saturation = 0, gamma = 0 })
    else
        set_all(BOOST)
    end
    mp.osd_message("NJ Player: color boost " .. (is_boost_on() and "ON" or "OFF"), 1.5)
    if menu then draw() end
end)

-- ------------------------------------------------------------
--  Resume position after a stream-quality switch
-- ------------------------------------------------------------
mp.register_event("file-loaded", function()
    if pending_seek and pending_seek > 0 then
        mp.commandv("seek", tostring(pending_seek), "absolute")
    end
    pending_seek = nil
end)

-- ------------------------------------------------------------
--  Startup: apply saved (or factory) picture settings
-- ------------------------------------------------------------
load_values()
apply_values()

-- Let the right-click menu (nj-menu.lua) close this menu so the
-- two never fight over the arrow keys.
mp.register_script_message("nj-quality-close", function()
    close_menu()
end)
