.MODEL SMALL
.STACK 100H

.DATA 
    ; 4x4 tahta icin 16 kartin gizli degerleri 
    gizli_kartlar DB 'A', 'B', 'C', 'D'
                  DB 'E', 'F', 'G', 'H'
                  DB 'D', 'C', 'B', 'A'
                  DB 'H', 'G', 'F', 'E' 
                  
    ; Ekranda gosterilen kart durumu: '*' = kapali, harf = acik
    acik_kartlar  DB 16 DUP('*')

    hamle_sayisi  DB 10
    kalan_sure    DB 60
    eslesen_cift  DB 0
    
    ; Secilen kartlarin tahta indeksleri (0-15 arasi)
    idx1          DB ?
    idx2          DB ?

    ; INT 21H , AH=2CH ile okunan sistem saatinin saniye degeri burada tutulur.
    ; Her saniye degisiminde kalan_sure bir azaltilir.
    son_saniye    DB ?
    imlec_satir   DB ?
    imlec_sutun   DB ?

    msg_baslik    DB 10, 13, '============ BELLEK OYUNU =============$'
    msg_stats     DB 10, 13, 'KALAN HAMLE: $'
    msg_time      DB '  |  KALAN SURE: $'
    msg_secim1    DB '1. Kart (0-F): $'
    msg_secim2    DB '2. Kart (0-F): $'
    msg_hata      DB 'Gecersiz! $'
    msg_yanlis    DB 'ESLESMEDI! (-5 Saniye)$'
    msg_dogru     DB 'TEBRIKLER! ESLESTI.$'
    msg_kazandin  DB 'TEBRIKLER! KAZANDINIZ.$'
    msg_kaybettin DB 'KAYBETTIN! YENIDEN DENE.$'
    msg_devam     DB 'Devam etmek icin bir tusa bas...$'
    msg_tekrar    DB 'Tekrar oynamak icin E, cikmak icin baska tusa basin...$'
     
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
    
    CALL EKRANI_TEMIZLE

    LEA DX, msg_baslik        ; Baslik bir kez yazilir
    MOV BL, 0BH
    CALL PRINT_STR_RENKLI

    LEA DX, msg_stats         ; "KALAN HAMLE:" etiketi 
    MOV BL, 07H
    CALL PRINT_STR_RENKLI

    LEA DX, msg_time          ; "KALAN SURE:" etiketi 
    MOV BL, 07H
    CALL PRINT_STR_RENKLI

    CALL TAHTAYI_YAZDIR       ; Tahta bir kez cizilir
    
                          
ANA_DONGU: 

    ; Kazanma kaybetme kontrolu 8 cift eslesti mi, sure bitti mi?
    CMP eslesen_cift, 8
    JE KAZANDIN
    CMP hamle_sayisi, 0
    JLE KAYBETTIN
    CMP kalan_sure, 0
    JLE KAYBETTIN

    CALL STATS_GUNCELLE        ; Sadece sayilari guncelle
    CALL TAHTAYI_YAZDIR        ; Tahtayi ustune yaz
    CALL MESAJ_ALANI_TEMIZLE   ; Alt mesaj satirini temizle

;1. KART SECIMI
SEC1:
    MOV AH, 02H        ; cursor'i satir 11'e gotur
    MOV BH, 0
    MOV DH, 11
    MOV DL, 0
    INT 10H
    LEA DX, msg_secim1
    MOV BL, 0EH 
    CALL PRINT_STR_RENKLI
    
    
    CALL KARAKTER_OKU    ; Klavyeden karakter oku
    CALL INDEKSE_CEVIR   ; '0'-'9' veya 'A'-'F' girisi 0-15 indeksine cevir
    CMP AH, 1            ; AH=1 ise gecersiz giris
    JE SEC1_HATA 
    
    ; Secilen kartin kapali olup olmadigini kontrol et 
    MOV BL, AL
    MOV BH, 0
    CMP acik_kartlar[BX], '*'
    JNE SEC1_HATA
    
    ; Karti ac: indeksi kaydet, gizli degeri acik_kartlar dizisine yaz
    MOV idx1, AL
    MOV SI, BX
    MOV AL, gizli_kartlar[SI]
    MOV acik_kartlar[SI], AL
    
    CALL TAHTAYI_YAZDIR     ; Aciilan karti tahtada goster

