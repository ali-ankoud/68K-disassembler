*-----------------------------------------------------------
* Title      : Disassembler Snippet
* Written by : ARM Cortex Companions
* Date       : 5/15/2023
* Description: 
*-----------------------------------------------------------

STARTER
        ORG     $1000       *Start at $1000
        
*-------------------------------------------------------------------------------------------------- 
       
START                       *START: Start code
        MOVE.B  #0,D0
        MOVE.B  #0,D1
        MOVE.B  #0,D2
        MOVE.B  #0,D3
        MOVE.B  #0,D4
        MOVE.B  #0,D5
        MOVE.B  #0,D6
        MOVE.B  #0,D7
        
        MOVE.B  #11,D0
        MOVE.W  #$FF00,D1
        TRAP    #15
        
TEST    
        LEA     INTRO,A1    *Intro text
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     ASTART,A1   *Input prompt text #1
        TRAP    #15
        
        LEA     NOTH,A1     *Fix to pervent weird thing about printing input
        MOVE.B  #2,D0       *String prompt #1
        TRAP    #15
        
        CMP.W   #8,D1       *Throw error if length is greater than 8 (length stored in D1)
        BGT     VERR3
        
        JSR     PARSE       *Parse string #1
        

        MOVE.L  D1,A3
        
        LEA     AEND,A1     *Input prompt text #2
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     NOTH,A1     *Fix to pervent weird thing about printing input
        MOVE.B  #2,D0       *String prompt #2
        TRAP    #15
        
        CMP.W   #8,D1       *Throw error if length is greater than 8 (length stored in D1)
        BGT     VERR3
        
        JSR     PARSE       *Parse string #2
        
        MOVE.L  D1,A4
        
        BRA     VINPUT      *Verify inputs
        
*--------------------------------------------------------------------------------------------------

PARSE                       *PARSE: Initialize variables involved in parsing
        MOVE.B  #0,D1       * [D1] parse output
        MOVE.B  #8,D2       * [D2] max letter counter (size of longword)
        
PSTEP                       *PSTEP: Step in parsing for loop
        MOVE.B  (A1)+,D0    *Read next byte from A1
        CMP.B   #0,D0       *Check if reached end of string input
        BEQ     PDONE       *Break the for loop if reached end
        LSL.L   #4,D1       *Logical shift left by 4 bits to insert next hex character
        CMP.B   #58,D0      *Distinguish between letter and number
        BLT     PNUM        *Handle number

PHEX    SUBI.B   #55,D0     *ASCII value subtracted by 55 to match hex value
        CMPI.B   #15,D0     *Check if ASCII is high for lowercase values
        BGT     PCAPS       *Handle lowercase
        BRA     PSTEP2
     
PCAPS   SUBI.B   #32,D0     *32 is difference between uppercase and lowercase ASCII
        BRA     PSTEP2

PNUM    SUB.B   #48,D0      *ASCII value subtracted by 48 to match hex value
        
PSTEP2  CMPI.B   #15,D0     *If D0 is not in between 0 and 15 inclusively, throw an error
        BGT     VERR2
        CMPI.B   #0,D0
        BLT     VERR2
        ADD.L   D0,D1       *Append hex char to parse output
        SUBQ.B  #1,D2       *Decrement the counter
        CMPI.B   #0,D2      *Compare if we reached max count
        BEQ     PDONE       *Complete parsing
        BRA     PSTEP       *Or else continue loop

PDONE   RTS

*--------------------------------------------------------------------------------------------------

VINPUT  CMP.L   A3,A4       *Verify input from parsing
        BLT     VERR1
        BRA     READLN

VERR1   LEA     VERR1M,A1   *Throw parsing error
        MOVE.B  #14,D0
        TRAP    #15
        BRA     END

VERR2   LEA     VERR2M,A1   *Throw range error
        MOVE.B  #14,D0
        TRAP    #15
        BRA     END

VERR3   LEA     VERR3M,A1   *Throw length error
        MOVE.B  #14,D0
        TRAP    #15
        BRA     END
        
*--------------------------------------------------------------------------------------------------

READLN                              *READLN: Start READLN for loop
        MOVE.L  A3,A2               *Set current address to start address
        MOVE.B  #0,D5               * [D5] Initialize counter to 32 (# lines to pause the screen)

RSTEP                               *RSTEP: 
        MOVE.W  (A2)+,D4
        MOVE.W  A2,D2
        SUBQ.W  #2,D2
        
        MOVEM.L D5,-(SP)
        MOVE.B  #0,D5
        JSR     HEXOUT              *Run printing operation for HEX address
        MOVEM.L (SP)+,D5
        
        LEA     SM2,A1              *Horizontal tab indent after printing hex
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVEM.L A4-A7/D1-D7,-(SP)   *Store data to stack
        JSR     DISASM              *Run disassembly for current machine code
        MOVEM.L (SP)+,A4-A7/D1-D7   *Recall data from stack
        
        ADDQ.B  #1,D5       *Increment counter by 1
        CMP.B   #32,D5      *Check if we reached 32 lines
        BEQ     RPAUSE      *Branch to pausing code
        
        LEA     LB,A1       *Print line break
        MOVE.B  #14,D0      
        TRAP    #15
        
RCONT                       *RCONT: Used to continue off of the RPAUSE label after a pause in the printing
        CMP.L   A2,A4       *Check if we reached the end address
        BLT     DSEOF       *End loop if so
        BRA     RSTEP       *Or else continue the loop
        
RPAUSE                      *RPAUSE: Used to pause printing at the end of the screen and wait for ENTER to be pressed
        MOVE.B  #0,D5       * Reset D5 counter
        MOVE.B  #5,D0       * [D0] Trap task #5: Character prompt
        TRAP    #15         * Only used for waiting for user to hit ENTER
        BRA     RCONT       *Continue with READLN loop

*--------------------------------------------------------------------------------------------------

HEXOUT                      *HEXOUT: Prints a value in hexadecimal
        MOVE.B  #6,D0       * [D0] Trap task #6: Print character (will apply to all trap operations involved)
        MOVE.B  #8,D3       * [D3] Decrementing counter to keep track length of longword
        
HSTEP                       *HSTEP: An iteration in the HEXOUT for loop
        ROL.L   #4,D2       *Rotational shift left by 4 bits to bring the first hex character to the other side
        MOVE.L  D2,D1       * [D1] Used for the AND operation to filter to the right four bits
        ANDI.L  #$F,D1      * Filter to the right four bits
        CMP.B   #10,D1      *Distinguish between number and letter
        BLT     HNUM        *Branch to number handling, or continue to letter handling
        
