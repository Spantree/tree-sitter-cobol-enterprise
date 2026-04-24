        IDENTIFICATION DIVISION.
       PROGRAM-ID. INQPORT.
      *****************************************************************
      * Portfolio Position Inquiry Handler                              *
      * - Retrieves current portfolio positions                        *
      * - Formats position data for display                            *
      * - Handles VSAM and DB2 access                                  *
      *****************************************************************
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-COMMAREA.
           COPY INQCOM.
           
       01  WS-POSITION-RECORD.
           COPY POSREC.
           
       01  WS-DB2-POSITION.
           EXEC SQL INCLUDE SQLPOS END-EXEC.
           
       01  WS-FLAGS.
           05 WS-RESPONSE-CODE        PIC S9(8) COMP.
           05 WS-POSITION-FOUND       PIC X VALUE 'N'.
              88 POSITION-EXISTS           VALUE 'Y'.
              88 NO-POSITION               VALUE 'N'.
              
       01  WS-MAP-FIELDS.
           05 WS-ACCOUNT-LABEL        PIC X(10) VALUE 'Account:'.
           05 WS-FUND-LABEL          PIC X(10) VALUE 'Fund ID:'.
           05 WS-UNITS-LABEL         PIC X(10) VALUE 'Units:'.
           05 WS-COST-LABEL          PIC X(15) VALUE 'Cost Basis:'.
           05 WS-VALUE-LABEL         PIC X(15) VALUE 'Market Value:'.
           
       LINKAGE SECTION.
       01  DFHCOMMAREA.
           COPY INQCOM.
           
       PROCEDURE DIVISION.
           PERFORM P100-INIT-PROGRAM
              THRU P100-EXIT.
              
           PERFORM P200-GET-POSITION
              THRU P200-EXIT.
              
           IF POSITION-EXISTS
              PERFORM P300-FORMAT-DISPLAY
                 THRU P300-EXIT
           ELSE
              PERFORM P900-NOT-FOUND
                 THRU P900-EXIT
           END-IF.
              
           EXEC CICS RETURN END-EXEC.
           
       P100-INIT-PROGRAM.
           MOVE LOW-VALUES TO WS-POSITION-RECORD
           MOVE DFHCOMMAREA TO WS-COMMAREA.
           
           EXEC CICS HANDLE CONDITION
                     ERROR(P999-ERROR-ROUTINE)
                     NOTFND(P900-NOT-FOUND)
           END-EXEC.
       P100-EXIT.
           EXIT.
           
       P200-GET-POSITION.
           MOVE WS-COMMAREA-ACCOUNT-NO 
             TO POSITION-ACCOUNT OF WS-POSITION-RECORD.
             
           EXEC CICS READ FILE('POSFILE')
                     INTO(WS-POSITION-RECORD)
                     RIDFLD(POSITION-ACCOUNT OF WS-POSITION-RECORD)
                     RESP(WS-RESPONSE-CODE)
           END-EXEC.
           
           IF WS-RESPONSE-CODE = DFHRESP(NORMAL)
              SET POSITION-EXISTS TO TRUE
           ELSE
              SET NO-POSITION TO TRUE
           END-IF.
       P200-EXIT.
           EXIT.
           
       P300-FORMAT-DISPLAY.
           EXEC CICS SEND MAP('POSMAP')
                     MAPSET('INQSET')
                     FROM(WS-POSITION-RECORD)
                     ERASE
                     RESP(WS-RESPONSE-CODE)
           END-EXEC.
       P300-EXIT.
           EXIT.
           
       P900-NOT-FOUND.
           MOVE 'Position not found for account' 
             TO INQCOM-ERROR-MSG OF WS-COMMAREA.
           MOVE WS-COMMAREA TO DFHCOMMAREA.
       P900-EXIT.
           EXIT.
           
       P999-ERROR-ROUTINE.
           MOVE 'Error accessing position data' 
             TO INQCOM-ERROR-MSG OF WS-COMMAREA.
           MOVE WS-RESPONSE-CODE 
             TO INQCOM-RESPONSE-CODE OF WS-COMMAREA.
           MOVE WS-COMMAREA TO DFHCOMMAREA.
       P999-EXIT.
           EXIT.