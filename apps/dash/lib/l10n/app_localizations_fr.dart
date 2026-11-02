// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navLive => 'Direct';

  @override
  String get navControl => 'Pilotage';

  @override
  String get navAutomate => 'Automatiser';

  @override
  String get navTune => 'Paramètres';

  @override
  String get navReplay => 'Relecture';

  @override
  String get navDevices => 'Appareils';

  @override
  String get navGuides => 'Guides';

  @override
  String get navSettings => 'Réglages';

  @override
  String get navSequences => 'Séquences';

  @override
  String get navScripts => 'Scripts';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageDesc => 'La langue de l’app. Les guides pas encore traduits restent en anglais.';

  @override
  String settingsLanguageSystem(String name) {
    return 'Celle du système ($name)';
  }

  @override
  String toastSaved(String name) {
    return 'Enregistré sous $name';
  }

  @override
  String get stopEngagedBar => 'Arrêt actif · touchez pour réarmer';

  @override
  String get stopEngagedTitle => 'Arrêt d’urgence actif';

  @override
  String get stopKeep => 'Rester arrêté';

  @override
  String get stopResetAll => 'Tout réarmer';

  @override
  String get stopReset => 'Lever l’arrêt';

  @override
  String stopBody(String names) {
    return 'Les moteurs sont arrêtés et toute commande de mouvement est bloquée sur $names.';
  }

  @override
  String get theDevice => 'l’appareil';

  @override
  String get stopCheck => 'Vérifiez l’appareil avant de lever l’arrêt. Il reste ensuite désarmé jusqu’à ce que vous le réarmiez.';

  @override
  String get fleet => 'Flotte';

  @override
  String get tagSim => 'Sim';

  @override
  String get fleetActive => 'Actif';

  @override
  String get fleetLost => 'Perdu';

  @override
  String get fleetLinked => 'Lié';

  @override
  String get fleetOff => 'Éteint';

  @override
  String get fleetOn => 'Allumé';

  @override
  String get connecting => 'Connexion';

  @override
  String get noLink => 'Pas de liaison';

  @override
  String get simulated => 'Simulé';

  @override
  String get statLink => 'Liaison';

  @override
  String get statLost => 'Perdue';

  @override
  String get statLatency => 'Latence';

  @override
  String get statBattery => 'Batterie';

  @override
  String get statRecording => 'Enregistrement';

  @override
  String get armed => 'Armé';

  @override
  String get disarmed => 'Désarmé';

  @override
  String stopLabelAll(int count) {
    return 'Arrêt d’urgence, les $count appareils';
  }

  @override
  String get stopLabel => 'Arrêt d’urgence';

  @override
  String stopTipAll(int count) {
    return 'Arrête les $count appareils connectés';
  }

  @override
  String get stopTipSlowRadio => 'STOP passe aussi par cette radio de télémesure, mais lentement : jusqu’à une seconde';

  @override
  String get stopAll => 'Tout arrêter';

  @override
  String get stop => 'Stop';

  @override
  String get failsafeHold => 'maintien de la position';

  @override
  String get failsafeRth => 'retour au point de départ';

  @override
  String get failsafeLand => 'atterrissage sur place';

  @override
  String linkLostFor(String seconds) {
    return 'Liaison perdue · $seconds s';
  }

  @override
  String failsafeActive(String action) {
    return 'Sécurité active : $action.';
  }

  @override
  String get reconnecting => 'Reconnexion. La sécurité se déclenche à 1,8 s.';

  @override
  String get controlsLocked => 'Les commandes sont bloquées jusqu’au retour de la liaison.';

  @override
  String get linkRestored => 'Liaison rétablie';

  @override
  String get linkRestoredBody => 'Le pilotage manuel est de nouveau possible.';

  @override
  String alertBelow(String limit) {
    return 'Sous $limit.';
  }

  @override
  String alertAbove(String limit) {
    return 'Au-dessus de $limit.';
  }

  @override
  String get linkLostOther => 'Sa sécurité prend le relais après 1,8 s.';

  @override
  String get compatNewerApp => 'Demande une app plus récente';

  @override
  String get compatOldLib => 'Bibliothèque trop ancienne';

  @override
  String compatSome(String why) {
    return 'Certaines fonctions peuvent ne pas marcher : $why.';
  }

  @override
  String get compatUpdateApp => 'Mettez à jour koebelt dash.';

  @override
  String get compatUpdateLib =>
      'Mettez à jour la bibliothèque koebelt/link de l’appareil, ou installez un koebelt dash plus ancien dans Réglages > Mises à jour.';

  @override
  String get show => 'Afficher';

  @override
  String alerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count alertes', one: '1 alerte');
    return '$_temp0';
  }

  @override
  String get linkLost => 'Liaison perdue';

  @override
  String get replayOffControl => 'Les commandes sont coupées pendant une relecture';

  @override
  String get replayOffControlWhy => 'Les commandes agissent sur un appareil connecté, pas sur un enregistrement.';

  @override
  String get replayOffSequences => 'Les séquences sont coupées pendant une relecture';

  @override
  String get replayOffSequencesWhy => 'Les séquences s’exécutent sur un appareil connecté, pas sur un enregistrement.';

  @override
  String get replayOffTune => 'Les réglages sont coupés pendant une relecture';

  @override
  String get replayOffTuneWhy => 'Les paramètres se lisent et s’écrivent sur un appareil connecté, pas sur un enregistrement.';

  @override
  String replayExitTo(String name) {
    return 'Quittez la relecture pour revenir à $name.';
  }

  @override
  String get replayExitConnect => 'Quittez la relecture, puis connectez un appareil.';

  @override
  String get replayBack => 'Retour à la relecture';

  @override
  String replayExitBackTo(String name) {
    return 'Quitter la relecture, revenir à $name';
  }

  @override
  String get replayExit => 'Quitter la relecture';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get noDeviceTitle => 'Aucun appareil connecté';

  @override
  String get noDeviceBody =>
      'Choisissez un appareil appairé ou appairez-en un nouveau. La télémesure et les commandes apparaissent une fois la liaison établie.';

  @override
  String get connectFailed => 'Connexion impossible';

  @override
  String get noPairedDevices => 'Aucun appareil appairé pour l’instant.';

  @override
  String get offline => 'Hors ligne';

  @override
  String batteryPct(int pct) {
    return 'Batterie $pct %';
  }

  @override
  String get connect => 'Connecter';

  @override
  String get pairNewDevice => 'Appairer un appareil';

  @override
  String get or => 'Ou';

  @override
  String get addSimulated => 'Ajouter un appareil simulé';

  @override
  String get addSimulatedDesc => 'Un drone, rover, bras, fusée ou banc d’essai virtuel, pour essayer l’app sans matériel.';

  @override
  String get openRecording => 'Ouvrir un enregistrement';

  @override
  String get openRecordingDesc => 'Rejouer une session, un journal de vol ou les enregistrements d’exemple.';

  @override
  String get setUpLibrary => 'Installer la bibliothèque';

  @override
  String get setUpLibraryDesc => 'Ajoutez koebelt/link à votre projet Arduino, Python, ROS 2 ou Rust.';

  @override
  String get noDevice => 'Aucun appareil';

  @override
  String get tagDemo => 'Démo';

  @override
  String moreConnected(int count) {
    return '+$count connectés';
  }

  @override
  String get alsoConnected => 'Aussi connectés';

  @override
  String get disconnectAll => 'Tout déconnecter';

  @override
  String get connectAnother => 'En connecter un autre';

  @override
  String get pairedDevices => 'Appareils appairés';

  @override
  String get noPairedDevicesShort => 'Aucun appareil appairé';

  @override
  String get noPairedDevicesHint => 'Appairez-en un, ajoutez un appareil simulé ou suivez le démarrage rapide.';

  @override
  String get pairDevice => 'Appairer';

  @override
  String get quickstart => 'Démarrage rapide';

  @override
  String get manage => 'Gérer';

  @override
  String get replaying => 'Relecture en cours';

  @override
  String get closeReplay => 'Fermer la relecture';

  @override
  String get simulator => 'Simulateur';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get open => 'Ouvrir';

  @override
  String get sequenceRunning => 'séquence en cours';

  @override
  String disconnectName(String name) {
    return 'Déconnecter $name';
  }

  @override
  String get automateSeqBlurb => 'Des étapes dans l’ordre, sans code : décoller, voler vers, attendre, atterrir ; rouler vers ; aller à une pose.';

  @override
  String get automateSeqPoint1 => 'Sans code : construite dans l’app';

  @override
  String get automateSeqPoint2 => 'S’exécute sur l’appareil quand il peut la stocker';

  @override
  String get automateSeqPoint3 => 'Continue si la liaison tombe';

  @override
  String get automateSeqConnect => 'Connectez un appareil pour construire ses séquences';

  @override
  String automateSeqCount(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count séquences', one: '1 séquence', zero: 'Aucune séquence');
    return '$_temp0 pour $name';
  }

  @override
  String get automateScriptBlurb => 'Du Python qui lit la télémesure et la caméra, décide, et pilote l’appareil.';

  @override
  String get automateScriptPoint1 => 'Logique, capteurs, caméra';

  @override
  String get automateScriptPoint2 => 'N’importe quelle bibliothèque : OpenCV, PyTorch, YOLO';

  @override
  String get automateScriptPoint3 => 'Déclencheurs : boutons, touches, conditions, minuteries';

  @override
  String get automateScriptPoint3Host => 'S’exécute sur un hôte de scripts : un ordinateur de votre réseau';

  @override
  String scriptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count scripts', one: '1 script', zero: 'Aucun script');
    return '$_temp0';
  }

  @override
  String get automateEyebrow => 'Deux façons d’automatiser';

  @override
  String runningOn(String what, String device) {
    return '$what sur $device';
  }

  @override
  String get automateTogether1 => 'Ensemble : un script peut lancer une séquence, ';

  @override
  String get automateTogether2 => ', et décider quand.';

  @override
  String get sequenceOrScript => 'Séquence ou script ?';

  @override
  String get running => 'En cours';

  @override
  String get layoutHud => 'HUD';

  @override
  String get layoutWall => 'MUR';

  @override
  String get editLayout => 'Modifier la disposition';

  @override
  String get sceneLayers3d => 'Calques de la scène 3D';

  @override
  String get layerCloud => 'Nuage de points';

  @override
  String get layerTrail => 'Trajectoire';

  @override
  String get layerRadar => 'Pistes radar';

  @override
  String get layerGrid => 'Grille au sol';

  @override
  String get sceneLayers => 'Calques de la scène';

  @override
  String get addWidget => 'Ajouter un widget';

  @override
  String widgetsSavedFor(String device, String screens) {
    return 'Les widgets sont enregistrés pour $device sur les écrans $screens.';
  }

  @override
  String get thisDevice => 'cet appareil';

  @override
  String get screenPhone => 'de téléphone';

  @override
  String get screenShort => 'de téléphone à l’horizontale';

  @override
  String get screenPortrait => 'de tablette à la verticale';

  @override
  String get screenTablet => 'de tablette';

  @override
  String get screenDesktop => 'd’ordinateur';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get cancel => 'Annuler';

  @override
  String get saveLayout => 'Enregistrer la disposition';

  @override
  String get back => 'Retour';

  @override
  String get paused => 'En pause';

  @override
  String get stale => 'Figé';

  @override
  String hzLive(int hz) {
    return '$hz Hz en direct';
  }

  @override
  String get resume => 'Reprendre';

  @override
  String get pause => 'Pause';

  @override
  String get statMin => 'Min';

  @override
  String get statMax => 'Max';

  @override
  String get statMean => 'Moy.';

  @override
  String get unit => 'Unité';

  @override
  String get window => 'Fenêtre';

  @override
  String get windowValue => '10 s · 300 mesures';

  @override
  String get source => 'Source';

  @override
  String get tapChannelToHide => 'Touchez une voie pour la masquer';

  @override
  String get rec => 'Rec';

  @override
  String get speedLimit => 'Vitesse max';

  @override
  String get setHomePose => 'Définir la pose de départ';

  @override
  String get setHomeHere => 'Définir le départ ici';

  @override
  String get useThisPose => 'Utiliser cette pose';

  @override
  String get setHome => 'Définir le départ';

  @override
  String get setHomePoseBody => 'Les angles actuels des articulations deviennent la pose où vont Pose de départ et les étapes Départ des séquences.';

  @override
  String setHomeBody(String metres) {
    return 'La position actuelle devient le point de départ (0, 0). Le retour au départ revient ici, et les points des séquences se mesurent depuis ici. L’appareil est à $metres m du départ actuel.';
  }

  @override
  String get autoDashDrives => 'dash le pilote';

  @override
  String get autoTakeBack => 'Choisissez MANUAL ou HOLD, ou bougez les manches, pour reprendre la main.';

  @override
  String get autoTip => 'Le mode de dash : pendant qu’une séquence ou un script pilote l’appareil. Lancez-en un depuis Automatiser.';

  @override
  String get tiltDrag => 'Inclinaison · glissez pour simuler';

  @override
  String get stickThrottle => 'Gaz';

  @override
  String get stickDrive => 'Avancer';

  @override
  String get stickYaw => 'Lacet';

  @override
  String get stickPitchRoll => 'Tangage · roulis';

  @override
  String get stickSteer => 'Direction';

  @override
  String get stickThrottleYaw => 'Gaz · lacet';

  @override
  String get tiltPitchRoll => 'Inclinaison · tangage et roulis';

  @override
  String get tiltSteerDrive => 'Inclinaison · direction et avance';

  @override
  String get axUp => 'HAUT';

  @override
  String get axDn => 'BAS';

  @override
  String get axFwd => 'AV';

  @override
  String get axRev => 'AR';

  @override
  String get axBack => 'AR';

  @override
  String get axL => 'G';

  @override
  String get axR => 'D';

  @override
  String get axYaw => 'LACET';

  @override
  String get rdAlt => 'Alt';

  @override
  String get rdOdom => 'Odo';

  @override
  String get rdSpeed => 'Vitesse';

  @override
  String get rdHdg => 'Cap';

  @override
  String get rdHome => 'Départ';

  @override
  String get rdVz => 'Vz';

  @override
  String get rdMax => 'Max';

  @override
  String get rdRange => 'Distance';

  @override
  String get rdToolX => 'Outil X';

  @override
  String get rdToolY => 'Outil Y';

  @override
  String get rdToolZ => 'Outil Z';

  @override
  String get rdThrust => 'Poussée';

  @override
  String get rdRpm => 'tr/min';

  @override
  String get rdCurrent => 'Courant';

  @override
  String get rdPower => 'Puissance';

  @override
  String get rdTemp => 'Temp.';

  @override
  String get rdEfficiency => 'Rendement';

  @override
  String get homePose => 'Pose de départ';

  @override
  String get setAsHome => 'Définir comme départ';

  @override
  String get armJoint => 'Articulations';

  @override
  String get armCartesian => 'Cartésien';

  @override
  String get toolFrame => 'Repère outil · relatif à la base';

  @override
  String armPadHelp(String frame, String wristBtn, String wrist, String gripper) {
    return 'Manette · $frame : articulations / cartésien · $wristBtn : $wrist · $gripper : pince';
  }

  @override
  String get armWrist => 'poignet';

  @override
  String get gripper => 'Pince';

  @override
  String gripperOpenPct(int pct) {
    return 'Ouverte à $pct %';
  }

  @override
  String get gripperOpen => 'Ouvrir';

  @override
  String get gripperClose => 'Fermer';

  @override
  String get flightPhase => 'Phase de vol';

  @override
  String get phasePad => 'Sur le pas de tir';

  @override
  String get phaseCount => 'Compte à rebours';

  @override
  String get phaseBoost => 'Propulsion';

  @override
  String get phaseCoast => 'Vol balistique';

  @override
  String get phaseDrogue => 'Extracteur';

  @override
  String get phaseMain => 'Principal';

  @override
  String get phaseLanded => 'Posée';

  @override
  String get preflight => 'Avant le vol';

  @override
  String get checkPyro => 'Continuité pyro · extracteur, principal';

  @override
  String get ok => 'OK';

  @override
  String get check => 'Vérifier';

  @override
  String get checkGps => 'Fix GPS';

  @override
  String sats(int count) {
    return '$count sat.';
  }

  @override
  String get noFix => 'Pas de fix';

  @override
  String get checkFlightComputer => 'Ordinateur de vol';

  @override
  String get safe => 'Sécurisé';

  @override
  String get armFlightComputer => 'Armer l’ordinateur de vol';

  @override
  String get armPadClear => 'N’armez que lorsque le pas de tir est dégagé';

  @override
  String startCountdown(String seconds) {
    return 'Lancer le compte à rebours · $seconds s';
  }

  @override
  String get abortLaunch => 'Annuler le lancement';

  @override
  String get deployDrogue => 'Déployer l’extracteur';

  @override
  String get deployMain => 'Déployer le principal';

  @override
  String autoDeploy(String metres) {
    return 'Déploiement auto · extracteur à l’apogée · principal à $metres m';
  }

  @override
  String landedBody(String apogee, String distance) {
    return 'Apogée $apogee m · posée à $distance m du pas de tir.';
  }

  @override
  String get resetToPad => 'Retour au pas de tir';

  @override
  String get altitude => 'Altitude';

  @override
  String get cutoff => 'Coupure';

  @override
  String get cutoffLimit => 'limite';

  @override
  String get cutoffBody => 'Les gaz ont été remis à 0. Vérifiez le moteur avant de relancer.';

  @override
  String get clear => 'Effacer';

  @override
  String get benchDisarmed => 'Armez le banc pour faire tourner le moteur. Restez à l’écart de l’hélice.';

  @override
  String get testSequence => 'Séquence de test';

  @override
  String get benchRamp => 'RAMPE';

  @override
  String get benchSteps => 'PALIERS';

  @override
  String get runAndRecord => 'Lancer et enregistrer';

  @override
  String benchRampDesc(String seconds) {
    return 'Rampe de 0 à 100 % en $seconds s, maintien 2 s, arrêt.';
  }

  @override
  String benchStepsDesc(String size, String seconds) {
    return 'Paliers de $size %, $seconds s chacun, jusqu’à 100 %.';
  }

  @override
  String benchLimits(String amps, String celsius) {
    return 'Limites : $amps A, $celsius °C.';
  }

  @override
  String get mspTitle => 'Surveillance et réglages';

  @override
  String mspBody(String name, String firmware) {
    return '$name tourne sous $firmware et est connecté par MSP, la liaison de configuration. L’app affiche sa télémesure, règle ses gains PID dans Paramètres, et STOP le désarme. Pilotez-le avec votre radiocommande.';
  }

  @override
  String get radioOnlyTitle => 'Liaison de télémesure seule';

  @override
  String radioOnlyBody(String name, String radio) {
    return '$name est connecté par $radio, qui ne transporte que la télémesure. Les manches, les modes et les commandes n’atteignent pas l’appareil par là ; STOP oui, en une seconde environ. Pilotez-le par sa liaison principale (Wi-Fi, Bluetooth ou radio SiK) et comptez sur sa sécurité hors de portée.';
  }

  @override
  String get aRadio => 'une radio';

  @override
  String get tileReadouts => 'Mesures';

  @override
  String get tileSrcFused => 'État fusionné';

  @override
  String get tileAttitude => 'Attitude';

  @override
  String get tileAccelerometer => 'Accéléromètre';

  @override
  String get tileGyroscope => 'Gyroscope';

  @override
  String get tileSrcBaroRange => 'Baro + télémètre';

  @override
  String get tileRadar => 'Radar';

  @override
  String get tileSrcRadar => 'Radar / scanner de sécurité';

  @override
  String get tileLidar => 'Lidar';

  @override
  String get tileSrcLidar => 'Lidar à balayage';

  @override
  String get tileJoints => 'Articulations';

  @override
  String get tileSrcJoints => 'Codeurs d’articulation';

  @override
  String get tileForceTorque => 'Force / couple';

  @override
  String get tileSrcWrist => 'Capteur F/C au poignet';

  @override
  String get tileSrcPower => 'Module d’alimentation';

  @override
  String get tileSrcRadio => 'Liaison radio';

  @override
  String get tileCamera => 'Caméra';

  @override
  String get tileSrcCamera => 'Caméra de l’appareil · MJPEG';

  @override
  String get tileSrcFleet => 'Chaque appareil connecté';

  @override
  String get tileSrcPhase => 'Automate de l’ordinateur de vol';

  @override
  String get tileVerticalSpeed => 'Vitesse verticale';

  @override
  String get tileSrcBaroImu => 'Fusion baro + IMU';

  @override
  String get tilePyro => 'Voies pyro';

  @override
  String get tileSrcPyro => 'Carte pyro 4 voies';

  @override
  String get tileSrcTacho => 'Tachymètre optique';

  @override
  String get tileTorque => 'Couple';

  @override
  String get tileSrcTorque => 'Capteur de couple de réaction';

  @override
  String get tileMotorTemp => 'Temp. moteur';

  @override
  String get tileSrcNtc => 'Thermistance CTN';

  @override
  String get tileRollRate => 'Vitesse de roulis';

  @override
  String get tilePitchRate => 'Vitesse de tangage';

  @override
  String get tileYawRate => 'Vitesse de lacet';

  @override
  String get tileGroundSpeed => 'Vitesse sol';

  @override
  String get tileAgl => 'Hauteur sol';

  @override
  String get tileOwnSpeed => 'Vitesse propre';

  @override
  String get tileVoltage => 'Tension';

  @override
  String get tilePyroBus => 'Bus pyro';

  @override
  String get tileStator => 'Stator';

  @override
  String get tileVibration => 'Vibrations';

  @override
  String get tileAcc200 => 'Accéléromètre · 200 G';

  @override
  String get tileSafetyScanner => 'Scanner de sécurité';

  @override
  String tracks(int count) {
    return '$count pistes';
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
    return '$count connectés';
  }

  @override
  String armedCount(int count) {
    return '$count armées';
  }

  @override
  String get proxClear => 'dégagé';

  @override
  String get tileProximity => 'Proximité';

  @override
  String get tileSrcProx => 'Capteurs de proximité';

  @override
  String tileSrcCustom(String hz) {
    return 'Voie personnalisée · $hz Hz';
  }

  @override
  String get tagScript => 'Script';

  @override
  String get viewEnded => 'terminé';

  @override
  String series(int count) {
    return '$count séries';
  }

  @override
  String get rdReach => 'Portée';

  @override
  String get pyroDrogue => 'Extracteur';

  @override
  String get pyroMain => 'Principal';

  @override
  String get pyroAirstart => 'Allumage en vol';

  @override
  String get pyroSpare => 'Réserve';

  @override
  String get pyroContinuity => 'Continuité';

  @override
  String get pyroFired => 'Tiré';

  @override
  String get pyroNotWired => 'Non câblé';

  @override
  String removeTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get removeDevice => 'Retirer l’appareil';

  @override
  String removeBody(String name) {
    return 'La clé d’appairage, les dispositions HUD et les brouillons de paramètres de $name sont supprimés de l’app.';
  }

  @override
  String get removeDisconnectFirst => 'Il sera d’abord déconnecté.';

  @override
  String get removeKept => 'Les enregistrements sont gardés. Pour réutiliser l’appareil, appairez-le avec un nouveau code.';

  @override
  String onlineOf(int online, int total) {
    return '$online sur $total en ligne';
  }

  @override
  String get devicesEmptyHint => 'Appairez un appareil, ou suivez le démarrage rapide pour ajouter la bibliothèque à votre projet.';

  @override
  String get devicesSeveral =>
      'Plusieurs appareils peuvent être connectés à la fois. Celui affiché reçoit les manches ; les autres tiennent sur manches centrés, et STOP les arrête tous.';

  @override
  String get connected => 'Connecté';

  @override
  String removeName(String name) {
    return 'Retirer $name';
  }

  @override
  String get online => 'En ligne';

  @override
  String get batShort => 'BAT';

  @override
  String get myRobot => 'Mon robot';

  @override
  String radioNothingHeard(String port, int baud) {
    return 'Rien entendu sur $port à $baud bauds. Vérifiez que l’appareil est allumé, que les deux radios utilisent le même canal et le même débit radio, et que le débit série correspond. Vous pouvez quand même ajouter la liaison et vous connecter plus tard.';
  }

  @override
  String get pairTitle => 'Appairer un appareil';

  @override
  String get pairNearby => 'À proximité';

  @override
  String get pairRadio => 'Radio';

  @override
  String get pairSimulated => 'Simulés';

  @override
  String get pairSimulatedIntro =>
      'Les appareils simulés tournent dans l’app et parlent le même protocole que le vrai matériel. N’ajoutez que ceux dont vous avez besoin ; chacun porte l’étiquette SIM.';

  @override
  String get added => 'Ajouté';

  @override
  String get addAnother => 'En ajouter un autre';

  @override
  String get add => 'Ajouter';

  @override
  String radioRatesTlm(int tlm) {
    return 'Télémesure $tlm Hz · sans commande';
  }

  @override
  String radioRates(int tlm, int ctl) {
    return 'Télémesure $tlm Hz · commande $ctl Hz';
  }

  @override
  String get radioIntro =>
      'Une liaison radio est un modem radio branché en USB sur cet ordinateur ou ce téléphone, qui parle à une radio jumelle sur l’appareil.';

  @override
  String get radioIntroMore => 'Pour l’app c’est un port série ; le type de radio fixe la vitesse et ce qu’elle peut transporter.';

  @override
  String get radioNoSerial => 'Pas de port série USB sur cette plateforme';

  @override
  String get radioNoSerialBody =>
      'Les apps iOS ne peuvent pas ouvrir d’adaptateur série USB. Utilisez l’app sur Android, macOS, Windows ou Linux pour les liaisons radio, ou connectez-vous en Wi-Fi ou Bluetooth.';

  @override
  String get radioLora =>
      'Les modules LoRa ne sont pas des périphériques USB à eux seuls. Flashez le croquis de station sol du guide LoRa sur une seconde carte avec la radio, et branchez cette carte.';

  @override
  String get usbPort => 'Port USB';

  @override
  String get refresh => 'Actualiser';

  @override
  String get noSerialPorts => 'Aucun port série trouvé. Branchez l’adaptateur USB de la radio.';

  @override
  String get baudRate => 'Débit (bauds)';

  @override
  String heard(String name) {
    return '$name entendu';
  }

  @override
  String get heardMavlink => 'Il parle MAVLink : pas besoin d’appairage.';

  @override
  String get heardPairing => 'Il est en mode appairage et recevra une clé.';

  @override
  String get heardNoPairing => 'Il n’est pas en mode appairage ; il est ajouté sans clé.';

  @override
  String get listening => 'Écoute';

  @override
  String get listenForDevice => 'Écouter l’appareil';

  @override
  String pairName(String name) {
    return 'Appairer $name';
  }

  @override
  String get addRadioLink => 'Ajouter la liaison radio';

  @override
  String get pairNearbyIntro =>
      'Branchez ou allumez la carte. Les contrôleurs de vol et les drones apparaissent d’eux-mêmes ; les cartes avec la bibliothèque koebelt/link apparaissent aussi ici en mode appairage.';

  @override
  String get scanning => 'Recherche en Wi-Fi, Bluetooth et USB…';

  @override
  String get stillScanning => 'Recherche d’autres appareils…';

  @override
  String get addByIp => 'Ajouter par adresse IP';

  @override
  String get name => 'Nom';

  @override
  String get mavlinkPortNote => 'L’app écoute sur UDP 14550, comme toute station sol ; le port est celui du véhicule, si vous le connaissez.';

  @override
  String get addDevice => 'Ajouter l’appareil';

  @override
  String get notShowingUp =>
      'L’appareil n’apparaît pas ? Les cartes sous ArduPilot, PX4, Betaflight ou INAV se connectent telles quelles ; les autres ont besoin de la bibliothèque koebelt/link.';

  @override
  String get openQuickstart => 'Ouvrir le démarrage rapide';

  @override
  String get orLower => 'ou';

  @override
  String get addItByIp => 'l’ajouter par adresse IP';

  @override
  String get secControl => 'Pilotage';

  @override
  String get secController => 'Manette';

  @override
  String get secLink => 'Liaison et sécurité';

  @override
  String get secRecording => 'Enregistrement';

  @override
  String get secAlerts => 'Alertes';

  @override
  String get secMap => 'Carte';

  @override
  String get secPairing => 'Appairage';

  @override
  String get secAi => 'Assistants IA (MCP)';

  @override
  String get secAiShort => 'Assistants IA';

  @override
  String get secUpdates => 'Mises à jour';

  @override
  String get setInput => 'Mode de pilotage';

  @override
  String get setInputDesc =>
      'Manches : deux joysticks virtuels. Curseurs : gaz et lacet à ressort avec un seul manche. Inclinaison : dirigez en inclinant le téléphone ou la tablette.';

  @override
  String get csSticks => 'MANCHES';

  @override
  String get csSliders => 'CURSEURS';

  @override
  String get csTilt => 'INCLINAISON';

  @override
  String get setInvert => 'Inverser le tangage';

  @override
  String get setInvertDesc => 'Pousser vers l’avant pour cabrer.';

  @override
  String get setHaptics => 'Retour haptique';

  @override
  String get setHapticsDesc => 'Vibrer au centre des manches et lors des avertissements.';

  @override
  String get setLinkLoss => 'En cas de perte de liaison';

  @override
  String get setLinkLossDesc =>
      'Ce que fait un drone après 1,8 s sans paquet de commande. Les robots au sol et les bras s’immobilisent, les bancs d’essai coupent le moteur, les fusées poursuivent leur séquence de vol.';

  @override
  String get setRate => 'Fréquence de télémesure';

  @override
  String get setRateDesc => 'Une fréquence élevée consomme plus de bande passante et de batterie.';

  @override
  String get setTestFailsafe => 'Tester la sécurité';

  @override
  String get setTestFailsafeDesc => 'Coupe la liaison de commande six secondes pour vérifier le comportement choisi.';

  @override
  String get runTest => 'Lancer le test';

  @override
  String get setRecordVideo => 'Enregistrer la vidéo';

  @override
  String get setRecordVideoDesc =>
      'Garder la caméra de l’appareil avec chaque enregistrement. La caméra reste connectée pendant l’enregistrement, même si aucun écran ne l’affiche.';

  @override
  String get setVideoFps => 'Images par seconde';

  @override
  String get setVideoFpsDesc => 'Nombre maximal d’images gardées par seconde. Une ESP32-CAM en 640×480 prend environ 10 Mo par minute à 10 i/s.';

  @override
  String get setAlertSound => 'Son des alertes';

  @override
  String get setAlertSoundDesc => 'Joué lors des alertes et des pertes de liaison. Les téléphones vibrent à la place quand le retour haptique est actif.';

  @override
  String kindsOnly(String kinds) {
    return '$kinds uniquement.';
  }

  @override
  String get below => 'Sous';

  @override
  String get above => 'Au-dessus';

  @override
  String get setMapTiles => 'Fond de carte';

  @override
  String get setMapTilesDesc =>
      'Fond de la vue carte : Mapbox Sombre, Plein air (relief) ou Satellite, vos propres tuiles, ou aucun (une grille métrique). Les tuiles déjà vues restent un moment sur cet appareil.';

  @override
  String get mapDark => 'SOMBRE';

  @override
  String get mapOutdoors => 'PLEIN AIR';

  @override
  String get mapSatellite => 'SATELLITE';

  @override
  String get mapCustom => 'PERSO';

  @override
  String get mapNone => 'AUCUN';

  @override
  String get setMapboxToken => 'Votre jeton Mapbox';

  @override
  String get setMapboxTokenDesc => 'Facultatif : un jeton public (pk.…) de votre propre compte Mapbox, pour utiliser votre quota plutôt que celui de l’app.';

  @override
  String get setTileUrl => 'URL des tuiles';

  @override
  String setTileUrlDesc(String z, String x, String y) {
    return 'Un modèle avec $z, $x et $y, par exemple une couche satellite de votre fournisseur avec sa clé. Respectez les conditions du fournisseur.';
  }

  @override
  String get setAttribution => 'Attribution';

  @override
  String get setAttributionDesc => 'La mention exigée par votre fournisseur, affichée sur la carte.';

  @override
  String get provider => 'Fournisseur';

  @override
  String get setGuides => 'Guides d’intégration';

  @override
  String get setGuidesDesc => 'Ajoutez la bibliothèque koebelt/link à vos projets Arduino, Python, ROS 2 ou Rust.';

  @override
  String scriptHostAt(String address) {
    return 'Hôte de scripts à $address';
  }

  @override
  String get forget => 'Oublier';

  @override
  String get setScriptHosts => 'Hôtes de scripts';

  @override
  String get setScriptHostsDesc =>
      'Des ordinateurs du réseau qui exécutent les scripts pour cet appareil, avec n’importe quelle bibliothèque Python. Sur l’ordinateur : pip install koebelt-dash-scripts, puis koebelt-dash-scripts host.';

  @override
  String get setScriptHostsDescPhone =>
      'Des ordinateurs du réseau qui exécutent les scripts pour ce téléphone, avec n’importe quelle bibliothèque Python. Sur l’ordinateur : pip install koebelt-dash-scripts, puis koebelt-dash-scripts host.';

  @override
  String get setBeHost => 'Être hôte de scripts';

  @override
  String get setBeHostDesc => 'Exécuter les scripts des téléphones et tablettes de ce réseau, avec le Python des scripts.';

  @override
  String setBeHostCode(String code) {
    return 'Code d’appairage : $code. Les téléphones s’appairent dans Scripts > S’exécute sur > Ajouter un hôte de scripts.';
  }

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sessions', one: '1 session');
    return '$_temp0';
  }

  @override
  String get import => 'Importer';

  @override
  String get record => 'Enregistrer';

  @override
  String get noRecordings =>
      'Pas encore d’enregistrement. Enregistrez un appareil connecté, ou utilisez Importer pour un fichier ou les enregistrements d’exemple.';

  @override
  String get tagNew => 'Nouveau';

  @override
  String get tagVideo => 'Vidéo';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count appareils', one: '1 appareil');
    return '$_temp0';
  }

  @override
  String deleteName(String name) {
    return 'Supprimer $name';
  }

  @override
  String exportName(String name) {
    return 'Exporter $name';
  }

  @override
  String get replayEyebrow => 'Enregistrement et relecture';

  @override
  String get sessions => 'Sessions';

  @override
  String get export => 'Exporter';

  @override
  String get exitToLive => 'Revenir au direct';

  @override
  String get play => 'Lecture';

  @override
  String deleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get exportFirst => 'Exporter d’abord';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteRecordingBody => 'L’enregistrement est supprimé de cet appareil. C’est définitif.';

  @override
  String deleteAllN(int count) {
    return 'Tout supprimer ($count)';
  }

  @override
  String get deleteSessionBody => 'L’enregistrement de chaque appareil de cette session est supprimé de cet appareil, avec sa vidéo. C’est définitif.';

  @override
  String sequenceN(int n) {
    return 'Séquence $n';
  }

  @override
  String sequencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count séquences', one: '1 séquence', zero: 'aucune séquence');
    return '$_temp0';
  }

  @override
  String copyOf(String name) {
    return '$name (copie)';
  }

  @override
  String noSequencesFor(String name) {
    return 'Pas encore de séquence pour $name.';
  }

  @override
  String sequenceIntro(String examples) {
    return 'Une séquence est une liste d’étapes ($examples) que l’app exécute l’une après l’autre, en attendant que l’appareil confirme chacune.';
  }

  @override
  String get sequenceComplete => 'Séquence terminée';

  @override
  String get sequenceStopped => 'Séquence arrêtée';

  @override
  String get flightSequence => 'Séquence de vol';

  @override
  String get flightSequenceBody =>
      'L’ordinateur de vol gère à bord le lancement, l’apogée et la récupération. Réglez le déploiement dans Paramètres ; utilisez ici les séquences pour les vérifications au pas de tir.';

  @override
  String get stepsDrone => 'décoller, voler vers des points, attendre, atterrir';

  @override
  String get stepsRover => 'rouler vers des points, attendre, changer de vitesse';

  @override
  String get stepsArm => 'aller à des poses, ouvrir ou fermer la pince';

  @override
  String get stepsBench => 'tenir un régime, monter d’un régime à un autre';

  @override
  String get stepsGeneric => 'attendre, choisir un mode, envoyer des commandes';

  @override
  String get whyExitReplay => 'Quittez la relecture pour lancer';

  @override
  String get whyResetStop => 'Levez d’abord l’arrêt';

  @override
  String get whyAddSteps => 'Ajoutez d’abord des étapes';

  @override
  String get onDevice => 'Sur l’appareil';

  @override
  String get uploading => 'Envoi';

  @override
  String stepOf(int n, int total) {
    return 'étape $n sur $total';
  }

  @override
  String get runsOnDevice => 'S’exécute sur l’appareil : continue si la liaison tombe';

  @override
  String get stopSequence => 'Arrêter la séquence';

  @override
  String get stoppedFromApp => 'Arrêtée depuis l’app';

  @override
  String get run => 'Lancer';

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count étapes', one: '1 étape');
    return '$_temp0';
  }

  @override
  String secondsTimed(String seconds) {
    return '$seconds s chronométrées';
  }

  @override
  String get newSequence => 'Nouvelle séquence';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get steps => 'Étapes';

  @override
  String get lockedWhileRunning => 'Verrouillée pendant l’exécution';

  @override
  String get addFirstStep => 'Ajoutez la première étape ci-dessous. Les étapes s’exécutent de haut en bas.';

  @override
  String get addStep => 'Ajouter une étape';

  @override
  String get dragToReorder => 'Glisser pour réordonner';

  @override
  String get deleteStep => 'Supprimer l’étape';

  @override
  String get useCurrentPosition => 'Utiliser la position actuelle';

  @override
  String get useCurrentPose => 'Utiliser la pose actuelle';

  @override
  String get egDeploy => 'p. ex. deploy';

  @override
  String get planTopView => 'Plan · vue de dessus';

  @override
  String get throttleProfile => 'Profil de gaz';

  @override
  String get liveView => 'Vue en direct';

  @override
  String get timeline => 'Chronologie';

  @override
  String get setPoseAsHome => 'Pose actuelle comme départ';

  @override
  String get planNoteDrone =>
      'Les points sont en mètres vers l’est et le nord depuis le point de décollage. Le drone s’arrête à chacun avant l’étape suivante. La sécurité s’applique toujours si la liaison tombe.';

  @override
  String get planNoteRover => 'Les points sont en mètres vers l’est et le nord depuis le point de départ. Le rover s’arrête à chacun avant l’étape suivante.';

  @override
  String planNoteArm(String button) {
    return 'Placez le bras à la main ou avec les commandes, puis « $button » pour l’enregistrer.';
  }

  @override
  String get planNoteBench => 'Les coupures de courant et de température de l’appareil restent actives pendant la séquence.';

  @override
  String get planNoteGeneric => 'Chaque étape attend la confirmation de l’appareil avant la suivante.';

  @override
  String metreGrid(String metres) {
    return 'grille de $metres m';
  }

  @override
  String get now => 'Maint.';

  @override
  String get and => 'et';

  @override
  String get checkNeedsPython => 'La vérification a besoin de Python sur cet ordinateur : Configurer Python sur la page du script.';

  @override
  String couldNotCheck(String python) {
    return 'Vérification impossible avec $python.';
  }

  @override
  String scriptErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Ce script a $count erreurs', one: 'Ce script a une erreur');
    return '$_temp0';
  }

  @override
  String get runAnyway => 'Lancer quand même';

  @override
  String get showThem => 'Les afficher';

  @override
  String get checkFound => 'La vérification a trouvé ce qui l’arrêterait, sans doute avant tout mouvement :';

  @override
  String lineN(int n) {
    return 'ligne $n';
  }

  @override
  String andMore(int count) {
    return 'et $count de plus';
  }

  @override
  String get installImports => 'Installer ce que ce script importe ?';

  @override
  String get installAndRun => 'Installer et lancer';

  @override
  String missingImports(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names ne sont pas dans ce Python : le script s’arrêterait à ses imports.',
      one: '$names n’est pas dans ce Python : le script s’arrêterait à ses imports.',
    );
    return '$_temp0';
  }

  @override
  String couldNotStart(String error) {
    return 'Démarrage impossible : $error';
  }

  @override
  String get pythonScripts => 'Scripts Python';

  @override
  String copiedExample(String file) {
    return 'Exemple copié dans $file, parmi vos scripts.';
  }

  @override
  String couldNotCopyExample(String error) {
    return 'Copie de l’exemple impossible : $error';
  }

  @override
  String get rename => 'Renommer';

  @override
  String get deleteScriptBody => 'Il va dans le dossier .trash du dossier des scripts, d’où vous pouvez le récupérer.';

  @override
  String get error => 'Erreur';

  @override
  String get examples => 'Exemples';

  @override
  String get connectedOutside => 'Connecté depuis l’extérieur de dash';

  @override
  String get editing => 'modifié';

  @override
  String get saved => 'enregistré';

  @override
  String get checkAction => 'Vérifier';

  @override
  String get checking => 'Vérification…';

  @override
  String get openInEditor => 'Ouvrir dans l’éditeur';

  @override
  String get newScript => 'Nouveau script';

  @override
  String get importPyZip => 'Importer un .py ou un .zip';

  @override
  String get noScriptsPlus => 'Pas encore de script. Partez d’un exemple, ou appuyez sur +.';

  @override
  String get scriptsEmpty => 'Les scripts pilotent vos appareils en Python. Créez-en un, importez-en un, ou partez d’un exemple.';

  @override
  String get edit => 'Modifier';

  @override
  String get share => 'Partager';

  @override
  String get noScriptsNew => 'Pas encore de script. Partez d’un exemple, ou appuyez sur Nouveau.';

  @override
  String get more => 'Plus';

  @override
  String get showInFinder => 'Afficher dans le Finder';

  @override
  String get showInFolder => 'Afficher dans le dossier';

  @override
  String get myScript => 'Mon script';

  @override
  String get create => 'Créer';

  @override
  String get save => 'Enregistrer';

  @override
  String get device => 'Appareil';

  @override
  String get needs => 'Requiert';

  @override
  String get runsOn => 'S’exécute sur';

  @override
  String get scriptsRunOnComputer => 'Les scripts tournent sur un ordinateur';

  @override
  String get scriptsRunOnComputerBody =>
      'Cet appareil les envoie à un hôte de scripts : un ordinateur du même réseau qui exécute koebelt-dash-scripts et peut utiliser n’importe quelle bibliothèque Python (OpenCV, PyTorch…).';

  @override
  String get addScriptHost => 'Ajouter un hôte de scripts';

  @override
  String get notRunning => 'À l’arrêt';

  @override
  String get endedError => 'Terminé sur une erreur';

  @override
  String get ended => 'Terminé';

  @override
  String get waitingConnect => 'En attente de la connexion du script (connect() dans le script)…';

  @override
  String get youHaveSticks => 'Vous avez les manches';

  @override
  String get youHaveSticksBody => 'Vous avez bougé les manches : ceux du script sont ignorés.';

  @override
  String get scriptLostSticks => 'Le script a perdu les manches';

  @override
  String isNotConnected(String name) {
    return '$name n’est pas connecté';
  }

  @override
  String get connectItOrChoose => 'Connectez-le, ou choisissez un autre appareil ci-dessus.';

  @override
  String doesNotFit(String name) {
    return '$name ne convient pas à ce script';
  }

  @override
  String get chooseOrChangeRequires => 'Choisissez un autre appareil ci-dessus, ou modifiez la ligne # requires:.';

  @override
  String get scriptNeedsDevice => 'Un script pilote un appareil : connectez-en d’abord un (Appareils, ou le menu des appareils en haut).';

  @override
  String get doesNotFitShort => 'ne convient pas';

  @override
  String get selectedInDash => 'Choisi dans dash';

  @override
  String get noneConnected => 'aucun connecté';

  @override
  String get thisComputer => 'Cet ordinateur';

  @override
  String get lookingForPython => 'Recherche de Python…';

  @override
  String get noneFound => 'Aucun trouvé';

  @override
  String get noPackage => 'sans la bibliothèque';

  @override
  String get python3Needed => 'Python 3 est nécessaire';

  @override
  String get python3NeededBody => 'Installez-le depuis python.org, puis revenez ici.';

  @override
  String get newerLibrary => 'Une version plus récente de la bibliothèque des scripts est sortie pour cette version de koebelt dash.';

  @override
  String get update => 'Mettre à jour';

  @override
  String get pythonNoAnswer => 'Ce Python ne répond pas';

  @override
  String get packageNotInPython => 'koebelt-dash-scripts n’est pas dans ce Python';

  @override
  String pythonNoAnswerBody(String python) {
    return 'dash n’a pas pu lancer $python. Choisissez-en un autre, ou créez un environnement de scripts.';
  }

  @override
  String get packageNotInPythonBody =>
      'Installez-la ici (pip install koebelt-dash-scripts), ou laissez dash créer un environnement de scripts dans le dossier des scripts.';

  @override
  String get installHere => 'Installer ici';

  @override
  String get scriptsEnvironment => 'Environnement de scripts';

  @override
  String get checkAgain => 'Vérifier à nouveau';

  @override
  String get settingUpPython => 'Configuration de Python';

  @override
  String get oneTimeSetup => 'Configuration initiale';

  @override
  String get oneTimeSetupBody =>
      'Les scripts ont besoin de la bibliothèque koebelt-dash-scripts. dash peut leur créer un environnement Python dans le dossier des scripts (.venv) et l’y installer ; vos propres bibliothèques (OpenCV, PyTorch…) y vont aussi.';

  @override
  String get setUpPython => 'Configurer Python';

  @override
  String packagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Des bibliothèques manquent', one: 'Une bibliothèque manque');
    return '$_temp0';
  }

  @override
  String packagesMissingBody(String modules, String packages) {
    return 'Ce script importe $modules, absent de ce Python : il s’arrêterait là. Installer $packages ?';
  }

  @override
  String get installing => 'Installation…';

  @override
  String get install => 'Installer';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get dismiss => 'Fermer';

  @override
  String get stopScript => 'Arrêter le script';

  @override
  String get restart => 'Relancer';

  @override
  String get triggers => 'Déclencheurs';

  @override
  String get triggersEmpty =>
      'Boutons, touches, boutons de manette, conditions et minuteries qui envoient des événements au script. Déclarez-les avec @dev.trigger(…), ou ajoutez-les ici.';

  @override
  String get limits => 'Limites';

  @override
  String get maxSpeed => 'Vitesse max';

  @override
  String get geofence => 'Zone autorisée';

  @override
  String get off => 'désactivé';

  @override
  String metresFromHome(int metres) {
    return '$metres m du départ';
  }

  @override
  String get ceiling => 'Plafond';

  @override
  String get armingTakeoff => 'Armement, décollage';

  @override
  String get allowed => 'autorisé';

  @override
  String get notAllowed => 'interdit';

  @override
  String get paramWrites => 'Écriture des paramètres';

  @override
  String get fire => 'Déclencher';

  @override
  String get notBound => 'Pas encore associé';

  @override
  String get console => 'Console';

  @override
  String loopHz(String hz) {
    return 'boucle $hz Hz';
  }

  @override
  String get consoleEmpty => 'Les sorties de print() et les erreurs s’affichent ici.';

  @override
  String get fromOutside => 'depuis l’extérieur de dash';

  @override
  String get valid => 'Valide';

  @override
  String padTaken(String button, String action) {
    return '$button est $action dans la configuration de la manette : cette action l’emporte.';
  }

  @override
  String get forDuration => 'pendant';

  @override
  String conditionHelp(String fields) {
    return 'Champs : $fields, mode, armed, et les voies propres à l’appareil (motor_temp.max…). Combinez avec and, or, not ; ajoutez « for 3s » pour attendre.';
  }

  @override
  String get whenTrue => 'QUAND VRAI';

  @override
  String get trueAndFalse => 'VRAI ET FAUX';

  @override
  String get alsoOnControl => 'Aussi dans Pilotage, à côté des manches';

  @override
  String get key => 'Touche';

  @override
  String get pressKey => 'Appuyez sur une touche…';

  @override
  String pressAnotherKey(String key) {
    return '$key · appuyez sur une autre pour changer';
  }

  @override
  String get clickThenKey => 'Cliquez, puis appuyez sur une touche';

  @override
  String get noButtonYet => 'Pas encore de bouton';

  @override
  String get pressButton => 'Appuyez sur un bouton…';

  @override
  String get learn => 'Apprendre';

  @override
  String get onlyThisMode => 'Seulement ce mode (HOLD…), ou vide pour tous';

  @override
  String get onlyMessagesContaining => 'Seulement les messages contenant…';

  @override
  String get every => 'CHAQUE';

  @override
  String get onceAfter => 'UNE FOIS APRÈS';

  @override
  String get secondsWord => 'secondes';

  @override
  String get addTrigger => 'Ajouter un déclencheur';

  @override
  String get editTrigger => 'Modifier le déclencheur';

  @override
  String get event => 'Événement';

  @override
  String get eventPlaceholder => 'Le nom que reçoit le script';

  @override
  String get firedBy => 'Déclenché par';

  @override
  String triggerHelp(String event) {
    return 'Le script reçoit « $event » dans le gestionnaire de ce nom, ou dans @dev.on_trigger. Conditions, événements et minuteries tournent dans dash.';
  }

  @override
  String get done => 'Terminé';

  @override
  String get limitsHelp => 'Réglées ici, pas dans le script : le script ne peut pas les changer.';

  @override
  String get maximumSpeed => 'Vitesse maximale';

  @override
  String get maximumSpeedDesc => 'Les manches du script sont ramenés à cette valeur, et sa vitesse plafonnée.';

  @override
  String get geofenceDesc => 'Au-delà de cette distance du départ, le script perd les manches et l’appareil s’immobilise.';

  @override
  String get ceilingDesc => 'Au-dessus de cette hauteur, pareil pour les drones.';

  @override
  String get allowArming => 'Autoriser l’armement et le décollage';

  @override
  String get allowArmingDesc => 'Sinon le script ne peut déplacer qu’un appareil que vous avez armé.';

  @override
  String get allowParams => 'Autoriser l’écriture des paramètres';

  @override
  String get allowParamsDesc => 'Pour les scripts de réglage. Ils peuvent changer le comportement de l’appareil.';

  @override
  String get pairing => 'Appairage…';

  @override
  String get pair => 'Appairer';

  @override
  String get scriptHostIntro =>
      'Un hôte de scripts est un ordinateur du même réseau qui exécute les scripts pour cet ordinateur : un portable, un Raspberry Pi, un Jetson… Sur celui-ci :';

  @override
  String get scriptHostIntroPhone =>
      'Un hôte de scripts est un ordinateur du même réseau qui exécute les scripts pour ce téléphone ou cette tablette : un portable, un Raspberry Pi, un Jetson… Sur celui-ci :';

  @override
  String get onTheNetwork => 'Sur le réseau';

  @override
  String get lookingForHosts => 'Recherche d’hôtes de scripts';

  @override
  String get noHostsFound => 'Aucun trouvé. Saisissez son adresse ci-dessous (donnée par `ipconfig getifaddr en0`, `hostname -I`…).';

  @override
  String get lookAgain => 'Chercher à nouveau';

  @override
  String get address => 'Adresse';

  @override
  String get pairingCode => 'Code d’appairage';

  @override
  String get pairingCodePlaceholder => 'ABC-123, affiché par l’hôte';

  @override
  String updatingPct(int pct) {
    return 'Mise à jour $pct %';
  }

  @override
  String get installingState => 'Installation';

  @override
  String get appUpdating => 'koebelt dash se met à jour';

  @override
  String appAvailable(String version) {
    return 'koebelt dash $version est disponible';
  }

  @override
  String get appUpToDate => 'koebelt dash est à jour';

  @override
  String get skipVersion => 'Ignorer cette version';

  @override
  String get later => 'Plus tard';

  @override
  String downloadingPct(int pct) {
    return 'Téléchargement $pct %';
  }

  @override
  String get installAnyway => 'Installer quand même';

  @override
  String get updateAnyway => 'Mettre à jour quand même';

  @override
  String installVersion(String version) {
    return 'Installer $version';
  }

  @override
  String get updateNow => 'Mettre à jour';

  @override
  String youHaveOlder(String version) {
    return 'Vous avez $version ; celle-ci est plus ancienne. Les réglages et enregistrements faits avec une version plus récente pourraient ne pas tous s’y ouvrir, et elle ne vous rappellera pas les plus récentes avant la prochaine sortie.';
  }

  @override
  String youHave(String version) {
    return 'Vous avez $version.';
  }

  @override
  String get notFromApp => 'Pas depuis l’app';

  @override
  String get checkingCompat => 'Vérification de la compatibilité avec vos appareils…';

  @override
  String get compatUnknown => 'Compatibilité inconnue';

  @override
  String get compatUnknownBody => 'Impossible de lire quelles versions de koebelt/link cette version prend en charge.';

  @override
  String notCompatibleWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Incompatible avec $count de vos appareils',
      one: 'Incompatible avec un de vos appareils',
    );
    return '$_temp0';
  }

  @override
  String notCompatibleBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mettez d’abord à jour leur bibliothèque koebelt/link, ou gardez votre version et choisissez-en une autre dans Réglages > Mises à jour.',
      one: 'Mettez d’abord à jour sa bibliothèque koebelt/link, ou gardez votre version et choisissez-en une autre dans Réglages > Mises à jour.',
    );
    return '$_temp0';
  }

  @override
  String get disarmFirst => 'Désarmez d’abord';

  @override
  String get disarmFirstBody => 'Un appareil connecté est armé. La mise à jour ferme l’app, ce qui coupe la liaison ; désarmez-le, puis mettez à jour.';

  @override
  String get devicesWillDisconnect => 'Les appareils vont se déconnecter';

  @override
  String devicesWillDisconnectBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'L’installation ferme l’app : les $count appareils connectés perdent la liaison et leur sécurité prend le relais jusqu’à la reconnexion.',
      one: 'L’installation ferme l’app : l’appareil connecté perd la liaison et sa sécurité prend le relais jusqu’à la reconnexion.',
    );
    return '$_temp0';
  }

  @override
  String get notInstalled => 'Non installée';

  @override
  String get inThisVersion => 'Dans cette version';

  @override
  String get whatsNew => 'Nouveautés';

  @override
  String get fullNotes => 'Notes de version complètes';

  @override
  String get chooseAnotherVersion => 'Choisir une autre version';

  @override
  String get chooseVersion => 'Choisir une version';

  @override
  String get close => 'Fermer';

  @override
  String get chooseVersionBody =>
      'Installez n’importe quelle version publiée, plus récente ou plus ancienne. Chacune indique si elle fonctionne avec les versions de koebelt/link que vos appareils ont signalées à leur dernière connexion.';

  @override
  String get askingGithub => 'Interrogation de GitHub…';

  @override
  String get noReleases => 'Aucune version trouvée.';

  @override
  String get installed => 'Installée';

  @override
  String get latest => 'Dernière';

  @override
  String get checkingShort => 'Vérification…';

  @override
  String get worksWithDevices => 'Fonctionne avec vos appareils';

  @override
  String get noDevicesToCheck => 'Pas encore d’appareil à vérifier';

  @override
  String notFor(String names) {
    return 'Pas pour $names';
  }

  @override
  String get details => 'Détails';

  @override
  String get updateHowAndroid => 'La mise à jour se télécharge ici et Android vous demande de confirmer l’installation.';

  @override
  String get updateHow => 'La mise à jour se télécharge, est vérifiée par rapport à la version publiée, et koebelt dash redémarre sur la nouvelle version.';

  @override
  String versionN(String version) {
    return 'Version $version';
  }

  @override
  String get noSelfUpdate =>
      'Cette version ne se met pas à jour elle-même : l’App Store et TestFlight mettent à jour les leurs, et les téléchargements depuis GitHub cherchent eux-mêmes les nouvelles versions.';

  @override
  String get releases => 'Versions';

  @override
  String get upToDate => 'À jour.';

  @override
  String versionAvailable(String version) {
    return '$version est disponible.';
  }

  @override
  String downloadingWhat(String what, int pct) {
    return 'Téléchargement de $what… $pct %';
  }

  @override
  String installingWhat(String what) {
    return 'Installation de $what…';
  }

  @override
  String get somethingWrong => 'Un problème est survenu.';

  @override
  String get notChecked => 'Pas encore vérifié.';

  @override
  String updateTo(String version) {
    return 'Mettre à jour vers $version';
  }

  @override
  String get checkNow => 'Vérifier maintenant';

  @override
  String get chooseVersionDesc =>
      'Installez n’importe quelle version publiée, même ancienne, en sachant si elle fonctionne avec les bibliothèques koebelt/link de vos appareils.';

  @override
  String get versions => 'Versions';

  @override
  String get betas => 'Bêtas';

  @override
  String get betasDesc => 'Proposer aussi les versions bêta et candidates : les prochaines fonctions avant leur sortie, avec plus de risques de bug.';

  @override
  String get autoCheck => 'Rechercher les mises à jour automatiquement';

  @override
  String get autoCheckDesc => 'Au lancement et une fois par jour, koebelt dash demande à GitHub la dernière version. Rien d’autre n’est envoyé.';

  @override
  String get padYawSteer => 'Lacet · direction';

  @override
  String get padRoll => 'Roulis';

  @override
  String get padPitchDrive => 'Tangage · avance';

  @override
  String get padUnavailable => 'Les manettes ne sont pas disponibles sur cette plateforme.';

  @override
  String get padNone =>
      'Aucune manette connectée. Appairez une manette Bluetooth dans les réglages du système, ou branchez-en une en USB. Les radiocommandes fonctionnent en mode joystick USB.';

  @override
  String padConnected(String names) {
    return 'Connectée : $names.';
  }

  @override
  String get padUse => 'Utiliser une manette';

  @override
  String get padUseDesc =>
      'Les manches pilotent drones et robots au sol, et déplacent les bras, une fois armés ; les boutons marchent sur tout appareil. Les commandes à l’écran restent actives quand la manette est au repos.';

  @override
  String get padSticks => 'Manches';

  @override
  String get padMoveNow => 'Bougez ou appuyez sur la commande maintenant';

  @override
  String get padButtons => 'Boutons';

  @override
  String get padDeadzone => 'Zone morte';

  @override
  String padDeadzoneDesc(int pct) {
    return 'Mouvement des manches ignoré autour du centre : $pct %.';
  }

  @override
  String get padExpo => 'Expo';

  @override
  String padExpoDesc(int pct) {
    return 'Réponse plus douce près du centre pour la précision : $pct %.';
  }

  @override
  String get padResetMapping => 'Réinitialiser la configuration';

  @override
  String get padResetMappingDesc => 'Disposition standard : manche gauche gaz et lacet, manche droit tangage et roulis, B / Rond pour STOP.';

  @override
  String get waiting => 'En attente…';

  @override
  String get invertDirection => 'Inverser le sens';

  @override
  String get inverted => 'Inversé';

  @override
  String get normal => 'Normal';

  @override
  String clearName(String name) {
    return 'Effacer $name';
  }

  @override
  String padDrives(String pad, String device) {
    return '$pad pilote $device';
  }

  @override
  String padArmToDrive(String pad) {
    return 'Armez pour piloter avec $pad ; ses boutons marchent déjà';
  }

  @override
  String get padButtonsWork => 'Les boutons marchent ; les manches pilotent drones et robots au sol';

  @override
  String get pad => 'Manette';

  @override
  String get copy => 'Copier';

  @override
  String get aiLet => 'Laisser les assistants utiliser koebelt dash';

  @override
  String get aiLetDesc =>
      'Claude, Codex, OpenCode, Cursor et les autres clients MCP peuvent lire la documentation, écrire des scripts, utiliser l’app et, avec votre accord, agir sur les appareils. dash n’envoie rien lui-même à un service d’IA ; l’assistant que vous connectez parle à son propre fournisseur.';

  @override
  String get aiConnectClient => 'Connecter un client';

  @override
  String get aiPaste => 'Collez ceci dans la configuration de l’assistant.';

  @override
  String get aiRemotePhone => 'Les assistants tournent sur un ordinateur : ils atteignent ce téléphone par le réseau, avec son jeton.';

  @override
  String get aiRemoteTablet => 'Les assistants tournent sur un ordinateur : ils atteignent cette tablette par le réseau, avec son jeton.';

  @override
  String get other => 'Autre';

  @override
  String get aiConnectedNow => 'Connecté maintenant';

  @override
  String get aiNone => 'Aucun assistant ces dix dernières minutes.';

  @override
  String actions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count actions', one: '1 action');
    return '$_temp0';
  }

  @override
  String get activity => 'Activité';

  @override
  String get aiAllowed => 'Autorisé sans demander';

  @override
  String get aiAllowedNone =>
      'Les appareils simulés et les relectures ne demandent jamais. Sur du vrai matériel, chaque action demande, sauf si vous l’autorisez pour la session. L’armement et le décollage demandent toujours.';

  @override
  String aiAllowedSome(String actions) {
    return 'Pour cette session : $actions. L’armement et le décollage demandent toujours.';
  }

  @override
  String get aiFromNetwork => 'Depuis ce réseau';

  @override
  String aiFromNetworkOn(String url, String token) {
    return 'Assistants sur d’autres ordinateurs : $url avec le jeton $token… (copiez-le depuis l’onglet Autre).';
  }

  @override
  String get aiFromNetworkOff => 'Laisser un assistant sur un autre ordinateur utiliser ce dash, avec un jeton.';

  @override
  String get aiActivity => 'Activité des assistants';

  @override
  String get nothingYet => 'Rien pour l’instant.';

  @override
  String get aiShort => 'IA';

  @override
  String aiAsks(String client) {
    return '$client demande';
  }

  @override
  String aiRealHardware(String device) {
    return '$device est du vrai matériel.';
  }

  @override
  String aiAllowSession(String device) {
    return 'Autoriser ce type d’action sur $device pour cette session';
  }

  @override
  String get refuse => 'Refuser';

  @override
  String get approve => 'Approuver';

  @override
  String get recordingsAndLogs => 'Enregistrements et journaux de vol';

  @override
  String fileUnreadable(String error) {
    return 'Le fichier n’a pas pu être lu : $error';
  }

  @override
  String get fromFile => 'Depuis un fichier';

  @override
  String get fromFileDesc => 'S’ouvre comme une session : relecture, carte, graphiques et export fonctionnent dessus.';

  @override
  String get fmtJson => 'Un enregistrement exporté de koebelt/dash';

  @override
  String get fmtBin => 'Journal ArduPilot, depuis la carte SD ou Mission Planner';

  @override
  String get fmtTlog => 'Journal de station sol : Mission Planner, QGroundControl, MAVProxy';

  @override
  String get fmtUlg => 'Journal PX4, depuis la carte SD ou QGroundControl';

  @override
  String reading(String file) {
    return 'Lecture de $file…';
  }

  @override
  String get stopRecordingFirst => 'Arrêtez d’abord l’enregistrement';

  @override
  String get notImported => 'Non importé';

  @override
  String get sampleRecordings => 'Enregistrements d’exemple';

  @override
  String get samplesIn => 'Les trois sessions de démo sont dans votre liste, marquées Démo.';

  @override
  String get samplesDesc => 'Trois sessions de démo enregistrées avec les appareils simulés : un vol de relevé, une prise et dépose, un lancement de fusée.';

  @override
  String get removeSamples => 'Retirer les exemples';

  @override
  String get loadSamples => 'Charger les exemples';

  @override
  String get exporting => 'Export…';

  @override
  String exportFormat(String format) {
    return 'Exporter en $format';
  }

  @override
  String frames(int count) {
    return '$count images';
  }

  @override
  String csvColumns(int count) {
    return '$count colonnes · seulement les voies envoyées par cet appareil';
  }

  @override
  String get noGpx => 'Pas de GPS dans cet enregistrement, donc pas de trace GPX';

  @override
  String encoding(String format, int pct) {
    return 'Encodage $format · $pct %';
  }

  @override
  String get exported => 'Exporté';

  @override
  String get exportFailed => 'Échec de l’export';

  @override
  String get decrease => 'Diminuer';

  @override
  String get increase => 'Augmenter';

  @override
  String was(String value) {
    return 'avant $value';
  }

  @override
  String firmware(String version) {
    return 'micrologiciel $version';
  }

  @override
  String parametersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count paramètres', one: '1 paramètre');
    return '$_temp0';
  }

  @override
  String get parameters => 'Paramètres';

  @override
  String unsaved(int count) {
    return '$count non enregistrés';
  }

  @override
  String written(String when) {
    return 'Écrit $when';
  }

  @override
  String get inSync => 'À jour';

  @override
  String get revert => 'Annuler';

  @override
  String get writing => 'Écriture…';

  @override
  String get writeToDevice => 'Écrire dans l’appareil';

  @override
  String get searchParameters => 'Chercher un paramètre';

  @override
  String get waitingParams => 'En attente de la table des paramètres…';

  @override
  String noParamsMatch(String query) {
    return 'Aucun paramètre ne correspond à « $query »';
  }

  @override
  String revertName(String name) {
    return 'Annuler $name';
  }

  @override
  String get liveResponse => 'Réponse en direct';

  @override
  String get copied => 'Copié';

  @override
  String get yourPairingCode => 'Votre code d’appairage · valable 10 min';

  @override
  String namePaired(String name) {
    return '$name appairé';
  }

  @override
  String get startListening => 'Commencer l’écoute';

  @override
  String get listeningWifiBle => 'Écoute en Wi-Fi et BLE · allumez votre appareil';

  @override
  String nameFound(String name) {
    return '$name trouvé';
  }

  @override
  String sensorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count capteurs', one: '1 capteur');
    return '$_temp0';
  }

  @override
  String get addToDevices => 'Ajouter aux appareils';

  @override
  String get connectNow => 'Connecter maintenant';

  @override
  String get inTheApp => 'Dans l’app';

  @override
  String get completeProgram => 'Programme complet';

  @override
  String get apiReference => 'Référence de l’API';

  @override
  String get exampleProjects => 'Projets d’exemple';

  @override
  String get allGuides => 'Tous les guides';

  @override
  String stepOfUpper(int n, int total) {
    return 'Étape $n sur $total';
  }

  @override
  String get flowDevice => 'Votre appareil';

  @override
  String get flowDeviceDesc => 'Capteurs, moteurs et koebelt/link sur la carte ou l’ordinateur embarqué.';

  @override
  String get flowLinkDesc => 'Wi-Fi, BLE, série USB ou radio, avec une liaison de secours si l’une tombe.';

  @override
  String get flowDashDesc => 'Tableaux de bord, pilotage, réglages et enregistrement, sur téléphone, tablette ou ordinateur.';

  @override
  String get library => 'bibliothèque';

  @override
  String get connectHardware => 'Connectez votre matériel';

  @override
  String get connectHardwareDesc =>
      'Votre appareil exécute une petite bibliothèque qui envoie ses capteurs à cette app et reçoit les commandes. Choisissez votre plateforme pour commencer.';

  @override
  String get guidesConnections => 'Liaisons';

  @override
  String get guidesConnectionsDesc => 'Comment marche chaque liaison, et que faire quand un appareil n’apparaît pas.';

  @override
  String get guidesDevices => 'Exemples d’appareils';

  @override
  String get guidesDevicesDesc => 'Un programme complet et commenté pour chaque type d’appareil.';

  @override
  String get guidesFeatures => 'Vidéo, carte et manettes';

  @override
  String get guidesFeaturesDesc => 'Afficher une caméra, placer l’appareil sur une carte, piloter à la manette.';

  @override
  String get guidesMore => 'Aller plus loin';

  @override
  String get guidesMoreDesc => 'Données personnalisées, réglages, séquences et sécurité.';

  @override
  String get viewChase => 'POURSUITE';

  @override
  String get viewOrbit => 'ORBITE';

  @override
  String get viewTop => 'DESSUS';

  @override
  String get viewMap => 'CARTE';

  @override
  String get viewCam => 'CAM';

  @override
  String get noMapboxToken => 'Cette version n’a pas de jeton Mapbox : saisissez le vôtre ci-dessous, ou choisissez une autre source.';

  @override
  String get waitingGps => 'En attente d’un fix GPS';

  @override
  String get grid => 'Grille';

  @override
  String get waitingScript => 'En attente du script';

  @override
  String get scriptEnded => 'Script terminé';

  @override
  String get noVideo => 'Cet enregistrement n’a pas de vidéo.';

  @override
  String get noCamera => 'Pas de caméra. Les appareils déclarent leurs caméras avec video() dans la bibliothèque.';

  @override
  String cameraByIp(String name) {
    return 'Cette caméra s’atteint par adresse IP. Connectez-vous à $name en Wi-Fi pour la voir.';
  }

  @override
  String get warning => 'Avertissement';

  @override
  String get alBattery => 'Batterie faible';

  @override
  String get alBatteryDesc => 'Charge restante, telle que l’appareil la signale.';

  @override
  String get alBatteryAct => 'Il est temps de le ramener.';

  @override
  String get alBatteryCritical => 'Batterie critique';

  @override
  String get alBatteryCriticalDesc => 'Une seconde limite, plus insistante : se répète jusqu’à acquittement.';

  @override
  String get alBatteryCriticalAct => 'Atterrissez ou arrêtez maintenant.';

  @override
  String get alVoltage => 'Tension de la batterie';

  @override
  String get alVoltageDesc => 'Pour les batteries qui ne donnent pas de pourcentage. Réglez la limite pour votre batterie, par exemple 3,5 V par élément.';

  @override
  String get alVoltageAct => 'Il est temps de le ramener.';

  @override
  String get alObstacle => 'Obstacle proche';

  @override
  String get alObstacleDesc =>
      'Le plus proche obstacle vu par un capteur de proximité, quand l’appareil est armé (les capteurs tournés vers le bas ne comptent pas).';

  @override
  String get alObstacleAct => 'Écartez-vous, ou arrêtez.';

  @override
  String get alRssi => 'Signal faible';

  @override
  String get alRssiDesc => 'Puissance du signal reçu, quand la liaison la donne.';

  @override
  String get alRssiAct => 'Rapprochez-vous ou faites demi-tour.';

  @override
  String get alLatency => 'Latence élevée';

  @override
  String get alLatencyDesc => 'Aller-retour de la liaison. Le pilotage paraît en retard au-delà de quelques centaines de millisecondes.';

  @override
  String get alLatencyAct => 'Le pilotage paraîtra en retard.';

  @override
  String get alAltitude => 'Plafond d’altitude';

  @override
  String get alAltitudeDesc => 'Hauteur au-dessus du départ. 120 m est la limite habituelle des drones en Europe et aux États-Unis.';

  @override
  String get alAltitudeAct => 'Descendez.';

  @override
  String get alDistance => 'Distance du départ';

  @override
  String get alDistanceDesc => 'Une zone simple : distance horizontale depuis le point de départ.';

  @override
  String get alDistanceAct => 'Rapprochez-le.';

  @override
  String get alTemp => 'Température';

  @override
  String get alTempDesc => 'Température du moteur, du variateur ou de la carte, quand l’appareil la donne.';

  @override
  String get alTempAct => 'Laissez-le refroidir.';

  @override
  String get kindDrone => 'Drone';

  @override
  String get kindRover => 'Robot au sol';

  @override
  String get kindArm => 'Bras robotisé';

  @override
  String get kindRocket => 'Fusée';

  @override
  String get kindBench => 'Banc d’essai';

  @override
  String get kindGeneric => 'Appareil';

  @override
  String get stTakeoff => 'Décoller';

  @override
  String get stFlyTo => 'Voler vers';

  @override
  String get stLand => 'Atterrir';

  @override
  String get stRth => 'Retour au départ';

  @override
  String get stDriveTo => 'Rouler vers';

  @override
  String get stPose => 'Aller à une pose';

  @override
  String get stRamp => 'Rampe';

  @override
  String get stWait => 'Attendre';

  @override
  String get stMode => 'Choisir le mode';

  @override
  String get stArm => 'Armer / désarmer';

  @override
  String get stCmd => 'Commande personnalisée';

  @override
  String get fEast => 'Est';

  @override
  String get fNorth => 'Nord';

  @override
  String get fHold => 'Maintien';

  @override
  String get fFrom => 'De';

  @override
  String get fTo => 'À';

  @override
  String get fOver => 'Sur';

  @override
  String get fDuration => 'Durée';

  @override
  String get fMode => 'Mode';

  @override
  String get fState => 'État';

  @override
  String get fLimit => 'Limite';

  @override
  String get fCommand => 'Commande';

  @override
  String get fValue => 'Valeur';

  @override
  String sumTakeoff(String alt) {
    return 'Décoller à $alt m';
  }

  @override
  String sumFlyTo(String x, String y, String z) {
    return 'Voler vers $x, $y m à $z m';
  }

  @override
  String sumDriveTo(String x, String y) {
    return 'Rouler vers $x, $y m';
  }

  @override
  String get sumRth => 'Revenir au départ et atterrir';

  @override
  String sumPose(String joints) {
    return 'Aller à la pose $joints°';
  }

  @override
  String sumGripper(String pct) {
    return 'Pince ouverte à $pct %';
  }

  @override
  String sumThrottle(String pct, String s) {
    return 'Gaz $pct % pendant $s s';
  }

  @override
  String sumRamp(String from, String to, String s) {
    return 'Rampe de $from à $to % en $s s';
  }

  @override
  String sumWait(String s) {
    return 'Attendre $s s';
  }

  @override
  String sumMode(String mode) {
    return 'Mode $mode';
  }

  @override
  String get sumArm => 'Armer';

  @override
  String get sumDisarm => 'Désarmer';

  @override
  String sumSpeed(String pct) {
    return 'Vitesse max $pct %';
  }

  @override
  String sumCmd(String name, String value) {
    return 'Commande $name = $value';
  }

  @override
  String get stoppedEstop => 'Arrêtée : arrêt d’urgence';

  @override
  String completedIn(String seconds) {
    return 'Terminée en $seconds s';
  }

  @override
  String stepTimedOut(int n, String step) {
    return 'Étape $n hors délai : $step';
  }

  @override
  String metresToGo(String metres) {
    return 'encore $metres m';
  }

  @override
  String get uploadingToDevice => 'Envoi à l’appareil';

  @override
  String get starting => 'Démarrage';

  @override
  String get completedOnDevice => 'Terminée sur l’appareil';

  @override
  String get deviceRejected => 'L’appareil n’a pas accepté la séquence';

  @override
  String get linkLostCarriesOn => 'Liaison perdue · l’appareil continue';

  @override
  String get stoppedDisconnected => 'Arrêtée : déconnecté';

  @override
  String get stoppedTookControl => 'Arrêtée : vous avez repris la main';

  @override
  String get stoppedManual => 'Arrêtée : pilotage manuel';

  @override
  String get stoppedByScript => 'Arrêtée par le script';

  @override
  String get reqAnyDevice => 'un appareil';

  @override
  String reqKinds(String kinds) {
    return '$kinds';
  }

  @override
  String reqWith(String kinds, String needs) {
    return '$kinds avec $needs';
  }

  @override
  String reqWrongKind(String name, String kind, String needs) {
    return '$name : $kind, alors que ce script demande $needs.';
  }

  @override
  String reqLacks(String name, String lacks, String needs) {
    return '$name n’a pas de $lacks ; ce script demande $needs.';
  }

  @override
  String get trgButton => 'Bouton';

  @override
  String get trgSwitch => 'Interrupteur';

  @override
  String get trgSlider => 'Curseur';

  @override
  String get trgController => 'Manette';

  @override
  String get trgCondition => 'Condition';

  @override
  String get trgEvent => 'Événement de l’appareil';

  @override
  String get trgTimer => 'Minuterie';

  @override
  String get evMode => 'Changement de mode';

  @override
  String get evFailsafe => 'Sécurité';

  @override
  String get evSeqDone => 'Séquence terminée';

  @override
  String get evLog => 'Message de l’appareil';

  @override
  String get onControl => 'dans Pilotage';

  @override
  String everyN(String seconds) {
    return 'Toutes les $seconds s';
  }

  @override
  String onceAfterN(String seconds) {
    return 'Une fois après $seconds s';
  }

  @override
  String get paArm => 'Armer / désarmer';

  @override
  String get paManual => 'Manuel';

  @override
  String get paHold => 'Maintien';

  @override
  String get paAuto => 'Rendre au script';

  @override
  String get paSlower => 'Moins vite';

  @override
  String get paFaster => 'Plus vite';

  @override
  String get paFrame => 'Articulations / cartésien';

  @override
  String get paWrist => 'Poignet';

  @override
  String get paNext => 'Appareil suivant';

  @override
  String get paStopHint => 'Arrêt d’urgence, immédiat';

  @override
  String get paHoldHint => 'Maintenir une seconde';

  @override
  String paSwitchTo(String mode) {
    return 'Passer en $mode';
  }

  @override
  String get paAutoHint => 'Après une reprise en main, rendre les manches au script (AUTO)';

  @override
  String paSwitchToDrones(String mode) {
    return 'Passer en $mode (drones)';
  }

  @override
  String get paHoldDronesHint => 'Maintenir une seconde (drones)';

  @override
  String get paRecordHint => 'Démarrer ou arrêter un enregistrement';

  @override
  String get paSlowerHint => 'Baisser la vitesse max de 10 %';

  @override
  String get paFasterHint => 'Monter la vitesse max de 10 %';

  @override
  String get paFrameHint => 'Bras : ce que déplacent les manches';

  @override
  String get paWristHint => 'Bras : le manche droit déplace J5 et J6 au lieu de J3 et J4';

  @override
  String get paGripperHint => 'Bras : ouvrir ou fermer';

  @override
  String get paNextHint => 'Plusieurs connectés : afficher et piloter le suivant';

  @override
  String get notSet => 'Non défini';

  @override
  String get padLeftStickX => 'Manche gauche X';

  @override
  String get padLeftStickY => 'Manche gauche Y';

  @override
  String get padRightStickX => 'Manche droit X';

  @override
  String get padRightStickY => 'Manche droit Y';

  @override
  String get padLeftTrigger => 'Gâchette gauche';

  @override
  String get padRightTrigger => 'Gâchette droite';

  @override
  String get padACross => 'A / Croix';

  @override
  String get padBCircle => 'B / Rond';

  @override
  String get padXSquare => 'X / Carré';

  @override
  String get padYTriangle => 'Y / Triangle';

  @override
  String get padLeftBumper => 'Bouton tranche gauche';

  @override
  String get padRightBumper => 'Bouton tranche droit';

  @override
  String get padBackShare => 'Back / Share';

  @override
  String get padStartOptions => 'Start / Options';

  @override
  String get padHome => 'Home';

  @override
  String get padLeftStickPress => 'Clic manche gauche';

  @override
  String get padRightStickPress => 'Clic manche droit';

  @override
  String get padDPadUp => 'Croix haut';

  @override
  String get padDPadDown => 'Croix bas';

  @override
  String get padDPadLeft => 'Croix gauche';

  @override
  String get padDPadRight => 'Croix droite';

  @override
  String get radioSik => 'Radio de télémesure SiK';

  @override
  String get radioLoraName => 'Station sol LoRa';

  @override
  String get radioOther => 'Autre radio série';

  @override
  String get radioSikDesc => 'Paires 433 / 868 / 915 MHz : 3DR, Holybro, RFD900. Série transparente jusqu’à environ 1 km, 40 km pour la RFD900.';

  @override
  String get radioLoraDesc => 'Une carte avec une radio LoRa en USB, flashée avec le croquis de station sol. 2 à 10 km, télémesure seule.';

  @override
  String get radioHc12Desc => 'Module série transparent bon marché sur un adaptateur USB. Environ 1 km à 9600 bauds.';

  @override
  String get radioXbeeDesc => 'Digi XBee en mode transparent sur une carte USB. 2,4 GHz ou 900 MHz.';

  @override
  String get radioOtherDesc => 'N’importe quelle radio série transparente. Réglez son débit ; l’app utilise des fréquences prudentes.';

  @override
  String get tplLoop => 'Une boucle de contrôle';

  @override
  String get tplButton => 'Une action sur bouton';

  @override
  String get fldBattery => 'Batterie';

  @override
  String get fldBatteryVoltage => 'Tension batterie';

  @override
  String get fldDistanceFromHome => 'Distance du départ';

  @override
  String get fldHeightAboveHome => 'Hauteur au-dessus du départ';

  @override
  String get fldSpeed => 'Vitesse';

  @override
  String get fldHeading => 'Cap';

  @override
  String get fldRoll => 'Roulis';

  @override
  String get fldPitch => 'Tangage';

  @override
  String get fldGripper => 'Pince';

  @override
  String get fldThrust => 'Poussée';

  @override
  String get fldRpm => 'tr/min';

  @override
  String get fldTemperature => 'Température';

  @override
  String get fldNearestObstacle => 'Obstacle le plus proche';

  @override
  String get fldSignal => 'Signal';

  @override
  String get fldLatency => 'Latence';

  @override
  String get fldGpsSatellites => 'Satellites GPS';

  @override
  String get ready => 'Prêt.';

  @override
  String get pythonManaged => 'Ce Python est géré par le système et refuse les bibliothèques : utilisez plutôt un environnement de scripts.';

  @override
  String failedWhy(String why) {
    return 'Échec : $why';
  }

  @override
  String get pipNoPackage => 'pip a terminé, mais koebelt-dash-scripts n’est toujours pas dans ce Python.';

  @override
  String packageUpToDate(String version) {
    return 'koebelt-dash-scripts $version est à jour dans ce Python.';
  }

  @override
  String packageInstalled(String version) {
    return 'koebelt-dash-scripts $version est installée dans ce Python.';
  }

  @override
  String packagesInstalled(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names sont installés dans ce Python.',
      one: '$names est installé dans ce Python.',
    );
    return '$_temp0';
  }

  @override
  String envReady(String version) {
    return 'L’environnement de scripts est prêt, avec koebelt-dash-scripts $version.';
  }

  @override
  String atMostDevices(int count) {
    return 'Au plus $count appareils à la fois. Déconnectez-en un d’abord.';
  }

  @override
  String noAnswerFrom(String name) {
    return 'Pas de réponse de $name';
  }

  @override
  String noHostAt(String address) {
    return 'Pas d’hôte de scripts à $address. `koebelt-dash-scripts host` y tourne-t-il ?';
  }

  @override
  String get hostRefused => 'L’hôte a refusé.';

  @override
  String get logUnknown =>
      'Ce fichier n’est pas un journal que l’app sait lire. Elle ouvre les exports JSON de koebelt/dash, les journaux ArduPilot .bin et .tlog, et les journaux PX4 .ulg.';

  @override
  String logEmpty(String format) {
    return 'Le fichier $format n’a pas de télémesure que l’app puisse afficher (attitude, position, batterie).';
  }

  @override
  String get logJsonUnreadable => 'Ce fichier JSON n’a pas pu être lu.';

  @override
  String get logJsonNotExport => 'Ce fichier JSON n’est pas un export d’enregistrement koebelt/dash.';

  @override
  String get logNoHeartbeat => 'Ce .tlog n’a pas de heartbeat de véhicule : ses messages ne peuvent être attribués à aucun véhicule.';

  @override
  String get viewDevices => 'Voir les appareils';

  @override
  String get simulatedTip => 'Simulé dans l’app, pas du vrai matériel';

  @override
  String get newShort => 'Nouveau';
}