HHEX                        *HHEX: Handle letters from HEXOUT for loop
        ADDI.B  #55,D1      *Increment decimal value by 55 to match corresponding ASCII
        BRA     HSTEP2      *Branch to step 2 of the iteration

HNUM                        *HNUM: Handle numbers from HEXOUT for loop
        ADDI.B  #48,D1      *Increment decimal value by 55 to match corresponding ASCII

HSTEP2                      *HSTEP2: 2nd part of an iteration from the HEXOUT for loop
        SUBQ.B  #1,D3       *Decrement counter for longword tracking
        
        CMP.B   D5,D1
        BEQ     HSKIP2
        
        TRAP #15            *Will print the ASCII value stored in D1
HSKIP2  CMPI.B  #0,D3       *Check if we reached 8 characters for a longword
        BEQ     HDONE       *End loop if done
        
        CMP.B   #48,D1
        BEQ     HSKIP3
        
        MOVE.B  #0,D5
        
HSKIP3  BRA     HSTEP       *Or else continue loop
        
HDONE   RTS


*--------------------------------------------------------------------------------------------------

SIZE    MOVE.B  #14,D0
        CMP.B   #%00,D5
        BEQ     SIZEB
        CMP.B   #%01,D5
        BEQ     SIZEW
        CMP.B   #%10,D5
        BEQ     SIZEL
        CMP.B   #%11,D5
        BEQ     SIZEW       *Assume WORD type on memory pointer things
        BRA     SRET
        
SIZEB   LEA     MODEB,A1
        BRA     SDONE

SIZEW   LEA     MODEW,A1
        BRA     SDONE

SIZEL   LEA     MODEL,A1
        BRA     SDONE

SDONE   TRAP    #15

SRET    RTS

*-----------------------------------------------------------------------------------
*using values in d3 (mode), d6 (register), and d5 (size) prints address mode
*uses d1, d0, and a1
*using values in d3 (mode), d6 (register), and d5 (size) prints address mode
*uses d1, d0, and a1
ADDRMODEALL
*comparisons
AM000   CMP     #%000,D3
        BNE     AM001
        LEA     VALD,A1
        TRAP    #15
        MOVE.B  D6,D1       *moving ea num to d1 to print
        MOVE.B  #3,D0       *moving 3 to d0 to print register number
        TRAP    #15         *printing register number
        MOVE.B  #14,D0      *replacing 14 in d0 to print strings
        BRA     AMEND

        
AM001   CMP     #%001,D3
        BNE     AM010
        CMP     #00,D5
        BEQ     DSERR
        LEA     VALA,A1
        TRAP    #15
        MOVE.B  D6,D1       *moving ea num to d1 to print
        MOVE.B  #3,D0       *moving 3 to d0 to print register number
        TRAP    #15         *printing register number
        MOVE.B  #14,D0      *replacing 14 in d0 to print strings
        BRA     AMEND

AM010   CMP     #%010,D3
        BNE     AM011
        LEA     OPENPTR,A1
        TRAP    #15
        LEA     VALA,A1
        TRAP    #15
        MOVE.B  D6,D1       *moving ea num to d1 to print
        MOVE.B  #3,D0       *moving 3 to d0 to print register number
        TRAP    #15         *printing register number
        MOVE.B  #14,D0      *replacing 14 in d0 to print strings
        LEA     CLOSEPTR,A1
        TRAP    #15
        BRA     AMEND

AM011   CMP     #%011,D3
        BNE     AM100
        LEA     OPENPTR,A1
        TRAP    #15
        LEA     VALA,A1
        TRAP    #15
        MOVE.B  D6,D1       *moving ea num to d1 to print
        MOVE.B  #3,D0       *moving 3 to d0 to print register number
        TRAP    #15         *printing register number
        MOVE.B  #14,D0      *replacing 14 in d0 to print strings
        LEA     CLOSEIPTR,A1
        TRAP    #15
        BRA     AMEND

AM100   CMP     #%100,D3
        BNE     AM111
        LEA     OPENDPTR,A1
        TRAP    #15
        LEA     VALA,A1
        TRAP    #15
        MOVE.B  D6,D1       *moving ea num to d1 to print
        MOVE.B  #3,D0       *moving 3 to d0 to print register number
        TRAP    #15         *printing register number
        MOVE.B  #14,D0      *replacing 14 in d0 to print strings
        LEA     CLOSEPTR,A1
        TRAP    #15
        BRA     AMEND

AM111   CMP     #%111,D3
        BNE     DSERR
        CMP     #%000,D6
        BNE     AM111001
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.W  (A2)+,D2
        MOVEM.L D5,-(SP)    
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        BRA     AMEND
        
AM111001
        CMP     #%001,D6
        BNE     AM111100
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.L  (A2)+,D2
        MOVEM.L D5,-(SP)
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        BRA     AMEND
        
AM111100
        CMP     #%100,D6
        BNE     DSERR
        LEA     VALN,A1
        TRAP    #15
        MOVE.W  (A2)+,D2
        MOVEM.L D5,-(SP)    
        MOVE.B  #3,D0
        MOVE.W  D2,D1
        TRAP    #15
        MOVE.B  #14,D0
        MOVEM.L (SP)+,D5
        MOVE.W  #0,D1
        BRA     AMEND
        
AMEND   MOVE.B  #14,D0
        RTS

*--------------------------------------------------------------------------------------------------
*Each machine code iterated through will be in D4. You can use all data registers as there will be a stack pointer involved
*You will kind of have to locate the label for the first 4 bits of the machine code. There is a special case where the prefix of 000 can be variable with the size parameter

*During the processing of each machine code, we skip the first four bits as they have been passed through during the searching system. The exception to this is two bits for machine codes that start with 00.

*CODING INSTRUCTIONS: You should not touch D0 as we want to keep it as the trap task. If for any reason you have to touch D0, make sure you set it back to #14 for printing the strings.
*Some codes take up an extra length, and while the iterator goes through each word by default, you can manually increment the pointer within the disassembly

DISASM                      *DISASM: Disassemble a machine code
        LSL.W   #1,D4       * Tier 0 binary search
        BCS     DS1
        BRA     DS0

*DS Tier 1 ----------------------------------------------------------------------------------------

DS0                         *DS0: Tier 1 binary search for 0 side
        LSL.W   #1,D4       
        BCS     DS01
        BRA     DS00

DS1                         *DS1: Tier 1 binary search for 1 side
        LSL.W   #1,D4       
        BCS     DS11
        BRA     DS10

DS00                        *DS00: Disassembly processing for 00 prefix
        ROL.W   #2,D4       
        MOVE.B  D4,D5
        ANDI.B  #%11,D5
        CMPI.B  #%00,D5
        BEQ     DAND
        BRA     DMOVE2

