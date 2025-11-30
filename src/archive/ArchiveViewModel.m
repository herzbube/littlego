// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "ArchiveViewModel.h"
#import "ArchiveGame.h"
#import "../go/GoGame.h"
#import "../go/GoPlayer.h"
#import "../player/Player.h"
#import "../utility/FilesystemMonitor.h"
#import "../utility/FilesystemOperations.h"
#import "../utility/PathUtilities.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ArchiveViewModel.
// -----------------------------------------------------------------------------
@interface ArchiveViewModel()
/// @name Private properties
//@{
/// @brief Dictionary with key = file name, value = NSMutableArray with the
/// following elements: index 0 = ArchiveGame object,
/// index 1 = FilesystemMonitor.
@property(nonatomic, retain) NSMutableDictionary* gameDictionary;
@property(nonatomic, retain) FilesystemMonitor* archiveFolderFilesystemMonitor;
@property(nonatomic, retain) NSTimer* delayedUpdateTimer;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSArray* gameList;
//@}
@end


@implementation ArchiveViewModel

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a ArchiveViewModel object with user defaults data.
///
/// @note This is the designated initializer of ArchiveViewModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.archiveFolder = [PathUtilities archiveFolderPath];

  self.gameDictionary = [NSMutableDictionary dictionary];

  self.gameList = [NSMutableArray arrayWithCapacity:0];
  self.sortCriteria = ArchiveSortCriteriaFileName;
  self.sortAscending = true;

  [self updateData];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(archiveContentChanged:) name:archiveContentChanged object:nil];

  // Monitoring the archive folder is required to detect new files being added.
  // Monitoring of individual files is also required (see udpateData) to detect
  // changes to the files that don't touch the archive folder (e.g. overwrites).
  NSURL* archiveFolderUrl = [NSURL fileURLWithPath:self.archiveFolder isDirectory:YES];
  self.archiveFolderFilesystemMonitor = [[[FilesystemMonitor alloc] initWithURL:archiveFolderUrl delegate:self] autorelease];
  [self.archiveFolderFilesystemMonitor startMonitoring];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ArchiveViewModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self.archiveFolderFilesystemMonitor stopMonitoring];
  self.archiveFolderFilesystemMonitor = nil;

  [self invalidateDelayedUpdateTimerIfStarted];

  self.archiveFolder = nil;
  self.gameList = nil;
  self.gameDictionary = nil;

  [super dealloc];
}

#pragma mark - Read and write user defaults

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:archiveViewKey];
  self.sortCriteria = [[dictionary valueForKey:sortCriteriaKey] intValue];
  self.sortAscending = [[dictionary valueForKey:sortAscendingKey] boolValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithInt:self.sortCriteria] forKey:sortCriteriaKey];
  [dictionary setValue:[NSNumber numberWithBool:self.sortAscending] forKey:sortAscendingKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:archiveViewKey];
}

#pragma mark - Reacting to updates of the archive folder content

// -----------------------------------------------------------------------------
/// @brief Responds to the #archiveContentChanged notification.
// -----------------------------------------------------------------------------
- (void) archiveContentChanged:(NSNotification*)notification
{
  [self updateData];
}

