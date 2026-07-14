local M = {}

M.defaults = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})
  vim.api.nvim_create_user_command("UltimateAI", function(command)
    M.run_subcommand(command.fargs[1])
  end, {nargs = "*"})
end

function M.run_subcommand(subcmd)
  if subcmd == "test" then
    M.test()
  elseif subcmd == "popup" then
    M.MyMenu()
  else
    print("Unknown command " .. (subcmd or ""))
  end
end

function M.test()
  print("Test passed successfully!")
end

function ShowPopup(opts, callback)
  local popup = require("plenary.popup")

  local Window_id

  local height = 20
  local width = 30
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

  Window_id = popup.create(opts, {
    title = "UltimateAI",
    highlight = "MyProjectWindow",
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
    callback = callback,
  })
end

function MyMenu()
  local opts = {}
  local cb = function(_, sel)
    print("it works")
  end
  ShowPopup(opts, cb)
end

function CloseMenu()
  vim.api.nvim_win_close(Win_id, true)
end


return M
