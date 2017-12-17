.model small
.stack 100h
.data
    w           db ?
    reg         db ?
    rm          db ?
    mod         db ?
    segAdr      dw 0  
    curPos      dw 100h
    input       db 255 dup (0)
    inputHan    dw ?
    tmp         db ?
    output      db 255 dup (0)
    outputHan   dw ?
    inByte      db ?
    maxBuffer   dw 255
    buffer      db 255 dup (?)
    bufferPos   dw ?
    bufferSize  dw ?
    info        db 'Arnas Danaitis, 4 grupe. Disasmas', 13, 10, 'Programa leidziama formatu: disasmas [source] [destination]', 13, 10, '$'
    watafak     db ';Neatpazinta komanda$'
    failOpen    db 'Nepavyko atidaryti arba sukurti failo - neteisingas pavadinimas?', 13, 10, '$'
    segReg      db 'ES$CS$SS$DS$'
    segPrefHex  db 26h, 2Eh, 36h, 3Eh
    segPushPop  db 06h, 0Eh, 16h, 1Eh
    regByte     db 'AL$CL$DL$BL$AH$CH$DH$BH$'
    regWord     db 'AX$CX$DX$BX$SP$BP$SI$DI$'
    addressName db 'BX + SI$BX + DI$BP + SI$BP + DI$SI$     DI$     BP$     BX$'
    jumpCond    db 'JO   $JNO  $JB   $JNB  $JE   $JNE  $JBE  $JA   $JS   $JNS  $JPE  $JPO  $JL   $JGE  $JLE  $JG   $'
    jumpCondXtr db 'LOOP $JCXZ $JMP  $'
    jumpCondHex db 70h, 7Fh ;startinis, paskutinis
    jumpXtrHex  db 0E2h, 0E3h, 0EBh 
    reg16Var    db 'INC  $DEC  $'
    pushPopVar  db 'PUSH $POP  $'
    reg16Hex    db 40h, 5Fh ;antra - compare'
    regForm     db 'ADD  $OR   $ADC  $SBB  $AND  $SUB  $XOR  $CMP  $'
    regFormHex  db 00h, 3Dh
    intHex      db 0CDh, 0CCh
    intVar      db 'INT  $'
    retHex      db 0C2h, 0C3h, 0CAh, 0CBh
    retVar      db 'RET  $RETF $'
    movVar      db 'MOV  $'
    comBuf      db 100 dup (' ')
    comBufL     dw ?
    resBuf      db 100 dup (?)
    resBufL     dw ?
    comBufOn    db 0
    grp3Hex     db 0F6h, 0F7h    
    grp3Var     db '                        MUL  $      DIV  $'
    grp45Hex    db 0FEh, 0FFh
    grp45Var    db 'INC  $DEC  $CALL $CALL $JMP  $JMP  $PUSH $'
    callJmpVar  db 'CALL $JMP  $'
    callJmpRHex db 0E8h, 0E9h
    callJmpAHex db 9Ah, 0EAh
    movTypHex   db 88h, 8Eh
    movGrp1Hex  db 0C6h, 0C7h
    movAdrAxHex db 0A0h, 0A3h, 0A2h
    movRegIHex  db 0B0h, 0BFh, 0B8h ;trecias - nuo kur prasideda zodiniai
    grp1Hex     db 80h, 83h
    popEvHex    db 8Fh
    newl        db 13, 10, '$'
    operandGap  db ', $'
    bracketPlus db '[$]$ + $'
    colon       db ':$'
    colonSpace  db ': $' 
    byteWordPtr db 'byte ptr $word ptr $'
    farPtr      db 'far $'
