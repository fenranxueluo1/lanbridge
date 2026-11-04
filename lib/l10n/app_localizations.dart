import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  bool get _zh => locale.languageCode == 'zh';

  String _s(String zh, String en) => _zh ? zh : en;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('zh'));
  }

  static const supportedLocales = <Locale>[Locale('zh'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Brand & general ---------------------------------------------------------
  String get appName => _s('邻传', 'LANBridge');
  String get tagline => _s('局域网直连传输', 'Direct over your LAN');
  String get demoMode => _s('演示模式', 'Demo mode');
  String get cancel => _s('取消', 'Cancel');
  String get close => _s('关闭', 'Close');
  String get done => _s('完成', 'Done');
  String get confirm => _s('确认', 'Confirm');
  String get save => _s('保存', 'Save');
  String get remove => _s('移除', 'Remove');
  String get clear => _s('清空', 'Clear');
  String get retry => _s('重试', 'Retry');
  String get all => _s('全部', 'All');
  String get search => _s('搜索', 'Search');
  String get on => _s('开启', 'On');
  String get off => _s('关闭', 'Off');
  String get justNow => _s('刚刚', 'Just now');
  String get unknown => _s('未知', 'Unknown');

  String minutesAgo(int minutes) => _s('$minutes 分钟前', '$minutes min ago');
  String todayAt(String time) => _s('今天 $time', 'Today $time');
  String yesterdayAt(String time) => _s('昨天 $time', 'Yesterday $time');
  String dateAt(int month, int day, String time) =>
      _s('$month月$day日 $time', '$month/$day $time');

  // Navigation --------------------------------------------------------------
  String get navNearby => _s('附近', 'Nearby');
  String get navSend => _s('发送', 'Send');
  String get navTransfers => _s('传输', 'Transfers');
  String get navSettings => _s('设置', 'Settings');

  // Nearby ------------------------------------------------------------------
  String get nearbySubtitle =>
      _s('同一网络内，即传即达，不经过云端', 'Instant transfers on the same network');
  String get scanning => _s('正在搜索附近设备', 'Looking for nearby devices');
  String get devicesFound => _s('发现设备', 'devices found');
  String get devicesCountLabel => _s('在线设备', 'Online devices');
  String get favorites => _s('收藏设备', 'Favorites');
  String get nearbyDevices => _s('附近设备', 'Nearby');
  String get noDevicesTitle => _s('附近还没有设备', 'No devices nearby');
  String get noDevicesBody => _s(
    '确认两台设备连接同一个 Wi-Fi，或关闭访客网络隔离后重试。',
    'Make sure both devices share the same Wi-Fi, or disable AP isolation.',
  );
  String get scanAgain => _s('重新搜索', 'Scan again');
  String get manualConnect => _s('手动连接', 'Manual connect');
  String get manualConnectTitle => _s('输入 IP 地址', 'Enter IP address');
  String get manualConnectHint =>
      _s('例如 192.168.1.24:53317', 'e.g. 192.168.1.24:53317');
  String get manualConnectAction => _s('连接', 'Connect');
  String get manualConnectDone => _s('已连接', 'Connected');
  String get manualConnectFailed =>
      _s('连接失败，请检查 IP 和局域网', 'Could not connect. Check the IP and LAN.');
  String get engineNotReady =>
      _s('传输引擎正在初始化，请稍后再试', 'The transfer engine is starting');
  String get transferStarted => _s('已开始发送', 'Transfer started');
  String get sendFailed => _s('发送失败', 'Could not send');
  String get pickerFailed => _s('无法打开文件选择器', 'Could not open the file picker');
  String get dropFilesHint => _s('松开以添加文件', 'Drop to add files');
  String droppedFiles(int count) =>
      _s('已添加 $count 个文件', 'Added $count file(s)');
  String get textMessageTitle => _s('发送文本', 'Send text');
  String get textMessageHint => _s('输入要发送的文本', 'Enter text to send');
  String get textFileName => _s('文本消息.txt', 'message.txt');
  String get httpsEncryption => _s('HTTPS 加密', 'HTTPS encryption');
  String get httpsEncryptionHint => _s(
    '自签名证书加密传输；关闭后仅用于兼容旧设备',
    'Encrypted with a self-signed certificate. Disable only for legacy peers.',
  );
  String get insecureTransferWarning => _s(
    '目标设备未启用 HTTPS，本次传输不会加密',
    'Target has HTTPS disabled; this transfer is not encrypted',
  );
  String get unencrypted => _s('未加密', 'Unencrypted');
  String get discoveryDisabled => _s('设备发现已关闭', 'Device discovery is off');
  String get scanQr => _s('扫码配对', 'Scan QR');
  String get pairCode => _s('配对码', 'Pair code');
  String get pairCodeTitle => _s('设备配对码', 'Pairing code');
  String get pairCodeHint => _s(
    '在同一局域网的另一台设备上打开邻传，输入下方配对码或地址。',
    'Open LANBridge on another device and enter this code or address.',
  );
  String get pairingAddress => _s('局域网地址', 'LAN address');
  String get pairCodeExpiry => _s('5 分钟后失效', 'Expires in 5 minutes');
  String get receiveCardTitle => _s('允许接收', 'Allow receiving');
  String get receiveCardHint =>
      _s('附近设备可以直接向你发送文件', 'Let nearby devices send files to you');
  String get receiveOffHint => _s('接收已暂停，设备仍可被发现', 'Receiving is paused');
  String get thisDevice => _s('本机', 'This device');
  String get connectedVia => _s('已连接 · 局域网', 'Connected · LAN');
  String get discovering => _s('搜索中', 'Discovering');
  String get capabilitiesLabel => _s('支持的能力', 'Capabilities');
  String get connectionInfo => _s('连接信息', 'Connection');

  String get localEndpoint => _s('本机地址', 'Local endpoint');
  String get transferInProgress => _s('传输进行中', 'Transfer in progress');

  String devicesFoundCount(int count) =>
      _s('发现 $count 台设备', '$count devices found');
  String onlineCount(int count) => _s('$count 台在线', '$count online');

  String get demoIncoming => _s('演示接收请求', 'Demo incoming request');
  String get demoIncomingHint => _s('预览接收确认界面', 'Preview the receive sheet');
  String get compatibilityNotice =>
      _s('兼容 LocalSend v2.2', 'LocalSend v2.2 compatible');

  // Device ------------------------------------------------------------------
  String get deviceDetails => _s('设备详情', 'Device details');
  String get fingerprint => _s('证书指纹', 'Certificate fingerprint');
  String get ipAddress => _s('IP 地址', 'IP address');
  String get favoriteDevice => _s('收藏设备', 'Favorite');
  String get favoriteHint =>
      _s('收藏后可快速发送，并可启用自动接收', 'Quick send and auto accept');
  String get autoAccept => _s('自动接收', 'Auto accept');
  String get autoAcceptHint =>
      _s('仅接收来自收藏设备的文件', 'Only accept files from favorites');
  String get forgetDevice => _s('忘记此设备', 'Forget device');
  String get forgetConfirmTitle => _s('忘记这个设备？', 'Forget this device?');
  String get forgetConfirmBody =>
      _s('下次发送前需要重新确认设备指纹。', 'You will need to verify its fingerprint again.');
  String get sendFiles => _s('发送文件', 'Send files');
  String get lastSeen => _s('最近在线', 'Last seen');
  String get compatibleMode =>
      _s('兼容模式 · LocalSend v2.2', 'Compatibility mode · LocalSend v2.2');
  String get fullMode => _s('邻传 完整模式', 'LANBridge full mode');
  String get capResume => _s('断点续传', 'Resume');
  String get capDelta => _s('增量同步', 'Delta sync');
  String get capManifest => _s('文件夹清单', 'Folder manifest');
  String get capPin => _s('PIN 保护', 'PIN');
  String get capWebShare => _s('网页分享', 'Web share');
  String get statusOnline => _s('在线', 'Online');
  String get statusBusy => _s('忙碌', 'Busy');
  String get statusOffline => _s('离线', 'Offline');
  String get copied => _s('已复制', 'Copied');
  String get copy => _s('复制', 'Copy');

  // Send --------------------------------------------------------------------
  String get send => _s('发送', 'Send');
  String get sendTitle => _s('发送', 'Send');
  String get sendSubtitle =>
      _s('选择内容，再选择一台附近的设备', 'Pick content, then choose a device');
  String get addContent => _s('添加内容', 'Add content');
  String get pickPhotos => _s('照片', 'Photos');
  String get pickVideos => _s('视频', 'Videos');
  String get pickFiles => _s('文件', 'Files');
  String get pickText => _s('文本', 'Text');
  String get selectedContent => _s('已选择', 'Selected');
  String get emptySelectionTitle => _s('还没有选择内容', 'Nothing selected yet');
  String get emptySelectionBody =>
      _s('从上方添加文件、文件夹或文本', 'Add files, folders or text above');
  String get chooseDevice => _s('选择接收设备', 'Choose a device');
  String get noSelectionHint => _s('先添加内容，才能发送', 'Add something to send first');
  String get noDeviceSelectedHint =>
      _s('请选择至少一台设备', 'Select at least one device');
  String get transferMode => _s('传输方式', 'Transfer mode');
  String get modeStandard => _s('标准模式', 'Standard');
  String get modeStandardHint => _s('兼容所有设备，整文件传输', 'Works with every device');
  String get modeSmart => _s('智能增量', 'Smart delta');
  String get modeSmartHint => _s('只传变化部分，节省时间与流量', 'Only send changed blocks');
  String get compatTransferNote => _s(
    '当前使用 LocalSend 兼容模式；增量同步将在后续版本提供',
    'LocalSend compatibility mode; delta sync is coming later',
  );
  String get startTransfer => _s('开始传输', 'Start transfer');
  String get sendSheetTitle => _s('确认发送', 'Confirm send');
  String get connectionSecure =>
      _s('端到端加密 · 设备指纹已校验', 'End-to-end encrypted · verified');
  String get sending => _s('发送中', 'Sending');

  String selectedCount(int count) => _s('$count 项内容', '$count items');
  String itemsCount(int count) => _s('$count 项', '$count items');
  String filesCount(int count) => _s('$count 个文件', '$count files');
  String sendToCount(int count) =>
      _s('发送到 $count 台设备', 'Send to $count devices');
  String targetCount(int count) => _s('$count 台设备', '$count devices');
  String totalSizeOf(String size) => _s('共 $size', '$size total');
  String startedSending(String name) => _s('已开始发送到 $name', 'Sending to $name');

  // Transfers ---------------------------------------------------------------
  String get transfersTitle => _s('传输', 'Transfers');
  String get transfersSubtitle =>
      _s('实时进度、断点与历史记录', 'Live progress, resume and history');
  String get tabActive => _s('进行中', 'Active');
  String get tabHistory => _s('历史', 'History');
  String get noActiveTitle => _s('暂无进行中的传输', 'No active transfers');
  String get noActiveBody =>
      _s('从“附近”选择设备开始传输', 'Pick a device from Nearby to start');
  String get noHistoryTitle => _s('还没有传输记录', 'No transfer history yet');
  String get noHistoryBody =>
      _s('完成的传输会显示在这里', 'Completed transfers appear here');
  String get statusWaiting => _s('等待中', 'Waiting');
  String get statusTransferring => _s('传输中', 'Transferring');
  String get statusPaused => _s('已暂停', 'Paused');
  String get statusCompleted => _s('已完成', 'Completed');
  String get statusFailed => _s('失败', 'Failed');
  String get statusCancelled => _s('已取消', 'Cancelled');
  String get statusVerifying => _s('校验中', 'Verifying');
  String get speedLabel => _s('速度', 'Speed');
  String get remainingLabel => _s('剩余', 'Left');
  String get savedLabel => _s('已节省', 'Saved');
  String get pause => _s('暂停', 'Pause');
  String get resume => _s('继续', 'Resume');
  String get cancelTransfer => _s('取消传输', 'Cancel transfer');
  String get sendAgain => _s('再次发送', 'Send again');
  String get deltaBadge => _s('增量', 'Delta');
  String get resumeBadge => _s('续传', 'Resumed');
  String get activeSummary => _s('正在传输', 'Transferring');
  String get clearHistory => _s('清空历史', 'Clear history');
  String get historyCleared => _s('历史已清空', 'History cleared');

  String sendingTo(String name) => _s('发送至 $name', 'To $name');
  String receivingFrom(String name) => _s('来自 $name', 'From $name');
  String progressOf(String transferred, String total) =>
      _s('$transferred / $total', '$transferred / $total');
  String savedBytes(String size) => _s('节省 $size', 'Saved $size');
  String activeItems(int count) => _s('$count 项进行中', '$count active');

  String etaSeconds(int seconds) => _s('$seconds 秒', '${seconds}s');
  String etaMinutes(int minutes) => _s('$minutes 分钟', '$minutes min');
  String etaMinutesSeconds(int minutes, int seconds) =>
      _s('$minutes 分 $seconds 秒', '${minutes}m ${seconds}s');
  String etaHours(int hours, int minutes) =>
      _s('$hours 小时 $minutes 分', '${hours}h ${minutes}m');

  // Transfer detail ---------------------------------------------------------
  String get transferDetails => _s('传输详情', 'Transfer details');
  String get transferItemList => _s('文件列表', 'Files');
  String get progressLabel => _s('总进度', 'Progress');
  String get cancelConfirmTitle => _s('取消这次传输？', 'Cancel this transfer?');
  String get cancelConfirmBody => _s(
    '已传输的部分会保留，下次可以从断点继续。',
    'Transferred data is kept so you can resume later.',
  );
  String get keepGoing => _s('继续传输', 'Keep going');
  String get transferComplete => _s('传输完成', 'Transfer complete');
  String get transferFailed => _s('传输失败', 'Transfer failed');
  String get transferCancelled => _s('传输已取消', 'Transfer cancelled');
  String get pausedToast => _s('已暂停', 'Paused');
  String get resumedToast => _s('已继续', 'Resumed');
  String get jobNotFound => _s('找不到这个传输任务', 'Transfer not found');

  // Incoming ----------------------------------------------------------------
  String get incomingTitle => _s('接收请求', 'Incoming request');
  String get incomingFiles => _s('待接收文件', 'Files');
  String get accept => _s('接收', 'Accept');
  String get decline => _s('拒绝', 'Decline');
  String get pinRequired => _s('需要 PIN', 'PIN required');
  String get pinLabel => _s('6 位 PIN', '6-digit PIN');
  String get pinError => _s('请输入 6 位数字（演示：任意数字）', 'Enter 6 digits (demo)');
  String get pinHintDemo => _s('演示：输入任意 6 位数字', 'Demo: any 6 digits');
  String get senderVerified => _s('指纹已验证', 'Fingerprint verified');
  String get acceptedToast => _s('已开始接收', 'Receiving now');
  String get declinedToast => _s('已拒绝这次传输', 'Request declined');

  String wantsToSend(String name, int count) =>
      _s('$name 想发送 $count 个文件', '$name wants to send $count files');
  String andMore(int count) => _s('还有 $count 个文件', 'and $count more');
  String fromPeer(String name) => _s('来自 $name', 'From $name');

  // Settings ----------------------------------------------------------------
  String get settingsTitle => _s('设置', 'Settings');
  String get settingsSubtitle =>
      _s('设备、网络与外观', 'Device, network and appearance');
  String get sectionDevice => _s('设备', 'Device');
  String get deviceName => _s('设备名称', 'Device name');
  String get deviceNameHint => _s(
    '附近设备看到的名字；手动修改会关闭自动命名',
    'How others see you; manual edits disable auto naming',
  );
  String get autoDeviceName => _s('每次启动自动命名', 'Random name on launch');
  String get autoDeviceNameHint => _s(
    '物理主题随机名称，自动避开附近同名设备',
    'Physics-themed names that avoid nearby duplicates',
  );
  String get deviceNameDialogTitle => _s('修改设备名称', 'Change device name');
  String get saveLocation => _s('保存位置', 'Save location');
  String get saveLocationApp => _s('应用目录', 'App folder');
  String get saveLocationAppHint => _s(
    '文件保存在应用沙箱内，仅限本应用访问',
    'Files stay inside the app sandbox',
  );
  String get saveLocationDownloads => _s('下载目录', 'Downloads');
  String get saveLocationDownloadsHint => _s(
    '文件保存到公共下载文件夹，可在 文件管理-我的手机-Download-邻传中查看',
    'Files go to the public Downloads folder (Files > My phone > Download)',
  );
  String get saveLocationUnavailable => _s(
    '无法访问下载目录，已保留当前设置',
    'Cannot access the Downloads folder; keeping the current choice',
  );
  String get change => _s('更改', 'Change');
  String get sectionNetwork => _s('网络与发现', 'Network & discovery');
  String get discovery => _s('启用发现', 'Discovery');
  String get discoveryHint => _s('通过局域网组播查找设备', 'Find devices over multicast');
  String get allowReceiving => _s('允许接收', 'Allow receiving');
  String get allowReceivingHint =>
      _s('关闭后不会响应发送请求', 'Ignore incoming requests');
  String get pinProtection => _s('PIN 保护', 'PIN protection');
  String get pinProtectionHint =>
      _s('发送方需要输入 6 位 PIN', 'Senders must enter a 6-digit PIN');
  String get port => _s('端口', 'Port');
  String get portDialogTitle => _s('服务端口', 'Service port');
  String get portInvalid => _s('请输入 1024–65535 的端口', 'Enter 1024–65535');
  String get sectionAppearance => _s('外观', 'Appearance');
  String get theme => _s('主题', 'Theme');
  String get themeSystem => _s('跟随系统', 'System');
  String get themeSystemHint =>
      _s('未选择时默认跟随系统', 'Follows the system until you choose');
  String get themeLight => _s('浅色', 'Light');
  String get themeDark => _s('深色', 'Dark');
  String get language => _s('语言', 'Language');
  String get chinese => _s('简体中文', '简体中文');
  String get english => _s('English', 'English');
  String get sectionGeneral => _s('通用', 'General');
  String get autoAcceptFavorites => _s('收藏设备自动接收', 'Auto-accept favorites');
  String get autoAcceptFavoritesHint =>
      _s('仅对已收藏且指纹匹配的设备生效', 'Only verified favorite devices');
  String get sectionAbout => _s('关于', 'About');
  String get version => _s('版本', 'Version');
  String get protocol => _s('协议', 'Protocol');
  String get protocolValue => _s('LocalSend v2.2', 'LocalSend v2.2');
  String get openSource => _s('开源与许可', 'Open source & licenses');
  String get privacy => _s('隐私说明', 'Privacy');
  String get privacyBody => _s(
    '邻传默认不联网、不上传任何设备信息、文件名或传输内容。所有数据只在局域网内传输。',
    'LANBridge does not upload device info, file names or content. Everything stays on your local network.',
  );
  String get licensesBody => _s(
    '邻传以 Apache License 2.0 开源。本应用使用 Flutter 构建，并在协议层面兼容 LocalSend v2.2（Apache-2.0）；LocalSend 是独立项目，与本项目无隶属关系。完整许可见仓库 LICENSE 和 THIRD_PARTY_NOTICES.md。',
    'LANBridge is licensed under the Apache License 2.0. Built with Flutter and protocol-compatible with LocalSend v2.2 (Apache-2.0); LocalSend is an independent project and is not affiliated with LANBridge. See LICENSE and THIRD_PARTY_NOTICES.md for details.',
  );
  String get sectionDiagnostics => _s('诊断', 'Diagnostics');
  String get exportDiagnostics => _s('导出诊断包', 'Export diagnostics');
  String get exportDiagnosticsHint =>
      _s('包含版本、网络状态与最近错误（已脱敏）', 'Version, network state and recent errors');
  String get exportDone => _s('诊断包已生成（演示）', 'Diagnostics exported (demo)');
  String get resetDemo => _s('重置演示数据', 'Reset demo data');
  String get resetDemoDone => _s('演示数据已重置', 'Demo data reset');
  String get shareWeb => _s('网页分享', 'Web share');
  String get shareWebHint =>
      _s('让浏览器直接下载你分享的文件', 'Let browsers download your files');
  String get comingSoon => _s('即将推出', 'Coming soon');

  // Misc --------------------------------------------------------------------
  String get securedBy =>
      _s('自签名证书 · HTTPS', 'Self-signed certificate · HTTPS');
  String get quickStatsDevices => _s('在线设备', 'Devices');
  String get quickStatsActive => _s('进行中', 'Active');
  String get quickStatsSaved => _s('今日节省', 'Saved today');
  String get footerNote =>
      _s('所有传输均在局域网内完成', 'All transfers stay on your local network');
  String get comingFromClipboard => _s('剪贴板文本', 'Clipboard text');
  String get folderItemLabel => _s('设计素材', 'Design assets');
  String get scanHint => _s('扫描二维码快速配对', 'Scan a QR code to pair');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((supported) => supported.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
