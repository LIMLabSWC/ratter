/*
 * MATLAB Compiler: 4.10 (R2009a)
 * Date: Mon Mar 26 14:18:57 2012
 * Arguments: "-B" "macro_default" "-o" "ShiftChecker" "-W" "main" "-d"
 * "C:\ratter\ExperPort\Utility\AutomatedEmails\ShiftChecker\src" "-T"
 * "link:exe" "-v" "C:\ratter\ExperPort\Utility\AutomatedEmails\ShiftChecker.m"
 * "-a" "C:\ratter\ExperPort\Utility\AutomatedEmails\checkshift.m" "-a"
 * "C:\ratter\ExperPort\Utility\check_calibration.m" "-a"
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
 * "C:\ratter\ExperPort\MySQLUtility\LIBMYSQL.dll" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\win64\zlibwapi.dll" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\win64\libmysql.dll" "-a"
 * "C:\ratter\ExperPort\MySQLUtility\win64\mym.mexw64" "-a"
 * "C:\ratter\ExperPort\Modules\Settings.m" "-a"
 * "C:\ratter\ExperPort\Settings\Settings_Custom.conf" "-a"
 * "C:\ratter\Protocols\@WaterCalibration\custom_preferences.mat" 
 */

#include "mclmcrrt.h"

#ifdef __cplusplus
extern "C" {
#endif
const unsigned char __MCC_ShiftChecker_session_key[] = {
    'A', '4', '8', 'B', '6', 'B', '2', '1', 'D', '6', '2', '8', 'C', '4', 'E',
    '3', '5', '7', '3', '2', '3', '2', 'B', '0', '1', 'B', '1', '6', '9', 'C',
    '0', '2', '8', '9', '0', '4', '0', '6', '5', '7', '8', 'D', '4', '8', '1',
    '0', '5', '8', '8', '9', '4', '3', '5', '9', 'C', 'D', '7', '4', 'F', 'B',
    '0', '8', 'D', 'B', '8', '5', '4', '9', '1', '6', 'A', '4', '3', '1', '3',
    'A', 'D', '3', '6', '2', 'F', '0', '0', '2', '0', '3', 'B', 'E', 'F', '1',
    '3', 'C', 'F', 'E', '2', '6', '7', '3', '5', '5', 'D', 'E', 'E', '6', '7',
    'C', 'E', 'B', '7', '5', '4', '6', '5', '1', '8', '5', 'A', '7', '3', 'D',
    '8', 'C', 'A', '7', '0', '3', '1', '3', '3', '2', 'E', 'C', '2', '0', '2',
    '3', 'E', 'C', '9', '4', '9', '7', '3', 'F', '4', 'D', 'E', 'D', '7', 'A',
    '8', '1', 'F', '5', '5', 'E', '9', '6', '6', '2', '4', 'F', 'E', 'E', '6',
    'F', '9', '9', '9', '8', '0', 'D', '4', 'F', 'B', '2', 'A', 'A', '2', 'D',
    '1', '6', 'E', '2', 'F', '2', 'C', '7', 'A', 'B', 'D', 'C', '9', '6', '6',
    '6', '8', '3', 'B', '2', 'F', '9', '1', '3', '3', '2', 'F', 'A', '9', '8',
    'B', '1', '4', '4', 'C', '5', 'A', '0', '6', 'E', '7', '0', '8', '0', '6',
    '3', '1', '5', 'F', '7', '3', '1', '6', '2', '9', 'C', '7', '1', 'D', '4',
    'E', '9', 'C', '7', 'F', '7', 'D', '6', 'D', 'C', '5', '9', '5', 'B', '9',
    '5', '\0'};

const unsigned char __MCC_ShiftChecker_public_key[] = {
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

static const char * MCC_ShiftChecker_matlabpath_data[] = 
  { "ShiftChecker/", "$TOOLBOXDEPLOYDIR/", "ratter/ExperPort/Utility/",
    "ratter/ExperPort/MySQLUtility/", "ratter/ExperPort/MySQLUtility/win64/",
    "ratter/ExperPort/Modules/", "ratter/ExperPort/Settings/",
    "ratter/Protocols/", "ratter/ExperPort/", "ratter/ExperPort/Analysis/",
    "ratter/ExperPort/FakeRP/", "ratter/ExperPort/HandleParam/",
    "ratter/ExperPort/Modules/NetClient/",
    "ratter/ExperPort/Modules/SoundTrigClient/", "ratter/ExperPort/Plugins/",
    "ratter/ExperPort/SoloUtility/", "ratter/ExperPort/Utility/WaterMeister/",
    "ratter/ExperPort/Utility/WeighAllRats/", "ratter/ExperPort/Utility/Zut/",
    "ratter/ExperPort/Utility/provisional/", "ratter/ExperPort/bin/",
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
    "toolbox/shared/controllib/", "toolbox/shared/dastudio/",
    "$TOOLBOXMATLABDIR/datamanager/", "toolbox/compiler/",
    "toolbox/control/control/", "toolbox/control/ctrlguis/",
    "toolbox/control/ctrlobsolete/", "toolbox/control/ctrlutil/",
    "toolbox/shared/slcontrollib/", "toolbox/daq/daq/",
    "toolbox/ident/ident/", "toolbox/ident/nlident/",
    "toolbox/ident/idobsolete/", "toolbox/ident/idutils/",
    "toolbox/shared/spcuilib/", "toolbox/instrument/instrument/",
    "toolbox/signal/signal/", "toolbox/signal/sigtools/", "toolbox/stats/" };

static const char * MCC_ShiftChecker_classpath_data[] = 
  { "java/jar/toolbox/control.jar", "java/jar/toolbox/instrument.jar",
    "java/jar/toolbox/testmeas.jar" };

static const char * MCC_ShiftChecker_libpath_data[] = 
  { "bin/win32/" };

static const char * MCC_ShiftChecker_app_opts_data[] = 
  { "" };

static const char * MCC_ShiftChecker_run_opts_data[] = 
  { "" };

static const char * MCC_ShiftChecker_warning_state_data[] = 
  { "off:MATLAB:dispatcher:nameConflict" };


mclComponentData __MCC_ShiftChecker_component_data = { 

  /* Public key data */
  __MCC_ShiftChecker_public_key,

  /* Component name */
  "ShiftChecker",

  /* Component Root */
  "",

  /* Application key data */
  __MCC_ShiftChecker_session_key,

  /* Component's MATLAB Path */
  MCC_ShiftChecker_matlabpath_data,

  /* Number of directories in the MATLAB Path */
  76,

  /* Component's Java class path */
  MCC_ShiftChecker_classpath_data,
  /* Number of directories in the Java class path */
  3,

  /* Component's load library path (for extra shared libraries) */
  MCC_ShiftChecker_libpath_data,
  /* Number of directories in the load library path */
  1,

  /* MCR instance-specific runtime options */
  MCC_ShiftChecker_app_opts_data,
  /* Number of MCR instance-specific runtime options */
  0,

  /* MCR global runtime options */
  MCC_ShiftChecker_run_opts_data,
  /* Number of MCR global runtime options */
  0,
  
  /* Component preferences directory */
  "ShiftChecker_F5061885B0FFB8B7756BA543F4665A67",

  /* MCR warning status data */
  MCC_ShiftChecker_warning_state_data,
  /* Number of MCR warning status modifiers */
  1,

  /* Path to component - evaluated at runtime */
  NULL

};

#ifdef __cplusplus
}
#endif


