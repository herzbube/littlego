// -----------------------------------------------------------------------------
// Copyright 2011-2016 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @mainpage
///
/// Little Go is an iOS application that lets the user play the game of Go
/// against another human, or against the computer.
///
/// The two main classes of the project are ApplicationDelegate and GoGame.
///
/// The main file to read for new developers is README.developer.
// -----------------------------------------------------------------------------


// Project includes
#import "ApplicationDelegate.h"
#import "MainMenuPresenter.h"
#import "WindowRootViewController.h"
#import "../gtp/GtpClient.h"
#import "../gtp/GtpEngine.h"
#import "../gtp/GtpUtilities.h"
#import "../gtp/PipeStreamBuffer.h"
#import "../newgame/NewGameModel.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/GtpEngineProfile.h"
#import "../player/PlayerModel.h"
#import "../play/boardposition/BoardPositionNavigationManager.h"
#import "../play/boardview/layer/BoardViewCGLayerCache.h"
#import "../play/controller/SoundHandling.h"
#import "../play/gameaction/GameActionManager.h"
#import "../play/model/BoardPositionModel.h"
#import "../play/model/BoardViewMetrics.h"
#import "../play/model/BoardViewModel.h"
#import "../play/model/ScoringModel.h"
#import "../archive/ArchiveViewModel.h"
#import "../diagnostics/BugReportUtilities.h"
#ifndef LITTLEGO_UNITTESTS
#import "../diagnostics/CrashReportingHandler.h"
#endif
#import "../diagnostics/CrashReportingModel.h"
#import "../diagnostics/GtpCommandModel.h"
#import "../diagnostics/GtpLogModel.h"
#import "../diagnostics/LoggingModel.h"
#import "../command/CommandProcessor.h"
#import "../command/HandleDocumentInteractionCommand.h"
#import "../command/SetupApplicationCommand.h"
#import "../command/diagnostics/RestoreBugReportUserDefaultsCommand.h"
#import "../command/game/PauseGameCommand.h"
#import "../go/GoGame.h"
#import "../shared/ApplicationStateManager.h"
#import "../shared/LayoutManager.h"
#import "../shared/LongRunningActionCounter.h"
#import "../ui/MagnifyingViewModel.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiSettingsModel.h"
#import "../utility/PathUtilities.h"
#import "../utility/UserDefaultsUpdater.h"

// System includes
#include <string>
#include <vector>
#include <sys/stat.h>  // for mkfifo


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ApplicationDelegate.
// -----------------------------------------------------------------------------
@interface ApplicationDelegate()
@property(nonatomic, retain) DDFileLogger* fileLogger;
/// @brief Is true if application:OpenURL:sourceApplication:annotation: should
/// not handle document interaction because
/// application:didFinishLaunchingWithOptions: already does the handling.
@property(nonatomic, assign) bool applicationOpenURLShouldIgnoreNextDocumentInteraction;
@end


@implementation ApplicationDelegate

// -----------------------------------------------------------------------------
/// @brief Shared instance of ApplicationDelegate.
// -----------------------------------------------------------------------------
static ApplicationDelegate* sharedDelegate = nil;
static std::streambuf* inputPipeStreamBuffer = nullptr;
static std::streambuf* outputPipeStreamBuffer = nullptr;

