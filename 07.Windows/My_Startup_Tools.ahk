#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

Global APP_NAME := "My_Startup_Tools", VERSION := "3.0.0.0", AUTHOR := "GPT", FIX_TIME := "2026/08/26"
Global LOG_ROOT := EnvGet("ProgramData") "\USB_Audit_Logs", SCRIPT_DIR := LOG_ROOT "\Scripts", SCRIPT_PATH := SCRIPT_DIR "\USBWatcher.ps1", ERROR_LOG := LOG_ROOT "\Error.log"

Global CONFIG := Map(
    "StartDelayMs", 1500, 
    "ProcessCheckMs", 5000, 
    "MaxLogSizeMB", 50,
    "MonitorFixed", true, 
    "MonitorRemovable", true, 
    "BaselineRecursive", true,
    "ShowStartNotification", false,   ; 默认关闭接入提示
    "MonitorAdbDevices", false,       ; 默认排除ADB/虚拟设备
    "PlainTextPaste", true,           ; Ctrl+Shift+V 默认开启
    "KeepAwake", false,               ; 防休眠默认关闭
    "ScreenOverlay", true             ; 低亮覆盖快捷键默认开启
)

Global Watchers := Map(), PendingStartTimers := Map(), ProcessingDrives := Map(), ShellApp := ComObject("Shell.Application")
Global OverlayGuis := Map()
Global MYINFO := APP_NAME "`n版本：v" VERSION "`n`nUSB 存储设备文件变动审计，并提供纯文本粘贴、亮屏防休眠和多显示器低亮覆盖功能。`n`n纯文本粘贴：Ctrl+Shift+V`n低亮覆盖：F8（2号）、F9（1号）、F10（3号）`n各功能可在托盘右键菜单中开关。`n`n生成与修改调试：" AUTHOR "`n修改时间：" FIX_TIME

if (A_Args.Length > 0 && StrLower(A_Args[1]) = "version") {
    ShowVersion(), ExitApp()
}

Initialize()

Initialize() {
    try DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
    EnsureDirectory(LOG_ROOT)
    EnsureDirectory(SCRIPT_DIR)
    EnsureStartupShortcut()
    EnsurePowerShellWorker()
    WriteSystemLog("============================================================")
    WriteSystemLog("程序启动 | " A_ComputerName " | " A_UserName " | Version " VERSION)
    SetupTrayMenu()
    RegisterGlobalHotkeys()
    ApplyPlainTextPasteHotkey()
    ApplyScreenOverlayHotkeys()
    OnMessage(0x0219, WM_DEVICECHANGE)
    OnExit(CleanupOnExit)
    SetTimer(CheckWatcherProcesses, 5000)
}

EnsureStartupShortcut() {
    startupLink := A_Startup "\" RegExReplace(A_ScriptName, "\.[^.]+$", "") ".lnk"
    legacyStartupCopy := A_Startup "\" A_ScriptName

    ; 防止旧版 Startup 副本运行时把快捷方式错误指向自身。
    if (StrLower(A_ScriptFullPath) = StrLower(legacyStartupCopy)) {
        WriteSystemLog("Startup | 检测到旧版启动副本，等待从主脚本重新创建快捷方式")
        return false
    }

    if A_IsCompiled {
        targetPath := A_ScriptFullPath
        targetArgs := ""
    } else {
        ; 直接使用当前 AutoHotkey 解释器，避免依赖 .ahk 文件关联。
        targetPath := A_AhkPath
        targetArgs := '"' A_ScriptFullPath '"'
    }

    try {
        FileCreateShortcut(targetPath, startupLink, A_ScriptDir, targetArgs, APP_NAME)
        ; 快捷方式创建成功后才清理旧的复制式启动项。
        if FileExist(legacyStartupCopy)
            FileDelete(legacyStartupCopy)
        WriteSystemLog("Startup | 已创建或更新启动快捷方式 | " startupLink)
        return true
    } catch Error as err {
        WriteErrorLog("Startup 快捷方式更新失败 | " err.Message)
        return false
    }
}

ShowVersion() {
    if !DllCall("AttachConsole", "UInt", -1)
        DllCall("AllocConsole")
    try { 
        stdout := FileOpen("*", "w") 
        stdout.Write("`n" MYINFO "`n") 
        stdout.Close() 
    } catch {
    }
    Sleep(100)
}

SetupTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("打开日志目录`tCtrl+Alt+O", OpenLogDirectory)
    A_TrayMenu.Add("当前监控设备`tCtrl+Alt+I", ShowCurrentWatchers)
    A_TrayMenu.Add()
    A_TrayMenu.Add("启用设备接入提示`tCtrl+Alt+N", ToggleStartNotification)
    A_TrayMenu.Add("监控 ADB / 虚拟设备`tCtrl+Alt+A", ToggleAdbDevices)
    A_TrayMenu.Add("启用 Ctrl+Shift+V 纯文本粘贴`tCtrl+Alt+V", TogglePlainTextPaste)
    A_TrayMenu.Add("启用亮屏防休眠`tCtrl+Alt+K", ToggleKeepAwake)
    A_TrayMenu.Add("启用低亮屏幕覆盖（F8/F9/F10）`tCtrl+Alt+M", ToggleScreenOverlay)
    if CONFIG["ShowStartNotification"]
        A_TrayMenu.Check("启用设备接入提示`tCtrl+Alt+N")
    if CONFIG["MonitorAdbDevices"]
        A_TrayMenu.Check("监控 ADB / 虚拟设备`tCtrl+Alt+A")
    if CONFIG["PlainTextPaste"]
        A_TrayMenu.Check("启用 Ctrl+Shift+V 纯文本粘贴`tCtrl+Alt+V")
    if CONFIG["KeepAwake"]
        A_TrayMenu.Check("启用亮屏防休眠`tCtrl+Alt+K")
    if CONFIG["ScreenOverlay"]
        A_TrayMenu.Check("启用低亮屏幕覆盖（F8/F9/F10）`tCtrl+Alt+M")
    A_TrayMenu.Add()
    A_TrayMenu.Add("安全弹出所有移动设备`tCtrl+Alt+E", ReleaseAllDrives)
    A_TrayMenu.Add()
    A_TrayMenu.Add("关于...`tCtrl+Alt+H", ShowAbout)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出`tCtrl+Alt+Q", ExitTool)
    A_IconTip := APP_NAME
}

RegisterGlobalHotkeys() {
    Hotkey("^!o", OpenLogDirectory)
    Hotkey("^!i", ShowCurrentWatchers)
    Hotkey("^!n", ToggleStartNotification)
    Hotkey("^!a", ToggleAdbDevices)
    Hotkey("^!v", TogglePlainTextPaste)
    Hotkey("^!k", ToggleKeepAwake)
    Hotkey("^!m", ToggleScreenOverlay)
    Hotkey("^!e", ReleaseAllDrives)
    Hotkey("^!h", ShowAbout)
    Hotkey("^!q", ExitTool)
}

ExitTool(*) {
    ExitApp()
}

ToggleStartNotification(*) {
    CONFIG["ShowStartNotification"] := !CONFIG["ShowStartNotification"]
    if CONFIG["ShowStartNotification"] {
        A_TrayMenu.Check("启用设备接入提示`tCtrl+Alt+N")
        WriteSystemLog("托盘操作 | 开启设备接入提示")
    } else {
        A_TrayMenu.Uncheck("启用设备接入提示`tCtrl+Alt+N")
        WriteSystemLog("托盘操作 | 关闭设备接入提示")
    }
}

ToggleAdbDevices(*) {
    CONFIG["MonitorAdbDevices"] := !CONFIG["MonitorAdbDevices"]
    if CONFIG["MonitorAdbDevices"] {
        A_TrayMenu.Check("监控 ADB / 虚拟设备`tCtrl+Alt+A")
        WriteSystemLog("托盘操作 | 开启监控 ADB / 虚拟设备")
    } else {
        A_TrayMenu.Uncheck("监控 ADB / 虚拟设备`tCtrl+Alt+A")
        WriteSystemLog("托盘操作 | 关闭监控 ADB / 虚拟设备")
    }
}

OpenLogDirectory(*) {
    WriteSystemLog("托盘操作 | 打开日志目录")
    EnsureDirectory(LOG_ROOT)
    try {
        Run('explorer.exe "' LOG_ROOT '"')
    } catch Error as err {
        WriteErrorLog("无法打开日志目录: " err.Message)
    }
}

ShowCurrentWatchers(*) {
    WriteSystemLog("托盘操作 | 查看当前监控设备列表")
    if (Watchers.Count = 0) {
        TrayTip(APP_NAME, "当前没有正在监控的设备。", 2)
        return
    }
    text := "当前监控设备：`n`n"
    for drive, info in Watchers
        text .= drive ":\ | PID=" info["PID"] " | " info["VolumeLabel"] "`n"
    MsgBox(text, APP_NAME, "Iconi")
}

ShowAbout(*) {
    WriteSystemLog("托盘操作 | 查看关于信息")
    MsgBox(MYINFO, "关于 - " APP_NAME, "Iconi")
}

