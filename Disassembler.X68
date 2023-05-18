*-----------------------------------------------------------
* Title      : Disassembler Snippet
* Written by : Ben Schipunov (ARM Cortex Companions)
* Date       : 5/15/2023
* Description: Ben Schipunov contribution to the disassembler
*-----------------------------------------------------------

STARTER
        ORG     $1000
        
*-------------------------------------------------------------------------------------------------- 
       
START                       *START: Start code
        LEA     ASTART,A1   *Input prompt text #1
        MOVE.B  #14,D0      
        TRAP    #15

        MOVE.B  #2,D0       *String prompt #1
        TRAP    #15
        
        JSR     PARSE       *Parse string #1
        

        MOVE.L  D1,A3
        
        LEA     AEND,A1     *Input prompt text #2
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.B  #2,D0       *String prompt #2
        TRAP    #15
        
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

VINPUT  CMP.L   A3,A4
        BLT     VERR1
        BRA     READLN

VERR1   LEA     VERR1M,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     END

VERR2   LEA     VERR2M,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     END
        
*--------------------------------------------------------------------------------------------------

READLN  SUBA.L  #4,A3
        SUBA.L  #4,A4
        MOVE.L  A3,A2

RSTEP   MOVE.L  (A2)+,D2
        MOVE.L  A2,D2
        
        
        JSR     HEXOUT
        
        LEA     HTM,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        *Disassembly code will start here
        *I will organize this area later on
        
        LEA     TESTM,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     LB,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        
        
        CMP.L   A2,A4
        BLE     END
        BRA     RSTEP

*--------------------------------------------------------------------------------------------------

HEXOUT                      *HEXOUT: Prints a value in hexadecimal
        MOVE.B  #6,D0       * [D0] Trap task #6
        MOVE.B  #0,D1
        MOVE.B  #8,D3
        
HSTEP   ROL.L   #4,D2
        MOVE.L  D2,D1
        ANDI.L  #$F,D1
        CMP.B   #10,D1
        BLT     HNUM
        
HHEX    ADDI.B  #55,D1
        BRA     HSTEP2

HNUM    ADDI.B  #48,D1

HSTEP2  SUBQ.B  #1,D3
        TRAP #15
        CMPI.B  #0,D3
        BEQ     HDONE
        BRA     HSTEP
        
HDONE   RTS

*--------------------------------------------------------------------------------------------------

END     MOVE.B  #9,D0
        TRAP    #15

CR      EQU     $0D
LF      EQU     $0A
HT      EQU     $09

INTRO   DC.B    'This is a program that will disassemble machine code from a start to an end address!',CR,LF,0
ASTART  DC.B    'Enter start address: $',0
AEND    DC.B    'Enter end address:   $',0

VERR1M  DC.B    'ERROR: End address must not be less than start address',CR,LF,0
VERR2M  DC.B    'ERROR: Invalid input',CR,LF,0

LB      DC.B    CR,LF,0

HTM     DC.B    HT,0

TESTM   DC.B    'TEST',0

    END    START        ; last line of so

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
