// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "../gtp/GtpClient.h"
#import "../gtp/GtpEngine.h"
#import "../gtp/GtpUtilities.h"
#import "../newgame/NewGameModel.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/GtpEngineProfile.h"
#import "../player/PlayerModel.h"
#import "../play/controller/SoundHandling.h"
#import "../play/model/BoardPositionModel.h"
#import "../play/model/PlayViewModel.h"
#import "../play/model/ScoringModel.h"
#import "../play/playtab/PlayTabController.h"
#import "../archive/ArchiveViewModel.h"
#import "../diagnostics/BugReportUtilities.h"
#import "../diagnostics/CrashReportingModel.h"
#import "../diagnostics/GtpCommandModel.h"
#import "../diagnostics/GtpLogModel.h"
#import "../diagnostics/LoggingModel.h"
#import "../command/CommandProcessor.h"
#import "../command/HandleDocumentInteraction.h"
#import "../command/SetupApplicationCommand.h"
#import "../command/diagnostics/RestoreBugReportUserDefaultsCommand.h"
#import "../command/game/PauseGameCommand.h"
#import "../go/GoGame.h"
#import "../shared/LongRunningActionCounter.h"
#import "../shared/ApplicationStateManager.h"
#import "../utility/PathUtilities.h"
#import "../utility/UserDefaultsUpdater.h"
#import "../ui/UiElementMetrics.h"

// Library includes
#include <lumberjack/DDTTYLogger.h>
#include <lumberjack/DDFileLogger.h>

// System includes
#include <string>
#include <vector>
#include <iostream>  // for cout
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

@synthesize window;
@synthesize tabBarController;


// -----------------------------------------------------------------------------
/// @brief Shared instance of ApplicationDelegate.
// -----------------------------------------------------------------------------
static ApplicationDelegate* sharedDelegate = nil;

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
  self.tabBarController = nil;
  self.window = nil;
  self.documentInteractionURL = nil;
  self.gtpClient = nil;
  self.gtpEngine = nil;
  self.theNewGameModel = nil;
  self.playerModel = nil;
  self.gtpEngineProfileModel = nil;
  self.playViewModel = nil;
  self.boardPositionModel = nil;
  self.scoringModel = nil;
  self.soundHandling = nil;
  self.game = nil;
  self.archiveViewModel = nil;
  self.gtpLogModel = nil;
  self.gtpCommandModel = nil;
  self.crashReportingModel = nil;
  self.loggingModel = nil;
  self.fileLogger = nil;
  [CommandProcessor releaseSharedProcessor];
  [LongRunningActionCounter releaseSharedCounter];
  [ApplicationStateManager releaseSharedManager];
  if (self == sharedDelegate)
    sharedDelegate = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Performs major application initialization tasks.
