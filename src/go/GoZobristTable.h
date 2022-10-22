// -----------------------------------------------------------------------------
// Copyright 2013-2022 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GoBoard;
@class GoGame;
@class GoNode;
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The GoZobristTable class encapsulates a table with random values.
/// When requested by clients, it uses those values co calculate Zobrist hashes.
/// (Zobrist hashes are used to find superko). It is the responsibiility of
/// clients to store the calculated hashes for later use.
///
/// @ingroup go
///
/// Read the Wikipedia article [1] to find out more about Zobrist hashing.
///
/// GoZobristTable uses 64 bit random values to initialize the table. Why 64 bit
/// and not, for instance, 32 bit, or 128 bit? I am not a computer scientist, so
/// I do not know the real reason. I am simply using the same number of bits
/// as everybody else (e.g. Fuego, but also [2]). It appears that it is
/// universally accepted that the chance for a hash collision is extremely (!)
/// small when 64 bit values are used (e.g. [3]).
///
/// [1] https://en.wikipedia.org/wiki/Zobrist_hashing
/// [2] http://www.cwi.nl/~tromp/java/go/GoGame.java (URL defunct)
/// [3] http://osdir.com/ml/games.devel.go/2002-09/msg00006.html (URL defunct)
// -----------------------------------------------------------------------------
@interface GoZobristTable : NSObject
{
}

- (id) initWithBoardSize:(enum GoBoardSize)boardSize;

- (long long) hashForBoard:(GoBoard*)board;
- (long long) hashForHandicapStonesInGame:(GoGame*)game;
- (long long) hashForNode:(GoNode*)node
                   inGame:(GoGame*)game;
- (long long) hashForBlackSetupStones:(NSArray*)blackSetupStones
                     whiteSetupStones:(NSArray*)whiteSetupStones
                        noSetupStones:(NSArray*)noSetupStones
             previousBlackSetupStones:(NSArray*)previousBlackSetupStones
             previousWhiteSetupStones:(NSArray*)previousWhiteSetupStones
                            afterNode:(GoNode*)node
                               inGame:(GoGame*)game;
- (long long) hashForStonePlayedByColor:(enum GoColor)color
                                atPoint:(GoPoint*)point
                        capturingStones:(NSArray*)capturedStones
                              afterNode:(GoNode*)node
                                 inGame:(GoGame*)game;

@end
