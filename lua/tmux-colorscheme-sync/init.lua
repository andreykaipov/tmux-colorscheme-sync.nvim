local config = require("tmux-colorscheme-sync.config")
local utils = require("tmux-colorscheme-sync.utils")
local debug = utils.debug

local M = {
	get_hl = config.get_hl,
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
end

return M
