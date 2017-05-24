local Json = require("json")
require "torch"
local model_loader = require "model_loader"

local M = {}
local models = {}
local currentEffectIndex = 0
local targetEffectIndex = 0
local sequence = {}
local timer = torch.Timer()
local manual_mode = false
local user_change_timer = torch.Timer()
-- TODO: dynamic
local cooldown = 10

local function load_models(models_object)
  local model_paths = {}
  for _,v in pairs(models_object) do
    model_paths[v.name] = v.path
  end
  local models = {}
  for k,v in pairs(model_paths) do
    models[k] = model_loader.load_model(v)
  end

  return models
end

local function next_index(idx)
  return (idx + 1) % #sequence
end

local function init(fileName, sequence_name)
  local file = io.open(fileName, "r")
  if file then
    local content = file:read("*a")
    local lines = Json.decode(content)
    io.close(file)
    models = load_models(lines["models"])
    sequence = lines[sequence_name]
    targetEffectIndex = next_index(currentEffectIndex)
  end
end

local function set_manual_mode(is_manual_mode)
  manual_mode = is_manual_mode
  if is_manual_mode then
    timer:stop()
  else
    timer:resume()
  end
end

local function get_current()
  local currentEffect = sequence[currentEffectIndex+1]
  return models[currentEffect.name], currentEffect.fadeIn, currentEffect.duration, currentEffect.strength
end

local function get_next()
  local currentEffect = sequence[targetEffectIndex + 1]
  return models[currentEffect.name], currentEffect.fadeIn, currentEffect.duration, currentEffect.strength
end

local function go_to_next()
  timer:reset()
  currentEffectIndex = targetEffectIndex
  targetEffectIndex = next_index(targetEffectIndex)
  local currentEffect = sequence[currentEffectIndex+1]
  print("Moving to " .. currentEffect.name)
end

local function next()
  if is_manual_mode then
    go_to_next()
  else
    if user_change_timer:time().real < cooldown then
      print("denied next due to cooldown: " .. user_change_timer:time().real .. "/" .. cooldown)
      return
    end
    user_change_timer:reset()

    timer:stop()
    local _, _, duration = get_current()
    local _, fade_in = get_next()
    local curr_time = timer:time().real
    -- simple case: not in mid transition
    if curr_time <= duration then
      targetEffectIndex = next_index(targetEffectIndex)
      print("Target changed: " .. sequence[targetEffectIndex+1].name)
    elseif curr_time >= duration + fade_in then
      print("shouldn't be here")
      go_to_next()
    else
      -- tricky case: mid-blend, change the target
    end
    timer:resume()
    print("Moving to " .. "crap")
  end
end

local function user_next()
end

-- return [model 1, model 2, blend factor between model1 and model2 , blend factor of result with original camera feed]
local function get_models()
  local current, _, duration, strength = get_current()
  local next_model, fade_in, _, next_strength = get_next()
  local curr_time = timer:time().real
  if (not manual_mode) and (curr_time >= (duration + fade_in)) then
      go_to_next()
      return get_models()
  end

  -- simple case: only one model
  if (curr_time <= duration) then
    return current, current, 1.0, strength
  end

  -- complex case: blend between current and next
  local t = (curr_time - duration) / fade_in
  local factor = 1.0 - t
  
  if factor > 1.0 then
    factor = 1.0
  elseif factor < 0 then
    factor = 0
  end
  return current, next_model, factor, strength*factor + (1-factor)*next_strength
end

M.init = init
M.next = next
M.get_models = get_models
M.set_manual_mode = set_manual_mode
return M
