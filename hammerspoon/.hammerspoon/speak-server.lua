-- speak-server — queued text-to-speech over HTTP, for remote Claude Code sessions.
--
-- The Azure VM has no audio stack, so `speak` there POSTs text to this server
-- over Tailscale and this Mac does the talking. Requests are queued, so two
-- dictations fired back to back play one after the other rather than on top of
-- each other.
--
--   POST /speak   body = the text to speak   → queued, spoken in order
--   POST /stop    body ignored, but must be   → clears the queue, kills playback
--                 non-empty: a bodyless POST
--                 is 400'd by the underlying
--                 server before we see it
--
-- Security: this server executes nothing. The request body is written to a temp
-- file and handed to /usr/bin/say as a file argument via hs.task, which takes an
-- argv array — no shell is involved, so no request can inject a command, and no
-- path or program name from a request is ever honoured. The whole exposure is
-- "anyone who can reach port 8722 can make this Mac talk", and reachability is
-- gated by Tailscale. If the tailnet ever holds nodes beyond this Mac and the
-- VM, add a Tailscale ACL restricting port 8722 to just those two machines.

local M = {}

local PORT = 8722
local RATE = "195"

-- nil means "pass no -v flag", so `say` uses the Mac's System Voice (System
-- Settings → Accessibility → Spoken Content). That is deliberate: the Siri
-- voices are the best ones available AND the only ones `say` cannot address by
-- name — they never appear in `say -v '?'` — so naming any voice here would
-- silently downgrade a Siri voice to a stock one. Set this to a name from
-- `say -v '?'` only if you want to pin a specific voice regardless.
local VOICE = nil

local queue = {}
local speaking = false

local function speakNext()
  if speaking or #queue == 0 then
    return
  end
  speaking = true

  local text = table.remove(queue, 1)
  local tmp = os.tmpname()
  local f = io.open(tmp, "w")
  if not f then
    speaking = false
    hs.printf("speak-server: could not write temp file %s", tmp)
    return
  end
  f:write(text)
  f:close()

  local args = { "-r", RATE, "-f", tmp }
  if VOICE then
    table.insert(args, 1, VOICE)
    table.insert(args, 1, "-v")
  end

  hs.task.new("/usr/bin/say", function()
    os.remove(tmp)
    speaking = false
    speakNext()
  end, args):start()
end

-- No setInterface() call: the default is every interface, which is what lets the
-- VM reach this over the tailnet. Naming an interface would pin it to one NIC.
M.server = hs.httpserver.new(false, false)
M.server:setPort(PORT)
M.server:setCallback(function(method, path, _headers, body)
  if method == "POST" and path == "/speak" and body and #body > 0 then
    table.insert(queue, body)
    speakNext()
    return "queued", 200, {}
  elseif method == "POST" and path == "/stop" then
    queue = {}
    hs.execute("killall say")
    speaking = false
    return "stopped", 200, {}
  end
  return "not found", 404, {}
end)
M.server:start()

hs.printf("speak-server: listening on %d (voice: %s)", PORT, VOICE or "System Voice")

return M
