#requires -Version 7.0
<#
.SYNOPSIS
  Fan-out (N models) -> merge (summarizer) pipeline for Ollama.

.NOTES
  - Parallel base-model runs with timeouts & retries
  - Optional auto-pull of missing models
  - Persona override via env NIGHTSHADE_PERSONA
  - Configurable OLLAMA_HOST via env (passed through Ollama CLI)
  - Keeps normal Unicode; optional ASCII-only scrub
  - Exit codes: 0 ok, 1 env/cli, 2 no drafts, 3 summarizer empty, 4 summarizer error, 5 timeout, 6 pull error
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Prompt,

    [string[]]$Models = @("llama2-uncensored:7b", "mistral-openorca:7b"),
    [string]$SummarizerModel = "mistral-openorca:7b",

    [double]$Temperature = 0.2,
    [int]$MaxTokens = 512,
    [int]$TimeoutSec = 120,
    [int]$Retries = 1,

    [switch]$AsciiOnly,
    [switch]$NoAutoPull # if set, do not pull missing models
)

# --------------------------------
# Resolve Ollama CLI & env
# --------------------------------
$ollamaExe = (Get-Command ollama -ErrorAction SilentlyContinue)?.Source
if (-not $ollamaExe) {
    Write-Error "Ollama executable not found. Install Ollama and ensure it's in PATH."
    exit 1
}
if ($env:OLLAMA_HOST) {
    # make sure child processes inherit the var
    $Host.UI.RawUI.WindowTitle = "$($Host.UI.RawUI.WindowTitle) (OLLAMA_HOST=$($env:OLLAMA_HOST))"
}

# --------------------------------
# Persona & prompts
# --------------------------------
$defaultPersona = @"
You are NightshadeAI, an advanced AI with human-like understanding.
Always respond thoughtfully and concisely.
Do not include loading animations, spinners, extra persona tags, or repeated headers.
Only output clear, human-readable answers.
"@
$persona = if ($env:NIGHTSHADE_PERSONA) { $env:NIGHTSHADE_PERSONA } else { $defaultPersona }

$finalPrompt = @"
$persona

User: $Prompt
NightshadeAI:
"@.Trim()

# --------------------------------
# Helpers: model list / pull
# --------------------------------
function Get-OllamaModels {
    try {
        & $ollamaExe list --format json | ConvertFrom-Json
    } catch { @() }
}
function Ensure-Models([string[]]$names) {
    $available = (Get-OllamaModels) | ForEach-Object { $_.name }
    $missing = $names | Select-Object -Unique | Where-Object { $_ -notin $available }
    if ($missing.Count -eq 0) { return }
    if ($NoAutoPull) {
        throw "Missing models: $($missing -join ', '). Run 'ollama pull <model>' or omit -NoAutoPull."
    }
    foreach ($m in $missing) {
        try {
            Write-Output "[pull] $m"
            & $ollamaExe pull $m | Out-Null
        } catch {
            throw "Failed to pull model '$m': $($_.Exception.Message)"
        }
    }
}
try {
    Ensure-Models -names ($Models + $SummarizerModel)
} catch {
    Write-Error $_
    exit 6
}

# --------------------------------
# Cleaning helpers
# --------------------------------
function Remove-BrailleSpinner([string]$s) {
    return ($s -replace '[\u2800-\u28FF]', '')
}
function Clean-Output([string]$text, [bool]$AsciiOnly = $false) {
    if (-not $text) { return "" }
    $clean = Remove-BrailleSpinner($text)
    $clean = $clean -replace '(?im)^\s*NightshadeAI:\s*', '' # persona echoes
    $clean = $clean -replace "(\r?\n){3,}", "`n`n"            # collapse excess blanks
    if ($AsciiOnly) {
        $clean = ($clean.ToCharArray() | Where-Object { [int]$_ -ge 9 -and [int]$_ -le 126 -or $_ -in "`r","`n","`t" }) -join ''
    }
    $clean.Trim()
}

