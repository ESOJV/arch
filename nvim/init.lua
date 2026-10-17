require('config.options')
require('config.keymaps')
require('config.autocmds')

-- Build hooks must be registered before vim.pack.add()
vim.api.nvim_create_autocmd('PackChanged', {
	callback = function(ev)
		local name = ev.data.spec.name
		local kind = ev.data.kind
		if kind == 'install' or kind == 'update' then
			if name == 'telescope-fzf-native.nvim' and vim.fn.executable('make') == 1 then
				vim.system({ 'make' }, { cwd = ev.data.path }):wait()
			end
			if name == 'LuaSnip' and vim.fn.has('win32') == 0 and vim.fn.executable('make') == 1 then
				vim.system({ 'make', 'install_jsregexp' }, { cwd = ev.data.path }):wait()
			end
		end
	end,
})

vim.pack.add({
	-- Snippets (must load before blink.cmp)
	'https://github.com/L3MON4D3/LuaSnip',

	-- Completion
	{ src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.0') },

	-- LSP
	'https://github.com/folke/lazydev.nvim',
	'https://github.com/neovim/nvim-lspconfig',
	'https://github.com/mason-org/mason.nvim',
	'https://github.com/mason-org/mason-lspconfig.nvim',
	'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
	'https://github.com/j-hui/fidget.nvim',

	-- Formatting
	'https://github.com/stevearc/conform.nvim',

	-- Telescope
	'https://github.com/nvim-lua/plenary.nvim',
	'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
	'https://github.com/nvim-telescope/telescope-ui-select.nvim',
	'https://github.com/nvim-tree/nvim-web-devicons',
	'https://github.com/nvim-telescope/telescope.nvim',
	'https://github.com/MeanderingProgrammer/render-markdown.nvim',

	-- Mini
	'https://github.com/echasnovski/mini.nvim',

	-- Colorscheme
	'https://github.com/rktjmp/lush.nvim',
	'https://github.com/zenbones-theme/zenbones.nvim',
})

vim.o.background = 'dark'
vim.cmd.colorscheme('zenbones')

require('config.lsp')
require('config.blink')
require('config.conform')
require('config.telescope')
require('config.mini')
