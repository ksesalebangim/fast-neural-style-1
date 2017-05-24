require "string"
local json = require "json"
require "torch"
require "math"
local model_loader = require "model_loader"
local http_worker = require "http_worker"

local M = {}
local models = {}
local currentEffectIndex = 0
local targetEffectIndex = 0
local sequence = {}
local timer = torch.Timer()
local manual_mode = false

local current_fade = nil
local is_fading = false

local URL_BASE = "http://127.0.0.1:5000/"


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

-------- Sound handling functions


---- Low-level

local function sound_fade_in(name, duration)
  http_worker.request(string.format("%splaySound/%s.ogg/fadeIn/%d",URL_BASE, name, duration))
end

local function sound_play(name)
  sound_fade_in(name, 0)
end

local function sound_stop(name)
  http_worker.request(string.format("%sstopSound/%s.ogg",URL_BASE, name))
end

local function sound_fade_out(name, duration)
  http_worker.request(string.format("%sfadeOut/%s.ogg/fadeOut/%d",URL_BASE, name, duration))
end

local function sound_stop_all()
  http_worker.request(URL_BASE .. "stopAllSounds")
end
---- High-level

--------- Fade between effects --------

local function create_fade(src_index, dst_index)
  local src_effect = sequence[src_index + 1]
  local dst_effect = sequence[dst_index + 1]
  local fade = {
                src_name = src_effect.name,
                dst_name = dst_effect.name,
                src_model = models[src_effect.name],
                dst_model = models[dst_effect.name],
                src_strength = src_effect.strength,
                dst_strength = dst_effect.strength,
                dst_index = dst_index,
                duration = src_effect.duration,
                fade_time = dst_effect.fadeIn,
                next_fades = 0, -- for manual fade, how many will follow
               }

  return fade
end

local function fade_factor(fade)
  local t = timer:time().real
  if t < fade.duration then
    -- 100% first effect
    return 0
  end

  return math.min(1.0,  (t - fade.duration) / fade.fade_time)
end

local function is_fade_running(fade)
  return timer:time().real < (fade.duration + fade.fade_time)
end

local function is_fade_fading(fade)
  return timer:time().real >= fade.duration
end

local function is_fade_done(fade)
  return timer:time().real >= (fade.duration + fade.fade_time)
end

local function is_fade_manual(fade)
  return fade.next_fades > 0
end

local function next_index(idx)
  return (idx + 1) % #sequence
end

------ End of Fade -------

local function init(fileName, sequence_name)
  local file = io.open(fileName, "r")
  local content = file:read("*a")
  local lines = json.decode(content)
  io.close(file)
  models = load_models(lines["models"])
  sequence = lines[sequence_name]
  targetEffectIndex = next_index(currentEffectIndex)
  current_fade = create_fade(currentEffectIndex, targetEffectIndex)
  sound_stop_all()
end

local function set_manual_mode(is_manual_mode)
  manual_mode = is_manual_mode
  if manual_mode then
    timer:stop()
  else
    timer:resume()
  end
end

local function go_to_next()
  is_fading = false -- we just finished a fade
  timer:reset()
  --currentEffectIndex = targetEffectIndex
  -- make sure sound state makes sense
  if current_fade.src_name ~= current_fade.dst_name then
    sound_stop(current_fade.src_name)
  end
  sound_play(current_fade.dst_name)

  currentEffectIndex = current_fade.dst_index
  targetEffectIndex = next_index(currentEffectIndex)
  local currentEffect = sequence[currentEffectIndex+1]
  local next_fade = create_fade(currentEffectIndex, targetEffectIndex)
  -- if this is a regular effect transition, use next_fade as-is
  -- otherwise specially create the next fade to start immediately
  if (not manual_mode) and (current_fade.next_fades > 1) then
    print("Done with short manual fade, creating long manual fade")
    next_fade.duration = 0
    next_fade.next_fades = current_fade.next_fades - 1
  end
  current_fade = next_fade
  print("Moving to " .. currentEffect.name)
end

local function next()
  if manual_mode then
    print("manual next")
    go_to_next()
  else
    if is_fade_manual(current_fade) and is_fade_running(current_fade) then
      print("denied next due to manual fade (" .. current_fade.next_fades .. "): " 
            .. timer:time().real .. "/" .. current_fade.duration + current_fade.fade_time)
      return
    end

    timer:stop()
    if not is_fade_fading(current_fade) then
      print("User-Next: forcing fade startt")
      -- simple case - not fading.
      -- immediately start fading
      current_fade.duration = 0
      current_fade.next_fades = 1 -- mark as manual fade
    else
      print("User-Next: forcing double-fade")
      -- fix up current fade to be very fast, mark it so that an immediate-fade will start afterwards
      local factor = 1.0 - fade_factor(current_fade)
      current_fade.src_strength = current_fade.src_strength*factor + current_fade.dst_strength*(1 - factor)

      current_fade.duration = 0
      -- TODO: make a parameter 
      current_fade.fade_time = 1 -- 1 sec for initial fade 

      -- mark as manual, with one fade following it immediately
      current_fade.next_fades = 2

      -- (ugh) mark as not fading, so next get_models() will set up sound properly
      is_fading = false
    end
    timer:reset()
    timer:resume()
  end
end

-- return [model 1, model 2, blend factor between model1 and model2 , blend factor of result with original camera feed]
local function get_models()
  if is_fade_done(current_fade) then
    go_to_next()
    return get_models()
  end
  if (not is_fading) and is_fade_fading(current_fade) then
    -- start a sound fade since we just started fading
    is_fading = true
    local time_left = math.floor(
                        math.max(
                          0, 
                          current_fade.fade_time - (timer:time().real - current_fade.duration)
                          ) * 1000
                        )

    sound_fade_out(current_fade.src_name, time_left)
    sound_fade_in(current_fade.dst_name, time_left)
  end
  -- fade_factor returns 0 = src, 1 = dst,
  -- invert that for blend strength
  local factor = 1 - fade_factor(current_fade)
  return current_fade.src_model, current_fade.dst_model, factor, current_fade.src_strength*factor + current_fade.dst_strength*(1 - factor)
end

M.init = init
M.next = next
M.get_models = get_models
M.set_manual_mode = set_manual_mode
return M
