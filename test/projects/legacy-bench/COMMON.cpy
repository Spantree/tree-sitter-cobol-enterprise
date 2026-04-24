      *****************************************************************
      * COMMON DEFINITIONS AND CONSTANTS
      * VERSION: 1.0
      * DATE: 2024
      *****************************************************************
      *
      * RETURN CODES
       01  RETURN-CODES.
           05  RC-SUCCESS                PIC S9(4) VALUE +0.
           05  RC-WARNING               PIC S9(4) VALUE +4.
           05  RC-ERROR                 PIC S9(4) VALUE +8.
           05  RC-SEVERE                PIC S9(4) VALUE +12.
           05  RC-CRITICAL              PIC S9(4) VALUE +16.
      *
      * STATUS CODES     
       01  STATUS-CODES.
           05  STATUS-ACTIVE            PIC X(01) VALUE 'A'.
           05  STATUS-CLOSED            PIC X(01) VALUE 'C'.
           05  STATUS-PENDING           PIC X(01) VALUE 'P'.
           05  STATUS-SUSPENDED         PIC X(01) VALUE 'S'.
           05  STATUS-FAILED            PIC X(01) VALUE 'F'.
           05  STATUS-REVERSED          PIC X(01) VALUE 'R'.
      *
      * TRANSACTION TYPES
       01  TRANSACTION-TYPES.
           05  TRN-TYPE-BUY            PIC X(02) VALUE 'BU'.
           05  TRN-TYPE-SELL           PIC X(02) VALUE 'SL'.
           05  TRN-TYPE-TRANSFER       PIC X(02) VALUE 'TR'.
           05  TRN-TYPE-FEE            PIC X(02) VALUE 'FE'.
      *
      * COMMON DATE/TIME FIELDS
       01  COMMON-DATETIME.
           05  CURRENT-DATE.
               10  CURR-YEAR           PIC X(04).
               10  CURR-MONTH          PIC X(02).
               10  CURR-DAY            PIC X(02).
           05  CURRENT-TIME.
               10  CURR-HOUR           PIC X(02).
               10  CURR-MINUTE         PIC X(02).
               10  CURR-SECOND         PIC X(02).
               10  CURR-MSEC           PIC X(02).
      *
      * COMMON ERROR HANDLING
       01  ERROR-HANDLING.
           05  ERROR-CODE              PIC X(04).
           05  ERROR-MODULE            PIC X(08).
           05  ERROR-ROUTINE           PIC X(08).
           05  ERROR-MESSAGE           PIC X(80).
      *
      * COMMON AUDIT FIELDS     
       01  AUDIT-FIELDS.
           05  AUDIT-TIMESTAMP         PIC X(26).
           05  AUDIT-USER              PIC X(08).
           05  AUDIT-TERMINAL          PIC X(08).
           05  AUDIT-PROGRAM           PIC X(08).
      *
      * COMMON CURRENCY CODES
       01  CURRENCY-CODES.
           05  CURR-USD                PIC X(03) VALUE 'USD'.
           05  CURR-EUR                PIC X(03) VALUE 'EUR'.
           05  CURR-GBP                PIC X(03) VALUE 'GBP'.
           05  CURR-JPY                PIC X(03) VALUE 'JPY'.
           05  CURR-CAD                PIC X(03) VALUE 'CAD'.
      ***************************************************************** 