// -----------------------------------------------------------------------------
/// @brief Returns the shared application delegate object.
///
/// TODO: Find out why Doxygen does not generate documentation for this method.
/// Cf. the convenience constructor in GtpClient, for which documentation is
/// generated.
// -----------------------------------------------------------------------------
+ (ApplicationDelegate*) sharedDelegate
{
  assert(sharedDelegate != nil);
  if (! sharedDelegate)
    DDLogError(@"Shared ApplicationDelegate instance is nil");
  return sharedDelegate;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new ApplicationDelegate object and returns that object.
/// From now on, sharedDelegate() also returns the same object.
///
/// This method exists for the purpose of unit testing. In a normal environment
/// the application delegate is created when the application's main nib file is
/// loaded.
// -----------------------------------------------------------------------------
+ (ApplicationDelegate*) newDelegate
{
  sharedDelegate = [[[ApplicationDelegate alloc] init] autorelease];
  sharedDelegate.applicationLaunchMode = ApplicationLaunchModeNormal;
  sharedDelegate.writeUserDefaultsEnabled = false;
  return sharedDelegate;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ApplicationDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.window = nil;
  self.documentInteractionURL = nil;
  self.gtpClient = nil;
  self.gtpEngine = nil;
  // Observes BoardViewModel, so must be deallocated first
  self.boardViewMetrics = nil;
  self.theNewGameModel = nil;
  self.playerModel = nil;
  self.gtpEngineProfileModel = nil;
  self.boardViewModel = nil;
  self.boardPositionModel = nil;
  self.scoringModel = nil;
  self.soundHandling = nil;
  self.game = nil;
  self.archiveViewModel = nil;
  self.gtpLogModel = nil;
  self.gtpCommandModel = nil;
  self.crashReportingModel = nil;
  self.loggingModel = nil;
  self.uiSettingsModel = nil;
  self.magnifyingViewModel = nil;
  self.fileLogger = nil;
  [MainMenuPresenter releaseSharedPresenter];
  [BoardPositionNavigationManager releaseSharedNavigationManager];
  [GameActionManager releaseSharedGameActionManager];
  [BoardViewCGLayerCache releaseSharedCache];
  [CommandProcessor releaseSharedProcessor];
  [LongRunningActionCounter releaseSharedCounter];
  [ApplicationStateManager releaseSharedManager];
  [LayoutManager releaseSharedManager];
  if (self == sharedDelegate)
    sharedDelegate = nil;

  if (inputPipeStreamBuffer)
  {
    delete inputPipeStreamBuffer;
    inputPipeStreamBuffer = nullptr;
  }
  if (outputPipeStreamBuffer)
  {
    delete outputPipeStreamBuffer;
    outputPipeStreamBuffer = nullptr;
  }

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Performs major application initialization tasks.
///
/// This method is invoked after the main .nib file (if there is any) has been
/// loaded, but while the application is still in the inactive state.
// -----------------------------------------------------------------------------
- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  // Make the single instance of this class available as a "shared object", or
  // Singleton.
  sharedDelegate = self;

  // Don't release with this set to true :-)
  self.launchImageModeEnabled = false;

  // Enable in normal (i.e. not unit testing) environment
  self.writeUserDefaultsEnabled = true;

  // Don't change the following sequence without thoroughly checking the
  // dependencies
  // The following steps have no dependencies
  [self setupResourceBundle];
  [self setupLogging];
  [self setupApplicationLaunchMode];
  bool setupDocumentInteractionSuccess = [self setupDocumentInteraction:launchOptions];
  [self setupFolders];
  // Depends on setupResourceBundle for reading registration domain defaults
  [self setupRegistrationDomain];
  // Depends on setupRegistrationDomain to provide fallback values if no user
  // preferences exist
  [self setupUserDefaults];
  // Depends on setupUserDefaults (for boardViewModel)
  [self setupSound];
  // Has no dependencies
  [self setupFuego];
  // Depends on setupUserDefaults (e.g. MainTabBarController wants to restore
  // tab order)
  [self setupGUI];
  // Depends on
  // - setupResourceBundle, for reading the Fabric API key
  // - setupUserDefaults, for crashReportingModel
  // - setupGUI, for setting up self.window and its rootViewController property,
  //   which is required to present the alert that asks the user for permission
  //   to submit a crash report
  [self setupCrashReporting];

  // Further setup steps are executed in a secondary thread so that we can
  // display a progress HUD
  [[[[SetupApplicationCommand alloc] init] autorelease] submit];

  BOOL canHandleURL = setupDocumentInteractionSuccess ? YES : NO;
  return canHandleURL;
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application is about to
/// become inactive.
///
/// Known events that trigger this:
/// - Modifying an app's document folder via iTunes' "File sharing" feature
///   (only prior to iOS 5)
/// - Any interrupt (e.g. incoming phone call, calling up the multitasking UI)
/// - Anything that will put the app in the background (e.g. Home button, screen
///   locking)
// -----------------------------------------------------------------------------
- (void) applicationWillResignActive:(UIApplication*)application
{
  DDLogInfo(@"applicationWillResignActive:() received");

  if (GoGameTypeComputerVsComputer == self.game.type)
  {
    switch (self.game.state)
    {
      case GoGameStateGameHasStarted:
        [[[[PauseGameCommand alloc] init] autorelease] submit];
        break;
      default:
        break;
    }
  }
  self.soundHandling.disabled = true;
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application has become
/// active (again).
// -----------------------------------------------------------------------------
- (void) applicationDidBecomeActive:(UIApplication*)application
{
  DDLogInfo(@"applicationDidBecomeActive:() received");

  self.soundHandling.disabled = false;
  // Send this notification just in case something changed in the documents
  // folder since the app was deactivated. Note: This is not just laziness - if
  // the user really *DID* change something via the file sharing feature of
  // iTunes, we won't be notified in any special way. The only thing that
  // happens in such a case is deactivation and reactivation.
  // Update for iOS 5: This no longer works in iOS 5
  [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application has entered the
/// background and is about to be suspended.
///
/// This method must complete within 5 seconds.
// -----------------------------------------------------------------------------
- (void) applicationDidEnterBackground:(UIApplication*)application
{
  DDLogInfo(@"applicationDidEnterBackground:() received");

  [self writeUserDefaults];
  [[ApplicationStateManager sharedManager] applicationDidEnterBackground];
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that the application is about to
/// come to the foreground (after having been suspended in the background).
// -----------------------------------------------------------------------------
- (void) applicationWillEnterForeground:(UIApplication*)application
{
  DDLogInfo(@"applicationWillEnterForeground:() received");
  [[ApplicationStateManager sharedManager] applicationWillEnterForeground];
}

// -----------------------------------------------------------------------------
/// @brief Invoked to notify this delegate that system memory is running low,
/// combined with the imperative request to free as much memory as possible.
// -----------------------------------------------------------------------------
- (void) applicationDidReceiveMemoryWarning:(UIApplication*)application
{
  // We can't do anything about the situation since it's Fuego that uses up too
  // much memory, probably due to an "enthusiastic" maximum memory setting
  // in the current GTP engine profile.
  DDLogWarn(@"ApplicationDelegate received memory warning");
  GtpEngineProfile* profile = self.gtpEngineProfileModel.activeProfile;
  if (profile)
    DDLogWarn(@"Active GtpEngineProfile is %@, max. memory is %d", profile.name, profile.fuegoMaxMemory);
  else
    DDLogWarn(@"No active GtpEngineProfile");

  // Save whatever data we can before the system kills the application
  [self writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Asks the delegate to open a resource identified by @a url.
///
/// This method is invoked both during application launch and while the
/// application is already running, to open an .sgf file passed into the app
/// via the system's document interaction mechanism.
// -----------------------------------------------------------------------------
- (BOOL) application:(UIApplication*)application
             openURL:(NSURL*)url
   sourceApplication:(NSString*)sourceApplication
          annotation:(id)annotation
{
  DDLogInfo(@"Document interaction wants to open URL %@", url);
  if (! [url isFileURL])
    return NO;
  if (self.applicationOpenURLShouldIgnoreNextDocumentInteraction)
  {
    self.applicationOpenURLShouldIgnoreNextDocumentInteraction = false;
    return NO;
  }
  self.documentInteractionURL = url;
  // Control returns before the .sgf file is actually loaded
  [[[[HandleDocumentInteractionCommand alloc] init] autorelease] submit];
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the crash reporting service.
// -----------------------------------------------------------------------------
- (void) setupCrashReporting
{
#ifndef LITTLEGO_UNITTESTS
  // TODO: Conditional compile this only when building for App Distribution

  // Reading the bundle resource results in a string with a trailing newline,
  // character because the resource file also contains a newline. Fabric does
  // not handle such extraneous whitespace characters, so we have to trim them
  // ourselves.
  NSString* fabricAPIKey = [[self contentOfTextResource:fabricAPIKeyResource] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (fabricAPIKey != nil)
  {
    // TODO: Don't start the service if the API key has a pre-determined "dummy"
    // value. This lets collaborators run the app without the need for
    // disseminating the API key.

    CrashReportingHandler* crashReportingHandler = [[[CrashReportingHandler alloc] initWithModel:self.crashReportingModel] autorelease];
    // Crashlytics calls [Fabric with:...] behind the scenes
    [Crashlytics startWithAPIKey:fabricAPIKey delegate:crashReportingHandler];
  }
  else
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to obtain Fabric API key from resources! Refusing to continue without crash reporting service."];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
#endif
}

// -----------------------------------------------------------------------------
/// @brief Sets up application logging.
// -----------------------------------------------------------------------------
- (void) setupLogging
{
  if (! self.fileLogger)
  {
    self.fileLogger = [[[DDFileLogger alloc] init] autorelease];
    self.fileLogger.rollingFrequency = 0;
    // If you change one of these parameters, also update the documentation in
    // the MANUAL document. Note that the log files are included in compressed
    // form in a bug report's diagnostics information file, and that file is
    // intended to be sent as an email attachment. Take care that the maximum
    // size taken up by log files does not cause the attachment file to grow
    // unreasonably large.
    self.fileLogger.maximumFileSize = 1024 * 1024;
    self.fileLogger.logFileManager.maximumNumberOfLogFiles = 10;
  }
  // If possible take the user preference from LoggingModel. If we're called
  // during application launch, however, that model object does not exist yet
  // and we have to fall back to reading directly from NSUserDefaults.
  bool loggingEnabled;
  if (self.loggingModel)
    loggingEnabled = self.loggingModel.loggingEnabled;
  else
    loggingEnabled = [[[NSUserDefaults standardUserDefaults] valueForKey:loggingEnabledKey] boolValue];
  if (loggingEnabled)
  {
    [DDLog addLogger:self.fileLogger withLevel:ddLogLevel];
    // Increase log level if you want to see more logging in the Debug console
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelWarning];
    DDLogInfo(@"Logging enabled. Log folder is %@", [self logFolder]);
  }
  else
  {
    DDLogInfo(@"Logging disabled");
    [DDLog removeAllLoggers];
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets up the application launch mode.
// -----------------------------------------------------------------------------
- (void) setupApplicationLaunchMode
{
  if ([BugReportUtilities diagnosticsInformationExists])
  {
    DDLogInfo(@"Launching in mode ApplicationLaunchModeDiagnostics");
    self.applicationLaunchMode = ApplicationLaunchModeDiagnostics;
  }
  else
  {
    DDLogInfo(@"Launching in mode ApplicationLaunchModeNormal");
    self.applicationLaunchMode = ApplicationLaunchModeNormal;
  }
}

// -----------------------------------------------------------------------------
/// @brief Scans @a launchOptions if it contains a document interaction URL,
/// and if it does whether the URL can be handled.
///
/// Returns true for success, false for failure. Success means either
/// - @a launchOptions does not contain an URL, or
/// - @a launchOptions contains an URL that can be handled
///
/// Failure means that @a launchOptions contains an URL that cannot be handled.
///
/// As a side-effect, if a URL that can be handled is detected this method sets
/// up document interaction related properties of this app delegate.
// -----------------------------------------------------------------------------
- (bool) setupDocumentInteraction:(NSDictionary*)launchOptions
{
  self.documentInteractionURL = nil;
  self.applicationOpenURLShouldIgnoreNextDocumentInteraction = false;

  bool success = true;
  NSURL* url = [launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
  if (url)
  {
    if ([url isFileURL])
    {
      self.documentInteractionURL = url;
      self.applicationOpenURLShouldIgnoreNextDocumentInteraction = true;
    }
    else
    {
      success = false;
    }
  }
  return success;
}

// -----------------------------------------------------------------------------
/// @brief Sets up a number of folders in the application bundle.
// -----------------------------------------------------------------------------
- (void) setupFolders
{
  NSString* archiveFolderPath = [PathUtilities archiveFolderPath];
  [PathUtilities createFolder:archiveFolderPath removeIfExists:false];
  NSString* backupFolderPath = [PathUtilities backupFolderPath];
  [PathUtilities createFolder:backupFolderPath removeIfExists:false];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the bundle that contains the application's resources. This
/// method does nothing if the @e resourceBundle property is not nil.
// -----------------------------------------------------------------------------
- (void) setupResourceBundle
{
  if (! self.resourceBundle)
    self.resourceBundle = [NSBundle mainBundle];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the registration domain in the user defaults system. This
/// must be done before application models are initialized with data from the
/// user defaults.
// -----------------------------------------------------------------------------
- (void) setupRegistrationDomain
{
  NSString* defaultsPathName = [self.resourceBundle pathForResource:registrationDomainDefaultsResource ofType:nil];
  NSMutableDictionary* defaultsDictionary = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:defaultsPathName]];

  // User defaults data must be upgraded *BEFORE* the registration domain
  // defaults are put into place
  [UserDefaultsUpdater upgradeToRegistrationDomainDefaults:defaultsDictionary];

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the various application models with values from the user
/// defaults system.
// -----------------------------------------------------------------------------
- (void) setupUserDefaults
{
  if (ApplicationLaunchModeDiagnostics == self.applicationLaunchMode)
  {
    RestoreBugReportUserDefaultsCommand* command = [[[RestoreBugReportUserDefaultsCommand alloc] init] autorelease];
    bool success = [command submit];
    if (! success)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Failed to restore user defaults while launching in mode ApplicationLaunchModeDiagnostics"];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }

  self.theNewGameModel = [[[NewGameModel alloc] init] autorelease];
  self.playerModel = [[[PlayerModel alloc] init] autorelease];
  self.gtpEngineProfileModel = [[[GtpEngineProfileModel alloc] init] autorelease];
  self.boardViewModel = [[[BoardViewModel alloc] init] autorelease];
  self.boardPositionModel = [[[BoardPositionModel alloc] init] autorelease];
  self.scoringModel = [[[ScoringModel alloc] init] autorelease];
  self.archiveViewModel = [[[ArchiveViewModel alloc] init] autorelease];
  self.gtpLogModel = [[[GtpLogModel alloc] init] autorelease];
  self.gtpCommandModel = [[[GtpCommandModel alloc] init] autorelease];
  self.crashReportingModel = [[[CrashReportingModel alloc] init] autorelease];
  self.loggingModel = [[[LoggingModel alloc] init] autorelease];
  self.uiSettingsModel = [[[UiSettingsModel alloc] init] autorelease];
  self.magnifyingViewModel = [[[MagnifyingViewModel alloc] init] autorelease];
  [self.theNewGameModel readUserDefaults];
  [self.playerModel readUserDefaults];
  [self.gtpEngineProfileModel readUserDefaults];
  [self.boardViewModel readUserDefaults];
  [self.boardPositionModel readUserDefaults];
  [self.scoringModel readUserDefaults];
  [self.archiveViewModel readUserDefaults];
  [self.gtpLogModel readUserDefaults];
  [self.gtpCommandModel readUserDefaults];
  [self.crashReportingModel readUserDefaults];
  [self.loggingModel readUserDefaults];
  [self.uiSettingsModel readUserDefaults];
  [self.magnifyingViewModel readUserDefaults];
  // Is dependent on some user defaults in BoardViewModel
  self.boardViewMetrics = [[[BoardViewMetrics alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Writes the current user preferences to the user defaults system.
///
/// This method does nothing if self.writeUserDefaultsEnabled is false, i.e. in
/// a unit testing environment. During unit tests no user defaults should be
/// written because on a developer machine (the only place where unit tests are
/// executed) we want to be able to switch back and forth between different
/// branches and versions. If we switch from a newer to an older version, then
/// the user defaults file on disk would contain user defaults that the older
/// version would not be able to understand.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  if (! self.writeUserDefaultsEnabled)
    return;

  [self.theNewGameModel writeUserDefaults];
  [self.playerModel writeUserDefaults];
  [self.gtpEngineProfileModel writeUserDefaults];
  [self.boardViewModel writeUserDefaults];
  [self.boardPositionModel writeUserDefaults];
  [self.scoringModel writeUserDefaults];
  [self.archiveViewModel writeUserDefaults];
  [self.gtpLogModel writeUserDefaults];
  [self.gtpCommandModel writeUserDefaults];
  [self.crashReportingModel writeUserDefaults];
  [self.loggingModel writeUserDefaults];
  [self.uiSettingsModel writeUserDefaults];
  [self.magnifyingViewModel writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the objects used to manage sound and vibration.
// -----------------------------------------------------------------------------
- (void) setupSound
{
  self.soundHandling = [[[SoundHandling alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the GTP engine and client (always Fuego).
///
/// In a regular desktop environment, engine and client would be launched in
/// separate processes, which would then communicate via stdin/stdout. Since
/// there is no way to launch separate processes under iOS, engine and client
/// run in separate threads, and they communicate via C++ Standard Library
/// I/O streams.
// -----------------------------------------------------------------------------
- (void) setupFuego
{
  // Create objects on the heap, not the stack, so that they remain alive after
  // control leaves this method. It would be much nicer to make these variables
  // members of the ApplicationDelegate class, but they are C++ and
  // ApplicationDelegate.h is also #import'ed by pure Objective-C
  // implementations.
  inputPipeStreamBuffer = new PipeStreamBuffer();
  outputPipeStreamBuffer = new PipeStreamBuffer();

  NSArray* streamBuffers = [NSArray arrayWithObjects:
                            [NSValue valueWithPointer:inputPipeStreamBuffer],
                            [NSValue valueWithPointer:outputPipeStreamBuffer],
                            nil];

  self.gtpClient = [GtpClient clientWithStreamBuffers:streamBuffers];
  self.gtpEngine = [GtpEngine engineWithStreamBuffers:streamBuffers];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the objects used to manage the GUI.
// -----------------------------------------------------------------------------
- (void) setupGUI
{
  [self setupWindow];
  [self setupWindowRootViewController];
  [self.window makeKeyAndVisible];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupGui.
// -----------------------------------------------------------------------------
- (void) setupWindow
{
  self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
  self.window.backgroundColor = [UIColor whiteColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupGui.
// -----------------------------------------------------------------------------
- (void) setupWindowRootViewController
{
  self.windowRootViewController = [[[WindowRootViewController alloc] init] autorelease];
  self.window.rootViewController = self.windowRootViewController;
  // UIWindow automatically adds the root VC's view as a subview to itself.
  // It also manages the layout of that view, so there is no need to use
  // Auto Layout and install constraints in UIWindow. In fact, doing so causes
  // trouble later on during the application's lifetime, when VCs are dismissed
  // after being presented modally. The problem is discussed here:
  // http://stackoverflow.com/q/23313112/1054378
}

// -----------------------------------------------------------------------------
/// @brief Loads the content of the text resource named @a resourceName.
// -----------------------------------------------------------------------------
- (NSString*) contentOfTextResource:(NSString*)resourceName
{
  if (! resourceName)
    return @"";

  NSURL* resourceURL = [self.resourceBundle URLForResource:resourceName
                                             withExtension:nil];
  if (nil == resourceURL)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to read text resource %@, resource URL is nil", resourceName];
    DDLogError(@"%@: %@", self, errorMessage);
    return nil;
  }

  NSStringEncoding usedEncoding;
  NSError* error;
  NSString* content = [NSString stringWithContentsOfURL:resourceURL
                                           usedEncoding:&usedEncoding
                                                  error:&error];
  if (nil == content)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to read text resource %@", resourceURL];
    if (nil != error)
      errorMessage = [NSString stringWithFormat:@"%@. Error decription: %@", errorMessage, [error localizedDescription]];
    DDLogError(@"%@: %@", self, errorMessage);
  }

  return content;
}

// -----------------------------------------------------------------------------
/// @brief Returns the full path of the folder that contains the application
/// log files.
// -----------------------------------------------------------------------------
- (NSString*) logFolder
{
  return [self.fileLogger.logFileManager logsDirectory];
}

@end
