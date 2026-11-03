// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navLive => 'Live';

  @override
  String get navControl => 'Controle';

  @override
  String get navAutomate => 'Automatizar';

  @override
  String get navTune => 'Parâmetros';

  @override
  String get navReplay => 'Replay';

  @override
  String get navDevices => 'Dispositivos';

  @override
  String get navGuides => 'Guias';

  @override
  String get navSettings => 'Configurações';

  @override
  String get navSequences => 'Sequências';

  @override
  String get navScripts => 'Scripts';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDesc => 'O idioma do app.';

  @override
  String get translationNote => 'Esta tradução foi feita com IA e pode conter erros. Correções são bem-vindas no repositório do GitHub.';

  @override
  String get translationContribute => 'Contribuir no GitHub';

  @override
  String get secLanguageUnits => 'Idioma e unidades';

  @override
  String get settingsUnits => 'Unidades';

  @override
  String get settingsUnitsDesc => 'Comprimentos, velocidades e temperaturas. Dispositivos, sequências e scripts continuam em metros; só a exibição muda.';

  @override
  String settingsUnitsSystem(String name) {
    return 'Como a região ($name)';
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
    return 'Igual ao sistema ($name)';
  }

  @override
  String toastSaved(String name) {
    return 'Salvo como $name';
  }

  @override
  String get stopEngagedBar => 'Parada ativa · toque para redefinir';

  @override
  String get stopEngagedTitle => 'Parada de emergência ativa';

  @override
  String get stopKeep => 'Manter parado';

  @override
  String get stopResetAll => 'Redefinir tudo';

  @override
  String get stopReset => 'Redefinir parada';

  @override
  String stopBody(String names) {
    return 'Os motores estão parados e todo comando de movimento está bloqueado em $names.';
  }

  @override
  String get theDevice => 'o dispositivo';

  @override
  String get stopCheck => 'Verifique o dispositivo antes de redefinir. Depois ele fica desarmado até você armá-lo de novo.';

  @override
  String get fleet => 'Frota';

  @override
  String get tagSim => 'Sim';

  @override
  String get fleetActive => 'Ativo';

  @override
  String get fleetLost => 'Perdido';

  @override
  String get fleetLinked => 'Ligado';

  @override
  String get fleetOff => 'Desligado';

  @override
  String get fleetOn => 'Ligado';

  @override
  String get connecting => 'Conectando';

  @override
  String get noLink => 'Sem link';

  @override
  String get simulated => 'Simulado';

  @override
  String get statLink => 'Link';

  @override
  String get statLost => 'Perdido';

  @override
  String get statLatency => 'Latência';

  @override
  String get statBattery => 'Bateria';

  @override
  String get statRecording => 'Gravando';

  @override
  String get armed => 'Armado';

  @override
  String get disarmed => 'Desarmado';

  @override
  String stopLabelAll(int count) {
    return 'Parada de emergência, todos os $count dispositivos';
  }

  @override
  String get stopLabel => 'Parada de emergência';

  @override
  String stopTipAll(int count) {
    return 'Para todos os $count dispositivos conectados';
  }

  @override
  String get stopTipSlowRadio => 'O STOP também vai por este rádio só de telemetria, mas é lento: até um segundo';

  @override
  String get stopAll => 'Parar tudo';

  @override
  String get stop => 'Stop';

  @override
  String get failsafeHold => 'mantendo posição';

  @override
  String get failsafeRth => 'voltando para casa';

  @override
  String get failsafeLand => 'pousando no lugar';

  @override
  String linkLostFor(String seconds) {
    return 'Link perdido · $seconds s';
  }

  @override
  String failsafeActive(String action) {
    return 'Failsafe ativo: $action.';
  }

  @override
  String get reconnecting => 'Reconectando. O failsafe começa em 1,8 s.';

  @override
  String get controlsLocked => 'Os controles ficam bloqueados até o link voltar.';

  @override
  String get linkRestored => 'Link restabelecido';

  @override
  String get linkRestoredBody => 'O controle manual está disponível de novo.';

  @override
  String alertBelow(String limit) {
    return 'Abaixo de $limit.';
  }

  @override
  String alertAbove(String limit) {
    return 'Acima de $limit.';
  }

  @override
  String get linkLostOther => 'O failsafe dele assume após 1,8 s.';

  @override
  String get compatNewerApp => 'Precisa de um app mais novo';

  @override
  String get compatOldLib => 'Biblioteca antiga demais';

  @override
  String compatSome(String why) {
    return 'Alguns recursos podem não funcionar: $why.';
  }

  @override
  String get compatUpdateApp => 'Atualize o koebelt dash.';

  @override
  String get compatUpdateLib => 'Atualize a biblioteca koebelt/link no dispositivo, ou instale um koebelt dash mais antigo em Configurações > Atualizações.';

  @override
  String get show => 'Mostrar';

  @override
  String alerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count alertas', one: '1 alerta');
    return '$_temp0';
  }

  @override
  String get linkLost => 'Link perdido';

  @override
  String get replayOffControl => 'Os controles ficam desligados durante um replay';

  @override
  String get replayOffControlWhy => 'Os controles agem sobre um dispositivo conectado, não sobre uma gravação.';

  @override
  String get replayOffSequences => 'As sequências ficam desligadas durante um replay';

  @override
  String get replayOffSequencesWhy => 'As sequências rodam num dispositivo conectado, não numa gravação.';

  @override
  String get replayOffTune => 'O ajuste fica desligado durante um replay';

  @override
  String get replayOffTuneWhy => 'Os parâmetros são lidos e escritos num dispositivo conectado, não numa gravação.';

  @override
  String replayExitTo(String name) {
    return 'Saia do replay para voltar a $name.';
  }

  @override
  String get replayExitConnect => 'Saia do replay e depois conecte um dispositivo.';

  @override
  String get replayBack => 'Voltar ao replay';

  @override
  String replayExitBackTo(String name) {
    return 'Sair do replay, voltar a $name';
  }

  @override
  String get replayExit => 'Sair do replay';

  @override
  String get notConnected => 'Não conectado';

  @override
  String get noDeviceTitle => 'Nenhum dispositivo conectado';

  @override
  String get noDeviceBody => 'Escolha um dispositivo pareado ou pareie um novo. A telemetria e os controles aparecem quando o link estiver ativo.';

  @override
  String get connectFailed => 'Não foi possível conectar';

  @override
  String get noPairedDevices => 'Ainda não há dispositivos pareados.';

  @override
  String get offline => 'Offline';

  @override
  String batteryPct(int pct) {
    return '$pct% de bateria';
  }

  @override
  String get connect => 'Conectar';

  @override
  String get pairNewDevice => 'Parear novo dispositivo';

  @override
  String get or => 'Ou';

  @override
  String get addSimulated => 'Adicionar um dispositivo simulado';

  @override
  String get addSimulatedDesc => 'Um drone, rover, braço, foguete ou bancada de teste virtual, para experimentar o app sem hardware.';

  @override
  String get openRecording => 'Abrir uma gravação';

  @override
  String get openRecordingDesc => 'Reproduza uma sessão, um log de voo ou as gravações de exemplo.';

  @override
  String get setUpLibrary => 'Configurar a biblioteca';

  @override
  String get setUpLibraryDesc => 'Adicione o koebelt/link ao seu projeto Arduino, Python, ROS 2 ou Rust.';

  @override
  String get noDevice => 'Sem dispositivo';

  @override
  String get tagDemo => 'Demo';

  @override
  String moreConnected(int count) {
    return '+$count conectados';
  }

  @override
  String get alsoConnected => 'Também conectados';

  @override
  String get disconnectAll => 'Desconectar todos';

  @override
  String get connectAnother => 'Conectar outro';

  @override
  String get pairedDevices => 'Dispositivos pareados';

  @override
  String get noPairedDevicesShort => 'Nenhum dispositivo pareado';

  @override
  String get noPairedDevicesHint => 'Pareie um, adicione um dispositivo simulado ou siga o início rápido.';

  @override
  String get pairDevice => 'Parear';

  @override
  String get quickstart => 'Início rápido';

  @override
  String get manage => 'Gerenciar';

  @override
  String get replaying => 'Em replay';

  @override
  String get closeReplay => 'Fechar replay';

  @override
  String get simulator => 'Simulador';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get open => 'Abrir';

  @override
  String get sequenceRunning => 'sequência em execução';

  @override
  String disconnectName(String name) {
    return 'Desconectar $name';
  }

  @override
  String get automateSeqBlurb => 'Passos em ordem, sem código: decolar, voar até, esperar, pousar; dirigir até; ir para uma pose.';

  @override
  String get automateSeqPoint1 => 'Sem código: montada no app';

  @override
  String get automateSeqPoint2 => 'Roda no dispositivo quando ele pode guardá-la';

  @override
  String get automateSeqPoint3 => 'Continua se o link cair';

  @override
  String get automateSeqConnect => 'Conecte um dispositivo para montar as sequências dele';

  @override
  String automateSeqCount(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sequências', one: '1 sequência', zero: 'Nenhuma sequência');
    return '$_temp0 para $name';
  }

  @override
  String get automateScriptBlurb => 'Python que lê a telemetria e a câmera, decide e pilota o dispositivo.';

  @override
  String get automateScriptPoint1 => 'Lógica, sensores, a câmera';

  @override
  String get automateScriptPoint2 => 'Qualquer pacote: OpenCV, PyTorch, YOLO';

  @override
  String get automateScriptPoint3 => 'Triggers: botões, teclas, condições, timers';

  @override
  String get automateScriptPoint3Host => 'Roda num host de scripts: um computador da sua rede';

  @override
  String scriptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count scripts', one: '1 script', zero: 'Nenhum script');
    return '$_temp0';
  }

  @override
  String get automateEyebrow => 'Duas formas de automatizar';

  @override
  String runningOn(String what, String device) {
    return '$what em $device';
  }

  @override
  String get automateTogether1 => 'Juntos: um script pode iniciar uma sequência, ';

  @override
  String get automateTogether2 => ', e decidir quando.';

  @override
  String get sequenceOrScript => 'Sequência ou script?';

  @override
  String get running => 'Em execução';

  @override
  String get layoutHud => 'HUD';

  @override
  String get layoutWall => 'WALL';

  @override
  String get editLayout => 'Editar layout';

  @override
  String get sceneLayers3d => 'Camadas da cena 3D';

  @override
  String get layerCloud => 'Nuvem de pontos';

  @override
  String get layerTrail => 'Trajetória';

  @override
  String get layerRadar => 'Rastros de radar';

  @override
  String get layerGrid => 'Grade do chão';

  @override
  String get sceneLayers => 'Camadas da cena';

  @override
  String get addWidget => 'Adicionar widget';

  @override
  String widgetsSavedFor(String device, String screens) {
    return 'Os widgets são salvos para $device em telas de $screens.';
  }

  @override
  String get thisDevice => 'este dispositivo';

  @override
  String get screenPhone => 'celular';

  @override
  String get screenShort => 'celular deitado';

  @override
  String get screenPortrait => 'tablet em pé';

  @override
  String get screenTablet => 'tablet';

  @override
  String get screenDesktop => 'computador';

  @override
  String get reset => 'Redefinir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get saveLayout => 'Salvar layout';

  @override
  String get back => 'Voltar';

  @override
  String get paused => 'Pausado';

  @override
  String get stale => 'Desatualizado';

  @override
  String hzLive(int hz) {
    return '$hz Hz ao vivo';
  }

  @override
  String get resume => 'Retomar';

  @override
  String get pause => 'Pausar';

  @override
  String get statMin => 'Mín';

  @override
  String get statMax => 'Máx';

  @override
  String get statMean => 'Média';

  @override
  String get unit => 'Unidade';

  @override
  String get window => 'Janela';

  @override
  String get windowValue => '10 s · 300 amostras';

  @override
  String get source => 'Fonte';

  @override
  String get tapChannelToHide => 'Toque num canal para ocultá-lo';

  @override
  String get rec => 'Rec';

  @override
  String get speedLimit => 'Limite de velocidade';

  @override
  String get setHomePose => 'Definir pose inicial';

  @override
  String get setHomeHere => 'Definir início aqui';

  @override
  String get useThisPose => 'Usar esta pose';

  @override
  String get setHome => 'Definir início';

  @override
  String get setHomePoseBody => 'Os ângulos atuais das juntas viram a pose para onde vão a Pose inicial e os passos Início das sequências.';

  @override
  String setHomeBody(String length) {
    return 'A posição atual vira o início (0, 0). O retorno para casa volta para cá, e os waypoints das sequências são medidos daqui. O dispositivo está a $length do início atual.';
  }

  @override
  String get autoDashDrives => 'o dash pilota';

  @override
  String get autoTakeBack => 'Escolha MANUAL ou HOLD, ou mova os sticks, para retomar o controle.';

  @override
  String get autoTip => 'O modo do dash: enquanto uma sequência ou um script pilota o dispositivo. Inicie um em Automatizar.';

  @override
  String get tiltDrag => 'Tilt · arraste para simular';

  @override
  String get stickThrottle => 'Acelerador';

  @override
  String get stickDrive => 'Avançar';

  @override
  String get stickYaw => 'Guinada';

  @override
  String get stickPitchRoll => 'Arfagem · rolagem';

  @override
  String get stickSteer => 'Direção';

  @override
  String get stickThrottleYaw => 'Acelerador · guinada';

  @override
  String get tiltPitchRoll => 'Tilt · arfagem e rolagem';

  @override
  String get tiltSteerDrive => 'Tilt · direção e avanço';

  @override
  String get axUp => 'CIMA';

  @override
  String get axDn => 'BAIXO';

  @override
  String get axFwd => 'FRENTE';

  @override
  String get axRev => 'RÉ';

  @override
  String get axBack => 'TRÁS';

  @override
  String get axL => 'E';

  @override
  String get axR => 'D';

  @override
  String get axYaw => 'GUIN';

  @override
  String get rdAlt => 'Alt';

  @override
  String get rdOdom => 'Odom';

  @override
  String get rdSpeed => 'Velocidade';

  @override
  String get rdHdg => 'Rumo';

  @override
  String get rdHome => 'Início';

  @override
  String get rdVz => 'Vz';

  @override
  String get rdMax => 'Máx';

  @override
  String get rdRange => 'Distância';

  @override
  String get rdToolX => 'Ferram. X';

  @override
  String get rdToolY => 'Ferram. Y';

  @override
  String get rdToolZ => 'Ferram. Z';

  @override
  String get rdThrust => 'Empuxo';

  @override
  String get rdRpm => 'RPM';

  @override
  String get rdCurrent => 'Corrente';

  @override
  String get rdPower => 'Potência';

  @override
  String get rdTemp => 'Temp';

  @override
  String get rdEfficiency => 'Eficiência';

  @override
  String get homePose => 'Pose inicial';

  @override
  String get setAsHome => 'Definir como início';

  @override
  String get armJoint => 'Junta';

  @override
  String get armCartesian => 'Cartesiano';

  @override
  String get toolFrame => 'Referencial da ferramenta · relativo à base';

  @override
  String armPadHelp(String frame, String wristBtn, String wrist, String gripper) {
    return 'Controle · $frame: junta / cartesiano · $wristBtn: $wrist · $gripper: garra';
  }

  @override
  String get armWrist => 'punho';

  @override
  String get gripper => 'Garra';

  @override
  String gripperOpenPct(int pct) {
    return '$pct% aberta';
  }

  @override
  String get gripperOpen => 'Abrir';

  @override
  String get gripperClose => 'Fechar';

  @override
  String get flightPhase => 'Fase de voo';

  @override
  String get phasePad => 'Na plataforma';

  @override
  String get phaseCount => 'Contagem regressiva';

  @override
  String get phaseBoost => 'Propulsão';

  @override
  String get phaseCoast => 'Inércia';

  @override
  String get phaseDrogue => 'Drogue';

  @override
  String get phaseMain => 'Principal';

  @override
  String get phaseLanded => 'Pousado';

  @override
  String get preflight => 'Pré-voo';

  @override
  String get checkPyro => 'Continuidade pyro · drogue, principal';

  @override
  String get ok => 'OK';

  @override
  String get check => 'Verificar';

  @override
  String get checkGps => 'Fix de GPS';

  @override
  String sats(int count) {
    return '$count sats';
  }

  @override
  String get noFix => 'Sem fix';

  @override
  String get checkFlightComputer => 'Computador de voo';

  @override
  String get safe => 'Seguro';

  @override
  String get armFlightComputer => 'Armar o computador de voo';

  @override
  String get armPadClear => 'Arme só quando a plataforma estiver livre';

  @override
  String startCountdown(String seconds) {
    return 'Iniciar contagem · $seconds s';
  }

  @override
  String get abortLaunch => 'Abortar lançamento';

  @override
  String get deployDrogue => 'Abrir drogue';

  @override
  String get deployMain => 'Abrir principal';

  @override
  String autoDeploy(String length) {
    return 'Abertura automática · drogue no apogeu · principal a $length';
  }

  @override
  String landedBody(String apogee, String distance) {
    return 'Apogeu $apogee · pousou a $distance da plataforma.';
  }

  @override
  String get resetToPad => 'Voltar à plataforma';

  @override
  String get altitude => 'Altitude';

  @override
  String get cutoff => 'Corte';

  @override
  String get cutoffLimit => 'limite';

  @override
  String get cutoffBody => 'O acelerador foi zerado. Verifique o motor antes de rodar de novo.';

  @override
  String get clear => 'Limpar';

  @override
  String get benchDisarmed => 'Arme a bancada para girar o motor. Fique longe da hélice.';

  @override
  String get testSequence => 'Sequência de teste';

  @override
  String get benchRamp => 'RAMPA';

  @override
  String get benchSteps => 'DEGRAUS';

  @override
  String get runAndRecord => 'Rodar e gravar';

  @override
  String benchRampDesc(String seconds) {
    return 'Rampa de 0 a 100% em $seconds s, manter 2 s, parar.';
  }

  @override
  String benchStepsDesc(String size, String seconds) {
    return 'Degraus de $size%, $seconds s cada, até 100%.';
  }

  @override
  String benchLimits(String amps, String temperature) {
    return 'Limites: $amps A, $temperature.';
  }

  @override
  String get mspTitle => 'Monitoramento e ajuste';

  @override
  String mspBody(String name, String firmware) {
    return '$name roda $firmware e está conectado por MSP, o link de configuração. O app mostra a telemetria, ajusta os ganhos PID em Parâmetros, e o STOP o desarma. Voe com seu rádio controle.';
  }

  @override
  String get radioOnlyTitle => 'Link só de telemetria';

  @override
  String radioOnlyBody(String name, String radio) {
    return '$name está conectado por $radio, que só leva telemetria. Sticks, modos e comandos não chegam ao dispositivo por aqui; o STOP chega, em cerca de um segundo. Controle-o pelo link principal (Wi-Fi, Bluetooth ou rádio SiK) e conte com o failsafe dele quando esse link estiver fora de alcance.';
  }

  @override
  String get aRadio => 'um rádio';

  @override
  String get tileReadouts => 'Leituras';

  @override
  String get tileSrcFused => 'Estado fundido';

  @override
  String get tileAttitude => 'Atitude';

  @override
  String get tileAccelerometer => 'Acelerômetro';

  @override
  String get tileGyroscope => 'Giroscópio';

  @override
  String get tileSrcBaroRange => 'Baro + telêmetro';

  @override
  String get tileRadar => 'Radar';

  @override
  String get tileSrcRadar => 'Radar / scanner de segurança';

  @override
  String get tileLidar => 'Lidar';

  @override
  String get tileSrcLidar => 'Lidar de varredura';

  @override
  String get tileJoints => 'Juntas';

  @override
  String get tileSrcJoints => 'Encoders das juntas';

  @override
  String get tileForceTorque => 'Força / torque';

  @override
  String get tileSrcWrist => 'Sensor F/T do punho';

  @override
  String get tileSrcPower => 'Módulo de energia';

  @override
  String get tileSrcRadio => 'Link de rádio';

  @override
  String get tileCamera => 'Câmera';

  @override
  String get tileSrcCamera => 'Câmera do dispositivo · MJPEG';

  @override
  String get tileSrcFleet => 'Cada dispositivo conectado';

  @override
  String get tileSrcPhase => 'Máquina de estados do computador de voo';

  @override
  String get tileVerticalSpeed => 'Velocidade vertical';

  @override
  String get tileSrcBaroImu => 'Fusão baro + IMU';

  @override
  String get tilePyro => 'Canais pyro';

  @override
  String get tileSrcPyro => 'Placa pyro de 4 canais';

  @override
  String get tileSrcTacho => 'Tacômetro óptico';

  @override
  String get tileTorque => 'Torque';

  @override
  String get tileSrcTorque => 'Célula de torque de reação';

  @override
  String get tileMotorTemp => 'Temp. do motor';

  @override
  String get tileSrcNtc => 'Termistor NTC';

  @override
  String get tileRollRate => 'Taxa de rolagem';

  @override
  String get tilePitchRate => 'Taxa de arfagem';

  @override
  String get tileYawRate => 'Taxa de guinada';

  @override
  String get tileGroundSpeed => 'Velocidade em solo';

  @override
  String get tileAgl => 'Altura';

  @override
  String get tileOwnSpeed => 'Velocidade própria';

  @override
  String get tileVoltage => 'Tensão';

  @override
  String get tilePyroBus => 'Barramento pyro';

  @override
  String get tileStator => 'Estator';

  @override
  String get tileVibration => 'Vibração';

  @override
  String get tileAcc200 => 'Acelerômetro · 200 G';

  @override
  String get tileSafetyScanner => 'Scanner de segurança';

  @override
  String tracks(int count) {
    return '$count rastros';
  }

  @override
  String points(int count) {
    return '$count pts';
  }

  @override
  String axes(int count) {
    return '$count eixos';
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
  String get proxClear => 'livre';

  @override
  String get tileProximity => 'Proximidade';

  @override
  String get tileSrcProx => 'Sensores de proximidade';

  @override
  String tileSrcCustom(String hz) {
    return 'Canal personalizado · $hz Hz';
  }

  @override
  String get tagScript => 'Script';

  @override
  String get viewEnded => 'encerrado';

  @override
  String series(int count) {
    return '$count séries';
  }

  @override
  String get rdReach => 'Alcance';

  @override
  String get pyroDrogue => 'Drogue';

  @override
  String get pyroMain => 'Principal';

  @override
  String get pyroAirstart => 'Ignição em voo';

  @override
  String get pyroSpare => 'Reserva';

  @override
  String get pyroContinuity => 'Continuidade';

  @override
  String get pyroFired => 'Disparado';

  @override
  String get pyroNotWired => 'Sem fio';

  @override
  String removeTitle(String name) {
    return 'Remover $name?';
  }

  @override
  String get removeDevice => 'Remover dispositivo';

  @override
  String removeBody(String name) {
    return 'A chave de pareamento, os layouts do HUD e os rascunhos de parâmetros de $name são apagados deste app.';
  }

  @override
  String get removeDisconnectFirst => 'Ele será desconectado antes.';

  @override
  String get removeKept => 'As gravações são mantidas. Para usar o dispositivo de novo, pareie com um código novo.';

  @override
  String onlineOf(int online, int total) {
    return '$online de $total online';
  }

  @override
  String get devicesEmptyHint => 'Pareie um dispositivo, ou siga o início rápido para adicionar a biblioteca ao seu projeto.';

  @override
  String get devicesSeveral =>
      'Vários dispositivos podem ficar conectados ao mesmo tempo. O que aparece recebe os sticks; os outros ficam parados com os sticks centralizados, e o STOP para todos.';

  @override
  String get connected => 'Conectado';

  @override
  String removeName(String name) {
    return 'Remover $name';
  }

  @override
  String get online => 'Online';

  @override
  String get batShort => 'BAT';

  @override
  String get myRobot => 'Meu robô';

  @override
  String radioNothingHeard(String port, int baud) {
    return 'Nada recebido em $port a $baud baud. Verifique se o dispositivo está ligado, se os dois rádios usam o mesmo canal e a mesma taxa no ar, e se o baud confere. Você ainda pode adicionar o link e conectar depois.';
  }

  @override
  String get pairTitle => 'Parear um dispositivo';

  @override
  String get pairNearby => 'Por perto';

  @override
  String get pairRadio => 'Rádio';

  @override
  String get pairSimulated => 'Simulados';

  @override
  String get pairSimulatedIntro =>
      'Os dispositivos simulados rodam dentro deste app e falam o mesmo protocolo do hardware real. Adicione só os que precisar; cada um aparece com a etiqueta SIM.';

  @override
  String get added => 'Adicionado';

  @override
  String get addAnother => 'Adicionar outro';

  @override
  String get add => 'Adicionar';

  @override
  String radioRatesTlm(int tlm) {
    return 'Telemetria $tlm Hz · sem controle';
  }

  @override
  String radioRates(int tlm, int ctl) {
    return 'Telemetria $tlm Hz · controle $ctl Hz';
  }

  @override
  String get radioIntro => 'Um link de rádio é um modem de rádio ligado por USB a este computador ou celular, conversando com um rádio par no dispositivo.';

  @override
  String get radioIntroMore => 'Para o app é uma porta serial; o tipo de rádio define a velocidade e quanto ele consegue levar.';

  @override
  String get radioNoSerial => 'Sem serial USB nesta plataforma';

  @override
  String get radioNoSerialBody =>
      'Apps de iOS não conseguem abrir adaptadores seriais USB. Use o app no Android, macOS, Windows ou Linux para links de rádio, ou conecte por Wi-Fi ou Bluetooth.';

  @override
  String get radioLora =>
      'Módulos LoRa não são dispositivos USB por si só. Grave o sketch de estação de solo do guia LoRa numa segunda placa com o rádio e ligue essa placa.';

  @override
  String get usbPort => 'Porta USB';

  @override
  String get refresh => 'Atualizar';

  @override
  String get noSerialPorts => 'Nenhuma porta serial encontrada. Ligue o adaptador USB do rádio.';

  @override
  String get baudRate => 'Baud';

  @override
  String heard(String name) {
    return '$name recebido';
  }

  @override
  String get heardMavlink => 'Ele fala MAVLink: não precisa parear.';

  @override
  String get heardPairing => 'Está em modo de pareamento e vai receber uma chave.';

  @override
  String get heardNoPairing => 'Não está em modo de pareamento; é adicionado sem chave.';

  @override
  String get listening => 'Escutando';

  @override
  String get listenForDevice => 'Escutar o dispositivo';

  @override
  String pairName(String name) {
    return 'Parear $name';
  }

  @override
  String get addRadioLink => 'Adicionar link de rádio';

  @override
  String get pairNearbyIntro =>
      'Ligue ou conecte a placa. Controladoras de voo e drones aparecem sozinhos; placas com a biblioteca koebelt/link também aparecem aqui em modo de pareamento.';

  @override
  String get scanning => 'Procurando por Wi-Fi, Bluetooth e USB…';

  @override
  String get stillScanning => 'Procurando mais dispositivos…';

  @override
  String get addByIp => 'Adicionar por endereço IP';

  @override
  String get name => 'Nome';

  @override
  String get mavlinkPortNote => 'O app escuta na UDP 14550, como qualquer estação de solo; a porta é a do veículo, se você souber.';

  @override
  String get addDevice => 'Adicionar dispositivo';

  @override
  String get notShowingUp =>
      'O dispositivo não aparece? Placas com ArduPilot, PX4, Betaflight ou INAV se conectam como estão; o resto precisa da biblioteca koebelt/link.';

  @override
  String get openQuickstart => 'Abrir o início rápido';

  @override
  String get orLower => 'ou';

  @override
  String get addItByIp => 'adicioná-lo por endereço IP';

  @override
  String get secControl => 'Controle';

  @override
  String get secController => 'Controle de jogo';

  @override
  String get secLink => 'Link e segurança';

  @override
  String get secRecording => 'Gravação';

  @override
  String get secAlerts => 'Alertas';

  @override
  String get secMap => 'Mapa';

  @override
  String get secPairing => 'Pareamento';

  @override
  String get secAi => 'Assistentes de IA (MCP)';

  @override
  String get secAiShort => 'Assistentes de IA';

  @override
  String get secUpdates => 'Atualizações';

  @override
  String get setInput => 'Modo de controle';

  @override
  String get setInputDesc =>
      'Sticks: dois joysticks virtuais. Sliders: acelerador e guinada com mola e um só stick. Tilt: dirija inclinando o celular ou o tablet.';

  @override
  String get csSticks => 'STICKS';

  @override
  String get csSliders => 'SLIDERS';

  @override
  String get csTilt => 'TILT';

  @override
  String get setInvert => 'Inverter arfagem';

  @override
  String get setInvertDesc => 'Empurrar para frente para levantar o nariz.';

  @override
  String get setHaptics => 'Resposta tátil';

  @override
  String get setHapticsDesc => 'Vibrar no centro dos sticks e nos avisos.';

  @override
  String get setLinkLoss => 'Ao perder o link';

  @override
  String get setLinkLossDesc =>
      'O que um drone faz após 1,8 s sem pacote de controle. Robôs terrestres e braços param, bancadas desligam o motor, foguetes seguem a sequência de voo.';

  @override
  String get setRate => 'Taxa de telemetria';

  @override
  String get setRateDesc => 'Taxas maiores usam mais banda e bateria.';

  @override
  String get setTestFailsafe => 'Testar o failsafe';

  @override
  String get setTestFailsafeDesc => 'Corta o link de controle por seis segundos para você conferir o comportamento configurado.';

  @override
  String get runTest => 'Rodar teste';

  @override
  String get setRecordVideo => 'Gravar vídeo';

  @override
  String get setRecordVideoDesc =>
      'Guarda a câmera do dispositivo em cada gravação. A câmera fica conectada durante a gravação, mesmo sem nenhuma tela mostrando.';

  @override
  String get setVideoFps => 'Quadros por segundo do vídeo';

  @override
  String get setVideoFpsDesc => 'Máximo de quadros por segundo guardados. Uma ESP32-CAM em 640×480 ocupa uns 10 MB por minuto a 10 fps.';

  @override
  String get setAlertSound => 'Som de alerta';

  @override
  String get setAlertSoundDesc => 'Toca nos alertas e quando o link cai. Celulares vibram em vez disso quando a resposta tátil está ligada.';

  @override
  String kindsOnly(String kinds) {
    return 'Só $kinds.';
  }

  @override
  String get below => 'Abaixo';

  @override
  String get above => 'Acima';

  @override
  String get setMapTiles => 'Blocos do mapa';

  @override
  String get setMapTilesDesc =>
      'Fundo da vista de mapa: Mapbox Dark, Outdoors (relevo) ou Satellite, seus próprios blocos, ou nenhum (uma grade métrica). Os blocos que você viu ficam neste dispositivo por um tempo.';

  @override
  String get mapDark => 'ESCURO';

  @override
  String get mapOutdoors => 'EXTERNO';

  @override
  String get mapSatellite => 'SATÉLITE';

  @override
  String get mapCustom => 'PRÓPRIO';

  @override
  String get mapNone => 'NENHUM';

  @override
  String get setMapboxToken => 'Seu token do Mapbox';

  @override
  String get setMapboxTokenDesc => 'Opcional: um token público (pk.…) da sua própria conta Mapbox, para usar a sua cota em vez da do app.';

  @override
  String get setTileUrl => 'URL dos blocos';

  @override
  String setTileUrlDesc(String z, String x, String y) {
    return 'Um modelo com $z, $x e $y, por exemplo uma camada de satélite do seu provedor de mapas com a chave dele. Respeite os termos do provedor.';
  }

  @override
  String get setAttribution => 'Atribuição';

  @override
  String get setAttributionDesc => 'O crédito que o seu provedor exige, mostrado no mapa.';

  @override
  String get provider => 'Provedor';

  @override
  String get setGuides => 'Guias de integração';

  @override
  String get setGuidesDesc => 'Adicione a biblioteca koebelt/link a projetos Arduino, Python, ROS 2 ou Rust.';

  @override
  String scriptHostAt(String address) {
    return 'Host de scripts em $address';
  }

  @override
  String get forget => 'Esquecer';

  @override
  String get setScriptHosts => 'Hosts de scripts';

  @override
  String get setScriptHostsDesc =>
      'Computadores da rede que rodam scripts para este dispositivo, com qualquer pacote Python. No computador: pip install koebelt-dash-scripts, depois koebelt-dash-scripts host.';

  @override
  String get setScriptHostsDescPhone =>
      'Computadores da rede que rodam scripts para este celular, com qualquer pacote Python. No computador: pip install koebelt-dash-scripts, depois koebelt-dash-scripts host.';

  @override
  String get setBeHost => 'Ser um host de scripts';

  @override
  String get setBeHostDesc => 'Rode scripts para celulares e tablets desta rede, com o Python dos scripts.';

  @override
  String setBeHostCode(String code) {
    return 'Código de pareamento: $code. Os celulares pareiam em Scripts > Roda em > Adicionar um host de scripts.';
  }

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sessões', one: '1 sessão');
    return '$_temp0';
  }

  @override
  String get import => 'Importar';

  @override
  String get record => 'Gravar';

  @override
  String get noRecordings => 'Ainda não há gravações. Grave um dispositivo conectado, ou use Importar para um arquivo ou as gravações de exemplo.';

  @override
  String get tagNew => 'Novo';

  @override
  String get tagVideo => 'Vídeo';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count dispositivos', one: '1 dispositivo');
    return '$_temp0';
  }

  @override
  String deleteName(String name) {
    return 'Apagar $name';
  }

  @override
  String exportName(String name) {
    return 'Exportar $name';
  }

  @override
  String get replayEyebrow => 'Gravação e reprodução';

  @override
  String get sessions => 'Sessões';

  @override
  String get export => 'Exportar';

  @override
  String get exitToLive => 'Voltar ao live';

  @override
  String get play => 'Reproduzir';

  @override
  String deleteTitle(String name) {
    return 'Apagar $name?';
  }

  @override
  String get exportFirst => 'Exportar antes';

  @override
  String get delete => 'Apagar';

  @override
  String get deleteRecordingBody => 'A gravação é removida deste dispositivo. Isso não pode ser desfeito.';

  @override
  String deleteAllN(int count) {
    return 'Apagar todas as $count';
  }

  @override
  String get deleteSessionBody => 'A gravação de cada dispositivo desta sessão é removida deste dispositivo, com o vídeo. Isso não pode ser desfeito.';

  @override
  String sequenceN(int n) {
    return 'Sequência $n';
  }

  @override
  String sequencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sequências', one: '1 sequência', zero: 'nenhuma sequência');
    return '$_temp0';
  }

  @override
  String copyOf(String name) {
    return '$name (cópia)';
  }

  @override
  String noSequencesFor(String name) {
    return 'Ainda não há sequências para $name.';
  }

  @override
  String sequenceIntro(String examples) {
    return 'Uma sequência é uma lista de passos ($examples) que o app executa um após o outro, esperando o dispositivo confirmar cada um.';
  }

  @override
  String get sequenceComplete => 'Sequência concluída';

  @override
  String get sequenceStopped => 'Sequência parada';

  @override
  String get flightSequence => 'Sequência de voo';

  @override
  String get flightSequenceBody =>
      'O computador de voo cuida a bordo do lançamento, do apogeu e da recuperação. Ajuste a abertura em Parâmetros; use as sequências aqui para as checagens na plataforma.';

  @override
  String get stepsDrone => 'decolar, voar até waypoints, esperar, pousar';

  @override
  String get stepsPlane => 'decolar, voar um circuito por waypoints, pousar';

  @override
  String get stepsRover => 'dirigir até waypoints, esperar, mudar a velocidade';

  @override
  String get stepsArm => 'ir para poses, abrir ou fechar a garra';

  @override
  String get stepsBench => 'manter um acelerador, rampa entre dois aceleradores';

  @override
  String get stepsGeneric => 'esperar, definir um modo, enviar comandos';

  @override
  String get whyExitReplay => 'Saia do replay para rodar';

  @override
  String get whyResetStop => 'Redefina a parada antes';

  @override
  String get whyAddSteps => 'Adicione passos antes';

  @override
  String get onDevice => 'No dispositivo';

  @override
  String get uploading => 'Enviando';

  @override
  String stepOf(int n, int total) {
    return 'passo $n de $total';
  }

  @override
  String get runsOnDevice => 'Roda no dispositivo: continua se o link cair';

  @override
  String get stopSequence => 'Parar sequência';

  @override
  String get stoppedFromApp => 'Parada pelo app';

  @override
  String get run => 'Rodar';

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count passos', one: '1 passo');
    return '$_temp0';
  }

  @override
  String secondsTimed(String seconds) {
    return '$seconds s cronometrados';
  }

  @override
  String get newSequence => 'Nova sequência';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get steps => 'Passos';

  @override
  String get lockedWhileRunning => 'Bloqueada durante a execução';

  @override
  String get addFirstStep => 'Adicione o primeiro passo abaixo. Os passos rodam de cima para baixo.';

  @override
  String get addStep => 'Adicionar passo';

  @override
  String get dragToReorder => 'Arraste para reordenar';

  @override
  String get deleteStep => 'Apagar passo';

  @override
  String get useCurrentPosition => 'Usar a posição atual';

  @override
  String get useCurrentPose => 'Usar a pose atual';

  @override
  String get egDeploy => 'ex.: deploy';

  @override
  String get planTopView => 'Plano · vista de cima';

  @override
  String get throttleProfile => 'Perfil do acelerador';

  @override
  String get liveView => 'Vista ao vivo';

  @override
  String get timeline => 'Linha do tempo';

  @override
  String get setPoseAsHome => 'Pose atual como início';

  @override
  String get planNoteDrone =>
      'Os waypoints são metros a leste e a norte do ponto de decolagem. O drone para em cada um antes do próximo passo. O failsafe continua valendo se o link cair.';

  @override
  String get planNotePlane =>
      'Os waypoints são metros a leste e ao norte do ponto de decolagem. Um avião não consegue parar: ele passa por cada um e circula enquanto espera. O failsafe continua valendo se o link cair.';

  @override
  String get planNoteRover => 'Os waypoints são metros a leste e a norte do ponto de partida. O rover para em cada um antes do próximo passo.';

  @override
  String get planNoteBoat =>
      'Os waypoints são metros a leste e ao norte do ponto de partida. O barco desacelera em cada um antes do próximo passo; vento e correnteza podem deslocá-lo enquanto espera.';

  @override
  String planNoteArm(String button) {
    return 'Mova o braço à mão ou com os controles de jog, depois use “$button” para gravá-la.';
  }

  @override
  String get planNoteBench => 'Os cortes por corrente e temperatura do dispositivo continuam ativos durante a sequência.';

  @override
  String get planNoteGeneric => 'Cada passo espera a confirmação do dispositivo antes de o próximo começar.';

  @override
  String metreGrid(String length) {
    return 'grade de $length';
  }

  @override
  String get now => 'Agora';

  @override
  String get and => 'e';

  @override
  String get checkNeedsPython => 'A checagem precisa de Python neste computador: Configurar Python na página do script.';

  @override
  String couldNotCheck(String python) {
    return 'Não foi possível checar com $python.';
  }

  @override
  String scriptErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Este script tem $count erros', one: 'Este script tem um erro');
    return '$_temp0';
  }

  @override
  String get runAnyway => 'Rodar mesmo assim';

  @override
  String get showThem => 'Mostrar';

  @override
  String get checkFound => 'A checagem achou o que o pararia, provavelmente antes de mover qualquer coisa:';

  @override
  String lineN(int n) {
    return 'linha $n';
  }

  @override
  String andMore(int count) {
    return 'e mais $count';
  }

  @override
  String get installImports => 'Instalar o que este script importa?';

  @override
  String get installAndRun => 'Instalar e rodar';

  @override
  String missingImports(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names não estão neste Python, então o script pararia nos imports.',
      one: '$names não está neste Python, então o script pararia nos imports.',
    );
    return '$_temp0';
  }

  @override
  String couldNotStart(String error) {
    return 'Não foi possível iniciar: $error';
  }

  @override
  String get pythonScripts => 'Scripts Python';

  @override
  String copiedExample(String file) {
    return 'Exemplo copiado para $file nos seus scripts.';
  }

  @override
  String couldNotCopyExample(String error) {
    return 'Não foi possível copiar o exemplo: $error';
  }

  @override
  String get rename => 'Renomear';

  @override
  String get deleteScriptBody => 'Ele vai para a pasta .trash dentro da pasta de scripts, de onde você pode recuperá-lo.';

  @override
  String get error => 'Erro';

  @override
  String get examples => 'Exemplos';

  @override
  String get connectedOutside => 'Conectado de fora do dash';

  @override
  String get editing => 'editando';

  @override
  String get saved => 'salvo';

  @override
  String get checkAction => 'Checar';

  @override
  String get checking => 'Checando…';

  @override
  String get openInEditor => 'Abrir no editor';

  @override
  String get newScript => 'Novo script';

  @override
  String get importPyZip => 'Importar um .py ou .zip';

  @override
  String get noScriptsPlus => 'Ainda não há scripts. Comece por um exemplo, ou toque em +.';

  @override
  String get scriptsEmpty => 'Scripts pilotam seus dispositivos com Python. Crie um, importe um ou comece por um exemplo.';

  @override
  String get edit => 'Editar';

  @override
  String get share => 'Compartilhar';

  @override
  String get noScriptsNew => 'Ainda não há scripts. Comece por um exemplo, ou toque em Novo.';

  @override
  String get more => 'Mais';

  @override
  String get showInFinder => 'Mostrar no Finder';

  @override
  String get showInFolder => 'Mostrar na pasta';

  @override
  String get myScript => 'Meu script';

  @override
  String get create => 'Criar';

  @override
  String get save => 'Salvar';

  @override
  String get device => 'Dispositivo';

  @override
  String get needs => 'Requer';

  @override
  String get runsOn => 'Roda em';

  @override
  String get scriptsRunOnComputer => 'Scripts rodam num computador';

  @override
  String get scriptsRunOnComputerBody =>
      'Este dispositivo os envia para um host de scripts: um computador da mesma rede rodando koebelt-dash-scripts, que pode usar qualquer pacote Python (OpenCV, PyTorch…).';

  @override
  String get addScriptHost => 'Adicionar um host de scripts';

  @override
  String get notRunning => 'Parado';

  @override
  String get endedError => 'Terminou com erro';

  @override
  String get ended => 'Terminou';

  @override
  String get waitingConnect => 'Esperando o script conectar (connect() no script)…';

  @override
  String get youHaveSticks => 'Você está com os sticks';

  @override
  String get youHaveSticksBody => 'Você mexeu os sticks, então os do script são ignorados.';

  @override
  String get scriptLostSticks => 'O script perdeu os sticks';

  @override
  String isNotConnected(String name) {
    return '$name não está conectado';
  }

  @override
  String get connectItOrChoose => 'Conecte-o, ou escolha outro dispositivo acima.';

  @override
  String doesNotFit(String name) {
    return '$name não serve para este script';
  }

  @override
  String get chooseOrChangeRequires => 'Escolha outro dispositivo acima, ou mude a linha # requires:.';

  @override
  String get scriptNeedsDevice => 'Um script pilota um dispositivo: conecte um antes (Dispositivos, ou o menu de dispositivos no topo).';

  @override
  String get doesNotFitShort => 'não serve';

  @override
  String get selectedInDash => 'Escolhido no dash';

  @override
  String get noneConnected => 'nenhum conectado';

  @override
  String get thisComputer => 'Este computador';

  @override
  String get lookingForPython => 'Procurando Python…';

  @override
  String get noneFound => 'Nenhum encontrado';

  @override
  String get noPackage => 'sem o pacote';

  @override
  String get python3Needed => 'É preciso o Python 3';

  @override
  String get python3NeededBody => 'Instale pelo python.org e volte aqui.';

  @override
  String get newerLibrary => 'Saiu uma versão mais nova da biblioteca dos scripts, para esta versão do koebelt dash.';

  @override
  String get update => 'Atualizar';

  @override
  String get pythonNoAnswer => 'Este Python não responde';

  @override
  String get packageNotInPython => 'koebelt-dash-scripts não está neste Python';

  @override
  String pythonNoAnswerBody(String python) {
    return 'O dash não conseguiu rodar $python. Escolha outro, ou crie um ambiente de scripts.';
  }

  @override
  String get packageNotInPythonBody => 'Instale aqui (pip install koebelt-dash-scripts), ou deixe o dash criar um ambiente de scripts na pasta de scripts.';

  @override
  String get installHere => 'Instalar aqui';

  @override
  String get scriptsEnvironment => 'Ambiente de scripts';

  @override
  String get checkAgain => 'Checar de novo';

  @override
  String get settingUpPython => 'Configurando o Python';

  @override
  String get oneTimeSetup => 'Configuração inicial';

  @override
  String get oneTimeSetupBody =>
      'Os scripts precisam do pacote koebelt-dash-scripts. O dash pode criar um ambiente Python para eles na pasta de scripts (.venv) e instalá-lo lá; seus próprios pacotes (OpenCV, PyTorch…) também vão para lá.';

  @override
  String get setUpPython => 'Configurar Python';

  @override
  String packagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Faltam pacotes', one: 'Falta um pacote');
    return '$_temp0';
  }

  @override
  String packagesMissingBody(String modules, String packages) {
    return 'Este script importa $modules, que não está neste Python: ele pararia ali. Instalar $packages?';
  }

  @override
  String get installing => 'Instalando…';

  @override
  String get install => 'Instalar';

  @override
  String get notNow => 'Agora não';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get stopScript => 'Parar script';

  @override
  String get restart => 'Reiniciar';

  @override
  String get triggers => 'Triggers';

  @override
  String get triggersEmpty =>
      'Botões, teclas, botões do controle, condições e timers que mandam eventos para o script. Declare-os com @dev.trigger(…), ou adicione-os aqui.';

  @override
  String get limits => 'Limites';

  @override
  String get maxSpeed => 'Velocidade máx';

  @override
  String get geofence => 'Geofence';

  @override
  String get off => 'desligado';

  @override
  String metresFromHome(String length) {
    return '$length do início';
  }

  @override
  String get ceiling => 'Teto';

  @override
  String get armingTakeoff => 'Armar, decolar';

  @override
  String get allowed => 'permitido';

  @override
  String get notAllowed => 'não permitido';

  @override
  String get paramWrites => 'Escrita de parâmetros';

  @override
  String get fire => 'Disparar';

  @override
  String get notBound => 'Ainda não atribuído';

  @override
  String get console => 'Console';

  @override
  String loopHz(String hz) {
    return 'loop $hz Hz';
  }

  @override
  String get consoleEmpty => 'A saída de print() e os erros aparecem aqui.';

  @override
  String get fromOutside => 'de fora do dash';

  @override
  String get valid => 'Válida';

  @override
  String padTaken(String button, String action) {
    return '$button é $action no mapeamento do controle: essa ação prevalece.';
  }

  @override
  String get forDuration => 'por';

  @override
  String conditionHelp(String fields) {
    return 'Campos: $fields, mode, armed, e os canais próprios do dispositivo (motor_temp.max…). Combine com and, or, not; adicione “for 3s” para esperar.';
  }

  @override
  String get whenTrue => 'QUANDO VERDADEIRO';

  @override
  String get trueAndFalse => 'VERDADEIRO E FALSO';

  @override
  String get alsoOnControl => 'Também em Controle, ao lado dos sticks';

  @override
  String get key => 'Tecla';

  @override
  String get pressKey => 'Aperte uma tecla…';

  @override
  String pressAnotherKey(String key) {
    return '$key · aperte outra para mudar';
  }

  @override
  String get clickThenKey => 'Clique e aperte uma tecla';

  @override
  String get noButtonYet => 'Ainda sem botão';

  @override
  String get pressButton => 'Aperte um botão…';

  @override
  String get learn => 'Aprender';

  @override
  String get onlyThisMode => 'Só este modo (HOLD…), ou vazio para qualquer um';

  @override
  String get onlyMessagesContaining => 'Só mensagens contendo…';

  @override
  String get every => 'A CADA';

  @override
  String get onceAfter => 'UMA VEZ APÓS';

  @override
  String get secondsWord => 'segundos';

  @override
  String get addTrigger => 'Adicionar trigger';

  @override
  String get editTrigger => 'Editar trigger';

  @override
  String get event => 'Evento';

  @override
  String get eventPlaceholder => 'O nome que o script recebe';

  @override
  String get firedBy => 'Disparado por';

  @override
  String triggerHelp(String event) {
    return 'O script recebe “$event” no handler com esse nome, ou em @dev.on_trigger. Condições, eventos e timers rodam no dash.';
  }

  @override
  String get done => 'Pronto';

  @override
  String get limitsHelp => 'Definidos aqui, não no script: o script não pode mudá-los.';

  @override
  String get maximumSpeed => 'Velocidade máxima';

  @override
  String get maximumSpeedDesc => 'Os sticks do script são escalados para isto, e o limite de velocidade dele é limitado.';

  @override
  String get geofenceDesc => 'Além desta distância do início, o script perde os sticks e o dispositivo para.';

  @override
  String get ceilingDesc => 'Acima desta altura, o mesmo, para drones.';

  @override
  String get allowArming => 'Permitir armar e decolar';

  @override
  String get allowArmingDesc => 'Senão o script só pode mover um dispositivo que você armou.';

  @override
  String get allowParams => 'Permitir escrita de parâmetros';

  @override
  String get allowParamsDesc => 'Para scripts de ajuste. Eles podem mudar o comportamento do dispositivo.';

  @override
  String get pairing => 'Pareando…';

  @override
  String get pair => 'Parear';

  @override
  String get scriptHostIntro =>
      'Um host de scripts é um computador da mesma rede que roda scripts para este computador: um notebook, um Raspberry Pi, um Jetson… Nele:';

  @override
  String get scriptHostIntroPhone =>
      'Um host de scripts é um computador da mesma rede que roda scripts para este celular ou tablet: um notebook, um Raspberry Pi, um Jetson… Nele:';

  @override
  String get onTheNetwork => 'Na rede';

  @override
  String get lookingForHosts => 'Procurando hosts de scripts';

  @override
  String get noHostsFound => 'Nenhum encontrado. Digite o endereço abaixo (mostrado por `ipconfig getifaddr en0`, `hostname -I`…).';

  @override
  String get lookAgain => 'Procurar de novo';

  @override
  String get address => 'Endereço';

  @override
  String get pairingCode => 'Código de pareamento';

  @override
  String get pairingCodePlaceholder => 'ABC-123, mostrado pelo host';

  @override
  String updatingPct(int pct) {
    return 'Atualizando $pct%';
  }

  @override
  String get installingState => 'Instalando';

  @override
  String get appUpdating => 'O koebelt dash está atualizando';

  @override
  String appAvailable(String version) {
    return 'O koebelt dash $version está disponível';
  }

  @override
  String get appUpToDate => 'O koebelt dash está atualizado';

  @override
  String get skipVersion => 'Pular esta versão';

  @override
  String get later => 'Depois';

  @override
  String downloadingPct(int pct) {
    return 'Baixando $pct%';
  }

  @override
  String get installAnyway => 'Instalar mesmo assim';

  @override
  String get updateAnyway => 'Atualizar mesmo assim';

  @override
  String installVersion(String version) {
    return 'Instalar $version';
  }

  @override
  String get updateNow => 'Atualizar agora';

  @override
  String youHaveOlder(String version) {
    return 'Você tem a $version; esta é uma versão mais antiga. Configurações e gravações feitas com uma versão mais nova podem não abrir todas nela, e ela não vai avisar das mais novas até o próximo lançamento.';
  }

  @override
  String youHave(String version) {
    return 'Você tem a $version.';
  }

  @override
  String get notFromApp => 'Não pelo app';

  @override
  String get checkingCompat => 'Checando a compatibilidade com seus dispositivos…';

  @override
  String get compatUnknown => 'Compatibilidade desconhecida';

  @override
  String get compatUnknownBody => 'Não foi possível ler quais versões do koebelt/link esta versão suporta.';

  @override
  String notCompatibleWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Não compatível com $count dos seus dispositivos',
      one: 'Não compatível com um dos seus dispositivos',
    );
    return '$_temp0';
  }

  @override
  String notCompatibleBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Atualize antes a biblioteca koebelt/link deles, ou mantenha sua versão e escolha outra em Configurações > Atualizações.',
      one: 'Atualize antes a biblioteca koebelt/link dele, ou mantenha sua versão e escolha outra em Configurações > Atualizações.',
    );
    return '$_temp0';
  }

  @override
  String get disarmFirst => 'Desarme antes';

  @override
  String get disarmFirstBody => 'Um dispositivo conectado está armado. Atualizar fecha o app, o que derruba o link; desarme-o e depois atualize.';

  @override
  String get devicesWillDisconnect => 'Os dispositivos vão desconectar';

  @override
  String devicesWillDisconnectBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A instalação fecha o app, então os $count dispositivos conectados perdem o link e o failsafe deles assume até você reconectar.',
      one: 'A instalação fecha o app, então o dispositivo conectado perde o link e o failsafe dele assume até você reconectar.',
    );
    return '$_temp0';
  }

  @override
  String get notInstalled => 'Não instalada';

  @override
  String get inThisVersion => 'Nesta versão';

  @override
  String get whatsNew => 'Novidades';

  @override
  String get fullNotes => 'Notas completas da versão';

  @override
  String get chooseAnotherVersion => 'Escolher outra versão';

  @override
  String get chooseVersion => 'Escolher uma versão';

  @override
  String get close => 'Fechar';

  @override
  String get chooseVersionBody =>
      'Instale qualquer versão publicada, mais nova ou mais antiga. Cada uma diz se funciona com as versões do koebelt/link que seus dispositivos informaram na última conexão.';

  @override
  String get askingGithub => 'Perguntando ao GitHub…';

  @override
  String get noReleases => 'Nenhuma versão encontrada.';

  @override
  String get installed => 'Instalada';

  @override
  String get latest => 'Mais recente';

  @override
  String get checkingShort => 'Checando…';

  @override
  String get worksWithDevices => 'Funciona com seus dispositivos';

  @override
  String get noDevicesToCheck => 'Ainda não há dispositivos para checar';

  @override
  String notFor(String names) {
    return 'Não para $names';
  }

  @override
  String get details => 'Detalhes';

  @override
  String get updateHowAndroid => 'A atualização é baixada aqui e o Android pede para você confirmar a instalação.';

  @override
  String get updateHow => 'A atualização é baixada, conferida com a versão publicada, e o koebelt dash reinicia na nova versão.';

  @override
  String versionN(String version) {
    return 'Versão $version';
  }

  @override
  String get noSelfUpdate =>
      'Esta versão não se atualiza sozinha: a App Store e o TestFlight atualizam as delas, e os downloads do GitHub procuram novas versões por conta própria.';

  @override
  String get releases => 'Versões';

  @override
  String get upToDate => 'Atualizado.';

  @override
  String versionAvailable(String version) {
    return '$version está disponível.';
  }

  @override
  String downloadingWhat(String what, int pct) {
    return 'Baixando $what… $pct%';
  }

  @override
  String installingWhat(String what) {
    return 'Instalando $what…';
  }

  @override
  String get somethingWrong => 'Algo deu errado.';

  @override
  String get notChecked => 'Ainda não checado.';

  @override
  String updateTo(String version) {
    return 'Atualizar para $version';
  }

  @override
  String get checkNow => 'Checar agora';

  @override
  String get chooseVersionDesc =>
      'Instale qualquer versão publicada, inclusive antigas, sabendo se funciona com as bibliotecas koebelt/link dos seus dispositivos.';

  @override
  String get versions => 'Versões';

  @override
  String get betas => 'Betas';

  @override
  String get betasDesc => 'Oferecer também versões beta e candidatas: os próximos recursos antes do lançamento, com mais chance de bug.';

  @override
  String get autoCheck => 'Procurar atualizações automaticamente';

  @override
  String get autoCheckDesc => 'Ao abrir e uma vez por dia, o koebelt dash pergunta ao GitHub pela versão mais recente. Nada mais é enviado.';

  @override
  String get padYawSteer => 'Guinada · direção';

  @override
  String get padRoll => 'Rolagem';

  @override
  String get padPitchDrive => 'Arfagem · avanço';

  @override
  String get padUnavailable => 'Os controles de jogo não estão disponíveis nesta plataforma.';

  @override
  String get padNone =>
      'Nenhum controle conectado. Pareie um controle Bluetooth nas configurações do sistema, ou ligue um por USB. Rádios RC funcionam no modo joystick USB.';

  @override
  String padConnected(String names) {
    return 'Conectado: $names.';
  }

  @override
  String get padUse => 'Usar um controle de jogo';

  @override
  String get padUseDesc =>
      'Os sticks pilotam drones e robôs terrestres, e movem os braços robóticos, depois de armados; os botões funcionam em qualquer dispositivo. Os controles na tela continuam funcionando enquanto o controle está parado.';

  @override
  String get padSticks => 'Sticks';

  @override
  String get padMoveNow => 'Mova ou aperte o controle agora';

  @override
  String get padButtons => 'Botões';

  @override
  String get padDeadzone => 'Zona morta';

  @override
  String padDeadzoneDesc(int pct) {
    return 'Movimento dos sticks ignorado em volta do centro: $pct %.';
  }

  @override
  String get padExpo => 'Expo';

  @override
  String padExpoDesc(int pct) {
    return 'Resposta mais suave perto do centro para o controle fino: $pct %.';
  }

  @override
  String get padResetMapping => 'Redefinir mapeamento';

  @override
  String get padResetMappingDesc => 'Disposição padrão: stick esquerdo acelerador e guinada, stick direito arfagem e rolagem, B / Círculo para STOP.';

  @override
  String get waiting => 'Aguardando…';

  @override
  String get invertDirection => 'Inverter direção';

  @override
  String get inverted => 'Invertido';

  @override
  String get normal => 'Normal';

  @override
  String clearName(String name) {
    return 'Limpar $name';
  }

  @override
  String padDrives(String pad, String device) {
    return '$pad pilota $device';
  }

  @override
  String padArmToDrive(String pad) {
    return 'Arme para pilotar com $pad; os botões dele já funcionam';
  }

  @override
  String get padButtonsWork => 'Os botões funcionam; os sticks pilotam drones e robôs terrestres';

  @override
  String get pad => 'Controle';

  @override
  String get copy => 'Copiar';

  @override
  String get aiLet => 'Deixar os assistentes usarem o koebelt dash';

  @override
  String get aiLetDesc =>
      'Claude, Codex, OpenCode, Cursor e outros clientes MCP podem ler a documentação, escrever scripts, usar o app e, com sua aprovação, agir nos dispositivos. O dash em si não envia nada a nenhum serviço de IA; o assistente que você conecta fala com o próprio provedor.';

  @override
  String get aiConnectClient => 'Conectar um cliente';

  @override
  String get aiPaste => 'Cole isto na configuração do assistente.';

  @override
  String get aiRemotePhone => 'Os assistentes rodam num computador: eles chegam a este celular pela rede, com o token dele.';

  @override
  String get aiRemoteTablet => 'Os assistentes rodam num computador: eles chegam a este tablet pela rede, com o token dele.';

  @override
  String get other => 'Outro';

  @override
  String get aiConnectedNow => 'Conectado agora';

  @override
  String get aiNone => 'Nenhum assistente nos últimos dez minutos.';

  @override
  String actions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ações', one: '1 ação');
    return '$_temp0';
  }

  @override
  String get activity => 'Atividade';

  @override
  String get aiAllowed => 'Permitido sem perguntar';

  @override
  String get aiAllowedNone =>
      'Dispositivos simulados e replays nunca perguntam. Em hardware real, cada ação pergunta, a menos que você a permita para a sessão. Armar e decolar sempre perguntam.';

  @override
  String aiAllowedSome(String actions) {
    return 'Para esta sessão: $actions. Armar e decolar sempre perguntam.';
  }

  @override
  String get aiFromNetwork => 'Desta rede';

  @override
  String aiFromNetworkOn(String url, String token) {
    return 'Assistentes em outros computadores: $url com o token $token… (copie-o na aba Outro).';
  }

  @override
  String get aiFromNetworkOff => 'Deixe um assistente em outro computador usar este dash, com um token.';

  @override
  String get aiActivity => 'Atividade dos assistentes';

  @override
  String get nothingYet => 'Nada ainda.';

  @override
  String get aiShort => 'IA';

  @override
  String aiAsks(String client) {
    return '$client pede';
  }

  @override
  String aiRealHardware(String device) {
    return '$device é hardware real.';
  }

  @override
  String aiAllowSession(String device) {
    return 'Permitir este tipo de ação em $device durante esta sessão';
  }

  @override
  String get refuse => 'Recusar';

  @override
  String get approve => 'Aprovar';

  @override
  String get recordingsAndLogs => 'Gravações e logs de voo';

  @override
  String fileUnreadable(String error) {
    return 'O arquivo não pôde ser lido: $error';
  }

  @override
  String get fromFile => 'De um arquivo';

  @override
  String get fromFileDesc => 'Abre como uma sessão: replay, mapa, gráficos e exportação funcionam nele.';

  @override
  String get fmtJson => 'Uma gravação exportada do koebelt/dash';

  @override
  String get fmtBin => 'Log do ArduPilot, do cartão SD ou do Mission Planner';

  @override
  String get fmtTlog => 'Log de estação de solo: Mission Planner, QGroundControl, MAVProxy';

  @override
  String get fmtUlg => 'Log do PX4, do cartão SD ou do QGroundControl';

  @override
  String reading(String file) {
    return 'Lendo $file…';
  }

  @override
  String get stopRecordingFirst => 'Pare a gravação antes';

  @override
  String get notImported => 'Não importado';

  @override
  String get sampleRecordings => 'Gravações de exemplo';

  @override
  String get samplesIn => 'As três sessões de demonstração estão na sua lista, marcadas como Demo.';

  @override
  String get samplesDesc =>
      'Três sessões de demonstração gravadas com os dispositivos simulados: um voo de levantamento, um pick and place, um lançamento de foguete.';

  @override
  String get removeSamples => 'Remover exemplos';

  @override
  String get loadSamples => 'Carregar exemplos';

  @override
  String get exporting => 'Exportando…';

  @override
  String exportFormat(String format) {
    return 'Exportar $format';
  }

  @override
  String frames(int count) {
    return '$count quadros';
  }

  @override
  String csvColumns(int count) {
    return '$count colunas · só os canais que este dispositivo enviou';
  }

  @override
  String get noGpx => 'Sem GPS nesta gravação, então sem trilha GPX';

  @override
  String encoding(String format, int pct) {
    return 'Codificando $format · $pct%';
  }

  @override
  String get exported => 'Exportado';

  @override
  String get exportFailed => 'Falha na exportação';

  @override
  String get decrease => 'Diminuir';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count parâmetros', one: '1 parâmetro');
    return '$_temp0';
  }

  @override
  String get parameters => 'Parâmetros';

  @override
  String unsaved(int count) {
    return '$count não salvos';
  }

  @override
  String written(String when) {
    return 'Escrito $when';
  }

  @override
  String get inSync => 'Sincronizado';

  @override
  String get revert => 'Reverter';

  @override
  String get writing => 'Escrevendo…';

  @override
  String get writeToDevice => 'Escrever no dispositivo';

  @override
  String get searchParameters => 'Buscar parâmetros';

  @override
  String get waitingParams => 'Aguardando a tabela de parâmetros…';

  @override
  String noParamsMatch(String query) {
    return 'Nenhum parâmetro corresponde a “$query”';
  }

  @override
  String revertName(String name) {
    return 'Reverter $name';
  }

  @override
  String get liveResponse => 'Resposta ao vivo';

  @override
  String get copied => 'Copiado';

  @override
  String get yourPairingCode => 'Seu código de pareamento · vale 10 min';

  @override
  String namePaired(String name) {
    return '$name pareado';
  }

  @override
  String get startListening => 'Começar a escutar';

  @override
  String get listeningWifiBle => 'Escutando por Wi-Fi e BLE · ligue o seu dispositivo';

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
  String get addToDevices => 'Adicionar aos dispositivos';

  @override
  String get connectNow => 'Conectar agora';

  @override
  String get inTheApp => 'No app';

  @override
  String get completeProgram => 'Programa completo';

  @override
  String get apiReference => 'Referência da API';

  @override
  String get exampleProjects => 'Projetos de exemplo';

  @override
  String get allGuides => 'Todos os guias';

  @override
  String stepOfUpper(int n, int total) {
    return 'Passo $n de $total';
  }

  @override
  String get flowDevice => 'Seu dispositivo';

  @override
  String get flowDeviceDesc => 'Sensores, motores e koebelt/link na placa ou no computador de bordo.';

  @override
  String get flowLinkDesc => 'Wi-Fi, BLE, serial USB ou rádio, com um link reserva se um cair.';

  @override
  String get flowDashDesc => 'Painéis, controle, ajuste e gravação, no celular, tablet ou computador.';

  @override
  String get library => 'biblioteca';

  @override
  String get connectHardware => 'Conecte o seu hardware';

  @override
  String get connectHardwareDesc =>
      'Seu dispositivo roda uma pequena biblioteca que envia os sensores para este app e recebe os comandos. Escolha a sua plataforma para começar.';

  @override
  String get guidesConnections => 'Conexões';

  @override
  String get guidesConnectionsDesc => 'Como cada link funciona, e o que fazer quando um dispositivo não aparece.';

  @override
  String get guidesDevices => 'Exemplos de dispositivos';

  @override
  String get guidesDevicesDesc => 'Um programa completo e comentado para cada tipo de dispositivo.';

  @override
  String get guidesFeatures => 'Vídeo, mapa e controles';

  @override
  String get guidesFeaturesDesc => 'Mostrar uma câmera, pôr o dispositivo num mapa, pilotar com um gamepad.';

  @override
  String get guidesMore => 'Indo além';

  @override
  String get guidesMoreDesc => 'Dados personalizados, ajuste, sequências e segurança.';

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
  String get noMapboxToken => 'Esta versão não tem token do Mapbox: insira o seu abaixo, ou escolha outra fonte.';

  @override
  String get waitingGps => 'Aguardando um fix de GPS';

  @override
  String get grid => 'Grade';

  @override
  String get waitingScript => 'Aguardando o script';

  @override
  String get scriptEnded => 'Script encerrado';

  @override
  String get noVideo => 'Esta gravação não tem vídeo.';

  @override
  String get noCamera => 'Sem câmera. Os dispositivos declaram câmeras com video() na biblioteca.';

  @override
  String cameraByIp(String name) {
    return 'Esta câmera é acessada por endereço IP. Conecte-se ao $name por Wi-Fi para vê-la.';
  }

  @override
  String get warning => 'Aviso';

  @override
  String get alBattery => 'Bateria fraca';

  @override
  String get alBatteryDesc => 'Carga restante, como o dispositivo informa.';

  @override
  String get alBatteryAct => 'Hora de trazê-lo de volta.';

  @override
  String get alBatteryCritical => 'Bateria crítica';

  @override
  String get alBatteryCriticalDesc => 'Um segundo limite, mais insistente: repete até você confirmar.';

  @override
  String get alBatteryCriticalAct => 'Pouse ou pare agora.';

  @override
  String get alVoltage => 'Tensão da bateria';

  @override
  String get alVoltageDesc => 'Para baterias que não informam porcentagem. Defina o limite para a sua bateria, por exemplo 3,5 V por célula.';

  @override
  String get alVoltageAct => 'Hora de trazê-lo de volta.';

  @override
  String get alObstacle => 'Obstáculo perto';

  @override
  String get alObstacleDesc => 'O mais próximo que um sensor de proximidade vê, enquanto armado (sensores voltados para baixo não contam).';

  @override
  String get alObstacleAct => 'Desvie, ou pare.';

  @override
  String get alRssi => 'Sinal fraco';

  @override
  String get alRssiDesc => 'Força do sinal recebido, quando o link informa.';

  @override
  String get alRssiAct => 'Chegue mais perto ou volte.';

  @override
  String get alLatency => 'Latência alta';

  @override
  String get alLatencyDesc => 'Ida e volta do link. O controle parece atrasado acima de algumas centenas de milissegundos.';

  @override
  String get alLatencyAct => 'O controle vai parecer atrasado.';

  @override
  String get alAltitude => 'Teto de altitude';

  @override
  String get alAltitudeDesc => 'Altura acima do início. 120 m é o limite comum para drones na Europa e nos EUA.';

  @override
  String get alAltitudeAct => 'Desça.';

  @override
  String get alDistance => 'Distância do início';

  @override
  String get alDistanceDesc => 'Uma geofence simples: distância horizontal de onde ele partiu.';

  @override
  String get alDistanceAct => 'Traga-o mais perto.';

  @override
  String get alTemp => 'Temperatura';

  @override
  String get alTempDesc => 'Temperatura do motor, do ESC ou da placa, quando o dispositivo informa uma.';

  @override
  String get alTempAct => 'Deixe esfriar.';

  @override
  String get kindDrone => 'Drone';

  @override
  String get kindPlane => 'Avião';

  @override
  String get kindRover => 'Robô terrestre';

  @override
  String get kindBoat => 'Barco';

  @override
  String get kindLegged => 'Robô com pernas';

  @override
  String get stWalkTo => 'Andar até';

  @override
  String sumWalkTo(String x, String y) {
    return 'Andar até $x, $y';
  }

  @override
  String get stepsLegged => 'andar até waypoints, esperar, mudar a velocidade';

  @override
  String get planNoteLegged => 'Os waypoints são metros a leste e ao norte do ponto de partida. O robô para e fica em pé em cada um antes do próximo passo.';

  @override
  String get legStand => 'Em pé';

  @override
  String get legSit => 'Sentado';

  @override
  String get gaitWalk => 'Passo';

  @override
  String get gaitTrot => 'Trote';

  @override
  String get stickTurnHeight => 'Girar · altura';

  @override
  String get stickWalk => 'Andar · lateral';

  @override
  String get stickTurn => 'Girar';

  @override
  String get legHeight => 'Altura';

  @override
  String get tiltWalk => 'Tilt · andar e deslizar';

  @override
  String get kindArm => 'Braço robótico';

  @override
  String get kindRocket => 'Foguete';

  @override
  String get kindBench => 'Bancada de teste';

  @override
  String get kindGeneric => 'Dispositivo';

  @override
  String get stTakeoff => 'Decolar';

  @override
  String get stFlyTo => 'Voar até';

  @override
  String get stLand => 'Pousar';

  @override
  String get stRth => 'Voltar para casa';

  @override
  String get stDriveTo => 'Dirigir até';

  @override
  String get stPose => 'Ir para uma pose';

  @override
  String get stRamp => 'Rampa';

  @override
  String get stWait => 'Esperar';

  @override
  String get stMode => 'Definir modo';

  @override
  String get stArm => 'Armar / desarmar';

  @override
  String get stCmd => 'Comando personalizado';

  @override
  String get fEast => 'Leste';

  @override
  String get fNorth => 'Norte';

  @override
  String get fHold => 'Manter';

  @override
  String get fFrom => 'De';

  @override
  String get fTo => 'Até';

  @override
  String get fOver => 'Em';

  @override
  String get fDuration => 'Duração';

  @override
  String get fMode => 'Modo';

  @override
  String get fState => 'Estado';

  @override
  String get fLimit => 'Limite';

  @override
  String get fCommand => 'Comando';

  @override
  String get fValue => 'Valor';

  @override
  String sumTakeoff(String alt) {
    return 'Decolar até $alt';
  }

  @override
  String sumFlyTo(String x, String y, String z) {
    return 'Voar até $x, $y a $z';
  }

  @override
  String sumDriveTo(String x, String y) {
    return 'Dirigir até $x, $y';
  }

  @override
  String get sumRth => 'Voltar para casa e pousar';

  @override
  String sumPose(String joints) {
    return 'Ir para a pose $joints°';
  }

  @override
  String sumGripper(String pct) {
    return 'Garra $pct% aberta';
  }

  @override
  String sumThrottle(String pct, String s) {
    return 'Acelerador $pct% por $s s';
  }

  @override
  String sumRamp(String from, String to, String s) {
    return 'Rampa de $from a $to% em $s s';
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
    return 'Limite de velocidade $pct%';
  }

  @override
  String sumCmd(String name, String value) {
    return 'Comando $name = $value';
  }

  @override
  String get stoppedEstop => 'Parada: parada de emergência';

  @override
  String completedIn(String seconds) {
    return 'Concluída em $seconds s';
  }

  @override
  String stepTimedOut(int n, String step) {
    return 'O passo $n estourou o tempo: $step';
  }

  @override
  String metresToGo(String length) {
    return 'faltam $length';
  }

  @override
  String get uploadingToDevice => 'Enviando ao dispositivo';

  @override
  String get starting => 'Iniciando';

  @override
  String get completedOnDevice => 'Concluída no dispositivo';

  @override
  String get deviceRejected => 'O dispositivo não aceitou a sequência';

  @override
  String get linkLostCarriesOn => 'Link perdido · o dispositivo continua';

  @override
  String get stoppedDisconnected => 'Parada: desconectado';

  @override
  String get stoppedTookControl => 'Parada: você assumiu o controle';

  @override
  String get stoppedManual => 'Parada: controle manual';

  @override
  String get stoppedByScript => 'Parada pelo script';

  @override
  String get reqAnyDevice => 'um dispositivo';

  @override
  String reqKinds(String kinds) {
    return '$kinds';
  }

  @override
  String reqWith(String kinds, String needs) {
    return '$kinds com $needs';
  }

  @override
  String reqWrongKind(String name, String kind, String needs) {
    return '$name: $kind, mas este script precisa de $needs.';
  }

  @override
  String reqLacks(String name, String lacks, String needs) {
    return '$name não tem $lacks; este script precisa de $needs.';
  }

  @override
  String get trgButton => 'Botão';

  @override
  String get trgSwitch => 'Chave';

  @override
  String get trgSlider => 'Slider';

  @override
  String get trgController => 'Controle';

  @override
  String get trgCondition => 'Condição';

  @override
  String get trgEvent => 'Evento do dispositivo';

  @override
  String get trgTimer => 'Timer';

  @override
  String get evMode => 'Mudança de modo';

  @override
  String get evFailsafe => 'Failsafe';

  @override
  String get evSeqDone => 'Sequência terminada';

  @override
  String get evLog => 'Mensagem do dispositivo';

  @override
  String get onControl => 'em Controle';

  @override
  String everyN(String seconds) {
    return 'A cada $seconds s';
  }

  @override
  String onceAfterN(String seconds) {
    return 'Uma vez após $seconds s';
  }

  @override
  String get paArm => 'Armar / desarmar';

  @override
  String get paManual => 'Manual';

  @override
  String get paHold => 'Manter';

  @override
  String get paAuto => 'Devolver ao script';

  @override
  String get paSlower => 'Mais devagar';

  @override
  String get paFaster => 'Mais rápido';

  @override
  String get paFrame => 'Junta / cartesiano';

  @override
  String get paWrist => 'Punho';

  @override
  String get paNext => 'Próximo dispositivo';

  @override
  String get paStopHint => 'Parada de emergência, na hora';

  @override
  String get paHoldHint => 'Segure por um segundo';

  @override
  String paSwitchTo(String mode) {
    return 'Mudar para $mode';
  }

  @override
  String get paAutoHint => 'Depois de assumir, devolver os sticks ao script (AUTO)';

  @override
  String paSwitchToDrones(String mode) {
    return 'Mudar para $mode (drones)';
  }

  @override
  String get paHoldDronesHint => 'Segure por um segundo (drones)';

  @override
  String get paRecordHint => 'Iniciar ou parar uma gravação';

  @override
  String get paSlowerHint => 'Baixar o limite de velocidade em 10 %';

  @override
  String get paFasterHint => 'Subir o limite de velocidade em 10 %';

  @override
  String get paFrameHint => 'Braços: o que os sticks movem';

  @override
  String get paWristHint => 'Braços: o stick direito move J5 e J6 em vez de J3 e J4';

  @override
  String get paGripperHint => 'Braços: abrir ou fechar';

  @override
  String get paNextHint => 'Vários conectados: mostrar e pilotar o próximo';

  @override
  String get notSet => 'Não definido';

  @override
  String get padLeftStickX => 'Stick esquerdo X';

  @override
  String get padLeftStickY => 'Stick esquerdo Y';

  @override
  String get padRightStickX => 'Stick direito X';

  @override
  String get padRightStickY => 'Stick direito Y';

  @override
  String get padLeftTrigger => 'Gatilho esquerdo';

  @override
  String get padRightTrigger => 'Gatilho direito';

  @override
  String get padACross => 'A / Xis';

  @override
  String get padBCircle => 'B / Círculo';

  @override
  String get padXSquare => 'X / Quadrado';

  @override
  String get padYTriangle => 'Y / Triângulo';

  @override
  String get padLeftBumper => 'Bumper esquerdo';

  @override
  String get padRightBumper => 'Bumper direito';

  @override
  String get padBackShare => 'Back / Share';

  @override
  String get padStartOptions => 'Start / Options';

  @override
  String get padHome => 'Home';

  @override
  String get padLeftStickPress => 'Clique do stick esquerdo';

  @override
  String get padRightStickPress => 'Clique do stick direito';

  @override
  String get padDPadUp => 'D-pad cima';

  @override
  String get padDPadDown => 'D-pad baixo';

  @override
  String get padDPadLeft => 'D-pad esquerda';

  @override
  String get padDPadRight => 'D-pad direita';

  @override
  String get radioSik => 'Rádio de telemetria SiK';

  @override
  String get radioLoraName => 'Estação de solo LoRa';

  @override
  String get radioOther => 'Outro rádio serial';

  @override
  String get radioSikDesc => 'Pares de 433 / 868 / 915 MHz: 3DR, Holybro, RFD900. Serial transparente até cerca de 1 km, 40 km com o RFD900.';

  @override
  String get radioLoraDesc => 'Uma placa com rádio LoRa por USB, gravada com o sketch de estação de solo. 2 a 10 km, só telemetria.';

  @override
  String get radioHc12Desc => 'Módulo serial transparente barato num adaptador USB. Cerca de 1 km a 9600 baud.';

  @override
  String get radioXbeeDesc => 'Digi XBee em modo transparente numa placa USB. 2,4 GHz ou 900 MHz.';

  @override
  String get radioOtherDesc => 'Qualquer rádio serial transparente. Ajuste o baud dele; o app usa taxas conservadoras.';

  @override
  String get tplLoop => 'Um loop de controle';

  @override
  String get tplButton => 'Uma ação por botão';

  @override
  String get fldBattery => 'Bateria';

  @override
  String get fldBatteryVoltage => 'Tensão da bateria';

  @override
  String get fldDistanceFromHome => 'Distância do início';

  @override
  String get fldHeightAboveHome => 'Altura acima do início';

  @override
  String get fldSpeed => 'Velocidade';

  @override
  String get fldHeading => 'Rumo';

  @override
  String get fldRoll => 'Rolagem';

  @override
  String get fldPitch => 'Arfagem';

  @override
  String get fldGripper => 'Garra';

  @override
  String get fldThrust => 'Empuxo';

  @override
  String get fldRpm => 'RPM';

  @override
  String get fldTemperature => 'Temperatura';

  @override
  String get fldNearestObstacle => 'Obstáculo mais próximo';

  @override
  String get fldSignal => 'Sinal';

  @override
  String get fldLatency => 'Latência';

  @override
  String get fldGpsSatellites => 'Satélites GPS';

  @override
  String get ready => 'Pronto.';

  @override
  String get pythonManaged => 'Este Python é gerenciado pelo sistema e recusa pacotes: use um ambiente de scripts.';

  @override
  String failedWhy(String why) {
    return 'Falhou: $why';
  }

  @override
  String get pipNoPackage => 'O pip terminou, mas o koebelt-dash-scripts ainda não está neste Python.';

  @override
  String packageUpToDate(String version) {
    return 'O koebelt-dash-scripts $version está atualizado neste Python.';
  }

  @override
  String packageInstalled(String version) {
    return 'O koebelt-dash-scripts $version está instalado neste Python.';
  }

  @override
  String packagesInstalled(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names estão instalados neste Python.',
      one: '$names está instalado neste Python.',
    );
    return '$_temp0';
  }

  @override
  String envReady(String version) {
    return 'O ambiente de scripts está pronto, com o koebelt-dash-scripts $version.';
  }

  @override
  String atMostDevices(int count) {
    return 'No máximo $count dispositivos ao mesmo tempo. Desconecte um antes.';
  }

  @override
  String noAnswerFrom(String name) {
    return 'Sem resposta de $name';
  }

  @override
  String noHostAt(String address) {
    return 'Nenhum host de scripts em $address. O `koebelt-dash-scripts host` está rodando lá?';
  }

  @override
  String get hostRefused => 'O host recusou.';

  @override
  String get logUnknown =>
      'Este arquivo não é um log que o app consiga ler. Ele abre exportações JSON do koebelt/dash, logs .bin e .tlog do ArduPilot, e logs .ulg do PX4.';

  @override
  String logEmpty(String format) {
    return 'O arquivo $format não tem telemetria que o app consiga mostrar (atitude, posição, bateria).';
  }

  @override
  String get logJsonUnreadable => 'Este arquivo JSON não pôde ser lido.';

  @override
  String get logJsonNotExport => 'Este arquivo JSON não é uma exportação de gravação do koebelt/dash.';

  @override
  String get logNoHeartbeat => 'Este .tlog não tem heartbeat de veículo, então as mensagens dele não podem ser atribuídas a nenhum veículo.';

  @override
  String get viewDevices => 'Ver dispositivos';

  @override
  String get simulatedTip => 'Simulado no app, não é hardware real';

  @override
  String get newShort => 'Novo';
}
