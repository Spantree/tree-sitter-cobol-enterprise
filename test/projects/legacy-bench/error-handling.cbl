      *================================================================*
      * Program Name: ERRHANDL
      * Description: Template for standard error handling patterns
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ERRHANDL.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Standard return codes
      *----------------------------------------------------------------*
       01  WS-RETURN-CODES.
           05  RC-SUCCESS              PIC S9(4) COMP VALUE +0.
           05  RC-WARNING              PIC S9(4) COMP VALUE +4.
           05  RC-ERROR               PIC S9(4) COMP VALUE +8.
           05  RC-SEVERE              PIC S9(4) COMP VALUE +12.
           05  RC-CRITICAL            PIC S9(4) COMP VALUE +16.
           
      *----------------------------------------------------------------*
      * Error message structure
      *----------------------------------------------------------------*
       01  WS-ERROR-MSG.
           05  WS-ERROR-PREFIX        PIC X(8)  VALUE 'ERH'.
           05  WS-ERROR-NUMBER        PIC 9(4)  VALUE ZEROS.
           05  FILLER                 PIC X     VALUE '-'.
           05  WS-ERROR-TEXT          PIC X(50) VALUE SPACES.
           05  FILLER                 PIC X     VALUE SPACES.
           05  WS-ERROR-SEVERITY      PIC X(8)  VALUE SPACES.
           
      *----------------------------------------------------------------*
      * Error tracking
      *----------------------------------------------------------------*
       01  WS-ERROR-FLAGS.
           05  WS-PROCESSING-ERROR    PIC X.
               88  NO-ERROR           VALUE 'N'.
               88  ERROR-OCCURRED     VALUE 'Y'.
           05  WS-ABEND-FLAG         PIC X.
               88  PERFORM-ABEND      VALUE 'Y'.
               88  NO-ABEND           VALUE 'N'.
               
       01  WS-ERROR-COUNTS.
           05  WS-WARNING-COUNT      PIC S9(4) COMP VALUE ZEROS.
           05  WS-ERROR-COUNT        PIC S9(4) COMP VALUE ZEROS.
           05  WS-SEVERE-COUNT       PIC S9(4) COMP VALUE ZEROS.
           
      *----------------------------------------------------------------*
      * Common error messages
      *----------------------------------------------------------------*
       01  ERROR-MESSAGES.
           05  ERR-001.
               10  FILLER    PIC X(50) VALUE
                   'INVALID INPUT PARAMETER RECEIVED'.
           05  ERR-002.
               10  FILLER    PIC X(50) VALUE
                   'REQUIRED FIELD IS MISSING'.
           05  ERR-003.
               10  FILLER    PIC X(50) VALUE
                   'FILE OPERATION FAILED'.
                   
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 3000-TERMINATE
           GOBACK.
           
       1000-INITIALIZE.
           INITIALIZE WS-ERROR-FLAGS
                      WS-ERROR-COUNTS
           SET NO-ERROR TO TRUE
           SET NO-ABEND TO TRUE
           .
           
       2000-PROCESS.
      *----------------------------------------------------------------*
      * Example error handling scenarios
      *----------------------------------------------------------------*
           
      *    Example of handling a warning
           PERFORM 8010-HANDLE-WARNING
           
      *    Example of handling an error
           PERFORM 8020-HANDLE-ERROR
           
      *    Example of handling a severe error
           PERFORM 8030-HANDLE-SEVERE
           
      *    Example of handling an abend condition
           PERFORM 8040-HANDLE-ABEND
           .
           
       3000-TERMINATE.
           PERFORM 8000-CHECK-FINAL-STATUS
           .
           
      *================================================================*
      * Error Handling Routines
      *================================================================*
       8000-CHECK-FINAL-STATUS.
      *----------------------------------------------------------------*
      * Determine final return code based on error counts
      *----------------------------------------------------------------*
           IF WS-SEVERE-COUNT > ZERO
               MOVE RC-SEVERE TO RETURN-CODE
           ELSE
               IF WS-ERROR-COUNT > ZERO
                   MOVE RC-ERROR TO RETURN-CODE
               ELSE
                   IF WS-WARNING-COUNT > ZERO
                       MOVE RC-WARNING TO RETURN-CODE
                   ELSE
                       MOVE RC-SUCCESS TO RETURN-CODE
                   END-IF
               END-IF
           END-IF
           .
           
       8010-HANDLE-WARNING.
      *----------------------------------------------------------------*
      * Warning handling pattern
      *----------------------------------------------------------------*
           ADD 1 TO WS-WARNING-COUNT
           MOVE 'WARNING' TO WS-ERROR-SEVERITY
           MOVE 1 TO WS-ERROR-NUMBER
           MOVE ERR-001 TO WS-ERROR-TEXT
           PERFORM 8100-LOG-ERROR
           .
           
       8020-HANDLE-ERROR.
      *----------------------------------------------------------------*
      * Error handling pattern
      *----------------------------------------------------------------*
           ADD 1 TO WS-ERROR-COUNT
           SET ERROR-OCCURRED TO TRUE
           MOVE 'ERROR' TO WS-ERROR-SEVERITY
           MOVE 2 TO WS-ERROR-NUMBER
           MOVE ERR-002 TO WS-ERROR-TEXT
           PERFORM 8100-LOG-ERROR
           .
           
       8030-HANDLE-SEVERE.
      *----------------------------------------------------------------*
      * Severe error handling pattern
      *----------------------------------------------------------------*
           ADD 1 TO WS-SEVERE-COUNT
           SET ERROR-OCCURRED TO TRUE
           MOVE 'SEVERE' TO WS-ERROR-SEVERITY
           MOVE 3 TO WS-ERROR-NUMBER
           MOVE ERR-003 TO WS-ERROR-TEXT
           PERFORM 8100-LOG-ERROR
           .
           
       8040-HANDLE-ABEND.
      *----------------------------------------------------------------*
      * Abend handling pattern
      *----------------------------------------------------------------*
           SET PERFORM-ABEND TO TRUE
           MOVE 'CRITICAL' TO WS-ERROR-SEVERITY
           MOVE 999 TO WS-ERROR-NUMBER
           MOVE 'UNRECOVERABLE ERROR - INITIATING ABEND' 
             TO WS-ERROR-TEXT
           PERFORM 8100-LOG-ERROR
           PERFORM 8500-INITIATE-ABEND
           .
           
       8100-LOG-ERROR.
      *----------------------------------------------------------------*
      * Common error logging routine
      *----------------------------------------------------------------*
           DISPLAY WS-ERROR-PREFIX '-' WS-ERROR-NUMBER ': '
                   WS-ERROR-SEVERITY
           DISPLAY WS-ERROR-TEXT
           .
           
       8500-INITIATE-ABEND.
      *----------------------------------------------------------------*
      * Controlled abend routine
      *----------------------------------------------------------------*
           DISPLAY 'ABNORMAL TERMINATION INITIATED'
           CALL 'CEE3ABD' USING RC-CRITICAL, 3
           . 