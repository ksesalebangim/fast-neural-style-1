local cv = require 'cv'
require 'cv.imgproc'
-- require 'cv.cudafilters'

require 'math'

require 'torch'
require 'nn'
require 'image'
require 'camera'

require 'qt'
require 'qttorch'
require 'qtwidget'

require 'fast_neural_style.ShaveImage'
require 'fast_neural_style.TotalVariation'
require 'fast_neural_style.InstanceNormalization'
local utils = require 'fast_neural_style.utils'
local preprocess = require 'fast_neural_style.preprocess'


local cmd = torch.CmdLine()

-- Model options
cmd:option('-models', 'models/instance_norm/candy.t7,models/instance_norm/la_muse.t7')
cmd:option('-height', 480)
cmd:option('-width', 640)

-- GPU options
cmd:option('-gpu', -1)
cmd:option('-backend', 'cuda')
cmd:option('-use_cudnn', 1)

-- Webcam options
cmd:option('-webcam_idx', 0)
cmd:option('-webcam_fps', 60)


local function main()
  local quit = false
  local manual_mode = false
  local manual_factor = 0
  local manual_timer = torch.Timer()

  local function keypress(k,n)
    if n == 'Key_N' then
      print('Next effect with cooldown')  
      return
    end
    -- Any key but the N key sets manual mode
    if not manual_mode then
      print('Key detected - Entering Manual Mode')
      manual_mode = true
    end
    manual_timer:reset()

    if n == 'Key_Escape' then
      print('escape detected!')
      quit=true
    elseif n == 'Key_Space' then
      print('Next effect')
    elseif n == 'Key_S' then
      print('Toggle Story mode')
      manual_mode = false
    elseif n == 'Key_P' then
      print('Take picture')
    elseif n == 'Key_Up' then
      print('Increase Effect ' .. manual_factor)
      manual_factor = math.min(manual_factor + 0.01, 1)
    elseif n == 'Key_Down' then
      print('Increase Reality ' .. manual_factor)
      manual_factor = math.max(manual_factor - 0.01, 0)
    else
      print(k,n)
    end
  end


  local opt = cmd:parse(arg)

  local dtype, use_cudnn = utils.setup_gpu(opt.gpu, opt.backend, opt.use_cudnn == 1)
  local opt_models = opt.models:split(',')
  local model_names = {opt_models[1], opt_models[2]}
  local models = {}
  -- load same model twice if onyl one provided
  if model_names[2] == nil then
    model_names[2] = model_names[1]
  end

  local preprocess_method = nil
  for _, checkpoint_path in ipairs(model_names) do
    print('loading model from ', checkpoint_path)
    local checkpoint = torch.load(checkpoint_path)
    local model = checkpoint.model
    model:evaluate()
    model:type(dtype)
    if use_cudnn then
      cudnn.convert(model, cudnn)
    end
    table.insert(models, model)
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
  end

  local preprocess = preprocess[preprocess_method]

  local camera_opt = {
    idx = opt.webcam_idx,
    fps = opt.webcam_fps,
    height = opt.height,
    width = opt.width,
  }
  local cam = image.Camera(camera_opt)
  local timer = torch.Timer()

  -- this requires GPU - move back to cv.GaussianBlur if cpu-only operation is needed
  --local gaussian_filter = cv.cuda.createGaussianFilter{srcType=cv.CV_32F, dstType=cv.CV_32F, ksize=3, sigma1=0.8}
  --local gaussian_filter = cv.cuda.createSobelFilter{cv.CV_32F, cv.CV_32F, 1, 1}
  local gaussian_filter = cv.GaussianBlur

  local timer = torch.Timer()

  local win = nil
  local listener = nil
  while not quit do
    -- Check if should return to manual mode (1 min of idle time)
    if(manual_mode and manual_timer:time().real > 60) then
       print('Idle detected - Entering Story Mode')
       manual_mode = false
    end
    -- Grab a frame from the webcam
    local img = cam:forward()
    image.hflip(img,img)
    -- Preprocess the frame
    local H, W = img:size(2), img:size(3)
    img = img:view(1, 3, H, W)
    local img_pre = preprocess.preprocess(img):type(dtype)

    -- Run the models
    local imgs_out = {}
    --[[
    for i, model in ipairs(models) do
      local img_out_pre = model:forward(img_pre)

      -- Deprocess the frame and show the image
      local img_out = preprocess.deprocess(img_out_pre)[1]:float()
      img = img:float()

      local ramp_time = 20 -- FADE IN/OUT TIME (SECONDS)
      local stay_time = 30 -- TIME ON/OFF (SECONDS)
      local max_strength = 0.8 -- how strong is the effect (0 is none, 1 is only effect)

      local current_time = timer:time().real % ((ramp_time + stay_time) * 2)
      local is_descending = (current_time > (ramp_time + stay_time))
      current_time = current_time %(ramp_time + stay_time)

      local alpha
      if current_time < ramp_time then
        alpha = current_time / ramp_time
      else
        alpha = 1
      end
      if is_descending then
        alpha = 1 - alpha
      end

      alpha = alpha * max_strength

      for i=1, 3 do
        --cv.GaussianBlur{src=img_out[i]:float(), ksize={7, 7}, sigmaX=0.8, dst=img_out[i], sigmaY=0.8 }
        cv.addWeighted {img_out[i], alpha, img[1][i], 1-alpha, 0, img_out[i]}
      end
      --cv.addWeighted {img_out, 0.5, img, 0.5, 0, img_out}
      table.insert(imgs_out, img_out)
    end
    --]]


    -- do linear blend
    local factor = (math.sin(timer:time().real / 3) + 1) * 0.5

    if(manual_mode) then
      factor = manual_factor
    end

    local blend_img = models[1]:forward(img_pre):mul(factor)
    blend_img:add(1 - factor, models[2]:forward(img_pre))
    -- Deprocess the frame
    --local img_out = preprocess.deprocess(blend_img)[1]:float()
    local img_out = preprocess.deprocess(blend_img)[1]
    
    for i=1, 3 do
      --cv.GaussianBlur{src=img_out[i]:float(), ksize={7, 7}, sigmaX=0.8, dst=img_out[i], sigmaY=0.8 }
      -- crashes because this is a tensor slice and not a contiguous tensor. fix :(
      -- https://github.com/VisionLabs/torch-opencv/issues/104
      --gaussian_filter:apply{src=img_out[i], dst=img_out[i]}
    end
    table.insert(imgs_out, img_out)

    local img_disp = image.toDisplayTensor{
      input = imgs_out,
      min = 0,
      max = 1,
      nrow = math.floor(math.sqrt(#imgs_out)),
    }

    if not win then
      -- On the first call use image.display to construct a window
      win = image.display(img_disp,1920,1080)
      -- make draw scale with bilinear filter
      win.painter:sethints("SmoothPixmapTransform")
      --listener = qt.QtLuaListener(win.window)
      qt.connect(win.window.listener, "sigKeyPress(QString,QByteArray,QByteArray)", keypress )

    else
      -- Reuse the same window
      win.image = img_out
      local size = win.window.size:totable()
      local qt_img = qt.QImage.fromTensor(img_disp)
      win.painter:image(0, 0, size.width, size.height, qt_img)
    end
    qt.doevents()
  end
  print("quitting")
  win.window:close()
  qt.qApp:quit()
end


main()
