local M = {}

M.defaults = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})
  vim.api.nvim_create_user_command("Prompt", function(prompt) M.MyPrompt(prompt.args)end, {})
  vim.api.nvim_create_user_command("UltimateAI", function(command)
    M.run_subcommand(command.fargs[1])
  end, {nargs = "*"})
end

function M.run_subcommand(subcmd)
  if subcmd == "test" then
    M.test()
  elseif subcmd == "popup" then
    M.stream_test_to_popup()
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
    line = linemain +height + 2,
    col = colmain,
    minwidth = width,
    minheight = 5,
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

function M.MyPrompt(prompt)
  local bufnr = vim.api.nvim_create_buf(true, true)

vim.system(
  { "ollama", "run", "mistral", prompt },
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

function M.stream_test_to_popup(cmd_args)
  -- 1. Create an unlisted, scratch buffer for the popup output
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- 2. Open the popup with the newly created buffer
  M.ShowPopup(bufnr, function(_, sel)
    print("Popup closed")
  end)

  -- Default command fallback adapted for Windows vs Unix
  if not cmd_args then
    if vim.fn.has("win32") == 1 then
      -- Windows PowerShell test loop
      cmd_args = { "powershell", "-Command", "1..10 | ForEach-Object { Write-Output \"Streaming chunk $_...\"; Start-Sleep -Milliseconds 200 }" }
    else
      -- Unix/Linux/macOS sh test loop
      cmd_args = { "sh", "-c", "for i in $(seq 1 10); do echo \"Streaming chunk $i...\"; sleep 0.2; done" }
    end
  end

  local partial_line = ""

  -- 3. Run the async job with streaming stdout enabled
  vim.system(
    cmd_args,
    {
      text = true,
      stdout = function(err, data)
        if err or not data then return end

        local content = partial_line .. data
        local lines = vim.split(content, "[\r\n]+", { trimempty = false })

        partial_line = lines[#lines]
        table.remove(lines, #lines)

        if #lines > 0 then
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
              local line_count = vim.api.nvim_buf_line_count(bufnr)
              
              if line_count == 1 and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == "" then
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
              else
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
              end
            end
          end)
        end
      end,
    },
    function(obj)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) and partial_line ~= "" then
          vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { partial_line })
        end
      end)
    end
  )
end
return M
