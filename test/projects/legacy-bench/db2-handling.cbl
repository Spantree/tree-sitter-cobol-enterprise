       *================================================================*
      * Program Name: DB2HNDL
      * Description: Template for DB2 database interactions
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2HNDL.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * SQL Communication Area
      *----------------------------------------------------------------*
           EXEC SQL INCLUDE SQLCA END-EXEC.
           
      *----------------------------------------------------------------*
      * SQL Declaration for example table
      *----------------------------------------------------------------*
           EXEC SQL DECLARE PORTFOLIO TABLE
           ( PORTFOLIO_ID        CHAR(10)     NOT NULL,
             PORTFOLIO_NAME      VARCHAR(50)   NOT NULL,
             CREATION_DATE       DATE          NOT NULL,
             LAST_UPDATE_TS     TIMESTAMP     NOT NULL,
             TOTAL_VALUE        DECIMAL(15,2)  NOT NULL,
             STATUS             CHAR(1)        NOT NULL
           ) END-EXEC.
           
      *----------------------------------------------------------------*
      * Host variables for DB2 operations
      *----------------------------------------------------------------*
       01  HV-PORTFOLIO.
           05  HV-PORTFOLIO-ID       PIC X(10).
           05  HV-PORTFOLIO-NAME     PIC X(50).
           05  HV-CREATION-DATE      PIC X(10).
           05  HV-LAST-UPDATE-TS     PIC X(26).
           05  HV-TOTAL-VALUE        PIC S9(13)V99 COMP-3.
           05  HV-STATUS             PIC X(01).
           
      *----------------------------------------------------------------*
      * Null indicators
      *----------------------------------------------------------------*
       01  HV-NULL-INDS.
           05  NI-PORTFOLIO-ID       PIC S9(4) COMP.
           05  NI-PORTFOLIO-NAME     PIC S9(4) COMP.
           05  NI-CREATION-DATE      PIC S9(4) COMP.
           05  NI-LAST-UPDATE-TS     PIC S9(4) COMP.
           05  NI-TOTAL-VALUE        PIC S9(4) COMP.
           05  NI-STATUS             PIC S9(4) COMP.
           
      *----------------------------------------------------------------*
      * DB2 Error handling
      *----------------------------------------------------------------*
       01  WS-DB2-ERROR-MSG.
           05  FILLER               PIC X(20) 
               VALUE 'DB2 ERROR - SQLCODE: '.
           05  WS-SQLCODE-DISP     PIC -999.
           05  FILLER               PIC X(20) 
               VALUE ', SQLERRM: '.
           05  WS-SQLERRM           PIC X(70).
           
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 3000-TERMINATE
           GOBACK.
           
       1000-INITIALIZE.
      *----------------------------------------------------------------*
      * Connect to DB2 and initialize work areas
      *----------------------------------------------------------------*
           INITIALIZE HV-PORTFOLIO
                      HV-NULL-INDS
           
           EXEC SQL
               CONNECT TO sample
           END-EXEC
           
           PERFORM 9000-CHECK-SQL-STATUS
           .
           
       2000-PROCESS.
      *----------------------------------------------------------------*
      * Example DB2 operations
      *----------------------------------------------------------------*
           PERFORM 2100-INSERT-EXAMPLE
           PERFORM 2200-SELECT-EXAMPLE
           PERFORM 2300-CURSOR-EXAMPLE
           PERFORM 2400-UPDATE-EXAMPLE
           PERFORM 2500-DELETE-EXAMPLE
           .
           
       2100-INSERT-EXAMPLE.
      *----------------------------------------------------------------*
      * Example INSERT operation
      *----------------------------------------------------------------*
           MOVE 'PORT00001'      TO HV-PORTFOLIO-ID
           MOVE 'TEST PORTFOLIO' TO HV-PORTFOLIO-NAME
           MOVE ZERO             TO NI-PORTFOLIO-ID
                                   NI-PORTFOLIO-NAME
           
           EXEC SQL
               INSERT INTO PORTFOLIO
               (PORTFOLIO_ID, PORTFOLIO_NAME, 
                CREATION_DATE, LAST_UPDATE_TS,
                TOTAL_VALUE, STATUS)
               VALUES
               (:HV-PORTFOLIO-ID   :NI-PORTFOLIO-ID,
                :HV-PORTFOLIO-NAME :NI-PORTFOLIO-NAME,
                CURRENT DATE,
                CURRENT TIMESTAMP,
                0,
                'A')
           END-EXEC
           
           PERFORM 9000-CHECK-SQL-STATUS
           .
           
       2200-SELECT-EXAMPLE.
      *----------------------------------------------------------------*
      * Example SELECT operation
      *----------------------------------------------------------------*
           EXEC SQL
               SELECT PORTFOLIO_ID,
                      PORTFOLIO_NAME,
                      CREATION_DATE,
                      LAST_UPDATE_TS,
                      TOTAL_VALUE,
                      STATUS
               INTO  :HV-PORTFOLIO-ID   :NI-PORTFOLIO-ID,
                     :HV-PORTFOLIO-NAME :NI-PORTFOLIO-NAME,
                     :HV-CREATION-DATE  :NI-CREATION-DATE,
                     :HV-LAST-UPDATE-TS :NI-LAST-UPDATE-TS,
                     :HV-TOTAL-VALUE    :NI-TOTAL-VALUE,
                     :HV-STATUS         :NI-STATUS
               FROM  PORTFOLIO
               WHERE PORTFOLIO_ID = :HV-PORTFOLIO-ID
           END-EXEC
           
           PERFORM 9000-CHECK-SQL-STATUS
           .
           
       2300-CURSOR-EXAMPLE.
      *----------------------------------------------------------------*
      * Example cursor operations
      *----------------------------------------------------------------*
           EXEC SQL
               DECLARE PORTFOLIO_CURSOR CURSOR FOR
               SELECT PORTFOLIO_ID,
                      PORTFOLIO_NAME,
                      STATUS
               FROM   PORTFOLIO
               WHERE  STATUS = 'A'
               FOR    FETCH ONLY
           END-EXEC
           
           EXEC SQL
               OPEN PORTFOLIO_CURSOR
           END-EXEC
           
           PERFORM UNTIL SQLCODE = +100
               EXEC SQL
                   FETCH PORTFOLIO_CURSOR
                   INTO :HV-PORTFOLIO-ID   :NI-PORTFOLIO-ID,
                        :HV-PORTFOLIO-NAME :NI-PORTFOLIO-NAME,
                        :HV-STATUS         :NI-STATUS
               END-EXEC
               
               IF SQLCODE = +0
                   PERFORM 2310-PROCESS-CURSOR-ROW
               END-IF
           END-PERFORM
           
           EXEC SQL
               CLOSE PORTFOLIO_CURSOR
           END-EXEC
           .
           
       2400-UPDATE-EXAMPLE.
      *----------------------------------------------------------------*
      * Example UPDATE operation
      *----------------------------------------------------------------*
           EXEC SQL
               UPDATE PORTFOLIO
               SET    STATUS = 'I',
                      LAST_UPDATE_TS = CURRENT TIMESTAMP
               WHERE  PORTFOLIO_ID = :HV-PORTFOLIO-ID
           END-EXEC
           
           PERFORM 9000-CHECK-SQL-STATUS
           .
           
       2500-DELETE-EXAMPLE.
      *----------------------------------------------------------------*
      * Example DELETE operation
      *----------------------------------------------------------------*
           EXEC SQL
               DELETE FROM PORTFOLIO
               WHERE  PORTFOLIO_ID = :HV-PORTFOLIO-ID
           END-EXEC
           
           PERFORM 9000-CHECK-SQL-STATUS
           .
           
       3000-TERMINATE.
      *----------------------------------------------------------------*
      * Disconnect from DB2 and cleanup
      *----------------------------------------------------------------*
           EXEC SQL
               COMMIT WORK
           END-EXEC
           
           EXEC SQL
               CONNECT RESET
           END-EXEC
           .
           
       9000-CHECK-SQL-STATUS.
      *----------------------------------------------------------------*
      * SQL error checking
      *----------------------------------------------------------------*
           IF SQLCODE NOT = 0
               MOVE SQLCODE TO WS-SQLCODE-DISP
               MOVE SQLERRMC TO WS-SQLERRM
               DISPLAY WS-DB2-ERROR-MSG
               IF SQLCODE < 0
                   PERFORM 9100-ROLLBACK
                   MOVE 8 TO RETURN-CODE
                   PERFORM 3000-TERMINATE
                   GOBACK
               END-IF
           END-IF
           .
           
       9100-ROLLBACK.
      *----------------------------------------------------------------*
      * Rollback DB2 changes
      *----------------------------------------------------------------*
           EXEC SQL
               ROLLBACK WORK
           END-EXEC
           .