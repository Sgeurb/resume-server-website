
# ==========================================================
# KNOWING 3.0 - Live Internet Fact Ticker
# Windows PowerShell 5.1
#
# Features:
# - Live facts from the Useless Facts API
# - New fact every 90 seconds
# - Each fact scrolls only once
# - Non-blocking internet requests
# - Duplicate detection
# - Offline fallback facts
# - Borderless, draggable, always-on-top window
# - Close button
# ==========================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ----------------------------------------------------------
# SETTINGS
# ----------------------------------------------------------

$factIntervalSeconds = 90
$scrollPixels = 2
$animationInterval = 40

$apiUrl = 'https://uselessfacts.jsph.pl/api/v2/facts/random?language=en'

$offlineFacts = @(
    'Octopuses have three hearts.',
    'The first computer mouse was made of wood.',
    'Honeybees communicate through a waggle dance.',
    'A day on Venus is longer than its year.',
    'Sharks existed before trees.',
    'An IPv4 address contains 32 bits.',
    'DNS translates domain names into IP addresses.',
    'Linux was first released in 1991.',
    'The Moon is slowly moving away from Earth.',
    'The first website went online in 1991.'
)

# ----------------------------------------------------------
# COLORS
# ----------------------------------------------------------

$background = [System.Drawing.Color]::FromArgb(25, 29, 38)
$foreground = [System.Drawing.Color]::FromArgb(230, 235, 245)
$accent = [System.Drawing.Color]::FromArgb(90, 190, 240)

# ----------------------------------------------------------
# MAIN WINDOW
# ----------------------------------------------------------

$form = New-Object System.Windows.Forms.Form

$form.Text = 'Knowing 3.0'
$form.FormBorderStyle = 'None'
$form.StartPosition = 'Manual'
$form.ClientSize = New-Object System.Drawing.Size(650, 48)
$form.BackColor = $background
$form.TopMost = $true
$form.ShowInTaskbar = $true

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

$form.Location = New-Object System.Drawing.Point(
    ($screen.Right - $form.Width - 10),
    ($screen.Bottom - $form.Height - 10)
)

# ----------------------------------------------------------
# TITLE
# ----------------------------------------------------------

$title = New-Object System.Windows.Forms.Label

$title.Text = 'Knowing'
$title.ForeColor = $accent
$title.BackColor = $background

$title.Font = New-Object System.Drawing.Font(
    'Segoe UI',
    9,
    [System.Drawing.FontStyle]::Bold
)

$title.Location = New-Object System.Drawing.Point(12, 15)
$title.Size = New-Object System.Drawing.Size(70, 20)

$form.Controls.Add($title)

# ----------------------------------------------------------
# TICKER PANEL
# ----------------------------------------------------------

$ticker = New-Object System.Windows.Forms.Panel

$ticker.Location = New-Object System.Drawing.Point(90, 8)
$ticker.Size = New-Object System.Drawing.Size(520, 32)
$ticker.BackColor = $background

$form.Controls.Add($ticker)

$font = New-Object System.Drawing.Font('Segoe UI', 11)
$brush = New-Object System.Drawing.SolidBrush($foreground)

# ----------------------------------------------------------
# APPLICATION STATE
# ----------------------------------------------------------

$script:currentFact = ''
$script:offset = $ticker.Width
$script:factFinished = $true
$script:lastFactChange = [DateTime]::MinValue
$script:fetchJob = $null
$script:seenFacts = @{}
$script:offlineIndex = 0

# ----------------------------------------------------------
# FACT DISPLAY FUNCTION
# ----------------------------------------------------------

function Show-KnowingFact {
    param([string]$Fact)

    if ([string]::IsNullOrWhiteSpace($Fact)) {
        return
    }

    $script:currentFact = $Fact.Trim()
    $script:offset = $ticker.Width
    $script:factFinished = $false
    $script:lastFactChange = [DateTime]::Now

    $script:seenFacts[$script:currentFact] = $true

    $ticker.Invalidate()
}

# ----------------------------------------------------------
# OFFLINE FALLBACK
# ----------------------------------------------------------

function Get-OfflineFact {

    foreach ($unused in $offlineFacts) {

        $fact = $offlineFacts[
            $script:offlineIndex % $offlineFacts.Count
        ]

        $script:offlineIndex++

        if (-not $script:seenFacts.ContainsKey($fact)) {
            return $fact
        }
    }

    return 'Knowing is waiting for more interesting facts.'
}

# ----------------------------------------------------------
# START BACKGROUND INTERNET REQUEST
# ----------------------------------------------------------

