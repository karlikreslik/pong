; pong.asm - 64-bitová verze hry Pong s raylib
; Kompilace: nasm -f elf64 pong.asm -o pong.o && gcc pong.o -o pong -lraylib -lm -no-pie

section .data
    ; Definice kláves z raylib
    KEY_W      equ 87
    KEY_S      equ 83
    KEY_UP     equ 265
    KEY_DOWN   equ 264
    
    ; Raylib funkce
    extern InitWindow, CloseWindow, WindowShouldClose
    extern BeginDrawing, EndDrawing, ClearBackground
    extern DrawRectangle, DrawText, DrawFPS
    extern SetTargetFPS, GetScreenWidth, GetScreenHeight
    extern IsKeyDown
    
    ; Barvy
    BLACK      equ 0xFF000000
    WHITE      equ 0xFFFFFFFF
    
    ; Textové řetězce
    title db "Pong v x86-64 Assembly + raylib", 0
    score_format db "%d", 0
    
    ; Herní proměnné
    screen_width dd 800
    screen_height dd 450
    paddle_width dd 20
    paddle_height dd 100
    ball_size dd 15
    
    player1_x dd 20
    player1_y dd 175
    player1_score dd 0
    
    player2_x dd 760
    player2_y dd 175
    player2_score dd 0
    
    ball_x dd 400
    ball_y dd 225
    ball_speed_x dd 4
    ball_speed_y dd 4

section .bss
    score_text resb 16

section .text
    global main
    
    ; Pro printf
    extern printf, sprintf

main:
    push rbp
    mov rbp, rsp
    
    ; Inicializace okna (InitWindow(width, height, title))
    mov edi, [screen_width]
    mov esi, [screen_height]
    mov rdx, title
    call InitWindow
    
    ; Nastavení FPS (SetTargetFPS(60))
    mov edi, 60
    call SetTargetFPS

.game_loop:
    ; Kontrola zavření okna
    call WindowShouldClose
    test eax, eax
    jnz .close_window
    
    ; --- Vstup ---
    ; Hráč 1 (W/S)
    mov edi, KEY_W
    call IsKeyDown
    test eax, eax
    jz .check_s
    sub dword [player1_y], 5
    
.check_s:
    mov edi, KEY_S
    call IsKeyDown
    test eax, eax
    jz .check_up
    add dword [player1_y], 5
    
    ; Hráč 2 (šipky nahoru/dolů)
.check_up:
    mov edi, KEY_UP
    call IsKeyDown
    test eax, eax
    jz .check_down
    sub dword [player2_y], 5
    
.check_down:
    mov edi, KEY_DOWN
    call IsKeyDown
    test eax, eax
    jz .move_ball
    add dword [player2_y], 5
    
    ; --- Pohyb míčku ---
.move_ball:
    mov eax, [ball_speed_x]
    add [ball_x], eax
    
    mov eax, [ball_speed_y]
    add [ball_y], eax
    
    ; --- Kolize s hranami ---
    ; Horní stěna
    mov eax, [ball_y]
    cmp eax, 0
    jg .check_bottom
    neg dword [ball_speed_y]
    
.check_bottom:
    ; Dolní stěna
    mov eax, [ball_y]
    mov ebx, [screen_height]
    sub ebx, [ball_size]
    cmp eax, ebx
    jl .check_paddle1
    neg dword [ball_speed_y]
    
    ; --- Kolize s pádly ---
.check_paddle1:
    ; Levé pádlo
    mov eax, [ball_x]
    mov ebx, [player1_x]
    add ebx, [paddle_width]
    cmp eax, ebx
    jg .check_paddle2
    
    mov eax, [ball_y]
    mov ebx, [player1_y]
    cmp eax, ebx
    jl .check_paddle2
    
    add ebx, [paddle_height]
    cmp eax, ebx
    jg .check_paddle2
    
    neg dword [ball_speed_x]
    
.check_paddle2:
    ; Pravé pádlo
    mov eax, [ball_x]
    add eax, [ball_size]
    cmp eax, [player2_x]
    jl .check_goals
    
    mov eax, [ball_y]
    mov ebx, [player2_y]
    cmp eax, ebx
    jl .check_goals
    
    add ebx, [paddle_height]
    cmp eax, ebx
    jg .check_goals
    
    neg dword [ball_speed_x]
    
    ; --- Kontrola gólů ---
.check_goals:
    ; Levý okraj
    mov eax, [ball_x]
    cmp eax, 0
    jg .check_right_goal
    inc dword [player2_score]
    call reset_ball
    
.check_right_goal:
    ; Pravý okraj
    mov eax, [ball_x]
    mov ebx, [screen_width]
    cmp eax, ebx
    jl .draw
    inc dword [player1_score]
    call reset_ball
    
    ; --- Vykreslení ---
.draw:
    call BeginDrawing
    
    ; Černé pozadí
    mov edi, BLACK
    call ClearBackground
    
    ; Levé pádlo
    mov edi, [player1_x]
    mov esi, [player1_y]
    mov edx, [paddle_width]
    mov ecx, [paddle_height]
    mov r8d, WHITE
    call DrawRectangle
    
    ; Pravé pádlo
    mov edi, [player2_x]
    mov esi, [player2_y]
    mov edx, [paddle_width]
    mov ecx, [paddle_height]
    mov r8d, WHITE
    call DrawRectangle
    
    ; Míček
    mov edi, [ball_x]
    mov esi, [ball_y]
    mov edx, [ball_size]
    mov ecx, [ball_size]
    mov r8d, WHITE
    call DrawRectangle
    
    ; Skóre hráče 1
    mov rdi, score_text
    mov rsi, score_format
    mov edx, [player1_score]
    call sprintf
    
    mov rdi, score_text
    mov esi, 10
    mov edx, 200
    mov ecx, 30
    mov r8d, WHITE
    call DrawText
    
    ; Skóre hráče 2
    mov rdi, score_text
    mov rsi, score_format
    mov edx, [player2_score]
    call sprintf
    
    mov rdi, score_text
    mov esi, 10
    mov edx, 600
    mov ecx, 30
    mov r8d, WHITE
    call DrawText
    
    ; FPS
    mov edi, 10
    mov esi, 10
    call DrawFPS
    
    call EndDrawing
    
    jmp .game_loop
    
.close_window:
    call CloseWindow
    
    ; Ukončení programu
    mov rsp, rbp
    pop rbp
    xor eax, eax
    ret
    
reset_ball:
    ; Reset míčku do středu
    mov eax, [screen_width]
    shr eax, 1
    mov [ball_x], eax
    
    mov eax, [screen_height]
    shr eax, 1
    mov [ball_y], eax
    
    ; Náhodný směr (pro zjednodušení jen obrácení směru)
    neg dword [ball_speed_x]
    mov dword [ball_speed_y], 4
    ret
