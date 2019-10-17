#import "NativeVideoViewPlugin.h"
#import <native_video_view/native_video_view-Swift.h>

@implementation NativeVideoViewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNativeVideoViewPlugin registerWithRegistrar:registrar];
}
@end
