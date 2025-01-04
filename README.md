# :file_folder: telescope-dirpicker.nvim

**telescope-dirpicker.nvim** is a directry picker plugin for NeoVim and Telescope.
It allows you to pick from a list of subdirectories and either execute
Telescope's `find_files` on that directory, or set up a custom callback to do
whatever you want when a directory is selected.

![dirpicker gif](https://github.com/synic/telescope-dirpicker.nvim/assets/30906/96d5b331-9c27-45e3-9073-9dfc25dd9de3)

## But Why?

On my machine, all of my code repositories are in `~/Projects`. I have bound
`<space>pp` to `:Telescope dirpicker cwd=~/Projects`. When I load vim, I type
`<space>pp` and pick from a project. When I want to work on a new project, I
open a new tab page and run `:Telescope dirpicker` again.

Initially I used [project.nvim](https://github.com/ahmedkhalf/project.nvim),
which I really like, however, it's got some issues and it seems like an
abandoned project. Some of the features I need are sitting in PRs that have
been open for over a year without any response. It also does a bunch of things
I don't really care about. I realized that what I actually need is pretty
simple.

## Requirements

- Neovim >= 0.5.0
- Telescope >= 0.1.6

**NOTE:** This may work on Windows, however, I have not been able to test it.

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "synic/telescope-dirpicker.nvim",
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)

    -- optional, if not provided, `:Telescope dirpicker` will still work, you
    -- won't be able to autocomplete `dirpicker` on first use if you lazy load
    -- telescope.
    telescope.load_extension("dirpicker")
  end,
},
```

#### Usage

To use the directory picker

```vim
:Telescope dirpicker cwd=~/Projects
```

```lua
require("telescope").extensions.dirpicker.dirpicker({ cwd = "~/Projects/" })
```

The default "select" action is to open the directory with `:Telescope
find_files`. You can configure this behavior by setting `on_select`
to a function with the signature: `function(dir)`:

```lua
require("telescope").extensions.dirpicker.dirpicker({
  cwd = "~/Projects/",
  prompt_title = "Projects",
  on_select = function(dir)
    vim.notify("You selected: " .. dir)
    vim.cmd.tcd(dir)
  end,
  -- on_select = vim.cmd.edit,  -- to open dir in netrw
})
```

#### Picker Options

These are the overrideable default picker configuration options:

```lua
local opts = {
  cwd = ".",
  prompt_title = "Pick a Directory",
  enable_preview = true,
  attach_default_mappings = true,
  mappings = { i = {}, n = {} }, -- use to add additional mappings
  on_select = function(dir)
    require("telescope.builtin").find_files({ cwd = dir })
  end,
}
```

#### Mappings

**telescope-dirpicker.nvim** comes with the following mappings:

| Normal mode | Insert mode | Action                                       |
| ----------- | ----------- | -------------------------------------------- |
| t           | \<c-t\>     | Change tab directory                         |
| l           | \<c-l\>     | Change buffer directory                      |
| c           | \<c-c\>     | Change global directory                      |
| e           | \<c-e\>     | Edit dir in default dir editor               |
| d           | \<c-d\>     | Edit first search dir in default dir editor  |
| b           | \<c-b\>     | Browse files in telescope                    |
