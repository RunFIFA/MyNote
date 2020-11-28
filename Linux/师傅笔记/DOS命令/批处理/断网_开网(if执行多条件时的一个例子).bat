@echo off
devcon disable *DEV_1691* > nul
echo 网卡已被禁用！
echo.
echo 启用网卡请输入1按回车；退出请输入2按回车，或关闭此窗口！
echo.
set /p number="请输入："
echo.
if %number% equ "1" (goto 2)  
if %number% equ "2" (goto 3)
if %number% gtr "2" (goto 1) else (goto 1)
:1
set /p number="输入有误，请输入1或2："
echo.
if %number% equ "1" (goto 2)  
if %number% equ "2" (goto 3)
if %number% gtr "2" (goto 1) else (goto 1)
:2
devcon enable *DEV_1691* > nul
echo.
echo 网卡已启用！
ping 127.0.0.1 /n 3 > nul
exit
:3
echo.
echo 即将退出...
ping 127.0.0.1 /n 3 > nul
exit

注：devcon是一个外部dos命令，可以启用、禁用、重新启动、更新、删除和查询单个设备或一组设备。

devcon查询pci设备：

输入：devcon find pci\*

#列出本地计算机上所有已知的PCI 设备,如下，这是本人的网卡一行：

PCI＼VEN_13F0&DEV_0201&SUBSYS_020113F0&REV_14＼3&13C0B0C5&0&48: Sundance ST201 based PCI Fast Ethernet Adapter #3

记下第一个&和第二个&之间的设备代码，例如我的网卡就是：DEV_0201