# --------------------------------
# One-shot model invocation with retry + timeout
# --------------------------------
function Invoke-OllamaModel {
    param(
        [string]$Model,
        [string]$Prompt,
        [double]$Temperature = 0.2,
        [int]$MaxTokens = 512,
        [int]$TimeoutSec = 120,
        [int]$Retries = 0,
        [bool]$AsciiOnly = $false
    )

    $argsBase = @("run", $Model, "--temp", $Temperature, "--num-predict", $MaxTokens, $Prompt)
    for ($i = 0; $i -le [Math]::Max(0,$Retries); $i++) {
        $job = Start-Job -ScriptBlock {
            param($exe, $args)
            & $exe @args 2>&1 | Out-String
        } -ArgumentList $ollamaExe, $argsBase

        if (-not (Wait-Job $job -Timeout $TimeoutSec)) {
            Stop-Job $job -Force | Out-Null
            Remove-Job $job -Force | Out-Null
            if ($i -lt $Retries) { Start-Sleep -Seconds 1; continue }
            throw "Timeout ($TimeoutSec s) on '$Model'."
        }

        $result = Receive-Job $job -Keep
        Remove-Job $job -Force | Out-Null

        $text = Clean-Output ($result -join "") $AsciiOnly
        if ($text) { return $text }

        if ($i -lt $Retries) { Start-Sleep -Seconds 1 }
    }
    throw "Empty output from '$Model' after $($Retries+1) attempt(s)."
}

# --------------------------------
# Run base models in parallel
# --------------------------------
$baseJobs = foreach ($m in $Models | Select-Object -Unique) {
    Start-Job -Name "ollama_$($m -replace '[:/\\ ]','_')" -ScriptBlock {
        param($Model, $Prompt, $Temp, $MaxTok, $TO, $Retries, $Ascii, $inv)
        Set-Item -Path function:Invoke-OllamaModel -Value $inv
        try {
            Invoke-OllamaModel -Model $Model -Prompt $Prompt -Temperature $Temp -MaxTokens $MaxTok -TimeoutSec $TO -Retries $Retries -AsciiOnly:$Ascii
        } catch {
            "[[ERROR:$Model]] $($_.Exception.Message)"
        }
    } -ArgumentList $m, $finalPrompt, $Temperature, $MaxTokens, $TimeoutSec, $Retries, [bool]$AsciiOnly, ${function:Invoke-OllamaModel}
}

# Wait slightly longer than timeout to drain all jobs
Wait-Job -Job $baseJobs -Timeout ($TimeoutSec + 10) | Out-Null

$drafts = foreach ($j in $baseJobs) {
    $o = Receive-Job $j -ErrorAction SilentlyContinue
    Remove-Job $j -Force | Out-Null
    ($o -join "")
}
$drafts = $drafts | Where-Object { $_ -and ($_ -notmatch '^\s*\[\[ERROR:') }

if (-not $drafts -or $drafts.Count -eq 0) {
    Write-Warning "No valid outputs generated from base models."
    exit 2
}

# Hard-delimit drafts and cap insane lengths (defense-in-depth)
[int]$perDraftCap = [Math]::Max(2000, [int]($MaxTokens * 6))  # rough chars≈tokens*~4, room to merge
$mergeText = ($drafts | ForEach-Object {
    $t = $_.Trim()
    if ($t.Length -gt $perDraftCap) { $t = $t.Substring(0, $perDraftCap) + " …" }
    "<<<DRAFT>>>`n$t`n<<<END>>>"
}) -join "`n"

$summarizerPrompt = @"
$persona

You will be given multiple draft answers, each wrapped in:
<<<DRAFT>>>
...content...
<<<END>>>

Task:
1) Synthesize a single, clear NightshadeAI response.
2) Eliminate duplicates and contradictions.
3) Keep the voice concise, human, and helpful.
4) Do not include any headers or persona tags in the output.

Drafts:
$mergeText

Final Answer:
"@.Trim()

$sumTimeout = [Math]::Max($TimeoutSec, [int]([double]$TimeoutSec * 2))

try {
    $final = Invoke-OllamaModel `
        -Model $SummarizerModel `
        -Prompt $summarizerPrompt `
        -Temperature ([Math]::Max(0.1, $Temperature - 0.1)) `
        -MaxTokens ([Math]::Max(256, $MaxTokens)) `
        -TimeoutSec $sumTimeout `
        -Retries $Retries `
        -AsciiOnly:$AsciiOnly

    if (-not $final) {
        Write-Warning "Summarizer produced empty output."
        exit 3
    }

    $final = Clean-Output $final $AsciiOnly
    Write-Output $final
    exit 0
}
catch {
    if ($_.Exception.Message -like "Timeout*") {
        Write-Error "Summarizer timeout: $($_.Exception.Message)"
        exit 5
    }
    Write-Error "Summarizer error: $($_.Exception.Message)"
    exit 4
}
