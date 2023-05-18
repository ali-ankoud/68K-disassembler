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
        
        LEA     AEND,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.B  #2,D0
        TRAP    #15
        
PARSE   

PROC    


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
