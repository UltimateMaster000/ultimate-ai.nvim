local M = {}

M.defaults = {}

function M.setup(opts)
  print("hello from setup")
  M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})
  vim.api.nvim_create_user_command("sayHello", function()
    M.say_hello()
  end, {})
end

function M.say_hello()
  print("Hello!")
end


return M
