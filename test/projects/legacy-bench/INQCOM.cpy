      ******************************************************************
      * Online Inquiry Communication Area                               *
      ******************************************************************
       01  INQCOM-AREA.
           05 INQCOM-FUNCTION         PIC X(4).
              88 INQCOM-MENU               VALUE 'MENU'.
              88 INQCOM-PORTFOLIO          VALUE 'INQP'.
              88 INQCOM-HISTORY            VALUE 'INQH'.
              88 INQCOM-EXIT               VALUE 'EXIT'.
           05 INQCOM-ACCOUNT-NO       PIC X(10).
           05 INQCOM-RESPONSE-CODE    PIC S9(8) COMP.
           05 INQCOM-ERROR-MSG        PIC X(80). 