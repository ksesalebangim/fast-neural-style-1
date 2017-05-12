Json = require("json")

local M = {}
local function loadSequence()
  local fileName = 'sequence.json'
  local file = io.open(fileName, "r")
  if file then
    local content = file:read("*a")
    local lines = Json.decode(content)
    io.close(file)
    return lines
  end
end

M.loadSequence = loadSequence;
