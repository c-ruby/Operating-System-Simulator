; OS Simulator
; Program 3
; (CMSC-3100-001)
; Allan Cunningham, Evan Thompson, Caleb Ruby
; cun82935@pennwest.edu, tho86271@pennwest.edu, rub4133@pennwest.edu

INCLUDE Irvine32.inc

.data

    buffersize equ 41
    buffer byte buffersize dup(0) ; for the input string
    wordbuffer byte buffersize dup(0) ; New string to store word from skipped whitespace
    bytecount DWORD ?
    currentindex DWORD ? ; index for saving where we are in the input string

    system_Time byte 0 ; variable for system time

    jobPointer dword ?
    
    ; constants for field offsets within a record
    jobName equ 0
    jobPriority equ 8
    jobStatus equ 9
    jobRunTime equ 10
    jobLoadTime equ 12

    ; constants for the status variables
    jobAvailable equ 0
    jobRun equ 1
    jobHold equ 2

    ; constant for the lowest priority
    lowestPriority equ 7

    ; constant for size of a record
    jobSize equ 14

    ; constant for number of jobs
    numberOfJobs equ 10

    value byte 0

    jobs byte numberOfJobs*jobSize dup (jobAvailable)

    ; Strings we compare the wordbuffer with to check for a valid command
    isQUIT BYTE "QUIT", 0
    isHELP BYTE "HELP", 0
    isLOAD BYTE "LOAD", 0
    isRUN BYTE "RUN", 0
    isHOLD BYTE "HOLD", 0
    isKILL BYTE "KILL", 0
    isSHOW BYTE "SHOW", 0
    isSTEP BYTE "STEP", 0
    isCHANGE BYTE "CHANGE", 0

    ; input prompt
    prompt BYTE "Enter command (QUIT, HELP, LOAD, RUN, HOLD, KILL, SHOW, STEP, CHANGE): ", 0
    
    ; These are just messages to print when a command is called since they don't actually do anything yet
    msgQUIT BYTE "You called Process_QUIT", 0
    msgHELP BYTE "Commands:", 0AH, \
        "- QUIT: Terminate the program.", 0AH, \
        "- HELP: Get assistance.", 0AH, \ 
        "- SHOW: Display the job queue.", 0AH, \
        "- LOAD job priority runtime: Add a job", 0AH, \
        "- RUN job: Start a job.", 0AH, \
        "- HOLD job: Pause a job.", 0AH, \
        "- KILL job: Remove a job.", 0AH, \
        "- STEP n: Process n cycles.", 0AH, \
        "- CHANGE job new_priority: Modify job priority.", 0
    msgLOAD BYTE "You called Process_LOAD", 0
    msgRUN BYTE "You called Process_RUN", 0
    msgHOLD BYTE "You called Process_HOLD", 0
    msgKILL BYTE "You called Process_KILL", 0
    msgSHOW BYTE "You called Process_SHOW", 0
    msgSTEP BYTE "You called Process_STEP", 0
    msgCHANGE BYTE "You called Process_CHANGE", 0

    MSGinvalidPriority BYTE "Please enter a priority within the range of 0 - 7", 0
    msgEnterJobName BYTE "Please enter a valid job name: ", 0
    msgEnterPriority BYTE "Please enter a valid priority (0-7): ", 0
    msgEnterJobRunTime BYTE "Please enter a valid run time: ", 0
    msgEnterSteps BYTE "Enter the number of steps: ", 0

    invalidEntry BYTE "Please enter a valid job with status 'RUN'", 0

    msgJobStatus BYTE "Status: ", 0
    msgJobRunTime BYTE "Run Time: ", 0
    msgJobLoadTime BYTE "Load Time: ", 0
    msgJobName BYTE "Job Name: ", 0
    msgJobPriority BYTE "Priority: ", 0

    msgIsHold BYTE "HOLD", 0
    msgIsRun BYTE "RUN", 0
    msgIsAvailable BYTE "AVAILABLE", 0

.code
toUpper PROC
    push esi
    convert_loop:
        mov al, [esi]               ; Load the byte at the current position into al
        cmp al, 0                   ; Check for null terminator (end of string)
        je end_convert_loop         ; If end of string, exit loop

        cmp al, 'a'                 ; Compare with 'a'
        jb skip_convert             ; If less than 'a', skip conversion

        cmp al, 'z'                 ; Compare with 'z'
        ja check_next_character     ; If greater than 'z', check next character

        sub al, 32                  ; Convert lowercase letter to uppercase
        mov [esi], al               ; Store the uppercase letter back

    check_next_character:
        inc esi                     ; Move to the next character
        jmp convert_loop            ; Repeat the loop

    skip_convert:
        inc esi                     ; Move to the next character
        jmp convert_loop            ; Repeat the loop

    end_convert_loop:
    
    pop esi
    ret
