/*****************************************************************************
 * VLCAppDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2019 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Luis Fernandes <zipleen # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Soomin Lee <TheHungryBu # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLC-Swift.h"

#import <AppCenter/AppCenter.h>
#import <AppCenterAnalytics/AppCenterAnalytics.h>
#import <AppCenterCrashes/AppCenterCrashes.h>

NSString *VLCAppCenterAppID = @"0114ca8e-2652-44ce-588d-2ebd035c3577";

#define BETA_DISTRIBUTION 1

@interface VLCAppDelegate ()
{
    BOOL _isComingFromHandoff;
    VLCKeychainCoordinator *_keychainCoordinator;
    AppCoordinator *appCoordinator;
    UITabBarController *rootViewController;
}

@end

@implementation VLCAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUInteger appThemeIndex = kVLCSettingAppThemeBright;
    if (@available(iOS 13.0, *)) {
        appThemeIndex = kVLCSettingAppThemeSystem;
    }

    NSDictionary *appDefaults = @{kVLCSettingAppTheme : @(appThemeIndex),
                                  kVLCSettingPasscodeAllowFaceID : @(1),
                                  kVLCSettingPasscodeAllowTouchID : @(1),
                                  kVLCSettingContinueAudioInBackgroundKey : @(YES),
                                  kVLCSettingStretchAudio : @(YES),
                                  kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue,
                                  kVLCSettingSkipLoopFilter : kVLCSettingSkipLoopFilterNonRef,
                                  kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue,
                                  kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue,
                                  kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue,
                                  kVLCSettingSubtitlesBoldFont: kVLCSettingSubtitlesBoldFontDefaultValue,
                                  kVLCSettingDeinterlace : kVLCSettingDeinterlaceDefaultValue,
                                  kVLCSettingHardwareDecoding : kVLCSettingHardwareDecodingDefault,
                                  kVLCSettingNetworkCaching : kVLCSettingNetworkCachingDefaultValue,
                                  kVLCSettingVolumeGesture : @(YES),
                                  kVLCSettingPlayPauseGesture : @(YES),
                                  kVLCSettingBrightnessGesture : @(YES),
                                  kVLCSettingSeekGesture : @(YES),
                                  kVLCSettingCloseGesture : @(YES),
                                  kVLCSettingVariableJumpDuration : @(NO),
                                  kVLCSettingVideoFullscreenPlayback : @(YES),
                                  kVLCSettingContinuePlayback : @(1),
                                  kVLCSettingContinueAudioPlayback : @(1),
                                  kVLCSettingWiFiSharingIPv6 : kVLCSettingWiFiSharingIPv6DefaultValue,
                                  kVLCSettingNetworkRTSPTCP : @(NO),
                                  kVLCSettingEqualizerProfile : kVLCSettingEqualizerProfileDefaultValue,
                                  kVLCSettingEqualizerProfileDisabled : @(YES),
                                  kVLCSettingPlaybackForwardSkipLength : kVLCSettingPlaybackForwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLength : kVLCSettingPlaybackBackwardSkipLengthDefaultValue,
                                  kVLCSettingOpenAppForPlayback : kVLCSettingOpenAppForPlaybackDefaultValue,
                                  kVLCAutomaticallyPlayNextItem : @(YES),
                                  kVLCSettingEnableMediaCellTextScrolling : @(NO),
                                  kVLCSettingShowThumbnails : kVLCSettingShowThumbnailsDefaultValue,
                                  kVLCSettingShowArtworks : kVLCSettingShowArtworksDefaultValue,
                                  kVLCSettingBackupMediaLibrary : kVLCSettingBackupMediaLibraryDefaultValue,
                                  kVLCSettingCastingAudioPassthrough : @(NO),
                                  kVLCSettingCastingConversionQuality : @(2),
                                  kVLCForceSMBV1 : @(YES),
                                  @"kVLCAudioLibraryGridLayoutALBUMS" : @(YES),
                                  @"kVLCAudioLibraryGridLayoutARTISTS" : @(YES),
                                  @"kVLCAudioLibraryGridLayoutGENRES" : @(YES),
                                  @"kVLCVideoLibraryGridLayoutALL_VIDEOS" : @(YES),
                                  @"kVLCVideoLibraryGridLayoutVIDEO_GROUPS" : @(YES),
    };
    [defaults registerDefaults:appDefaults];
}

- (void)setupApplicationCoordinator
{
    void (^setupAppCoordinator)(void) = ^{
        self->appCoordinator = [[AppCoordinator alloc] initWithTabBarController:self->rootViewController];
        [self->appCoordinator start];
    };
    [self validatePasscodeIfNeededWithCompletion:setupAppCoordinator];
}

- (void)configureShortCutItemsWithApplication:(UIApplication *)application
{
    /* add our static shortcut items the dynamic way to ease l10n and dynamic elements to be introduced later */
    if (application.shortcutItems == nil || application.shortcutItems.count < 4) {
        UIApplicationShortcutItem *localVideoItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutLocalVideo
                                                                                     localizedTitle:NSLocalizedString(@"VIDEO",nil)
                                                                                  localizedSubtitle:nil
                                                                                               icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Video"]
                                                                                           userInfo:nil];
        UIApplicationShortcutItem *localAudioItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutLocalAudio
                                                                                     localizedTitle:NSLocalizedString(@"AUDIO",nil)
                                                                                  localizedSubtitle:nil
                                                                                               icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Audio"]
                                                                                           userInfo:nil];
        UIApplicationShortcutItem *localplaylistItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutPlaylist
                                                                                        localizedTitle:NSLocalizedString(@"PLAYLISTS",nil)
                                                                                     localizedSubtitle:nil
                                                                                                  icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Playlist"]
                                                                                              userInfo:nil];
        UIApplicationShortcutItem *networkItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutNetwork
                                                                                  localizedTitle:NSLocalizedString(@"NETWORK",nil)
                                                                               localizedSubtitle:nil
                                                                                            icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Network"]
                                                                                        userInfo:nil];
        application.shortcutItems = @[localVideoItem, localAudioItem, localplaylistItem, networkItem];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MSACAppCenter start:VLCAppCenterAppID withServices:@[[MSACAnalytics class], [MSACCrashes class]]];

    self.orientationLock = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    rootViewController = [UITabBarController new];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    [VLCAppearanceManager setupAppearanceWithTheme:PresentationTheme.current];
    [self setupApplicationCoordinator];

    [self configureShortCutItemsWithApplication:application];

    return YES;
}

#pragma mark - Handoff

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType
{
    return [userActivityType isEqualToString:kVLCUserActivityPlaying];
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *))restorationHandler
{
    VLCMLMedia *media = [appCoordinator mediaForUserActivity:userActivity];
    if (!media) return NO;

    [self validatePasscodeIfNeededWithCompletion:^{
        [[VLCPlaybackService sharedInstance] playMedia:media];
    }];
    return YES;
}

- (void)application:(UIApplication *)application
didFailToContinueUserActivityWithType:(NSString *)userActivityType
              error:(NSError *)error
{
    if (error.code != NSUserCancelledError){
        //TODO: present alert
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    for (id<VLCURLHandler> handler in URLHandlers.handlers) {
        if ([handler canHandleOpenWithUrl:url options:options]) {
            if ([handler performOpenWithUrl:url options:options]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    //Touch ID is shown 
    if ([_window.rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]){
        UINavigationController *navCon = (UINavigationController *)_window.rootViewController.presentedViewController;
        if ([navCon.topViewController isKindOfClass:[PasscodeLockController class]]){
            return;
        }
    }
    [self validatePasscodeIfNeededWithCompletion:^{
        //TODO: handle updating the videoview and
        if ([VLCPlaybackService sharedInstance].isPlaying){
            //TODO: push playback
        }
    }];
    [[MLMediaLibrary sharedMediaLibrary] applicationWillExit];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (!_isComingFromHandoff) {
        [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
      //  [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];
        [[VLCPlaybackService sharedInstance] recoverDisplayedMetadata];
    } else if(_isComingFromHandoff) {
        _isComingFromHandoff = NO;
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    [appCoordinator handleShortcutItem:shortcutItem];
}

#pragma mark - pass code validation
- (VLCKeychainCoordinator *)keychainCoordinator
{
    if (!_keychainCoordinator) {
        _keychainCoordinator = [[VLCKeychainCoordinator alloc] init];
    }
    return _keychainCoordinator;
}

- (void)validatePasscodeIfNeededWithCompletion:(void(^)(void))completion
{
    if ([VLCKeychainCoordinator passcodeLockEnabled]) {
        //TODO: Dimiss playback
        [self.keychainCoordinator validatePasscodeWithCompletion:completion];
    } else {
        completion();
    }
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return self.orientationLock;
}

@end
