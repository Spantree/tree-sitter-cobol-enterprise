      *================================================================*
      * DB2 Table Definitions
      * Version: 1.0
      * Date: 2024
      *================================================================*
      
      *----------------------------------------------------------------*
      * Position History Table
      *----------------------------------------------------------------*
       01  POSHIST-RECORD.
           05  PH-ACCOUNT-NO        PIC X(8).
           05  PH-PORTFOLIO-ID      PIC X(10).
           05  PH-TRANS-DATE        PIC X(10).
           05  PH-TRANS-TIME        PIC X(8).
           05  PH-TRANS-TYPE        PIC X(2).
           05  PH-SECURITY-ID       PIC X(12).
           05  PH-QUANTITY          PIC S9(12)V9(3) COMP-3.
           05  PH-PRICE             PIC S9(12)V9(3) COMP-3.
           05  PH-AMOUNT            PIC S9(13)V9(2) COMP-3.
           05  PH-FEES              PIC S9(13)V9(2) COMP-3.
           05  PH-TOTAL-AMOUNT      PIC S9(13)V9(2) COMP-3.
           05  PH-COST-BASIS        PIC S9(13)V9(2) COMP-3.
           05  PH-GAIN-LOSS         PIC S9(13)V9(2) COMP-3.
           05  PH-PROCESS-DATE      PIC X(10).
           05  PH-PROCESS-TIME      PIC X(8).
           05  PH-PROGRAM-ID        PIC X(8).
           05  PH-USER-ID           PIC X(8).
           05  PH-AUDIT-TIMESTAMP   PIC X(26).
      
      *----------------------------------------------------------------*
      * Error Log Table
      *----------------------------------------------------------------*
       01  ERRLOG-RECORD.
           05  EL-ERROR-TIMESTAMP   PIC X(26).
           05  EL-PROGRAM-ID        PIC X(8).
           05  EL-ERROR-TYPE        PIC X(1).
               88  EL-TYPE-SYSTEM     VALUE 'S'.
               88  EL-TYPE-APP        VALUE 'A'.
               88  EL-TYPE-DATA       VALUE 'D'.
           05  EL-ERROR-SEVERITY    PIC S9(4) COMP.
               88  EL-SEV-INFO        VALUE 1.
               88  EL-SEV-WARN        VALUE 2.
               88  EL-SEV-ERROR       VALUE 3.
               88  EL-SEV-SEVERE      VALUE 4.
           05  EL-ERROR-CODE        PIC X(8).
           05  EL-ERROR-MESSAGE     PIC X(200).
           05  EL-PROCESS-DATE      PIC X(10).
           05  EL-PROCESS-TIME      PIC X(8).
           05  EL-USER-ID           PIC X(8).
           05  EL-ADDITIONAL-INFO   PIC X(500). 