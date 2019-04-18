local wrapper = [[collect(){
  mkdir -p $1
  echo "${@:2}" > $1/cmd
  "${@:2}" > $1/out 2> $1/err
  echo $? > $1/status-code
}; collect ]]

local async = {}

async.new_context = function(name)
  return {
    _name = name,
    _ix = 1,
    get_folder_name = function(ctx)
      local path = "/tmp/harvest.nvim/" .. ctx._name .. "-" .. ctx._ix .. "/"
      ctx:inc_ix()
      return path
    end,
    inc_ix = function(ctx)
      ctx._ix = ctx._ix + 1
    end,
    call = function(this, cmd)
      return async.call(this, cmd)
    end
  }
end

async.call = function(ctx, cmd)
  local folder_name = ctx:get_folder_name()
  io.popen(wrapper .. folder_name .. ' ' .. table.concat(cmd, " "))

  return {
    name = folder_name,
    _status = nil,
    status = function(this)
      if not this._status then
        this._status = io.popen("cat " .. folder_name .. "status-code"):read()
      end

      return this._status
    end,
    routine = coroutine.create(function()
      while true do
        local ret = io.popen("cat " .. folder_name .. "status-code 2>/dev/null || echo not"):read()
        if ret ~= "not" then
          return ret
        end
        coroutine.yield()
      end
    end),
    and_then = function(this, new_cmd)
      return async.and_then(ctx, this, new_cmd)
    end,
    recover = function(this, new_cmd)
      return async.recover(ctx, this, new_cmd)
    end,
    realize = function(this)
      while true do
        local alive, status = coroutine.resume(this.routine)
        if status == "0" or (not alive and this:status() == "0") then
          return true
        elseif alive and status == nil then
          return nil
        end
      end

    end
  }
end

async.and_then = function(ctx, old, cmd)
  if old:realize() then
    return async.call(ctx, cmd)
  end
  return old
end

async.recover = function(ctx, old, cmd)
  if not old:realize() then
    return async.call(ctx, cmd)
  end
  return old
end

async.collect = function(coroutines)
  local returned = {}
  local waiting_queue = {}

  for _, crt in ipairs(coroutines) do
    table.insert(waiting_queue, crt)
  end

  while #waiting_queue > 0 do
    for ix, crt in ipairs(waiting_queue) do
      local alive, status = coroutine.resume(crt.routine)
      if status ~= nil then
        table.remove(waiting_queue, ix)
        returned[crt.name] = (status == "0")
      elseif not alive then
        table.remove(waiting_queue, ix)
      end
    end
  end

  return returned
end

return async
