// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navLive => 'Live';

  @override
  String get navControl => 'Control';

  @override
  String get navAutomate => 'Automatizar';

  @override
  String get navTune => 'Parámetros';

  @override
  String get navReplay => 'Replay';

  @override
  String get navDevices => 'Dispositivos';

  @override
  String get navGuides => 'Guías';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navSequences => 'Secuencias';

  @override
  String get navScripts => 'Scripts';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDesc => 'El idioma de la app.';

  @override
  String get translationNote => 'Esta traducción se hizo con IA y puede contener errores. Las correcciones son bienvenidas en el repositorio de GitHub.';

  @override
  String get translationContribute => 'Contribuir en GitHub';

  @override
  String get secLanguageUnits => 'Idioma y unidades';

  @override
  String get settingsUnits => 'Unidades';

  @override
  String get settingsUnitsDesc =>
      'Longitudes, velocidades y temperaturas. Los dispositivos, las secuencias y los scripts siguen en metros; solo cambia lo que se muestra.';

  @override
  String settingsUnitsSystem(String name) {
    return 'Como la región ($name)';
  }

  @override
  String get unitsMetric => 'Métrico (m, m/s, °C)';

  @override
  String get unitsImperial => 'Imperial (ft, mph, °F)';

  @override
  String get unitsMetricShort => 'métrico';

  @override
  String get unitsImperialShort => 'imperial';

  @override
  String settingsLanguageSystem(String name) {
    return 'Igual que el sistema ($name)';
  }

  @override
  String toastSaved(String name) {
    return 'Guardado como $name';
  }

  @override
  String get stopEngagedBar => 'Parada activa · toca para restablecer';

  @override
  String get stopEngagedTitle => 'Parada de emergencia activa';

  @override
  String get stopKeep => 'Mantener parado';

  @override
  String get stopResetAll => 'Restablecer todo';

  @override
  String get stopReset => 'Restablecer parada';

  @override
  String stopBody(String names) {
    return 'Los motores están parados y todo comando de movimiento está bloqueado en $names.';
  }

  @override
  String get theDevice => 'el dispositivo';

  @override
  String get stopCheck => 'Revisa el dispositivo antes de restablecer. Después sigue desarmado hasta que lo vuelvas a armar.';

  @override
  String get fleet => 'Flota';

  @override
  String get tagSim => 'Sim';

  @override
  String get fleetActive => 'Activo';

  @override
  String get fleetLost => 'Perdido';

  @override
  String get fleetLinked => 'Enlazado';

  @override
  String get fleetOff => 'Apagado';

  @override
  String get fleetOn => 'Encendido';

  @override
  String get connecting => 'Conectando';

  @override
  String get noLink => 'Sin enlace';

  @override
  String get simulated => 'Simulado';

  @override
  String get statLink => 'Enlace';

  @override
  String get statLost => 'Perdido';

  @override
  String get statLatency => 'Latencia';

  @override
  String get statBattery => 'Batería';

  @override
  String get statRecording => 'Grabando';

  @override
  String get armed => 'Armado';

  @override
  String get disarmed => 'Desarmado';

  @override
  String stopLabelAll(int count) {
    return 'Parada de emergencia, los $count dispositivos';
  }

  @override
  String get stopLabel => 'Parada de emergencia';

  @override
  String stopTipAll(int count) {
    return 'Para los $count dispositivos conectados';
  }

  @override
  String get stopTipSlowRadio => 'STOP también se envía por esta radio solo de telemetría, pero es lento: hasta un segundo';

  @override
  String get stopAll => 'Parar todo';

  @override
  String get stop => 'Stop';

  @override
  String get failsafeHold => 'manteniendo posición';

  @override
  String get failsafeRth => 'volviendo a casa';

  @override
  String get failsafeLand => 'aterrizando en el sitio';

  @override
  String linkLostFor(String seconds) {
    return 'Enlace perdido · $seconds s';
  }

  @override
  String failsafeActive(String action) {
    return 'Failsafe activo: $action.';
  }

  @override
  String get reconnecting => 'Reconectando. El failsafe se activa a 1,8 s.';

  @override
  String get controlsLocked => 'Los controles están bloqueados hasta que vuelva el enlace.';

  @override
  String get linkRestored => 'Enlace restablecido';

  @override
  String get linkRestoredBody => 'El control manual vuelve a estar disponible.';

  @override
  String alertBelow(String limit) {
    return 'Por debajo de $limit.';
  }

  @override
  String alertAbove(String limit) {
    return 'Por encima de $limit.';
  }

  @override
  String get linkLostOther => 'Su failsafe toma el control tras 1,8 s.';

  @override
  String get compatNewerApp => 'Necesita una app más reciente';

  @override
  String get compatOldLib => 'Librería demasiado antigua';

  @override
  String compatSome(String why) {
    return 'Algunas funciones pueden no funcionar: $why.';
  }

  @override
  String get compatUpdateApp => 'Actualiza koebelt dash.';

  @override
  String get compatUpdateLib => 'Actualiza la librería koebelt/link del dispositivo, o instala un koebelt dash anterior en Ajustes > Actualizaciones.';

  @override
  String get show => 'Mostrar';

  @override
  String alerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count alertas', one: '1 alerta');
    return '$_temp0';
  }

  @override
  String get linkLost => 'Enlace perdido';

  @override
  String get replayOffControl => 'Los controles están desactivados durante un replay';

  @override
  String get replayOffControlWhy => 'Los controles actúan sobre un dispositivo conectado, no sobre una grabación.';

  @override
  String get replayOffSequences => 'Las secuencias están desactivadas durante un replay';

  @override
  String get replayOffSequencesWhy => 'Las secuencias se ejecutan en un dispositivo conectado, no en una grabación.';

  @override
  String get replayOffTune => 'Los ajustes están desactivados durante un replay';

  @override
  String get replayOffTuneWhy => 'Los parámetros se leen y escriben en un dispositivo conectado, no en una grabación.';

  @override
  String replayExitTo(String name) {
    return 'Sal del replay para volver a $name.';
  }

  @override
  String get replayExitConnect => 'Sal del replay y luego conecta un dispositivo.';

  @override
  String get replayBack => 'Volver al replay';

  @override
  String replayExitBackTo(String name) {
    return 'Salir del replay, volver a $name';
  }

  @override
  String get replayExit => 'Salir del replay';

  @override
  String get notConnected => 'No conectado';

  @override
  String get noDeviceTitle => 'Ningún dispositivo conectado';

  @override
  String get noDeviceBody => 'Elige un dispositivo emparejado o empareja uno nuevo. La telemetría y los controles aparecen cuando el enlace está activo.';

  @override
  String get connectFailed => 'No se pudo conectar';

  @override
  String get noPairedDevices => 'Aún no hay dispositivos emparejados.';

  @override
  String get offline => 'Sin conexión';

  @override
  String batteryPct(int pct) {
    return '$pct % de batería';
  }

  @override
  String get connect => 'Conectar';

  @override
  String get pairNewDevice => 'Emparejar dispositivo';

  @override
  String get or => 'O';

  @override
  String get addSimulated => 'Añadir un dispositivo simulado';

  @override
  String get addSimulatedDesc => 'Un dron, rover, brazo, cohete o banco de pruebas virtual, para probar la app sin hardware.';

  @override
  String get openRecording => 'Abrir una grabación';

  @override
  String get openRecordingDesc => 'Reproduce una sesión, un log de vuelo o las grabaciones de ejemplo.';

  @override
  String get setUpLibrary => 'Instalar la librería';

  @override
  String get setUpLibraryDesc => 'Añade koebelt/link a tu proyecto Arduino, Python, ROS 2 o Rust.';

  @override
  String get noDevice => 'Sin dispositivo';

  @override
  String get tagDemo => 'Demo';

  @override
  String moreConnected(int count) {
    return '+$count conectados';
  }

  @override
  String get alsoConnected => 'También conectados';

  @override
  String get disconnectAll => 'Desconectar todo';

  @override
  String get connectAnother => 'Conectar otro';

  @override
  String get pairedDevices => 'Dispositivos emparejados';

  @override
  String get noPairedDevicesShort => 'Ningún dispositivo emparejado';

  @override
  String get noPairedDevicesHint => 'Empareja uno, añade un dispositivo simulado o sigue el inicio rápido.';

  @override
  String get pairDevice => 'Emparejar';

  @override
  String get quickstart => 'Inicio rápido';

  @override
  String get manage => 'Gestionar';

  @override
  String get replaying => 'En replay';

  @override
  String get closeReplay => 'Cerrar replay';

  @override
  String get simulator => 'Simulador';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get open => 'Abrir';

  @override
  String get sequenceRunning => 'secuencia en curso';

  @override
  String disconnectName(String name) {
    return 'Desconectar $name';
  }

  @override
  String get automateSeqBlurb => 'Pasos en orden, sin código: despegar, volar a, esperar, aterrizar; conducir a; ir a una pose.';

  @override
  String get automateSeqPoint1 => 'Sin código: se crea en la app';

  @override
  String get automateSeqPoint2 => 'Se ejecuta en el dispositivo cuando puede guardarla';

  @override
  String get automateSeqPoint3 => 'Sigue si se cae el enlace';

  @override
  String get automateSeqConnect => 'Conecta un dispositivo para crear sus secuencias';

  @override
  String automateSeqCount(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count secuencias', one: '1 secuencia', zero: 'Ninguna secuencia');
    return '$_temp0 para $name';
  }

  @override
  String get automateScriptBlurb => 'Python que lee la telemetría y la cámara, decide y pilota el dispositivo.';

  @override
  String get automateScriptPoint1 => 'Lógica, sensores, la cámara';

  @override
  String get automateScriptPoint2 => 'Cualquier paquete: OpenCV, PyTorch, YOLO';

  @override
  String get automateScriptPoint3 => 'Triggers: botones, teclas, condiciones, temporizadores';

  @override
  String get automateScriptPoint3Host => 'Se ejecuta en un host de scripts: un ordenador de tu red';

  @override
  String scriptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count scripts', one: '1 script', zero: 'Ningún script');
    return '$_temp0';
  }

  @override
  String get automateEyebrow => 'Dos formas de automatizar';

  @override
  String runningOn(String what, String device) {
    return '$what en $device';
  }

  @override
  String get automateTogether1 => 'Juntos: un script puede lanzar una secuencia, ';

  @override
  String get automateTogether2 => ', y decidir cuándo.';

  @override
  String get sequenceOrScript => '¿Secuencia o script?';

  @override
  String get running => 'En curso';

  @override
  String get layoutHud => 'HUD';

  @override
  String get layoutWall => 'WALL';

  @override
  String get editLayout => 'Editar diseño';

  @override
  String get sceneLayers3d => 'Capas de la escena 3D';

  @override
  String get layerCloud => 'Nube de puntos';

  @override
  String get layerTrail => 'Trayectoria';

  @override
  String get layerRadar => 'Pistas de radar';

  @override
  String get layerGrid => 'Rejilla del suelo';

  @override
  String get sceneLayers => 'Capas de la escena';

  @override
  String get addWidget => 'Añadir widget';

  @override
  String widgetsSavedFor(String device, String screens) {
    return 'Los widgets se guardan para $device en pantallas de $screens.';
  }

  @override
  String get thisDevice => 'este dispositivo';

  @override
  String get screenPhone => 'teléfono';

  @override
  String get screenShort => 'teléfono en horizontal';

  @override
  String get screenPortrait => 'tableta en vertical';

  @override
  String get screenTablet => 'tableta';

  @override
  String get screenDesktop => 'ordenador';

  @override
  String get reset => 'Restablecer';

  @override
  String get cancel => 'Cancelar';

  @override
  String get saveLayout => 'Guardar diseño';

  @override
  String get back => 'Atrás';

  @override
  String get paused => 'En pausa';

  @override
  String get stale => 'Congelado';

  @override
  String hzLive(int hz) {
    return '$hz Hz en live';
  }

  @override
  String get resume => 'Reanudar';

  @override
  String get pause => 'Pausa';

  @override
  String get statMin => 'Mín';

  @override
  String get statMax => 'Máx';

  @override
  String get statMean => 'Media';

  @override
  String get unit => 'Unidad';

  @override
  String get window => 'Ventana';

  @override
  String get windowValue => '10 s · 300 muestras';

  @override
  String get source => 'Fuente';

  @override
  String get tapChannelToHide => 'Toca un canal para ocultarlo';

  @override
  String get rec => 'Rec';

  @override
  String get speedLimit => 'Velocidad máx';

  @override
  String get setHomePose => 'Fijar pose de inicio';

  @override
  String get setHomeHere => 'Fijar el inicio aquí';

  @override
  String get useThisPose => 'Usar esta pose';

  @override
  String get setHome => 'Fijar inicio';

  @override
  String get setHomePoseBody =>
      'Los ángulos actuales de las articulaciones pasan a ser la pose a la que van Pose de inicio y los pasos Inicio de las secuencias.';

  @override
  String setHomeBody(String length) {
    return 'La posición actual pasa a ser el inicio (0, 0). La vuelta a casa vuelve aquí, y los waypoints de las secuencias se miden desde aquí. El dispositivo está a $length del inicio actual.';
  }

  @override
  String get autoDashDrives => 'dash lo pilota';

  @override
  String get autoTakeBack => 'Elige MANUAL o HOLD, o mueve los sticks, para recuperar el control.';

  @override
  String get autoTip => 'El modo de dash: mientras una secuencia o un script pilota el dispositivo. Lanza uno desde Automatizar.';

  @override
  String get tiltDrag => 'Tilt · arrastra para simular';

  @override
  String get stickThrottle => 'Acelerador';

  @override
  String get stickDrive => 'Avanzar';

  @override
  String get stickYaw => 'Guiñada';

  @override
  String get stickPitchRoll => 'Cabeceo · alabeo';

  @override
  String get stickSteer => 'Dirección';

  @override
  String get stickThrottleYaw => 'Acelerador · guiñada';

  @override
  String get tiltPitchRoll => 'Tilt · cabeceo y alabeo';

  @override
  String get tiltSteerDrive => 'Tilt · dirección y avance';

  @override
  String get axUp => 'ARR';

  @override
  String get axDn => 'ABJ';

  @override
  String get axFwd => 'AV';

  @override
  String get axRev => 'ATR';

  @override
  String get axBack => 'ATR';

  @override
  String get axL => 'I';

  @override
  String get axR => 'D';

  @override
  String get axYaw => 'GUIÑ';

  @override
  String get rdAlt => 'Alt';

  @override
  String get rdOdom => 'Odom';

  @override
  String get rdSpeed => 'Velocidad';

  @override
  String get rdHdg => 'Rumbo';

  @override
  String get rdHome => 'Inicio';

  @override
  String get rdVz => 'Vz';

  @override
  String get rdMax => 'Máx';

  @override
  String get rdRange => 'Distancia';

  @override
  String get rdToolX => 'Herram. X';

  @override
  String get rdToolY => 'Herram. Y';

  @override
  String get rdToolZ => 'Herram. Z';

  @override
  String get rdThrust => 'Empuje';

  @override
  String get rdRpm => 'RPM';

  @override
  String get rdCurrent => 'Corriente';

  @override
  String get rdPower => 'Potencia';

  @override
  String get rdTemp => 'Temp';

  @override
  String get rdEfficiency => 'Eficiencia';

  @override
  String get homePose => 'Pose de inicio';

  @override
  String get setAsHome => 'Fijar como inicio';

  @override
  String get armJoint => 'Articular';

  @override
  String get armCartesian => 'Cartesiano';

  @override
  String get toolFrame => 'Marco de la herramienta · relativo a la base';

  @override
  String armPadHelp(String frame, String wristBtn, String wrist, String gripper) {
    return 'Mando · $frame: articular / cartesiano · $wristBtn: $wrist · $gripper: pinza';
  }

  @override
  String get armWrist => 'muñeca';

  @override
  String get gripper => 'Pinza';

  @override
  String gripperOpenPct(int pct) {
    return '$pct % abierta';
  }

  @override
  String get gripperOpen => 'Abrir';

  @override
  String get gripperClose => 'Cerrar';

  @override
  String get flightPhase => 'Fase de vuelo';

  @override
  String get phasePad => 'En la rampa';

  @override
  String get phaseCount => 'Cuenta atrás';

  @override
  String get phaseBoost => 'Propulsión';

  @override
  String get phaseCoast => 'Inercia';

  @override
  String get phaseDrogue => 'Drogue';

  @override
  String get phaseMain => 'Principal';

  @override
  String get phaseLanded => 'Aterrizado';

  @override
  String get preflight => 'Prevuelo';

  @override
  String get checkPyro => 'Continuidad pyro · drogue, principal';

  @override
  String get ok => 'OK';

  @override
  String get check => 'Revisar';

  @override
  String get checkGps => 'Fix GPS';

  @override
  String sats(int count) {
    return '$count sats';
  }

  @override
  String get noFix => 'Sin fix';

  @override
  String get checkFlightComputer => 'Ordenador de vuelo';

  @override
  String get safe => 'Seguro';

  @override
  String get armFlightComputer => 'Armar el ordenador de vuelo';

  @override
  String get armPadClear => 'Arma solo cuando la rampa esté despejada';

  @override
  String startCountdown(String seconds) {
    return 'Iniciar cuenta atrás · $seconds s';
  }

  @override
  String get abortLaunch => 'Abortar lanzamiento';

  @override
  String get deployDrogue => 'Desplegar drogue';

  @override
  String get deployMain => 'Desplegar principal';

  @override
  String autoDeploy(String length) {
    return 'Despliegue auto · drogue en el apogeo · principal a $length';
  }

  @override
  String landedBody(String apogee, String distance) {
    return 'Apogeo $apogee · aterrizó a $distance de la rampa.';
  }

  @override
  String get resetToPad => 'Volver a la rampa';

  @override
  String get altitude => 'Altitud';

  @override
  String get cutoff => 'Corte';

  @override
  String get cutoffLimit => 'límite';

  @override
  String get cutoffBody => 'El acelerador se puso a 0. Revisa el motor antes de volver a lanzar.';

  @override
  String get clear => 'Borrar';

  @override
  String get benchDisarmed => 'Arma el banco para hacer girar el motor. Mantente lejos de la hélice.';

  @override
  String get testSequence => 'Secuencia de prueba';

  @override
  String get benchRamp => 'RAMPA';

  @override
  String get benchSteps => 'ESCALONES';

  @override
  String get runAndRecord => 'Lanzar y grabar';

  @override
  String benchRampDesc(String seconds) {
    return 'Rampa de 0 a 100 % en $seconds s, mantener 2 s, parar.';
  }

  @override
  String benchStepsDesc(String size, String seconds) {
    return 'Escalones de $size %, $seconds s cada uno, hasta 100 %.';
  }

  @override
  String benchLimits(String amps, String temperature) {
    return 'Límites: $amps A, $temperature.';
  }

  @override
  String get mspTitle => 'Monitorización y ajuste';

  @override
  String mspBody(String name, String firmware) {
    return '$name ejecuta $firmware y está conectado por MSP, el enlace de configuración. La app muestra su telemetría, ajusta sus PID en Parámetros, y STOP lo desarma. Vuélalo con tu emisora RC.';
  }

  @override
  String get radioOnlyTitle => 'Enlace solo de telemetría';

  @override
  String radioOnlyBody(String name, String radio) {
    return '$name está conectado a través de $radio, que solo lleva telemetría. Los sticks, modos y comandos no llegan al dispositivo por aquí; STOP sí, en un segundo aprox. Contrólalo por su enlace principal (Wi-Fi, Bluetooth o radio SiK) y confía en su failsafe cuando ese enlace esté fuera de alcance.';
  }

  @override
  String get aRadio => 'una radio';

  @override
  String get tileReadouts => 'Lecturas';

  @override
  String get tileSrcFused => 'Estado fusionado';

  @override
  String get tileAttitude => 'Actitud';

  @override
  String get tileAccelerometer => 'Acelerómetro';

  @override
  String get tileGyroscope => 'Giroscopio';

  @override
  String get tileSrcBaroRange => 'Baro + telémetro';

  @override
  String get tileRadar => 'Radar';

  @override
  String get tileSrcRadar => 'Radar / escáner de seguridad';

  @override
  String get tileLidar => 'Lidar';

  @override
  String get tileSrcLidar => 'Lidar de barrido';

  @override
  String get tileJoints => 'Articulaciones';

  @override
  String get tileSrcJoints => 'Encoders de articulación';

  @override
  String get tileForceTorque => 'Fuerza / par';

  @override
  String get tileSrcWrist => 'Sensor F/T de muñeca';

  @override
  String get tileSrcPower => 'Módulo de potencia';

  @override
  String get tileSrcRadio => 'Enlace de radio';

  @override
  String get tileCamera => 'Cámara';

  @override
  String get tileSrcCamera => 'Cámara del dispositivo · MJPEG';

  @override
  String get tileSrcFleet => 'Cada dispositivo conectado';

  @override
  String get tileSrcPhase => 'Máquina de estados del ordenador de vuelo';

  @override
  String get tileVerticalSpeed => 'Velocidad vertical';

  @override
  String get tileSrcBaroImu => 'Fusión baro + IMU';

  @override
  String get tilePyro => 'Canales pyro';

  @override
  String get tileSrcPyro => 'Placa pyro de 4 canales';

  @override
  String get tileSrcTacho => 'Tacómetro óptico';

  @override
  String get tileTorque => 'Par';

  @override
  String get tileSrcTorque => 'Célula de par de reacción';

  @override
  String get tileMotorTemp => 'Temp. motor';

  @override
  String get tileSrcNtc => 'Termistor NTC';

  @override
  String get tileRollRate => 'Velocidad de alabeo';

  @override
  String get tilePitchRate => 'Velocidad de cabeceo';

  @override
  String get tileYawRate => 'Velocidad de guiñada';

  @override
  String get tileGroundSpeed => 'Velocidad sobre el suelo';

  @override
  String get tileAgl => 'Altura';

  @override
  String get tileOwnSpeed => 'Velocidad propia';

  @override
  String get tileVoltage => 'Tensión';

  @override
  String get tilePyroBus => 'Bus pyro';

  @override
  String get tileStator => 'Estátor';

  @override
  String get tileVibration => 'Vibración';

  @override
  String get tileAcc200 => 'Acelerómetro · 200 G';

  @override
  String get tileSafetyScanner => 'Escáner de seguridad';

  @override
  String tracks(int count) {
    return '$count pistas';
  }

  @override
  String points(int count) {
    return '$count pts';
  }

  @override
  String axes(int count) {
    return '$count ejes';
  }

  @override
  String connectedCount(int count) {
    return '$count conectados';
  }

  @override
  String armedCount(int count) {
    return '$count armados';
  }

  @override
  String get proxClear => 'despejado';

  @override
  String get tileProximity => 'Proximidad';

  @override
  String get tileSrcProx => 'Sensores de proximidad';

  @override
  String tileSrcCustom(String hz) {
    return 'Canal personalizado · $hz Hz';
  }

  @override
  String get tagScript => 'Script';

  @override
  String get viewEnded => 'terminado';

  @override
  String series(int count) {
    return '$count series';
  }

  @override
  String get rdReach => 'Alcance';

  @override
  String get pyroDrogue => 'Drogue';

  @override
  String get pyroMain => 'Principal';

  @override
  String get pyroAirstart => 'Encendido en vuelo';

  @override
  String get pyroSpare => 'Reserva';

  @override
  String get pyroContinuity => 'Continuidad';

  @override
  String get pyroFired => 'Disparado';

  @override
  String get pyroNotWired => 'Sin cablear';

  @override
  String removeTitle(String name) {
    return '¿Quitar $name?';
  }

  @override
  String get removeDevice => 'Quitar dispositivo';

  @override
  String removeBody(String name) {
    return 'La clave de emparejamiento, los diseños del HUD y los borradores de parámetros de $name se borran de esta app.';
  }

  @override
  String get removeDisconnectFirst => 'Primero se desconectará.';

  @override
  String get removeKept => 'Las grabaciones se conservan. Para volver a usar el dispositivo, emparéjalo con un código nuevo.';

  @override
  String onlineOf(int online, int total) {
    return '$online de $total en línea';
  }

  @override
  String get devicesEmptyHint => 'Empareja un dispositivo, o sigue el inicio rápido para añadir la librería a tu proyecto.';

  @override
  String get devicesSeveral =>
      'Se pueden conectar varios dispositivos a la vez. El que se muestra recibe los sticks; los demás se mantienen con los sticks centrados, y STOP los para a todos.';

  @override
  String get connected => 'Conectado';

  @override
  String removeName(String name) {
    return 'Quitar $name';
  }

  @override
  String get online => 'En línea';

  @override
  String get batShort => 'BAT';

  @override
  String get myRobot => 'Mi robot';

  @override
  String radioNothingHeard(String port, int baud) {
    return 'Nada recibido en $port a $baud baudios. Comprueba que el dispositivo está encendido, que ambas radios usan el mismo canal y velocidad aérea, y que coinciden los baudios. Puedes añadir el enlace igualmente y conectar más tarde.';
  }

  @override
  String get pairTitle => 'Emparejar un dispositivo';

  @override
  String get pairNearby => 'Cerca';

  @override
  String get pairRadio => 'Radio';

  @override
  String get pairSimulated => 'Simulados';

  @override
  String get pairSimulatedIntro =>
      'Los dispositivos simulados se ejecutan dentro de la app y hablan el mismo protocolo que el hardware real. Añade solo los que necesites; cada uno aparece con la etiqueta SIM.';

  @override
  String get added => 'Añadido';

  @override
  String get addAnother => 'Añadir otro';

  @override
  String get add => 'Añadir';

  @override
  String radioRatesTlm(int tlm) {
    return 'Telemetría $tlm Hz · sin control';
  }

  @override
  String radioRates(int tlm, int ctl) {
    return 'Telemetría $tlm Hz · control $ctl Hz';
  }

  @override
  String get radioIntro =>
      'Un enlace de radio es un módem de radio conectado por USB a este ordenador o teléfono, que habla con una radio gemela en el dispositivo.';

  @override
  String get radioIntroMore => 'Para la app es un puerto serie; el tipo de radio fija la velocidad y cuánto puede transportar.';

  @override
  String get radioNoSerial => 'Sin serie USB en esta plataforma';

  @override
  String get radioNoSerialBody =>
      'Las apps de iOS no pueden abrir adaptadores serie USB. Usa la app en Android, macOS, Windows o Linux para los enlaces de radio, o conecta por Wi-Fi o Bluetooth.';

  @override
  String get radioLora =>
      'Los módulos LoRa no son dispositivos USB por sí solos. Graba el sketch de estación de tierra de la guía LoRa en una segunda placa con la radio, y conecta esa placa.';

  @override
  String get usbPort => 'Puerto USB';

  @override
  String get refresh => 'Actualizar';

  @override
  String get noSerialPorts => 'No se encontraron puertos serie. Conecta el adaptador USB de la radio.';

  @override
  String get baudRate => 'Baudios';

  @override
  String heard(String name) {
    return '$name recibido';
  }

  @override
  String get heardMavlink => 'Habla MAVLink: no hace falta emparejar.';

  @override
  String get heardPairing => 'Está en modo emparejamiento y recibirá una clave.';

  @override
  String get heardNoPairing => 'No está en modo emparejamiento; se añade sin clave.';

  @override
  String get listening => 'Escuchando';

  @override
  String get listenForDevice => 'Escuchar el dispositivo';

  @override
  String pairName(String name) {
    return 'Emparejar $name';
  }

  @override
  String get addRadioLink => 'Añadir enlace de radio';

  @override
  String get pairNearbyIntro =>
      'Conecta o enciende la placa. Las controladoras de vuelo y los drones aparecen solos; las placas con la librería koebelt/link también aparecen aquí en modo emparejamiento.';

  @override
  String get scanning => 'Buscando por Wi-Fi, Bluetooth y USB…';

  @override
  String get stillScanning => 'Buscando más dispositivos…';

  @override
  String get addByIp => 'Añadir por dirección IP';

  @override
  String get name => 'Nombre';

  @override
  String get mavlinkPortNote => 'La app escucha en UDP 14550, como cualquier estación de tierra; el puerto es el del vehículo, si lo conoces.';

  @override
  String get addDevice => 'Añadir dispositivo';

  @override
  String get notShowingUp =>
      '¿No aparece el dispositivo? Las placas con ArduPilot, PX4, Betaflight o INAV se conectan tal cual; todo lo demás necesita la librería koebelt/link.';

  @override
  String get openQuickstart => 'Abrir el inicio rápido';

  @override
  String get orLower => 'o';

  @override
  String get addItByIp => 'añadirlo por dirección IP';

  @override
  String get secControl => 'Control';

  @override
  String get secController => 'Mando';

  @override
  String get secLink => 'Enlace y seguridad';

  @override
  String get secRecording => 'Grabación';

  @override
  String get secAlerts => 'Alertas';

  @override
  String get secMap => 'Mapa';

  @override
  String get secPairing => 'Emparejamiento';

  @override
  String get secAi => 'Asistentes IA (MCP)';

  @override
  String get secAiShort => 'Asistentes IA';

  @override
  String get secUpdates => 'Actualizaciones';

  @override
  String get setInput => 'Método de control';

  @override
  String get setInputDesc =>
      'Sticks: dos joysticks virtuales. Sliders: acelerador y guiñada con muelle y un solo stick. Tilt: dirige inclinando el teléfono o la tableta.';

  @override
  String get csSticks => 'STICKS';

  @override
  String get csSliders => 'SLIDERS';

  @override
  String get csTilt => 'TILT';

  @override
  String get setInvert => 'Invertir cabeceo';

  @override
  String get setInvertDesc => 'Empujar hacia delante para subir el morro.';

  @override
  String get setHaptics => 'Respuesta háptica';

  @override
  String get setHapticsDesc => 'Vibrar en el centro de los sticks y en los avisos.';

  @override
  String get setLinkLoss => 'Al perder el enlace';

  @override
  String get setLinkLossDesc =>
      'Lo que hace un dron tras 1,8 s sin paquete de control. Los robots terrestres y los brazos se detienen, los bancos de prueba paran el motor, los cohetes siguen su secuencia de vuelo.';

  @override
  String get setRate => 'Frecuencia de telemetría';

  @override
  String get setRateDesc => 'Las frecuencias altas usan más ancho de banda y batería.';

  @override
  String get setTestFailsafe => 'Probar el failsafe';

  @override
  String get setTestFailsafeDesc => 'Corta el enlace de control seis segundos para que compruebes el comportamiento configurado.';

  @override
  String get runTest => 'Lanzar la prueba';

  @override
  String get setRecordVideo => 'Grabar vídeo';

  @override
  String get setRecordVideoDesc =>
      'Guarda la cámara del dispositivo con cada grabación. La cámara sigue conectada mientras se graba, aunque ninguna pantalla la muestre.';

  @override
  String get setVideoFps => 'Imágenes por segundo';

  @override
  String get setVideoFpsDesc => 'Máximo de imágenes guardadas por segundo. Una ESP32-CAM a 640×480 ocupa unos 10 MB por minuto a 10 fps.';

  @override
  String get setAlertSound => 'Sonido de alerta';

  @override
  String get setAlertSoundDesc => 'Suena con las alertas y al perder el enlace. Los teléfonos vibran en su lugar si la respuesta háptica está activa.';

  @override
  String kindsOnly(String kinds) {
    return 'Solo $kinds.';
  }

  @override
  String get below => 'Por debajo';

  @override
  String get above => 'Por encima';

  @override
  String get setMapTiles => 'Teselas del mapa';

  @override
  String get setMapTilesDesc =>
      'Fondo de la vista de mapa: Mapbox Dark, Outdoors (relieve) o Satellite, tus propias teselas, o ninguno (una rejilla métrica). Las teselas que has visto se quedan un tiempo en este dispositivo.';

  @override
  String get mapDark => 'OSCURO';

  @override
  String get mapOutdoors => 'EXTERIOR';

  @override
  String get mapSatellite => 'SATÉLITE';

  @override
  String get mapCustom => 'PROPIO';

  @override
  String get mapNone => 'NINGUNO';

  @override
  String get setMapboxToken => 'Tu token de Mapbox';

  @override
  String get setMapboxTokenDesc => 'Opcional: un token público (pk.…) de tu propia cuenta de Mapbox, para usar tu cuota en lugar de la de la app.';

  @override
  String get setTileUrl => 'URL de teselas';

  @override
  String setTileUrlDesc(String z, String x, String y) {
    return 'Una plantilla con $z, $x y $y, por ejemplo una capa de satélite de tu proveedor de mapas con su clave. Respeta las condiciones del proveedor.';
  }

  @override
  String get setAttribution => 'Atribución';

  @override
  String get setAttributionDesc => 'El crédito que exige tu proveedor, mostrado en el mapa.';

  @override
  String get provider => 'Proveedor';

  @override
  String get setGuides => 'Guías de integración';

  @override
  String get setGuidesDesc => 'Añade la librería koebelt/link a proyectos Arduino, Python, ROS 2 o Rust.';

  @override
  String scriptHostAt(String address) {
    return 'Host de scripts en $address';
  }

  @override
  String get forget => 'Olvidar';

  @override
  String get setScriptHosts => 'Hosts de scripts';

  @override
  String get setScriptHostsDesc =>
      'Ordenadores de la red que ejecutan scripts para este dispositivo, con cualquier paquete de Python. En el ordenador: pip install koebelt-dash-scripts, luego koebelt-dash-scripts host.';

  @override
  String get setScriptHostsDescPhone =>
      'Ordenadores de la red que ejecutan scripts para este teléfono, con cualquier paquete de Python. En el ordenador: pip install koebelt-dash-scripts, luego koebelt-dash-scripts host.';

  @override
  String get setBeHost => 'Ser host de scripts';

  @override
  String get setBeHostDesc => 'Ejecuta scripts para teléfonos y tabletas de esta red, con el Python de los scripts.';

  @override
  String setBeHostCode(String code) {
    return 'Código de emparejamiento: $code. Los teléfonos se emparejan en Scripts > Se ejecuta en > Añadir un host de scripts.';
  }

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sesiones', one: '1 sesión');
    return '$_temp0';
  }

  @override
  String get import => 'Importar';

  @override
  String get record => 'Grabar';

  @override
  String get noRecordings => 'Aún no hay grabaciones. Graba un dispositivo conectado, o usa Importar para un archivo o las grabaciones de ejemplo.';

  @override
  String get tagNew => 'Nuevo';

  @override
  String get tagVideo => 'Vídeo';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count dispositivos', one: '1 dispositivo');
    return '$_temp0';
  }

  @override
  String deleteName(String name) {
    return 'Borrar $name';
  }

  @override
  String exportName(String name) {
    return 'Exportar $name';
  }

  @override
  String get replayEyebrow => 'Grabación y reproducción';

  @override
  String get sessions => 'Sesiones';

  @override
  String get export => 'Exportar';

  @override
  String get exitToLive => 'Volver al live';

  @override
  String get play => 'Reproducir';

  @override
  String deleteTitle(String name) {
    return '¿Borrar $name?';
  }

  @override
  String get exportFirst => 'Exportar antes';

  @override
  String get delete => 'Borrar';

  @override
  String get deleteRecordingBody => 'La grabación se elimina de este dispositivo. No se puede deshacer.';

  @override
  String deleteAllN(int count) {
    return 'Borrar las $count';
  }

  @override
  String get deleteSessionBody => 'La grabación de cada dispositivo de esta sesión se elimina de este dispositivo, con su vídeo. No se puede deshacer.';

  @override
  String sequenceN(int n) {
    return 'Secuencia $n';
  }

  @override
  String sequencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count secuencias', one: '1 secuencia', zero: 'ninguna secuencia');
    return '$_temp0';
  }

  @override
  String copyOf(String name) {
    return '$name (copia)';
  }

  @override
  String noSequencesFor(String name) {
    return 'Aún no hay secuencias para $name.';
  }

  @override
  String sequenceIntro(String examples) {
    return 'Una secuencia es una lista de pasos ($examples) que la app ejecuta uno tras otro, esperando a que el dispositivo confirme cada uno.';
  }

  @override
  String get sequenceComplete => 'Secuencia completada';

  @override
  String get sequenceStopped => 'Secuencia detenida';

  @override
  String get flightSequence => 'Secuencia de vuelo';

  @override
  String get flightSequenceBody =>
      'El ordenador de vuelo gestiona a bordo el lanzamiento, el apogeo y la recuperación. Ajusta el despliegue en Parámetros; usa aquí las secuencias para las comprobaciones en rampa.';

  @override
  String get stepsDrone => 'despegar, volar a waypoints, esperar, aterrizar';

  @override
  String get stepsPlane => 'despegar, volar un circuito por waypoints, aterrizar';

  @override
  String get stepsRover => 'conducir a waypoints, esperar, cambiar de velocidad';

  @override
  String get stepsArm => 'ir a poses, abrir o cerrar la pinza';

  @override
  String get stepsBench => 'mantener un acelerador, rampa entre dos aceleradores';

  @override
  String get stepsGeneric => 'esperar, elegir un modo, enviar comandos';

  @override
  String get whyExitReplay => 'Sal del replay para lanzar';

  @override
  String get whyResetStop => 'Restablece primero la parada';

  @override
  String get whyAddSteps => 'Añade primero pasos';

  @override
  String get onDevice => 'En el dispositivo';

  @override
  String get uploading => 'Enviando';

  @override
  String stepOf(int n, int total) {
    return 'paso $n de $total';
  }

  @override
  String get runsOnDevice => 'Se ejecuta en el dispositivo: sigue si se cae el enlace';

  @override
  String get stopSequence => 'Detener secuencia';

  @override
  String get stoppedFromApp => 'Detenida desde la app';

  @override
  String get run => 'Lanzar';

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pasos', one: '1 paso');
    return '$_temp0';
  }

  @override
  String secondsTimed(String seconds) {
    return '$seconds s cronometrados';
  }

  @override
  String get newSequence => 'Nueva secuencia';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get steps => 'Pasos';

  @override
  String get lockedWhileRunning => 'Bloqueada durante la ejecución';

  @override
  String get addFirstStep => 'Añade el primer paso abajo. Los pasos se ejecutan de arriba abajo.';

  @override
  String get addStep => 'Añadir paso';

  @override
  String get dragToReorder => 'Arrastra para reordenar';

  @override
  String get deleteStep => 'Borrar paso';

  @override
  String get useCurrentPosition => 'Usar la posición actual';

  @override
  String get useCurrentPose => 'Usar la pose actual';

  @override
  String get egDeploy => 'p. ej. deploy';

  @override
  String get planTopView => 'Plano · vista superior';

  @override
  String get throttleProfile => 'Perfil de acelerador';

  @override
  String get liveView => 'Vista en live';

  @override
  String get timeline => 'Línea de tiempo';

  @override
  String get setPoseAsHome => 'Pose actual como inicio';

  @override
  String get planNoteDrone =>
      'Los waypoints son metros al este y al norte del punto de despegue. El dron se detiene en cada uno antes del siguiente paso. El failsafe sigue aplicándose si se cae el enlace.';

  @override
  String get planNotePlane =>
      'Los waypoints son metros al este y al norte del punto de despegue. Un avión no puede detenerse: pasa por cada uno y da vueltas mientras espera. El failsafe sigue activo si se cae el enlace.';

  @override
  String get planNoteRover => 'Los waypoints son metros al este y al norte del punto de partida. El rover se detiene en cada uno antes del siguiente paso.';

  @override
  String get planNoteBoat =>
      'Los waypoints son metros al este y al norte del punto de partida. El barco reduce la velocidad en cada uno antes del paso siguiente; el viento y la corriente pueden desplazarlo mientras espera.';

  @override
  String planNoteArm(String button) {
    return 'Mueve el brazo a mano o con los controles de jog, y usa «$button» para grabarla.';
  }

  @override
  String get planNoteBench => 'Los cortes por corriente y temperatura del dispositivo siguen activos durante la secuencia.';

  @override
  String get planNoteGeneric => 'Cada paso espera la confirmación del dispositivo antes de empezar el siguiente.';

  @override
  String metreGrid(String length) {
    return 'rejilla de $length';
  }

  @override
  String get now => 'Ahora';

  @override
  String get and => 'y';

  @override
  String get checkNeedsPython => 'La comprobación necesita Python en este ordenador: Configurar Python en la página del script.';

  @override
  String couldNotCheck(String python) {
    return 'No se pudo comprobar con $python.';
  }

  @override
  String scriptErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Este script tiene $count errores', one: 'Este script tiene un error');
    return '$_temp0';
  }

  @override
  String get runAnyway => 'Lanzar igualmente';

  @override
  String get showThem => 'Mostrarlos';

  @override
  String get checkFound => 'La comprobación encontró lo que lo pararía, probablemente antes de mover nada:';

  @override
  String lineN(int n) {
    return 'línea $n';
  }

  @override
  String andMore(int count) {
    return 'y $count más';
  }

  @override
  String get installImports => '¿Instalar lo que importa este script?';

  @override
  String get installAndRun => 'Instalar y lanzar';

  @override
  String missingImports(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names no están en este Python, así que el script se pararía en sus imports.',
      one: '$names no está en este Python, así que el script se pararía en sus imports.',
    );
    return '$_temp0';
  }

  @override
  String couldNotStart(String error) {
    return 'No se pudo iniciar: $error';
  }

  @override
  String get pythonScripts => 'Scripts de Python';

  @override
  String copiedExample(String file) {
    return 'Ejemplo copiado en $file, entre tus scripts.';
  }

  @override
  String couldNotCopyExample(String error) {
    return 'No se pudo copiar el ejemplo: $error';
  }

  @override
  String get rename => 'Renombrar';

  @override
  String get deleteScriptBody => 'Se mueve a la carpeta .trash dentro de la carpeta de scripts, donde puedes recuperarlo.';

  @override
  String get error => 'Error';

  @override
  String get examples => 'Ejemplos';

  @override
  String get connectedOutside => 'Conectado desde fuera de dash';

  @override
  String get editing => 'editando';

  @override
  String get saved => 'guardado';

  @override
  String get checkAction => 'Comprobar';

  @override
  String get checking => 'Comprobando…';

  @override
  String get openInEditor => 'Abrir en el editor';

  @override
  String get newScript => 'Nuevo script';

  @override
  String get importPyZip => 'Importar un .py o .zip';

  @override
  String get noScriptsPlus => 'Aún no hay scripts. Empieza desde un ejemplo, o pulsa +.';

  @override
  String get scriptsEmpty => 'Los scripts pilotan tus dispositivos desde Python. Crea uno, importa uno o empieza desde un ejemplo.';

  @override
  String get edit => 'Editar';

  @override
  String get share => 'Compartir';

  @override
  String get noScriptsNew => 'Aún no hay scripts. Empieza desde un ejemplo, o pulsa Nuevo.';

  @override
  String get more => 'Más';

  @override
  String get showInFinder => 'Mostrar en el Finder';

  @override
  String get showInFolder => 'Mostrar en la carpeta';

  @override
  String get myScript => 'Mi script';

  @override
  String get create => 'Crear';

  @override
  String get save => 'Guardar';

  @override
  String get device => 'Dispositivo';

  @override
  String get needs => 'Requiere';

  @override
  String get runsOn => 'Se ejecuta en';

  @override
  String get scriptsRunOnComputer => 'Los scripts se ejecutan en un ordenador';

  @override
  String get scriptsRunOnComputerBody =>
      'Este dispositivo los envía a un host de scripts: un ordenador de la misma red con koebelt-dash-scripts, que puede usar cualquier paquete de Python (OpenCV, PyTorch…).';

  @override
  String get addScriptHost => 'Añadir un host de scripts';

  @override
  String get notRunning => 'Parado';

  @override
  String get endedError => 'Terminó con un error';

  @override
  String get ended => 'Terminado';

  @override
  String get waitingConnect => 'Esperando a que el script se conecte (connect() en el script)…';

  @override
  String get youHaveSticks => 'Tienes los sticks';

  @override
  String get youHaveSticksBody => 'Has movido los sticks, así que se ignoran los del script.';

  @override
  String get scriptLostSticks => 'El script perdió los sticks';

  @override
  String isNotConnected(String name) {
    return '$name no está conectado';
  }

  @override
  String get connectItOrChoose => 'Conéctalo, o elige otro dispositivo arriba.';

  @override
  String doesNotFit(String name) {
    return '$name no encaja con este script';
  }

  @override
  String get chooseOrChangeRequires => 'Elige otro dispositivo arriba, o cambia la línea # requires:.';

  @override
  String get scriptNeedsDevice => 'Un script pilota un dispositivo: conecta uno primero (Dispositivos, o el menú de dispositivos arriba).';

  @override
  String get doesNotFitShort => 'no encaja';

  @override
  String get selectedInDash => 'Elegido en dash';

  @override
  String get noneConnected => 'ninguno conectado';

  @override
  String get thisComputer => 'Este ordenador';

  @override
  String get lookingForPython => 'Buscando Python…';

  @override
  String get noneFound => 'Ninguno encontrado';

  @override
  String get noPackage => 'sin el paquete';

  @override
  String get python3Needed => 'Hace falta Python 3';

  @override
  String get python3NeededBody => 'Instálalo desde python.org y vuelve aquí.';

  @override
  String get newerLibrary => 'Ha salido una versión más reciente de la librería de los scripts, para esta versión de koebelt dash.';

  @override
  String get update => 'Actualizar';

  @override
  String get pythonNoAnswer => 'Este Python no responde';

  @override
  String get packageNotInPython => 'koebelt-dash-scripts no está en este Python';

  @override
  String pythonNoAnswerBody(String python) {
    return 'dash no pudo ejecutar $python. Elige otro, o crea un entorno de scripts.';
  }

  @override
  String get packageNotInPythonBody =>
      'Instálalo aquí (pip install koebelt-dash-scripts), o deja que dash cree un entorno de scripts en la carpeta de scripts.';

  @override
  String get installHere => 'Instalar aquí';

  @override
  String get scriptsEnvironment => 'Entorno de scripts';

  @override
  String get checkAgain => 'Comprobar de nuevo';

  @override
  String get settingUpPython => 'Configurando Python';

  @override
  String get oneTimeSetup => 'Configuración inicial';

  @override
  String get oneTimeSetupBody =>
      'Los scripts necesitan el paquete koebelt-dash-scripts. dash puede crearles un entorno de Python en la carpeta de scripts (.venv) e instalarlo allí; tus propios paquetes (OpenCV, PyTorch…) van allí también.';

  @override
  String get setUpPython => 'Configurar Python';

  @override
  String packagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Faltan paquetes', one: 'Falta un paquete');
    return '$_temp0';
  }

  @override
  String packagesMissingBody(String modules, String packages) {
    return 'Este script importa $modules, que no está en este Python: se pararía ahí. ¿Instalar $packages?';
  }

  @override
  String get installing => 'Instalando…';

  @override
  String get install => 'Instalar';

  @override
  String get notNow => 'Ahora no';

  @override
  String get dismiss => 'Cerrar';

  @override
  String get stopScript => 'Detener script';

  @override
  String get restart => 'Reiniciar';

  @override
  String get triggers => 'Triggers';

  @override
  String get triggersEmpty =>
      'Botones, teclas, botones del mando, condiciones y temporizadores que envían eventos al script. Decláralos con @dev.trigger(…), o añádelos aquí.';

  @override
  String get limits => 'Límites';

  @override
  String get maxSpeed => 'Velocidad máx';

  @override
  String get geofence => 'Geofence';

  @override
  String get off => 'desactivado';

  @override
  String metresFromHome(String length) {
    return '$length del inicio';
  }

  @override
  String get ceiling => 'Techo';

  @override
  String get armingTakeoff => 'Armado, despegue';

  @override
  String get allowed => 'permitido';

  @override
  String get notAllowed => 'no permitido';

  @override
  String get paramWrites => 'Escritura de parámetros';

  @override
  String get fire => 'Disparar';

  @override
  String get notBound => 'Aún sin asignar';

  @override
  String get console => 'Consola';

  @override
  String loopHz(String hz) {
    return 'bucle $hz Hz';
  }

  @override
  String get consoleEmpty => 'La salida de print() y los errores aparecen aquí.';

  @override
  String get fromOutside => 'desde fuera de dash';

  @override
  String get valid => 'Válida';

  @override
  String padTaken(String button, String action) {
    return '$button es $action en la configuración del mando: esa acción tiene prioridad.';
  }

  @override
  String get forDuration => 'durante';

  @override
  String conditionHelp(String fields) {
    return 'Campos: $fields, mode, armed, y los canales propios del dispositivo (motor_temp.max…). Combina con and, or, not; añade «for 3s» para esperar.';
  }

  @override
  String get whenTrue => 'CUANDO ES VERDAD';

  @override
  String get trueAndFalse => 'VERDAD Y FALSO';

  @override
  String get alsoOnControl => 'También en Control, junto a los sticks';

  @override
  String get key => 'Tecla';

  @override
  String get pressKey => 'Pulsa una tecla…';

  @override
  String pressAnotherKey(String key) {
    return '$key · pulsa otra para cambiar';
  }

  @override
  String get clickThenKey => 'Haz clic y pulsa una tecla';

  @override
  String get noButtonYet => 'Aún sin botón';

  @override
  String get pressButton => 'Pulsa un botón…';

  @override
  String get learn => 'Aprender';

  @override
  String get onlyThisMode => 'Solo este modo (HOLD…), o vacío para cualquiera';

  @override
  String get onlyMessagesContaining => 'Solo mensajes que contienen…';

  @override
  String get every => 'CADA';

  @override
  String get onceAfter => 'UNA VEZ TRAS';

  @override
  String get secondsWord => 'segundos';

  @override
  String get addTrigger => 'Añadir trigger';

  @override
  String get editTrigger => 'Editar trigger';

  @override
  String get event => 'Evento';

  @override
  String get eventPlaceholder => 'El nombre que recibe el script';

  @override
  String get firedBy => 'Disparado por';

  @override
  String triggerHelp(String event) {
    return 'El script recibe «$event» en el handler con ese nombre, o en @dev.on_trigger. Las condiciones, eventos y temporizadores se ejecutan en dash.';
  }

  @override
  String get done => 'Hecho';

  @override
  String get limitsHelp => 'Se fijan aquí, no en el script: el script no puede cambiarlos.';

  @override
  String get maximumSpeed => 'Velocidad máxima';

  @override
  String get maximumSpeedDesc => 'Los sticks del script se escalan a esto, y su velocidad máxima se limita.';

  @override
  String get geofenceDesc => 'Más allá de esta distancia del inicio, el script pierde los sticks y el dispositivo se detiene.';

  @override
  String get ceilingDesc => 'Por encima de esta altura, lo mismo para los drones.';

  @override
  String get allowArming => 'Permitir armado y despegue';

  @override
  String get allowArmingDesc => 'Si no, el script solo puede mover un dispositivo que tú hayas armado.';

  @override
  String get allowParams => 'Permitir escritura de parámetros';

  @override
  String get allowParamsDesc => 'Para scripts de ajuste. Pueden cambiar el comportamiento del dispositivo.';

  @override
  String get pairing => 'Emparejando…';

  @override
  String get pair => 'Emparejar';

  @override
  String get scriptHostIntro =>
      'Un host de scripts es un ordenador de la misma red que ejecuta scripts para este ordenador: un portátil, una Raspberry Pi, una Jetson… En él:';

  @override
  String get scriptHostIntroPhone =>
      'Un host de scripts es un ordenador de la misma red que ejecuta scripts para este teléfono o tableta: un portátil, una Raspberry Pi, una Jetson… En él:';

  @override
  String get onTheNetwork => 'En la red';

  @override
  String get lookingForHosts => 'Buscando hosts de scripts';

  @override
  String get noHostsFound => 'Ninguno encontrado. Escribe su dirección abajo (la muestra `ipconfig getifaddr en0`, `hostname -I`…).';

  @override
  String get lookAgain => 'Buscar de nuevo';

  @override
  String get address => 'Dirección';

  @override
  String get pairingCode => 'Código de emparejamiento';

  @override
  String get pairingCodePlaceholder => 'ABC-123, mostrado por el host';

  @override
  String updatingPct(int pct) {
    return 'Actualizando $pct %';
  }

  @override
  String get installingState => 'Instalando';

  @override
  String get appUpdating => 'koebelt dash se está actualizando';

  @override
  String appAvailable(String version) {
    return 'koebelt dash $version está disponible';
  }

  @override
  String get appUpToDate => 'koebelt dash está al día';

  @override
  String get skipVersion => 'Omitir esta versión';

  @override
  String get later => 'Más tarde';

  @override
  String downloadingPct(int pct) {
    return 'Descargando $pct %';
  }

  @override
  String get installAnyway => 'Instalar igualmente';

  @override
  String get updateAnyway => 'Actualizar igualmente';

  @override
  String installVersion(String version) {
    return 'Instalar $version';
  }

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String youHaveOlder(String version) {
    return 'Tienes $version; esta es una versión anterior. Los ajustes y grabaciones hechos con una versión más reciente pueden no abrirse todos en ella, y no te avisará de las nuevas hasta la próxima publicación.';
  }

  @override
  String youHave(String version) {
    return 'Tienes $version.';
  }

  @override
  String get notFromApp => 'No desde la app';

  @override
  String get checkingCompat => 'Comprobando la compatibilidad con tus dispositivos…';

  @override
  String get compatUnknown => 'Compatibilidad desconocida';

  @override
  String get compatUnknownBody => 'No se pudo leer qué versiones de koebelt/link admite esta versión.';

  @override
  String notCompatibleWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No es compatible con $count de tus dispositivos',
      one: 'No es compatible con uno de tus dispositivos',
    );
    return '$_temp0';
  }

  @override
  String notCompatibleBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Actualiza primero su librería koebelt/link, o conserva tu versión y elige otra en Ajustes > Actualizaciones.',
      one: 'Actualiza primero su librería koebelt/link, o conserva tu versión y elige otra en Ajustes > Actualizaciones.',
    );
    return '$_temp0';
  }

  @override
  String get disarmFirst => 'Desarma primero';

  @override
  String get disarmFirstBody => 'Hay un dispositivo conectado armado. Actualizar cierra la app, lo que corta el enlace; desármalo y luego actualiza.';

  @override
  String get devicesWillDisconnect => 'Los dispositivos se desconectarán';

  @override
  String devicesWillDisconnectBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'La instalación cierra la app, así que los $count dispositivos conectados pierden el enlace y su failsafe toma el control hasta que vuelvas a conectar.',
      one: 'La instalación cierra la app, así que el dispositivo conectado pierde el enlace y su failsafe toma el control hasta que vuelvas a conectar.',
    );
    return '$_temp0';
  }

  @override
  String get notInstalled => 'No instalada';

  @override
  String get inThisVersion => 'En esta versión';

  @override
  String get whatsNew => 'Novedades';

  @override
  String get fullNotes => 'Notas completas de la versión';

  @override
  String get chooseAnotherVersion => 'Elegir otra versión';

  @override
  String get chooseVersion => 'Elegir una versión';

  @override
  String get close => 'Cerrar';

  @override
  String get chooseVersionBody =>
      'Instala cualquier versión publicada, más nueva o más antigua. Cada una indica si funciona con las versiones de koebelt/link que tus dispositivos comunicaron en su última conexión.';

  @override
  String get askingGithub => 'Consultando GitHub…';

  @override
  String get noReleases => 'No se encontraron versiones.';

  @override
  String get installed => 'Instalada';

  @override
  String get latest => 'Última';

  @override
  String get checkingShort => 'Comprobando…';

  @override
  String get worksWithDevices => 'Funciona con tus dispositivos';

  @override
  String get noDevicesToCheck => 'Aún no hay dispositivos que comprobar';

  @override
  String notFor(String names) {
    return 'No para $names';
  }

  @override
  String get details => 'Detalles';

  @override
  String get updateHowAndroid => 'La actualización se descarga aquí y Android te pide confirmar la instalación.';

  @override
  String get updateHow => 'La actualización se descarga, se verifica contra la publicación, y koebelt dash se reinicia en la nueva versión.';

  @override
  String versionN(String version) {
    return 'Versión $version';
  }

  @override
  String get noSelfUpdate =>
      'Esta versión no se actualiza sola: la App Store y TestFlight actualizan las suyas, y las descargas de GitHub buscan nuevas versiones por su cuenta.';

  @override
  String get releases => 'Versiones';

  @override
  String get upToDate => 'Al día.';

  @override
  String versionAvailable(String version) {
    return '$version está disponible.';
  }

  @override
  String downloadingWhat(String what, int pct) {
    return 'Descargando $what… $pct %';
  }

  @override
  String installingWhat(String what) {
    return 'Instalando $what…';
  }

  @override
  String get somethingWrong => 'Algo salió mal.';

  @override
  String get notChecked => 'Aún sin comprobar.';

  @override
  String updateTo(String version) {
    return 'Actualizar a $version';
  }

  @override
  String get checkNow => 'Comprobar ahora';

  @override
  String get chooseVersionDesc =>
      'Instala cualquier versión publicada, también antiguas, sabiendo si funciona con las librerías koebelt/link de tus dispositivos.';

  @override
  String get versions => 'Versiones';

  @override
  String get betas => 'Betas';

  @override
  String get betasDesc => 'Ofrecer también versiones beta y candidatas: las próximas funciones antes de su publicación, con más probabilidades de algún fallo.';

  @override
  String get autoCheck => 'Buscar actualizaciones automáticamente';

  @override
  String get autoCheckDesc => 'Al arrancar y una vez al día, koebelt dash pregunta a GitHub por la última versión. No se envía nada más.';

  @override
  String get padYawSteer => 'Guiñada · dirección';

  @override
  String get padRoll => 'Alabeo';

  @override
  String get padPitchDrive => 'Cabeceo · avance';

  @override
  String get padUnavailable => 'Los mandos no están disponibles en esta plataforma.';

  @override
  String get padNone =>
      'Ningún mando conectado. Empareja un mando Bluetooth en los ajustes del sistema, o conecta uno por USB. Las emisoras RC funcionan en modo joystick USB.';

  @override
  String padConnected(String names) {
    return 'Conectado: $names.';
  }

  @override
  String get padUse => 'Usar un mando';

  @override
  String get padUseDesc =>
      'Los sticks pilotan drones y robots terrestres, y mueven los brazos, una vez armados; los botones funcionan en cualquier dispositivo. Los controles en pantalla siguen funcionando mientras el mando está en reposo.';

  @override
  String get padSticks => 'Sticks';

  @override
  String get padMoveNow => 'Mueve o pulsa el control ahora';

  @override
  String get padButtons => 'Botones';

  @override
  String get padDeadzone => 'Zona muerta';

  @override
  String padDeadzoneDesc(int pct) {
    return 'Movimiento de los sticks ignorado alrededor del centro: $pct %.';
  }

  @override
  String get padExpo => 'Expo';

  @override
  String padExpoDesc(int pct) {
    return 'Respuesta más suave cerca del centro para el control fino: $pct %.';
  }

  @override
  String get padResetMapping => 'Restablecer asignación';

  @override
  String get padResetMappingDesc => 'Disposición estándar: stick izquierdo acelerador y guiñada, stick derecho cabeceo y alabeo, B / Círculo para STOP.';

  @override
  String get waiting => 'Esperando…';

  @override
  String get invertDirection => 'Invertir sentido';

  @override
  String get inverted => 'Invertido';

  @override
  String get normal => 'Normal';

  @override
  String clearName(String name) {
    return 'Borrar $name';
  }

  @override
  String padDrives(String pad, String device) {
    return '$pad pilota $device';
  }

  @override
  String padArmToDrive(String pad) {
    return 'Arma para pilotar con $pad; sus botones ya funcionan';
  }

  @override
  String get padButtonsWork => 'Los botones funcionan; los sticks pilotan drones y robots terrestres';

  @override
  String get pad => 'Mando';

  @override
  String get copy => 'Copiar';

  @override
  String get aiLet => 'Dejar que los asistentes usen koebelt dash';

  @override
  String get aiLetDesc =>
      'Claude, Codex, OpenCode, Cursor y otros clientes MCP pueden leer la documentación, escribir scripts, usar la app y, con tu aprobación, actuar sobre los dispositivos. dash no envía nada a ningún servicio de IA; el asistente que conectas habla con su propio proveedor.';

  @override
  String get aiConnectClient => 'Conectar un cliente';

  @override
  String get aiPaste => 'Pega esto en la configuración del asistente.';

  @override
  String get aiRemotePhone => 'Los asistentes se ejecutan en un ordenador: llegan a este teléfono por la red, con su token.';

  @override
  String get aiRemoteTablet => 'Los asistentes se ejecutan en un ordenador: llegan a esta tableta por la red, con su token.';

  @override
  String get other => 'Otro';

  @override
  String get aiConnectedNow => 'Conectado ahora';

  @override
  String get aiNone => 'Ningún asistente en los últimos diez minutos.';

  @override
  String actions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count acciones', one: '1 acción');
    return '$_temp0';
  }

  @override
  String get activity => 'Actividad';

  @override
  String get aiAllowed => 'Permitido sin preguntar';

  @override
  String get aiAllowedNone =>
      'Los dispositivos simulados y los replays nunca preguntan. En hardware real, cada acción pregunta salvo que la permitas para la sesión. El armado y el despegue siempre preguntan.';

  @override
  String aiAllowedSome(String actions) {
    return 'Para esta sesión: $actions. El armado y el despegue siempre preguntan.';
  }

  @override
  String get aiFromNetwork => 'Desde esta red';

  @override
  String aiFromNetworkOn(String url, String token) {
    return 'Asistentes en otros ordenadores: $url con el token $token… (cópialo desde la pestaña Otro).';
  }

  @override
  String get aiFromNetworkOff => 'Deja que un asistente en otro ordenador use este dash, con un token.';

  @override
  String get aiActivity => 'Actividad de los asistentes';

  @override
  String get nothingYet => 'Nada todavía.';

  @override
  String get aiShort => 'IA';

  @override
  String aiAsks(String client) {
    return '$client pregunta';
  }

  @override
  String aiRealHardware(String device) {
    return '$device es hardware real.';
  }

  @override
  String aiAllowSession(String device) {
    return 'Permitir este tipo de acción en $device durante esta sesión';
  }

  @override
  String get refuse => 'Rechazar';

  @override
  String get approve => 'Aprobar';

  @override
  String get recordingsAndLogs => 'Grabaciones y logs de vuelo';

  @override
  String fileUnreadable(String error) {
    return 'No se pudo leer el archivo: $error';
  }

  @override
  String get fromFile => 'Desde un archivo';

  @override
  String get fromFileDesc => 'Se abre como una sesión: el replay, el mapa, los gráficos y la exportación funcionan con ella.';

  @override
  String get fmtJson => 'Una grabación exportada desde koebelt/dash';

  @override
  String get fmtBin => 'Log de ArduPilot, desde la tarjeta SD o Mission Planner';

  @override
  String get fmtTlog => 'Log de estación de tierra: Mission Planner, QGroundControl, MAVProxy';

  @override
  String get fmtUlg => 'Log de PX4, desde la tarjeta SD o QGroundControl';

  @override
  String reading(String file) {
    return 'Leyendo $file…';
  }

  @override
  String get stopRecordingFirst => 'Detén antes la grabación';

  @override
  String get notImported => 'No importado';

  @override
  String get sampleRecordings => 'Grabaciones de ejemplo';

  @override
  String get samplesIn => 'Las tres sesiones de demostración están en tu lista, marcadas como Demo.';

  @override
  String get samplesDesc =>
      'Tres sesiones de demostración grabadas con los dispositivos simulados: un vuelo de reconocimiento, un pick and place, un lanzamiento de cohete.';

  @override
  String get removeSamples => 'Quitar ejemplos';

  @override
  String get loadSamples => 'Cargar ejemplos';

  @override
  String get exporting => 'Exportando…';

  @override
  String exportFormat(String format) {
    return 'Exportar $format';
  }

  @override
  String frames(int count) {
    return '$count fotogramas';
  }

  @override
  String csvColumns(int count) {
    return '$count columnas · solo los canales que envió este dispositivo';
  }

  @override
  String get noGpx => 'Sin GPS en esta grabación, así que no hay track GPX';

  @override
  String encoding(String format, int pct) {
    return 'Codificando $format · $pct %';
  }

  @override
  String get exported => 'Exportado';

  @override
  String get exportFailed => 'Error al exportar';

  @override
  String get decrease => 'Disminuir';

  @override
  String get increase => 'Aumentar';

  @override
  String was(String value) {
    return 'antes $value';
  }

  @override
  String firmware(String version) {
    return 'firmware $version';
  }

  @override
  String parametersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count parámetros', one: '1 parámetro');
    return '$_temp0';
  }

  @override
  String get parameters => 'Parámetros';

  @override
  String unsaved(int count) {
    return '$count sin guardar';
  }

  @override
  String written(String when) {
    return 'Escrito $when';
  }

  @override
  String get inSync => 'Sincronizado';

  @override
  String get revert => 'Revertir';

  @override
  String get writing => 'Escribiendo…';

  @override
  String get writeToDevice => 'Escribir en el dispositivo';

  @override
  String get searchParameters => 'Buscar parámetros';

  @override
  String get waitingParams => 'Esperando la tabla de parámetros…';

  @override
  String noParamsMatch(String query) {
    return 'Ningún parámetro coincide con «$query»';
  }

  @override
  String revertName(String name) {
    return 'Revertir $name';
  }

  @override
  String get liveResponse => 'Respuesta en live';

  @override
  String get copied => 'Copiado';

  @override
  String get yourPairingCode => 'Tu código de emparejamiento · válido 10 min';

  @override
  String namePaired(String name) {
    return '$name emparejado';
  }

  @override
  String get startListening => 'Empezar a escuchar';

  @override
  String get listeningWifiBle => 'Escuchando por Wi-Fi y BLE · enciende tu dispositivo';

  @override
  String nameFound(String name) {
    return '$name encontrado';
  }

  @override
  String sensorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sensores', one: '1 sensor');
    return '$_temp0';
  }

  @override
  String get addToDevices => 'Añadir a dispositivos';

  @override
  String get connectNow => 'Conectar ahora';

  @override
  String get inTheApp => 'En la app';

  @override
  String get completeProgram => 'Programa completo';

  @override
  String get apiReference => 'Referencia de la API';

  @override
  String get exampleProjects => 'Proyectos de ejemplo';

  @override
  String get allGuides => 'Todas las guías';

  @override
  String stepOfUpper(int n, int total) {
    return 'Paso $n de $total';
  }

  @override
  String get flowDevice => 'Tu dispositivo';

  @override
  String get flowDeviceDesc => 'Sensores, motores y koebelt/link en la placa o el ordenador de a bordo.';

  @override
  String get flowLinkDesc => 'Wi-Fi, BLE, serie USB o radio, con un enlace de respaldo si uno se cae.';

  @override
  String get flowDashDesc => 'Paneles, control, ajustes y grabación, en teléfono, tableta u ordenador.';

  @override
  String get library => 'librería';

  @override
  String get connectHardware => 'Conecta tu hardware';

  @override
  String get connectHardwareDesc =>
      'Tu dispositivo ejecuta una pequeña librería que envía sus sensores a esta app y recibe los controles. Elige tu plataforma para empezar.';

  @override
  String get guidesConnections => 'Conexiones';

  @override
  String get guidesConnectionsDesc => 'Cómo funciona cada enlace, y qué hacer cuando un dispositivo no aparece.';

  @override
  String get guidesDevices => 'Ejemplos de dispositivos';

  @override
  String get guidesDevicesDesc => 'Un programa completo y comentado para cada tipo de dispositivo.';

  @override
  String get guidesFeatures => 'Vídeo, mapa y mandos';

  @override
  String get guidesFeaturesDesc => 'Muestra una cámara, pon el dispositivo en un mapa, pilota con un mando.';

  @override
  String get guidesMore => 'Más allá';

  @override
  String get guidesMoreDesc => 'Datos personalizados, ajustes, secuencias y seguridad.';

  @override
  String get viewChase => 'CHASE';

  @override
  String get viewOrbit => 'ORBIT';

  @override
  String get viewTop => 'TOP';

  @override
  String get viewMap => 'MAPA';

  @override
  String get viewCam => 'CAM';

  @override
  String get noMapboxToken => 'Esta versión no tiene token de Mapbox: introduce el tuyo abajo, o elige otra fuente.';

  @override
  String get waitingGps => 'Esperando un fix GPS';

  @override
  String get grid => 'Rejilla';

  @override
  String get waitingScript => 'Esperando al script';

  @override
  String get scriptEnded => 'Script terminado';

  @override
  String get noVideo => 'Esta grabación no tiene vídeo.';

  @override
  String get noCamera => 'Sin cámara. Los dispositivos declaran cámaras con video() en la librería.';

  @override
  String cameraByIp(String name) {
    return 'Esta cámara se alcanza por dirección IP. Conéctate a $name por Wi-Fi para verla.';
  }

  @override
  String get warning => 'Aviso';

  @override
  String get alBattery => 'Batería baja';

  @override
  String get alBatteryDesc => 'Carga restante, tal como la indica el dispositivo.';

  @override
  String get alBatteryAct => 'Es hora de traerlo de vuelta.';

  @override
  String get alBatteryCritical => 'Batería crítica';

  @override
  String get alBatteryCriticalDesc => 'Un segundo límite, más insistente: se repite hasta que lo confirmes.';

  @override
  String get alBatteryCriticalAct => 'Aterriza o para ya.';

  @override
  String get alVoltage => 'Tensión de batería';

  @override
  String get alVoltageDesc => 'Para baterías que no indican porcentaje. Ajusta el límite a tu batería, por ejemplo 3,5 V por celda.';

  @override
  String get alVoltageAct => 'Es hora de traerlo de vuelta.';

  @override
  String get alObstacle => 'Obstáculo cerca';

  @override
  String get alObstacleDesc => 'Lo más cercano que ve un sensor de proximidad, mientras está armado (los sensores que miran hacia abajo no cuentan).';

  @override
  String get alObstacleAct => 'Apártate o para.';

  @override
  String get alRssi => 'Señal débil';

  @override
  String get alRssiDesc => 'Intensidad de la señal recibida, cuando el enlace la indica.';

  @override
  String get alRssiAct => 'Acércate o da la vuelta.';

  @override
  String get alLatency => 'Latencia alta';

  @override
  String get alLatencyDesc => 'Ida y vuelta del enlace. El control se nota retrasado por encima de unos cientos de milisegundos.';

  @override
  String get alLatencyAct => 'El control se notará retrasado.';

  @override
  String get alAltitude => 'Techo de altitud';

  @override
  String get alAltitudeDesc => 'Altura sobre el inicio. 120 m es el límite habitual para drones en Europa y EE. UU.';

  @override
  String get alAltitudeAct => 'Desciende.';

  @override
  String get alDistance => 'Distancia al inicio';

  @override
  String get alDistanceDesc => 'Una geofence simple: distancia horizontal desde donde salió.';

  @override
  String get alDistanceAct => 'Acércalo.';

  @override
  String get alTemp => 'Temperatura';

  @override
  String get alTempDesc => 'Temperatura del motor, del ESC o de la placa, cuando el dispositivo la indica.';

  @override
  String get alTempAct => 'Deja que se enfríe.';

  @override
  String get kindDrone => 'Dron';

  @override
  String get kindPlane => 'Avión';

  @override
  String get kindRover => 'Robot terrestre';

  @override
  String get kindBoat => 'Barco';

  @override
  String get kindLegged => 'Robot con patas';

  @override
  String get stWalkTo => 'Caminar a';

  @override
  String sumWalkTo(String x, String y) {
    return 'Caminar a $x, $y';
  }

  @override
  String get stepsLegged => 'caminar a waypoints, esperar, cambiar la velocidad';

  @override
  String get planNoteLegged =>
      'Los waypoints son metros al este y al norte del punto de partida. El robot se detiene y se queda de pie en cada uno antes del paso siguiente.';

  @override
  String get legStand => 'De pie';

  @override
  String get legSit => 'Sentado';

  @override
  String get gaitWalk => 'Paso';

  @override
  String get gaitTrot => 'Trote';

  @override
  String get stickTurnHeight => 'Girar · altura';

  @override
  String get stickWalk => 'Caminar · lateral';

  @override
  String get stickTurn => 'Girar';

  @override
  String get legHeight => 'Altura';

  @override
  String get tiltWalk => 'Tilt · caminar y desplazarse';

  @override
  String get kindArm => 'Brazo robótico';

  @override
  String get kindRocket => 'Cohete';

  @override
  String get kindBench => 'Banco de pruebas';

  @override
  String get kindGeneric => 'Dispositivo';

  @override
  String get stTakeoff => 'Despegar';

  @override
  String get stFlyTo => 'Volar a';

  @override
  String get stLand => 'Aterrizar';

  @override
  String get stRth => 'Volver a casa';

  @override
  String get stDriveTo => 'Conducir a';

  @override
  String get stPose => 'Ir a una pose';

  @override
  String get stRamp => 'Rampa';

  @override
  String get stWait => 'Esperar';

  @override
  String get stMode => 'Elegir modo';

  @override
  String get stArm => 'Armar / desarmar';

  @override
  String get stCmd => 'Comando personalizado';

  @override
  String get fEast => 'Este';

  @override
  String get fNorth => 'Norte';

  @override
  String get fHold => 'Mantener';

  @override
  String get fFrom => 'Desde';

  @override
  String get fTo => 'Hasta';

  @override
  String get fOver => 'En';

  @override
  String get fDuration => 'Duración';

  @override
  String get fMode => 'Modo';

  @override
  String get fState => 'Estado';

  @override
  String get fLimit => 'Límite';

  @override
  String get fCommand => 'Comando';

  @override
  String get fValue => 'Valor';

  @override
  String sumTakeoff(String alt) {
    return 'Despegar a $alt';
  }

  @override
  String sumFlyTo(String x, String y, String z) {
    return 'Volar a $x, $y a $z';
  }

  @override
  String sumDriveTo(String x, String y) {
    return 'Conducir a $x, $y';
  }

  @override
  String get sumRth => 'Volver a casa y aterrizar';

  @override
  String sumPose(String joints) {
    return 'Ir a la pose $joints°';
  }

  @override
  String sumGripper(String pct) {
    return 'Pinza abierta al $pct %';
  }

  @override
  String sumThrottle(String pct, String s) {
    return 'Acelerador $pct % durante $s s';
  }

  @override
  String sumRamp(String from, String to, String s) {
    return 'Rampa de $from a $to % en $s s';
  }

  @override
  String sumWait(String s) {
    return 'Esperar $s s';
  }

  @override
  String sumMode(String mode) {
    return 'Modo $mode';
  }

  @override
  String get sumArm => 'Armar';

  @override
  String get sumDisarm => 'Desarmar';

  @override
  String sumSpeed(String pct) {
    return 'Velocidad máx $pct %';
  }

  @override
  String sumCmd(String name, String value) {
    return 'Comando $name = $value';
  }

  @override
  String get stoppedEstop => 'Detenida: parada de emergencia';

  @override
  String completedIn(String seconds) {
    return 'Completada en $seconds s';
  }

  @override
  String stepTimedOut(int n, String step) {
    return 'El paso $n superó el tiempo: $step';
  }

  @override
  String metresToGo(String length) {
    return 'Faltan $length';
  }

  @override
  String get uploadingToDevice => 'Enviando al dispositivo';

  @override
  String get starting => 'Iniciando';

  @override
  String get completedOnDevice => 'Completada en el dispositivo';

  @override
  String get deviceRejected => 'El dispositivo no aceptó la secuencia';

  @override
  String get linkLostCarriesOn => 'Enlace perdido · el dispositivo continúa';

  @override
  String get stoppedDisconnected => 'Detenida: desconectado';

  @override
  String get stoppedTookControl => 'Detenida: tomaste el control';

  @override
  String get stoppedManual => 'Detenida: control manual';

  @override
  String get stoppedByScript => 'Detenida por el script';

  @override
  String get reqAnyDevice => 'un dispositivo';

  @override
  String reqKinds(String kinds) {
    return 'un $kinds';
  }

  @override
  String reqWith(String kinds, String needs) {
    return '$kinds con $needs';
  }

  @override
  String reqWrongKind(String name, String kind, String needs) {
    return '$name es un $kind; este script necesita $needs.';
  }

  @override
  String reqLacks(String name, String lacks, String needs) {
    return '$name no tiene $lacks; este script necesita $needs.';
  }

  @override
  String get trgButton => 'Botón';

  @override
  String get trgSwitch => 'Interruptor';

  @override
  String get trgSlider => 'Slider';

  @override
  String get trgController => 'Mando';

  @override
  String get trgCondition => 'Condición';

  @override
  String get trgEvent => 'Evento del dispositivo';

  @override
  String get trgTimer => 'Temporizador';

  @override
  String get evMode => 'Cambio de modo';

  @override
  String get evFailsafe => 'Failsafe';

  @override
  String get evSeqDone => 'Secuencia terminada';

  @override
  String get evLog => 'Mensaje del dispositivo';

  @override
  String get onControl => 'en Control';

  @override
  String everyN(String seconds) {
    return 'Cada $seconds s';
  }

  @override
  String onceAfterN(String seconds) {
    return 'Una vez tras $seconds s';
  }

  @override
  String get paArm => 'Armar / desarmar';

  @override
  String get paManual => 'Manual';

  @override
  String get paHold => 'Mantener';

  @override
  String get paAuto => 'Devolver al script';

  @override
  String get paSlower => 'Más lento';

  @override
  String get paFaster => 'Más rápido';

  @override
  String get paFrame => 'Articular / cartesiano';

  @override
  String get paWrist => 'Muñeca';

  @override
  String get paNext => 'Siguiente dispositivo';

  @override
  String get paStopHint => 'Parada de emergencia, inmediata';

  @override
  String get paHoldHint => 'Mantener un segundo';

  @override
  String paSwitchTo(String mode) {
    return 'Pasar a $mode';
  }

  @override
  String get paAutoHint => 'Tras tomar el control, devolver los sticks al script (AUTO)';

  @override
  String paSwitchToDrones(String mode) {
    return 'Pasar a $mode (drones)';
  }

  @override
  String get paHoldDronesHint => 'Mantener un segundo (drones)';

  @override
  String get paRecordHint => 'Iniciar o detener una grabación';

  @override
  String get paSlowerHint => 'Bajar la velocidad máx un 10 %';

  @override
  String get paFasterHint => 'Subir la velocidad máx un 10 %';

  @override
  String get paFrameHint => 'Brazos: lo que mueven los sticks';

  @override
  String get paWristHint => 'Brazos: el stick derecho mueve J5 y J6 en lugar de J3 y J4';

  @override
  String get paGripperHint => 'Brazos: abrir o cerrar';

  @override
  String get paNextHint => 'Varios conectados: mostrar y pilotar el siguiente';

  @override
  String get notSet => 'Sin asignar';

  @override
  String get padLeftStickX => 'Stick izquierdo X';

  @override
  String get padLeftStickY => 'Stick izquierdo Y';

  @override
  String get padRightStickX => 'Stick derecho X';

  @override
  String get padRightStickY => 'Stick derecho Y';

  @override
  String get padLeftTrigger => 'Gatillo izquierdo';

  @override
  String get padRightTrigger => 'Gatillo derecho';

  @override
  String get padACross => 'A / Cruz';

  @override
  String get padBCircle => 'B / Círculo';

  @override
  String get padXSquare => 'X / Cuadrado';

  @override
  String get padYTriangle => 'Y / Triángulo';

  @override
  String get padLeftBumper => 'Bumper izquierdo';

  @override
  String get padRightBumper => 'Bumper derecho';

  @override
  String get padBackShare => 'Back / Share';

  @override
  String get padStartOptions => 'Start / Options';

  @override
  String get padHome => 'Home';

  @override
  String get padLeftStickPress => 'Clic stick izquierdo';

  @override
  String get padRightStickPress => 'Clic stick derecho';

  @override
  String get padDPadUp => 'D-pad arriba';

  @override
  String get padDPadDown => 'D-pad abajo';

  @override
  String get padDPadLeft => 'D-pad izquierda';

  @override
  String get padDPadRight => 'D-pad derecha';

  @override
  String get radioSik => 'Radio de telemetría SiK';

  @override
  String get radioLoraName => 'Estación de tierra LoRa';

  @override
  String get radioOther => 'Otra radio serie';

  @override
  String get radioSikDesc => 'Parejas 433 / 868 / 915 MHz: 3DR, Holybro, RFD900. Serie transparente hasta 1 km aprox., 40 km con la RFD900.';

  @override
  String get radioLoraDesc => 'Una placa con radio LoRa por USB, grabada con el sketch de estación de tierra. 2 a 10 km, solo telemetría.';

  @override
  String get radioHc12Desc => 'Módulo serie transparente barato sobre un adaptador USB. Unos 1 km a 9600 baudios.';

  @override
  String get radioXbeeDesc => 'Digi XBee en modo transparente sobre una placa USB. 2,4 GHz o 900 MHz.';

  @override
  String get radioOtherDesc => 'Cualquier radio serie transparente. Ajusta sus baudios; la app usa frecuencias prudentes.';

  @override
  String get tplLoop => 'Un bucle de control';

  @override
  String get tplButton => 'Una acción con botón';

  @override
  String get fldBattery => 'Batería';

  @override
  String get fldBatteryVoltage => 'Tensión de batería';

  @override
  String get fldDistanceFromHome => 'Distancia al inicio';

  @override
  String get fldHeightAboveHome => 'Altura sobre el inicio';

  @override
  String get fldSpeed => 'Velocidad';

  @override
  String get fldHeading => 'Rumbo';

  @override
  String get fldRoll => 'Alabeo';

  @override
  String get fldPitch => 'Cabeceo';

  @override
  String get fldGripper => 'Pinza';

  @override
  String get fldThrust => 'Empuje';

  @override
  String get fldRpm => 'RPM';

  @override
  String get fldTemperature => 'Temperatura';

  @override
  String get fldNearestObstacle => 'Obstáculo más cercano';

  @override
  String get fldSignal => 'Señal';

  @override
  String get fldLatency => 'Latencia';

  @override
  String get fldGpsSatellites => 'Satélites GPS';

  @override
  String get ready => 'Listo.';

  @override
  String get pythonManaged => 'Este Python lo gestiona el sistema y rechaza paquetes: usa mejor un entorno de scripts.';

  @override
  String failedWhy(String why) {
    return 'Error: $why';
  }

  @override
  String get pipNoPackage => 'pip terminó, pero koebelt-dash-scripts sigue sin estar en este Python.';

  @override
  String packageUpToDate(String version) {
    return 'koebelt-dash-scripts $version está al día en este Python.';
  }

  @override
  String packageInstalled(String version) {
    return 'koebelt-dash-scripts $version está instalado en este Python.';
  }

  @override
  String packagesInstalled(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names están instalados en este Python.',
      one: '$names está instalado en este Python.',
    );
    return '$_temp0';
  }

  @override
  String envReady(String version) {
    return 'El entorno de scripts está listo, con koebelt-dash-scripts $version.';
  }

  @override
  String atMostDevices(int count) {
    return 'Como máximo $count dispositivos a la vez. Desconecta uno primero.';
  }

  @override
  String noAnswerFrom(String name) {
    return 'Sin respuesta de $name';
  }

  @override
  String noHostAt(String address) {
    return 'No hay host de scripts en $address. ¿Se está ejecutando `koebelt-dash-scripts host` allí?';
  }

  @override
  String get hostRefused => 'El host lo rechazó.';

  @override
  String get logUnknown =>
      'Este archivo no es un log que la app pueda leer. Abre exportaciones JSON de koebelt/dash, logs .bin y .tlog de ArduPilot, y logs .ulg de PX4.';

  @override
  String logEmpty(String format) {
    return 'El archivo $format no tiene telemetría que la app pueda mostrar (actitud, posición, batería).';
  }

  @override
  String get logJsonUnreadable => 'No se pudo leer este archivo JSON.';

  @override
  String get logJsonNotExport => 'Este archivo JSON no es una exportación de grabación de koebelt/dash.';

  @override
  String get logNoHeartbeat => 'Este .tlog no tiene heartbeat de vehículo, así que sus mensajes no se pueden atribuir a ningún vehículo.';

  @override
  String get viewDevices => 'Ver dispositivos';

  @override
  String get simulatedTip => 'Simulado en la app, no es hardware real';

  @override
  String get newShort => 'Nuevo';
}
