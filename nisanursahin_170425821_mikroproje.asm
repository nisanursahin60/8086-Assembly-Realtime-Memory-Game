.MODEL SMALL
.STACK 100H

.DATA
    gizli_kartlar DB 'A', 'B', 'C', 'D'
                  DB 'E', 'F', 'G', 'H'
                  DB 'D', 'C', 'B', 'A'
                  DB 'H', 'G', 'F', 'E'

    acik_kartlar  DB 16 DUP('*')

    hamle_sayisi  DB 10
    kalan_sure    DB 60
    eslesen_cift  DB 0
    idx1          DB ?
    idx2          DB ?

    ; TIMER ICIN DEGISKENLER
    ; Gercek zamanli sayacç icin isletim sisteminden aldigimiz saniye verisini burada tutuyoruz
    son_saniye    DB ?
    imlec_satir   DB ?
    imlec_sutun   DB ?

    msg_baslik    DB 10, 13, '============ BELLEK OYUNU =============$'
    msg_stats     DB 10, 13, 'KALAN HAMLE: $'
    msg_time      DB '  |  KALAN SURE: $'
    msg_secim1    DB 10, 13, '1. Kart (0-F): $'
    msg_secim2    DB 10, 13, '2. Kart (0-F): $'
    msg_hata      DB 10, 13, 'Gecersiz! $'
    msg_yanlis    DB 10, 13, 'ESLESMEDI! (-5 Saniye)$'
    msg_dogru     DB 10, 13, 'TEBRIKLER! ESLESTI.$'
    msg_kazandin  DB 10, 13, 'TEBRIKLER! KAZANDINIZ.$'
    msg_kaybettin DB 10, 13, 'KAYBETTIN! YENIDEN DENE.$'
    msg_devam     DB 10, 13, 'Devam etmek icin bir tusa bas...$' 
    ; --- BASLANGIC EKRANI METINLERI ---
    logo1 DB 10,10,10,10,10, '                   ',219,'    ',219,'   ',219,'',219,'   ',219,'',219,'',219,'',219,'',219,'',219,'  ',219,'  ',219,'',219,'',219,'',219,'',219,'',219,'   ',219,'',219,'   $'
    logo2 DB 10,13,          '                   ',219,'    ',219,'  ',219,'  ',219,'  ',219,'       ',219,'      ',219,'   ',219,'  ',219,'  $'
    logo3 DB 10,13,          '                   ',219,'',219,'',219,'',219,'',219,'',219,' ',219,'    ',219,' ',219,'',219,'',219,'',219,'',219,'   ',219,'    ',219,'    ',219,'    ',219,' $'
    logo4 DB 10,13,          '                   ',219,'    ',219,' ',219,'',219,'',219,'',219,'',219,'',219,' ',219,'       ',219,'   ',219,'     ',219,'',219,'',219,'',219,'',219,'',219,' $'
    logo5 DB 10,13,          '                   ',219,'    ',219,' ',219,'    ',219,' ',219,'       ',219,'  ',219,'',219,'',219,'',219,'',219,'',219,' ',219,'    ',219,' $'
    
    msg_karti     DB 10,13,10,13, '                                KARTI OYUNU$'
    msg_isim      DB 10,13,10,13, '                     Gelistiren: Nisanur Sahin ', 2, '$'
    msg_press_key DB 10,13,10,13,10,13, '               Oyuna baslamak icin herhangi bir tusa basin...$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    CALL BASLANGIC_EKRANI

    ; --- GERCEK ZAMANLAYICI BASLATICISI ---
    ; DOS kesmesi (INT 21H, AH=2CH) ile sistem saatini okuyoruz
    ; DH registerindaki saniye degerini referans olarak kaydediyoruz
    MOV AH, 2CH
    INT 21H
    MOV son_saniye, DH
    
                          
