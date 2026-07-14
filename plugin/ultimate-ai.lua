
vim.api.nvim_create_user_command("sayHello", function()
  require("ultimate-ai").say_hello()
end, {})
