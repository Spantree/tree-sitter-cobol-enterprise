      *****************************************************************
      * TRANSACTION RECORD STRUCTURE
      * VERSION: 1.0
      * DATE: 2024
      *****************************************************************
       01  TRANSACTION-RECORD.
           05  TRN-KEY.
               10  TRN-DATE           PIC X(08).
               10  TRN-TIME           PIC X(06).
               10  TRN-PORTFOLIO-ID   PIC X(08).
               10  TRN-SEQUENCE-NO    PIC X(06).
           05  TRN-DATA.
               10  TRN-INVESTMENT-ID  PIC X(10).
               10  TRN-TYPE           PIC X(02).
                   88  TRN-TYPE-BUY     VALUE 'BU'.
                   88  TRN-TYPE-SELL    VALUE 'SL'.
                   88  TRN-TYPE-TRANS   VALUE 'TR'.
                   88  TRN-TYPE-FEE     VALUE 'FE'.
               10  TRN-QUANTITY       PIC S9(11)V9(4) COMP-3.
               10  TRN-PRICE         PIC S9(11)V9(4) COMP-3.
               10  TRN-AMOUNT        PIC S9(13)V9(2) COMP-3.
               10  TRN-CURRENCY      PIC X(03).
               10  TRN-STATUS        PIC X(01).
                   88  TRN-STATUS-PEND   VALUE 'P'.
                   88  TRN-STATUS-DONE   VALUE 'D'.
                   88  TRN-STATUS-FAIL   VALUE 'F'.
                   88  TRN-STATUS-REV    VALUE 'R'.
           05  TRN-AUDIT.
               10  TRN-PROCESS-DATE  PIC X(26).
               10  TRN-PROCESS-USER  PIC X(08).
           05  TRN-FILLER           PIC X(50).
      *****************************************************************
      * FIELD DESCRIPTIONS:
      * TRN-DATE        : TRANSACTION DATE (YYYYMMDD)
      * TRN-TIME        : TRANSACTION TIME (HHMMSS)
      * TRN-PORTFOLIO-ID: PORTFOLIO IDENTIFIER
      * TRN-SEQUENCE-NO : SEQUENCE NUMBER FOR MULTIPLE TRANS
      * TRN-TYPE        : BU=BUY, SL=SELL, TR=TRANSFER, FE=FEE
      * TRN-STATUS      : P=PENDING, D=DONE, F=FAILED, R=REVERSED
      ***************************************************************** 