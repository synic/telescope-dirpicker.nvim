local telescope = require("telescope")
local path = require("plenary.path")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local sorters = require("telescope.sorters")
local previewers = require("telescope.previewers")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")

local displayer = require("telescope.pickers.entry_display").create({
	separator = " ",
	items = { { width = 30 }, { remaining = true } },
})

local function get_subdirs(dir)
	local subdirs = {}

	local files = vim.split(vim.fn.glob(dir .. "/*"), "\n", { trimempty = true })
	for _, file in ipairs(files) do
		if path.new(file):is_dir() then
			table.insert(subdirs, file)
		end
	end
	return subdirs
end

local function make_display(entry)
	return displayer({ entry.name, { entry.value, "Comment" } })
end

local function create_finder(opts)
	return finders.new_table({
		results = get_subdirs(opts.cwd),
		entry_maker = function(entry)
			local name = vim.fn.fnamemodify(entry, ":t")
			return {
				display = make_display,
				name = name,
				value = entry,
				ordinal = name .. " " .. entry,
			}
		end,
	})
end

local function exec_cb(_, cmd)
	return function(prompt_bufnr)
		local entry = state.get_selected_entry(prompt_bufnr)
		actions.close(prompt_bufnr)

		if type(cmd) == "function" then
			cmd(entry.value)
			return
		end

		vim.cmd(":" .. cmd .. " " .. entry.value)
	end
end

local function goto_first_dir(opts)
	return function(prompt_bufnr)
		actions.close(prompt_bufnr)
		vim.cmd(":edit " .. opts.cwd)
	end
end

local function get_default_opts()
	return {
		cwd = ".",
		on_select = function(dir)
			builtin.find_files({ cwd = dir })
		end,
		enable_preview = true,
	}
end

local function dirpicker(opts)
	opts = vim.tbl_deep_extend("force", get_default_opts(), opts)
	local browse = function(d)
		builtin.find_files({ cwd = d })
	end

	pickers
		.new(opts, {
			prompt_title = opts.prompt_title or "Pick a Directory",
			finder = create_finder(opts),
			previewer = opts.enable_preview and previewers.vim_buffer_cat.new(opts) or false,
			sorter = opts.sorter or sorters.get_fuzzy_file(),
			attach_mappings = function(prompt_bufnr, map)
				map("n", "t", exec_cb(opts, "tcd"))
				map("n", "l", exec_cb(opts, "lcd"))
				map("n", "c", exec_cb(opts, "cd"))
				map("n", "e", exec_cb(opts, "edit"))
				map("n", "d", goto_first_dir(opts))
				map("n", "b", exec_cb(opts, browse))
				map("i", "<c-t>", exec_cb(opts, "tcd"))
				map("i", "<c-l>", exec_cb(opts, "lcd"))
				map("i", "<c-c>", exec_cb(opts, "cd"))
				map("i", "<c-e>", exec_cb(opts, "edit"))
				map("i", "<c-d>", goto_first_dir(opts))
				map("i", "<c-b>", exec_cb(opts, browse))

				local function select()
					local entry = state.get_selected_entry(prompt_bufnr)
					actions.close(prompt_bufnr)
					opts.on_select(entry.value)
				end

				actions.select_default:replace(select)
				return true
			end,
		})
		:find()
end

return telescope.register_extension({ exports = { dirpicker = dirpicker } })
