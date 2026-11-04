import common from '@ohos.app.ability.common';
import wantAgent from '@ohos.app.ability.wantAgent';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import notificationManager from '@ohos.notificationManager';
import fs from '@ohos.file.fs';
import fileuri from '@ohos.file.fileuri';
import picker from '@ohos.file.picker';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import {
  FlutterEngine,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';

const TAG = 'LanBridgePlugin';
const PATHS_CHANNEL = 'plugins.flutter.io/path_provider';
const PICKER_CHANNEL = 'lanbridge/picker';
const NETWORK_CHANNEL = 'lanbridge/network';
const BACKGROUND_CHANNEL = 'lanbridge/background';
const DOWNLOADS_CHANNEL = 'lanbridge/downloads';

class PickedFile {
  name: string;
  size: number;
  path: string;

  constructor(name: string, size: number, path: string) {
    this.name = name;
    this.size = size;
    this.path = path;
  }
}

class PathsHandler implements MethodCallHandler {
  private plugin: LanBridgePlugin;

  constructor(plugin: LanBridgePlugin) {
    this.plugin = plugin;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.plugin.handlePaths(call, result);
  }
}

class PickerHandler implements MethodCallHandler {
  private plugin: LanBridgePlugin;

  constructor(plugin: LanBridgePlugin) {
    this.plugin = plugin;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.plugin.handlePicker(call, result);
  }
}

class NetworkHandler implements MethodCallHandler {
  private plugin: LanBridgePlugin;

  constructor(plugin: LanBridgePlugin) {
    this.plugin = plugin;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.plugin.handleNetwork(call, result);
  }
}

class BackgroundHandler implements MethodCallHandler {
  private plugin: LanBridgePlugin;

  constructor(plugin: LanBridgePlugin) {
    this.plugin = plugin;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.plugin.handleBackground(call, result);
  }
}

class DownloadsHandler implements MethodCallHandler {
  private plugin: LanBridgePlugin;

  constructor(plugin: LanBridgePlugin) {
    this.plugin = plugin;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.plugin.handleDownloads(call, result);
  }
}

/// Local OpenHarmony plugin. It provides the path_provider channel used by the
/// Dart package, a native file/photo/folder picker, and the mobile network
/// helpers.
export class LanBridgePlugin {
  private context: common.UIAbilityContext;
  private pathsChannel: MethodChannel | null = null;
  private pickerChannel: MethodChannel | null = null;
  private networkChannel: MethodChannel | null = null;
  private backgroundChannel: MethodChannel | null = null;
  private downloadsChannel: MethodChannel | null = null;
  private backgroundRunning = false;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  attach(engine: FlutterEngine): void {
    const messenger = engine.getDartExecutor().getBinaryMessenger();
    this.pathsChannel = new MethodChannel(messenger, PATHS_CHANNEL);
    this.pathsChannel.setMethodCallHandler(new PathsHandler(this));
    this.pickerChannel = new MethodChannel(messenger, PICKER_CHANNEL);
    this.pickerChannel.setMethodCallHandler(new PickerHandler(this));
    this.networkChannel = new MethodChannel(messenger, NETWORK_CHANNEL);
    this.networkChannel.setMethodCallHandler(new NetworkHandler(this));
    this.backgroundChannel = new MethodChannel(messenger, BACKGROUND_CHANNEL);
    this.backgroundChannel.setMethodCallHandler(new BackgroundHandler(this));
    this.downloadsChannel = new MethodChannel(messenger, DOWNLOADS_CHANNEL);
    this.downloadsChannel.setMethodCallHandler(new DownloadsHandler(this));
  }

  detach(): void {
    if (this.backgroundRunning) {
      this.stopBackground().catch((error: Error) => {
        Log.w(TAG, `Failed to stop background task: ${this.errorMessage(error)}`);
      });
    }
    this.pathsChannel?.setMethodCallHandler(null);
    this.pathsChannel = null;
    this.pickerChannel?.setMethodCallHandler(null);
    this.pickerChannel = null;
    this.networkChannel?.setMethodCallHandler(null);
    this.networkChannel = null;
    this.backgroundChannel?.setMethodCallHandler(null);
    this.backgroundChannel = null;
    this.downloadsChannel?.setMethodCallHandler(null);
    this.downloadsChannel = null;
  }

  handlePaths(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'getTemporaryDirectory':
      case 'getApplicationCacheDirectory':
        result.success(this.context.cacheDir);
        break;
      case 'getApplicationSupportDirectory':
      case 'getApplicationDocumentsDirectory':
      case 'getLibraryDirectory':
      case 'getDownloadsDirectory':
      case 'getStorageDirectory':
        result.success(this.context.filesDir);
        break;
      case 'getExternalStorageDirectory':
        result.success(this.context.filesDir);
        break;
      case 'getExternalCacheDirectories':
        result.success([this.context.cacheDir]);
        break;
      case 'getExternalStorageDirectories':
        result.success([this.context.filesDir]);
        break;
      default:
        result.notImplemented();
    }
  }

  handlePicker(call: MethodCall, result: MethodResult): void {
    if (call.method === 'pickFiles') {
      const kind = (call.argument('kind') as string) ?? 'any';
      this.pickFiles(kind)
        .then((files: PickedFile[]) => {
          result.success(this.fileMaps(files));
        })
        .catch((error: Error) => {
          result.error('PICKER_FAILED', this.errorMessage(error), null);
        });
      return;
    }
    result.notImplemented();
  }

  handleNetwork(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'acquireMulticastLock':
      case 'releaseMulticastLock':
        result.success(null);
        break;
      default:
        result.notImplemented();
    }
  }

  handleDownloads(call: MethodCall, result: MethodResult): void {
    if (call.method === 'getDir') {
      result.success(this.downloadsDirPath());
      return;
    }
    if (call.method === 'authorize') {
      this.authorizeDownloadsDir()
        .then((path: string) => {
          result.success(path);
        })
        .catch((error: Error) => {
          result.error('DOWNLOADS_AUTH', this.errorMessage(error), null);
        });
      return;
    }
    if (call.method === 'exportFiles') {
      const dir = (call.argument('dir') as string) ?? '';
      const files = (call.argument('files') as string[]) ?? [];
      this.exportFilesToDownloads(dir, files)
        .then((destinations: Array<string | null>) => {
          result.success(destinations);
        })
        .catch((error: Error) => {
          result.error('DOWNLOADS_EXPORT', this.errorMessage(error), null);
        });
      return;
    }
    result.notImplemented();
  }

  handleBackground(call: MethodCall, result: MethodResult): void {
    if (call.method === 'start') {
      this.startBackground()
        .then(() => {
          result.success(null);
        })
        .catch((error: Error) => {
          result.error('BACKGROUND_START', this.errorMessage(error), null);
        });
      return;
    }
    if (call.method === 'stop') {
      this.stopBackground()
        .then(() => {
          result.success(null);
        })
        .catch((error: Error) => {
          result.error('BACKGROUND_STOP', this.errorMessage(error), null);
        });
      return;
    }
    if (call.method === 'notifyComplete') {
      const title = (call.argument('title') as string) ?? '邻传';
      const body = (call.argument('body') as string) ?? '';
      this.showCompletionNotification(title, body)
        .then(() => {
          result.success(null);
        })
        .catch((error: Error) => {
          result.error('NOTIFY_COMPLETE', this.errorMessage(error), null);
        });
      return;
    }
    result.notImplemented();
  }

  /// The pre-defined URI of this app's folder inside the public Download
  /// directory. DOWNLOAD-mode saves land in "Download/<bundleName>" and the
  /// authorization for that folder persists across restarts and reinstalls.
  private downloadsUri(): string {
    return `file://docs/storage/Users/currentUser/Download/${this.context.abilityInfo.bundleName}`;
  }

  /// Returns the sandbox-visible path of "Download/<bundleName>" when the
  /// folder is already authorized, otherwise null.
  private downloadsDirPath(): string | null {
    try {
      const uri = new fileuri.FileUri(this.downloadsUri());
      const stat = fs.statSync(uri.path);
      if (stat.isDirectory()) {
        return uri.path;
      }
    } catch (_) {
      // Not created or not authorized yet.
    }
    return null;
  }

  /// Ensures the persistent authorization for "Download/<bundleName>" by
  /// triggering a DOWNLOAD-mode save (the system saves directly into that
  /// folder without showing a picker UI) and returns its path.
  private async authorizeDownloadsDir(): Promise<string> {
    const existing = this.downloadsDirPath();
    if (existing !== null) {
      return existing;
    }
    const options = new picker.DocumentSaveOptions();
    options.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
    // Avoid pre-creating an empty placeholder file on devices that support it.
    options.autoCreateEmptyFile = false;
    const documentPicker = new picker.DocumentViewPicker(this.context);
    await documentPicker.save(options);
    const path = this.downloadsDirPath();
    if (path === null) {
      throw new Error('Download directory is not accessible');
    }
    return path;
  }

  /// Moves [files] (sandbox paths) into the public downloads [dir]. Resolves
  /// with one entry per input: the destination path on success, or null when
  /// the file was left untouched.
  private async exportFilesToDownloads(
    dir: string,
    files: string[],
  ): Promise<Array<string | null>> {
    if (dir.length === 0 || files.length === 0) {
      return [];
    }
    this.ensureDir(dir);
    const destinations: Array<string | null> = [];
    for (let index = 0; index < files.length; index++) {
      const source = files[index];
      try {
        const destination = this.uniqueDestination(dir, this.baseName(source));
        await fs.copyFile(source, destination);
        fs.unlinkSync(source);
        destinations.push(destination);
      } catch (error) {
        Log.w(TAG, `Failed to export ${source}: ${this.errorMessage(error as Error)}`);
        destinations.push(null);
      }
    }
    return destinations;
  }

  private baseName(path: string): string {
    const trimmed = this.trimTrailingSlash(path);
    return trimmed.substring(trimmed.lastIndexOf('/') + 1);
  }

  /// Appends " (n)" before the extension until the name is free in [dir].
  private uniqueDestination(dir: string, name: string): string {
    const safe = this.safeName(name);
    const dot = safe.lastIndexOf('.');
    const stem = dot > 0 ? safe.substring(0, dot) : safe;
    const ext = dot > 0 ? safe.substring(dot) : '';
    let candidate = `${dir}/${safe}`;
    let counter = 1;
    while (fs.accessSync(candidate)) {
      candidate = `${dir}/${stem} (${counter})${ext}`;
      counter++;
    }
    return candidate;
  }

  private async startBackground(): Promise<void> {
    if (this.backgroundRunning) return;
    try {
      await notificationManager.requestEnableNotification(this.context);
    } catch (_) {
      // The user may have disabled notifications.
    }
    const info: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: this.context.abilityInfo.bundleName,
        abilityName: 'EntryAbility',
      }],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
    };
    const agent = await wantAgent.getWantAgent(info);
    await backgroundTaskManager.startBackgroundRunning(
      this.context,
      backgroundTaskManager.BackgroundMode.DATA_TRANSFER,
      agent,
    );
    this.backgroundRunning = true;
  }

  private async stopBackground(): Promise<void> {
    if (!this.backgroundRunning) return;
    await backgroundTaskManager.stopBackgroundRunning(this.context);
    this.backgroundRunning = false;
  }

  private async showCompletionNotification(
    title: string,
    body: string,
  ): Promise<void> {
    const request: notificationManager.NotificationRequest = {
      id: 1002,
      content: {
        notificationContentType:
          notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: body,
        },
      },
    };
    await notificationManager.publish(request);
  }

  private fileMaps(files: PickedFile[]): Map<string, Object>[] {
    const maps: Map<string, Object>[] = [];
    for (const file of files) {
      const map = new Map<string, Object>();
      map.set('name', file.name);
      map.set('size', file.size);
      map.set('path', file.path);
      maps.push(map);
    }
    return maps;
  }

  private async pickFiles(kind: string): Promise<PickedFile[]> {
    let uris: string[] = [];
    if (kind === 'image' || kind === 'video') {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = kind === 'image'
        ? photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
        : photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
      options.maxSelectNumber = 100;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const selected = await photoPicker.select(options);
      uris = selected.photoUris;
    } else {
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 100;
      options.selectMode = picker.DocumentSelectMode.FILE;
      const documentPicker = new picker.DocumentViewPicker(this.context);
      uris = await documentPicker.select(options);
    }
    return this.copyToCache(uris);
  }

  private async copyToCache(uris: string[]): Promise<PickedFile[]> {
    const files: PickedFile[] = [];
    if (uris.length === 0) {
      return files;
    }
    const directory = `${this.context.cacheDir}/lanbridge_picked/${Date.now()}`;
    this.ensureDir(directory);
    for (let index = 0; index < uris.length; index++) {
      const uri = uris[index];
      const name = this.fileNameFromUri(uri);
      const destination = `${directory}/${index}_${this.safeName(name)}`;
      try {
        const source = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        try {
          fs.copyFileSync(source.fd, destination);
        } finally {
          fs.closeSync(source);
        }
        const stat = fs.statSync(destination);
        files.push(new PickedFile(name, stat.size, destination));
      } catch (error) {
        Log.w(TAG, `Failed to copy picked file ${uri}: ${this.errorMessage(error as Error)}`);
      }
    }
    return files;
  }

  private fileNameFromUri(uri: string): string {
    const clean = uri.split('?')[0];
    const trimmed = this.trimTrailingSlash(clean);
    const raw = trimmed.substring(trimmed.lastIndexOf('/') + 1);
    try {
      return decodeURIComponent(raw);
    } catch (_) {
      return raw;
    }
  }

  private trimTrailingSlash(value: string): string {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  private safeName(name: string): string {
    const safe = name.replace(/[\\/:*?"<>|]/g, '_');
    if (safe.length === 0 || safe === '.' || safe === '..') {
      return 'file';
    }
    return safe;
  }

  private ensureDir(path: string): void {
    try {
      fs.mkdirSync(path, true);
    } catch (_) {
      // The directory already exists or cannot be created.
    }
  }

  private errorMessage(error: Error): string {
    if (error instanceof Error && error.message.length > 0) {
      return error.message;
    }
    return `${error}`;
  }
}
