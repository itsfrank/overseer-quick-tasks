local o_template = require("overseer.template")
local overseer = require("overseer")
local harpoon = require("harpoon")

---@class OqtListItem
---@field name string
---@field cmd string[]
---@field _task_id? number

local oqt = {}

---@type HarpoonPartialConfigItem
oqt.harppon_list_config = {
    encode = function(list_item)
        if list_item.value.name == nil or list_item.value.cmd == nil then
            return nil
        end
        local obj = {
            name = list_item.value.name,
            cmd = list_item.value.cmd,
        }
        return vim.json.encode(obj)
    end,

    decode = function(obj_str)
        local obj = vim.json.decode(obj_str)
        return {
            value = obj,
        }
    end,

    display = function(list_item)
        return list_item.value.name
    end,

    -- dont have duplicate names, name will overwrite
    equals = function(list_line_a, list_line_b)
        if list_line_a == nil or list_line_b == nil then
            return false
        end
        return list_line_a.value.name == list_line_b.value.name
    end,

    create_list_item = function(_, item)
        -- from ui
        if item ~= nil then
            if type(item) == "string" then
                return {
                    value = {
                        name = item,
                        cmd = item,
                    },
                }
            elseif type(item) == "table" then
                -- transform into a list item
                if item.value == nil then
                    item = {
                        value = item,
                    }
                end
                vim.validate({
                    name = { item.value.name, "string" },
                    cmd = { item.value.name, { "string", "table" } },
                })
                return item
            end
            error("invalid item type")
        end
        error("Cannot create an item with append(nil), use oqt.prompt_new_task()")
    end,

    select = function(list_item, _, _)
        local make_task = function()
            return overseer.new_task({
                name = list_item.value.name,
                cmd = list_item.value.cmd,
                components = { -- required because "default" causes errors for some reason
                    { "display_duration", detail_level = 2 },
                    "on_output_summarize",
                    "on_exit_set_status",
                    "on_complete_notify",
                    "on_complete_dispose",
                },
            })
        end

        local task = nil

        -- task not created yet
        if list_item.value._task_id == nil then
            task = make_task()
        end

        -- task should be created, lets look for it
        if task == nil then
            local tasks = overseer.list_tasks({
                filter = function(t)
                    return t.id == list_item.value._task_id
                end,
            })
            if #tasks == 0 then
                -- couldn't find it, let's make one
                task = make_task()
            else
                task = tasks[1]
            end
        end

        -- set the id so we reuse the same task in the future
        list_item.value._task_id = task.id
        task:restart(true)
    end,
}

--- open overseer shell task prompt, add task to list
function oqt.prompt_new_task()
    local tmpl
    o_template.get_by_name("shell", {
        dir = vim.fn.getcwd(),
    }, function(t)
        tmpl = t
    end)
    o_template.build_task_args(tmpl, { prompt = "always", params = {} }, function(task, err)
        if err or task == nil then
            return
        end
        harpoon:list("oqt"):append({
            value = {
                name = task.name,
                cmd = task.cmd,
            },
        })
    end)
end

--- open float output of most recently run task
function oqt.float_last_task()
    local tasks = overseer.list_tasks({ recent_first = true })
    if #tasks == 0 then
        vim.notify("no recent tasks", vim.log.levels.WARN)
        return
    end

    local task = tasks[1]
    overseer.run_action(task, "open float")
    vim.keymap.set("n", "q", ":q<cr>", { buffer = 0 })
end

--- open float output of task at index i
---@param i number
function oqt.float_task(i)
    local oqt_list = harpoon:list("oqt")
    if i <= 0 or i > oqt_list:length() then
        vim.notify("index '" .. tostring(i) .. "' is out of bounds for the oqt list", vim.log.levels.ERROR)
        return
    end
    local item = harpoon:list("oqt"):get(i)

    local task = nil
    if item.value._task_id ~= nil then
        local tasks = overseer.list_tasks({
            filter = function(t)
                return t.id == item.value._task_id
            end,
        })
        if #tasks > 0 then
            task = tasks[1]
        end
    end

    if task == nil then
        vim.notify(
            "could not open float for task at index '" .. tostring(i) .. "' make sure it was run at least once",
            vim.log.levels.WARN
        )
        return
    end

    overseer.run_action(task, "open float")
end

--- setup default keymaps for oqt
function oqt.setup_keymaps()
    vim.keymap.set("n", "<leader>tn", function()
        oqt.prompt_new_task()
    end, { desc = "[T]asks [N]ew - harpoon overseer quick tasks" })

    vim.keymap.set("n", "<leader>tv", function()
        harpoon.ui:toggle_quick_menu(harpoon:list("oqt"))
    end, { desc = "[T]asks [V]iew - harpoon overseer quick tasks" })

    vim.keymap.set("n", "<leader>tl", function()
        oqt.float_last_task()
    end, { desc = "last [T]ask output [L]ast - harpoon overseer quick tasks" })

    -- set up numeric keymaps: <leader>t1-9 for running tasks
    for i = 1, 9 do
        vim.keymap.set("n", "<leader>t" .. tostring(i), function()
            harpoon:list("oqt"):select(i)
        end, { desc = "[T]asks run - harpoon overseer quick tasks" .. tostring(i) })

        vim.keymap.set("n", "<leader>to" .. tostring(i), function()
            oqt.float_task(i)
        end, { desc = "[T]asks [O]utput - harpoon overseer quick tasks" .. tostring(i) })
    end
end

return oqt