///
/// This method is invoked after the main .nib file has been loaded, but while
/// the application is still in the inactive state.
// -----------------------------------------------------------------------------
- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  // Make the single instance of this class available as a "shared object", or
  // Singleton.
  sharedDelegate = self;

  // Enable in normal (i.e. not unit testing) environment
  self.writeUserDefaultsEnabled = true;

  // For QuincyKit to work properly, this method must be invoked in the context
  // of the main thread, i.e. it cannot be invoked by SetupApplicationCommand
  // which runs in a secondary thread. If this method is invoked in a secondary
  // thread context, QuincyKit will not query the user whether she wants to
  // send a crash report. In fact, QuincyKit will not do anything at all.
  [self setupCrashReporting];

  // Don't change the following sequence without thoroughly checking the
  // dependencies
  // TODO: Document dependencies
  [self setupGUI];
  [self setupLogging];
  [self setupApplicationLaunchMode];
  bool setupDocumentInteractionSuccess = [self setupDocumentInteraction:launchOptions];
  [self setupFolders];
  [self setupResourceBundle];
  [self setupRegistrationDomain];
  [self setupUserDefaults];
  [self setupSound];
  [self setupFuego];
  [self setupTabBarController];
  [self setupPlayTab];

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
  [[[[HandleDocumentInteraction alloc] init] autorelease] submit];
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the crash reporting service.
// -----------------------------------------------------------------------------
- (void) setupCrashReporting
{
  BWQuincyManager* sharedQuincyManager = [BWQuincyManager sharedQuincyManager];
  [sharedQuincyManager setSubmissionURL:crashReportSubmissionURL];
  // The QuincyKit docs do not mention this, but setting the delegate is
  // required for displaying an alert view to the user
  [sharedQuincyManager setDelegate:self];
  // Default is NO (QuincyKit docs claim the default is YES)
  sharedQuincyManager.showAlwaysButton = YES;
  sharedQuincyManager.feedbackActivated = YES;
  // sharedQuincyManager.appIdentifier must not be set, otherwise no crash
  // reports are sent to the submission URL.
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
    [DDLog addLogger:self.fileLogger];
    // Enable this if you want logging to also go to the Debug console
//    [DDLog addLogger:[DDTTYLogger sharedInstance]];
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
/// @brief Sets up a number of folders in the application bundle. Depending on
/// the folder's purpose, it is either created if it does not exist, or deleted
/// if it does exist.
// -----------------------------------------------------------------------------
- (void) setupFolders
{
  NSString* archiveFolderPath = [PathUtilities archiveFolderPath];
  [PathUtilities createFolder:archiveFolderPath removeIfExists:false];
  NSString* backupFolderPath = [PathUtilities backupFolderPath];
  [PathUtilities createFolder:backupFolderPath removeIfExists:false];
  // Must not remove the Inbox folder if the application is launched because of
  // document interaction. Removal in this case is delayed to the next app
  // launch without document interaction.
  if (! self.documentInteractionURL)
  {
    NSString* inboxFolderPath = [PathUtilities inboxFolderPath];
    [PathUtilities deleteItemIfExists:inboxFolderPath];
  }
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
  self.playViewModel = [[[PlayViewModel alloc] init] autorelease];
  self.boardPositionModel = [[[BoardPositionModel alloc] init] autorelease];
  self.scoringModel = [[[ScoringModel alloc] init] autorelease];
  self.archiveViewModel = [[[ArchiveViewModel alloc] init] autorelease];
  self.gtpLogModel = [[[GtpLogModel alloc] init] autorelease];
  self.gtpCommandModel = [[[GtpCommandModel alloc] init] autorelease];
  self.crashReportingModel = [[[CrashReportingModel alloc] init] autorelease];
  self.loggingModel = [[[LoggingModel alloc] init] autorelease];
  [self.theNewGameModel readUserDefaults];
  [self.playerModel readUserDefaults];
  [self.gtpEngineProfileModel readUserDefaults];
  [self.playViewModel readUserDefaults];
  [self.boardPositionModel readUserDefaults];
  [self.scoringModel readUserDefaults];
  [self.archiveViewModel readUserDefaults];
  [self.gtpLogModel readUserDefaults];
  [self.gtpCommandModel readUserDefaults];
  [self.crashReportingModel readUserDefaults];
  [self.loggingModel readUserDefaults];
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
  [self.playViewModel writeUserDefaults];
  [self.boardPositionModel writeUserDefaults];
  [self.scoringModel writeUserDefaults];
  [self.archiveViewModel writeUserDefaults];
  [self.gtpLogModel writeUserDefaults];
  [self.gtpCommandModel writeUserDefaults];
  [self.crashReportingModel writeUserDefaults];
  [self.loggingModel writeUserDefaults];

  [[NSUserDefaults standardUserDefaults] synchronize];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the objects used to manage sound and vibration.
// -----------------------------------------------------------------------------
- (void) setupSound
{
  self.soundHandling = [[[SoundHandling alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the objects used to manage the GUI.
// -----------------------------------------------------------------------------
- (void) setupGUI
{
  [UiElementMetrics setInterfaceOrientationSource:self.tabBarController];
  [self.window makeKeyAndVisible];

  // Disable edit button in the "more" navigation controller
  self.tabBarController.customizableViewControllers = [NSArray array];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the GTP engine and client (always Fuego).
///
/// In a regular desktop environment, engine and client would be launched in
/// separate processes, which would then communicate via stdin/stdout. Since
/// there is no way to launch separate processes under iOS, engine and client
/// run in separate threads, and they communicate via named pipes.
// -----------------------------------------------------------------------------
- (void) setupFuego
{
  mode_t pipeMode = S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH;
  NSString* tempDir = NSTemporaryDirectory();
  NSString* inputPipePath = [NSString pathWithComponents:[NSArray arrayWithObjects:tempDir, @"inputPipe", nil]];
  NSString* outputPipePath = [NSString pathWithComponents:[NSArray arrayWithObjects:tempDir, @"outputPipe", nil]];
  std::vector<std::string> pipeList;
  pipeList.push_back([inputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
  pipeList.push_back([outputPipePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
  std::vector<std::string>::const_iterator it = pipeList.begin();
  for (; it != pipeList.end(); ++it)
  {
    std::string pipePath = *it;
    std::cout << "Creating input pipe " << pipePath << std::endl;
    // TODO: Check if pipes already exist, and/or clean them up when the
    // application shuts down
    int status = mkfifo(pipePath.c_str(), pipeMode);
    if (status == 0)
      std::cout << "Success!" << std::endl;
    else
    {
      std::cout << "Failure! Reason = ";
      switch (errno)
      {
        case EACCES:
          std::cout << "EACCES" << std::endl;
          break;
        case EEXIST:
          std::cout << "EEXIST" << std::endl;
          break;
        case ELOOP:
          std::cout << "ELOOP" << std::endl;
          break;
        case ENOENT:
          std::cout << "ENOENT" << std::endl;
          break;
        case EROFS:
          std::cout << "EROFS" << std::endl;
          break;
        default:
          std::cout << "Some other result: " << status << std::endl;
          break;
      }
    }
  }
  self.gtpClient = [GtpClient clientWithInputPipe:inputPipePath outputPipe:outputPipePath];
  self.gtpEngine = [GtpEngine engineWithInputPipe:inputPipePath outputPipe:outputPipePath];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the application's main tab bar controller and its more
/// navigation controller to use this ApplicationDelegate object as their
/// delegate.
// -----------------------------------------------------------------------------
- (void) setupTabBarController
{
  [self tabBarController].delegate = self;
  [self tabBarController].moreNavigationController.delegate = self;
}

// -----------------------------------------------------------------------------
/// @brief Creates and initializes objects that are required to display the
/// view hierarchy on the Play tab (the tab that is initially visible after
/// application launch).
// -----------------------------------------------------------------------------
- (void) setupPlayTab
{
  UIViewController* playTabController = [PlayTabController playTabController];
  UINavigationController* playTabRootController = (UINavigationController*)[self tabController:TabTypePlay];
  [playTabRootController pushViewController:playTabController animated:NO];
}

// -----------------------------------------------------------------------------
/// @brief Returns the root controller for the tab identified by @a tabID.
/// Returns nil if @a tabID is not recognized.
///
/// This method returns the correct controller even if the tab is located in
/// the "More" navigation controller.
// -----------------------------------------------------------------------------
- (UIViewController*) tabController:(enum TabType)tabID
{
  for (UIViewController* controller in tabBarController.viewControllers)
  {
    if (controller.tabBarItem.tag == tabID)
      return controller;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the main view for the tab identified by @a tabID. Returns
/// nil if @a tabID is not recognized.
///
/// This method returns the correct view even if the tab is located in the
/// "More" navigation controller.
// -----------------------------------------------------------------------------
- (UIView*) tabView:(enum TabType)tabID
{
  UIViewController* tabController = [self tabController:tabID];
  if (tabController)
    return tabController.view;
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Activates the tab identified by @a tabID, making it visible to the
/// user.
///
/// This method works correctly even if the tab is located in the "More"
/// navigation controller.
// -----------------------------------------------------------------------------
- (void) activateTab:(enum TabType)tabID
{
  UIViewController* tabController = [self tabController:tabID];
  if (tabController)
  {
    tabBarController.selectedViewController = tabController;
    // The delegate method tabBarController:didSelectViewController:() is not
    // invoked when the selectedViewController property is changed
    // programmatically
    [self writeUserDefaults];
  }
}

// -----------------------------------------------------------------------------
/// @brief UITabBarControllerDelegate method
///
/// Writes user defaults in response to the user switching tabs.
// -----------------------------------------------------------------------------
- (void) tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController
{
  [self writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief UINavigationControllerDelegate method
///
/// Writes user defaults in response to the user switching views on the tab
/// bar controller's more navigation controller.
// -----------------------------------------------------------------------------
- (void) navigationController:(UINavigationController*)navigationController didShowViewController:(UIViewController*)viewController animated:(BOOL)animated
{
  [self writeUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Loads the content of the text resource named @a resourceName.
// -----------------------------------------------------------------------------
- (NSString*) contentOfTextResource:(NSString*)resourceName
{
  if (! resourceName)
    return @"";
  NSURL* resourceURL = [[ApplicationDelegate sharedDelegate].resourceBundle URLForResource:resourceName
                                                                             withExtension:nil];
  NSStringEncoding usedEncoding;
  NSError* error;
  return [NSString stringWithContentsOfURL:resourceURL
                              usedEncoding:&usedEncoding
                                     error:&error];
}

// -----------------------------------------------------------------------------
/// @brief Maps TabType values to resource file names. The name that is returned
/// can be used with NSBundle to load the resource file's content.
// -----------------------------------------------------------------------------
- (NSString*) resourceNameForTabType:(enum TabType)tabType
{
  NSString* resourceName = nil;
  switch (tabType)
  {
    case TabTypeManual:
      resourceName = manualDocumentResource;
      break;
    case TabTypeAbout:
      resourceName = aboutDocumentResource;
      break;
    case TabTypeSourceCode:
      resourceName = sourceCodeDocumentResource;
      break;
    case TabTypeCredits:
      resourceName = creditsDocumentResource;
      break;
    default:
      break;
  }
  return resourceName;
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
