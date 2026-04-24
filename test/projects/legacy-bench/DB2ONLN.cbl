        IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2ONLN.
      *****************************************************************
      * Online DB2 Connection Manager                                   *
      * - Manages DB2 connection pool                                  *
      * - Optimizes connection reuse                                   *
      * - Handles connection errors                                    *
      * - Monitors connection status                                   *
      *****************************************************************
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-DB2-AREA.
           EXEC SQL INCLUDE SQLCA END-EXEC.
           
       01  WS-POOL-STATS.
           05 WS-TOTAL-CONNECTIONS    PIC S9(8) COMP VALUE 0.
           05 WS-ACTIVE-CONNECTIONS   PIC S9(8) COMP VALUE 0.
           05 WS-AVAILABLE-CONNECTIONS PIC S9(8) COMP VALUE 0.
           05 WS-MAX-CONNECTIONS      PIC S9(8) COMP VALUE 100.
           
       01  WS-ERROR-AREA.
           COPY ERRHND.
           
       LINKAGE SECTION.
       01  DB2-REQUEST-AREA.
           05 DB2-REQUEST-TYPE        PIC X.
              88 DB2-CONNECT              VALUE 'C'.
              88 DB2-DISCONNECT           VALUE 'D'.
              88 DB2-STATUS               VALUE 'S'.
           05 DB2-RESPONSE-CODE       PIC S9(8) COMP.
           05 DB2-CONNECTION-TOKEN    PIC X(16).
           05 DB2-ERROR-INFO.
              10 DB2-SQLCODE          PIC S9(9) COMP.
              10 DB2-ERROR-MSG        PIC X(80).
           
       PROCEDURE DIVISION USING DB2-REQUEST-AREA.
           EVALUATE TRUE
               WHEN DB2-CONNECT
                    PERFORM P100-PROCESS-CONNECT
                       THRU P100-EXIT
               WHEN DB2-DISCONNECT
                    PERFORM P200-PROCESS-DISCONNECT
                       THRU P200-EXIT
               WHEN DB2-STATUS
                    PERFORM P300-CHECK-STATUS
                       THRU P300-EXIT
           END-EVALUATE.
           
           EXEC CICS RETURN END-EXEC.
           
       P100-PROCESS-CONNECT.
           IF WS-ACTIVE-CONNECTIONS < WS-MAX-CONNECTIONS
              PERFORM P110-ESTABLISH-CONNECTION
                 THRU P110-EXIT
           ELSE
              MOVE 'Maximum connections reached' 
                TO DB2-ERROR-MSG
              MOVE -1 TO DB2-RESPONSE-CODE
           END-IF.
       P100-EXIT.
           EXIT.
           
       P110-ESTABLISH-CONNECTION.
           EXEC SQL CONNECT TO POSMVP END-EXEC.
           
           IF SQLCODE = 0
              ADD 1 TO WS-ACTIVE-CONNECTIONS
              MOVE SQLCODE TO DB2-SQLCODE
              MOVE 0 TO DB2-RESPONSE-CODE
              PERFORM P120-GENERATE-TOKEN
                 THRU P120-EXIT
           ELSE
              MOVE SQLCODE TO DB2-SQLCODE
              MOVE SQLERRMC TO DB2-ERROR-MSG
              MOVE -1 TO DB2-RESPONSE-CODE
           END-IF.
       P110-EXIT.
           EXIT.
           
       P120-GENERATE-TOKEN.
           MOVE FUNCTION CURRENT-DATE TO DB2-CONNECTION-TOKEN.
           STRING DB2-CONNECTION-TOKEN DELIMITED BY SIZE
                  WS-ACTIVE-CONNECTIONS DELIMITED BY SIZE
                  INTO DB2-CONNECTION-TOKEN.
       P120-EXIT.
           EXIT.
           
       P200-PROCESS-DISCONNECT.
           EXEC SQL DISCONNECT END-EXEC.
           
           IF SQLCODE = 0
              SUBTRACT 1 FROM WS-ACTIVE-CONNECTIONS
              MOVE 0 TO DB2-RESPONSE-CODE
           ELSE
              MOVE SQLCODE TO DB2-SQLCODE
              MOVE SQLERRMC TO DB2-ERROR-MSG
              MOVE -1 TO DB2-RESPONSE-CODE
           END-IF.
       P200-EXIT.
           EXIT.
           
       P300-CHECK-STATUS.
           EXEC SQL SELECT CURRENT SERVER 
                    INTO :DB2-ERROR-MSG
           END-EXEC.
           
           IF SQLCODE = 0
              MOVE 0 TO DB2-RESPONSE-CODE
           ELSE
              MOVE SQLCODE TO DB2-SQLCODE
              MOVE -1 TO DB2-RESPONSE-CODE
           END-IF.
           
           MOVE WS-ACTIVE-CONNECTIONS 
             TO DB2-RESPONSE-CODE.
       P300-EXIT.
           EXIT.