DAND    ROL.W   #4,D4
        MOVE.B  D4,D5
        ANDI.B  #%0010,D5
        CMPI.B  #%0010,D5
        BNE     DSERRINS
        
        ROL.W   #2,D4
        MOVE.B  D4,D5
        ANDI.B  #%111,D5
        
        ROL.W   #3,D4           ; Shift D4 left by 3 bits to get opmode
        MOVE.B  D4,D3           ; Move the byte in D4 to D5
        ANDI.B  #%111,D3        ; AND operation to isolate the last 3 bits
        
        ROL.W   #3,D4           ; Shift D4 left by 3 bits to get register number
        MOVE.B  D4,D6           ; Move the byte in D4 to D5
        ANDI.B  #%111,D6        ; AND operation to isolate the last 3 bits
        
        LEA     VALD,A1         ; Load effective address of Dn
        TRAP    #15             ; Print Dn
        MOVE.B  D5,D7           ; Store the register number for later use

        
        CMP.B   #%000,D5        ; Compare with byte size
        BEQ     DANDB
        CMP.B   #%001,D5        ; Compare with word size
        BEQ     DANDW
        CMP.B   #%010,D5        ; Compare with long size
        BEQ     DANDL
        
        BRA     DSEND           ; Branch to DSEND in case of invalid code

DANDB   LEA     ANDM,A1         ; Load effective address of ANDM string
        TRAP    #15             ; Print ANDM string
        LEA     MODEB,A1        ; Load effective address of MODEB string
        TRAP    #15             ; Print MODEB string
        BRA     DANDA           ; Branch to addressing mode parsing

DANDW   LEA     ANDM,A1         ; Load effective address of ANDM string
        TRAP    #15             ; Print ANDM string
        LEA     MODEW,A1        ; Load effective address of MODEW string
        TRAP    #15             ; Print MODEW string
        BRA     DANDA           ; Branch to addressing mode parsing

DANDL   LEA     ANDM,A1         ; Load effective address of ANDM string
        TRAP    #15             ; Print ANDM string
        LEA     MODEL,A1        ; Load effective address of MODEL string
        TRAP    #15             ; Print MODEL string
        BRA     DANDA           ; Branch to addressing mode parsing

DANDA   LEA     SM5,A1
        TRAP    #15

        ANDI.B  #%111,D4        ; AND operation to isolate the last 3 bits in D4
        MOVE.B  D4,D6           ; Store the register number in D6 for later use

        JSR     ADDRMODEALL     ; Call subroutine to parse and print effective address

        BRA     DSEND                 


        
*NEEDS INTEGRATION WITH AND OPCODE AND REST OF 00 PROCESSING
DMOVE2  NOP                 *DMOVE2: Disassembly function serving MOVE and MOVEA
        *size in d5 from above processing
        LEA     MOVEM,A1
        TRAP    #15
                
        *dest reg to d7
        ROL.W   #3,D4
        MOVE.B  D4,D7
        AND.B   #%111,D7
        
        *dest mode to d3: An means MOVEA
        ROL.W   #3,D4
        MOVE.B  D4,D3
        AND.B   #%111,D3
        MOVE.W  D3,A6
        
        CMP     #%001,D3
        BEQ     DMOVEA
MOVECONT
*printing size then first addressing moode, then comma
*size is different for move
MSIZE   MOVE.B  #14,D0
        CMP.B   #%01,D5
        BEQ     MSIZEB
        CMP.B   #%11,D5
        BEQ     MSIZEW
        CMP.B   #%10,D5
        BEQ     MSIZEL
        CMP.B   #%11,D5
        BEQ     MSIZEW       *Assume WORD type on memory pointer things
        BRA     DSERR
        
MSIZEB  LEA     MODEB,A1
        BRA     MSDONE

MSIZEW  LEA     MODEW,A1
        BRA     MSDONE

MSIZEL  LEA     MODEL,A1
        BRA     MSDONE

MSDONE  TRAP    #15

        LEA     SM7,A1
        TRAP    #15
        
        *source mode to d3
        ROL.W   #3,D4
        MOVE.B  D4,D3
        AND.B   #%111,D3
        
        *source reg to d6
        ROL.W   #3,D4
        MOVE.B  D4,D6
        AND.B   #%111,D6
        
        JSR     ADDRMODEALL
        CMP     #%001,D3
        BEQ     MOVEERRCHECK    *as size is diff, err check for byte op on addr reg direct
        LEA     COMMA,A1
        TRAP    #15
        MOVE.B  D7,D6
        MOVE.W  A6,D3
        JSR     ADDRMODEALL
        BRA     DSEND

DMOVEA  NOP
        CMP     #%01,D5     *if size is byte, err
        BEQ     DSERR
        LEA     VALA,A1        *else, print A and return
        TRAP    #15
        BRA     MOVECONT

MOVEERRCHECK
        CMP     #%01,D5
        BEQ     DSERR
        BRA     DSEND

        

*DS Tier 2 ----------------------------------------------------------------------------------------

DS01                        *DS01: Tier 2 binary search for 01 side
        LSL.W   #1,D4
        BCS     DS011
        BRA     DS010

DS10                        *DS10: Tier 2 binary search for 10 side
        LSL.W   #1,D4
        BCS     DS101
        BRA     DS100

DS11                        *DS11: Tier 2 binary search for 11 side
        LSL.W   #1,D4
        BCS     DS111
        BRA     DS110

*DS Tier 3 ----------------------------------------------------------------------------------------

DS010                       *DS010: Tier 3 binary search for 010 side
        LSL.W   #1,D4
        BCS     DS0101
        BRA     DS0100

DS011                       *DS011: Tier 3 binary search for 011 side
        LSL.W   #1,D4
        BCS     DS0111
        BRA     DS0110

DS100                       *DS100: Tier 3 binary search for 100 side
        LSL.W   #1,D4
        BCS     DS1001
        BRA     DS1000

DS101                       *DS101: Tier 3 binary search for 101 side
        LSL.W   #1,D4
        BCS     DS1011
        BRA     DS1010

DS110                       *DS110: Tier 3 binary search for 110 side
        LSL.W   #1,D4
        BCS     DS1101
        BRA     DS1100

DS111                       *DS111: Tier 3 binary search for 111 side
        LSL.W   #1,D4
        BCS     DS1111
        BRA     DS1110

*DS Tier 4 ----------------------------------------------------------------------------------------

DS0100                      *DS0100: Processing for 0100 prefix
        CMPI.W  #%1110011100010000,D4
        BEQ     DNOP
        CMPI.W  #%1110011101010000,D4
        BEQ     DRTS
        
        MOVE.W  D4,D2
        ANDI.W  #%0001110000000000,D2
        CMPI.W  #%0001110000000000,D2
        BEQ     DLEA
        
        ROL.W   #4,D4
        MOVE.B  D4,D2
        ANDI.B  #%1111,D2
        
        CMP.B   #%1110,D2
        BEQ     DJSR
        
        CMP.B   #%0110,D2
        BEQ     DNOT
        
        BRA     DSERRINS

