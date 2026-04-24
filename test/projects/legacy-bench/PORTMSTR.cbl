       *================================================================*
      * Program Name: PORTMSTR
      * Description: Portfolio Master File Maintenance Program
      *             Handles CRUD operations for Portfolio records
      * Author: [Author name]
      * Date Written: 2024-03-20
      * Maintenance Log:
      * Date       Author        Description
      * ---------- ------------- -------------------------------------
      * 2024-03-20 [Author]     Initial Creation
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PORTMSTR.
       
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
               RECORD KEY IS PORT-ID
               FILE STATUS IS WS-PORT-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD  PORTFOLIO-FILE
           RECORD CONTAINS 100 CHARACTERS.
       01  PORTFOLIO-RECORD.
           05  PORT-ID             PIC X(10).
           05  PORT-NAME           PIC X(50).
           05  PORT-CREATE-DATE    PIC X(10).
           05  PORT-STATUS         PIC X(01).
           05  PORT-TOTAL-VALUE    PIC S9(13)V99 COMP-3.
           05  FILLER              PIC X(24).
       
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Constants and switches
      *----------------------------------------------------------------*
       01  WS-CONSTANTS.
           05  WS-PROGRAM-NAME     PIC X(08) VALUE 'PORTMSTR'.
           05  WS-SUCCESS          PIC S9(4) VALUE +0.
           05  WS-ERROR            PIC S9(4) VALUE +8.
           05  WS-ERROR-TEXT       PIC X(50) VALUE SPACES.
           
       01  WS-SWITCHES.
           05  WS-PORT-STATUS      PIC X(02).
               88  PORT-SUCCESS    VALUE '00'.
               88  PORT-EOF        VALUE '10'.
               88  PORT-NOT-FOUND  VALUE '23'.
               88  PORT-DUP-KEY    VALUE '22'.
           
           05  WS-VALID-STATUS     PIC X(01).
               88  VALID-STATUS    VALUE 'A' 'I' 'C'.
           
           05  WS-END-OF-FILE-SW   PIC X     VALUE 'N'.
               88  END-OF-FILE              VALUE 'Y'.
               88  NOT-END-OF-FILE          VALUE 'N'.
           
      *----------------------------------------------------------------*
      * Work areas
      *----------------------------------------------------------------*
       01  WS-WORK-AREAS.
           05  WS-CURRENT-DATE     PIC X(10).
           05  WS-RETURN-CODE      PIC S9(4) COMP VALUE +0.
           
       LINKAGE SECTION.
       01  LS-COMMAND-AREA.
           05  LS-COMMAND          PIC X(01).
               88  CREATE-PORT     VALUE 'C'.
               88  READ-PORT       VALUE 'R'.
               88  UPDATE-PORT     VALUE 'U'.
               88  DELETE-PORT     VALUE 'D'.
           05  LS-PORTFOLIO        PIC X(100).
           05  LS-RETURN-CODE      PIC S9(4) COMP.
           
       PROCEDURE DIVISION USING LS-COMMAND-AREA.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           
           EVALUATE TRUE
               WHEN CREATE-PORT
                   PERFORM 2000-CREATE-PORTFOLIO
               WHEN READ-PORT
                   PERFORM 3000-READ-PORTFOLIO
               WHEN UPDATE-PORT
                   PERFORM 4000-UPDATE-PORTFOLIO
               WHEN DELETE-PORT
                   PERFORM 5000-DELETE-PORTFOLIO
               WHEN OTHER
                   MOVE 'Invalid command' TO WS-ERROR-TEXT
                   PERFORM 9000-ERROR
           END-EVALUATE
           
           PERFORM 6000-TERMINATE
           GOBACK.
           
       1000-INITIALIZE.
           INITIALIZE WS-WORK-AREAS
           
           OPEN I-O PORTFOLIO-FILE
           IF NOT PORT-SUCCESS
               MOVE 'Error opening Portfolio file' TO WS-ERROR-TEXT
               PERFORM 9000-ERROR
           END-IF
           
           ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD
           .
           
       2000-CREATE-PORTFOLIO.
      *----------------------------------------------------------------*
      * Create new portfolio record
      *----------------------------------------------------------------*
           MOVE LS-PORTFOLIO TO PORTFOLIO-RECORD
           
           PERFORM 2100-VALIDATE-PORTFOLIO
           IF WS-RETURN-CODE NOT = WS-SUCCESS
               PERFORM 9000-ERROR
           END-IF
           
           WRITE PORTFOLIO-RECORD
           IF PORT-DUP-KEY
               MOVE 'Portfolio ID already exists' TO WS-ERROR-TEXT
               PERFORM 9000-ERROR
           END-IF
           
           IF NOT PORT-SUCCESS
               MOVE 'Error writing Portfolio record' TO WS-ERROR-TEXT
               PERFORM 9000-ERROR
           END-IF
           .
           
       2100-VALIDATE-PORTFOLIO.
      *----------------------------------------------------------------*
      * Validate portfolio data
      *----------------------------------------------------------------*
           IF PORT-ID(1:4) NOT = 'PORT'
              OR PORT-ID(5:5) IS NOT NUMERIC
               MOVE 'Invalid Portfolio ID format' TO WS-ERROR-TEXT
               MOVE WS-ERROR TO WS-RETURN-CODE
               EXIT PARAGRAPH
           END-IF
           
           IF PORT-NAME = SPACES
               MOVE 'Portfolio Name is required' TO WS-ERROR-TEXT
               MOVE WS-ERROR TO WS-RETURN-CODE
               EXIT PARAGRAPH
           END-IF
           
           MOVE PORT-STATUS TO WS-VALID-STATUS
           IF NOT VALID-STATUS
               MOVE 'Invalid Portfolio Status' TO WS-ERROR-TEXT
               MOVE WS-ERROR TO WS-RETURN-CODE
               EXIT PARAGRAPH
           END-IF
           .
           
       3000-READ-PORTFOLIO.
      *----------------------------------------------------------------*
      * Read portfolio record
      *----------------------------------------------------------------*
           MOVE LS-PORTFOLIO TO PORTFOLIO-RECORD
           
           READ PORTFOLIO-FILE
           
           EVALUATE TRUE
               WHEN PORT-SUCCESS
                   MOVE PORTFOLIO-RECORD TO LS-PORTFOLIO
               WHEN PORT-NOT-FOUND
                   MOVE 'Portfolio not found' TO WS-ERROR-TEXT
                   PERFORM 9000-ERROR
               WHEN OTHER
                   MOVE 'Error reading Portfolio' TO WS-ERROR-TEXT
                   PERFORM 9000-ERROR
           END-EVALUATE
           .
           
       4000-UPDATE-PORTFOLIO.
      *----------------------------------------------------------------*
      * Update portfolio record
      *----------------------------------------------------------------*
           MOVE LS-PORTFOLIO TO PORTFOLIO-RECORD
           
           PERFORM 2100-VALIDATE-PORTFOLIO
           IF WS-RETURN-CODE NOT = WS-SUCCESS
               PERFORM 9000-ERROR
           END-IF
           
           REWRITE PORTFOLIO-RECORD
           
           IF PORT-NOT-FOUND
               MOVE 'Portfolio not found for update' TO WS-ERROR-TEXT
               PERFORM 9000-ERROR
           END-IF
           
           IF NOT PORT-SUCCESS
               MOVE 'Error updating Portfolio' TO WS-ERROR-TEXT
               PERFORM 9000-ERROR
           END-IF
           
           PERFORM 2100-LOG-PORTFOLIO-UPDATE
           .
           
       5000-DELETE-PORTFOLIO.
      *----------------------------------------------------------------*
      * Delete portfolio record
      *----------------------------------------------------------------*
           MOVE LS-PORTFOLIO TO PORTFOLIO-RECORD
           
           DELETE PORTFOLIO-FILE
           
           IF PORT-NOT-FOUND
               MOVE 'Portfolio not found for deletion' TO WS-ERROR-TEXT
               PERFORM 9000-ERROR
           END-IF
           
           IF NOT PORT-SUCCESS
               MOVE 'Error deleting Portfolio' TO WS-ERROR-TEXT
               PERFORM 9000-ERROR
           END-IF
           .
           
       6000-TERMINATE.
           CLOSE PORTFOLIO-FILE
           
           MOVE WS-RETURN-CODE TO LS-RETURN-CODE
           .
           
       9000-ERROR.
           MOVE WS-ERROR TO WS-RETURN-CODE
           PERFORM 6000-TERMINATE
           GOBACK
           .

      *----------------------------------------------------------------*
      * Example error handling call
      *----------------------------------------------------------------*
       2100-HANDLE-VSAM-ERROR.
           MOVE 'PORTMSTR' TO LS-PROGRAM-ID
           MOVE ERR-CAT-VSAM TO LS-CATEGORY
           MOVE WS-FILE-STATUS TO LS-ERROR-CODE
           
           EVALUATE WS-FILE-STATUS
               WHEN ERR-VSAM-DUPKEY
                   MOVE ERR-WARNING TO LS-SEVERITY
                   MOVE ERR-VSAM-22 TO LS-ERROR-TEXT
               WHEN ERR-VSAM-NOTFND
                   MOVE ERR-WARNING TO LS-SEVERITY
                   MOVE ERR-VSAM-23 TO LS-ERROR-TEXT
               WHEN OTHER
                   MOVE ERR-ERROR TO LS-SEVERITY
                   MOVE ERR-OTHER TO LS-ERROR-TEXT
           END-EVALUATE
           
           MOVE PORT-KEY TO LS-ERROR-DETAILS
           
           CALL 'ERRPROC' USING LS-ERROR-REQUEST
           .

      *----------------------------------------------------------------*
      * Example audit logging call
      *----------------------------------------------------------------*
       2100-LOG-PORTFOLIO-UPDATE.
           INITIALIZE LS-AUDIT-REQUEST
           
           MOVE 'PORTFOLIO' TO LS-SYSTEM-ID
           MOVE USERID      TO LS-USER-ID
           MOVE 'PORTMSTR' TO LS-PROGRAM
           MOVE TERMINAL-ID TO LS-TERMINAL
           
           MOVE 'TRAN'     TO LS-TYPE
           MOVE 'UPDATE  ' TO LS-ACTION
           MOVE 'SUCC'     TO LS-STATUS
           
           MOVE PORT-ID    TO LS-PORT-ID
           MOVE PORT-ACCOUNT-NO TO LS-ACCT-NO
           
           MOVE WS-BEFORE-IMAGE TO LS-BEFORE-IMAGE
           MOVE PORT-RECORD     TO LS-AFTER-IMAGE
           MOVE 'Portfolio updated successfully' TO LS-MESSAGE
           
           CALL 'AUDPROC' USING LS-AUDIT-REQUEST
           .