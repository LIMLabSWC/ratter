/*
 * MATLAB Compiler: 4.10 (R2009a)
 * Date: Mon Dec 19 15:00:26 2011
 * Arguments: "-B" "macro_default" "-o" "GCS_receiver" "-W" "main" "-d"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_receiver_compiled\src"
 * "-T" "link:exe"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_receiver.m" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\win64\libmysql.dll" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\win64\mym.mexw64" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\zlibwapi.dll" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\bdata.p" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\LIBMYSQL.dll" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexw32" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexa64" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexmaci" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexmaci64" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexmaci.tiger" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_Message.m" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_Message.fig" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_checkcode.p" "-a"
 * "C:\ratter\ExperPort\Utility\AutomatedEmails\senderror_report.m" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\get_network_info.m" 
 */

#include "mclmcrrt.h"

#ifdef __cplusplus
extern "C" {
#endif
const unsigned char __MCC_GCS_receiver_session_key[] = {
    '6', 'D', '5', '8', 'B', '5', '4', 'F', '2', '7', 'A', 'F', 'F', '7', 'A',
    '6', '3', '8', 'F', 'F', 'B', 'C', 'A', 'E', 'E', 'A', '7', '1', 'B', 'E',
    'C', 'F', '2', 'A', 'C', '9', '8', 'B', '0', 'B', '9', 'E', '6', '5', '0',
    '2', '5', '4', '0', '6', '0', '4', 'C', 'F', '7', '1', '6', '1', 'D', '5',
    '6', 'E', 'C', 'F', 'E', '2', '8', '4', 'F', 'C', '6', 'D', 'A', '5', '5',
    '1', '8', '1', '6', '9', 'A', 'B', '8', 'B', 'A', '8', '7', '7', '1', 'F',
    '2', '7', '3', '1', '1', '9', 'B', '5', '9', 'E', '0', '3', '0', '8', '4',
    'E', 'E', '2', 'F', 'A', '8', '5', '7', '2', '1', '7', 'F', 'D', '7', 'E',
    '1', 'D', '5', '6', '7', 'E', '3', '5', 'B', 'A', '6', 'E', 'B', '5', '5',
    '3', 'E', '3', '3', '7', 'C', '9', '0', 'D', 'D', 'E', 'A', '4', '4', '4',
    '7', '5', '0', '7', 'A', 'D', '9', '2', '2', '9', '3', 'B', '9', '7', 'F',
    '0', '3', 'E', 'C', '0', '4', '9', 'E', 'A', '4', '8', '6', 'E', '5', '8',
    '0', 'F', 'E', 'F', 'A', '6', '3', '9', 'A', 'C', '6', 'A', '5', '3', 'C',
    '6', '4', '8', '8', 'D', '7', '0', '7', '9', '7', '2', '7', 'A', '8', 'D',
    '6', '9', '0', '8', 'E', '0', '0', 'C', 'E', 'B', '7', '7', '9', '2', '4',
    '6', '3', '9', '3', '6', 'C', '8', '8', 'D', 'A', '8', '0', '7', 'A', 'E',
    'E', '5', 'E', '0', 'F', 'A', '4', 'C', '9', '3', '8', '6', 'B', '5', 'F',
    'D', '\0'};

const unsigned char __MCC_GCS_receiver_public_key[] = {
    '3', '0', '8', '1', '9', 'D', '3', '0', '0', 'D', '0', '6', '0', '9', '2',
    'A', '8', '6', '4', '8', '8', '6', 'F', '7', '0', 'D', '0', '1', '0', '1',
    '0', '1', '0', '5', '0', '0', '0', '3', '8', '1', '8', 'B', '0', '0', '3',
    '0', '8', '1', '8', '7', '0', '2', '8', '1', '8', '1', '0', '0', 'C', '4',
    '9', 'C', 'A', 'C', '3', '4', 'E', 'D', '1', '3', 'A', '5', '2', '0', '6',
    '5', '8', 'F', '6', 'F', '8', 'E', '0', '1', '3', '8', 'C', '4', '3', '1',
    '5', 'B', '4', '3', '1', '5', '2', '7', '7', 'E', 'D', '3', 'F', '7', 'D',
    'A', 'E', '5', '3', '0', '9', '9', 'D', 'B', '0', '8', 'E', 'E', '5', '8',
    '9', 'F', '8', '0', '4', 'D', '4', 'B', '9', '8', '1', '3', '2', '6', 'A',
    '5', '2', 'C', 'C', 'E', '4', '3', '8', '2', 'E', '9', 'F', '2', 'B', '4',
    'D', '0', '8', '5', 'E', 'B', '9', '5', '0', 'C', '7', 'A', 'B', '1', '2',
    'E', 'D', 'E', '2', 'D', '4', '1', '2', '9', '7', '8', '2', '0', 'E', '6',
    '3', '7', '7', 'A', '5', 'F', 'E', 'B', '5', '6', '8', '9', 'D', '4', 'E',
    '6', '0', '3', '2', 'F', '6', '0', 'C', '4', '3', '0', '7', '4', 'A', '0',
    '4', 'C', '2', '6', 'A', 'B', '7', '2', 'F', '5', '4', 'B', '5', '1', 'B',
    'B', '4', '6', '0', '5', '7', '8', '7', '8', '5', 'B', '1', '9', '9', '0',
    '1', '4', '3', '1', '4', 'A', '6', '5', 'F', '0', '9', '0', 'B', '6', '1',
    'F', 'C', '2', '0', '1', '6', '9', '4', '5', '3', 'B', '5', '8', 'F', 'C',
    '8', 'B', 'A', '4', '3', 'E', '6', '7', '7', '6', 'E', 'B', '7', 'E', 'C',
    'D', '3', '1', '7', '8', 'B', '5', '6', 'A', 'B', '0', 'F', 'A', '0', '6',
    'D', 'D', '6', '4', '9', '6', '7', 'C', 'B', '1', '4', '9', 'E', '5', '0',
    '2', '0', '1', '1', '1', '\0'};

static const char * MCC_GCS_receiver_matlabpath_data[] = 
  { "GCS_receiver/", "$TOOLBOXDEPLOYDIR/",
    "ratter/ExperPort/MySQLUtility/win64/", "ratter/ExperPort/MySQLUtility/",
    "ratter/ExperPort/Utility/AutomatedEmails/", "ratter/ExperPort/",
    "ratter/ExperPort/Analysis/", "ratter/ExperPort/FakeRP/",
    "ratter/ExperPort/HandleParam/", "ratter/ExperPort/Modules/",
    "ratter/ExperPort/Utility/", "ratter/ExperPort/Utility/provisional/",
    "ratter/Rigscripts/", "$TOOLBOXMATLABDIR/general/",
    "$TOOLBOXMATLABDIR/ops/", "$TOOLBOXMATLABDIR/lang/",
    "$TOOLBOXMATLABDIR/elmat/", "$TOOLBOXMATLABDIR/randfun/",
    "$TOOLBOXMATLABDIR/elfun/", "$TOOLBOXMATLABDIR/specfun/",
    "$TOOLBOXMATLABDIR/matfun/", "$TOOLBOXMATLABDIR/datafun/",
    "$TOOLBOXMATLABDIR/polyfun/", "$TOOLBOXMATLABDIR/funfun/",
    "$TOOLBOXMATLABDIR/sparfun/", "$TOOLBOXMATLABDIR/scribe/",
    "$TOOLBOXMATLABDIR/graph2d/", "$TOOLBOXMATLABDIR/graph3d/",
    "$TOOLBOXMATLABDIR/specgraph/", "$TOOLBOXMATLABDIR/graphics/",
    "$TOOLBOXMATLABDIR/uitools/", "$TOOLBOXMATLABDIR/strfun/",
    "$TOOLBOXMATLABDIR/imagesci/", "$TOOLBOXMATLABDIR/iofun/",
    "$TOOLBOXMATLABDIR/audiovideo/", "$TOOLBOXMATLABDIR/timefun/",
    "$TOOLBOXMATLABDIR/datatypes/", "$TOOLBOXMATLABDIR/verctrl/",
    "$TOOLBOXMATLABDIR/codetools/", "$TOOLBOXMATLABDIR/helptools/",
    "$TOOLBOXMATLABDIR/winfun/", "$TOOLBOXMATLABDIR/winfun/net/",
    "$TOOLBOXMATLABDIR/demos/", "$TOOLBOXMATLABDIR/timeseries/",
    "$TOOLBOXMATLABDIR/hds/", "$TOOLBOXMATLABDIR/guide/",
    "$TOOLBOXMATLABDIR/plottools/", "toolbox/local/",
    "toolbox/shared/dastudio/", "$TOOLBOXMATLABDIR/datamanager/",
    "toolbox/compiler/" };

static const char * MCC_GCS_receiver_classpath_data[] = 
  { "" };

static const char * MCC_GCS_receiver_libpath_data[] = 
  { "" };

static const char * MCC_GCS_receiver_app_opts_data[] = 
  { "" };

static const char * MCC_GCS_receiver_run_opts_data[] = 
  { "" };

static const char * MCC_GCS_receiver_warning_state_data[] = 
  { "off:MATLAB:dispatcher:nameConflict" };


mclComponentData __MCC_GCS_receiver_component_data = { 

  /* Public key data */
  __MCC_GCS_receiver_public_key,

  /* Component name */
  "GCS_receiver",

  /* Component Root */
  "",

  /* Application key data */
  __MCC_GCS_receiver_session_key,

  /* Component's MATLAB Path */
  MCC_GCS_receiver_matlabpath_data,

  /* Number of directories in the MATLAB Path */
  51,

  /* Component's Java class path */
  MCC_GCS_receiver_classpath_data,
  /* Number of directories in the Java class path */
  0,

  /* Component's load library path (for extra shared libraries) */
  MCC_GCS_receiver_libpath_data,
  /* Number of directories in the load library path */
  0,

  /* MCR instance-specific runtime options */
  MCC_GCS_receiver_app_opts_data,
  /* Number of MCR instance-specific runtime options */
  0,

  /* MCR global runtime options */
  MCC_GCS_receiver_run_opts_data,
  /* Number of MCR global runtime options */
  0,
  
  /* Component preferences directory */
  "GCS_receiver_94BE60D412F6D9EAEE58E2EC5DE169EA",

  /* MCR warning status data */
  MCC_GCS_receiver_warning_state_data,
  /* Number of MCR warning status modifiers */
  1,

  /* Path to component - evaluated at runtime */
  NULL

};

#ifdef __cplusplus
}
#endif


