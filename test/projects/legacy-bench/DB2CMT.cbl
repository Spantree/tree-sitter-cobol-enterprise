       *================================================================*
      * Program Name: DB2CMT
      * Description: DB2 Commit Controller
      * Version: 1.0
      * Date: 2024
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2CMT.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
           01  WS-SAVEPOINT-ID      PIC X(18).
           EXEC SQL END DECLARE SECTION END-EXEC.
           
           COPY SQLCA.
           COPY DBPROC.
           COPY ERRHAND.
           
       01  WS-COMMIT-STATS.
           05  WS-COMMIT-COUNT      PIC S9(9) COMP VALUE 0.
           05  WS-ROLLBACK-COUNT    PIC S9(9) COMP VALUE 0.
           05  WS-SAVEPOINT-COUNT   PIC S9(9) COMP VALUE 0.
           
       01  WS-CURRENT-TIMESTAMP    PIC X(26).
       
       LINKAGE SECTION.
       01  LS-COMMIT-REQUEST.
           05  LS-FUNCTION         PIC X(4).
               88  FUNC-INIT         VALUE 'INIT'.
               88  FUNC-CMIT         VALUE 'CMIT'.
               88  FUNC-RBACK        VALUE 'RBAK'.
               88  FUNC-SAVE         VALUE 'SAVE'.
               88  FUNC-REST         VALUE 'REST'.
               88  FUNC-STAT         VALUE 'STAT'.
           05  LS-SAVEPOINT-NAME   PIC X(18).
           05  LS-COMMIT-PARMS.
               10  LS-RECORDS-PROC PIC S9(9) COMP.
               10  LS-COMMIT-FREQ  PIC S9(4) COMP.
               10  LS-FORCE-FLAG   PIC X(1).
                   88  LS-FORCE-COMMIT VALUE 'Y'.
           05  LS-RETURN-CODE      PIC S9(4) COMP.
           05  LS-ERROR-INFO.
               10  LS-SQLCODE      PIC S9(9) COMP.
               10  LS-ERROR-MSG    PIC X(80).
       
       PROCEDURE DIVISION USING LS-COMMIT-REQUEST.
       0000-MAIN.
           EVALUATE TRUE
               WHEN FUNC-INIT
                   PERFORM 1000-INITIALIZE
               WHEN FUNC-CMIT
                   PERFORM 2000-COMMIT
               WHEN FUNC-RBACK
                   PERFORM 3000-ROLLBACK
               WHEN FUNC-SAVE
                   PERFORM 4000-SAVEPOINT
               WHEN FUNC-REST
                   PERFORM 5000-RESTORE
               WHEN FUNC-STAT
                   PERFORM 6000-STATISTICS
               WHEN OTHER
                   MOVE 'Invalid function code' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-EVALUATE
           
           GOBACK
           .
           
       1000-INITIALIZE.
           INITIALIZE WS-COMMIT-STATS
           MOVE 0 TO LS-RETURN-CODE
           .
           
       2000-COMMIT.
           IF LS-RECORDS-PROC >= LS-COMMIT-FREQ
           OR LS-FORCE-COMMIT
               PERFORM 2100-ISSUE-COMMIT
           END-IF
           .
           
       2100-ISSUE-COMMIT.
           EXEC SQL
               COMMIT WORK
           END-EXEC
           
           IF SQLCODE = 0
               ADD 1 TO WS-COMMIT-COUNT
               MOVE 0 TO LS-RETURN-CODE
           ELSE
               MOVE SQLCODE TO LS-SQLCODE
               MOVE 'Commit failed' TO LS-ERROR-MSG
               MOVE 8 TO LS-RETURN-CODE
               PERFORM 9100-LOG-ERROR
           END-IF
           .
           
       3000-ROLLBACK.
           EXEC SQL
               ROLLBACK WORK
           END-EXEC
           
           IF SQLCODE = 0
               ADD 1 TO WS-ROLLBACK-COUNT
               MOVE 0 TO LS-RETURN-CODE
           ELSE
               MOVE SQLCODE TO LS-SQLCODE
               MOVE 'Rollback failed' TO LS-ERROR-MSG
               MOVE 8 TO LS-RETURN-CODE
               PERFORM 9100-LOG-ERROR
           END-IF
           .
           
       4000-SAVEPOINT.
           MOVE LS-SAVEPOINT-NAME TO WS-SAVEPOINT-ID
           
           EXEC SQL
               SAVEPOINT :WS-SAVEPOINT-ID ON ROLLBACK RETAIN CURSORS
           END-EXEC
           
           IF SQLCODE = 0
               ADD 1 TO WS-SAVEPOINT-COUNT
               MOVE 0 TO LS-RETURN-CODE
           ELSE
               MOVE SQLCODE TO LS-SQLCODE
               MOVE 'Savepoint creation failed' TO LS-ERROR-MSG
               MOVE 8 TO LS-RETURN-CODE
               PERFORM 9100-LOG-ERROR
           END-IF
           .
           
       5000-RESTORE.
           MOVE LS-SAVEPOINT-NAME TO WS-SAVEPOINT-ID
           
           EXEC SQL
               ROLLBACK TO SAVEPOINT :WS-SAVEPOINT-ID
           END-EXEC
           
           IF SQLCODE = 0
               ADD 1 TO WS-ROLLBACK-COUNT
               MOVE 0 TO LS-RETURN-CODE
           ELSE
               MOVE SQLCODE TO LS-SQLCODE
               MOVE 'Savepoint restore failed' TO LS-ERROR-MSG
               MOVE 8 TO LS-RETURN-CODE
               PERFORM 9100-LOG-ERROR
           END-IF
           .
           
       6000-STATISTICS.
           DISPLAY 'DB2 Commit Controller Statistics:'
           DISPLAY '  Commits:    ' WS-COMMIT-COUNT
           DISPLAY '  Rollbacks:  ' WS-ROLLBACK-COUNT
           DISPLAY '  Savepoints: ' WS-SAVEPOINT-COUNT
           .
           
       9000-ERROR-ROUTINE.
           MOVE 'DB2CMT' TO ERR-PROGRAM
           MOVE 12 TO LS-RETURN-CODE
           CALL 'ERRPROC' USING ERR-MESSAGE
           .
           
       9100-LOG-ERROR.
           CALL 'DB2ERR' USING LS-ERROR-INFO
           .