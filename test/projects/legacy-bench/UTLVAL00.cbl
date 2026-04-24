       IDENTIFICATION DIVISION.
       PROGRAM-ID. UTLVAL00.
       AUTHOR. CLAUDE.
       DATE-WRITTEN. 2024-04-09.
      *****************************************************************
      * Data Validation Utility                                        *
      *                                                               *
      * Performs comprehensive data validation:                       *
      * - Data integrity checks                                      *
      * - Cross-reference validation                                 *
      * - Format verification                                        *
      * - Balance reconciliation                                     *
      *****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           CONSOLE IS CONS.
           
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT VALIDATION-CONTROL ASSIGN TO VALCTL
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-VAL-STATUS.

           SELECT POSITION-MASTER ASSIGN TO POSMSTRE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS POS-KEY
               FILE STATUS IS WS-POS-STATUS.

           SELECT TRANSACTION-HISTORY ASSIGN TO TRANHIST
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS TRAN-KEY
               FILE STATUS IS WS-TRAN-STATUS.

           SELECT ERROR-REPORT ASSIGN TO ERRRPT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-RPT-STATUS.

       DATA DIVISION.
       FILE SECTION.
           COPY POSREC.
           COPY TRNREC.
           
       FD  VALIDATION-CONTROL
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  VALIDATION-RECORD.
           05  VAL-TYPE             PIC X(10).
           05  VAL-PARAMETERS       PIC X(70).

       FD  ERROR-REPORT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  ERROR-RECORD            PIC X(132).

       WORKING-STORAGE SECTION.
           COPY RTNCODE.
           COPY ERRHAND.

       01  WS-FILE-STATUS.
           05  WS-VAL-STATUS        PIC XX.
           05  WS-POS-STATUS        PIC XX.
           05  WS-TRAN-STATUS       PIC XX.
           05  WS-RPT-STATUS        PIC XX.

       01  WS-VALIDATION-TYPES.
           05  WS-INTEGRITY         PIC X(10) VALUE 'INTEGRITY'.
           05  WS-XREF              PIC X(10) VALUE 'XREF'.
           05  WS-FORMAT            PIC X(10) VALUE 'FORMAT'.
           05  WS-BALANCE           PIC X(10) VALUE 'BALANCE'.

       01  WS-PROCESSING-FLAGS.
           05  WS-END-OF-VAL        PIC X VALUE 'N'.
               88  END-OF-VALIDATION VALUE 'Y'.
           05  WS-ERROR-FOUND       PIC X VALUE 'N'.
               88  ERROR-FOUND      VALUE 'Y'.

       01  WS-VALIDATION-TOTALS.
           05  WS-RECORDS-READ      PIC 9(9) VALUE ZERO.
           05  WS-RECORDS-VALID     PIC 9(9) VALUE ZERO.
           05  WS-RECORDS-ERROR     PIC 9(9) VALUE ZERO.
           05  WS-TOTAL-AMOUNT      PIC S9(15)V99 VALUE ZERO.
           05  WS-CONTROL-TOTAL     PIC S9(15)V99 VALUE ZERO.

       01  WS-ERROR-LINE.
           05  WS-ERR-TYPE          PIC X(10).
           05  FILLER               PIC X(2) VALUE SPACES.
           05  WS-ERR-KEY           PIC X(20).
           05  FILLER               PIC X(2) VALUE SPACES.
           05  WS-ERR-DESC          PIC X(98).

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 3000-CLEANUP
           GOBACK.

       1000-INITIALIZE.
           PERFORM 1100-OPEN-FILES
           PERFORM 1200-INIT-PROCESSING.

       1100-OPEN-FILES.
           OPEN INPUT VALIDATION-CONTROL
           IF WS-VAL-STATUS NOT = '00'
               MOVE 'ERROR OPENING VALIDATION CONTROL'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN INPUT POSITION-MASTER
           IF WS-POS-STATUS NOT = '00'
               MOVE 'ERROR OPENING POSITION MASTER'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN INPUT TRANSACTION-HISTORY
           IF WS-TRAN-STATUS NOT = '00'
               MOVE 'ERROR OPENING TRANSACTION HISTORY'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN OUTPUT ERROR-REPORT
           IF WS-RPT-STATUS NOT = '00'
               MOVE 'ERROR OPENING ERROR REPORT'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF.

       1200-INIT-PROCESSING.
           INITIALIZE WS-VALIDATION-TOTALS.

       2000-PROCESS.
           PERFORM UNTIL END-OF-VALIDATION
               READ VALIDATION-CONTROL
                   AT END
                       SET END-OF-VALIDATION TO TRUE
                   NOT AT END
                       PERFORM 2100-PROCESS-VALIDATION
               END-READ
           END-PERFORM.

       2100-PROCESS-VALIDATION.
           EVALUATE VAL-TYPE
               WHEN WS-INTEGRITY
                   PERFORM 2200-CHECK-INTEGRITY
               WHEN WS-XREF
                   PERFORM 2300-CHECK-XREF
               WHEN WS-FORMAT
                   PERFORM 2400-CHECK-FORMAT
               WHEN WS-BALANCE
                   PERFORM 2500-CHECK-BALANCE
               WHEN OTHER
                   MOVE 'INVALID VALIDATION TYPE'
                     TO WS-ERROR-MESSAGE
                   PERFORM 9999-ERROR-HANDLER
           END-EVALUATE.

       2200-CHECK-INTEGRITY.
           PERFORM 2210-CHECK-POSITION-INTEGRITY
           PERFORM 2220-CHECK-TRANSACTION-INTEGRITY.

       2300-CHECK-XREF.
           PERFORM 2310-CHECK-POSITION-XREF
           PERFORM 2320-CHECK-TRANSACTION-XREF.

       2400-CHECK-FORMAT.
           PERFORM 2410-CHECK-POSITION-FORMAT
           PERFORM 2420-CHECK-TRANSACTION-FORMAT.

       2500-CHECK-BALANCE.
           PERFORM 2510-ACCUMULATE-POSITIONS
           PERFORM 2520-VERIFY-BALANCES.

       3000-CLEANUP.
           CLOSE VALIDATION-CONTROL
                POSITION-MASTER
                TRANSACTION-HISTORY
                ERROR-REPORT.

       9999-ERROR-HANDLER.
           ADD 1 TO WS-RECORDS-ERROR
           SET ERROR-FOUND TO TRUE
           MOVE WS-ERROR-MESSAGE TO WS-ERR-DESC
           WRITE ERROR-RECORD FROM WS-ERROR-LINE.