DNOP    LEA     NOPM,A1
        TRAP    #15
        BRA     DSEND
        
DNOT    ROL.W   #2,D4           ; shift D4 left by 2 bits to get size
        MOVE.B  D4,D5           ; move the byte in D4 to D5
        ANDI.B  #%11,D5         ; AND operation to isolate the last 2 bits

        CMP.B   #%00,D5         ; compare with byte size
        BEQ     DNOTB
        CMP.B   #%01,D5         ; compare with word size
        BEQ     DNOTW
        CMP.B   #%10,D5         ; compare with long size
        BEQ     DNOTL
        
        BRA     DSEND           ; branch to DSEND in case of invalid code

DNOTB   LEA     NOTM,A1         ; load effective address of NOTM string
        TRAP    #15             ; print NOTM string
        LEA     MODEB,A1        ; load effective address of MODEB string
        TRAP    #15             ; print MODEB string
        BRA     DNOTA           ; branch to addressing mode parsing

DNOTW   LEA     NOTM,A1         ; load effective address of NOTM string
        TRAP    #15             ; print NOTM string
        LEA     MODEW,A1        ; load effective address of MODEW string
        TRAP    #15             ; print MODEW string
        BRA     DNOTA           ; branch to addressing mode parsing

DNOTL   LEA     NOTM,A1         ; load effective address of NOTM string
        TRAP    #15             ; print NOTM string
        LEA     MODEL,A1        ; load effective address of MODEL string
        TRAP    #15             ; print MODEL string
        BRA     DNOTA           ; branch to addressing mode parsing

DNOTA   ROL.W   #6,D4           ; shift D4 left by 6 bits to get addressing mode and register
        MOVE.B  D4,D1           ; move the byte in D4 to D1
        ANDI.B  #%111111,D1     ; AND operation to isolate the last 6 bits

        ; Now process addressing mode and register based on the value in D1

        MOVE.B  D1,D5           ; Move the byte in D1 to D5
        ANDI.B  #%111,D5        ; AND operation to isolate the last 3 bits
        BEQ     DREG            ; If it is direct register mode
        CMP.B   #%010,D5        ; Compare with An
        BEQ     ADREG
        CMP.B   #%011,D5        ; Compare with (An)+
        BEQ     ADREGP
        CMP.B   #%100,D5        ; Compare with -(An)
        BEQ     MADREG
        CMP.B   #%111,D5        ; Compare with (xxx).W or (xxx).L
        BEQ     EXT
            
        BRA     DSEND

DREG    MOVE.B  D1,D6           ; Move the byte in D1 to D6
        ANDI.B  #%111,D6        ; AND operation to isolate the last 3 bits for register number
        ADD.B   VALD,D6         ; Convert register number to ASCII
        LEA     VALD,A1         ; Load effective address of Dn
        TRAP    #15             ; Print Dn
        BRA     DSEND

ADREG   MOVE.B  D1,D6           ; Similar to DREG, but for An mode
        ANDI.B  #%111,D6
        ADD.B   VALA,D6
        LEA     VALA,A1
        TRAP    #15
        BRA     DSEND

ADREGP  MOVE.B  D1,D6           ; Similar to ADREG, but for (An)+ mode
        ANDI.B  #%111,D6
        ADD.B   VALA,D6
        LEA     VALA,A1
        TRAP    #15
        LEA     CLOSEIPTR,A1    ; Load effective address of )+
        TRAP    #15             ; Print )+
        BRA     DSEND

MADREG  MOVE.B  D1,D6           ; Similar to ADREG, but for -(An) mode
        ANDI.B  #%111,D6
        ADD.B   VALA,D6
        LEA     OPENDPTR,A1     ; Load effective address of -(
        TRAP    #15             ; Print -(
        LEA     VALA,A1
        TRAP    #15
        LEA     CLOSEPTR,A1     ; Load effective address of )
        TRAP    #15             ; Print )
        BRA     DSEND

EXT     MOVE.B  D1,D6           ; For (xxx).W and (xxx).L modes
        ANDI.B  #%1,D6
        BEQ     EXTW
        LEA     VALN,A1         ; Load effective address of #
        TRAP    #15             ; Print #
        BRA     DSEND

EXTW    LEA     VAL0,A1         ; Load effective address of 0
        TRAP    #15             ; Print 0
        BRA     DSEND

        
DJSR    ROL.W   #2,D4
        MOVE.B  D4,D2
        ANDI.B  #%111,D2
        CMPI.B  #%10,D2
        BNE     DSERR
        
        LEA     JSRM,A1
        TRAP    #15
        
        LEA     SM7,A1
        TRAP    #15

        ROL.W   #3,D4       * [D2] address mode
        MOVE.B  D4,D2
        ANDI.B  #%111,D2
        
        ROL.W   #3,D4       * [D1] address register
        MOVE.B  D4,D1
        ANDI.B  #%111,D1
        
        CMPI.B  #%010,D2
        BEQ     DJSR_REG
        
        CMPI.B  #%111,D2
        BNE     DSERR
        
        CMPI.B  #%000,D1
        BEQ     DJSR_CUSW
        
        CMPI.B  #%001,D1
        BEQ     DJSR_CUSL
        
        BRA     DSEND
        
        
        
DJSR_REG        
        LEA     OPENPTR,A1
        TRAP    #15
        
        LEA     VALA,A1
        TRAP    #15
        
        MOVE.B  #3,D0
        TRAP    #15
        MOVE.B  #14,D0
        
        LEA     CLOSEPTR,A1
        TRAP    #15
        
        BRA     DSEND

        
DJSR_CUSW
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.W  (A2)+,D2
        MOVEM.L D5,-(SP)
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        BRA     DSEND

DJSR_CUSL
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.L  (A2)+,D2
        MOVEM.L D5,-(SP)
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        BRA     DSEND
        
DRTS    LEA     RTSM,A1
        TRAP    #15
        BRA     DSEND
        
        
DLEA    *printing
        LEA     LEAM,A1
        TRAP    #15
        LEA     SM7,A1
        TRAP    #15
        
        *shifting out 111
        ROL.W   #3,D4
        
        *getting destination register
        ROL.W   #3,D4
        MOVE.B  D4,D2
        ANDI.B  #%111,D2
        
        *getting ea mode
        ROL.W   #3,D4
        MOVE.B  D4,D3
        ANDI.B  #%111,D3
        
        CMP.B   #%010,D3
        BEQ     DLEAP
        
        CMP.B   #%111,D3
        BEQ     DLEAP
        
        BRA     DSERREA
        
        *getting ea reg
