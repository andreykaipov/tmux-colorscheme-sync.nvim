local M = {}

M.settings = {}

M.default_settings = {
	debug = false, -- debug logging
	mapping = nil, -- any additional highlight groups you want to expose
	tmux_source_file = "~/.tmux.conf", -- the path of your tmux conf file the plugin will resource
}

M.get_color_mapping = function()
	local m = M.get_default_color_mapping()
	local user_mapping = M.settings.mapping
	if user_mapping then
		m = vim.tbl_deep_extend("force", m, user_mapping() or {})
	end
	return m
end

M.get_default_color_mapping = function()
	-- stylua: ignore
	-- these are signifcant enough highlight groups from catppuccin
	-- i'm assuming other color schemes will have a similar enough pattern
	local colors = {
		-- text
		identifier   = M.get_hl("Identifier"), --  (c.flamingo, nil)
		constant     = M.get_hl("Constant"),   --  (c.peach, nil)
		["function"] = M.get_hl("Function"),   --  (c.blue, nil)
		-- editor
		normal        = M.get_hl("Normal"),      -- (c.text, c.base)
		color_column  = M.get_hl("ColorColumn"), -- (nil, c.surface0)
		tabline       = M.get_hl("TabLine"),     -- (c.surface1, c.mantle)
		winbar        = M.get_hl("WinBar"),      -- (c.rosewater, nil)
	}
	-- these might be nice
	colors.normal_darker = colors.normal
	colors.normal_darker = {
		fg = colors.normal.fg,
		bg = M.shade(colors.normal.bg, -40),
	}
	colors.normal_lighter = colors.normal
	colors.normal_lighter = {
		fg = colors.normal.fg,
		bg = M.shade(colors.normal.bg, 40),
	}
	return colors
end

M.get_hl = function(name)
	local hl = vim.api.nvim_get_hl(0, { name = name })
	local fg = hl and hl.fg or nil
	local bg = hl and hl.bg or nil
	local color = {
		fg = fg and string.format("#%06x", fg) or "default",
		bg = bg and string.format("#%06x", bg) or "default",
	}
	return hl and color or nil
end

M.color_tune = function(col, amt)
	col = string.gsub(col, "^#", "")
	if not col or col == "" or col == "default" then
		return "default"
	end
	local num = tonumber(col, 16)
	local r = bit.rshift(num, 16) + amt
	local b = bit.band(bit.rshift(num, 8), 0x00FF) + amt
	local g = bit.band(num, 0x0000FF) + amt
	local newColor = bit.bor(g, bit.bor(bit.lshift(b, 8), bit.lshift(r, 16)))
	return string.format("#%X", newColor)
end

-- https://www.reddit.com/r/neovim/comments/qco76a/way_to_increase_decrease_brightness_of_selected/
--
---@diagnostic disable: param-type-mismatch
M.shade = function(color, percent)
	local r, g, b = M.to_rgb(color)
	if r == "default" then
		return r
	end
	r = M.clamp_color(math.floor(tonumber(r * (100 + percent) / 100)))
	g = M.clamp_color(math.floor(tonumber(g * (100 + percent) / 100)))
	b = M.clamp_color(math.floor(tonumber(b * (100 + percent) / 100)))
	return "#" .. string.format("%0x", r) .. string.format("%0x", g) .. string.format("%0x", b)
end

M.to_rgb = function(color)
	color = string.gsub(color, "^#", "")
	if not color or color == "" or color == "default" then
		return "default"
	end
	return tonumber(color:sub(1, 2), 16), tonumber(color:sub(3, 4), 16), tonumber(color:sub(4, 5), 16)
end

M.clamp_color = function(color)
	return math.max(math.min(color, 255), 0)
end

return M
