*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
        MOVE.L      #%11100111000100000000000000000000,D4    placeholder address input
        MOVE.L      #%11100111000100000000000000000000,D5    storing NOP comparison in d5
        MOVE.B      #0,NOPBOOL          initializing NOPBOOL

        MOVE.L      #0,D7               loop counter
        MOVE.L      #12,D3              terminal val
L0100   CMP         D7,D3               if equals
        BEQ         R0100               branch to result comparison
        ADDQ.L      #1,D7               incrementing loop counter
        LSL.L       #1,D4               doing shift op on d4
        BCC         SA00100             if 0, jump to 0 store
        MOVE.B      #1,D6               store 1 in d6
        BRA         CNP0100             after storing 1, jump to comparisons
SA00100 MOVE.B      #0,D6               store 0 in d6
CNP0100 LSL.L       #1,D5               doing shift op on NOP comparison
        BCC         SC00100             branching to store 0
        MOVE.B      #1,D2               storing nop comparison bit in d2
        BRA         CMP0100             branching to avoid 0 store
SC00100 MOVE.B      #0,D2               storing nop comparison bit in d2
CMP0100 CMP         D2,D6               comparing bits 0100
        BEQ         L0100               placeholder: branch to next opcode (RTS, JSR, NOT, etc)
        MOVE.B      #1,NOPBOOL          Setting NOP to FALSE
        BRA         END                 placeholder: branch to next opcode

R0100                                   *result 0100
        CMP         #0,NOPBOOL          comparing 0 and nopbool
        BEQ         NOP                 if equal, print nop
        BRA         END                 else, branch to end (redundant)
        
NOP     MOVE.B      'NOP',CURADR        printing nop
        LEA         CURADR,A1
        MOVE.B      #14,D0
        TRAP        #15
        
END

    SIMHALT             ; halt simulator

* Put variables and constants here

CURADR  DC.B    'NOP',0

NOPBOOL DC.B    0,0

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