toUpper ENDP
WriteSpace PROC
    mov al, ' ' ; ASCII code for space
    call WriteChar
    ret
WriteSpace ENDP

skip_whitespace PROC
    mov currentindex, 0
    push edi   ; Save the value of EDI register
    push esi   ; Save the value of ESI register
    push ebx   ; Save the value of EBX register
    mov esi, 0         ; initialize index for wordbuffer string
    mov edi, currentindex         ; initialize index for input buffer
skip_whitespace_loop:   
    cmp edi, bytecount  ; Check if we've reached the end of the input
    jge end_skip_whitespace ; If so, end skipping whitespace
    mov al, buffer[edi] ; Load the current character
    cmp al, 32 ; Check if it's a space (ascii space is 32)
    je skip_whitespace_increment ; If so, skip it
    cmp al, 9 ; Check if it's a tab (ascii tab is 9)
    je skip_whitespace_increment ; If so, skip it
    mov wordbuffer[esi], al ; Otherwise, store it in the wordbuffer
    inc esi ; Increment index for wordbuffer
    
copy_until_whitespace:
    inc edi ; Move to the next character in the input buffer
    cmp edi, bytecount ; Check if we've reached the end of the input
    jge end_skip_whitespace ; If so, end copying
    mov al, buffer[edi] ; Load the next character
    cmp al, 32 ; Check if it's a space
    je end_skip_whitespace ; If so, end copying
    cmp al, 9 ; Check if it's a tab
    je end_skip_whitespace ; If so, end copying
    mov wordbuffer[esi], al ; Otherwise, store it in the wordbuffer
    inc esi ; Increment index for wordbuffer
    jmp copy_until_whitespace ; Repeat until whitespace is encountered
skip_whitespace_increment:
    inc edi ; Increment index for input buffer
    jmp skip_whitespace_loop ; Repeat until a non-whitespace character is found

end_skip_whitespace:
    mov byte ptr [wordbuffer + esi], 0 ; Null-terminate the wordbuffer
    mov currentindex, edi
    pop ebx
    pop esi
    pop edi
    ret
skip_whitespace ENDP

getNumber PROC
    ; Save registers
    push eax
    push ecx
    push edx
    push ebx

    ; Initialize variables
    mov value, 0
    call skip_whitespace
    mov al, value       ; Initialize value to 0
    mov ecx, 0       ; Initialize index to 0
    mov edx, 10      ; We will multiply by 10
    
convert_loop:
    movzx ebx, byte ptr [wordbuffer + ecx] ; Load character from wordbuffer into BL
    cmp ebx, 0       ; Check for end of string
    je convert_done  ; If end of string, exit loop
    cmp ebx, '0'
    jl convert_done ; make sure the character is a digit between 0 - 9
    cmp ebx, '9'
    jg convert_done
    
    ; Convert ASCII character to integer
    sub ebx, '0'     ; Convert ASCII character to digit
    imul eax, edx ; Multiply value by 10
    add eax, ebx     ; Add digit to value
    
    inc ecx          ; Move to next character
    jmp convert_loop ; Repeat until end of string
    
convert_done:
    mov value, al

    ; Restore registers
    pop ebx
    pop edx
    pop ecx
    pop eax

    ret
getNumber ENDP

findNextAvailable PROC
    push edi
    push eax
    mov edi, offset jobs
checknext:
    mov eax, jobStatus[edi]
    cmp eax, 0
    je jobfound
    add edi, jobSize
    jmp checknext
jobfound:
    mov jobPointer, edi
    pop eax
    pop edi
    ret
findNextAvailable ENDP

