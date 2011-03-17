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


@interface GoGame : NSObject
{
}

+ (GoGame*) sharedGame;
- (void) play:(GoPoint*)point;
- (void) playForMe;
- (void) pass;
- (void) undo;
- (void) resign;

@property(retain) GoBoard* board;
@property(retain) GoPlayer* playerBlack;
@property(retain) GoPlayer* playerWhite;
@property(getter=hasStarted) bool started;
@property(getter=hasEnded) bool ended;
@property(retain) GoMove* firstMove;
@property(retain) GoMove* lastMove;

@end
