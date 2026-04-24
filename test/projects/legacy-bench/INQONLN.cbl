       IDENTIFICATION DIVISION.
       PROGRAM-ID. INQONLN.
      *****************************************************************
      * Portfolio Online Inquiry Main Handler                           *
      * - Handles CICS portfolio inquiry transactions                   *
      * - Manages screen interactions                                   *
      * - Processes portfolio lookups                                   *
      * - Interfaces with DB2 for history                              *
      *****************************************************************
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-COMMAREA.
           COPY INQCOM.
           
       01  WS-FLAGS.
           05 WS-END-OF-SESSION       PIC X VALUE 'N'.
              88 SESSION-ACTIVE             VALUE 'N'.
              88 SESSION-TERMINATED         VALUE 'Y'.
           05 WS-RESPONSE-CODE        PIC S9(8) COMP.
           
       01  WS-ERROR-AREA.
           COPY ERRHND.
           
       01  WS-SECURITY-REQUEST.
           05 SEC-REQUEST-TYPE     PIC X.
           05 SEC-USER-ID          PIC X(8).
           05 SEC-RESOURCE-NAME    PIC X(8).
           05 SEC-ACCESS-TYPE      PIC X(8).
           05 SEC-RESPONSE-CODE    PIC S9(8) COMP.
           05 SEC-ERROR-INFO       PIC X(80).
           
       LINKAGE SECTION.
       01  DFHCOMMAREA.
           COPY INQCOM.
           
       PROCEDURE DIVISION.
           EXEC CICS HANDLE CONDITION
                     ERROR(P900-ERROR-ROUTINE)
                     PGMIDERR(P900-ERROR-ROUTINE)
                     NOTFND(P900-ERROR-ROUTINE)
           END-EXEC.
           
           PERFORM P100-PROCESS-REQUEST
              THRU P100-EXIT
              UNTIL SESSION-TERMINATED.
              
           EXEC CICS RETURN 
           END-EXEC.
           
       P100-PROCESS-REQUEST.
           MOVE LOW-VALUES TO WS-COMMAREA.
           
           EXEC CICS RECEIVE MAP('INQMAP')
                     MAPSET('INQSET')
                     INTO(WS-COMMAREA)
                     RESP(WS-RESPONSE-CODE)
           END-EXEC.
           
           EVALUATE WS-COMMAREA-FUNCTION
               WHEN 'MENU'
                    PERFORM P200-DISPLAY-MENU
                       THRU P200-EXIT
               WHEN 'INQP'
                    PERFORM P300-PORTFOLIO-INQUIRY
                       THRU P300-EXIT
               WHEN 'INQH'
                    PERFORM P400-HISTORY-INQUIRY
                       THRU P400-EXIT
               WHEN 'EXIT'
                    SET SESSION-TERMINATED TO TRUE
               WHEN OTHER
                    PERFORM P900-ERROR-ROUTINE
                       THRU P900-EXIT
           END-EVALUATE.
           
           PERFORM P050-SECURITY-CHECK
              THRU P050-EXIT.
              
           IF SEC-RESPONSE-CODE NOT = 0
              MOVE SEC-ERROR-INFO 
                TO WS-ERROR-MESSAGE
              PERFORM P900-ERROR-ROUTINE
                 THRU P900-EXIT
              EXEC CICS RETURN END-EXEC
           END-IF.
       P100-EXIT.
           EXIT.
           
       P200-DISPLAY-MENU.
           EXEC CICS SEND MAP('INQMNU')
                     MAPSET('INQSET')
                     ERASE
                     RESP(WS-RESPONSE-CODE)
           END-EXEC.
       P200-EXIT.
           EXIT.
           
       P300-PORTFOLIO-INQUIRY.
           EXEC CICS LINK PROGRAM('INQPORT')
                     COMMAREA(WS-COMMAREA)
                     LENGTH(LENGTH OF WS-COMMAREA)
                     RESP(WS-RESPONSE-CODE)
           END-EXEC.
       P300-EXIT.
           EXIT.
           
       P400-HISTORY-INQUIRY.
           EXEC CICS LINK PROGRAM('INQHIST')
                     COMMAREA(WS-COMMAREA)
                     LENGTH(LENGTH OF WS-COMMAREA)
                     RESP(WS-RESPONSE-CODE)
           END-EXEC.
       P400-EXIT.
           EXIT.
           
       P900-ERROR-ROUTINE.
           MOVE 'INQONLN' TO ERR-PROGRAM.
           MOVE 'P900-ERROR-ROUTINE' TO ERR-PARAGRAPH.
           MOVE EIBRESP TO ERR-CICS-RESP.
           MOVE EIBRESP2 TO ERR-CICS-RESP2.
           SET ERR-WARNING TO TRUE.
           
           EXEC CICS LINK PROGRAM('ERRHNDL')
                     COMMAREA(WS-ERROR-AREA)
                     LENGTH(LENGTH OF WS-ERROR-AREA)
           END-EXEC.
           
           IF ERR-ABEND
              EXEC CICS ABEND ABCODE('IERR') END-EXEC
           END-IF.
           
           MOVE ERR-MESSAGE TO WS-ERROR-MESSAGE.
       P900-EXIT.
           EXIT.
           
       P050-SECURITY-CHECK.
           MOVE 'V' TO SEC-REQUEST-TYPE.
           
           EXEC CICS ASSIGN
                     USERID(SEC-USER-ID)
           END-EXEC.
           
           EXEC CICS LINK PROGRAM('SECMGR')
                     COMMAREA(WS-SECURITY-REQUEST)
                     LENGTH(LENGTH OF WS-SECURITY-REQUEST)
           END-EXEC.
           
           IF SEC-RESPONSE-CODE = 0
              MOVE 'A' TO SEC-REQUEST-TYPE
              MOVE 'INQONLN' TO SEC-RESOURCE-NAME
              MOVE 'READ' TO SEC-ACCESS-TYPE
              
              EXEC CICS LINK PROGRAM('SECMGR')
                        COMMAREA(WS-SECURITY-REQUEST)
                        LENGTH(LENGTH OF WS-SECURITY-REQUEST)
              END-EXEC
              
              IF SEC-RESPONSE-CODE = 0
                 MOVE 'L' TO SEC-REQUEST-TYPE
                 
                 EXEC CICS LINK PROGRAM('SECMGR')
                           COMMAREA(WS-SECURITY-REQUEST)
                           LENGTH(LENGTH OF WS-SECURITY-REQUEST)
                 END-EXEC
              END-IF
           END-IF.
       P050-EXIT.
           EXIT. 