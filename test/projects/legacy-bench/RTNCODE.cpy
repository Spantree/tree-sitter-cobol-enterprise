      ******************************************************************
      * Return Code Management Copybook                                 *
      ******************************************************************
       01  RETURN-CODE-AREA.
           05 RC-REQUEST-TYPE        PIC X.
              88 RC-INITIALIZE           VALUE 'I'.
              88 RC-SET-CODE             VALUE 'S'.
              88 RC-GET-CODE             VALUE 'G'.
              88 RC-LOG-CODE             VALUE 'L'.
              88 RC-ANALYZE              VALUE 'A'.
           05 RC-PROGRAM-ID         PIC X(8).
           05 RC-CODES-AREA.
              10 RC-CURRENT-CODE    PIC S9(4) COMP.
              10 RC-HIGHEST-CODE    PIC S9(4) COMP.
              10 RC-NEW-CODE        PIC S9(4) COMP.
              10 RC-STATUS          PIC X.
                 88 RC-STATUS-SUCCESS    VALUE 'S'.
                 88 RC-STATUS-WARNING    VALUE 'W'.
                 88 RC-STATUS-ERROR      VALUE 'E'.
                 88 RC-STATUS-SEVERE     VALUE 'F'.
           05 RC-MESSAGE           PIC X(80).
           05 RC-RESPONSE-CODE     PIC S9(8) COMP.
           05 RC-ANALYSIS-DATA.
              10 RC-START-TIME     PIC X(26).
              10 RC-END-TIME       PIC X(26).
              10 RC-TOTAL-CODES    PIC S9(8) COMP.
              10 RC-MAX-CODE       PIC S9(4) COMP.
              10 RC-MIN-CODE       PIC S9(4) COMP.
           05 RC-RETURN-DATA.
              10 RC-RETURN-VALUE   PIC S9(4) COMP.
              10 RC-HIGHEST-RETURN PIC S9(4) COMP.
              10 RC-RETURN-STATUS  PIC X.