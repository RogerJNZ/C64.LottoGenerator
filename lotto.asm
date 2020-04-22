*=$0801
        BYTE $0E, $08, $0A, $00, $9E, $20, $28, $32, $30, $38, $34, $29, $00, $00, $00
*=$0824
; Parameters (decimal numbers)
max_number   = #40
num_lines    = #50
num_columns  = #07
num_delay    = #40 
page_size    = #16

; C64 Subroutines
CHROUT       =  $FFD2
KEYBUF       =  $DC01
SCRCLR       =  $E544
SCRUP        =  $E8EA

; Constants
key_space    = #$EF
ptrline      = #$28

; Variables
msg_ptr      = $14  ;,$15 BASIC temp: Integer value
ptr          = $D1  ; LOW, ptr+1 HIGH han ge ptr to JSR $ffd2 pointer location
scr_ptr      = $FB  ; $FC High byte
delay        = $FD
rnd_range    = $97
page_end     = $FE  
temp         = $FF


TODO Add smooth scrolling


; To Do
; DONE 13 Apr 2020 num_lines and num_cols are 1 more than they should be
; DONE 13 Apr 2020 Combine print title and continue and allow print title to be on 2nd line
; Done 13 Apr 2020 Add Press Space to cont. at end and every page
; NOPE make the bottom line 3 lines down
; print ready in bottom 3 lines
; Add parameters in basic to set line number, columns and max num


        jsr  init_random
        jsr  SCRCLR     ; clear screen
        lda  page_size  ; set first page break
        sta  page_end
        LDA  #$16       ;Flip case to charset
        STA  $D018  
        lda  #$00       ; Print on first line
        sta  ptr
       
        jsr  print_title
        jsr  print_rows 
        jsr  print_end
        jsr  SCRCLR     ; clear screen
        
        
        rts



init_random
        lda  CHROUT     
        sta  $d40e     
        sta  $d40f     
        lda  #$80      
        sta  $d412     
        rts


; Input: ptr
print_title
        lda  #<message_title
        sta  rnd_range
        lda  #>message_title
        sta  rnd_range+1
        lda  #$04
        sta  ptr+1
        jsr  print_message
        rts

; Input: ptr, ptr+1
print_continue
        lda  #<message_continue
        sta  rnd_range
        lda  #>message_continue
        sta  rnd_range+1
        jsr  print_message
wait_spacekey
        lda  KEYBUF ;WAIT FOR SPACEBAR
        cmp  key_space
        bne  wait_spacekey
        rts
 
print_clear
        lda  #<message_clear
        sta  rnd_range
        lda  #>message_clear
        sta  rnd_range+1
        jsr  print_message       
        rts

print_end
        lda  #<message_end
        sta  rnd_range
        lda  #>message_end
        sta  rnd_range+1
        jsr  print_message 
wait_spacekeyend
        lda  KEYBUF ;WAIT FOR SPACEBAR
        cmp  key_space
        bne  wait_spacekeyend      
        rts

; Input 
; ptr - screen postion to print
; rng_range - message location
print_message
        ldy  #$00  
message_loop
        lda  (rnd_range),y 
        beq  end_message 
        cmp  #$C0
        bcc  message_lowercase
        sbc  #$80 
        bne  message_print  ; Used bne instead of jmp to save one byte
message_lowercase
        and  #$3f      ; Convert Petscii to screen code https://sta.c64.org/cbm64pettoscr.html
message_print
        sta  (ptr),y   
        iny
        bne  message_loop 
end_message
        rts





 
print_rows
        lda  num_delay     ; Initialise delay
        sta  delay
        
        ldx  #$00          ; Lotto Line Number
        lda  #$28
        sta  ptr           ; Current location on screen
        lda  #$04
        sta  ptr+1
