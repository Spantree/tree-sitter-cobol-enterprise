      *================================================================*
      * Copybook Name: PORTFLIO
      * Description: Portfolio Master Record Layout
      * Author: [Author name]
      * Date Written: 2024-03-20
      * Maintenance Log:
      * Date       Author        Description
      * ---------- ------------- -------------------------------------
      * 2024-03-20 [Author]     Initial Creation
      *================================================================*
       01  PORT-RECORD.
           05  PORT-KEY.
               10  PORT-ID             PIC X(8).
               10  PORT-ACCOUNT-NO     PIC X(10).
           05  PORT-CLIENT-INFO.
               10  PORT-CLIENT-NAME    PIC X(30).
               10  PORT-CLIENT-TYPE    PIC X(1).
                   88  PORT-INDIVIDUAL    VALUE 'I'.
                   88  PORT-CORPORATE     VALUE 'C'.
                   88  PORT-TRUST         VALUE 'T'.
           05  PORT-PORTFOLIO-INFO.
               10  PORT-CREATE-DATE    PIC 9(8).
               10  PORT-LAST-MAINT     PIC 9(8).
               10  PORT-STATUS         PIC X(1).
                   88  PORT-ACTIVE       VALUE 'A'.
                   88  PORT-CLOSED       VALUE 'C'.
                   88  PORT-SUSPENDED    VALUE 'S'.
           05  PORT-FINANCIAL-INFO.
               10  PORT-TOTAL-VALUE    PIC S9(13)V99 COMP-3.
               10  PORT-CASH-BALANCE   PIC S9(13)V99 COMP-3.
           05  PORT-AUDIT-INFO.
               10  PORT-LAST-USER      PIC X(8).
               10  PORT-LAST-TRANS     PIC 9(8).
           05  PORT-FILLER            PIC X(50). 