ProcessCommand PROC
    push ebx  ; Save the value of EBX register
    push esi  ; Save the value of ESI register
    push edi  ; Save the value of EDI register

    call clearBuffer

    inputloop:
        mov edi, OFFSET buffer ; Point to the beginning of the buffer
        mov ecx, SIZEOF buffer ; Specify the size of the buffer
        mov eax, 0
        mov currentindex, 0

    read_input:
        mov edx, OFFSET prompt
        call WriteString ; print the prompt

        mov edx, OFFSET buffer ; point to the buffer
        mov ecx, SIZEOF buffer ; specify max characters
        call ReadString ; read the input

        mov bytecount, eax ; number of characters
        mov ecx, eax       ; counter for loop

        mov ebx, SIZEOF buffer

        mov esi, 0 ; Reset the index for the wordbuffer string
        call skip_whitespace ; Skip whitespace in the input

    caseCommands:     ;test for quit
    	cld                  ;compare forward
    	mov esi, offset wordbuffer ;the command from the commandline
        call toUpper
    	mov ecx, sizeof isQUIT  ;size of quit
        mov edi, offset isQUIT   ;the quit string
    	repe cmpsb  ;compare the strings
    	jne case1      ;not quit, try next
    	call Process_QUIT
    	jmp foundcmd     ;jump to found command
    case1:     ;test for help
        cld
        mov esi, offset wordbuffer ;the command from the commandline
        mov ecx, sizeof isHELP
        mov edi, offset isHELP
        repe cmpsb
        jne case2
        call Process_HELP
        jmp foundcmd
    case2: ;test for load
        cld
        mov esi, offset wordbuffer ;the command from the commandline
        mov ecx, sizeof isLOAD
        mov edi, offset isLOAD
        repe cmpsb
        jne case3
        call Process_LOAD
        jmp foundcmd
    case3: ;test for run
        cld
        mov esi, offset wordbuffer ;the command from the commandline
        mov ecx, sizeof isRUN
        mov edi, offset isRUN
        repe cmpsb
        jne case4
        call Process_RUN
        jmp foundcmd
    case4: ;test for hold
        cld
        mov esi, offset wordbuffer ;the command from the commandline
        mov ecx, sizeof isHOLD
        mov edi, offset isHOLD
        repe cmpsb
        jne case5
        call Process_HOLD
        jmp foundcmd
    case5: ;test for kill
        cld
        mov esi, offset wordbuffer ;the command from the commandline
        mov ecx, sizeof isKILL
        mov edi, offset isKILL
        repe cmpsb
        jne case6
        call Process_KILL
        jmp foundcmd
    case6: ;test for show
        cld
        mov esi, offset wordbuffer ;the command from the commandline
        mov ecx, sizeof isSHOW
        mov edi, offset isSHOW
        repe cmpsb
        jne case7
        call Process_SHOW
        jmp foundcmd
    case7: ;test for step
        cld
        mov esi, offset wordbuffer ;the command from the commandline
        mov ecx, sizeof isSTEP
        mov edi, offset isSTEP
        repe cmpsb
        jne case8
        call Process_STEP
        jmp foundcmd
    case8: ;test for change
        cld
        mov esi, offset wordbuffer ;the command from the commandline
        mov ecx, sizeof isCHANGE
        mov edi, offset isCHANGE
        repe cmpsb
        jne endcmd
        call Process_CHANGE
        jmp foundcmd
    foundcmd:
    
    endcmd:
    
    call clearBuffer

    next:
        ; Update the currentindex for next input processing
        mov eax, currentindex
        cmp eax, bytecount
        jmp inputloop ; once there are no more words we move to the input loop
    ret
        pop edi   ; Restore the value of EDI register
        pop esi   ; Restore the value of ESI register
        pop ebx   ; Restore the value of EBX register

ProcessCommand ENDP

clearBuffer PROC
        mov edi, OFFSET buffer ; Point to the beginning of the buffer
        mov ecx, SIZEOF buffer ; Specify the size of the buffer
        mov eax, 0
    clear_buffer_loop:
        cmp ecx, 0            ; Check if we've cleared the entire buffer
        je endclear
        mov [edi], al         ; Fill the current byte with null
        inc edi               ; Move to the next byte
        dec ecx               ; Decrement the loop counter
        jmp clear_buffer_loop ; Repeat until the entire buffer is cleared
    endclear:
    ret
clearBuffer ENDP

main PROC
    mov system_Time, 0
    mov jobPointer, offset jobs
while1:
    call ProcessCommand
    jmp while1
main ENDP

