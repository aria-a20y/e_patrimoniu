# generate_review_input.ps1
# Genereaza un singur fisier text cu tot codul sursa relevant pentru security review.
# Ruleaza din folderul radacina al proiectului:
#   powershell -ExecutionPolicy Bypass -File generate_review_input.ps1

$rootDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputFile = Join-Path $rootDir "FULL_SOURCE_FOR_REVIEW.txt"

# ── Directoare si fisiere de EXCLUS ──────────────────────────────────────────
$excludeDirs = @(
    'build', '.dart_tool', '.idea', '.git', '.metadata',
    'node_modules', '.flib', 'web\flutter_service_worker.js'
)

# ── Extensii de inclus ────────────────────────────────────────────────────────
$includedExtensions = @('.dart', '.js', '.yaml', '.json', '.env.example')

# ── Fisiere specifice de inclus intotdeauna ────────────────────────────────────
$alwaysInclude = @(
    'pubspec.yaml',
    'vercel.json',
    'backend\package.json',
    'backend\render.yaml'
)

# ── Fisiere de EXCLUS explicit ────────────────────────────────────────────────
$alwaysExclude = @(
    'pubspec.lock',
    'package-lock.json',
    'flutter_debug.log',
    'flutter_analyze.log',
    'FULL_SOURCE_FOR_REVIEW.txt',
    'SECURITY_REVIEW_PROMPT.md'
)

Write-Host "Generez FULL_SOURCE_FOR_REVIEW.txt ..." -ForegroundColor Cyan

$output = [System.Text.StringBuilder]::new()
[void]$output.AppendLine("=" * 80)
[void]$output.AppendLine("E-PATRIMONIU — FULL SOURCE CODE FOR SECURITY REVIEW")
[void]$output.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$output.AppendLine("Root: $rootDir")
[void]$output.AppendLine("=" * 80)
[void]$output.AppendLine("")

$fileCount = 0

Get-ChildItem -Path $rootDir -Recurse -File | ForEach-Object {
    $file = $_
    $relativePath = $file.FullName.Substring($rootDir.Length + 1)

    # Excludem directoarele nedorite
    foreach ($excl in $excludeDirs) {
        if ($relativePath -like "$excl\*" -or $relativePath -like "$excl/*") {
            return
        }
    }

    # Excludem fisierele explicite
    if ($alwaysExclude -contains $file.Name) { return }
    if ($alwaysExclude -contains $relativePath) { return }

    # Excludem fisierele generate de Dart (.g.dart, .freezed.dart)
    if ($file.Name -match '\.g\.dart$' -or $file.Name -match '\.freezed\.dart$') { return }

    # Includem doar extensiile relevante
    if ($includedExtensions -notcontains $file.Extension) {
        # Verificam daca e in lista alwaysInclude
        $isAlways = $false
        foreach ($a in $alwaysInclude) {
            if ($relativePath -eq $a -or $relativePath -eq $a.Replace('\', '/')) {
                $isAlways = $true; break
            }
        }
        if (-not $isAlways) { return }
    }

    # Excludem fisierele prea mari (> 200 KB — probabil generate)
    if ($file.Length -gt 200KB) { return }

    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
    } catch {
        return
    }

    if ([string]::IsNullOrWhiteSpace($content)) { return }

    [void]$output.AppendLine("")
    [void]$output.AppendLine("─" * 80)
    [void]$output.AppendLine("FILE: $relativePath")
    [void]$output.AppendLine("SIZE: $($file.Length) bytes  |  MODIFIED: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))")
    [void]$output.AppendLine("─" * 80)
    [void]$output.AppendLine($content)

    $fileCount++
    Write-Host "  + $relativePath" -ForegroundColor Gray
}

[void]$output.AppendLine("")
[void]$output.AppendLine("=" * 80)
[void]$output.AppendLine("TOTAL FILES INCLUDED: $fileCount")
[void]$output.AppendLine("=" * 80)

# Scriem fisierul de iesire
[System.IO.File]::WriteAllText($outputFile, $output.ToString(), [System.Text.Encoding]::UTF8)

$sizeKB = [math]::Round((Get-Item $outputFile).Length / 1KB, 1)
Write-Host ""
Write-Host "Gata! Fisier generat: FULL_SOURCE_FOR_REVIEW.txt ($sizeKB KB, $fileCount fisiere)" -ForegroundColor Green
Write-Host ""
Write-Host "Urmatorii pasi:" -ForegroundColor Yellow
Write-Host "  1. Deschide SECURITY_REVIEW_PROMPT.md si copiaza continutul"
Write-Host "  2. Intr-un chat nou cu AI-ul ales, incarca FULL_SOURCE_FOR_REVIEW.txt"
Write-Host "  3. Lipeste continutul promptului si trimite"
Write-Host ""
pause
