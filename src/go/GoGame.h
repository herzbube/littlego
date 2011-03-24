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


// Forward declarations
@class GoBoard;
@class GoPlayer;
@class GoMove;
@class GoPoint;


// GoGame takes the role of a model in an MVC pattern that includes, for
// instance, the view and controller on the Play tab
@interface GoGame : NSObject
{
}

+ (GoGame*) sharedGame;
- (void) play:(GoPoint*)point;
- (void) pass;
- (void) computerPlay;
- (void) resign;
- (void) undo;

@property(retain) GoBoard* board;
@property(retain) GoPlayer* playerBlack;
@property(retain) GoPlayer* playerWhite;
@property(retain) GoMove* firstMove;
@property(retain) GoMove* lastMove;
@property enum GoGameState state;
@property int boardSize;

@end
