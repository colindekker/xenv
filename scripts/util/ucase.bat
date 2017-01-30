@echo off
goto :end_remarks
*************************************************************************************
*
*
*	authored:Sam Wofford
*	Returns uppercase of a string
*	12:07 PM 11/13/02
**************************************************************************************
:end_remarks
setlocal
set errorlevel=-1
if {%1}=={} echo NO ARG GIVEN&call :Help &goto :endit
if {%1}=={/?} call :Help &set errorlevel=&goto :endit
call :set_ucase_array A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
:start
set input=%1
set input=%input:"=%
set totparams=0
call :COUNT_PARAMS %input%
call :MAKE_UPPEERCASE %input%
set errorlevel=
echo %convertedstring%
endlocal
goto :eof
:endit
echo %errorlevel%
endlocal
goto :eof

:MAKE_UPPEERCASE
:nextstring
if {%1}=={} goto :eof
set string=%1
set /a params+=1
set STRINGCONVERTED=
set pos=0
:NEXT_CHAR
set onechar=%%string^:^~%pos%,1%%
for /f "tokens=1,2 delims==" %%a in ('set onechar') do for /f %%c in ('echo %%b') do call :checkit %%c
if not defined STRINGCONVERTED goto :NEXT_CHAR
shift /1
if %params% LSS %totparams% set convertedstring=%convertedstring% &:add one space,but not at end
goto :nextstring
goto :eof

:Help
echo USAGE:%~n0 string OR %~n0 "see with spaces"
echo function returns the uppercase of the string or -1 (error)
echo strings with embedded spaces needs to be in quotes Ex. "upper case"
echo in a batch NTscript "for /f %%%%A in ('ucase STRING') do set var=%%%%A"
goto :eof

:checkit
if /i {%1}=={echo} set STRINGCONVERTED=Y&goto :eof
set char=%1
set UCFOUND=
for /f "tokens=2 delims=_=" %%A in ('set UCASE_') do call :findit %%A %char%
if defined UCFOUND (set convertedstring=%convertedstring%%ucletter%) else (set convertedstring=%convertedstring%%char%)

set /a pos+=1
goto :eof

:set_ucase_array
:setit
if {%1}=={} goto :eof
set UCASE_%1_=%1
SHIFT /1
goto :setit

:findit
if defined UCFOUND goto :eof
set ucletter=%1
set lcchar=%2
if /i {%ucletter%}=={%lcchar%} set UCFOUND=yes
goto :eof

:COUNT_PARAMS
:COUNTPARAMS
if {%1}=={} goto :eof
set /a totparams+=1
shift /1
goto :COUNTPARAMS
