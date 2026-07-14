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

function M.ShowPopup(opts, callback)
  local popup = require("plenary.popup")

  local Window_id

  local height = 20
  local width = 30
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
  local linemain =  math.floor(((vim.o.lines - height) / 2) - 1)
  local colmain = math.floor((vim.o.columns - width) / 2)

  Window_id = popup.create(opts, {
    title = "UltimateAI",
    highlight = "MyProjectWindow",
    line = linemain,
    col = colmain,
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
    callback = callback,
  })

  Window_id2 = popup.create(opts, {
    title = "UltimateAIsubwindow",
    highlight = "MyProjectWindow",
    line = linemain,
    col = colmain + width + 2,
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
    callback = callback,
  })

end

function M.MyMenu()
  local bufnr = vim.api.nvim_create_buf(true, true)

vim.system(
  { "ollama", "run", "mistral", "give me 10 random words" },
  { text = true },
  function(obj)
    if obj.stdout then
      local lines = vim.split(obj.stdout, "\n")
      vim.schedule(function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      end)
    end
  end
)
local opts = {}
  local cb = function(_, sel)
    print("it works")
  end
  M.ShowPopup(bufnr, cb)
end



return M
