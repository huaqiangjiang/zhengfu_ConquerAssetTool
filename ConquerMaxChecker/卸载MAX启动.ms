/*
    征服MAX模型检查器 - 取消 3ds Max 启动加载
    用法：把本文件拖入 3ds Max，会删除启动目录里的自动加载器。
*/

(
    local startupFolder = ""
    local loaderPath = ""

    try(startupFolder = getDir #userStartupScripts)catch(startupFolder = "")
    if startupFolder == "" do try(startupFolder = getDir #startupScripts)catch(startupFolder = "")

    if startupFolder == "" then
    (
        messageBox "卸载失败：无法取得 3ds Max 启动脚本目录。" title:"征服MAX模型检查器"
    )
    else
    (
        loaderPath = startupFolder + "\\ConquerMaxChecker_AutoLoad.ms"
        if doesFileExist loaderPath then
        (
            try(deleteFile loaderPath)catch()
            messageBox "已取消开机自动加载。当前已打开的插件窗口不会被自动关闭。" title:"征服MAX模型检查器"
        )
        else
        (
            messageBox "没有找到自动加载器，无需卸载。" title:"征服MAX模型检查器"
        )
    )
)