PrintJobs PROC
    push edi
    push ecx
    push ebx
    push edx

    mov edi, jobPointer    ; the beginning of the job to be printed

    ; print job name
    mov ebx, 0
    mov edx, OFFSET msgJobName
    call WriteString
    printchar:
    cmp ebx, 8
    je doneprintchar
    mov eax, jobName[edi + ebx]
    call WriteChar
    inc ebx
    jmp printchar
    doneprintchar:
    call WriteSpace

    ; print job priority
    mov edx, OFFSET msgJobPriority
    call WriteString
    movzx eax, byte ptr jobPriority[edi]
    call WriteInt
    call WriteSpace

    ; print job status
    mov edx, OFFSET msgJobStatus
    call WriteString
    movzx eax, byte ptr jobStatus[edi]
    cmp eax, jobAvailable
    je printavailable
    cmp eax, jobRun
    je printrun
    cmp eax, jobHold
    je printhold
    
    printavailable:
    mov edx, OFFSET msgIsAvailable
    call WriteString
    jmp endprint
    printrun:
    mov edx, OFFSET msgIsRun
    call WriteString
    jmp endprint
    printhold:
    mov edx, OFFSET isHOLD
    call WriteString
    jmp endprint
    endprint:

    call WriteSpace

    ; print job run time
    mov edx, OFFSET msgJobRunTime
    call WriteString
    movzx eax, word ptr jobRunTime[edi]
    call WriteInt
    call WriteSpace

    ; print job load time
    mov edx, OFFSET msgJobLoadTime
    call WriteString
    movzx eax, word ptr jobLoadTime[edi]
    call WriteInt
    call Crlf

end_PrintJobs:
    pop edx
    pop ebx
    pop ecx
    pop edi
ret
PrintJobs ENDP

Process_QUIT PROC
    mov edx, OFFSET msgQUIT
    call WriteString
    call crlf
    exit
Process_QUIT ENDP

Process_HELP PROC
    mov edx, OFFSET msgHELP
    call WriteString
    call crlf
    ret
Process_HELP ENDP

Process_LOAD PROC
  mov edx, OFFSET msgLOAD
  call WriteString
  call Crlf

  ; Prompt for job name
  mov edx, OFFSET msgEnterJobName
  call WriteString

  read_input:
  mov edx, OFFSET buffer ; point to the buffer
  mov ecx, SIZEOF buffer ; specify max characters
  call ReadString ; read the input

  ; Get job name from wordbuffer
  call skip_whitespace
  call findNextAvailable
  mov edi, jobPointer
  
  ; Loop through wordbuffer and copy characters to job name field
  mov ecx, 0                   ; Initialize loop counter
  copy_name_loop:
    mov al, byte ptr [wordbuffer + ecx] ; Get character from wordbuffer
    cmp al, 0                   ; Check for end of string
    je read_priority
    add edi, ecx
    mov byte ptr jobName[edi], al ; Copy character to job name field
    inc ecx                       ; Increment loop counter
    jmp copy_name_loop            ; Repeat loop until null terminator is found

    read_priority:
    mov edx, offset msgEnterPriority
    call WriteString
    call clearBuffer
    mov edx, OFFSET buffer
    mov ecx, SIZEOF buffer
    call ReadString
    call getNumber
    mov edi, jobPointer
    mov al, value
    mov jobPriority[edi], eax

    read_jobRunTime:
    mov edx, offset msgEnterJobRunTime
    call WriteString
    call clearBuffer
    mov edx, OFFSET buffer
    mov ecx, SIZEOF buffer
    call ReadString
    call getNumber
    mov edi, jobPointer
    mov al, value
    mov jobRunTime[edi], eax

    mov byte ptr jobStatus[edi], jobHold

    movzx eax, system_Time 
    mov jobLoadTime[edi], eax

  ret
Process_LOAD ENDP

Process_RUN PROC
    call findJob
    cmp jobPointer, 0
    je error
    mov edi, jobPointer
    mov byte ptr jobStatus[edi], jobRun
    jmp endhold
    error:
    endhold:
    ret
Process_RUN ENDP

Process_HOLD PROC
    call findJob
    cmp jobPointer, 0
    je error
    mov edi, jobPointer
    mov byte ptr jobStatus[edi], jobHold
    jmp endhold
    error:
    endhold:
    ret
Process_HOLD ENDP

Process_KILL PROC
    push edi
    
    call findJob
    cmp jobPointer, 0
    je notfound
    mov edi, jobPointer
    cmp byte ptr jobStatus[edi], jobRun
    jne notfound

    mov byte ptr jobStatus[edi], jobAvailable
    jmp endhold
 
    notfound:
        mov edx, OFFSET invalidEntry
        call writestring
        call crlf
    endhold:

    pop edi
    ret
