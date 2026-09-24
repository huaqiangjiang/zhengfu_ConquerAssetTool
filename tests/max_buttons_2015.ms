global ConquerMaxChecker
global conquerCheckerRollout
global buttonTestLog = createFile @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\.build\max-buttons.log"
fn buttonRecord value = (format "%\n" value to:buttonTestLog; flush buttonTestLog)
buttonRecord "START"
try
(
    fileIn @"C:\Users\admin\Documents\ChatGPT\征服MAX模型检查器\ConquerMaxChecker\ConquerMaxChecker.ms"
    buttonRecord "LOAD_OK"
    local badModel = box name:"button_test_problem"
    local goodModel = box name:"button_test_good"
    ConquerMaxChecker.report = #()
    ConquerMaxChecker.add "不通过" "模型" badModel.name "test" "test"
    clearSelection()
    conquerCheckerRollout.btnLocate.pressed()
    if selection.count != 1 or selection[1] != badModel do throw "problem selection failed"
    if ConquerMaxChecker.busy or not conquerCheckerRollout.btnLocate.enabled do throw "busy state not released"
    buttonRecord "LOCATE_HANDLER_OK"
    conquerCheckerRollout.btnOpenBackup.pressed()
    if ConquerMaxChecker.busy or not conquerCheckerRollout.btnOpenBackup.enabled do throw "backup busy state not released"
    if findString conquerCheckerRollout.lblStatus.text "ConquerMaxChecker\\backups" == undefined do throw "backup handler did not finish"
    buttonRecord "BACKUP_HANDLER_OK"
    buttonRecord "PASS"
)
catch(buttonRecord ("FAIL " + getCurrentException() as string))
close buttonTestLog
quitMAX #noPrompt
