      *****************************************************************
      * HISTORY RECORD STRUCTURE
      * VERSION: 1.0
      * DATE: 2024
      *****************************************************************
       01  HISTORY-RECORD.
           05  HIST-KEY.
               10  HIST-PORTFOLIO-ID  PIC X(08).
               10  HIST-DATE         PIC X(08).
               10  HIST-TIME         PIC X(06).
               10  HIST-SEQ-NO       PIC X(04).
           05  HIST-DATA.
               10  HIST-RECORD-TYPE  PIC X(02).
                   88  HIST-TYPE-PORT    VALUE 'PT'.
                   88  HIST-TYPE-POS     VALUE 'PS'.
                   88  HIST-TYPE-TRN     VALUE 'TR'.
               10  HIST-ACTION-CODE  PIC X(01).
                   88  HIST-ACTION-ADD   VALUE 'A'.
                   88  HIST-ACTION-CHG   VALUE 'C'.
                   88  HIST-ACTION-DEL   VALUE 'D'.
               10  HIST-BEFORE-IMAGE PIC X(400).
               10  HIST-AFTER-IMAGE  PIC X(400).
               10  HIST-REASON-CODE  PIC X(04).
           05  HIST-AUDIT.
               10  HIST-PROCESS-DATE PIC X(26).
               10  HIST-PROCESS-USER PIC X(08).
           05  HIST-FILLER          PIC X(50).
      *****************************************************************
      * FIELD DESCRIPTIONS:
      * HIST-PORTFOLIO-ID: PORTFOLIO IDENTIFIER
      * HIST-DATE        : HISTORY DATE (YYYYMMDD)
      * HIST-TIME        : HISTORY TIME (HHMMSS)
      * HIST-SEQ-NO      : SEQUENCE NUMBER
      * HIST-RECORD-TYPE : PT=PORTFOLIO, PS=POSITION, TR=TRANSACTION
      * HIST-ACTION-CODE : A=ADD, C=CHANGE, D=DELETE
      * HIST-BEFORE-IMAGE: RECORD IMAGE BEFORE CHANGE
      * HIST-AFTER-IMAGE : RECORD IMAGE AFTER CHANGE
      * HIST-REASON-CODE : REASON FOR CHANGE
      ***************************************************************** 