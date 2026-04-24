       *================================================================*
      * Program Name: HISTLD00
      * Description: Position History DB2 Load Program
      * Version: 1.0
      * Date: 2024
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HISTLD00.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-HISTORY
               ASSIGN TO TRANHIST
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS TH-KEY
               FILE STATUS IS WS-TH-STATUS.
               
           SELECT BATCH-CONTROL-FILE
               ASSIGN TO BCHCTL
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS BCT-KEY
               FILE STATUS IS WS-BCT-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD  TRANSACTION-HISTORY.
           COPY HISTREC.
       
       FD  BATCH-CONTROL-FILE.
           COPY BCHCTL.
       
       WORKING-STORAGE SECTION.
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
           COPY DBTBLS.
           EXEC SQL END DECLARE SECTION END-EXEC.
           
           COPY SQLCA.
           COPY DBPROC.
           COPY ERRHAND.
           COPY BCHCON.
           
       01  WS-FILE-STATUS.
           05  WS-TH-STATUS          PIC X(2).
           05  WS-BCT-STATUS         PIC X(2).
           
       01  WS-COUNTERS.
           05  WS-RECORDS-READ       PIC S9(9) COMP VALUE 0.
           05  WS-RECORDS-WRITTEN    PIC S9(9) COMP VALUE 0.
           05  WS-ERROR-COUNT        PIC S9(9) COMP VALUE 0.
           05  WS-COMMIT-COUNT       PIC S9(4) COMP VALUE 0.
           
       01  WS-COMMIT-THRESHOLD       PIC S9(4) COMP VALUE 1000.
       
       01  WS-SWITCHES.
           05  WS-END-OF-FILE-SW     PIC X(1) VALUE 'N'.
               88  END-OF-FILE         VALUE 'Y'.
               88  MORE-RECORDS        VALUE 'N'.
               
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           
           PERFORM 2000-PROCESS
               UNTIL END-OF-FILE
               OR WS-ERROR-COUNT > 100
           
           PERFORM 3000-TERMINATE
           
           MOVE WS-ERROR-COUNT TO RETURN-CODE
           GOBACK
           .
           
       1000-INITIALIZE.
           PERFORM 1100-OPEN-FILES
           PERFORM 1200-CONNECT-DB2
           PERFORM 1300-INIT-CHECKPOINTS
           .
           
       2000-PROCESS.
           PERFORM 2100-READ-HISTORY
           
           IF MORE-RECORDS
               PERFORM 2200-LOAD-TO-DB2
               PERFORM 2300-CHECK-COMMIT
           END-IF
           .
           
       3000-TERMINATE.
           PERFORM 3100-FINAL-COMMIT
           PERFORM 3200-CLOSE-FILES
           PERFORM 3300-DISCONNECT-DB2
           PERFORM 3400-DISPLAY-STATS
           .
           
       1100-OPEN-FILES.
           OPEN INPUT TRANSACTION-HISTORY
           IF WS-TH-STATUS NOT = '00'
               MOVE 'Error opening history file' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           
           OPEN I-O BATCH-CONTROL-FILE
           IF WS-BCT-STATUS NOT = '00'
               MOVE 'Error opening control file' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       1200-CONNECT-DB2.
           PERFORM CONNECT-TO-DB2
           .
           
       1300-INIT-CHECKPOINTS.
           MOVE SPACES TO BCT-KEY
           MOVE 'HISTLD00' TO BCT-JOB-NAME
           
           READ BATCH-CONTROL-FILE
               INVALID KEY
                   MOVE 'Control record not found' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-READ
           
           MOVE BCT-STAT-ACTIVE TO BCT-STATUS
           REWRITE BATCH-CONTROL-RECORD
           .
           
       2100-READ-HISTORY.
           READ TRANSACTION-HISTORY
               AT END
                   SET END-OF-FILE TO TRUE
               NOT AT END
                   ADD 1 TO WS-RECORDS-READ
           END-READ
           .
           
       2200-LOAD-TO-DB2.
           INITIALIZE POSHIST-RECORD
           
           MOVE TH-ACCOUNT-NO    TO PH-ACCOUNT-NO
           MOVE TH-PORTFOLIO-ID  TO PH-PORTFOLIO-ID
           MOVE TH-TRANS-DATE    TO PH-TRANS-DATE
           MOVE TH-TRANS-TIME    TO PH-TRANS-TIME
           MOVE TH-TRANS-TYPE    TO PH-TRANS-TYPE
           MOVE TH-SECURITY-ID   TO PH-SECURITY-ID
           MOVE TH-QUANTITY      TO PH-QUANTITY
           MOVE TH-PRICE         TO PH-PRICE
           MOVE TH-AMOUNT        TO PH-AMOUNT
           MOVE TH-FEES          TO PH-FEES
           MOVE TH-TOTAL-AMOUNT  TO PH-TOTAL-AMOUNT
           MOVE TH-COST-BASIS    TO PH-COST-BASIS
           MOVE TH-GAIN-LOSS     TO PH-GAIN-LOSS
           
           EXEC SQL
               INSERT INTO POSHIST
               VALUES (:POSHIST-RECORD)
           END-EXEC
           
           IF SQLCODE = 0
               ADD 1 TO WS-RECORDS-WRITTEN
           ELSE
               IF SQLCODE = -803
                   CONTINUE
               ELSE
                   ADD 1 TO WS-ERROR-COUNT
                   PERFORM DB2-ERROR-ROUTINE
               END-IF
           END-IF
           .
           
       2300-CHECK-COMMIT.
           ADD 1 TO WS-COMMIT-COUNT
           
           IF WS-COMMIT-COUNT >= WS-COMMIT-THRESHOLD
               EXEC SQL
                   COMMIT WORK
               END-EXEC
               
               MOVE 0 TO WS-COMMIT-COUNT
               
               PERFORM 2310-UPDATE-CHECKPOINT
           END-IF
           .
           
       2310-UPDATE-CHECKPOINT.
           MOVE WS-RECORDS-READ TO BCT-RECORDS-READ
           MOVE WS-RECORDS-WRITTEN TO BCT-RECORDS-WRITTEN
           
           REWRITE BATCH-CONTROL-RECORD
               INVALID KEY
                   MOVE 'Error updating checkpoint' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-REWRITE
           .
           
       3100-FINAL-COMMIT.
           EXEC SQL
               COMMIT WORK
           END-EXEC
           
           PERFORM 2310-UPDATE-CHECKPOINT
           .
           
       3200-CLOSE-FILES.
           CLOSE TRANSACTION-HISTORY
                 BATCH-CONTROL-FILE
           .
           
       3300-DISCONNECT-DB2.
           PERFORM DISCONNECT-FROM-DB2
           .
           
       3400-DISPLAY-STATS.
           DISPLAY 'HISTLD00 Processing Statistics:'
           DISPLAY '  Records Read:    ' WS-RECORDS-READ
           DISPLAY '  Records Written: ' WS-RECORDS-WRITTEN
           DISPLAY '  Errors:         ' WS-ERROR-COUNT
           .
           
       9000-ERROR-ROUTINE.
           MOVE 'HISTLD00' TO ERR-PROGRAM
           CALL 'ERRPROC' USING ERR-MESSAGE
           
           EXEC SQL
               ROLLBACK WORK
           END-EXEC
           .