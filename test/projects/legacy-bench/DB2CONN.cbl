       *================================================================*
      * Program Name: DB2CONN
      * Description: DB2 Connection Manager
      * Version: 1.0
      * Date: 2024
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2CONN.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
           01  WS-DB-NAME           PIC X(8).
           01  WS-PLAN-NAME         PIC X(8).
           EXEC SQL END DECLARE SECTION END-EXEC.
           
           COPY SQLCA.
           COPY DBPROC.
           COPY ERRHAND.
           
       01  WS-CONNECTION-STATE      PIC X(1).
           88  WS-CONNECTED           VALUE 'Y'.
           88  WS-DISCONNECTED        VALUE 'N'.
           
       01  WS-RETRY-COUNT          PIC S9(4) COMP VALUE 0.
       01  WS-MAX-RETRIES          PIC S9(4) COMP VALUE 3.
       
       LINKAGE SECTION.
       01  LS-DB2-REQUEST.
           05  LS-FUNCTION         PIC X(4).
               88  FUNC-CONN         VALUE 'CONN'.
               88  FUNC-DISC         VALUE 'DISC'.
               88  FUNC-STAT         VALUE 'STAT'.
           05  LS-DB-NAME          PIC X(8).
           05  LS-PLAN-NAME        PIC X(8).
           05  LS-RETURN-CODE      PIC S9(4) COMP.
           05  LS-ERROR-INFO.
               10  LS-SQLCODE      PIC S9(9) COMP.
               10  LS-ERROR-MSG    PIC X(80).
       
       PROCEDURE DIVISION USING LS-DB2-REQUEST.
       0000-MAIN.
           EVALUATE TRUE
               WHEN FUNC-CONN
                   PERFORM 1000-CONNECT
               WHEN FUNC-DISC
                   PERFORM 2000-DISCONNECT
               WHEN FUNC-STAT
                   PERFORM 3000-CHECK-STATUS
               WHEN OTHER
                   MOVE 'Invalid function code' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-EVALUATE
           
           GOBACK
           .
           
       1000-CONNECT.
           SET WS-DISCONNECTED TO TRUE
           MOVE ZERO TO WS-RETRY-COUNT
           MOVE LS-DB-NAME TO WS-DB-NAME
           MOVE LS-PLAN-NAME TO WS-PLAN-NAME
           
           PERFORM UNTIL WS-CONNECTED
                      OR WS-RETRY-COUNT >= WS-MAX-RETRIES
               
               EXEC SQL
                   CONNECT TO :WS-DB-NAME
               END-EXEC
               
               IF SQLCODE = 0
                   SET WS-CONNECTED TO TRUE
                   MOVE 0 TO LS-RETURN-CODE
               ELSE
                   ADD 1 TO WS-RETRY-COUNT
                   PERFORM 1100-HANDLE-CONN-ERROR
               END-IF
               
               IF WS-RETRY-COUNT < WS-MAX-RETRIES
                   AND NOT WS-CONNECTED
                   CALL 'DELAY' USING DB2-RETRY-WAIT
               END-IF
           END-PERFORM
           .
           
       1100-HANDLE-CONN-ERROR.
           MOVE SQLCODE TO LS-SQLCODE
           
           EVALUATE SQLCODE
               WHEN -30081
                   MOVE 'Maximum connections exceeded' 
                     TO LS-ERROR-MSG
               WHEN -99999
                   MOVE 'Network error connecting to DB2' 
                     TO LS-ERROR-MSG
               WHEN OTHER
                   MOVE 'General DB2 connection error' 
                     TO LS-ERROR-MSG
           END-EVALUATE
           
           MOVE 12 TO LS-RETURN-CODE
           .
           
       2000-DISCONNECT.
           IF WS-CONNECTED
               EXEC SQL
                   COMMIT WORK
               END-EXEC
               
               EXEC SQL
                   CONNECT RESET
               END-EXEC
               
               IF SQLCODE = 0
                   SET WS-DISCONNECTED TO TRUE
                   MOVE 0 TO LS-RETURN-CODE
               ELSE
                   MOVE SQLCODE TO LS-SQLCODE
                   MOVE 'Error disconnecting from DB2' 
                     TO LS-ERROR-MSG
                   MOVE 8 TO LS-RETURN-CODE
               END-IF
           END-IF
           .
           
       3000-CHECK-STATUS.
           EXEC SQL
               SELECT CURRENT SERVER
               INTO :WS-DB-NAME
               FROM SYSIBM.SYSDUMMY1
           END-EXEC
           
           IF SQLCODE = 0
               SET WS-CONNECTED TO TRUE
               MOVE 0 TO LS-RETURN-CODE
           ELSE
               SET WS-DISCONNECTED TO TRUE
               MOVE SQLCODE TO LS-SQLCODE
               MOVE 'DB2 connection not active' 
                 TO LS-ERROR-MSG
               MOVE 4 TO LS-RETURN-CODE
           END-IF
           .
           
       9000-ERROR-ROUTINE.
           MOVE 'DB2CONN' TO ERR-PROGRAM
           MOVE 12 TO LS-RETURN-CODE
           CALL 'ERRPROC' USING ERR-MESSAGE
           .