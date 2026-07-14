local M = {}

function M.say_hello()
  print("Hello!")
end

vim.api.nvim_create_user_command("SayHello", M.say_hello, {})

return M
