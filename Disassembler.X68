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

READLN  MOVE.L  A3,A2

RSTEP   MOVE.L  (A2)+,D4
        MOVE.L  A2,D2
        SUBQ.L  #4,D2
        
        JSR     HEXOUT
        
        LEA     HTM,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVEM.L A0-A7/D0-D7,-(SP)
        JSR     DISASM
        MOVEM.L (SP)+,A0-A7/D0-D7
        
        *Disassembly code will start here
        *I will organize this area later on
        
        LEA     TESTM,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     LB,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        
        
        CMP.L   A2,A4
        BLT     END
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
*Each machine code iterated through will be in D4. You can use all data registers as there will be a stack pointer involved
*You will kind of have to locate the label for the first 4 bits of the machine code. There is a special case where the prefix of 000 can be variable with the size parameter

DISASM                      *DISASM: Disassemble a machine code
        LSL.L   #1,D4
        BCS     DS1
        BRA     DS0
        
DS0      
        LSL.L   #1,D4
        BCS     DS01
        BRA     DS00

DS1      
        LSL.L   #1,D4
        BCS     DS11
        BRA     DS10

DS00     
        ROL.L   #2,D4
        MOVE.L  D4,D5
        ANDI.B  #%11,D4
        CMPI.B  #%00,D4
        BEQ     DAND

DAND    NOP                 *DAND: Disassembly function serving DAND        
        
DMOVE2  NOP                 *DMOVE2: Disassembly function serving MOVE and MOVEA
        

DMOVEA  NOP

*DS Tier 2
*--------------------------------------------------------------------------------------------------

DS01    
        LSL.L   #1,D4
        BCS     DS011
        BRA     DS010

DS10    
        LSL.L   #1,D4
        BCS     DS101
        BRA     DS100

DS11    
        LSL.L   #1,D4
        BCS     DS111
        BRA     DS110

*DS Tier 3
*--------------------------------------------------------------------------------------------------

DS010    
        LSL.L   #1,D4
        BCS     DS0101
        BRA     DS0100

DS011    
        LSL.L   #1,D4
        BCS     DS0111
        BRA     DS0110

DS100    
        LSL.L   #1,D4
        BCS     DS1001
        BRA     DS1000

DS101    
        LSL.L   #1,D4
        BCS     DS1011
        BRA     DS1010

DS110    
        LSL.L   #1,D4
        BCS     DS1101
        BRA     DS1100

DS111    
        LSL.L   #1,D4
        BCS     DS1111
        BRA     DS1110

*DS Tier 4
*--------------------------------------------------------------------------------------------------

DS0100  NOP

DS0101  NOP

DS0110  NOP

DS0111  NOP

DS1000  NOP

DS1001  NOP

DS1010  NOP

DS1011  NOP

DS1100  NOP

DS1101  NOP

DS1110  NOP

DS1111  NOP

*DS Final
*--------------------------------------------------------------------------------------------------

DSERR   NOP

DSEND   RTS

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
