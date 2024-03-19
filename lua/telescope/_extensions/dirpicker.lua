local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
	return
end

local path = require("plenary.path")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local sorters = require("telescope.sorters")
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

local function create_finder(opts)
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

	local directories = {}

	for _, dir in ipairs(search_in) do
		directories = table_concat(directories, get_subdirs(dir))
	end

	return finders.new_table({
		results = directories,
		entry_maker = function(entry)
			local display_name = vim.fn.fnamemodify(entry, ":t")
			return {
				display = make_display,
				name = display_name,
				value = entry,
				ordinal = display_name .. " " .. entry,
			}
		end,
	})
end

local function exec_command(opts, prompt_bufnr, cmd)
	local entry = state.get_selected_entry(prompt_bufnr)
	local full_cmd = cmd .. " " .. entry.value

	if not opts.silent then
		vim.notify(":" .. full_cmd)
	end
	actions.close(prompt_bufnr)
	vim.cmd(full_cmd)
end

local function dirpicker(opts)
	opts = opts or {}

	pickers
		.new(opts, {
			prompt_title = opts.prompt_title or "Pick a Directory",
			finder = create_finder(opts),
			previewer = false,
			sorter = opts.sorter or sorters.get_fuzzy_file(),
			attach_mappings = function(prompt_bufnr, map)
				map("n", "t", function(pb)
					exec_command(opts, pb, "tcd")
				end)
				map("n", "l", function(pb)
					exec_command(opts, pb, "lcd")
				end)
				map("n", "c", function(pb)
					exec_command(opts, pb, "cd")
				end)
				map("n", "e", function(pb)
					exec_command(opts, pb, "edit")
				end)
				map("i", "<c-t>", function(pb)
					exec_command(opts, pb, "tcd")
				end)
				map("i", "<c-l>", function(pb)
					exec_command(opts, pb, "lcd")
				end)
				map("i", "<c-c>", function(pb)
					exec_command(opts, pb, "cd")
				end)
				map("i", "<c-e>", function(pb)
					exec_command(opts, pb, "edit")
				end)

				local function select()
					local entry = state.get_selected_entry(prompt_bufnr)
					actions.close(prompt_bufnr)

					local on_select = opts.on_select or function(dir)
						builtin.find_files({ cwd = dir })
					end

					on_select(entry.value)
				end

				actions.select_default:replace(select)
				return true
			end,
		})
		:find()
end

return telescope.register_extension({ exports = { dirpicker = dirpicker } })
