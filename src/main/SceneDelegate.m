// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


// Project includes
#import "SceneDelegate.h"
#import "ApplicationDelegate.h"
#import "MainTabBarController.h"
#import "Registry.h"
#import "../command/game/PauseGameCommand.h"
#import "../command/HandleDocumentInteractionCommand.h"
#import "../command/SetupApplicationCommand.h"
#ifndef LITTLEGO_UNITTESTS
#import "../diagnostics/CrashReportingHandler.h"
#endif
#import "../go/GoGame.h"
#import "../play/controller/SoundHandling.h"
#import "../shared/ApplicationStateManager.h"
#import "../shared/LongRunningActionCounter.h"


// TODO xxx Study the scene-based lifecycle events
// https://developer.apple.com/documentation/uikit/managing-your-app-s-life-cycle?language=objc#Respond-to-scene-based-life-cycle-events

// TODO xxx TN3187: After adopting scene-based life-cycle ensure to test your
// app in Split View, Slide Over, and Stage Manager on iPad.

// TODO xxx do we need a newDelegate method, as in ApplicationDelegate?

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SceneDelegate.
// -----------------------------------------------------------------------------
@interface SceneDelegate()
@property(nonatomic, retain) UISceneConnectionOptions* pendingSceneConnectionOptions;
@property(nonatomic, retain) NSArray* documentInteractionUrls;
@end


@implementation SceneDelegate

#pragma mark - Synthesize properties

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// ModelProvider protocol.
@synthesize window = _window;

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Shared instance of SceneDelegate.
// -----------------------------------------------------------------------------
static SceneDelegate* sharedDelegate = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared scene delegate object.
// -----------------------------------------------------------------------------
+ (SceneDelegate*) sharedDelegate
{
  assert(sharedDelegate != nil);
  if (! sharedDelegate)
    DDLogError(@"Shared SceneDelegate instance is nil");
  return sharedDelegate;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SceneDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  Registry* sharedRegistry = [Registry sharedRegistry];
  sharedRegistry.sceneDelegate = nil;
  sharedRegistry.windowProvider = nil;
  sharedRegistry.magnifyingGlassOwner = nil;

  self.window = nil;
  self.pendingSceneConnectionOptions = nil;
  self.documentInteractionUrls = nil;

  if (self == sharedDelegate)
    sharedDelegate = nil;

  [super dealloc];
}

#pragma mark - UIWindowSceneDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UIWindowSceneDelegate method.
// -----------------------------------------------------------------------------
      - (void) scene:(UIScene*)scene
willConnectToSession:(UISceneSession*)session
             options:(UISceneConnectionOptions*)connectionOptions
{
  DDLogInfo(@"scene:willConnectToSession:options:() received");

  // Make the single instance of this class available as a "shared object", or
  // Singleton.
  sharedDelegate = self;

  // Also make the shared object available via registry
  Registry* sharedRegistry = [Registry sharedRegistry];
  sharedRegistry.sceneDelegate = self;
  sharedRegistry.windowProvider = self;

  if (! [scene isKindOfClass:[UIWindowScene class]])
  {
    // TODO xxx Raise exception => fail early?
    DDLogWarn(@"scene:willConnectToSession:options:() received for a scene that is not a UIWindowScene");
    return;
  }

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];

  UIWindowScene* windowScene = (UIWindowScene*)scene;

  // Depends on user defaults having been set up in the application delegate
  // (e.g. MainTabBarController wants to restore tab order)
  [self setupGUI:windowScene];

  // Depends on
  // - User defaults having been set up in the application delegate (for
  //   crashReportingModel)
  // - setupGUI, for setting up self.window and its rootViewController property,
  //   which is required to present the alert that asks the user for permission
  //   to submit a crash report
  [self setupCrashReporting];

  // Further setup steps are executed in a secondary thread so that we can
  // display a progress HUD
  [[[[SetupApplicationCommand alloc] init] autorelease] submit];

  // Options are handled in sceneDidBecomeActive:()
  self.pendingSceneConnectionOptions = connectionOptions;

  // Document interaction URLs are detected in scene:openURLContexts:()
  self.documentInteractionUrls = nil;
}

