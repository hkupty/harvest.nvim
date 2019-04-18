
-- [[
-- Sample dependency declaration
--{
--  {"vigemus/iron.nvim"},
--  {"inspect", repository = "luarocks"}
--}
-- ]]
local depstree = {}

depstree.newtree = function()
  return {
    _items = {},
    add = function(tree, items)
      for _, dep in ipairs(items) do
        local repository = dep.repository or "github"

        if tree._items[repository] == nil then
          tree._items[repository] = {}
        end

        table.insert(tree._items[repository], dep)
      end
    return tree
    end,
    process = function(tree, repo, process_fn)
      local ret = {}
      for key, val in pairs(tree._items[repo]) do
        if not tree._items[repo][key].processed then
          ret[key] = process_fn(key, val)
        end
        tree._items[repo][key].processed = true
      end
      return ret
    end
  }
end

return depstree
