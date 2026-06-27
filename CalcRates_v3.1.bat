@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo ==============================================
echo 杜比视界® Profile 7 VBV 参数计算器 (MEL / FEL)
echo 输入 VBV_safeRate (整数 Mbps) 并选择增强层类型
echo ==============================================
echo.

:INPUT_SAFE_RATE
  set /p "SAFE_RATE_IN=请输入 VBV_safeRate (整数 Mbps): "
  set "SAFE_RATE_MAX=%SAFE_RATE_IN: =%"

  if "%SAFE_RATE_MAX%"=="" (
    echo 错误：输入不能为空。
    echo.
    goto INPUT_SAFE_RATE
  )

  echo %SAFE_RATE_MAX%| findstr /r "^[1-9][0-9]*$" >nul
  if errorlevel 1 (
    echo 错误：必须输入大于 0 的整数，且不能有前导零。
    echo.
    goto INPUT_SAFE_RATE
  )

:INPUT_TYPE
  set /p "TYPE=请选择增强层类型 (MEL / FEL): "
  set "TYPE=%TYPE: =%"

  if /i "%TYPE%"=="MEL" goto TYPE_OK
  if /i "%TYPE%"=="FEL" goto TYPE_OK
  echo 错误：增强层类型必须输入 MEL 或 FEL。
  echo.
  goto INPUT_TYPE

:TYPE_OK

if /i "%TYPE%"=="MEL" goto MEL_GLOBAL
goto FEL_ORIGINAL

:MEL_GLOBAL
set "BEST_BL_MAX_RATE=0"
set "BEST_SAFE_RATE=0"
set "BEST_BL_RATIO=0"
set "BEST_BL_BUFF=0"
set "BEST_EL_BUFF=0"

set "TEST_SAFE=%SAFE_RATE_MAX%"
:LOOP_MEL
if %TEST_SAFE% LSS 1 goto END_MEL

set /a VBV_MAX_RATE = TEST_SAFE * 900
set /a VBV_BUFF_SIZE = TEST_SAFE * 300

for %%r in (995 990 985 980) do (
    set /a "TEST=VBV_MAX_RATE * %%r %% 1000"
    if !TEST! EQU 0 (
        set /a "BL_MAX=VBV_MAX_RATE * %%r / 1000"
        set /a "EL_MAX=VBV_MAX_RATE - BL_MAX"
        if !BL_MAX! LEQ 100000 if !EL_MAX! LEQ 100000 (
            if !BL_MAX! GTR !BEST_BL_MAX_RATE! (
                set "BEST_BL_MAX_RATE=!BL_MAX!"
                set "BEST_SAFE_RATE=!TEST_SAFE!"
                set "BEST_BL_RATIO=%%r"
                set /a "BL_BUFF=VBV_BUFF_SIZE * %%r / 1000"
                set "BEST_BL_BUFF=!BL_BUFF!"
                set /a "EL_BUFF=VBV_BUFF_SIZE - BL_BUFF"
                set "BEST_EL_BUFF=!EL_BUFF!"
                set "BEST_EL_MAX=!EL_MAX!"
            )
        )
    )
)

set /a TEST_SAFE -= 1
goto LOOP_MEL

:END_MEL
if %BEST_SAFE_RATE% EQU 0 (
    echo 错误：即使在 1 Mbps 下也找不到满足约束的组合。
    goto END
)

rem 转换比例字符串
if %BEST_BL_RATIO% EQU 995 set "RATIO=99.5%%, 0.5%%"
if %BEST_BL_RATIO% EQU 990 set "RATIO=99%%, 1%%"
if %BEST_BL_RATIO% EQU 985 set "RATIO=98.5%%, 1.5%%"
if %BEST_BL_RATIO% EQU 980 set "RATIO=98%%, 2%%"

if not "%SAFE_RATE_MAX%"=="%BEST_SAFE_RATE%" (
    echo.
    echo 注意：%SAFE_RATE_MAX% Mbps 无满足约束的组合，已自动降低至 %BEST_SAFE_RATE% Mbps。
)

echo.
echo ===== 计算结果 (MEL) =====
echo VBV_safeRate = %BEST_SAFE_RATE% Mbps
echo BL_maxRate   = %BEST_BL_MAX_RATE% Kbps
echo BL_buffSize  = %BEST_BL_BUFF% Kbps
echo MEL_maxRate  = %BEST_EL_MAX% Kbps
echo MEL_buffSize = %BEST_EL_BUFF% Kbps
echo BL_MEL_ratio = %RATIO%
echo ==========================
goto END

:FEL_ORIGINAL
set "SAFE_RATE=%SAFE_RATE_MAX%"
set "ORIGINAL_SAFE_RATE=%SAFE_RATE%"

:SAFE_LOOP_FEL
if %SAFE_RATE% LSS 1 (
    echo 错误：即使降低到 1 Mbps 也找不到满足约束的组合。
    goto END
)

set /a VBV_MAX_RATE = SAFE_RATE * 900
set /a VBV_BUFF_SIZE = SAFE_RATE * 300

set /a MAX_Z2 = 10000000 / VBV_MAX_RATE
if !MAX_Z2! GTR 95 set MAX_Z2=95
if !MAX_Z2! LSS 80 (
    set /a SAFE_RATE -= 1
    goto SAFE_LOOP_FEL
)

set "Z2=!MAX_Z2!"
set /a Z3 = 100 - Z2
set /a BL_MAX = VBV_MAX_RATE * Z2 / 100
set /a FEL_MAX = VBV_MAX_RATE - BL_MAX

if !BL_MAX! LEQ 100000 if !FEL_MAX! LEQ 100000 goto FEL_FOUND
set /a SAFE_RATE -= 1
goto SAFE_LOOP_FEL

:FEL_FOUND
if not "%ORIGINAL_SAFE_RATE%"=="%SAFE_RATE%" (
    echo.
    echo 注意：%ORIGINAL_SAFE_RATE% Mbps 无满足约束的组合，已自动降低至 %SAFE_RATE% Mbps。
)
set /a BL_BUFF = VBV_BUFF_SIZE * Z2 / 100
set /a FEL_BUFF = VBV_BUFF_SIZE - BL_BUFF
set "RATIO=!Z2!%%, !Z3!%%"

echo.
echo ===== 计算结果 (FEL) =====
echo VBV_safeRate = %SAFE_RATE% Mbps
echo BL_maxRate   = %BL_MAX% Kbps
echo BL_buffSize  = %BL_BUFF% Kbps
echo FEL_maxRate  = %FEL_MAX% Kbps
echo FEL_buffSize = %FEL_BUFF% Kbps
echo BL_FEL_ratio = %RATIO%
echo ==========================
goto END

:END
echo.
pause