ANA_DONGU: 
;Her dongu basinda oyunun bitip bitmedigini kontrol ediyoruz
    CMP eslesen_cift, 8
    JE KAZANDIN
    CMP hamle_sayisi, 0
    JLE KAYBETTIN
    CMP kalan_sure, 0
    JLE KAYBETTIN

    CALL EKRANI_TEMIZLE
    
    ; Baslik (Camgobegi)
    LEA DX, msg_baslik
    MOV BL, 0BH 
    CALL PRINT_STR_RENKLI
    
    ; Istatistikler
    LEA DX, msg_stats
    MOV BL, 07H 
    CALL PRINT_STR_RENKLI
    MOV AL, hamle_sayisi
    MOV BL, 0AH 
    CALL SAYI_YAZDIR
    
    ; Zamanlayici
    ; Sure 10 saniyenin altina dustugunde oyuncuyu uyarmak icin rengi saridan kirmiziya (0CH) ceviriyoruz.
    LEA DX, msg_time
    MOV BL, 07H 
    CALL PRINT_STR_RENKLI
    MOV AL, kalan_sure
    MOV BL, 0EH      ; Sari
    CMP AL, 10
    JAE SURE_RENGI_TAMAM
    MOV BL, 0CH      ; 10 Saniyenin altinda Kirmizi
SURE_RENGI_TAMAM:
    CALL SAYI_YAZDIR
    
   
    CALL TAHTAYI_YAZDIR

    ;1. KART SECIMI
SEC1:
    LEA DX, msg_secim1
    MOV BL, 0EH 
    CALL PRINT_STR_RENKLI
    CALL KARAKTER_OKU
    CALL INDEKSE_CEVIR
    CMP AH, 1
    JE SEC1_HATA 
    
    
    ;Secilen kartin daha once acilip acilmadigina maske dizisinden ('*') kontrol ediyoruz
    MOV BL, AL
    MOV BH, 0
    CMP acik_kartlar[BX], '*'
    JNE SEC1_HATA
    
    MOV idx1, AL
    MOV SI, BX
    MOV AL, gizli_kartlar[SI]
    MOV acik_kartlar[SI], AL
    
    CALL EKRANI_TEMIZLE
    CALL TAHTAYI_YAZDIR

    ; 2. KART SECIMI
SEC2:
    LEA DX, msg_secim2
    MOV BL, 0EH 
    CALL PRINT_STR_RENKLI
    CALL KARAKTER_OKU
    CALL INDEKSE_CEVIR
    CMP AH, 1
    JE SEC2_HATA
    CMP AL, idx1
    JE SEC2_HATA
    
    MOV BL, AL
    MOV BH, 0
    CMP acik_kartlar[BX], '*'
    JNE SEC2_HATA
    
    MOV idx2, AL
    MOV DI, BX
    MOV AL, gizli_kartlar[DI]
    MOV acik_kartlar[DI], AL
    
    CALL EKRANI_TEMIZLE
    CALL TAHTAYI_YAZDIR

    ; --- KARSILASTIRMA --- 
    ; Secilen iki indeksteki (SI ve DI) degerleri karsilastriyoruz.
    DEC hamle_sayisi 

    MOV BL, idx1
    MOV BH, 0
    MOV SI, BX
    
    MOV BL, idx2
    MOV BH, 0
    MOV DI, BX

    MOV AL, gizli_kartlar[SI]
    MOV AH, gizli_kartlar[DI]
    
    CMP AL, AH
    JE ESLESME_TAMAM
    
    
    ;Eslesme basarisizsa ceza olarak sureden 5 saniye dusuuryoruz
    LEA DX, msg_yanlis
    MOV BL, 0CH ; Kirmizi
    CALL PRINT_STR_RENKLI
    MOV acik_kartlar[SI], '*'
    MOV acik_kartlar[DI], '*'
    
    CMP kalan_sure, 5
    JB SURE_SIFIRLA
    SUB kalan_sure, 5
    JMP BEKLE_VE_DEVAM

SURE_SIFIRLA:
    MOV kalan_sure, 0
    JMP BEKLE_VE_DEVAM

ESLESME_TAMAM:
    INC eslesen_cift
    LEA DX, msg_dogru
    MOV BL, 0AH ; Yesil
    CALL PRINT_STR_RENKLI

