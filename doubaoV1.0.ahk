; ================== 豆包实时字幕助手 v1.0（无默认托盘菜单） ==================
#Requires AutoHotkey v2.0
;@Ahk2Exe-SetMainIcon shell32_dll_Icon_23.ico   ; 编译器指令：设置exe图标
#SingleInstance Force
#NoTrayIcon          ; 隐藏默认托盘图标和菜单
Persistent
A_IconHidden := false ; 重新显示图标
TraySetIcon("shell32.dll", 23)

; 默认设置
global TargetWin := ""
global Opacity := 180

; 创建 GUI
MyGui := Gui("+AlwaysOnTop +ToolWindow", "豆包实时字幕助手 v1.0")
MyGui.SetFont("s10")
MyGui.AddText(, "✅ 豆包实时双语字幕专用工具")
MyGui.AddText("x10 yp+25", "1. 打开豆包 → 启动实时字幕（独立窗口）")

; 按钮同一行
MyGui.AddButton("x10 yp+30 w180", "应用（置顶+穿透+半透明）").OnEvent("Click", ApplyToSubtitle)
MyGui.AddButton("x200 yp w100", "恢复正常").OnEvent("Click", RestoreNormal)

; 半透明度输入行
MyGui.AddText("x10 yp+40", "半透明度 (0-255，越小越透):")
OpacityEdit := MyGui.AddEdit("x210 yp-3 w60", Opacity)

; 热键提示分行显示
MyGui.AddText("x10 yp+35", "热键：")
MyGui.AddText("x20 yp+20", "Ctrl+Shift+Q = 应用")
MyGui.AddText("x20 yp+20", "Ctrl+Shift+W = 恢复")

MyGui.Show("w330 h200")

; 热键绑定
^+q:: ApplyToSubtitle()
^+w:: RestoreNormal()

; ============== 辅助函数：获取扩展样式（兼容32/64位） ==============
GetWindowExStyle(hwnd) {
    if (A_PtrSize == 8)
        return DllCall("GetWindowLongPtr", "Ptr", hwnd, "Int", -20, "Ptr")
    else
        return DllCall("GetWindowLong", "Ptr", hwnd, "Int", -20, "UInt")
}

; ============== 辅助函数：设置扩展样式（兼容32/64位） ==============
SetWindowExStyle(hwnd, style) {
    if (A_PtrSize == 8)
        return DllCall("SetWindowLongPtr", "Ptr", hwnd, "Int", -20, "Ptr", style)
    else
        return DllCall("SetWindowLong", "Ptr", hwnd, "Int", -20, "UInt", style)
}

; ============== 精准查找字幕窗口 ==============
FindSubtitleWindow() {
    windows := WinGetList("ahk_exe Doubao.exe ahk_class Chrome_WidgetWin_1")
    if (windows.Length = 0)
        return 0
    
    for hwnd in windows {
        ctrlHwnd := ControlGetHwnd("Chrome_RenderWidgetHostHWND1", "ahk_id " hwnd)
        if (!ctrlHwnd)
            continue
        
        WinGetPos &x, &y, &w, &h, "ahk_id " hwnd
        title := WinGetTitle("ahk_id " hwnd)
        
        if (w >= 650 && w <= 850 && h >= 120 && h <= 200) {
            if (title != "" && InStr(title, "豆包") && w > 1000)
                continue
            return hwnd
        }
    }
    return 0
}

; ============== 应用函数 ==============
ApplyToSubtitle(*) {
    global TargetWin, Opacity, OpacityEdit
    
    Opacity := Integer(OpacityEdit.Value)
    if (Opacity < 0 || Opacity > 255) {
        MsgBox "透明度数值必须在 0-255 之间", "豆包助手", "Iconx"
        return
    }

    TargetWin := FindSubtitleWindow()
    if (!TargetWin) {
        MsgBox "❌ 未找到豆包实时字幕窗口！`n`n请确保：`n1. 已打开豆包的实时双语字幕功能`n2. 字幕窗口已独立显示（非嵌入主窗口）", "豆包助手", "Iconx"
        return
    }

    ; 安全确认
    title := WinGetTitle("ahk_id " TargetWin)
    WinGetPos &x, &y, &w, &h, "ahk_id " TargetWin
    if (title != "" && InStr(title, "豆包") && w > 1000) {
        Result := MsgBox("警告：检测到目标窗口可能是豆包主窗口（标题：" title "，尺寸：" w "x" h "）。`n`n确定要继续应用效果吗？", "豆包助手", "Icon! YN")
        if (Result = "No")
            return
    }

    ; 应用效果
    WinSetAlwaysOnTop(1, "ahk_id " TargetWin)
    WinMove(,,, , "ahk_id " TargetWin)

    style := GetWindowExStyle(TargetWin)
    SetWindowExStyle(TargetWin, style | 0x80000 | 0x20)

    WinSetTransColor("Off", "ahk_id " TargetWin)
    WinSetTransparent("Off", "ahk_id " TargetWin)
    WinSetTransparent(Opacity, "ahk_id " TargetWin)

    ToolTip "✅ 已应用：置顶、穿透、半透明 (" Opacity ")", 800, 400
    SetTimer () => ToolTip(), -2000
}

; ============== 恢复函数 ==============
RestoreNormal(*) {
    global TargetWin
    
    if (TargetWin = "" || !WinExist("ahk_id " TargetWin)) {
        TargetWin := FindSubtitleWindow()
        if (!TargetWin) {
            ToolTip "未找到豆包字幕窗口", 800, 400
            SetTimer () => ToolTip(), -1500
            return
        }
    }

    style := GetWindowExStyle(TargetWin)
    SetWindowExStyle(TargetWin, style & 0xFFF7FFDF)
    
    WinSetTransColor("Off", "ahk_id " TargetWin)
    WinSetTransparent("Off", "ahk_id " TargetWin)
    WinSetAlwaysOnTop(0, "ahk_id " TargetWin)
    
    ToolTip "🔄 已恢复正常", 800, 400
    SetTimer () => ToolTip(), -1500
}

; ============== 自定义托盘菜单（仅三项） ==============
A_TrayMenu.Delete()   ; 清空默认项
A_TrayMenu.Add("一键应用", (*) => ApplyToSubtitle())
A_TrayMenu.Add("恢复正常", (*) => RestoreNormal())
A_TrayMenu.Add("退出", (*) => ExitApp())