DLEAP   ROL.W   #3,D4
        MOVE.B  D4,D6
        ANDI.B  #%111,D6
        
        *printing
        JSR     ADDRMODEALL
        
        LEA     COMMA,A1
        TRAP    #15
        LEA     VALA,A1
        TRAP    #15
        MOVE.B  #3,D0
        MOVE.B  D2,D1
        TRAP    #15
        MOVE.B  #14,D0
        
        BRA DSEND
        
JSR010
        CMP.B   #%010,D3
        BNE     JSR111
        LEA     OPENPTR,A1
        TRAP    #15
        LEA     VALA,A1
        TRAP    #15
        MOVE.B  #3,D0
        MOVE.B  D6,D1
        TRAP    #15
        MOVE.B  #14,D0
        LEA     CLOSEPTR,A1
        TRAP    #15
        BRA     JSRPRINT2
JSR111
        CMP.B   #%111,D3
        BNE     DSERR
        CMP.B   #%000,D6
        BNE     JSR111001
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.W  (A2)+,D2
        MOVEM.L D5,-(SP)    
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        MOVE.B  #14,D0
        BRA     JSRPRINT2
        
JSR111001
        CMP.B   #%001,D6
        BNE     DSERR
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.L  (A2)+,D2
        MOVEM.L D5,-(SP)
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        MOVE.B  #14,D0
        BRA     JSRPRINT2
        
JSRPRINT2
        LEA     COMMA,A1
        TRAP    #15
        LEA     VALA,A1
        TRAP    #15
        MOVE.B  #3,D0
        MOVE.W  D7,D1
        TRAP    #15
        MOVE.B  #14,D0
        
        BRA     DSEND
        

* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS0101  NOP
        
DADDQ   NOP
        LEA     ADDM,A1
        TRAP    #15
        LEA     VALQ,A1
        TRAP    #15
        
        *parsing data to d1
        ROL.W   #3,D4
        MOVE.B  D4,D1
        AND.B   #%111,D1
        
        *ensuring next bit is 0
        ROL.W   #1,D4
        MOVE.B  D4,D5
        AND.B   #%1,D5
        CMP     #0,D5
        BNE     DSERR
        
        *parsing and printing size
        ROL.W   #2,D4
        MOVE.B  D4,D5
        AND.B   #%11,D5
        JSR     SIZE
        LEA     SM7,A1
        TRAP    #15
        
        *parsing effective address information
        *mode:
        ROL.W   #3,D4
        MOVE.B  D4,D3
        AND.B   #%111,D3
        
        *register:
        ROL.B   #3,D4
        MOVE.B  D4,D6
        AND.B   #%111,D6
        
        *printing data
        LEA     VALN,A1
        TRAP    #15
        MOVE.B  #3,D0
        TRAP    #15
        MOVE.B  #14,D0
        LEA     COMMA,A1
        TRAP    #15
        
        CMP     #%100,D3
        BEQ     DSERR
        JSR     ADDRMODEALL
        
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS0110  
        ROL.W   #4,D4   *Get next 4 bits
        MOVE.B  D4,D2   *Copy to D2
        ANDI.B  #%1111,D2   *Set all bits to 0 except next 4
        
        CMP.B   #%0000,D2   *BRA
        BEQ     DBRA
        
        CMP.B   #%1110,D2   *BGT   
        BEQ     DBGT
        
        CMP.B   #%1111,D2   *BLE   
        BEQ     DBLE
        
        CMP.B   #%0111,D2   *BEQ   
        BEQ     DBEQ
        
        BRA     DSERRINS
        
DBRA    LEA     BRAM,A1
        TRAP    #15
        
        LEA     SM7,A1
        TRAP    #15

        ROL.W   #8,D4       * [D1] 8 bit Displacement 
        MOVE.B  D4,D1
        ANDI.L  #$1100,D1
        
        CMPI.B  #%00000000,D1
        BEQ     DBRA_16BIT      * Word
        
        CMPI.B  #%11111111,D1
        BEQ     DBRA_32BIT      * Long
        
        * 8 Bit Displacement
        LEA     DOLLAR,A1
        TRAP    #15
        
        MOVE.W  (A2)+,D2
        ADD.W   D1,D2
        ADD.W   #4,D2   *unsure   
        MOVE.B  #48,D5
        JSR     HEXOUT
        BRA     DSEND

        *Displacement is put in D1      
        
        
        BRA     DSEND
        
DBRA_16BIT
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.W  (A2)+,D2
        ADD.W   A2,D2
        SUB.W   #2,D2   *unsure
        MOVEM.L D5,-(SP)    
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        BRA     DSEND

DBRA_32BIT
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.L  (A2)+,D2
        ADD.L   A2,D2
        SUB.L   #2,D2   *unsure
        MOVEM.L D5,-(SP)
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        BRA     DSEND
        
        
        
DBGT    LEA     BGTM,A1
        TRAP    #15
        
        LEA     SM7,A1
        TRAP    #15
        
        ROL.W   #8,D4       * [D1] 8 bit Displacement 
        MOVE.B  D4,D1
        ANDI.W  #%0000000011111111,D1
        
        CMPI.B  #%00000000,D1
        BEQ     DBRA_16BIT      * Word
        
        CMPI.B  #%11111111,D1
        BEQ     DBRA_32BIT      * Long
        
        LEA     DOLLAR,A1
        TRAP    #15
    
        MOVE.W  A2,D2
        ADD.W   D1,D2
  
        MOVE.B  #48,D5
        JSR     HEXOUT
        BRA     DSEND

DBLE    LEA     BLEM,A1
        TRAP    #15
        
        LEA     SM7,A1
        TRAP    #15
        
        ROL.W   #8,D4       * [D1] 8 bit Displacement 
        MOVE.B  D4,D1
        ANDI.W  #%0000000011111111,D1
        
        CMPI.B  #%00000000,D1
        BEQ     DBRA_16BIT      * Word
        
        CMPI.B  #%11111111,D1
        BEQ     DBRA_32BIT      * Long
        
        LEA     DOLLAR,A1
        TRAP    #15
        
        MOVE.W  A2,D2
        ADD.W   D1,D2
 
        MOVE.B  #48,D5
        JSR     HEXOUT
        
        BRA     DSEND

