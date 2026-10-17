-- Paste from system clipboard with Shift+Insert (sent by Super+V via Hyprland)
vim.keymap.set('n', '<S-Insert>', '"+p')
vim.keymap.set('i', '<S-Insert>', '<C-r>+')

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Goes to previous diagnostic' })
vim.keymap.set('n', 'd]', vim.diagnostic.goto_next, { desc = 'Goes to next diagnostic' })

-- Exit terminal
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Netrw file explorer
vim.keymap.set('n', '<leader>rw', vim.cmd.Ex, { desc = 'Open net[RW] file explorer' })

-- ============================================================================
-- PANE/SPLIT CREATION
-- ============================================================================
vim.keymap.set('n', '<leader>vt', function()
  vim.cmd 'vsplit'
  vim.cmd 'terminal'
  vim.cmd 'startinsert'
end, { desc = '[V]ertical [T]erminal' })

vim.keymap.set('n', '<leader>ht', function()
  vim.cmd 'split'
  vim.cmd 'terminal'
  vim.cmd 'startinsert'
end, { desc = '[H]orizontal [T]erminal' })

vim.keymap.set('n', '<leader>nvv', '<cmd>vsplit<CR>', { desc = '[N]ew [V]ertical [V]im pane' })
vim.keymap.set('n', '<leader>nvh', '<cmd>split<CR>', { desc = '[N]ew [V]im [H]orizontal pane' })

vim.keymap.set('n', '<leader>nsv', function()
  vim.cmd 'vsplit'
  vim.cmd 'terminal'
  vim.cmd 'startinsert'
end, { desc = '[N]ew [S]hell [V]ertical' })

vim.keymap.set('n', '<leader>nsh', function()
  vim.cmd 'split'
  vim.cmd 'terminal'
  vim.cmd 'startinsert'
end, { desc = '[N]ew [S]hell [H]orizontal' })

-- ============================================================================
-- TAB CREATION
-- ============================================================================
vim.keymap.set('n', '<leader>nts', function()
  vim.cmd 'tabnew'
  vim.cmd 'terminal'
  vim.cmd 'startinsert'
end, { desc = '[N]ew [T]ab [S]hell' })

vim.keymap.set('n', '<leader>nta', function()
  vim.cmd 'tabnew'
  vim.cmd 'terminal claude'
  vim.api.nvim_buf_set_name(0, 'Claude')
  vim.cmd 'startinsert'
end, { desc = '[N]ew [T]ab [A]I Claude' })

vim.keymap.set('n', '<leader>ntv', function()
  vim.cmd 'tabnew'
  vim.api.nvim_buf_set_name(0, 'Claude')
  vim.cmd 'startinsert'
end, { desc = '[N]ew [T]ab [V]im' })

-- ============================================================================
-- TAB MOVEMENT
-- ============================================================================
vim.keymap.set('n', '<leader>tl', '<cmd>tabnext<CR>', { desc = '[T]ab [L]eft (next)' })
vim.keymap.set('n', '<leader><Tab>', '<cmd>tabnext<CR>', { desc = 'Next tab' })
vim.keymap.set('n', '<leader>th', '<cmd>tabprevious<CR>', { desc = '[T]ab [H] (previous)' })
vim.keymap.set('n', '<leader><S-Tab>', '<cmd>tabprevious<CR>', { desc = 'Previous tab' })

for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, '<cmd>tabn ' .. i .. '<CR>')
end

-- ============================================================================
-- SMART CLOSE (buffer, window, or tab)
-- ============================================================================
vim.keymap.set('n', '<leader>x', function()
  local buffers = vim.fn.len(vim.fn.getbufinfo { buflisted = 1 })
  local tabs = vim.fn.tabpagenr '$'
  local is_terminal = vim.bo.buftype == 'terminal'

  local old_confirm = vim.o.confirm
  vim.o.confirm = false

  if buffers > 1 then
    vim.cmd(is_terminal and 'bdelete!' or 'bdelete')
  elseif tabs > 1 then
    vim.cmd 'tabclose'
  else
    vim.cmd(is_terminal and 'quit!' or 'quit')
  end

  vim.o.confirm = old_confirm
end, { desc = 'Smart close (buffer/tab/quit)' })

vim.keymap.set('n', '<leader>X', function()
  local buffers = vim.fn.len(vim.fn.getbufinfo { buflisted = 1 })
  local tabs = vim.fn.tabpagenr '$'

  if buffers > 1 then
    vim.cmd 'bdelete!'
  elseif tabs > 1 then
    vim.cmd 'tabclose!'
  else
    vim.cmd 'quit!'
  end
end, { desc = 'Force close (discard changes)' })

-- ============================================================================
-- CODE RUNNER
-- ============================================================================
local runners = {
  go = 'go run %',
  python = 'python3 %',
  javascript = 'node %',
  typescript = 'ts-node %',
  lua = 'lua %',
  rust = 'cargo run',
  c = 'gcc % -o /tmp/a.out && /tmp/a.out',
  cpp = 'g++ % -o /tmp/a.out && /tmp/a.out',
}

vim.keymap.set('n', '<leader>nr', function()
  local ft = vim.bo.filetype
  local cmd = runners[ft]
  if cmd then
    vim.cmd 'write'
    vim.cmd('10split | terminal ' .. cmd)
  else
    print('No runner for filetype: ' .. ft)
  end
end, { desc = '[N]ew [R]unner' })

-- Close terminal with q
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = true })
  end,
})
