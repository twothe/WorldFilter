local defaultFrame = DEFAULT_CHAT_FRAME
local defaultWrite = DEFAULT_CHAT_FRAME.AddMessage
local log = function(text, r, g, b, group, holdTime)
  defaultWrite(defaultFrame, tostring(text), r, g, b, group, holdTime)
end

local hookChatFrame = function(frame)
  if (not frame) then return end
  
  local original = frame.AddMessage
  if (original) then
    frame.AddMessage = function(t, message, ...)
      if (WorldFilter_Enabled) then
        local found, _, channel = string.find(message, "^%[%d+. ([^%]]+)%]")
        if (found and channel) then
          channel = string.lower(channel)
          if ((channel == "world") or (channel == "trade")) then
            if (not WorldFilter_FindKeyword(message)) then
              return
            end  
          end
        end
      end
      original(t, message, unpack (arg))
    end
  else
    log("Tried to hook non-chat frame")
  end
end

function WorldFilter_FindKeyword(message)
  for pattern, _ in pairs(WorldFilter_KeyWords) do
    if (string.find(message, pattern)) then
      return true
    end
  end
  return false
end

function WorldFilter_OnLoad()
  this:RegisterEvent("VARIABLES_LOADED")

	-- Set up slash commands.
	SlashCmdList["WORLDFILTER"] = WorldFilter_CmdRelay
	SLASH_WORLDFILTER1 = "/wf"
	SLASH_WORLDFILTER2 = "/worldfilter"
end

local hookFunctions = function()
  hookChatFrame(ChatFrame1)
  hookChatFrame(ChatFrame2)
  hookChatFrame(ChatFrame3)
  hookChatFrame(ChatFrame4)
  hookChatFrame(ChatFrame5)
  hookChatFrame(ChatFrame6)
  hookChatFrame(ChatFrame7)
end

local initialize = function()
  WorldFilter_KeyWords = WorldFilter_KeyWords or {}
  WorldFilter_Enabled = WorldFilter_Enabled or true
  hookFunctions()
  
	log(string.format("WorldFilter loaded (%s)", (WorldFilter_Enabled and "enabled") or "disabled"))
end

-- Event handler.  Checks for non-WhoFrame /whos.
function WorldFilter_OnEvent()
	if (event == "VARIABLES_LOADED") then
    initialize()
	end
end

local commands = setmetatable({
  
  ["add"] = function(args)
    local found, _, keyword = string.find(args or "", "^%s*(%S+)")
    if (found) then
      WorldFilter_KeyWords[keyword] = true
      log(string.format("Added '%s' to list." , keyword))
    else
      log("/wf add <keyword> - add a keyword to the list.")
    end
  end,
  
  ["del"] = function(args)
    local found, _, keyword = string.find(args or "", "^%s*(%S+)")
    if (found) then
      if (WorldFilter_KeyWords[keyword]) then
        WorldFilter_KeyWords[keyword] = nil
        log(string.format("Removed '%s' from the list." , keyword))
      else
        log(string.format("'%s' is not on the list." , keyword))
      end
    else
      log("/wf del <keyword> - removes a keyword from the list.")
    end
  end,
    
  ["on"] = function(args)
    WorldFilter_Enabled = true
    log("WorldFilter enabled")
  end,
  
    
  ["off"] = function(args)
    WorldFilter_Enabled = false
    log("WorldFilter disabled")
  end,

  ["list"] = function()
    local keywords = {}
    log("Keywords on the list:")
    for keyword,_ in pairs(WorldFilter_KeyWords) do
      table.insert(keywords, keyword)
    end
    log(table.concat(keywords, ", "))
  end,
  
}, {
  __index = function()
    return function()
      log("WorldFilter - Filters World channel by keywords")
      log("Commands:")
      log("  /wf add <keyword> - add a keyword to the list.")
      log("  /wf del <keyword> - removes a keyword from the list.")
      log("  /wf list          - lists all keywords currently active.")
      log("  /wf on/off        - temporarily disables or re-enables World Filter.")
    end
  end
})

-- Command-line handler.  Passes to other functions.
function WorldFilter_CmdRelay(args)
	if args then
		_, _, cmd, subargs = string.find (args, "^%s*(%S-)%s(.+)$")
		if not cmd then
			cmd = args
		end
    commands[string.lower(cmd)](subargs)
	end
end
