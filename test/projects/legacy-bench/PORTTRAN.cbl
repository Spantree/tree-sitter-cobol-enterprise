      *================================================================*
      * Program Name: PORTTRAN
      * Description: Portfolio Transaction Processing
      * Author: [Author name]
      * Date Written: 2024-03-20
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PORTTRAN.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE
               ASSIGN TO TRANFILE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-TRAN-STATUS.
               
           SELECT PORTFOLIO-FILE
               ASSIGN TO PORTFILE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS PORT-ID
               FILE STATUS IS WS-PORT-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD  TRANSACTION-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       COPY TRNREC.
       
       FD  PORTFOLIO-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       COPY PORTREC.
       
       WORKING-STORAGE SECTION.
           COPY ERRHAND.
           COPY AUDITLOG.
           
       01  WS-FILE-STATUS.
           05  WS-TRAN-STATUS      PIC X(2).
           05  WS-PORT-STATUS      PIC X(2).
           
       01  WS-COUNTERS.
           05  WS-READ-COUNT       PIC 9(8) COMP.
           05  WS-PROCESS-COUNT    PIC 9(8) COMP.
           05  WS-ERROR-COUNT      PIC 9(8) COMP.
           
       01  WS-EOF-FLAG            PIC X(1).
           88  END-OF-FILE          VALUE 'Y'.
           88  MORE-RECORDS         VALUE 'N'.
           
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           
           IF WS-TRAN-STATUS = '00'
               PERFORM 2000-PROCESS-TRANSACTIONS
                   UNTIL END-OF-FILE
                   OR WS-ERROR-COUNT > 100
           END-IF
           
           PERFORM 3000-TERMINATE
           
           GOBACK
           .
           
       1000-INITIALIZE.
           INITIALIZE WS-FILE-STATUS
                      WS-COUNTERS
           SET MORE-RECORDS TO TRUE
           
           OPEN INPUT TRANSACTION-FILE
           IF WS-TRAN-STATUS NOT = '00'
               MOVE 'Error opening transaction file' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           
           OPEN I-O PORTFOLIO-FILE
           IF WS-PORT-STATUS NOT = '00'
               MOVE 'Error opening portfolio file' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       2000-PROCESS-TRANSACTIONS.
           READ TRANSACTION-FILE
               AT END
                   SET END-OF-FILE TO TRUE
               NOT AT END
                   ADD 1 TO WS-READ-COUNT
                   PERFORM 2100-VALIDATE-TRANSACTION
           END-READ
           .
           
       2100-VALIDATE-TRANSACTION.
           MOVE SPACES TO ERR-TEXT
           
           PERFORM 2110-CHECK-PORTFOLIO
           IF ERR-TEXT = SPACES
               PERFORM 2120-CHECK-TRANSACTION-TYPE
           END-IF
           IF ERR-TEXT = SPACES
               PERFORM 2130-CHECK-AMOUNTS
           END-IF
           
           IF ERR-TEXT = SPACES
               ADD 1 TO WS-PROCESS-COUNT
           ELSE
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       2110-CHECK-PORTFOLIO.
           IF TRN-PORTFOLIO-ID = SPACES
               MOVE 'Portfolio ID is required' TO ERR-TEXT
               EXIT PARAGRAPH
           END-IF
           
           MOVE TRN-PORTFOLIO-ID TO PORT-ID
           READ PORTFOLIO-FILE
               INVALID KEY
                   STRING 'Invalid Portfolio ID: '
                          TRN-PORTFOLIO-ID
                     DELIMITED BY SIZE
                     INTO ERR-TEXT
           END-READ
           .
           
       2120-CHECK-TRANSACTION-TYPE.
           EVALUATE TRN-TYPE
               WHEN 'BU'
               WHEN 'SL'
               WHEN 'TR'
               WHEN 'FE'
                   CONTINUE
               WHEN OTHER
                   STRING 'Invalid Transaction Type: '
                          TRN-TYPE
                     DELIMITED BY SIZE
                     INTO ERR-TEXT
           END-EVALUATE
           .
           
       2130-CHECK-AMOUNTS.
           IF TRN-QUANTITY <= ZERO
               MOVE 'Quantity must be greater than zero' TO ERR-TEXT
               EXIT PARAGRAPH
           END-IF
           
           IF TRN-PRICE <= ZERO AND TRN-TYPE NOT = 'TR'
               MOVE 'Price must be greater than zero' TO ERR-TEXT
               EXIT PARAGRAPH
           END-IF
           
           IF TRN-AMOUNT <= ZERO AND TRN-TYPE NOT = 'TR'
               MOVE 'Amount must be greater than zero' TO ERR-TEXT
           END-IF
           .
           
       2200-UPDATE-POSITIONS.
           EVALUATE TRN-TYPE
               WHEN 'BU'
                   PERFORM 2210-PROCESS-BUY
               WHEN 'SL'
                   PERFORM 2220-PROCESS-SELL
               WHEN 'TR'
                   PERFORM 2230-PROCESS-TRANSFER
               WHEN 'FE'
                   PERFORM 2240-PROCESS-FEE
           END-EVALUATE
           
           PERFORM 2300-UPDATE-AUDIT-TRAIL
           .
           
       2210-PROCESS-BUY.
           MOVE TRN-PORTFOLIO-ID TO PORT-ID
           READ PORTFOLIO-FILE
               INVALID KEY
                   MOVE 'Portfolio not found for update' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
                   EXIT PARAGRAPH
           END-READ
           
           ADD TRN-QUANTITY TO PORT-TOTAL-UNITS
           ADD TRN-AMOUNT   TO PORT-TOTAL-COST
           
           REWRITE PORTFOLIO-RECORD
               INVALID KEY
                   MOVE 'Error updating portfolio' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-REWRITE
           .
           
       2220-PROCESS-SELL.
           MOVE TRN-PORTFOLIO-ID TO PORT-ID
           READ PORTFOLIO-FILE
               INVALID KEY
                   MOVE 'Portfolio not found for update' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
                   EXIT PARAGRAPH
           END-READ
           
           IF PORT-TOTAL-UNITS < TRN-QUANTITY
               MOVE 'Insufficient units for sale' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
               EXIT PARAGRAPH
           END-IF
           
           SUBTRACT TRN-QUANTITY FROM PORT-TOTAL-UNITS
           SUBTRACT TRN-AMOUNT   FROM PORT-TOTAL-COST
           
           REWRITE PORTFOLIO-RECORD
               INVALID KEY
                   MOVE 'Error updating portfolio' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-REWRITE
           .
           
       2230-PROCESS-TRANSFER.
           MOVE 'Transfer processing not implemented' TO ERR-TEXT
           PERFORM 9000-ERROR-ROUTINE
           .
           
       2240-PROCESS-FEE.
           MOVE TRN-PORTFOLIO-ID TO PORT-ID
           READ PORTFOLIO-FILE
               INVALID KEY
                   MOVE 'Portfolio not found for fee' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
                   EXIT PARAGRAPH
           END-READ
           
           SUBTRACT TRN-AMOUNT FROM PORT-TOTAL-COST
           
           REWRITE PORTFOLIO-RECORD
               INVALID KEY
                   MOVE 'Error updating portfolio' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-REWRITE
           .
           
       2300-UPDATE-AUDIT-TRAIL.
           INITIALIZE AUDIT-RECORD
           
           MOVE FUNCTION CURRENT-DATE TO AUD-TIMESTAMP
           MOVE 'PORTTRAN'     TO AUD-PROGRAM
           MOVE FUNCTION USER-ID TO AUD-USER-ID
           MOVE 'TRAN'         TO AUD-TYPE
           
           EVALUATE TRN-TYPE
               WHEN 'BU'
                   MOVE 'CREATE  ' TO AUD-ACTION
               WHEN 'SL'
                   MOVE 'DELETE  ' TO AUD-ACTION
               WHEN 'TR'
                   MOVE 'UPDATE  ' TO AUD-ACTION
               WHEN 'FE'
                   MOVE 'UPDATE  ' TO AUD-ACTION
           END-EVALUATE
           
           IF WS-PORT-STATUS = '00'
               MOVE 'SUCC'     TO AUD-STATUS
           ELSE
               MOVE 'FAIL'     TO AUD-STATUS
           END-IF
           
           MOVE TRN-PORTFOLIO-ID TO AUD-PORTFOLIO-ID
           MOVE PORT-ACCOUNT-NO  TO AUD-ACCOUNT-NO
           
      *    Store original portfolio state
           MOVE PORT-RECORD      TO AUD-BEFORE-IMAGE
           
      *    Build audit message
           STRING 'Transaction: ' DELIMITED BY SIZE
                  TRN-TYPE       DELIMITED BY SIZE
                  ' Amount: '    DELIMITED BY SIZE
                  TRN-AMOUNT     DELIMITED BY SIZE
                  ' Units: '     DELIMITED BY SIZE
                  TRN-QUANTITY   DELIMITED BY SIZE
             INTO AUD-MESSAGE
           
           PERFORM 2310-WRITE-AUDIT-RECORD
           .
           
       2310-WRITE-AUDIT-RECORD.
      *    Call the audit processor
           CALL 'AUDPROC' USING AUDIT-RECORD
           
           IF RETURN-CODE NOT = ZERO
               MOVE 'Error writing audit record' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       3000-TERMINATE.
           CLOSE TRANSACTION-FILE
                 PORTFOLIO-FILE
                 
           DISPLAY 'Transactions Read:    ' WS-READ-COUNT
           DISPLAY 'Transactions Process: ' WS-PROCESS-COUNT
           DISPLAY 'Errors Encountered:   ' WS-ERROR-COUNT
           .
           
       9000-ERROR-ROUTINE.
           ADD 1 TO WS-ERROR-COUNT
           MOVE ERR-CAT-PROC TO ERR-CATEGORY
           MOVE 'PORTTRAN' TO ERR-PROGRAM
           
           CALL 'ERRPROC' USING ERR-MESSAGE
           . 