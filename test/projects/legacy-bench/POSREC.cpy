      *****************************************************************
      * POSITION RECORD STRUCTURE
      * VERSION: 1.0
      * DATE: 2024
      *****************************************************************
       01  POSITION-RECORD.
           05  POS-KEY.
               10  POS-PORTFOLIO-ID   PIC X(08).
               10  POS-DATE           PIC X(08).
               10  POS-INVESTMENT-ID  PIC X(10).
           05  POS-DATA.
               10  POS-QUANTITY       PIC S9(11)V9(4) COMP-3.
               10  POS-COST-BASIS     PIC S9(13)V9(2) COMP-3.
               10  POS-MARKET-VALUE   PIC S9(13)V9(2) COMP-3.
               10  POS-CURRENCY       PIC X(03).
               10  POS-STATUS         PIC X(01).
                   88  POS-STATUS-ACTIVE  VALUE 'A'.
                   88  POS-STATUS-CLOSED  VALUE 'C'.
                   88  POS-STATUS-PEND    VALUE 'P'.
           05  POS-AUDIT.
               10  POS-LAST-MAINT-DATE   PIC X(26).
               10  POS-LAST-MAINT-USER   PIC X(08).
           05  POS-FILLER               PIC X(50).
      *****************************************************************
      * FIELD DESCRIPTIONS:
      * POS-PORTFOLIO-ID : PORTFOLIO IDENTIFIER
      * POS-DATE         : POSITION DATE (YYYYMMDD)
      * POS-INVESTMENT-ID: INVESTMENT IDENTIFIER
      * POS-QUANTITY     : HOLDING QUANTITY
      * POS-COST-BASIS   : TOTAL COST BASIS
      * POS-MARKET-VALUE : CURRENT MARKET VALUE
      * POS-STATUS       : A=ACTIVE, C=CLOSED, P=PENDING
      ***************************************************************** 