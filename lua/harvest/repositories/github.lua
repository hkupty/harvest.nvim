local parallel = require("harvest.async")
local defaults = require("harvest.defaults")

local github = {
  context = parallel.new_context("github"),
}

local install_dir = function(dep)
   return defaults.install_dir .. "/" .. dep
end

local target_dir = function(dep)
   return defaults.neovim_dir .. "/start/"
end

local remote_url = function(dep)
   return "https://github.com/" .. dep ..".git"
end

github.fetch = function(dependency)
  local dep = dependency[1]
  return github.context:call{
    "ls", install_dir(dep)
  }:and_then{
    "cd",
    install_dir(dep),
    "&&",
    "git",
    "pull"
  }:recover{
    "git",
    "clone",
    remote_url(dep),
    install_dir(dep)
  }:and_then{
    "ln",
    "-sf",
    install_dir(dep),
    target_dir(dep)
  }
end

github.get_plugin_definition = function(dependency)
  local dep = dependency[1]
  local ret = loadfile(defaults.install_dir .. "/" .. dep .. "/plugin.lua")
  return ret() or {}
end


return github
