-- If multiple files are listed then ldoc reports "module not found" errors
-- to ghost line numbers.
-- https://github.com/lunarmodules/LDoc/issues/351
--file = {"src/slime.lua", "src/simpleanim.lua"}
file = {"src/slime.lua"}
project = "SLIME"
title = "slime api"
description = "point-and-click adventure game library."
all = true
sort = true
prettify_files = "show"
examples = {
    "examples/basics",
    exclude = {
            "examples/basics/conf.lua",
            "examples/basics/slime.lua",
            "examples/basics/simpleanim.lua"
    }
}
readme = "README.md"
format = "markdown"
style = true
no_lua_ref = true
