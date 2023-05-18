*-----------------------------------------------------------
* Title      : Disassembler Snippet
* Written by : Ben Schipunov (ARM Cortex Companions)
* Date       : 5/15/2023
* Description: Ben Schipunov contribution to the disassembler
*-----------------------------------------------------------

STARTER
        ORG     $1000
        
START   LEA     ASTART,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVE.B  #2,D0
        TRAP    #15
        
        JSR     PSTART
        MOVE.L  D1,A3
        
        LEA     AEND,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.B  #2,D0
        TRAP    #15
        
        JSR     PSTART
        MOVE.L  D1,A4
        
        BRA     END
        

PSTART                      *PSTART: Initialize variables involved in parsing
        MOVE.B  #0,D1       * [D1] parse output
        MOVE.B  #8,D2       * [D2] max letter counter (size of longword)
        
PSTEP                       *PSTEP: Step in parsing for loop
        MOVE.B  (A1)+,D0    *Read next byte from A1
        CMP.B   #0,D0       *Check if reached end of string input
        BEQ     PDONE       *Break the for loop if reached end
        LSL.L   #4,D1       *Logical shift left by 4 bits to insert next hex character
        CMP.B   #58,D0      *Distinguish between letter and number
        BLT     PNUM        *Handle number
        BRA     PHEX        *Handle hex letter

PHEX    SUB.B   #55,D0      *ASCII value subtracted by 55 to match hex value
        BRA     PSTEP2

PNUM    SUB.B   #48,D0      *ASCII value subtracted by 48 to match hex value
        
PSTEP2  ADD.L   D0,D1       *Append hex char to parse output
        SUBQ.B  #1,D2       *Decrement the counter
        CMP.B   #0,D2       *Compare if we reached max count
        BEQ     PDONE       *Complete parsing
        BRA     PSTEP       *Or else continue loop

PDONE   RTS

VINPUT  MOVE.B  #0,D0       *Temporary line to allow compiling

PROC    MOVE.B  #0,D0       *Temporary line to allow compiling


END     MOVE.B  #9,D0
        TRAP    #15

CR      EQU     $0D
LF      EQU     $0A

INTRO   DC.B    'This is a program that will disassemble machine code from a start to an end address!'
ASTART  DC.B    'Enter start address: $',0
AEND    DC.B    'Enter end address:   $',0

    END    START        ; last line of so
*-----------------------------------------------------------
* Title      : Disassembler Snippet
* Written by : Ben Schipunov (ARM Cortex Companions)
* Date       : 5/15/2023
* Description: Ben Schipunov contribution to the disassembler
*-----------------------------------------------------------

STARTER
        ORG     $1000
        
START   LEA     ASTART,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVE.B  #2,D0
        TRAP    #15
        
        JSR     PSTART
        MOVE.L  D1,A3
        
        LEA     AEND,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.B  #2,D0
        TRAP    #15
        
        JSR     PSTART
        MOVE.L  D1,A4
        
        BRA     END
        

PSTART                      *PSTART: Initialize variables involved in parsing
        MOVE.B  #0,D1       * [D1] parse output
        MOVE.B  #8,D2       * [D2] max letter counter (size of longword)
        
PSTEP                       *PSTEP: Step in parsing for loop
        MOVE.B  (A1)+,D0    *Read next byte from A1
        CMP.B   #0,D0       *Check if reached end of string input
        BEQ     PDONE       *Break the for loop if reached end
        LSL.L   #4,D1       *Logical shift left by 4 bits to insert next hex character
        CMP.B   #58,D0      *Distinguish between letter and number
        BLT     PNUM        *Handle number
        BRA     PHEX        *Handle hex letter

PHEX    SUB.B   #55,D0      *ASCII value subtracted by 55 to match hex value
        BRA     PSTEP2

PNUM    SUB.B   #48,D0      *ASCII value subtracted by 48 to match hex value
        
PSTEP2  ADD.L   D0,D1       *Append hex char to parse output
        SUBQ.B  #1,D2       *Decrement the counter
        CMP.B   #0,D2       *Compare if we reached max count
        BEQ     PDONE       *Complete parsing
        BRA     PSTEP       *Or else continue loop

PDONE   RTS

VINPUT  MOVE.B  #0,D0       *Temporary line to allow compiling

PROC    MOVE.B  #0,D0       *Temporary line to allow compiling


END     MOVE.B  #9,D0
        TRAP    #15

CR      EQU     $0D
LF      EQU     $0A

INTRO   DC.B    'This is a program that will disassemble machine code from a start to an end address!'
ASTART  DC.B    'Enter start address: $',0
AEND    DC.B    'Enter end address:   $',0

    END    START        ; last line of so

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