DBEQ    LEA     BEQM,A1
        TRAP    #15
        
        LEA     SM7,A1
        TRAP    #15
        
        ROL.W   #8,D4       * [D1] 8 bit Displacement 
        MOVE.B  D4,D1
        ANDI.W  #%0000000011111111,D1
        
        CMPI.B  #%00000000,D1
        BEQ     DBRA_16BIT      * Word
        
        CMPI.B  #%11111111,D1
        BEQ     DBRA_32BIT      * Long
        
        LEA     DOLLAR,A1
        TRAP    #15

        MOVE.W  A2,D2
        ADD.W   D1,D2
 
        MOVE.B  #48,D5
        JSR     HEXOUT
        
        BRA     DSEND

* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS0111  NOP
        
DMOVEQ  NOP
        LEA     MOVEM,A1
        TRAP    #15
        LEA     VALQ,A1
        TRAP    #15
        LEA     SM7,A1
        TRAP    #15
        
        *getting register number
        ROL.W   #3,D4
        MOVE.B  D4,D5
        AND.B   #%111,D5
        
        *throwing error if next digit not 0
        ROL.W   #1,D4
        MOVE.B  D4,D6
        AND.B   #%1,D6
        CMP.B   #0,D6
        BNE     DSERR
        
        *getting data and printing information
        ROL.W   #8,D4
        MOVE.B  D4,D1
        AND.B   #%11111111,D1
        LEA     VALN,A1
        TRAP    #15
        MOVE.B  #3,D0
        TRAP    #15
        MOVE.B  #14,D0
        LEA     COMMA,A1
        TRAP    #15
        LEA     VALD,A1
        TRAP    #15
        MOVE.B  #3,D0
        MOVE.W  D5,D1
        TRAP    #15
        
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1000  NOP
        
DOR     ROL.W   #3,D4           ; Shift D4 left by 3 bits to get register number
        MOVE.B  D4,D5           ; Move the byte in D4 to D5
        ANDI.B  #%111,D5        ; AND operation to isolate the last 3 bits
        MOVE.B  D5,D6           ; Store the register number in D6 for later use

        ROL.W   #3,D4           ; Shift D4 left by 3 bits to get opmode
        MOVE.B  D4,D5           ; Move the byte in D4 to D5
        ANDI.B  #%111,D5        ; AND operation to isolate the last 3 bits
        CMP.B   #%000,D5        ; Compare with byte size
        BEQ     DORB
        CMP.B   #%001,D5        ; Compare with word size
        BEQ     DORW
        CMP.B   #%010,D5        ; Compare with long size
        BEQ     DORL
        
        BRA     DSEND           ; Branch to DSEND in case of invalid code

DORB    LEA     ORM,A1          ; Load effective address of ORM string
        TRAP    #15             ; Print ORM string
        LEA     MODEB,A1        ; Load effective address of MODEB string
        TRAP    #15             ; Print MODEB string
        BRA     DORA            ; Branch to addressing mode parsing

DORW    LEA     ORM,A1          ; Load effective address of ORM string
        TRAP    #15             ; Print ORM string
        LEA     MODEW,A1        ; Load effective address of MODEW string
        TRAP    #15             ; Print MODEW string
        BRA     DORA            ; Branch to addressing mode parsing

DORL    LEA     ORM,A1          ; Load effective address of ORM string
        TRAP    #15             ; Print ORM string
        LEA     MODEL,A1        ; Load effective address of MODEL string
        TRAP    #15             ; Print MODEL string
        BRA     DORA            ; Branch to addressing mode parsing

DORA    LEA     SM6,A1
        TRAP    #15
		ROL.W   #6,D4           ; Shift D4 left by 6 bits to get addressing mode and register
        MOVE.B  D4,D5           ; Move the byte in D4 to D5
        ANDI.B  #%111000,D5     ; AND operation to isolate the mode bits
        ROR.B   #3,D5           ; Shift D5 right by 3 bits to get mode
        MOVE.B  D5,D3           ; Store mode in D3 for further checks
        ANDI.B  #%111,D4        ; AND operation to isolate the last 3 bits in D4
        MOVE.B  D4,D6           ; Store the register number in D6 for later use

        JSR     ADDRMODEALL     ; Call subroutine to parse and print effective address

        BRA     DSEND                    


* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1001  NOP
DSUB    NOP
*print sub
        LEA     SUBM,A1
        TRAP    #15

*parse dn reg: 3 bits
*number of the data register involved
*nums 0-7, paired with below
        ROL.W   #3,D4       *dn reg num in d1
        MOVE.B  D4,D7
        ANDI.B  #%111,D7
        
        MOVE.W  D7,A6       *temporary for storage

*parse opmode: 3 bits
*Dn - <ea> -> Dn: .B=000, .W=001, .L=010
*<ea> - <Dn> -> <ea>: .B=100, .W=101, .L=110
*invalid: 111, 011
*parse first digit separately
        ROL.W   #1,D4       *addressing mode in d2
        MOVE.B  D4,D7
        ANDI.B  #%1,D7
        
*parsing next two digits of size
        ROL.W   #2,D4       *size in d5
        MOVE.B  D4,D5
        ANDI.B  #%11,D5
        JSR     SIZE
        LEA     SM7,A1
        TRAP    #15
        
*if addressing mode=<ea>-Dn -> <ea> print ea info first
        CMP.B   #%0,D7       *if 1, then register info printed last
        BEQ     DSUBEA      *branch to ea before register
        
*printing register information
DSUBPRNTREG
        LEA     VALD,A1
        TRAP    #15
        MOVE.W  A6,D1       *retrieving a6 register data
        MOVE.B  #3,D0       *moving 3 to d0 to print register number
        TRAP    #15         *printing register number
        MOVE.B  #14,D0      *replacing 14 in d0 to print strings
        CMP.B   #%0,D7      *if info finished printing
        BEQ     DSEND      *branch to end
        LEA     COMMA,A1
        TRAP    #15

        
* parse ea mode: 3 bits
*Dn000, An001, (An)010, (An)+011, -(An)100, (d16An)101, (d8An,Xn)110, data111
*address reg direct not allowed for .B operations
*no invalid
DSUBEA
        ROL.W   #3,D4       *ea mode
        MOVE.B  D4,D3
        ANDI.B  #%111,D3

*parse ea reg: 3 bits
*no invalid: paired with opmode below (nums 0-7)
*if mode=111, 000=.W, 001=.L, 100=#<data>
        ROL.W   #3,D4       *ea mode
        MOVE.B  D4,D6
        ANDI.B  #%111,D6
        
        MOVE.L  D3,D4   *temporarily using D4 
        
*comparisons
        CMP     #%100,D3
        BEQ     DSERR
        JSR     ADDRMODEALL
        CMP.B   #%1,D7      *if info printed
        BEQ     DSEND       *end
        LEA     COMMA,A1
        TRAP    #15
        BRA     DSUBPRNTREG *check d6 for size of data
*then take data from d4 and print (?)

        BRA     DSEND