BEKLE_VE_DEVAM:
    LEA DX, msg_devam
    MOV BL, 0FH ; Beyaz
    CALL PRINT_STR_RENKLI
    MOV AH, 07H
    INT 21H
    JMP ANA_DONGU

SEC1_HATA:
    LEA DX, msg_hata
    MOV BL, 0CH 
    CALL PRINT_STR_RENKLI
    JMP SEC1
SEC2_HATA:
    LEA DX, msg_hata
    MOV BL, 0CH 
    CALL PRINT_STR_RENKLI
    JMP SEC2

KAZANDIN:
    LEA DX, msg_kazandin
    MOV BL, 0AH 
    CALL PRINT_STR_RENKLI
    JMP CIKIS
KAYBETTIN:
    LEA DX, msg_kaybettin
    MOV BL, 0CH 
    CALL PRINT_STR_RENKLI

CIKIS:
    MOV AH, 4CH
    INT 21H
MAIN ENDP

; YARDIMCI FONKSIYONLAR

; TEKLI KARAKTER YAZDIRMA 
RENKLI_YAZ PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, 09H
    MOV BH, 0     
    MOV CX, 1
    INT 10H
    
   
    MOV AH, 03H
    MOV BH, 0
    INT 10H
    INC DL
    CMP DL, 80
    JB IMLEC_KAYDIR
    MOV DL, 0
    INC DH
IMLEC_KAYDIR:
    MOV AH, 02H
    MOV BH, 0
    INT 10H
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
RENKLI_YAZ ENDP

PRINT_STR_RENKLI PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    MOV SI, DX
    ; Baslangic kursorunu 1 kez al
    MOV AH, 03H
    MOV BH, 0
    INT 10H       
    
STR_DONGU:
    MOV AL, [SI]
    CMP AL, '$'
    JE STR_BITIR
    
    CMP AL, 10
    JE STR_YENI_SATIR
    CMP AL, 13
    JE STR_SATIR_BASI
    
    ; Karakteri Rengiyle Birlikte Bas
    MOV AH, 09H
    MOV BH, 0
    MOV CX, 1
    INT 10H
    
    ; Kursoru manuel hesaplayarak hiz kazan
    INC DL
    CMP DL, 80
    JB KURSOR_SET
    MOV DL, 0
    INC DH
    JMP KURSOR_SET
    
STR_YENI_SATIR:
    INC DH
    JMP KURSOR_SET
    
STR_SATIR_BASI:
    MOV DL, 0
    
KURSOR_SET:
    MOV AH, 02H
    MOV BH, 0
    INT 10H
    
    INC SI
    JMP STR_DONGU
    
STR_BITIR:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_STR_RENKLI ENDP

SAYI_YAZDIR PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV AH, 0
    MOV CL, 10
    DIV CL      
    MOV DL, AL
    MOV DH, AH  
    
    MOV AL, DL
    ADD AL, '0'
    CALL RENKLI_YAZ  
    
    MOV AL, DH
    ADD AL, '0'
    CALL RENKLI_YAZ  
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SAYI_YAZDIR ENDP


TAHTAYI_YAZDIR PROC
    PUSH CX
    PUSH BX
    PUSH DX
    PUSH DI       ; 
    MOV CX, 16
    MOV SI, 0
    MOV DI, 0     
    
    MOV DL, 10
    MOV AH, 02H
    INT 21H
    MOV DL, 13
    INT 21H

YAZ_DONGU:
    MOV AL, acik_kartlar[SI]
    CMP AL, '*'
    JE KAPALI_KART
    MOV BL, 0AH   ; Yesil
    JMP KART_YAZ
KAPALI_KART:
    MOV BL, 79H   ; Acik Mavi
KART_YAZ:
    CALL RENKLI_YAZ
    
    MOV AL, ' '
    MOV BL, 07H
    CALL RENKLI_YAZ
    
    INC SI
    INC DI        ; Satirda kac kart bastigimizi sayiyoruz
    CMP DI, 4     
    JNE ATLA
    
    ; Eger 4 karta ulasildiysa alti satira gec
    MOV DL, 10 
    MOV AH, 02H
    INT 21H
    MOV DL, 13
    INT 21H
    MOV DI, 0     ; Sayaci sifirla