SEC2:
    MOV AH, 02H        ; cursor'i satir 11'e gotur
    MOV BH, 0
    MOV DH, 11
    MOV DL, 0
    INT 10H
    LEA DX, msg_secim2
    MOV BL, 0EH 
    CALL PRINT_STR_RENKLI
    CALL KARAKTER_OKU
    CALL INDEKSE_CEVIR
    CMP AH, 1
    JE SEC2_HATA 
    
    ; Ayni karti iki kez secmeyi engelle
    CMP AL, idx1
    JE SEC2_HATA
    
    ; Secilen kartin kapali olup olmadigini kontrol et
    MOV BL, AL
    MOV BH, 0
    CMP acik_kartlar[BX], '*'
    JNE SEC2_HATA
    
    ; Karti ac
    MOV idx2, AL
    MOV DI, BX
    MOV AL, gizli_kartlar[DI]
    MOV acik_kartlar[DI], AL
    
    CALL TAHTAYI_YAZDIR  ; Ikinci acilan karti tahtada goster
    
    ; ---- ESLESME KONTROLU ----

    DEC hamle_sayisi     ; Her iki kart secildiginde 1 hamle harcan
    
    ; SI ve DI ile iki kartin gizli degerlerini karsilastir
    MOV BL, idx1
    MOV BH, 0
    MOV SI, BX
    
    MOV BL, idx2
    MOV BH, 0
    MOV DI, BX
    MOV AL, gizli_kartlar[SI]
    MOV AH, gizli_kartlar[DI]
    
    CMP AL, AH
    JE ESLESME_TAMAM   ; Degerler esitse eslesme basarili
    
    ; ---- ESLESME BASARISIZ ----
    MOV AH, 02H        
    MOV BH, 0
    MOV DH, 11
    MOV DL, 0
    INT 10H
    LEA DX, msg_yanlis
    MOV BL, 0CH
    CALL PRINT_STR_RENKLI 
    
    ; Kartlari tekrar kapat 
    MOV acik_kartlar[SI], '*'
    MOV acik_kartlar[DI], '*' 
    
    ; Ceza: Sureden 5 saniye dus (sure 5'ten az ise sifirla)
    CMP kalan_sure, 5
    JB SURE_SIFIRLA
    SUB kalan_sure, 5
    JMP BEKLE_VE_DEVAM

SURE_SIFIRLA:
    MOV kalan_sure, 0
    JMP BEKLE_VE_DEVAM
    
    
; ---- ESLESME BASARILI ----
ESLESME_TAMAM:
    INC eslesen_cift ; Bulunan cift sayisini artir
    
    MOV AH, 02H        ; cursor'i satir 11'e gotur
    MOV BH, 0
    MOV DH, 11
    MOV DL, 0
    INT 10H
    LEA DX, msg_dogru
    MOV BL, 0AH
    CALL PRINT_STR_RENKLI 
    
; ---- HAMLE SONU: TUS BEKLE ----    
BEKLE_VE_DEVAM:
    MOV AH, 02H        
    MOV BH, 0
    MOV DH, 12
    MOV DL, 0
    INT 10H
    LEA DX, msg_devam
    MOV BL, 0FH
    CALL PRINT_STR_RENKLI
    
    ;Herhangi bir tusa basilana kadar bekle (INT 21H / AH=07H)
    MOV AH, 07H
    INT 21H
    JMP ANA_DONGU

SEC1_HATA:
    MOV AH, 02H        
    MOV BH, 0
    MOV DH, 11
    MOV DL, 0
    INT 10H
    LEA DX, msg_hata
    MOV BL, 0CH 
    CALL PRINT_STR_RENKLI
    JMP SEC1

SEC2_HATA:
    MOV AH, 02H        
    MOV BH, 0
    MOV DH, 11
    MOV DL, 0
    INT 10H
    LEA DX, msg_hata
    MOV BL, 0CH 
    CALL PRINT_STR_RENKLI
    JMP SEC2

KAZANDIN:
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 11
    MOV DL, 0
    INT 10H
    LEA DX, msg_kazandin
    MOV BL, 0AH 
    CALL PRINT_STR_RENKLI
    JMP OYUN_SONU
KAYBETTIN:
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 11
    MOV DL, 0
    INT 10H
    LEA DX, msg_kaybettin
    MOV BL, 0CH 
    CALL PRINT_STR_RENKLI

OYUN_SONU:
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 12
    MOV DL, 0
    INT 10H
    LEA DX, msg_tekrar    ; Oyuncuya tekrar oynama secenegi sun
    MOV BL, 0EH
    CALL PRINT_STR_RENKLI 
    
    ; INT 16H / AH=00H ile tus beklenir, AL'ye karakter gelir
    MOV AH, 00H
    INT 16H              ; Tusa basilmasini bekle
    
    CMP AL, 'e'          ; 'e' ye basildi mi
    JE YENIDEN_BASLAT
    CMP AL, 'E'
    JE YENIDEN_BASLAT
    JMP CIKIS            ; Baska tus = cikis

YENIDEN_BASLAT:
    ; Degiskenleri sifirla
    MOV hamle_sayisi, 10
    MOV kalan_sure, 60
    MOV eslesen_cift, 0
    
    ; Tum kartlari kapat
    MOV CX, 16
    MOV SI, 0
KAPAT_DONGU:
    MOV acik_kartlar[SI], '*'
    INC SI
    LOOP KAPAT_DONGU
    
    ; Zamanlayiciyi sifirla
    MOV AH, 2CH
    INT 21H
    MOV son_saniye, DH
    
    ; Ekrani yeniden hazirla
    CALL EKRANI_TEMIZLE
    LEA DX, msg_baslik
    MOV BL, 0BH
    CALL PRINT_STR_RENKLI
    LEA DX, msg_stats
    MOV BL, 07H
    CALL PRINT_STR_RENKLI
    LEA DX, msg_time
    MOV BL, 07H
    CALL PRINT_STR_RENKLI
    CALL TAHTAYI_YAZDIR
    JMP ANA_DONGU

CIKIS:
    MOV AH, 4CH
    INT 21H
MAIN ENDP 


; YARDIMCI FONKSIYONLAR 

; Tek bir karakteri BIOS'un INT 10H / AH=09H fonksiyonu ile
; BL registerindaki renkte ekrana yazar, ardindan cursoru bir sag kaydirir
; Girdi : AL = karakter, BL = renk kodu
RENKLI_YAZ PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, 09H       ; Karakter + renk yaz
    MOV BH, 0          ; Sayfa 0
    MOV CX, 1         ; 1 kez yazar
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


;'$' ile biten bir string'i BL rengiyle ekrana yazar.
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


; AL registerindaki 0-99 araligindaki sayiyi iki basamakli olarak ekrana yazar 
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
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV SI, 0
    MOV DI, 0        
    
TAHTA_SATIR_HESAPLA:
    MOV AX, SI        
    MOV BL, 4
    DIV BL            
    
    ADD AL, 4         
    MOV DH, AL
    MOV AL, AH
    SHL AL, 1         
    MOV DL, AL
    
    MOV AH, 02H
    MOV BH, 0
    INT 10H          
    
    MOV AL, acik_kartlar[SI]
    CMP AL, '*'
    JE KAPALI_K
    MOV BL, 0AH
    JMP YAZ_K
KAPALI_K:
    MOV BL, 79H
YAZ_K:
    CALL RENKLI_YAZ
    
    INC SI
    CMP SI, 16
    JNE TAHTA_SATIR_HESAPLA

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
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


    LEA DX, msg_karti
    MOV BL, 0FH
    CALL PRINT_STR_RENKLI

    ; Gelistiren kismini 
    LEA DX, msg_isim
    MOV BL, 08H
    CALL PRINT_STR_RENKLI

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


; Klavyeden bir karakter okur. Tus bekleme sirasinda her saniye INT 21H / AH=2CH ile sistem saatini kontrol eder; saniye
; degistiyse kalan_sure'yi bir azaltir ve ekrandaki sure sayisini
; gunceller. Sure sifira ulasirsa KAYBETTIN etiketine atlar.
KARAKTER_OKU PROC
BEKLE_TUS:
    MOV AH, 01H
    INT 16H
    JNZ TUS_AL
      
    ;Tus yokken sistem saatini oku
    MOV AH, 2CH
    INT 21H
    CMP DH, son_saniye
    JE BEKLE_TUS 
    
    ;Saniye degisir zamanlayiciyi guncelle
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
    MOV DL, 29
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

STATS_GUNCELLE PROC
    PUSH AX
    PUSH BX
    PUSH DX
    
    ;HAMLE SAYISINI GUNCELLE
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 2        
    MOV DL, 14        
    INT 10H
    
    MOV AL, hamle_sayisi
    MOV BL, 0AH
    CALL SAYI_YAZDIR
    
    ;KALAN SUREYI GUNCELLE
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 2
    MOV DL, 29       
    INT 10H
    
    MOV AL, kalan_sure
    MOV BL, 0EH
    CMP AL, 10
    JAE SURE_OK
    MOV BL, 0CH
SURE_OK:
    CALL SAYI_YAZDIR
    
    POP DX
    POP BX
    POP AX
    RET
STATS_GUNCELLE ENDP

MESAJ_ALANI_TEMIZLE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Satir 10'dan 15'e kadar boslukla doldur
    MOV DH, 10
SATIR_DONGU:
    MOV DL, 0
    MOV AH, 02H
    MOV BH, 0
    INT 10H          
    
    MOV CX, 80       
    MOV AL, ' '
    MOV BL, 07H
    MOV AH, 09H
    INT 10H
    
    INC DH
    CMP DH, 16
    JL SATIR_DONGU
    
    ; Cursori mesaj alanina birakir
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 10
    MOV DL, 0
    INT 10H
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MESAJ_ALANI_TEMIZLE ENDP 


;Klavyeden okunan hex karakterini0-15 araliginda bir indekse donusturur
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
