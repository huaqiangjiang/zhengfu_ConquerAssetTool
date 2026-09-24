macroScript ConquerMaxChecker
category:"征服MAX"
tooltip:"征服MAX模型检查器"
buttonText:"征服MAX检查器"
(
    local macroFolder = ""
    local checkerScript = ""
    local loadError = "宏加载失败"

    try
    (
        macroFolder = getFilenamePath (getSourceFileName())
        checkerScript = macroFolder + "ConquerMaxChecker.ms"
    )
    catch()

    if checkerScript == "" or not doesFileExist checkerScript then
    (
        messageBox "未找到同目录下的 ConquerMaxChecker.ms。" title:"征服MAX模型检查器"
    )
    else
    (
        try
        (
            fileIn checkerScript
        )
        catch
        (
            try(loadError = getCurrentException() as string)catch(loadError = "宏加载失败")
            messageBox ("加载征服MAX模型检查器失败：\n" + loadError) title:"征服MAX模型检查器"
        )
    )
)

global ConquerMaxCheckerDockRollout

try(cui.UnRegisterDialogBar ConquerMaxCheckerDockRollout)catch()
try(destroyDialog ConquerMaxCheckerDockRollout)catch()

rollout ConquerMaxCheckerDockRollout "征服MAX" width:54 height:72
(
    button btnOpenChecker "征检" pos:[6,6] width:42 height:28 tooltip:"打开征服MAX模型检查器"

    on btnOpenChecker pressed do
    (
        macros.run "征服MAX" "ConquerMaxChecker"
    )
)

try
(
    createDialog ConquerMaxCheckerDockRollout 54 72 style:#(#style_toolwindow, #style_sysmenu)
)
catch()

try
(
    cui.RegisterDialogBar ConquerMaxCheckerDockRollout style:#(#cui_dock_left, #cui_dock_right, #cui_floatable, #cui_handles)
    cui.DockDialogBar ConquerMaxCheckerDockRollout #cui_dock_left
)
catch()
