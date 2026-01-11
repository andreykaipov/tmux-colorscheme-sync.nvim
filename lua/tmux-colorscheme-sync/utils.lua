local config = require("tmux-colorscheme-sync.config")
local msg_prefix = "tmux-colorscheme-sync: "

local M = {}

function M.debug(msg)
	if config.settings.debug == false or msg == nil then
		return
	end

	if type(msg) == "string" then
		print(msg_prefix .. msg)
	elseif type(msg) == "table" then
		print(msg_prefix)
		M.print_table(msg)
	elseif type(msg) == "boolean" then
		print(msg_prefix .. tostring(msg))
	else
		print("Unhandled message type to dbg: message type is " .. type(msg))
	end
end

function M.print_table(t)
	print(vim.inspect(t))
end

function M.augroup(name)
	return vim.api.nvim_create_augroup("tmux-colorscheme-sync-" .. name, { clear = true })
end

function M.color(name)
	local hl = vim.api.nvim_get_hl(0, { name = name })
	local fg = hl and hl.fg or nil
	local bg = hl and hl.bg or nil
	local color = {
		fg = fg and string.format("#%06x", fg) or "none",
		bg = bg and string.format("#%06x", bg) or "none",
	}
	return hl and color or nil
end

return M