function Start-FactFetch {

    if ($null -ne $script:fetchJob) {
        return
    }

    $script:fetchJob = Start-Job -ArgumentList $apiUrl -ScriptBlock {

        param($url)

        try {

            # Use TLS 1.2 for Windows PowerShell 5.1
            [Net.ServicePointManager]::SecurityProtocol =
                [Net.SecurityProtocolType]::Tls12

            $response = Invoke-RestMethod `
                -Uri $url `
                -Method Get `
                -TimeoutSec 10 `
                -Headers @{ Accept = 'application/json' } `
                -ErrorAction Stop

            if (-not [string]::IsNullOrWhiteSpace(
                $response.text
            )) {
                $response.text
            }

        }
        catch {
            # The main application will use an offline fact.
        }

    }
}

# ----------------------------------------------------------
# CHECK BACKGROUND REQUEST
# ----------------------------------------------------------

function Complete-FactFetch {

    if ($null -eq $script:fetchJob) {
        return
    }

    if ($script:fetchJob.State -notin @(
        'Completed', 'Failed', 'Stopped'
    )) {
        return
    }

    $result = @(
        Receive-Job -Job $script:fetchJob `
            -ErrorAction SilentlyContinue
    )

    Remove-Job -Job $script:fetchJob -Force
    $script:fetchJob = $null

    $newFact = $null

    foreach ($item in $result) {

        $candidate = [string]$item

        if (
            -not [string]::IsNullOrWhiteSpace($candidate) -and
            -not $script:seenFacts.ContainsKey($candidate.Trim())
        ) {
            $newFact = $candidate.Trim()
            break
        }
    }

    if ($null -eq $newFact) {
        $newFact = Get-OfflineFact
    }

    Show-KnowingFact -Fact $newFact
}

# ----------------------------------------------------------
# PAINT SCROLLING TEXT
# ----------------------------------------------------------

$ticker.Add_Paint({

    param($sender, $e)

    $e.Graphics.TextRenderingHint =
        [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    if (-not $script:factFinished) {

        $e.Graphics.DrawString(
            $script:currentFact,
            $font,
            $brush,
            [float]$script:offset,
            [float]5
        )
    }
})

# ----------------------------------------------------------
# CLOSE BUTTON
# ----------------------------------------------------------

$close = New-Object System.Windows.Forms.Button

$close.Text = 'X'
$close.FlatStyle = 'Flat'
$close.FlatAppearance.BorderSize = 0
$close.ForeColor = $foreground
$close.BackColor = $background

$close.Font = New-Object System.Drawing.Font(
    'Segoe UI',
    10,
    [System.Drawing.FontStyle]::Bold
)

$close.Location = New-Object System.Drawing.Point(615, 8)
$close.Size = New-Object System.Drawing.Size(28, 30)

$close.Add_Click({
    $form.Close()
})

$form.Controls.Add($close)
$close.BringToFront()

# ----------------------------------------------------------
# DRAGGING SUPPORT
# ----------------------------------------------------------

$script:dragging = $false
$script:dragStart = [System.Drawing.Point]::Empty
$script:windowStart = [System.Drawing.Point]::Empty

$title.Add_MouseDown({

    param($sender, $e)

    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {

        $script:dragging = $true

        $script:dragStart =
            [System.Windows.Forms.Cursor]::Position

        $script:windowStart = $form.Location
    }
})

$title.Add_MouseMove({

    if ($script:dragging) {

        $cursor = [System.Windows.Forms.Cursor]::Position

        $dx = $cursor.X - $script:dragStart.X
        $dy = $cursor.Y - $script:dragStart.Y

        $form.Location = New-Object System.Drawing.Point(
            ($script:windowStart.X + $dx),
            ($script:windowStart.Y + $dy)
        )
    }
})

$title.Add_MouseUp({
    $script:dragging = $false
})

# ----------------------------------------------------------
# ANIMATION AND FACT TIMER
# ----------------------------------------------------------

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $animationInterval

$timer.Add_Tick({

    # Check whether a background request has finished
    if ($null -ne $script:fetchJob) {

        Complete-FactFetch

        # Wait for the next tick before proceeding
        return
    }

    # Scroll the current fact once
    if (-not $script:factFinished) {

        $textWidth = [System.Windows.Forms.TextRenderer]::MeasureText(
            $script:currentFact,
            $font
        ).Width

        $script:offset -= $scrollPixels

        if ($script:offset -le -$textWidth) {

            $script:factFinished = $true
            $script:offset = -$textWidth - 10
        }

        $ticker.Invalidate()
    }

    # Wait until the current fact is finished
    if (-not $script:factFinished) {
        return
    }

    # Check whether 90 seconds have passed
    $elapsed = (
        [DateTime]::Now - $script:lastFactChange
    ).TotalSeconds

    if ($elapsed -ge $factIntervalSeconds) {

        Start-FactFetch
    }
})

# ----------------------------------------------------------
# START APPLICATION
# ----------------------------------------------------------

$form.Add_Shown({

    $timer.Start()

    # Retrieve the first fact immediately
    Start-FactFetch
})

# ----------------------------------------------------------
# CLEANUP
# ----------------------------------------------------------

$form.Add_FormClosed({

    $timer.Stop()
    $timer.Dispose()

    if ($null -ne $script:fetchJob) {

        Stop-Job -Job $script:fetchJob `
            -ErrorAction SilentlyContinue

        Remove-Job -Job $script:fetchJob `
            -Force -ErrorAction SilentlyContinue
    }

    $font.Dispose()
    $brush.Dispose()
    $title.Font.Dispose()
    $close.Font.Dispose()
})

# ----------------------------------------------------------
# LAUNCH KNOWING
# ----------------------------------------------------------

[void]$form.ShowDialog()

