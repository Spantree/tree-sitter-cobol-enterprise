       *================================================================*
      * Program Name: PORTUPDT
      * Description: Portfolio Update Program
      *             Updates existing portfolio records
      * Author: [Author name]
      * Date Written: 2024-03-20
      * Maintenance Log:
      * Date       Author        Description
      * ---------- ------------- -------------------------------------
      * 2024-03-20 [Author]     Initial Creation
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PORTUPDT.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PORTFOLIO-FILE
               ASSIGN TO PORTFILE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS PORT-KEY
               FILE STATUS IS WS-FILE-STATUS.
           
           SELECT UPDATE-FILE
               ASSIGN TO UPDTFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-UPDT-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD  PORTFOLIO-FILE.
           COPY PORTFLIO.
           
       FD  UPDATE-FILE.
       01  UPDATE-RECORD.
           05  UPDT-KEY.
               10  UPDT-ID        PIC X(8).
               10  UPDT-ACCT-NO   PIC X(10).
           05  UPDT-ACTION        PIC X(1).
               88  UPDT-STATUS    VALUE 'S'.
               88  UPDT-VALUE     VALUE 'V'.
               88  UPDT-NAME      VALUE 'N'.
           05  UPDT-NEW-VALUE     PIC X(50).
           
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Constants and switches
      *----------------------------------------------------------------*
       01  WS-CONSTANTS.
           05  WS-PROGRAM-NAME     PIC X(08) VALUE 'PORTUPDT '.
           05  WS-SUCCESS          PIC S9(4) VALUE +0.
           05  WS-ERROR            PIC S9(4) VALUE +8.
           
       01  WS-SWITCHES.
           05  WS-FILE-STATUS      PIC X(02).
               88  WS-SUCCESS-STATUS     VALUE '00'.
               88  WS-EOF-STATUS        VALUE '10'.
               88  WS-REC-NOT-FND       VALUE '23'.
           
           05  WS-UPDT-STATUS      PIC X(02).
               88  WS-UPDT-SUCCESS      VALUE '00'.
               88  WS-UPDT-EOF          VALUE '10'.
           
           05  WS-END-OF-FILE-SW   PIC X     VALUE 'N'.
               88  END-OF-FILE              VALUE 'Y'.
               88  NOT-END-OF-FILE          VALUE 'N'.
           
      *----------------------------------------------------------------*
      * Work areas
      *----------------------------------------------------------------*
       01  WS-WORK-AREAS.
           05  WS-UPDATE-COUNT     PIC 9(7) VALUE ZERO.
           05  WS-ERROR-COUNT      PIC 9(7) VALUE ZERO.
           05  WS-RETURN-CODE      PIC S9(4) VALUE +0.
           05  WS-NUMERIC-WORK     PIC S9(13)V99.
           
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           
           PERFORM 2000-PROCESS
              UNTIL END-OF-FILE
           
           PERFORM 3000-TERMINATE
           
           GOBACK.
           
       1000-INITIALIZE.
           INITIALIZE WS-WORK-AREAS
           
           OPEN I-O   PORTFOLIO-FILE
           OPEN INPUT UPDATE-FILE
           
           IF NOT WS-SUCCESS-STATUS OR 
              NOT WS-UPDT-SUCCESS
              DISPLAY 'Error opening files: ' 
                      'PORT=' WS-FILE-STATUS
                      'UPDT=' WS-UPDT-STATUS
              MOVE WS-ERROR TO WS-RETURN-CODE
              PERFORM 3000-TERMINATE
           END-IF
           .
           
       2000-PROCESS.
           READ UPDATE-FILE
               AT END
                   SET END-OF-FILE TO TRUE
               NOT AT END
                   PERFORM 2100-PROCESS-UPDATE
           END-READ
           .
           
       2100-PROCESS-UPDATE.
           MOVE UPDT-KEY TO PORT-KEY
           
           READ PORTFOLIO-FILE
           
           IF WS-SUCCESS-STATUS
               PERFORM 2200-APPLY-UPDATE
           ELSE
               ADD 1 TO WS-ERROR-COUNT
               DISPLAY 'Record not found: ' PORT-KEY
           END-IF
           .
           
       2200-APPLY-UPDATE.
           EVALUATE TRUE
               WHEN UPDT-STATUS
                   MOVE UPDT-NEW-VALUE TO PORT-STATUS
               WHEN UPDT-NAME
                   MOVE UPDT-NEW-VALUE TO PORT-CLIENT-NAME
               WHEN UPDT-VALUE
                   MOVE UPDT-NEW-VALUE TO WS-NUMERIC-WORK
                   MOVE WS-NUMERIC-WORK TO PORT-TOTAL-VALUE
           END-EVALUATE
           
           REWRITE PORT-RECORD
           
           IF WS-SUCCESS-STATUS
               ADD 1 TO WS-UPDATE-COUNT
           ELSE
               ADD 1 TO WS-ERROR-COUNT
               DISPLAY 'Update failed for: ' PORT-KEY
           END-IF
           .
           
       3000-TERMINATE.
           CLOSE PORTFOLIO-FILE
                 UPDATE-FILE
           
           DISPLAY 'Updates processed: ' WS-UPDATE-COUNT
           DISPLAY 'Errors occurred:  ' WS-ERROR-COUNT
           
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .