// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "Registry.h"
#import "SceneDelegate.h"
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
#import "../play/model/BoardSetupModel.h"
#import "../play/model/BoardViewMetrics.h"
#import "../play/model/BoardViewModel.h"
#import "../play/model/GameVariationModel.h"
#import "../play/model/MarkupModel.h"
#import "../play/model/NodeTreeViewModel.h"
#import "../play/model/ScoringModel.h"
#import "../archive/ArchiveViewModel.h"
#import "../diagnostics/BugReportUtilities.h"
#import "../diagnostics/CrashReportingModel.h"
#import "../diagnostics/GtpCommandModel.h"
#import "../diagnostics/GtpLogModel.h"
#import "../diagnostics/LoggingModel.h"
#import "../command/CommandProcessor.h"
#import "../command/backup/CleanBackupSgfCommand.h"
#import "../command/diagnostics/RestoreBugReportUserDefaultsCommand.h"
#import "../shared/ApplicationStateManager.h"
#import "../shared/LayoutManager.h"
#import "../shared/LongRunningActionCounter.h"
#import "../sgf/SgfSettingsModel.h"
#import "../ui/MagnifyingViewModel.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiSettingsModel.h"
#import "../utility/LogFormatter.h"
#import "../utility/PathUtilities.h"
#import "../utility/UserDefaultsUpdater.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ApplicationDelegate.
// -----------------------------------------------------------------------------
@interface ApplicationDelegate()
@property(nonatomic, retain) DDFileLogger* fileLogger;
@end


@implementation ApplicationDelegate

#pragma mark - Synthesize properties

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// ModelProvider protocol.
@synthesize theNewGameModel = _theNewGameModel;
@synthesize playerModel = _playerModel;
@synthesize gtpEngineProfileModel = _gtpEngineProfileModel;
@synthesize boardViewModel = _boardViewModel;
@synthesize boardViewMetrics = _boardViewMetrics;
@synthesize boardPositionModel = _boardPositionModel;
@synthesize scoringModel = _scoringModel;
@synthesize soundHandling = _soundHandling;
@synthesize archiveViewModel = _archiveViewModel;
@synthesize gtpLogModel = _gtpLogModel;
@synthesize gtpCommandModel = _gtpCommandModel;
@synthesize crashReportingModel = _crashReportingModel;
@synthesize loggingModel = _loggingModel;
@synthesize uiSettingsModel = _uiSettingsModel;
@synthesize magnifyingViewModel = _magnifyingViewModel;
@synthesize boardSetupModel = _boardSetupModel;
@synthesize sgfSettingsModel = _sgfSettingsModel;
@synthesize markupModel = _markupModel;
@synthesize nodeTreeViewModel = _nodeTreeViewModel;
@synthesize gameVariationModel = _gameVariationModel;

#pragma mark - Initialization and deallocation

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
  // Unregister objects owned by ApplicationDelegate. We do this by releasing
  // the whole registry. Should someone access the registry afterwards they will
  // get a new registry object with all references set to nil.
  [Registry releaseSharedRegistry];

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
  self.boardSetupModel = nil;
  self.sgfSettingsModel = nil;
  self.markupModel = nil;
  self.nodeTreeViewModel = nil;
  self.gameVariationModel = nil;
  self.fileLogger = nil;
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

#pragma mark - UIApplicationDelegate overrides

// -----------------------------------------------------------------------------
/// @brief Performs major application initialization tasks.
///
/// This method is invoked after the main .nib file (if there is any) has been
/// loaded, but while the application is still in the inactive state.
///
/// After adopting the scene life cycle, @a launchOptions is now always @e nil.
/// Instead SceneDelegate now receives information about why a scene was
/// created.
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

  // In UI test mode discard state saved by the previous test
  NSProcessInfo* processInfo = [NSProcessInfo processInfo];
  if ([processInfo.arguments containsObject:uiTestModeLaunchArgument])
    [self prepareForUiTests];

  // Don't change the following sequence without thoroughly checking the
  // dependencies. Also note that scene handling in SceneDelegate is
  // dependent on parts of this sequence having been executed.

  // The following steps have no dependencies
  [self setupResourceBundle];
  [self setupLogging];
  [self setupApplicationLaunchMode];
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
  // Depends on models having been set up
  [self setupRegistry];

  return YES;
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

