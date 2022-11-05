// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "RestoreGameFromSgfCommand.h"
#import "../game/LoadGameCommand.h"
#import "../sgf/LoadSgfCommand.h"
#import "../../utility/PathUtilities.h"


@implementation RestoreGameFromSgfCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  BOOL fileExists;
  NSString* backupFilePath = [PathUtilities filePathForBackupFileNamed:sgfBackupFileName
                                                            fileExists:&fileExists];
  if (! fileExists)
    return false;

  LoadSgfCommand* loadSgfCommand = [[[LoadSgfCommand alloc] initWithSgfFilePath:backupFilePath] autorelease];
  // We don't want weird user settings to prevent the loading of our backup
  // file. For instance the user could have set up a forced encoding which
  // might cause the load operation to fail because our backup file is written
  // with UTF-8 encoding.
  loadSgfCommand.ignoreSgfSettings = true;
  bool success = [loadSgfCommand submit];
  if (! success)
  {
    DDLogError(@"%@: LoadSgfCommand failed to load backup file", [self shortDescription]);
    assert(0);
    return false;
  }

  SGFCDocumentReadResult* sgfReadResult = loadSgfCommand.sgfDocumentReadResultSingleEncoding;

  // We perform only basic data validation. The backup file was written by us
  // and it should never have any errors.
  if (! sgfReadResult.isSgfDataValid)
  {
    DDLogError(@"%@: SGF data loaded by LoadSgfCommand from backup file is invalid", [self shortDescription]);
    assert(0);
    return false;
  }
  SGFCDocument* sgfDocument = sgfReadResult.document;
  NSArray* sgfGames = sgfDocument.games;
  if (sgfGames.count != 1)
  {
    DDLogError(@"%@: SGF data loaded by LoadSgfCommand from backup file has more than 1 game", [self shortDescription]);
    assert(0);
    return false;
  }
  SGFCGame* sgfGame = [sgfGames firstObject];
  NSArray* sgfGameInfoNodes = sgfGame.gameInfoNodes;
  // At the time when this code was written a game info node is always present
  // in the backup file, because SaveSgfCommand always writes handicap and komi
  // even if they have the default value 0. It's conceivable, though, that this
  // might change in the future, so we guard against it and use the root node
  // as replacement.
  if (sgfGameInfoNodes.count == 0)
  {
    if (! sgfGame.hasRootNode)
    {
      DDLogError(@"%@: SGF data loaded by LoadSgfCommand from backup file has no root node", [self shortDescription]);
      assert(0);
      return false;
    }
    sgfGameInfoNodes = @[sgfGame.rootNode];
  }
  else if (sgfGameInfoNodes.count > 1)
  {
    DDLogError(@"%@: SGF data loaded by LoadSgfCommand from backup file has more than 1 game info node", [self shortDescription]);
    assert(0);
    return false;
  }
  SGFCNode* sgfGameInfoNode = [sgfGameInfoNodes firstObject];
  SGFCGoGameInfo* sgfGoGameInfo = sgfGameInfoNode.gameInfo.toGoGameInfo;
  if (! sgfGoGameInfo)
  {
    DDLogError(@"%@: SGF data loaded by LoadSgfCommand from backup file does not contain a Go game", [self shortDescription]);
    assert(0);
    return false;
  }

  LoadGameCommand* loadCommand = [[[LoadGameCommand alloc] initWithGameInfoNode:sgfGameInfoNode goGameInfo:sgfGoGameInfo game:sgfGame] autorelease];
  loadCommand.restoreMode = true;
  success = [loadCommand submit];
  return success;
}

@end
