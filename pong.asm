; pong.asm - 64-bit Pong game with raylib
; Compile with: nasm -f elf64 pong.asm -o pong.o && gcc pong.o -o pong -lraylib -lm -no-pie

section .data
    ; Raylib key codes
    KEY_W      equ 87
    KEY_S      equ 83
    KEY_UP     equ 265
    KEY_DOWN   equ 264
    
    ; Raylib functions
    extern InitWindow, CloseWindow, WindowShouldClose
    extern BeginDrawing, EndDrawing, ClearBackground
    extern DrawRectangle, DrawText, DrawFPS
    extern SetTargetFPS, GetScreenWidth, GetScreenHeight
    extern IsKeyDown
    
    ; Colors
    BLACK      equ 0xFF000000
    WHITE      equ 0xFFFFFFFF
    
    ; Strings
    title db "Pong in x86-64 Assembly with raylib", 0
    score_format db "%d", 0
    
    ; Game variables
    screen_width dd 800
    screen_height dd 450
    paddle_width dd 20
    paddle_height dd 100
    ball_size dd 15
    
    player1_x dd 20
    player1_y dd 175
    player1_score dd 0
    player1_text db "0", 0
    
    player2_x dd 760
    player2_y dd 175
    player2_score dd 0
    player2_text db "0", 0
    
    ball_x dd 400
    ball_y dd 225
    ball_speed_x dd 4
    ball_speed_y dd 4

section .text
    global main
    extern printf, sprintf

main:
    push rbp
    mov rbp, rsp
    
    ; Initialize window
    mov edi, [screen_width]
    mov esi, [screen_height]
    mov rdx, title
    call InitWindow
    
    ; Set FPS
    mov edi, 60
    call SetTargetFPS

.game_loop:
    ; Check if window should close
    call WindowShouldClose
    test eax, eax
    jnz .close_window
    
    ; --- Player input ---
    ; Player 1 (W/S keys)
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
    
    ; Player 2 (Up/Down arrows)
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
    
    ; --- Ball movement ---
.move_ball:
    mov eax, [ball_speed_x]
    add [ball_x], eax
    
    mov eax, [ball_speed_y]
    add [ball_y], eax
    
    ; --- Wall collisions ---
    ; Top wall
    mov eax, [ball_y]
    cmp eax, 0
    jg .check_bottom
    neg dword [ball_speed_y]
    
.check_bottom:
    ; Bottom wall
    mov eax, [ball_y]
    mov ebx, [screen_height]
    sub ebx, [ball_size]
    cmp eax, ebx
    jl .check_paddle1
    neg dword [ball_speed_y]
    
    ; --- Paddle collisions ---
.check_paddle1:
    ; Left paddle
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
    ; Right paddle
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
    
    ; --- Goal detection ---
.check_goals:
    ; Left goal
    mov eax, [ball_x]
    cmp eax, 0
    jg .check_right_goal
    inc dword [player2_score]
    
    ; Update score text
    mov rdi, player2_text
    mov rsi, score_format
    mov edx, [player2_score]
    call sprintf
    
    call reset_ball
    
.check_right_goal:
    ; Right goal
    mov eax, [ball_x]
    mov ebx, [screen_width]
    cmp eax, ebx
    jl .draw
    inc dword [player1_score]
    
    ; Update score text
    mov rdi, player1_text
    mov rsi, score_format
    mov edx, [player1_score]
    call sprintf
    
    call reset_ball
    
    ; --- Drawing ---
.draw:
    call BeginDrawing
    
    ; Black background
    mov edi, BLACK
    call ClearBackground
    
    ; Left paddle
    mov edi, [player1_x]
    mov esi, [player1_y]
    mov edx, [paddle_width]
    mov ecx, [paddle_height]
    mov r8d, WHITE
    call DrawRectangle
    
    ; Right paddle
    mov edi, [player2_x]
    mov esi, [player2_y]
    mov edx, [paddle_width]
    mov ecx, [paddle_height]
    mov r8d, WHITE
    call DrawRectangle
    
    ; Ball
    mov edi, [ball_x]
    mov esi, [ball_y]
    mov edx, [ball_size]
    mov ecx, [ball_size]
    mov r8d, WHITE
    call DrawRectangle
    
    ; Player 1 score (left side)
    mov rdi, player1_text
    mov esi, [screen_width]
    shr esi, 2      ; screen_width / 4
    mov edx, 30     ; Y position
    mov ecx, 40     ; Font size
    mov r8d, WHITE
    call DrawText
    
    ; Player 2 score (right side)
    mov rdi, player2_text
    mov esi, [screen_width]
    shr esi, 1      ; screen_width / 2
    add esi, [screen_width]
    shr esi, 1      ; screen_width * 3/4
    mov edx, 30     ; Y position
    mov ecx, 40     ; Font size
    mov r8d, WHITE
    call DrawText
    
    ; FPS counter
    mov edi, 10
    mov esi, 10
    call DrawFPS
    
    call EndDrawing
    
    jmp .game_loop
    
.close_window:
    call CloseWindow
    
    ; Exit program
    mov rsp, rbp
    pop rbp
    xor eax, eax
    ret
    
reset_ball:
    ; Reset ball to center
    mov eax, [screen_width]
    shr eax, 1
    mov [ball_x], eax
    
    mov eax, [screen_height]
    shr eax, 1
    mov [ball_y], eax
    
    ; Reverse direction
    neg dword [ball_speed_x]
    mov dword [ball_speed_y], 4
    ret
