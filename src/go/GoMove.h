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


#include "../Constants.h"

@class GoPoint;

@interface GoMove : NSObject
{
}

+ (GoMove*) newMove:(enum GoMoveType)type after:(GoMove*)move;
- (GoMove*) init:(enum GoMoveType)type;

@property enum GoMoveType type;
@property(retain) GoPoint* point;
@property(getter=isBlack) bool black;
@property(retain) GoMove* previous;   // TODO check for retain cycle
@property(retain) GoMove* next;       // TODO check for retain cycle

@end
