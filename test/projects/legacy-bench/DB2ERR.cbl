      *================================================================*
      * Program Name: DB2ERR
      * Description: DB2 SQL Error Handler
      * Version: 1.0
      * Date: 2024
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2ERR.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
           01  WS-ERRLOG-REC.
               COPY DBTBLS REPLACING 
                   ==POSHIST-RECORD== BY ==WS-POSHIST-REC==
                   ==ERRLOG-RECORD== BY ==WS-ERRLOG-REC==.
           EXEC SQL END DECLARE SECTION END-EXEC.
           
           COPY SQLCA.
           COPY DBPROC.
           COPY ERRHAND.
           
       01  WS-CURRENT-TIMESTAMP    PIC X(26).
       01  WS-FORMATTED-SQLCODE    PIC -Z(8)9.
       
       01  WS-ERROR-CATEGORIES.
           05  WS-DEADLOCK         PIC S9(8) VALUE -911.
           05  WS-TIMEOUT          PIC S9(8) VALUE -913.
           05  WS-CONNECTION-ERROR PIC S9(8) VALUE -30081.
           05  WS-DUP-KEY          PIC S9(8) VALUE -803.
           05  WS-NOT-FOUND        PIC S9(8) VALUE +100.
       
       LINKAGE SECTION.
       01  LS-ERROR-REQUEST.
           05  LS-FUNCTION         PIC X(4).
               88  FUNC-LOG          VALUE 'LOG '.
               88  FUNC-DIAG         VALUE 'DIAG'.
               88  FUNC-RETR         VALUE 'RETR'.
           05  LS-PROGRAM-ID       PIC X(8).
           05  LS-ERROR-INFO.
               10  LS-SQLCODE      PIC S9(9) COMP.
               10  LS-SQLSTATE     PIC X(5).
               10  LS-ERROR-TEXT   PIC X(80).
           05  LS-ADDITIONAL-INFO  PIC X(100).
           05  LS-RETURN-CODE      PIC S9(4) COMP.
           05  LS-RETRY-FLAG       PIC X(1).
               88  LS-SHOULD-RETRY   VALUE 'Y'.
               88  LS-NO-RETRY       VALUE 'N'.
       
       PROCEDURE DIVISION USING LS-ERROR-REQUEST.
       0000-MAIN.
           EVALUATE TRUE
               WHEN FUNC-LOG
                   PERFORM 1000-LOG-ERROR
               WHEN FUNC-DIAG
                   PERFORM 2000-DIAGNOSE-ERROR
               WHEN FUNC-RETR
                   PERFORM 3000-RETRIEVE-ERROR
               WHEN OTHER
                   MOVE 'Invalid function code' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-EVALUATE
           
           GOBACK
           .
           
       1000-LOG-ERROR.
           INITIALIZE WS-ERRLOG-REC
           
           ACCEPT WS-CURRENT-TIMESTAMP FROM TIME STAMP
           
           MOVE WS-CURRENT-TIMESTAMP TO EL-ERROR-TIMESTAMP
           MOVE LS-PROGRAM-ID       TO EL-PROGRAM-ID
           MOVE 'D'                 TO EL-ERROR-TYPE
           
           PERFORM 1100-SET-SEVERITY
           
           MOVE LS-SQLCODE TO WS-FORMATTED-SQLCODE
           STRING 'SQLCODE: ' WS-FORMATTED-SQLCODE
                  ' STATE: ' LS-SQLSTATE
                  DELIMITED BY SIZE
                  INTO EL-ERROR-CODE
           
           MOVE LS-ERROR-TEXT      TO EL-ERROR-MESSAGE
           MOVE FUNCTION CURRENT-DATE(1:10) 
                                  TO EL-PROCESS-DATE
           MOVE FUNCTION CURRENT-DATE(12:8) 
                                  TO EL-PROCESS-TIME
           MOVE SPACES             TO EL-USER-ID
           MOVE LS-ADDITIONAL-INFO TO EL-ADDITIONAL-INFO
           
           PERFORM 1200-INSERT-ERROR
           .
           
       1100-SET-SEVERITY.
           EVALUATE LS-SQLCODE
               WHEN WS-DEADLOCK
               WHEN WS-TIMEOUT
                   MOVE 2 TO EL-ERROR-SEVERITY
                   SET LS-SHOULD-RETRY TO TRUE
               WHEN WS-CONNECTION-ERROR
                   MOVE 4 TO EL-ERROR-SEVERITY
                   SET LS-NO-RETRY TO TRUE
               WHEN WS-DUP-KEY
                   MOVE 1 TO EL-ERROR-SEVERITY
                   SET LS-NO-RETRY TO TRUE
               WHEN WS-NOT-FOUND
                   MOVE 1 TO EL-ERROR-SEVERITY
                   SET LS-NO-RETRY TO TRUE
               WHEN OTHER
                   IF LS-SQLCODE < 0
                       MOVE 3 TO EL-ERROR-SEVERITY
                       SET LS-NO-RETRY TO TRUE
                   ELSE
                       MOVE 1 TO EL-ERROR-SEVERITY
                       SET LS-NO-RETRY TO TRUE
                   END-IF
           END-EVALUATE
           .
           
       1200-INSERT-ERROR.
           EXEC SQL
               INSERT INTO ERRLOG
               VALUES (:WS-ERRLOG-REC)
           END-EXEC
           
           IF SQLCODE = 0
               MOVE 0 TO LS-RETURN-CODE
           ELSE
               MOVE 'Error logging to ERRLOG' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       2000-DIAGNOSE-ERROR.
           EVALUATE LS-SQLCODE
               WHEN WS-DEADLOCK
                   MOVE 'Deadlock detected - retry transaction'
                     TO LS-ERROR-TEXT
                   MOVE 4 TO LS-RETURN-CODE
               WHEN WS-TIMEOUT
                   MOVE 'Timeout occurred - retry transaction'
                     TO LS-ERROR-TEXT
                   MOVE 4 TO LS-RETURN-CODE
               WHEN WS-CONNECTION-ERROR
                   MOVE 'DB2 connection error - check availability'
                     TO LS-ERROR-TEXT
                   MOVE 12 TO LS-RETURN-CODE
               WHEN WS-DUP-KEY
                   MOVE 'Duplicate key violation'
                     TO LS-ERROR-TEXT
                   MOVE 8 TO LS-RETURN-CODE
               WHEN OTHER
                   IF LS-SQLCODE < 0
                       MOVE 'Unhandled DB2 error'
                         TO LS-ERROR-TEXT
                       MOVE 12 TO LS-RETURN-CODE
                   ELSE
                       MOVE 'DB2 warning condition'
                         TO LS-ERROR-TEXT
                       MOVE 4 TO LS-RETURN-CODE
                   END-IF
           END-EVALUATE
           .
           
       3000-RETRIEVE-ERROR.
           EXEC SQL
               SELECT ERROR_MESSAGE,
                      ERROR_SEVERITY,
                      ADDITIONAL_INFO
               INTO :EL-ERROR-MESSAGE,
                    :EL-ERROR-SEVERITY,
                    :EL-ADDITIONAL-INFO
               FROM ERRLOG
               WHERE PROGRAM_ID = :LS-PROGRAM-ID
               AND ERROR_TIMESTAMP = 
                   (SELECT MAX(ERROR_TIMESTAMP)
                    FROM ERRLOG
                    WHERE PROGRAM_ID = :LS-PROGRAM-ID)
           END-EXEC
           
           IF SQLCODE = 0
               MOVE EL-ERROR-MESSAGE TO LS-ERROR-TEXT
               MOVE EL-ERROR-SEVERITY TO LS-RETURN-CODE
           ELSE
               MOVE 'No error history found' TO LS-ERROR-TEXT
               MOVE 4 TO LS-RETURN-CODE
           END-IF
           .
           
       9000-ERROR-ROUTINE.
           MOVE 'DB2ERR' TO ERR-PROGRAM
           MOVE 12 TO LS-RETURN-CODE
           CALL 'ERRPROC' USING ERR-MESSAGE
           .