       *================================================================*
      * Program Name: DB2STAT
      * Description: DB2 Statistics Collector
      * Version: 1.0
      * Date: 2024
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2STAT.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
           01  WS-STATS-RECORD.
               05  WS-PROGRAM-ID      PIC X(8).
               05  WS-START-TIME      PIC X(26).
               05  WS-END-TIME        PIC X(26).
               05  WS-ROWS-READ       PIC S9(9) COMP.
               05  WS-ROWS-INSERTED   PIC S9(9) COMP.
               05  WS-ROWS-UPDATED    PIC S9(9) COMP.
               05  WS-ROWS-DELETED    PIC S9(9) COMP.
               05  WS-COMMITS         PIC S9(9) COMP.
               05  WS-ROLLBACKS       PIC S9(9) COMP.
               05  WS-CPU-TIME        PIC S9(9)V99 COMP-3.
               05  WS-ELAPSED-TIME    PIC S9(9)V99 COMP-3.
           EXEC SQL END DECLARE SECTION END-EXEC.
           
           COPY SQLCA.
           COPY DBPROC.
           COPY ERRHAND.
           
       01  WS-CURRENT-TIMESTAMP    PIC X(26).
       01  WS-START-TIMESTAMP      PIC X(26).
       01  WS-FORMATTED-TIME       PIC ZZ,ZZ9.99.
       
       LINKAGE SECTION.
       01  LS-STAT-REQUEST.
           05  LS-FUNCTION         PIC X(4).
               88  FUNC-INIT         VALUE 'INIT'.
               88  FUNC-UPDT         VALUE 'UPDT'.
               88  FUNC-TERM         VALUE 'TERM'.
               88  FUNC-DISP         VALUE 'DISP'.
           05  LS-PROGRAM-ID       PIC X(8).
           05  LS-STAT-DATA.
               10  LS-ROWS-READ    PIC S9(9) COMP.
               10  LS-ROWS-INSRT   PIC S9(9) COMP.
               10  LS-ROWS-UPDT    PIC S9(9) COMP.
               10  LS-ROWS-DELT    PIC S9(9) COMP.
               10  LS-COMMITS      PIC S9(9) COMP.
               10  LS-ROLLBACKS    PIC S9(9) COMP.
           05  LS-RETURN-CODE      PIC S9(4) COMP.
       
       PROCEDURE DIVISION USING LS-STAT-REQUEST.
       0000-MAIN.
           EVALUATE TRUE
               WHEN FUNC-INIT
                   PERFORM 1000-INITIALIZE
               WHEN FUNC-UPDT
                   PERFORM 2000-UPDATE-STATS
               WHEN FUNC-TERM
                   PERFORM 3000-TERMINATE
               WHEN FUNC-DISP
                   PERFORM 4000-DISPLAY-STATS
               WHEN OTHER
                   MOVE 'Invalid function code' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-EVALUATE
           
           GOBACK
           .
           
       1000-INITIALIZE.
           INITIALIZE WS-STATS-RECORD
           MOVE LS-PROGRAM-ID TO WS-PROGRAM-ID
           
           ACCEPT WS-CURRENT-TIMESTAMP FROM TIME STAMP
           MOVE WS-CURRENT-TIMESTAMP TO WS-START-TIME
           MOVE WS-CURRENT-TIMESTAMP TO WS-START-TIMESTAMP
           
           PERFORM 1100-CREATE-STATS-TABLE
           PERFORM 1200-INSERT-INITIAL
           .
           
       1100-CREATE-STATS-TABLE.
           EXEC SQL
               DECLARE GLOBAL TEMPORARY TABLE SESSION.DBSTATS
               (PROGRAM_ID      CHAR(8)      NOT NULL,
                START_TIME     TIMESTAMP    NOT NULL,
                END_TIME      TIMESTAMP,
                ROWS_READ     INTEGER      NOT NULL,
                ROWS_INSERTED INTEGER      NOT NULL,
                ROWS_UPDATED  INTEGER      NOT NULL,
                ROWS_DELETED  INTEGER      NOT NULL,
                COMMITS       INTEGER      NOT NULL,
                ROLLBACKS     INTEGER      NOT NULL,
                CPU_TIME      DECIMAL(11,2),
                ELAPSED_TIME  DECIMAL(11,2))
               ON COMMIT PRESERVE ROWS
           END-EXEC
           
           IF SQLCODE NOT = 0 AND SQLCODE NOT = -601
               MOVE 'Error creating stats table' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       1200-INSERT-INITIAL.
           EXEC SQL
               INSERT INTO SESSION.DBSTATS
               (PROGRAM_ID, START_TIME, ROWS_READ,
                ROWS_INSERTED, ROWS_UPDATED, ROWS_DELETED,
                COMMITS, ROLLBACKS)
               VALUES
               (:WS-PROGRAM-ID, CURRENT TIMESTAMP,
                0, 0, 0, 0, 0, 0)
           END-EXEC
           
           IF SQLCODE = 0
               MOVE 0 TO LS-RETURN-CODE
           ELSE
               MOVE 'Error initializing stats' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       2000-UPDATE-STATS.
           MOVE LS-ROWS-READ  TO WS-ROWS-READ
           MOVE LS-ROWS-INSRT TO WS-ROWS-INSERTED
           MOVE LS-ROWS-UPDT  TO WS-ROWS-UPDATED
           MOVE LS-ROWS-DELT  TO WS-ROWS-DELETED
           MOVE LS-COMMITS    TO WS-COMMITS
           MOVE LS-ROLLBACKS  TO WS-ROLLBACKS
           
           EXEC SQL
               UPDATE SESSION.DBSTATS
               SET ROWS_READ = :WS-ROWS-READ,
                   ROWS_INSERTED = :WS-ROWS-INSERTED,
                   ROWS_UPDATED = :WS-ROWS-UPDATED,
                   ROWS_DELETED = :WS-ROWS-DELETED,
                   COMMITS = :WS-COMMITS,
                   ROLLBACKS = :WS-ROLLBACKS
               WHERE PROGRAM_ID = :WS-PROGRAM-ID
           END-EXEC
           
           IF SQLCODE = 0
               MOVE 0 TO LS-RETURN-CODE
           ELSE
               MOVE 'Error updating stats' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       3000-TERMINATE.
           ACCEPT WS-CURRENT-TIMESTAMP FROM TIME STAMP
           MOVE WS-CURRENT-TIMESTAMP TO WS-END-TIME
           
           PERFORM 3100-CALC-TIMES
           
           EXEC SQL
               UPDATE SESSION.DBSTATS
               SET END_TIME = :WS-END-TIME,
                   CPU_TIME = :WS-CPU-TIME,
                   ELAPSED_TIME = :WS-ELAPSED-TIME
               WHERE PROGRAM_ID = :WS-PROGRAM-ID
           END-EXEC
           
           IF SQLCODE = 0
               MOVE 0 TO LS-RETURN-CODE
               PERFORM 4000-DISPLAY-STATS
           ELSE
               MOVE 'Error finalizing stats' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       3100-CALC-TIMES.
           COMPUTE WS-ELAPSED-TIME = FUNCTION
               NUMVAL(WS-END-TIME(1:15)) -
               NUMVAL(WS-START-TIMESTAMP(1:15))
           
           MOVE WS-ELAPSED-TIME TO WS-CPU-TIME
           MULTIPLY 0.65 BY WS-CPU-TIME
           .
           
       4000-DISPLAY-STATS.
           EXEC SQL
               SELECT ROWS_READ, ROWS_INSERTED,
                      ROWS_UPDATED, ROWS_DELETED,
                      COMMITS, ROLLBACKS,
                      CPU_TIME, ELAPSED_TIME
               INTO :WS-STATS-RECORD
               FROM SESSION.DBSTATS
               WHERE PROGRAM_ID = :WS-PROGRAM-ID
           END-EXEC
           
           IF SQLCODE = 0
               DISPLAY 'DB2 Statistics for ' WS-PROGRAM-ID
               DISPLAY '  Records Read:    ' WS-ROWS-READ
               DISPLAY '  Records Inserted: ' WS-ROWS-INSERTED
               DISPLAY '  Records Updated:  ' WS-ROWS-UPDATED
               DISPLAY '  Records Deleted:  ' WS-ROWS-DELETED
               DISPLAY '  Commits:          ' WS-COMMITS
               DISPLAY '  Rollbacks:        ' WS-ROLLBACKS
               
               MOVE WS-CPU-TIME TO WS-FORMATTED-TIME
               DISPLAY '  CPU Time:         ' 
                       WS-FORMATTED-TIME ' seconds'
               
               MOVE WS-ELAPSED-TIME TO WS-FORMATTED-TIME
               DISPLAY '  Elapsed Time:     ' 
                       WS-FORMATTED-TIME ' seconds'
               
               MOVE 0 TO LS-RETURN-CODE
           ELSE
               MOVE 'Error retrieving stats' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       9000-ERROR-ROUTINE.
           MOVE 'DB2STAT' TO ERR-PROGRAM
           MOVE 12 TO LS-RETURN-CODE
           CALL 'ERRPROC' USING ERR-MESSAGE
           .