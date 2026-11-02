// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navLive => 'ライブ';

  @override
  String get navControl => '操縦';

  @override
  String get navAutomate => '自動化';

  @override
  String get navTune => 'パラメータ';

  @override
  String get navReplay => 'リプレイ';

  @override
  String get navDevices => 'デバイス';

  @override
  String get navGuides => 'ガイド';

  @override
  String get navSettings => '設定';

  @override
  String get navSequences => 'シーケンス';

  @override
  String get navScripts => 'スクリプト';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageDesc => 'アプリの言語。';

  @override
  String get translationNote => 'この翻訳は AI で作成されており、誤りを含む可能性があります。修正は GitHub リポジトリで歓迎しています。';

  @override
  String get translationContribute => 'GitHub で貢献する';

  @override
  String settingsLanguageSystem(String name) {
    return 'システムと同じ（$name）';
  }

  @override
  String toastSaved(String name) {
    return '$name として保存しました';
  }

  @override
  String get stopEngagedBar => '停止中 · タップして解除';

  @override
  String get stopEngagedTitle => '緊急停止中';

  @override
  String get stopKeep => '停止したままにする';

  @override
  String get stopResetAll => 'すべて解除';

  @override
  String get stopReset => '停止を解除';

  @override
  String stopBody(String names) {
    return '$names のモーターは停止し、すべての動作コマンドがブロックされています。';
  }

  @override
  String get theDevice => 'デバイス';

  @override
  String get stopCheck => '解除する前にデバイスを確認してください。解除後も、再びアームするまでディスアーム状態のままです。';

  @override
  String get fleet => 'フリート';

  @override
  String get tagSim => 'SIM';

  @override
  String get fleetActive => 'アクティブ';

  @override
  String get fleetLost => '切断';

  @override
  String get fleetLinked => '接続中';

  @override
  String get fleetOff => 'オフ';

  @override
  String get fleetOn => 'オン';

  @override
  String get connecting => '接続中';

  @override
  String get noLink => 'リンクなし';

  @override
  String get simulated => 'シミュレーション';

  @override
  String get statLink => 'リンク';

  @override
  String get statLost => '切断';

  @override
  String get statLatency => 'レイテンシ';

  @override
  String get statBattery => 'バッテリー';

  @override
  String get statRecording => '録画中';

  @override
  String get armed => 'アーム';

  @override
  String get disarmed => 'ディスアーム';

  @override
  String stopLabelAll(int count) {
    return '緊急停止（$count 台すべて）';
  }

  @override
  String get stopLabel => '緊急停止';

  @override
  String stopTipAll(int count) {
    return '接続中の $count 台をすべて停止します';
  }

  @override
  String get stopTipSlowRadio => 'このテレメトリ専用無線でも STOP は送られますが、遅く、最大 1 秒かかります';

  @override
  String get stopAll => 'すべて停止';

  @override
  String get stop => '停止';

  @override
  String get failsafeHold => '位置を保持中';

  @override
  String get failsafeRth => 'ホームへ帰還中';

  @override
  String get failsafeLand => 'その場で着陸中';

  @override
  String linkLostFor(String seconds) {
    return 'リンク切断 · $seconds 秒';
  }

  @override
  String failsafeActive(String action) {
    return 'フェイルセーフ作動：$action。';
  }

  @override
  String get reconnecting => '再接続中。フェイルセーフは 1.8 秒で作動します。';

  @override
  String get controlsLocked => 'リンクが戻るまで操縦はロックされます。';

  @override
  String get linkRestored => 'リンク復帰';

  @override
  String get linkRestoredBody => '手動操縦が再び使えます。';

  @override
  String alertBelow(String limit) {
    return '$limit 未満。';
  }

  @override
  String alertAbove(String limit) {
    return '$limit 超過。';
  }

  @override
  String get linkLostOther => '1.8 秒後にこのデバイスのフェイルセーフが作動します。';

  @override
  String get compatNewerApp => '新しいアプリが必要です';

  @override
  String get compatOldLib => 'ライブラリが古すぎます';

  @override
  String compatSome(String why) {
    return '一部の機能が動作しない可能性があります：$why。';
  }

  @override
  String get compatUpdateApp => 'koebelt dash を更新してください。';

  @override
  String get compatUpdateLib => 'デバイスの koebelt/link ライブラリを更新するか、設定 > アップデート で古い koebelt dash をインストールしてください。';

  @override
  String get show => '表示';

  @override
  String alerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'アラート $count 件', one: 'アラート 1 件');
    return '$_temp0';
  }

  @override
  String get linkLost => 'リンク切断';

  @override
  String get replayOffControl => 'リプレイ中は操縦できません';

  @override
  String get replayOffControlWhy => '操縦は接続中のデバイスに対して行われ、録画には作用しません。';

  @override
  String get replayOffSequences => 'リプレイ中はシーケンスを使えません';

  @override
  String get replayOffSequencesWhy => 'シーケンスは接続中のデバイスで実行され、録画では実行されません。';

  @override
  String get replayOffTune => 'リプレイ中は調整できません';

  @override
  String get replayOffTuneWhy => 'パラメータは接続中のデバイスで読み書きされ、録画では読み書きされません。';

  @override
  String replayExitTo(String name) {
    return 'リプレイを終了して $name に戻ります。';
  }

  @override
  String get replayExitConnect => 'リプレイを終了してから、デバイスを接続してください。';

  @override
  String get replayBack => 'リプレイに戻る';

  @override
  String replayExitBackTo(String name) {
    return 'リプレイを終了して $name に戻る';
  }

  @override
  String get replayExit => 'リプレイを終了';

  @override
  String get notConnected => '未接続';

  @override
  String get noDeviceTitle => 'デバイスが接続されていません';

  @override
  String get noDeviceBody => 'ペアリング済みのデバイスを選ぶか、新しくペアリングしてください。リンクがつながるとテレメトリと操縦が表示されます。';

  @override
  String get connectFailed => '接続できませんでした';

  @override
  String get noPairedDevices => 'ペアリング済みのデバイスはまだありません。';

  @override
  String get offline => 'オフライン';

  @override
  String batteryPct(int pct) {
    return 'バッテリー $pct%';
  }

  @override
  String get connect => '接続';

  @override
  String get pairNewDevice => '新しいデバイスをペアリング';

  @override
  String get or => 'または';

  @override
  String get addSimulated => 'シミュレーションのデバイスを追加';

  @override
  String get addSimulatedDesc => '仮想のドローン、ローバー、アーム、ロケット、テストベンチで、ハードウェアなしでアプリを試せます。';

  @override
  String get openRecording => '録画を開く';

  @override
  String get openRecordingDesc => 'セッション、フライトログ、サンプル録画を再生します。';

  @override
  String get setUpLibrary => 'ライブラリを設定';

  @override
  String get setUpLibraryDesc => 'Arduino、Python、ROS 2、Rust のプロジェクトに koebelt/link を追加します。';

  @override
  String get noDevice => 'デバイスなし';

  @override
  String get tagDemo => 'デモ';

  @override
  String moreConnected(int count) {
    return '+$count 台接続中';
  }

  @override
  String get alsoConnected => '他に接続中';

  @override
  String get disconnectAll => 'すべて切断';

  @override
  String get connectAnother => '別のデバイスを接続';

  @override
  String get pairedDevices => 'ペアリング済みのデバイス';

  @override
  String get noPairedDevicesShort => 'ペアリング済みのデバイスなし';

  @override
  String get noPairedDevicesHint => 'ペアリングするか、シミュレーションのデバイスを追加するか、クイックスタートに従ってください。';

  @override
  String get pairDevice => 'ペアリング';

  @override
  String get quickstart => 'クイックスタート';

  @override
  String get manage => '管理';

  @override
  String get replaying => 'リプレイ中';

  @override
  String get closeReplay => 'リプレイを閉じる';

  @override
  String get simulator => 'シミュレーター';

  @override
  String get disconnect => '切断';

  @override
  String get open => '開く';

  @override
  String get sequenceRunning => 'シーケンス実行中';

  @override
  String disconnectName(String name) {
    return '$name を切断';
  }

  @override
  String get automateSeqBlurb => 'コード不要の順番どおりのステップ：離陸、移動、待機、着陸、走行、ポーズへ移動。';

  @override
  String get automateSeqPoint1 => 'コード不要：アプリ内で作成';

  @override
  String get automateSeqPoint2 => '保存できるデバイスではデバイス上で実行';

  @override
  String get automateSeqPoint3 => 'リンクが切れても続行';

  @override
  String get automateSeqConnect => 'デバイスを接続するとシーケンスを作れます';

  @override
  String automateSeqCount(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 件', zero: 'なし');
    return '$name のシーケンス $_temp0';
  }

  @override
  String get automateScriptBlurb => 'テレメトリとカメラを読み取り、判断し、デバイスを操縦する Python。';

  @override
  String get automateScriptPoint1 => 'ロジック、センサー、カメラ';

  @override
  String get automateScriptPoint2 => 'どんなパッケージでも：OpenCV、PyTorch、YOLO';

  @override
  String get automateScriptPoint3 => 'トリガー：ボタン、キー、条件、タイマー';

  @override
  String get automateScriptPoint3Host => 'スクリプトホスト（ネットワーク上のコンピューター）で実行';

  @override
  String scriptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'スクリプト $count 件', zero: 'スクリプトなし');
    return '$_temp0';
  }

  @override
  String get automateEyebrow => '自動化の 2 つの方法';

  @override
  String runningOn(String what, String device) {
    return '$device の $what';
  }

  @override
  String get automateTogether1 => '組み合わせ：スクリプトは ';

  @override
  String get automateTogether2 => 'でシーケンスを開始し、そのタイミングを判断できます。';

  @override
  String get sequenceOrScript => 'シーケンスかスクリプトか？';

  @override
  String get running => '実行中';

  @override
  String get layoutHud => 'HUD';

  @override
  String get layoutWall => 'WALL';

  @override
  String get editLayout => 'レイアウトを編集';

  @override
  String get sceneLayers3d => '3D シーンのレイヤー';

  @override
  String get layerCloud => '点群';

  @override
  String get layerTrail => '軌跡';

  @override
  String get layerRadar => 'レーダートラック';

  @override
  String get layerGrid => '地面グリッド';

  @override
  String get sceneLayers => 'シーンのレイヤー';

  @override
  String get addWidget => 'ウィジェットを追加';

  @override
  String widgetsSavedFor(String device, String screens) {
    return 'ウィジェットは $device の$screens画面ごとに保存されます。';
  }

  @override
  String get thisDevice => 'このデバイス';

  @override
  String get screenPhone => 'スマートフォン';

  @override
  String get screenShort => '横向きスマートフォン';

  @override
  String get screenPortrait => '縦向きタブレット';

  @override
  String get screenTablet => 'タブレット';

  @override
  String get screenDesktop => 'デスクトップ';

  @override
  String get reset => 'リセット';

  @override
  String get cancel => 'キャンセル';

  @override
  String get saveLayout => 'レイアウトを保存';

  @override
  String get back => '戻る';

  @override
  String get paused => '一時停止中';

  @override
  String get stale => '古いデータ';

  @override
  String hzLive(int hz) {
    return '$hz Hz ライブ';
  }

  @override
  String get resume => '再開';

  @override
  String get pause => '一時停止';

  @override
  String get statMin => '最小';

  @override
  String get statMax => '最大';

  @override
  String get statMean => '平均';

  @override
  String get unit => '単位';

  @override
  String get window => '期間';

  @override
  String get windowValue => '10 秒 · 300 サンプル';

  @override
  String get source => 'ソース';

  @override
  String get tapChannelToHide => 'チャンネルをタップして非表示';

  @override
  String get rec => 'REC';

  @override
  String get speedLimit => '速度制限';

  @override
  String get setHomePose => 'ホームポーズを設定';

  @override
  String get setHomeHere => 'ここをホームに設定';

  @override
  String get useThisPose => 'このポーズを使う';

  @override
  String get setHome => 'ホームを設定';

  @override
  String get setHomePoseBody => '現在の関節角度が、ホームポーズとシーケンスのホームステップで移動するポーズになります。';

  @override
  String setHomeBody(String metres) {
    return '現在位置がホーム (0, 0) になります。ホームへの帰還はここに戻り、シーケンスのウェイポイントはここから測られます。デバイスは現在のホームから $metres m の位置にあります。';
  }

  @override
  String get autoDashDrives => 'dash が操縦中';

  @override
  String get autoTakeBack => 'MANUAL か HOLD を選ぶか、スティックを動かすと操縦を取り戻せます。';

  @override
  String get autoTip => 'dash のモード：シーケンスやスクリプトがデバイスを操縦している間です。自動化から実行してください。';

  @override
  String get tiltDrag => 'チルト · ドラッグでシミュレート';

  @override
  String get stickThrottle => 'スロットル';

  @override
  String get stickDrive => '前進';

  @override
  String get stickYaw => 'ヨー';

  @override
  String get stickPitchRoll => 'ピッチ · ロール';

  @override
  String get stickSteer => 'ステア';

  @override
  String get stickThrottleYaw => 'スロットル · ヨー';

  @override
  String get tiltPitchRoll => 'チルト · ピッチとロール';

  @override
  String get tiltSteerDrive => 'チルト · ステアと前進';

  @override
  String get axUp => '上';

  @override
  String get axDn => '下';

  @override
  String get axFwd => '前';

  @override
  String get axRev => '後';

  @override
  String get axBack => '後';

  @override
  String get axL => '左';

  @override
  String get axR => '右';

  @override
  String get axYaw => 'ヨー';

  @override
  String get rdAlt => '高度';

  @override
  String get rdOdom => '走行距離';

  @override
  String get rdSpeed => '速度';

  @override
  String get rdHdg => '方位';

  @override
  String get rdHome => 'ホーム';

  @override
  String get rdVz => 'Vz';

  @override
  String get rdMax => '最大';

  @override
  String get rdRange => '距離';

  @override
  String get rdToolX => 'ツール X';

  @override
  String get rdToolY => 'ツール Y';

  @override
  String get rdToolZ => 'ツール Z';

  @override
  String get rdThrust => '推力';

  @override
  String get rdRpm => 'RPM';

  @override
  String get rdCurrent => '電流';

  @override
  String get rdPower => '電力';

  @override
  String get rdTemp => '温度';

  @override
  String get rdEfficiency => '効率';

  @override
  String get homePose => 'ホームポーズ';

  @override
  String get setAsHome => 'ホームに設定';

  @override
  String get armJoint => '関節';

  @override
  String get armCartesian => '直交';

  @override
  String get toolFrame => 'ツール座標系 · ベース基準';

  @override
  String armPadHelp(String frame, String wristBtn, String wrist, String gripper) {
    return 'コントローラー · $frame：関節 / 直交 · $wristBtn：$wrist · $gripper：グリッパー';
  }

  @override
  String get armWrist => '手首';

  @override
  String get gripper => 'グリッパー';

  @override
  String gripperOpenPct(int pct) {
    return '$pct% 開';
  }

  @override
  String get gripperOpen => '開く';

  @override
  String get gripperClose => '閉じる';

  @override
  String get flightPhase => '飛行フェーズ';

  @override
  String get phasePad => 'ランチパッド上';

  @override
  String get phaseCount => 'カウントダウン';

  @override
  String get phaseBoost => 'ブースト';

  @override
  String get phaseCoast => '慣性飛行';

  @override
  String get phaseDrogue => 'ドローグ';

  @override
  String get phaseMain => 'メイン';

  @override
  String get phaseLanded => '着地';

  @override
  String get preflight => '飛行前';

  @override
  String get checkPyro => 'パイロ導通 · ドローグ、メイン';

  @override
  String get ok => 'OK';

  @override
  String get check => '確認';

  @override
  String get checkGps => 'GPS 測位';

  @override
  String sats(int count) {
    return '$count 衛星';
  }

  @override
  String get noFix => '測位なし';

  @override
  String get checkFlightComputer => 'フライトコンピューター';

  @override
  String get safe => '安全';

  @override
  String get armFlightComputer => 'フライトコンピューターをアーム';

  @override
  String get armPadClear => 'パッド周囲が安全なときだけアームしてください';

  @override
  String startCountdown(String seconds) {
    return 'カウントダウン開始 · $seconds 秒';
  }

  @override
  String get abortLaunch => '打ち上げ中止';

  @override
  String get deployDrogue => 'ドローグ展開';

  @override
  String get deployMain => 'メイン展開';

  @override
  String autoDeploy(String metres) {
    return '自動展開 · 頂点でドローグ · $metres m でメイン';
  }

  @override
  String landedBody(String apogee, String distance) {
    return '最高到達点 $apogee m · パッドから $distance m に着地。';
  }

  @override
  String get resetToPad => 'パッドに戻す';

  @override
  String get altitude => '高度';

  @override
  String get cutoff => 'カットオフ';

  @override
  String get cutoffLimit => '制限';

  @override
  String get cutoffBody => 'スロットルを 0 にしました。再実行する前にモーターを確認してください。';

  @override
  String get clear => 'クリア';

  @override
  String get benchDisarmed => 'モーターを回すにはベンチをアームしてください。プロペラから離れてください。';

  @override
  String get testSequence => 'テストシーケンス';

  @override
  String get benchRamp => 'ランプ';

  @override
  String get benchSteps => 'ステップ';

  @override
  String get runAndRecord => '実行して録画';

  @override
  String benchRampDesc(String seconds) {
    return '0 から 100% まで $seconds 秒でランプ、2 秒保持、停止。';
  }

  @override
  String benchStepsDesc(String size, String seconds) {
    return '$size% ずつ、各 $seconds 秒、100% まで。';
  }

  @override
  String benchLimits(String amps, String celsius) {
    return '制限：$amps A、$celsius °C。';
  }

  @override
  String get mspTitle => '監視とチューニング';

  @override
  String mspBody(String name, String firmware) {
    return '$name は $firmware で動作し、設定用リンクの MSP で接続されています。アプリはテレメトリを表示し、パラメータ画面で PID ゲインを調整し、STOP でディスアームします。飛行は RC 送信機で行ってください。';
  }

  @override
  String get radioOnlyTitle => 'テレメトリ専用リンク';

  @override
  String radioOnlyBody(String name, String radio) {
    return '$name は $radio 経由で接続されていますが、これはテレメトリしか送れません。スティック、モード、コマンドはこの経路ではデバイスに届きません。STOP は約 1 秒で届きます。メインのリンク（Wi-Fi、Bluetooth、SiK 無線）で操縦し、そのリンクが圏外のときはフェイルセーフに任せてください。';
  }

  @override
  String get aRadio => '無線';

  @override
  String get tileReadouts => '計測値';

  @override
  String get tileSrcFused => '融合状態';

  @override
  String get tileAttitude => '姿勢';

  @override
  String get tileAccelerometer => '加速度計';

  @override
  String get tileGyroscope => 'ジャイロスコープ';

  @override
  String get tileSrcBaroRange => '気圧 + 距離計';

  @override
  String get tileRadar => 'レーダー';

  @override
  String get tileSrcRadar => 'レーダー / 安全スキャナー';

  @override
  String get tileLidar => 'LiDAR';

  @override
  String get tileSrcLidar => 'スキャン式 LiDAR';

  @override
  String get tileJoints => '関節';

  @override
  String get tileSrcJoints => '関節エンコーダー';

  @override
  String get tileForceTorque => '力 / トルク';

  @override
  String get tileSrcWrist => '手首の力覚センサー';

  @override
  String get tileSrcPower => '電源モジュール';

  @override
  String get tileSrcRadio => '無線リンク';

  @override
  String get tileCamera => 'カメラ';

  @override
  String get tileSrcCamera => 'デバイスのカメラ · MJPEG';

  @override
  String get tileSrcFleet => '接続中のすべてのデバイス';

  @override
  String get tileSrcPhase => 'フライトコンピューターのステートマシン';

  @override
  String get tileVerticalSpeed => '垂直速度';

  @override
  String get tileSrcBaroImu => '気圧 + IMU 融合';

  @override
  String get tilePyro => 'パイロチャンネル';

  @override
  String get tileSrcPyro => '4 チャンネルパイロ基板';

  @override
  String get tileSrcTacho => '光学タコメーター';

  @override
  String get tileTorque => 'トルク';

  @override
  String get tileSrcTorque => '反力トルクセル';

  @override
  String get tileMotorTemp => 'モーター温度';

  @override
  String get tileSrcNtc => 'NTC サーミスター';

  @override
  String get tileRollRate => 'ロールレート';

  @override
  String get tilePitchRate => 'ピッチレート';

  @override
  String get tileYawRate => 'ヨーレート';

  @override
  String get tileGroundSpeed => '対地速度';

  @override
  String get tileAgl => '対地高度';

  @override
  String get tileOwnSpeed => '自己速度';

  @override
  String get tileVoltage => '電圧';

  @override
  String get tilePyroBus => 'パイロバス';

  @override
  String get tileStator => 'ステーター';

  @override
  String get tileVibration => '振動';

  @override
  String get tileAcc200 => '加速度計 · 200 G';

  @override
  String get tileSafetyScanner => '安全スキャナー';

  @override
  String tracks(int count) {
    return '$count トラック';
  }

  @override
  String points(int count) {
    return '$count 点';
  }

  @override
  String axes(int count) {
    return '$count 軸';
  }

  @override
  String connectedCount(int count) {
    return '$count 台接続中';
  }

  @override
  String armedCount(int count) {
    return '$count アーム済み';
  }

  @override
  String get proxClear => '障害物なし';

  @override
  String get tileProximity => '近接';

  @override
  String get tileSrcProx => '近接センサー';

  @override
  String tileSrcCustom(String hz) {
    return 'カスタムチャンネル · $hz Hz';
  }

  @override
  String get tagScript => 'スクリプト';

  @override
  String get viewEnded => '終了';

  @override
  String series(int count) {
    return '$count 系列';
  }

  @override
  String get rdReach => '到達距離';

  @override
  String get pyroDrogue => 'ドローグ';

  @override
  String get pyroMain => 'メイン';

  @override
  String get pyroAirstart => '空中点火';

  @override
  String get pyroSpare => '予備';

  @override
  String get pyroContinuity => '導通';

  @override
  String get pyroFired => '発火済み';

  @override
  String get pyroNotWired => '未配線';

  @override
  String removeTitle(String name) {
    return '$name を削除しますか？';
  }

  @override
  String get removeDevice => 'デバイスを削除';

  @override
  String removeBody(String name) {
    return '$name のペアリングキー、HUD レイアウト、パラメータの下書きがこのアプリから削除されます。';
  }

  @override
  String get removeDisconnectFirst => '先に切断されます。';

  @override
  String get removeKept => '録画は残ります。このデバイスを再び使うには、新しいコードでペアリングしてください。';

  @override
  String onlineOf(int online, int total) {
    return '$total 台中 $online 台がオンライン';
  }

  @override
  String get devicesEmptyHint => 'デバイスをペアリングするか、クイックスタートに従ってプロジェクトにライブラリを追加してください。';

  @override
  String get devicesSeveral => '複数のデバイスを同時に接続できます。表示中のデバイスがスティックを受け取り、他はスティック中央で停止し、STOP ですべて止まります。';

  @override
  String get connected => '接続済み';

  @override
  String removeName(String name) {
    return '$name を削除';
  }

  @override
  String get online => 'オンライン';

  @override
  String get batShort => 'BAT';

  @override
  String get myRobot => 'マイロボット';

  @override
  String radioNothingHeard(String port, int baud) {
    return '$port（$baud baud）で何も受信しませんでした。デバイスの電源、両方の無線のチャンネルと無線速度、ボーレートが合っているか確認してください。リンクを追加して後で接続することもできます。';
  }

  @override
  String get pairTitle => 'デバイスをペアリング';

  @override
  String get pairNearby => '近く';

  @override
  String get pairRadio => '無線';

  @override
  String get pairSimulated => 'シミュレーション';

  @override
  String get pairSimulatedIntro => 'シミュレーションのデバイスはアプリ内で動作し、実機と同じプロトコルで通信します。必要なものだけ追加してください。それぞれ SIM タグ付きで表示されます。';

  @override
  String get added => '追加済み';

  @override
  String get addAnother => 'もう 1 台追加';

  @override
  String get add => '追加';

  @override
  String radioRatesTlm(int tlm) {
    return 'テレメトリ $tlm Hz · 操縦なし';
  }

  @override
  String radioRates(int tlm, int ctl) {
    return 'テレメトリ $tlm Hz · 操縦 $ctl Hz';
  }

  @override
  String get radioIntro => '無線リンクとは、このコンピューターやスマートフォンに USB で接続した無線モデムが、デバイス側の対になる無線と通信するものです。';

  @override
  String get radioIntroMore => 'アプリからはシリアルポートとして見え、無線の種類によって速度と送れる量が決まります。';

  @override
  String get radioNoSerial => 'このプラットフォームには USB シリアルがありません';

  @override
  String get radioNoSerialBody => 'iOS アプリは USB シリアルアダプターを開けません。無線リンクには Android、macOS、Windows、Linux のアプリを使うか、Wi-Fi か Bluetooth で接続してください。';

  @override
  String get radioLora => 'LoRa モジュール単体は USB デバイスではありません。LoRa ガイドの地上局スケッチを無線付きの 2 枚目のボードに書き込み、そのボードを接続してください。';

  @override
  String get usbPort => 'USB ポート';

  @override
  String get refresh => '更新';

  @override
  String get noSerialPorts => 'シリアルポートが見つかりません。無線の USB アダプターを接続してください。';

  @override
  String get baudRate => 'ボーレート';

  @override
  String heard(String name) {
    return '$name を受信';
  }

  @override
  String get heardMavlink => 'MAVLink で通信します。ペアリングは不要です。';

  @override
  String get heardPairing => 'ペアリングモードなので、キーを受け取ります。';

  @override
  String get heardNoPairing => 'ペアリングモードではないため、キーなしで追加されます。';

  @override
  String get listening => '受信待ち';

  @override
  String get listenForDevice => 'デバイスを受信待ち';

  @override
  String pairName(String name) {
    return '$name をペアリング';
  }

  @override
  String get addRadioLink => '無線リンクを追加';

  @override
  String get pairNearbyIntro => 'ボードを接続するか電源を入れてください。フライトコントローラーとドローンは自動で表示されます。koebelt/link ライブラリを使うボードもペアリングモード中はここに表示されます。';

  @override
  String get scanning => 'Wi-Fi、Bluetooth、USB ボードを検索中…';

  @override
  String get stillScanning => 'さらにデバイスを検索中…';

  @override
  String get addByIp => 'IP アドレスで追加';

  @override
  String get name => '名前';

  @override
  String get mavlinkPortNote => 'アプリは一般的な地上局と同じく UDP 14550 で待ち受けます。ポートはわかれば機体側のものを指定します。';

  @override
  String get addDevice => 'デバイスを追加';

  @override
  String get notShowingUp => 'デバイスが表示されませんか？ ArduPilot、PX4、Betaflight、INAV のボードはそのまま接続できます。それ以外は koebelt/link ライブラリが必要です。';

  @override
  String get openQuickstart => 'クイックスタートを開く';

  @override
  String get orLower => 'または';

  @override
  String get addItByIp => 'IP アドレスで追加';

  @override
  String get secControl => '操縦';

  @override
  String get secController => 'ゲームコントローラー';

  @override
  String get secLink => 'リンクと安全';

  @override
  String get secRecording => '録画';

  @override
  String get secAlerts => 'アラート';

  @override
  String get secMap => '地図';

  @override
  String get secPairing => 'ペアリング';

  @override
  String get secAi => 'AI アシスタント (MCP)';

  @override
  String get secAiShort => 'AI アシスタント';

  @override
  String get secUpdates => 'アップデート';

  @override
  String get setInput => '入力方法';

  @override
  String get setInputDesc => 'スティック：2 本の仮想ジョイスティック。スライダー：バネ付きのスロットルとヨー、スティック 1 本。チルト：スマートフォンやタブレットを傾けて操縦。';

  @override
  String get csSticks => 'スティック';

  @override
  String get csSliders => 'スライダー';

  @override
  String get csTilt => 'チルト';

  @override
  String get setInvert => 'ピッチを反転';

  @override
  String get setInvertDesc => '前に倒すと機首が上がります。';

  @override
  String get setHaptics => '触覚フィードバック';

  @override
  String get setHapticsDesc => 'スティック中央と警告時に振動します。';

  @override
  String get setLinkLoss => 'リンク切断時';

  @override
  String get setLinkLossDesc => '制御パケットが 1.8 秒途絶えたときのドローンの動作です。地上ロボットとアームは停止、テストベンチはモーターを止め、ロケットは飛行シーケンスを続けます。';

  @override
  String get setRate => 'テレメトリレート';

  @override
  String get setRateDesc => 'レートを上げるほど帯域とバッテリーを使います。';

  @override
  String get setTestFailsafe => 'フェイルセーフをテスト';

  @override
  String get setTestFailsafeDesc => '制御リンクを 6 秒間切断し、設定した動作を確認できます。';

  @override
  String get runTest => 'テストを実行';

  @override
  String get setRecordVideo => 'ビデオを録画';

  @override
  String get setRecordVideoDesc => '各録画にデバイスのカメラを残します。録画中は、どの画面に表示していなくてもカメラは接続されたままです。';

  @override
  String get setVideoFps => 'ビデオのフレームレート';

  @override
  String get setVideoFpsDesc => '1 秒に残す最大フレーム数。640×480 の ESP32-CAM は 10 fps で 1 分あたり約 10 MB です。';

  @override
  String get setAlertSound => 'アラート音';

  @override
  String get setAlertSoundDesc => 'アラート時とリンク切断時に鳴ります。触覚フィードバックがオンのスマートフォンでは代わりに振動します。';

  @override
  String kindsOnly(String kinds) {
    return '$kinds のみ。';
  }

  @override
  String get below => '未満';

  @override
  String get above => '超過';

  @override
  String get setMapTiles => '地図タイル';

  @override
  String get setMapTilesDesc => '地図表示の背景：Mapbox Dark、Outdoors（地形）、Satellite、独自のタイル、またはなし（メートルグリッド）。表示したタイルはしばらくこのデバイスに残ります。';

  @override
  String get mapDark => 'ダーク';

  @override
  String get mapOutdoors => 'アウトドア';

  @override
  String get mapSatellite => '衛星';

  @override
  String get mapCustom => 'カスタム';

  @override
  String get mapNone => 'なし';

  @override
  String get setMapboxToken => 'あなたの Mapbox トークン';

  @override
  String get setMapboxTokenDesc => '任意：自分の Mapbox アカウントの公開トークン (pk.…)。アプリのクォータではなく自分のクォータを使います。';

  @override
  String get setTileUrl => 'タイル URL';

  @override
  String setTileUrlDesc(String z, String x, String y) {
    return '$z、$x、$y を含むテンプレート。たとえば地図プロバイダーの衛星レイヤーとそのキー。プロバイダーの利用規約を守ってください。';
  }

  @override
  String get setAttribution => '帰属表示';

  @override
  String get setAttributionDesc => 'プロバイダーが求めるクレジット。地図上に表示されます。';

  @override
  String get provider => 'プロバイダー';

  @override
  String get setGuides => '連携ガイド';

  @override
  String get setGuidesDesc => 'Arduino、Python、ROS 2、Rust のプロジェクトに koebelt/link ライブラリを追加します。';

  @override
  String scriptHostAt(String address) {
    return '$address のスクリプトホスト';
  }

  @override
  String get forget => '削除';

  @override
  String get setScriptHosts => 'スクリプトホスト';

  @override
  String get setScriptHostsDesc =>
      'このデバイスのためにスクリプトを実行するネットワーク上のコンピューター。Python パッケージは何でも使えます。コンピューターで：pip install koebelt-dash-scripts、次に koebelt-dash-scripts host。';

  @override
  String get setScriptHostsDescPhone =>
      'このスマートフォンのためにスクリプトを実行するネットワーク上のコンピューター。Python パッケージは何でも使えます。コンピューターで：pip install koebelt-dash-scripts、次に koebelt-dash-scripts host。';

  @override
  String get setBeHost => 'スクリプトホストになる';

  @override
  String get setBeHostDesc => 'このネットワーク上のスマートフォンやタブレットのスクリプトを、スクリプトの Python で実行します。';

  @override
  String setBeHostCode(String code) {
    return 'ペアリングコード：$code。スマートフォンは スクリプト > 実行先 > スクリプトホストを追加 でペアリングします。';
  }

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count セッション', one: '1 セッション');
    return '$_temp0';
  }

  @override
  String get import => 'インポート';

  @override
  String get record => '録画';

  @override
  String get noRecordings => '録画はまだありません。接続中のデバイスを録画するか、インポートでファイルやサンプル録画を開いてください。';

  @override
  String get tagNew => '新規';

  @override
  String get tagVideo => 'ビデオ';

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 台', one: '1 台');
    return '$_temp0';
  }

  @override
  String deleteName(String name) {
    return '$name を削除';
  }

  @override
  String exportName(String name) {
    return '$name を書き出す';
  }

  @override
  String get replayEyebrow => '録画と再生';

  @override
  String get sessions => 'セッション';

  @override
  String get export => '書き出し';

  @override
  String get exitToLive => 'ライブに戻る';

  @override
  String get play => '再生';

  @override
  String deleteTitle(String name) {
    return '$name を削除しますか？';
  }

  @override
  String get exportFirst => '先に書き出す';

  @override
  String get delete => '削除';

  @override
  String get deleteRecordingBody => '録画はこのデバイスから削除されます。元に戻せません。';

  @override
  String deleteAllN(int count) {
    return '$count 件すべて削除';
  }

  @override
  String get deleteSessionBody => 'このセッションの全デバイスの録画が、ビデオと一緒にこのデバイスから削除されます。元に戻せません。';

  @override
  String sequenceN(int n) {
    return 'シーケンス $n';
  }

  @override
  String sequencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'シーケンス $count 件', zero: 'シーケンスなし');
    return '$_temp0';
  }

  @override
  String copyOf(String name) {
    return '$name のコピー';
  }

  @override
  String noSequencesFor(String name) {
    return '$name のシーケンスはまだありません。';
  }

  @override
  String sequenceIntro(String examples) {
    return 'シーケンスはステップ（$examples）のリストで、アプリが 1 つずつ実行し、各ステップでデバイスの確認を待ちます。';
  }

  @override
  String get sequenceComplete => 'シーケンス完了';

  @override
  String get sequenceStopped => 'シーケンス停止';

  @override
  String get flightSequence => '飛行シーケンス';

  @override
  String get flightSequenceBody => 'フライトコンピューターが打ち上げ、頂点、回収を機上で処理します。展開はパラメータ画面で設定し、ここのシーケンスはパッドでの点検に使ってください。';

  @override
  String get stepsDrone => '離陸、ウェイポイントへ飛行、待機、着陸';

  @override
  String get stepsRover => 'ウェイポイントへ走行、待機、速度変更';

  @override
  String get stepsArm => 'ポーズへ移動、グリッパーの開閉';

  @override
  String get stepsBench => 'スロットルを保持、2 つのスロットル間をランプ';

  @override
  String get stepsGeneric => '待機、モード設定、コマンド送信';

  @override
  String get whyExitReplay => '実行するにはリプレイを終了';

  @override
  String get whyResetStop => '先に停止を解除';

  @override
  String get whyAddSteps => '先にステップを追加';

  @override
  String get onDevice => 'デバイス上';

  @override
  String get uploading => 'アップロード中';

  @override
  String stepOf(int n, int total) {
    return 'ステップ $n / $total';
  }

  @override
  String get runsOnDevice => 'デバイス上で実行：リンクが切れても続行';

  @override
  String get stopSequence => 'シーケンスを停止';

  @override
  String get stoppedFromApp => 'アプリから停止';

  @override
  String get run => '実行';

  @override
  String stepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ステップ', one: '1 ステップ');
    return '$_temp0';
  }

  @override
  String secondsTimed(String seconds) {
    return '計 $seconds 秒';
  }

  @override
  String get newSequence => '新しいシーケンス';

  @override
  String get duplicate => '複製';

  @override
  String get steps => 'ステップ';

  @override
  String get lockedWhileRunning => '実行中はロック';

  @override
  String get addFirstStep => '下に最初のステップを追加してください。ステップは上から順に実行されます。';

  @override
  String get addStep => 'ステップを追加';

  @override
  String get dragToReorder => 'ドラッグで並べ替え';

  @override
  String get deleteStep => 'ステップを削除';

  @override
  String get useCurrentPosition => '現在位置を使う';

  @override
  String get useCurrentPose => '現在のポーズを使う';

  @override
  String get egDeploy => '例：deploy';

  @override
  String get planTopView => 'プラン · 上面図';

  @override
  String get throttleProfile => 'スロットルプロファイル';

  @override
  String get liveView => 'ライブビュー';

  @override
  String get timeline => 'タイムライン';

  @override
  String get setPoseAsHome => '現在のポーズをホームに';

  @override
  String get planNoteDrone => 'ウェイポイントは離陸地点から東と北へのメートルです。ドローンは次のステップの前に各ポイントで停止します。リンクが切れてもフェイルセーフは有効です。';

  @override
  String get planNoteRover => 'ウェイポイントは出発地点から東と北へのメートルです。ローバーは次のステップの前に各ポイントで停止します。';

  @override
  String planNoteArm(String button) {
    return 'アームを手で動かすかジョグ操作で動かし、「$button」で記録してください。';
  }

  @override
  String get planNoteBench => 'デバイスの電流と温度のカットオフは、シーケンス中も有効です。';

  @override
  String get planNoteGeneric => '各ステップは、デバイスの確認を待ってから次に進みます。';

  @override
  String metreGrid(String metres) {
    return '$metres m グリッド';
  }

  @override
  String get now => '現在';

  @override
  String get and => 'と';

  @override
  String get checkNeedsPython => 'チェックにはこのコンピューターの Python が必要です：スクリプトのページで Python をセットアップ。';

  @override
  String couldNotCheck(String python) {
    return '$python でチェックできませんでした。';
  }

  @override
  String scriptErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'このスクリプトには $count 件のエラーがあります', one: 'このスクリプトにはエラーがあります');
    return '$_temp0';
  }

  @override
  String get runAnyway => 'それでも実行';

  @override
  String get showThem => '表示';

  @override
  String get checkFound => 'チェックで、何かが動く前に止まりそうな箇所が見つかりました：';

  @override
  String lineN(int n) {
    return '$n 行目';
  }

  @override
  String andMore(int count) {
    return 'ほか $count 件';
  }

  @override
  String get installImports => 'このスクリプトがインポートするものをインストールしますか？';

  @override
  String get installAndRun => 'インストールして実行';

  @override
  String missingImports(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names がこの Python にないため、スクリプトはインポートで止まります。',
      one: '$names がこの Python にないため、スクリプトはインポートで止まります。',
    );
    return '$_temp0';
  }

  @override
  String couldNotStart(String error) {
    return '開始できませんでした：$error';
  }

  @override
  String get pythonScripts => 'Python スクリプト';

  @override
  String copiedExample(String file) {
    return 'サンプルをスクリプトの $file にコピーしました。';
  }

  @override
  String couldNotCopyExample(String error) {
    return 'サンプルをコピーできませんでした：$error';
  }

  @override
  String get rename => '名前を変更';

  @override
  String get deleteScriptBody => 'スクリプトフォルダ内の .trash フォルダに移動し、そこから戻せます。';

  @override
  String get error => 'エラー';

  @override
  String get examples => 'サンプル';

  @override
  String get connectedOutside => 'dash の外から接続';

  @override
  String get editing => '編集中';

  @override
  String get saved => '保存済み';

  @override
  String get checkAction => 'チェック';

  @override
  String get checking => 'チェック中…';

  @override
  String get openInEditor => 'エディタで開く';

  @override
  String get newScript => '新しいスクリプト';

  @override
  String get importPyZip => '.py または .zip をインポート';

  @override
  String get noScriptsPlus => 'スクリプトはまだありません。サンプルから始めるか、+ を押してください。';

  @override
  String get scriptsEmpty => 'スクリプトは Python でデバイスを操縦します。作成するか、インポートするか、サンプルから始めてください。';

  @override
  String get edit => '編集';

  @override
  String get share => '共有';

  @override
  String get noScriptsNew => 'スクリプトはまだありません。サンプルから始めるか、新規 を押してください。';

  @override
  String get more => 'その他';

  @override
  String get showInFinder => 'Finder で表示';

  @override
  String get showInFolder => 'フォルダで表示';

  @override
  String get myScript => 'マイスクリプト';

  @override
  String get create => '作成';

  @override
  String get save => '保存';

  @override
  String get device => 'デバイス';

  @override
  String get needs => '必要';

  @override
  String get runsOn => '実行先';

  @override
  String get scriptsRunOnComputer => 'スクリプトはコンピューターで実行されます';

  @override
  String get scriptsRunOnComputerBody => 'このデバイスはスクリプトをスクリプトホストに送ります。同じネットワーク上で koebelt-dash-scripts を実行するコンピューターで、Python パッケージ（OpenCV、PyTorch…）を何でも使えます。';

  @override
  String get addScriptHost => 'スクリプトホストを追加';

  @override
  String get notRunning => '停止中';

  @override
  String get endedError => 'エラーで終了';

  @override
  String get ended => '終了';

  @override
  String get waitingConnect => 'スクリプトの接続を待機中（スクリプト内の connect()）…';

  @override
  String get youHaveSticks => 'スティックはあなたが操作中';

  @override
  String get youHaveSticksBody => 'スティックを動かしたため、スクリプトのスティック入力は無視されます。';

  @override
  String get scriptLostSticks => 'スクリプトがスティックを失いました';

  @override
  String isNotConnected(String name) {
    return '$name は接続されていません';
  }

  @override
  String get connectItOrChoose => '接続するか、上で別のデバイスを選んでください。';

  @override
  String doesNotFit(String name) {
    return '$name はこのスクリプトに合いません';
  }

  @override
  String get chooseOrChangeRequires => '上で別のデバイスを選ぶか、# requires: 行を変更してください。';

  @override
  String get scriptNeedsDevice => 'スクリプトはデバイスを操縦します。先にデバイスを接続してください（デバイス、または上部のデバイスメニュー）。';

  @override
  String get doesNotFitShort => '合いません';

  @override
  String get selectedInDash => 'dash で選択中';

  @override
  String get noneConnected => '接続なし';

  @override
  String get thisComputer => 'このコンピューター';

  @override
  String get lookingForPython => 'Python を検索中…';

  @override
  String get noneFound => '見つかりません';

  @override
  String get noPackage => 'パッケージなし';

  @override
  String get python3Needed => 'Python 3 が必要です';

  @override
  String get python3NeededBody => 'python.org からインストールして、ここに戻ってください。';

  @override
  String get newerLibrary => 'この koebelt dash 向けに、スクリプトが使うライブラリの新しいバージョンが出ています。';

  @override
  String get update => '更新';

  @override
  String get pythonNoAnswer => 'この Python は応答しません';

  @override
  String get packageNotInPython => 'この Python に koebelt-dash-scripts がありません';

  @override
  String pythonNoAnswerBody(String python) {
    return 'dash は $python を実行できませんでした。別のものを選ぶか、スクリプト環境を作成してください。';
  }

  @override
  String get packageNotInPythonBody => 'ここにインストールする（pip install koebelt-dash-scripts）か、dash にスクリプトフォルダ内のスクリプト環境を作成させてください。';

  @override
  String get installHere => 'ここにインストール';

  @override
  String get scriptsEnvironment => 'スクリプト環境';

  @override
  String get checkAgain => '再チェック';

  @override
  String get settingUpPython => 'Python をセットアップ中';

  @override
  String get oneTimeSetup => '初回セットアップ';

  @override
  String get oneTimeSetupBody =>
      'スクリプトには koebelt-dash-scripts パッケージが必要です。dash はスクリプトフォルダに Python 環境（.venv）を作ってそこにインストールできます。自分のパッケージ（OpenCV、PyTorch…）もそこに入ります。';

  @override
  String get setUpPython => 'Python をセットアップ';

  @override
  String packagesMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'パッケージが不足しています', one: 'パッケージが不足しています');
    return '$_temp0';
  }

  @override
  String packagesMissingBody(String modules, String packages) {
    return 'このスクリプトは $modules をインポートしますが、この Python にはありません。そこで止まります。$packages をインストールしますか？';
  }

  @override
  String get installing => 'インストール中…';

  @override
  String get install => 'インストール';

  @override
  String get notNow => '後で';

  @override
  String get dismiss => '閉じる';

  @override
  String get stopScript => 'スクリプトを停止';

  @override
  String get restart => '再起動';

  @override
  String get triggers => 'トリガー';

  @override
  String get triggersEmpty => 'スクリプトにイベントを送るボタン、キー、コントローラーのボタン、条件、タイマー。@dev.trigger(…) で宣言するか、ここで追加してください。';

  @override
  String get limits => '制限';

  @override
  String get maxSpeed => '最高速度';

  @override
  String get geofence => 'ジオフェンス';

  @override
  String get off => 'オフ';

  @override
  String metresFromHome(int metres) {
    return 'ホームから $metres m';
  }

  @override
  String get ceiling => '高度上限';

  @override
  String get armingTakeoff => 'アーム、離陸';

  @override
  String get allowed => '許可';

  @override
  String get notAllowed => '不許可';

  @override
  String get paramWrites => 'パラメータの書き込み';

  @override
  String get fire => '発火';

  @override
  String get notBound => '未割り当て';

  @override
  String get console => 'コンソール';

  @override
  String loopHz(String hz) {
    return 'ループ $hz Hz';
  }

  @override
  String get consoleEmpty => 'print() の出力とエラーがここに表示されます。';

  @override
  String get fromOutside => 'dash の外から';

  @override
  String get valid => '有効';

  @override
  String padTaken(String button, String action) {
    return '$button はコントローラー設定で $action に割り当てられています。その動作が優先されます。';
  }

  @override
  String get forDuration => '継続';

  @override
  String conditionHelp(String fields) {
    return 'フィールド：$fields、mode、armed、デバイス独自のチャンネル（motor_temp.max…）。and、or、not で組み合わせ、待つには「for 3s」を付けます。';
  }

  @override
  String get whenTrue => '真のとき';

  @override
  String get trueAndFalse => '真と偽';

  @override
  String get alsoOnControl => '操縦画面のスティックの横にも表示';

  @override
  String get key => 'キー';

  @override
  String get pressKey => 'キーを押してください…';

  @override
  String pressAnotherKey(String key) {
    return '$key · 別のキーを押すと変更';
  }

  @override
  String get clickThenKey => 'クリックしてからキーを押す';

  @override
  String get noButtonYet => 'ボタン未設定';

  @override
  String get pressButton => 'ボタンを押してください…';

  @override
  String get learn => '学習';

  @override
  String get onlyThisMode => 'このモードのみ（HOLD…）、空ならすべて';

  @override
  String get onlyMessagesContaining => '次を含むメッセージのみ…';

  @override
  String get every => '毎回';

  @override
  String get onceAfter => '一度だけ';

  @override
  String get secondsWord => '秒';

  @override
  String get addTrigger => 'トリガーを追加';

  @override
  String get editTrigger => 'トリガーを編集';

  @override
  String get event => 'イベント';

  @override
  String get eventPlaceholder => 'スクリプトが受け取る名前';

  @override
  String get firedBy => '発火元';

  @override
  String triggerHelp(String event) {
    return 'スクリプトは「$event」をその名前のハンドラーか @dev.on_trigger で受け取ります。条件、イベント、タイマーは dash で動作します。';
  }

  @override
  String get done => '完了';

  @override
  String get limitsHelp => 'スクリプトではなくここで設定します。スクリプトからは変更できません。';

  @override
  String get maximumSpeed => '最高速度';

  @override
  String get maximumSpeedDesc => 'スクリプトのスティック入力はこの値に縮小され、速度制限も上限が設定されます。';

  @override
  String get geofenceDesc => 'ホームからこの距離を超えると、スクリプトはスティックを失い、デバイスは停止します。';

  @override
  String get ceilingDesc => 'この高さを超えたときも同様です（ドローン）。';

  @override
  String get allowArming => 'アームと離陸を許可';

  @override
  String get allowArmingDesc => '許可しない場合、スクリプトはあなたがアームしたデバイスしか動かせません。';

  @override
  String get allowParams => 'パラメータの書き込みを許可';

  @override
  String get allowParamsDesc => 'チューニング用スクリプト向け。デバイスの挙動を変えられます。';

  @override
  String get pairing => 'ペアリング中…';

  @override
  String get pair => 'ペアリング';

  @override
  String get scriptHostIntro => 'スクリプトホストとは、このコンピューターのためにスクリプトを実行する同じネットワーク上のコンピューターです（ノート PC、Raspberry Pi、Jetson…）。そのコンピューターで：';

  @override
  String get scriptHostIntroPhone => 'スクリプトホストとは、このスマートフォンやタブレットのためにスクリプトを実行する同じネットワーク上のコンピューターです（ノート PC、Raspberry Pi、Jetson…）。そのコンピューターで：';

  @override
  String get onTheNetwork => 'ネットワーク上';

  @override
  String get lookingForHosts => 'スクリプトホストを検索中';

  @override
  String get noHostsFound => '見つかりません。下にアドレスを入力してください（`ipconfig getifaddr en0`、`hostname -I` などで表示されます）。';

  @override
  String get lookAgain => '再検索';

  @override
  String get address => 'アドレス';

  @override
  String get pairingCode => 'ペアリングコード';

  @override
  String get pairingCodePlaceholder => 'ABC-123、ホストに表示されます';

  @override
  String updatingPct(int pct) {
    return '更新中 $pct%';
  }

  @override
  String get installingState => 'インストール中';

  @override
  String get appUpdating => 'koebelt dash を更新中';

  @override
  String appAvailable(String version) {
    return 'koebelt dash $version が利用可能です';
  }

  @override
  String get appUpToDate => 'koebelt dash は最新です';

  @override
  String get skipVersion => 'このバージョンをスキップ';

  @override
  String get later => '後で';

  @override
  String downloadingPct(int pct) {
    return 'ダウンロード中 $pct%';
  }

  @override
  String get installAnyway => 'それでもインストール';

  @override
  String get updateAnyway => 'それでも更新';

  @override
  String installVersion(String version) {
    return '$version をインストール';
  }

  @override
  String get updateNow => '今すぐ更新';

  @override
  String youHaveOlder(String version) {
    return 'お使いのバージョンは $version です。これは古いバージョンです。新しいバージョンで作った設定や録画がすべて開けるとは限らず、次のリリースまで新しいバージョンを知らせません。';
  }

  @override
  String youHave(String version) {
    return 'お使いのバージョンは $version です。';
  }

  @override
  String get notFromApp => 'アプリからは不可';

  @override
  String get checkingCompat => 'デバイスとの互換性を確認中…';

  @override
  String get compatUnknown => '互換性不明';

  @override
  String get compatUnknownBody => 'このリリースが対応する koebelt/link のバージョンを読み取れませんでした。';

  @override
  String notCompatibleWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 台のデバイスと互換性がありません', one: '1 台のデバイスと互換性がありません');
    return '$_temp0';
  }

  @override
  String notCompatibleBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '先にそれらのデバイスの koebelt/link ライブラリを更新するか、今のバージョンのまま 設定 > アップデート で別のバージョンを選んでください。',
      one: '先にそのデバイスの koebelt/link ライブラリを更新するか、今のバージョンのまま 設定 > アップデート で別のバージョンを選んでください。',
    );
    return '$_temp0';
  }

  @override
  String get disarmFirst => '先にディスアーム';

  @override
  String get disarmFirstBody => '接続中のデバイスがアームされています。更新するとアプリが閉じてリンクが切れます。ディスアームしてから更新してください。';

  @override
  String get devicesWillDisconnect => 'デバイスが切断されます';

  @override
  String devicesWillDisconnectBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'インストールするとアプリが閉じるため、接続中の $count 台はリンクを失い、再接続するまでフェイルセーフが作動します。',
      one: 'インストールするとアプリが閉じるため、接続中のデバイスはリンクを失い、再接続するまでフェイルセーフが作動します。',
    );
    return '$_temp0';
  }

  @override
  String get notInstalled => '未インストール';

  @override
  String get inThisVersion => 'このバージョンの内容';

  @override
  String get whatsNew => '新機能';

  @override
  String get fullNotes => 'リリースノート全文';

  @override
  String get chooseAnotherVersion => '別のバージョンを選ぶ';

  @override
  String get chooseVersion => 'バージョンを選ぶ';

  @override
  String get close => '閉じる';

  @override
  String get chooseVersionBody => '公開されたバージョンなら新旧どれでもインストールできます。各バージョンには、デバイスが前回接続時に報告した koebelt/link のバージョンで動くかが表示されます。';

  @override
  String get askingGithub => 'GitHub に問い合わせ中…';

  @override
  String get noReleases => 'リリースが見つかりません。';

  @override
  String get installed => 'インストール済み';

  @override
  String get latest => '最新';

  @override
  String get checkingShort => '確認中…';

  @override
  String get worksWithDevices => 'お使いのデバイスで動作';

  @override
  String get noDevicesToCheck => '確認するデバイスがまだありません';

  @override
  String notFor(String names) {
    return '$names には非対応';
  }

  @override
  String get details => '詳細';

  @override
  String get updateHowAndroid => 'アップデートはここでダウンロードされ、Android がインストールの確認を求めます。';

  @override
  String get updateHow => 'アップデートはダウンロード後にリリースと照合され、koebelt dash が新しいバージョンで再起動します。';

  @override
  String versionN(String version) {
    return 'バージョン $version';
  }

  @override
  String get noSelfUpdate => 'このビルドは自動更新しません。App Store と TestFlight はそれぞれが更新し、GitHub からのダウンロード版は自分で新しいバージョンを確認します。';

  @override
  String get releases => 'リリース';

  @override
  String get upToDate => '最新です。';

  @override
  String versionAvailable(String version) {
    return '$version が利用可能です。';
  }

  @override
  String downloadingWhat(String what, int pct) {
    return '$what をダウンロード中… $pct%';
  }

  @override
  String installingWhat(String what) {
    return '$what をインストール中…';
  }

  @override
  String get somethingWrong => '問題が発生しました。';

  @override
  String get notChecked => 'まだ確認していません。';

  @override
  String updateTo(String version) {
    return '$version に更新';
  }

  @override
  String get checkNow => '今すぐ確認';

  @override
  String get chooseVersionDesc => '公開されたバージョンなら古いものもインストールでき、デバイスの koebelt/link ライブラリで動くかどうかがわかります。';

  @override
  String get versions => 'バージョン';

  @override
  String get betas => 'ベータ';

  @override
  String get betasDesc => 'ベータ版とリリース候補も提示：リリース前の次の機能を試せますが、バグの可能性は高くなります。';

  @override
  String get autoCheck => 'アップデートを自動で確認';

  @override
  String get autoCheckDesc => '起動時と 1 日 1 回、koebelt dash は GitHub に最新リリースを問い合わせます。それ以外は何も送信しません。';

  @override
  String get padYawSteer => 'ヨー · ステア';

  @override
  String get padRoll => 'ロール';

  @override
  String get padPitchDrive => 'ピッチ · 前進';

  @override
  String get padUnavailable => 'このプラットフォームではコントローラーを使えません。';

  @override
  String get padNone => 'コントローラーが接続されていません。システム設定で Bluetooth コントローラーをペアリングするか、USB で接続してください。RC 送信機は USB ジョイスティックモードで使えます。';

  @override
  String padConnected(String names) {
    return '接続中：$names。';
  }

  @override
  String get padUse => 'ゲームコントローラーを使う';

  @override
  String get padUseDesc => 'アーム後は、スティックでドローンや地上ロボットを操縦し、ロボットアームをジョグ操作できます。ボタンはどのデバイスでも使えます。コントローラーを操作していない間も画面上の操作は使えます。';

  @override
  String get padSticks => 'スティック';

  @override
  String get padMoveNow => '今、操作部を動かすか押してください';

  @override
  String get padButtons => 'ボタン';

  @override
  String get padDeadzone => 'デッドゾーン';

  @override
  String padDeadzoneDesc(int pct) {
    return '中央付近で無視するスティックの動き：$pct %。';
  }

  @override
  String get padExpo => 'エクスポ';

  @override
  String padExpoDesc(int pct) {
    return '細かい操作のため中央付近の反応を穏やかにします：$pct %。';
  }

  @override
  String get padResetMapping => '割り当てをリセット';

  @override
  String get padResetMappingDesc => '標準の割り当て：左スティックでスロットルとヨー、右スティックでピッチとロール、B / ○ で STOP。';

  @override
  String get waiting => '待機中…';

  @override
  String get invertDirection => '方向を反転';

  @override
  String get inverted => '反転';

  @override
  String get normal => '通常';

  @override
  String clearName(String name) {
    return '$name をクリア';
  }

  @override
  String padDrives(String pad, String device) {
    return '$pad が $device を操縦中';
  }

  @override
  String padArmToDrive(String pad) {
    return '$pad で操縦するにはアームしてください。ボタンは既に使えます';
  }

  @override
  String get padButtonsWork => 'ボタンは使えます。スティックはドローンと地上ロボットを操縦します';

  @override
  String get pad => 'コントローラー';

  @override
  String get copy => 'コピー';

  @override
  String get aiLet => 'アシスタントに koebelt dash の使用を許可';

  @override
  String get aiLetDesc =>
      'Claude、Codex、OpenCode、Cursor などの MCP クライアントが、ドキュメントを読み、スクリプトを書き、アプリを使い、あなたの承認のもとでデバイスを操作できます。dash 自体はどの AI サービスにも何も送りません。接続したアシスタントが自分のプロバイダーと通信します。';

  @override
  String get aiConnectClient => 'クライアントを接続';

  @override
  String get aiPaste => 'これをアシスタントの設定に貼り付けてください。';

  @override
  String get aiRemotePhone => 'アシスタントはコンピューター上で動作し、このスマートフォンにはネットワーク経由でトークンを使って接続します。';

  @override
  String get aiRemoteTablet => 'アシスタントはコンピューター上で動作し、このタブレットにはネットワーク経由でトークンを使って接続します。';

  @override
  String get other => 'その他';

  @override
  String get aiConnectedNow => '接続中';

  @override
  String get aiNone => '過去 10 分間にアシスタントはありません。';

  @override
  String actions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 件の操作', one: '1 件の操作');
    return '$_temp0';
  }

  @override
  String get activity => 'アクティビティ';

  @override
  String get aiAllowed => '確認なしで許可';

  @override
  String get aiAllowedNone => 'シミュレーションのデバイスとリプレイでは確認しません。実機では、セッション中に許可しない限り毎回確認します。アームと離陸は常に確認します。';

  @override
  String aiAllowedSome(String actions) {
    return 'このセッション：$actions。アームと離陸は常に確認します。';
  }

  @override
  String get aiFromNetwork => 'このネットワークから';

  @override
  String aiFromNetworkOn(String url, String token) {
    return '他のコンピューターのアシスタント：$url、トークン $token…（その他タブからコピー）。';
  }

  @override
  String get aiFromNetworkOff => '別のコンピューターのアシスタントがトークンでこの dash を使えるようにします。';

  @override
  String get aiActivity => 'アシスタントのアクティビティ';

  @override
  String get nothingYet => 'まだ何もありません。';

  @override
  String get aiShort => 'AI';

  @override
  String aiAsks(String client) {
    return '$client からの要求';
  }

  @override
  String aiRealHardware(String device) {
    return '$device は実機です。';
  }

  @override
  String aiAllowSession(String device) {
    return 'このセッション中、$device でこの種の操作を許可';
  }

  @override
  String get refuse => '拒否';

  @override
  String get approve => '承認';

  @override
  String get recordingsAndLogs => '録画とフライトログ';

  @override
  String fileUnreadable(String error) {
    return 'ファイルを読み込めませんでした：$error';
  }

  @override
  String get fromFile => 'ファイルから';

  @override
  String get fromFileDesc => 'セッションとして開きます。リプレイ、地図、グラフ、書き出しが使えます。';

  @override
  String get fmtJson => 'koebelt/dash から書き出した録画';

  @override
  String get fmtBin => 'ArduPilot のログ（SD カードまたは Mission Planner から）';

  @override
  String get fmtTlog => '地上局のログ：Mission Planner、QGroundControl、MAVProxy';

  @override
  String get fmtUlg => 'PX4 のログ（SD カードまたは QGroundControl から）';

  @override
  String reading(String file) {
    return '$file を読み込み中…';
  }

  @override
  String get stopRecordingFirst => '先に録画を停止してください';

  @override
  String get notImported => 'インポートされていません';

  @override
  String get sampleRecordings => 'サンプル録画';

  @override
  String get samplesIn => '3 つのデモセッションがリストにあり、デモ と表示されています。';

  @override
  String get samplesDesc => 'シミュレーションのデバイスで録画した 3 つのデモセッション：測量飛行、ピックアンドプレース、ロケット打ち上げ。';

  @override
  String get removeSamples => 'サンプルを削除';

  @override
  String get loadSamples => 'サンプルを読み込む';

  @override
  String get exporting => '書き出し中…';

  @override
  String exportFormat(String format) {
    return '$format で書き出す';
  }

  @override
  String frames(int count) {
    return '$count フレーム';
  }

  @override
  String csvColumns(int count) {
    return '$count 列 · このデバイスが送信したチャンネルのみ';
  }

  @override
  String get noGpx => 'この録画には GPS がないため、GPX トラックはありません';

  @override
  String encoding(String format, int pct) {
    return '$format をエンコード中 · $pct%';
  }

  @override
  String get exported => '書き出しました';

  @override
  String get exportFailed => '書き出しに失敗しました';

  @override
  String get decrease => '減らす';

  @override
  String get increase => '増やす';

  @override
  String was(String value) {
    return '変更前 $value';
  }

  @override
  String firmware(String version) {
    return 'ファームウェア $version';
  }

  @override
  String parametersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'パラメータ $count 件', one: 'パラメータ 1 件');
    return '$_temp0';
  }

  @override
  String get parameters => 'パラメータ';

  @override
  String unsaved(int count) {
    return '未保存 $count 件';
  }

  @override
  String written(String when) {
    return '$when に書き込み済み';
  }

  @override
  String get inSync => '同期済み';

  @override
  String get revert => '元に戻す';

  @override
  String get writing => '書き込み中…';

  @override
  String get writeToDevice => 'デバイスに書き込む';

  @override
  String get searchParameters => 'パラメータを検索';

  @override
  String get waitingParams => 'パラメータテーブルを待機中…';

  @override
  String noParamsMatch(String query) {
    return '「$query」に一致するパラメータはありません';
  }

  @override
  String revertName(String name) {
    return '$name を元に戻す';
  }

  @override
  String get liveResponse => 'ライブ応答';

  @override
  String get copied => 'コピーしました';

  @override
  String get yourPairingCode => 'ペアリングコード · 10 分間有効';

  @override
  String namePaired(String name) {
    return '$name をペアリングしました';
  }

  @override
  String get startListening => '受信待ちを開始';

  @override
  String get listeningWifiBle => 'Wi-Fi と BLE で受信待ち · デバイスの電源を入れてください';

  @override
  String nameFound(String name) {
    return '$name が見つかりました';
  }

  @override
  String sensorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'センサー $count 個', one: 'センサー 1 個');
    return '$_temp0';
  }

  @override
  String get addToDevices => 'デバイスに追加';

  @override
  String get connectNow => '今すぐ接続';

  @override
  String get inTheApp => 'アプリ内';

  @override
  String get completeProgram => '完全なプログラム';

  @override
  String get apiReference => 'API リファレンス';

  @override
  String get exampleProjects => 'サンプルプロジェクト';

  @override
  String get allGuides => 'すべてのガイド';

  @override
  String stepOfUpper(int n, int total) {
    return 'ステップ $n / $total';
  }

  @override
  String get flowDevice => 'あなたのデバイス';

  @override
  String get flowDeviceDesc => 'ボードまたはコンパニオンコンピューター上のセンサー、モーター、koebelt/link。';

  @override
  String get flowLinkDesc => 'Wi-Fi、BLE、USB シリアル、無線。1 本が切れても予備のリンクがあります。';

  @override
  String get flowDashDesc => 'スマートフォン、タブレット、デスクトップでのダッシュボード、操縦、チューニング、録画。';

  @override
  String get library => 'ライブラリ';

  @override
  String get connectHardware => 'ハードウェアを接続';

  @override
  String get connectHardwareDesc => 'デバイスで小さなライブラリを実行すると、センサーがこのアプリに送られ、操縦入力を受け取れます。プラットフォームを選んで始めましょう。';

  @override
  String get guidesConnections => '接続';

  @override
  String get guidesConnectionsDesc => '各リンクのしくみと、デバイスが表示されないときの対処。';

  @override
  String get guidesDevices => 'デバイスの例';

  @override
  String get guidesDevicesDesc => 'デバイスの種類ごとの完全なコメント付きプログラム。';

  @override
  String get guidesFeatures => 'ビデオ、地図、コントローラー';

  @override
  String get guidesFeaturesDesc => 'カメラを表示し、デバイスを地図に置き、ゲームパッドで操縦する。';

  @override
  String get guidesMore => 'さらに詳しく';

  @override
  String get guidesMoreDesc => 'カスタムデータ、チューニング、シーケンス、安全。';

  @override
  String get viewChase => 'CHASE';

  @override
  String get viewOrbit => 'ORBIT';

  @override
  String get viewTop => 'TOP';

  @override
  String get viewMap => '地図';

  @override
  String get viewCam => 'CAM';

  @override
  String get noMapboxToken => 'このビルドには Mapbox トークンがありません。下に自分のトークンを入力するか、別のソースを選んでください。';

  @override
  String get waitingGps => 'GPS 測位を待機中';

  @override
  String get grid => 'グリッド';

  @override
  String get waitingScript => 'スクリプトを待機中';

  @override
  String get scriptEnded => 'スクリプト終了';

  @override
  String get noVideo => 'この録画にはビデオがありません。';

  @override
  String get noCamera => 'カメラがありません。デバイスはライブラリの video() でカメラを宣言します。';

  @override
  String cameraByIp(String name) {
    return 'このカメラには IP アドレスで接続します。表示するには Wi-Fi で $name に接続してください。';
  }

  @override
  String get warning => '警告';

  @override
  String get alBattery => 'バッテリー低下';

  @override
  String get alBatteryDesc => 'デバイスが報告する残量。';

  @override
  String get alBatteryAct => '戻す時間です。';

  @override
  String get alBatteryCritical => 'バッテリー危険';

  @override
  String get alBatteryCriticalDesc => '2 つ目のより強い制限：確認するまで繰り返します。';

  @override
  String get alBatteryCriticalAct => '今すぐ着陸するか停止してください。';

  @override
  String get alVoltage => 'バッテリー電圧';

  @override
  String get alVoltageDesc => '残量を報告しないバッテリー用。お使いのバッテリーに合わせて設定してください（例：1 セルあたり 3.5 V）。';

  @override
  String get alVoltageAct => '戻す時間です。';

  @override
  String get alObstacle => '障害物接近';

  @override
  String get alObstacleDesc => 'アーム中に近接センサーが捉えた最も近いもの（下向きのセンサーは含みません）。';

  @override
  String get alObstacleAct => '避けるか停止してください。';

  @override
  String get alRssi => '電波が弱い';

  @override
  String get alRssiDesc => 'リンクが報告する受信信号強度。';

  @override
  String get alRssiAct => '近づくか引き返してください。';

  @override
  String get alLatency => '高レイテンシ';

  @override
  String get alLatencyDesc => 'リンクの往復時間。数百ミリ秒を超えると操縦が遅れて感じられます。';

  @override
  String get alLatencyAct => '操縦が遅れて感じられます。';

  @override
  String get alAltitude => '高度上限';

  @override
  String get alAltitudeDesc => 'ホームからの高さ。ヨーロッパと米国ではドローンの一般的な上限は 120 m です。';

  @override
  String get alAltitudeAct => '降下してください。';

  @override
  String get alDistance => 'ホームからの距離';

  @override
  String get alDistanceDesc => '簡単なジオフェンス：出発地点からの水平距離。';

  @override
  String get alDistanceAct => '近くに戻してください。';

  @override
  String get alTemp => '温度';

  @override
  String get alTempDesc => 'デバイスが報告する場合の、モーター、ESC、ボードの温度。';

  @override
  String get alTempAct => '冷やしてください。';

  @override
  String get kindDrone => 'ドローン';

  @override
  String get kindRover => '地上ロボット';

  @override
  String get kindArm => 'ロボットアーム';

  @override
  String get kindRocket => 'ロケット';

  @override
  String get kindBench => 'テストベンチ';

  @override
  String get kindGeneric => 'デバイス';

  @override
  String get stTakeoff => '離陸';

  @override
  String get stFlyTo => '飛行';

  @override
  String get stLand => '着陸';

  @override
  String get stRth => 'ホームへ帰還';

  @override
  String get stDriveTo => '走行';

  @override
  String get stPose => 'ポーズへ移動';

  @override
  String get stRamp => 'ランプ';

  @override
  String get stWait => '待機';

  @override
  String get stMode => 'モード設定';

  @override
  String get stArm => 'アーム / ディスアーム';

  @override
  String get stCmd => 'カスタムコマンド';

  @override
  String get fEast => '東';

  @override
  String get fNorth => '北';

  @override
  String get fHold => '保持';

  @override
  String get fFrom => '開始';

  @override
  String get fTo => '終了';

  @override
  String get fOver => '時間';

  @override
  String get fDuration => '時間';

  @override
  String get fMode => 'モード';

  @override
  String get fState => '状態';

  @override
  String get fLimit => '制限';

  @override
  String get fCommand => 'コマンド';

  @override
  String get fValue => '値';

  @override
  String sumTakeoff(String alt) {
    return '$alt m まで離陸';
  }

  @override
  String sumFlyTo(String x, String y, String z) {
    return '$x、$y m へ高度 $z m で飛行';
  }

  @override
  String sumDriveTo(String x, String y) {
    return '$x、$y m へ走行';
  }

  @override
  String get sumRth => 'ホームへ帰還して着陸';

  @override
  String sumPose(String joints) {
    return 'ポーズ $joints° へ移動';
  }

  @override
  String sumGripper(String pct) {
    return 'グリッパー $pct% 開';
  }

  @override
  String sumThrottle(String pct, String s) {
    return 'スロットル $pct% を $s 秒';
  }

  @override
  String sumRamp(String from, String to, String s) {
    return '$s 秒で $from から $to% へランプ';
  }

  @override
  String sumWait(String s) {
    return '$s 秒待機';
  }

  @override
  String sumMode(String mode) {
    return 'モード $mode';
  }

  @override
  String get sumArm => 'アーム';

  @override
  String get sumDisarm => 'ディスアーム';

  @override
  String sumSpeed(String pct) {
    return '速度制限 $pct%';
  }

  @override
  String sumCmd(String name, String value) {
    return 'コマンド $name = $value';
  }

  @override
  String get stoppedEstop => '停止：緊急停止';

  @override
  String completedIn(String seconds) {
    return '$seconds 秒で完了';
  }

  @override
  String stepTimedOut(int n, String step) {
    return 'ステップ $n がタイムアウト：$step';
  }

  @override
  String metresToGo(String metres) {
    return '残り $metres m';
  }

  @override
  String get uploadingToDevice => 'デバイスにアップロード中';

  @override
  String get starting => '開始中';

  @override
  String get completedOnDevice => 'デバイス上で完了';

  @override
  String get deviceRejected => 'デバイスがシーケンスを受け付けませんでした';

  @override
  String get linkLostCarriesOn => 'リンク切断 · デバイスは続行中';

  @override
  String get stoppedDisconnected => '停止：切断';

  @override
  String get stoppedTookControl => '停止：操縦を取り戻しました';

  @override
  String get stoppedManual => '停止：手動操縦';

  @override
  String get stoppedByScript => 'スクリプトにより停止';

  @override
  String get reqAnyDevice => 'デバイス';

  @override
  String reqKinds(String kinds) {
    return '$kinds';
  }

  @override
  String reqWith(String kinds, String needs) {
    return '$needs を備えた$kinds';
  }

  @override
  String reqWrongKind(String name, String kind, String needs) {
    return '$name は$kindですが、このスクリプトには $needs が必要です。';
  }

  @override
  String reqLacks(String name, String lacks, String needs) {
    return '$name には $lacks がありません。このスクリプトには $needs が必要です。';
  }

  @override
  String get trgButton => 'ボタン';

  @override
  String get trgSwitch => 'スイッチ';

  @override
  String get trgSlider => 'スライダー';

  @override
  String get trgController => 'コントローラー';

  @override
  String get trgCondition => '条件';

  @override
  String get trgEvent => 'デバイスイベント';

  @override
  String get trgTimer => 'タイマー';

  @override
  String get evMode => 'モード変更';

  @override
  String get evFailsafe => 'フェイルセーフ';

  @override
  String get evSeqDone => 'シーケンス終了';

  @override
  String get evLog => 'デバイスのメッセージ';

  @override
  String get onControl => '操縦画面';

  @override
  String everyN(String seconds) {
    return '$seconds 秒ごと';
  }

  @override
  String onceAfterN(String seconds) {
    return '$seconds 秒後に 1 回';
  }

  @override
  String get paArm => 'アーム / ディスアーム';

  @override
  String get paManual => '手動';

  @override
  String get paHold => '保持';

  @override
  String get paAuto => 'スクリプトに戻す';

  @override
  String get paSlower => '減速';

  @override
  String get paFaster => '加速';

  @override
  String get paFrame => '関節 / 直交';

  @override
  String get paWrist => '手首';

  @override
  String get paNext => '次のデバイス';

  @override
  String get paStopHint => '緊急停止、即時';

  @override
  String get paHoldHint => '1 秒長押し';

  @override
  String paSwitchTo(String mode) {
    return '$mode に切り替え';
  }

  @override
  String get paAutoHint => '操縦を取り戻した後、スティックをスクリプトに戻す（AUTO）';

  @override
  String paSwitchToDrones(String mode) {
    return '$mode に切り替え（ドローン）';
  }

  @override
  String get paHoldDronesHint => '1 秒長押し（ドローン）';

  @override
  String get paRecordHint => '録画の開始・停止';

  @override
  String get paSlowerHint => '速度制限を 10% 下げる';

  @override
  String get paFasterHint => '速度制限を 10% 上げる';

  @override
  String get paFrameHint => 'アーム：スティックで動かす対象';

  @override
  String get paWristHint => 'アーム：右スティックで J3 と J4 の代わりに J5 と J6 を動かす';

  @override
  String get paGripperHint => 'アーム：開閉';

  @override
  String get paNextHint => '複数接続時：次のデバイスを表示して操縦';

  @override
  String get notSet => '未設定';

  @override
  String get padLeftStickX => '左スティック X';

  @override
  String get padLeftStickY => '左スティック Y';

  @override
  String get padRightStickX => '右スティック X';

  @override
  String get padRightStickY => '右スティック Y';

  @override
  String get padLeftTrigger => '左トリガー';

  @override
  String get padRightTrigger => '右トリガー';

  @override
  String get padACross => 'A / ×';

  @override
  String get padBCircle => 'B / ○';

  @override
  String get padXSquare => 'X / □';

  @override
  String get padYTriangle => 'Y / △';

  @override
  String get padLeftBumper => '左バンパー';

  @override
  String get padRightBumper => '右バンパー';

  @override
  String get padBackShare => 'Back / Share';

  @override
  String get padStartOptions => 'Start / Options';

  @override
  String get padHome => 'Home';

  @override
  String get padLeftStickPress => '左スティック押し込み';

  @override
  String get padRightStickPress => '右スティック押し込み';

  @override
  String get padDPadUp => '十字キー上';

  @override
  String get padDPadDown => '十字キー下';

  @override
  String get padDPadLeft => '十字キー左';

  @override
  String get padDPadRight => '十字キー右';

  @override
  String get radioSik => 'SiK テレメトリ無線';

  @override
  String get radioLoraName => 'LoRa 地上局';

  @override
  String get radioOther => 'その他のシリアル無線';

  @override
  String get radioSikDesc => '433 / 868 / 915 MHz のペア：3DR、Holybro、RFD900。透過シリアルで約 1 km、RFD900 なら 40 km。';

  @override
  String get radioLoraDesc => 'USB 接続の LoRa 無線付きボードに地上局スケッチを書き込んだもの。2〜10 km、テレメトリのみ。';

  @override
  String get radioHc12Desc => 'USB アダプター上の安価な透過シリアルモジュール。9600 baud で約 1 km。';

  @override
  String get radioXbeeDesc => 'USB エクスプローラーボード上で透過モードの Digi XBee。2.4 GHz または 900 MHz。';

  @override
  String get radioOtherDesc => '透過シリアル無線なら何でも。ボーレートを設定してください。アプリは控えめなレートを使います。';

  @override
  String get tplLoop => '制御ループ';

  @override
  String get tplButton => 'ボタンで実行するアクション';

  @override
  String get fldBattery => 'バッテリー';

  @override
  String get fldBatteryVoltage => 'バッテリー電圧';

  @override
  String get fldDistanceFromHome => 'ホームからの距離';

  @override
  String get fldHeightAboveHome => 'ホームからの高さ';

  @override
  String get fldSpeed => '速度';

  @override
  String get fldHeading => '方位';

  @override
  String get fldRoll => 'ロール';

  @override
  String get fldPitch => 'ピッチ';

  @override
  String get fldGripper => 'グリッパー';

  @override
  String get fldThrust => '推力';

  @override
  String get fldRpm => 'RPM';

  @override
  String get fldTemperature => '温度';

  @override
  String get fldNearestObstacle => '最も近い障害物';

  @override
  String get fldSignal => '信号';

  @override
  String get fldLatency => 'レイテンシ';

  @override
  String get fldGpsSatellites => 'GPS 衛星';

  @override
  String get ready => '準備完了。';

  @override
  String get pythonManaged => 'この Python はシステムが管理していてパッケージを拒否します。代わりにスクリプト環境を使ってください。';

  @override
  String failedWhy(String why) {
    return '失敗：$why';
  }

  @override
  String get pipNoPackage => 'pip は終了しましたが、この Python にはまだ koebelt-dash-scripts がありません。';

  @override
  String packageUpToDate(String version) {
    return 'この Python の koebelt-dash-scripts $version は最新です。';
  }

  @override
  String packageInstalled(String version) {
    return 'この Python に koebelt-dash-scripts $version がインストールされました。';
  }

  @override
  String packagesInstalled(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$names がこの Python にインストールされました。', one: '$names がこの Python にインストールされました。');
    return '$_temp0';
  }

  @override
  String envReady(String version) {
    return 'スクリプト環境の準備ができました（koebelt-dash-scripts $version）。';
  }

  @override
  String atMostDevices(int count) {
    return '同時に接続できるのは $count 台までです。先に 1 台切断してください。';
  }

  @override
  String noAnswerFrom(String name) {
    return '$name から応答がありません';
  }

  @override
  String noHostAt(String address) {
    return '$address にスクリプトホストがありません。そこで `koebelt-dash-scripts host` は動いていますか？';
  }

  @override
  String get hostRefused => 'ホストに拒否されました。';

  @override
  String get logUnknown => 'このファイルはアプリが読めるログではありません。開けるのは koebelt/dash の JSON 書き出し、ArduPilot の .bin と .tlog、PX4 の .ulg です。';

  @override
  String logEmpty(String format) {
    return 'この $format ファイルには、アプリが表示できるテレメトリ（姿勢、位置、バッテリー）がありません。';
  }

  @override
  String get logJsonUnreadable => 'この JSON ファイルを読み込めませんでした。';

  @override
  String get logJsonNotExport => 'この JSON ファイルは koebelt/dash の録画の書き出しではありません。';

  @override
  String get logNoHeartbeat => 'この .tlog には機体のハートビートがないため、メッセージをどの機体のものか特定できません。';

  @override
  String get viewDevices => 'デバイスを表示';

  @override
  String get simulatedTip => 'アプリ内のシミュレーションで、実機ではありません';

  @override
  String get newShort => '新規';
}
