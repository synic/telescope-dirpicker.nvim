local telescope = require("telescope")
local path = require("plenary.path")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local sorters = require("telescope.sorters")
local state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")

local displayer = require("telescope.pickers.entry_display").create({
	separator = " ",
	items = { { width = 30 }, { remaining = true } },
})

local function get_entry_and_close_dialog(prompt_bufnr)
	local entry = state.get_selected_entry(prompt_bufnr)
	actions.close(prompt_bufnr)
	return entry.value
end

local function get_subdirs(opts)
	local dir = opts.cwd
	local subdirs = {}

	if opts.cmd then
		if type(opts.cmd) == "function" then
			subdirs = opts.cmd(opts)
		else
			local cmd = opts.cmd:gsub("__cwd", vim.fn.resolve(dir))
			local pfile = io.popen(cmd)

			if pfile ~= nil then
				for line in pfile:lines() do
					table.insert(subdirs, line)
				end
			end
		end
	else
		local gp = opts.glob_pattern:gsub("__cwd", vim.fn.resolve(dir))
		local files = vim.split(vim.fn.glob(gp), "\n", { trimempty = true })
		for _, file in ipairs(files) do
			if path.new(file):is_dir() then
				if file ~= "." and file ~= ".." then
					table.insert(subdirs, file)
				end
			end
		end
	end

	return subdirs
end

local function make_display(entry)
	return displayer({ entry.name, { entry.value, "Comment" } })
end

local function create_finder(opts)
	return finders.new_table({
		results = get_subdirs(opts),
		entry_maker = function(entry)
			local name = ""
			local p = entry

			if type(entry) == "table" then
				name = entry.name
				p = entry.path
			else
				name = vim.fn.fnamemodify(entry, ":t")
			end

			return {
				display = make_display,
				name = name,
				value = p,
				ordinal = name,
			}
		end,
	})
end

local function exec_cb(_, cmd)
	return function(prompt_bufnr)
		local dir = get_entry_and_close_dialog(prompt_bufnr)

		if type(cmd) == "function" then
			cmd(dir)
			return
		end

		vim.cmd[cmd](dir)
	end
end

local function goto_cwd(opts)
	return function(prompt_bufnr)
		actions.close(prompt_bufnr)
		vim.cmd.edit(opts.cwd)
	end
end

local function get_default_opts()
	return {
		cwd = ".",
		on_select = function(dir)
			builtin.find_files({ cwd = dir })
		end,
		enable_preview = true,
		glob_pattern = "__cwd/*",
		cmd = nil,
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
			sorter = opts.sorter or sorters.get_fuzzy_file(opts),
			attach_mappings = function(prompt_bufnr, map)
				map("n", "t", exec_cb(opts, "tcd"))
				map("n", "l", exec_cb(opts, "lcd"))
				map("n", "c", exec_cb(opts, "cd"))
				map("n", "e", exec_cb(opts, "edit"))
				map("n", "d", goto_cwd(opts))
				map("n", "b", exec_cb(opts, browse))
				map("i", "<c-t>", exec_cb(opts, "tcd"))
				map("i", "<c-l>", exec_cb(opts, "lcd"))
				map("i", "<c-c>", exec_cb(opts, "cd"))
				map("i", "<c-e>", exec_cb(opts, "edit"))
				map("i", "<c-d>", goto_cwd(opts))
				map("i", "<c-b>", exec_cb(opts, browse))

				local function select()
					local dir = get_entry_and_close_dialog(prompt_bufnr)
					opts.on_select(dir)
				end

				actions.select_default:replace(select)
				return true
			end,
		})
		:find()
end

return telescope.register_extension({ exports = { dirpicker = dirpicker } })
