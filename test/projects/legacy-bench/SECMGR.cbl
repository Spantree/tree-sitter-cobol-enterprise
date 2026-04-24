       IDENTIFICATION DIVISION.
       PROGRAM-ID. SECMGR.
      *****************************************************************
      * Security Manager for Online Programs                            *
      * - Validates CICS user credentials                              *
      * - Manages DB2 authorization                                    *
      * - Implements access control                                    *
      * - Maintains security audit trail                               *
      *****************************************************************
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-DB2-AREA.
           EXEC SQL INCLUDE SQLCA END-EXEC.
           
       01  WS-SECURITY-AREA.
           05 WS-USER-ID           PIC X(8).
           05 WS-TERMINAL-ID       PIC X(4).
           05 WS-TRANSACTION-ID    PIC X(4).
           05 WS-PROGRAM-NAME      PIC X(8).
           05 WS-ACCESS-TYPE       PIC X(8).
           05 WS-TIMESTAMP         PIC X(26).
           
       01  WS-ERROR-AREA.
           COPY ERRHND.
           
       LINKAGE SECTION.
       01  SECURITY-REQUEST-AREA.
           05 SEC-REQUEST-TYPE     PIC X.
              88 SEC-VALIDATE           VALUE 'V'.
              88 SEC-AUTHORIZE          VALUE 'A'.
              88 SEC-AUDIT              VALUE 'L'.
           05 SEC-USER-ID          PIC X(8).
           05 SEC-RESOURCE-NAME    PIC X(8).
           05 SEC-ACCESS-TYPE      PIC X(8).
           05 SEC-RESPONSE-CODE    PIC S9(8) COMP.
           05 SEC-ERROR-INFO       PIC X(80).
           
       PROCEDURE DIVISION USING SECURITY-REQUEST-AREA.
           EVALUATE TRUE
               WHEN SEC-VALIDATE
                    PERFORM P100-VALIDATE-USER
                       THRU P100-EXIT
               WHEN SEC-AUTHORIZE
                    PERFORM P200-CHECK-AUTH
                       THRU P200-EXIT
               WHEN SEC-AUDIT
                    PERFORM P300-LOG-ACCESS
                       THRU P300-EXIT
           END-EVALUATE.
           
           EXEC CICS RETURN END-EXEC.
           
       P100-VALIDATE-USER.
           EXEC CICS ASSIGN
                     USERID(WS-USER-ID)
                     RESP(SEC-RESPONSE-CODE)
           END-EXEC.
           
           IF SEC-RESPONSE-CODE = DFHRESP(NORMAL)
              IF SEC-USER-ID = WS-USER-ID
                 MOVE 0 TO SEC-RESPONSE-CODE
              ELSE
                 MOVE 'User validation failed' 
                   TO SEC-ERROR-INFO
                 MOVE 8 TO SEC-RESPONSE-CODE
              END-IF
           ELSE
              MOVE 'Unable to obtain user credentials' 
                TO SEC-ERROR-INFO
              MOVE 12 TO SEC-RESPONSE-CODE
           END-IF.
       P100-EXIT.
           EXIT.
           
       P200-CHECK-AUTH.
           EXEC SQL
                SELECT COUNT(*)
                INTO :WS-DB2-AREA
                FROM AUTHFILE
                WHERE USER_ID = :SEC-USER-ID
                  AND RESOURCE = :SEC-RESOURCE-NAME
                  AND ACCESS_TYPE = :SEC-ACCESS-TYPE
           END-EXEC.
           
           EVALUATE SQLCODE
               WHEN 0
                    IF WS-DB2-AREA > 0
                       MOVE 0 TO SEC-RESPONSE-CODE
                    ELSE
                       MOVE 'Access denied' 
                         TO SEC-ERROR-INFO
                       MOVE 8 TO SEC-RESPONSE-CODE
                    END-IF
               WHEN OTHER
                    MOVE 'Authorization check failed' 
                      TO SEC-ERROR-INFO
                    MOVE 12 TO SEC-RESPONSE-CODE
           END-EVALUATE.
       P200-EXIT.
           EXIT.
           
       P300-LOG-ACCESS.
           MOVE FUNCTION CURRENT-DATE TO WS-TIMESTAMP.
           
           EXEC CICS ASSIGN
                     USERID(WS-USER-ID)
                     TERMID(WS-TERMINAL-ID)
                     TRANSID(WS-TRANSACTION-ID)
           END-EXEC.
           
           MOVE SEC-RESOURCE-NAME TO WS-PROGRAM-NAME.
           MOVE SEC-ACCESS-TYPE TO WS-ACCESS-TYPE.
           
           EXEC SQL
                INSERT INTO AUDITLOG
                (TIMESTAMP, USER_ID, TERMINAL_ID, 
                 TRANS_ID, PROGRAM, ACCESS_TYPE)
                VALUES
                (:WS-TIMESTAMP, :WS-USER-ID, :WS-TERMINAL-ID,
                 :WS-TRANSACTION-ID, :WS-PROGRAM-NAME, 
                 :WS-ACCESS-TYPE)
           END-EXEC.
           
           IF SQLCODE = 0
              MOVE 0 TO SEC-RESPONSE-CODE
           ELSE
              MOVE 'Audit logging failed' 
                TO SEC-ERROR-INFO
              MOVE 12 TO SEC-RESPONSE-CODE
           END-IF.
       P300-EXIT.
           EXIT.