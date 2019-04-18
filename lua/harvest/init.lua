depstree = require("harvest.depstree")
parallel = require("harvest.parallel")
repositories = require("harvest.repositories")

harvest = {}

harvest.dependencies = function(deps)
  return depstree.newtree():add(deps)
end


harvest.fetch_latest = function(deps_tree)
  local process_tree = {}
  for repo, def in repositories do
    deps_tree:process(repo, function(item)
      def.fetch(item)
      local definition = def.get_plugin_definition(item)
      if definition.dependencies ~= nil then
        deps_tree:add(definition.dependencies)
      end
      end)
  end
end





return harvest
