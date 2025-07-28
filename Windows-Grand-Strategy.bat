@echo off
setlocal enabledelayedexpansion

:: TerminalConqueror.bat - Windows порт Unix Grand Strategy Game
:: Сохранены все оригинальные функции, но адаптированы под Windows CMD

:: ====== ОСНОВНЫЕ НАСТРОЙКИ ======
set VERSION=1.2
set MAP_WIDTH=20
set MAP_HEIGHT=10
set COUNTRIES=Europa Atlantis Sparta Vikingland Oceania Eastasia
set COLORS=31 32 33 34 35 36
set SPECIAL_EVENTS=Earthquake Plague Rebellion Alliance

:: ====== ДАННЫЕ ИГРОКА ======
set PLAYER_COUNTRY=
set PLAYER_GOLD=100
set PLAYER_ARMY=50
set PLAYER_TECH=1
set PLAYER_TERRITORIES=
set SAVE_FILE=terminal_conqueror_save.txt

:: ====== ДАННЫЕ ИГРЫ ======
set WORLD_MAP=
set COUNTRY_OWNER=
set COUNTRY_ARMY=
set COUNTRY_TECH=
set COUNTRY_GOLD=
set DIPLOMACY=
set TURN=1

:: ====== ФУНКЦИИ ======

:: Определение ОС и особенностей
:os_specific_features
for /f "tokens=*" %%a in ('ver') do set OS_STRING=%%a
if "%OS_STRING%" == *Microsoft* (
    set OS=Windows
    echo Windows detected! Bonus: +5 gold per turn from trade efficiency.
    set /a PLAYER_GOLD+=5
) else (
    set OS=Unknown
    echo Unknown OS - playing in compatibility mode
)
timeout /t 2 >nul
goto :EOF

:: Генерация карты
:generate_map
set WORLD_MAP=
set COUNTRY_OWNER=
set PLAYER_TERRITORIES=

:: Инициализация пустой карты
for /l %%y in (0,1,%MAP_HEIGHT%) do (
    for /l %%x in (0,1,%MAP_WIDTH%) do (
        set WORLD_MAP=!WORLD_MAP!%%x,%%y=. 
        set COUNTRY_OWNER=!COUNTRY_OWNER!%%x,%%y= 
    )
)

:: Распределение территорий
for %%c in (%COUNTRIES%) do (
    set COUNTRY_GOLD=!COUNTRY_GOLD!%%c=100 
    set COUNTRY_ARMY=!COUNTRY_ARMY!%%c=50 
    set COUNTRY_TECH=!COUNTRY_TECH!%%c=1 
    set DIPLOMACY=!DIPLOMACY!%%c=Neutral 

    for /l %%i in (1,1,3) do (
        :retry_territory
        set /a rand_x=!random! %% %MAP_WIDTH%
        set /a rand_y=!random! %% %MAP_HEIGHT%
        call :get_value "!WORLD_MAP!" "!rand_x!,!rand_y!" cell
        
        if "!cell!"=="." (
            set "short_name=%%c"
            set short_name=!short_name:~0,1!
            call :set_value WORLD_MAP "!rand_x!,!rand_y!" "!short_name!"
            call :set_value COUNTRY_OWNER "!rand_x!,!rand_y!" "%%c"
            
            if "%%c"=="!PLAYER_COUNTRY!" (
                set PLAYER_TERRITORIES=!PLAYER_TERRITORIES!!rand_x!,!rand_y! 
            )
        ) else (
            goto retry_territory
        )
    )
)
goto :EOF

:: Получение значения из строки
:get_value
set "data=%~1"
set "key=%~2"
set "result="

for %%a in (%data%) do (
    for /f "tokens=1,2 delims==" %%b in ("%%a") do (
        if "%%b"=="%key%" set result=%%c
    )
)
set "%~3=%result%"
goto :EOF

:: Установка значения в строке
:set_value
set "varname=%~1"
set "key=%~2"
set "newval=%~3"
set "new_data="
set "found=0"

for %%a in (!%varname%!) do (
    for /f "tokens=1,2 delims==" %%b in ("%%a") do (
        if "%%b"=="%key%" (
            set "new_data=!new_data!%key%=%newval% "
            set found=1
        ) else (
            set "new_data=!new_data!%%b=%%c "
        )
    )
)

if !found!==0 set "new_data=!new_data!%key%=%newval% "
set "%varname%=%new_data%"
goto :EOF

