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

local function table_concat(table1, table2)
	for i = 1, #table2 do
		table1[#table1 + 1] = table2[i]
	end
	return table1
end

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

local function get_search_in(opts)
	local search_in = {}
	if type(opts.cwd) == "function" then
		search_in = opts.cwd()
	elseif type(opts.cwd) == "string" then
		search_in = vim.split(opts.cwd, ",", { trimempty = true })
	elseif type(opts.cwd) == "table" then
		search_in = opts.cwd
	else
		table.insert(search_in, vim.loop.cwd())
	end
	return search_in
end

local function create_finder(opts)
	local directories = {}

	for _, dir in ipairs(get_search_in(opts)) do
		directories = table_concat(directories, get_subdirs(dir))
	end

	return finders.new_table({
		results = directories,
		entry_maker = function(entry)
			return {
				display = make_display,
				name = opts.get_entry_display(entry),
				value = entry,
				ordinal = opts.get_entry_ordinal(entry),
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

local function goto_first_directory(opts)
	return function(prompt_bufnr)
		local search_in = get_search_in(opts)
		local value = search_in[1]

		local full_cmd = "edit " .. value

		if not opts.silent then
			vim.notify(":" .. full_cmd)
		end
		actions.close(prompt_bufnr)
		vim.cmd(full_cmd)
	end
end

local function get_default_opts()
	return {
		on_select = nil,
		get_entry_display = function(entry)
			return vim.fn.fnamemodify(entry, ":t")
		end,
		get_entry_ordinal = function(entry)
			local name = vim.fn.fnamemodify(entry, ":t")
			return name .. " " .. entry
		end,
	}
end

local function dirpicker(opts)
	opts = vim.tbl_deep_extend("force", get_default_opts(), opts)

	local enable_preview = true
	if opts.enable_preview ~= nil then
		enable_preview = opts.enable_preview
	end

	pickers
		.new(opts, {
			prompt_title = opts.prompt_title or "Pick a Directory",
			finder = create_finder(opts),
			previewer = enable_preview and previewers.vim_buffer_cat.new(opts) or false,
			sorter = opts.sorter or sorters.get_fuzzy_file(),
			attach_mappings = function(prompt_bufnr, map)
				map("n", "t", exec_cb(opts, "tcd"))
				map("n", "l", exec_cb(opts, "lcd"))
				map("n", "c", exec_cb(opts, "cd"))
				map("n", "e", exec_cb(opts, "edit"))
				map("n", "d", goto_first_directory(opts))
				map(
					"n",
					"b",
					exec_cb(opts, function(d)
						builtin.find_files({ cwd = d })
					end)
				)
				map("i", "<c-t>", exec_cb(opts, "tcd"))
				map("i", "<c-l>", exec_cb(opts, "lcd"))
				map("i", "<c-c>", exec_cb(opts, "cd"))
				map("i", "<c-e>", exec_cb(opts, "edit"))
				map("i", "<c-d>", goto_first_directory(opts))
				map(
					"i",
					"<c-b>",
					exec_cb(opts, function(d)
						builtin.find_files({ cwd = d })
					end)
				)

				local function select()
					local entry = state.get_selected_entry(prompt_bufnr)
					actions.close(prompt_bufnr)

					if type(opts.on_select) == "function" then
						opts.on_select(entry.value)
					else
						builtin.find_files({ cwd = entry.value })
					end
				end

				actions.select_default:replace(select)
				return true
			end,
		})
		:find()
end

return telescope.register_extension({ exports = { dirpicker = dirpicker } })
