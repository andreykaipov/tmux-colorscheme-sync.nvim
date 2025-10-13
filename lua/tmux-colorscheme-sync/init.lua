local config = require("tmux-colorscheme-sync.config")
local utils = require("tmux-colorscheme-sync.utils")
local debug = utils.debug

local M = {
	get_hl = config.get_hl,
	normal = nil,
}

function M.setup(settings)
	-- Let user config overwrite any default config options.
	config.settings = vim.tbl_deep_extend("force", config.default_settings, settings or {})

	vim.api.nvim_create_autocmd({ "ColorScheme" }, {
		group = utils.augroup("setvars"),
		pattern = "*",
		desc = "Sync nvim Normal color with active pane of tmux",
		callback = function()
			local colors = config.get_color_mapping()

			local cmd = ""
			for k, v in pairs(colors) do
				cmd = cmd .. string.format("tmux set -g @nvim_color_%s_fg '%s'\n", k, v.fg)
				cmd = cmd .. string.format("tmux set -g @nvim_color_%s_bg '%s'\n", k, v.bg)
			end
			debug(cmd)
			os.execute(cmd)

			if config.settings.tmux_source_file then
				os.execute("tmux source " .. config.settings.tmux_source_file)
			end
		end,
	})

	if not M.normal then
		M.normal = config.get_color_mapping().normal
	end

	-- vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
	-- vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })

	-- vim.api.nvim_create_autocmd({ "WinLeave", "FocusLost" }, {
	-- 	group = utils.augroup("tmux-left-neotree"),
	-- 	pattern = "*",
	-- 	desc = "",
	-- 	callback = function()
	-- 		-- if vim.bo.filetype == "neo-tree" then
	-- 		-- print("left neo-tree")
	-- 		-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	-- 		-- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
	-- 		-- vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
	-- 		-- end
	-- 		-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	-- 		-- os.execute("tmux set-option -w window-active-style 'fg=default,bg=default'")
	-- 		-- vim.api.nvim_set_hl(0, "Normal", { fg = M.normal.fg, bg = M.normal.bg })
	-- 	end,
	-- })
	-- vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained" }, {
	-- 	group = utils.augroup("tmux-winenter"),
	-- 	pattern = "*",
	-- 	desc = "",
	-- 	callback = function()
	-- 		-- os.execute("tmux set-option -w window-active-style 'fg=default,bg=default'")
	-- 		vim.api.nvim_set_hl(0, "Normal", { fg = M.normal.fg, bg = M.normal.bg })
	-- 		vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
	-- 		-- print("neo-tree)
	-- 	end,
	-- })
	-- vim.api.nvim_create_autocmd({ "FocusLost" }, {
	-- 	group = utils.augroup("tmux-focuslost"),
	-- 	pattern = "*",
	-- 	desc = "",
	-- 	callback = function()
	-- 		-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	-- 		-- os.execute(string.format("tmux set-option -w window-active-style 'fg=default,bg=%s'", normal.bg))
	-- 	end,
	-- })
end

return M
