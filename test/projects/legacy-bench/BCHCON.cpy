      *================================================================*
      * BATCH CONTROL CONSTANTS
      * Version: 1.0
      * Date: 2024
      *================================================================*
       01  BATCH-CONTROL-CONSTANTS.
      *    Process Status Values
           05  BCT-STAT-VALUES.
               10  BCT-STAT-READY     PIC X(1) VALUE 'R'.
               10  BCT-STAT-ACTIVE    PIC X(1) VALUE 'A'.
               10  BCT-STAT-WAITING   PIC X(1) VALUE 'W'.
               10  BCT-STAT-DONE      PIC X(1) VALUE 'D'.
               10  BCT-STAT-ERROR     PIC X(1) VALUE 'E'.
      
      *    Return Code Thresholds
           05  BCT-RC-THRESHOLDS.
               10  BCT-RC-SUCCESS     PIC S9(4) COMP VALUE +0.
               10  BCT-RC-WARNING     PIC S9(4) COMP VALUE +4.
               10  BCT-RC-ERROR       PIC S9(4) COMP VALUE +8.
               10  BCT-RC-SEVERE      PIC S9(4) COMP VALUE +12.
               10  BCT-RC-CRITICAL    PIC S9(4) COMP VALUE +16.
      
      *    Process Control Values
           05  BCT-CTRL-VALUES.
               10  BCT-MAX-PREREQ     PIC 9(2) COMP VALUE 10.
               10  BCT-MAX-RESTARTS   PIC 9(2) COMP VALUE 3.
               10  BCT-WAIT-INTERVAL  PIC 9(4) COMP VALUE 300.
               10  BCT-MAX-WAIT-TIME  PIC 9(4) COMP VALUE 3600.
      
      *    Process Types
           05  BCT-PROC-TYPES.
               10  BCT-TYPE-INITIAL   PIC X(3) VALUE 'INI'.
               10  BCT-TYPE-UPDATE    PIC X(3) VALUE 'UPD'.
               10  BCT-TYPE-REPORT    PIC X(3) VALUE 'RPT'.
               10  BCT-TYPE-CLEANUP   PIC X(3) VALUE 'CLN'.
      
      *    Dependency Types
           05  BCT-DEP-TYPES.
               10  BCT-DEP-REQUIRED   PIC X(1) VALUE 'R'.
               10  BCT-DEP-OPTIONAL   PIC X(1) VALUE 'O'.
               10  BCT-DEP-EXCLUSIVE  PIC X(1) VALUE 'X'.
      
      *    Special Process Names
           05  BCT-PROC-NAMES.
               10  BCT-START-OF-DAY   PIC X(8) VALUE 'STARTDAY'.
               10  BCT-END-OF-DAY     PIC X(8) VALUE 'ENDDAY  '.
               10  BCT-EMERGENCY      PIC X(8) VALUE 'EMERGENCY'.
      
      *    Control File Record Types
           05  BCT-REC-TYPES.
               10  BCT-REC-CONTROL    PIC X(1) VALUE 'C'.
               10  BCT-REC-PROCESS    PIC X(1) VALUE 'P'.
               10  BCT-REC-DEPEND     PIC X(1) VALUE 'D'.
               10  BCT-REC-HISTORY    PIC X(1) VALUE 'H'.
      
      *    Standard Messages
           05  BCT-MESSAGES.
               10  BCT-MSG-STARTING   PIC X(30) 
                   VALUE 'Process starting...           '.
               10  BCT-MSG-COMPLETE   PIC X(30)
                   VALUE 'Process completed successfully'.
               10  BCT-MSG-FAILED     PIC X(30)
                   VALUE 'Process failed - check errors '.
               10  BCT-MSG-WAITING    PIC X(30)
                   VALUE 'Waiting for prerequisites     '. 