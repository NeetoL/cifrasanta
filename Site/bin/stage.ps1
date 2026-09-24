param([Parameter(Mandatory = $true)][string]$Destination)
$ErrorActionPreference = 'Stop'
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$targetRoot = [IO.Path]::GetFullPath($Destination)
if ($targetRoot -eq $sourceRoot) { throw 'Escolha uma pasta de destino diferente de Site.' }
$files = @(
    '.htaccess', '.gitignore', 'api.php', 'admin.php', 'admin-import.php', 'admin-fontes.php', 'assets/admin.css', 'assets/admin.js', 'app/Views/admin/kit.php',
    'app/server.php', 'app/Core/Database.php', 'app/Core/Service.php', 'app/Core/Playlists.php',
    'config/database.php', 'config/install.php'
)
$files += Get-ChildItem -LiteralPath (Join-Path $sourceRoot 'app/Import') -Filter '*.php' | ForEach-Object { 'app/Import/' + $_.Name }
$files += 'config/import-providers.example.php'
if ((Test-Path -LiteralPath (Join-Path $sourceRoot 'config/import-providers.php')) -and !(Test-Path -LiteralPath (Join-Path $targetRoot 'config/import-providers.php'))) { $files += 'config/import-providers.php' }
foreach ($file in $files) {
    $source = Join-Path $sourceRoot $file
    if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Arquivo necessário ausente: $file" }
}
foreach ($file in $files) {
    $target = Join-Path $targetRoot $file
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceRoot $file) -Destination $target -Force
}
Write-Output "API e painel preparados em $targetRoot"
Write-Output 'A chave de primeiro acesso e os scripts de testes não são publicados.'
