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
  { "ollama", "run", "mistral", "300 word short story" },
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

function M.stream_test_to_popup(prompt)
  prompt = prompt or "give me 100 random words"

  local bufnr = vim.api.nvim_create_buf(false, true)

  M.ShowPopup(bufnr, function(_, sel)
    print("Popup closed")
  end)

  -- Use curl to hit Ollama's HTTP API directly
  vim.system(
    {
      "curl",
      "-s",
      "-N",
      "http://localhost:11434/api/generate",
      "-d",
      vim.json.encode({
        model = "mistral",
        prompt = prompt,
        stream = true,
      }),
    },
    {
      text = true,
      stdout = function(err, data)
        if err or not data or data == "" then return end

        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(bufnr) then return end

          -- Ollama API streams lines of JSON: {"response": "word", "done": false}
          for _, raw_line in ipairs(vim.split(data, "[\r\n]", { plain = false })) do
            if raw_line ~= "" then
              local ok, json = pcall(vim.json.decode, raw_line)
              if ok and json and json.response then
                local token = json.response

                -- Split on newlines if the generated token contains line breaks
                local incoming_lines = vim.split(token, "[\r\n]", { plain = false })
                local line_count = vim.api.nvim_buf_line_count(bufnr)

                -- Append chunk to current buffer line
                local last_line = vim.api.nvim_buf_get_lines(bufnr, line_count - 1, line_count, false)[1] or ""
                local updated_last_line = last_line .. incoming_lines[1]
                vim.api.nvim_buf_set_lines(bufnr, line_count - 1, line_count, false, { updated_last_line })

                -- Handle multiline responses
                if #incoming_lines > 1 then
                  local rest_lines = {}
                  for i = 2, #incoming_lines do
                    table.insert(rest_lines, incoming_lines[i])
                  end
                  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, rest_lines)
                end
              end
            end
          end
        end)
      end,
    }
  )
end
return M
