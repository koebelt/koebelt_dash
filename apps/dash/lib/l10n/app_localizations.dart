import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de'), Locale('en'), Locale('es'), Locale('fr'), Locale('pt')];

  /// No description provided for @navLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get navLive;

  /// No description provided for @navControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get navControl;

  /// No description provided for @navAutomate.
  ///
  /// In en, this message translates to:
  /// **'Automate'**
  String get navAutomate;

  /// No description provided for @navTune.
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get navTune;

  /// No description provided for @navReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get navReplay;

  /// No description provided for @navDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get navDevices;

  /// No description provided for @navGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get navGuides;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navSequences.
  ///
  /// In en, this message translates to:
  /// **'Sequences'**
  String get navSequences;

  /// No description provided for @navScripts.
  ///
  /// In en, this message translates to:
  /// **'Scripts'**
  String get navScripts;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'The app\'s language. Guides not yet translated stay in English.'**
  String get settingsLanguageDesc;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as the system ({name})'**
  String settingsLanguageSystem(String name);

  /// No description provided for @toastSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String toastSaved(String name);

  /// No description provided for @stopEngagedBar.
  ///
  /// In en, this message translates to:
  /// **'Stop engaged · tap to reset'**
  String get stopEngagedBar;

  /// No description provided for @stopEngagedTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency stop engaged'**
  String get stopEngagedTitle;

  /// No description provided for @stopKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep stopped'**
  String get stopKeep;

  /// No description provided for @stopResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get stopResetAll;

  /// No description provided for @stopReset.
  ///
  /// In en, this message translates to:
  /// **'Reset stop'**
  String get stopReset;

  /// No description provided for @stopBody.
  ///
  /// In en, this message translates to:
  /// **'Motors are stopped and all motion commands are blocked on {names}.'**
  String stopBody(String names);

  /// No description provided for @theDevice.
  ///
  /// In en, this message translates to:
  /// **'the device'**
  String get theDevice;

  /// No description provided for @stopCheck.
  ///
  /// In en, this message translates to:
  /// **'Check the device before you reset. After reset it stays disarmed until you arm it again.'**
  String get stopCheck;

  /// No description provided for @fleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get fleet;

  /// No description provided for @tagSim.
  ///
  /// In en, this message translates to:
  /// **'Sim'**
  String get tagSim;

  /// No description provided for @fleetActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get fleetActive;

  /// No description provided for @fleetLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get fleetLost;

  /// No description provided for @fleetLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get fleetLinked;

  /// No description provided for @fleetOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get fleetOff;

  /// No description provided for @fleetOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get fleetOn;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @noLink.
  ///
  /// In en, this message translates to:
  /// **'No link'**
  String get noLink;

  /// No description provided for @simulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated'**
  String get simulated;

  /// No description provided for @statLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get statLink;

  /// No description provided for @statLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get statLost;

  /// No description provided for @statLatency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get statLatency;

  /// No description provided for @statBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get statBattery;

  /// No description provided for @statRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get statRecording;

  /// No description provided for @armed.
  ///
  /// In en, this message translates to:
  /// **'Armed'**
  String get armed;

  /// No description provided for @disarmed.
  ///
  /// In en, this message translates to:
  /// **'Disarmed'**
  String get disarmed;

  /// No description provided for @stopLabelAll.
  ///
  /// In en, this message translates to:
  /// **'Emergency stop, all {count} devices'**
  String stopLabelAll(int count);

  /// No description provided for @stopLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency stop'**
  String get stopLabel;

  /// No description provided for @stopTipAll.
  ///
  /// In en, this message translates to:
  /// **'Stops all {count} connected devices'**
  String stopTipAll(int count);

  /// No description provided for @stopTipSlowRadio.
  ///
  /// In en, this message translates to:
  /// **'STOP is still sent over this telemetry-only radio, but it is slow: up to a second'**
  String get stopTipSlowRadio;

  /// No description provided for @stopAll.
  ///
  /// In en, this message translates to:
  /// **'Stop all'**
  String get stopAll;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @failsafeHold.
  ///
  /// In en, this message translates to:
  /// **'holding position'**
  String get failsafeHold;

  /// No description provided for @failsafeRth.
  ///
  /// In en, this message translates to:
  /// **'returning home'**
  String get failsafeRth;

  /// No description provided for @failsafeLand.
  ///
  /// In en, this message translates to:
  /// **'landing in place'**
  String get failsafeLand;

  /// No description provided for @linkLostFor.
  ///
  /// In en, this message translates to:
  /// **'Link lost · {seconds} s'**
  String linkLostFor(String seconds);

  /// No description provided for @failsafeActive.
  ///
  /// In en, this message translates to:
  /// **'Failsafe active: {action}.'**
  String failsafeActive(String action);

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting. Failsafe starts at 1.8 s.'**
  String get reconnecting;

  /// No description provided for @controlsLocked.
  ///
  /// In en, this message translates to:
  /// **'Controls are locked until the link is back.'**
  String get controlsLocked;

  /// No description provided for @linkRestored.
  ///
  /// In en, this message translates to:
  /// **'Link restored'**
  String get linkRestored;

  /// No description provided for @linkRestoredBody.
  ///
  /// In en, this message translates to:
  /// **'Manual control is available again.'**
  String get linkRestoredBody;

  /// No description provided for @alertBelow.
  ///
  /// In en, this message translates to:
  /// **'Below {limit}.'**
  String alertBelow(String limit);

  /// No description provided for @alertAbove.
  ///
  /// In en, this message translates to:
  /// **'Above {limit}.'**
  String alertAbove(String limit);

  /// No description provided for @linkLostOther.
  ///
  /// In en, this message translates to:
  /// **'Its failsafe takes over after 1.8 s.'**
  String get linkLostOther;

  /// No description provided for @compatNewerApp.
  ///
  /// In en, this message translates to:
  /// **'Needs a newer app'**
  String get compatNewerApp;

  /// No description provided for @compatOldLib.
  ///
  /// In en, this message translates to:
  /// **'Library too old'**
  String get compatOldLib;

  /// No description provided for @compatSome.
  ///
  /// In en, this message translates to:
  /// **'Some features may not work: {why}.'**
  String compatSome(String why);

  /// No description provided for @compatUpdateApp.
  ///
  /// In en, this message translates to:
  /// **'Update koebelt dash.'**
  String get compatUpdateApp;

  /// No description provided for @compatUpdateLib.
  ///
  /// In en, this message translates to:
  /// **'Update the koebelt/link library on the device, or install an older koebelt dash in Settings > Updates.'**
  String get compatUpdateLib;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 alert} other{{count} alerts}}'**
  String alerts(int count);

  /// No description provided for @linkLost.
  ///
  /// In en, this message translates to:
  /// **'Link lost'**
  String get linkLost;

  /// No description provided for @replayOffControl.
  ///
  /// In en, this message translates to:
  /// **'Controls are off during a replay'**
  String get replayOffControl;

  /// No description provided for @replayOffControlWhy.
  ///
  /// In en, this message translates to:
  /// **'Controls act on a connected device, not on a recording.'**
  String get replayOffControlWhy;

  /// No description provided for @replayOffSequences.
  ///
  /// In en, this message translates to:
  /// **'Sequences are off during a replay'**
  String get replayOffSequences;

  /// No description provided for @replayOffSequencesWhy.
  ///
  /// In en, this message translates to:
  /// **'Sequences run on a connected device, not on a recording.'**
  String get replayOffSequencesWhy;

  /// No description provided for @replayOffTune.
  ///
  /// In en, this message translates to:
  /// **'Tuning is off during a replay'**
  String get replayOffTune;

  /// No description provided for @replayOffTuneWhy.
  ///
  /// In en, this message translates to:
  /// **'Parameters are read and written on a connected device, not on a recording.'**
  String get replayOffTuneWhy;

  /// No description provided for @replayExitTo.
  ///
  /// In en, this message translates to:
  /// **'Exit the replay to get back to {name}.'**
  String replayExitTo(String name);

  /// No description provided for @replayExitConnect.
  ///
  /// In en, this message translates to:
  /// **'Exit the replay, then connect a device.'**
  String get replayExitConnect;

  /// No description provided for @replayBack.
  ///
  /// In en, this message translates to:
  /// **'Back to the replay'**
  String get replayBack;

  /// No description provided for @replayExitBackTo.
  ///
  /// In en, this message translates to:
  /// **'Exit replay, back to {name}'**
  String replayExitBackTo(String name);

  /// No description provided for @replayExit.
  ///
  /// In en, this message translates to:
  /// **'Exit replay'**
  String get replayExit;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @noDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'No device connected'**
  String get noDeviceTitle;

  /// No description provided for @noDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a paired device or pair a new one. Telemetry and controls appear once the link is up.'**
  String get noDeviceBody;

  /// No description provided for @connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect'**
  String get connectFailed;

  /// No description provided for @noPairedDevices.
  ///
  /// In en, this message translates to:
  /// **'No paired devices yet.'**
  String get noPairedDevices;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @batteryPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% battery'**
  String batteryPct(int pct);

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @pairNewDevice.
  ///
  /// In en, this message translates to:
  /// **'Pair new device'**
  String get pairNewDevice;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @addSimulated.
  ///
  /// In en, this message translates to:
  /// **'Add a simulated device'**
  String get addSimulated;

  /// No description provided for @addSimulatedDesc.
  ///
  /// In en, this message translates to:
  /// **'A virtual drone, rover, arm, rocket or test bench, to try the app without hardware.'**
  String get addSimulatedDesc;

  /// No description provided for @openRecording.
  ///
  /// In en, this message translates to:
  /// **'Open a recording'**
  String get openRecording;

  /// No description provided for @openRecordingDesc.
  ///
  /// In en, this message translates to:
  /// **'Replay a session, a flight log or the sample recordings.'**
  String get openRecordingDesc;

  /// No description provided for @setUpLibrary.
  ///
  /// In en, this message translates to:
  /// **'Set up the library'**
  String get setUpLibrary;

  /// No description provided for @setUpLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Add koebelt/link to your Arduino, Python, ROS 2 or Rust project.'**
  String get setUpLibraryDesc;

  /// No description provided for @noDevice.
  ///
  /// In en, this message translates to:
  /// **'No device'**
  String get noDevice;

  /// No description provided for @tagDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get tagDemo;

  /// No description provided for @moreConnected.
  ///
  /// In en, this message translates to:
  /// **'+{count} connected'**
  String moreConnected(int count);

  /// No description provided for @alsoConnected.
  ///
  /// In en, this message translates to:
  /// **'Also connected'**
  String get alsoConnected;

  /// No description provided for @disconnectAll.
  ///
  /// In en, this message translates to:
  /// **'Disconnect all'**
  String get disconnectAll;

  /// No description provided for @connectAnother.
  ///
  /// In en, this message translates to:
  /// **'Connect another'**
  String get connectAnother;

  /// No description provided for @pairedDevices.
  ///
  /// In en, this message translates to:
  /// **'Paired devices'**
  String get pairedDevices;

  /// No description provided for @noPairedDevicesShort.
  ///
  /// In en, this message translates to:
  /// **'No paired devices'**
  String get noPairedDevicesShort;

  /// No description provided for @noPairedDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Pair one, add a simulated device, or follow the quickstart.'**
  String get noPairedDevicesHint;

  /// No description provided for @pairDevice.
  ///
  /// In en, this message translates to:
  /// **'Pair device'**
  String get pairDevice;

  /// No description provided for @quickstart.
  ///
  /// In en, this message translates to:
  /// **'Quickstart'**
  String get quickstart;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @replaying.
  ///
  /// In en, this message translates to:
  /// **'Replaying'**
  String get replaying;

  /// No description provided for @closeReplay.
  ///
  /// In en, this message translates to:
  /// **'Close replay'**
  String get closeReplay;

  /// No description provided for @simulator.
  ///
  /// In en, this message translates to:
  /// **'Simulator'**
  String get simulator;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @sequenceRunning.
  ///
  /// In en, this message translates to:
  /// **'sequence running'**
  String get sequenceRunning;

  /// No description provided for @disconnectName.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {name}'**
  String disconnectName(String name);

  /// No description provided for @automateSeqBlurb.
  ///
  /// In en, this message translates to:
  /// **'Steps in order, no code: take off, fly to, wait, land; drive to; move to a pose.'**
  String get automateSeqBlurb;

  /// No description provided for @automateSeqPoint1.
  ///
  /// In en, this message translates to:
  /// **'No code: build it in the app'**
  String get automateSeqPoint1;

  /// No description provided for @automateSeqPoint2.
  ///
  /// In en, this message translates to:
  /// **'Runs on the device when it can store it'**
  String get automateSeqPoint2;

  /// No description provided for @automateSeqPoint3.
  ///
  /// In en, this message translates to:
  /// **'Keeps going if the link drops'**
  String get automateSeqPoint3;

  /// No description provided for @automateSeqConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect a device to build its sequences'**
  String get automateSeqConnect;

  /// No description provided for @automateSeqCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sequence} =1{1 sequence} other{{count} sequences}} for {name}'**
  String automateSeqCount(int count, String name);

  /// No description provided for @automateScriptBlurb.
  ///
  /// In en, this message translates to:
  /// **'Python that reads the telemetry and the camera, decides, and drives the device.'**
  String get automateScriptBlurb;

  /// No description provided for @automateScriptPoint1.
  ///
  /// In en, this message translates to:
  /// **'Logic, sensors, the camera'**
  String get automateScriptPoint1;

  /// No description provided for @automateScriptPoint2.
  ///
  /// In en, this message translates to:
  /// **'Any package: OpenCV, PyTorch, YOLO'**
  String get automateScriptPoint2;

  /// No description provided for @automateScriptPoint3.
  ///
  /// In en, this message translates to:
  /// **'Triggers: buttons, keys, conditions, timers'**
  String get automateScriptPoint3;

  /// No description provided for @automateScriptPoint3Host.
  ///
  /// In en, this message translates to:
  /// **'Runs on a script host: a computer on your network'**
  String get automateScriptPoint3Host;

  /// No description provided for @scriptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No script} =1{1 script} other{{count} scripts}}'**
  String scriptsCount(int count);

  /// No description provided for @automateEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Two ways to automate'**
  String get automateEyebrow;

  /// No description provided for @runningOn.
  ///
  /// In en, this message translates to:
  /// **'{what} on {device}'**
  String runningOn(String what, String device);

  /// No description provided for @automateTogether1.
  ///
  /// In en, this message translates to:
  /// **'Together: a script can start a sequence, '**
  String get automateTogether1;

  /// No description provided for @automateTogether2.
  ///
  /// In en, this message translates to:
  /// **', and decide when.'**
  String get automateTogether2;

  /// No description provided for @sequenceOrScript.
  ///
  /// In en, this message translates to:
  /// **'Sequence or script?'**
  String get sequenceOrScript;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @layoutHud.
  ///
  /// In en, this message translates to:
  /// **'HUD'**
  String get layoutHud;

  /// No description provided for @layoutWall.
  ///
  /// In en, this message translates to:
  /// **'WALL'**
  String get layoutWall;

  /// No description provided for @editLayout.
  ///
  /// In en, this message translates to:
  /// **'Edit layout'**
  String get editLayout;

  /// No description provided for @sceneLayers3d.
  ///
  /// In en, this message translates to:
  /// **'3D scene layers'**
  String get sceneLayers3d;

  /// No description provided for @layerCloud.
  ///
  /// In en, this message translates to:
  /// **'Point cloud'**
  String get layerCloud;

  /// No description provided for @layerTrail.
  ///
  /// In en, this message translates to:
  /// **'Trajectory'**
  String get layerTrail;

  /// No description provided for @layerRadar.
  ///
  /// In en, this message translates to:
  /// **'Radar tracks'**
  String get layerRadar;

  /// No description provided for @layerGrid.
  ///
  /// In en, this message translates to:
  /// **'Ground grid'**
  String get layerGrid;

  /// No description provided for @sceneLayers.
  ///
  /// In en, this message translates to:
  /// **'Scene layers'**
  String get sceneLayers;

  /// No description provided for @addWidget.
  ///
  /// In en, this message translates to:
  /// **'Add widget'**
  String get addWidget;

  /// No description provided for @widgetsSavedFor.
  ///
  /// In en, this message translates to:
  /// **'Widgets are saved for {device} on {screens} screens.'**
  String widgetsSavedFor(String device, String screens);

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'this device'**
  String get thisDevice;

  /// No description provided for @screenPhone.
  ///
  /// In en, this message translates to:
  /// **'phone'**
  String get screenPhone;

  /// No description provided for @screenShort.
  ///
  /// In en, this message translates to:
  /// **'sideways phone'**
  String get screenShort;

  /// No description provided for @screenPortrait.
  ///
  /// In en, this message translates to:
  /// **'upright tablet'**
  String get screenPortrait;

  /// No description provided for @screenTablet.
  ///
  /// In en, this message translates to:
  /// **'tablet'**
  String get screenTablet;

  /// No description provided for @screenDesktop.
  ///
  /// In en, this message translates to:
  /// **'desktop'**
  String get screenDesktop;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saveLayout.
  ///
  /// In en, this message translates to:
  /// **'Save layout'**
  String get saveLayout;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @stale.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get stale;

  /// No description provided for @hzLive.
  ///
  /// In en, this message translates to:
  /// **'{hz} Hz live'**
  String hzLive(int hz);

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @statMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get statMin;

  /// No description provided for @statMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get statMax;

  /// No description provided for @statMean.
  ///
  /// In en, this message translates to:
  /// **'Mean'**
  String get statMean;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @window.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get window;

  /// No description provided for @windowValue.
  ///
  /// In en, this message translates to:
  /// **'10 s · 300 samples'**
  String get windowValue;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @tapChannelToHide.
  ///
  /// In en, this message translates to:
  /// **'Tap a channel to hide it'**
  String get tapChannelToHide;

  /// No description provided for @rec.
  ///
  /// In en, this message translates to:
  /// **'Rec'**
  String get rec;

  /// No description provided for @speedLimit.
  ///
  /// In en, this message translates to:
  /// **'Speed limit'**
  String get speedLimit;

  /// No description provided for @setHomePose.
  ///
  /// In en, this message translates to:
  /// **'Set home pose'**
  String get setHomePose;

  /// No description provided for @setHomeHere.
  ///
  /// In en, this message translates to:
  /// **'Set home here'**
  String get setHomeHere;

  /// No description provided for @useThisPose.
  ///
  /// In en, this message translates to:
  /// **'Use this pose'**
  String get useThisPose;

  /// No description provided for @setHome.
  ///
  /// In en, this message translates to:
  /// **'Set home'**
  String get setHome;

  /// No description provided for @setHomePoseBody.
  ///
  /// In en, this message translates to:
  /// **'The current joint angles become the pose that Home pose and sequence Home steps move to.'**
  String get setHomePoseBody;

  /// No description provided for @setHomeBody.
  ///
  /// In en, this message translates to:
  /// **'The current position becomes home (0, 0). Return-to-home flies back here, and sequence waypoints are measured from here. The device is {metres} m from the current home.'**
  String setHomeBody(String metres);

  /// No description provided for @autoDashDrives.
  ///
  /// In en, this message translates to:
  /// **'dash drives it'**
  String get autoDashDrives;

  /// No description provided for @autoTakeBack.
  ///
  /// In en, this message translates to:
  /// **'Choose MANUAL or HOLD, or move the sticks, to take it back.'**
  String get autoTakeBack;

  /// No description provided for @autoTip.
  ///
  /// In en, this message translates to:
  /// **'dash’s mode: while a sequence or a script drives the device. Run one from Automate.'**
  String get autoTip;

  /// No description provided for @tiltDrag.
  ///
  /// In en, this message translates to:
  /// **'Tilt · drag to simulate'**
  String get tiltDrag;

  /// No description provided for @stickThrottle.
  ///
  /// In en, this message translates to:
  /// **'Throttle'**
  String get stickThrottle;

  /// No description provided for @stickDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get stickDrive;

  /// No description provided for @stickYaw.
  ///
  /// In en, this message translates to:
  /// **'Yaw'**
  String get stickYaw;

  /// No description provided for @stickPitchRoll.
  ///
  /// In en, this message translates to:
  /// **'Pitch · roll'**
  String get stickPitchRoll;

  /// No description provided for @stickSteer.
  ///
  /// In en, this message translates to:
  /// **'Steer'**
  String get stickSteer;

  /// No description provided for @stickThrottleYaw.
  ///
  /// In en, this message translates to:
  /// **'Throttle · yaw'**
  String get stickThrottleYaw;

  /// No description provided for @tiltPitchRoll.
  ///
  /// In en, this message translates to:
  /// **'Tilt · pitch and roll'**
  String get tiltPitchRoll;

  /// No description provided for @tiltSteerDrive.
  ///
  /// In en, this message translates to:
  /// **'Tilt · steer and drive'**
  String get tiltSteerDrive;

  /// No description provided for @axUp.
  ///
  /// In en, this message translates to:
  /// **'UP'**
  String get axUp;

  /// No description provided for @axDn.
  ///
  /// In en, this message translates to:
  /// **'DN'**
  String get axDn;

  /// No description provided for @axFwd.
  ///
  /// In en, this message translates to:
  /// **'FWD'**
  String get axFwd;

  /// No description provided for @axRev.
  ///
  /// In en, this message translates to:
  /// **'REV'**
  String get axRev;

  /// No description provided for @axBack.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get axBack;

  /// No description provided for @axL.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get axL;

  /// No description provided for @axR.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get axR;

  /// No description provided for @axYaw.
  ///
  /// In en, this message translates to:
  /// **'YAW'**
  String get axYaw;

  /// No description provided for @rdAlt.
  ///
  /// In en, this message translates to:
  /// **'Alt'**
  String get rdAlt;

  /// No description provided for @rdOdom.
  ///
  /// In en, this message translates to:
  /// **'Odom'**
  String get rdOdom;

  /// No description provided for @rdSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get rdSpeed;

  /// No description provided for @rdHdg.
  ///
  /// In en, this message translates to:
  /// **'Hdg'**
  String get rdHdg;

  /// No description provided for @rdHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get rdHome;

  /// No description provided for @rdVz.
  ///
  /// In en, this message translates to:
  /// **'Vz'**
  String get rdVz;

  /// No description provided for @rdMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get rdMax;

  /// No description provided for @rdRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get rdRange;

  /// No description provided for @rdToolX.
  ///
  /// In en, this message translates to:
  /// **'Tool X'**
  String get rdToolX;

  /// No description provided for @rdToolY.
  ///
  /// In en, this message translates to:
  /// **'Tool Y'**
  String get rdToolY;

  /// No description provided for @rdToolZ.
  ///
  /// In en, this message translates to:
  /// **'Tool Z'**
  String get rdToolZ;

  /// No description provided for @rdThrust.
  ///
  /// In en, this message translates to:
  /// **'Thrust'**
  String get rdThrust;

  /// No description provided for @rdRpm.
  ///
  /// In en, this message translates to:
  /// **'RPM'**
  String get rdRpm;

  /// No description provided for @rdCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get rdCurrent;

  /// No description provided for @rdPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get rdPower;

  /// No description provided for @rdTemp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get rdTemp;

  /// No description provided for @rdEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get rdEfficiency;

  /// No description provided for @homePose.
  ///
  /// In en, this message translates to:
  /// **'Home pose'**
  String get homePose;

  /// No description provided for @setAsHome.
  ///
  /// In en, this message translates to:
  /// **'Set as home'**
  String get setAsHome;

  /// No description provided for @armJoint.
  ///
  /// In en, this message translates to:
  /// **'Joint'**
  String get armJoint;

  /// No description provided for @armCartesian.
  ///
  /// In en, this message translates to:
  /// **'Cartesian'**
  String get armCartesian;

  /// No description provided for @toolFrame.
  ///
  /// In en, this message translates to:
  /// **'Tool frame · base-relative'**
  String get toolFrame;

  /// No description provided for @armPadHelp.
  ///
  /// In en, this message translates to:
  /// **'Controller · {frame}: joint / cartesian · {wristBtn}: {wrist} · {gripper}: gripper'**
  String armPadHelp(String frame, String wristBtn, String wrist, String gripper);

  /// No description provided for @armWrist.
  ///
  /// In en, this message translates to:
  /// **'wrist'**
  String get armWrist;

  /// No description provided for @gripper.
  ///
  /// In en, this message translates to:
  /// **'Gripper'**
  String get gripper;

  /// No description provided for @gripperOpenPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% open'**
  String gripperOpenPct(int pct);

  /// No description provided for @gripperOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get gripperOpen;

  /// No description provided for @gripperClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get gripperClose;

  /// No description provided for @flightPhase.
  ///
  /// In en, this message translates to:
  /// **'Flight phase'**
  String get flightPhase;

  /// No description provided for @phasePad.
  ///
  /// In en, this message translates to:
  /// **'On pad'**
  String get phasePad;

  /// No description provided for @phaseCount.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get phaseCount;

  /// No description provided for @phaseBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get phaseBoost;

  /// No description provided for @phaseCoast.
  ///
  /// In en, this message translates to:
  /// **'Coast'**
  String get phaseCoast;

  /// No description provided for @phaseDrogue.
  ///
  /// In en, this message translates to:
  /// **'Drogue'**
  String get phaseDrogue;

  /// No description provided for @phaseMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get phaseMain;

  /// No description provided for @phaseLanded.
  ///
  /// In en, this message translates to:
  /// **'Landed'**
  String get phaseLanded;

  /// No description provided for @preflight.
  ///
  /// In en, this message translates to:
  /// **'Pre-flight'**
  String get preflight;

  /// No description provided for @checkPyro.
  ///
  /// In en, this message translates to:
  /// **'Pyro continuity · drogue, main'**
  String get checkPyro;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @checkGps.
  ///
  /// In en, this message translates to:
  /// **'GPS lock'**
  String get checkGps;

  /// No description provided for @sats.
  ///
  /// In en, this message translates to:
  /// **'{count} sats'**
  String sats(int count);

  /// No description provided for @noFix.
  ///
  /// In en, this message translates to:
  /// **'No fix'**
  String get noFix;

  /// No description provided for @checkFlightComputer.
  ///
  /// In en, this message translates to:
  /// **'Flight computer'**
  String get checkFlightComputer;

  /// No description provided for @safe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get safe;

  /// No description provided for @armFlightComputer.
  ///
  /// In en, this message translates to:
  /// **'Arm flight computer'**
  String get armFlightComputer;

  /// No description provided for @armPadClear.
  ///
  /// In en, this message translates to:
  /// **'Arm only when the pad is clear'**
  String get armPadClear;

  /// No description provided for @startCountdown.
  ///
  /// In en, this message translates to:
  /// **'Start countdown · {seconds} s'**
  String startCountdown(String seconds);

  /// No description provided for @abortLaunch.
  ///
  /// In en, this message translates to:
  /// **'Abort launch'**
  String get abortLaunch;

  /// No description provided for @deployDrogue.
  ///
  /// In en, this message translates to:
  /// **'Deploy drogue'**
  String get deployDrogue;

  /// No description provided for @deployMain.
  ///
  /// In en, this message translates to:
  /// **'Deploy main'**
  String get deployMain;

  /// No description provided for @autoDeploy.
  ///
  /// In en, this message translates to:
  /// **'Auto deploy · drogue at apogee · main at {metres} m'**
  String autoDeploy(String metres);

  /// No description provided for @landedBody.
  ///
  /// In en, this message translates to:
  /// **'Apogee {apogee} m · landed {distance} m from the pad.'**
  String landedBody(String apogee, String distance);

  /// No description provided for @resetToPad.
  ///
  /// In en, this message translates to:
  /// **'Reset to pad'**
  String get resetToPad;

  /// No description provided for @altitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get altitude;

  /// No description provided for @cutoff.
  ///
  /// In en, this message translates to:
  /// **'Cutoff'**
  String get cutoff;

  /// No description provided for @cutoffLimit.
  ///
  /// In en, this message translates to:
  /// **'limit'**
  String get cutoffLimit;

  /// No description provided for @cutoffBody.
  ///
  /// In en, this message translates to:
  /// **'Throttle was set to 0. Check the motor before running again.'**
  String get cutoffBody;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @benchDisarmed.
  ///
  /// In en, this message translates to:
  /// **'Arm the bench to spin the motor. Keep clear of the propeller.'**
  String get benchDisarmed;

  /// No description provided for @testSequence.
  ///
  /// In en, this message translates to:
  /// **'Test sequence'**
  String get testSequence;

  /// No description provided for @benchRamp.
  ///
  /// In en, this message translates to:
  /// **'RAMP'**
  String get benchRamp;

  /// No description provided for @benchSteps.
  ///
  /// In en, this message translates to:
  /// **'STEPS'**
  String get benchSteps;

  /// No description provided for @runAndRecord.
  ///
  /// In en, this message translates to:
  /// **'Run and record'**
  String get runAndRecord;

  /// No description provided for @benchRampDesc.
  ///
  /// In en, this message translates to:
  /// **'Ramp 0 to 100 % over {seconds} s, hold 2 s, stop.'**
  String benchRampDesc(String seconds);

  /// No description provided for @benchStepsDesc.
  ///
  /// In en, this message translates to:
  /// **'Steps of {size} %, {seconds} s each, up to 100 %.'**
  String benchStepsDesc(String size, String seconds);

  /// No description provided for @benchLimits.
  ///
  /// In en, this message translates to:
  /// **'Limits: {amps} A, {celsius} °C.'**
  String benchLimits(String amps, String celsius);

  /// No description provided for @mspTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitoring and tuning'**
  String get mspTitle;

  /// No description provided for @mspBody.
  ///
  /// In en, this message translates to:
  /// **'{name} runs {firmware} and is connected over MSP, the configuration link. The app shows its telemetry, tunes its PID gains on the Tune screen, and STOP disarms it. Fly it with your RC transmitter.'**
  String mspBody(String name, String firmware);

  /// No description provided for @radioOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Telemetry-only link'**
  String get radioOnlyTitle;

  /// No description provided for @radioOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is connected through {radio}, which carries telemetry only. Sticks, modes and commands do not reach the device this way; STOP does, within about a second. Control it over its main link (Wi-Fi, Bluetooth or a SiK radio) and rely on its failsafe when that link is out of range.'**
  String radioOnlyBody(String name, String radio);

  /// No description provided for @aRadio.
  ///
  /// In en, this message translates to:
  /// **'a radio'**
  String get aRadio;

  /// No description provided for @tileReadouts.
  ///
  /// In en, this message translates to:
  /// **'Readouts'**
  String get tileReadouts;

  /// No description provided for @tileSrcFused.
  ///
  /// In en, this message translates to:
  /// **'Fused state'**
  String get tileSrcFused;

  /// No description provided for @tileAttitude.
  ///
  /// In en, this message translates to:
  /// **'Attitude'**
  String get tileAttitude;

  /// No description provided for @tileAccelerometer.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer'**
  String get tileAccelerometer;

  /// No description provided for @tileGyroscope.
  ///
  /// In en, this message translates to:
  /// **'Gyroscope'**
  String get tileGyroscope;

  /// No description provided for @tileSrcBaroRange.
  ///
  /// In en, this message translates to:
  /// **'Baro + rangefinder'**
  String get tileSrcBaroRange;

  /// No description provided for @tileRadar.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get tileRadar;

  /// No description provided for @tileSrcRadar.
  ///
  /// In en, this message translates to:
  /// **'Radar / safety scanner'**
  String get tileSrcRadar;

  /// No description provided for @tileLidar.
  ///
  /// In en, this message translates to:
  /// **'Lidar'**
  String get tileLidar;

  /// No description provided for @tileSrcLidar.
  ///
  /// In en, this message translates to:
  /// **'Scanning lidar'**
  String get tileSrcLidar;

  /// No description provided for @tileJoints.
  ///
  /// In en, this message translates to:
  /// **'Joints'**
  String get tileJoints;

  /// No description provided for @tileSrcJoints.
  ///
  /// In en, this message translates to:
  /// **'Joint encoders'**
  String get tileSrcJoints;

  /// No description provided for @tileForceTorque.
  ///
  /// In en, this message translates to:
  /// **'Force / torque'**
  String get tileForceTorque;

  /// No description provided for @tileSrcWrist.
  ///
  /// In en, this message translates to:
  /// **'Wrist F/T sensor'**
  String get tileSrcWrist;

  /// No description provided for @tileSrcPower.
  ///
  /// In en, this message translates to:
  /// **'Power module'**
  String get tileSrcPower;

  /// No description provided for @tileSrcRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio link'**
  String get tileSrcRadio;

  /// No description provided for @tileCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get tileCamera;

  /// No description provided for @tileSrcCamera.
  ///
  /// In en, this message translates to:
  /// **'Device camera · MJPEG'**
  String get tileSrcCamera;

  /// No description provided for @tileSrcFleet.
  ///
  /// In en, this message translates to:
  /// **'Every connected device'**
  String get tileSrcFleet;

  /// No description provided for @tileSrcPhase.
  ///
  /// In en, this message translates to:
  /// **'Flight computer state machine'**
  String get tileSrcPhase;

  /// No description provided for @tileVerticalSpeed.
  ///
  /// In en, this message translates to:
  /// **'Vertical speed'**
  String get tileVerticalSpeed;

  /// No description provided for @tileSrcBaroImu.
  ///
  /// In en, this message translates to:
  /// **'Baro + IMU fusion'**
  String get tileSrcBaroImu;

  /// No description provided for @tilePyro.
  ///
  /// In en, this message translates to:
  /// **'Pyro channels'**
  String get tilePyro;

  /// No description provided for @tileSrcPyro.
  ///
  /// In en, this message translates to:
  /// **'4-channel pyro board'**
  String get tileSrcPyro;

  /// No description provided for @tileSrcTacho.
  ///
  /// In en, this message translates to:
  /// **'Optical tachometer'**
  String get tileSrcTacho;

  /// No description provided for @tileTorque.
  ///
  /// In en, this message translates to:
  /// **'Torque'**
  String get tileTorque;

  /// No description provided for @tileSrcTorque.
  ///
  /// In en, this message translates to:
  /// **'Reaction torque cell'**
  String get tileSrcTorque;

  /// No description provided for @tileMotorTemp.
  ///
  /// In en, this message translates to:
  /// **'Motor temp'**
  String get tileMotorTemp;

  /// No description provided for @tileSrcNtc.
  ///
  /// In en, this message translates to:
  /// **'NTC thermistor'**
  String get tileSrcNtc;

  /// No description provided for @tileRollRate.
  ///
  /// In en, this message translates to:
  /// **'Roll rate'**
  String get tileRollRate;

  /// No description provided for @tilePitchRate.
  ///
  /// In en, this message translates to:
  /// **'Pitch rate'**
  String get tilePitchRate;

  /// No description provided for @tileYawRate.
  ///
  /// In en, this message translates to:
  /// **'Yaw rate'**
  String get tileYawRate;

  /// No description provided for @tileGroundSpeed.
  ///
  /// In en, this message translates to:
  /// **'Ground speed'**
  String get tileGroundSpeed;

  /// No description provided for @tileAgl.
  ///
  /// In en, this message translates to:
  /// **'AGL'**
  String get tileAgl;

  /// No description provided for @tileOwnSpeed.
  ///
  /// In en, this message translates to:
  /// **'Own speed'**
  String get tileOwnSpeed;

  /// No description provided for @tileVoltage.
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get tileVoltage;

  /// No description provided for @tilePyroBus.
  ///
  /// In en, this message translates to:
  /// **'Pyro bus'**
  String get tilePyroBus;

  /// No description provided for @tileStator.
  ///
  /// In en, this message translates to:
  /// **'Stator'**
  String get tileStator;

  /// No description provided for @tileVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get tileVibration;

  /// No description provided for @tileAcc200.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer · 200 G'**
  String get tileAcc200;

  /// No description provided for @tileSafetyScanner.
  ///
  /// In en, this message translates to:
  /// **'Safety scanner'**
  String get tileSafetyScanner;

  /// No description provided for @tracks.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String tracks(int count);

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'{count} pts'**
  String points(int count);

  /// No description provided for @axes.
  ///
  /// In en, this message translates to:
  /// **'{count} axes'**
  String axes(int count);

  /// No description provided for @connectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} connected'**
  String connectedCount(int count);

  /// No description provided for @armedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} armed'**
  String armedCount(int count);

  /// No description provided for @proxClear.
  ///
  /// In en, this message translates to:
  /// **'clear'**
  String get proxClear;

  /// No description provided for @tileProximity.
  ///
  /// In en, this message translates to:
  /// **'Proximity'**
  String get tileProximity;

  /// No description provided for @tileSrcProx.
  ///
  /// In en, this message translates to:
  /// **'Proximity sensors'**
  String get tileSrcProx;

  /// No description provided for @tileSrcCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom channel · {hz} Hz'**
  String tileSrcCustom(String hz);

  /// No description provided for @tagScript.
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get tagScript;

  /// No description provided for @viewEnded.
  ///
  /// In en, this message translates to:
  /// **'ended'**
  String get viewEnded;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'{count} series'**
  String series(int count);

  /// No description provided for @rdReach.
  ///
  /// In en, this message translates to:
  /// **'Reach'**
  String get rdReach;

  /// No description provided for @pyroDrogue.
  ///
  /// In en, this message translates to:
  /// **'Drogue'**
  String get pyroDrogue;

  /// No description provided for @pyroMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get pyroMain;

  /// No description provided for @pyroAirstart.
  ///
  /// In en, this message translates to:
  /// **'Airstart'**
  String get pyroAirstart;

  /// No description provided for @pyroSpare.
  ///
  /// In en, this message translates to:
  /// **'Spare'**
  String get pyroSpare;

  /// No description provided for @pyroContinuity.
  ///
  /// In en, this message translates to:
  /// **'Continuity'**
  String get pyroContinuity;

  /// No description provided for @pyroFired.
  ///
  /// In en, this message translates to:
  /// **'Fired'**
  String get pyroFired;

  /// No description provided for @pyroNotWired.
  ///
  /// In en, this message translates to:
  /// **'Not wired'**
  String get pyroNotWired;

  /// No description provided for @removeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeTitle(String name);

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get removeDevice;

  /// No description provided for @removeBody.
  ///
  /// In en, this message translates to:
  /// **'The pairing key, HUD layouts and parameter drafts for {name} are deleted from this app.'**
  String removeBody(String name);

  /// No description provided for @removeDisconnectFirst.
  ///
  /// In en, this message translates to:
  /// **'It will be disconnected first.'**
  String get removeDisconnectFirst;

  /// No description provided for @removeKept.
  ///
  /// In en, this message translates to:
  /// **'Recordings are kept. To use the device again, pair it with a new code.'**
  String get removeKept;

  /// No description provided for @onlineOf.
  ///
  /// In en, this message translates to:
  /// **'{online} of {total} online'**
  String onlineOf(int online, int total);

  /// No description provided for @devicesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Pair a device, or follow the quickstart to add the library to your project.'**
  String get devicesEmptyHint;

  /// No description provided for @devicesSeveral.
  ///
  /// In en, this message translates to:
  /// **'Several devices can be connected at once. The one shown gets the sticks; the others hold on centred sticks, and STOP stops them all.'**
  String get devicesSeveral;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @removeName.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removeName(String name);

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @batShort.
  ///
  /// In en, this message translates to:
  /// **'BAT'**
  String get batShort;

  /// No description provided for @myRobot.
  ///
  /// In en, this message translates to:
  /// **'My robot'**
  String get myRobot;

  /// No description provided for @radioNothingHeard.
  ///
  /// In en, this message translates to:
  /// **'Nothing heard on {port} at {baud} baud. Check that the device is on, both radios use the same channel and air rate, and the baud rate matches. You can still add the link and connect later.'**
  String radioNothingHeard(String port, int baud);

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair a device'**
  String get pairTitle;

  /// No description provided for @pairNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get pairNearby;

  /// No description provided for @pairRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get pairRadio;

  /// No description provided for @pairSimulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated'**
  String get pairSimulated;

  /// No description provided for @pairSimulatedIntro.
  ///
  /// In en, this message translates to:
  /// **'Simulated devices run inside this app and speak the same protocol as real hardware. Add only the ones you need; each one is listed with a SIM tag.'**
  String get pairSimulatedIntro;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @addAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another'**
  String get addAnother;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @radioRatesTlm.
  ///
  /// In en, this message translates to:
  /// **'Telemetry {tlm} Hz · no control'**
  String radioRatesTlm(int tlm);

  /// No description provided for @radioRates.
  ///
  /// In en, this message translates to:
  /// **'Telemetry {tlm} Hz · control {ctl} Hz'**
  String radioRates(int tlm, int ctl);

  /// No description provided for @radioIntro.
  ///
  /// In en, this message translates to:
  /// **'A radio link is a radio modem plugged into this computer or phone over USB, talking to a matching radio on the device.'**
  String get radioIntro;

  /// No description provided for @radioIntroMore.
  ///
  /// In en, this message translates to:
  /// **'To the app it is a serial port; the radio type sets the speed and how much it can carry.'**
  String get radioIntroMore;

  /// No description provided for @radioNoSerial.
  ///
  /// In en, this message translates to:
  /// **'No USB serial on this platform'**
  String get radioNoSerial;

  /// No description provided for @radioNoSerialBody.
  ///
  /// In en, this message translates to:
  /// **'iOS apps cannot open USB serial adapters. Use the app on Android, macOS, Windows or Linux for radio links, or connect over Wi-Fi or Bluetooth.'**
  String get radioNoSerialBody;

  /// No description provided for @radioLora.
  ///
  /// In en, this message translates to:
  /// **'LoRa modules are not USB devices on their own. Flash the ground-station sketch from the LoRa guide onto a second board with the radio, and plug that board in.'**
  String get radioLora;

  /// No description provided for @usbPort.
  ///
  /// In en, this message translates to:
  /// **'USB port'**
  String get usbPort;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noSerialPorts.
  ///
  /// In en, this message translates to:
  /// **'No serial ports found. Plug in the radio’s USB adapter.'**
  String get noSerialPorts;

  /// No description provided for @baudRate.
  ///
  /// In en, this message translates to:
  /// **'Baud rate'**
  String get baudRate;

  /// No description provided for @heard.
  ///
  /// In en, this message translates to:
  /// **'Heard {name}'**
  String heard(String name);

  /// No description provided for @heardMavlink.
  ///
  /// In en, this message translates to:
  /// **'It speaks MAVLink: no pairing needed.'**
  String get heardMavlink;

  /// No description provided for @heardPairing.
  ///
  /// In en, this message translates to:
  /// **'It is in pairing mode and will get a key.'**
  String get heardPairing;

  /// No description provided for @heardNoPairing.
  ///
  /// In en, this message translates to:
  /// **'It is not in pairing mode; it is added without a key.'**
  String get heardNoPairing;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get listening;

  /// No description provided for @listenForDevice.
  ///
  /// In en, this message translates to:
  /// **'Listen for device'**
  String get listenForDevice;

  /// No description provided for @pairName.
  ///
  /// In en, this message translates to:
  /// **'Pair {name}'**
  String pairName(String name);

  /// No description provided for @addRadioLink.
  ///
  /// In en, this message translates to:
  /// **'Add radio link'**
  String get addRadioLink;

  /// No description provided for @pairNearbyIntro.
  ///
  /// In en, this message translates to:
  /// **'Plug in or power on the board. Flight controllers and drones appear on their own; boards running the koebelt/link library also show up here while in pairing mode.'**
  String get pairNearbyIntro;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning Wi-Fi, Bluetooth and USB boards…'**
  String get scanning;

  /// No description provided for @stillScanning.
  ///
  /// In en, this message translates to:
  /// **'Still scanning for more devices…'**
  String get stillScanning;

  /// No description provided for @addByIp.
  ///
  /// In en, this message translates to:
  /// **'Add by IP address'**
  String get addByIp;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @mavlinkPortNote.
  ///
  /// In en, this message translates to:
  /// **'The app listens on UDP 14550, like any ground station; the port is the vehicle’s, if you know it.'**
  String get mavlinkPortNote;

  /// No description provided for @addDevice.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get addDevice;

  /// No description provided for @notShowingUp.
  ///
  /// In en, this message translates to:
  /// **'Device not showing up? Boards with ArduPilot, PX4, Betaflight or INAV connect as they are; anything else needs the koebelt/link library.'**
  String get notShowingUp;

  /// No description provided for @openQuickstart.
  ///
  /// In en, this message translates to:
  /// **'Open the quickstart'**
  String get openQuickstart;

  /// No description provided for @orLower.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orLower;

  /// No description provided for @addItByIp.
  ///
  /// In en, this message translates to:
  /// **'add it by IP address'**
  String get addItByIp;

  /// No description provided for @secControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get secControl;

  /// No description provided for @secController.
  ///
  /// In en, this message translates to:
  /// **'Game controller'**
  String get secController;

  /// No description provided for @secLink.
  ///
  /// In en, this message translates to:
  /// **'Link and safety'**
  String get secLink;

  /// No description provided for @secRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get secRecording;

  /// No description provided for @secAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get secAlerts;

  /// No description provided for @secMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get secMap;

  /// No description provided for @secPairing.
  ///
  /// In en, this message translates to:
  /// **'Pairing'**
  String get secPairing;

  /// No description provided for @secAi.
  ///
  /// In en, this message translates to:
  /// **'AI assistants (MCP)'**
  String get secAi;

  /// No description provided for @secAiShort.
  ///
  /// In en, this message translates to:
  /// **'AI assistants'**
  String get secAiShort;

  /// No description provided for @secUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get secUpdates;

  /// No description provided for @setInput.
  ///
  /// In en, this message translates to:
  /// **'Input method'**
  String get setInput;

  /// No description provided for @setInputDesc.
  ///
  /// In en, this message translates to:
  /// **'Sticks: two virtual joysticks. Sliders: spring-loaded throttle and yaw with one stick. Tilt: steer by tilting the phone or tablet.'**
  String get setInputDesc;

  /// No description provided for @csSticks.
  ///
  /// In en, this message translates to:
  /// **'STICKS'**
  String get csSticks;

  /// No description provided for @csSliders.
  ///
  /// In en, this message translates to:
  /// **'SLIDERS'**
  String get csSliders;

  /// No description provided for @csTilt.
  ///
  /// In en, this message translates to:
  /// **'TILT'**
  String get csTilt;

  /// No description provided for @setInvert.
  ///
  /// In en, this message translates to:
  /// **'Invert pitch'**
  String get setInvert;

  /// No description provided for @setInvertDesc.
  ///
  /// In en, this message translates to:
  /// **'Push forward to pitch up.'**
  String get setInvertDesc;

  /// No description provided for @setHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get setHaptics;

  /// No description provided for @setHapticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Vibrate at stick centre and on warnings.'**
  String get setHapticsDesc;

  /// No description provided for @setLinkLoss.
  ///
  /// In en, this message translates to:
  /// **'On link loss'**
  String get setLinkLoss;

  /// No description provided for @setLinkLossDesc.
  ///
  /// In en, this message translates to:
  /// **'What a drone does after 1.8 s without a control packet. Ground robots and arms hold, test benches stop the motor, rockets continue their flight sequence.'**
  String get setLinkLossDesc;

  /// No description provided for @setRate.
  ///
  /// In en, this message translates to:
  /// **'Telemetry rate'**
  String get setRate;

  /// No description provided for @setRateDesc.
  ///
  /// In en, this message translates to:
  /// **'Higher rates use more bandwidth and battery.'**
  String get setRateDesc;

  /// No description provided for @setTestFailsafe.
  ///
  /// In en, this message translates to:
  /// **'Test failsafe'**
  String get setTestFailsafe;

  /// No description provided for @setTestFailsafeDesc.
  ///
  /// In en, this message translates to:
  /// **'Drops the control link for six seconds so you can check the configured behaviour.'**
  String get setTestFailsafeDesc;

  /// No description provided for @runTest.
  ///
  /// In en, this message translates to:
  /// **'Run test'**
  String get runTest;

  /// No description provided for @setRecordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get setRecordVideo;

  /// No description provided for @setRecordVideoDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep the device’s camera with each recording. The camera stays connected while recording, even when no screen shows it.'**
  String get setRecordVideoDesc;

  /// No description provided for @setVideoFps.
  ///
  /// In en, this message translates to:
  /// **'Video frame rate'**
  String get setVideoFps;

  /// No description provided for @setVideoFpsDesc.
  ///
  /// In en, this message translates to:
  /// **'Most frames a second kept. An ESP32-CAM at 640×480 takes about 10 MB a minute at 10 fps.'**
  String get setVideoFpsDesc;

  /// No description provided for @setAlertSound.
  ///
  /// In en, this message translates to:
  /// **'Alert sound'**
  String get setAlertSound;

  /// No description provided for @setAlertSoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Plays on alerts and when the link is lost. Phones vibrate instead when haptics are on.'**
  String get setAlertSoundDesc;

  /// No description provided for @kindsOnly.
  ///
  /// In en, this message translates to:
  /// **'{kinds} only.'**
  String kindsOnly(String kinds);

  /// No description provided for @below.
  ///
  /// In en, this message translates to:
  /// **'Below'**
  String get below;

  /// No description provided for @above.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get above;

  /// No description provided for @setMapTiles.
  ///
  /// In en, this message translates to:
  /// **'Map tiles'**
  String get setMapTiles;

  /// No description provided for @setMapTilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Background for the map view: Mapbox Dark, Outdoors (terrain) or Satellite, your own tiles, or none (a metre grid). Tiles you have looked at stay on this device for a while.'**
  String get setMapTilesDesc;

  /// No description provided for @mapDark.
  ///
  /// In en, this message translates to:
  /// **'DARK'**
  String get mapDark;

  /// No description provided for @mapOutdoors.
  ///
  /// In en, this message translates to:
  /// **'OUTDOORS'**
  String get mapOutdoors;

  /// No description provided for @mapSatellite.
  ///
  /// In en, this message translates to:
  /// **'SATELLITE'**
  String get mapSatellite;

  /// No description provided for @mapCustom.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM'**
  String get mapCustom;

  /// No description provided for @mapNone.
  ///
  /// In en, this message translates to:
  /// **'NONE'**
  String get mapNone;

  /// No description provided for @setMapboxToken.
  ///
  /// In en, this message translates to:
  /// **'Your Mapbox token'**
  String get setMapboxToken;

  /// No description provided for @setMapboxTokenDesc.
  ///
  /// In en, this message translates to:
  /// **'Optional: a public token (pk.…) from your own Mapbox account, to use your quota instead of the app’s.'**
  String get setMapboxTokenDesc;

  /// No description provided for @setTileUrl.
  ///
  /// In en, this message translates to:
  /// **'Tile URL'**
  String get setTileUrl;

  /// No description provided for @setTileUrlDesc.
  ///
  /// In en, this message translates to:
  /// **'A template with {z}, {x} and {y}, for example a satellite layer from your map provider with its key. Respect the provider’s terms.'**
  String setTileUrlDesc(String z, String x, String y);

  /// No description provided for @setAttribution.
  ///
  /// In en, this message translates to:
  /// **'Attribution'**
  String get setAttribution;

  /// No description provided for @setAttributionDesc.
  ///
  /// In en, this message translates to:
  /// **'The credit your provider requires, shown on the map.'**
  String get setAttributionDesc;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @setGuides.
  ///
  /// In en, this message translates to:
  /// **'Integration guides'**
  String get setGuides;

  /// No description provided for @setGuidesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add the koebelt/link library to Arduino, Python, ROS 2 or Rust projects.'**
  String get setGuidesDesc;

  /// No description provided for @scriptHostAt.
  ///
  /// In en, this message translates to:
  /// **'Script host at {address}'**
  String scriptHostAt(String address);

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forget;

  /// No description provided for @setScriptHosts.
  ///
  /// In en, this message translates to:
  /// **'Script hosts'**
  String get setScriptHosts;

  /// No description provided for @setScriptHostsDesc.
  ///
  /// In en, this message translates to:
  /// **'Computers on the network that run scripts for this device, with any Python package. On the computer: pip install koebelt-dash-scripts, then koebelt-dash-scripts host.'**
  String get setScriptHostsDesc;

  /// No description provided for @setScriptHostsDescPhone.
  ///
  /// In en, this message translates to:
  /// **'Computers on the network that run scripts for this phone, with any Python package. On the computer: pip install koebelt-dash-scripts, then koebelt-dash-scripts host.'**
  String get setScriptHostsDescPhone;

  /// No description provided for @setBeHost.
  ///
  /// In en, this message translates to:
  /// **'Be a script host'**
  String get setBeHost;

  /// No description provided for @setBeHostDesc.
  ///
  /// In en, this message translates to:
  /// **'Run scripts for phones and tablets on this network, with the scripts’ Python.'**
  String get setBeHostDesc;

  /// No description provided for @setBeHostCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code: {code}. Phones pair in Scripts > Runs on > Add a script host.'**
  String setBeHostCode(String code);

  /// No description provided for @sessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String sessionsCount(int count);

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @noRecordings.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet. Record a connected device, or use Import for a file or the sample recordings.'**
  String get noRecordings;

  /// No description provided for @tagNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get tagNew;

  /// No description provided for @tagVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get tagVideo;

  /// No description provided for @devicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 device} other{{count} devices}}'**
  String devicesCount(int count);

  /// No description provided for @deleteName.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteName(String name);

  /// No description provided for @exportName.
  ///
  /// In en, this message translates to:
  /// **'Export {name}'**
  String exportName(String name);

  /// No description provided for @replayEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Recording and playback'**
  String get replayEyebrow;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exitToLive.
  ///
  /// In en, this message translates to:
  /// **'Exit to live'**
  String get exitToLive;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteTitle(String name);

  /// No description provided for @exportFirst.
  ///
  /// In en, this message translates to:
  /// **'Export first'**
  String get exportFirst;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteRecordingBody.
  ///
  /// In en, this message translates to:
  /// **'The recording is removed from this device. This cannot be undone.'**
  String get deleteRecordingBody;

  /// No description provided for @deleteAllN.
  ///
  /// In en, this message translates to:
  /// **'Delete all {count}'**
  String deleteAllN(int count);

  /// No description provided for @deleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Every device’s recording of this session is removed from this device, with its video. This cannot be undone.'**
  String get deleteSessionBody;

  /// No description provided for @sequenceN.
  ///
  /// In en, this message translates to:
  /// **'Sequence {n}'**
  String sequenceN(int n);

  /// No description provided for @sequencesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no sequence} =1{1 sequence} other{{count} sequences}}'**
  String sequencesCount(int count);

  /// No description provided for @copyOf.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String copyOf(String name);

  /// No description provided for @noSequencesFor.
  ///
  /// In en, this message translates to:
  /// **'No sequences for {name} yet.'**
  String noSequencesFor(String name);

  /// No description provided for @sequenceIntro.
  ///
  /// In en, this message translates to:
  /// **'A sequence is a list of steps ({examples}) that the app runs one after the other, waiting for the device to confirm each one.'**
  String sequenceIntro(String examples);

  /// No description provided for @sequenceComplete.
  ///
  /// In en, this message translates to:
  /// **'Sequence complete'**
  String get sequenceComplete;

  /// No description provided for @sequenceStopped.
  ///
  /// In en, this message translates to:
  /// **'Sequence stopped'**
  String get sequenceStopped;

  /// No description provided for @flightSequence.
  ///
  /// In en, this message translates to:
  /// **'Flight sequence'**
  String get flightSequence;

  /// No description provided for @flightSequenceBody.
  ///
  /// In en, this message translates to:
  /// **'The flight computer runs launch, apogee and recovery on board. Set deployment on the Tune screen; use sequences here for pad checks.'**
  String get flightSequenceBody;

  /// No description provided for @stepsDrone.
  ///
  /// In en, this message translates to:
  /// **'take off, fly to waypoints, wait, land'**
  String get stepsDrone;

  /// No description provided for @stepsRover.
  ///
  /// In en, this message translates to:
  /// **'drive to waypoints, wait, change speed'**
  String get stepsRover;

  /// No description provided for @stepsArm.
  ///
  /// In en, this message translates to:
  /// **'move to poses, open or close the gripper'**
  String get stepsArm;

  /// No description provided for @stepsBench.
  ///
  /// In en, this message translates to:
  /// **'hold a throttle, ramp between two throttles'**
  String get stepsBench;

  /// No description provided for @stepsGeneric.
  ///
  /// In en, this message translates to:
  /// **'wait, set a mode, send commands'**
  String get stepsGeneric;

  /// No description provided for @whyExitReplay.
  ///
  /// In en, this message translates to:
  /// **'Exit replay to run'**
  String get whyExitReplay;

  /// No description provided for @whyResetStop.
  ///
  /// In en, this message translates to:
  /// **'Reset the stop first'**
  String get whyResetStop;

  /// No description provided for @whyAddSteps.
  ///
  /// In en, this message translates to:
  /// **'Add steps first'**
  String get whyAddSteps;

  /// No description provided for @onDevice.
  ///
  /// In en, this message translates to:
  /// **'On device'**
  String get onDevice;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploading;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'step {n} of {total}'**
  String stepOf(int n, int total);

  /// No description provided for @runsOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Runs on the device: it carries on if the link drops'**
  String get runsOnDevice;

  /// No description provided for @stopSequence.
  ///
  /// In en, this message translates to:
  /// **'Stop sequence'**
  String get stopSequence;

  /// No description provided for @stoppedFromApp.
  ///
  /// In en, this message translates to:
  /// **'Stopped from the app'**
  String get stoppedFromApp;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String stepsCount(int count);

  /// No description provided for @secondsTimed.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s timed'**
  String secondsTimed(String seconds);

  /// No description provided for @newSequence.
  ///
  /// In en, this message translates to:
  /// **'New sequence'**
  String get newSequence;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @lockedWhileRunning.
  ///
  /// In en, this message translates to:
  /// **'Locked while running'**
  String get lockedWhileRunning;

  /// No description provided for @addFirstStep.
  ///
  /// In en, this message translates to:
  /// **'Add the first step below. Steps run top to bottom.'**
  String get addFirstStep;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// No description provided for @deleteStep.
  ///
  /// In en, this message translates to:
  /// **'Delete step'**
  String get deleteStep;

  /// No description provided for @useCurrentPosition.
  ///
  /// In en, this message translates to:
  /// **'Use current position'**
  String get useCurrentPosition;

  /// No description provided for @useCurrentPose.
  ///
  /// In en, this message translates to:
  /// **'Use current pose'**
  String get useCurrentPose;

  /// No description provided for @egDeploy.
  ///
  /// In en, this message translates to:
  /// **'e.g. deploy'**
  String get egDeploy;

  /// No description provided for @planTopView.
  ///
  /// In en, this message translates to:
  /// **'Plan · top view'**
  String get planTopView;

  /// No description provided for @throttleProfile.
  ///
  /// In en, this message translates to:
  /// **'Throttle profile'**
  String get throttleProfile;

  /// No description provided for @liveView.
  ///
  /// In en, this message translates to:
  /// **'Live view'**
  String get liveView;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @setPoseAsHome.
  ///
  /// In en, this message translates to:
  /// **'Set current pose as home'**
  String get setPoseAsHome;

  /// No description provided for @planNoteDrone.
  ///
  /// In en, this message translates to:
  /// **'Waypoints are metres east and north of the take-off point. The drone holds at each one before the next step. The failsafe still applies if the link drops.'**
  String get planNoteDrone;

  /// No description provided for @planNoteRover.
  ///
  /// In en, this message translates to:
  /// **'Waypoints are metres east and north of the start point. The rover stops at each one before the next step.'**
  String get planNoteRover;

  /// No description provided for @planNoteArm.
  ///
  /// In en, this message translates to:
  /// **'Move the arm by hand or with jog controls, then use “{button}” to record it.'**
  String planNoteArm(String button);

  /// No description provided for @planNoteBench.
  ///
  /// In en, this message translates to:
  /// **'Current and temperature cutoffs on the device stay active during the sequence.'**
  String get planNoteBench;

  /// No description provided for @planNoteGeneric.
  ///
  /// In en, this message translates to:
  /// **'Each step waits for the device to confirm before the next one starts.'**
  String get planNoteGeneric;

  /// No description provided for @metreGrid.
  ///
  /// In en, this message translates to:
  /// **'{metres} m grid'**
  String metreGrid(String metres);

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @checkNeedsPython.
  ///
  /// In en, this message translates to:
  /// **'Check needs Python on this computer: Set up Python on the script’s page.'**
  String get checkNeedsPython;

  /// No description provided for @couldNotCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not check with {python}.'**
  String couldNotCheck(String python);

  /// No description provided for @scriptErrors.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This script has an error} other{This script has {count} errors}}'**
  String scriptErrors(int count);

  /// No description provided for @runAnyway.
  ///
  /// In en, this message translates to:
  /// **'Run anyway'**
  String get runAnyway;

  /// No description provided for @showThem.
  ///
  /// In en, this message translates to:
  /// **'Show them'**
  String get showThem;

  /// No description provided for @checkFound.
  ///
  /// In en, this message translates to:
  /// **'Check found what would stop it, probably before it moves anything:'**
  String get checkFound;

  /// No description provided for @lineN.
  ///
  /// In en, this message translates to:
  /// **'line {n}'**
  String lineN(int n);

  /// No description provided for @andMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String andMore(int count);

  /// No description provided for @installImports.
  ///
  /// In en, this message translates to:
  /// **'Install what this script imports?'**
  String get installImports;

  /// No description provided for @installAndRun.
  ///
  /// In en, this message translates to:
  /// **'Install and run'**
  String get installAndRun;

  /// No description provided for @missingImports.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{names} is not in this Python, so the script would stop at its imports.} other{{names} are not in this Python, so the script would stop at its imports.}}'**
  String missingImports(int count, String names);

  /// No description provided for @couldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start: {error}'**
  String couldNotStart(String error);

  /// No description provided for @pythonScripts.
  ///
  /// In en, this message translates to:
  /// **'Python scripts'**
  String get pythonScripts;

  /// No description provided for @copiedExample.
  ///
  /// In en, this message translates to:
  /// **'Copied the example to {file} in your scripts.'**
  String copiedExample(String file);

  /// No description provided for @couldNotCopyExample.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the example: {error}'**
  String couldNotCopyExample(String error);

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @deleteScriptBody.
  ///
  /// In en, this message translates to:
  /// **'It moves to the .trash folder inside the scripts folder, where you can get it back.'**
  String get deleteScriptBody;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @examples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get examples;

  /// No description provided for @connectedOutside.
  ///
  /// In en, this message translates to:
  /// **'Connected from outside dash'**
  String get connectedOutside;

  /// No description provided for @editing.
  ///
  /// In en, this message translates to:
  /// **'editing'**
  String get editing;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get saved;

  /// No description provided for @checkAction.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkAction;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @openInEditor.
  ///
  /// In en, this message translates to:
  /// **'Open in editor'**
  String get openInEditor;

  /// No description provided for @newScript.
  ///
  /// In en, this message translates to:
  /// **'New script'**
  String get newScript;

  /// No description provided for @importPyZip.
  ///
  /// In en, this message translates to:
  /// **'Import a .py or .zip'**
  String get importPyZip;

  /// No description provided for @noScriptsPlus.
  ///
  /// In en, this message translates to:
  /// **'No scripts yet. Start from an example, or press +.'**
  String get noScriptsPlus;

  /// No description provided for @scriptsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Scripts drive your devices from Python. Create one, import one, or start from an example.'**
  String get scriptsEmpty;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @noScriptsNew.
  ///
  /// In en, this message translates to:
  /// **'No scripts yet. Start from an example, or press New.'**
  String get noScriptsNew;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @showInFinder.
  ///
  /// In en, this message translates to:
  /// **'Show in Finder'**
  String get showInFinder;

  /// No description provided for @showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get showInFolder;

  /// No description provided for @myScript.
  ///
  /// In en, this message translates to:
  /// **'My script'**
  String get myScript;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @needs.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get needs;

  /// No description provided for @runsOn.
  ///
  /// In en, this message translates to:
  /// **'Runs on'**
  String get runsOn;

  /// No description provided for @scriptsRunOnComputer.
  ///
  /// In en, this message translates to:
  /// **'Scripts run on a computer'**
  String get scriptsRunOnComputer;

  /// No description provided for @scriptsRunOnComputerBody.
  ///
  /// In en, this message translates to:
  /// **'This device sends them to a script host: a computer on the same network running koebelt-dash-scripts, which can use any Python package (OpenCV, PyTorch…).'**
  String get scriptsRunOnComputerBody;

  /// No description provided for @addScriptHost.
  ///
  /// In en, this message translates to:
  /// **'Add a script host'**
  String get addScriptHost;

  /// No description provided for @notRunning.
  ///
  /// In en, this message translates to:
  /// **'Not running'**
  String get notRunning;

  /// No description provided for @endedError.
  ///
  /// In en, this message translates to:
  /// **'Ended with an error'**
  String get endedError;

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get ended;

  /// No description provided for @waitingConnect.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the script to connect (connect() in the script)…'**
  String get waitingConnect;

  /// No description provided for @youHaveSticks.
  ///
  /// In en, this message translates to:
  /// **'You have the sticks'**
  String get youHaveSticks;

  /// No description provided for @youHaveSticksBody.
  ///
  /// In en, this message translates to:
  /// **'You moved the sticks, so the script’s are ignored.'**
  String get youHaveSticksBody;

  /// No description provided for @scriptLostSticks.
  ///
  /// In en, this message translates to:
  /// **'The script lost the sticks'**
  String get scriptLostSticks;

  /// No description provided for @isNotConnected.
  ///
  /// In en, this message translates to:
  /// **'{name} is not connected'**
  String isNotConnected(String name);

  /// No description provided for @connectItOrChoose.
  ///
  /// In en, this message translates to:
  /// **'Connect it, or choose another device above.'**
  String get connectItOrChoose;

  /// No description provided for @doesNotFit.
  ///
  /// In en, this message translates to:
  /// **'{name} does not fit this script'**
  String doesNotFit(String name);

  /// No description provided for @chooseOrChangeRequires.
  ///
  /// In en, this message translates to:
  /// **'Choose another device above, or change the # requires: line.'**
  String get chooseOrChangeRequires;

  /// No description provided for @scriptNeedsDevice.
  ///
  /// In en, this message translates to:
  /// **'A script drives a device: connect one first (Devices, or the device menu at the top).'**
  String get scriptNeedsDevice;

  /// No description provided for @doesNotFitShort.
  ///
  /// In en, this message translates to:
  /// **'does not fit'**
  String get doesNotFitShort;

  /// No description provided for @selectedInDash.
  ///
  /// In en, this message translates to:
  /// **'Selected in dash'**
  String get selectedInDash;

  /// No description provided for @noneConnected.
  ///
  /// In en, this message translates to:
  /// **'none connected'**
  String get noneConnected;

  /// No description provided for @thisComputer.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get thisComputer;

  /// No description provided for @lookingForPython.
  ///
  /// In en, this message translates to:
  /// **'Looking for Python…'**
  String get lookingForPython;

  /// No description provided for @noneFound.
  ///
  /// In en, this message translates to:
  /// **'None found'**
  String get noneFound;

  /// No description provided for @noPackage.
  ///
  /// In en, this message translates to:
  /// **'no package'**
  String get noPackage;

  /// No description provided for @python3Needed.
  ///
  /// In en, this message translates to:
  /// **'Python 3 is needed'**
  String get python3Needed;

  /// No description provided for @python3NeededBody.
  ///
  /// In en, this message translates to:
  /// **'Install it from python.org, then come back here.'**
  String get python3NeededBody;

  /// No description provided for @newerLibrary.
  ///
  /// In en, this message translates to:
  /// **'A newer version of the library scripts use is out, for this version of koebelt dash.'**
  String get newerLibrary;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @pythonNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'This Python does not answer'**
  String get pythonNoAnswer;

  /// No description provided for @packageNotInPython.
  ///
  /// In en, this message translates to:
  /// **'koebelt-dash-scripts is not in this Python'**
  String get packageNotInPython;

  /// No description provided for @pythonNoAnswerBody.
  ///
  /// In en, this message translates to:
  /// **'dash could not run {python}. Choose another, or create a scripts environment.'**
  String pythonNoAnswerBody(String python);

  /// No description provided for @packageNotInPythonBody.
  ///
  /// In en, this message translates to:
  /// **'Install it here (pip install koebelt-dash-scripts), or let dash create a scripts environment in the scripts folder.'**
  String get packageNotInPythonBody;

  /// No description provided for @installHere.
  ///
  /// In en, this message translates to:
  /// **'Install here'**
  String get installHere;

  /// No description provided for @scriptsEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Scripts environment'**
  String get scriptsEnvironment;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @settingUpPython.
  ///
  /// In en, this message translates to:
  /// **'Setting up Python'**
  String get settingUpPython;

  /// No description provided for @oneTimeSetup.
  ///
  /// In en, this message translates to:
  /// **'One-time setup'**
  String get oneTimeSetup;

  /// No description provided for @oneTimeSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Scripts need the koebelt-dash-scripts package. dash can create a Python environment for them in the scripts folder (.venv) and install it there; your own packages (OpenCV, PyTorch…) go there too.'**
  String get oneTimeSetupBody;

  /// No description provided for @setUpPython.
  ///
  /// In en, this message translates to:
  /// **'Set up Python'**
  String get setUpPython;

  /// No description provided for @packagesMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A package is missing} other{Packages are missing}}'**
  String packagesMissing(int count);

  /// No description provided for @packagesMissingBody.
  ///
  /// In en, this message translates to:
  /// **'This script imports {modules}, not in this Python: it would stop there. Install {packages}?'**
  String packagesMissingBody(String modules, String packages);

  /// No description provided for @installing.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get installing;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @stopScript.
  ///
  /// In en, this message translates to:
  /// **'Stop script'**
  String get stopScript;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @triggers.
  ///
  /// In en, this message translates to:
  /// **'Triggers'**
  String get triggers;

  /// No description provided for @triggersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Buttons, keys, controller buttons, conditions and timers that send events to the script. Declare them with @dev.trigger(…), or add them here.'**
  String get triggersEmpty;

  /// No description provided for @limits.
  ///
  /// In en, this message translates to:
  /// **'Limits'**
  String get limits;

  /// No description provided for @maxSpeed.
  ///
  /// In en, this message translates to:
  /// **'Max speed'**
  String get maxSpeed;

  /// No description provided for @geofence.
  ///
  /// In en, this message translates to:
  /// **'Geofence'**
  String get geofence;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get off;

  /// No description provided for @metresFromHome.
  ///
  /// In en, this message translates to:
  /// **'{metres} m from home'**
  String metresFromHome(int metres);

  /// No description provided for @ceiling.
  ///
  /// In en, this message translates to:
  /// **'Ceiling'**
  String get ceiling;

  /// No description provided for @armingTakeoff.
  ///
  /// In en, this message translates to:
  /// **'Arming, take-off'**
  String get armingTakeoff;

  /// No description provided for @allowed.
  ///
  /// In en, this message translates to:
  /// **'allowed'**
  String get allowed;

  /// No description provided for @notAllowed.
  ///
  /// In en, this message translates to:
  /// **'not allowed'**
  String get notAllowed;

  /// No description provided for @paramWrites.
  ///
  /// In en, this message translates to:
  /// **'Parameter writes'**
  String get paramWrites;

  /// No description provided for @fire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fire;

  /// No description provided for @notBound.
  ///
  /// In en, this message translates to:
  /// **'Not bound yet'**
  String get notBound;

  /// No description provided for @console.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get console;

  /// No description provided for @loopHz.
  ///
  /// In en, this message translates to:
  /// **'loop {hz} Hz'**
  String loopHz(String hz);

  /// No description provided for @consoleEmpty.
  ///
  /// In en, this message translates to:
  /// **'print() output and errors show here.'**
  String get consoleEmpty;

  /// No description provided for @fromOutside.
  ///
  /// In en, this message translates to:
  /// **'from outside dash'**
  String get fromOutside;

  /// No description provided for @valid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid;

  /// No description provided for @padTaken.
  ///
  /// In en, this message translates to:
  /// **'{button} is {action} in the controller mapping: that action wins.'**
  String padTaken(String button, String action);

  /// No description provided for @forDuration.
  ///
  /// In en, this message translates to:
  /// **'for'**
  String get forDuration;

  /// No description provided for @conditionHelp.
  ///
  /// In en, this message translates to:
  /// **'Fields: {fields}, mode, armed, and the device’s own channels (motor_temp.max…). Combine with and, or, not; add “for 3s” to wait.'**
  String conditionHelp(String fields);

  /// No description provided for @whenTrue.
  ///
  /// In en, this message translates to:
  /// **'WHEN TRUE'**
  String get whenTrue;

  /// No description provided for @trueAndFalse.
  ///
  /// In en, this message translates to:
  /// **'TRUE AND FALSE'**
  String get trueAndFalse;

  /// No description provided for @alsoOnControl.
  ///
  /// In en, this message translates to:
  /// **'Also on Control, next to the sticks'**
  String get alsoOnControl;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get key;

  /// No description provided for @pressKey.
  ///
  /// In en, this message translates to:
  /// **'Press a key…'**
  String get pressKey;

  /// No description provided for @pressAnotherKey.
  ///
  /// In en, this message translates to:
  /// **'{key} · press another to change'**
  String pressAnotherKey(String key);

  /// No description provided for @clickThenKey.
  ///
  /// In en, this message translates to:
  /// **'Click, then press a key'**
  String get clickThenKey;

  /// No description provided for @noButtonYet.
  ///
  /// In en, this message translates to:
  /// **'No button yet'**
  String get noButtonYet;

  /// No description provided for @pressButton.
  ///
  /// In en, this message translates to:
  /// **'Press a button…'**
  String get pressButton;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @onlyThisMode.
  ///
  /// In en, this message translates to:
  /// **'Only this mode (HOLD…), or empty for any'**
  String get onlyThisMode;

  /// No description provided for @onlyMessagesContaining.
  ///
  /// In en, this message translates to:
  /// **'Only messages containing…'**
  String get onlyMessagesContaining;

  /// No description provided for @every.
  ///
  /// In en, this message translates to:
  /// **'EVERY'**
  String get every;

  /// No description provided for @onceAfter.
  ///
  /// In en, this message translates to:
  /// **'ONCE AFTER'**
  String get onceAfter;

  /// No description provided for @secondsWord.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get secondsWord;

  /// No description provided for @addTrigger.
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get addTrigger;

  /// No description provided for @editTrigger.
  ///
  /// In en, this message translates to:
  /// **'Edit trigger'**
  String get editTrigger;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @eventPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'The name the script receives'**
  String get eventPlaceholder;

  /// No description provided for @firedBy.
  ///
  /// In en, this message translates to:
  /// **'Fired by'**
  String get firedBy;

  /// No description provided for @triggerHelp.
  ///
  /// In en, this message translates to:
  /// **'The script receives “{event}” in the handler of that name, or in @dev.on_trigger. Conditions, events and timers run in dash.'**
  String triggerHelp(String event);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @limitsHelp.
  ///
  /// In en, this message translates to:
  /// **'Set here, not in the script: the script cannot change them.'**
  String get limitsHelp;

  /// No description provided for @maximumSpeed.
  ///
  /// In en, this message translates to:
  /// **'Maximum speed'**
  String get maximumSpeed;

  /// No description provided for @maximumSpeedDesc.
  ///
  /// In en, this message translates to:
  /// **'The script’s sticks are scaled to this, and its speed limit capped.'**
  String get maximumSpeedDesc;

  /// No description provided for @geofenceDesc.
  ///
  /// In en, this message translates to:
  /// **'Beyond this distance from home, the script loses the sticks and the device holds.'**
  String get geofenceDesc;

  /// No description provided for @ceilingDesc.
  ///
  /// In en, this message translates to:
  /// **'Above this height, the same for drones.'**
  String get ceilingDesc;

  /// No description provided for @allowArming.
  ///
  /// In en, this message translates to:
  /// **'Allow arming and take-off'**
  String get allowArming;

  /// No description provided for @allowArmingDesc.
  ///
  /// In en, this message translates to:
  /// **'Otherwise the script can only move a device you armed.'**
  String get allowArmingDesc;

  /// No description provided for @allowParams.
  ///
  /// In en, this message translates to:
  /// **'Allow parameter writes'**
  String get allowParams;

  /// No description provided for @allowParamsDesc.
  ///
  /// In en, this message translates to:
  /// **'For tuning scripts. They can change how the device behaves.'**
  String get allowParamsDesc;

  /// No description provided for @pairing.
  ///
  /// In en, this message translates to:
  /// **'Pairing…'**
  String get pairing;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @scriptHostIntro.
  ///
  /// In en, this message translates to:
  /// **'A script host is a computer on the same network that runs scripts for this computer: a laptop, a Raspberry Pi, a Jetson… On it:'**
  String get scriptHostIntro;

  /// No description provided for @scriptHostIntroPhone.
  ///
  /// In en, this message translates to:
  /// **'A script host is a computer on the same network that runs scripts for this phone or tablet: a laptop, a Raspberry Pi, a Jetson… On it:'**
  String get scriptHostIntroPhone;

  /// No description provided for @onTheNetwork.
  ///
  /// In en, this message translates to:
  /// **'On the network'**
  String get onTheNetwork;

  /// No description provided for @lookingForHosts.
  ///
  /// In en, this message translates to:
  /// **'Looking for script hosts'**
  String get lookingForHosts;

  /// No description provided for @noHostsFound.
  ///
  /// In en, this message translates to:
  /// **'None found. Type its address below (shown by `ipconfig getifaddr en0`, `hostname -I`…).'**
  String get noHostsFound;

  /// No description provided for @lookAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get lookAgain;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @pairingCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get pairingCode;

  /// No description provided for @pairingCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'ABC-123, printed by the host'**
  String get pairingCodePlaceholder;

  /// No description provided for @updatingPct.
  ///
  /// In en, this message translates to:
  /// **'Updating {pct}%'**
  String updatingPct(int pct);

  /// No description provided for @installingState.
  ///
  /// In en, this message translates to:
  /// **'Installing'**
  String get installingState;

  /// No description provided for @appUpdating.
  ///
  /// In en, this message translates to:
  /// **'koebelt dash is updating'**
  String get appUpdating;

  /// No description provided for @appAvailable.
  ///
  /// In en, this message translates to:
  /// **'koebelt dash {version} is available'**
  String appAvailable(String version);

  /// No description provided for @appUpToDate.
  ///
  /// In en, this message translates to:
  /// **'koebelt dash is up to date'**
  String get appUpToDate;

  /// No description provided for @skipVersion.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get skipVersion;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @downloadingPct.
  ///
  /// In en, this message translates to:
  /// **'Downloading {pct}%'**
  String downloadingPct(int pct);

  /// No description provided for @installAnyway.
  ///
  /// In en, this message translates to:
  /// **'Install anyway'**
  String get installAnyway;

  /// No description provided for @updateAnyway.
  ///
  /// In en, this message translates to:
  /// **'Update anyway'**
  String get updateAnyway;

  /// No description provided for @installVersion.
  ///
  /// In en, this message translates to:
  /// **'Install {version}'**
  String installVersion(String version);

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @youHaveOlder.
  ///
  /// In en, this message translates to:
  /// **'You have {version}; this is an older version. Settings and recordings made with a newer version may not all open in it, and it will not remind you about newer ones until the next release.'**
  String youHaveOlder(String version);

  /// No description provided for @youHave.
  ///
  /// In en, this message translates to:
  /// **'You have {version}.'**
  String youHave(String version);

  /// No description provided for @notFromApp.
  ///
  /// In en, this message translates to:
  /// **'Not from the app'**
  String get notFromApp;

  /// No description provided for @checkingCompat.
  ///
  /// In en, this message translates to:
  /// **'Checking compatibility with your devices…'**
  String get checkingCompat;

  /// No description provided for @compatUnknown.
  ///
  /// In en, this message translates to:
  /// **'Compatibility unknown'**
  String get compatUnknown;

  /// No description provided for @compatUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'Could not read which koebelt/link versions this release supports.'**
  String get compatUnknownBody;

  /// No description provided for @notCompatibleWith.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Not compatible with one of your devices} other{Not compatible with {count} of your devices}}'**
  String notCompatibleWith(int count);

  /// No description provided for @notCompatibleBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Update the koebelt/link library on it first, or keep your version and choose another in Settings > Updates.} other{Update the koebelt/link library on them first, or keep your version and choose another in Settings > Updates.}}'**
  String notCompatibleBody(int count);

  /// No description provided for @disarmFirst.
  ///
  /// In en, this message translates to:
  /// **'Disarm first'**
  String get disarmFirst;

  /// No description provided for @disarmFirstBody.
  ///
  /// In en, this message translates to:
  /// **'A connected device is armed. Updating closes the app, which drops the link; disarm it, then update.'**
  String get disarmFirstBody;

  /// No description provided for @devicesWillDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Devices will disconnect'**
  String get devicesWillDisconnect;

  /// No description provided for @devicesWillDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Installing closes the app, so the connected device loses the link and its failsafe takes over until you reconnect.} other{Installing closes the app, so the {count} connected devices lose the link and their failsafe takes over until you reconnect.}}'**
  String devicesWillDisconnectBody(int count);

  /// No description provided for @notInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get notInstalled;

  /// No description provided for @inThisVersion.
  ///
  /// In en, this message translates to:
  /// **'In this version'**
  String get inThisVersion;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What’s new'**
  String get whatsNew;

  /// No description provided for @fullNotes.
  ///
  /// In en, this message translates to:
  /// **'Full release notes'**
  String get fullNotes;

  /// No description provided for @chooseAnotherVersion.
  ///
  /// In en, this message translates to:
  /// **'Choose another version'**
  String get chooseAnotherVersion;

  /// No description provided for @chooseVersion.
  ///
  /// In en, this message translates to:
  /// **'Choose a version'**
  String get chooseVersion;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @chooseVersionBody.
  ///
  /// In en, this message translates to:
  /// **'Install any published version, newer or older. Each one says whether it works with the koebelt/link versions your devices reported when they last connected.'**
  String get chooseVersionBody;

  /// No description provided for @askingGithub.
  ///
  /// In en, this message translates to:
  /// **'Asking GitHub…'**
  String get askingGithub;

  /// No description provided for @noReleases.
  ///
  /// In en, this message translates to:
  /// **'No releases found.'**
  String get noReleases;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @checkingShort.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingShort;

  /// No description provided for @worksWithDevices.
  ///
  /// In en, this message translates to:
  /// **'Works with your devices'**
  String get worksWithDevices;

  /// No description provided for @noDevicesToCheck.
  ///
  /// In en, this message translates to:
  /// **'No devices to check yet'**
  String get noDevicesToCheck;

  /// No description provided for @notFor.
  ///
  /// In en, this message translates to:
  /// **'Not for {names}'**
  String notFor(String names);

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @updateHowAndroid.
  ///
  /// In en, this message translates to:
  /// **'The update downloads here and Android asks you to confirm the install.'**
  String get updateHowAndroid;

  /// No description provided for @updateHow.
  ///
  /// In en, this message translates to:
  /// **'The update downloads, is checked against the release, and koebelt dash restarts on the new version.'**
  String get updateHow;

  /// No description provided for @versionN.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionN(String version);

  /// No description provided for @noSelfUpdate.
  ///
  /// In en, this message translates to:
  /// **'This build does not update itself: the App Store and TestFlight update theirs, and the downloads from GitHub check for new versions on their own.'**
  String get noSelfUpdate;

  /// No description provided for @releases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get releases;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date.'**
  String get upToDate;

  /// No description provided for @versionAvailable.
  ///
  /// In en, this message translates to:
  /// **'{version} is available.'**
  String versionAvailable(String version);

  /// No description provided for @downloadingWhat.
  ///
  /// In en, this message translates to:
  /// **'Downloading {what}… {pct}%'**
  String downloadingWhat(String what, int pct);

  /// No description provided for @installingWhat.
  ///
  /// In en, this message translates to:
  /// **'Installing {what}…'**
  String installingWhat(String what);

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWrong;

  /// No description provided for @notChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet.'**
  String get notChecked;

  /// No description provided for @updateTo.
  ///
  /// In en, this message translates to:
  /// **'Update to {version}'**
  String updateTo(String version);

  /// No description provided for @checkNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkNow;

  /// No description provided for @chooseVersionDesc.
  ///
  /// In en, this message translates to:
  /// **'Install any published version, older ones too, with whether it works with your devices’ koebelt/link libraries.'**
  String get chooseVersionDesc;

  /// No description provided for @versions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get versions;

  /// No description provided for @betas.
  ///
  /// In en, this message translates to:
  /// **'Betas'**
  String get betas;

  /// No description provided for @betasDesc.
  ///
  /// In en, this message translates to:
  /// **'Also offer beta versions and release candidates: the next features before they are released, with more chances of a bug.'**
  String get betasDesc;

  /// No description provided for @autoCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates automatically'**
  String get autoCheck;

  /// No description provided for @autoCheckDesc.
  ///
  /// In en, this message translates to:
  /// **'At launch and once a day, koebelt dash asks GitHub for the latest release. Nothing else is sent.'**
  String get autoCheckDesc;

  /// No description provided for @padYawSteer.
  ///
  /// In en, this message translates to:
  /// **'Yaw · steer'**
  String get padYawSteer;

  /// No description provided for @padRoll.
  ///
  /// In en, this message translates to:
  /// **'Roll'**
  String get padRoll;

  /// No description provided for @padPitchDrive.
  ///
  /// In en, this message translates to:
  /// **'Pitch · drive'**
  String get padPitchDrive;

  /// No description provided for @padUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Controllers are not available on this platform.'**
  String get padUnavailable;

  /// No description provided for @padNone.
  ///
  /// In en, this message translates to:
  /// **'No controller connected. Pair a Bluetooth controller in the system settings, or plug one in over USB. RC transmitters work in USB joystick mode.'**
  String get padNone;

  /// No description provided for @padConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected: {names}.'**
  String padConnected(String names);

  /// No description provided for @padUse.
  ///
  /// In en, this message translates to:
  /// **'Use a game controller'**
  String get padUse;

  /// No description provided for @padUseDesc.
  ///
  /// In en, this message translates to:
  /// **'Sticks drive drones and ground robots, and jog robot arms, once they are armed; buttons work on any device. On-screen controls keep working while the controller is idle.'**
  String get padUseDesc;

  /// No description provided for @padSticks.
  ///
  /// In en, this message translates to:
  /// **'Sticks'**
  String get padSticks;

  /// No description provided for @padMoveNow.
  ///
  /// In en, this message translates to:
  /// **'Move or press the control now'**
  String get padMoveNow;

  /// No description provided for @padButtons.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get padButtons;

  /// No description provided for @padDeadzone.
  ///
  /// In en, this message translates to:
  /// **'Dead zone'**
  String get padDeadzone;

  /// No description provided for @padDeadzoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Stick movement ignored around the centre: {pct} %.'**
  String padDeadzoneDesc(int pct);

  /// No description provided for @padExpo.
  ///
  /// In en, this message translates to:
  /// **'Expo'**
  String get padExpo;

  /// No description provided for @padExpoDesc.
  ///
  /// In en, this message translates to:
  /// **'Softer response near the centre for fine control: {pct} %.'**
  String padExpoDesc(int pct);

  /// No description provided for @padResetMapping.
  ///
  /// In en, this message translates to:
  /// **'Reset mapping'**
  String get padResetMapping;

  /// No description provided for @padResetMappingDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard layout: left stick throttle and yaw, right stick pitch and roll, B / Circle for STOP.'**
  String get padResetMappingDesc;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting…'**
  String get waiting;

  /// No description provided for @invertDirection.
  ///
  /// In en, this message translates to:
  /// **'Invert direction'**
  String get invertDirection;

  /// No description provided for @inverted.
  ///
  /// In en, this message translates to:
  /// **'Inverted'**
  String get inverted;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @clearName.
  ///
  /// In en, this message translates to:
  /// **'Clear {name}'**
  String clearName(String name);

  /// No description provided for @padDrives.
  ///
  /// In en, this message translates to:
  /// **'{pad} drives {device}'**
  String padDrives(String pad, String device);

  /// No description provided for @padArmToDrive.
  ///
  /// In en, this message translates to:
  /// **'Arm to drive with {pad}; its buttons already work'**
  String padArmToDrive(String pad);

  /// No description provided for @padButtonsWork.
  ///
  /// In en, this message translates to:
  /// **'Buttons work; sticks drive drones and ground robots'**
  String get padButtonsWork;

  /// No description provided for @pad.
  ///
  /// In en, this message translates to:
  /// **'Pad'**
  String get pad;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @aiLet.
  ///
  /// In en, this message translates to:
  /// **'Let assistants use koebelt dash'**
  String get aiLet;

  /// No description provided for @aiLetDesc.
  ///
  /// In en, this message translates to:
  /// **'Claude, Codex, OpenCode, Cursor and other MCP clients can read the docs, write scripts, use the app and, with your approval, act on devices. dash itself sends nothing to any AI service; the assistant you connect talks to its own provider.'**
  String get aiLetDesc;

  /// No description provided for @aiConnectClient.
  ///
  /// In en, this message translates to:
  /// **'Connect a client'**
  String get aiConnectClient;

  /// No description provided for @aiPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste this into the assistant’s setup.'**
  String get aiPaste;

  /// No description provided for @aiRemotePhone.
  ///
  /// In en, this message translates to:
  /// **'Assistants run on a computer: they reach this phone over the network, with its token.'**
  String get aiRemotePhone;

  /// No description provided for @aiRemoteTablet.
  ///
  /// In en, this message translates to:
  /// **'Assistants run on a computer: they reach this tablet over the network, with its token.'**
  String get aiRemoteTablet;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @aiConnectedNow.
  ///
  /// In en, this message translates to:
  /// **'Connected now'**
  String get aiConnectedNow;

  /// No description provided for @aiNone.
  ///
  /// In en, this message translates to:
  /// **'No assistant in the last ten minutes.'**
  String get aiNone;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 action} other{{count} actions}}'**
  String actions(int count);

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @aiAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed without asking'**
  String get aiAllowed;

  /// No description provided for @aiAllowedNone.
  ///
  /// In en, this message translates to:
  /// **'Simulated devices and replays never ask. On real hardware, every action asks unless you allow it for the session. Arming and take-off always ask.'**
  String get aiAllowedNone;

  /// No description provided for @aiAllowedSome.
  ///
  /// In en, this message translates to:
  /// **'For this session: {actions}. Arming and take-off always ask.'**
  String aiAllowedSome(String actions);

  /// No description provided for @aiFromNetwork.
  ///
  /// In en, this message translates to:
  /// **'From this network'**
  String get aiFromNetwork;

  /// No description provided for @aiFromNetworkOn.
  ///
  /// In en, this message translates to:
  /// **'Assistants on other computers: {url} with the token {token}… (copy it from the Other tab).'**
  String aiFromNetworkOn(String url, String token);

  /// No description provided for @aiFromNetworkOff.
  ///
  /// In en, this message translates to:
  /// **'Let an assistant on another computer use this dash, with a token.'**
  String get aiFromNetworkOff;

  /// No description provided for @aiActivity.
  ///
  /// In en, this message translates to:
  /// **'Assistant activity'**
  String get aiActivity;

  /// No description provided for @nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet.'**
  String get nothingYet;

  /// No description provided for @aiShort.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiShort;

  /// No description provided for @aiAsks.
  ///
  /// In en, this message translates to:
  /// **'{client} asks'**
  String aiAsks(String client);

  /// No description provided for @aiRealHardware.
  ///
  /// In en, this message translates to:
  /// **'{device} is real hardware.'**
  String aiRealHardware(String device);

  /// No description provided for @aiAllowSession.
  ///
  /// In en, this message translates to:
  /// **'Allow this kind of action on {device} for this session'**
  String aiAllowSession(String device);

  /// No description provided for @refuse.
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get refuse;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @recordingsAndLogs.
  ///
  /// In en, this message translates to:
  /// **'Recordings and flight logs'**
  String get recordingsAndLogs;

  /// No description provided for @fileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read: {error}'**
  String fileUnreadable(String error);

  /// No description provided for @fromFile.
  ///
  /// In en, this message translates to:
  /// **'From a file'**
  String get fromFile;

  /// No description provided for @fromFileDesc.
  ///
  /// In en, this message translates to:
  /// **'Opens as a session: replay, the map, the charts and export all work on it.'**
  String get fromFileDesc;

  /// No description provided for @fmtJson.
  ///
  /// In en, this message translates to:
  /// **'A recording exported from koebelt/dash'**
  String get fmtJson;

  /// No description provided for @fmtBin.
  ///
  /// In en, this message translates to:
  /// **'ArduPilot log, from the SD card or Mission Planner'**
  String get fmtBin;

  /// No description provided for @fmtTlog.
  ///
  /// In en, this message translates to:
  /// **'Ground station log: Mission Planner, QGroundControl, MAVProxy'**
  String get fmtTlog;

  /// No description provided for @fmtUlg.
  ///
  /// In en, this message translates to:
  /// **'PX4 log, from the SD card or QGroundControl'**
  String get fmtUlg;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading {file}…'**
  String reading(String file);

  /// No description provided for @stopRecordingFirst.
  ///
  /// In en, this message translates to:
  /// **'Stop the recording first'**
  String get stopRecordingFirst;

  /// No description provided for @notImported.
  ///
  /// In en, this message translates to:
  /// **'Not imported'**
  String get notImported;

  /// No description provided for @sampleRecordings.
  ///
  /// In en, this message translates to:
  /// **'Sample recordings'**
  String get sampleRecordings;

  /// No description provided for @samplesIn.
  ///
  /// In en, this message translates to:
  /// **'The three demo sessions are in your list, marked Demo.'**
  String get samplesIn;

  /// No description provided for @samplesDesc.
  ///
  /// In en, this message translates to:
  /// **'Three demo sessions recorded with the simulated devices: a survey flight, a pick and place, a rocket launch.'**
  String get samplesDesc;

  /// No description provided for @removeSamples.
  ///
  /// In en, this message translates to:
  /// **'Remove samples'**
  String get removeSamples;

  /// No description provided for @loadSamples.
  ///
  /// In en, this message translates to:
  /// **'Load samples'**
  String get loadSamples;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exporting;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export {format}'**
  String exportFormat(String format);

  /// No description provided for @frames.
  ///
  /// In en, this message translates to:
  /// **'{count} frames'**
  String frames(int count);

  /// No description provided for @csvColumns.
  ///
  /// In en, this message translates to:
  /// **'{count} columns · only channels this device sent'**
  String csvColumns(int count);

  /// No description provided for @noGpx.
  ///
  /// In en, this message translates to:
  /// **'No GPS in this recording, so no GPX track'**
  String get noGpx;

  /// No description provided for @encoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding {format} · {pct}%'**
  String encoding(String format, int pct);

  /// No description provided for @exported.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exported;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @was.
  ///
  /// In en, this message translates to:
  /// **'was {value}'**
  String was(String value);

  /// No description provided for @firmware.
  ///
  /// In en, this message translates to:
  /// **'firmware {version}'**
  String firmware(String version);

  /// No description provided for @parametersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 parameter} other{{count} parameters}}'**
  String parametersCount(int count);

  /// No description provided for @parameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parameters;

  /// No description provided for @unsaved.
  ///
  /// In en, this message translates to:
  /// **'{count} unsaved'**
  String unsaved(int count);

  /// No description provided for @written.
  ///
  /// In en, this message translates to:
  /// **'Written {when}'**
  String written(String when);

  /// No description provided for @inSync.
  ///
  /// In en, this message translates to:
  /// **'In sync'**
  String get inSync;

  /// No description provided for @revert.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get revert;

  /// No description provided for @writing.
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get writing;

  /// No description provided for @writeToDevice.
  ///
  /// In en, this message translates to:
  /// **'Write to device'**
  String get writeToDevice;

  /// No description provided for @searchParameters.
  ///
  /// In en, this message translates to:
  /// **'Search parameters'**
  String get searchParameters;

  /// No description provided for @waitingParams.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the parameter table…'**
  String get waitingParams;

  /// No description provided for @noParamsMatch.
  ///
  /// In en, this message translates to:
  /// **'No parameters match “{query}”'**
  String noParamsMatch(String query);

  /// No description provided for @revertName.
  ///
  /// In en, this message translates to:
  /// **'Revert {name}'**
  String revertName(String name);

  /// No description provided for @liveResponse.
  ///
  /// In en, this message translates to:
  /// **'Live response'**
  String get liveResponse;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @yourPairingCode.
  ///
  /// In en, this message translates to:
  /// **'Your pairing code · valid 10 min'**
  String get yourPairingCode;

  /// No description provided for @namePaired.
  ///
  /// In en, this message translates to:
  /// **'{name} paired'**
  String namePaired(String name);

  /// No description provided for @startListening.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get startListening;

  /// No description provided for @listeningWifiBle.
  ///
  /// In en, this message translates to:
  /// **'Listening on Wi-Fi and BLE · power on your device'**
  String get listeningWifiBle;

  /// No description provided for @nameFound.
  ///
  /// In en, this message translates to:
  /// **'{name} found'**
  String nameFound(String name);

  /// No description provided for @sensorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sensor} other{{count} sensors}}'**
  String sensorsCount(int count);

  /// No description provided for @addToDevices.
  ///
  /// In en, this message translates to:
  /// **'Add to devices'**
  String get addToDevices;

  /// No description provided for @connectNow.
  ///
  /// In en, this message translates to:
  /// **'Connect now'**
  String get connectNow;

  /// No description provided for @inTheApp.
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get inTheApp;

  /// No description provided for @completeProgram.
  ///
  /// In en, this message translates to:
  /// **'Complete program'**
  String get completeProgram;

  /// No description provided for @apiReference.
  ///
  /// In en, this message translates to:
  /// **'API reference'**
  String get apiReference;

  /// No description provided for @exampleProjects.
  ///
  /// In en, this message translates to:
  /// **'Example projects'**
  String get exampleProjects;

  /// No description provided for @allGuides.
  ///
  /// In en, this message translates to:
  /// **'All guides'**
  String get allGuides;

  /// No description provided for @stepOfUpper.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String stepOfUpper(int n, int total);

  /// No description provided for @flowDevice.
  ///
  /// In en, this message translates to:
  /// **'Your device'**
  String get flowDevice;

  /// No description provided for @flowDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Sensors, motors and koebelt/link on the board or companion computer.'**
  String get flowDeviceDesc;

  /// No description provided for @flowLinkDesc.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi, BLE, USB serial or a radio, with a fallback link if one drops.'**
  String get flowLinkDesc;

  /// No description provided for @flowDashDesc.
  ///
  /// In en, this message translates to:
  /// **'Dashboards, control, tuning and recording, on phone, tablet or desktop.'**
  String get flowDashDesc;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'library'**
  String get library;

  /// No description provided for @connectHardware.
  ///
  /// In en, this message translates to:
  /// **'Connect your hardware'**
  String get connectHardware;

  /// No description provided for @connectHardwareDesc.
  ///
  /// In en, this message translates to:
  /// **'Your device runs a small library that streams sensors to this app and receives control input. Pick your platform to start.'**
  String get connectHardwareDesc;

  /// No description provided for @guidesConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get guidesConnections;

  /// No description provided for @guidesConnectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'How each link works, and what to do when a device does not show up.'**
  String get guidesConnectionsDesc;

  /// No description provided for @guidesDevices.
  ///
  /// In en, this message translates to:
  /// **'Device examples'**
  String get guidesDevices;

  /// No description provided for @guidesDevicesDesc.
  ///
  /// In en, this message translates to:
  /// **'A complete, commented program for each kind of device.'**
  String get guidesDevicesDesc;

  /// No description provided for @guidesFeatures.
  ///
  /// In en, this message translates to:
  /// **'Video, map and controllers'**
  String get guidesFeatures;

  /// No description provided for @guidesFeaturesDesc.
  ///
  /// In en, this message translates to:
  /// **'Show a camera, put the device on a map, drive with a gamepad.'**
  String get guidesFeaturesDesc;

  /// No description provided for @guidesMore.
  ///
  /// In en, this message translates to:
  /// **'Going further'**
  String get guidesMore;

  /// No description provided for @guidesMoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Custom data, tuning, sequences and safety.'**
  String get guidesMoreDesc;

  /// No description provided for @viewChase.
  ///
  /// In en, this message translates to:
  /// **'CHASE'**
  String get viewChase;

  /// No description provided for @viewOrbit.
  ///
  /// In en, this message translates to:
  /// **'ORBIT'**
  String get viewOrbit;

  /// No description provided for @viewTop.
  ///
  /// In en, this message translates to:
  /// **'TOP'**
  String get viewTop;

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'MAP'**
  String get viewMap;

  /// No description provided for @viewCam.
  ///
  /// In en, this message translates to:
  /// **'CAM'**
  String get viewCam;

  /// No description provided for @noMapboxToken.
  ///
  /// In en, this message translates to:
  /// **'This build has no Mapbox token: enter your own below, or choose another source.'**
  String get noMapboxToken;

  /// No description provided for @waitingGps.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a GPS fix'**
  String get waitingGps;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @waitingScript.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the script'**
  String get waitingScript;

  /// No description provided for @scriptEnded.
  ///
  /// In en, this message translates to:
  /// **'Script ended'**
  String get scriptEnded;

  /// No description provided for @noVideo.
  ///
  /// In en, this message translates to:
  /// **'This recording has no video.'**
  String get noVideo;

  /// No description provided for @noCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera. Devices declare cameras with video() in the library.'**
  String get noCamera;

  /// No description provided for @cameraByIp.
  ///
  /// In en, this message translates to:
  /// **'This camera is reached by IP address. Connect to {name} over Wi-Fi to see it.'**
  String cameraByIp(String name);

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @alBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery low'**
  String get alBattery;

  /// No description provided for @alBatteryDesc.
  ///
  /// In en, this message translates to:
  /// **'Charge left, as the device reports it.'**
  String get alBatteryDesc;

  /// No description provided for @alBatteryAct.
  ///
  /// In en, this message translates to:
  /// **'Time to bring it back.'**
  String get alBatteryAct;

  /// No description provided for @alBatteryCritical.
  ///
  /// In en, this message translates to:
  /// **'Battery critical'**
  String get alBatteryCritical;

  /// No description provided for @alBatteryCriticalDesc.
  ///
  /// In en, this message translates to:
  /// **'A second, louder limit: repeats until acknowledged.'**
  String get alBatteryCriticalDesc;

  /// No description provided for @alBatteryCriticalAct.
  ///
  /// In en, this message translates to:
  /// **'Land or stop now.'**
  String get alBatteryCriticalAct;

  /// No description provided for @alVoltage.
  ///
  /// In en, this message translates to:
  /// **'Battery voltage'**
  String get alVoltage;

  /// No description provided for @alVoltageDesc.
  ///
  /// In en, this message translates to:
  /// **'For packs that do not report a percentage. Set the limit for your pack, for example 3.5 V per cell.'**
  String get alVoltageDesc;

  /// No description provided for @alVoltageAct.
  ///
  /// In en, this message translates to:
  /// **'Time to bring it back.'**
  String get alVoltageAct;

  /// No description provided for @alObstacle.
  ///
  /// In en, this message translates to:
  /// **'Obstacle close'**
  String get alObstacle;

  /// No description provided for @alObstacleDesc.
  ///
  /// In en, this message translates to:
  /// **'The nearest thing a proximity sensor sees, while armed (sensors looking down do not count).'**
  String get alObstacleDesc;

  /// No description provided for @alObstacleAct.
  ///
  /// In en, this message translates to:
  /// **'Steer away, or stop.'**
  String get alObstacleAct;

  /// No description provided for @alRssi.
  ///
  /// In en, this message translates to:
  /// **'Weak signal'**
  String get alRssi;

  /// No description provided for @alRssiDesc.
  ///
  /// In en, this message translates to:
  /// **'Received signal strength, when the link reports it.'**
  String get alRssiDesc;

  /// No description provided for @alRssiAct.
  ///
  /// In en, this message translates to:
  /// **'Move closer or turn back.'**
  String get alRssiAct;

  /// No description provided for @alLatency.
  ///
  /// In en, this message translates to:
  /// **'High latency'**
  String get alLatency;

  /// No description provided for @alLatencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Round trip of the link. Control feels late above a few hundred milliseconds.'**
  String get alLatencyDesc;

  /// No description provided for @alLatencyAct.
  ///
  /// In en, this message translates to:
  /// **'Control will feel late.'**
  String get alLatencyAct;

  /// No description provided for @alAltitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude ceiling'**
  String get alAltitude;

  /// No description provided for @alAltitudeDesc.
  ///
  /// In en, this message translates to:
  /// **'Height above home. 120 m is the usual limit for drones in Europe and the US.'**
  String get alAltitudeDesc;

  /// No description provided for @alAltitudeAct.
  ///
  /// In en, this message translates to:
  /// **'Descend.'**
  String get alAltitudeAct;

  /// No description provided for @alDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance from home'**
  String get alDistance;

  /// No description provided for @alDistanceDesc.
  ///
  /// In en, this message translates to:
  /// **'A simple geofence: horizontal distance from where it started.'**
  String get alDistanceDesc;

  /// No description provided for @alDistanceAct.
  ///
  /// In en, this message translates to:
  /// **'Bring it closer.'**
  String get alDistanceAct;

  /// No description provided for @alTemp.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get alTemp;

  /// No description provided for @alTempDesc.
  ///
  /// In en, this message translates to:
  /// **'Motor, ESC or board temperature, when the device reports one.'**
  String get alTempDesc;

  /// No description provided for @alTempAct.
  ///
  /// In en, this message translates to:
  /// **'Let it cool down.'**
  String get alTempAct;

  /// No description provided for @kindDrone.
  ///
  /// In en, this message translates to:
  /// **'Drone'**
  String get kindDrone;

  /// No description provided for @kindRover.
  ///
  /// In en, this message translates to:
  /// **'Ground robot'**
  String get kindRover;

  /// No description provided for @kindArm.
  ///
  /// In en, this message translates to:
  /// **'Robot arm'**
  String get kindArm;

  /// No description provided for @kindRocket.
  ///
  /// In en, this message translates to:
  /// **'Rocket'**
  String get kindRocket;

  /// No description provided for @kindBench.
  ///
  /// In en, this message translates to:
  /// **'Test bench'**
  String get kindBench;

  /// No description provided for @kindGeneric.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get kindGeneric;

  /// No description provided for @stTakeoff.
  ///
  /// In en, this message translates to:
  /// **'Take off'**
  String get stTakeoff;

  /// No description provided for @stFlyTo.
  ///
  /// In en, this message translates to:
  /// **'Fly to'**
  String get stFlyTo;

  /// No description provided for @stLand.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get stLand;

  /// No description provided for @stRth.
  ///
  /// In en, this message translates to:
  /// **'Return home'**
  String get stRth;

  /// No description provided for @stDriveTo.
  ///
  /// In en, this message translates to:
  /// **'Drive to'**
  String get stDriveTo;

  /// No description provided for @stPose.
  ///
  /// In en, this message translates to:
  /// **'Move to pose'**
  String get stPose;

  /// No description provided for @stRamp.
  ///
  /// In en, this message translates to:
  /// **'Ramp'**
  String get stRamp;

  /// No description provided for @stWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get stWait;

  /// No description provided for @stMode.
  ///
  /// In en, this message translates to:
  /// **'Set mode'**
  String get stMode;

  /// No description provided for @stArm.
  ///
  /// In en, this message translates to:
  /// **'Arm / disarm'**
  String get stArm;

  /// No description provided for @stCmd.
  ///
  /// In en, this message translates to:
  /// **'Custom command'**
  String get stCmd;

  /// No description provided for @fEast.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get fEast;

  /// No description provided for @fNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get fNorth;

  /// No description provided for @fHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get fHold;

  /// No description provided for @fFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fFrom;

  /// No description provided for @fTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get fTo;

  /// No description provided for @fOver.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get fOver;

  /// No description provided for @fDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get fDuration;

  /// No description provided for @fMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get fMode;

  /// No description provided for @fState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get fState;

  /// No description provided for @fLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get fLimit;

  /// No description provided for @fCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get fCommand;

  /// No description provided for @fValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get fValue;

  /// No description provided for @sumTakeoff.
  ///
  /// In en, this message translates to:
  /// **'Take off to {alt} m'**
  String sumTakeoff(String alt);

  /// No description provided for @sumFlyTo.
  ///
  /// In en, this message translates to:
  /// **'Fly to {x}, {y} m at {z} m'**
  String sumFlyTo(String x, String y, String z);

  /// No description provided for @sumDriveTo.
  ///
  /// In en, this message translates to:
  /// **'Drive to {x}, {y} m'**
  String sumDriveTo(String x, String y);

  /// No description provided for @sumRth.
  ///
  /// In en, this message translates to:
  /// **'Return home and land'**
  String get sumRth;

  /// No description provided for @sumPose.
  ///
  /// In en, this message translates to:
  /// **'Move to pose {joints}°'**
  String sumPose(String joints);

  /// No description provided for @sumGripper.
  ///
  /// In en, this message translates to:
  /// **'Gripper {pct}% open'**
  String sumGripper(String pct);

  /// No description provided for @sumThrottle.
  ///
  /// In en, this message translates to:
  /// **'Throttle {pct}% for {s} s'**
  String sumThrottle(String pct, String s);

  /// No description provided for @sumRamp.
  ///
  /// In en, this message translates to:
  /// **'Ramp {from} to {to}% over {s} s'**
  String sumRamp(String from, String to, String s);

  /// No description provided for @sumWait.
  ///
  /// In en, this message translates to:
  /// **'Wait {s} s'**
  String sumWait(String s);

  /// No description provided for @sumMode.
  ///
  /// In en, this message translates to:
  /// **'Mode {mode}'**
  String sumMode(String mode);

  /// No description provided for @sumArm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get sumArm;

  /// No description provided for @sumDisarm.
  ///
  /// In en, this message translates to:
  /// **'Disarm'**
  String get sumDisarm;

  /// No description provided for @sumSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed limit {pct}%'**
  String sumSpeed(String pct);

  /// No description provided for @sumCmd.
  ///
  /// In en, this message translates to:
  /// **'Command {name} = {value}'**
  String sumCmd(String name, String value);

  /// No description provided for @stoppedEstop.
  ///
  /// In en, this message translates to:
  /// **'Stopped: emergency stop'**
  String get stoppedEstop;

  /// No description provided for @completedIn.
  ///
  /// In en, this message translates to:
  /// **'Completed in {seconds} s'**
  String completedIn(String seconds);

  /// No description provided for @stepTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Step {n} timed out: {step}'**
  String stepTimedOut(int n, String step);

  /// No description provided for @metresToGo.
  ///
  /// In en, this message translates to:
  /// **'{metres} m to go'**
  String metresToGo(String metres);

  /// No description provided for @uploadingToDevice.
  ///
  /// In en, this message translates to:
  /// **'Uploading to the device'**
  String get uploadingToDevice;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get starting;

  /// No description provided for @completedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Completed on the device'**
  String get completedOnDevice;

  /// No description provided for @deviceRejected.
  ///
  /// In en, this message translates to:
  /// **'The device did not accept the sequence'**
  String get deviceRejected;

  /// No description provided for @linkLostCarriesOn.
  ///
  /// In en, this message translates to:
  /// **'Link lost · the device carries on'**
  String get linkLostCarriesOn;

  /// No description provided for @stoppedDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Stopped: disconnected'**
  String get stoppedDisconnected;

  /// No description provided for @stoppedTookControl.
  ///
  /// In en, this message translates to:
  /// **'Stopped: you took control'**
  String get stoppedTookControl;

  /// No description provided for @stoppedManual.
  ///
  /// In en, this message translates to:
  /// **'Stopped: manual control'**
  String get stoppedManual;

  /// No description provided for @stoppedByScript.
  ///
  /// In en, this message translates to:
  /// **'Stopped by the script'**
  String get stoppedByScript;

  /// No description provided for @reqAnyDevice.
  ///
  /// In en, this message translates to:
  /// **'a device'**
  String get reqAnyDevice;

  /// No description provided for @reqKinds.
  ///
  /// In en, this message translates to:
  /// **'a {kinds}'**
  String reqKinds(String kinds);

  /// No description provided for @reqWith.
  ///
  /// In en, this message translates to:
  /// **'{kinds} with {needs}'**
  String reqWith(String kinds, String needs);

  /// No description provided for @reqWrongKind.
  ///
  /// In en, this message translates to:
  /// **'{name} is a {kind}; this script needs {needs}.'**
  String reqWrongKind(String name, String kind, String needs);

  /// No description provided for @reqLacks.
  ///
  /// In en, this message translates to:
  /// **'{name} has no {lacks}; this script needs {needs}.'**
  String reqLacks(String name, String lacks, String needs);

  /// No description provided for @trgButton.
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get trgButton;

  /// No description provided for @trgSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get trgSwitch;

  /// No description provided for @trgSlider.
  ///
  /// In en, this message translates to:
  /// **'Slider'**
  String get trgSlider;

  /// No description provided for @trgController.
  ///
  /// In en, this message translates to:
  /// **'Controller'**
  String get trgController;

  /// No description provided for @trgCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get trgCondition;

  /// No description provided for @trgEvent.
  ///
  /// In en, this message translates to:
  /// **'Device event'**
  String get trgEvent;

  /// No description provided for @trgTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get trgTimer;

  /// No description provided for @evMode.
  ///
  /// In en, this message translates to:
  /// **'Mode changes'**
  String get evMode;

  /// No description provided for @evFailsafe.
  ///
  /// In en, this message translates to:
  /// **'Failsafe'**
  String get evFailsafe;

  /// No description provided for @evSeqDone.
  ///
  /// In en, this message translates to:
  /// **'Sequence finished'**
  String get evSeqDone;

  /// No description provided for @evLog.
  ///
  /// In en, this message translates to:
  /// **'Device message'**
  String get evLog;

  /// No description provided for @onControl.
  ///
  /// In en, this message translates to:
  /// **'on Control'**
  String get onControl;

  /// No description provided for @everyN.
  ///
  /// In en, this message translates to:
  /// **'Every {seconds} s'**
  String everyN(String seconds);

  /// No description provided for @onceAfterN.
  ///
  /// In en, this message translates to:
  /// **'Once after {seconds} s'**
  String onceAfterN(String seconds);

  /// No description provided for @paArm.
  ///
  /// In en, this message translates to:
  /// **'Arm / disarm'**
  String get paArm;

  /// No description provided for @paManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get paManual;

  /// No description provided for @paHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get paHold;

  /// No description provided for @paAuto.
  ///
  /// In en, this message translates to:
  /// **'Back to the script'**
  String get paAuto;

  /// No description provided for @paSlower.
  ///
  /// In en, this message translates to:
  /// **'Speed down'**
  String get paSlower;

  /// No description provided for @paFaster.
  ///
  /// In en, this message translates to:
  /// **'Speed up'**
  String get paFaster;

  /// No description provided for @paFrame.
  ///
  /// In en, this message translates to:
  /// **'Joint / Cartesian'**
  String get paFrame;

  /// No description provided for @paWrist.
  ///
  /// In en, this message translates to:
  /// **'Wrist'**
  String get paWrist;

  /// No description provided for @paNext.
  ///
  /// In en, this message translates to:
  /// **'Next device'**
  String get paNext;

  /// No description provided for @paStopHint.
  ///
  /// In en, this message translates to:
  /// **'Emergency stop, immediately'**
  String get paStopHint;

  /// No description provided for @paHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Hold for one second'**
  String get paHoldHint;

  /// No description provided for @paSwitchTo.
  ///
  /// In en, this message translates to:
  /// **'Switch to {mode}'**
  String paSwitchTo(String mode);

  /// No description provided for @paAutoHint.
  ///
  /// In en, this message translates to:
  /// **'After taking over, give the sticks back to the script (AUTO)'**
  String get paAutoHint;

  /// No description provided for @paSwitchToDrones.
  ///
  /// In en, this message translates to:
  /// **'Switch to {mode} (drones)'**
  String paSwitchToDrones(String mode);

  /// No description provided for @paHoldDronesHint.
  ///
  /// In en, this message translates to:
  /// **'Hold for one second (drones)'**
  String get paHoldDronesHint;

  /// No description provided for @paRecordHint.
  ///
  /// In en, this message translates to:
  /// **'Start or stop a recording'**
  String get paRecordHint;

  /// No description provided for @paSlowerHint.
  ///
  /// In en, this message translates to:
  /// **'Lower the speed limit 10 %'**
  String get paSlowerHint;

  /// No description provided for @paFasterHint.
  ///
  /// In en, this message translates to:
  /// **'Raise the speed limit 10 %'**
  String get paFasterHint;

  /// No description provided for @paFrameHint.
  ///
  /// In en, this message translates to:
  /// **'Arms: what the sticks move'**
  String get paFrameHint;

  /// No description provided for @paWristHint.
  ///
  /// In en, this message translates to:
  /// **'Arms: right stick moves J5 and J6 instead of J3 and J4'**
  String get paWristHint;

  /// No description provided for @paGripperHint.
  ///
  /// In en, this message translates to:
  /// **'Arms: open or close'**
  String get paGripperHint;

  /// No description provided for @paNextHint.
  ///
  /// In en, this message translates to:
  /// **'Several connected: show and drive the next one'**
  String get paNextHint;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @padLeftStickX.
  ///
  /// In en, this message translates to:
  /// **'Left stick X'**
  String get padLeftStickX;

  /// No description provided for @padLeftStickY.
  ///
  /// In en, this message translates to:
  /// **'Left stick Y'**
  String get padLeftStickY;

  /// No description provided for @padRightStickX.
  ///
  /// In en, this message translates to:
  /// **'Right stick X'**
  String get padRightStickX;

  /// No description provided for @padRightStickY.
  ///
  /// In en, this message translates to:
  /// **'Right stick Y'**
  String get padRightStickY;

  /// No description provided for @padLeftTrigger.
  ///
  /// In en, this message translates to:
  /// **'Left trigger'**
  String get padLeftTrigger;

  /// No description provided for @padRightTrigger.
  ///
  /// In en, this message translates to:
  /// **'Right trigger'**
  String get padRightTrigger;

  /// No description provided for @padACross.
  ///
  /// In en, this message translates to:
  /// **'A / Cross'**
  String get padACross;

  /// No description provided for @padBCircle.
  ///
  /// In en, this message translates to:
  /// **'B / Circle'**
  String get padBCircle;

  /// No description provided for @padXSquare.
  ///
  /// In en, this message translates to:
  /// **'X / Square'**
  String get padXSquare;

  /// No description provided for @padYTriangle.
  ///
  /// In en, this message translates to:
  /// **'Y / Triangle'**
  String get padYTriangle;

  /// No description provided for @padLeftBumper.
  ///
  /// In en, this message translates to:
  /// **'Left bumper'**
  String get padLeftBumper;

  /// No description provided for @padRightBumper.
  ///
  /// In en, this message translates to:
  /// **'Right bumper'**
  String get padRightBumper;

  /// No description provided for @padBackShare.
  ///
  /// In en, this message translates to:
  /// **'Back / Share'**
  String get padBackShare;

  /// No description provided for @padStartOptions.
  ///
  /// In en, this message translates to:
  /// **'Start / Options'**
  String get padStartOptions;

  /// No description provided for @padHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get padHome;

  /// No description provided for @padLeftStickPress.
  ///
  /// In en, this message translates to:
  /// **'Left stick press'**
  String get padLeftStickPress;

  /// No description provided for @padRightStickPress.
  ///
  /// In en, this message translates to:
  /// **'Right stick press'**
  String get padRightStickPress;

  /// No description provided for @padDPadUp.
  ///
  /// In en, this message translates to:
  /// **'D-pad up'**
  String get padDPadUp;

  /// No description provided for @padDPadDown.
  ///
  /// In en, this message translates to:
  /// **'D-pad down'**
  String get padDPadDown;

  /// No description provided for @padDPadLeft.
  ///
  /// In en, this message translates to:
  /// **'D-pad left'**
  String get padDPadLeft;

  /// No description provided for @padDPadRight.
  ///
  /// In en, this message translates to:
  /// **'D-pad right'**
  String get padDPadRight;

  /// No description provided for @radioSik.
  ///
  /// In en, this message translates to:
  /// **'SiK telemetry radio'**
  String get radioSik;

  /// No description provided for @radioLoraName.
  ///
  /// In en, this message translates to:
  /// **'LoRa ground station'**
  String get radioLoraName;

  /// No description provided for @radioOther.
  ///
  /// In en, this message translates to:
  /// **'Other serial radio'**
  String get radioOther;

  /// No description provided for @radioSikDesc.
  ///
  /// In en, this message translates to:
  /// **'433 / 868 / 915 MHz pairs: 3DR, Holybro, RFD900. Transparent serial up to about 1 km, 40 km for RFD900.'**
  String get radioSikDesc;

  /// No description provided for @radioLoraDesc.
  ///
  /// In en, this message translates to:
  /// **'A board with a LoRa radio on USB, flashed with the ground-station sketch. 2 to 10 km, telemetry only.'**
  String get radioLoraDesc;

  /// No description provided for @radioHc12Desc.
  ///
  /// In en, this message translates to:
  /// **'Cheap transparent serial module on a USB adapter. About 1 km at 9600 baud.'**
  String get radioHc12Desc;

  /// No description provided for @radioXbeeDesc.
  ///
  /// In en, this message translates to:
  /// **'Digi XBee in transparent mode on a USB explorer board. 2.4 GHz or 900 MHz.'**
  String get radioXbeeDesc;

  /// No description provided for @radioOtherDesc.
  ///
  /// In en, this message translates to:
  /// **'Any transparent serial radio. Set its baud rate; the app uses conservative rates.'**
  String get radioOtherDesc;

  /// No description provided for @tplLoop.
  ///
  /// In en, this message translates to:
  /// **'A control loop'**
  String get tplLoop;

  /// No description provided for @tplButton.
  ///
  /// In en, this message translates to:
  /// **'A button action'**
  String get tplButton;

  /// No description provided for @fldBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get fldBattery;

  /// No description provided for @fldBatteryVoltage.
  ///
  /// In en, this message translates to:
  /// **'Battery voltage'**
  String get fldBatteryVoltage;

  /// No description provided for @fldDistanceFromHome.
  ///
  /// In en, this message translates to:
  /// **'Distance from home'**
  String get fldDistanceFromHome;

  /// No description provided for @fldHeightAboveHome.
  ///
  /// In en, this message translates to:
  /// **'Height above home'**
  String get fldHeightAboveHome;

  /// No description provided for @fldSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get fldSpeed;

  /// No description provided for @fldHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get fldHeading;

  /// No description provided for @fldRoll.
  ///
  /// In en, this message translates to:
  /// **'Roll'**
  String get fldRoll;

  /// No description provided for @fldPitch.
  ///
  /// In en, this message translates to:
  /// **'Pitch'**
  String get fldPitch;

  /// No description provided for @fldGripper.
  ///
  /// In en, this message translates to:
  /// **'Gripper'**
  String get fldGripper;

  /// No description provided for @fldThrust.
  ///
  /// In en, this message translates to:
  /// **'Thrust'**
  String get fldThrust;

  /// No description provided for @fldRpm.
  ///
  /// In en, this message translates to:
  /// **'RPM'**
  String get fldRpm;

  /// No description provided for @fldTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get fldTemperature;

  /// No description provided for @fldNearestObstacle.
  ///
  /// In en, this message translates to:
  /// **'Nearest obstacle'**
  String get fldNearestObstacle;

  /// No description provided for @fldSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get fldSignal;

  /// No description provided for @fldLatency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get fldLatency;

  /// No description provided for @fldGpsSatellites.
  ///
  /// In en, this message translates to:
  /// **'GPS satellites'**
  String get fldGpsSatellites;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready.'**
  String get ready;

  /// No description provided for @pythonManaged.
  ///
  /// In en, this message translates to:
  /// **'This Python is managed by the system and refuses packages: use a scripts environment instead.'**
  String get pythonManaged;

  /// No description provided for @failedWhy.
  ///
  /// In en, this message translates to:
  /// **'Failed: {why}'**
  String failedWhy(String why);

  /// No description provided for @pipNoPackage.
  ///
  /// In en, this message translates to:
  /// **'pip finished, but koebelt-dash-scripts is still not in this Python.'**
  String get pipNoPackage;

  /// No description provided for @packageUpToDate.
  ///
  /// In en, this message translates to:
  /// **'koebelt-dash-scripts {version} is up to date in this Python.'**
  String packageUpToDate(String version);

  /// No description provided for @packageInstalled.
  ///
  /// In en, this message translates to:
  /// **'koebelt-dash-scripts {version} is installed in this Python.'**
  String packageInstalled(String version);

  /// No description provided for @packagesInstalled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{names} is installed in this Python.} other{{names} are installed in this Python.}}'**
  String packagesInstalled(int count, String names);

  /// No description provided for @envReady.
  ///
  /// In en, this message translates to:
  /// **'The scripts environment is ready, with koebelt-dash-scripts {version}.'**
  String envReady(String version);

  /// No description provided for @atMostDevices.
  ///
  /// In en, this message translates to:
  /// **'At most {count} devices at once. Disconnect one first.'**
  String atMostDevices(int count);

  /// No description provided for @noAnswerFrom.
  ///
  /// In en, this message translates to:
  /// **'No answer from {name}'**
  String noAnswerFrom(String name);

  /// No description provided for @noHostAt.
  ///
  /// In en, this message translates to:
  /// **'No script host at {address}. Is `koebelt-dash-scripts host` running there?'**
  String noHostAt(String address);

  /// No description provided for @hostRefused.
  ///
  /// In en, this message translates to:
  /// **'The host refused.'**
  String get hostRefused;

  /// No description provided for @logUnknown.
  ///
  /// In en, this message translates to:
  /// **'This file is not a log the app can read. It opens koebelt/dash JSON exports, ArduPilot .bin and .tlog logs, and PX4 .ulg logs.'**
  String get logUnknown;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'The {format} file has no telemetry the app can show (attitude, position, battery).'**
  String logEmpty(String format);

  /// No description provided for @logJsonUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This JSON file could not be read.'**
  String get logJsonUnreadable;

  /// No description provided for @logJsonNotExport.
  ///
  /// In en, this message translates to:
  /// **'This JSON file is not a koebelt/dash recording export.'**
  String get logJsonNotExport;

  /// No description provided for @logNoHeartbeat.
  ///
  /// In en, this message translates to:
  /// **'This .tlog has no vehicle heartbeat, so its messages cannot be attributed to a vehicle.'**
  String get logNoHeartbeat;

  /// No description provided for @viewDevices.
  ///
  /// In en, this message translates to:
  /// **'View devices'**
  String get viewDevices;

  /// No description provided for @simulatedTip.
  ///
  /// In en, this message translates to:
  /// **'Simulated in the app, not real hardware'**
  String get simulatedTip;

  /// No description provided for @newShort.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newShort;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
