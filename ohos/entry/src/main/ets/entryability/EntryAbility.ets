import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { LanBridgePlugin } from '../plugins/LanBridgePlugin';

export default class EntryAbility extends FlutterAbility {
  private lanBridgePlugin: LanBridgePlugin | null = null;

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    this.lanBridgePlugin = new LanBridgePlugin(this.context);
    this.lanBridgePlugin.attach(flutterEngine);
  }

  cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    this.lanBridgePlugin?.detach();
    this.lanBridgePlugin = null;
    super.cleanUpFlutterEngine(flutterEngine);
  }
}