DS1010  NOP
        BRA     DSERRINS

        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1011  NOP
        BRA     DSERRINS
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1100  NOP
        BRA     DSERRINS
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1101  NOP

DADD    NOP
        LEA     ADDM,A1
        TRAP    #15
        
        *parse dn reg: 3 bits
*number of the data register involved
*nums 0-7, paired with below
        ROL.W   #3,D4       *dn reg num in d7
        MOVE.B  D4,D7
        ANDI.B  #%111,D7
        
        MOVE.W  D7,A6

*parse opmode: 3 bits
*Dn - <ea> -> Dn: .B=000, .W=001, .L=010
*<ea> - <Dn> -> <ea>: .B=100, .W=101, .L=110
*invalid: 111, 011
*parse first digit separately
        ROL.W   #1,D4       *addressing mode in d2
        MOVE.B  D4,D7
        ANDI.B  #%1,D7
        
*parsing next two digits of size
        ROL.W   #2,D4       *size in d5
        MOVE.B  D4,D5
        ANDI.B  #%11,D5
        CMP.B   #%11,D5     *if size is 11, then opcode is ADDA
        BEQ     DADDA
        JSR     SIZE
        LEA     SM7,A1
        TRAP    #15
        
*if addressing mode=<ea>-Dn -> <ea> print ea info first
        CMP.B   #%0,D7       *if 0, then register info printed last
        BEQ     DADDEA      *branch to ea before register
        
*printing register information
DADDPRNTREG
        CMP.B   #%11,D5
        BEQ     PRINTA
        LEA     VALD,A1
ADDCONT
        TRAP    #15
        MOVE.W  A6,D1       *moving reg num to d1 to print
        MOVE.B  #3,D0       *moving 3 to d0 to print register number
        TRAP    #15         *printing register number
        MOVE.B  #14,D0      *replacing 14 in d0 to print strings
        CMP.B   #%0,D7      *if info finished printing
        BEQ     DSEND      *branch to end
        LEA     COMMA,A1
        TRAP    #15

        
* parse ea mode: 3 bits
*Dn000, An001, (An)010, (An)+011, -(An)100, (d16An)101, (d8An,Xn)110, data111
*address reg direct not allowed for .B operations
*no invalid
DADDEA
        ROL.W   #3,D4       *ea mode
        MOVE.B  D4,D3
        ANDI.B  #%111,D3

*parse ea reg: 3 bits
*no invalid: paired with opmode below (nums 0-7)
*if mode=111, 000=.W, 001=.L, 100=#<data>
        ROL.W   #3,D4       *ea mode
        MOVE.B  D4,D6
        ANDI.B  #%111,D6
        
*comparisons
        CMP     #%100,D3
        BEQ     ADDDATACHECK
DATACHECKCONT
        JSR     ADDRMODEALL
        CMP.B   #%1,D7      *if info printed
        BEQ     DSEND       *end
        LEA     COMMA,A1
        TRAP    #15
        BRA     DADDPRNTREG 

        BRA     DSEND
        
PRINTA  LEA     VALA,A1
        BRA     ADDCONT

        
DADDA   NOP
        LEA     VALA,A1
        TRAP    #15
        CMP.B   #%0,D7      *for adda, 0=word, 1=longword
        BNE     ADDAL
        LEA     MODEW,A1
        BRA     ADDSIZEEND
ADDAL   LEA     MODEL,A1
        BRA     ADDSIZEEND
ADDSIZEEND
        TRAP    #15
        LEA     SM7,A1
        TRAP    #15
        MOVE.B  #%0,D7       *set d2 to print adda in correct order: address register always last
        BRA     DADDEA
ADDDATACHECK
        CMP.B   #%11,D5
        BEQ     DSERR
        BRA     DATACHECKCONT
        
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1110
        ROL.W   #3,D4           * [D2] Reading count
        MOVE.B  D4,D2
        ANDI.B  #%111,D2
        
        ROL.W   #1,D4           * [D3] Reading direction
        MOVE.B  D4,D3
        ANDI.B  #%1,D3
        
        ROL.W   #2,D4           * [D5] Reading size
        MOVE.B  D4,D5
        ANDI.B  #%11,D5
        
        CMP.B   #%11,D5   * Start processing code as memory if size is 11
        BEQ     DS1110MEM
        
        ROL.W   #1,D4           * [D6] Reading count mode
        MOVE.B  D4,D6
        ANDI.B  #%1,D6
        
        ROL.W   #2,D4           * [D7] reading type of shift
        MOVE.B  D4,D7
        ANDI.B  #%11,D7
        
        ROL.W   #3,D4           * [D1] reading register
        MOVE.B  D4,D1
        ANDI.B  #%111,D1
        
        CMP.B   #%01,D7   *Determine shift type
        BEQ     DLS
        CMP.B   #%00,D7
        BEQ     DAS
        CMP.B   #%11,D7
        BEQ     DRO
        
        BRA     DSEND               *Fallback in case of invalid code
        
DS1110A MOVEM.L A0-A7/D0-D7,-(SP)   *Print shift direction
        JSR     DS1110SIDE
        MOVEM.L (SP)+,A0-A7/D0-D7
        
        MOVEM.L A0-A7/D0-D7,-(SP)   *Print size
        JSR     SIZE
        MOVEM.L (SP)+,A0-A7/D0-D7
        
        MOVE.B  #14,D0
        LEA     SM5,A1
        TRAP    #15
        
        CMP.B   #%11,D5
        BEQ     DS1110MEMA
        
        CMP.B   #%1,D6
        BEQ     DS1110_REG_D
        BRA     DS1110_REG_I
        
DS1110B MOVE.B  D1,D6               *We ned D1 for trap task so since we're done using D6, we put D1 into D6 temporarily
        
        MOVE.B  #3,D0
        MOVE.B  D2,D1
        TRAP    #15
        
        MOVE.B  #14,D0
        LEA     COMMA,A1
        TRAP    #15
        
        LEA     VALD,A1
        TRAP    #15
        
        MOVE.B  #3,D0
        MOVE.B  D6,D1
        TRAP    #15
        
        BRA     DSEND
        
DS1110_REG_I
        LEA     VALN,A1
        TRAP    #15
        BRA     DS1110B

DS1110_REG_D
        LEA     VALD,A1
        TRAP    #15
        BRA     DS1110B       
        
DLS     LEA     LSM,A1
        TRAP    #15
        BRA     DS1110A
        
DAS     LEA     ASM,A1
        TRAP    #15
        BRA     DS1110A
        
DRO     LEA     ROM,A1
        TRAP    #15
        BRA     DS1110A
        
DS1110SIDE
        MOVE.B  #6,D0
        CMP.B   #1,D3
        BEQ     DS1110LSIDE
        MOVE.B  #82,D1
        TRAP    #15
        BRA     DS1110SIDEEND

