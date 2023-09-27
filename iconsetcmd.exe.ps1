# Define constants for LoadImage function
$IMAGE_ICON = 1
$LR_LOADFROMFILE = 16

# Define the LoadImage function from user32.dll
function LoadImage {
    param (
        [System.IntPtr] $hInst,
        [string] $lpszName,
        [System.UInt32] $uType,
        [int] $cxDesired,
        [int] $cyDesired,
        [System.UInt32] $fuLoad
    )

    $signature = @"
    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    public static extern IntPtr LoadImage(IntPtr hInst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);
"@
    $loadImage = Add-Type -MemberDefinition $signature -Name 'User32' -Namespace 'User32' -PassThru

    return $loadImage::LoadImage($hInst, $lpszName, $uType, $cxDesired, $cyDesired, $fuLoad)
}

# Icon file path
$iconPath = "C:\Icon\256\sphere.ico"

# Load the icon and get the handle
$hIcon = [System.IntPtr]::Zero
$hIcon = LoadImage $hIcon $iconPath $IMAGE_ICON 0 0 $LR_LOADFROMFILE

# Output the HICON handle
Write-Host "Icon Handle: $hIcon"

# Get the current working directory path
$currentDirectoryPath = (Get-Location).Path

# Function to get the PID and HWND of the Command Prompt window by partial matching window title with directory path
Function Get-ConsoleInfoByMatchingPath {
    param (
        [string] $partialWindowTitle
    )

    if ([string]::IsNullOrEmpty($partialWindowTitle)) {
        Write-Host "No partial window title specified. Cannot get console information."
        return $null
    }

    $consoleProcesses = Get-Process -Name "cmd" -ErrorAction SilentlyContinue
    if ($consoleProcesses -eq $null) {
        Write-Host "Command Prompt (cmd.exe) process not found."
        return $null
    }

    foreach ($process in $consoleProcesses) {
        $windowTitleActual = $process.MainWindowTitle.Trim()
        if ($windowTitleActual -like "*$partialWindowTitle*") {
            $consoleInfo = New-Object PSObject -Property @{
                "PID" = $process.Id
                "HWND" = $process.MainWindowHandle
            }
            Write-Host "Console Window Found with partial title: $windowTitleActual"
            return $consoleInfo
        }
    }

    Write-Host "Console Window Not Found with partial title: $partialWindowTitle"
    return $null
}

# Find the Command Prompt window associated with the current working directory
$consoleInfo = Get-ConsoleInfoByMatchingPath -partialWindowTitle $currentDirectoryPath

# Output the console PID and HWND if found
if ($consoleInfo -ne $null) {
    Write-Host "Console PID: $($consoleInfo.PID)"
    Write-Host "Console HWND: $($consoleInfo.HWND)"
    
    # Add-Type to define the User32 class with SendMessage method
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    
    public class User32 {
        [DllImport("user32.dll")]
        public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    }
"@

    # Send WM_SETICON messages to the console window with the icon handle
    $WM_SETICON = 0x80


		# Send the WM_SETICON messages and report success
    $consoleHWnd = $consoleInfo.HWND
    $result1 = [User32]::SendMessage($consoleHWnd, $WM_SETICON, [IntPtr]0, $hIcon)
    if ($result1 -ne [IntPtr]::Zero) {
        Write-Host "WM_SETICON (Small Icon) Success!"
    }

    $result2 = [User32]::SendMessage($consoleHWnd, $WM_SETICON, [IntPtr]1, $hIcon)
    if ($result2 -ne [IntPtr]::Zero) {
        Write-Host "WM_SETICON (Large Icon) Success!"
    }
}
