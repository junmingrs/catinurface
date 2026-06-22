local M = {}

local term = nil
local buf = nil
local job = nil

local default_opts = {
  width = 40,
  height = 12,
  threshold = {
    [0] = "lua/catinurface/images/no.jpg",
    [1] = "lua/catinurface/images/small.jpg",
    [5] = "lua/catinurface/images/medium.jpg",
    [10] = "lua/catinurface/images/big.jpg",
  }
}

local config = vim.deepcopy(default_opts)

local function resolve_path(path)
  path = vim.fn.expand(path)
  if vim.startswith(path, "/") then
    return path
  end
  return vim.api.nvim_get_runtime_file(path, false)[1]
end

local function getImage(errors)
  local best_threshold = -math.huge
  for t, _ in pairs(config.threshold) do
    if t <= errors and t > best_threshold then
      best_threshold = t
    end
  end
  return resolve_path(config.threshold[best_threshold])
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
  local cmd = string.format("chafa --size=%dx%d %s", config.width, config.height, vim.fn.expand(image_path))

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

  vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = config.width,
    height = config.height,
    row = ui.height - config.height - 2, -- Adjust for statusline
    col = ui.width - config.width - 2,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    noautocmd = true
  })
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

function M.setup(opts)
  opts = opts or {}

  config = vim.tbl_deep_extend("force", vim.deepcopy(default_opts), opts)

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
