I was experiencing an issue while running PowerShell Core (`pwsh`) on Linux.  If I held down a key such as Delete (for example, to delete a large portion of a line) some of ANSI sequences are echoed to the console, leaving visual artifacts.

PSReadline cannot turn off TTY echo while reading user input.  If keystrokes are entered too fast, some will be output to the console.  This is especially problematic with escape codes, who render as something like this: `^[[4~`

The problem is that DotNet Core does not expose an API to turn off TTY echo.  It does so during a `ReadKey` call, but there's no way to ask DotNet to leave echo turned off; it turns it back on immediately after each `ReadKey` call.

TTY echo is enabled and disabled via Linux's `tcgetattr` and `tcsetattr` API calls which operate on a `termios` struct.  This struct varies by platform, making it dangerous and difficult to write a single cross-platform assembly that manipulates this data structure.

Linux has a `stty` utility that can turn echo on and off, but invoking an external binary before and after each prompt is too slow.

My solution is to turn on and off echo via `stty` and observe which bit in the data structure changes.  This is messy hack, but it lets us detect at runtime the bit we need to manipulate without compiling against platform-specific header files.  After that, we can call `tcgetattr` and `tcsetattr` in-process and flip the correct bit, without any process-spawning overhead.

## Other implementation details

"csharp-compiler.psm1" exposes a function to compile CSharp with the `/AllowUnsafe` flag on PowerShell Core.  It also lets us cache the compiled assembly to disk.

"TermiosInterop.cs" exposes bindings to `tcgetattr` and `tcsetattr` as well as a struct granting raw access to the first 32 bytes of a memory buffer.  This is enough to read the ECHO bit from Linux's termios struct.