print_loop
        lda  ptr          
        sta  scr_ptr       ; Record begining of line address so we can move to the next line 
        lda  ptr+1        
        sta  scr_ptr+1     ; Need to store high byte as ptr can move to the next block when printing columns

        ; Print line header
        PHA
        TXA                ; line number
        PHA
        adc  #$01          ; Convert line number to "1" indexed
        jsr  print_decimal ; print line number
        inc  ptr
        inc  ptr    
        
        ldy  #$00      
        lda  #$3A     
        sta  (ptr),y   
        inc  ptr  
        inc  ptr           ; print space
        ; Print a line of random numbers
        jsr  pick_random        
        jsr  print_columns   
        PLA
        TAX
        PLA
        
        ; Move to next line
        clc
        lda  scr_ptr       ; Block x position
        adc  ptrline       ; Move to the next line
        sta  ptr 
        lda  scr_ptr+1
        adc  #$00          ; if cross block then add one to ptr+1
        sta  ptr+1         ; Move to next block if x > block
        cmp  #$07          ; Don't go past the end of the screen
        bcc  row_nextline
        ; Print title message
        TXA
        PHA
        ldx ptr            ; store current print location
        ldy ptr+1
        lda #$28           ; print title on 2nd line down before screen is moved up one line
        sta ptr
        jsr print_title
        stx ptr            ; restore current print location
        sty ptr+1
        ; Move screen
        jsr  SCRUP         ; move screen up one line 
        PLA
        TAX
        ; Move cursor
        lda  scr_ptr
        sta  ptr           ; if last line then set screen postion back to prev line
        dec  ptr+1
row_nextline
        inx                ; next row
        cpx  page_end
        bne  row_continue
        TXA
        PHA
        jsr  print_continue               
        jsr  print_clear
        lda  page_end
        adc  page_size
        sta  page_end
    
        PLA
        TAX
row_continue
        cpx  num_lines
        bcc  print_loop
        rts





; Inputs None
pick_random
        lda  max_number   ; Random number range
        adc  #$01 
        sta  rnd_range
        ldx  #$00         ; Column Number
pick_loop
        inx
        dec rnd_range
random_number
        lda  $D41B     
        cmp  rnd_range    ; Range = Max Number - current column + 1
        bcs  random_number 
        stx  temp         ; Add current column    
        adc  temp            
        
        ; Swap the current pox in the array with the random number position
        ; By swapping array positions instead of the actual random number
        ; we never have to worry about duplicate random numbers
        ; Note: We also never have to re-initialise the array, since, as long
        ; as every array value is unique we can just continue to sawp their position
        tay
        lda  NumberArray,y     ; Swap random position with X
        sta  NumberArray       ; temporary swap space    
        lda  NumberArray,x   
        sta  NumberArray,y   
        lda  NumberArray     
        sta  NumberArray,x   
        tya
        sbc #$01               ; 0 array is the swap space so array is 1 indexed however comparison is 0 indexed
        cpx  num_columns     
        bcc  pick_loop  
        rts





print_columns
        ldx  #$01    
column_loop
        TXA
        PHA
        lda  NumberArray,x
        PHA
        jsr  print_cycle
        PLA
        jsr  print_decimal
        PLA
        TAX
       
        lda  KEYBUF        ; Remove delay when space pressed
        cmp  key_space
        bne  column_next
        lda  #$01          ; Fast Mode!   
        sta  delay
column_next
        clc
        lda  ptr          ; move 2 characters to the left. Use adc so we can check if we have crossed a black of memory   
        adc  #$03   
        sta  ptr  
        
        bcc  column_sameblock
        inc  ptr+1       
column_sameblock
        inx
        cpx  num_columns    
        bcc  column_loop
        rts


        
; Print a loop of numbers
; Rewrite this function
print_cycle
        ldx delay 
        txa
        PHA
cycleloop
        ldy max_number
cyclenumber
        TYA
        PHA     
        jsr print_decimal
        PLA
        TAY
        dey
        bne cyclenumber
        PLA
        TAX
        dex
        txa
        PHA
        bne cycleloop
        PLA
        TAX
        rts
        


; Displays numbers up to 99 at screen location ptr
; Input: A - Number to print
print_decimal
        ldx  #$00      
decimal_loop
        cmp  #$0a
        bcc  decimal   
        inx
        sbc  #$0a      
        jmp  decimal_loop
decimal
        ldy  #$01      
        adc  #$30      
        sta  (ptr),y   
        dey
        txa
        adc  #$30      
        sta  (ptr),y   
        rts



message_title
        TEXT "Lotto Number Generator (RJ 2020)", $00
message_continue
        TEXT "--Press space to continue--", $00
message_end
        TEXT "--End of list. Press space--", $00
message_clear
        TEXT "                            ", $00
NumberArray
        BYTE $00,$01,$02,$03,$04,$05,$06,$07,$08,$09
        BYTE $0a,$0b,$0c,$0d,$0e,$0f,$10,$11,$12,$13
        BYTE $14,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d
        BYTE $1e,$1f,$20,$21,$22,$23,$24,$25,$26,$27
        BYTE $28

