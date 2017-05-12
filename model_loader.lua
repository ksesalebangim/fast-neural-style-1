require 'torch'
require 'nn'

-- TODO: real logic here (e.g. all the dir or parse some json config file)
--local model_paths = {"models/instance_norm/candy.t7","models/instance_norm/la_muse.t7", "models/instance_norm/udnie.t7"}
 local model_paths = {"../fast-neural-style/mymodels/5_30_8000/fireCropped2.t7","../fast-neural-style/mymodels/5_30_8000/windswirllines.t7", "../fast-neural-style/mymodels/5_30_8000/lizardhead.t7"}
local dtype = nil
local M = {}
local models = {}
-- +1 every next(), -1 every prev()
local offset = 0
local change_time = 0
-- NOTE: temporary calculation
-- cycle_length is amount of time in seconds per effect cycle
local cycle_length = 3*2*math.pi
-- cycle_factor is the amount to multiply input to sin() to get that behavior
local cycle_factor = 2*math.pi/cycle_length

local function next()
	offset = offset + 1
end

local use_cudnn = false


local preprocess_method = nil
local function load_model(checkpoint_path)
	print('loading model from ', checkpoint_path)
    local checkpoint = torch.load(checkpoint_path)
    local model = checkpoint.model
    model:evaluate()
    model:type(dtype)
    if use_cudnn then
      cudnn.convert(model, cudnn)
    end
    
    local this_preprocess_method = checkpoint.opt.preprocessing or 'vgg'
    if not preprocess_method then
      print('got here')
      preprocess_method = this_preprocess_method
      print(preprocess_method)
    else
      if this_preprocess_method ~= preprocess_method then
        error('All models must use the same preprocessing')
      end
    end
    return model
end


local function get_preprocess_method()
    return preprocess_method
end

local function init(data_type, cudnn)
    dtype = data_type
    use_cudnn = cudnn
    for _, checkpoint_path in ipairs(model_paths) do
        table.insert(models, load_model(checkpoint_path))
    end
end



M.next = next
M.load_model = load_model
M.init = init
M.get_preprocess_method = get_preprocess_method

return M
