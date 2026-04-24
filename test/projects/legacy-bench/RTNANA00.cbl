       IDENTIFICATION DIVISION.
       PROGRAM-ID. RTNANA00.
      *****************************************************************
      * Return Code Analysis Utility                                    *
      * - Analyzes return codes across system                          *
      * - Generates trend analysis                                     *
      * - Identifies error patterns                                    *
      * - Produces analysis reports                                    *
      *****************************************************************
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REPORT-FILE
               ASSIGN TO RPTFILE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-REPORT-STATUS.
           
       DATA DIVISION.
       FILE SECTION.
       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  REPORT-RECORD              PIC X(133).
       
       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 WS-REPORT-STATUS        PIC XX.
           
       01  WS-DB2-AREA.
           EXEC SQL INCLUDE SQLCA END-EXEC.
           
       01  WS-CURRENT-DATE-DATA.
           05 WS-CURRENT-DATE.
              10 WS-CURRENT-YEAR     PIC 9(4).
              10 WS-CURRENT-MONTH    PIC 9(2).
              10 WS-CURRENT-DAY      PIC 9(2).
           05 WS-CURRENT-TIME.
              10 WS-CURRENT-HOUR     PIC 9(2).
              10 WS-CURRENT-MINUTE   PIC 9(2).
              10 WS-CURRENT-SECOND   PIC 9(2).
              10 WS-CURRENT-MS       PIC 9(2).
           
       01  WS-ANALYSIS-AREA.
           05 WS-START-TIME          PIC X(26).
           05 WS-END-TIME            PIC X(26).
           05 WS-PROGRAM-COUNT       PIC S9(8) COMP.
           05 WS-ERROR-COUNT         PIC S9(8) COMP.
           05 WS-WARNING-COUNT       PIC S9(8) COMP.
           05 WS-SUCCESS-COUNT       PIC S9(8) COMP.
           05 WS-SEVERE-COUNT        PIC S9(8) COMP.
           
       01  WS-REPORT-LINES.
           05 WS-HEADER1.
              10 FILLER              PIC X(133) VALUE ALL '-'.
           05 WS-HEADER2.
              10 FILLER              PIC X(30) VALUE SPACES.
              10 FILLER              PIC X(73) 
                 VALUE 'Return Code Analysis Report'.
              10 FILLER              PIC X(30) VALUE SPACES.
           05 WS-HEADER3.
              10 FILLER              PIC X(15) VALUE 'Report Date:'.
              10 WS-RPT-DATE         PIC X(10).
              10 FILLER              PIC X(5)  VALUE SPACES.
              10 FILLER              PIC X(15) VALUE 'Report Time:'.
              10 WS-RPT-TIME         PIC X(8).
              10 FILLER              PIC X(80) VALUE SPACES.
           05 WS-DETAIL-HDR.
              10 FILLER              PIC X(8)  VALUE 'Program'.
              10 FILLER              PIC X(2)  VALUE SPACES.
              10 FILLER              PIC X(10) VALUE 'Total'.
              10 FILLER              PIC X(2)  VALUE SPACES.
              10 FILLER              PIC X(10) VALUE 'Success'.
              10 FILLER              PIC X(2)  VALUE SPACES.
              10 FILLER              PIC X(10) VALUE 'Warning'.
              10 FILLER              PIC X(2)  VALUE SPACES.
              10 FILLER              PIC X(10) VALUE 'Error'.
              10 FILLER              PIC X(2)  VALUE SPACES.
              10 FILLER              PIC X(10) VALUE 'Severe'.
              10 FILLER              PIC X(65) VALUE SPACES.
           05 WS-DETAIL-LINE.
              10 WS-DTL-PROGRAM      PIC X(8).
              10 FILLER              PIC X(2)  VALUE SPACES.
              10 WS-DTL-TOTAL        PIC ZZZ,ZZ9.
              10 FILLER              PIC X(3)  VALUE SPACES.
              10 WS-DTL-SUCCESS      PIC ZZZ,ZZ9.
              10 FILLER              PIC X(3)  VALUE SPACES.
              10 WS-DTL-WARNING      PIC ZZZ,ZZ9.
              10 FILLER              PIC X(3)  VALUE SPACES.
              10 WS-DTL-ERROR        PIC ZZZ,ZZ9.
              10 FILLER              PIC X(3)  VALUE SPACES.
              10 WS-DTL-SEVERE       PIC ZZZ,ZZ9.
              10 FILLER              PIC X(65) VALUE SPACES.
              
       PROCEDURE DIVISION.
           PERFORM P100-INIT-PROGRAM
              THRU P100-EXIT.
              
           PERFORM P200-PROCESS-ANALYSIS
              THRU P200-EXIT.
              
           PERFORM P300-GENERATE-REPORT
              THRU P300-EXIT.
              
           PERFORM P900-CLOSE-FILES
              THRU P900-EXIT.
              
           GOBACK.
           
       P100-INIT-PROGRAM.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA.
           
           OPEN OUTPUT REPORT-FILE.
           IF WS-REPORT-STATUS NOT = '00'
              DISPLAY 'Error opening report file: ' WS-REPORT-STATUS
              MOVE 12 TO RETURN-CODE
              GOBACK
           END-IF.
           
           INITIALIZE WS-ANALYSIS-AREA.
       P100-EXIT.
           EXIT.
           
       P200-PROCESS-ANALYSIS.
           EXEC SQL
                DECLARE PRGCUR CURSOR FOR
                SELECT PROGRAM_ID,
                       COUNT(*) AS TOTAL,
                       COUNT(CASE WHEN STATUS_CODE = 'S' THEN 1 END),
                       COUNT(CASE WHEN STATUS_CODE = 'W' THEN 1 END),
                       COUNT(CASE WHEN STATUS_CODE = 'E' THEN 1 END),
                       COUNT(CASE WHEN STATUS_CODE = 'F' THEN 1 END)
                FROM RTNCODES
                GROUP BY PROGRAM_ID
                ORDER BY PROGRAM_ID
           END-EXEC.
           
           EXEC SQL OPEN PRGCUR END-EXEC.
           
           PERFORM P210-WRITE-HEADERS
              THRU P210-EXIT.
              
           PERFORM P220-PROCESS-DETAIL
              THRU P220-EXIT
              UNTIL SQLCODE = 100.
              
           EXEC SQL CLOSE PRGCUR END-EXEC.
       P200-EXIT.
           EXIT.
           
       P210-WRITE-HEADERS.
           WRITE REPORT-RECORD FROM WS-HEADER1.
           WRITE REPORT-RECORD FROM WS-HEADER2.
           
           MOVE WS-CURRENT-DATE TO WS-RPT-DATE.
           STRING WS-CURRENT-HOUR ':' WS-CURRENT-MINUTE ':'
                  WS-CURRENT-SECOND
                  DELIMITED BY SIZE
                  INTO WS-RPT-TIME.
           WRITE REPORT-RECORD FROM WS-HEADER3.
           
           WRITE REPORT-RECORD FROM WS-HEADER1.
           WRITE REPORT-RECORD FROM WS-DETAIL-HDR.
           WRITE REPORT-RECORD FROM WS-HEADER1.
       P210-EXIT.
           EXIT.
           
       P220-PROCESS-DETAIL.
           EXEC SQL
                FETCH PRGCUR
                INTO :WS-DTL-PROGRAM,
                     :WS-DTL-TOTAL,
                     :WS-DTL-SUCCESS,
                     :WS-DTL-WARNING,
                     :WS-DTL-ERROR,
                     :WS-DTL-SEVERE
           END-EXEC.
           
           IF SQLCODE = 0
              WRITE REPORT-RECORD FROM WS-DETAIL-LINE
              
              ADD WS-DTL-TOTAL TO WS-PROGRAM-COUNT
              ADD WS-DTL-SUCCESS TO WS-SUCCESS-COUNT
              ADD WS-DTL-WARNING TO WS-WARNING-COUNT
              ADD WS-DTL-ERROR TO WS-ERROR-COUNT
              ADD WS-DTL-SEVERE TO WS-SEVERE-COUNT
           END-IF.
       P220-EXIT.
           EXIT.
           
       P300-GENERATE-REPORT.
           WRITE REPORT-RECORD FROM WS-HEADER1.
           
           MOVE 'TOTALS' TO WS-DTL-PROGRAM.
           MOVE WS-PROGRAM-COUNT TO WS-DTL-TOTAL.
           MOVE WS-SUCCESS-COUNT TO WS-DTL-SUCCESS.
           MOVE WS-WARNING-COUNT TO WS-DTL-WARNING.
           MOVE WS-ERROR-COUNT TO WS-DTL-ERROR.
           MOVE WS-SEVERE-COUNT TO WS-DTL-SEVERE.
           
           WRITE REPORT-RECORD FROM WS-DETAIL-LINE.
           WRITE REPORT-RECORD FROM WS-HEADER1.
       P300-EXIT.
           EXIT.
           
       P900-CLOSE-FILES.
           CLOSE REPORT-FILE.
       P900-EXIT.
           EXIT. 