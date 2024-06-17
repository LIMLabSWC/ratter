/*
 * MATLAB Compiler: 4.10 (R2009a)
 * Date: Tue Mar 19 08:09:43 2013
 * Arguments: "-B" "macro_default" "-o" "GlobalControlSystem" "-W" "main" "-d"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GlobalControlSystem\src"
 * "-T" "link:exe" "-v"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GlobalControlSystem.m" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\warn_running.m" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\activate_buttons.m" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\check_running.m" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_Confirm.fig" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_Confirm.m" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_Message.fig" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_Message.m" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GlobalControlSystem.fig"
 * "-a" "C:\ratter\ExperPort\Utility\GlobalControlSystem\GlobalControlSystem.m"
 * "-a" "C:\ratter\ExperPort\Utility\GlobalControlSystem\send_job.m" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\update_status.m" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\LIBMYSQL.dll" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexw32" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexa64" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexa64.phenom" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexa64cuda" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexglx" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexmaci" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexmaci64" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\mym.mexmaci.tiger" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\zlibwapi.dll" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\bdata.p" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\win64\libmysql.dll" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\win64\mym.mexw64" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_Script.m" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_Script.fig" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_makecode.p" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_checkcode.p" "-a"
 * "C:\ratter\ExperPort\Utility\GlobalControlSystem\GCS_checkpassword.p" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\get_network_info.m" 
 */

#include "mclmcrrt.h"

