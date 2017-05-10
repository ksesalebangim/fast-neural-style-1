require 'torch'
require 'nn'

-- TODO: real logic here (e.g. all the dir or parse some json config file)
local model_paths = {"models/instance_norm/candy.t7","models/instance_norm/la_muse.t7"}
local dtype = nil
local M = {}

local function next()

end

local use_cudnn = false

local function init(data_type, cudnn)
	dtype = data_type
	use_cudnn = cudnn
end

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


local function get_current_model()
	return model
end

local function get_preprocess_method()
	return preprocess_method
end


M.next = next
M.load_model = load_model
M.init = init
M.get_preprocess_method = get_preprocess_method

return M