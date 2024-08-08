#import "AudioUtils.h"
#import "LivekitReactNative.h"
#import "WebRTCModule.h"
#import "WebRTCModuleOptions.h"
#import <LiveKitWebRTC/RTCAudioSession.h>
#import <LiveKitWebRTC/RTCAudioSessionConfiguration.h>
#import <AVFAudio/AVFAudio.h>
#import <AVKit/AVKit.h>

@implementation LivekitReactNative
RCT_EXPORT_MODULE();

-(instancetype)init {
    if(self = [super init]) {
        
        LKRTCAudioSessionConfiguration* config = [[LKRTCAudioSessionConfiguration alloc] init];
        [config setCategory:AVAudioSessionCategoryPlayAndRecord];
        [config setCategoryOptions:
             AVAudioSessionCategoryOptionAllowAirPlay|
             AVAudioSessionCategoryOptionAllowBluetooth|
             AVAudioSessionCategoryOptionAllowBluetoothA2DP|
             AVAudioSessionCategoryOptionDefaultToSpeaker
        ];
        [config setMode:AVAudioSessionModeVideoChat];
        [LKRTCAudioSessionConfiguration setWebRTCConfiguration: config];
        return self;
    } else {
        return nil;
    }
}

+(BOOL)requiresMainQueueSetup {
    return NO;
}

+(void)setup {
    LKRTCDefaultVideoEncoderFactory *videoEncoderFactory = [[LKRTCDefaultVideoEncoderFactory alloc] init];
    LKRTCVideoEncoderFactorySimulcast *simulcastVideoEncoderFactory = [[LKRTCVideoEncoderFactorySimulcast alloc] initWithPrimary:videoEncoderFactory fallback:videoEncoderFactory];
    WebRTCModuleOptions *options = [WebRTCModuleOptions sharedInstance];
    options.videoEncoderFactory = simulcastVideoEncoderFactory;
}

/// Configure default audio config for WebRTC
RCT_EXPORT_METHOD(configureAudio:(NSDictionary *) config){
    NSDictionary *iOSConfig = [config objectForKey:@"ios"];
    if(iOSConfig == nil) {
        return;
    }
    
    NSString * defaultOutput = [iOSConfig objectForKey:@"defaultOutput"];
    if (defaultOutput == nil) {
        defaultOutput = @"speaker";
    }
    
    LKRTCAudioSessionConfiguration* rtcConfig = [[LKRTCAudioSessionConfiguration alloc] init];
    [rtcConfig setCategory:AVAudioSessionCategoryPlayAndRecord];
    
    if([defaultOutput isEqualToString:@"earpiece"]){
        [rtcConfig setCategoryOptions:
         AVAudioSessionCategoryOptionAllowAirPlay|
         AVAudioSessionCategoryOptionAllowBluetooth|
         AVAudioSessionCategoryOptionAllowBluetoothA2DP];
        [rtcConfig setMode:AVAudioSessionModeVoiceChat];
    } else {
        [rtcConfig setCategoryOptions:
         AVAudioSessionCategoryOptionAllowAirPlay|
         AVAudioSessionCategoryOptionAllowBluetooth|
         AVAudioSessionCategoryOptionAllowBluetoothA2DP|
         AVAudioSessionCategoryOptionDefaultToSpeaker];
        [rtcConfig setMode:AVAudioSessionModeVideoChat];
    }
    [LKRTCAudioSessionConfiguration setWebRTCConfiguration: rtcConfig];
}

RCT_EXPORT_METHOD(startAudioSession){
}

RCT_EXPORT_METHOD(stopAudioSession){
    
}

RCT_EXPORT_METHOD(showAudioRoutePicker){
    if (@available(iOS 11.0, *)) {
        AVRoutePickerView *routePickerView = [[AVRoutePickerView alloc] init];
        NSArray<UIView *> *subviews = routePickerView.subviews;
        for (int i = 0; i < subviews.count; i++) {
            UIView *subview = [subviews objectAtIndex:i];
            if([subview isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *) subview;
                [button sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            }
        }
    }
}

RCT_EXPORT_METHOD(getAudioOutputsWithResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject){
    resolve(@[@"default", @"force_speaker"]);
}
RCT_EXPORT_METHOD(selectAudioOutput:(NSString *)deviceId
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject){
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    
    if ([deviceId isEqualToString:@"default"]) {
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
    } else if ([deviceId isEqualToString:@"force_speaker"]) {
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    }
    
    if (error != nil) {
        reject(@"selectAudioOutput error", error.localizedDescription, error);
    } else {
        resolve(nil);
    }
}


/// Configure audio config for WebRTC
RCT_EXPORT_METHOD(setAppleAudioConfiguration:(NSDictionary *) configuration){
  LKRTCAudioSession* session = [LKRTCAudioSession sharedInstance];
    LKRTCAudioSessionConfiguration* config = [LKRTCAudioSessionConfiguration webRTCConfiguration];

  NSString* appleAudioCategory = configuration[@"audioCategory"];
  NSArray* appleAudioCategoryOptions = configuration[@"audioCategoryOptions"];
  NSString* appleAudioMode = configuration[@"audioMode"];
  
  [session lockForConfiguration];

  if(appleAudioCategoryOptions != nil) {
    config.categoryOptions = 0;
    for(NSString* option in appleAudioCategoryOptions) {
      if([@"mixWithOthers" isEqualToString:option]) {
        config.categoryOptions |= AVAudioSessionCategoryOptionMixWithOthers;
      } else if([@"duckOthers" isEqualToString:option]) {
        config.categoryOptions |= AVAudioSessionCategoryOptionDuckOthers;
      } else if([@"allowBluetooth" isEqualToString:option]) {
        config.categoryOptions |= AVAudioSessionCategoryOptionAllowBluetooth;
      } else if([@"allowBluetoothA2DP" isEqualToString:option]) {
        config.categoryOptions |= AVAudioSessionCategoryOptionAllowBluetoothA2DP;
      } else if([@"allowAirPlay" isEqualToString:option]) {
        config.categoryOptions |= AVAudioSessionCategoryOptionAllowAirPlay;
      } else if([@"defaultToSpeaker" isEqualToString:option]) {
        config.categoryOptions |= AVAudioSessionCategoryOptionDefaultToSpeaker;
      }
    }
  }

  if(appleAudioCategory != nil) {
    config.category = [AudioUtils audioSessionCategoryFromString:appleAudioCategory];
    [session setCategory:config.category withOptions:config.categoryOptions error:nil];
  }

  if(appleAudioMode != nil) {
    config.mode = [AudioUtils audioSessionModeFromString:appleAudioMode];
    [session setMode:config.mode error:nil];
  }

  [session unlockForConfiguration];
}
@end
