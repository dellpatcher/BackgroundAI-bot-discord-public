param(
    [string]$Prompt
)

# -----------------------------
# Auto-detect Ollama executable
# -----------------------------
$ollamaExe = (Get-Command ollama -ErrorAction SilentlyContinue).Source
if (-not $ollamaExe) {
    Write-Output "❌ Ollama executable not found. Install Ollama and ensure it's in PATH."
    exit 1
}

# -----------------------------
# Models
# -----------------------------
$models = @("llama2-uncensored:7b", "mistral-openorca:7b")
$finalModel = "mistral-openorca:7b"  # Summarizer model

# -----------------------------
# Persona Prompt
# -----------------------------
$persona = @"
You are NightshadeAI, an advanced AI with human-like understanding.
Always respond thoughtfully and concisely.
Do not include loading animations, spinners, extra persona tags, or repeated headers.
Only output clear, human-readable answers.
"@

$finalPrompt = "$persona`nUser: $Prompt`nNightshadeAI:"

# -----------------------------
# Safe file reading
# -----------------------------
function Read-FileSafely($filePath) {
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $decoder = New-Object System.Text.UTF8Encoding($false, $false)
    return $decoder.GetString($bytes)
}

# -----------------------------
# Clean model output
# -----------------------------
function Clean-Output($text) {
    $clean = $text -replace '[\u2800-\u28FF]', ''        # Remove braille spinners
    $clean = $clean -replace '[^\x20-\x7E\r\n]', ''      # Remove other non-printable/unicode
    $clean = $clean -replace 'NightshadeAI:', ''         # Remove repeated persona tags
    return $clean.Trim()
}

# -----------------------------
# Run base models
# -----------------------------
$outputs = @()
foreach ($m in $models) {
    try {
        $tempFile = "$env:TEMP\STDOUT_$($m.Replace(':','_')).txt"
        $process = Start-Process -FilePath $ollamaExe `
            -ArgumentList @("run", $m, $finalPrompt) `
            -NoNewWindow -RedirectStandardOutput $tempFile -PassThru
        $process.WaitForExit()

        $raw = Read-FileSafely($tempFile)
        $clean = Clean-Output($raw)
        if ($clean) { $outputs += $clean }

        Remove-Item $tempFile -Force
    }
    catch {
        Write-Output "⚠️ Error running model '$m': $_"
    }
}

# -----------------------------
# Summarizer: merge into unified NightshadeAI response
# -----------------------------
if ($outputs.Count -gt 0) {
    $mergeText = $outputs -join "`n---`n"

    $summarizerPrompt = @"
$persona

The following are draft answers from multiple NightshadeAI modules:

$mergeText

Please merge them into a single, clear, human-readable NightshadeAI response.
Avoid duplication and keep the voice consistent.
Final Answer:
"@

    $tempFile = "$env:TEMP\STDOUT_FINAL.txt"
    $process = Start-Process -FilePath $ollamaExe `
        -ArgumentList @("run", $finalModel, $summarizerPrompt) `
        -NoNewWindow -RedirectStandardOutput $tempFile -PassThru
    $process.WaitForExit()

    $rawFinal = Read-FileSafely($tempFile)
    $finalAnswer = Clean-Output($rawFinal)

    Remove-Item $tempFile -Force
    Write-Output $finalAnswer
} else {
    Write-Output "⚠️ No outputs generated from base models."
}

}

