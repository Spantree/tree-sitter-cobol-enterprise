      ******************************************************************
      * DB2 Request Area Copybook                                       *
      ******************************************************************
       01  DB2-REQUEST-AREA.
           05 DB2-REQUEST-TYPE        PIC X.
              88 DB2-CONNECT              VALUE 'C'.
              88 DB2-DISCONNECT           VALUE 'D'.
              88 DB2-STATUS               VALUE 'S'.
           05 DB2-RESPONSE-CODE       PIC S9(8) COMP.
           05 DB2-CONNECTION-TOKEN    PIC X(16).
           05 DB2-ERROR-INFO.
              10 DB2-SQLCODE          PIC S9(9) COMP.
              10 DB2-ERROR-MSG        PIC X(80). 