// -----------------------------------------------------------------------------
/// @brief FilesystemMonitorDelegate method.
// -----------------------------------------------------------------------------
- (void) filesystemMonitor:(FilesystemMonitor*)filesystemMonitor
            changeOccurred:(enum FilesystemMonitorChangeType)changeType
                       url:(NSURL*)url
{
  // Sometimes a filesytem operation causes several FilesystemMonitor
  // notifications. To avoid unnecessary model updates, and because the number
  // of notifications cannot be predicted, the invocation of updateData() is
  // delayed until a certain amount of time has passed without further
  // notifications.

  if ([url hasDirectoryPath])
  {
    switch (changeType)
    {
      // Received for new files, file renames, file deletes, i.e. for all
      // changes that modify the folder content.
      // Not received for file replacements or any other changes that only
      // touch a file's content or metadata.
      case FilesystemMonitorChangeTypeDataChanged:
        [self startOrRefreshDelayedUpdateTimer];
        break;

      // None of the other notifications are ever received.
      default:
        break;
    }
  }
  else
  {
    switch (changeType)
    {
      // Received when a file copy or file move overwrites the file
      // - Outside of the app (with "cp" or "mv")
      // - With FilesystemOperations (std::filesystem::copy)
      // Received when other changes are made to the file
      // - Outside of the app (content redirected into the file)
      case FilesystemMonitorChangeTypeDataChanged:
      // Received when file metadata is changed
      // - Outside of the app (with "touch")
      // Received multiple times when a file copy or file move overwrites the
      // file
      // - Outside of the app (with "cp" or "mv")
      // - With FilesystemOperations (std::filesystem::copy)
      // Received when other changes are made to the file
      // - Outside of the app (content redirected into the file)
      case FilesystemMonitorChangeTypeMetadataChanged:
      // Received when a file copy or file move overwrites the file
      // - Outside of the app (with "cp" or "mv")
      // - With FilesystemOperations (std::filesystem::copy)
      // Received when other changes are made to the file
      // - Outside of the app (content redirected into the file)
      case FilesystemMonitorChangeTypeSizeChanged:
      // Received when a file copy or file move overwrites the file
      // - Outside of the app (with "cp" or "mv")
      // - With FilesystemOperations (std::filesystem::copy)
      // Received when other changes are made to the file
      // - Outside of the app (content redirected into the file)
      case FilesystemMonitorChangeTypeRenamed:
      // Received when a file is deleted
      // - Outside of the app (with "rm")
      // - With FilesystemOperations (std::filesystem::remove_all)
      case FilesystemMonitorChangeTypeDeleted:
      // Received when the file is deleted
      // - Outside of the app (with "rm")
      // - With FilesystemOperations (std::filesystem::remove_all)
      case FilesystemMonitorChangeTypeObjectLinkCountChanged:
        [self startOrRefreshDelayedUpdateTimer];
        break;

      // None of the other notifications are ever received.
      default:
        break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Starts a timer that when it fires causes updateData() to be invoked.
/// Refreshes the timer if it is already running.
// -----------------------------------------------------------------------------
- (void) startOrRefreshDelayedUpdateTimer
{
  static NSTimeInterval updateDelayThresholdInSeconds = 0.5;

  [self invalidateDelayedUpdateTimerIfStarted];

  self.delayedUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:updateDelayThresholdInSeconds
                                                             target:self
                                                           selector:@selector(delayedUpdateData)
                                                           userInfo:nil
                                                            repeats:NO];
}

// -----------------------------------------------------------------------------
/// @brief Invalidates the "delayed update" timer. Does nothing if the timer
/// is not active.
// -----------------------------------------------------------------------------
- (void) invalidateDelayedUpdateTimerIfStarted
{
  if (! self.delayedUpdateTimer)
    return;

  [self.delayedUpdateTimer invalidate];
  self.delayedUpdateTimer = nil;
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when the "delayed update" timer fires. Performs cleanup
/// and then invokes updateData().
// -----------------------------------------------------------------------------
- (void) delayedUpdateData
{
  self.delayedUpdateTimer = nil;

  [self updateData];
}

#pragma mark - Public interface part 1

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (int) gameCount
{
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31) files.
  return (int)self.gameList.count;
}

// -----------------------------------------------------------------------------
/// @brief Returns the game object located at position @a index in the gameList
/// array.
// -----------------------------------------------------------------------------
- (ArchiveGame*) gameAtIndex:(int)index
{
  return [self.gameList objectAtIndex:index];
}

// -----------------------------------------------------------------------------
/// @brief Returns the game object with name @a name.
// -----------------------------------------------------------------------------
- (ArchiveGame*) gameWithName:(NSString*)name
{
  NSString* fileName = [name stringByAppendingString:@".sgf"];
  return [self gameWithFileName:fileName];
}

// -----------------------------------------------------------------------------
/// @brief Returns the game object with file name @a fileName.
// -----------------------------------------------------------------------------
- (ArchiveGame*) gameWithFileName:(NSString*)fileName
{
  for (ArchiveGame* game in self.gameList)
  {
    if ([game.fileName isEqualToString:fileName])
      return game;
  }
  return nil;
}

#pragma mark - Updating model data

// -----------------------------------------------------------------------------
/// @brief Updates all data structures to match the content of the archive
/// folder.
// -----------------------------------------------------------------------------
- (void) updateData
{
  NSMutableDictionary* oldGameDictionary = self.gameDictionary;
  NSMutableDictionary* newGameDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* newGameList = [NSMutableArray array];

  NSArray* fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.archiveFolder error:nil];
  for (NSString* fileName in fileList)
  {
    if ([self shouldIgnoreFileName:fileName])
      continue;

    NSString* filePath = [self.archiveFolder stringByAppendingPathComponent:fileName];
    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];

    NSMutableArray* gameData = [oldGameDictionary objectForKey:fileName];
    if (gameData)
    {
      ArchiveGame* game = gameData.firstObject;
      [game updateFileAttributes:fileAttributes];
      game.fileContentRevision += 1;

      // A rename may have delayed starting the monitoring => start it now
      FilesystemMonitor* filesystemMonitor = [gameData lastObject];
      if (! filesystemMonitor.isMonitoringStarted)
        [filesystemMonitor startMonitoring];
    }
    else
    {
      ArchiveGame* game = [[[ArchiveGame alloc] initWithFileName:fileName fileAttributes:fileAttributes] autorelease];
      FilesystemMonitor* filesystemMonitor = [self createAndStartFilesystemMonitor:filePath];
      gameData = [NSMutableArray arrayWithObjects:game, filesystemMonitor, nil];
    }

    newGameDictionary[fileName] = gameData;
    [newGameList addObject:gameData.firstObject];
  }

  [oldGameDictionary enumerateKeysAndObjectsUsingBlock:^(NSString* fileName, NSMutableArray* oldGameData, BOOL* stop)
  {
    NSMutableArray* newGameData = [newGameDictionary valueForKey:fileName];
    if (newGameData)
      return;

    ArchiveGame* deletedGame = [oldGameData firstObject];
    deletedGame.fileDeleted = true;

    FilesystemMonitor* deletedGameFilesystemMonitor = [oldGameData lastObject];
    [deletedGameFilesystemMonitor stopMonitoring];
  }];

  [self sortGameList:newGameList];

  // Replace private dictionary before public list, so that we are ready when
  // clients request data in response to their KVO triggers
  self.gameDictionary = newGameDictionary;

  // Replace entire array to trigger KVO
  self.gameList = newGameList;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a fileName is not an archived game and should be
/// ignored by this model.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreFileName:(NSString*)fileName
{
  if ([fileName isEqualToString:@"Logs"])  // ignore logging framework folder
    return true;
  if ([fileName isEqualToString:bugReportDiagnosticsInformationFileName])
    return true;
  if ([fileName isEqualToString:inboxFolderName])  // ignore folder where document interaction places file
    return true;
  return false;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new FilesystemMonitor object that monitors @a filePath.
/// Starts the monitoring process and returns the object.
// -----------------------------------------------------------------------------
- (FilesystemMonitor*) createAndStartFilesystemMonitor:(NSString*)filePath
{
  FilesystemMonitor* filesystemMonitor = [self createFilesystemMonitor:filePath];
  [filesystemMonitor startMonitoring];
  return filesystemMonitor;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new FilesystemMonitor object that monitors @a filePath.
/// Returns the object without starting monitoring.
// -----------------------------------------------------------------------------
- (FilesystemMonitor*) createFilesystemMonitor:(NSString*)filePath
{
  NSURL* fileUrl = [NSURL fileURLWithPath:filePath isDirectory:NO];
  FilesystemMonitor* filesystemMonitor = [[[FilesystemMonitor alloc] initWithURL:fileUrl delegate:self] autorelease];

  return filesystemMonitor;
}

// -----------------------------------------------------------------------------
/// @brief Sorts @a gameList in-place according to the current sort criteria.
// -----------------------------------------------------------------------------
- (void) sortGameList:(NSMutableArray*)gameList
{
  // TODO: sort by file date if self.sortCriteria says so. It might be
  // interesting to have a look at NSComparator and blocks.
  NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil
                                                                   ascending:self.sortAscending
                                                                    selector:@selector(compare:)];
  [gameList sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

#pragma mark - Public interface part 2

// -----------------------------------------------------------------------------
/// @brief Returns a unique name that can be used to save @a game right now.
/// The name is guaranteed to be unique only at the time this method is invoked.
///
/// The name is suitable for display in the UI. The name pattern is
/// "BBB vs. WWW iii", where
/// - BBB = Black player name
/// - WWW = White player name
/// - iii = Numeric counter starting with 1. The counter does not use prefix
///         zeroes.
// -----------------------------------------------------------------------------
- (NSString*) uniqueGameNameForGame:(GoGame*)game;
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* uniqueGameName = nil;
  NSString* prefix = [NSString stringWithFormat:@"%@ vs. %@", game.playerBlack.player.name, game.playerWhite.player.name];
  int suffix = 1;
  while (true)
  {
    uniqueGameName = [NSString stringWithFormat:@"%@ %d", prefix, suffix];
    NSString* uniqueFileName = [uniqueGameName stringByAppendingString:@".sgf"];
    NSString* uniqueFilePath = [self.archiveFolder stringByAppendingPathComponent:uniqueFileName];
    if (! [fileManager fileExistsAtPath:uniqueFilePath])
      break;
    suffix++;
  }
  return uniqueGameName;
}

// -----------------------------------------------------------------------------
/// @brief Returns a unique name for @a preferredGameName that can be used to
/// save a game right now. The name is guaranteed to be unique only at the time
/// this method is invoked.
///
/// If no other game exists with the same name, this method returns a copy of
/// @a preferredGameName.
///
/// If another game with the same name already exists, this method adds a suffix
/// to @a preferredGameName to make the preferred game name unique. The pattern
/// is "preferredGameName iii", where
/// - iii = Numeric counter starting with 1. The counter does not use prefix
///         zeroes. If a game with counter 1 already exists, the counter is
///         increased to 2, etc.
// -----------------------------------------------------------------------------
- (NSString*) uniqueGameNameForName:(NSString*)preferredGameName
{
  if (! [self gameWithName:preferredGameName])
    return [[preferredGameName copy] autorelease];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* uniqueGameName = nil;
  int suffix = 1;
  while (true)
  {
    uniqueGameName = [NSString stringWithFormat:@"%@ %d", preferredGameName, suffix];
    NSString* uniqueFileName = [uniqueGameName stringByAppendingString:@".sgf"];
    NSString* uniqueFilePath = [self.archiveFolder stringByAppendingPathComponent:uniqueFileName];
    if (! [fileManager fileExistsAtPath:uniqueFilePath])
      break;
    suffix++;
  }
  return uniqueGameName;
}

// -----------------------------------------------------------------------------
/// @brief Returns the full file path of the game whose name is @a name. The
/// file path may or may not refer to an already existing file.
// -----------------------------------------------------------------------------
- (NSString*) filePathForGameWithName:(NSString*)name
{
  NSString* fileName = [name stringByAppendingString:@".sgf"];
  NSString* filePath = [self.archiveFolder stringByAppendingPathComponent:fileName];
  return filePath;
}

// -----------------------------------------------------------------------------
/// @brief Update the model data in preparation of an upcoming file rename.
///
/// A rename in the filesystem will trigger a model update via filesystem
/// monitoring. The model update tries to match ArchiveGame objects to
/// filesystem entries via their file names. This would lead to the ArchiveGame
/// object that represents the renamed file to be no longer being recognized and
/// marked as deleted. This method avoids this situation, allowing the
/// ArchiveGame object to remain valid so that details about the game can
/// continue to be displayed in the UI.
// -----------------------------------------------------------------------------
- (bool) archiveGame:(ArchiveGame*)archiveGame willBeRenamedTo:(NSString*)newFileName
{
  // Below we replace the fileName property value in the ArchiveGame object.
  // To make sure that the old NSString object is not deallocated we do
  // a retain/autorelease here.
  NSString* oldFileName = [[archiveGame.fileName retain] autorelease];

  NSMutableArray* oldGameData = [self.gameDictionary objectForKey:oldFileName];
  if (! oldGameData)
  {
    DDLogError(@"%@: No game data for old file name: %@", self, oldFileName);
    return false;
  }

  NSMutableArray* newGameData = [self.gameDictionary objectForKey:newFileName];
  if (newGameData)
  {
    DDLogError(@"%@: Game data for new file name is already present: %@", self, newFileName);
    return false;
  }

  ArchiveGame* game = oldGameData.firstObject;
  game.fileName = newFileName;

  // We can't be sure whether monitoring would continue to work after the
  // rename, and in any case we would receive the wrong NSURL for any
  // notifications. See FilesystemMonitor class documentation for details.
  // The cleanest way is to stop monitoring and create a new FilesystemMonitor
  // with the new name.
  FilesystemMonitor* oldFilesystemMonitor = oldGameData.lastObject;
  [oldFilesystemMonitor stopMonitoring];

  // Because the file has not yet been renamed, we cannot yet start to
  // monitor the new name. This will happen on the next full model update.
  NSString* newFilePath = [self.archiveFolder stringByAppendingPathComponent:newFileName];
  FilesystemMonitor* newFilesystemMonitor = [self createFilesystemMonitor:newFilePath];

  newGameData = [NSMutableArray arrayWithObjects:game, newFilesystemMonitor, nil];
  [self.gameDictionary removeObjectForKey:oldFileName];
  self.gameDictionary[newFileName] = newGameData;

  // Re-sort and replace the entire array to trigger KVO.
  // We already do this here to keep the model data consistent, although we
  // expect a filesystem rename to occur soon after this method was called,
  // which will cause self.gameList to be updated again.
  NSMutableArray* newGameList = [NSMutableArray arrayWithArray:self.gameList];
  [self sortGameList:newGameList];
  self.gameList = newGameList;

  return true;
}

@end
