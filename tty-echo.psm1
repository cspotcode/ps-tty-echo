Import-Module "$PSScriptRoot/csharp-compiler.psm1"
if(Test-Path './TermiosInteropAssembly') {
    [Reflection.Assembly]::LoadFile((Resolve-Path './_compiled'))
} else {
    Compile-Csharp -SourceFile "$PSScriptRoot/TermiosInterop.cs" -Unsafe -OutputFile "$PSScriptRoot/TermiosInteropAssembly"
}

# Note to self: /usr/include/x86_64-linux-gnu/bits/termios.h

# Buffer that must be bigger than the termios struct on all platforms
[IntPtr]$buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(400)

# Byte and bit of termios struct that contains the echo flag
$echoBitDetected = $false
$byte_affected = -1
$bit_affected = -1 # <-- is a bitmask, not an index

$TCSANOW = 0

<#
Detect which bit in termios contains the echo flag.
We do this by turning echo on and off via `stty` and then observing the difference.
#>
Function detectEchoBit() {
    $termiosBefore = gettermios
    stty -echo
    $termiosEchoOff = gettermios
    stty echo
    $termiosEchoOn = gettermios
    settermios $termiosBefore
    ForEach($byte in 0..31) {
        if($termiosEchoOff."c_$byte" -ne $termiosEchoOn."c_$byte") {
            ([ref]$byte_affected).Value = $byte
            ([ref]$bit_affected).Value = $termiosEchoOff."c_$byte" -bxor $termiosEchoOn."c_$byte"
            return
        }
    }
    throw 'Unable to detect termios echo bit'
}

Function autoDetectEchoBit {
    if(-not $echoBitDetected) {
        detectEchoBit
        ([ref]$echoBitDetected).Value = $true
    }
}

function gettermios([int]$fd = 0) {
    [Cspotcode.TermiosInterop+Termios]$termios = [Cspotcode.TermiosInterop+Termios]::new()
    $failure = [Cspotcode.TermiosInterop]::tcgetattr($fd, $buffer)
    if($failure) { throw 'failure' }
    [Cspotcode.TermiosInterop]::BlitIntPtrToTermios($buffer, [ref]$termios)
    return ,$termios
}
Function settermios([Cspotcode.TermiosInterop+Termios]$termios, [int]$fd = 0) {
    [Cspotcode.TermiosInterop]::BlitTermiosToIntPtr($termios, $buffer)
    $failure = [Cspotcode.TermiosInterop]::tcsetattr($fd, $TCSANOW, $buffer)
    if($failure) { throw 'failure' }
}

Function SetEchoBit([ref][Cspotcode.TermiosInterop+Termios]$termios, $state) {
    autoDetectEchoBit
    if($state) {
        $termios.value."c_$byte_affected" = $termios.value."c_$byte_affected" -bor $bit_affected
    } else {
        $termios.value."c_$byte_affected" = $termios.value."c_$byte_affected" -band (-bnot $bit_affected)
    }
}

Function GetEchoBit([Cspotcode.TermiosInterop+Termios]$termios) {
    autoDetectEchoBit
    ($termios."c_$byte_affected" -band $bit_affected) -ne 0
}

Function Set-TtyEcho {
    param(
        [Parameter(Mandatory)]
        [boolean] $state
    )
    $termios = gettermios
    SetEchoBit ([ref]$termios) $state
    settermios $termios
}

Function Get-TtyEcho() {
    $termios = gettermios
    GetEchoBit $termios
}

Function getbytebitaffected {
    $byte_affected
    $bit_affected
}
