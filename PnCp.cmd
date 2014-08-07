@echo off
setlocal enableextensions
if exist Pn\Config.cmd pushd . && goto cfg
if exist ..\Pn\Config.cmd pushd .. && goto cfg
goto :eof

:cfg
call Pn\Config.cmd 
if "%php%"=="" exit /b

if "%1"=="exec" if not "%2"=="" cmd /c "%2 %3 %4 %5 %6" && goto :eof
if not "%1"=="" (
  call :%1 %2
  goto :eof
)

prompt -$g
title PHPnow %pn_ver% ������� (Apache %htd_ver%, %php_dir%, %myd_dir%)
goto menu


:restart_apache
if not exist %htd_dir%\logs\httpd.pid goto :eof
echo.
echo  �������� Apache ...
pushd %htd_dir%
bin\%htd_exe% -k restart -n %htd_svc% || set errno=1
popd
if "%errno%"=="1" %pause%
goto :eof


:execmd
if exist %1 call %1 && goto :eof
if exist %PnCmds%\%1 call %PnCmds%\%1 && goto :eof
echo # δ�ҵ� %1 !
%pause%
goto :eof


:menu
echo     __________________________________________________________________________
echo    ^|                                                                          ^|
echo    ^|                     Windows����ϵͳPHP�������������                     ^|
echo    ^|                                                                          ^|
echo    ^|   1  - ���Apache��MySQL�˿�ʹ��״̬                                     ^|
echo    ^|                                                                          ^|
echo    ^|   2  - ����Apache��������MySQL���ݿ�                                     ^|
echo    ^|                                                                          ^|
echo    ^|   3  - ֹͣApache��������MySQL���ݿ�                                     ^|
echo    ^|                                                                          ^|
echo    ^|   4  - ǿ����ֹApache��������MySQL���ݿ���̲�ж��                       ^|
echo    ^|                                                                          ^|
echo    ^|   5  - ���� Apache �������˿�        6  - ���� MySQL root ����           ^|
echo    ^|                                                                          ^|
echo    ^|   7  - ��������Apache������          8  - ��������MySQL���ݿ�            ^|
echo    ^|                                                                          ^|
echo    ^|   9  - ����ֹͣApache������          10 - ����ֹͣMySQL���ݿ�            ^|
echo    ^|                                                                          ^|
echo    ^|   11 - ��������Apache������          12 - ��������MySQL���ݿ�            ^|
echo    ^|                                                                          ^|
echo    ^|   13 - ����PHP��error_reporting                                          ^|
echo    ^|__________________________________________________________________________^|
set /p input=-^> ��ѡ��: 
cls
echo.
if "%input%"== "1"  goto chk_port
if "%input%"== "2"  call :execmd Start.cmd
if "%input%"== "3"  call :execmd Stop.cmd
if "%input%"== "4"  goto force_stop
if "%input%"== "5"  goto chg_port
if "%input%"== "6"  goto reset_mydpwd 
if "%input%"== "7"  call :execmd Apa_Start.cmd
if "%input%"== "8"  call :execmd My_Start.cmd
if "%input%"== "9"  call :execmd Apa_Stop.cmd
if "%input%"== "10" call :execmd My_Stop.cmd
if "%input%"== "11" call :execmd Apa_Restart.cmd
if "%input%"== "12" call :execmd My_Restart.cmd
if "%input%"== "13" goto err_report
goto end

:chg_port
set /p nport=-^> �����µ� http �˿�(1-65535): 
if "%nport%"=="" goto end
%php% "$p = env('nport'); if ($p !== ''.ceil($p) || 1 > $p || $p > 65535) exit(1);" || goto chg_port
%php% "chg_port(env('nport'));" || %pause% && goto end
set htd_port=%nport%
if "%1"=="noRestart" goto end
call :restart_apache
goto end

:chk_port
if not exist %Sys32%\tasklist.exe goto chk_port_1
if not exist %Sys32%\netstat.exe goto chk_port_2
%php% "chk_port('%htd_port%');"
if not errorlevel 1 echo   ָ���� httpd �˿� %htd_port% ��ʱδ��ռ��.
%php% "chk_port('%myd_port%');"
if not errorlevel 1 echo   ָ���� MySQL �˿� %myd_port% ��ʱδ��ռ��.
echo.
%pause% & goto end
:chk_port_1
echo  # ȱ�� %Sys32%\tasklist.exe, �޷�����. & %pause% & goto end
:chk_port_2
echo  # ȱ�� %Sys32%\netstat.exe, �޷�����. & %pause% & goto end

:err_report
echo   ________________________________________________________________
echo  ^|                                                                ^|
echo  ^|        ���� php error_reporting (���󱨸�) �ȼ�                ^|
echo  ^|                                                                ^|
echo  ^|     0 - E_ALL ^& ~E_NOTICE ^& ~E_WARNING                         ^|
echo  ^|                               ��ͨ; ��������, ����һ�㾯��     ^|
echo  ^|                                                                ^|
echo  ^|     1 - E_ALL                                                  ^|
echo  ^|                               �ϸ�; ���Ի���, ��ʾ���д���     ^|
echo  ^|________________________________________________________________^|
set /p input=-^> ��ѡ��: 
if "%input%"=="0" set err_reporting=E_ALL ^& ~E_NOTICE ^& ~E_WARNING
if "%input%"=="1" set err_reporting=E_ALL
if "%err_reporting%"=="" goto end
%php% "frpl($php_ini, '^(error_reporting)\s*=.*(\r\n)', '$1 = %err_reporting%$2');" || %pause% && goto end
call :restart_apache
goto end


:reset_mydpwd
set /p newpwd=-^> ���� root ����: 
if "%newpwd%"=="" goto reset_mydpwd
echo.
set pnTmp=%SystemRoot%\Temp\Pn_%RANDOM%.%RANDOM%
echo SET PASSWORD FOR 'root'@'localhost' = PASSWORD('%newpwd%');>%pnTmp%
if exist %myd_dir%\data\%COMPUTERNAME%.pid %net% stop %myd_svc%
set myini=%CD%\%myd_dir%\my.ini
start /b %myd_dir%\bin\%myd_exe% --defaults-file="%myini%" --init-file=%pnTmp%
%myd_dir%\bin\mysqladmin.exe shutdown -uroot -p"%newpwd%"
echo  �ȴ� MySQL �˳� ...
echo.
%php% "while(@file_exists('%myd_dir%\data\%COMPUTERNAME%.pid')) usleep(50000);"
echo.>%pnTmp%
del %pnTmp% /Q
%net% start %myd_svc% || %pause%
goto end

:force_stop
set taskkill=%Sys32%\taskkill.exe
if not exist %taskkill% (
  echo  # ȱ�� %taskkill%, �޷�����. & %pause% & goto end
)
%taskkill% /fi "SERVICES eq %htd_svc%" /f /t
%taskkill% /fi "SERVICES eq %myd_svc%" /f /t
%net% stop %myd_svc%>nul 2>nul
%net% stop %htd_svc%>nul 2>nul
%htd_dir%\bin\%htd_exe% -k uninstall -n %htd_svc%>nul 2>nul
%myd_dir%\bin\%myd_exe% --remove %myd_svc%>nul 2>nul
del %myd_dir%\data\%COMPUTERNAME%.pid %htd_dir%\logs\httpd.pid /q>nul 2>nul
%pause%
goto end

:end
prompt
popd