ATLA:
    LOOP YAZ_DONGU
    
    POP DI
    POP DX
    POP BX
    POP CX
    RET
TAHTAYI_YAZDIR ENDP

EKRANI_TEMIZLE PROC
    MOV AX, 0003H
    INT 10H
    RET
EKRANI_TEMIZLE ENDP 

BASLANGIC_EKRANI PROC
    PUSH AX
    PUSH BX
    PUSH DX

    CALL EKRANI_TEMIZLE

    
    LEA DX, logo1
    MOV BL, 0BH
    CALL PRINT_STR_RENKLI
    LEA DX, logo2
    MOV BL, 0BH
    CALL PRINT_STR_RENKLI
    LEA DX, logo3
    MOV BL, 0BH
    CALL PRINT_STR_RENKLI
    LEA DX, logo4
    MOV BL, 0BH
    CALL PRINT_STR_RENKLI
    LEA DX, logo5
    MOV BL, 0BH
    CALL PRINT_STR_RENKLI

    ; KARTI OYUNU alt basligini Beyaz (0FH) ile bas
    LEA DX, msg_karti
    MOV BL, 0FH
    CALL PRINT_STR_RENKLI

    ; Gelistiren kismini Koyu Gri (08H) veya Sari (0EH) ile bas
    LEA DX, msg_isim
    MOV BL, 08H
    CALL PRINT_STR_RENKLI

    ; Tus bekleme yazisini Yanip Sonen Sari (8EH) ile bas
    ; (8 bitlik renk kodunda en bastaki biti 1 yapmak yaziyi yanip sondurur)
    LEA DX, msg_press_key
    MOV BL, 8EH
    CALL PRINT_STR_RENKLI

    ; Herhangi bir tusa basilmasini bekler (INT 16H, AH=00H)
    MOV AH, 00H
    INT 16H

    POP DX
    POP BX
    POP AX
    RET
BASLANGIC_EKRANI ENDP

KARAKTER_OKU PROC
BEKLE_TUS:
    MOV AH, 01H
    INT 16H
    JNZ TUS_AL  

    MOV AH, 2CH
    INT 21H
    CMP DH, son_saniye
    JE BEKLE_TUS 

    MOV son_saniye, DH
    CMP kalan_sure, 0
    JLE ZAMAN_DOLDU
    DEC kalan_sure

    MOV AH, 03H
    MOV BH, 0
    INT 10H
    MOV imlec_satir, DH
    MOV imlec_sutun, DL

    MOV AH, 02H
    MOV BH, 0
    MOV DH, 2
    MOV DL, 32
    INT 10H

    MOV AL, kalan_sure
    MOV BL, 0EH     
    CMP AL, 10
    JAE RENK_AYARLANDI
    MOV BL, 0CH     
RENK_AYARLANDI:
    CALL SAYI_YAZDIR

    MOV AH, 02H
    MOV BH, 0
    MOV DH, imlec_satir
    MOV DL, imlec_sutun
    INT 10H

    JMP BEKLE_TUS 

ZAMAN_DOLDU:
    POP AX 
    JMP KAYBETTIN

TUS_AL:
    MOV AH, 00H
    INT 16H
    
    PUSH AX
    PUSH BX
    MOV BL, 0FH 
    CALL RENKLI_YAZ
    POP BX
    POP AX
    RET
KARAKTER_OKU ENDP

INDEKSE_CEVIR PROC
    MOV AH, 0
    CMP AL, '0'
    JB HATA_IND
    CMP AL, '9'
    JBE RAKAM
    CMP AL, 'A'
    JB HATA_IND
    CMP AL, 'F'
    JBE B_HARF
    CMP AL, 'a'
    JB HATA_IND
    CMP AL, 'f'
    JBE K_HARF
HATA_IND:
    MOV AH, 1
    RET
RAKAM: SUB AL, 48
    RET
B_HARF: SUB AL, 55
    RET
K_HARF: SUB AL, 87
    RET
INDEKSE_CEVIR ENDP

END MAIN