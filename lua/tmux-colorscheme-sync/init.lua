local config = require("tmux-colorscheme-sync.config")
local utils = require("tmux-colorscheme-sync.utils")
local debug = utils.debug

local M = {
	get_hl = config.get_hl,
	normal = {},
	normal_nc = {},
	line_nr = {},
}


function M.setup(settings)
	-- Let user config overwrite any default config options.
	config.settings = vim.tbl_deep_extend("force", config.default_settings, settings or {})

	if not M.normal then
		M.normal = config.get_color_mapping().normal
	end

	vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
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

			local changed = true
			if config.settings.cache_file then
				local path = vim.fn.expand(config.settings.cache_file)
				local lines = {}
				for k, v in pairs(colors) do
					table.insert(lines, string.format("set -g @nvim_color_%s_fg '%s'", k, v.fg))
					table.insert(lines, string.format("set -g @nvim_color_%s_bg '%s'", k, v.bg))
				end
				table.sort(lines)
				local new_content = table.concat(lines, "\n") .. "\n"

				-- read existing cache to check if colors changed
				local old_content = nil
				local rf = io.open(path, "r")
				if rf then
					old_content = rf:read("*a")
					rf:close()
				end

				if old_content == new_content then
					changed = false
					debug("cache unchanged, skipping tmux source")
				else
					-- ensure parent directory exists
					local dir = path:match("(.*/)")
					if dir then
						os.execute("mkdir -p " .. dir)
					end
					local wf = io.open(path, "w")
					if wf then
						wf:write(new_content)
						wf:close()
						debug("wrote cache to " .. path)
					end
				end
			end

			if changed and config.settings.tmux_source_file then
				os.execute("tmux source " .. config.settings.tmux_source_file)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
		group = utils.augroup("get-original-colors"),
		pattern = "*",
		desc = "",
		callback = function()
			M.normal = utils.color("Normal")
			M.normal_nc = utils.color("NormalNC")
			M.line_nr = utils.color("LineNr")
		end,
	})
	vim.api.nvim_create_autocmd({ "FocusLost" }, {
		group = utils.augroup("tmux-make-transparent"),
		pattern = "*",
		desc = "Sets nvim highlight groups to inactive bg on FocusLost",
		callback = function()
			-- Use the dimmed bg color instead of 'none' to avoid flicker.
			-- When bg='none' (transparent), Neovim may redraw before FocusGained
			-- autocmds restore colors, showing a flash of the terminal bg.
			-- Using the actual dim color is visually identical (terminal bg is
			-- set to the same color via OSC 11) but flicker-free.
			local inactive_bg = "none"
			local colors = config.get_color_mapping()
			if colors.normal_lighter and colors.normal_lighter.bg and colors.normal_lighter.bg ~= "default" then
				inactive_bg = colors.normal_lighter.bg
			end
			vim.api.nvim_set_hl(0, "Normal", { bg = inactive_bg })
			vim.api.nvim_set_hl(0, "NormalNC", { bg = inactive_bg })
			vim.api.nvim_set_hl(0, "LineNr", { fg = M.line_nr.fg, bg = inactive_bg })
			-- Apply to any extra highlight groups the user configured
			local extra = config.settings.focus_lost_highlights or {}
			for _, hl_name in ipairs(extra) do
				vim.api.nvim_set_hl(0, hl_name, { bg = inactive_bg })
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "FocusGained" }, {
		group = utils.augroup("tmux-restore-transparency"),
		pattern = "*",
		desc = "Restores transparency to original colors of colorscheme",
		callback = function()
			vim.api.nvim_set_hl(0, "Normal", { bg = M.normal.bg })
			vim.api.nvim_set_hl(0, "NormalNC", { bg = M.normal_nc.bg })
			vim.api.nvim_set_hl(0, "LineNr", { fg = M.line_nr.fg, bg = M.line_nr.bg })
		end,
	})
end

return M
