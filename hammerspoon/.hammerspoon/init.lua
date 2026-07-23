-- Hammerspoon config.
--
-- Keep this file a table of contents: each capability lives in its own module
-- alongside it and is pulled in with require(). Modules are stowed individually
-- (see the `hammerspoon` package), so ~/.hammerspoon stays a real directory that
-- Hammerspoon can still write its own runtime files (Spoons/, console history)
-- into.

-- Start with Hammerspoon at login — speak-server is a background service the VM
-- depends on, so it should survive a reboot without anyone opening the app.
hs.autoLaunch(true)

-- speak-server: queued TTS over HTTP, so `speak` on the Azure VM plays here.
require("speak-server")

-- `open -g hammerspoon://reload` reloads the config from a terminal — handy from
-- a Claude Code session, where the menubar item isn't reachable.
hs.urlevent.bind("reload", function()
  hs.reload()
end)

hs.alert.show("Hammerspoon config loaded")
