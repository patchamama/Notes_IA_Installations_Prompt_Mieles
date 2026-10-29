$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$raw = [Console]::In.ReadToEnd()
$j = $raw | ConvertFrom-Json

# ---- colours (ANSI) -------------------------------------------------------------------------------
$e = [char]27
$RESET = "$e[0m"
function C($code, $text) { return "$e[${code}m$text$RESET" }
$DIM = '2'; $BOLD = '1'
$GREEN = '38;5;78'; $YELLOW = '38;5;220'; $ORANGE = '38;5;208'; $RED = '38;5;203'
$CYAN = '38;5;81'; $BLUE = '38;5;75'; $MAGENTA = '38;5;176'; $GRAY = '38;5;244'
$FULL = [string][char]0x2588; $EMPTY = [string][char]0x2591; $SEP = " $(C $GRAY ([string][char]0x2502)) "

# Green below 50%, yellow below 75%, orange below 90%, red from there.
function LevelColor([double]$pct) {
  if ($pct -ge 90) { return $RED }
  if ($pct -ge 75) { return $ORANGE }
  if ($pct -ge 50) { return $YELLOW }
  return $GREEN
}

function Bar([double]$pct, [int]$width = 8) {
  $pct = [math]::Max(0, [math]::Min(100, $pct))
  $filled = [int][math]::Round($pct / 100 * $width)
  $color = LevelColor $pct
  return (C $color ($FULL * $filled)) + (C $GRAY ($EMPTY * ($width - $filled)))
}

function Meter($label, [double]$pct, $suffix = '') {
  $color = LevelColor $pct
  $text = "$(C $GRAY $label) $(Bar $pct) $(C $BOLD (C $color ('{0}%' -f [int]$pct)))"
  if ($suffix) { $text += ' ' + (C $GRAY $suffix) }
  return $text
}

function Remaining($epoch) {
  if (-not $epoch) { return '?' }
  $span = [DateTimeOffset]::FromUnixTimeSeconds([int64]$epoch) - [DateTimeOffset]::UtcNow
  if ($span.TotalSeconds -le 0) { return 'now' }
  if ($span.TotalHours -ge 24) { return ('{0}d{1}h' -f [int]$span.Days, $span.Hours) }
  if ($span.TotalHours -ge 1) { return ('{0}h{1:00}m' -f [int]$span.TotalHours, $span.Minutes) }
  return ('{0}m' -f [int][math]::Ceiling($span.TotalMinutes))
}

