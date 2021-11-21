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
    "examples/basic_setup.lua",
    "examples/animated_sprites.lua",
    "examples/events.lua"
}
readme = "README.md"
format = "markdown"
style = true
no_lua_ref = true
