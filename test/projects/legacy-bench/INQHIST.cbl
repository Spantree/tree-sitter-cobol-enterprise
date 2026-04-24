        IDENTIFICATION DIVISION.
       PROGRAM-ID. INQHIST.
      *****************************************************************
      * Transaction History Inquiry Handler                             *
      * - Retrieves transaction history from DB2                       *
      * - Formats history data for display                            *
      * - Supports scrolling through history                          *
      *****************************************************************
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-COMMAREA.
           COPY INQCOM.
           
       01  WS-DB2-AREA.
           EXEC SQL INCLUDE SQLCA END-EXEC.
           
       01  WS-HISTORY-TABLE.
           05 WS-HISTORY-ENTRY OCCURS 10 TIMES.
              10 WS-TRANS-DATE    PIC X(10).
              10 WS-TRANS-TYPE    PIC X(4).
              10 WS-TRANS-UNITS   PIC S9(9)V99 COMP-3.
              10 WS-TRANS-PRICE   PIC S9(9)V99 COMP-3.
              10 WS-TRANS-AMOUNT  PIC S9(9)V99 COMP-3.
              
       01  WS-FLAGS.
           05 WS-RESPONSE-CODE    PIC S9(8) COMP.
           05 WS-MORE-HISTORY     PIC X VALUE 'N'.
              88 MORE-ROWS             VALUE 'Y'.
              88 NO-MORE-ROWS          VALUE 'N'.
           05 WS-ROW-COUNT        PIC S9(4) COMP.
           
       01  WS-DB2-REQUEST.
           05 DB2-REQUEST-TYPE        PIC X.
           05 DB2-RESPONSE-CODE       PIC S9(8) COMP.
           05 DB2-CONNECTION-TOKEN    PIC X(16).
           05 DB2-ERROR-INFO.
              10 DB2-SQLCODE          PIC S9(9) COMP.
              10 DB2-ERROR-MSG        PIC X(80).
           
       01  WS-CURSOR-REQUEST.
           05 CURS-REQUEST-TYPE     PIC X.
           05 CURS-NAME             PIC X(18) VALUE 'HISTORY_CURSOR'.
           05 CURS-STMT             PIC X(240).
           05 CURS-ARRAY-FETCH      PIC X VALUE 'Y'.
           05 CURS-RESPONSE-CODE    PIC S9(8) COMP.
           05 CURS-DATA-AREA        PIC X(3000).
           05 CURS-DATA-LENGTH      PIC S9(4) COMP.
           
       01  WS-RECOVERY-REQUEST.
           05 RECV-REQUEST-TYPE     PIC X.
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
           
       LINKAGE SECTION.
       01  DFHCOMMAREA.
           COPY INQCOM.
           
       PROCEDURE DIVISION.
           PERFORM P100-INIT-PROGRAM
              THRU P100-EXIT.
              
           PERFORM P200-GET-HISTORY
              THRU P200-EXIT.
              
           PERFORM P300-FORMAT-DISPLAY
              THRU P300-EXIT.
              
           EXEC CICS RETURN END-EXEC.
           
       P100-INIT-PROGRAM.
           MOVE DFHCOMMAREA TO WS-COMMAREA.
           MOVE ZEROS TO WS-ROW-COUNT.
           SET NO-MORE-ROWS TO TRUE.
           
           EXEC CICS HANDLE CONDITION
                     ERROR(P999-ERROR-ROUTINE)
           END-EXEC.
           
           PERFORM P150-DB2-CONNECT
              THRU P150-EXIT.
       P100-EXIT.
           EXIT.
           
       P150-DB2-CONNECT.
           MOVE 'C' TO DB2-REQUEST-TYPE.
           
           EXEC CICS LINK PROGRAM('DB2ONLN')
                     COMMAREA(WS-DB2-REQUEST)
                     LENGTH(LENGTH OF WS-DB2-REQUEST)
           END-EXEC.
           
           IF DB2-RESPONSE-CODE NOT = 0
              MOVE 'C' TO RECV-REQUEST-TYPE
              MOVE 'INQHIST' TO RECV-PROGRAM
              MOVE DB2-SQLCODE TO RECV-SQLCODE
              
              EXEC CICS LINK PROGRAM('DB2RECV')
                        COMMAREA(WS-RECOVERY-REQUEST)
                        LENGTH(LENGTH OF WS-RECOVERY-REQUEST)
              END-EXEC
              
              IF RECV-SUCCESS
                 PERFORM P150-DB2-CONNECT
                    THRU P150-EXIT
              ELSE
                 MOVE RECV-MESSAGE 
                   TO INQCOM-ERROR-MSG OF WS-COMMAREA
                 PERFORM P999-ERROR-ROUTINE
                    THRU P999-EXIT
              END-IF
           END-IF.
           
           MOVE DB2-CONNECTION-TOKEN 
             TO WS-DB2-TOKEN.
       P150-EXIT.
           EXIT.
           
       P200-GET-HISTORY.
           MOVE 'SELECT TRANS_DATE, TRANS_TYPE, TRANS_UNITS, ' &
                'TRANS_PRICE, TRANS_AMOUNT ' &
                'FROM POSHIST ' &
                'WHERE ACCOUNT_NO = ? ' &
                'ORDER BY TRANS_DATE DESC' 
             TO CURS-STMT.
             
           MOVE 'D' TO CURS-REQUEST-TYPE.
           EXEC CICS LINK PROGRAM('CURSMGR')
                     COMMAREA(WS-CURSOR-REQUEST)
                     LENGTH(LENGTH OF WS-CURSOR-REQUEST)
           END-EXEC.
           
           IF CURS-RESPONSE-CODE = 0
              MOVE 'O' TO CURS-REQUEST-TYPE
              EXEC CICS LINK PROGRAM('CURSMGR')
                        COMMAREA(WS-CURSOR-REQUEST)
                        LENGTH(LENGTH OF WS-CURSOR-REQUEST)
              END-EXEC
              
              IF CURS-RESPONSE-CODE = 0
                 PERFORM P250-FETCH-HISTORY
                    THRU P250-EXIT
              END-IF
           END-IF.
           
           MOVE 'C' TO CURS-REQUEST-TYPE.
           EXEC CICS LINK PROGRAM('CURSMGR')
                     COMMAREA(WS-CURSOR-REQUEST)
                     LENGTH(LENGTH OF WS-CURSOR-REQUEST)
           END-EXEC.
       P200-EXIT.
           EXIT.
           
       P250-FETCH-HISTORY.
           MOVE 'F' TO CURS-REQUEST-TYPE.
           EXEC CICS LINK PROGRAM('CURSMGR')
                     COMMAREA(WS-CURSOR-REQUEST)
                     LENGTH(LENGTH OF WS-CURSOR-REQUEST)
           END-EXEC.
           
           IF CURS-RESPONSE-CODE >= 0
              MOVE CURS-DATA-AREA TO WS-HISTORY-TABLE
           END-IF.
       P250-EXIT.
           EXIT.
           
       P300-FORMAT-DISPLAY.
           EXEC CICS SEND MAP('HISMAP')
                     MAPSET('INQSET')
                     FROM(WS-HISTORY-TABLE)
                     LENGTH(LENGTH OF WS-HISTORY-TABLE)
                     ERASE
                     RESP(WS-RESPONSE-CODE)
           END-EXEC.
       P300-EXIT.
           EXIT.
           
       P999-ERROR-ROUTINE.
           MOVE SQLCODE 
             TO INQCOM-RESPONSE-CODE OF WS-COMMAREA.
           MOVE WS-COMMAREA TO DFHCOMMAREA.
       P999-EXIT.
           EXIT.