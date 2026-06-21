local M = {}

local term = nil
local buf = nil
local job = nil

local width = 40
local height = 12

local function getImage(errors)
  local name = nil
  if errors == 0 then
    name = "noerror.jpg"
  elseif errors < 5 then
    name = "smallerror.jpg"
  elseif errors < 10 then
    name = "mediumerror.jpg"
  else
    name = "bigerror.jpg"
  end
  return vim.api.nvim_get_runtime_file("lua/catinurface/images/" .. name, false)[1]
end

local function getNumberOfErrors()
  local bufnr = vim.api.nvim_get_current_buf()

  return #vim.diagnostic.get(bufnr, {
    severity = vim.diagnostic.severity.ERROR
  })
end

local function updateImage()
  if buf == nil then return end
  if term == nil then return end
  if job then
    vim.fn.jobstop(job)
  end

  local num_errors = getNumberOfErrors()
  local image_path = getImage(num_errors)
  local cmd = string.format("chafa --size=%dx%d %s", width, height, vim.fn.expand(image_path))

  vim.api.nvim_chan_send(term, "\x1b[2J\x1b[3J\x1b[H")
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _)
      if data then
        vim.api.nvim_chan_send(term, table.concat(data, "\n"))
      end
    end,
  })
end

local function create_panel()
  buf = vim.api.nvim_create_buf(false, true)

  local ui = vim.api.nvim_list_uis()[1]

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = ui.height - height - 2, -- Adjust for statusline
    col = ui.width - width - 2,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    noautocmd = true
  }
  vim.api.nvim_open_win(buf, false, opts)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  term = vim.api.nvim_open_term(buf, {})

  updateImage()
end

local function close_panel()
  if buf == nil then return end
  vim.api.nvim_buf_delete(buf, { force = true })
  buf = nil
end

M.setup = function()
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    callback = function()
      if buf ~= nil then
        updateImage()
      end
    end
  })

  vim.keymap.set('n', '<leader>j', function()
    if buf == nil then
      create_panel()
    else
      close_panel()
    end
  end, { desc = "Toggle Cat In Your Face" })
end

return M
