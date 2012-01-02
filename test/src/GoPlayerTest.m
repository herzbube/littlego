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


// Test includes
#import "GoPlayerTest.h"

// Application includes
#import <go/GoGame.h>
#import <go/GoPlayer.h>
#import <player/Player.h>


@implementation GoPlayerTest

// -----------------------------------------------------------------------------
/// @brief Checks the initial state of a GoPoint object after a new GoGame has
/// been created.
// -----------------------------------------------------------------------------
- (void) testInitialState
{
  STAssertNotNil(m_game.playerBlack, nil);
  STAssertNotNil(m_game.playerBlack.player, nil);
  STAssertTrue(m_game.playerBlack.isBlack, nil);
  STAssertTrue([m_game.playerBlack.colorString isEqualToString:@"B"], nil);
  STAssertNotNil(m_game.playerWhite, nil);
  STAssertNotNil(m_game.playerWhite.player, nil);
  STAssertFalse(m_game.playerWhite.isBlack, nil);
  STAssertTrue([m_game.playerWhite.colorString isEqualToString:@"W"], nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the newGameBlackPlayer() and newGameWhitePlayer()
/// convenience constructors.
// -----------------------------------------------------------------------------
- (void) testNewGamePlayer
{
  GoPlayer* newGameBlackPlayer = [GoPlayer newGameBlackPlayer];
  STAssertNotNil(newGameBlackPlayer, nil);
  STAssertTrue(m_game.playerBlack != newGameBlackPlayer, nil);
  STAssertEquals(m_game.playerBlack.player, newGameBlackPlayer.player, nil);
  STAssertTrue(newGameBlackPlayer.isBlack, nil);
  STAssertTrue([newGameBlackPlayer.colorString isEqualToString:@"B"], nil);

  GoPlayer* newGameWhitePlayer = [GoPlayer newGameWhitePlayer];
  STAssertNotNil(newGameWhitePlayer, nil);
  STAssertTrue(m_game.playerWhite != newGameWhitePlayer, nil);
  STAssertEquals(m_game.playerWhite.player, newGameWhitePlayer.player, nil);
  STAssertFalse(newGameWhitePlayer.isBlack, nil);
  STAssertTrue([newGameWhitePlayer.colorString isEqualToString:@"W"], nil);
}

// -----------------------------------------------------------------------------
/// @brief Exercises the blackPlayer() and whitePlayer() convenience
/// constructors.
// -----------------------------------------------------------------------------
- (void) testBlackWhitePlayer;
{
  Player* player = [[[Player alloc] init] autorelease];

  GoPlayer* blackPlayer = [GoPlayer blackPlayer:player];
  STAssertNotNil(blackPlayer, nil);
  STAssertTrue(m_game.playerBlack != blackPlayer, nil);
  STAssertEquals(player, blackPlayer.player, nil);
  STAssertTrue(blackPlayer.isBlack, nil);
  STAssertTrue([blackPlayer.colorString isEqualToString:@"B"], nil);

  GoPlayer* whitePlayer = [GoPlayer whitePlayer:player];
  STAssertNotNil(whitePlayer, nil);
  STAssertTrue(m_game.playerWhite != whitePlayer, nil);
  STAssertEquals(player, whitePlayer.player, nil);
  STAssertFalse(whitePlayer.isBlack, nil);
  STAssertTrue([whitePlayer.colorString isEqualToString:@"W"], nil);

  STAssertThrowsSpecificNamed([GoPlayer blackPlayer:nil],
                              NSException, NSInvalidArgumentException, @"test 1");
  STAssertThrowsSpecificNamed([GoPlayer whitePlayer:nil],
                              NSException, NSInvalidArgumentException, @"test 2");
}

@end
