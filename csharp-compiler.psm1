# From https://stackoverflow.com/a/48103035/531727

function Compile-CSharp {
    [CmdletBinding(DefaultParameterSetName='FromFile')]
    param(
        [Parameter(Mandatory, ParameterSetName='FromFile', Position=0)]
        $SourceFile,
        [Parameter(Mandatory, ParameterSetName='FromText', Position=0)]
        $SourceText,
        $OutputFile,
        [switch]$NoLoadAssembly,
        [switch]$Unsafe
    )
    if(-not $SourceText) {
        $SourceText = Get-Content -Raw $SourceFile
    }
    # set of C# compilation parameters
    $lst = [Collections.Generic.List[Microsoft.CodeAnalysis.SyntaxTree]]::new()
    $lst.Add([Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText($SourceText))

    [Microsoft.CodeAnalysis.MetadataReference[]]$ref = @(
        [Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile(
            [Object].Assembly.Location
        )
    )
    $opt = [Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new(
        [Microsoft.CodeAnalysis.OutputKind]::DynamicallyLinkedLibrary
    )
    if($Unsafe) {
        [Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions].GetProperty(
            'AllowUnsafe' # because we're using unsafe code
        ).SetValue($opt, $true)
    }
    # let's rock!
    $cmp = [Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create(
        [IO.Path]::GetRandomFilename(), $lst, $ref, $opt
    )

    try {
        $ms = [IO.MemoryStream]::new()

        if(!($err = $cmp.Emit($ms)).Success) { return $err }
        [void]$ms.Seek(0, [IO.SeekOrigin]::Begin)
        if(-not $NoLoadAssembly) {
            $asm = [Reflection.Assembly]::Load($ms.ToArray())
        }
        if($OutputFile) {
            [void]$ms.Seek(0, [IO.SeekOrigin]::Begin)
            $file = [IO.File]::Create($OutputFile)
            $ms.CopyTo($file)
            $file.Close()
        }
    }
    catch { $_ }
    finally {
        if ($ms) { $ms.Dispose() }
    }
}
