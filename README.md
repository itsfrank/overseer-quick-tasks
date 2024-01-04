# Overseer Quick Tasks - Powered by Harpoon2

Maintain a persisted list of overseer tasks and execute them with efficient
keystrokes.

## Install

**must be installed**

- [overseer.nvim](https://github.com/stevearc/overseer.nvim/tree/master)
- [harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)
  - **note:** must use harpoon2

Using Lazy:

```lua
---@type LazySpec
return {
    "itsfrank/overseer-quick-tasks",
    dependencies = {
        "ThePrimeagen/harpoon",
        "stevearc/overseer.nvim",
    },
}
```

## Setup

Add the `"oqt"` list to harpoon with harpoon's partial config

```lua
-- with lazy, just add this to lazy spec above
-- for other managers, just copy the body wherever you want oqt configured
config = function()
    local harpoon = require("harpoon")
    local oqt = require("oqt")
    -- harpoon supports being partialy configured, should not affect your main setup
    harpoon:setup({
        oqt = oqt.harppon_list_config,
    })

    -- optional, set up the default oqt keymaps
    oqt.setup_keymaps()
end,
```

<details>
    <summary> Alternative - setup in harpoon's config </summary>

Alternatively, you can add oqt in Harpoon's setup, this requires adding oqt as
a dependency to harpoon, then just add the `oqt =` line above to the setup
object (I think you will need to remove harpoon form oqt's dependencies)

```lua
-- example harpoon lazy spec
return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2", -- required!
    dependencies = {
        "nvim-lua/plenary.nvim",
        "itsfrank/overseer-quick-tasks",
    },
    config = function()
        local harpoon = require("harpoon")
        local oqt = require("oqt")
        harpoon:setup({
            oqt = oqt.harppon_list_config, -- must be called "oqt"
            -- rest of setup options
        })

        -- optional, set up the default oqt keymaps
        oqt.setup_keymaps()

        -- rest of harpoon config
    end,
}
```

</details>

## Keymaps

**note**: if you want to register your own keymaps, see the
`oqt.setup_keymaps()` function in `lua/oqt.lua` for how I set up mine

Calling `oqt.setup_keymaps()` registers the following keymaps:

- `<leader>tn` - open the overseer shell task prompt, appends task to harpoon list
- `<leader>tv` - open then harpoon ui for the oqt list where tasks can be added, removed, or reordered
  - to add a new task from this ui, the shell command must be entered, tasks cannot be given names from this ui
- `<leader>tl` - open the float output window of the last task executed
- Numbered keymaps (`<n>` is a number from 1-9, e.g. `<leader>t1`, or `<leader>tv4`):
  - `<leader>t<n>` - execute task #`<n>` from the list, will notify via `vim.notify` when it completes
  - `<leader>tv<n>` - open float output of task #`<n>` from the list

Tasks executed from the list will show up in overseer's window
(`:OverseerToggle`) just like any other overseer tasks, any overseer action can
be applied to them like normal.

## Lua APIs

**oqt API**

- `oqt.prompt_new_task()` - open the overseer shell command prompt, adds resulting task to list
  - **note**: currently the `cwd` parameter is ignored
- `oqt.float_last_task()` - open float output window of last executed task
- `oqt.float_task(i)` - open float output window of task at index `i` in `"oqt"` harpoon list
  - `@param i number`
- `oqt.setup_keymaps()` - apply default keymaps

**harpoon API**

- `harpoon:list("oqt"):select(i)` - execute task at index `i`
  - `@field i number`
  - **note**: if task `i` is already running, it will kill it before starting it again
- `harpoon:list("oqt"):append(obj)` - add a new task to the end of the list
  - `@param obj { value: { name:string, cmd:string|string[] }}`
  - **note** you cannot call append with no args, this will result in an error, use `otq.prompt_new_task()` instead
- `harpoon:list("oqt"):get(i)` get element at index `i` from list
  - `@param i number`
  - `@return { value: { name:string, cmd:string|string[], _task_id?: number}}`
    - `_task_id` will only be set if the task has been executed, it does not persist

## Current issues

- Only supports shell tasks