ReleaseAllDrives(*) {
    WriteSystemLog("托盘操作 | 尝试安全弹出所有移动设备")
    if (Watchers.Count = 0) {
        TrayTip(APP_NAME, "当前没有正在监控的设备。", 2)
        return
    }
    
    drives := []
    for drive, _ in Watchers
        drives.Push(drive)
        
    count := 0
    for _, drive in drives {
        if !Watchers.Has(drive)
            continue
            
        if StopMonitoring(drive, true) {
            count++
            Sleep(200)
            try {
                item := ShellApp.Namespace(17).ParseName(drive ":\")
                if item
                    item.InvokeVerb("Eject")
            } catch Error as err {
                WriteErrorLog("安全弹出失败 | Drive=" drive " | " err.Message)
            }
        }
    }
    if (count > 0 && CONFIG["ShowStartNotification"])
        TrayTip(APP_NAME, "已解除 " count " 个设备的后台监控并发送安全弹出指令。", 3)
}

WM_DEVICECHANGE(wParam, lParam, msg, hwnd) {
    if (wParam = 0x8000 && lParam && NumGet(lParam, 4, "UInt") = 2) {
        for _, drive in GetDriveLetters(NumGet(lParam, 12, "UInt")) {
            for _, siblingDrive in GetSiblingDrives(drive) {
                ScheduleStartMonitoring(siblingDrive)
            }
        }
    } else if (wParam = 0x8004 && lParam && NumGet(lParam, 4, "UInt") = 2) {
        for _, drive in GetDriveLetters(NumGet(lParam, 12, "UInt")) {
            StopMonitoring(drive, false)
        }
    }
}

GetDriveLetters(mask) {
    drives := []
    Loop 26 {
        if (mask & (1 << (A_Index - 1)))
            drives.Push(Chr(64 + A_Index))
    }
    return drives
}

GetSiblingDrives(driveLetter) {
    drivesMap := Map()
    drivesMap[driveLetter] := true
    try {
        wmi := ComObjGet("winmgmts:")
        for partition in wmi.ExecQuery('ASSOCIATORS OF {Win32_LogicalDisk.DeviceID="' driveLetter '"} WHERE AssocClass=Win32_LogicalDiskToPartition') {
            for diskDrive in wmi.ExecQuery('ASSOCIATORS OF {Win32_DiskPartition.DeviceID="' partition.DeviceID '"} WHERE AssocClass=Win32_DiskDriveToDiskPartition') {
                for part in wmi.ExecQuery('ASSOCIATORS OF {Win32_DiskDrive.DeviceID="' diskDrive.DeviceID '"} WHERE AssocClass=Win32_DiskDriveToDiskPartition') {
                    for logDisk in wmi.ExecQuery('ASSOCIATORS OF {Win32_DiskPartition.DeviceID="' part.DeviceID '"} WHERE AssocClass=Win32_LogicalDiskToPartition') {
                        d := SubStr(logDisk.DeviceID, 1, 1)
                        drivesMap[d] := true
                    }
                }
            }
        }
    } catch {
    }
    drives := []
    for d, _ in drivesMap
        drives.Push(d)
    return drives
}

ScheduleStartMonitoring(drive) {
    if IsDriveBeingWatched(drive) || PendingStartTimers.Has(drive) || ProcessingDrives.Has(drive)
        return
    callback := StartMonitoring.Bind(drive)
    PendingStartTimers[drive] := callback
    SetTimer(callback, -CONFIG["StartDelayMs"])
}

GetPreciseTimestamp(&readable := "") {
    timeStr := FormatTime(, "yyyyMMdd_HHmmss")
    msec := Format("{:03}", A_MSec)
    readable := FormatTime(, "yyyy-MM-dd HH:mm:ss") "." msec
    return timeStr "_" msec
}

IsAdbDevice(drivePath, volName) {
    if CONFIG["MonitorAdbDevices"]
        return false
    
    volLower := StrLower(volName)
    if (volLower ~= "(mumu|bluestacks|nox|ldplayer)")
        return true

    try {
        driveLetter := SubStr(drivePath, 1, 2)
        wmi := ComObjGet("winmgmts:")
        
        hasPartition := false
        for partition in wmi.ExecQuery('ASSOCIATORS OF {Win32_LogicalDisk.DeviceID="' driveLetter '"} WHERE AssocClass=Win32_LogicalDiskToPartition') {
            hasPartition := true
            for diskDrive in wmi.ExecQuery('ASSOCIATORS OF {Win32_DiskPartition.DeviceID="' partition.DeviceID '"} WHERE AssocClass=Win32_DiskDriveToDiskPartition') {
                pnpId := StrLower(diskDrive.PNPDeviceID)
                model := StrLower(diskDrive.Model)
                if InStr(pnpId, "adb") || InStr(pnpId, "vid_18d1") || InStr(pnpId, "vid_2717") || InStr(model, "virtual") || InStr(model, "vhd") {
                    WriteSystemLog("检测到虚拟/ADB设备特征 | Drive=" driveLetter " | Model=" diskDrive.Model)
                    return true
                }
            }
        }
        
        if (!hasPartition) {
            WriteSystemLog("检测到无物理分区的虚拟/ADB盘符 | Drive=" driveLetter " | Label=" volName)
            return true
        }
    } catch {
    }

    return false
}

StartMonitoring(drive) {
    if PendingStartTimers.Has(drive)
        PendingStartTimers.Delete(drive)
    
    if ProcessingDrives.Has(drive)
        return
    ProcessingDrives[drive] := true

    try {
        drivePath := drive ":\"
        
        status := ""
        Loop 7 {
            try {
                if DirExist(drivePath) {
                    status := DriveGetStatus(drivePath)
                    if (status = "Ready")
                        break
                }
            } catch {
            }
            Sleep(1000)
        }
        
        if (status != "Ready" || IsDriveBeingWatched(drive))
            return
        
        try {
            drvType := DriveGetType(drivePath)
        } catch {
            return
        }
        
        if !IsAllowedDriveType(drvType)
            return

        try {
            volName := DriveGetLabel(drivePath)
        } catch {
            volName := ""
        }

        if IsAdbDevice(drivePath, volName) {
            WriteSystemLog("已自动排除 ADB / 虚拟设备 | Drive=" drive)
            return
        }

        EnsurePowerShellWorker()
        EnsureDirectory(LOG_ROOT)
        timestamp := GetPreciseTimestamp(&timestampReadable)
        
        volName := SanitizeFileName(volName)
        if (volName = "")
            volName := "Volume_" drive

        baseName := timestamp "_" drive "Drive_" volName
        baselineLog := LOG_ROOT "\" baseName "_Baseline.log"
        activityLog := LOG_ROOT "\" baseName "_Activity.log"

        WriteSystemLog("开始生成 Baseline | Drive=" drive " | Label=" volName)
        GenerateBaselineLog(drive, baselineLog, volName, timestampReadable)
        InitializeActivityLog(activityLog, drive, volName, timestampReadable)

        runCmd := 'powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "' SCRIPT_PATH '" -DriveLetter "' drive '" -LogPath "' activityLog '" -MaxLogSizeMB "' CONFIG["MaxLogSizeMB"] '"'
        
        try {
            Run(runCmd, , "Hide", &PID)
        } catch Error as err {
            WriteErrorLog("Worker 启动失败 | Drive=" drive " | " err.Message)
            AppendActivityLog(activityLog, "[" timestampReadable "] [ERROR] Worker 启动失败: " err.Message)
            return
        }

        if !PID {
            WriteErrorLog("Worker 启动失败，未获得 PID | Drive=" drive)
            return
        }

        Watchers[drive] := Map(
            "PID", PID, 
            "ActivityLog", activityLog, 
            "BaselineLog", baselineLog, 
            "VolumeLabel", volName, 
            "StartTime", timestampReadable, 
            "WorkerStartTick", A_TickCount
        )
        
        WriteSystemLog("开始监控 | Drive=" drive " | PID=" PID " | Label=" volName)
        
        if CONFIG["ShowStartNotification"]
            TrayTip(APP_NAME, drive ":\ 已开始监控。", 2)
    } finally {
        ProcessingDrives.Delete(drive)
    }
}

StopMonitoring(drive, eject := false) {
    ; 【终极加固】双重判断，若已被其他线程/事件安全清理，直接返回
    if !Watchers.Has(drive)
        return false
        
    info := Watchers[drive]
    
    if (!eject && (A_TickCount - info["WorkerStartTick"] < 10000))
        return false
        
    if (!eject) {
        try {
            if InStr(DriveGetList(), drive)
                return false
        } catch {
        }
    }
        
    PID := info["PID"]
    activityLog := info["ActivityLog"]
    
    AppendActivityLog(activityLog, "[" FormatTime(, "yyyy-MM-dd HH:mm:ss") "." Format("{:03}", A_MSec) "] [SYSTEM] 停止监控")
    
    if ProcessExist(PID) {
        try {
            ProcessClose(PID)
            ProcessWaitClose(PID, 2000)
        } catch {
        }
    }
    
    try {
        if Watchers.Has(drive)
            Watchers.Delete(drive)
    } catch {
    }
    
    WriteSystemLog("停止监控 | Drive=" drive " | PID=" PID)
    return true
}

CheckWatcherProcesses(*) {
    if (Watchers.Count = 0)
        return
        
    deadDrives := []
    for drive, info in Watchers {
        if !ProcessExist(info["PID"]) {
            deadDrives.Push(drive)
            nowStr := FormatTime(, "yyyy-MM-dd HH:mm:ss") "." Format("{:03}", A_MSec)
            AppendActivityLog(info["ActivityLog"], "[" nowStr "] [ERROR] PowerShell Worker 异常退出 | PID=" info["PID"])
            WriteErrorLog("Worker 异常退出 | Drive=" drive " | PID=" info["PID"])
        }
    }
    
    for _, drive in deadDrives
        try Watchers.Delete(drive)
}

IsDriveBeingWatched(drive) => Watchers.Has(drive)

IsAllowedDriveType(drvType) => (drvType = "Removable") ? CONFIG["MonitorRemovable"] : ((drvType = "Fixed") ? CONFIG["MonitorFixed"] : false)

GenerateBaselineLog(drive, logFile, volName, timestampReadable) {
    fileObj := 0
    try {
        fileObj := FileOpen(logFile, "w", "UTF-8")
        if !fileObj
            return WriteErrorLog("无法创建 Baseline 日志 | " logFile)

        fileObj.WriteLine("=== 初始文件快照 (Baseline) ===`n接入时间: " timestampReadable "`n设备盘符: " drive ":\`n卷标: " volName "`n计算机: " A_ComputerName "`n用户: " A_UserName "`n--------------------------------------------------")
        fileCount := 0
        totalSize := 0
        searchMode := CONFIG["BaselineRecursive"] ? "R" : ""

        try {
            Loop Files, drive ":\*", searchMode {
                if !DirExist(drive ":\")
                    break
                fileObj.WriteLine("[" FormatTime(A_LoopFileTimeModified, "yyyy-MM-dd HH:mm:ss") "] [" Round(A_LoopFileSize / 1024, 2) " KB] [" (A_LoopFileAttrib = "" ? "-" : A_LoopFileAttrib) "] " A_LoopFilePath)
                fileCount++
                totalSize += A_LoopFileSize
            }
        } catch Error as err {
            fileObj.WriteLine("[ERROR] Baseline 扫描异常: " err.Message)
            WriteErrorLog("Baseline 扫描异常 | Drive=" drive " | " err.Message)
        }
        
        fileObj.WriteLine("--------------------------------------------------`n共计文件数量: " fileCount "`n总文件大小: " FormatBytes(totalSize) "`nBaseline 完成时间: " FormatTime(, "yyyy-MM-dd HH:mm:ss") "." Format("{:03}", A_MSec))
    } catch Error as err { 
        WriteErrorLog("Baseline 创建失败 | Drive=" drive " | " err.Message) 
    } finally { 
        if IsObject(fileObj) 
            fileObj.Close() 
    }
}

InitializeActivityLog(logFile, drive, volName, timestampReadable) {
    try {
        fileObj := FileOpen(logFile, "w", "UTF-8")
        if fileObj {
            fileObj.WriteLine("=== USB 文件动态行为记录 ===`n开始时间: " timestampReadable "`n设备盘符: " drive ":\`n卷标: " volName "`n计算机: " A_ComputerName "`n用户: " A_UserName "`n--------------------------------------------------")
            fileObj.Close()
        }
    } catch Error as err { 
        WriteErrorLog("Activity 日志初始化失败 | " err.Message) 
    }
}

AppendActivityLog(logFile, text) {
    try {
        fileObj := FileOpen(logFile, "a", "UTF-8")
        if !fileObj
            return false
        fileObj.WriteLine(text)
        fileObj.Close()
        return true
    } catch { 
        return false 
    }
}

WriteErrorLog(text) {
    EnsureDirectory(LOG_ROOT)
    try {
        fileObj := FileOpen(ERROR_LOG, "a", "UTF-8")
        if fileObj {
            fileObj.WriteLine("[" FormatTime(, "yyyy-MM-dd HH:mm:ss") "." Format("{:03}", A_MSec) "] " text)
            fileObj.Close()
        }
    } catch {
    }
}

WriteSystemLog(text) {
    EnsureDirectory(LOG_ROOT)
    try {
        fileObj := FileOpen(LOG_ROOT "\System.log", "a", "UTF-8")
        if fileObj {
            fileObj.WriteLine("[" FormatTime(, "yyyy-MM-dd HH:mm:ss") "." Format("{:03}", A_MSec) "] " text)
            fileObj.Close()
        }
    } catch {
    }
}

SanitizeFileName(name) {
    if (name = "")
        return ""
    name := Trim(RegExReplace(name, '[\\/:*?"<>|]', "_"), " .")
    return (StrLen(name) > 80) ? SubStr(name, 1, 80) : name
}

FormatBytes(bytes) {
    if (bytes < 1024)
        return bytes " B"
    if (bytes < 1048576)
        return Round(bytes / 1024, 2) " KB"
    if (bytes < 1073741824)
        return Round(bytes / 1048576, 2) " MB"
    return Round(bytes / 1073741824, 2) " GB"
}

EnsureDirectory(path) {
    if !DirExist(path) {
        try {
            DirCreate(path)
        } catch {
        }
    }
    return DirExist(path)
}

EnsurePowerShellWorker() {
    EnsureDirectory(SCRIPT_DIR)
    if FileExist(SCRIPT_PATH)
        try FileDelete(SCRIPT_PATH)

    try {
        FileAppend(GetPowerShellWorkerCode(), SCRIPT_PATH, "UTF-8")
    }
    catch Error as err {
        WriteErrorLog("创建 PowerShell Worker 失败: " err.Message)
    }
}

GetPowerShellWorkerCode() {
    ps := []
    ps.Push("param(")
    ps.Push("    [Parameter(Mandatory=$true)]")
    ps.Push("    [string]$DriveLetter,")
    ps.Push("    [Parameter(Mandatory=$true)]")
    ps.Push("    [string]$LogPath,")
    ps.Push("    [int]$MaxLogSizeMB = 50")
    ps.Push(")")
    ps.Push("")
    ps.Push("$ErrorActionPreference = 'Stop'")
    ps.Push("$TargetDrive = $DriveLetter + ':\'")
    ps.Push("$Watcher = $null")
    ps.Push("$RegisteredEvents = @()")
    ps.Push("")
    ps.Push("function Write-ActivityLog {")
    ps.Push("    param([string]$Message)")
    ps.Push("")
    ps.Push("    try {")
    ps.Push("        if ($MaxLogSizeMB -gt 0 -and (Test-Path -LiteralPath $LogPath)) {")
    ps.Push("            $limit = $MaxLogSizeMB * 1MB")
    ps.Push("            $size = (Get-Item -LiteralPath $LogPath).Length")
    ps.Push("")
    ps.Push("            if ($size -ge $limit) {")
    ps.Push("                $directory = [System.IO.Path]::GetDirectoryName($LogPath)")
    ps.Push("                $name = [System.IO.Path]::GetFileNameWithoutExtension($LogPath)")
    ps.Push("                $archive = $name + '_' + (Get-Date).ToString('yyyyMMdd_HHmmss_fff') + '.log'")
    ps.Push("                $archivePath = Join-Path $directory $archive")
    ps.Push("                Move-Item -LiteralPath $LogPath -Destination $archivePath -Force -ErrorAction Stop")
    ps.Push("            }")
    ps.Push("        }")
    ps.Push("")
    ps.Push("        Add-Content -LiteralPath $LogPath -Value $Message -Encoding UTF8 -ErrorAction Stop")
    ps.Push("    }")
    ps.Push("    catch {")
    ps.Push("    }")
    ps.Push("}")
    ps.Push("")
    ps.Push("function Write-EventLogLine {")
    ps.Push("    param(")
    ps.Push("        [string]$Action,")
    ps.Push("        [string]$Path,")
    ps.Push("        [string]$OldPath = ''")
    ps.Push("    )")
    ps.Push("")
    ps.Push("    $time = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')")
    ps.Push("")
    ps.Push("    if ($Action -eq 'Renamed') {")
    ps.Push("        $msg = '[' + $time + '] [Renamed] [' + $OldPath + '] -> ' + $Path")
    ps.Push("    }")
    ps.Push("    else {")
    ps.Push("        $msg = '[' + $time + '] [' + $Action + '] ' + $Path")
    ps.Push("    }")
    ps.Push("")
    ps.Push("    Write-ActivityLog $msg")
    ps.Push("}")
    ps.Push("")
    ps.Push("try {")
    ps.Push("    Write-ActivityLog '=== Worker 启动 ==='")
    ps.Push("    Write-ActivityLog ('Worker PID: ' + $PID)")
    ps.Push("    Write-ActivityLog ('目标路径: ' + $TargetDrive)")
    ps.Push("")
    ps.Push("    if (-not (Test-Path -LiteralPath $TargetDrive)) {")
    ps.Push("        throw ('目标盘不存在: ' + $TargetDrive)")
    ps.Push("    }")
    ps.Push("")
    ps.Push("    $Watcher = New-Object System.IO.FileSystemWatcher")
    ps.Push("    $Watcher.Path = $TargetDrive")
    ps.Push("    $Watcher.Filter = '*'")
    ps.Push("    $Watcher.IncludeSubdirectories = $true")
    ps.Push("    $Watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::DirectoryName -bor [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::Size")
    ps.Push("    $Watcher.InternalBufferSize = 65536")
    ps.Push("    $Watcher.EnableRaisingEvents = $true")
    ps.Push("")
    ps.Push("    foreach ($eventName in @('Created', 'Deleted', 'Changed', 'Renamed', 'Error')) {")
    ps.Push("        $source = 'USBWatcher_' + $DriveLetter + '_' + $eventName")
    ps.Push("        Register-ObjectEvent -InputObject $Watcher -EventName $eventName -SourceIdentifier $source -ErrorAction Stop | Out-Null")
    ps.Push("        $RegisteredEvents += $source")
    ps.Push("    }")
    ps.Push("")
    ps.Push("    $Dedup = @{}")
    ps.Push("    $DedupWindowMs = 500")
    ps.Push("")
    ps.Push("    Write-ActivityLog ('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff') + '] [SYSTEM] FileSystemWatcher 已启动')")
    ps.Push("")
    ps.Push("    while ($true) {")
    ps.Push("        if (-not (Test-Path -LiteralPath $TargetDrive)) {")
    ps.Push("            Write-ActivityLog ('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff') + '] [SYSTEM] 检测到目标盘已消失，Worker 即将退出')")
    ps.Push("            break")
    ps.Push("        }")
    ps.Push("")
    ps.Push("        $EventRecord = Wait-Event -Timeout 1")
    ps.Push("        if ($null -eq $EventRecord) {")
    ps.Push("            continue")
    ps.Push("        }")
    ps.Push("")
    ps.Push("        try {")
    ps.Push("            $sourceId = $EventRecord.SourceIdentifier")
    ps.Push("            $eventArgs = $EventRecord.SourceEventArgs")
    ps.Push("")
    ps.Push("            if ($sourceId -like '*_Error') {")
    ps.Push("                $exception = $eventArgs.GetException()")
    ps.Push("                Write-ActivityLog ('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff') + '] [ERROR] FileSystemWatcher 错误: ' + $exception.Message)")
    ps.Push("                continue")
    ps.Push("            }")
    ps.Push("")
    ps.Push("            if ($sourceId -like '*_Renamed') {")
    ps.Push("                Write-EventLogLine 'Renamed' $eventArgs.FullPath $eventArgs.OldFullPath")
    ps.Push("                continue")
    ps.Push("            }")
    ps.Push("")
    ps.Push("            $changeType = $eventArgs.ChangeType.ToString()")
    ps.Push("            $fullPath = $eventArgs.FullPath")
    ps.Push("            $key = $changeType + '|' + $fullPath")
    ps.Push("            $nowTick = [Environment]::TickCount64")
    ps.Push("            $duplicate = $false")
    ps.Push("")
    ps.Push("            if ($Dedup.ContainsKey($key)) {")
    ps.Push("                $elapsed = $nowTick - $Dedup[$key]")
    ps.Push("                if ($elapsed -lt $DedupWindowMs) {")
    ps.Push("                    $duplicate = $true")
    ps.Push("                }")
    ps.Push("            }")
    ps.Push("")
    ps.Push("            $Dedup[$key] = $nowTick")
    ps.Push("            if (-not $duplicate) {")
    ps.Push("                Write-EventLogLine $changeType $fullPath")
    ps.Push("            }")
    ps.Push("")
    ps.Push("            if ($Dedup.Count -gt 5000) {")
    ps.Push("                $removeKeys = @()")
    ps.Push("                foreach ($item in @($Dedup.GetEnumerator())) {")
    ps.Push("                    if (($nowTick - $item.Value) -gt 10000) {")
    ps.Push("                        $removeKeys += $item.Key")
    ps.Push("                    }")
    ps.Push("                }")
    ps.Push("                foreach ($removeKey in $removeKeys) {")
    ps.Push("                    $Dedup.Remove($removeKey)")
    ps.Push("                }")
    ps.Push("            }")
    ps.Push("        }")
    ps.Push("        catch {")
    ps.Push("        }")
    ps.Push("        finally {")
    ps.Push("            try {")
    ps.Push("                Remove-Event -EventIdentifier $EventRecord.EventIdentifier -ErrorAction SilentlyContinue")
    ps.Push("            }")
    ps.Catch := ""
    ps.Push("            catch {")
    ps.Push("            }")
    ps.Push("        }")
    ps.Push("    }")
    ps.Push("}")
    ps.Push("catch {")
    ps.Push("    try {")
    ps.Push("        Write-ActivityLog ('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff') + '] [FATAL] Worker 异常: ' + $_.Exception.Message)")
    ps.Push("    }")
    ps.Push("    catch {")
    ps.Push("    }")
    ps.Push("}")
    ps.Push("finally {")
    ps.Push("    foreach ($source in $RegisteredEvents) {")
    ps.Push("        try {")
    ps.Push("            Unregister-Event -SourceIdentifier $source -ErrorAction SilentlyContinue")
    ps.Push("        }")
    ps.Catch := ""
    ps.Push("        catch {")
    ps.Push("        }")
    ps.Push("    }")
    ps.Push("    if ($null -ne $Watcher) {")
    ps.Push("        try {")
    ps.Push("            $Watcher.EnableRaisingEvents = $false")
    ps.Push("        }")
    ps.Catch := ""
    ps.Push("        catch {")
    ps.Push("        }")
    ps.Push("        try {")
    ps.Push("            $Watcher.Dispose()")
    ps.Catch := ""
    ps.Push("        }")
    ps.Catch := ""
    ps.Push("        catch {")
    ps.Push("        }")
    ps.Push("    }")
    ps.Push("}")
    
    result := ""
    for _, line in ps {
        if (result != "")
            result .= "`r`n"
        result .= line
    }
    return result
}

ToggleScreenOverlayForMonitor(monitorNum, *) {
    global OverlayGuis

    if OverlayGuis.Has(monitorNum) {
        try OverlayGuis[monitorNum].Destroy()
        OverlayGuis.Delete(monitorNum)
        return
    }

    try {
        MonitorGet(monitorNum, &left, &top, &right, &bottom)
    } catch Error as err {
        MsgBox("无法获取 " monitorNum " 号显示器：" err.Message, APP_NAME, "Icon!")
        return
    }

    overlay := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale")
    overlay.BackColor := "000000"
    try {
        overlay.Show("x" left " y" top " w" (right - left) " h" (bottom - top))
        WinSetTransparent(243, overlay)
        OverlayGuis[monitorNum] := overlay
    } catch Error as err {
        try overlay.Destroy()
        MsgBox("创建低亮覆盖失败：" err.Message, APP_NAME, "Icon!")
    }
}

ClearScreenOverlays() {
    global OverlayGuis
    for _, overlay in OverlayGuis {
        try overlay.Destroy()
    }
    OverlayGuis.Clear()
}

CleanupOnExit(ExitReason, ExitCode) {
    for _, callback in PendingStartTimers
        try {
            SetTimer(callback, 0)
        } catch {
        }
    PendingStartTimers.Clear()
    ProcessingDrives.Clear()
    for _, info in Watchers {
        try { 
            if ProcessExist(info["PID"]) 
                ProcessClose(info["PID"]) 
        } catch {
        }
    }
    Watchers.Clear()
    ClearScreenOverlays()
    WriteSystemLog("程序退出 | Reason=" ExitReason " | Code=" ExitCode)
}

TogglePlainTextPaste(*) {
    CONFIG["PlainTextPaste"] := !CONFIG["PlainTextPaste"]
    ApplyPlainTextPasteHotkey()
    UpdateFeatureMenuCheck("启用 Ctrl+Shift+V 纯文本粘贴`tCtrl+Alt+V", CONFIG["PlainTextPaste"])
    WriteSystemLog("托盘操作 | " (CONFIG["PlainTextPaste"] ? "开启" : "关闭") "纯文本粘贴")
}

ApplyPlainTextPasteHotkey() {
    Hotkey("^+v", PastePlainText, CONFIG["PlainTextPaste"] ? "On" : "Off")
}

PastePlainText(*) {
    savedClipboard := ClipboardAll()
    try {
        A_Clipboard := A_Clipboard
        Sleep(50)
        Send("^v")
    } finally {
        Sleep(100)
        A_Clipboard := savedClipboard
    }
}

;每 55000 毫秒（55秒）发送一次 F15 键
ToggleKeepAwake(*) {
    CONFIG["KeepAwake"] := !CONFIG["KeepAwake"]
    SetTimer(KeepAwake, CONFIG["KeepAwake"] ? 55000 : 0)
    if CONFIG["KeepAwake"] {
        KeepAwake()
        MsgBox("一直亮屏已启用。", APP_NAME, "Iconi T3")
    } else {
        MsgBox("一直亮屏已关闭。", APP_NAME, "Iconi T3")
    }
    UpdateFeatureMenuCheck("启用亮屏防休眠`tCtrl+Alt+K", CONFIG["KeepAwake"])
    WriteSystemLog("托盘操作 | " (CONFIG["KeepAwake"] ? "开启" : "关闭") "亮屏防休眠")
}

KeepAwake(*) {
    Send("{F15}")
}

ToggleScreenOverlay(*) {
    CONFIG["ScreenOverlay"] := !CONFIG["ScreenOverlay"]
    ApplyScreenOverlayHotkeys()
    if !CONFIG["ScreenOverlay"]
        ClearScreenOverlays()
    UpdateFeatureMenuCheck("启用低亮屏幕覆盖（F8/F9/F10）`tCtrl+Alt+M", CONFIG["ScreenOverlay"])
    WriteSystemLog("托盘操作 | " (CONFIG["ScreenOverlay"] ? "开启" : "关闭") "低亮屏幕覆盖")
}

ApplyScreenOverlayHotkeys() {
    state := CONFIG["ScreenOverlay"] ? "On" : "Off"
    Hotkey("F8", ToggleScreenOverlayForMonitor.Bind(2), state)
    Hotkey("F9", ToggleScreenOverlayForMonitor.Bind(1), state)
    Hotkey("F10", ToggleScreenOverlayForMonitor.Bind(3), state)
}

UpdateFeatureMenuCheck(item, enabled) {
    if enabled
        A_TrayMenu.Check(item)
    else
        A_TrayMenu.Uncheck(item)
}
