// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "gtp/GtpClient.h"
#import "gtp/GtpEngine.h"
#import "newgame/NewGameController.h"
#import "newgame/NewGameModel.h"
#import "player/PlayerModel.h"
#import "player/Player.h"
#import "player/GtpEngineSettings.h"
#import "play/PlayViewModel.h"
#import "play/SoundHandling.h"
#import "go/GoGame.h"
#import "go/GoPlayer.h"
#import "archive/ArchiveViewModel.h"

// System includes
#include <string>
#include <vector>
#include <iostream>  // for cout
#include <sys/stat.h>  // for mkfifo


#include <stdlib.h>
#include <unistd.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ApplicationDelegate.
// -----------------------------------------------------------------------------
@interface ApplicationDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIApplicationDelegate protocol
//@{
- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions;
- (void) applicationWillResignActive:(UIApplication*)application;
- (void) applicationDidEnterBackground:(UIApplication*)application;
- (void) applicationWillEnterForeground:(UIApplication*)application;
- (void) applicationDidBecomeActive:(UIApplication*)application;
- (void) applicationWillTerminate:(UIApplication*)application;
- (void) applicationDidReceiveMemoryWarning:(UIApplication*)application;
//@}
@end


@implementation ApplicationDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize resourceBundle;
@synthesize gtpClient;
@synthesize gtpEngine;
@synthesize newGameModel;
@synthesize playerModel;
@synthesize playViewModel;
@synthesize soundHandling;
@synthesize game;
@synthesize archiveViewModel;


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
  @synchronized(self)
  {
    assert(sharedDelegate != nil);
    return sharedDelegate;
  }
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
  return sharedDelegate;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ApplicationDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.tabBarController = nil;
  self.window = nil;
  self.gtpClient = nil;
  self.gtpEngine = nil;
  self.newGameModel = nil;
  self.playerModel = nil;
  self.playViewModel = nil;
  self.soundHandling = nil;
  self.game = nil;
  self.archiveViewModel = nil;
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

  [self setupResourceBundle];
  [self setupUserDefaults];
  [self setupGUI];
  [self setupFuego];
  [self startNewGame];

  // We don't handle any URL resources in launchOptions
  // -> always return success
  return YES;
}

- (void) applicationWillResignActive:(UIApplication*)application
{
}

- (void) applicationDidEnterBackground:(UIApplication*)application
{
  [self.newGameModel writeUserDefaults];
  [self.playerModel writeUserDefaults];
  [self.playViewModel writeUserDefaults];
  [self.archiveViewModel writeUserDefaults];
}

- (void) applicationWillEnterForeground:(UIApplication*)application
{
}

- (void) applicationDidBecomeActive:(UIApplication*)application
{
}

- (void) applicationWillTerminate:(UIApplication*)application
{
}

- (void) applicationDidReceiveMemoryWarning:(UIApplication*)application
{
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
/// @brief Sets up the various application models with values from the user
/// defaults system.
// -----------------------------------------------------------------------------
- (void) setupUserDefaults
{
  // Set up application defaults *BEFORE* loading user defaults
  NSString* defaultsPathName = [self.resourceBundle pathForResource:registrationDomainDefaultsResource ofType:nil];
  NSDictionary* defaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:defaultsPathName];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];

  // Create model objects and load values from the user defaults system
  self.newGameModel = [[[NewGameModel alloc] init] autorelease];
  self.playerModel = [[[PlayerModel alloc] init] autorelease];
  self.playViewModel = [[[PlayViewModel alloc] init] autorelease];
  self.archiveViewModel = [[[ArchiveViewModel alloc] init] autorelease];
  [self.newGameModel readUserDefaults];
  [self.playerModel readUserDefaults];
  [self.playViewModel readUserDefaults];
  [self.archiveViewModel readUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the objects used to manage the GUI.
// -----------------------------------------------------------------------------
- (void) setupGUI
{
  [self.window addSubview:tabBarController.view];
  [self.window makeKeyAndVisible];
  self.soundHandling = [[SoundHandling alloc] init];
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
/// @brief Starts a new game using the values currently stored in NewGameModel.
// -----------------------------------------------------------------------------
- (void) startNewGame
{
  // De-allocate the old game *BEFORE* creating a new one. Go objects attached
  // to the old game need to be able to access their instance using GoGame's
  // class method sharedGame().
  // TODO: Remove this comment and statement as soon as Go objects no longer
  // rely on sharedGame().
  self.game = nil;
  // TODO: Prevent starting a new game if the defaults are somehow invalid
  // (currently known: player UUID may refer to a player that has been removed)
  self.game = [GoGame newGame];

  if (HumanVsHumanGame != self.game.type)
  {
    Player* computerPlayerWithGtpSettings = self.game.playerBlack.player;
    if (computerPlayerWithGtpSettings.isHuman)
    {
      computerPlayerWithGtpSettings = self.game.playerWhite.player;
      assert(! computerPlayerWithGtpSettings.isHuman);
    }
    else
    {
      // TODO notify user that we ignore the white player's settings;
      // alternatively let the user choose which player's settings should be
      // used
    }
    [computerPlayerWithGtpSettings.gtpEngineSettings applySettings];
  }
}

@end
