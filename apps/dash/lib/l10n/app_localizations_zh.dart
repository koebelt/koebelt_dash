// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navLive => '实时';

  @override
  String get navControl => '操控';

  @override
  String get navAutomate => '自动化';

  @override
  String get navTune => '参数';

  @override
  String get navReplay => '回放';

  @override
  String get navDevices => '设备';

  @override
  String get navGuides => '指南';

  @override
  String get navSettings => '设置';

  @override
  String get navSequences => '序列';

  @override
  String get navScripts => '脚本';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageDesc => '应用的语言。';

  @override
  String get translationNote => '此翻译由 AI 生成，可能存在错误。欢迎在 GitHub 仓库中提交修正。';

  @override
  String get translationContribute => '在 GitHub 上贡献';

  @override
  String get secLanguageUnits => '语言和单位';

  @override
  String get settingsUnits => '单位';

  @override
  String get settingsUnitsDesc => '长度、速度和温度。设备、序列和脚本仍使用米；只改变显示方式。';

  @override
  String settingsUnitsSystem(String name) {
    return '跟随地区（$name）';
  }

  @override
  String get unitsMetric => '公制（m、m/s、°C）';

  @override
  String get unitsImperial => '英制（ft、mph、°F）';

  @override
  String get unitsMetricShort => '公制';

  @override
  String get unitsImperialShort => '英制';

  @override
  String settingsLanguageSystem(String name) {
    return '跟随系统（$name）';
  }

  @override
  String toastSaved(String name) {
    return '已保存为 $name';
  }

  @override
  String get stopEngagedBar => '已急停 · 点按以重置';

  @override
  String get stopEngagedTitle => '紧急停止已触发';

  @override
  String get stopKeep => '保持停止';

  @override
  String get stopResetAll => '全部重置';

  @override
  String get stopReset => '重置停止';

  @override
  String stopBody(String names) {
    return '$names 的电机已停止，所有运动指令均被阻止。';
  }

  @override
  String get theDevice => '设备';

  @override
  String get stopCheck => '重置前请检查设备。重置后设备保持上锁，直到你再次解锁。';

  @override
  String get fleet => '机队';

  @override
  String get tagSim => '模拟';

  @override
  String get fleetActive => '活动';

  @override
  String get fleetLost => '丢失';

  @override
  String get fleetLinked => '已连接';

  @override
  String get fleetOff => '关';

  @override
  String get fleetOn => '开';

  @override
  String get connecting => '正在连接';

  @override
  String get noLink => '无链路';

  @override
  String get simulated => '模拟';

  @override
  String get statLink => '链路';

  @override
  String get statLost => '丢失';

  @override
  String get statLatency => '延迟';

  @override
  String get statBattery => '电池';

  @override
  String get statRecording => '录制中';

  @override
  String get armed => '已解锁';

  @override
  String get disarmed => '已上锁';

  @override
  String stopLabelAll(int count) {
    return '紧急停止，全部 $count 台设备';
  }

  @override
  String get stopLabel => '紧急停止';

  @override
  String stopTipAll(int count) {
    return '停止所有 $count 台已连接的设备';
  }

  @override
  String get stopTipSlowRadio => 'STOP 仍会通过这个仅遥测的电台发送，但较慢：最多需要一秒';

  @override
  String get stopAll => '全部停止';

  @override
  String get stop => '停止';

  @override
  String get failsafeHold => '保持位置';

  @override
  String get failsafeRth => '正在返航';

  @override
  String get failsafeLand => '原地降落';

  @override
  String linkLostFor(String seconds) {
    return '链路丢失 · $seconds 秒';
  }

  @override
  String failsafeActive(String action) {
    return '失控保护已启动：$action。';
  }

  @override
  String get reconnecting => '正在重新连接。失控保护将在 1.8 秒后启动。';

  @override
  String get controlsLocked => '链路恢复前操控已锁定。';

  @override
  String get linkRestored => '链路已恢复';

  @override
  String get linkRestoredBody => '手动操控已恢复可用。';

  @override
  String alertBelow(String limit) {
    return '低于 $limit。';
  }

  @override
  String alertAbove(String limit) {
    return '高于 $limit。';
  }

  @override
  String get linkLostOther => '1.8 秒后由其失控保护接管。';

  @override
  String get compatNewerApp => '需要更新的应用';

  @override
  String get compatOldLib => '库版本过旧';

  @override
  String compatSome(String why) {
    return '部分功能可能无法使用：$why。';
  }

  @override
  String get compatUpdateApp => '请更新 koebelt dash。';

  @override
  String get compatUpdateLib => '请更新设备上的 koebelt/link 库，或在 设置 > 更新 中安装旧版 koebelt dash。';

  @override
  String get show => '显示';

  @override
  String alerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 条警报', one: '1 条警报');
    return '$_temp0';
  }

  @override
  String get linkLost => '链路丢失';

  @override
  String get replayOffControl => '回放期间操控不可用';

  @override
  String get replayOffControlWhy => '操控作用于已连接的设备，而不是录制。';

  @override
  String get replayOffSequences => '回放期间序列不可用';

  @override
  String get replayOffSequencesWhy => '序列在已连接的设备上运行，而不是在录制上。';

  @override
  String get replayOffTune => '回放期间参数调整不可用';

  @override
  String get replayOffTuneWhy => '参数在已连接的设备上读写，而不是在录制上。';

  @override
  String replayExitTo(String name) {
    return '退出回放以返回 $name。';
  }

  @override
  String get replayExitConnect => '退出回放，然后连接设备。';

  @override
  String get replayBack => '返回回放';

  @override
  String replayExitBackTo(String name) {
    return '退出回放，返回 $name';
  }

  @override
  String get replayExit => '退出回放';

  @override
  String get notConnected => '未连接';

  @override
  String get noDeviceTitle => '没有连接设备';

  @override
  String get noDeviceBody => '选择已配对的设备，或配对新设备。链路建立后会显示遥测和操控。';

  @override
  String get connectFailed => '无法连接';

  @override
  String get noPairedDevices => '还没有已配对的设备。';

  @override
  String get offline => '离线';

  @override
  String batteryPct(int pct) {
    return '电池 $pct%';
  }

  @override
  String get connect => '连接';

  @override
  String get pairNewDevice => '配对新设备';

  @override
  String get or => '或';

  @override
  String get addSimulated => '添加模拟设备';

  @override
  String get addSimulatedDesc => '虚拟的无人机、地面机器人、机械臂、火箭或测试台，无需硬件即可试用应用。';

  @override
  String get openRecording => '打开录制';

  @override
  String get openRecordingDesc => '回放会话、飞行日志或示例录制。';

  @override
  String get setUpLibrary => '设置库';

  @override
  String get setUpLibraryDesc => '将 koebelt/link 添加到你的 Arduino、Python、ROS 2 或 Rust 项目中。';

  @override
  String get noDevice => '无设备';

  @override
  String get tagDemo => '演示';

  @override
  String moreConnected(int count) {
    return '另有 $count 台已连接';
  }

  @override
  String get alsoConnected => '同时连接';

  @override
  String get disconnectAll => '全部断开';

  @override
  String get connectAnother => '再连接一台';

  @override
  String get pairedDevices => '已配对的设备';

  @override
  String get noPairedDevicesShort => '没有已配对的设备';

  @override
  String get noPairedDevicesHint => '配对一台、添加模拟设备，或按照快速入门操作。';

  @override
  String get pairDevice => '配对设备';

  @override
  String get quickstart => '快速入门';

  @override
  String get manage => '管理';

  @override
  String get replaying => '正在回放';

  @override
  String get closeReplay => '关闭回放';

  @override
  String get simulator => '模拟器';

  @override
  String get disconnect => '断开';

  @override
  String get open => '打开';

  @override
  String get sequenceRunning => '序列运行中';

  @override
  String disconnectName(String name) {
    return '断开 $name';
  }

  @override
  String get automateSeqBlurb => '按顺序排列的步骤，无需代码：起飞、飞往、等待、降落；行驶至；移动到姿态。';

  @override
  String get automateSeqPoint1 => '无需代码：在应用中构建';

  @override
  String get automateSeqPoint2 => '设备能存储时在设备上运行';

  @override
  String get automateSeqPoint3 => '链路中断也能继续';

  @override
  String get automateSeqConnect => '连接设备以构建它的序列';

  @override
  String automateSeqCount(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个序列', zero: '没有序列');
    return '$name：$_temp0';
  }

  @override
  String get automateScriptBlurb => '读取遥测和摄像头、做出判断并操控设备的 Python。';

  @override
  String get automateScriptPoint1 => '逻辑、传感器、摄像头';

  @override
  String get automateScriptPoint2 => '任意包：OpenCV、PyTorch、YOLO';

  @override
  String get automateScriptPoint3 => '触发器：按钮、按键、条件、定时器';

  @override
  String get automateScriptPoint3Host => '在脚本主机上运行：你网络中的一台电脑';

  @override
  String scriptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个脚本', one: '1 个脚本', zero: '没有脚本');
    return '$_temp0';
  }

  @override
  String get automateEyebrow => '两种自动化方式';

  @override
  String runningOn(String what, String device) {
    return '$device 上的$what';
  }

  @override
  String get automateTogether1 => '组合使用：脚本可以启动序列 ';

  @override
  String get automateTogether2 => '，并决定何时启动。';

  @override
  String get sequenceOrScript => '序列还是脚本？';

  @override
  String get running => '运行中';

  @override
  String get layoutHud => 'HUD';

  @override
  String get layoutWall => 'WALL';

  @override
  String get editLayout => '编辑布局';

  @override
  String get sceneLayers3d => '3D 场景图层';

  @override
  String get layerCloud => '点云';

  @override
  String get layerTrail => '轨迹';

  @override
  String get layerRadar => '雷达目标';

  @override
  String get layerGrid => '地面网格';

  @override
  String get sceneLayers => '场景图层';

  @override
  String get addWidget => '添加小部件';

  @override
  String widgetsSavedFor(String device, String screens) {
    return '小部件按 $device 在$screens屏幕上分别保存。';
  }

  @override
  String get thisDevice => '此设备';

  @override
  String get screenPhone => '手机';

  @override
  String get screenShort => '横屏手机';

  @override
  String get screenPortrait => '竖屏平板';

  @override
  String get screenTablet => '平板';

  @override
  String get screenDesktop => '桌面';

  @override
  String get reset => '重置';

  @override
  String get cancel => '取消';

  @override
  String get saveLayout => '保存布局';

  @override
  String get back => '返回';

  @override
  String get paused => '已暂停';

  @override
  String get stale => '过时';

  @override
  String hzLive(int hz) {
    return '实时 $hz Hz';
  }

  @override
  String get resume => '继续';

  @override
  String get pause => '暂停';

  @override
  String get statMin => '最小';

  @override
  String get statMax => '最大';

  @override
  String get statMean => '平均';

  @override
  String get unit => '单位';

  @override
  String get window => '窗口';

  @override
  String get windowValue => '10 秒 · 300 个样本';

  @override
  String get source => '来源';

  @override
  String get tapChannelToHide => '点按通道以隐藏';

  @override
  String get rec => '录制';

  @override
  String get speedLimit => '速度限制';

  @override
  String get setHomePose => '设置初始姿态';

  @override
  String get setHomeHere => '将此处设为返航点';

  @override
  String get useThisPose => '使用此姿态';

  @override
  String get setHome => '设置返航点';

  @override
  String get setHomePoseBody => '当前的关节角度将成为“初始姿态”和序列中“初始姿态”步骤要移动到的姿态。';

  @override
  String setHomeBody(String length) {
    return '当前位置成为返航点 (0, 0)。返航会飞回这里，序列航点也以此为基准测量。设备距当前返航点 $length。';
  }

  @override
  String get autoDashDrives => '由 dash 操控';

  @override
  String get autoTakeBack => '选择 MANUAL 或 HOLD，或拨动摇杆，即可收回操控。';

  @override
  String get autoTip => 'dash 的模式：序列或脚本操控设备时使用。在“自动化”中运行。';

  @override
  String get tiltDrag => '倾斜 · 拖动以模拟';

  @override
  String get stickThrottle => '油门';

  @override
  String get stickDrive => '行驶';

  @override
  String get stickYaw => '偏航';

  @override
  String get stickPitchRoll => '俯仰 · 横滚';

  @override
  String get stickSteer => '转向';

  @override
  String get stickThrottleYaw => '油门 · 偏航';

  @override
  String get tiltPitchRoll => '倾斜 · 俯仰和横滚';

  @override
  String get tiltSteerDrive => '倾斜 · 转向和行驶';

  @override
  String get axUp => '上';

  @override
  String get axDn => '下';

  @override
  String get axFwd => '前';

  @override
  String get axRev => '后';

  @override
  String get axBack => '后';

  @override
  String get axL => '左';

  @override
  String get axR => '右';

  @override
  String get axYaw => '偏航';

  @override
  String get rdAlt => '高度';

  @override
  String get rdOdom => '里程';

  @override
  String get rdSpeed => '速度';

  @override
  String get rdHdg => '航向';

  @override
  String get rdHome => '返航点';

  @override
  String get rdVz => 'Vz';

  @override
  String get rdMax => '最大';

  @override
  String get rdRange => '距离';

  @override
  String get rdToolX => '工具 X';

  @override
  String get rdToolY => '工具 Y';

  @override
  String get rdToolZ => '工具 Z';

  @override
  String get rdThrust => '推力';

  @override
  String get rdRpm => 'RPM';

  @override
  String get rdCurrent => '电流';

  @override
  String get rdPower => '功率';

  @override
  String get rdTemp => '温度';

  @override
  String get rdEfficiency => '效率';

  @override
  String get homePose => '初始姿态';

  @override
  String get setAsHome => '设为初始';

  @override
  String get armJoint => '关节';

  @override
  String get armCartesian => '笛卡尔';

  @override
  String get toolFrame => '工具坐标系 · 相对基座';

  @override
  String armPadHelp(String frame, String wristBtn, String wrist, String gripper) {
    return '手柄 · $frame：关节 / 笛卡尔 · $wristBtn：$wrist · $gripper：夹爪';
  }

  @override
  String get armWrist => '手腕';

  @override
  String get gripper => '夹爪';

  @override
  String gripperOpenPct(int pct) {
    return '张开 $pct%';
  }

  @override
  String get gripperOpen => '张开';

  @override
  String get gripperClose => '闭合';

  @override
  String get flightPhase => '飞行阶段';

  @override
  String get phasePad => '发射台上';

  @override
  String get phaseCount => '倒计时';

  @override
  String get phaseBoost => '助推';

  @override
  String get phaseCoast => '滑行';

  @override
  String get phaseDrogue => '减速伞';

  @override
  String get phaseMain => '主伞';

  @override
  String get phaseLanded => '已着陆';

  @override
  String get preflight => '飞行前检查';

  @override
  String get checkPyro => '点火通路 · 减速伞、主伞';

  @override
  String get ok => '正常';

  @override
  String get check => '检查';

  @override
  String get checkGps => 'GPS 定位';

  @override
  String sats(int count) {
    return '$count 颗卫星';
  }

  @override
  String get noFix => '未定位';

  @override
  String get checkFlightComputer => '飞行计算机';

  @override
  String get safe => '安全';

  @override
  String get armFlightComputer => '解锁飞行计算机';

  @override
  String get armPadClear => '仅在发射台周围无人时解锁';

  @override
  String startCountdown(String seconds) {
    return '开始倒计时 · $seconds 秒';
  }

  @override
  String get abortLaunch => '中止发射';

  @override
  String get deployDrogue => '展开减速伞';

  @override
  String get deployMain => '展开主伞';

  @override
  String autoDeploy(String length) {
    return '自动展开 · 远地点展开减速伞 · $length 展开主伞';
  }

  @override
  String landedBody(String apogee, String distance) {
    return '远地点 $apogee · 着陆点距发射台 $distance。';
  }

  @override
  String get resetToPad => '重置到发射台';

  @override
  String get altitude => '高度';

  @override
  String get cutoff => '切断';

  @override
  String get cutoffLimit => '限制';

  @override
  String get cutoffBody => '油门已设为 0。再次运行前请检查电机。';

  @override
  String get clear => '清除';

  @override
  String get benchDisarmed => '解锁测试台以转动电机。远离螺旋桨。';

  @override
  String get testSequence => '测试序列';

  @override
  String get benchRamp => 'RAMP';

  @override
  String get benchSteps => 'STEPS';

  @override
  String get runAndRecord => '运行并录制';

  @override
  String benchRampDesc(String seconds) {
    return '$seconds 秒内从 0 爬升到 100 %，保持 2 秒，停止。';
  }

  @override
  String benchStepsDesc(String size, String seconds) {
    return '每级 $size %，每级 $seconds 秒，直到 100 %。';
  }

  @override
  String benchLimits(String amps, String temperature) {
    return '限制：$amps A，$temperature。';
  }

  @override
  String get mspTitle => '监控与调参';

  @override
  String mspBody(String name, String firmware) {
    return '$name 运行 $firmware，通过配置链路 MSP 连接。应用显示其遥测，在“参数”页面调整 PID 增益，STOP 会将其上锁。请用你的遥控器飞行。';
  }

  @override
  String get radioOnlyTitle => '仅遥测链路';

  @override
  String radioOnlyBody(String name, String radio) {
    return '$name 通过 $radio 连接，该链路只传输遥测。摇杆、模式和指令无法通过它到达设备；STOP 可以，约一秒内送达。请通过主链路（Wi-Fi、蓝牙或 SiK 电台）操控它，主链路超出范围时依靠其失控保护。';
  }

  @override
  String get aRadio => '电台';

  @override
  String get tileReadouts => '读数';

  @override
  String get tileSrcFused => '融合状态';

  @override
  String get tileAttitude => '姿态';

  @override
  String get tileAccelerometer => '加速度计';

  @override
  String get tileGyroscope => '陀螺仪';

  @override
  String get tileSrcBaroRange => '气压计 + 测距仪';

  @override
  String get tileRadar => '雷达';

  @override
  String get tileSrcRadar => '雷达 / 安全扫描仪';

  @override
  String get tileLidar => '激光雷达';

  @override
  String get tileSrcLidar => '扫描式激光雷达';

  @override
  String get tileJoints => '关节';

  @override
  String get tileSrcJoints => '关节编码器';

  @override
  String get tileForceTorque => '力 / 力矩';

  @override
  String get tileSrcWrist => '腕部力 / 力矩传感器';

  @override
  String get tileSrcPower => '电源模块';

  @override
  String get tileSrcRadio => '电台链路';

  @override
  String get tileCamera => '摄像头';

  @override
  String get tileSrcCamera => '设备摄像头 · MJPEG';

  @override
  String get tileSrcFleet => '所有已连接的设备';

  @override
  String get tileSrcPhase => '飞行计算机状态机';

  @override
  String get tileVerticalSpeed => '垂直速度';

  @override
  String get tileSrcBaroImu => '气压计 + IMU 融合';

  @override
  String get tilePyro => '点火通道';

  @override
  String get tileSrcPyro => '4 通道点火板';

  @override
  String get tileSrcTacho => '光学转速计';

  @override
  String get tileTorque => '扭矩';

  @override
  String get tileSrcTorque => '反扭矩传感器';

  @override
  String get tileMotorTemp => '电机温度';

  @override
  String get tileSrcNtc => 'NTC 热敏电阻';

  @override
  String get tileRollRate => '横滚角速度';

  @override
  String get tilePitchRate => '俯仰角速度';

  @override
  String get tileYawRate => '偏航角速度';

  @override
  String get tileGroundSpeed => '地速';

  @override
  String get tileAgl => '离地高度';

  @override
  String get tileOwnSpeed => '自身速度';

  @override
  String get tileVoltage => '电压';

  @override
  String get tilePyroBus => '点火总线';

  @override
  String get tileStator => '定子';

  @override
  String get tileVibration => '振动';

  @override
  String get tileAcc200 => '加速度计 · 200 G';

  @override
  String get tileSafetyScanner => '安全扫描仪';

  @override
  String tracks(int count) {
    return '$count 个目标';
  }

  @override
  String points(int count) {
    return '$count 个点';
  }

  @override
  String axes(int count) {
    return '$count 轴';
  }

  @override
  String connectedCount(int count) {
    return '$count 台已连接';
  }

  @override
  String armedCount(int count) {
    return '$count 台已解锁';
  }

  @override
  String get proxClear => '无障碍';

  @override
  String get tileProximity => '接近';

  @override
  String get tileSrcProx => '接近传感器';

  @override
  String tileSrcCustom(String hz) {
    return '自定义通道 · $hz Hz';
  }

  @override
  String get tagScript => '脚本';

  @override
  String get viewEnded => '已结束';

  @override
  String series(int count) {
    return '$count 个序列';
  }

  @override
  String get rdReach => '可达距离';

  @override
  String get pyroDrogue => '减速伞';

  @override
  String get pyroMain => '主伞';

  @override
  String get pyroAirstart => '空中点火';

  @override
  String get pyroSpare => '备用';

  @override
  String get pyroContinuity => '通路';

  @override
  String get pyroFired => '已点火';

  @override
  String get pyroNotWired => '未接线';

  @override
  String removeTitle(String name) {
    return '移除 $name？';
  }

  @override
  String get removeDevice => '移除设备';

  @override
  String removeBody(String name) {
    return '$name 的配对密钥、HUD 布局和参数草稿将从此应用中删除。';
  }

  @override
  String get removeDisconnectFirst => '会先断开连接。';

  @override
  String get removeKept => '录制会保留。若要再次使用该设备，请用新的配对码配对。';

  @override
  String onlineOf(int online, int total) {
    return '$online / $total 在线';
  }

  @override
  String get devicesEmptyHint => '配对一台设备，或按照快速入门将库添加到你的项目中。';

  @override
  String get devicesSeveral => '可以同时连接多台设备。当前显示的设备接收摇杆输入；其他设备收到居中的摇杆并保持，STOP 会停止所有设备。';

  @override
  String get connected => '已连接';

  @override
  String removeName(String name) {
    return '移除 $name';
  }

  @override
  String get online => '在线';

  @override
  String get batShort => '电池';

  @override
  String get myRobot => '我的机器人';

  @override
  String radioNothingHeard(String port, int baud) {
    return '在 $port 上以 $baud baud 没有收到任何信号。请检查设备是否开机、两个电台是否使用相同的信道和空中速率、波特率是否一致。你仍然可以先添加链路，稍后再连接。';
  }

  @override
  String get pairTitle => '配对设备';

  @override
  String get pairNearby => '附近';

  @override
  String get pairRadio => '电台';

  @override
  String get pairSimulated => '模拟';

  @override
  String get pairSimulatedIntro => '模拟设备在此应用内运行，使用与真实硬件相同的协议。只添加你需要的；每台都带有 SIM 标签。';

  @override
  String get added => '已添加';

  @override
  String get addAnother => '再添加一台';

  @override
  String get add => '添加';

  @override
  String radioRatesTlm(int tlm) {
    return '遥测 $tlm Hz · 无操控';
  }

  @override
  String radioRates(int tlm, int ctl) {
    return '遥测 $tlm Hz · 操控 $ctl Hz';
  }

  @override
  String get radioIntro => '电台链路是通过 USB 插在这台电脑或手机上的电台模块，与设备上配对的电台通信。';

  @override
  String get radioIntroMore => '对应用来说它是一个串口；电台类型决定速度和可承载的数据量。';

  @override
  String get radioNoSerial => '此平台不支持 USB 串口';

  @override
  String get radioNoSerialBody => 'iOS 应用无法打开 USB 串口适配器。请在 Android、macOS、Windows 或 Linux 上使用电台链路，或通过 Wi-Fi 或蓝牙连接。';

  @override
  String get radioLora => 'LoRa 模块本身不是 USB 设备。请将 LoRa 指南中的地面站程序烧录到另一块带电台的板子上，然后插上那块板子。';

  @override
  String get usbPort => 'USB 端口';

  @override
  String get refresh => '刷新';

  @override
  String get noSerialPorts => '未找到串口。请插入电台的 USB 适配器。';

  @override
  String get baudRate => '波特率';

  @override
  String heard(String name) {
    return '收到 $name';
  }

  @override
  String get heardMavlink => '它使用 MAVLink：无需配对。';

  @override
  String get heardPairing => '它处于配对模式，将获得密钥。';

  @override
  String get heardNoPairing => '它不在配对模式；将以无密钥方式添加。';

  @override
  String get listening => '正在监听';

  @override
  String get listenForDevice => '监听设备';

  @override
  String pairName(String name) {
    return '配对 $name';
  }

  @override
  String get addRadioLink => '添加电台链路';

  @override
  String get pairNearbyIntro => '插上或打开板子电源。飞控和无人机会自动出现；运行 koebelt/link 库的板子在配对模式下也会显示在这里。';

  @override
  String get scanning => '正在扫描 Wi-Fi、蓝牙和 USB 板子…';

  @override
  String get stillScanning => '仍在扫描更多设备…';

  @override
  String get addByIp => '通过 IP 地址添加';

  @override
  String get name => '名称';

  @override
  String get mavlinkPortNote => '应用像其他地面站一样监听 UDP 14550；如果知道，这里填写飞行器的端口。';

  @override
  String get addDevice => '添加设备';

  @override
  String get notShowingUp => '设备没有出现？运行 ArduPilot、PX4、Betaflight 或 INAV 的板子可直接连接；其他设备需要 koebelt/link 库。';

  @override
  String get openQuickstart => '打开快速入门';

  @override
  String get orLower => '或';

  @override
  String get addItByIp => '通过 IP 地址添加';

  @override
  String get secControl => '操控';

  @override
  String get secController => '游戏手柄';

  @override
  String get secLink => '链路与安全';

  @override
  String get secRecording => '录制';

  @override
  String get secAlerts => '警报';

  @override
  String get secMap => '地图';

  @override
  String get secPairing => '配对';

  @override
  String get secAi => 'AI 助手（MCP）';

  @override
  String get secAiShort => 'AI 助手';

  @override
  String get secUpdates => '更新';

  @override
  String get setInput => '输入方式';

  @override
  String get setInputDesc => '摇杆：两个虚拟摇杆。滑块：自动回中的油门和偏航，配合一个摇杆。倾斜：通过倾斜手机或平板来操控。';

  @override
  String get csSticks => '摇杆';

  @override
  String get csSliders => '滑块';

  @override
  String get csTilt => '倾斜';

  @override
  String get setInvert => '反转俯仰';

  @override
  String get setInvertDesc => '向前推为抬头。';

  @override
  String get setHaptics => '触觉反馈';

  @override
  String get setHapticsDesc => '摇杆回中和警告时振动。';

  @override
  String get setLinkLoss => '链路丢失时';

  @override
  String get setLinkLossDesc => '无人机在 1.8 秒未收到操控数据包后的动作。地面机器人和机械臂保持，测试台停止电机，火箭继续其飞行序列。';

  @override
  String get setRate => '遥测频率';

  @override
  String get setRateDesc => '频率越高，占用带宽和电量越多。';

  @override
  String get setTestFailsafe => '测试失控保护';

  @override
  String get setTestFailsafeDesc => '断开操控链路六秒，以便检查所配置的行为。';

  @override
  String get runTest => '运行测试';

  @override
  String get setRecordVideo => '录制视频';

  @override
  String get setRecordVideoDesc => '每次录制都保存设备的摄像头画面。录制期间摄像头保持连接，即使没有页面显示它。';

  @override
  String get setVideoFps => '视频帧率';

  @override
  String get setVideoFpsDesc => '每秒最多保留的帧数。640×480 的 ESP32-CAM 在 10 fps 下每分钟约 10 MB。';

  @override
  String get setAlertSound => '警报声音';

  @override
  String get setAlertSoundDesc => '在警报和链路丢失时播放。开启触觉反馈时，手机改为振动。';

  @override
  String kindsOnly(String kinds) {
    return '仅限$kinds。';
  }

  @override
  String get below => '低于';

  @override
  String get above => '高于';

  @override
  String get setMapTiles => '地图瓦片';

  @override
  String get setMapTilesDesc => '地图视图的背景：Mapbox Dark、Outdoors（地形）或 Satellite、你自己的瓦片，或无（米制网格）。看过的瓦片会在此设备上保留一段时间。';

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
  String get setMapboxToken => '你的 Mapbox 令牌';

  @override
  String get setMapboxTokenDesc => '可选：来自你自己 Mapbox 账户的公开令牌（pk.…），使用你的配额而不是应用的配额。';

  @override
  String get setTileUrl => '瓦片 URL';

  @override
  String setTileUrlDesc(String z, String x, String y) {
    return '包含 $z、$x 和 $y 的模板，例如地图服务商带密钥的卫星图层。请遵守服务商的条款。';
  }

  @override
  String get setAttribution => '署名';

  @override
  String get setAttributionDesc => '你的服务商要求的署名，显示在地图上。';

  @override
  String get provider => '服务商';

  @override
  String get setGuides => '集成指南';

  @override
  String get setGuidesDesc => '将 koebelt/link 库添加到 Arduino、Python、ROS 2 或 Rust 项目中。';

  @override
  String scriptHostAt(String address) {
    return '位于 $address 的脚本主机';
  }

  @override
  String get forget => '忘记';

  @override
  String get setScriptHosts => '脚本主机';

  @override
  String get setScriptHostsDesc => '网络中为此设备运行脚本的电脑，可使用任意 Python 包。在电脑上：pip install koebelt-dash-scripts，然后 koebelt-dash-scripts host。';

  @override
  String get setScriptHostsDescPhone => '网络中为此手机运行脚本的电脑，可使用任意 Python 包。在电脑上：pip install koebelt-dash-scripts，然后 koebelt-dash-scripts host。';

  @override
  String get setBeHost => '作为脚本主机';

  @override
  String get setBeHostDesc => '用脚本的 Python 为此网络中的手机和平板运行脚本。';

  @override
  String setBeHostCode(String code) {
    return '配对码：$code。手机在 脚本 > 运行于 > 添加脚本主机 中配对。';
  }

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个会话', one: '1 个会话');
    return '$_temp0';
  }

  @override
  String get import => '导入';

  @override
  String get record => '录制';

  @override
  String get noRecordings => '还没有录制。录制一台已连接的设备，或用“导入”打开文件或示例录制。';

  @override
  String get tagNew => '新';

  @override
  String get tagVideo => '视频';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 台设备', one: '1 台设备');
    return '$_temp0';
  }

  @override
  String deleteName(String name) {
    return '删除 $name';
  }

  @override
  String exportName(String name) {
    return '导出 $name';
  }

  @override
  String get replayEyebrow => '录制与回放';

  @override
  String get sessions => '会话';

  @override
  String get export => '导出';

  @override
  String get exitToLive => '退出到实时';

  @override
  String get play => '播放';

  @override
  String deleteTitle(String name) {
    return '删除 $name？';
  }

  @override
  String get exportFirst => '先导出';

  @override
  String get delete => '删除';

  @override
  String get deleteRecordingBody => '该录制将从此设备中移除。此操作无法撤销。';

  @override
  String deleteAllN(int count) {
    return '全部删除 $count 个';
  }

  @override
  String get deleteSessionBody => '此会话中所有设备的录制及其视频都将从此设备中移除。此操作无法撤销。';

  @override
  String sequenceN(int n) {
    return '序列 $n';
  }

  @override
  String sequencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个序列', zero: '没有序列');
    return '$_temp0';
  }

  @override
  String copyOf(String name) {
    return '$name 副本';
  }

  @override
  String noSequencesFor(String name) {
    return '$name 还没有序列。';
  }

  @override
  String sequenceIntro(String examples) {
    return '序列是一组步骤（$examples），应用逐一运行，并等待设备确认每一步。';
  }

  @override
  String get sequenceComplete => '序列完成';

  @override
  String get sequenceStopped => '序列已停止';

  @override
  String get flightSequence => '飞行序列';

  @override
  String get flightSequenceBody => '飞行计算机在机上执行发射、远地点和回收。在“参数”页面设置开伞；这里的序列用于发射台检查。';

  @override
  String get stepsDrone => '起飞、飞往航点、等待、降落';

  @override
  String get stepsRover => '行驶至航点、等待、改变速度';

  @override
  String get stepsArm => '移动到姿态、张开或闭合夹爪';

  @override
  String get stepsBench => '保持油门、在两个油门之间爬升';

  @override
  String get stepsGeneric => '等待、设置模式、发送指令';

  @override
  String get whyExitReplay => '退出回放后才能运行';

  @override
  String get whyResetStop => '请先重置停止';

  @override
  String get whyAddSteps => '请先添加步骤';

  @override
  String get onDevice => '在设备上';

  @override
  String get uploading => '正在上传';

  @override
  String stepOf(int n, int total) {
    return '第 $n / $total 步';
  }

  @override
  String get runsOnDevice => '在设备上运行：链路中断也会继续';

  @override
  String get stopSequence => '停止序列';

  @override
  String get stoppedFromApp => '已从应用停止';

  @override
  String get run => '运行';

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个步骤', one: '1 个步骤');
    return '$_temp0';
  }

  @override
  String secondsTimed(String seconds) {
    return '计时 $seconds 秒';
  }

  @override
  String get newSequence => '新建序列';

  @override
  String get duplicate => '复制';

  @override
  String get steps => '步骤';

  @override
  String get lockedWhileRunning => '运行期间已锁定';

  @override
  String get addFirstStep => '在下方添加第一个步骤。步骤从上到下运行。';

  @override
  String get addStep => '添加步骤';

  @override
  String get dragToReorder => '拖动以重新排序';

  @override
  String get deleteStep => '删除步骤';

  @override
  String get useCurrentPosition => '使用当前位置';

  @override
  String get useCurrentPose => '使用当前姿态';

  @override
  String get egDeploy => '例如 deploy';

  @override
  String get planTopView => '规划 · 俯视图';

  @override
  String get throttleProfile => '油门曲线';

  @override
  String get liveView => '实时视图';

  @override
  String get timeline => '时间轴';

  @override
  String get setPoseAsHome => '将当前姿态设为初始';

  @override
  String get planNoteDrone => '航点是相对起飞点向东和向北的米数。无人机在每个航点保持，然后执行下一步。链路中断时失控保护仍然有效。';

  @override
  String get planNoteRover => '航点是相对起点向东和向北的米数。地面机器人在每个航点停下，然后执行下一步。';

  @override
  String planNoteArm(String button) {
    return '用手或点动控制移动机械臂，然后用“$button”记录。';
  }

  @override
  String get planNoteBench => '设备上的电流和温度切断在序列运行期间保持有效。';

  @override
  String get planNoteGeneric => '每一步都等待设备确认后才开始下一步。';

  @override
  String metreGrid(String length) {
    return '$length 网格';
  }

  @override
  String get now => '现在';

  @override
  String get and => '和';

  @override
  String get checkNeedsPython => '检查需要这台电脑上的 Python：在脚本页面中点击“设置 Python”。';

  @override
  String couldNotCheck(String python) {
    return '无法用 $python 检查。';
  }

  @override
  String scriptErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '此脚本有 $count 个错误', one: '此脚本有 1 个错误');
    return '$_temp0';
  }

  @override
  String get runAnyway => '仍然运行';

  @override
  String get showThem => '显示';

  @override
  String get checkFound => '检查发现了会让它停止的问题，很可能在它移动任何东西之前：';

  @override
  String lineN(int n) {
    return '第 $n 行';
  }

  @override
  String andMore(int count) {
    return '另有 $count 个';
  }

  @override
  String get installImports => '安装此脚本导入的包？';

  @override
  String get installAndRun => '安装并运行';

  @override
  String missingImports(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '此 Python 中没有 $names，脚本会在导入时停止。', one: '此 Python 中没有 $names，脚本会在导入时停止。');
    return '$_temp0';
  }

  @override
  String couldNotStart(String error) {
    return '无法启动：$error';
  }

  @override
  String get pythonScripts => 'Python 脚本';

  @override
  String copiedExample(String file) {
    return '已将示例复制到你脚本中的 $file。';
  }

  @override
  String couldNotCopyExample(String error) {
    return '无法复制示例：$error';
  }

  @override
  String get rename => '重命名';

  @override
  String get deleteScriptBody => '它会移到脚本文件夹中的 .trash 文件夹，你可以从那里找回。';

  @override
  String get error => '错误';

  @override
  String get examples => '示例';

  @override
  String get connectedOutside => '从 dash 外部连接';

  @override
  String get editing => '编辑中';

  @override
  String get saved => '已保存';

  @override
  String get checkAction => '检查';

  @override
  String get checking => '正在检查…';

  @override
  String get openInEditor => '在编辑器中打开';

  @override
  String get newScript => '新建脚本';

  @override
  String get importPyZip => '导入 .py 或 .zip';

  @override
  String get noScriptsPlus => '还没有脚本。从示例开始，或按 +。';

  @override
  String get scriptsEmpty => '脚本用 Python 操控你的设备。新建一个、导入一个，或从示例开始。';

  @override
  String get edit => '编辑';

  @override
  String get share => '分享';

  @override
  String get noScriptsNew => '还没有脚本。从示例开始，或按“新建”。';

  @override
  String get more => '更多';

  @override
  String get showInFinder => '在访达中显示';

  @override
  String get showInFolder => '在文件夹中显示';

  @override
  String get myScript => '我的脚本';

  @override
  String get create => '创建';

  @override
  String get save => '保存';

  @override
  String get device => '设备';

  @override
  String get needs => '需要';

  @override
  String get runsOn => '运行于';

  @override
  String get scriptsRunOnComputer => '脚本在电脑上运行';

  @override
  String get scriptsRunOnComputerBody => '此设备会把脚本发送到脚本主机：同一网络中运行 koebelt-dash-scripts 的电脑，可以使用任意 Python 包（OpenCV、PyTorch…）。';

  @override
  String get addScriptHost => '添加脚本主机';

  @override
  String get notRunning => '未运行';

  @override
  String get endedError => '因错误结束';

  @override
  String get ended => '已结束';

  @override
  String get waitingConnect => '等待脚本连接（脚本中的 connect()）…';

  @override
  String get youHaveSticks => '摇杆由你掌控';

  @override
  String get youHaveSticksBody => '你拨动了摇杆，因此忽略脚本的摇杆输入。';

  @override
  String get scriptLostSticks => '脚本失去了摇杆控制';

  @override
  String isNotConnected(String name) {
    return '$name 未连接';
  }

  @override
  String get connectItOrChoose => '连接它，或在上方选择其他设备。';

  @override
  String doesNotFit(String name) {
    return '$name 不适用于此脚本';
  }

  @override
  String get chooseOrChangeRequires => '在上方选择其他设备，或修改 # requires: 行。';

  @override
  String get scriptNeedsDevice => '脚本需要操控设备：请先连接一台（设备页面，或顶部的设备菜单）。';

  @override
  String get doesNotFitShort => '不适用';

  @override
  String get selectedInDash => 'dash 中选中的设备';

  @override
  String get noneConnected => '无已连接设备';

  @override
  String get thisComputer => '这台电脑';

  @override
  String get lookingForPython => '正在查找 Python…';

  @override
  String get noneFound => '未找到';

  @override
  String get noPackage => '无包';

  @override
  String get python3Needed => '需要 Python 3';

  @override
  String get python3NeededBody => '请从 python.org 安装，然后回到这里。';

  @override
  String get newerLibrary => '脚本所用的库有适用于此版本 koebelt dash 的新版本。';

  @override
  String get update => '更新';

  @override
  String get pythonNoAnswer => '此 Python 没有响应';

  @override
  String get packageNotInPython => '此 Python 中没有 koebelt-dash-scripts';

  @override
  String pythonNoAnswerBody(String python) {
    return 'dash 无法运行 $python。请选择其他 Python，或创建脚本环境。';
  }

  @override
  String get packageNotInPythonBody => '在这里安装（pip install koebelt-dash-scripts），或让 dash 在脚本文件夹中创建脚本环境。';

  @override
  String get installHere => '在这里安装';

  @override
  String get scriptsEnvironment => '脚本环境';

  @override
  String get checkAgain => '重新检查';

  @override
  String get settingUpPython => '正在设置 Python';

  @override
  String get oneTimeSetup => '一次性设置';

  @override
  String get oneTimeSetupBody => '脚本需要 koebelt-dash-scripts 包。dash 可以在脚本文件夹中为它们创建 Python 环境（.venv）并安装到那里；你自己的包（OpenCV、PyTorch…）也装在那里。';

  @override
  String get setUpPython => '设置 Python';

  @override
  String packagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '缺少多个包', one: '缺少一个包');
    return '$_temp0';
  }

  @override
  String packagesMissingBody(String modules, String packages) {
    return '此脚本导入了 $modules，但此 Python 中没有：脚本会在那里停止。要安装 $packages 吗？';
  }

  @override
  String get installing => '正在安装…';

  @override
  String get install => '安装';

  @override
  String get notNow => '暂不';

  @override
  String get dismiss => '忽略';

  @override
  String get stopScript => '停止脚本';

  @override
  String get restart => '重新启动';

  @override
  String get triggers => '触发器';

  @override
  String get triggersEmpty => '向脚本发送事件的按钮、按键、手柄按键、条件和定时器。用 @dev.trigger(…) 声明，或在这里添加。';

  @override
  String get limits => '限制';

  @override
  String get maxSpeed => '最大速度';

  @override
  String get geofence => '电子围栏';

  @override
  String get off => '关';

  @override
  String metresFromHome(String length) {
    return '距返航点 $length';
  }

  @override
  String get ceiling => '高度上限';

  @override
  String get armingTakeoff => '解锁、起飞';

  @override
  String get allowed => '允许';

  @override
  String get notAllowed => '不允许';

  @override
  String get paramWrites => '参数写入';

  @override
  String get fire => '触发';

  @override
  String get notBound => '尚未绑定';

  @override
  String get console => '控制台';

  @override
  String loopHz(String hz) {
    return '循环 $hz Hz';
  }

  @override
  String get consoleEmpty => 'print() 的输出和错误显示在这里。';

  @override
  String get fromOutside => '来自 dash 外部';

  @override
  String get valid => '有效';

  @override
  String padTaken(String button, String action) {
    return '$button 在手柄映射中是“$action”：以该操作为准。';
  }

  @override
  String get forDuration => '持续';

  @override
  String conditionHelp(String fields) {
    return '字段：$fields、mode、armed，以及设备自己的通道（motor_temp.max…）。用 and、or、not 组合；加上“for 3s”表示等待。';
  }

  @override
  String get whenTrue => '为真时';

  @override
  String get trueAndFalse => '为真和为假时';

  @override
  String get alsoOnControl => '同时显示在操控页面的摇杆旁';

  @override
  String get key => '按键';

  @override
  String get pressKey => '按一个键…';

  @override
  String pressAnotherKey(String key) {
    return '$key · 按其他键更改';
  }

  @override
  String get clickThenKey => '点击，然后按一个键';

  @override
  String get noButtonYet => '尚未设置按键';

  @override
  String get pressButton => '按一个按键…';

  @override
  String get learn => '学习';

  @override
  String get onlyThisMode => '仅限此模式（HOLD…），留空则任意';

  @override
  String get onlyMessagesContaining => '仅包含以下内容的消息…';

  @override
  String get every => '每隔';

  @override
  String get onceAfter => '延迟一次';

  @override
  String get secondsWord => '秒';

  @override
  String get addTrigger => '添加触发器';

  @override
  String get editTrigger => '编辑触发器';

  @override
  String get event => '事件';

  @override
  String get eventPlaceholder => '脚本收到的名称';

  @override
  String get firedBy => '触发方式';

  @override
  String triggerHelp(String event) {
    return '脚本在同名的处理函数或 @dev.on_trigger 中收到“$event”。条件、事件和定时器在 dash 中运行。';
  }

  @override
  String get done => '完成';

  @override
  String get limitsHelp => '在这里设置，而不是在脚本中：脚本无法更改它们。';

  @override
  String get maximumSpeed => '最大速度';

  @override
  String get maximumSpeedDesc => '脚本的摇杆按此缩放，速度限制也以此为上限。';

  @override
  String get geofenceDesc => '超出距返航点的此距离后，脚本失去摇杆控制，设备保持。';

  @override
  String get ceilingDesc => '高于此高度时，无人机同样处理。';

  @override
  String get allowArming => '允许解锁和起飞';

  @override
  String get allowArmingDesc => '否则脚本只能移动你已解锁的设备。';

  @override
  String get allowParams => '允许写入参数';

  @override
  String get allowParamsDesc => '用于调参脚本。它们可以改变设备的行为。';

  @override
  String get pairing => '正在配对…';

  @override
  String get pair => '配对';

  @override
  String get scriptHostIntro => '脚本主机是同一网络中为这台电脑运行脚本的电脑：笔记本、Raspberry Pi、Jetson…在它上面运行：';

  @override
  String get scriptHostIntroPhone => '脚本主机是同一网络中为此手机或平板运行脚本的电脑：笔记本、Raspberry Pi、Jetson…在它上面运行：';

  @override
  String get onTheNetwork => '网络中';

  @override
  String get lookingForHosts => '正在查找脚本主机';

  @override
  String get noHostsFound => '未找到。请在下方输入它的地址（由 `ipconfig getifaddr en0`、`hostname -I`… 显示）。';

  @override
  String get lookAgain => '重新查找';

  @override
  String get address => '地址';

  @override
  String get pairingCode => '配对码';

  @override
  String get pairingCodePlaceholder => 'ABC-123，由主机显示';

  @override
  String updatingPct(int pct) {
    return '正在更新 $pct%';
  }

  @override
  String get installingState => '正在安装';

  @override
  String get appUpdating => 'koebelt dash 正在更新';

  @override
  String appAvailable(String version) {
    return 'koebelt dash $version 可用';
  }

  @override
  String get appUpToDate => 'koebelt dash 已是最新版本';

  @override
  String get skipVersion => '跳过此版本';

  @override
  String get later => '稍后';

  @override
  String downloadingPct(int pct) {
    return '正在下载 $pct%';
  }

  @override
  String get installAnyway => '仍然安装';

  @override
  String get updateAnyway => '仍然更新';

  @override
  String installVersion(String version) {
    return '安装 $version';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String youHaveOlder(String version) {
    return '你当前是 $version；这是较旧的版本。用较新版本创建的设置和录制可能无法全部打开，并且在下一个版本发布前不会再提醒你更新。';
  }

  @override
  String youHave(String version) {
    return '你当前是 $version。';
  }

  @override
  String get notFromApp => '不是从应用安装的';

  @override
  String get checkingCompat => '正在检查与你的设备的兼容性…';

  @override
  String get compatUnknown => '兼容性未知';

  @override
  String get compatUnknownBody => '无法读取此版本支持的 koebelt/link 版本。';

  @override
  String notCompatibleWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '与你的 $count 台设备不兼容', one: '与你的一台设备不兼容');
    return '$_temp0';
  }

  @override
  String notCompatibleBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '请先更新它们上面的 koebelt/link 库，或保留当前版本并在 设置 > 更新 中选择其他版本。',
      one: '请先更新它上面的 koebelt/link 库，或保留当前版本并在 设置 > 更新 中选择其他版本。',
    );
    return '$_temp0';
  }

  @override
  String get disarmFirst => '请先上锁';

  @override
  String get disarmFirstBody => '有已连接的设备处于解锁状态。更新会关闭应用并断开链路；请先上锁再更新。';

  @override
  String get devicesWillDisconnect => '设备将断开连接';

  @override
  String devicesWillDisconnectBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '安装会关闭应用，$count 台已连接的设备会失去链路，在你重新连接前由其失控保护接管。',
      one: '安装会关闭应用，已连接的设备会失去链路，在你重新连接前由其失控保护接管。',
    );
    return '$_temp0';
  }

  @override
  String get notInstalled => '未安装';

  @override
  String get inThisVersion => '此版本中';

  @override
  String get whatsNew => '新功能';

  @override
  String get fullNotes => '完整发布说明';

  @override
  String get chooseAnotherVersion => '选择其他版本';

  @override
  String get chooseVersion => '选择版本';

  @override
  String get close => '关闭';

  @override
  String get chooseVersionBody => '安装任意已发布的版本，较新或较旧均可。每个版本都会标明是否适用于你的设备上次连接时报告的 koebelt/link 版本。';

  @override
  String get askingGithub => '正在询问 GitHub…';

  @override
  String get noReleases => '未找到发布版本。';

  @override
  String get installed => '已安装';

  @override
  String get latest => '最新';

  @override
  String get checkingShort => '正在检查…';

  @override
  String get worksWithDevices => '适用于你的设备';

  @override
  String get noDevicesToCheck => '还没有可检查的设备';

  @override
  String notFor(String names) {
    return '不适用于 $names';
  }

  @override
  String get details => '详情';

  @override
  String get updateHowAndroid => '更新会下载到这里，Android 会要求你确认安装。';

  @override
  String get updateHow => '更新会下载、与发布版本核对，然后 koebelt dash 以新版本重启。';

  @override
  String versionN(String version) {
    return '版本 $version';
  }

  @override
  String get noSelfUpdate => '此版本不会自行更新：App Store 和 TestFlight 会更新它们的版本，从 GitHub 下载的版本会自行检查新版本。';

  @override
  String get releases => '发布版本';

  @override
  String get upToDate => '已是最新。';

  @override
  String versionAvailable(String version) {
    return '$version 可用。';
  }

  @override
  String downloadingWhat(String what, int pct) {
    return '正在下载 $what… $pct%';
  }

  @override
  String installingWhat(String what) {
    return '正在安装 $what…';
  }

  @override
  String get somethingWrong => '出了点问题。';

  @override
  String get notChecked => '尚未检查。';

  @override
  String updateTo(String version) {
    return '更新到 $version';
  }

  @override
  String get checkNow => '立即检查';

  @override
  String get chooseVersionDesc => '安装任意已发布的版本，包括旧版本，并标明是否适用于你设备上的 koebelt/link 库。';

  @override
  String get versions => '版本';

  @override
  String get betas => '测试版';

  @override
  String get betasDesc => '也提供测试版和候选版本：在正式发布前体验新功能，但出现问题的可能性更大。';

  @override
  String get autoCheck => '自动检查更新';

  @override
  String get autoCheckDesc => '启动时以及每天一次，koebelt dash 会向 GitHub 查询最新版本。不会发送其他任何内容。';

  @override
  String get padYawSteer => '偏航 · 转向';

  @override
  String get padRoll => '横滚';

  @override
  String get padPitchDrive => '俯仰 · 行驶';

  @override
  String get padUnavailable => '此平台不支持游戏手柄。';

  @override
  String get padNone => '没有连接手柄。在系统设置中配对蓝牙手柄，或通过 USB 插上。遥控器可在 USB 摇杆模式下使用。';

  @override
  String padConnected(String names) {
    return '已连接：$names。';
  }

  @override
  String get padUse => '使用游戏手柄';

  @override
  String get padUseDesc => '设备解锁后，摇杆可操控无人机和地面机器人，并点动机械臂；按键适用于任何设备。手柄闲置时，屏幕上的操控照常可用。';

  @override
  String get padSticks => '摇杆';

  @override
  String get padMoveNow => '现在移动或按下控件';

  @override
  String get padButtons => '按键';

  @override
  String get padDeadzone => '死区';

  @override
  String padDeadzoneDesc(int pct) {
    return '中心附近忽略的摇杆行程：$pct %。';
  }

  @override
  String get padExpo => 'Expo';

  @override
  String padExpoDesc(int pct) {
    return '中心附近响应更柔和，便于精细操控：$pct %。';
  }

  @override
  String get padResetMapping => '重置映射';

  @override
  String get padResetMappingDesc => '标准布局：左摇杆油门和偏航，右摇杆俯仰和横滚，B / ○ 为 STOP。';

  @override
  String get waiting => '等待中…';

  @override
  String get invertDirection => '反转方向';

  @override
  String get inverted => '已反转';

  @override
  String get normal => '正常';

  @override
  String clearName(String name) {
    return '清除 $name';
  }

  @override
  String padDrives(String pad, String device) {
    return '$pad 正在操控 $device';
  }

  @override
  String padArmToDrive(String pad) {
    return '解锁后即可用 $pad 操控；按键已可使用';
  }

  @override
  String get padButtonsWork => '按键可用；摇杆可操控无人机和地面机器人';

  @override
  String get pad => '手柄';

  @override
  String get copy => '复制';

  @override
  String get aiLet => '允许助手使用 koebelt dash';

  @override
  String get aiLetDesc => 'Claude、Codex、OpenCode、Cursor 和其他 MCP 客户端可以阅读文档、编写脚本、使用应用，并在你批准后操作设备。dash 本身不向任何 AI 服务发送任何内容；你连接的助手与其自己的服务商通信。';

  @override
  String get aiConnectClient => '连接客户端';

  @override
  String get aiPaste => '将此内容粘贴到助手的配置中。';

  @override
  String get aiRemotePhone => '助手在电脑上运行：它们通过网络、使用令牌访问这台手机。';

  @override
  String get aiRemoteTablet => '助手在电脑上运行：它们通过网络、使用令牌访问这台平板。';

  @override
  String get other => '其他';

  @override
  String get aiConnectedNow => '当前已连接';

  @override
  String get aiNone => '过去十分钟内没有助手。';

  @override
  String actions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个操作', one: '1 个操作');
    return '$_temp0';
  }

  @override
  String get activity => '活动';

  @override
  String get aiAllowed => '无需询问即允许';

  @override
  String get aiAllowedNone => '模拟设备和回放从不询问。在真实硬件上，每个操作都会询问，除非你在本次会话中允许。解锁和起飞总是会询问。';

  @override
  String aiAllowedSome(String actions) {
    return '本次会话：$actions。解锁和起飞总是会询问。';
  }

  @override
  String get aiFromNetwork => '来自此网络';

  @override
  String aiFromNetworkOn(String url, String token) {
    return '其他电脑上的助手：$url，令牌 $token…（从“其他”标签页复制）。';
  }

  @override
  String get aiFromNetworkOff => '允许另一台电脑上的助手使用令牌访问此 dash。';

  @override
  String get aiActivity => '助手活动';

  @override
  String get nothingYet => '暂无内容。';

  @override
  String get aiShort => 'AI';

  @override
  String aiAsks(String client) {
    return '$client 请求';
  }

  @override
  String aiRealHardware(String device) {
    return '$device 是真实硬件。';
  }

  @override
  String aiAllowSession(String device) {
    return '本次会话中允许在 $device 上执行此类操作';
  }

  @override
  String get refuse => '拒绝';

  @override
  String get approve => '批准';

  @override
  String get recordingsAndLogs => '录制和飞行日志';

  @override
  String fileUnreadable(String error) {
    return '无法读取文件：$error';
  }

  @override
  String get fromFile => '从文件';

  @override
  String get fromFileDesc => '作为会话打开：回放、地图、图表和导出都可使用。';

  @override
  String get fmtJson => '从 koebelt/dash 导出的录制';

  @override
  String get fmtBin => 'ArduPilot 日志，来自 SD 卡或 Mission Planner';

  @override
  String get fmtTlog => '地面站日志：Mission Planner、QGroundControl、MAVProxy';

  @override
  String get fmtUlg => 'PX4 日志，来自 SD 卡或 QGroundControl';

  @override
  String reading(String file) {
    return '正在读取 $file…';
  }

  @override
  String get stopRecordingFirst => '请先停止录制';

  @override
  String get notImported => '未导入';

  @override
  String get sampleRecordings => '示例录制';

  @override
  String get samplesIn => '三个演示会话已在你的列表中，标记为“演示”。';

  @override
  String get samplesDesc => '用模拟设备录制的三个演示会话：一次测绘飞行、一次抓取放置、一次火箭发射。';

  @override
  String get removeSamples => '移除示例';

  @override
  String get loadSamples => '加载示例';

  @override
  String get exporting => '正在导出…';

  @override
  String exportFormat(String format) {
    return '导出 $format';
  }

  @override
  String frames(int count) {
    return '$count 帧';
  }

  @override
  String csvColumns(int count) {
    return '$count 列 · 仅此设备发送的通道';
  }

  @override
  String get noGpx => '此录制没有 GPS，因此没有 GPX 轨迹';

  @override
  String encoding(String format, int pct) {
    return '正在编码 $format · $pct%';
  }

  @override
  String get exported => '已导出';

  @override
  String get exportFailed => '导出失败';

  @override
  String get decrease => '减少';

  @override
  String get increase => '增加';

  @override
  String was(String value) {
    return '原为 $value';
  }

  @override
  String firmware(String version) {
    return '固件 $version';
  }

  @override
  String parametersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个参数', one: '1 个参数');
    return '$_temp0';
  }

  @override
  String get parameters => '参数';

  @override
  String unsaved(int count) {
    return '$count 项未保存';
  }

  @override
  String written(String when) {
    return '$when已写入';
  }

  @override
  String get inSync => '已同步';

  @override
  String get revert => '还原';

  @override
  String get writing => '正在写入…';

  @override
  String get writeToDevice => '写入设备';

  @override
  String get searchParameters => '搜索参数';

  @override
  String get waitingParams => '正在等待参数表…';

  @override
  String noParamsMatch(String query) {
    return '没有与“$query”匹配的参数';
  }

  @override
  String revertName(String name) {
    return '还原 $name';
  }

  @override
  String get liveResponse => '实时响应';

  @override
  String get copied => '已复制';

  @override
  String get yourPairingCode => '你的配对码 · 10 分钟内有效';

  @override
  String namePaired(String name) {
    return '$name 已配对';
  }

  @override
  String get startListening => '开始监听';

  @override
  String get listeningWifiBle => '正在通过 Wi-Fi 和 BLE 监听 · 请打开设备电源';

  @override
  String nameFound(String name) {
    return '找到 $name';
  }

  @override
  String sensorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个传感器', one: '1 个传感器');
    return '$_temp0';
  }

  @override
  String get addToDevices => '添加到设备';

  @override
  String get connectNow => '立即连接';

  @override
  String get inTheApp => '在应用中';

  @override
  String get completeProgram => '完整程序';

  @override
  String get apiReference => 'API 参考';

  @override
  String get exampleProjects => '示例项目';

  @override
  String get allGuides => '所有指南';

  @override
  String stepOfUpper(int n, int total) {
    return '第 $n 步，共 $total 步';
  }

  @override
  String get flowDevice => '你的设备';

  @override
  String get flowDeviceDesc => '板子或协处理电脑上的传感器、电机和 koebelt/link。';

  @override
  String get flowLinkDesc => 'Wi-Fi、BLE、USB 串口或电台，一条中断时还有备用链路。';

  @override
  String get flowDashDesc => '手机、平板或电脑上的仪表盘、操控、调参和录制。';

  @override
  String get library => '库';

  @override
  String get connectHardware => '连接你的硬件';

  @override
  String get connectHardwareDesc => '你的设备运行一个小型库，将传感器数据传到此应用并接收操控输入。选择你的平台开始。';

  @override
  String get guidesConnections => '连接';

  @override
  String get guidesConnectionsDesc => '每种链路的工作原理，以及设备不显示时该怎么办。';

  @override
  String get guidesDevices => '设备示例';

  @override
  String get guidesDevicesDesc => '每种设备的完整注释程序。';

  @override
  String get guidesFeatures => '视频、地图和手柄';

  @override
  String get guidesFeaturesDesc => '显示摄像头、将设备放到地图上、用手柄操控。';

  @override
  String get guidesMore => '进阶';

  @override
  String get guidesMoreDesc => '自定义数据、调参、序列和安全。';

  @override
  String get viewChase => 'CHASE';

  @override
  String get viewOrbit => 'ORBIT';

  @override
  String get viewTop => 'TOP';

  @override
  String get viewMap => '地图';

  @override
  String get viewCam => 'CAM';

  @override
  String get noMapboxToken => '此版本没有 Mapbox 令牌：请在下方输入你自己的令牌，或选择其他来源。';

  @override
  String get waitingGps => '正在等待 GPS 定位';

  @override
  String get grid => '网格';

  @override
  String get waitingScript => '正在等待脚本';

  @override
  String get scriptEnded => '脚本已结束';

  @override
  String get noVideo => '此录制没有视频。';

  @override
  String get noCamera => '没有摄像头。设备在库中用 video() 声明摄像头。';

  @override
  String cameraByIp(String name) {
    return '此摄像头通过 IP 地址访问。通过 Wi-Fi 连接到 $name 才能看到它。';
  }

  @override
  String get warning => '警告';

  @override
  String get alBattery => '电池电量低';

  @override
  String get alBatteryDesc => '设备报告的剩余电量。';

  @override
  String get alBatteryAct => '该返回了。';

  @override
  String get alBatteryCritical => '电池电量严重不足';

  @override
  String get alBatteryCriticalDesc => '第二个更严格的限制：重复提醒直到确认。';

  @override
  String get alBatteryCriticalAct => '立即降落或停止。';

  @override
  String get alVoltage => '电池电压';

  @override
  String get alVoltageDesc => '用于不报告百分比的电池。按你的电池设置限制，例如每节 3.5 V。';

  @override
  String get alVoltageAct => '该返回了。';

  @override
  String get alObstacle => '障碍物接近';

  @override
  String get alObstacleDesc => '解锁时接近传感器看到的最近物体（朝下的传感器不计入）。';

  @override
  String get alObstacleAct => '避开或停止。';

  @override
  String get alRssi => '信号弱';

  @override
  String get alRssiDesc => '链路报告的接收信号强度。';

  @override
  String get alRssiAct => '靠近一些或掉头。';

  @override
  String get alLatency => '延迟高';

  @override
  String get alLatencyDesc => '链路的往返时间。超过几百毫秒时操控会感觉滞后。';

  @override
  String get alLatencyAct => '操控会感觉滞后。';

  @override
  String get alAltitude => '高度上限';

  @override
  String get alAltitudeDesc => '相对返航点的高度。欧洲和美国无人机的常见限制为 120 m。';

  @override
  String get alAltitudeAct => '请下降。';

  @override
  String get alDistance => '距返航点距离';

  @override
  String get alDistanceDesc => '简单的电子围栏：距起点的水平距离。';

  @override
  String get alDistanceAct => '请飞近一些。';

  @override
  String get alTemp => '温度';

  @override
  String get alTempDesc => '设备报告的电机、电调或板子温度。';

  @override
  String get alTempAct => '让它冷却。';

  @override
  String get kindDrone => '无人机';

  @override
  String get kindRover => '地面机器人';

  @override
  String get kindArm => '机械臂';

  @override
  String get kindRocket => '火箭';

  @override
  String get kindBench => '测试台';

  @override
  String get kindGeneric => '设备';

  @override
  String get stTakeoff => '起飞';

  @override
  String get stFlyTo => '飞往';

  @override
  String get stLand => '降落';

  @override
  String get stRth => '返航';

  @override
  String get stDriveTo => '行驶至';

  @override
  String get stPose => '移动到姿态';

  @override
  String get stRamp => '爬升';

  @override
  String get stWait => '等待';

  @override
  String get stMode => '设置模式';

  @override
  String get stArm => '解锁 / 上锁';

  @override
  String get stCmd => '自定义指令';

  @override
  String get fEast => '东';

  @override
  String get fNorth => '北';

  @override
  String get fHold => '保持';

  @override
  String get fFrom => '从';

  @override
  String get fTo => '到';

  @override
  String get fOver => '用时';

  @override
  String get fDuration => '时长';

  @override
  String get fMode => '模式';

  @override
  String get fState => '状态';

  @override
  String get fLimit => '限制';

  @override
  String get fCommand => '指令';

  @override
  String get fValue => '值';

  @override
  String sumTakeoff(String alt) {
    return '起飞到 $alt';
  }

  @override
  String sumFlyTo(String x, String y, String z) {
    return '飞往 $x, $y，高度 $z';
  }

  @override
  String sumDriveTo(String x, String y) {
    return '行驶至 $x, $y';
  }

  @override
  String get sumRth => '返航并降落';

  @override
  String sumPose(String joints) {
    return '移动到姿态 $joints°';
  }

  @override
  String sumGripper(String pct) {
    return '夹爪张开 $pct%';
  }

  @override
  String sumThrottle(String pct, String s) {
    return '油门 $pct%，持续 $s 秒';
  }

  @override
  String sumRamp(String from, String to, String s) {
    return '$s 秒内从 $from 爬升到 $to%';
  }

  @override
  String sumWait(String s) {
    return '等待 $s 秒';
  }

  @override
  String sumMode(String mode) {
    return '模式 $mode';
  }

  @override
  String get sumArm => '解锁';

  @override
  String get sumDisarm => '上锁';

  @override
  String sumSpeed(String pct) {
    return '速度限制 $pct%';
  }

  @override
  String sumCmd(String name, String value) {
    return '指令 $name = $value';
  }

  @override
  String get stoppedEstop => '已停止：紧急停止';

  @override
  String completedIn(String seconds) {
    return '用时 $seconds 秒完成';
  }

  @override
  String stepTimedOut(int n, String step) {
    return '第 $n 步超时：$step';
  }

  @override
  String metresToGo(String length) {
    return '还剩 $length';
  }

  @override
  String get uploadingToDevice => '正在上传到设备';

  @override
  String get starting => '正在启动';

  @override
  String get completedOnDevice => '已在设备上完成';

  @override
  String get deviceRejected => '设备未接受该序列';

  @override
  String get linkLostCarriesOn => '链路丢失 · 设备继续执行';

  @override
  String get stoppedDisconnected => '已停止：连接断开';

  @override
  String get stoppedTookControl => '已停止：你接管了操控';

  @override
  String get stoppedManual => '已停止：手动操控';

  @override
  String get stoppedByScript => '已被脚本停止';

  @override
  String get reqAnyDevice => '设备';

  @override
  String reqKinds(String kinds) {
    return '$kinds';
  }

  @override
  String reqWith(String kinds, String needs) {
    return '带有 $needs 的$kinds';
  }

  @override
  String reqWrongKind(String name, String kind, String needs) {
    return '$name 是$kind；此脚本需要 $needs。';
  }

  @override
  String reqLacks(String name, String lacks, String needs) {
    return '$name 没有 $lacks；此脚本需要 $needs。';
  }

  @override
  String get trgButton => '按钮';

  @override
  String get trgSwitch => '开关';

  @override
  String get trgSlider => '滑块';

  @override
  String get trgController => '手柄';

  @override
  String get trgCondition => '条件';

  @override
  String get trgEvent => '设备事件';

  @override
  String get trgTimer => '定时器';

  @override
  String get evMode => '模式变化';

  @override
  String get evFailsafe => '失控保护';

  @override
  String get evSeqDone => '序列结束';

  @override
  String get evLog => '设备消息';

  @override
  String get onControl => '在操控页面';

  @override
  String everyN(String seconds) {
    return '每 $seconds 秒';
  }

  @override
  String onceAfterN(String seconds) {
    return '$seconds 秒后一次';
  }

  @override
  String get paArm => '解锁 / 上锁';

  @override
  String get paManual => '手动';

  @override
  String get paHold => '保持';

  @override
  String get paAuto => '交还给脚本';

  @override
  String get paSlower => '减速';

  @override
  String get paFaster => '加速';

  @override
  String get paFrame => '关节 / 笛卡尔';

  @override
  String get paWrist => '手腕';

  @override
  String get paNext => '下一台设备';

  @override
  String get paStopHint => '紧急停止，立即生效';

  @override
  String get paHoldHint => '按住一秒';

  @override
  String paSwitchTo(String mode) {
    return '切换到 $mode';
  }

  @override
  String get paAutoHint => '接管后，将摇杆交还给脚本（AUTO）';

  @override
  String paSwitchToDrones(String mode) {
    return '切换到 $mode（无人机）';
  }

  @override
  String get paHoldDronesHint => '按住一秒（无人机）';

  @override
  String get paRecordHint => '开始或停止录制';

  @override
  String get paSlowerHint => '速度限制降低 10 %';

  @override
  String get paFasterHint => '速度限制提高 10 %';

  @override
  String get paFrameHint => '机械臂：摇杆控制的对象';

  @override
  String get paWristHint => '机械臂：右摇杆控制 J5 和 J6，而不是 J3 和 J4';

  @override
  String get paGripperHint => '机械臂：张开或闭合';

  @override
  String get paNextHint => '连接多台时：显示并操控下一台';

  @override
  String get notSet => '未设置';

  @override
  String get padLeftStickX => '左摇杆 X';

  @override
  String get padLeftStickY => '左摇杆 Y';

  @override
  String get padRightStickX => '右摇杆 X';

  @override
  String get padRightStickY => '右摇杆 Y';

  @override
  String get padLeftTrigger => '左扳机';

  @override
  String get padRightTrigger => '右扳机';

  @override
  String get padACross => 'A / ×';

  @override
  String get padBCircle => 'B / ○';

  @override
  String get padXSquare => 'X / □';

  @override
  String get padYTriangle => 'Y / △';

  @override
  String get padLeftBumper => '左肩键';

  @override
  String get padRightBumper => '右肩键';

  @override
  String get padBackShare => 'Back / Share';

  @override
  String get padStartOptions => 'Start / Options';

  @override
  String get padHome => 'Home';

  @override
  String get padLeftStickPress => '左摇杆按下';

  @override
  String get padRightStickPress => '右摇杆按下';

  @override
  String get padDPadUp => '方向键上';

  @override
  String get padDPadDown => '方向键下';

  @override
  String get padDPadLeft => '方向键左';

  @override
  String get padDPadRight => '方向键右';

  @override
  String get radioSik => 'SiK 数传电台';

  @override
  String get radioLoraName => 'LoRa 地面站';

  @override
  String get radioOther => '其他串口电台';

  @override
  String get radioSikDesc => '433 / 868 / 915 MHz 成对电台：3DR、Holybro、RFD900。透明串口，约 1 km，RFD900 可达 40 km。';

  @override
  String get radioLoraDesc => 'USB 连接、带 LoRa 电台并烧录了地面站程序的板子。2 到 10 km，仅遥测。';

  @override
  String get radioHc12Desc => '装在 USB 适配器上的廉价透明串口模块。9600 baud 下约 1 km。';

  @override
  String get radioXbeeDesc => '在 USB 扩展板上以透明模式工作的 Digi XBee。2.4 GHz 或 900 MHz。';

  @override
  String get radioOtherDesc => '任何透明串口电台。设置其波特率；应用使用保守的速率。';

  @override
  String get tplLoop => '控制循环';

  @override
  String get tplButton => '按钮操作';

  @override
  String get fldBattery => '电池';

  @override
  String get fldBatteryVoltage => '电池电压';

  @override
  String get fldDistanceFromHome => '距返航点距离';

  @override
  String get fldHeightAboveHome => '相对返航点高度';

  @override
  String get fldSpeed => '速度';

  @override
  String get fldHeading => '航向';

  @override
  String get fldRoll => '横滚';

  @override
  String get fldPitch => '俯仰';

  @override
  String get fldGripper => '夹爪';

  @override
  String get fldThrust => '推力';

  @override
  String get fldRpm => 'RPM';

  @override
  String get fldTemperature => '温度';

  @override
  String get fldNearestObstacle => '最近障碍物';

  @override
  String get fldSignal => '信号';

  @override
  String get fldLatency => '延迟';

  @override
  String get fldGpsSatellites => 'GPS 卫星';

  @override
  String get ready => '就绪。';

  @override
  String get pythonManaged => '此 Python 由系统管理，拒绝安装包：请改用脚本环境。';

  @override
  String failedWhy(String why) {
    return '失败：$why';
  }

  @override
  String get pipNoPackage => 'pip 已完成，但此 Python 中仍然没有 koebelt-dash-scripts。';

  @override
  String packageUpToDate(String version) {
    return '此 Python 中的 koebelt-dash-scripts $version 已是最新。';
  }

  @override
  String packageInstalled(String version) {
    return 'koebelt-dash-scripts $version 已安装到此 Python。';
  }

  @override
  String packagesInstalled(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$names 已安装到此 Python。', one: '$names 已安装到此 Python。');
    return '$_temp0';
  }

  @override
  String envReady(String version) {
    return '脚本环境已就绪，含 koebelt-dash-scripts $version。';
  }

  @override
  String atMostDevices(int count) {
    return '最多同时连接 $count 台设备。请先断开一台。';
  }

  @override
  String noAnswerFrom(String name) {
    return '$name 没有响应';
  }

  @override
  String noHostAt(String address) {
    return '$address 上没有脚本主机。那里在运行 `koebelt-dash-scripts host` 吗？';
  }

  @override
  String get hostRefused => '主机拒绝了。';

  @override
  String get logUnknown => '此文件不是应用能读取的日志。可打开 koebelt/dash JSON 导出、ArduPilot .bin 和 .tlog 日志，以及 PX4 .ulg 日志。';

  @override
  String logEmpty(String format) {
    return '此 $format 文件没有应用可显示的遥测（姿态、位置、电池）。';
  }

  @override
  String get logJsonUnreadable => '无法读取此 JSON 文件。';

  @override
  String get logJsonNotExport => '此 JSON 文件不是 koebelt/dash 的录制导出。';

  @override
  String get logNoHeartbeat => '此 .tlog 没有飞行器心跳，因此无法确定消息属于哪个飞行器。';

  @override
  String get viewDevices => '查看设备';

  @override
  String get simulatedTip => '在应用中模拟，不是真实硬件';

  @override
  String get newShort => '新';
}
