// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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


// Test includes
#import "GoPlayerTest.h"

// Application includes
#import <go/GoGame.h>
#import <go/GoPlayer.h>
#import <main/ApplicationDelegate.h>
#import <newgame/NewGameModel.h>
#import <player/Player.h>


@implementation GoPlayerTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of GoPlayer objects after a new GoGame has
/// been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  XCTAssertNotNil(m_game.playerBlack);
  XCTAssertNotNil(m_game.playerBlack.player);
  XCTAssertTrue(m_game.playerBlack.isBlack);
  XCTAssertTrue([m_game.playerBlack.colorString isEqualToString:@"B"]);
  XCTAssertNotNil(m_game.playerWhite);
  XCTAssertNotNil(m_game.playerWhite.player);
  XCTAssertFalse(m_game.playerWhite.isBlack);
  XCTAssertTrue([m_game.playerWhite.colorString isEqualToString:@"W"]);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the defaultBlackPlayer() and defaultWhitePlayer()
/// convenience constructors.
// -----------------------------------------------------------------------------
- (void) testDefaultBlackWhitePlayer
{
  GoPlayer* defaultBlackPlayer = [GoPlayer defaultBlackPlayer];
  XCTAssertNotNil(defaultBlackPlayer);
  XCTAssertTrue(m_game.playerBlack != defaultBlackPlayer);
  XCTAssertEqual(m_game.playerBlack.player, defaultBlackPlayer.player);
  XCTAssertTrue(defaultBlackPlayer.isBlack);
  XCTAssertTrue([defaultBlackPlayer.colorString isEqualToString:@"B"]);

  GoPlayer* defaultWhitePlayer = [GoPlayer defaultWhitePlayer];
  XCTAssertNotNil(defaultWhitePlayer);
  XCTAssertTrue(m_game.playerWhite != defaultWhitePlayer);
  XCTAssertEqual(m_game.playerWhite.player, defaultWhitePlayer.player);
  XCTAssertFalse(defaultWhitePlayer.isBlack);
  XCTAssertTrue([defaultWhitePlayer.colorString isEqualToString:@"W"]);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the defaultBlackPlayer() and defaultWhitePlayer()
/// convenience constructors when the default black/white player UUIDs in
/// NewGameModel refer to Player objects that do not exist.
// -----------------------------------------------------------------------------
- (void) testInvalidDefaultBlackWhitePlayer
{
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
  newGameModel.gameType = GoGameTypeHumanVsHuman;
  newGameModel.humanBlackPlayerUUID = @"invalid_black";
  newGameModel.humanWhitePlayerUUID = @"invalid_white";
  GoPlayer* defaultBlackPlayer = [GoPlayer defaultBlackPlayer];
  XCTAssertNil(defaultBlackPlayer);
  GoPlayer* defaultWhitePlayer = [GoPlayer defaultWhitePlayer];
  XCTAssertNil(defaultWhitePlayer);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the blackPlayer() and whitePlayer() convenience
/// constructors.
// -----------------------------------------------------------------------------
- (void) testBlackWhitePlayer;
{
  Player* player = [[[Player alloc] init] autorelease];

  GoPlayer* blackPlayer = [GoPlayer blackPlayer:player];
  XCTAssertNotNil(blackPlayer);
  XCTAssertTrue(m_game.playerBlack != blackPlayer);
  XCTAssertEqual(player, blackPlayer.player);
  XCTAssertTrue(blackPlayer.isBlack);
  XCTAssertTrue([blackPlayer.colorString isEqualToString:@"B"]);

  GoPlayer* whitePlayer = [GoPlayer whitePlayer:player];
  XCTAssertNotNil(whitePlayer);
  XCTAssertTrue(m_game.playerWhite != whitePlayer);
  XCTAssertEqual(player, whitePlayer.player);
  XCTAssertFalse(whitePlayer.isBlack);
  XCTAssertTrue([whitePlayer.colorString isEqualToString:@"W"]);

  XCTAssertThrowsSpecificNamed([GoPlayer blackPlayer:nil],
                              NSException, NSInvalidArgumentException, @"test 1");
  XCTAssertThrowsSpecificNamed([GoPlayer whitePlayer:nil],
                              NSException, NSInvalidArgumentException, @"test 2");
}

@end
