-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Auto-enter insert mode when switching to a terminal buffer
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  pattern = 'term://*',
  callback = function()
    vim.cmd 'startinsert'
  end,
})