.code
vazhiojam:
    MOV ax, @data
    MOV ds, ax
    CALL paramCheck
    MOV ah, 3Dh
    MOV dx, offset input
    MOV bx, offset inputHan
    CALL openFile
    MOV ah, 3Ch
    MOV dx, offset output
    MOV bx, offset outputHan
    CALL openFile
    read:
        MOV resBufL, 0
        MOV comBuFL, 0
        MOV comBufOn, 1
        MOV dx, curPos
        XCHG dl, dh
        CALL printHex
        MOV dl, dh
        CALL printHex
        MOV word ptr comBuf + 4, ' :'
        ADD comBufL, 2
        MOV comBufOn, 0
        CALL readBuffer
        CALL analyseByte
        MOV bx, offset comBuf
        ADD bx, comBufL
        padBuf:
            CMP [bx], ' '
            JE  endPadBuf
            MOV [bx], ' '
            INC comBufL
            INC bx
        JMP padBuf
        endPadBuf:
        MOV dx, offset comBuf
        MOV cx, 30
        CALL bufToFile
        MOV cx, resBufL
        MOV dx, offset resBuf
        CALL bufToFile                                                                                            
    JMP read   
    fin:
        MOV ah, 3Eh
        MOV bx, inputHan
        INT 21h
        MOV ah, 3Eh
        MOV bx, outputHan
        INT 21h
    finfin: 
        MOV ax, 4C00h
    INT 21h    
    
    PROC paramCheck
        MOV ch, 0
    	MOV cl, es:[0080h]                         
    	CMP cx, 3        
    	JBE yra                      
    	MOV bx, offset input
    	XOR si, si
    	DEC cx
        infoSearch:
            CMP es:[0082h + si], 20h 
            JNE tasPats              
            MOV bx, offset tmp       
            tasPats:
            MOV al, es:[0082h + si]
            MOV [bx], al
            INC bx
            INC si
        LOOP infoSearch
	    JMP endCheck                                                                	
        yra:
    	MOV ah, 9
    	MOV dx, offset info
    	INT 21h
    	JMP finfin		
    endCheck:
    RET
    ENDP paramCheck
	
	PROC openFile
	    MOV al, 0 
        INT 21h
        JNC ok
        MOV ah, 9                                                                                 
        MOV dx, offset failOpen
        INT 21h
        JMP fin        
        ok:
        MOV [bx], ax    
    RET
	ENDP openFile 
    
    PROC bufToFile ;dx - buferio adresas, cx - buferio ilgis
        MOV bx, outputHan
        MOV ah, 40h
        INT 21h
    RET
    ENDP bufToFile    
            
    PROC readBuffer
        PUSH si
        PUSH ax
        MOV bx, bufferPos 
        MOV si, offset buffer
        CMP bx, bufferSize
        JNE cont
        CALL readFile
        CMP bufferSize, 0
        JE  fin
        cont:
        MOV al, [bx + si]
        MOV inByte, al
        MOV comBufOn, 1
        MOV dl, al
        CALL printHex
        MOV comBufOn, 0
        INC curPos           
        INC bufferPos
        POP ax
        POP si      
    RET
    ENDP readBuffer
    
    PROC readFile
        MOV bx, inputHan
        MOV cx, maxBuffer
        MOV dx, offset buffer
        MOV ah, 3Fh
        INT 21h
        MOV bufferSize, ax
        MOV bufferPos, 0 
        MOV bx, 0
    RET
    ENDP
    
    PROC analyseByte
        MOV ah, inByte
        maybePrefix:
            MOV bx, offset segPrefHex
            MOV si, offset segReg
            MOV cx, 4
            checkPrefix:
                CMP ah, [bx]
                JE prefix
                INC bx
                ADD si, 3
            LOOP checkPrefix
            JMP maybeRet
            prefix:
            MOV segAdr, si
            CALL readBuffer
            MOV ah, inByte
        maybeRet:
            MOV bx, offset retHex
            CALL checkArea
            JE  doRet
            ADD bx, 2
            CALL checkArea
            JNE maybeInt
            LEA si, retVar + 6
            JMP dodoret
            doRet:
            MOV si, offset retVar
            dodoret:
            CALL printUntilBuck
            CMP ah, [bx]
            JNE vsio
            CALL readAndPrintWord
            JMP vsio
        maybeInt:
            MOV bx, offset intHex
            MOV si, offset intVar
            CMP ah, [bx + 1]
            JNE maybeSimpleInt
            MOV dl, 3
            JMP printInt
            maybeSimpleInt:
                CMP ah, [bx]
                JNE maybeSingleWord
                CALL readBuffer
                MOV dl, inByte
            printInt:
                CALL printUntilBuck
                CALL printHex
                JMP vsio                               
        maybeSingleWord:
            MOV bx, offset reg16Hex
            CALL checkArea
            JNE maybeMovImmediateToReg
            MOV si, offset reg16Var
            MOV al, [bx]
            whichCommand:
                MOV cx, 8
                MOV bp, offset regWord
                whichReg16:
                    CMP al, ah
                    JNE cont16Command
                    CALL printUntilBuck
                    MOV si, bp
                    CALL printUntilBuck
                    JMP vsio
                    cont16Command:
                    INC al
                    ADD bp, 3
                LOOP whichReg16
            ADD si, 6
            JMP whichCommand
        maybeMovImmediateToReg:
            MOV bx, offset movRegIHex
            CALL checkArea
            JNE  maybeMovTypical
            MOV si, offset movVar ;iskart aisku kad MOV
            CALL printUntilBuck
            MOV al, [bx]
            MOV si, offset regByte
            whichRegMovIm:
                CMP al, ah
                JNE contMovIm
                CALL printUntilBuck
                CALL printGap
                CMP ah, [bx + 2]
                JB  byteOnly
                CALL readAndPrintWord
                JMP vsio
                byteOnly:
                CALL readAndPrintByte
                endMovIm:
                JMP vsio
                contMovIm:
                INC al
                ADD si, 3
            JMP whichRegMovIm
        maybeMovTypical:
            MOV bx, offset movTypHex
            CALL checkArea
            JNE maybeTypicalFormat
            CMP ah, [bx + si] ;cia lea
            JE  next
            MOV si, offset movVar
            CALL printUntilBuck
            MOV al, [bx + 1]
            SUB al, ah
            CALL analyseModRm 
            CALL setW
            CMP al, 0
            JE movTypSegSwap
            CMP al, 2 
            JE  movTypSeg
            DEC al
            CALL doCompletelyTypical
            JMP vsio
            movTypSeg:
            MOV w, 1
            CALL printPtr
            CALL doRm
            CALL printGap
            MOV bx, offset reg
            CALL printSegByReg
            JMP vsio
            movTypSegSwap:
            MOV w, 1
            MOV bx, offset reg
            CALL printSegByReg
            CALL printGap
            CALL printPtr
            CALL doRm
            JMP vsio            
        maybeTypicalFormat:
            MOV bx, offset regFormHex
            CALL checkArea
            JNE  maybeMovGrp1 
            maybePushPopSegment: ;pirmiausia patikrinu situos, nes sitam area
                MOV bx, offset segPushPop
                MOV cx, 4
                MOV bp, offset segReg
                MOV si, offset pushPopVar
                checkPushPop:
                    CMP ah, [bx]
                    JE  foundPushPop
                    MOV al, [bx]
                    INC al
                    CMP ah, al
                    JE  foundPop
                    ADD bp, 3
                    INC bx
                LOOP checkPushPop
                JMP typical
                foundPop:
                    ADD si, 6        
                foundPushPop:
                    CALL printUntilBuck
                    MOV si, bp
                    CALL printUntilBuck
                    JMP vsio
            typical:
            MOV bx, offset regFormHex
            MOV si, offset regForm
            MOV al, [bx]
            ADD al, 5
            whichTypical:
                CMP ah, al
                JBE foundTypical
                MOV cl, [si]
                ADD al, 8
                ADD si, 6
            JMP whichTypical
            foundTypical:
            CALL printUntilBuck
            CALL setW
            SUB al, ah
            CMP al, 1
            JBE imToA
            CALL analyseModRm 
            CALL doCompletelyTypical
            JMP vsio                       
            ImToA:
            MOV si, offset regByte
            CMP w, 0
            JE  printLuckyByte
            ADD si, 24 ;slykstu? slykstu. paprasta? paprasta. 1:1
            CALL printUntilBuck
            CALL printGap
            CALL readAndPrintWord
            JMP vsio
            printLuckyByte:
            CALL printUntilBuck
            CALL printGap
            CALL readAndPrintByte
            JMP vsio
        maybeMovGrp1:
            MOV bx, offset movGrp1Hex
            CALL checkArea
            JNE maybeGrp1
            MOV si, offset movVar
            CALL printUntilBuck
            CALL setW
            CALL analyseModRm
            JMP grp1LaterPart
        maybeGrp1:
            MOV bx, offset grp1Hex
            CALL checkArea
            JNE maybeMovToA
            CALL setW
            CALL analyseModRm
            MOV si, offset regForm
            MOV bx, offset reg
            MOV ch, 6
            CALL offsetToSi
            grp1LaterPart:
            CALL printPtr
            CALL doRm
            CALL printGap
            CMP ah, 81h ;sitas ima zodi, todel kitoks 
            JE  wordImmediate
            CMP ah, 0C7h ;sitas irgi
            JE  wordImmediate 
            CALL readAndPrintByte  
            JMP vsio
            wordImmediate:
            CALL readAndPrintWord
            JMP vsio
        maybeMovToA:
            MOV bx, offset movAdrAxHex
            CALL checkArea
            JNE maybeGrp345
            CALL setW
            MOV si, offset movVar
            CALL printUntilBuck
            MOV si, offset regByte
            CMP w, 0
            JE  contMovA  
            ADD si, 24
            contMovA:
            CMP ah, [bx + 2]
            JAE swapMovA
            CALL printUntilBuck
            CALL printGap
            CALL doDirectAddress
            JMP vsio
            swapMovA:
            CALL doDirectAddress
            CALL printGap
            CALL printUntilBuck
            JMP vsio
        maybeGrp345:
            MOV bx, offset grp3Hex
            CALL checkArea
            JE ye
            MOV bx, offset grp45Hex
            CALL checkArea
            JNE maybeRelativeCallJump
            ye:
            ADD bx, 2
            MOV si, bx
            CALL setW
            CALL analyseModRm
            MOV bx, offset reg
            MOV ch, 6
            CALL offsetToSi
            CMP reg, 3
            JE  specPtr345
            CMP reg, 5
            JE  specPtr345 
            CALL printPtr
            JMP cont345
            specPtr345:
            PUSH si
            MOV si, offset farPtr
            CALL printUntilBuck
            POP si
            cont345:
            CALL printUntilBuck
            CALL doRm 
            JMP vsio
        maybeRelativeCallJump:
            MOV bx, offset callJmpRHex
            CALL checkArea
            JNE maybeCondJump
            MOV si, offset callJmpVar
            CMP ah, [bx + 1]
            JNE contRelCallJmp
            ADD si, 6
            contRelCallJmp:
            CALL printUntilBuck
            MOV w, 1
            CALL relativeOffset
            JMP vsio
        maybeCondJump:
            MOV bx, offset jumpCondHex
            CALL checkArea
            JNE maybeDifJump
            MOV si, offset jumpCond
            MOV al, [bx]
            whichJump: 
                CMP al, ah
                JNE contJmp
                printJb: ;opkodas ah
                CALL printUntilBuck
                MOV w, 0
                CALL relativeOffset
                JMP vsio
                contJmp:
                INC al
                ADD si, 6 ;nes kas 6 pavadinimai keiciasi
            JMP whichJump
        maybeDifJump:
            MOV bx, offset jumpXtrHex
            MOV si, offset jumpCondXtr
            MOV cx, 3
            checkXtraJmp:
                CMP ah, [bx]
                JE  printJb ;nu negrazu, bet ka db :D
                ADD si, 6
                INC bx
            LOOP checkXtraJmp
        maybePopEv:
            CMP ah, popEvHex
            JNE maybeAbsoluteCallJump
            LEA si, pushPopVar + 6
            CALL printUntilBuck
            MOV w, 1
            CALL analyseModRm
            CALL printPtr
            CALL doRm
            JMP vsio
        maybeAbsoluteCallJump:
            MOV bx, offset callJmpAHex
            MOV si, offset callJmpVar
            CMP ah, [bx]
            JE aCallJmp
            CMP ah, [bx + 1]
            JE aJmp
            JMP next
            aJmp:
                ADD si, 6
            aCallJmp:
                CALL printUntilBuck
                CALL readBuffer
                MOV al, inByte
                CALL readBuffer
                MOV ah, inByte
                PUSH ax
                CALL readAndPrintWord
                MOV si, offset colon
                CALL printUntilBuck
                POP dx
                XCHG dl, dh
                CALL printHex
                MOV dl, dh
                CALL printHex
                JMP vsio                                                        
        next:
            MOV si, offset watafak
            CALL printUntilBuck
    vsio: 
    MOV si, offset newl
    CALL printUntilBuck
    MOV segAdr, 0
    RET
    ENDP analyseByte
    
    PROC printPtr
        CMP mod, 3
        JE  noPtr
        MOV si, offset byteWordPtr
        CMP w, 0
        JE  outputPtr
        ADD si, 10
        outputPtr:
            CALL printUntilBuck
    noPtr:
    RET
    ENDP printPtr
    
    PROC doCompletelyTypical            
        simpleRegular:
            CMP al, 4
            JB  swap
            CALL doRm
            CALL printGap
            MOV bx, offset reg
            CALL printByReg
            JMP endTypical               
        swap:
            MOV bx, offset reg
            CALL printByReg
            CALL printGap
            CALL doRm
            JMP endTypical
    endTypical:    
    RET
    ENDP doCompletelyTypical
    
    PROC doDirectAddress
        PUSH si
        MOV si, offset bracketPlus
        CALL printUntilBuck
        CALL readAndPrintWord
        LEA si, bracketPlus + 2
        CALL printUntilBuck
        POP si
    RET   
    ENDP doDirectAddress
    
    PROC doRm
        CMP segAdr, 0
        JE  noPrefix
        MOV si, segAdr
        CALL printUntilBuck 
        MOV si, offset colon
        CALL printUntilBuck
        noPrefix:
            CMP mod, 3
            JNE directAddress
            MOV bx, offset rm
            CALL printByReg
            JMP doneDoneRm        
        directAddress:
            CMP mod, 0
            JNE simpleRm
            CMP rm, 6
            JNE simpleRm
            CALL doDirectAddress
            JMP doneDoneRm       
        simpleRm:
            MOV si, offset bracketPlus
            CALL printUntilBuck
            MOV si, offset addressName
            MOV bx, offset rm
            MOV ch, 8
            CALL offsetToSi
            CMP mod, 0
            JNE withOffset
            JMP doneRm        
        withOffset:
            LEA si, bracketPlus + 4
            CALL printUntilBuck
            CMP mod, 1
            JNE wOffset
            CALL readAndPrintByte
            JMP doneRm                    
            wOffset:
            CALL readAndPrintWord
            JMP doneRm
    doneRm:
        LEA si, bracketPlus + 2
        CALL printUntilBuck
    doneDoneRm:
    RET
    ENDP doRm
    
    PROC printSegByReg ;reg adresas - bx
        MOV si, offset segReg
        MOV ch, 3
        CALL offsetToSi
    RET
    ENDP printSegByReg
    
    PROC printByReg ;reg adresas - bx
        MOV si, offset regByte
        CMP w, 1
        JNE printByRegCont
        ADD si, 24 
        printByRegCont:
        MOV ch, 3
        CALL offsetToSi
    RET
    ENDP printByReg
    
    PROC offsetToSi ;is ko daugint ch, ka daugint [bx]
        PUSH ax
        MOV al, [bx]
        MUL ch
        ADD si, ax
        POP ax
        CALL printUntilBuck
    RET
    ENDP offsetToSi 
     
    PROC analyseModRm
        PUSH ax
        CALL readBuffer
        MOV ah, inByte
        AND ah, 11000000b
        SHR ah, 6
        MOV mod, ah
        MOV ah, inByte
        AND ah, 00111000b
        SHR ah, 3
        MOV reg, ah
        MOV ah, inByte
        AND ah, 00000111b
        MOV rm, ah
        POP ax
    RET
    ENDP analyseModRm
    
    PROC checkArea ;rezio pradzios adresas bx
        CMP ah, [bx]
        JB  doesNotBelong
        CMP ah, [bx + 1]
        JA  doesNotBelong
        CMP ah, ah    
    doesNotBelong:
    RET
    ENDP checkArea
        
    PROC setW
        PUSH ax
        MOV w, 0
        SHR ah, 1
        JNC wDone
        INC w         
    wDone:
    POP ax    
    RET
    ENDP setW
        
    PROC readAndPrintWord
        PUSH dx
        CALL readBuffer
        MOV dh, inByte
        MOV tmp, dh
        CALL readAndPrintByte
        MOV dl, tmp
        CALL printHex
        POP dx
    RET
    ENDP readAndPrintWord
    
    PROC readAndPrintByte
        CALL readBuffer
        MOV dl, inByte                    
        CALL printHex        
    RET
    ENDP readAndPrintByte
        
    PROC printUntilBuck ;pavadinimo adresas jau si
        PUSH ax
        MOV di, offset resBuf
        ADD di, resBufL 
        printTxt:
            CMP [si], '$'
            JE doneTxt
            MOV ah, [si]
            MOV [di], ah
            INC si
            INC di
            INC resBufL
        JMP printTxt
        doneTxt:
        POP ax
     RET
     ENDP printUntilBuck
                    
     PROC relativeOffset ;grazins i bx
        PUSH ax
        CALL readBuffer
        MOV al, inByte
        CMP w, 0
        JE byte
        CALL readBuffer
        MOV ah, inByte
        byte:
            CBW
        both:
            MOV bx, curPos
            ADD bx, ax
            MOV dl, bh
            CALL printHex
            MOV dl, bl
            CALL printHex       
     POP ax
     RET
     ENDP relativeOffset
     
     PROC printHex ;tarkim, kad baitas registre dl
        PUSH ax
        PUSH dx
        MOV dh, dl
        AND dl, 11110000b
        SHR dl, 4
        CALL printHalfByte
        AND dh, 00001111b
        MOV dl, dh
        CALL printHalfByte
        POP dx
        POP ax
     RET
     ENDP printHex

     PROC printHalfByte
        ADD dl, 30h
        CMP dl, 39h
        JBE notLetter
        ADD dl, 7
        notLetter:
            CMP comBufOn, 1
            JNE printResByte
            MOV ax, comBufL
            MOV di, offset comBuf
            INC comBufL
            JMP bothBufs
            printResByte:
            MOV ax, resBufL
            MOV di, offset resBuf
            INC resBufL
            bothBufs:
            ADD di, ax
            MOV [di], dl
     RET
     ENDP printHalfByte
     
     PROC printGap
        PUSH si
        MOV si, offset operandGap
        CALL printUntilBuck
        POP si
     RET
     ENDP printGap        
END vazhiojam