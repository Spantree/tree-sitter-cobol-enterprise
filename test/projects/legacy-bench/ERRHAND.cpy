      *================================================================*
      * Copybook Name: ERRHAND
      * Description: Standard Error Handling Definitions
      * Author: [Author name]
      * Date Written: 2024-03-20
      *================================================================*
      
      *----------------------------------------------------------------*
      * Error Categories
      *----------------------------------------------------------------*
       01  ERR-CATEGORIES.
           05  ERR-CAT-VSAM        PIC X(2) VALUE 'VS'.
           05  ERR-CAT-VALID       PIC X(2) VALUE 'VL'.
           05  ERR-CAT-PROC        PIC X(2) VALUE 'PR'.
           05  ERR-CAT-SYSTEM      PIC X(2) VALUE 'SY'.
           
      *----------------------------------------------------------------*
      * Standard Return Codes
      *----------------------------------------------------------------*
       01  ERR-RETURN-CODES.
           05  ERR-SUCCESS         PIC S9(4) COMP VALUE +0.
           05  ERR-WARNING         PIC S9(4) COMP VALUE +4.
           05  ERR-ERROR           PIC S9(4) COMP VALUE +8.
           05  ERR-SEVERE          PIC S9(4) COMP VALUE +12.
           05  ERR-TERMINAL        PIC S9(4) COMP VALUE +16.
           
      *----------------------------------------------------------------*
      * Error Message Structure
      *----------------------------------------------------------------*
       01  ERR-MESSAGE.
           05  ERR-TIMESTAMP.
               10  ERR-DATE        PIC X(10).
               10  ERR-TIME        PIC X(8).
           05  ERR-PROGRAM         PIC X(8).
           05  ERR-CATEGORY        PIC X(2).
           05  ERR-CODE            PIC X(4).
           05  ERR-SEVERITY        PIC S9(4) COMP.
           05  ERR-TEXT            PIC X(80).
           05  ERR-DETAILS         PIC X(256).
           
      *----------------------------------------------------------------*
      * VSAM Status Handling
      *----------------------------------------------------------------*
       01  ERR-VSAM-STATUSES.
           05  ERR-VSAM-SUCCESS    PIC X(2) VALUE '00'.
           05  ERR-VSAM-DUPKEY     PIC X(2) VALUE '22'.
           05  ERR-VSAM-NOTFND     PIC X(2) VALUE '23'.
           05  ERR-VSAM-EOF        PIC X(2) VALUE '10'.
           
       01  ERR-VSAM-MSGS.
           05  ERR-VSAM-22         PIC X(80) VALUE
               'Duplicate record key'.
           05  ERR-VSAM-23         PIC X(80) VALUE
               'Record not found'.
           05  ERR-OTHER           PIC X(80) VALUE
               'Unexpected VSAM error'. 