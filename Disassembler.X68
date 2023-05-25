*-----------------------------------------------------------
* Title      : Disassembler Snippet
* Written by : ARM Cortex Companions
* Date       : 5/15/2023
* Description: Ben Schipunov contribution to the disassembler
*-----------------------------------------------------------

STARTER
        ORG     $1000       *Start at $1000
        
*-------------------------------------------------------------------------------------------------- 
       
START                       *START: Start code

        LEA     INTRO,A1    *Intro text
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     ASTART,A1   *Input prompt text #1
        TRAP    #15

        MOVE.B  #2,D0       *String prompt #1
        TRAP    #15
        
        CMP.W   #8,D1       *Throw error if length is greater than 8 (length stored in D1)
        BGT     VERR3
        
        JSR     PARSE       *Parse string #1
        

        MOVE.L  D1,A3
        
        LEA     AEND,A1     *Input prompt text #2
        MOVE.B  #14,D0
        TRAP    #15
        
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
        
        JSR     HEXOUT              *Run printing operation for HEX address
        
        LEA     HTM,A1              *Horizontal tab indent after printing hex
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVEM.L A0-A7/D1-D7,-(SP)   *Store data to stack
        JSR     DISASM              *Run disassembly for current machine code
        MOVEM.L (SP)+,A0-A7/D1-D7   *Recall data from stack
        
        ADDQ.B  #1,D5       *Increment counter by 1
        CMP.B   #32,D5      *Check if we reached 32 lines
        BEQ     RPAUSE      *Branch to pausing code
        
        LEA     LB,A1       *Print line break
        MOVE.B  #14,D0      
        TRAP    #15
        
RCONT                       *RCONT: Used to continue off of the RPAUSE label after a pause in the printing
        CMP.L   A2,A4       *Check if we reached the end address
        BLT     END         *End loop if so
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
        TRAP #15            *Will print the ASCII value stored in D1
        CMPI.B  #0,D3       *Check if we reached 8 characters for a longword
        BEQ     HDONE       *End loop if done
        BRA     HSTEP       *Or else continue loop
        
HDONE   RTS

*--------------------------------------------------------------------------------------------------
*Each machine code iterated through will be in D4. You can use all data registers as there will be a stack pointer involved
*You will kind of have to locate the label for the first 4 bits of the machine code. There is a special case where the prefix of 000 can be variable with the size parameter

*During the processing of each machine code, we skip the first four bits as they have been passed through during the searching system. The exception to this is two bits for machine codes that start with 00.

*CODING INSTRUCTIONS: You should not touch D0 as we want to keep it as the trap task. If for any reason you have to touch D0, make sure ou set it back to #14 for printing the strings.
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
        MOVE.W  D4,D5
        ANDI.B  #%11,D4
        CMPI.B  #%00,D4
        BEQ     DAND
        BRA     DSEND

DAND    NOP                 *DAND: Disassembly function serving DAND        
        
DMOVE2  NOP                 *DMOVE2: Disassembly function serving MOVE and MOVEA
        

DMOVEA  NOP

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
        BRA     DSEND

DNOP    LEA     NOPM,A1
        TRAP    #15
        BRA     DSEND
        
DNOT    NOP
        BRA     DSEND
        
DJSR    NOP
        BRA     DSEND
        
DRTS    NOP
        BRA     DSEND

* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS0101  NOP
        BRA     DSEND
        
DADDQ   NOP
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS0110  NOP
        BRA     DSEND
        
DBCC    NOP
        BRA     DSEND
        
DBRA    NOP
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS0111  NOP
        BRA     DSEND
        
DMOVEQ  NOP
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1000  NOP
        BRA     DSEND
        
DOR     NOP
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1001  NOP
        BRA     DSEND
        
DSUB    NOP
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1010  NOP
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1011  NOP
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1100  NOP
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1101  NOP
        BRA     DSEND
        
DADDA   NOP
        BRA     DSEND
        
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1110
        
        BRA     DSEND
        
DLSL    NOP
        BRA     DSEND
        
DLSR    NOP
        BRA     DSEND
        
DASL    NOP
        BRA     DSEND
        
DASR    NOP
        BRA     DSEND
        
DROL    NOP
        BRA     DSEND
        
DROR    NOP
        BRA     DSEND
 
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DS1111  NOP
        BRA     DSEND

*DS Final
*--------------------------------------------------------------------------------------------------

DSERR   NOP

DSEND   RTS

END     MOVE.B  #9,D0
        TRAP    #15

CR      EQU     $0D
LF      EQU     $0A
HT      EQU     $09

INTRO   DC.B    'This is a program that will disassemble machine code stored in memory!',CR,LF,'Inputs are read as hex form of longword size (up to 8 chars)!',CR,LF,0
ASTART  DC.B    'Enter start address: $',0
AEND    DC.B    'Enter end address:   $',0

VERR1M  DC.B    'ERROR: End address must not be less than start address!',CR,LF,0
VERR2M  DC.B    'ERROR: Invalid characters in input!',CR,LF,0
VERR3M  DC.B    'ERROR: Input cannot be greater than 8 characters!',CR,LF,0

LB      DC.B    CR,LF,0

HTM     DC.B    HT,0

TESTM   DC.B    'TEST',0

MODEB   DC.B    '.B',0
MODEW   DC.B    '.W',0
MODEL   DC.B    '.L',0


NOPM    DC.B    'NOP',0

MOVEM   DC.B    'MOVE',0

ADDM    DC.B    'ADD',0

SUBM    DC.B    'SUB',0

LEAM    DC.B    'LEA',0

ANDM    DC.B    'AND',0
ORM     DC.B    'OR',0
NOTM    DC.B    'NOT',0

LSLM    DC.B    'LSL',0
LSRM    DC.B    'LSR',0
ASLM    DC.B    'ASL',0
ASRM    DC.B    'ASR',0

ROLM    DC.B    'ROL',0
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
