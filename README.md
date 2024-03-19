# :file_folder: telescope-dirpicker.nvim

**telescope-dirpicker.nvim** is a directry picker plugin for NeoVim and Telescope.
It allows you to pick from a list of subdirectories and either execute
Telescope's `find_files` on that directory, or set up a custom callback to do
whatever you want when a directory is selected.

## :question: But Why?

On my machine, all of my code repositories are in `~/Projects`. I have bound
`<space>pp` to `:Telescope dirpicker cwd=~/Projects`. When I load vim, I type
`<space>pp` and pick from a project. When I want to work on a new project, I
open a new tab page and run `:Telescope dirpicker` again.

## ⚡ Requirements

- Neovim >= 0.5.0
- Telescope >= 0.1.6

**NOTE:** This may work on Windows, however, I have not been able to test it.

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
      "synic/telescope-dirpicker.nvim",
      config = function()
        require('telescope').load_extension('dirpicker')
      end,
    }
  },
},
```

#### Usage

To use the directory picker

```vim
:Telescope dirpicker cwd=~/Projects
```

```lua
require('telescope').extensions.dirpicker.dirpicker({ cwd = "~/Projects/" })
```

With a custom select callback:

```lua
require('telescope').extensions.dirpicker.dirpicker({
  cwd = "~/Projects/",
  prompt_title = "Projects",
  on_select = function(dir)
    vim.notify("You selected directory: " .. dir)
    vim.cmd.tcd(dir)
  end,
})
```

#### Mappins

**telescope-dirpicker.nvim** comes with the following mappings:

| Normal mode | Insert mode | Action  | Notes                              |
| ----------- | ----------- | ------- | ---------------------------------- |
| t           | \<c-t\>     | `:tcd`  |                                    |
| l           | \<c-l\>     | `:lcd`  |                                    |
| c           | \<c-c\>     | `:cd`   |                                    |
| e           | \<c-e\>     | `:edit` |                                    |
| d           | \<c-d\>     |         | goes to the first passed directory |
