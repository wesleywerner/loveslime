# Unit Testing

Testing and code coverage uses the busted and luacov libraries. Busted auto generates code coverage statistics (luacov.stats.out).

## Dependencies

- luarocks install busted
- luarocks install luacov

Run tests:

```
busted
```

Generate coverage report (luacov.report.out):

```
luacov
```

# Documentation

Generated from source comments with the LDoc library, output into the `doc` directory:

```
lua LDoc\ldoc.lua .
```

Requirements:

- Lua 5.2

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