# ---- background tasks ----------------------------------------------------------------------------
# The status line input does not list them, so they are read from the tail of the session
# transcript: launches versus completion notifications.
function BackgroundTasks($path) {
  if (-not $path -or -not (Test-Path -LiteralPath $path)) { return $null }
  $fs = [System.IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
  try {
    $window = 800KB
    if ($fs.Length -gt $window) { $fs.Seek(-$window, 'End') | Out-Null }
    $text = (New-Object System.IO.StreamReader($fs, [Text.Encoding]::UTF8)).ReadToEnd()
  } finally { $fs.Dispose() }

  $started = [ordered]@{}
  foreach ($m in [regex]::Matches($text, 'running in background with ID: ([A-Za-z0-9_-]+)|agentId: ([A-Za-z0-9_-]+)')) {
    $id = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
    $started[$id] = $true
  }
  $done = @{}
  $last = $null
  foreach ($m in [regex]::Matches($text, 'task-id>([A-Za-z0-9_-]+)</task-id>.{0,600}?<status>(\w+)</status>(?:.{0,400}?<summary>(.*?)</summary>)?')) {
    $done[$m.Groups[1].Value] = $m.Groups[2].Value
    $last = @{ status = $m.Groups[2].Value; summary = $m.Groups[3].Value }
  }
  $running = @($started.Keys | Where-Object { -not $done.ContainsKey($_) }).Count

  $parts = @()
  if ($running -gt 0) { $parts += (C $MAGENTA ("bg {0} running" -f $running)) }
  if ($last) {
    $kind = if ($last.summary -match 'pytest|\btests?\b') { 'tests' } else { 'task' }
    $exit = if ($last.summary -match 'exit code (\d+)') { ' (exit ' + $Matches[1] + ')' } else { '' }
    $ok = $last.status -eq 'completed'
    $parts += (C ($(if ($ok) { $GREEN } else { $RED })) ("last {0}: {1}{2}" -f $kind, $(if ($ok) { 'OK' } else { $last.status.ToUpper() }), $exit))
  }
  if ($parts.Count -eq 0) { return $null }
  return ($parts -join (C $GRAY ', '))
}

# ---- pytest suite progress -----------------------------------------------------------------------
# The newest recently-written log in this session's scratchpad / background-task folders
# (cheap: two folders, recent files only).
function SuiteProgress($sessionId) {
  if (-not $sessionId) { return $null }
  $root = Join-Path $env:TEMP 'claude'
  if (-not (Test-Path $root)) { return $null }
  $cutoff = (Get-Date).AddMinutes(-30)
  $file = Get-ChildItem -Path (Join-Path $root "*\$sessionId\scratchpad\*.log"), (Join-Path $root "*\$sessionId\tasks\*.output") -File |
    Where-Object { $_.LastWriteTime -gt $cutoff } | Sort-Object LastWriteTime -Descending |
    Where-Object {
      $fs = [System.IO.File]::Open($_.FullName, 'Open', 'Read', 'ReadWrite')
      try { if ($fs.Length -gt 16384) { $fs.Seek(-16384, 'End') | Out-Null }
            $script:suiteTail = (New-Object System.IO.StreamReader($fs)).ReadToEnd() } finally { $fs.Dispose() }
      $script:suiteTail -match '(?m)^[\.FEsxX]{10,}' -or $script:suiteTail -match '\d+ (passed|failed|error)[^\r\n]* in [\d\.]+s'
    } | Select-Object -First 1
  if (-not $file) { return $null }
  $tail = $script:suiteTail
  if ($tail -match '(\d+) (passed|failed|error)[^\r\n]* in [\d\.]+s') {
    $failed = $tail -match '\d+ (failed|error)'
    $time = $Matches[0].Split(' in ')[-1]
    return (C ($(if ($failed) { $RED } else { $GREEN })) ("suite {0} {1}" -f $(if ($failed) { 'FAIL' } else { 'PASS' }), $time))
  }
  $percent = $null
  foreach ($m in [regex]::Matches($tail, '\[\s*(\d+)%\]')) { $percent = [int]$m.Groups[1].Value }
  if ($null -eq $percent) { return $null }
  $bad = 0
  foreach ($line in ($tail -split "`r?`n" | Where-Object { $_ -match '^[\.FEsxX]+(\s+\[\s*\d+%\])?\s*$' })) { $bad += ([regex]::Matches($line, '[FE]')).Count }
  $stale = ((Get-Date) - $file.LastWriteTime).TotalSeconds -gt 120
  # A suite's own progress is not a warning level: blue while healthy, red as soon as a test failed.
  $barColor = if ($bad) { $RED } elseif ($stale) { $ORANGE } else { $BLUE }
  $filled = [int][math]::Round($percent / 100 * 8)
  $bar = (C $barColor ($FULL * $filled)) + (C $GRAY ($EMPTY * (8 - $filled)))
  $text = "$(C $GRAY 'suite') $bar $(C $BOLD (C $barColor ('{0}%' -f $percent)))"
  if ($bad) { $text += ' ' + (C $RED ("{0}F" -f $bad)) }
  if ($stale) { $text += ' ' + (C $ORANGE 'stalled?') }
  return $text
}

# ---- assemble ------------------------------------------------------------------------------------
$parts = @()
if ($j.model.display_name) { $parts += (C $BOLD (C $CYAN $j.model.display_name)) }
if ($j.workspace.current_dir) { $parts += (C $BLUE (Split-Path -Leaf $j.workspace.current_dir)) }

$cw = $j.context_window
if ($cw -and $null -ne $cw.used_percentage) {
  $size = [int]$cw.context_window_size
  $used = [int]([double]$cw.used_percentage / 100 * $size)
  $parts += (Meter 'ctx' ([double]$cw.used_percentage) ('{0}k/{1}k' -f [int]($used / 1000), [int]($size / 1000)))
}

$rl = $j.rate_limits
if ($rl) {
  if ($rl.five_hour) { $parts += (Meter '5h' ([double]$rl.five_hour.used_percentage) ('resets ' + (Remaining $rl.five_hour.resets_at))) }
  if ($rl.seven_day) { $parts += (Meter '7d' ([double]$rl.seven_day.used_percentage) ('resets ' + (Remaining $rl.seven_day.resets_at))) }
}

$suite = SuiteProgress $j.session_id
if ($suite) { $parts += $suite }

$bg = BackgroundTasks $j.transcript_path
if ($bg) { $parts += $bg }

[Console]::Out.Write(($parts -join $SEP))
