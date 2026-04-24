       IDENTIFICATION DIVISION.
       PROGRAM-ID. TSTGEN00.
       AUTHOR. CLAUDE.
       DATE-WRITTEN. 2024-04-09.
      *****************************************************************
      * Test Data Generator                                           *
      *                                                               *
      * Generates test data for system testing:                      *
      * - Portfolio test data                                        *
      * - Transaction test scenarios                                 *
      * - Error condition data                                       *
      * - Performance test volumes                                   *
      *****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           CONSOLE IS CONS.
           
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TEST-CONFIG ASSIGN TO TSTCFG
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-CFG-STATUS.

           SELECT PORTFOLIO-OUT ASSIGN TO PORTOUT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-PORT-STATUS.

           SELECT TRANSACTION-OUT ASSIGN TO TRANOUT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-TRAN-STATUS.

           SELECT RANDOM-SEED ASSIGN TO RANDSEED
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-RAND-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TEST-CONFIG
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  CONFIG-RECORD.
           05  CFG-TEST-TYPE        PIC X(10).
           05  CFG-VOLUME           PIC 9(6).
           05  CFG-PARAMETERS       PIC X(64).

       FD  PORTFOLIO-OUT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  PORTFOLIO-RECORD.
           COPY PORTFLIO REPLACING ==:PREFIX:== BY ==PORT==.

       FD  TRANSACTION-OUT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  TRANSACTION-RECORD.
           COPY TRNREC REPLACING ==:PREFIX:== BY ==TRAN==.

       FD  RANDOM-SEED
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  SEED-RECORD             PIC 9(9).

       WORKING-STORAGE SECTION.
           COPY RTNCODE.
           COPY ERRHAND.

       01  WS-FILE-STATUS.
           05  WS-CFG-STATUS        PIC XX.
           05  WS-PORT-STATUS       PIC XX.
           05  WS-TRAN-STATUS       PIC XX.
           05  WS-RAND-STATUS       PIC XX.

       01  WS-TEST-TYPES.
           05  WS-PORTFOLIO         PIC X(10) VALUE 'PORTFOLIO'.
           05  WS-TRANSACTION       PIC X(10) VALUE 'TRANSACTN'.
           05  WS-ERROR-TEST        PIC X(10) VALUE 'ERROR'.
           05  WS-VOLUME-TEST       PIC X(10) VALUE 'VOLUME'.

       01  WS-PROCESSING-FLAGS.
           05  WS-END-OF-CONFIG     PIC X VALUE 'N'.
               88  END-OF-CONFIG    VALUE 'Y'.

       01  WS-COUNTERS.
           05  WS-RECORDS-WRITTEN   PIC 9(9) VALUE ZERO.
           05  WS-ERROR-COUNT       PIC 9(9) VALUE ZERO.

       01  WS-RANDOM-VALUES.
           05  WS-RANDOM-SEED       PIC 9(9).
           05  WS-RANDOM-NUM        PIC 9(9).
           05  WS-RANDOM-DECIMAL    PIC 9(9)V99.

       01  WS-PORTFOLIO-DATA.
           05  WS-PORT-ID           PIC X(10).
           05  WS-PORT-NAME         PIC X(30).
           05  WS-PORT-TYPE         PIC X(2).
           05  WS-PORT-STATUS       PIC X(1).
           05  WS-PORT-BALANCE      PIC 9(15)V99.

       01  WS-TRANSACTION-DATA.
           05  WS-TRAN-ID           PIC X(12).
           05  WS-TRAN-TYPE         PIC X(2).
           05  WS-TRAN-AMOUNT       PIC 9(15)V99.
           05  WS-TRAN-DATE         PIC X(8).
           05  WS-TRAN-STATUS       PIC X(1).

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 3000-CLEANUP
           GOBACK.

       1000-INITIALIZE.
           PERFORM 1100-OPEN-FILES
           PERFORM 1200-INIT-RANDOM
           PERFORM 1300-INIT-COUNTERS.

       1100-OPEN-FILES.
           OPEN INPUT TEST-CONFIG
           IF WS-CFG-STATUS NOT = '00'
               MOVE 'ERROR OPENING CONFIG FILE'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN OUTPUT PORTFOLIO-OUT
           IF WS-PORT-STATUS NOT = '00'
               MOVE 'ERROR OPENING PORTFOLIO OUTPUT'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN OUTPUT TRANSACTION-OUT
           IF WS-TRAN-STATUS NOT = '00'
               MOVE 'ERROR OPENING TRANSACTION OUTPUT'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN INPUT RANDOM-SEED
           IF WS-RAND-STATUS NOT = '00'
               MOVE 'ERROR OPENING RANDOM SEED'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF.

       1200-INIT-RANDOM.
           READ RANDOM-SEED
           MOVE SEED-RECORD TO WS-RANDOM-SEED.

       1300-INIT-COUNTERS.
           INITIALIZE WS-COUNTERS.

       2000-PROCESS.
           PERFORM UNTIL END-OF-CONFIG
               READ TEST-CONFIG
                   AT END
                       SET END-OF-CONFIG TO TRUE
                   NOT AT END
                       PERFORM 2100-GENERATE-TEST-DATA
               END-READ
           END-PERFORM.

       2100-GENERATE-TEST-DATA.
           EVALUATE CFG-TEST-TYPE
               WHEN WS-PORTFOLIO
                   PERFORM 2200-GEN-PORTFOLIO
               WHEN WS-TRANSACTION
                   PERFORM 2300-GEN-TRANSACTION
               WHEN WS-ERROR-TEST
                   PERFORM 2400-GEN-ERROR-DATA
               WHEN WS-VOLUME-TEST
                   PERFORM 2500-GEN-VOLUME-DATA
               WHEN OTHER
                   MOVE 'INVALID TEST TYPE'
                     TO WS-ERROR-MESSAGE
                   PERFORM 9999-ERROR-HANDLER
           END-EVALUATE.

       2200-GEN-PORTFOLIO.
           PERFORM VARYING WS-RECORDS-WRITTEN FROM 1 BY 1
                   UNTIL WS-RECORDS-WRITTEN > CFG-VOLUME
               PERFORM 2210-GEN-PORT-DATA
               PERFORM 2220-WRITE-PORT-RECORD
           END-PERFORM.

       2300-GEN-TRANSACTION.
           PERFORM VARYING WS-RECORDS-WRITTEN FROM 1 BY 1
                   UNTIL WS-RECORDS-WRITTEN > CFG-VOLUME
               PERFORM 2310-GEN-TRAN-DATA
               PERFORM 2320-WRITE-TRAN-RECORD
           END-PERFORM.

       2400-GEN-ERROR-DATA.
           PERFORM 2410-GEN-DATA-ERRORS
           PERFORM 2420-GEN-PROCESS-ERRORS.

       2500-GEN-VOLUME-DATA.
           PERFORM 2510-GEN-LARGE-PORTFOLIO
           PERFORM 2520-GEN-LARGE-TRANSACTION.

       3000-CLEANUP.
           CLOSE TEST-CONFIG
                PORTFOLIO-OUT
                TRANSACTION-OUT
                RANDOM-SEED.

       9999-ERROR-HANDLER.
           ADD 1 TO WS-ERROR-COUNT
           DISPLAY WS-ERROR-MESSAGE UPON CONS
           IF WS-ERROR-COUNT > 100
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF. 