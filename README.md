# tmux-colorscheme-sync.nvim

Sync your Neovim colorscheme with tmux — automatically export highlight colors
as tmux user variables (`@nvim_color_*`) so your tmux status line and styles
can stay in sync with whatever colorscheme Neovim is using.

The plugin also handles focus dimming: when Neovim loses focus (you switch to
another tmux pane), highlight backgrounds are set to a dimmed color so the
inactive pane blends with tmux's inactive pane styling. When focus returns,
original colors are restored.

## Features

- Exports Neovim highlight colors to tmux as user variables on `ColorScheme`
  and `UIEnter`
- Optionally caches the exported variables to a file so tmux can source them
  on cold start (before Neovim is open)
- Optionally re-sources a tmux config file when colors change
- Computes `normal_darker` and `normal_lighter` shade variants for use in
  tmux styles
- Dims Neovim on `FocusLost` using the `normal_lighter` shade (instead of
  `bg=none`) to avoid flicker on focus transitions
- `focus_lost_highlights` option to dim additional highlight groups (e.g.
  NvimTree, neo-tree) on `FocusLost`

## Requirements

- Neovim >= 0.9
- tmux (for color syncing and focus events)
- `focus-events on` in your tmux config

## Installation

With [mini.deps](https://github.com/echasnovski/mini.deps):

```lua
MiniDeps.add('andreykaipov/tmux-colorscheme-sync.nvim')
require('tmux-colorscheme-sync').setup()
```

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    'andreykaipov/tmux-colorscheme-sync.nvim',
    config = true,
}
```

## Configuration

All options are optional. Below are the defaults:

```lua
require('tmux-colorscheme-sync').setup({
    -- Enable debug logging
    debug = false,

    -- Function returning a table of extra {fg, bg} color mappings to export.
    -- Merged on top of the default mappings.
    mapping = nil,

    -- Path to source after setting tmux color variables (e.g. "~/.tmux.conf"
    -- or "~/.config/tmux/styles.conf"). Only re-sourced when colors change.
    tmux_source_file = nil,

    -- Path to write tmux `set -g` commands so tmux can source them on cold
    -- start (before Neovim is open). Only written when colors change.
    cache_file = nil,

    -- Percent to darken normal bg for the `normal_darker` color mapping.
    darker_shade = -40,

    -- Percent to lighten normal bg for the `normal_lighter` color mapping.
    -- Also used as the inactive bg on FocusLost.
    lighter_shade = 5,

    -- Extra highlight groups to set to the inactive bg on FocusLost.
    -- Useful for sidebar plugins like nvim-tree or neo-tree.
    focus_lost_highlights = {},
})
```

### Example

```lua
require('tmux-colorscheme-sync').setup({
    cache_file = '~/.local/state/tmux/colorscheme-cache.conf',
    tmux_source_file = '~/.config/tmux/styles.conf',
    lighter_shade = 30,
    focus_lost_highlights = {
        'SignColumn',
        'NvimTreeNormal',
        'NvimTreeNormalNC',
    },
})
```

## How it works

### Color syncing

On `UIEnter` and `ColorScheme`, the plugin reads highlight groups from Neovim
and sets tmux user variables:

```
@nvim_color_normal_fg '#c0caf5'
@nvim_color_normal_bg '#1a1b26'
@nvim_color_normal_lighter_bg '#2a2b3d'
...
```

You can reference these in your tmux config:

```tmux
set -g status-style "bg=#{@nvim_color_normal_darker_bg},fg=#{@nvim_color_normal_fg}"
set -g window-status-current-style "bg=#{@nvim_color_normal_bg}"
```

If `cache_file` is set, the variables are also written as `set -g` commands to
a file that tmux can source on startup:

```tmux
# in tmux.conf
source-file -q ~/.local/state/tmux/colorscheme-cache.conf
```

### Focus dimming

When Neovim loses focus (`FocusLost`), the plugin sets `Normal`, `NormalNC`,
and `LineNr` backgrounds to the `normal_lighter` color. Any groups listed in
`focus_lost_highlights` are also set to this color.

This is intentionally **not** `bg=none` (transparent). Using the actual dimmed
color avoids a flicker that occurs when Neovim redraws before `FocusGained`
autocmds can restore colors — with `bg=none`, that redraw shows whatever the
terminal background happens to be mid-transition.

When focus returns (`FocusGained`), original colors are restored.

### Exported color mappings

| Key              | Highlight group | Description                           |
|------------------|-----------------|---------------------------------------|
| `normal`         | `Normal`        | Main editor text and background       |
| `identifier`     | `Identifier`    | Variable names, etc.                  |
| `constant`       | `Constant`      | Constant values                       |
| `function`       | `Function`      | Function names                        |
| `color_column`   | `ColorColumn`   | Column guide background               |
| `tabline`        | `TabLine`       | Tab line background                   |
| `winbar`         | `WinBar`        | Window bar                            |
| `normal_darker`  | *(computed)*    | Normal bg darkened by `darker_shade`  |
| `normal_lighter` | *(computed)*    | Normal bg lightened by `lighter_shade`|

Each mapping exports both `_fg` and `_bg` variants as tmux user variables.

Use the `mapping` option to add your own:

```lua
require('tmux-colorscheme-sync').setup({
    mapping = function()
        local get_hl = require('tmux-colorscheme-sync.config').get_hl
        return {
            cursor_line = get_hl('CursorLine'),
            visual = get_hl('Visual'),
        }
    end,
})
```
