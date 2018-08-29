import-module ./compile.psm1 -force
$erroractionpreference = 'stop'

# $signature = @'
# [DllImport("libc")]
# public static extern int tcgetattr(
#     int fd,
#     IntPtr termios_p
# );
# '@ 

# $type = Add-Type -MemberDefinition $signature `
#     -Name termios -Namespace tcgetattr `
#     -PassThru

compileUnsafe (get-content -raw termios.cs)

[IntPtr]$buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(400)
[long]$num = $buffer[0]
function binary([int]$num, $size = 64) {
    [Convert]::ToString($num, 2).padleft($size, '0') # 1010
}
function gettermios([int]$fd = 0) {
	[TermiosInterop.Termios]$termios = [TermiosInterop.Termios]::new()
	[TermiosInterop.TermiosInterop]::tcgetattr($fd, $buffer)
	[TermiosInterop.TermiosInterop]::BlitIntPtrToTermios($buffer, [ref]$termios)
    $termios
}
function logTermios($termios, $start = 0, $finish = 8) {
    #binary $termios.c_iflag
    #binary $termios.c_oflag
    #binary $termios.c_cflag
    $start..$finish | % {
        [pscustomobject]@{index = $_; binary = (binary $termios."c_$_" 8)}
    }
}

# echo 'new'
$termios = [TermiosInterop.Termios]::new()
# logTermios $termios

# echo 'blit to intptr'
[TermiosInterop.TermiosInterop]::BlitTermiosToIntPtr($termios, $buffer)
# logTermios $termios

# echo 'blit back to termios'
[TermiosInterop.TermiosInterop]::BlitIntPtrToTermios($buffer, [ref]$termios)
# logTermios $termios

echo 'echo off'
stty -echo
$termios = gettermios 0
$offLog = logTermios $termios 0 31
$offLog

echo 'echo on'
stty echo
$termios = gettermios 0
$onLog = logTermios $termios 0 31
$onLog

echo 'diff'
Compare-Object $offLog $onLog

# enable echo via
# $termios.c_12 |= 8

# $buffer

# [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
#     public struct Termios {
#         public int State;    // State of this storage, one of DFS_STORAGE_STATE_*, possibly ORd with DFS_STORAGE_STATE_ACTIVE        
#         [MarshalAs(UnmanagedType.LPWStr)] public string ServerName; // Name of server hosting this storage
#         [MarshalAs(UnmanagedType.LPWStr)] public string ShareName;    // Name of share hosting this storage
#     }