#pragma mark - UIApplicationDelegate overrides - Scene support

// -----------------------------------------------------------------------------
/// @brief UIApplicationDelegate method.
// -----------------------------------------------------------------------------
 - (UISceneConfiguration*) application:(UIApplication*)application
configurationForConnectingSceneSession:(UISceneSession*)connectingSceneSession
                               options:(UISceneConnectionOptions*)options
{
  DDLogInfo(@"application:configurationForConnectingSceneSession:options:() received");

  // Each UISceneConfiguration must have a unique configuration name that is
  // used to identify the scene.
  NSString* configurationName = @"Default Scene Configuration";

  // This project does not define its scene configurations in Info.plist.
  // This app only has one scene, and its configuration is created
  // programmatically here.
  UISceneConfiguration* sceneConfiguration = [UISceneConfiguration configurationWithName:configurationName
                                                                             sessionRole:connectingSceneSession.role];
  sceneConfiguration.sceneClass = [UIWindowScene class];
  sceneConfiguration.delegateClass = [SceneDelegate class];
  // The scene's initial view controller is not defined in a storyboard (this
  // project does not use storyboards), but is is provided programmatically by
  // the scene delegate.
  sceneConfiguration.storyboard = nil;
  
  return sceneConfiguration;
}

// -----------------------------------------------------------------------------
/// @brief UIApplicationDelegate method.
// -----------------------------------------------------------------------------
   - (void) application:(UIApplication*)application
didDiscardSceneSessions:(NSSet<UISceneSession*>*)sceneSessions
{
  DDLogInfo(@"application:didDiscardSceneSessions:() received");

  // From the documentation:
  //   "If your app isn’t running, UIKit calls this method the next time your
  //   app launches."
  // Before implementing something here, consider the implications of the above.
}

#pragma mark - Setup methods for application:didFinishLaunchingWithOptions:

// -----------------------------------------------------------------------------
/// @brief Prepares the app for launching in UI test mode.
// -----------------------------------------------------------------------------
- (void) prepareForUiTests
{
  NSString* appDomain = [[NSBundle mainBundle] bundleIdentifier];
  [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
  [[NSUserDefaults standardUserDefaults] synchronize];

  [[[[CleanBackupSgfCommand alloc] init] autorelease] submit];
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
    // the user manual. Note that the log files are included in compressed
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
    self.fileLogger.logFormatter = [[[LogFormatter alloc] init] autorelease];
    id<DDLogger> logger = [DDOSLogger sharedInstance];  // uses os_log
    // The Xcode console adds its own timestamp
    logger.logFormatter = [[[LogFormatter alloc] initWithLogFormatStyle:LogFormatStyleWithoutTimestamp] autorelease];
    // Increase log level if you want to see more logging in the Debug console
    [DDLog addLogger:logger withLevel:DDLogLevelWarning];
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
  self.boardSetupModel = [[[BoardSetupModel alloc] init] autorelease];
  self.sgfSettingsModel = [[[SgfSettingsModel alloc] init] autorelease];
  self.markupModel = [[[MarkupModel alloc] init] autorelease];
  self.nodeTreeViewModel = [[[NodeTreeViewModel alloc] init] autorelease];
  self.gameVariationModel = [[[GameVariationModel alloc] init] autorelease];
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
  [self.boardSetupModel readUserDefaults];
  [self.sgfSettingsModel readUserDefaults];
  [self.markupModel readUserDefaults];
  [self.nodeTreeViewModel readUserDefaults];
  [self.gameVariationModel readUserDefaults];
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
  [self.boardSetupModel writeUserDefaults];
  [self.sgfSettingsModel writeUserDefaults];
  [self.markupModel writeUserDefaults];
  [self.nodeTreeViewModel writeUserDefaults];
  [self.gameVariationModel writeUserDefaults];
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
/// @brief Sets up the shared Registry with objects owned by
/// ApplicationDelegate.
// -----------------------------------------------------------------------------
- (void) setupRegistry
{
  Registry* sharedRegistry = [Registry sharedRegistry];

  sharedRegistry.applicationDelegate = self;
  sharedRegistry.modelProvider = self;
}

#pragma mark - Public helper methods

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