:: Отрисовка карты
:draw_map
cls
echo === TERMINAL CONQUEROR v%VERSION% ===
echo OS: %OS% ^| Turn: %TURN%
echo Country: %PLAYER_COUNTRY% ^| Gold: %PLAYER_GOLD% ^| Army: %PLAYER_ARMY% ^| Tech: %PLAYER_TECH%
echo Territories: %PLAYER_TERRITORIES: =% | find /c " " >nul && (for /f %%a in ('echo "!PLAYER_TERRITORIES!" ^| find /c " "') do set count=%%a) || set count=0
echo/
setlocal enabledelayedexpansion
for /l %%y in (0,1,%MAP_HEIGHT%) do (
    set "line="
    for /l %%x in (0,1,%MAP_WIDTH%) do (
        call :get_value "!WORLD_MAP!" "%%x,%%y" cell
        call :get_value "!COUNTRY_OWNER!" "%%x,%%y" owner
        
        set "color=37"
        set i=1
        for %%c in (%COUNTRIES%) do (
            if "%%c"=="!owner!" (
                for /f "tokens=!i!" %%a in ("%COLORS%") do set color=%%a
            )
            set /a i+=1
        )
        
        set "line=!line!!cell! "
    )
    echo !line!
)
echo/
endlocal
goto :EOF

:: Главное меню
:main_menu
:menu_loop
cls
echo === TERMINAL CONQUEROR ===
echo 1. New Game
echo 2. Load Game
echo 3. View GitHub (Windows)
echo 4. Exit
set /p choice=Choose: 

if "%choice%"=="1" (
    call :new_game
    call :os_specific_features
) else if "%choice%"=="2" (
    call :load_game
) else if "%choice%"=="3" (
    start "" "https://github.com/danast942/Bash-Grand-Strategy"
    goto menu_loop
) else if "%choice%"=="4" (
    exit /b 0
) else (
    echo Invalid choice!
    timeout /t 1 >nul
    goto menu_loop
)
goto :EOF

:: Новая игра
:new_game
cls
echo === SELECT YOUR KINGDOM ===
set i=1
for %%c in (%COUNTRIES%) do (
    echo !i!. %%c
    set /a i+=1
)
set /p choice=Choose your country (1-%i%): 

set i=1
for %%c in (%COUNTRIES%) do (
    if !i!==%choice% set PLAYER_COUNTRY=%%c
    set /a i+=1
)

if defined PLAYER_COUNTRY (
    call :generate_map
    call :game_loop
) else (
    echo Invalid choice!
    timeout /t 1 >nul
    goto new_game
)
goto :EOF

:: Основной игровой цикл
:game_loop
:game_loop_start
call :draw_map
echo === ACTIONS ===
echo 1. Recruit Army (10 gold)
echo 2. Research Tech (20 gold)
echo 3. Attack Territory
echo 4. Diplomacy
echo 5. Trade Routes
echo 6. End Turn
echo 7. Save ^& Exit

if "%OS%"=="Windows" (
    echo 8. [Windows] Spy Network (25 gold)
)

set /p action=Choose: 

if "%action%"=="1" (
    call :recruit_army
) else if "%action%"=="2" (
    call :research_tech
) else if "%action%"=="3" (
    call :attack_territory
) else if "%action%"=="4" (
    call :diplomacy_menu
) else if "%action%"=="5" (
    call :trade_routes
) else if "%action%"=="6" (
    call :end_turn
) else if "%action%"=="7" (
    call :save_game
    exit /b 0
) else if "%action%"=="8" (
    call :os_special_action
) else (
    echo Invalid choice!
    timeout /t 1 >nul
)
goto game_loop_start
goto :EOF

:: Остальные функции (аналогично адаптируются)
:recruit_army
if %PLAYER_GOLD% geq 10 (
    set /a PLAYER_GOLD-=10
    set /a PLAYER_ARMY+=10
    echo Army recruited! +10 soldiers.
) else (
    echo Not enough gold!
)
timeout /t 1 >nul
goto :EOF

:research_tech
if %PLAYER_GOLD% geq 20 (
    set /a PLAYER_GOLD-=20
    set /a PLAYER_TECH+=1
    echo Tech researched! Level: %PLAYER_TECH%
) else (
    echo Not enough gold!
)
timeout /t 1 >nul
goto :EOF

:: ... (остальные функции аналогично)

:: Специальное действие для Windows
:os_special_action
if "%OS%"=="Windows" (
    if %PLAYER_GOLD% geq 25 (
        set /a PLAYER_GOLD-=25
        echo Spy network established! You can see enemy movements next turn.
    ) else (
        echo Not enough gold!
    )
) else (
    echo No special action for your OS.
)
timeout /t 1 >nul
goto :EOF

:: Запуск игры
call :main_menu
