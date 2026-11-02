// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navLive => 'Live';

  @override
  String get navControl => 'Steuerung';

  @override
  String get navAutomate => 'Automatisieren';

  @override
  String get navTune => 'Parameter';

  @override
  String get navReplay => 'Replay';

  @override
  String get navDevices => 'Geräte';

  @override
  String get navGuides => 'Anleitungen';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navSequences => 'Sequenzen';

  @override
  String get navScripts => 'Skripte';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageDesc => 'Die Sprache der App.';

  @override
  String get translationNote => 'Diese Übersetzung wurde mit KI erstellt und kann Fehler enthalten. Korrekturen sind im GitHub-Repository willkommen.';

  @override
  String get translationContribute => 'Auf GitHub beitragen';

  @override
  String get secLanguageUnits => 'Sprache und Einheiten';

  @override
  String get settingsUnits => 'Einheiten';

  @override
  String get settingsUnitsDesc =>
      'Längen, Geschwindigkeiten und Temperaturen. Geräte, Sequenzen und Skripte rechnen weiter in Metern; nur die Anzeige ändert sich.';

  @override
  String settingsUnitsSystem(String name) {
    return 'Wie die Region ($name)';
  }

  @override
  String get unitsMetric => 'Metrisch (m, m/s, °C)';

  @override
  String get unitsImperial => 'Imperial (ft, mph, °F)';

  @override
  String get unitsMetricShort => 'metrisch';

  @override
  String get unitsImperialShort => 'imperial';

  @override
  String settingsLanguageSystem(String name) {
    return 'Wie das System ($name)';
  }

  @override
  String toastSaved(String name) {
    return 'Gespeichert als $name';
  }

  @override
  String get stopEngagedBar => 'Stopp aktiv · tippen zum Zurücksetzen';

  @override
  String get stopEngagedTitle => 'Not-Stopp aktiv';

  @override
  String get stopKeep => 'Gestoppt lassen';

  @override
  String get stopResetAll => 'Alle zurücksetzen';

  @override
  String get stopReset => 'Stopp zurücksetzen';

  @override
  String stopBody(String names) {
    return 'Die Motoren sind gestoppt und alle Bewegungsbefehle sind gesperrt auf $names.';
  }

  @override
  String get theDevice => 'dem Gerät';

  @override
  String get stopCheck => 'Prüfe das Gerät, bevor du zurücksetzt. Danach bleibt es entschärft, bis du es wieder scharf schaltest.';

  @override
  String get fleet => 'Flotte';

  @override
  String get tagSim => 'Sim';

  @override
  String get fleetActive => 'Aktiv';

  @override
  String get fleetLost => 'Verloren';

  @override
  String get fleetLinked => 'Verbunden';

  @override
  String get fleetOff => 'Aus';

  @override
  String get fleetOn => 'An';

  @override
  String get connecting => 'Verbinde';

  @override
  String get noLink => 'Keine Verbindung';

  @override
  String get simulated => 'Simuliert';

  @override
  String get statLink => 'Link';

  @override
  String get statLost => 'Verloren';

  @override
  String get statLatency => 'Latenz';

  @override
  String get statBattery => 'Akku';

  @override
  String get statRecording => 'Aufnahme';

  @override
  String get armed => 'Scharf';

  @override
  String get disarmed => 'Entschärft';

  @override
  String stopLabelAll(int count) {
    return 'Not-Stopp, alle $count Geräte';
  }

  @override
  String get stopLabel => 'Not-Stopp';

  @override
  String stopTipAll(int count) {
    return 'Stoppt alle $count verbundenen Geräte';
  }

  @override
  String get stopTipSlowRadio => 'STOP geht auch über dieses reine Telemetrie-Funkmodul, aber langsam: bis zu einer Sekunde';

  @override
  String get stopAll => 'Alle stoppen';

  @override
  String get stop => 'Stopp';

  @override
  String get failsafeHold => 'hält die Position';

  @override
  String get failsafeRth => 'fliegt nach Hause';

  @override
  String get failsafeLand => 'landet an Ort und Stelle';

  @override
  String linkLostFor(String seconds) {
    return 'Link verloren · $seconds s';
  }

  @override
  String failsafeActive(String action) {
    return 'Failsafe aktiv: $action.';
  }

  @override
  String get reconnecting => 'Verbinde neu. Das Failsafe greift nach 1,8 s.';

  @override
  String get controlsLocked => 'Die Steuerung ist gesperrt, bis der Link zurück ist.';

  @override
  String get linkRestored => 'Link wiederhergestellt';

  @override
  String get linkRestoredBody => 'Manuelle Steuerung ist wieder möglich.';

  @override
  String alertBelow(String limit) {
    return 'Unter $limit.';
  }

  @override
  String alertAbove(String limit) {
    return 'Über $limit.';
  }

  @override
  String get linkLostOther => 'Sein Failsafe übernimmt nach 1,8 s.';

  @override
  String get compatNewerApp => 'Braucht eine neuere App';

  @override
  String get compatOldLib => 'Bibliothek zu alt';

  @override
  String compatSome(String why) {
    return 'Manche Funktionen gehen evtl. nicht: $why.';
  }

  @override
  String get compatUpdateApp => 'Aktualisiere koebelt dash.';

  @override
  String get compatUpdateLib =>
      'Aktualisiere die koebelt/link-Bibliothek auf dem Gerät, oder installiere ein älteres koebelt dash unter Einstellungen > Updates.';

  @override
  String get show => 'Zeigen';

  @override
  String alerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Warnungen', one: '1 Warnung');
    return '$_temp0';
  }

  @override
  String get linkLost => 'Link verloren';

  @override
  String get replayOffControl => 'Die Steuerung ist während eines Replays aus';

  @override
  String get replayOffControlWhy => 'Die Steuerung wirkt auf ein verbundenes Gerät, nicht auf eine Aufnahme.';

  @override
  String get replayOffSequences => 'Sequenzen sind während eines Replays aus';

  @override
  String get replayOffSequencesWhy => 'Sequenzen laufen auf einem verbundenen Gerät, nicht auf einer Aufnahme.';

  @override
  String get replayOffTune => 'Das Einstellen ist während eines Replays aus';

  @override
  String get replayOffTuneWhy => 'Parameter werden auf einem verbundenen Gerät gelesen und geschrieben, nicht auf einer Aufnahme.';

  @override
  String replayExitTo(String name) {
    return 'Beende das Replay, um zu $name zurückzukehren.';
  }

  @override
  String get replayExitConnect => 'Beende das Replay und verbinde dann ein Gerät.';

  @override
  String get replayBack => 'Zurück zum Replay';

  @override
  String replayExitBackTo(String name) {
    return 'Replay beenden, zurück zu $name';
  }

  @override
  String get replayExit => 'Replay beenden';

  @override
  String get notConnected => 'Nicht verbunden';

  @override
  String get noDeviceTitle => 'Kein Gerät verbunden';

  @override
  String get noDeviceBody => 'Wähle ein gekoppeltes Gerät oder kopple ein neues. Telemetrie und Steuerung erscheinen, sobald der Link steht.';

  @override
  String get connectFailed => 'Verbindung fehlgeschlagen';

  @override
  String get noPairedDevices => 'Noch keine gekoppelten Geräte.';

  @override
  String get offline => 'Offline';

  @override
  String batteryPct(int pct) {
    return '$pct % Akku';
  }

  @override
  String get connect => 'Verbinden';

  @override
  String get pairNewDevice => 'Neues Gerät koppeln';

  @override
  String get or => 'Oder';

  @override
  String get addSimulated => 'Simuliertes Gerät hinzufügen';

  @override
  String get addSimulatedDesc => 'Eine virtuelle Drohne, ein Rover, Arm, eine Rakete oder ein Prüfstand, um die App ohne Hardware auszuprobieren.';

  @override
  String get openRecording => 'Aufnahme öffnen';

  @override
  String get openRecordingDesc => 'Spiele eine Sitzung, ein Fluglog oder die Beispielaufnahmen ab.';

  @override
  String get setUpLibrary => 'Bibliothek einrichten';

  @override
  String get setUpLibraryDesc => 'Füge koebelt/link zu deinem Arduino-, Python-, ROS-2- oder Rust-Projekt hinzu.';

  @override
  String get noDevice => 'Kein Gerät';

  @override
  String get tagDemo => 'Demo';

  @override
  String moreConnected(int count) {
    return '+$count verbunden';
  }

  @override
  String get alsoConnected => 'Ebenfalls verbunden';

  @override
  String get disconnectAll => 'Alle trennen';

  @override
  String get connectAnother => 'Weiteres verbinden';

  @override
  String get pairedDevices => 'Gekoppelte Geräte';

  @override
  String get noPairedDevicesShort => 'Keine gekoppelten Geräte';

  @override
  String get noPairedDevicesHint => 'Kopple eines, füge ein simuliertes Gerät hinzu oder folge dem Schnellstart.';

  @override
  String get pairDevice => 'Koppeln';

  @override
  String get quickstart => 'Schnellstart';

  @override
  String get manage => 'Verwalten';

  @override
  String get replaying => 'Replay läuft';

  @override
  String get closeReplay => 'Replay schließen';

  @override
  String get simulator => 'Simulator';

  @override
  String get disconnect => 'Trennen';

  @override
  String get open => 'Öffnen';

  @override
  String get sequenceRunning => 'Sequenz läuft';

  @override
  String disconnectName(String name) {
    return '$name trennen';
  }

  @override
  String get automateSeqBlurb => 'Schritte in Reihenfolge, ohne Code: starten, fliegen zu, warten, landen; fahren zu; Pose anfahren.';

  @override
  String get automateSeqPoint1 => 'Ohne Code: in der App gebaut';

  @override
  String get automateSeqPoint2 => 'Läuft auf dem Gerät, wenn es sie speichern kann';

  @override
  String get automateSeqPoint3 => 'Läuft weiter, wenn der Link abbricht';

  @override
  String get automateSeqConnect => 'Verbinde ein Gerät, um seine Sequenzen zu bauen';

  @override
  String automateSeqCount(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Sequenzen', one: '1 Sequenz', zero: 'Keine Sequenz');
    return '$_temp0 für $name';
  }

  @override
  String get automateScriptBlurb => 'Python, das Telemetrie und Kamera liest, entscheidet und das Gerät steuert.';

  @override
  String get automateScriptPoint1 => 'Logik, Sensoren, die Kamera';

  @override
  String get automateScriptPoint2 => 'Jedes Paket: OpenCV, PyTorch, YOLO';

  @override
  String get automateScriptPoint3 => 'Trigger: Tasten, Buttons, Bedingungen, Timer';

  @override
  String get automateScriptPoint3Host => 'Läuft auf einem Skript-Host: einem Computer in deinem Netz';

  @override
  String scriptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Skripte', one: '1 Skript', zero: 'Kein Skript');
    return '$_temp0';
  }

  @override
  String get automateEyebrow => 'Zwei Wege zu automatisieren';

  @override
  String runningOn(String what, String device) {
    return '$what auf $device';
  }

  @override
  String get automateTogether1 => 'Zusammen: Ein Skript kann eine Sequenz starten ';

  @override
  String get automateTogether2 => ', und entscheiden, wann.';

  @override
  String get sequenceOrScript => 'Sequenz oder Skript?';

  @override
  String get running => 'Läuft';

  @override
  String get layoutHud => 'HUD';

  @override
  String get layoutWall => 'WALL';

  @override
  String get editLayout => 'Layout bearbeiten';

  @override
  String get sceneLayers3d => '3D-Ebenen';

  @override
  String get layerCloud => 'Punktwolke';

  @override
  String get layerTrail => 'Flugbahn';

  @override
  String get layerRadar => 'Radarspuren';

  @override
  String get layerGrid => 'Bodenraster';

  @override
  String get sceneLayers => 'Szenen-Ebenen';

  @override
  String get addWidget => 'Widget hinzufügen';

  @override
  String widgetsSavedFor(String device, String screens) {
    return 'Widgets werden für $device auf $screens-Bildschirmen gespeichert.';
  }

  @override
  String get thisDevice => 'dieses Gerät';

  @override
  String get screenPhone => 'Handy';

  @override
  String get screenShort => 'Handy quer';

  @override
  String get screenPortrait => 'Tablet hochkant';

  @override
  String get screenTablet => 'Tablet';

  @override
  String get screenDesktop => 'Desktop';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get saveLayout => 'Layout speichern';

  @override
  String get back => 'Zurück';

  @override
  String get paused => 'Pausiert';

  @override
  String get stale => 'Veraltet';

  @override
  String hzLive(int hz) {
    return '$hz Hz live';
  }

  @override
  String get resume => 'Fortsetzen';

  @override
  String get pause => 'Pause';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statMean => 'Mittel';

  @override
  String get unit => 'Einheit';

  @override
  String get window => 'Fenster';

  @override
  String get windowValue => '10 s · 300 Werte';

  @override
  String get source => 'Quelle';

  @override
  String get tapChannelToHide => 'Tippe auf einen Kanal, um ihn auszublenden';

  @override
  String get rec => 'Rec';

  @override
  String get speedLimit => 'Tempolimit';

  @override
  String get setHomePose => 'Home-Pose setzen';

  @override
  String get setHomeHere => 'Home hier setzen';

  @override
  String get useThisPose => 'Diese Pose nehmen';

  @override
  String get setHome => 'Home setzen';

  @override
  String get setHomePoseBody => 'Die aktuellen Gelenkwinkel werden die Pose, die Home-Pose und die Home-Schritte der Sequenzen anfahren.';

  @override
  String setHomeBody(String length) {
    return 'Die aktuelle Position wird Home (0, 0). Die Rückkehr nach Hause fliegt hierher, und Wegpunkte der Sequenzen werden von hier gemessen. Das Gerät ist $length vom aktuellen Home entfernt.';
  }

  @override
  String get autoDashDrives => 'dash steuert';

  @override
  String get autoTakeBack => 'Wähle MANUAL oder HOLD oder bewege die Sticks, um zu übernehmen.';

  @override
  String get autoTip => 'Der Modus von dash: solange eine Sequenz oder ein Skript das Gerät steuert. Starte eines unter Automatisieren.';

  @override
  String get tiltDrag => 'Tilt · ziehen zum Simulieren';

  @override
  String get stickThrottle => 'Gas';

  @override
  String get stickDrive => 'Fahren';

  @override
  String get stickYaw => 'Gier';

  @override
  String get stickPitchRoll => 'Nick · Roll';

  @override
  String get stickSteer => 'Lenken';

  @override
  String get stickThrottleYaw => 'Gas · Gier';

  @override
  String get tiltPitchRoll => 'Tilt · Nick und Roll';

  @override
  String get tiltSteerDrive => 'Tilt · lenken und fahren';

  @override
  String get axUp => 'HOCH';

  @override
  String get axDn => 'RUNT';

  @override
  String get axFwd => 'VOR';

  @override
  String get axRev => 'ZUR';

  @override
  String get axBack => 'ZUR';

  @override
  String get axL => 'L';

  @override
  String get axR => 'R';

  @override
  String get axYaw => 'GIER';

  @override
  String get rdAlt => 'Höhe';

  @override
  String get rdOdom => 'Odom';

  @override
  String get rdSpeed => 'Tempo';

  @override
  String get rdHdg => 'Kurs';

  @override
  String get rdHome => 'Home';

  @override
  String get rdVz => 'Vz';

  @override
  String get rdMax => 'Max';

  @override
  String get rdRange => 'Distanz';

  @override
  String get rdToolX => 'Werkz. X';

  @override
  String get rdToolY => 'Werkz. Y';

  @override
  String get rdToolZ => 'Werkz. Z';

  @override
  String get rdThrust => 'Schub';

  @override
  String get rdRpm => 'U/min';

  @override
  String get rdCurrent => 'Strom';

  @override
  String get rdPower => 'Leistung';

  @override
  String get rdTemp => 'Temp';

  @override
  String get rdEfficiency => 'Effizienz';

  @override
  String get homePose => 'Home-Pose';

  @override
  String get setAsHome => 'Als Home setzen';

  @override
  String get armJoint => 'Gelenk';

  @override
  String get armCartesian => 'Kartesisch';

  @override
  String get toolFrame => 'Werkzeugsystem · relativ zur Basis';

  @override
  String armPadHelp(String frame, String wristBtn, String wrist, String gripper) {
    return 'Controller · $frame: Gelenk / kartesisch · $wristBtn: $wrist · $gripper: Greifer';
  }

  @override
  String get armWrist => 'Handgelenk';

  @override
  String get gripper => 'Greifer';

  @override
  String gripperOpenPct(int pct) {
    return '$pct % offen';
  }

  @override
  String get gripperOpen => 'Öffnen';

  @override
  String get gripperClose => 'Schließen';

  @override
  String get flightPhase => 'Flugphase';

  @override
  String get phasePad => 'Auf der Rampe';

  @override
  String get phaseCount => 'Countdown';

  @override
  String get phaseBoost => 'Boost';

  @override
  String get phaseCoast => 'Ausrollen';

  @override
  String get phaseDrogue => 'Drogue';

  @override
  String get phaseMain => 'Hauptschirm';

  @override
  String get phaseLanded => 'Gelandet';

  @override
  String get preflight => 'Vor dem Flug';

  @override
  String get checkPyro => 'Pyro-Durchgang · Drogue, Hauptschirm';

  @override
  String get ok => 'OK';

  @override
  String get check => 'Prüfen';

  @override
  String get checkGps => 'GPS-Fix';

  @override
  String sats(int count) {
    return '$count Sats';
  }

  @override
  String get noFix => 'Kein Fix';

  @override
  String get checkFlightComputer => 'Flugcomputer';

  @override
  String get safe => 'Sicher';

  @override
  String get armFlightComputer => 'Flugcomputer scharf schalten';

  @override
  String get armPadClear => 'Nur scharf schalten, wenn die Rampe frei ist';

  @override
  String startCountdown(String seconds) {
    return 'Countdown starten · $seconds s';
  }

  @override
  String get abortLaunch => 'Start abbrechen';

  @override
  String get deployDrogue => 'Drogue auslösen';

  @override
  String get deployMain => 'Hauptschirm auslösen';

  @override
  String autoDeploy(String length) {
    return 'Auto-Auslösung · Drogue im Apogäum · Hauptschirm bei $length';
  }

  @override
  String landedBody(String apogee, String distance) {
    return 'Apogäum $apogee · gelandet $distance von der Rampe.';
  }

  @override
  String get resetToPad => 'Zurück auf die Rampe';

  @override
  String get altitude => 'Höhe';

  @override
  String get cutoff => 'Abschaltung';

  @override
  String get cutoffLimit => 'Grenze';

  @override
  String get cutoffBody => 'Das Gas wurde auf 0 gesetzt. Prüfe den Motor, bevor du neu startest.';

  @override
  String get clear => 'Löschen';

  @override
  String get benchDisarmed => 'Schalte den Prüfstand scharf, um den Motor zu drehen. Halte Abstand zum Propeller.';

  @override
  String get testSequence => 'Testsequenz';

  @override
  String get benchRamp => 'RAMPE';

  @override
  String get benchSteps => 'STUFEN';

  @override
  String get runAndRecord => 'Starten und aufnehmen';

  @override
  String benchRampDesc(String seconds) {
    return 'Rampe von 0 auf 100 % in $seconds s, 2 s halten, stopp.';
  }

  @override
  String benchStepsDesc(String size, String seconds) {
    return 'Stufen von $size %, je $seconds s, bis 100 %.';
  }

  @override
  String benchLimits(String amps, String temperature) {
    return 'Grenzen: $amps A, $temperature.';
  }

  @override
  String get mspTitle => 'Überwachung und Tuning';

  @override
  String mspBody(String name, String firmware) {
    return '$name läuft mit $firmware und ist über MSP verbunden, die Konfigurationsverbindung. Die App zeigt die Telemetrie, stellt die PID-Werte unter Parameter ein, und STOP entschärft. Flieg ihn mit deinem RC-Sender.';
  }

  @override
  String get radioOnlyTitle => 'Nur-Telemetrie-Link';

  @override
  String radioOnlyBody(String name, String radio) {
    return '$name ist über $radio verbunden, das nur Telemetrie überträgt. Sticks, Modi und Befehle erreichen das Gerät so nicht; STOP schon, in etwa einer Sekunde. Steuere es über seinen Hauptlink (WLAN, Bluetooth oder ein SiK-Funkmodul) und verlass dich auf sein Failsafe, wenn dieser Link außer Reichweite ist.';
  }

  @override
  String get aRadio => 'ein Funkmodul';

  @override
  String get tileReadouts => 'Messwerte';

  @override
  String get tileSrcFused => 'Fusionierter Zustand';

  @override
  String get tileAttitude => 'Lage';

  @override
  String get tileAccelerometer => 'Beschleunigungssensor';

  @override
  String get tileGyroscope => 'Gyroskop';

  @override
  String get tileSrcBaroRange => 'Baro + Entfernungssensor';

  @override
  String get tileRadar => 'Radar';

  @override
  String get tileSrcRadar => 'Radar / Sicherheitsscanner';

  @override
  String get tileLidar => 'Lidar';

  @override
  String get tileSrcLidar => 'Scannendes Lidar';

  @override
  String get tileJoints => 'Gelenke';

  @override
  String get tileSrcJoints => 'Gelenkencoder';

  @override
  String get tileForceTorque => 'Kraft / Drehmoment';

  @override
  String get tileSrcWrist => 'Kraft-Momenten-Sensor am Handgelenk';

  @override
  String get tileSrcPower => 'Strommodul';

  @override
  String get tileSrcRadio => 'Funklink';

  @override
  String get tileCamera => 'Kamera';

  @override
  String get tileSrcCamera => 'Gerätekamera · MJPEG';

  @override
  String get tileSrcFleet => 'Jedes verbundene Gerät';

  @override
  String get tileSrcPhase => 'Zustandsautomat des Flugcomputers';

  @override
  String get tileVerticalSpeed => 'Vertikalgeschwindigkeit';

  @override
  String get tileSrcBaroImu => 'Baro- + IMU-Fusion';

  @override
  String get tilePyro => 'Pyro-Kanäle';

  @override
  String get tileSrcPyro => '4-Kanal-Pyroplatine';

  @override
  String get tileSrcTacho => 'Optischer Drehzahlmesser';

  @override
  String get tileTorque => 'Drehmoment';

  @override
  String get tileSrcTorque => 'Reaktionsmomentsensor';

  @override
  String get tileMotorTemp => 'Motortemp.';

  @override
  String get tileSrcNtc => 'NTC-Thermistor';

  @override
  String get tileRollRate => 'Rollrate';

  @override
  String get tilePitchRate => 'Nickrate';

  @override
  String get tileYawRate => 'Gierrate';

  @override
  String get tileGroundSpeed => 'Geschwindigkeit über Grund';

  @override
  String get tileAgl => 'Höhe über Grund';

  @override
  String get tileOwnSpeed => 'Eigengeschwindigkeit';

  @override
  String get tileVoltage => 'Spannung';

  @override
  String get tilePyroBus => 'Pyro-Bus';

  @override
  String get tileStator => 'Stator';

  @override
  String get tileVibration => 'Vibration';

  @override
  String get tileAcc200 => 'Beschleunigungssensor · 200 G';

  @override
  String get tileSafetyScanner => 'Sicherheitsscanner';

  @override
  String tracks(int count) {
    return '$count Spuren';
  }

  @override
  String points(int count) {
    return '$count Pkt.';
  }

  @override
  String axes(int count) {
    return '$count Achsen';
  }

  @override
  String connectedCount(int count) {
    return '$count verbunden';
  }

  @override
  String armedCount(int count) {
    return '$count scharf';
  }

  @override
  String get proxClear => 'frei';

  @override
  String get tileProximity => 'Nähe';

  @override
  String get tileSrcProx => 'Näherungssensoren';

  @override
  String tileSrcCustom(String hz) {
    return 'Eigener Kanal · $hz Hz';
  }

  @override
  String get tagScript => 'Skript';

  @override
  String get viewEnded => 'beendet';

  @override
  String series(int count) {
    return '$count Reihen';
  }

  @override
  String get rdReach => 'Reichweite';

  @override
  String get pyroDrogue => 'Drogue';

  @override
  String get pyroMain => 'Hauptschirm';

  @override
  String get pyroAirstart => 'Zündung im Flug';

  @override
  String get pyroSpare => 'Reserve';

  @override
  String get pyroContinuity => 'Durchgang';

  @override
  String get pyroFired => 'Gezündet';

  @override
  String get pyroNotWired => 'Nicht angeschlossen';

  @override
  String removeTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get removeDevice => 'Gerät entfernen';

  @override
  String removeBody(String name) {
    return 'Kopplungsschlüssel, HUD-Layouts und Parameterentwürfe von $name werden aus dieser App gelöscht.';
  }

  @override
  String get removeDisconnectFirst => 'Es wird zuerst getrennt.';

  @override
  String get removeKept => 'Aufnahmen bleiben erhalten. Um das Gerät wieder zu nutzen, kopple es mit einem neuen Code.';

  @override
  String onlineOf(int online, int total) {
    return '$online von $total online';
  }

  @override
  String get devicesEmptyHint => 'Kopple ein Gerät oder folge dem Schnellstart, um die Bibliothek zu deinem Projekt hinzuzufügen.';

  @override
  String get devicesSeveral =>
      'Mehrere Geräte können gleichzeitig verbunden sein. Das angezeigte bekommt die Sticks; die anderen halten mit zentrierten Sticks, und STOP stoppt alle.';

  @override
  String get connected => 'Verbunden';

  @override
  String removeName(String name) {
    return '$name entfernen';
  }

  @override
  String get online => 'Online';

  @override
  String get batShort => 'AKKU';

  @override
  String get myRobot => 'Mein Roboter';

  @override
  String radioNothingHeard(String port, int baud) {
    return 'Nichts empfangen auf $port bei $baud Baud. Prüfe, ob das Gerät an ist, beide Funkmodule denselben Kanal und dieselbe Luftrate nutzen und die Baudrate stimmt. Du kannst den Link trotzdem hinzufügen und später verbinden.';
  }

  @override
  String get pairTitle => 'Gerät koppeln';

  @override
  String get pairNearby => 'In der Nähe';

  @override
  String get pairRadio => 'Funk';

  @override
  String get pairSimulated => 'Simuliert';

  @override
  String get pairSimulatedIntro =>
      'Simulierte Geräte laufen in dieser App und sprechen dasselbe Protokoll wie echte Hardware. Füge nur die hinzu, die du brauchst; jedes ist mit SIM markiert.';

  @override
  String get added => 'Hinzugefügt';

  @override
  String get addAnother => 'Noch eins';

  @override
  String get add => 'Hinzufügen';

  @override
  String radioRatesTlm(int tlm) {
    return 'Telemetrie $tlm Hz · keine Steuerung';
  }

  @override
  String radioRates(int tlm, int ctl) {
    return 'Telemetrie $tlm Hz · Steuerung $ctl Hz';
  }

  @override
  String get radioIntro =>
      'Ein Funklink ist ein Funkmodem, das per USB an diesem Computer oder Handy hängt und mit einem passenden Funkmodul am Gerät spricht.';

  @override
  String get radioIntroMore => 'Für die App ist es ein serieller Port; der Funktyp bestimmt Tempo und Datenmenge.';

  @override
  String get radioNoSerial => 'Kein USB-Seriell auf dieser Plattform';

  @override
  String get radioNoSerialBody =>
      'iOS-Apps können keine USB-Seriell-Adapter öffnen. Nutze die App unter Android, macOS, Windows oder Linux für Funklinks, oder verbinde per WLAN oder Bluetooth.';

  @override
  String get radioLora =>
      'LoRa-Module sind allein keine USB-Geräte. Flashe den Bodenstations-Sketch aus der LoRa-Anleitung auf ein zweites Board mit dem Funkmodul und steck dieses Board an.';

  @override
  String get usbPort => 'USB-Port';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get noSerialPorts => 'Keine seriellen Ports gefunden. Steck den USB-Adapter des Funkmoduls an.';

  @override
  String get baudRate => 'Baudrate';

  @override
  String heard(String name) {
    return '$name empfangen';
  }

  @override
  String get heardMavlink => 'Es spricht MAVLink: kein Koppeln nötig.';

  @override
  String get heardPairing => 'Es ist im Kopplungsmodus und bekommt einen Schlüssel.';

  @override
  String get heardNoPairing => 'Es ist nicht im Kopplungsmodus; es wird ohne Schlüssel hinzugefügt.';

  @override
  String get listening => 'Lausche';

  @override
  String get listenForDevice => 'Auf Gerät lauschen';

  @override
  String pairName(String name) {
    return '$name koppeln';
  }

  @override
  String get addRadioLink => 'Funklink hinzufügen';

  @override
  String get pairNearbyIntro =>
      'Steck das Board an oder schalte es ein. Flugcontroller und Drohnen erscheinen von selbst; Boards mit der koebelt/link-Bibliothek erscheinen hier auch im Kopplungsmodus.';

  @override
  String get scanning => 'Suche über WLAN, Bluetooth und USB…';

  @override
  String get stillScanning => 'Suche weitere Geräte…';

  @override
  String get addByIp => 'Per IP-Adresse hinzufügen';

  @override
  String get name => 'Name';

  @override
  String get mavlinkPortNote => 'Die App lauscht auf UDP 14550 wie jede Bodenstation; der Port ist der des Fahrzeugs, falls du ihn kennst.';

  @override
  String get addDevice => 'Gerät hinzufügen';

  @override
  String get notShowingUp =>
      'Gerät erscheint nicht? Boards mit ArduPilot, PX4, Betaflight oder INAV verbinden sich direkt; alles andere braucht die koebelt/link-Bibliothek.';

  @override
  String get openQuickstart => 'Schnellstart öffnen';

  @override
  String get orLower => 'oder';

  @override
  String get addItByIp => 'es per IP-Adresse hinzufügen';

  @override
  String get secControl => 'Steuerung';

  @override
  String get secController => 'Gamecontroller';

  @override
  String get secLink => 'Link und Sicherheit';

  @override
  String get secRecording => 'Aufnahme';

  @override
  String get secAlerts => 'Warnungen';

  @override
  String get secMap => 'Karte';

  @override
  String get secPairing => 'Kopplung';

  @override
  String get secAi => 'KI-Assistenten (MCP)';

  @override
  String get secAiShort => 'KI-Assistenten';

  @override
  String get secUpdates => 'Updates';

  @override
  String get setInput => 'Eingabemethode';

  @override
  String get setInputDesc =>
      'Sticks: zwei virtuelle Joysticks. Slider: Gas und Gier mit Federrückstellung und ein Stick. Tilt: lenken durch Neigen von Handy oder Tablet.';

  @override
  String get csSticks => 'STICKS';

  @override
  String get csSliders => 'SLIDER';

  @override
  String get csTilt => 'TILT';

  @override
  String get setInvert => 'Nick umkehren';

  @override
  String get setInvertDesc => 'Nach vorn drücken, um die Nase zu heben.';

  @override
  String get setHaptics => 'Haptisches Feedback';

  @override
  String get setHapticsDesc => 'Vibrieren in der Stick-Mitte und bei Warnungen.';

  @override
  String get setLinkLoss => 'Bei Link-Verlust';

  @override
  String get setLinkLossDesc =>
      'Was eine Drohne nach 1,8 s ohne Steuerpaket tut. Bodenroboter und Arme halten, Prüfstände stoppen den Motor, Raketen setzen ihre Flugsequenz fort.';

  @override
  String get setRate => 'Telemetrierate';

  @override
  String get setRateDesc => 'Höhere Raten brauchen mehr Bandbreite und Akku.';

  @override
  String get setTestFailsafe => 'Failsafe testen';

  @override
  String get setTestFailsafeDesc => 'Trennt den Steuerlink sechs Sekunden lang, damit du das eingestellte Verhalten prüfen kannst.';

  @override
  String get runTest => 'Test starten';

  @override
  String get setRecordVideo => 'Video aufnehmen';

  @override
  String get setRecordVideoDesc =>
      'Behalte die Kamera des Geräts bei jeder Aufnahme. Die Kamera bleibt während der Aufnahme verbunden, auch wenn kein Bildschirm sie zeigt.';

  @override
  String get setVideoFps => 'Video-Bildrate';

  @override
  String get setVideoFpsDesc => 'Höchstens so viele Bilder pro Sekunde werden behalten. Eine ESP32-CAM bei 640×480 braucht etwa 10 MB pro Minute bei 10 fps.';

  @override
  String get setAlertSound => 'Warnton';

  @override
  String get setAlertSoundDesc => 'Ertönt bei Warnungen und bei Link-Verlust. Handys vibrieren stattdessen, wenn Haptik an ist.';

  @override
  String kindsOnly(String kinds) {
    return 'Nur $kinds.';
  }

  @override
  String get below => 'Unter';

  @override
  String get above => 'Über';

  @override
  String get setMapTiles => 'Kartenkacheln';

  @override
  String get setMapTilesDesc =>
      'Hintergrund der Kartenansicht: Mapbox Dark, Outdoors (Gelände) oder Satellite, eigene Kacheln oder keine (ein Meterraster). Angesehene Kacheln bleiben eine Weile auf diesem Gerät.';

  @override
  String get mapDark => 'DUNKEL';

  @override
  String get mapOutdoors => 'OUTDOOR';

  @override
  String get mapSatellite => 'SATELLIT';

  @override
  String get mapCustom => 'EIGENE';

  @override
  String get mapNone => 'KEINE';

  @override
  String get setMapboxToken => 'Dein Mapbox-Token';

  @override
  String get setMapboxTokenDesc => 'Optional: ein öffentliches Token (pk.…) deines eigenen Mapbox-Kontos, um dein Kontingent statt dem der App zu nutzen.';

  @override
  String get setTileUrl => 'Kachel-URL';

  @override
  String setTileUrlDesc(String z, String x, String y) {
    return 'Eine Vorlage mit $z, $x und $y, zum Beispiel eine Satellitenebene deines Kartenanbieters mit seinem Schlüssel. Beachte die Bedingungen des Anbieters.';
  }

  @override
  String get setAttribution => 'Quellenangabe';

  @override
  String get setAttributionDesc => 'Der Hinweis, den dein Anbieter verlangt, auf der Karte angezeigt.';

  @override
  String get provider => 'Anbieter';

  @override
  String get setGuides => 'Integrationsanleitungen';

  @override
  String get setGuidesDesc => 'Füge die koebelt/link-Bibliothek zu Arduino-, Python-, ROS-2- oder Rust-Projekten hinzu.';

  @override
  String scriptHostAt(String address) {
    return 'Skript-Host unter $address';
  }

  @override
  String get forget => 'Vergessen';

  @override
  String get setScriptHosts => 'Skript-Hosts';

  @override
  String get setScriptHostsDesc =>
      'Computer im Netz, die Skripte für dieses Gerät ausführen, mit jedem Python-Paket. Auf dem Computer: pip install koebelt-dash-scripts, dann koebelt-dash-scripts host.';

  @override
  String get setScriptHostsDescPhone =>
      'Computer im Netz, die Skripte für dieses Handy ausführen, mit jedem Python-Paket. Auf dem Computer: pip install koebelt-dash-scripts, dann koebelt-dash-scripts host.';

  @override
  String get setBeHost => 'Skript-Host sein';

  @override
  String get setBeHostDesc => 'Führe Skripte für Handys und Tablets in diesem Netz aus, mit dem Python der Skripte.';

  @override
  String setBeHostCode(String code) {
    return 'Kopplungscode: $code. Handys koppeln unter Skripte > Läuft auf > Skript-Host hinzufügen.';
  }

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Sitzungen', one: '1 Sitzung');
    return '$_temp0';
  }

  @override
  String get import => 'Importieren';

  @override
  String get record => 'Aufnehmen';

  @override
  String get noRecordings => 'Noch keine Aufnahmen. Nimm ein verbundenes Gerät auf oder nutze Importieren für eine Datei oder die Beispielaufnahmen.';

  @override
  String get tagNew => 'Neu';

  @override
  String get tagVideo => 'Video';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Geräte', one: '1 Gerät');
    return '$_temp0';
  }

  @override
  String deleteName(String name) {
    return '$name löschen';
  }

  @override
  String exportName(String name) {
    return '$name exportieren';
  }

  @override
  String get replayEyebrow => 'Aufnahme und Wiedergabe';

  @override
  String get sessions => 'Sitzungen';

  @override
  String get export => 'Exportieren';

  @override
  String get exitToLive => 'Zurück zu Live';

  @override
  String get play => 'Abspielen';

  @override
  String deleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get exportFirst => 'Erst exportieren';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteRecordingBody => 'Die Aufnahme wird von diesem Gerät entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String deleteAllN(int count) {
    return 'Alle $count löschen';
  }

  @override
  String get deleteSessionBody =>
      'Die Aufnahme jedes Geräts dieser Sitzung wird mit ihrem Video von diesem Gerät entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String sequenceN(int n) {
    return 'Sequenz $n';
  }

  @override
  String sequencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Sequenzen', one: '1 Sequenz', zero: 'keine Sequenz');
    return '$_temp0';
  }

  @override
  String copyOf(String name) {
    return '$name Kopie';
  }

  @override
  String noSequencesFor(String name) {
    return 'Noch keine Sequenzen für $name.';
  }

  @override
  String sequenceIntro(String examples) {
    return 'Eine Sequenz ist eine Liste von Schritten ($examples), die die App nacheinander ausführt und dabei auf die Bestätigung des Geräts wartet.';
  }

  @override
  String get sequenceComplete => 'Sequenz abgeschlossen';

  @override
  String get sequenceStopped => 'Sequenz gestoppt';

  @override
  String get flightSequence => 'Flugsequenz';

  @override
  String get flightSequenceBody =>
      'Der Flugcomputer erledigt Start, Apogäum und Bergung an Bord. Stelle die Auslösung unter Parameter ein; nutze Sequenzen hier für Checks auf der Rampe.';

  @override
  String get stepsDrone => 'starten, Wegpunkte anfliegen, warten, landen';

  @override
  String get stepsPlane => 'starten, eine Runde über Wegpunkte fliegen, landen';

  @override
  String get stepsRover => 'Wegpunkte anfahren, warten, Tempo ändern';

  @override
  String get stepsArm => 'Posen anfahren, Greifer öffnen oder schließen';

  @override
  String get stepsBench => 'ein Gas halten, zwischen zwei Gaswerten rampen';

  @override
  String get stepsGeneric => 'warten, einen Modus setzen, Befehle senden';

  @override
  String get whyExitReplay => 'Zum Starten Replay beenden';

  @override
  String get whyResetStop => 'Erst den Stopp zurücksetzen';

  @override
  String get whyAddSteps => 'Erst Schritte hinzufügen';

  @override
  String get onDevice => 'Auf dem Gerät';

  @override
  String get uploading => 'Lädt hoch';

  @override
  String stepOf(int n, int total) {
    return 'Schritt $n von $total';
  }

  @override
  String get runsOnDevice => 'Läuft auf dem Gerät: läuft weiter, wenn der Link abbricht';

  @override
  String get stopSequence => 'Sequenz stoppen';

  @override
  String get stoppedFromApp => 'In der App gestoppt';

  @override
  String get run => 'Starten';

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Schritte', one: '1 Schritt');
    return '$_temp0';
  }

  @override
  String secondsTimed(String seconds) {
    return '$seconds s getaktet';
  }

  @override
  String get newSequence => 'Neue Sequenz';

  @override
  String get duplicate => 'Duplizieren';

  @override
  String get steps => 'Schritte';

  @override
  String get lockedWhileRunning => 'Gesperrt während des Laufs';

  @override
  String get addFirstStep => 'Füge unten den ersten Schritt hinzu. Schritte laufen von oben nach unten.';

  @override
  String get addStep => 'Schritt hinzufügen';

  @override
  String get dragToReorder => 'Ziehen zum Umsortieren';

  @override
  String get deleteStep => 'Schritt löschen';

  @override
  String get useCurrentPosition => 'Aktuelle Position nehmen';

  @override
  String get useCurrentPose => 'Aktuelle Pose nehmen';

  @override
  String get egDeploy => 'z. B. deploy';

  @override
  String get planTopView => 'Plan · Draufsicht';

  @override
  String get throttleProfile => 'Gasprofil';

  @override
  String get liveView => 'Live-Ansicht';

  @override
  String get timeline => 'Zeitleiste';

  @override
  String get setPoseAsHome => 'Aktuelle Pose als Home';

  @override
  String get planNoteDrone =>
      'Wegpunkte sind Meter östlich und nördlich vom Startpunkt. Die Drohne hält an jedem, bevor der nächste Schritt kommt. Das Failsafe gilt weiter, wenn der Link abbricht.';

  @override
  String get planNotePlane =>
      'Wegpunkte sind Meter östlich und nördlich vom Startpunkt. Ein Flugzeug kann nicht anhalten: Es fliegt durch jeden Punkt und kreist, während es wartet. Der Failsafe greift weiterhin, wenn der Link abbricht.';

  @override
  String get planNoteRover => 'Wegpunkte sind Meter östlich und nördlich vom Startpunkt. Der Rover hält an jedem, bevor der nächste Schritt kommt.';

  @override
  String get planNoteBoat =>
      'Wegpunkte sind Meter östlich und nördlich vom Startpunkt. Das Boot wird an jedem Punkt langsamer, bevor der nächste Schritt beginnt; Wind und Strömung können es beim Warten versetzen.';

  @override
  String planNoteArm(String button) {
    return 'Bewege den Arm von Hand oder mit den Jog-Tasten, dann nimm sie mit „$button“ auf.';
  }

  @override
  String get planNoteBench => 'Die Strom- und Temperaturabschaltung des Geräts bleibt während der Sequenz aktiv.';

  @override
  String get planNoteGeneric => 'Jeder Schritt wartet auf die Bestätigung des Geräts, bevor der nächste beginnt.';

  @override
  String metreGrid(String length) {
    return 'Raster $length';
  }

  @override
  String get now => 'Jetzt';

  @override
  String get and => 'und';

  @override
  String get checkNeedsPython => 'Die Prüfung braucht Python auf diesem Computer: Python einrichten auf der Skriptseite.';

  @override
  String couldNotCheck(String python) {
    return 'Prüfung mit $python nicht möglich.';
  }

  @override
  String scriptErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Dieses Skript hat $count Fehler', one: 'Dieses Skript hat einen Fehler');
    return '$_temp0';
  }

  @override
  String get runAnyway => 'Trotzdem starten';

  @override
  String get showThem => 'Zeigen';

  @override
  String get checkFound => 'Die Prüfung hat gefunden, was es stoppen würde, vermutlich bevor sich etwas bewegt:';

  @override
  String lineN(int n) {
    return 'Zeile $n';
  }

  @override
  String andMore(int count) {
    return 'und $count weitere';
  }

  @override
  String get installImports => 'Installieren, was dieses Skript importiert?';

  @override
  String get installAndRun => 'Installieren und starten';

  @override
  String missingImports(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names sind nicht in diesem Python, das Skript würde also bei seinen Imports stoppen.',
      one: '$names ist nicht in diesem Python, das Skript würde also bei seinen Imports stoppen.',
    );
    return '$_temp0';
  }

  @override
  String couldNotStart(String error) {
    return 'Start fehlgeschlagen: $error';
  }

  @override
  String get pythonScripts => 'Python-Skripte';

  @override
  String copiedExample(String file) {
    return 'Beispiel nach $file in deine Skripte kopiert.';
  }

  @override
  String couldNotCopyExample(String error) {
    return 'Beispiel konnte nicht kopiert werden: $error';
  }

  @override
  String get rename => 'Umbenennen';

  @override
  String get deleteScriptBody => 'Es kommt in den Ordner .trash im Skriptordner, wo du es zurückholen kannst.';

  @override
  String get error => 'Fehler';

  @override
  String get examples => 'Beispiele';

  @override
  String get connectedOutside => 'Von außerhalb von dash verbunden';

  @override
  String get editing => 'bearbeitet';

  @override
  String get saved => 'gespeichert';

  @override
  String get checkAction => 'Prüfen';

  @override
  String get checking => 'Prüfe…';

  @override
  String get openInEditor => 'Im Editor öffnen';

  @override
  String get newScript => 'Neues Skript';

  @override
  String get importPyZip => '.py oder .zip importieren';

  @override
  String get noScriptsPlus => 'Noch keine Skripte. Starte mit einem Beispiel oder tippe auf +.';

  @override
  String get scriptsEmpty => 'Skripte steuern deine Geräte mit Python. Erstelle eins, importiere eins oder starte mit einem Beispiel.';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get share => 'Teilen';

  @override
  String get noScriptsNew => 'Noch keine Skripte. Starte mit einem Beispiel oder tippe auf Neu.';

  @override
  String get more => 'Mehr';

  @override
  String get showInFinder => 'Im Finder zeigen';

  @override
  String get showInFolder => 'Im Ordner zeigen';

  @override
  String get myScript => 'Mein Skript';

  @override
  String get create => 'Erstellen';

  @override
  String get save => 'Speichern';

  @override
  String get device => 'Gerät';

  @override
  String get needs => 'Braucht';

  @override
  String get runsOn => 'Läuft auf';

  @override
  String get scriptsRunOnComputer => 'Skripte laufen auf einem Computer';

  @override
  String get scriptsRunOnComputerBody =>
      'Dieses Gerät schickt sie an einen Skript-Host: einen Computer im selben Netz mit koebelt-dash-scripts, der jedes Python-Paket nutzen kann (OpenCV, PyTorch…).';

  @override
  String get addScriptHost => 'Skript-Host hinzufügen';

  @override
  String get notRunning => 'Läuft nicht';

  @override
  String get endedError => 'Mit Fehler beendet';

  @override
  String get ended => 'Beendet';

  @override
  String get waitingConnect => 'Warte, bis sich das Skript verbindet (connect() im Skript)…';

  @override
  String get youHaveSticks => 'Du hast die Sticks';

  @override
  String get youHaveSticksBody => 'Du hast die Sticks bewegt, also werden die des Skripts ignoriert.';

  @override
  String get scriptLostSticks => 'Das Skript hat die Sticks verloren';

  @override
  String isNotConnected(String name) {
    return '$name ist nicht verbunden';
  }

  @override
  String get connectItOrChoose => 'Verbinde es oder wähle oben ein anderes Gerät.';

  @override
  String doesNotFit(String name) {
    return '$name passt nicht zu diesem Skript';
  }

  @override
  String get chooseOrChangeRequires => 'Wähle oben ein anderes Gerät oder ändere die Zeile # requires:.';

  @override
  String get scriptNeedsDevice => 'Ein Skript steuert ein Gerät: Verbinde zuerst eins (Geräte oder das Gerätemenü oben).';

  @override
  String get doesNotFitShort => 'passt nicht';

  @override
  String get selectedInDash => 'In dash gewählt';

  @override
  String get noneConnected => 'keins verbunden';

  @override
  String get thisComputer => 'Dieser Computer';

  @override
  String get lookingForPython => 'Suche Python…';

  @override
  String get noneFound => 'Keins gefunden';

  @override
  String get noPackage => 'ohne Paket';

  @override
  String get python3Needed => 'Python 3 wird gebraucht';

  @override
  String get python3NeededBody => 'Installiere es von python.org und komm dann hierher zurück.';

  @override
  String get newerLibrary => 'Eine neuere Version der Bibliothek für Skripte ist da, für diese Version von koebelt dash.';

  @override
  String get update => 'Aktualisieren';

  @override
  String get pythonNoAnswer => 'Dieses Python antwortet nicht';

  @override
  String get packageNotInPython => 'koebelt-dash-scripts ist nicht in diesem Python';

  @override
  String pythonNoAnswerBody(String python) {
    return 'dash konnte $python nicht ausführen. Wähle ein anderes oder erstelle eine Skriptumgebung.';
  }

  @override
  String get packageNotInPythonBody => 'Installiere es hier (pip install koebelt-dash-scripts), oder lass dash eine Skriptumgebung im Skriptordner erstellen.';

  @override
  String get installHere => 'Hier installieren';

  @override
  String get scriptsEnvironment => 'Skriptumgebung';

  @override
  String get checkAgain => 'Erneut prüfen';

  @override
  String get settingUpPython => 'Richte Python ein';

  @override
  String get oneTimeSetup => 'Einmalige Einrichtung';

  @override
  String get oneTimeSetupBody =>
      'Skripte brauchen das Paket koebelt-dash-scripts. dash kann im Skriptordner eine Python-Umgebung dafür erstellen (.venv) und es dort installieren; deine eigenen Pakete (OpenCV, PyTorch…) kommen auch dorthin.';

  @override
  String get setUpPython => 'Python einrichten';

  @override
  String packagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Pakete fehlen', one: 'Ein Paket fehlt');
    return '$_temp0';
  }

  @override
  String packagesMissingBody(String modules, String packages) {
    return 'Dieses Skript importiert $modules, das nicht in diesem Python ist: Es würde dort stoppen. $packages installieren?';
  }

  @override
  String get installing => 'Installiere…';

  @override
  String get install => 'Installieren';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get dismiss => 'Schließen';

  @override
  String get stopScript => 'Skript stoppen';

  @override
  String get restart => 'Neu starten';

  @override
  String get triggers => 'Trigger';

  @override
  String get triggersEmpty =>
      'Buttons, Tasten, Controllertasten, Bedingungen und Timer, die Ereignisse an das Skript senden. Deklariere sie mit @dev.trigger(…) oder füge sie hier hinzu.';

  @override
  String get limits => 'Grenzen';

  @override
  String get maxSpeed => 'Max. Tempo';

  @override
  String get geofence => 'Geofence';

  @override
  String get off => 'aus';

  @override
  String metresFromHome(String length) {
    return '$length von Home';
  }

  @override
  String get ceiling => 'Deckenhöhe';

  @override
  String get armingTakeoff => 'Scharf schalten, Start';

  @override
  String get allowed => 'erlaubt';

  @override
  String get notAllowed => 'nicht erlaubt';

  @override
  String get paramWrites => 'Parameter schreiben';

  @override
  String get fire => 'Auslösen';

  @override
  String get notBound => 'Noch nicht belegt';

  @override
  String get console => 'Konsole';

  @override
  String loopHz(String hz) {
    return 'Schleife $hz Hz';
  }

  @override
  String get consoleEmpty => 'Ausgaben von print() und Fehler erscheinen hier.';

  @override
  String get fromOutside => 'von außerhalb von dash';

  @override
  String get valid => 'Gültig';

  @override
  String padTaken(String button, String action) {
    return '$button ist $action in der Controllerbelegung: diese Aktion hat Vorrang.';
  }

  @override
  String get forDuration => 'für';

  @override
  String conditionHelp(String fields) {
    return 'Felder: $fields, mode, armed und die eigenen Kanäle des Geräts (motor_temp.max…). Kombiniere mit and, or, not; füge „for 3s“ zum Warten hinzu.';
  }

  @override
  String get whenTrue => 'WENN WAHR';

  @override
  String get trueAndFalse => 'WAHR UND FALSCH';

  @override
  String get alsoOnControl => 'Auch in Steuerung, neben den Sticks';

  @override
  String get key => 'Taste';

  @override
  String get pressKey => 'Drück eine Taste…';

  @override
  String pressAnotherKey(String key) {
    return '$key · drück eine andere zum Ändern';
  }

  @override
  String get clickThenKey => 'Klicken, dann eine Taste drücken';

  @override
  String get noButtonYet => 'Noch keine Taste';

  @override
  String get pressButton => 'Drück einen Button…';

  @override
  String get learn => 'Anlernen';

  @override
  String get onlyThisMode => 'Nur dieser Modus (HOLD…), oder leer für jeden';

  @override
  String get onlyMessagesContaining => 'Nur Meldungen mit…';

  @override
  String get every => 'ALLE';

  @override
  String get onceAfter => 'EINMAL NACH';

  @override
  String get secondsWord => 'Sekunden';

  @override
  String get addTrigger => 'Trigger hinzufügen';

  @override
  String get editTrigger => 'Trigger bearbeiten';

  @override
  String get event => 'Ereignis';

  @override
  String get eventPlaceholder => 'Der Name, den das Skript bekommt';

  @override
  String get firedBy => 'Ausgelöst durch';

  @override
  String triggerHelp(String event) {
    return 'Das Skript bekommt „$event“ im Handler dieses Namens oder in @dev.on_trigger. Bedingungen, Ereignisse und Timer laufen in dash.';
  }

  @override
  String get done => 'Fertig';

  @override
  String get limitsHelp => 'Hier eingestellt, nicht im Skript: Das Skript kann sie nicht ändern.';

  @override
  String get maximumSpeed => 'Höchsttempo';

  @override
  String get maximumSpeedDesc => 'Die Sticks des Skripts werden darauf skaliert und sein Tempolimit begrenzt.';

  @override
  String get geofenceDesc => 'Jenseits dieser Entfernung von Home verliert das Skript die Sticks und das Gerät hält.';

  @override
  String get ceilingDesc => 'Über dieser Höhe dasselbe, für Drohnen.';

  @override
  String get allowArming => 'Scharf schalten und Start erlauben';

  @override
  String get allowArmingDesc => 'Sonst kann das Skript nur ein Gerät bewegen, das du scharf geschaltet hast.';

  @override
  String get allowParams => 'Parameter schreiben erlauben';

  @override
  String get allowParamsDesc => 'Für Tuning-Skripte. Sie können ändern, wie sich das Gerät verhält.';

  @override
  String get pairing => 'Kopple…';

  @override
  String get pair => 'Koppeln';

  @override
  String get scriptHostIntro =>
      'Ein Skript-Host ist ein Computer im selben Netz, der Skripte für diesen Computer ausführt: ein Laptop, ein Raspberry Pi, ein Jetson… Darauf:';

  @override
  String get scriptHostIntroPhone =>
      'Ein Skript-Host ist ein Computer im selben Netz, der Skripte für dieses Handy oder Tablet ausführt: ein Laptop, ein Raspberry Pi, ein Jetson… Darauf:';

  @override
  String get onTheNetwork => 'Im Netz';

  @override
  String get lookingForHosts => 'Suche Skript-Hosts';

  @override
  String get noHostsFound => 'Keiner gefunden. Gib seine Adresse unten ein (angezeigt von `ipconfig getifaddr en0`, `hostname -I`…).';

  @override
  String get lookAgain => 'Erneut suchen';

  @override
  String get address => 'Adresse';

  @override
  String get pairingCode => 'Kopplungscode';

  @override
  String get pairingCodePlaceholder => 'ABC-123, vom Host angezeigt';

  @override
  String updatingPct(int pct) {
    return 'Update $pct %';
  }

  @override
  String get installingState => 'Installiere';

  @override
  String get appUpdating => 'koebelt dash wird aktualisiert';

  @override
  String appAvailable(String version) {
    return 'koebelt dash $version ist verfügbar';
  }

  @override
  String get appUpToDate => 'koebelt dash ist aktuell';

  @override
  String get skipVersion => 'Diese Version überspringen';

  @override
  String get later => 'Später';

  @override
  String downloadingPct(int pct) {
    return 'Lade $pct %';
  }

  @override
  String get installAnyway => 'Trotzdem installieren';

  @override
  String get updateAnyway => 'Trotzdem aktualisieren';

  @override
  String installVersion(String version) {
    return '$version installieren';
  }

  @override
  String get updateNow => 'Jetzt aktualisieren';

  @override
  String youHaveOlder(String version) {
    return 'Du hast $version; dies ist eine ältere Version. Einstellungen und Aufnahmen aus einer neueren Version öffnen sich darin evtl. nicht alle, und sie erinnert dich bis zur nächsten Veröffentlichung nicht an neuere.';
  }

  @override
  String youHave(String version) {
    return 'Du hast $version.';
  }

  @override
  String get notFromApp => 'Nicht aus der App';

  @override
  String get checkingCompat => 'Prüfe die Kompatibilität mit deinen Geräten…';

  @override
  String get compatUnknown => 'Kompatibilität unbekannt';

  @override
  String get compatUnknownBody => 'Es ließ sich nicht lesen, welche koebelt/link-Versionen diese Version unterstützt.';

  @override
  String notCompatibleWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nicht kompatibel mit $count deiner Geräte',
      one: 'Nicht kompatibel mit einem deiner Geräte',
    );
    return '$_temp0';
  }

  @override
  String notCompatibleBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aktualisiere zuerst ihre koebelt/link-Bibliothek, oder behalte deine Version und wähle unter Einstellungen > Updates eine andere.',
      one: 'Aktualisiere zuerst seine koebelt/link-Bibliothek, oder behalte deine Version und wähle unter Einstellungen > Updates eine andere.',
    );
    return '$_temp0';
  }

  @override
  String get disarmFirst => 'Erst entschärfen';

  @override
  String get disarmFirstBody => 'Ein verbundenes Gerät ist scharf. Das Update schließt die App und trennt den Link; entschärfe es, dann aktualisiere.';

  @override
  String get devicesWillDisconnect => 'Geräte werden getrennt';

  @override
  String devicesWillDisconnectBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Die Installation schließt die App, die $count verbundenen Geräte verlieren also den Link und ihr Failsafe übernimmt, bis du neu verbindest.',
      one: 'Die Installation schließt die App, das verbundene Gerät verliert also den Link und sein Failsafe übernimmt, bis du neu verbindest.',
    );
    return '$_temp0';
  }

  @override
  String get notInstalled => 'Nicht installiert';

  @override
  String get inThisVersion => 'In dieser Version';

  @override
  String get whatsNew => 'Neu';

  @override
  String get fullNotes => 'Vollständige Versionshinweise';

  @override
  String get chooseAnotherVersion => 'Andere Version wählen';

  @override
  String get chooseVersion => 'Version wählen';

  @override
  String get close => 'Schließen';

  @override
  String get chooseVersionBody =>
      'Installiere jede veröffentlichte Version, neuer oder älter. Jede zeigt, ob sie mit den koebelt/link-Versionen deiner Geräte bei deren letzter Verbindung funktioniert.';

  @override
  String get askingGithub => 'Frage GitHub…';

  @override
  String get noReleases => 'Keine Versionen gefunden.';

  @override
  String get installed => 'Installiert';

  @override
  String get latest => 'Neueste';

  @override
  String get checkingShort => 'Prüfe…';

  @override
  String get worksWithDevices => 'Funktioniert mit deinen Geräten';

  @override
  String get noDevicesToCheck => 'Noch keine Geräte zum Prüfen';

  @override
  String notFor(String names) {
    return 'Nicht für $names';
  }

  @override
  String get details => 'Details';

  @override
  String get updateHowAndroid => 'Das Update wird hier geladen und Android fragt nach der Bestätigung der Installation.';

  @override
  String get updateHow => 'Das Update wird geladen, gegen die Veröffentlichung geprüft, und koebelt dash startet in der neuen Version neu.';

  @override
  String versionN(String version) {
    return 'Version $version';
  }

  @override
  String get noSelfUpdate =>
      'Diese Version aktualisiert sich nicht selbst: App Store und TestFlight aktualisieren ihre, und die Downloads von GitHub suchen selbst nach neuen Versionen.';

  @override
  String get releases => 'Versionen';

  @override
  String get upToDate => 'Aktuell.';

  @override
  String versionAvailable(String version) {
    return '$version ist verfügbar.';
  }

  @override
  String downloadingWhat(String what, int pct) {
    return 'Lade $what… $pct %';
  }

  @override
  String installingWhat(String what) {
    return 'Installiere $what…';
  }

  @override
  String get somethingWrong => 'Etwas ist schiefgelaufen.';

  @override
  String get notChecked => 'Noch nicht geprüft.';

  @override
  String updateTo(String version) {
    return 'Auf $version aktualisieren';
  }

  @override
  String get checkNow => 'Jetzt prüfen';

  @override
  String get chooseVersionDesc =>
      'Installiere jede veröffentlichte Version, auch ältere, mit Hinweis, ob sie mit den koebelt/link-Bibliotheken deiner Geräte funktioniert.';

  @override
  String get versions => 'Versionen';

  @override
  String get betas => 'Betas';

  @override
  String get betasDesc => 'Auch Beta-Versionen und Release-Kandidaten anbieten: die nächsten Funktionen vor ihrer Veröffentlichung, mit höherem Fehlerrisiko.';

  @override
  String get autoCheck => 'Automatisch nach Updates suchen';

  @override
  String get autoCheckDesc => 'Beim Start und einmal am Tag fragt koebelt dash GitHub nach der neuesten Version. Sonst wird nichts gesendet.';

  @override
  String get padYawSteer => 'Gier · Lenken';

  @override
  String get padRoll => 'Roll';

  @override
  String get padPitchDrive => 'Nick · Fahren';

  @override
  String get padUnavailable => 'Controller sind auf dieser Plattform nicht verfügbar.';

  @override
  String get padNone =>
      'Kein Controller verbunden. Kopple einen Bluetooth-Controller in den Systemeinstellungen oder steck einen per USB an. RC-Sender funktionieren im USB-Joystick-Modus.';

  @override
  String padConnected(String names) {
    return 'Verbunden: $names.';
  }

  @override
  String get padUse => 'Gamecontroller verwenden';

  @override
  String get padUseDesc =>
      'Sticks steuern Drohnen und Bodenroboter und bewegen Roboterarme, sobald sie scharf sind; Buttons funktionieren auf jedem Gerät. Die Bildschirmsteuerung funktioniert weiter, solange der Controller ruht.';

  @override
  String get padSticks => 'Sticks';

  @override
  String get padMoveNow => 'Bewege oder drück das Bedienelement jetzt';

  @override
  String get padButtons => 'Buttons';

  @override
  String get padDeadzone => 'Totzone';

  @override
  String padDeadzoneDesc(int pct) {
    return 'Stickbewegung um die Mitte, die ignoriert wird: $pct %.';
  }

  @override
  String get padExpo => 'Expo';

  @override
  String padExpoDesc(int pct) {
    return 'Weichere Reaktion um die Mitte für feine Steuerung: $pct %.';
  }

  @override
  String get padResetMapping => 'Belegung zurücksetzen';

  @override
  String get padResetMappingDesc => 'Standardbelegung: linker Stick Gas und Gier, rechter Stick Nick und Roll, B / Kreis für STOP.';

  @override
  String get waiting => 'Warte…';

  @override
  String get invertDirection => 'Richtung umkehren';

  @override
  String get inverted => 'Umgekehrt';

  @override
  String get normal => 'Normal';

  @override
  String clearName(String name) {
    return '$name löschen';
  }

  @override
  String padDrives(String pad, String device) {
    return '$pad steuert $device';
  }

  @override
  String padArmToDrive(String pad) {
    return 'Scharf schalten, um mit $pad zu steuern; seine Buttons gehen schon';
  }

  @override
  String get padButtonsWork => 'Buttons gehen; Sticks steuern Drohnen und Bodenroboter';

  @override
  String get pad => 'Controller';

  @override
  String get copy => 'Kopieren';

  @override
  String get aiLet => 'Assistenten koebelt dash nutzen lassen';

  @override
  String get aiLetDesc =>
      'Claude, Codex, OpenCode, Cursor und andere MCP-Clients können die Doku lesen, Skripte schreiben, die App nutzen und, mit deiner Zustimmung, auf Geräte einwirken. dash selbst sendet nichts an einen KI-Dienst; der verbundene Assistent spricht mit seinem eigenen Anbieter.';

  @override
  String get aiConnectClient => 'Client verbinden';

  @override
  String get aiPaste => 'Füge das in die Einrichtung des Assistenten ein.';

  @override
  String get aiRemotePhone => 'Assistenten laufen auf einem Computer: Sie erreichen dieses Handy über das Netz, mit seinem Token.';

  @override
  String get aiRemoteTablet => 'Assistenten laufen auf einem Computer: Sie erreichen dieses Tablet über das Netz, mit seinem Token.';

  @override
  String get other => 'Andere';

  @override
  String get aiConnectedNow => 'Jetzt verbunden';

  @override
  String get aiNone => 'Kein Assistent in den letzten zehn Minuten.';

  @override
  String actions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Aktionen', one: '1 Aktion');
    return '$_temp0';
  }

  @override
  String get activity => 'Aktivität';

  @override
  String get aiAllowed => 'Ohne Nachfrage erlaubt';

  @override
  String get aiAllowedNone =>
      'Simulierte Geräte und Replays fragen nie. Auf echter Hardware fragt jede Aktion, außer du erlaubst sie für die Sitzung. Scharf schalten und Start fragen immer.';

  @override
  String aiAllowedSome(String actions) {
    return 'Für diese Sitzung: $actions. Scharf schalten und Start fragen immer.';
  }

  @override
  String get aiFromNetwork => 'Aus diesem Netz';

  @override
  String aiFromNetworkOn(String url, String token) {
    return 'Assistenten auf anderen Computern: $url mit dem Token $token… (kopiere es vom Reiter Andere).';
  }

  @override
  String get aiFromNetworkOff => 'Lass einen Assistenten auf einem anderen Computer dieses dash nutzen, mit einem Token.';

  @override
  String get aiActivity => 'Assistenten-Aktivität';

  @override
  String get nothingYet => 'Noch nichts.';

  @override
  String get aiShort => 'KI';

  @override
  String aiAsks(String client) {
    return '$client fragt';
  }

  @override
  String aiRealHardware(String device) {
    return '$device ist echte Hardware.';
  }

  @override
  String aiAllowSession(String device) {
    return 'Diese Art Aktion auf $device für diese Sitzung erlauben';
  }

  @override
  String get refuse => 'Ablehnen';

  @override
  String get approve => 'Zulassen';

  @override
  String get recordingsAndLogs => 'Aufnahmen und Fluglogs';

  @override
  String fileUnreadable(String error) {
    return 'Die Datei konnte nicht gelesen werden: $error';
  }

  @override
  String get fromFile => 'Aus einer Datei';

  @override
  String get fromFileDesc => 'Öffnet sich als Sitzung: Replay, Karte, Diagramme und Export funktionieren damit.';

  @override
  String get fmtJson => 'Eine aus koebelt/dash exportierte Aufnahme';

  @override
  String get fmtBin => 'ArduPilot-Log, von der SD-Karte oder aus Mission Planner';

  @override
  String get fmtTlog => 'Bodenstations-Log: Mission Planner, QGroundControl, MAVProxy';

  @override
  String get fmtUlg => 'PX4-Log, von der SD-Karte oder aus QGroundControl';

  @override
  String reading(String file) {
    return 'Lese $file…';
  }

  @override
  String get stopRecordingFirst => 'Erst die Aufnahme stoppen';

  @override
  String get notImported => 'Nicht importiert';

  @override
  String get sampleRecordings => 'Beispielaufnahmen';

  @override
  String get samplesIn => 'Die drei Demo-Sitzungen sind in deiner Liste, als Demo markiert.';

  @override
  String get samplesDesc => 'Drei Demo-Sitzungen mit den simulierten Geräten: ein Vermessungsflug, ein Pick-and-Place, ein Raketenstart.';

  @override
  String get removeSamples => 'Beispiele entfernen';

  @override
  String get loadSamples => 'Beispiele laden';

  @override
  String get exporting => 'Exportiere…';

  @override
  String exportFormat(String format) {
    return 'Als $format exportieren';
  }

  @override
  String frames(int count) {
    return '$count Frames';
  }

  @override
  String csvColumns(int count) {
    return '$count Spalten · nur Kanäle, die dieses Gerät gesendet hat';
  }

  @override
  String get noGpx => 'Kein GPS in dieser Aufnahme, also kein GPX-Track';

  @override
  String encoding(String format, int pct) {
    return 'Kodiere $format · $pct %';
  }

  @override
  String get exported => 'Exportiert';

  @override
  String get exportFailed => 'Export fehlgeschlagen';

  @override
  String get decrease => 'Verringern';

  @override
  String get increase => 'Erhöhen';

  @override
  String was(String value) {
    return 'vorher $value';
  }

  @override
  String firmware(String version) {
    return 'Firmware $version';
  }

  @override
  String parametersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Parameter', one: '1 Parameter');
    return '$_temp0';
  }

  @override
  String get parameters => 'Parameter';

  @override
  String unsaved(int count) {
    return '$count ungespeichert';
  }

  @override
  String written(String when) {
    return 'Geschrieben $when';
  }

  @override
  String get inSync => 'Synchron';

  @override
  String get revert => 'Zurücksetzen';

  @override
  String get writing => 'Schreibe…';

  @override
  String get writeToDevice => 'Aufs Gerät schreiben';

  @override
  String get searchParameters => 'Parameter suchen';

  @override
  String get waitingParams => 'Warte auf die Parametertabelle…';

  @override
  String noParamsMatch(String query) {
    return 'Kein Parameter passt zu „$query“';
  }

  @override
  String revertName(String name) {
    return '$name zurücksetzen';
  }

  @override
  String get liveResponse => 'Live-Antwort';

  @override
  String get copied => 'Kopiert';

  @override
  String get yourPairingCode => 'Dein Kopplungscode · 10 Min. gültig';

  @override
  String namePaired(String name) {
    return '$name gekoppelt';
  }

  @override
  String get startListening => 'Lauschen starten';

  @override
  String get listeningWifiBle => 'Lausche über WLAN und BLE · schalte dein Gerät ein';

  @override
  String nameFound(String name) {
    return '$name gefunden';
  }

  @override
  String sensorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Sensoren', one: '1 Sensor');
    return '$_temp0';
  }

  @override
  String get addToDevices => 'Zu Geräten hinzufügen';

  @override
  String get connectNow => 'Jetzt verbinden';

  @override
  String get inTheApp => 'In der App';

  @override
  String get completeProgram => 'Vollständiges Programm';

  @override
  String get apiReference => 'API-Referenz';

  @override
  String get exampleProjects => 'Beispielprojekte';

  @override
  String get allGuides => 'Alle Anleitungen';

  @override
  String stepOfUpper(int n, int total) {
    return 'Schritt $n von $total';
  }

  @override
  String get flowDevice => 'Dein Gerät';

  @override
  String get flowDeviceDesc => 'Sensoren, Motoren und koebelt/link auf dem Board oder Begleitcomputer.';

  @override
  String get flowLinkDesc => 'WLAN, BLE, USB-Seriell oder Funk, mit einem Ersatzlink, falls einer abbricht.';

  @override
  String get flowDashDesc => 'Dashboards, Steuerung, Tuning und Aufnahme, auf Handy, Tablet oder Desktop.';

  @override
  String get library => 'Bibliothek';

  @override
  String get connectHardware => 'Verbinde deine Hardware';

  @override
  String get connectHardwareDesc =>
      'Dein Gerät führt eine kleine Bibliothek aus, die Sensoren an diese App streamt und Steuerbefehle empfängt. Wähle deine Plattform zum Start.';

  @override
  String get guidesConnections => 'Verbindungen';

  @override
  String get guidesConnectionsDesc => 'Wie jeder Link funktioniert und was zu tun ist, wenn ein Gerät nicht erscheint.';

  @override
  String get guidesDevices => 'Gerätebeispiele';

  @override
  String get guidesDevicesDesc => 'Ein vollständiges, kommentiertes Programm für jede Geräteart.';

  @override
  String get guidesFeatures => 'Video, Karte und Controller';

  @override
  String get guidesFeaturesDesc => 'Eine Kamera zeigen, das Gerät auf eine Karte setzen, mit einem Gamepad steuern.';

  @override
  String get guidesMore => 'Weiterführend';

  @override
  String get guidesMoreDesc => 'Eigene Daten, Tuning, Sequenzen und Sicherheit.';

  @override
  String get viewChase => 'CHASE';

  @override
  String get viewOrbit => 'ORBIT';

  @override
  String get viewTop => 'TOP';

  @override
  String get viewMap => 'KARTE';

  @override
  String get viewCam => 'CAM';

  @override
  String get noMapboxToken => 'Diese Version hat kein Mapbox-Token: Gib unten dein eigenes ein oder wähle eine andere Quelle.';

  @override
  String get waitingGps => 'Warte auf einen GPS-Fix';

  @override
  String get grid => 'Raster';

  @override
  String get waitingScript => 'Warte auf das Skript';

  @override
  String get scriptEnded => 'Skript beendet';

  @override
  String get noVideo => 'Diese Aufnahme hat kein Video.';

  @override
  String get noCamera => 'Keine Kamera. Geräte deklarieren Kameras mit video() in der Bibliothek.';

  @override
  String cameraByIp(String name) {
    return 'Diese Kamera wird per IP-Adresse erreicht. Verbinde dich per WLAN mit $name, um sie zu sehen.';
  }

  @override
  String get warning => 'Warnung';

  @override
  String get alBattery => 'Akku schwach';

  @override
  String get alBatteryDesc => 'Restladung, wie das Gerät sie meldet.';

  @override
  String get alBatteryAct => 'Zeit, es zurückzuholen.';

  @override
  String get alBatteryCritical => 'Akku kritisch';

  @override
  String get alBatteryCriticalDesc => 'Eine zweite, lautere Grenze: wiederholt sich bis zur Bestätigung.';

  @override
  String get alBatteryCriticalAct => 'Jetzt landen oder stoppen.';

  @override
  String get alVoltage => 'Akkuspannung';

  @override
  String get alVoltageDesc => 'Für Akkus ohne Prozentangabe. Stell die Grenze für deinen Akku ein, zum Beispiel 3,5 V pro Zelle.';

  @override
  String get alVoltageAct => 'Zeit, es zurückzuholen.';

  @override
  String get alObstacle => 'Hindernis nah';

  @override
  String get alObstacleDesc => 'Das Nächste, was ein Näherungssensor sieht, solange scharf (nach unten gerichtete Sensoren zählen nicht).';

  @override
  String get alObstacleAct => 'Ausweichen oder stoppen.';

  @override
  String get alRssi => 'Schwaches Signal';

  @override
  String get alRssiDesc => 'Empfangene Signalstärke, wenn der Link sie meldet.';

  @override
  String get alRssiAct => 'Komm näher oder dreh um.';

  @override
  String get alLatency => 'Hohe Latenz';

  @override
  String get alLatencyDesc => 'Umlaufzeit des Links. Über ein paar hundert Millisekunden fühlt sich die Steuerung verzögert an.';

  @override
  String get alLatencyAct => 'Die Steuerung wird sich verzögert anfühlen.';

  @override
  String get alAltitude => 'Höhengrenze';

  @override
  String get alAltitudeDesc => 'Höhe über Home. 120 m ist die übliche Grenze für Drohnen in Europa und den USA.';

  @override
  String get alAltitudeAct => 'Sinken.';

  @override
  String get alDistance => 'Entfernung von Home';

  @override
  String get alDistanceDesc => 'Ein einfacher Geofence: horizontale Entfernung vom Startpunkt.';

  @override
  String get alDistanceAct => 'Hol es näher.';

  @override
  String get alTemp => 'Temperatur';

  @override
  String get alTempDesc => 'Motor-, ESC- oder Board-Temperatur, wenn das Gerät eine meldet.';

  @override
  String get alTempAct => 'Lass es abkühlen.';

  @override
  String get kindDrone => 'Drohne';

  @override
  String get kindPlane => 'Flugzeug';

  @override
  String get kindRover => 'Bodenroboter';

  @override
  String get kindBoat => 'Boot';

  @override
  String get kindArm => 'Roboterarm';

  @override
  String get kindRocket => 'Rakete';

  @override
  String get kindBench => 'Prüfstand';

  @override
  String get kindGeneric => 'Gerät';

  @override
  String get stTakeoff => 'Starten';

  @override
  String get stFlyTo => 'Fliegen zu';

  @override
  String get stLand => 'Landen';

  @override
  String get stRth => 'Nach Hause';

  @override
  String get stDriveTo => 'Fahren zu';

  @override
  String get stPose => 'Pose anfahren';

  @override
  String get stRamp => 'Rampe';

  @override
  String get stWait => 'Warten';

  @override
  String get stMode => 'Modus setzen';

  @override
  String get stArm => 'Scharf / entschärfen';

  @override
  String get stCmd => 'Eigener Befehl';

  @override
  String get fEast => 'Ost';

  @override
  String get fNorth => 'Nord';

  @override
  String get fHold => 'Halten';

  @override
  String get fFrom => 'Von';

  @override
  String get fTo => 'Bis';

  @override
  String get fOver => 'Über';

  @override
  String get fDuration => 'Dauer';

  @override
  String get fMode => 'Modus';

  @override
  String get fState => 'Zustand';

  @override
  String get fLimit => 'Grenze';

  @override
  String get fCommand => 'Befehl';

  @override
  String get fValue => 'Wert';

  @override
  String sumTakeoff(String alt) {
    return 'Starten auf $alt';
  }

  @override
  String sumFlyTo(String x, String y, String z) {
    return 'Fliegen zu $x, $y in $z';
  }

  @override
  String sumDriveTo(String x, String y) {
    return 'Fahren zu $x, $y';
  }

  @override
  String get sumRth => 'Nach Hause und landen';

  @override
  String sumPose(String joints) {
    return 'Pose anfahren $joints°';
  }

  @override
  String sumGripper(String pct) {
    return 'Greifer $pct % offen';
  }

  @override
  String sumThrottle(String pct, String s) {
    return 'Gas $pct % für $s s';
  }

  @override
  String sumRamp(String from, String to, String s) {
    return 'Rampe $from bis $to % in $s s';
  }

  @override
  String sumWait(String s) {
    return '$s s warten';
  }

  @override
  String sumMode(String mode) {
    return 'Modus $mode';
  }

  @override
  String get sumArm => 'Scharf schalten';

  @override
  String get sumDisarm => 'Entschärfen';

  @override
  String sumSpeed(String pct) {
    return 'Tempolimit $pct %';
  }

  @override
  String sumCmd(String name, String value) {
    return 'Befehl $name = $value';
  }

  @override
  String get stoppedEstop => 'Gestoppt: Not-Stopp';

  @override
  String completedIn(String seconds) {
    return 'Fertig in $seconds s';
  }

  @override
  String stepTimedOut(int n, String step) {
    return 'Zeitüberschreitung bei Schritt $n: $step';
  }

  @override
  String metresToGo(String length) {
    return 'noch $length';
  }

  @override
  String get uploadingToDevice => 'Lade aufs Gerät';

  @override
  String get starting => 'Starte';

  @override
  String get completedOnDevice => 'Auf dem Gerät abgeschlossen';

  @override
  String get deviceRejected => 'Das Gerät hat die Sequenz nicht angenommen';

  @override
  String get linkLostCarriesOn => 'Link verloren · das Gerät macht weiter';

  @override
  String get stoppedDisconnected => 'Gestoppt: getrennt';

  @override
  String get stoppedTookControl => 'Gestoppt: du hast übernommen';

  @override
  String get stoppedManual => 'Gestoppt: manuelle Steuerung';

  @override
  String get stoppedByScript => 'Vom Skript gestoppt';

  @override
  String get reqAnyDevice => 'ein Gerät';

  @override
  String reqKinds(String kinds) {
    return '$kinds';
  }

  @override
  String reqWith(String kinds, String needs) {
    return '$kinds mit $needs';
  }

  @override
  String reqWrongKind(String name, String kind, String needs) {
    return '$name: $kind, dieses Skript braucht aber $needs.';
  }

  @override
  String reqLacks(String name, String lacks, String needs) {
    return '$name fehlt $lacks; dieses Skript braucht $needs.';
  }

  @override
  String get trgButton => 'Button';

  @override
  String get trgSwitch => 'Schalter';

  @override
  String get trgSlider => 'Slider';

  @override
  String get trgController => 'Controller';

  @override
  String get trgCondition => 'Bedingung';

  @override
  String get trgEvent => 'Geräteereignis';

  @override
  String get trgTimer => 'Timer';

  @override
  String get evMode => 'Moduswechsel';

  @override
  String get evFailsafe => 'Failsafe';

  @override
  String get evSeqDone => 'Sequenz beendet';

  @override
  String get evLog => 'Gerätemeldung';

  @override
  String get onControl => 'in Steuerung';

  @override
  String everyN(String seconds) {
    return 'Alle $seconds s';
  }

  @override
  String onceAfterN(String seconds) {
    return 'Einmal nach $seconds s';
  }

  @override
  String get paArm => 'Scharf / entschärfen';

  @override
  String get paManual => 'Manuell';

  @override
  String get paHold => 'Halten';

  @override
  String get paAuto => 'Zurück ans Skript';

  @override
  String get paSlower => 'Langsamer';

  @override
  String get paFaster => 'Schneller';

  @override
  String get paFrame => 'Gelenk / kartesisch';

  @override
  String get paWrist => 'Handgelenk';

  @override
  String get paNext => 'Nächstes Gerät';

  @override
  String get paStopHint => 'Not-Stopp, sofort';

  @override
  String get paHoldHint => 'Eine Sekunde halten';

  @override
  String paSwitchTo(String mode) {
    return 'Wechsel zu $mode';
  }

  @override
  String get paAutoHint => 'Nach dem Übernehmen die Sticks ans Skript zurückgeben (AUTO)';

  @override
  String paSwitchToDrones(String mode) {
    return 'Wechsel zu $mode (Drohnen)';
  }

  @override
  String get paHoldDronesHint => 'Eine Sekunde halten (Drohnen)';

  @override
  String get paRecordHint => 'Aufnahme starten oder stoppen';

  @override
  String get paSlowerHint => 'Tempolimit um 10 % senken';

  @override
  String get paFasterHint => 'Tempolimit um 10 % erhöhen';

  @override
  String get paFrameHint => 'Arme: was die Sticks bewegen';

  @override
  String get paWristHint => 'Arme: rechter Stick bewegt J5 und J6 statt J3 und J4';

  @override
  String get paGripperHint => 'Arme: öffnen oder schließen';

  @override
  String get paNextHint => 'Mehrere verbunden: das nächste zeigen und steuern';

  @override
  String get notSet => 'Nicht belegt';

  @override
  String get padLeftStickX => 'Linker Stick X';

  @override
  String get padLeftStickY => 'Linker Stick Y';

  @override
  String get padRightStickX => 'Rechter Stick X';

  @override
  String get padRightStickY => 'Rechter Stick Y';

  @override
  String get padLeftTrigger => 'Linker Trigger';

  @override
  String get padRightTrigger => 'Rechter Trigger';

  @override
  String get padACross => 'A / Kreuz';

  @override
  String get padBCircle => 'B / Kreis';

  @override
  String get padXSquare => 'X / Quadrat';

  @override
  String get padYTriangle => 'Y / Dreieck';

  @override
  String get padLeftBumper => 'Linker Bumper';

  @override
  String get padRightBumper => 'Rechter Bumper';

  @override
  String get padBackShare => 'Back / Share';

  @override
  String get padStartOptions => 'Start / Options';

  @override
  String get padHome => 'Home';

  @override
  String get padLeftStickPress => 'Linker Stick drücken';

  @override
  String get padRightStickPress => 'Rechter Stick drücken';

  @override
  String get padDPadUp => 'D-Pad hoch';

  @override
  String get padDPadDown => 'D-Pad runter';

  @override
  String get padDPadLeft => 'D-Pad links';

  @override
  String get padDPadRight => 'D-Pad rechts';

  @override
  String get radioSik => 'SiK-Telemetriefunk';

  @override
  String get radioLoraName => 'LoRa-Bodenstation';

  @override
  String get radioOther => 'Anderes serielles Funkmodul';

  @override
  String get radioSikDesc => '433 / 868 / 915 MHz-Paare: 3DR, Holybro, RFD900. Transparent seriell bis etwa 1 km, 40 km mit RFD900.';

  @override
  String get radioLoraDesc => 'Ein Board mit LoRa-Funk über USB, mit dem Bodenstations-Sketch geflasht. 2 bis 10 km, nur Telemetrie.';

  @override
  String get radioHc12Desc => 'Günstiges transparentes serielles Modul an einem USB-Adapter. Etwa 1 km bei 9600 Baud.';

  @override
  String get radioXbeeDesc => 'Digi XBee im transparenten Modus auf einem USB-Explorer-Board. 2,4 GHz oder 900 MHz.';

  @override
  String get radioOtherDesc => 'Jedes transparente serielle Funkmodul. Stell seine Baudrate ein; die App nutzt vorsichtige Raten.';

  @override
  String get tplLoop => 'Eine Regelschleife';

  @override
  String get tplButton => 'Eine Aktion per Button';

  @override
  String get fldBattery => 'Akku';

  @override
  String get fldBatteryVoltage => 'Akkuspannung';

  @override
  String get fldDistanceFromHome => 'Entfernung von Home';

  @override
  String get fldHeightAboveHome => 'Höhe über Home';

  @override
  String get fldSpeed => 'Tempo';

  @override
  String get fldHeading => 'Kurs';

  @override
  String get fldRoll => 'Roll';

  @override
  String get fldPitch => 'Nick';

  @override
  String get fldGripper => 'Greifer';

  @override
  String get fldThrust => 'Schub';

  @override
  String get fldRpm => 'U/min';

  @override
  String get fldTemperature => 'Temperatur';

  @override
  String get fldNearestObstacle => 'Nächstes Hindernis';

  @override
  String get fldSignal => 'Signal';

  @override
  String get fldLatency => 'Latenz';

  @override
  String get fldGpsSatellites => 'GPS-Satelliten';

  @override
  String get ready => 'Bereit.';

  @override
  String get pythonManaged => 'Dieses Python wird vom System verwaltet und lehnt Pakete ab: nutze stattdessen eine Skriptumgebung.';

  @override
  String failedWhy(String why) {
    return 'Fehlgeschlagen: $why';
  }

  @override
  String get pipNoPackage => 'pip ist fertig, aber koebelt-dash-scripts ist noch immer nicht in diesem Python.';

  @override
  String packageUpToDate(String version) {
    return 'koebelt-dash-scripts $version ist in diesem Python aktuell.';
  }

  @override
  String packageInstalled(String version) {
    return 'koebelt-dash-scripts $version ist in diesem Python installiert.';
  }

  @override
  String packagesInstalled(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names sind in diesem Python installiert.',
      one: '$names ist in diesem Python installiert.',
    );
    return '$_temp0';
  }

  @override
  String envReady(String version) {
    return 'Die Skriptumgebung ist bereit, mit koebelt-dash-scripts $version.';
  }

  @override
  String atMostDevices(int count) {
    return 'Höchstens $count Geräte gleichzeitig. Trenne zuerst eins.';
  }

  @override
  String noAnswerFrom(String name) {
    return 'Keine Antwort von $name';
  }

  @override
  String noHostAt(String address) {
    return 'Kein Skript-Host unter $address. Läuft dort `koebelt-dash-scripts host`?';
  }

  @override
  String get hostRefused => 'Der Host hat abgelehnt.';

  @override
  String get logUnknown =>
      'Diese Datei ist kein Log, das die App lesen kann. Sie öffnet JSON-Exporte von koebelt/dash, ArduPilot-Logs (.bin und .tlog) und PX4-Logs (.ulg).';

  @override
  String logEmpty(String format) {
    return 'Die $format-Datei hat keine Telemetrie, die die App zeigen kann (Lage, Position, Akku).';
  }

  @override
  String get logJsonUnreadable => 'Diese JSON-Datei konnte nicht gelesen werden.';

  @override
  String get logJsonNotExport => 'Diese JSON-Datei ist kein Aufnahme-Export von koebelt/dash.';

  @override
  String get logNoHeartbeat => 'Dieses .tlog hat keinen Fahrzeug-Heartbeat, seine Meldungen lassen sich also keinem Fahrzeug zuordnen.';

  @override
  String get viewDevices => 'Geräte ansehen';

  @override
  String get simulatedTip => 'In der App simuliert, keine echte Hardware';

  @override
  String get newShort => 'Neu';
}
