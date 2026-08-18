-- ============================================================
--  NJ PLAYER — enhancement preset switcher + resume control
--  Binds CTRL+0..3 to apply enhancement profiles and F9 to
--  cycle through them, with OSD feedback. CTRL+BACKSPACE clears
--  the resume position of just the current video.
-- ============================================================

local utils = require "mp.utils"

local PRESETS = {
    { profile = "nj-clean",  label = "Enhancement OFF" },
    { profile = "nj-lucid",  label = "Lucid (adaptive sharpen)" },
    { profile = "nj-cinema", label = "Cinema (full pipeline)" },
    { profile = "nj-anime",  label = "Anime4K" },
}

local idx = 1

local function apply_current()
    mp.commandv("apply-profile", PRESETS[idx].profile)
    mp.osd_message("NJ Player: " .. PRESETS[idx].label, 1.5)
end

-- F9 cycles through the presets
mp.add_key_binding("F9", "nj-cycle-preset", function()
    idx = idx % #PRESETS + 1
    apply_current()
end)

-- CTRL+0..3 jump straight to a preset
for i, preset in ipairs(PRESETS) do
    mp.add_key_binding("CTRL+" .. (i - 1), "nj-preset-" .. i, function()
        idx = i
        apply_current()
    end)
end

-- ------------------------------------------------------------
--  CTRL+BACKSPACE — clear the resume position of THIS video
--  Deletes this file's watch-later entry (identified by the
--  filename comment mpv writes with write-filename-in-watch-later-config)
--  and turns off save-position-on-quit for the rest of this session,
--  so quitting does not write a fresh position either.
-- ------------------------------------------------------------
local nj_suppress_save = false

local function nj_clear_resume()
    local path = mp.get_property("path")
    local cfg = mp.get_property("config-dir")
    local cleared = 0
    if path and cfg then
        local wl_dir = utils.join_path(cfg, "watch_later")
        local norm = function(s) return (s:gsub("\\", "/"):lower()) end
        local target = norm("# " .. path)
        local entries = utils.readdir(wl_dir)
        if entries then
            for _, name in ipairs(entries) do
                local file = utils.join_path(wl_dir, name)
                local fh = io.open(file, "r")
                if fh then
                    local first = fh:read("*l")
                    fh:close()
                    if first and norm(first) == target then
                        os.remove(file)
                        cleared = cleared + 1
                    end
                end
            end
        end
    end
    mp.set_property("save-position-on-quit", "no")
    nj_suppress_save = true
    if cleared > 0 then
        mp.osd_message("NJ Player: resume position cleared - this video restarts from the beginning", 2.0)
    else
        mp.osd_message("NJ Player: no resume position to clear", 1.5)
    end
end

mp.add_key_binding("ctrl+BS", "nj-clear-resume", nj_clear_resume)

-- Show the current preset in the OSD when playback starts, and restore
-- position saving once a NEW file loads (it stays off for the rest of the
-- session that used CTRL+BACKSPACE).
mp.register_event("file-loaded", function()
    if nj_suppress_save then
        mp.set_property("save-position-on-quit", "yes")
        nj_suppress_save = false
    end
    mp.osd_message("NJ Player: " .. PRESETS[idx].label, 1.2)
end)
