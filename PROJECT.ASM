.model small
.stack 100h

.data
; FILE SYSTEM 
filename    db 'student.txt',0
fileHandle  dw ?
tempChar    db ?

lblR        db 'Roll: $'
lblN        db ' Name: $'
lblS        db ' Sem: $'
lblC        db ' CGPA: $'
newlineFile db 13,10

; MENU & PROMPTS
menuMsg     db 13,10,'1. Add Student',13,10,'2. Display All Students',13,10
            db '3. Exit',13,10,'Enter choice: $'

enterRoll   db 13,10,'Enter Roll Number: $'
enterName   db 13,10,'Enter Name: $'
enterSem    db 13,10,'Enter Semester (1-8): $'
enterCgpa   db 13,10,'Enter CGPA (0-4): $'

savedMsg    db 13,10,'Saved to student.txt$'
allMsg      db 13,10,'--- All Students ---',13,10,'$'
labelRoll   db 'Roll: $'
labelName   db 'Name: $'
labelSem    db 'Semester: $'
labelCgpa   db 'CGPA: $'
divider     db '--------------------',13,10,'$'
newline     db 13,10,'$'

maxStudents equ 10

; DATA ARRAYS 
; Both Roll and Name now use 20-byte string buffers
rollArray    db maxStudents*20 dup('$') 
nameArray    db maxStudents*20 dup('$')
semArray     db maxStudents dup(0)
cgpaArray    db maxStudents dup(0)
studentCount db 0

.code

; READ DIGIT (For Sem/CGPA) 
readDigit PROC
    mov ah,1
    int 21h
    sub al,'0'
    ret
readDigit ENDP

; READ STRING (For Roll/Name) 
readString PROC
    mov cx,19           ; Max characters
rs_loop:
    mov ah,1
    int 21h
    cmp al,13           ; Check for Enter key
    je rs_done
    mov [di],al
    inc di
    loop rs_loop
rs_done:
    mov byte ptr [di],'$'
    ret
readString ENDP

; WRITE STRING TO FILE
writeStringToFile PROC
    mov si,dx
    xor cx,cx
count_chars:
    cmp byte ptr [si],'$'
    je do_write
    inc cx
    inc si
    jmp count_chars
do_write:
    jcxz skip_write     ; If string is empty, don't crash
    mov ah,40h
    mov bx,fileHandle
    int 21h
skip_write:
    ret
writeStringToFile ENDP

; SAVE TO FILE
saveToFile PROC
    mov ah, 3Dh
    mov al, 2          
    lea dx, filename
    int 21h
    jnc opened
    mov ah, 3Ch
    xor cx, cx
    lea dx, filename
    int 21h
opened:
    mov fileHandle, ax

    mov ah, 42h
    mov al, 2          ; Seek to end (Append)
    mov bx, fileHandle
    xor cx, cx
    xor dx, dx
    int 21h

    ; Write Roll (String)
    lea dx, lblR
    call writeStringToFile
    mov al, studentCount
    mov dl, 20
    mul dl
    lea dx, rollArray
    add dx, ax
    call writeStringToFile

    ; Write Name (String) 
    lea dx, lblN
    call writeStringToFile
    mov al, studentCount
    mov dl, 20
    mul dl
    lea dx, nameArray
    add dx, ax
    call writeStringToFile

    ; Write Sem (Digit)
    lea dx, lblS
    call writeStringToFile
    xor bx, bx
    mov bl, studentCount
    mov al, [semArray + bx]
    add al, '0'
    mov tempChar, al
    mov ah, 40h
    mov bx, fileHandle
    mov cx, 1
    lea dx, tempChar
    int 21h

    ; Write CGPA (Digit)
    lea dx, lblC
    call writeStringToFile
    xor bx, bx
    mov bl, studentCount
    mov al, [cgpaArray + bx]
    add al, '0'
    mov tempChar, al
    mov ah, 40h
    mov bx, fileHandle
    mov cx, 1
    lea dx, tempChar
    int 21h

    ; Newline in file
    mov ah, 40h
    mov bx, fileHandle
    mov cx, 2
    lea dx, newlineFile
    int 21h

    mov ah, 3Eh
    mov bx, fileHandle
    int 21h
    ret
saveToFile ENDP

; ADD STUDENT
addStudent PROC
    ; Read Roll as String
    mov dx,OFFSET enterRoll
    mov ah,9
    int 21h
    mov al,studentCount
    mov bl,20
    mul bl
    lea di, rollArray
    add di, ax
    call readString

    ; Read Name as String
    mov dx,OFFSET enterName
    mov ah,9
    int 21h
    mov al,studentCount
    mov bl,20
    mul bl
    lea di, nameArray
    add di, ax
    call readString

    ; Read Sem
    mov dx,OFFSET enterSem
    mov ah,9
    int 21h
    call readDigit
    xor bx, bx
    mov bl,studentCount
    mov [semArray + bx],al

    ; Read CGPA
    mov dx,OFFSET enterCgpa
    mov ah,9
    int 21h
    call readDigit
    xor bx, bx
    mov bl,studentCount
    mov [cgpaArray + bx],al

    call saveToFile
    inc studentCount

    mov dx,OFFSET savedMsg
    mov ah,9
    int 21h
    ret
addStudent ENDP

; DISPLAY ALL
displayAll PROC
    mov dx,OFFSET allMsg
    mov ah,9
    int 21h
    xor si,si
    mov cl,studentCount
    cmp cl, 0
    je done_disp
loop_disp:
    push cx
    mov dx,OFFSET divider
    mov ah,9
    int 21h

    ; Display Roll
    mov dx,OFFSET labelRoll
    mov ah,9
    int 21h
    mov ax,si
    mov bx,20
    mul bx
    lea dx,rollArray
    add dx,ax
    mov ah,9
    int 21h
    mov dx,OFFSET newline
    int 21h

    ; Display Name
    mov dx,OFFSET labelName
    mov ah,9
    int 21h
    mov ax,si
    mov bx,20
    mul bx
    lea dx,nameArray
    add dx,ax
    mov ah,9
    int 21h
    mov dx,OFFSET newline
    int 21h

    ; Display Sem
    mov dx,OFFSET labelSem
    mov ah,9
    int 21h
    mov al,[semArray + si]
    add al,'0'
    mov dl,al
    mov ah,2
    int 21h
    mov dx,OFFSET newline
    mov ah,9
    int 21h

    ; Display CGPA
    mov dx,OFFSET labelCgpa
    mov ah,9
    int 21h
    mov al,[cgpaArray + si]
    add al,'0'
    mov dl,al
    mov ah,2
    int 21h
    mov dx,OFFSET newline
    mov ah,9
    int 21h

    inc si
    pop cx
    loop loop_disp
done_disp:
    ret
displayAll ENDP

;  MAIN
main PROC
    mov ax,@data
    mov ds,ax
menu:
    mov dx,OFFSET menuMsg
    mov ah,9
    int 21h
    mov ah,1
    int 21h
    cmp al,'1'
    je A
    cmp al,'2'
    je D
    cmp al,'3'
    je EXIT_P
    jmp menu
A:  call addStudent
    jmp menu
D:  call displayAll
    jmp menu
EXIT_P:
    mov ah,4Ch
    int 21h
main ENDP
end main