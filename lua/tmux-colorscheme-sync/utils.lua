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

return M
