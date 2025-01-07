local telescope = require("telescope")
local path = require("plenary.path")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local sorters = require("telescope.sorters")
local state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")

local function get_entry_and_close_dialog(prompt_bufnr)
	local entry = state.get_selected_entry()
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
			---@diagnostic disable-next-line: param-type-mismatch
			if path.new(file):is_dir() then
				if file ~= "." and file ~= ".." then
					table.insert(subdirs, file)
				end
			end
		end
	end

	return subdirs
end

local function create_finder(opts)
	local displayer = require("telescope.pickers.entry_display").create({
		separator = opts.displayer.separator,
		items = { { width = opts.displayer.name_width }, { remaining = true } },
	})

	local make_display = function(entry)
		return displayer({ entry.name, { entry.value, "Comment" } })
	end

	return finders.new_table({
		results = get_subdirs(opts),
		entry_maker = function(entry)
			local name, p = type(entry) == "table" and entry.name, entry.path or vim.fn.fnamemodify(entry, ":t")

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

local function get_default_opts()
	return {
		cwd = ".",
		on_select = function(dir)
			builtin.find_files({ cwd = dir })
		end,
		enable_preview = true,
		glob_pattern = "__cwd/*",
		cmd = nil,
		attach_default_mappings = true,
		displayer = {
			separator = " ",
			name_width = 30,
		},
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
				if opts.attach_default_mappings then
					map("n", "t", exec_cb(opts, "tcd"), { desc = "Set tab cwd (:tcd)" })
					map("n", "l", exec_cb(opts, "lcd"), { desc = "Set buffer cwd (:lcd)" })
					map("n", "c", exec_cb(opts, "cd"), { desc = "Set cwd (:cd)" })
					map("n", "e", exec_cb(opts, "edit"), { desc = "Open dir in file browser" })
					map("n", "b", exec_cb(opts, browse), { desc = "Find files in directory" })
					map("i", "<c-t>", exec_cb(opts, "tcd"), { desc = "Set buffer cwd (:tcd)" })
					map("i", "<c-l>", exec_cb(opts, "lcd"), { desc = "Set local cwd (:lcd)" })
					map("i", "<c-c>", exec_cb(opts, "cd"), { desc = "Set cwd (:cd)" })
					map("i", "<c-e>", exec_cb(opts, "edit"), { desc = "Open dir in file browser" })
					map("i", "<c-b>", exec_cb(opts, browse), { desc = "Find files in directory" })
				end

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