DS1110LSIDE
        MOVE.B  #76,D1
        TRAP    #15
        
DS1110SIDEEND
        RTS 

DS1110MEM
                                * Shift type is instead stored in D2
        
        ROL.W   #3,D4           * [D6] Reading address mode
        MOVE.B  D4,D6
        ANDI.B  #%111,D6
        
        ROL.W   #3,D4           * [D1] Reading address register
        MOVE.B  D4,D1
        ANDI.B  #%111,D1
        
        CMP.B   #%01,D2
        BEQ     DLS
        CMP.B   #%00,D2
        BEQ     DAS
        CMP.B   #%11,D2
        BEQ     DRO
        BRA     DSEND
        
        
DS1110MEMA
        
        CMP.B   #%010,D6
        BEQ     DS1110MEM_REG
        CMP.B   #%011,D6
        BEQ     DS1110MEM_INC
        CMP.B   #%100,D6
        BEQ     DS1110MEM_DEC
        
        CMP.B   #%111,D6
        BNE     DSERR
        
        CMP.B   #%000,D1
        BEQ     DS1110MEM_CUSW
        CMP.B   #%001,D1
        BEQ     DS1110MEM_CUSL
        
        BRA     DSEND

DS1110MEM_REG
        LEA     OPENPTR,A1
        TRAP    #15
        
        LEA     VALA,A1
        TRAP    #15
        
        MOVE.B  #3,D0
        TRAP    #15
        MOVE.B  #14,D0
        
        LEA     CLOSEPTR,A1
        TRAP    #15
        
        BRA     DSEND

DS1110MEM_INC
        LEA     OPENPTR,A1
        TRAP    #15
        
        LEA     VALA,A1
        TRAP    #15
        
        MOVE.B  #3,D0
        TRAP    #15
        MOVE.B  #14,D0
        
        LEA     CLOSEIPTR,A1
        TRAP    #15
        
        BRA     DSEND

DS1110MEM_DEC
        LEA     OPENDPTR,A1
        TRAP    #15
        
        LEA     VALA,A1
        TRAP    #15
        
        MOVE.B  #3,D0
        TRAP    #15
        MOVE.B  #14,D0
        
        LEA     CLOSEPTR,A1
        TRAP    #15
        
        BRA     DSEND
        
DS1110MEM_CUSW
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.W  (A2)+,D2
        MOVEM.L D5,-(SP)
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        BRA     DSEND
        
DS1110MEM_CUSL
        LEA     DOLLAR,A1
        TRAP    #15
        MOVE.L  (A2)+,D2
        MOVEM.L D5,-(SP)
        MOVE.B  #48,D5
        JSR     HEXOUT
        MOVEM.L (SP)+,D5
        BRA     DSEND
        

* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1111  NOP
        BRA     DSEND

*DS Final
*--------------------------------------------------------------------------------------------------

DSERR   MOVE.B  #14,D0
        LEA     ERRM,A1
        TRAP    #15
        BRA     DSEND
        
DSERRINS
        MOVE.B  #14,D0
        LEA     ERRMINS,A1
        TRAP    #15
        BRA     DSEND

DSERREA
        MOVE.B  #14,D0
        LEA     ERRMEA,A1
        TRAP    #15

DSEND   RTS

DSEOF   LEA     LB,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     REST,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.B  #5,D0
        TRAP    #15
        
        CMP.B   #89,D1
        BEQ     START
        CMP.B   #121,D1
        BEQ     START

END     LEA     LB,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     LB,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     ENDMSG,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     AUTHOR,A1
        TRAP    #15
        
        LEA     LB,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.B  #9,D0
        TRAP    #15

*Initialized Variables
*--------------------------------------------------------------------------------------------------

CR      EQU     $0D
LF      EQU     $0A
HT      EQU     $09

INTRO   DC.B    'This is a program that will disassemble machine code stored in memory!',CR,LF,'Inputs are read as hex form of longword size (up to 8 chars)!',CR,LF,0
ASTART  DC.B    'Enter start address: $',0
AEND    DC.B    'Enter end address:   $',0
REST    DC.B    'Restart Disassembler (y/n)? ',0
ENDMSG  DC.B    'Thank you for using the Disassembler!',CR,LF,0
AUTHOR  DC.B    'Made by the ARM Cortex Companions!',CR,LF,0

VERR1M  DC.B    'ERROR: End address must not be less than start address!',CR,LF,0
VERR2M  DC.B    'ERROR: Invalid characters in input!',CR,LF,0
VERR3M  DC.B    'ERROR: Input cannot be greater than 8 characters!',CR,LF,0

LB      DC.B    CR,LF,0

HTM     DC.B    HT,0

SM1     DC.B    ' ',0
SM2     DC.B    '  ',0
SM3     DC.B    '   ',0
SM4     DC.B    '    ',0
SM5     DC.B    '     ',0
SM6     DC.B    '      ',0
SM7     DC.B    '       ',0

TESTM   DC.B    'TEST',0

NOTH    DC.B    '',0
NOTH2   DC.B    '',0

ERRM    DC.B    ' *ERROR',0
ERRMINS DC.B    '',0
ERRMEA  DC.B    ' *ERROR: Unsupported Addressing Mode',0

MODEB   DC.B    '.B',0
MODEW   DC.B    '.W',0
MODEL   DC.B    '.L',0

VALA    DC.B    'A',0
VALD    DC.B    'D',0
VALN    DC.B    '#',0
VAL0    DC.B    '0',0
VALQ    DC.B    'Q',0

OPENPTR     DC.B    '(',0
OPENDPTR    DC.B    '-(',0

CLOSEPTR    DC.B    ')',0
CLOSEIPTR   DC.B    ')+',0

COMMA   DC.B    ',',0
DOLLAR  DC.B    '$',0

NOPM    DC.B    'NOP',0

MOVEM   DC.B    'MOVE',0

ADDM    DC.B    'ADD',0

SUBM    DC.B    'SUB',0

LEAM    DC.B    'LEA',0

ANDM    DC.B    'AND',0
ORM     DC.B    'OR',0
NOTM    DC.B    'NOT',0

LSM    DC.B    'LS',0
LSRM    DC.B    'LSR',0
ASM    DC.B    'AS',0
ASRM    DC.B    'ASR',0

ROM    DC.B    'RO',0
RORM    DC.B    'ROR',0

BGTM    DC.B    'BGT',0
BLEM    DC.B    'BLE',0
BEQM    DC.B    'BEQ',0

JSRM    DC.B    'JSR',0
RTSM    DC.B    'RTS',0

BRAM    DC.B    'BRA',0


    END    START        ; last line of so



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
