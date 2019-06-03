#import "FlutterPushyPlugin.h"
#import <flutter_pushy/flutter_pushy-Swift.h>

@implementation FlutterPushyPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterPushyPlugin registerWithRegistrar:registrar];
}
@end
