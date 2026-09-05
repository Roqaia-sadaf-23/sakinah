# Creates local signing artifacts, never prints passwords or overwrites keys.
# Run once on Windows; restore backups (not a new key) on another workstation.
param(
    [Parameter(Mandatory = $true)]
    [string]$KeytoolPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$androidRoot = Join-Path $projectRoot 'android'
$signingDirectory = Join-Path $androidRoot '.signing'
$propertiesPath = Join-Path $androidRoot 'key.properties'
$keystorePath = Join-Path $signingDirectory 'upload-keystore.p12'
$certificatePath = Join-Path $signingDirectory 'upload-certificate.pem'

if (-not (Test-Path -LiteralPath $KeytoolPath -PathType Leaf)) {
    throw 'Java keytool was not found.'
}
foreach ($target in @($signingDirectory, $propertiesPath)) {
    if (-not [IO.Path]::GetFullPath($target).StartsWith(
        $androidRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )) { throw 'Signing target is outside the Android project.' }
    if (Test-Path -LiteralPath $target) {
        throw 'Signing files already exist. Back them up and inspect them; never overwrite an upload key.'
    }
}

# Exclude other local accounts before generating any secret material.
$ownerSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
$systemSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-18')
$directoryAcl = [Security.AccessControl.DirectorySecurity]::new()
$directoryAcl.SetOwner($ownerSid)
$directoryAcl.SetAccessRuleProtection($true, $false)
foreach ($sid in @($ownerSid, $systemSid)) {
    $directoryAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
        $sid, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    ))
}
[void](New-Item -ItemType Directory -Path $signingDirectory)
Set-Acl -LiteralPath $signingDirectory -AclObject $directoryAcl

$secretBytes = [byte[]]::new(32)
$random = [Security.Cryptography.RandomNumberGenerator]::Create()
$random.GetBytes($secretBytes)
$random.Dispose()
$signingPassword = [Convert]::ToBase64String($secretBytes)
[Array]::Clear($secretBytes, 0, $secretBytes.Length)

function Invoke-PrivateKeytool([string]$Arguments) {
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $KeytoolPath
    $startInfo.Arguments = $Arguments
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    # The password is not part of a command line, shell history or tool output.
    $startInfo.EnvironmentVariables['SAKINAH_UPLOAD_PASSWORD'] = $signingPassword
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    [void]$stdout.GetAwaiter().GetResult()
    [void]$stderr.GetAwaiter().GetResult()
    $code = $process.ExitCode
    $process.Dispose()
    if ($code -ne 0) { throw "keytool failed (exit $code); no passwords were logged." }
}

try {
    # Persist the password first, so even an interrupted generation is recoverable.
    $stream = [IO.File]::Open($propertiesPath, 'CreateNew', 'Write', 'None')
    $stream.Dispose()
    $fileAcl = [Security.AccessControl.FileSecurity]::new()
    $fileAcl.SetOwner($ownerSid)
    $fileAcl.SetAccessRuleProtection($true, $false)
    foreach ($sid in @($ownerSid, $systemSid)) {
        $fileAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
            $sid, 'FullControl', 'Allow'
        ))
    }
    Set-Acl -LiteralPath $propertiesPath -AclObject $fileAcl
    $stream = [IO.File]::Open($propertiesPath, 'Open', 'Write', 'None')
    try {
        $properties = "storePassword=$signingPassword`nkeyPassword=$signingPassword`nkeyAlias=upload`nstoreFile=.signing/upload-keystore.p12`n"
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($properties)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
        [Array]::Clear($bytes, 0, $bytes.Length)
    } finally { $stream.Dispose() }

    Invoke-PrivateKeytool "-genkeypair -keystore `"$keystorePath`" -storetype PKCS12 -alias upload -keyalg RSA -keysize 3072 -sigalg SHA256withRSA -validity 10000 -dname `"CN=Sakinah Upload, O=Roqaia Apps`" -storepass:env SAKINAH_UPLOAD_PASSWORD -keypass:env SAKINAH_UPLOAD_PASSWORD -noprompt"
    Invoke-PrivateKeytool "-exportcert -rfc -keystore `"$keystorePath`" -storetype PKCS12 -alias upload -storepass:env SAKINAH_UPLOAD_PASSWORD -file `"$certificatePath`""
    Write-Output 'Created upload keystore, public certificate and key.properties with restricted local permissions. No passwords printed.'
} finally {
    $signingPassword = $null
    $properties = $null
}
