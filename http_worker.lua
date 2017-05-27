local ipc = require 'libipc'

local M = {}

-- See examples/workqueue.lua for the complete listing
-- Create a named workqueue
local workers = nil
local q = nil
local worker_count = 2

local function request(url)
  q:write(url)
end

local function init()
   q = ipc.workqueue('my queue')
   -- Create 1 background worker that read from the named workqueue
   workers = ipc.map(worker_count, function()
     -- This function is not a closure, it is a totally clean Lua environment
     local ipc = require 'libipc'
     local http = require 'socket.http'
     -- Open the queue by name (the main thread already created it)
     local q = ipc.workqueue('my queue')
     repeat
       -- Read the next http url off the workqueue
       local url = q:read()
       if url then
         print(url)
         http.request(url)
       end
     until url == nil
     q:close()
   end)
end

local function close()
  for i=1,worker_count do
    q:write(nil)
  end

  if workers ~= nil then
    workers:join()
  end
  if q ~= nil then
    q:close()
  end
end

M.init = init
M.request = request
M.close = close
return M
