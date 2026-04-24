      *================================================================*
      * Program Name: PORTREAD
      * Description: Portfolio Record Reading Program
      *             Demonstrates reading capabilities of Portfolio file
      * Author: [Author name]
      * Date Written: 2024-03-20
      * Maintenance Log:
      * Date       Author        Description
      * ---------- ------------- -------------------------------------
      * 2024-03-20 [Author]     Initial Creation
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PORTREAD.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PORTFOLIO-FILE
               ASSIGN TO PORTFILE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS PORT-KEY
               FILE STATUS IS WS-FILE-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD  PORTFOLIO-FILE.
           COPY PORTFLIO.
       
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Constants and switches
      *----------------------------------------------------------------*
       01  WS-CONSTANTS.
           05  WS-PROGRAM-NAME     PIC X(08) VALUE 'PORTREAD '.
           05  WS-SUCCESS          PIC S9(4) VALUE +0.
           05  WS-ERROR            PIC S9(4) VALUE +8.
           
       01  WS-SWITCHES.
           05  WS-FILE-STATUS      PIC X(02).
               88  WS-SUCCESS-STATUS     VALUE '00'.
               88  WS-EOF-STATUS        VALUE '10'.
               88  WS-REC-NOT-FND       VALUE '23'.
           
           05  WS-END-OF-FILE-SW   PIC X     VALUE 'N'.
               88  END-OF-FILE              VALUE 'Y'.
               88  NOT-END-OF-FILE          VALUE 'N'.
           
      *----------------------------------------------------------------*
      * Work areas
      *----------------------------------------------------------------*
       01  WS-WORK-AREAS.
           05  WS-RECORD-COUNT     PIC 9(7) VALUE ZERO.
           05  WS-RETURN-CODE      PIC S9(4) VALUE +0.
           
       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * Main process
      *----------------------------------------------------------------*
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           
           PERFORM 2000-PROCESS
              UNTIL END-OF-FILE
           
           PERFORM 3000-TERMINATE
           
           GOBACK.
           
       1000-INITIALIZE.
           INITIALIZE WS-WORK-AREAS
           
           OPEN INPUT PORTFOLIO-FILE
           IF NOT WS-SUCCESS-STATUS
              DISPLAY 'Error opening file: ' WS-FILE-STATUS
              MOVE WS-ERROR TO WS-RETURN-CODE
              PERFORM 3000-TERMINATE
           END-IF
           .
           
       2000-PROCESS.
           READ PORTFOLIO-FILE NEXT RECORD
               AT END
                   SET END-OF-FILE TO TRUE
               NOT AT END
                   ADD 1 TO WS-RECORD-COUNT
                   PERFORM 2100-DISPLAY-RECORD
           END-READ
           .
           
       2100-DISPLAY-RECORD.
           DISPLAY 'Portfolio Record: ' WS-RECORD-COUNT
           DISPLAY '  ID: ' PORT-ID
           DISPLAY '  Account: ' PORT-ACCOUNT-NO
           DISPLAY '  Client: ' PORT-CLIENT-NAME
           DISPLAY '  Status: ' PORT-STATUS
           DISPLAY '  Total Value: ' PORT-TOTAL-VALUE
           DISPLAY ' '
           .
           
       3000-TERMINATE.
           CLOSE PORTFOLIO-FILE
           
           DISPLAY 'Total Records Read: ' WS-RECORD-COUNT
           
           MOVE WS-RETURN-CODE TO RETURN-CODE
           . 