// -----------------------------------------------------------------------------
/// @brief UIWindowSceneDelegate method.
///
/// Invoked to notify this delegate that the scene is about to become inactive.
///
/// Known events that triggered this when it was still an application delegate
/// method:
/// - Any interrupt (e.g. incoming phone call, calling up the multitasking UI)
/// - Anything that will put the app in the background (e.g. Home button, screen
///   locking)
// -----------------------------------------------------------------------------
- (void) sceneWillResignActive:(UIScene*)scene
{
  DDLogInfo(@"sceneWillResignActive:() received");

  GoGame* game = [GoGame sharedGame];
  if (GoGameTypeComputerVsComputer == game.type)
  {
    switch (game.state)
    {
      case GoGameStateGameHasStarted:
        [[[[PauseGameCommand alloc] init] autorelease] submit];
        break;
      default:
        break;
    }
  }

  [ApplicationDelegate sharedDelegate].soundHandling.disabled = true;
}

// -----------------------------------------------------------------------------
/// @brief UIWindowSceneDelegate method.
///
/// Invoked to notify this delegate that the scene has become active (again).
// -----------------------------------------------------------------------------
- (void) sceneDidBecomeActive:(UIScene*)scene
{
  DDLogInfo(@"sceneDidBecomeActive:() received");

  [ApplicationDelegate sharedDelegate].soundHandling.disabled = false;

  // Send this notification just in case something changed in the documents
  // folder since the app was deactivated. Note: This is not just laziness - if
  // the user really *DID* change something via the file sharing feature of
  // iTunes, we won't be notified in any special way. The only thing that
  // happens in such a case is deactivation and reactivation.
  [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];

  if (self.pendingSceneConnectionOptions)
  {
    // We are only interested in URLs. If the options contain anything else
    // (e.g. shortcut item, handoff, ...) we ignore it.
    [self scene:scene openURLContexts:self.pendingSceneConnectionOptions.URLContexts];

    self.pendingSceneConnectionOptions = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief UIWindowSceneDelegate method.
///
/// Invoked to notify this delegate that the scene has entered the background
/// and is about to be suspended.
///
/// This method must complete within 5 seconds.
// -----------------------------------------------------------------------------
- (void) sceneDidEnterBackground:(UIScene*)scene
{
  DDLogInfo(@"sceneDidEnterBackground:() received");

  [[ApplicationDelegate sharedDelegate] writeUserDefaults];
  [[ApplicationStateManager sharedManager] applicationDidEnterBackground];
}

// -----------------------------------------------------------------------------
/// @brief UIWindowSceneDelegate method.
///
/// Invoked to notify this delegate that the scene is about to come to
/// the foreground (after having been suspended in the background).
// -----------------------------------------------------------------------------
- (void) sceneWillEnterForeground:(UIScene*)scene
{
  DDLogInfo(@"sceneWillEnterForeground:() received");

  [[ApplicationStateManager sharedManager] applicationWillEnterForeground];
}

// -----------------------------------------------------------------------------
/// @brief UIWindowSceneDelegate method.
///
/// Asks the delegate to open the resources identified by @a urlContexts.
///
/// This method is invoked both when a scene is created (typically during
/// application launch) and when the scene already exists, i.e. while the
/// application is already running.
///
/// The implementation ignores all URLs except file URLs. File URLs are expected
/// to be references to .sgf files and are handed off for processing to
/// delayedDocumentInteraction().
// -----------------------------------------------------------------------------
 - (void) scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)urlContexts
{
  if (! urlContexts || urlContexts.count == 0)
    return;

  NSMutableArray* documentInteractionUrls = [NSMutableArray array];

  for (UIOpenURLContext* urlContext in urlContexts)
  {
    NSURL* url = urlContext.URL;
    if ([url isFileURL])
      [documentInteractionUrls addObject:url];
  }

  if (documentInteractionUrls.count > 0)
  {
    self.documentInteractionUrls = documentInteractionUrls;
    [self delayedDocumentInteraction];
  }
}

#pragma mark - Setting up the GUI

// -----------------------------------------------------------------------------
/// @brief Sets up the objects used to manage the GUI.
// -----------------------------------------------------------------------------
- (void) setupGUI:(UIWindowScene*)windowScene
{
  [self setupWindow:windowScene];
  [self setupWindowRootViewController];
  [self.window makeKeyAndVisible];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupGui.
// -----------------------------------------------------------------------------
- (void) setupWindow:(UIWindowScene*)windowScene
{
  self.window = [[[UIWindow alloc] initWithWindowScene:windowScene] autorelease];

  // Don't set up a default window background color - it is the job of the
  // root view controllers of the MainTabBarController to do this, and to use
  // extended layout properly so that their background extends behind the
  // status bar. If the window ever becomes visible it will show with a black
  // background.
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupGui.
// -----------------------------------------------------------------------------
- (void) setupWindowRootViewController
{
  // It's important that a UITabBarController is used directly as the window
  // root VC. If UITabBarController is used as the child VC of some other view
  // controller, the extended layout handling of navigation bars does not work
  // correctly.
  MainTabBarController* mainTabBarController = [[[MainTabBarController alloc] init] autorelease];
  [Registry sharedRegistry].magnifyingGlassOwner = mainTabBarController;

  self.window.rootViewController = mainTabBarController;
  // UIWindow automatically adds the root VC's view as a subview to itself.
  // It also manages the layout of that view, so there is no need to use
  // Auto Layout and install constraints in UIWindow. In fact, doing so causes
  // trouble later on during the application's lifetime, when VCs are dismissed
  // after being presented modally. The problem is discussed here:
  // https://stackoverflow.com/q/23313112/1054378
}

#pragma mark - Setting up the crash reporting service

// -----------------------------------------------------------------------------
/// @brief Sets up the crash reporting service.
// -----------------------------------------------------------------------------
- (void) setupCrashReporting
{
#ifdef LITTLEGO_NDEBUG
#ifndef LITTLEGO_UNITTESTS
  // One way to disable everything programmatically is this:
  //   [[FIRApp defaultApp] setDataCollectionDefaultEnabled:NO];
  // Unfortunately this also disables crash reporting.

  [FIRApp configure];

  CrashReportingModel* crashReportingModel = [ApplicationDelegate sharedDelegate].crashReportingModel;
  CrashReportingHandler* crashReportingHandler = [[[CrashReportingHandler alloc] initWithModel:crashReportingModel] autorelease];
  [crashReportingHandler handleUnsentCrashReportsOrDoNothing];
#endif
#endif
}

#pragma mark - Document interaction handling

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedDocumentInteraction];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for handling delayed document interaction.
///
/// Document interaction handling is delayed while a long running action is in
/// progress.
/// - A typical long running action relevant for document interaction
///   handling is SetupApplicationCommand. This command is executed when the
///   application launches and the application's scene is created.
/// - Other long running actions could be in progress if the application is
///   already running and the application's scene already exists.
///
/// In both cases, document interaction handling needs to wait until the long
/// running action ends.
// -----------------------------------------------------------------------------
- (void) delayedDocumentInteraction
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;

  if (! self.documentInteractionUrls)
    return;
  NSArray* documentInteractionUrls = self.documentInteractionUrls;
  self.documentInteractionUrls = nil;

  DDLogInfo(@"Document interaction wants to open URLs %@", documentInteractionUrls);

  // Control returns before the .sgf files are actually imported
  [[[[HandleDocumentInteractionCommand alloc] initWithUrls:documentInteractionUrls] autorelease] submit];
}

@end
