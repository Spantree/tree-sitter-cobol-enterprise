       IDENTIFICATION DIVISION.
       PROGRAM-ID. RTNCDE00.
      *****************************************************************
      * Standard Return Code Handler                                    *
      * - Manages standardized return codes across system              *
      * - Provides return code analysis and reporting                  *
      * - Integrates with error handling framework                     *
      * - Maintains return code audit trail                            *
      *****************************************************************
       
       ENVIRONMENT DIVISION.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-CURRENT-TIME.
           05 WS-CURRENT-DATE.
              10 WS-CURRENT-YEAR     PIC 9(4).
              10 WS-CURRENT-MONTH    PIC 9(2).
              10 WS-CURRENT-DAY      PIC 9(2).
           05 WS-CURRENT-HOURS       PIC 9(2).
           05 WS-CURRENT-MINUTES     PIC 9(2).
           05 WS-CURRENT-SECONDS     PIC 9(2).
           05 WS-CURRENT-MILLISEC    PIC 9(2).
           
       01  WS-DB2-AREA.
           EXEC SQL INCLUDE SQLCA END-EXEC.
           
       LINKAGE SECTION.
       01  RC-REQUEST-AREA.
           COPY RTNCODE.
           
       PROCEDURE DIVISION USING RC-REQUEST-AREA.
           EVALUATE TRUE
               WHEN RC-INITIALIZE
                    PERFORM P100-INIT-RETURN-CODES
                       THRU P100-EXIT
               WHEN RC-SET-CODE
                    PERFORM P200-SET-RETURN-CODE
                       THRU P200-EXIT
               WHEN RC-GET-CODE
                    PERFORM P300-GET-RETURN-CODE
                       THRU P300-EXIT
               WHEN RC-LOG-CODE
                    PERFORM P400-LOG-RETURN-CODE
                       THRU P400-EXIT
               WHEN RC-ANALYZE
                    PERFORM P500-ANALYZE-CODES
                       THRU P500-EXIT
           END-EVALUATE.
           
           GOBACK.
           
       P100-INIT-RETURN-CODES.
           INITIALIZE RC-CODES-AREA.
           MOVE SPACES TO RC-PROGRAM-ID.
           MOVE 0 TO RC-CURRENT-CODE.
           MOVE 0 TO RC-HIGHEST-CODE.
           SET RC-STATUS-SUCCESS TO TRUE.
           MOVE 0 TO RC-RESPONSE-CODE.
       P100-EXIT.
           EXIT.
           
       P200-SET-RETURN-CODE.
           IF RC-NEW-CODE > RC-HIGHEST-CODE
              MOVE RC-NEW-CODE TO RC-HIGHEST-CODE
           END-IF.
           
           MOVE RC-NEW-CODE TO RC-CURRENT-CODE.
           
           EVALUATE RC-NEW-CODE
               WHEN 0
                    SET RC-STATUS-SUCCESS TO TRUE
               WHEN 1 THRU 4
                    SET RC-STATUS-WARNING TO TRUE
               WHEN 5 THRU 8
                    SET RC-STATUS-ERROR TO TRUE
               WHEN OTHER
                    SET RC-STATUS-SEVERE TO TRUE
           END-EVALUATE.
           
           MOVE 0 TO RC-RESPONSE-CODE.
       P200-EXIT.
           EXIT.
           
       P300-GET-RETURN-CODE.
           MOVE RC-CURRENT-CODE TO RC-RETURN-VALUE.
           MOVE RC-HIGHEST-CODE TO RC-HIGHEST-RETURN.
           MOVE RC-STATUS TO RC-RETURN-STATUS.
           MOVE 0 TO RC-RESPONSE-CODE.
       P300-EXIT.
           EXIT.
           
       P400-LOG-RETURN-CODE.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-TIME.
           
           EXEC SQL
                INSERT INTO RTNCODES
                (TIMESTAMP,
                 PROGRAM_ID,
                 RETURN_CODE,
                 HIGHEST_CODE,
                 STATUS_CODE,
                 MESSAGE_TEXT)
                VALUES
                (:WS-CURRENT-TIME,
                 :RC-PROGRAM-ID,
                 :RC-CURRENT-CODE,
                 :RC-HIGHEST-CODE,
                 :RC-STATUS,
                 :RC-MESSAGE)
           END-EXEC.
           
           IF SQLCODE = 0
              MOVE 0 TO RC-RESPONSE-CODE
           ELSE
              MOVE 8 TO RC-RESPONSE-CODE
           END-IF.
       P400-EXIT.
           EXIT.
           
       P500-ANALYZE-CODES.
           EXEC SQL
                SELECT COUNT(*),
                       MAX(RETURN_CODE),
                       MIN(RETURN_CODE)
                INTO :RC-TOTAL-CODES,
                     :RC-MAX-CODE,
                     :RC-MIN-CODE
                FROM RTNCODES
                WHERE PROGRAM_ID = :RC-PROGRAM-ID
                  AND TIMESTAMP >= :RC-START-TIME
                  AND TIMESTAMP <= :RC-END-TIME
           END-EXEC.
           
           IF SQLCODE = 0
              MOVE 0 TO RC-RESPONSE-CODE
           ELSE
              MOVE 8 TO RC-RESPONSE-CODE
           END-IF.
       P500-EXIT.
           EXIT.