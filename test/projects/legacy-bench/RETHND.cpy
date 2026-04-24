      *****************************************************************
      * RETURN CODE HANDLING DEFINITIONS
      * VERSION: 1.0
      * DATE: 2024
      *****************************************************************
       01  RETURN-HANDLING.
           05  RETURN-STATUS.
               10  RETURN-CODE         PIC S9(4) COMP.
                   88  RC-SUCCESS      VALUE +0.
                   88  RC-WARNING      VALUE +4.
                   88  RC-ERROR        VALUE +8.
                   88  RC-SEVERE       VALUE +12.
                   88  RC-CRITICAL     VALUE +16.
               10  REASON-CODE         PIC S9(4) COMP.
               10  MODULE-ID           PIC X(8).
               10  FUNCTION-ID         PIC X(8).
           
           05  RETURN-DETAILS.
               10  ERROR-LOCATION.
                   15  PROGRAM-NAME    PIC X(8).
                   15  PARAGRAPH-NAME  PIC X(8).
                   15  ERROR-ROUTINE   PIC X(8).
               10  ERROR-INFO.
                   15  ERROR-TYPE      PIC X(1).
                       88  ERR-VALIDATION  VALUE 'V'.
                       88  ERR-PROCESSING  VALUE 'P'.
                       88  ERR-DATABASE    VALUE 'D'.
                       88  ERR-FILE        VALUE 'F'.
                       88  ERR-SECURITY    VALUE 'S'.
                   15  ERROR-CODE      PIC X(4).
                   15  ERROR-TEXT      PIC X(80).
               10  SYSTEM-INFO.
                   15  SYSTEM-CODE     PIC X(4).
                   15  SYSTEM-MSG      PIC X(80).

           05  RETURN-ACTIONS.
               10  ACTION-FLAG         PIC X(1).
                   88  ACTION-CONTINUE VALUE 'C'.
                   88  ACTION-ABORT    VALUE 'A'.
                   88  ACTION-RETRY    VALUE 'R'.
               10  RETRY-COUNT         PIC 9(2) COMP.
               10  MAX-RETRIES         PIC 9(2) COMP VALUE 3.
      *****************************************************************
      * STANDARD ERROR CODES
      *****************************************************************
       01  STD-ERROR-CODES.
           05  ERR-INVALID-DATA    PIC X(4) VALUE 'E001'.
           05  ERR-NOT-FOUND       PIC X(4) VALUE 'E002'.
           05  ERR-DUPLICATE       PIC X(4) VALUE 'E003'.
           05  ERR-FILE-ERROR      PIC X(4) VALUE 'E004'.
           05  ERR-DB-ERROR        PIC X(4) VALUE 'E005'.
           05  ERR-SECURITY        PIC X(4) VALUE 'E006'.
           05  ERR-PROCESSING      PIC X(4) VALUE 'E007'.
           05  ERR-VALIDATION      PIC X(4) VALUE 'E008'.
           05  ERR-VERSION         PIC X(4) VALUE 'E009'.
           05  ERR-TIMEOUT         PIC X(4) VALUE 'E010'.
      *****************************************************************
      * USAGE EXAMPLE:
      *
      *     MOVE 'PORTMSTR'   TO MODULE-ID
      *     MOVE 'VALIDATE'   TO FUNCTION-ID
      *     MOVE 'E001'       TO ERROR-CODE
      *     SET ERR-VALIDATION TO TRUE
      *     SET RC-ERROR      TO TRUE
      *     MOVE 'Invalid portfolio ID' TO ERROR-TEXT
      ***************************************************************** 