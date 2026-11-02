// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navLive => 'Live';

  @override
  String get navControl => 'Control';

  @override
  String get navAutomate => 'Automate';

  @override
  String get navTune => 'Tune';

  @override
  String get navReplay => 'Replay';

  @override
  String get navDevices => 'Devices';

  @override
  String get navGuides => 'Guides';

  @override
  String get navSettings => 'Settings';

  @override
  String get navSequences => 'Sequences';

  @override
  String get navScripts => 'Scripts';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDesc => 'The app\'s language. Guides not yet translated stay in English.';

  @override
  String settingsLanguageSystem(String name) {
    return 'Same as the system ($name)';
  }

  @override
  String toastSaved(String name) {
    return 'Saved as $name';
  }

  @override
  String get stopEngagedBar => 'Stop engaged · tap to reset';

  @override
  String get stopEngagedTitle => 'Emergency stop engaged';

  @override
  String get stopKeep => 'Keep stopped';

  @override
  String get stopResetAll => 'Reset all';

  @override
  String get stopReset => 'Reset stop';

  @override
  String stopBody(String names) {
    return 'Motors are stopped and all motion commands are blocked on $names.';
  }

  @override
  String get theDevice => 'the device';

  @override
  String get stopCheck => 'Check the device before you reset. After reset it stays disarmed until you arm it again.';

  @override
  String get fleet => 'Fleet';

  @override
  String get tagSim => 'Sim';

  @override
  String get fleetActive => 'Active';

  @override
  String get fleetLost => 'Lost';

  @override
  String get fleetLinked => 'Linked';

  @override
  String get fleetOff => 'Off';

  @override
  String get fleetOn => 'On';

  @override
  String get connecting => 'Connecting';

  @override
  String get noLink => 'No link';

  @override
  String get simulated => 'Simulated';

  @override
  String get statLink => 'Link';

  @override
  String get statLost => 'Lost';

  @override
  String get statLatency => 'Latency';

  @override
  String get statBattery => 'Battery';

  @override
  String get statRecording => 'Recording';

  @override
  String get armed => 'Armed';

  @override
  String get disarmed => 'Disarmed';

  @override
  String stopLabelAll(int count) {
    return 'Emergency stop, all $count devices';
  }

  @override
  String get stopLabel => 'Emergency stop';

  @override
  String stopTipAll(int count) {
    return 'Stops all $count connected devices';
  }

  @override
  String get stopTipSlowRadio => 'STOP is still sent over this telemetry-only radio, but it is slow: up to a second';

  @override
  String get stopAll => 'Stop all';

  @override
  String get stop => 'Stop';

  @override
  String get failsafeHold => 'holding position';

  @override
  String get failsafeRth => 'returning home';

  @override
  String get failsafeLand => 'landing in place';

  @override
  String linkLostFor(String seconds) {
    return 'Link lost · $seconds s';
  }

  @override
  String failsafeActive(String action) {
    return 'Failsafe active: $action.';
  }

  @override
  String get reconnecting => 'Reconnecting. Failsafe starts at 1.8 s.';

  @override
  String get controlsLocked => 'Controls are locked until the link is back.';

  @override
  String get linkRestored => 'Link restored';

  @override
  String get linkRestoredBody => 'Manual control is available again.';

  @override
  String alertBelow(String limit) {
    return 'Below $limit.';
  }

  @override
  String alertAbove(String limit) {
    return 'Above $limit.';
  }

  @override
  String get linkLostOther => 'Its failsafe takes over after 1.8 s.';

  @override
  String get compatNewerApp => 'Needs a newer app';

  @override
  String get compatOldLib => 'Library too old';

  @override
  String compatSome(String why) {
    return 'Some features may not work: $why.';
  }

  @override
  String get compatUpdateApp => 'Update koebelt dash.';

  @override
  String get compatUpdateLib => 'Update the koebelt/link library on the device, or install an older koebelt dash in Settings > Updates.';

  @override
  String get show => 'Show';

  @override
  String alerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count alerts', one: '1 alert');
    return '$_temp0';
  }

  @override
  String get linkLost => 'Link lost';

  @override
  String get replayOffControl => 'Controls are off during a replay';

  @override
  String get replayOffControlWhy => 'Controls act on a connected device, not on a recording.';

  @override
  String get replayOffSequences => 'Sequences are off during a replay';

  @override
  String get replayOffSequencesWhy => 'Sequences run on a connected device, not on a recording.';

  @override
  String get replayOffTune => 'Tuning is off during a replay';

  @override
  String get replayOffTuneWhy => 'Parameters are read and written on a connected device, not on a recording.';

  @override
  String replayExitTo(String name) {
    return 'Exit the replay to get back to $name.';
  }

  @override
  String get replayExitConnect => 'Exit the replay, then connect a device.';

  @override
  String get replayBack => 'Back to the replay';

  @override
  String replayExitBackTo(String name) {
    return 'Exit replay, back to $name';
  }

  @override
  String get replayExit => 'Exit replay';

  @override
  String get notConnected => 'Not connected';

  @override
  String get noDeviceTitle => 'No device connected';

  @override
  String get noDeviceBody => 'Pick a paired device or pair a new one. Telemetry and controls appear once the link is up.';

  @override
  String get connectFailed => 'Could not connect';

  @override
  String get noPairedDevices => 'No paired devices yet.';

  @override
  String get offline => 'Offline';

  @override
  String batteryPct(int pct) {
    return '$pct% battery';
  }

  @override
  String get connect => 'Connect';

  @override
  String get pairNewDevice => 'Pair new device';

  @override
  String get or => 'Or';

  @override
  String get addSimulated => 'Add a simulated device';

  @override
  String get addSimulatedDesc => 'A virtual drone, rover, arm, rocket or test bench, to try the app without hardware.';

  @override
  String get openRecording => 'Open a recording';

  @override
  String get openRecordingDesc => 'Replay a session, a flight log or the sample recordings.';

  @override
  String get setUpLibrary => 'Set up the library';

  @override
  String get setUpLibraryDesc => 'Add koebelt/link to your Arduino, Python, ROS 2 or Rust project.';

  @override
  String get noDevice => 'No device';

  @override
  String get tagDemo => 'Demo';

  @override
  String moreConnected(int count) {
    return '+$count connected';
  }

  @override
  String get alsoConnected => 'Also connected';

  @override
  String get disconnectAll => 'Disconnect all';

  @override
  String get connectAnother => 'Connect another';

  @override
  String get pairedDevices => 'Paired devices';

  @override
  String get noPairedDevicesShort => 'No paired devices';

  @override
  String get noPairedDevicesHint => 'Pair one, add a simulated device, or follow the quickstart.';

  @override
  String get pairDevice => 'Pair device';

  @override
  String get quickstart => 'Quickstart';

  @override
  String get manage => 'Manage';

  @override
  String get replaying => 'Replaying';

  @override
  String get closeReplay => 'Close replay';

  @override
  String get simulator => 'Simulator';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get open => 'Open';

  @override
  String get sequenceRunning => 'sequence running';

  @override
  String disconnectName(String name) {
    return 'Disconnect $name';
  }

  @override
  String get automateSeqBlurb => 'Steps in order, no code: take off, fly to, wait, land; drive to; move to a pose.';

  @override
  String get automateSeqPoint1 => 'No code: build it in the app';

  @override
  String get automateSeqPoint2 => 'Runs on the device when it can store it';

  @override
  String get automateSeqPoint3 => 'Keeps going if the link drops';

  @override
  String get automateSeqConnect => 'Connect a device to build its sequences';

  @override
  String automateSeqCount(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sequences', one: '1 sequence', zero: 'No sequence');
    return '$_temp0 for $name';
  }

  @override
  String get automateScriptBlurb => 'Python that reads the telemetry and the camera, decides, and drives the device.';

  @override
  String get automateScriptPoint1 => 'Logic, sensors, the camera';

  @override
  String get automateScriptPoint2 => 'Any package: OpenCV, PyTorch, YOLO';

  @override
  String get automateScriptPoint3 => 'Triggers: buttons, keys, conditions, timers';

  @override
  String get automateScriptPoint3Host => 'Runs on a script host: a computer on your network';

  @override
  String scriptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count scripts', one: '1 script', zero: 'No script');
    return '$_temp0';
  }

  @override
  String get automateEyebrow => 'Two ways to automate';

  @override
  String runningOn(String what, String device) {
    return '$what on $device';
  }

  @override
  String get automateTogether1 => 'Together: a script can start a sequence, ';

  @override
  String get automateTogether2 => ', and decide when.';

  @override
  String get sequenceOrScript => 'Sequence or script?';

  @override
  String get running => 'Running';

  @override
  String get layoutHud => 'HUD';

  @override
  String get layoutWall => 'WALL';

  @override
  String get editLayout => 'Edit layout';

  @override
  String get sceneLayers3d => '3D scene layers';

  @override
  String get layerCloud => 'Point cloud';

  @override
  String get layerTrail => 'Trajectory';

  @override
  String get layerRadar => 'Radar tracks';

  @override
  String get layerGrid => 'Ground grid';

  @override
  String get sceneLayers => 'Scene layers';

  @override
  String get addWidget => 'Add widget';

  @override
  String widgetsSavedFor(String device, String screens) {
    return 'Widgets are saved for $device on $screens screens.';
  }

  @override
  String get thisDevice => 'this device';

  @override
  String get screenPhone => 'phone';

  @override
  String get screenShort => 'sideways phone';

  @override
  String get screenPortrait => 'upright tablet';

  @override
  String get screenTablet => 'tablet';

  @override
  String get screenDesktop => 'desktop';

  @override
  String get reset => 'Reset';

  @override
  String get cancel => 'Cancel';

  @override
  String get saveLayout => 'Save layout';

  @override
  String get back => 'Back';

  @override
  String get paused => 'Paused';

  @override
  String get stale => 'Stale';

  @override
  String hzLive(int hz) {
    return '$hz Hz live';
  }

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statMean => 'Mean';

  @override
  String get unit => 'Unit';

  @override
  String get window => 'Window';

  @override
  String get windowValue => '10 s · 300 samples';

  @override
  String get source => 'Source';

  @override
  String get tapChannelToHide => 'Tap a channel to hide it';

  @override
  String get rec => 'Rec';

  @override
  String get speedLimit => 'Speed limit';

  @override
  String get setHomePose => 'Set home pose';

  @override
  String get setHomeHere => 'Set home here';

  @override
  String get useThisPose => 'Use this pose';

  @override
  String get setHome => 'Set home';

  @override
  String get setHomePoseBody => 'The current joint angles become the pose that Home pose and sequence Home steps move to.';

  @override
  String setHomeBody(String metres) {
    return 'The current position becomes home (0, 0). Return-to-home flies back here, and sequence waypoints are measured from here. The device is $metres m from the current home.';
  }

  @override
  String get autoDashDrives => 'dash drives it';

  @override
  String get autoTakeBack => 'Choose MANUAL or HOLD, or move the sticks, to take it back.';

  @override
  String get autoTip => 'dash’s mode: while a sequence or a script drives the device. Run one from Automate.';

  @override
  String get tiltDrag => 'Tilt · drag to simulate';

  @override
  String get stickThrottle => 'Throttle';

  @override
  String get stickDrive => 'Drive';

  @override
  String get stickYaw => 'Yaw';

  @override
  String get stickPitchRoll => 'Pitch · roll';

  @override
  String get stickSteer => 'Steer';

  @override
  String get stickThrottleYaw => 'Throttle · yaw';

  @override
  String get tiltPitchRoll => 'Tilt · pitch and roll';

  @override
  String get tiltSteerDrive => 'Tilt · steer and drive';

  @override
  String get axUp => 'UP';

  @override
  String get axDn => 'DN';

  @override
  String get axFwd => 'FWD';

  @override
  String get axRev => 'REV';

  @override
  String get axBack => 'BACK';

  @override
  String get axL => 'L';

  @override
  String get axR => 'R';

  @override
  String get axYaw => 'YAW';

  @override
  String get rdAlt => 'Alt';

  @override
  String get rdOdom => 'Odom';

  @override
  String get rdSpeed => 'Speed';

  @override
  String get rdHdg => 'Hdg';

  @override
  String get rdHome => 'Home';

  @override
  String get rdVz => 'Vz';

  @override
  String get rdMax => 'Max';

  @override
  String get rdRange => 'Range';

  @override
  String get rdToolX => 'Tool X';

  @override
  String get rdToolY => 'Tool Y';

  @override
  String get rdToolZ => 'Tool Z';

  @override
  String get rdThrust => 'Thrust';

  @override
  String get rdRpm => 'RPM';

  @override
  String get rdCurrent => 'Current';

  @override
  String get rdPower => 'Power';

  @override
  String get rdTemp => 'Temp';

  @override
  String get rdEfficiency => 'Efficiency';

  @override
  String get homePose => 'Home pose';

  @override
  String get setAsHome => 'Set as home';

  @override
  String get armJoint => 'Joint';

  @override
  String get armCartesian => 'Cartesian';

  @override
  String get toolFrame => 'Tool frame · base-relative';

  @override
  String armPadHelp(String frame, String wristBtn, String wrist, String gripper) {
    return 'Controller · $frame: joint / cartesian · $wristBtn: $wrist · $gripper: gripper';
  }

  @override
  String get armWrist => 'wrist';

  @override
  String get gripper => 'Gripper';

  @override
  String gripperOpenPct(int pct) {
    return '$pct% open';
  }

  @override
  String get gripperOpen => 'Open';

  @override
  String get gripperClose => 'Close';

  @override
  String get flightPhase => 'Flight phase';

  @override
  String get phasePad => 'On pad';

  @override
  String get phaseCount => 'Countdown';

  @override
  String get phaseBoost => 'Boost';

  @override
  String get phaseCoast => 'Coast';

  @override
  String get phaseDrogue => 'Drogue';

  @override
  String get phaseMain => 'Main';

  @override
  String get phaseLanded => 'Landed';

  @override
  String get preflight => 'Pre-flight';

  @override
  String get checkPyro => 'Pyro continuity · drogue, main';

  @override
  String get ok => 'OK';

  @override
  String get check => 'Check';

  @override
  String get checkGps => 'GPS lock';

  @override
  String sats(int count) {
    return '$count sats';
  }

  @override
  String get noFix => 'No fix';

  @override
  String get checkFlightComputer => 'Flight computer';

  @override
  String get safe => 'Safe';

  @override
  String get armFlightComputer => 'Arm flight computer';

  @override
  String get armPadClear => 'Arm only when the pad is clear';

  @override
  String startCountdown(String seconds) {
    return 'Start countdown · $seconds s';
  }

  @override
  String get abortLaunch => 'Abort launch';

  @override
  String get deployDrogue => 'Deploy drogue';

  @override
  String get deployMain => 'Deploy main';

  @override
  String autoDeploy(String metres) {
    return 'Auto deploy · drogue at apogee · main at $metres m';
  }

  @override
  String landedBody(String apogee, String distance) {
    return 'Apogee $apogee m · landed $distance m from the pad.';
  }

  @override
  String get resetToPad => 'Reset to pad';

  @override
  String get altitude => 'Altitude';

  @override
  String get cutoff => 'Cutoff';

  @override
  String get cutoffLimit => 'limit';

  @override
  String get cutoffBody => 'Throttle was set to 0. Check the motor before running again.';

  @override
  String get clear => 'Clear';

  @override
  String get benchDisarmed => 'Arm the bench to spin the motor. Keep clear of the propeller.';

  @override
  String get testSequence => 'Test sequence';

  @override
  String get benchRamp => 'RAMP';

  @override
  String get benchSteps => 'STEPS';

  @override
  String get runAndRecord => 'Run and record';

  @override
  String benchRampDesc(String seconds) {
    return 'Ramp 0 to 100 % over $seconds s, hold 2 s, stop.';
  }

  @override
  String benchStepsDesc(String size, String seconds) {
    return 'Steps of $size %, $seconds s each, up to 100 %.';
  }

  @override
  String benchLimits(String amps, String celsius) {
    return 'Limits: $amps A, $celsius °C.';
  }

  @override
  String get mspTitle => 'Monitoring and tuning';

  @override
  String mspBody(String name, String firmware) {
    return '$name runs $firmware and is connected over MSP, the configuration link. The app shows its telemetry, tunes its PID gains on the Tune screen, and STOP disarms it. Fly it with your RC transmitter.';
  }

  @override
  String get radioOnlyTitle => 'Telemetry-only link';

  @override
  String radioOnlyBody(String name, String radio) {
    return '$name is connected through $radio, which carries telemetry only. Sticks, modes and commands do not reach the device this way; STOP does, within about a second. Control it over its main link (Wi-Fi, Bluetooth or a SiK radio) and rely on its failsafe when that link is out of range.';
  }

  @override
  String get aRadio => 'a radio';

  @override
  String get tileReadouts => 'Readouts';

  @override
  String get tileSrcFused => 'Fused state';

  @override
  String get tileAttitude => 'Attitude';

  @override
  String get tileAccelerometer => 'Accelerometer';

  @override
  String get tileGyroscope => 'Gyroscope';

  @override
  String get tileSrcBaroRange => 'Baro + rangefinder';

  @override
  String get tileRadar => 'Radar';

  @override
  String get tileSrcRadar => 'Radar / safety scanner';

  @override
  String get tileLidar => 'Lidar';

  @override
  String get tileSrcLidar => 'Scanning lidar';

  @override
  String get tileJoints => 'Joints';

  @override
  String get tileSrcJoints => 'Joint encoders';

  @override
  String get tileForceTorque => 'Force / torque';

  @override
  String get tileSrcWrist => 'Wrist F/T sensor';

  @override
  String get tileSrcPower => 'Power module';

  @override
  String get tileSrcRadio => 'Radio link';

  @override
  String get tileCamera => 'Camera';

  @override
  String get tileSrcCamera => 'Device camera · MJPEG';

  @override
  String get tileSrcFleet => 'Every connected device';

  @override
  String get tileSrcPhase => 'Flight computer state machine';

  @override
  String get tileVerticalSpeed => 'Vertical speed';

  @override
  String get tileSrcBaroImu => 'Baro + IMU fusion';

  @override
  String get tilePyro => 'Pyro channels';

  @override
  String get tileSrcPyro => '4-channel pyro board';

  @override
  String get tileSrcTacho => 'Optical tachometer';

  @override
  String get tileTorque => 'Torque';

  @override
  String get tileSrcTorque => 'Reaction torque cell';

  @override
  String get tileMotorTemp => 'Motor temp';

  @override
  String get tileSrcNtc => 'NTC thermistor';

  @override
  String get tileRollRate => 'Roll rate';

  @override
  String get tilePitchRate => 'Pitch rate';

  @override
  String get tileYawRate => 'Yaw rate';

  @override
  String get tileGroundSpeed => 'Ground speed';

  @override
  String get tileAgl => 'AGL';

  @override
  String get tileOwnSpeed => 'Own speed';

  @override
  String get tileVoltage => 'Voltage';

  @override
  String get tilePyroBus => 'Pyro bus';

  @override
  String get tileStator => 'Stator';

  @override
  String get tileVibration => 'Vibration';

  @override
  String get tileAcc200 => 'Accelerometer · 200 G';

  @override
  String get tileSafetyScanner => 'Safety scanner';

  @override
  String tracks(int count) {
    return '$count tracks';
  }

  @override
  String points(int count) {
    return '$count pts';
  }

  @override
  String axes(int count) {
    return '$count axes';
  }

  @override
  String connectedCount(int count) {
    return '$count connected';
  }

  @override
  String armedCount(int count) {
    return '$count armed';
  }

  @override
  String get proxClear => 'clear';

  @override
  String get tileProximity => 'Proximity';

  @override
  String get tileSrcProx => 'Proximity sensors';

  @override
  String tileSrcCustom(String hz) {
    return 'Custom channel · $hz Hz';
  }

  @override
  String get tagScript => 'Script';

  @override
  String get viewEnded => 'ended';

  @override
  String series(int count) {
    return '$count series';
  }

  @override
  String get rdReach => 'Reach';

  @override
  String get pyroDrogue => 'Drogue';

  @override
  String get pyroMain => 'Main';

  @override
  String get pyroAirstart => 'Airstart';

  @override
  String get pyroSpare => 'Spare';

  @override
  String get pyroContinuity => 'Continuity';

  @override
  String get pyroFired => 'Fired';

  @override
  String get pyroNotWired => 'Not wired';

  @override
  String removeTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeDevice => 'Remove device';

  @override
  String removeBody(String name) {
    return 'The pairing key, HUD layouts and parameter drafts for $name are deleted from this app.';
  }

  @override
  String get removeDisconnectFirst => 'It will be disconnected first.';

  @override
  String get removeKept => 'Recordings are kept. To use the device again, pair it with a new code.';

  @override
  String onlineOf(int online, int total) {
    return '$online of $total online';
  }

  @override
  String get devicesEmptyHint => 'Pair a device, or follow the quickstart to add the library to your project.';

  @override
  String get devicesSeveral =>
      'Several devices can be connected at once. The one shown gets the sticks; the others hold on centred sticks, and STOP stops them all.';

  @override
  String get connected => 'Connected';

  @override
  String removeName(String name) {
    return 'Remove $name';
  }

  @override
  String get online => 'Online';

  @override
  String get batShort => 'BAT';

  @override
  String get myRobot => 'My robot';

  @override
  String radioNothingHeard(String port, int baud) {
    return 'Nothing heard on $port at $baud baud. Check that the device is on, both radios use the same channel and air rate, and the baud rate matches. You can still add the link and connect later.';
  }

  @override
  String get pairTitle => 'Pair a device';

  @override
  String get pairNearby => 'Nearby';

  @override
  String get pairRadio => 'Radio';

  @override
  String get pairSimulated => 'Simulated';

  @override
  String get pairSimulatedIntro =>
      'Simulated devices run inside this app and speak the same protocol as real hardware. Add only the ones you need; each one is listed with a SIM tag.';

  @override
  String get added => 'Added';

  @override
  String get addAnother => 'Add another';

  @override
  String get add => 'Add';

  @override
  String radioRatesTlm(int tlm) {
    return 'Telemetry $tlm Hz · no control';
  }

  @override
  String radioRates(int tlm, int ctl) {
    return 'Telemetry $tlm Hz · control $ctl Hz';
  }

  @override
  String get radioIntro => 'A radio link is a radio modem plugged into this computer or phone over USB, talking to a matching radio on the device.';

  @override
  String get radioIntroMore => 'To the app it is a serial port; the radio type sets the speed and how much it can carry.';

  @override
  String get radioNoSerial => 'No USB serial on this platform';

  @override
  String get radioNoSerialBody =>
      'iOS apps cannot open USB serial adapters. Use the app on Android, macOS, Windows or Linux for radio links, or connect over Wi-Fi or Bluetooth.';

  @override
  String get radioLora =>
      'LoRa modules are not USB devices on their own. Flash the ground-station sketch from the LoRa guide onto a second board with the radio, and plug that board in.';

  @override
  String get usbPort => 'USB port';

  @override
  String get refresh => 'Refresh';

  @override
  String get noSerialPorts => 'No serial ports found. Plug in the radio’s USB adapter.';

  @override
  String get baudRate => 'Baud rate';

  @override
  String heard(String name) {
    return 'Heard $name';
  }

  @override
  String get heardMavlink => 'It speaks MAVLink: no pairing needed.';

  @override
  String get heardPairing => 'It is in pairing mode and will get a key.';

  @override
  String get heardNoPairing => 'It is not in pairing mode; it is added without a key.';

  @override
  String get listening => 'Listening';

  @override
  String get listenForDevice => 'Listen for device';

  @override
  String pairName(String name) {
    return 'Pair $name';
  }

  @override
  String get addRadioLink => 'Add radio link';

  @override
  String get pairNearbyIntro =>
      'Plug in or power on the board. Flight controllers and drones appear on their own; boards running the koebelt/link library also show up here while in pairing mode.';

  @override
  String get scanning => 'Scanning Wi-Fi, Bluetooth and USB boards…';

  @override
  String get stillScanning => 'Still scanning for more devices…';

  @override
  String get addByIp => 'Add by IP address';

  @override
  String get name => 'Name';

  @override
  String get mavlinkPortNote => 'The app listens on UDP 14550, like any ground station; the port is the vehicle’s, if you know it.';

  @override
  String get addDevice => 'Add device';

  @override
  String get notShowingUp =>
      'Device not showing up? Boards with ArduPilot, PX4, Betaflight or INAV connect as they are; anything else needs the koebelt/link library.';

  @override
  String get openQuickstart => 'Open the quickstart';

  @override
  String get orLower => 'or';

  @override
  String get addItByIp => 'add it by IP address';

  @override
  String get secControl => 'Control';

  @override
  String get secController => 'Game controller';

  @override
  String get secLink => 'Link and safety';

  @override
  String get secRecording => 'Recording';

  @override
  String get secAlerts => 'Alerts';

  @override
  String get secMap => 'Map';

  @override
  String get secPairing => 'Pairing';

  @override
  String get secAi => 'AI assistants (MCP)';

  @override
  String get secAiShort => 'AI assistants';

  @override
  String get secUpdates => 'Updates';

  @override
  String get setInput => 'Input method';

  @override
  String get setInputDesc =>
      'Sticks: two virtual joysticks. Sliders: spring-loaded throttle and yaw with one stick. Tilt: steer by tilting the phone or tablet.';

  @override
  String get csSticks => 'STICKS';

  @override
  String get csSliders => 'SLIDERS';

  @override
  String get csTilt => 'TILT';

  @override
  String get setInvert => 'Invert pitch';

  @override
  String get setInvertDesc => 'Push forward to pitch up.';

  @override
  String get setHaptics => 'Haptic feedback';

  @override
  String get setHapticsDesc => 'Vibrate at stick centre and on warnings.';

  @override
  String get setLinkLoss => 'On link loss';

  @override
  String get setLinkLossDesc =>
      'What a drone does after 1.8 s without a control packet. Ground robots and arms hold, test benches stop the motor, rockets continue their flight sequence.';

  @override
  String get setRate => 'Telemetry rate';

  @override
  String get setRateDesc => 'Higher rates use more bandwidth and battery.';

  @override
  String get setTestFailsafe => 'Test failsafe';

  @override
  String get setTestFailsafeDesc => 'Drops the control link for six seconds so you can check the configured behaviour.';

  @override
  String get runTest => 'Run test';

  @override
  String get setRecordVideo => 'Record video';

  @override
  String get setRecordVideoDesc => 'Keep the device’s camera with each recording. The camera stays connected while recording, even when no screen shows it.';

  @override
  String get setVideoFps => 'Video frame rate';

  @override
  String get setVideoFpsDesc => 'Most frames a second kept. An ESP32-CAM at 640×480 takes about 10 MB a minute at 10 fps.';

  @override
  String get setAlertSound => 'Alert sound';

  @override
  String get setAlertSoundDesc => 'Plays on alerts and when the link is lost. Phones vibrate instead when haptics are on.';

  @override
  String kindsOnly(String kinds) {
    return '$kinds only.';
  }

  @override
  String get below => 'Below';

  @override
  String get above => 'Above';

  @override
  String get setMapTiles => 'Map tiles';

  @override
  String get setMapTilesDesc =>
      'Background for the map view: Mapbox Dark, Outdoors (terrain) or Satellite, your own tiles, or none (a metre grid). Tiles you have looked at stay on this device for a while.';

  @override
  String get mapDark => 'DARK';

  @override
  String get mapOutdoors => 'OUTDOORS';

  @override
  String get mapSatellite => 'SATELLITE';

  @override
  String get mapCustom => 'CUSTOM';

  @override
  String get mapNone => 'NONE';

  @override
  String get setMapboxToken => 'Your Mapbox token';

  @override
  String get setMapboxTokenDesc => 'Optional: a public token (pk.…) from your own Mapbox account, to use your quota instead of the app’s.';

  @override
  String get setTileUrl => 'Tile URL';

  @override
  String setTileUrlDesc(String z, String x, String y) {
    return 'A template with $z, $x and $y, for example a satellite layer from your map provider with its key. Respect the provider’s terms.';
  }

  @override
  String get setAttribution => 'Attribution';

  @override
  String get setAttributionDesc => 'The credit your provider requires, shown on the map.';

  @override
  String get provider => 'Provider';

  @override
  String get setGuides => 'Integration guides';

  @override
  String get setGuidesDesc => 'Add the koebelt/link library to Arduino, Python, ROS 2 or Rust projects.';

  @override
  String scriptHostAt(String address) {
    return 'Script host at $address';
  }

  @override
  String get forget => 'Forget';

  @override
  String get setScriptHosts => 'Script hosts';

  @override
  String get setScriptHostsDesc =>
      'Computers on the network that run scripts for this device, with any Python package. On the computer: pip install koebelt-dash-scripts, then koebelt-dash-scripts host.';

  @override
  String get setScriptHostsDescPhone =>
      'Computers on the network that run scripts for this phone, with any Python package. On the computer: pip install koebelt-dash-scripts, then koebelt-dash-scripts host.';

  @override
  String get setBeHost => 'Be a script host';

  @override
  String get setBeHostDesc => 'Run scripts for phones and tablets on this network, with the scripts’ Python.';

  @override
  String setBeHostCode(String code) {
    return 'Pairing code: $code. Phones pair in Scripts > Runs on > Add a script host.';
  }

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sessions', one: '1 session');
    return '$_temp0';
  }

  @override
  String get import => 'Import';

  @override
  String get record => 'Record';

  @override
  String get noRecordings => 'No recordings yet. Record a connected device, or use Import for a file or the sample recordings.';

  @override
  String get tagNew => 'New';

  @override
  String get tagVideo => 'Video';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count devices', one: '1 device');
    return '$_temp0';
  }

  @override
  String deleteName(String name) {
    return 'Delete $name';
  }

  @override
  String exportName(String name) {
    return 'Export $name';
  }

  @override
  String get replayEyebrow => 'Recording and playback';

  @override
  String get sessions => 'Sessions';

  @override
  String get export => 'Export';

  @override
  String get exitToLive => 'Exit to live';

  @override
  String get play => 'Play';

  @override
  String deleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get exportFirst => 'Export first';

  @override
  String get delete => 'Delete';

  @override
  String get deleteRecordingBody => 'The recording is removed from this device. This cannot be undone.';

  @override
  String deleteAllN(int count) {
    return 'Delete all $count';
  }

  @override
  String get deleteSessionBody => 'Every device’s recording of this session is removed from this device, with its video. This cannot be undone.';

  @override
  String sequenceN(int n) {
    return 'Sequence $n';
  }

  @override
  String sequencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sequences', one: '1 sequence', zero: 'no sequence');
    return '$_temp0';
  }

  @override
  String copyOf(String name) {
    return '$name copy';
  }

  @override
  String noSequencesFor(String name) {
    return 'No sequences for $name yet.';
  }

  @override
  String sequenceIntro(String examples) {
    return 'A sequence is a list of steps ($examples) that the app runs one after the other, waiting for the device to confirm each one.';
  }

  @override
  String get sequenceComplete => 'Sequence complete';

  @override
  String get sequenceStopped => 'Sequence stopped';

  @override
  String get flightSequence => 'Flight sequence';

  @override
  String get flightSequenceBody =>
      'The flight computer runs launch, apogee and recovery on board. Set deployment on the Tune screen; use sequences here for pad checks.';

  @override
  String get stepsDrone => 'take off, fly to waypoints, wait, land';

  @override
  String get stepsRover => 'drive to waypoints, wait, change speed';

  @override
  String get stepsArm => 'move to poses, open or close the gripper';

  @override
  String get stepsBench => 'hold a throttle, ramp between two throttles';

  @override
  String get stepsGeneric => 'wait, set a mode, send commands';

  @override
  String get whyExitReplay => 'Exit replay to run';

  @override
  String get whyResetStop => 'Reset the stop first';

  @override
  String get whyAddSteps => 'Add steps first';

  @override
  String get onDevice => 'On device';

  @override
  String get uploading => 'Uploading';

  @override
  String stepOf(int n, int total) {
    return 'step $n of $total';
  }

  @override
  String get runsOnDevice => 'Runs on the device: it carries on if the link drops';

  @override
  String get stopSequence => 'Stop sequence';

  @override
  String get stoppedFromApp => 'Stopped from the app';

  @override
  String get run => 'Run';

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count steps', one: '1 step');
    return '$_temp0';
  }

  @override
  String secondsTimed(String seconds) {
    return '$seconds s timed';
  }

  @override
  String get newSequence => 'New sequence';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get steps => 'Steps';

  @override
  String get lockedWhileRunning => 'Locked while running';

  @override
  String get addFirstStep => 'Add the first step below. Steps run top to bottom.';

  @override
  String get addStep => 'Add step';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get deleteStep => 'Delete step';

  @override
  String get useCurrentPosition => 'Use current position';

  @override
  String get useCurrentPose => 'Use current pose';

  @override
  String get egDeploy => 'e.g. deploy';

  @override
  String get planTopView => 'Plan · top view';

  @override
  String get throttleProfile => 'Throttle profile';

  @override
  String get liveView => 'Live view';

  @override
  String get timeline => 'Timeline';

  @override
  String get setPoseAsHome => 'Set current pose as home';

  @override
  String get planNoteDrone =>
      'Waypoints are metres east and north of the take-off point. The drone holds at each one before the next step. The failsafe still applies if the link drops.';

  @override
  String get planNoteRover => 'Waypoints are metres east and north of the start point. The rover stops at each one before the next step.';

  @override
  String planNoteArm(String button) {
    return 'Move the arm by hand or with jog controls, then use “$button” to record it.';
  }

  @override
  String get planNoteBench => 'Current and temperature cutoffs on the device stay active during the sequence.';

  @override
  String get planNoteGeneric => 'Each step waits for the device to confirm before the next one starts.';

  @override
  String metreGrid(String metres) {
    return '$metres m grid';
  }

  @override
  String get now => 'Now';

  @override
  String get and => 'and';

  @override
  String get checkNeedsPython => 'Check needs Python on this computer: Set up Python on the script’s page.';

  @override
  String couldNotCheck(String python) {
    return 'Could not check with $python.';
  }

  @override
  String scriptErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'This script has $count errors', one: 'This script has an error');
    return '$_temp0';
  }

  @override
  String get runAnyway => 'Run anyway';

  @override
  String get showThem => 'Show them';

  @override
  String get checkFound => 'Check found what would stop it, probably before it moves anything:';

  @override
  String lineN(int n) {
    return 'line $n';
  }

  @override
  String andMore(int count) {
    return 'and $count more';
  }

  @override
  String get installImports => 'Install what this script imports?';

  @override
  String get installAndRun => 'Install and run';

  @override
  String missingImports(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names are not in this Python, so the script would stop at its imports.',
      one: '$names is not in this Python, so the script would stop at its imports.',
    );
    return '$_temp0';
  }

  @override
  String couldNotStart(String error) {
    return 'Could not start: $error';
  }

  @override
  String get pythonScripts => 'Python scripts';

  @override
  String copiedExample(String file) {
    return 'Copied the example to $file in your scripts.';
  }

  @override
  String couldNotCopyExample(String error) {
    return 'Could not copy the example: $error';
  }

  @override
  String get rename => 'Rename';

  @override
  String get deleteScriptBody => 'It moves to the .trash folder inside the scripts folder, where you can get it back.';

  @override
  String get error => 'Error';

  @override
  String get examples => 'Examples';

  @override
  String get connectedOutside => 'Connected from outside dash';

  @override
  String get editing => 'editing';

  @override
  String get saved => 'saved';

  @override
  String get checkAction => 'Check';

  @override
  String get checking => 'Checking…';

  @override
  String get openInEditor => 'Open in editor';

  @override
  String get newScript => 'New script';

  @override
  String get importPyZip => 'Import a .py or .zip';

  @override
  String get noScriptsPlus => 'No scripts yet. Start from an example, or press +.';

  @override
  String get scriptsEmpty => 'Scripts drive your devices from Python. Create one, import one, or start from an example.';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get noScriptsNew => 'No scripts yet. Start from an example, or press New.';

  @override
  String get more => 'More';

  @override
  String get showInFinder => 'Show in Finder';

  @override
  String get showInFolder => 'Show in folder';

  @override
  String get myScript => 'My script';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get device => 'Device';

  @override
  String get needs => 'Needs';

  @override
  String get runsOn => 'Runs on';

  @override
  String get scriptsRunOnComputer => 'Scripts run on a computer';

  @override
  String get scriptsRunOnComputerBody =>
      'This device sends them to a script host: a computer on the same network running koebelt-dash-scripts, which can use any Python package (OpenCV, PyTorch…).';

  @override
  String get addScriptHost => 'Add a script host';

  @override
  String get notRunning => 'Not running';

  @override
  String get endedError => 'Ended with an error';

  @override
  String get ended => 'Ended';

  @override
  String get waitingConnect => 'Waiting for the script to connect (connect() in the script)…';

  @override
  String get youHaveSticks => 'You have the sticks';

  @override
  String get youHaveSticksBody => 'You moved the sticks, so the script’s are ignored.';

  @override
  String get scriptLostSticks => 'The script lost the sticks';

  @override
  String isNotConnected(String name) {
    return '$name is not connected';
  }

  @override
  String get connectItOrChoose => 'Connect it, or choose another device above.';

  @override
  String doesNotFit(String name) {
    return '$name does not fit this script';
  }

  @override
  String get chooseOrChangeRequires => 'Choose another device above, or change the # requires: line.';

  @override
  String get scriptNeedsDevice => 'A script drives a device: connect one first (Devices, or the device menu at the top).';

  @override
  String get doesNotFitShort => 'does not fit';

  @override
  String get selectedInDash => 'Selected in dash';

  @override
  String get noneConnected => 'none connected';

  @override
  String get thisComputer => 'This computer';

  @override
  String get lookingForPython => 'Looking for Python…';

  @override
  String get noneFound => 'None found';

  @override
  String get noPackage => 'no package';

  @override
  String get python3Needed => 'Python 3 is needed';

  @override
  String get python3NeededBody => 'Install it from python.org, then come back here.';

  @override
  String get newerLibrary => 'A newer version of the library scripts use is out, for this version of koebelt dash.';

  @override
  String get update => 'Update';

  @override
  String get pythonNoAnswer => 'This Python does not answer';

  @override
  String get packageNotInPython => 'koebelt-dash-scripts is not in this Python';

  @override
  String pythonNoAnswerBody(String python) {
    return 'dash could not run $python. Choose another, or create a scripts environment.';
  }

  @override
  String get packageNotInPythonBody => 'Install it here (pip install koebelt-dash-scripts), or let dash create a scripts environment in the scripts folder.';

  @override
  String get installHere => 'Install here';

  @override
  String get scriptsEnvironment => 'Scripts environment';

  @override
  String get checkAgain => 'Check again';

  @override
  String get settingUpPython => 'Setting up Python';

  @override
  String get oneTimeSetup => 'One-time setup';

  @override
  String get oneTimeSetupBody =>
      'Scripts need the koebelt-dash-scripts package. dash can create a Python environment for them in the scripts folder (.venv) and install it there; your own packages (OpenCV, PyTorch…) go there too.';

  @override
  String get setUpPython => 'Set up Python';

  @override
  String packagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Packages are missing', one: 'A package is missing');
    return '$_temp0';
  }

  @override
  String packagesMissingBody(String modules, String packages) {
    return 'This script imports $modules, not in this Python: it would stop there. Install $packages?';
  }

  @override
  String get installing => 'Installing…';

  @override
  String get install => 'Install';

  @override
  String get notNow => 'Not now';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get stopScript => 'Stop script';

  @override
  String get restart => 'Restart';

  @override
  String get triggers => 'Triggers';

  @override
  String get triggersEmpty =>
      'Buttons, keys, controller buttons, conditions and timers that send events to the script. Declare them with @dev.trigger(…), or add them here.';

  @override
  String get limits => 'Limits';

  @override
  String get maxSpeed => 'Max speed';

  @override
  String get geofence => 'Geofence';

  @override
  String get off => 'off';

  @override
  String metresFromHome(int metres) {
    return '$metres m from home';
  }

  @override
  String get ceiling => 'Ceiling';

  @override
  String get armingTakeoff => 'Arming, take-off';

  @override
  String get allowed => 'allowed';

  @override
  String get notAllowed => 'not allowed';

  @override
  String get paramWrites => 'Parameter writes';

  @override
  String get fire => 'Fire';

  @override
  String get notBound => 'Not bound yet';

  @override
  String get console => 'Console';

  @override
  String loopHz(String hz) {
    return 'loop $hz Hz';
  }

  @override
  String get consoleEmpty => 'print() output and errors show here.';

  @override
  String get fromOutside => 'from outside dash';

  @override
  String get valid => 'Valid';

  @override
  String padTaken(String button, String action) {
    return '$button is $action in the controller mapping: that action wins.';
  }

  @override
  String get forDuration => 'for';

  @override
  String conditionHelp(String fields) {
    return 'Fields: $fields, mode, armed, and the device’s own channels (motor_temp.max…). Combine with and, or, not; add “for 3s” to wait.';
  }

  @override
  String get whenTrue => 'WHEN TRUE';

  @override
  String get trueAndFalse => 'TRUE AND FALSE';

  @override
  String get alsoOnControl => 'Also on Control, next to the sticks';

  @override
  String get key => 'Key';

  @override
  String get pressKey => 'Press a key…';

  @override
  String pressAnotherKey(String key) {
    return '$key · press another to change';
  }

  @override
  String get clickThenKey => 'Click, then press a key';

  @override
  String get noButtonYet => 'No button yet';

  @override
  String get pressButton => 'Press a button…';

  @override
  String get learn => 'Learn';

  @override
  String get onlyThisMode => 'Only this mode (HOLD…), or empty for any';

  @override
  String get onlyMessagesContaining => 'Only messages containing…';

  @override
  String get every => 'EVERY';

  @override
  String get onceAfter => 'ONCE AFTER';

  @override
  String get secondsWord => 'seconds';

  @override
  String get addTrigger => 'Add trigger';

  @override
  String get editTrigger => 'Edit trigger';

  @override
  String get event => 'Event';

  @override
  String get eventPlaceholder => 'The name the script receives';

  @override
  String get firedBy => 'Fired by';

  @override
  String triggerHelp(String event) {
    return 'The script receives “$event” in the handler of that name, or in @dev.on_trigger. Conditions, events and timers run in dash.';
  }

  @override
  String get done => 'Done';

  @override
  String get limitsHelp => 'Set here, not in the script: the script cannot change them.';

  @override
  String get maximumSpeed => 'Maximum speed';

  @override
  String get maximumSpeedDesc => 'The script’s sticks are scaled to this, and its speed limit capped.';

  @override
  String get geofenceDesc => 'Beyond this distance from home, the script loses the sticks and the device holds.';

  @override
  String get ceilingDesc => 'Above this height, the same for drones.';

  @override
  String get allowArming => 'Allow arming and take-off';

  @override
  String get allowArmingDesc => 'Otherwise the script can only move a device you armed.';

  @override
  String get allowParams => 'Allow parameter writes';

  @override
  String get allowParamsDesc => 'For tuning scripts. They can change how the device behaves.';

  @override
  String get pairing => 'Pairing…';

  @override
  String get pair => 'Pair';

  @override
  String get scriptHostIntro =>
      'A script host is a computer on the same network that runs scripts for this computer: a laptop, a Raspberry Pi, a Jetson… On it:';

  @override
  String get scriptHostIntroPhone =>
      'A script host is a computer on the same network that runs scripts for this phone or tablet: a laptop, a Raspberry Pi, a Jetson… On it:';

  @override
  String get onTheNetwork => 'On the network';

  @override
  String get lookingForHosts => 'Looking for script hosts';

  @override
  String get noHostsFound => 'None found. Type its address below (shown by `ipconfig getifaddr en0`, `hostname -I`…).';

  @override
  String get lookAgain => 'Look again';

  @override
  String get address => 'Address';

  @override
  String get pairingCode => 'Pairing code';

  @override
  String get pairingCodePlaceholder => 'ABC-123, printed by the host';

  @override
  String updatingPct(int pct) {
    return 'Updating $pct%';
  }

  @override
  String get installingState => 'Installing';

  @override
  String get appUpdating => 'koebelt dash is updating';

  @override
  String appAvailable(String version) {
    return 'koebelt dash $version is available';
  }

  @override
  String get appUpToDate => 'koebelt dash is up to date';

  @override
  String get skipVersion => 'Skip this version';

  @override
  String get later => 'Later';

  @override
  String downloadingPct(int pct) {
    return 'Downloading $pct%';
  }

  @override
  String get installAnyway => 'Install anyway';

  @override
  String get updateAnyway => 'Update anyway';

  @override
  String installVersion(String version) {
    return 'Install $version';
  }

  @override
  String get updateNow => 'Update now';

  @override
  String youHaveOlder(String version) {
    return 'You have $version; this is an older version. Settings and recordings made with a newer version may not all open in it, and it will not remind you about newer ones until the next release.';
  }

  @override
  String youHave(String version) {
    return 'You have $version.';
  }

  @override
  String get notFromApp => 'Not from the app';

  @override
  String get checkingCompat => 'Checking compatibility with your devices…';

  @override
  String get compatUnknown => 'Compatibility unknown';

  @override
  String get compatUnknownBody => 'Could not read which koebelt/link versions this release supports.';

  @override
  String notCompatibleWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Not compatible with $count of your devices',
      one: 'Not compatible with one of your devices',
    );
    return '$_temp0';
  }

  @override
  String notCompatibleBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Update the koebelt/link library on them first, or keep your version and choose another in Settings > Updates.',
      one: 'Update the koebelt/link library on it first, or keep your version and choose another in Settings > Updates.',
    );
    return '$_temp0';
  }

  @override
  String get disarmFirst => 'Disarm first';

  @override
  String get disarmFirstBody => 'A connected device is armed. Updating closes the app, which drops the link; disarm it, then update.';

  @override
  String get devicesWillDisconnect => 'Devices will disconnect';

  @override
  String devicesWillDisconnectBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Installing closes the app, so the $count connected devices lose the link and their failsafe takes over until you reconnect.',
      one: 'Installing closes the app, so the connected device loses the link and its failsafe takes over until you reconnect.',
    );
    return '$_temp0';
  }

  @override
  String get notInstalled => 'Not installed';

  @override
  String get inThisVersion => 'In this version';

  @override
  String get whatsNew => 'What’s new';

  @override
  String get fullNotes => 'Full release notes';

  @override
  String get chooseAnotherVersion => 'Choose another version';

  @override
  String get chooseVersion => 'Choose a version';

  @override
  String get close => 'Close';

  @override
  String get chooseVersionBody =>
      'Install any published version, newer or older. Each one says whether it works with the koebelt/link versions your devices reported when they last connected.';

  @override
  String get askingGithub => 'Asking GitHub…';

  @override
  String get noReleases => 'No releases found.';

  @override
  String get installed => 'Installed';

  @override
  String get latest => 'Latest';

  @override
  String get checkingShort => 'Checking…';

  @override
  String get worksWithDevices => 'Works with your devices';

  @override
  String get noDevicesToCheck => 'No devices to check yet';

  @override
  String notFor(String names) {
    return 'Not for $names';
  }

  @override
  String get details => 'Details';

  @override
  String get updateHowAndroid => 'The update downloads here and Android asks you to confirm the install.';

  @override
  String get updateHow => 'The update downloads, is checked against the release, and koebelt dash restarts on the new version.';

  @override
  String versionN(String version) {
    return 'Version $version';
  }

  @override
  String get noSelfUpdate =>
      'This build does not update itself: the App Store and TestFlight update theirs, and the downloads from GitHub check for new versions on their own.';

  @override
  String get releases => 'Releases';

  @override
  String get upToDate => 'Up to date.';

  @override
  String versionAvailable(String version) {
    return '$version is available.';
  }

  @override
  String downloadingWhat(String what, int pct) {
    return 'Downloading $what… $pct%';
  }

  @override
  String installingWhat(String what) {
    return 'Installing $what…';
  }

  @override
  String get somethingWrong => 'Something went wrong.';

  @override
  String get notChecked => 'Not checked yet.';

  @override
  String updateTo(String version) {
    return 'Update to $version';
  }

  @override
  String get checkNow => 'Check now';

  @override
  String get chooseVersionDesc => 'Install any published version, older ones too, with whether it works with your devices’ koebelt/link libraries.';

  @override
  String get versions => 'Versions';

  @override
  String get betas => 'Betas';

  @override
  String get betasDesc => 'Also offer beta versions and release candidates: the next features before they are released, with more chances of a bug.';

  @override
  String get autoCheck => 'Check for updates automatically';

  @override
  String get autoCheckDesc => 'At launch and once a day, koebelt dash asks GitHub for the latest release. Nothing else is sent.';

  @override
  String get padYawSteer => 'Yaw · steer';

  @override
  String get padRoll => 'Roll';

  @override
  String get padPitchDrive => 'Pitch · drive';

  @override
  String get padUnavailable => 'Controllers are not available on this platform.';

  @override
  String get padNone =>
      'No controller connected. Pair a Bluetooth controller in the system settings, or plug one in over USB. RC transmitters work in USB joystick mode.';

  @override
  String padConnected(String names) {
    return 'Connected: $names.';
  }

  @override
  String get padUse => 'Use a game controller';

  @override
  String get padUseDesc =>
      'Sticks drive drones and ground robots, and jog robot arms, once they are armed; buttons work on any device. On-screen controls keep working while the controller is idle.';

  @override
  String get padSticks => 'Sticks';

  @override
  String get padMoveNow => 'Move or press the control now';

  @override
  String get padButtons => 'Buttons';

  @override
  String get padDeadzone => 'Dead zone';

  @override
  String padDeadzoneDesc(int pct) {
    return 'Stick movement ignored around the centre: $pct %.';
  }

  @override
  String get padExpo => 'Expo';

  @override
  String padExpoDesc(int pct) {
    return 'Softer response near the centre for fine control: $pct %.';
  }

  @override
  String get padResetMapping => 'Reset mapping';

  @override
  String get padResetMappingDesc => 'Standard layout: left stick throttle and yaw, right stick pitch and roll, B / Circle for STOP.';

  @override
  String get waiting => 'Waiting…';

  @override
  String get invertDirection => 'Invert direction';

  @override
  String get inverted => 'Inverted';

  @override
  String get normal => 'Normal';

  @override
  String clearName(String name) {
    return 'Clear $name';
  }

  @override
  String padDrives(String pad, String device) {
    return '$pad drives $device';
  }

  @override
  String padArmToDrive(String pad) {
    return 'Arm to drive with $pad; its buttons already work';
  }

  @override
  String get padButtonsWork => 'Buttons work; sticks drive drones and ground robots';

  @override
  String get pad => 'Pad';

  @override
  String get copy => 'Copy';

  @override
  String get aiLet => 'Let assistants use koebelt dash';

  @override
  String get aiLetDesc =>
      'Claude, Codex, OpenCode, Cursor and other MCP clients can read the docs, write scripts, use the app and, with your approval, act on devices. dash itself sends nothing to any AI service; the assistant you connect talks to its own provider.';

  @override
  String get aiConnectClient => 'Connect a client';

  @override
  String get aiPaste => 'Paste this into the assistant’s setup.';

  @override
  String get aiRemotePhone => 'Assistants run on a computer: they reach this phone over the network, with its token.';

  @override
  String get aiRemoteTablet => 'Assistants run on a computer: they reach this tablet over the network, with its token.';

  @override
  String get other => 'Other';

  @override
  String get aiConnectedNow => 'Connected now';

  @override
  String get aiNone => 'No assistant in the last ten minutes.';

  @override
  String actions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count actions', one: '1 action');
    return '$_temp0';
  }

  @override
  String get activity => 'Activity';

  @override
  String get aiAllowed => 'Allowed without asking';

  @override
  String get aiAllowedNone =>
      'Simulated devices and replays never ask. On real hardware, every action asks unless you allow it for the session. Arming and take-off always ask.';

  @override
  String aiAllowedSome(String actions) {
    return 'For this session: $actions. Arming and take-off always ask.';
  }

  @override
  String get aiFromNetwork => 'From this network';

  @override
  String aiFromNetworkOn(String url, String token) {
    return 'Assistants on other computers: $url with the token $token… (copy it from the Other tab).';
  }

  @override
  String get aiFromNetworkOff => 'Let an assistant on another computer use this dash, with a token.';

  @override
  String get aiActivity => 'Assistant activity';

  @override
  String get nothingYet => 'Nothing yet.';

  @override
  String get aiShort => 'AI';

  @override
  String aiAsks(String client) {
    return '$client asks';
  }

  @override
  String aiRealHardware(String device) {
    return '$device is real hardware.';
  }

  @override
  String aiAllowSession(String device) {
    return 'Allow this kind of action on $device for this session';
  }

  @override
  String get refuse => 'Refuse';

  @override
  String get approve => 'Approve';

  @override
  String get recordingsAndLogs => 'Recordings and flight logs';

  @override
  String fileUnreadable(String error) {
    return 'The file could not be read: $error';
  }

  @override
  String get fromFile => 'From a file';

  @override
  String get fromFileDesc => 'Opens as a session: replay, the map, the charts and export all work on it.';

  @override
  String get fmtJson => 'A recording exported from koebelt/dash';

  @override
  String get fmtBin => 'ArduPilot log, from the SD card or Mission Planner';

  @override
  String get fmtTlog => 'Ground station log: Mission Planner, QGroundControl, MAVProxy';

  @override
  String get fmtUlg => 'PX4 log, from the SD card or QGroundControl';

  @override
  String reading(String file) {
    return 'Reading $file…';
  }

  @override
  String get stopRecordingFirst => 'Stop the recording first';

  @override
  String get notImported => 'Not imported';

  @override
  String get sampleRecordings => 'Sample recordings';

  @override
  String get samplesIn => 'The three demo sessions are in your list, marked Demo.';

  @override
  String get samplesDesc => 'Three demo sessions recorded with the simulated devices: a survey flight, a pick and place, a rocket launch.';

  @override
  String get removeSamples => 'Remove samples';

  @override
  String get loadSamples => 'Load samples';

  @override
  String get exporting => 'Exporting…';

  @override
  String exportFormat(String format) {
    return 'Export $format';
  }

  @override
  String frames(int count) {
    return '$count frames';
  }

  @override
  String csvColumns(int count) {
    return '$count columns · only channels this device sent';
  }

  @override
  String get noGpx => 'No GPS in this recording, so no GPX track';

  @override
  String encoding(String format, int pct) {
    return 'Encoding $format · $pct%';
  }

  @override
  String get exported => 'Exported';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String was(String value) {
    return 'was $value';
  }

  @override
  String firmware(String version) {
    return 'firmware $version';
  }

  @override
  String parametersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count parameters', one: '1 parameter');
    return '$_temp0';
  }

  @override
  String get parameters => 'Parameters';

  @override
  String unsaved(int count) {
    return '$count unsaved';
  }

  @override
  String written(String when) {
    return 'Written $when';
  }

  @override
  String get inSync => 'In sync';

  @override
  String get revert => 'Revert';

  @override
  String get writing => 'Writing…';

  @override
  String get writeToDevice => 'Write to device';

  @override
  String get searchParameters => 'Search parameters';

  @override
  String get waitingParams => 'Waiting for the parameter table…';

  @override
  String noParamsMatch(String query) {
    return 'No parameters match “$query”';
  }

  @override
  String revertName(String name) {
    return 'Revert $name';
  }

  @override
  String get liveResponse => 'Live response';

  @override
  String get copied => 'Copied';

  @override
  String get yourPairingCode => 'Your pairing code · valid 10 min';

  @override
  String namePaired(String name) {
    return '$name paired';
  }

  @override
  String get startListening => 'Start listening';

  @override
  String get listeningWifiBle => 'Listening on Wi-Fi and BLE · power on your device';

  @override
  String nameFound(String name) {
    return '$name found';
  }

  @override
  String sensorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sensors', one: '1 sensor');
    return '$_temp0';
  }

  @override
  String get addToDevices => 'Add to devices';

  @override
  String get connectNow => 'Connect now';

  @override
  String get inTheApp => 'In the app';

  @override
  String get completeProgram => 'Complete program';

  @override
  String get apiReference => 'API reference';

  @override
  String get exampleProjects => 'Example projects';

  @override
  String get allGuides => 'All guides';

  @override
  String stepOfUpper(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get flowDevice => 'Your device';

  @override
  String get flowDeviceDesc => 'Sensors, motors and koebelt/link on the board or companion computer.';

  @override
  String get flowLinkDesc => 'Wi-Fi, BLE, USB serial or a radio, with a fallback link if one drops.';

  @override
  String get flowDashDesc => 'Dashboards, control, tuning and recording, on phone, tablet or desktop.';

  @override
  String get library => 'library';

  @override
  String get connectHardware => 'Connect your hardware';

  @override
  String get connectHardwareDesc =>
      'Your device runs a small library that streams sensors to this app and receives control input. Pick your platform to start.';

  @override
  String get guidesConnections => 'Connections';

  @override
  String get guidesConnectionsDesc => 'How each link works, and what to do when a device does not show up.';

  @override
  String get guidesDevices => 'Device examples';

  @override
  String get guidesDevicesDesc => 'A complete, commented program for each kind of device.';

  @override
  String get guidesFeatures => 'Video, map and controllers';

  @override
  String get guidesFeaturesDesc => 'Show a camera, put the device on a map, drive with a gamepad.';

  @override
  String get guidesMore => 'Going further';

  @override
  String get guidesMoreDesc => 'Custom data, tuning, sequences and safety.';

  @override
  String get viewChase => 'CHASE';

  @override
  String get viewOrbit => 'ORBIT';

  @override
  String get viewTop => 'TOP';

  @override
  String get viewMap => 'MAP';

  @override
  String get viewCam => 'CAM';

  @override
  String get noMapboxToken => 'This build has no Mapbox token: enter your own below, or choose another source.';

  @override
  String get waitingGps => 'Waiting for a GPS fix';

  @override
  String get grid => 'Grid';

  @override
  String get waitingScript => 'Waiting for the script';

  @override
  String get scriptEnded => 'Script ended';

  @override
  String get noVideo => 'This recording has no video.';

  @override
  String get noCamera => 'No camera. Devices declare cameras with video() in the library.';

  @override
  String cameraByIp(String name) {
    return 'This camera is reached by IP address. Connect to $name over Wi-Fi to see it.';
  }

  @override
  String get warning => 'Warning';

  @override
  String get alBattery => 'Battery low';

  @override
  String get alBatteryDesc => 'Charge left, as the device reports it.';

  @override
  String get alBatteryAct => 'Time to bring it back.';

  @override
  String get alBatteryCritical => 'Battery critical';

  @override
  String get alBatteryCriticalDesc => 'A second, louder limit: repeats until acknowledged.';

  @override
  String get alBatteryCriticalAct => 'Land or stop now.';

  @override
  String get alVoltage => 'Battery voltage';

  @override
  String get alVoltageDesc => 'For packs that do not report a percentage. Set the limit for your pack, for example 3.5 V per cell.';

  @override
  String get alVoltageAct => 'Time to bring it back.';

  @override
  String get alObstacle => 'Obstacle close';

  @override
  String get alObstacleDesc => 'The nearest thing a proximity sensor sees, while armed (sensors looking down do not count).';

  @override
  String get alObstacleAct => 'Steer away, or stop.';

  @override
  String get alRssi => 'Weak signal';

  @override
  String get alRssiDesc => 'Received signal strength, when the link reports it.';

  @override
  String get alRssiAct => 'Move closer or turn back.';

  @override
  String get alLatency => 'High latency';

  @override
  String get alLatencyDesc => 'Round trip of the link. Control feels late above a few hundred milliseconds.';

  @override
  String get alLatencyAct => 'Control will feel late.';

  @override
  String get alAltitude => 'Altitude ceiling';

  @override
  String get alAltitudeDesc => 'Height above home. 120 m is the usual limit for drones in Europe and the US.';

  @override
  String get alAltitudeAct => 'Descend.';

  @override
  String get alDistance => 'Distance from home';

  @override
  String get alDistanceDesc => 'A simple geofence: horizontal distance from where it started.';

  @override
  String get alDistanceAct => 'Bring it closer.';

  @override
  String get alTemp => 'Temperature';

  @override
  String get alTempDesc => 'Motor, ESC or board temperature, when the device reports one.';

  @override
  String get alTempAct => 'Let it cool down.';

  @override
  String get kindDrone => 'Drone';

  @override
  String get kindRover => 'Ground robot';

  @override
  String get kindArm => 'Robot arm';

  @override
  String get kindRocket => 'Rocket';

  @override
  String get kindBench => 'Test bench';

  @override
  String get kindGeneric => 'Device';

  @override
  String get stTakeoff => 'Take off';

  @override
  String get stFlyTo => 'Fly to';

  @override
  String get stLand => 'Land';

  @override
  String get stRth => 'Return home';

  @override
  String get stDriveTo => 'Drive to';

  @override
  String get stPose => 'Move to pose';

  @override
  String get stRamp => 'Ramp';

  @override
  String get stWait => 'Wait';

  @override
  String get stMode => 'Set mode';

  @override
  String get stArm => 'Arm / disarm';

  @override
  String get stCmd => 'Custom command';

  @override
  String get fEast => 'East';

  @override
  String get fNorth => 'North';

  @override
  String get fHold => 'Hold';

  @override
  String get fFrom => 'From';

  @override
  String get fTo => 'To';

  @override
  String get fOver => 'Over';

  @override
  String get fDuration => 'Duration';

  @override
  String get fMode => 'Mode';

  @override
  String get fState => 'State';

  @override
  String get fLimit => 'Limit';

  @override
  String get fCommand => 'Command';

  @override
  String get fValue => 'Value';

  @override
  String sumTakeoff(String alt) {
    return 'Take off to $alt m';
  }

  @override
  String sumFlyTo(String x, String y, String z) {
    return 'Fly to $x, $y m at $z m';
  }

  @override
  String sumDriveTo(String x, String y) {
    return 'Drive to $x, $y m';
  }

  @override
  String get sumRth => 'Return home and land';

  @override
  String sumPose(String joints) {
    return 'Move to pose $joints°';
  }

  @override
  String sumGripper(String pct) {
    return 'Gripper $pct% open';
  }

  @override
  String sumThrottle(String pct, String s) {
    return 'Throttle $pct% for $s s';
  }

  @override
  String sumRamp(String from, String to, String s) {
    return 'Ramp $from to $to% over $s s';
  }

  @override
  String sumWait(String s) {
    return 'Wait $s s';
  }

  @override
  String sumMode(String mode) {
    return 'Mode $mode';
  }

  @override
  String get sumArm => 'Arm';

  @override
  String get sumDisarm => 'Disarm';

  @override
  String sumSpeed(String pct) {
    return 'Speed limit $pct%';
  }

  @override
  String sumCmd(String name, String value) {
    return 'Command $name = $value';
  }

  @override
  String get stoppedEstop => 'Stopped: emergency stop';

  @override
  String completedIn(String seconds) {
    return 'Completed in $seconds s';
  }

  @override
  String stepTimedOut(int n, String step) {
    return 'Step $n timed out: $step';
  }

  @override
  String metresToGo(String metres) {
    return '$metres m to go';
  }

  @override
  String get uploadingToDevice => 'Uploading to the device';

  @override
  String get starting => 'Starting';

  @override
  String get completedOnDevice => 'Completed on the device';

  @override
  String get deviceRejected => 'The device did not accept the sequence';

  @override
  String get linkLostCarriesOn => 'Link lost · the device carries on';

  @override
  String get stoppedDisconnected => 'Stopped: disconnected';

  @override
  String get stoppedTookControl => 'Stopped: you took control';

  @override
  String get stoppedManual => 'Stopped: manual control';

  @override
  String get stoppedByScript => 'Stopped by the script';

  @override
  String get reqAnyDevice => 'a device';

  @override
  String reqKinds(String kinds) {
    return 'a $kinds';
  }

  @override
  String reqWith(String kinds, String needs) {
    return '$kinds with $needs';
  }

  @override
  String reqWrongKind(String name, String kind, String needs) {
    return '$name is a $kind; this script needs $needs.';
  }

  @override
  String reqLacks(String name, String lacks, String needs) {
    return '$name has no $lacks; this script needs $needs.';
  }

  @override
  String get trgButton => 'Button';

  @override
  String get trgSwitch => 'Switch';

  @override
  String get trgSlider => 'Slider';

  @override
  String get trgController => 'Controller';

  @override
  String get trgCondition => 'Condition';

  @override
  String get trgEvent => 'Device event';

  @override
  String get trgTimer => 'Timer';

  @override
  String get evMode => 'Mode changes';

  @override
  String get evFailsafe => 'Failsafe';

  @override
  String get evSeqDone => 'Sequence finished';

  @override
  String get evLog => 'Device message';

  @override
  String get onControl => 'on Control';

  @override
  String everyN(String seconds) {
    return 'Every $seconds s';
  }

  @override
  String onceAfterN(String seconds) {
    return 'Once after $seconds s';
  }

  @override
  String get paArm => 'Arm / disarm';

  @override
  String get paManual => 'Manual';

  @override
  String get paHold => 'Hold';

  @override
  String get paAuto => 'Back to the script';

  @override
  String get paSlower => 'Speed down';

  @override
  String get paFaster => 'Speed up';

  @override
  String get paFrame => 'Joint / Cartesian';

  @override
  String get paWrist => 'Wrist';

  @override
  String get paNext => 'Next device';

  @override
  String get paStopHint => 'Emergency stop, immediately';

  @override
  String get paHoldHint => 'Hold for one second';

  @override
  String paSwitchTo(String mode) {
    return 'Switch to $mode';
  }

  @override
  String get paAutoHint => 'After taking over, give the sticks back to the script (AUTO)';

  @override
  String paSwitchToDrones(String mode) {
    return 'Switch to $mode (drones)';
  }

  @override
  String get paHoldDronesHint => 'Hold for one second (drones)';

  @override
  String get paRecordHint => 'Start or stop a recording';

  @override
  String get paSlowerHint => 'Lower the speed limit 10 %';

  @override
  String get paFasterHint => 'Raise the speed limit 10 %';

  @override
  String get paFrameHint => 'Arms: what the sticks move';

  @override
  String get paWristHint => 'Arms: right stick moves J5 and J6 instead of J3 and J4';

  @override
  String get paGripperHint => 'Arms: open or close';

  @override
  String get paNextHint => 'Several connected: show and drive the next one';

  @override
  String get notSet => 'Not set';

  @override
  String get padLeftStickX => 'Left stick X';

  @override
  String get padLeftStickY => 'Left stick Y';

  @override
  String get padRightStickX => 'Right stick X';

  @override
  String get padRightStickY => 'Right stick Y';

  @override
  String get padLeftTrigger => 'Left trigger';

  @override
  String get padRightTrigger => 'Right trigger';

  @override
  String get padACross => 'A / Cross';

  @override
  String get padBCircle => 'B / Circle';

  @override
  String get padXSquare => 'X / Square';

  @override
  String get padYTriangle => 'Y / Triangle';

  @override
  String get padLeftBumper => 'Left bumper';

  @override
  String get padRightBumper => 'Right bumper';

  @override
  String get padBackShare => 'Back / Share';

  @override
  String get padStartOptions => 'Start / Options';

  @override
  String get padHome => 'Home';

  @override
  String get padLeftStickPress => 'Left stick press';

  @override
  String get padRightStickPress => 'Right stick press';

  @override
  String get padDPadUp => 'D-pad up';

  @override
  String get padDPadDown => 'D-pad down';

  @override
  String get padDPadLeft => 'D-pad left';

  @override
  String get padDPadRight => 'D-pad right';

  @override
  String get radioSik => 'SiK telemetry radio';

  @override
  String get radioLoraName => 'LoRa ground station';

  @override
  String get radioOther => 'Other serial radio';

  @override
  String get radioSikDesc => '433 / 868 / 915 MHz pairs: 3DR, Holybro, RFD900. Transparent serial up to about 1 km, 40 km for RFD900.';

  @override
  String get radioLoraDesc => 'A board with a LoRa radio on USB, flashed with the ground-station sketch. 2 to 10 km, telemetry only.';

  @override
  String get radioHc12Desc => 'Cheap transparent serial module on a USB adapter. About 1 km at 9600 baud.';

  @override
  String get radioXbeeDesc => 'Digi XBee in transparent mode on a USB explorer board. 2.4 GHz or 900 MHz.';

  @override
  String get radioOtherDesc => 'Any transparent serial radio. Set its baud rate; the app uses conservative rates.';

  @override
  String get tplLoop => 'A control loop';

  @override
  String get tplButton => 'A button action';

  @override
  String get fldBattery => 'Battery';

  @override
  String get fldBatteryVoltage => 'Battery voltage';

  @override
  String get fldDistanceFromHome => 'Distance from home';

  @override
  String get fldHeightAboveHome => 'Height above home';

  @override
  String get fldSpeed => 'Speed';

  @override
  String get fldHeading => 'Heading';

  @override
  String get fldRoll => 'Roll';

  @override
  String get fldPitch => 'Pitch';

  @override
  String get fldGripper => 'Gripper';

  @override
  String get fldThrust => 'Thrust';

  @override
  String get fldRpm => 'RPM';

  @override
  String get fldTemperature => 'Temperature';

  @override
  String get fldNearestObstacle => 'Nearest obstacle';

  @override
  String get fldSignal => 'Signal';

  @override
  String get fldLatency => 'Latency';

  @override
  String get fldGpsSatellites => 'GPS satellites';

  @override
  String get ready => 'Ready.';

  @override
  String get pythonManaged => 'This Python is managed by the system and refuses packages: use a scripts environment instead.';

  @override
  String failedWhy(String why) {
    return 'Failed: $why';
  }

  @override
  String get pipNoPackage => 'pip finished, but koebelt-dash-scripts is still not in this Python.';

  @override
  String packageUpToDate(String version) {
    return 'koebelt-dash-scripts $version is up to date in this Python.';
  }

  @override
  String packageInstalled(String version) {
    return 'koebelt-dash-scripts $version is installed in this Python.';
  }

  @override
  String packagesInstalled(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$names are installed in this Python.', one: '$names is installed in this Python.');
    return '$_temp0';
  }

  @override
  String envReady(String version) {
    return 'The scripts environment is ready, with koebelt-dash-scripts $version.';
  }

  @override
  String atMostDevices(int count) {
    return 'At most $count devices at once. Disconnect one first.';
  }

  @override
  String noAnswerFrom(String name) {
    return 'No answer from $name';
  }

  @override
  String noHostAt(String address) {
    return 'No script host at $address. Is `koebelt-dash-scripts host` running there?';
  }

  @override
  String get hostRefused => 'The host refused.';

  @override
  String get logUnknown => 'This file is not a log the app can read. It opens koebelt/dash JSON exports, ArduPilot .bin and .tlog logs, and PX4 .ulg logs.';

  @override
  String logEmpty(String format) {
    return 'The $format file has no telemetry the app can show (attitude, position, battery).';
  }

  @override
  String get logJsonUnreadable => 'This JSON file could not be read.';

  @override
  String get logJsonNotExport => 'This JSON file is not a koebelt/dash recording export.';

  @override
  String get logNoHeartbeat => 'This .tlog has no vehicle heartbeat, so its messages cannot be attributed to a vehicle.';

  @override
  String get viewDevices => 'View devices';

  @override
  String get simulatedTip => 'Simulated in the app, not real hardware';

  @override
  String get newShort => 'New';
}