Process_KILL ENDP

Process_SHOW PROC
    mov ecx, numberOfJobs
    mov ebx, 0
    mov edx, OFFSET msgSHOW
    call WriteString
    call crlf
    mov edi, offset jobs
    
    check:
    cmp byte ptr jobStatus[edi], jobAvailable
    jne printit
    next:
    inc ebx
    add edi, jobSize
    cmp ebx, numberOfJobs
    jle check
    jmp endshow

    printit:
    mov jobPointer, edi
    call PrintJobs
    jmp next

    endshow:
    ret
Process_SHOW ENDP

Process_STEP PROC
    mov edx, OFFSET msgSTEP
    call WriteString
    call crlf

    ; Prompt for number of steps
    mov edx, OFFSET msgEnterSteps
    call WriteString

    ; Read number of steps
    mov edx, OFFSET buffer ; point to the buffer
    mov ecx, SIZEOF buffer ; specify max characters
    call ReadString ; read the input
    call getNumber ; get the number from the input
    mov bl, value ; store the number of steps in ebx

    ; Find the highest priority job
    call findHighestPriority
    mov edi, jobPointer ; get the pointer to the highest priority job
    mov edx, 0

    printnext:
    ; Decrement the runTime of the job
    dec byte ptr jobRunTime[edi]
    mov jobPointer, edi
    call printJobs
    inc edx
    inc system_Time

    cmp byte ptr jobRunTime[edi], 0
    jne continue
    jmp setstatus

    continue:
    cmp edx, ebx
    jle printnext
    jmp endstep

    setstatus:
    mov byte ptr jobStatus[edi], jobAvailable

    endstep:

    ret
Process_STEP ENDP

Process_CHANGE PROC
    call findJob
    cmp jobPointer, 0
    je error
    mov edi, jobPointer
    mov edx, offset msgEnterPriority
    call WriteString
    mov edx, offset buffer
    mov ecx, sizeof buffer
    call readstring
    call getNumber
    mov bl, value
    mov byte ptr jobPriority[edi], bl
    jmp endchange
    error:
    endchange:
    ret
Process_CHANGE ENDP

findHighestPriority PROC
    push edi
    push eax
    push ebx

    mov edi, offset jobs      ; Start at the beginning of the jobs array
    mov ecx, numberOfJobs     ; Set loop counter to the number of jobs
    mov eax, lowestPriority  ; Initialize highest priority to the lowest possible value
    mov ebx, 0                ; Initialize jobPointer to 0

findHighestPriority_loop:
    cmp ecx, 0               ; Check if we've checked all jobs
    je end_findHighestPriority  ; If so, end the procedure

    movzx edx, byte ptr jobStatus[edi] ; get the status
    cmp edx, jobRun
    jne nextJob ; if its not run, jump to next job

    movzx edx, byte ptr jobPriority[edi] ; Get the priority of the current job
    cmp edx, eax              ; Compare it with the highest priority found so far
    jge nextJob              ; If it's not higher, move to the next job

    ; If it's higher, update the highest priority and the jobPointer
    mov eax, edx
    mov ebx, edi

nextJob:
    add edi, jobSize         ; Move to the next job
    dec ecx                   ; Decrement the loop counter
    jmp findHighestPriority_loop  ; Repeat until all jobs have been checked

end_findHighestPriority:
    mov jobPointer, ebx      ; Store the jobPointer after the loop
    pop ebx
    pop eax
    pop edi
    ret
findHighestPriority ENDP


findJOB PROC
    mov edx, offset msgEnterJobName
    call WriteString
    
    call clearBuffer

    mov edx, OFFSET buffer ; point to the buffer
    mov ecx, SIZEOF buffer ; specify max characters
    call ReadString ; read the input

    call skip_whitespace

    mov ebx, offset jobs
    mov edx, numberOfJobs

    findLoop:
    cld
    mov esi, offset wordbuffer ;the command from the commandline
    mov edi, offset jobName
    add edi, ebx
    cmpsb
    je foundjob
    add ebx, jobSize
    dec edx
    cmp edx, 0
    jne findLoop
    cmp edx, 0
    je notfound

    foundjob:
    mov jobPointer, ebx
    jmp endfind

    notfound:
    mov jobPointer, 0

    endfind:

ret
findJOB ENDP


END main
