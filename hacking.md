# Documentation

Requirements

- Lua 5.2
- LuaRocks

## Dependencies

- apt-get install lua5.2-dev
- luarocks install penlight

## Troubleshooting

You Get: `bad argument #1 to 'load' (function expected, got string)`
Solution: Install Lua 5.2

You Get: `module 'pl.class' not found`
Solution: Install penlight

You Get: `src/lfs.c:84:10: fatal error: lua.h: No such file or directory`
Solution: Install lua5.2-dev
