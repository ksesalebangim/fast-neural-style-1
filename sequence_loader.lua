local Json = require("json")
require "torch"
local model_loader = require "model_loader"

local M = {}
local models = {}
local currentEffectIndex = 0
local sequence = {}
local timer = torch.Timer()

local function loadModels(modelsObject)
  local model_paths = {}
  for _,v in pairs(modelsObject) do
    model_paths[v.name] = v.path
  end
  local models = {}
  for k,v in pairs(model_paths) do
    models[k] = model_loader.load_model(v)
  end

  return models
end

local function init(fileName)
  if not fileName then
    fileName = 'sequence.json'
  end
  local file = io.open(fileName, "r")
  if file then
    local content = file:read("*a")
    local lines = Json.decode(content)
    io.close(file)
    models = loadModels(lines["models"])
    sequence = lines["sequence"]
  end
end

local function next()
  timer:reset()
  currentEffectIndex = (currentEffectIndex+1) % #sequence
  local currentEffect = sequence[currentEffectIndex+1]
  print("Moving to " .. currentEffect.name)
end

local function getCurrent()
  local currentEffect = sequence[currentEffectIndex+1]
  return models[currentEffect.name], currentEffect.fadeIn, currentEffect.duration, currentEffect.strength
end

local function getNext()
  local currentEffect = sequence[((currentEffectIndex + 1) % #sequence) + 1]
  return models[currentEffect.name], currentEffect.fadeIn, currentEffect.duration, currentEffect.strength
end

-- return [model 1, model 2, blend factor between model1 and model2 , blend factor of result with original camera feed]
local function get_models()
    local current, _, duration, strength = getCurrent()
    local next_model, fade_in, _, next_strength = getNext()
    local curr_time = timer:time().real
    if (curr_time > (duration + fade_in)) then
        next()
        return get_models()
    end 

    -- simple case: only one model
    if (curr_time <= duration) then
	return current, current, 1.0, strength
    end

    -- complex case: blend between current and next
    local t = (curr_time - duration) / fade_in
    local factor = 1.0 - t
     return current, next_model, factor, strength*factor + (1-factor)*next_strength
end

M.init = init
M.next = next
M.get_models = get_models
return M
