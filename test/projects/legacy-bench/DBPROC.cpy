      *================================================================*
      * DB2 Standard Procedures
      * Version: 1.0
      * Date: 2024
      *================================================================*
      
      *----------------------------------------------------------------*
      * SQL Error Handling
      *----------------------------------------------------------------*
       01  DB2-ERROR-HANDLING.
           05  DB2-ERROR-MESSAGE.
               10  FILLER          PIC X(9) VALUE 'SQLCODE: '.
               10  DB2-SQLCODE-TXT PIC X(6).
               10  FILLER          PIC X(9) VALUE ' STATE: '.
               10  DB2-STATE       PIC X(5).
               10  FILLER          PIC X(8) VALUE ' ERROR: '.
               10  DB2-ERROR-TEXT  PIC X(70).
           05  DB2-SAVE-STATUS     PIC X(5).
           05  DB2-RETRY-COUNT     PIC S9(4) COMP VALUE 0.
           05  DB2-MAX-RETRIES     PIC S9(4) COMP VALUE 3.
           05  DB2-RETRY-WAIT      PIC S9(4) COMP VALUE 100.
      
      *----------------------------------------------------------------*
      * Standard DB2 Procedures
      *----------------------------------------------------------------*
       CONNECT-TO-DB2.
           EXEC SQL
               CONNECT TO POSMVP
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Connection failed' TO DB2-ERROR-TEXT
               PERFORM DB2-ERROR-ROUTINE
           END-IF
           .
      
       DISCONNECT-FROM-DB2.
           EXEC SQL
               COMMIT WORK
           END-EXEC
           
           EXEC SQL
               CONNECT RESET
           END-EXEC
           .
      
       DB2-ERROR-ROUTINE.
           MOVE SQLCODE TO DB2-SQLCODE-TXT
           MOVE SQLSTATE TO DB2-STATE
           
           EXEC SQL
               ROLLBACK WORK
           END-EXEC
           
           MOVE 'DB2ERROR' TO ERR-PROGRAM
           MOVE DB2-ERROR-MESSAGE TO ERR-TEXT
           CALL 'ERRPROC' USING ERR-MESSAGE
           .
      
       CHECK-SQL-STATUS.
           IF SQLCODE NOT = 0
               PERFORM DB2-ERROR-ROUTINE
           END-IF
           . 