#ifdef __cplusplus
extern "C" {
#endif
const unsigned char __MCC_GlobalControlSystem_session_key[] = {
    '3', '4', '5', '2', '3', '8', 'D', 'B', '9', '9', 'A', 'E', '4', 'B', '0',
    'F', 'C', 'A', '7', 'F', '3', '1', '9', 'D', '4', 'E', 'A', '0', '1', '7',
    '0', '2', '9', '7', '8', '0', 'B', '7', '9', '0', 'A', 'B', 'B', '6', '4',
    'C', '5', 'A', 'F', '9', 'E', 'E', '0', '8', '1', '5', '5', 'D', '2', '5',
    'B', '6', '3', '8', 'A', 'A', '9', 'E', '8', '4', '9', '7', 'C', '7', 'B',
    'F', '5', 'B', '2', '5', 'E', '6', 'F', 'A', '3', '5', 'C', '8', 'D', '5',
    '7', 'D', '6', 'B', 'A', 'E', '2', '0', '8', '5', 'C', '1', 'D', 'C', '5',
    'E', '6', '5', 'E', 'B', '2', 'E', 'C', '9', '6', '7', 'A', '0', '7', '7',
    '7', '7', 'D', '0', '2', '7', 'F', 'F', '7', '2', '2', '9', 'F', '6', '9',
    'D', '9', 'C', '8', 'E', 'F', 'F', '7', 'A', 'E', '4', '7', '0', 'E', 'B',
    '1', '6', '7', 'B', 'A', '5', 'E', '2', '7', '9', '4', 'F', 'B', '2', 'C',
    'E', '6', '8', '6', 'A', 'F', '7', 'C', '2', 'D', '8', '0', '5', 'C', '3',
    'D', '5', 'D', '1', 'E', '4', '1', 'A', 'A', '3', '0', 'E', 'B', 'B', '2',
    'A', '4', '4', 'B', '8', '4', 'C', '4', '6', 'C', 'E', 'F', '3', 'F', '3',
    '7', '2', '8', '5', '2', '2', 'C', '8', '2', '5', 'F', '0', '5', '0', 'F',
    'E', 'E', 'C', '8', '7', '5', 'B', '1', 'A', '6', 'F', '0', 'B', '0', 'F',
    '2', '9', '0', '9', '8', '6', 'A', '7', 'A', '1', 'C', '7', '5', 'F', 'C',
    'D', '\0'};

const unsigned char __MCC_GlobalControlSystem_public_key[] = {
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

static const char * MCC_GlobalControlSystem_matlabpath_data[] = 
  { "GlobalContro/", "$TOOLBOXDEPLOYDIR/", "ratter/ExperPort/MySQLUtility/",
    "ratter/ExperPort/MySQLUtility/win64/", "ratter/ExperPort/",
    "ratter/ExperPort/Analysis/", "ratter/ExperPort/FakeRP/",
    "ratter/ExperPort/HandleParam/", "ratter/ExperPort/Utility/",
    "ratter/ExperPort/Utility/provisional/", "ratter/Rigscripts/",
    "$TOOLBOXMATLABDIR/general/", "$TOOLBOXMATLABDIR/ops/",
    "$TOOLBOXMATLABDIR/lang/", "$TOOLBOXMATLABDIR/elmat/",
    "$TOOLBOXMATLABDIR/randfun/", "$TOOLBOXMATLABDIR/elfun/",
    "$TOOLBOXMATLABDIR/specfun/", "$TOOLBOXMATLABDIR/matfun/",
    "$TOOLBOXMATLABDIR/datafun/", "$TOOLBOXMATLABDIR/polyfun/",
    "$TOOLBOXMATLABDIR/funfun/", "$TOOLBOXMATLABDIR/sparfun/",
    "$TOOLBOXMATLABDIR/scribe/", "$TOOLBOXMATLABDIR/graph2d/",
    "$TOOLBOXMATLABDIR/graph3d/", "$TOOLBOXMATLABDIR/specgraph/",
    "$TOOLBOXMATLABDIR/graphics/", "$TOOLBOXMATLABDIR/uitools/",
    "$TOOLBOXMATLABDIR/strfun/", "$TOOLBOXMATLABDIR/imagesci/",
    "$TOOLBOXMATLABDIR/iofun/", "$TOOLBOXMATLABDIR/audiovideo/",
    "$TOOLBOXMATLABDIR/timefun/", "$TOOLBOXMATLABDIR/datatypes/",
    "$TOOLBOXMATLABDIR/verctrl/", "$TOOLBOXMATLABDIR/codetools/",
    "$TOOLBOXMATLABDIR/helptools/", "$TOOLBOXMATLABDIR/winfun/",
    "$TOOLBOXMATLABDIR/winfun/net/", "$TOOLBOXMATLABDIR/demos/",
    "$TOOLBOXMATLABDIR/timeseries/", "$TOOLBOXMATLABDIR/hds/",
    "$TOOLBOXMATLABDIR/guide/", "$TOOLBOXMATLABDIR/plottools/",
    "toolbox/local/", "toolbox/shared/dastudio/",
    "$TOOLBOXMATLABDIR/datamanager/", "toolbox/compiler/" };

static const char * MCC_GlobalControlSystem_classpath_data[] = 
  { "" };

static const char * MCC_GlobalControlSystem_libpath_data[] = 
  { "" };

static const char * MCC_GlobalControlSystem_app_opts_data[] = 
  { "" };

static const char * MCC_GlobalControlSystem_run_opts_data[] = 
  { "" };

static const char * MCC_GlobalControlSystem_warning_state_data[] = 
  { "off:MATLAB:dispatcher:nameConflict" };


mclComponentData __MCC_GlobalControlSystem_component_data = { 

  /* Public key data */
  __MCC_GlobalControlSystem_public_key,

  /* Component name */
  "GlobalControlSystem",

  /* Component Root */
  "",

  /* Application key data */
  __MCC_GlobalControlSystem_session_key,

  /* Component's MATLAB Path */
  MCC_GlobalControlSystem_matlabpath_data,

  /* Number of directories in the MATLAB Path */
  49,

  /* Component's Java class path */
  MCC_GlobalControlSystem_classpath_data,
  /* Number of directories in the Java class path */
  0,

  /* Component's load library path (for extra shared libraries) */
  MCC_GlobalControlSystem_libpath_data,
  /* Number of directories in the load library path */
  0,

  /* MCR instance-specific runtime options */
  MCC_GlobalControlSystem_app_opts_data,
  /* Number of MCR instance-specific runtime options */
  0,

  /* MCR global runtime options */
  MCC_GlobalControlSystem_run_opts_data,
  /* Number of MCR global runtime options */
  0,
  
  /* Component preferences directory */
  "GlobalContro_6B1460CD1A646609E7EF9459BB677E54",

  /* MCR warning status data */
  MCC_GlobalControlSystem_warning_state_data,
  /* Number of MCR warning status modifiers */
  1,

  /* Path to component - evaluated at runtime */
  NULL

};

#ifdef __cplusplus
}
#endif


