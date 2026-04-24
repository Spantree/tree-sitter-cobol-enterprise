       *================================================================*
      * Program Name: PORTDEL
      * Description: Portfolio Deletion Program
      *             Processes portfolio deletion requests
      * Author: [Author name]
      * Date Written: 2024-03-20
      * Maintenance Log:
      * Date       Author        Description
      * ---------- ------------- -------------------------------------
      * 2024-03-20 [Author]     Initial Creation
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PORTDEL.
       
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
           
           SELECT DELETE-FILE
               ASSIGN TO DELEFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-DEL-STATUS.
           
           SELECT AUDIT-FILE
               ASSIGN TO AUDFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-AUD-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD  PORTFOLIO-FILE.
           COPY PORTFLIO.
           
       FD  DELETE-FILE.
       01  DELETE-RECORD.
           05  DEL-KEY.
               10  DEL-ID          PIC X(8).
               10  DEL-ACCT-NO     PIC X(10).
           05  DEL-REASON-CODE     PIC X(2).
               88  DEL-CLOSED        VALUE '01'.
               88  DEL-TRANSFERRED   VALUE '02'.
               88  DEL-REQUESTED     VALUE '03'.
           05  DEL-FILLER         PIC X(60).
           
       FD  AUDIT-FILE.
       01  AUDIT-RECORD.
           05  AUD-TIMESTAMP      PIC X(26).
           05  AUD-ACTION         PIC X(6).
           05  AUD-KEY           PIC X(18).
           05  AUD-REASON        PIC X(2).
           05  AUD-STATUS        PIC X(1).
           05  AUD-FILLER        PIC X(27).
       
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Constants and switches
      *----------------------------------------------------------------*
       01  WS-CONSTANTS.
           05  WS-PROGRAM-NAME     PIC X(08) VALUE 'PORTDEL  '.
           05  WS-SUCCESS          PIC S9(4) VALUE +0.
           05  WS-ERROR            PIC S9(4) VALUE +8.
           
       01  WS-SWITCHES.
           05  WS-FILE-STATUS      PIC X(02).
               88  WS-SUCCESS-STATUS     VALUE '00'.
               88  WS-REC-NOT-FND       VALUE '23'.
               88  WS-EOF-STATUS         VALUE '10'.
           
           05  WS-DEL-STATUS       PIC X(02).
               88  WS-DEL-SUCCESS       VALUE '00'.
               88  WS-DEL-EOF           VALUE '10'.
               
           05  WS-AUD-STATUS       PIC X(02).
               88  WS-AUD-SUCCESS       VALUE '00'.
           
           05  WS-END-OF-FILE-SW   PIC X     VALUE 'N'.
               88  END-OF-FILE              VALUE 'Y'.
               88  NOT-END-OF-FILE          VALUE 'N'.
           
      *----------------------------------------------------------------*
      * Work areas
      *----------------------------------------------------------------*
       01  WS-WORK-AREAS.
           05  WS-DELETE-COUNT     PIC 9(7) VALUE ZERO.
           05  WS-ERROR-COUNT      PIC 9(7) VALUE ZERO.
           05  WS-NOT-FND-COUNT    PIC 9(7) VALUE ZERO.
           05  WS-RETURN-CODE      PIC S9(4) VALUE +0.
           05  WS-TIMESTAMP        PIC X(26).
           
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
           OPEN INPUT DELETE-FILE
           OPEN OUTPUT AUDIT-FILE
           
           IF NOT WS-SUCCESS-STATUS OR 
              NOT WS-DEL-SUCCESS OR
              NOT WS-AUD-SUCCESS
              DISPLAY 'Error opening files: ' 
                      'PORT=' WS-FILE-STATUS
                      'DEL='  WS-DEL-STATUS
                      'AUD='  WS-AUD-STATUS
              MOVE WS-ERROR TO WS-RETURN-CODE
              PERFORM 3000-TERMINATE
           END-IF
           .
           
       2000-PROCESS.
           READ DELETE-FILE
               AT END
                   SET END-OF-FILE TO TRUE
               NOT AT END
                   PERFORM 2100-PROCESS-DELETE
           END-READ
           .
           
       2100-PROCESS-DELETE.
           MOVE DEL-KEY TO PORT-KEY
           
           READ PORTFOLIO-FILE
           
           EVALUATE TRUE
               WHEN WS-SUCCESS-STATUS
                   PERFORM 2200-DELETE-RECORD
               WHEN WS-REC-NOT-FND
                   ADD 1 TO WS-NOT-FND-COUNT
                   DISPLAY 'Record not found: ' PORT-KEY
               WHEN OTHER
                   ADD 1 TO WS-ERROR-COUNT
                   DISPLAY 'Read error for: ' PORT-KEY
           END-EVALUATE
           .
           
       2200-DELETE-RECORD.
           DELETE PORTFOLIO-FILE
           
           IF WS-SUCCESS-STATUS
               ADD 1 TO WS-DELETE-COUNT
               PERFORM 2300-WRITE-AUDIT
           ELSE
               ADD 1 TO WS-ERROR-COUNT
               DISPLAY 'Delete failed for: ' PORT-KEY
           END-IF
           .
           
       2300-WRITE-AUDIT.
           ACCEPT WS-TIMESTAMP FROM TIME STAMP
           
           MOVE WS-TIMESTAMP TO AUD-TIMESTAMP
           MOVE 'DELETE' TO AUD-ACTION
           MOVE PORT-KEY TO AUD-KEY
           MOVE DEL-REASON-CODE TO AUD-REASON
           MOVE PORT-STATUS TO AUD-STATUS
           
           WRITE AUDIT-RECORD
           
           IF NOT WS-AUD-SUCCESS
               DISPLAY 'Audit write failed for: ' PORT-KEY
           END-IF
           .
           
       3000-TERMINATE.
           CLOSE PORTFOLIO-FILE
                 DELETE-FILE
                 AUDIT-FILE
           
           DISPLAY 'Records deleted:  ' WS-DELETE-COUNT
           DISPLAY 'Records not found:' WS-NOT-FND-COUNT
           DISPLAY 'Errors occurred:  ' WS-ERROR-COUNT
           
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .