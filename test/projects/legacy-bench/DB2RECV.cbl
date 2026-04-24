       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2RECV.
      *****************************************************************
      * DB2 Recovery Manager for Online Programs                        *
      * - Handles DB2 connection failures                              *
      * - Implements retry logic                                       *
      * - Manages transaction rollback                                 *
      * - Provides recovery status tracking                            *
      *****************************************************************
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-DB2-AREA.
           EXEC SQL INCLUDE SQLCA END-EXEC.
           
       01  WS-RECOVERY-STATS.
           05 WS-RETRY-COUNT        PIC S9(4) COMP VALUE 0.
           05 WS-MAX-RETRIES        PIC S9(4) COMP VALUE 3.
           05 WS-RETRY-INTERVAL     PIC S9(8) COMP VALUE 2.
           05 WS-LAST-ERROR         PIC S9(9) COMP VALUE 0.
           
       01  WS-ERROR-AREA.
           COPY ERRHND.
           
       01  WS-DB2-REQUEST.
           COPY DB2REQ.
           
       LINKAGE SECTION.
       01  RECOVERY-REQUEST-AREA.
           05 RECV-REQUEST-TYPE     PIC X.
              88 RECV-CONNECTION         VALUE 'C'.
              88 RECV-TRANSACTION        VALUE 'T'.
              88 RECV-CURSOR             VALUE 'R'.
           05 RECV-RESPONSE-CODE    PIC S9(8) COMP.
           05 RECV-SQLCODE          PIC S9(9) COMP.
           05 RECV-ERROR-INFO.
              10 RECV-PROGRAM       PIC X(8).
              10 RECV-CURSOR        PIC X(18).
              10 RECV-MESSAGE       PIC X(80).
           05 RECV-STATUS           PIC X.
              88 RECV-SUCCESS            VALUE 'S'.
              88 RECV-FAILED            VALUE 'F'.
              88 RECV-RETRY             VALUE 'R'.
           
       PROCEDURE DIVISION USING RECOVERY-REQUEST-AREA.
           EVALUATE TRUE
               WHEN RECV-CONNECTION
                    PERFORM P100-RECOVER-CONNECTION
                       THRU P100-EXIT
               WHEN RECV-TRANSACTION
                    PERFORM P200-RECOVER-TRANSACTION
                       THRU P200-EXIT
               WHEN RECV-CURSOR
                    PERFORM P300-RECOVER-CURSOR
                       THRU P300-EXIT
           END-EVALUATE.
           
           EXEC CICS RETURN END-EXEC.
           
       P100-RECOVER-CONNECTION.
           MOVE 0 TO WS-RETRY-COUNT.
           
           PERFORM UNTIL WS-RETRY-COUNT >= WS-MAX-RETRIES
              PERFORM P110-ATTEMPT-RECONNECT
                 THRU P110-EXIT
                 
              IF RECV-SUCCESS
                 EXIT PERFORM
              ELSE
                 PERFORM P120-WAIT-INTERVAL
                    THRU P120-EXIT
                 ADD 1 TO WS-RETRY-COUNT
              END-IF
           END-PERFORM.
           
           IF WS-RETRY-COUNT >= WS-MAX-RETRIES
              SET RECV-FAILED TO TRUE
              MOVE -1 TO RECV-RESPONSE-CODE
           END-IF.
       P100-EXIT.
           EXIT.
           
       P110-ATTEMPT-RECONNECT.
           MOVE 'C' TO DB2-REQUEST-TYPE OF WS-DB2-REQUEST.
           
           EXEC CICS LINK PROGRAM('DB2ONLN')
                     COMMAREA(WS-DB2-REQUEST)
                     LENGTH(LENGTH OF WS-DB2-REQUEST)
           END-EXEC.
           
           IF DB2-RESPONSE-CODE OF WS-DB2-REQUEST = 0
              SET RECV-SUCCESS TO TRUE
              MOVE 0 TO RECV-RESPONSE-CODE
           ELSE
              SET RECV-RETRY TO TRUE
              MOVE DB2-SQLCODE OF WS-DB2-REQUEST 
                TO RECV-SQLCODE
           END-IF.
       P110-EXIT.
           EXIT.
           
       P120-WAIT-INTERVAL.
           EXEC CICS DELAY
                     INTERVAL(WS-RETRY-INTERVAL)
           END-EXEC.
       P120-EXIT.
           EXIT.
           
       P200-RECOVER-TRANSACTION.
           EXEC SQL ROLLBACK END-EXEC.
           
           IF SQLCODE = 0
              SET RECV-SUCCESS TO TRUE
              MOVE 0 TO RECV-RESPONSE-CODE
           ELSE
              SET RECV-FAILED TO TRUE
              MOVE SQLCODE TO RECV-SQLCODE
              MOVE -1 TO RECV-RESPONSE-CODE
           END-IF.
       P200-EXIT.
           EXIT.
           
       P300-RECOVER-CURSOR.
           MOVE SPACES TO WS-ERROR-AREA.
           MOVE RECV-PROGRAM TO ERR-PROGRAM.
           MOVE RECV-CURSOR TO ERR-PARAGRAPH.
           MOVE RECV-SQLCODE TO ERR-SQLCODE.
           SET ERR-WARNING TO TRUE.
           
           EXEC CICS LINK PROGRAM('ERRHNDL')
                     COMMAREA(WS-ERROR-AREA)
                     LENGTH(LENGTH OF WS-ERROR-AREA)
           END-EXEC.
           
           IF ERR-CONTINUE
              SET RECV-RETRY TO TRUE
           ELSE
              SET RECV-FAILED TO TRUE
           END-IF.
           
           MOVE ERR-MESSAGE TO RECV-MESSAGE.
       P300-EXIT.
           EXIT. 