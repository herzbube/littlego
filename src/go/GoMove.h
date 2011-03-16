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


// Project includes
#include "../Constants.h"

// Forward declarations
@class GoPoint;


@interface GoMove : NSObject
{
}

+ (GoMove*) move:(enum GoMoveType)type after:(GoMove*)move;
- (GoMove*) init:(enum GoMoveType)initType;

@property enum GoMoveType type;
@property(retain) GoPoint* point;
@property(getter=isBlack) bool black;
// TODO: Check if previous and next properties should be made read-only to
// the public, because otherwise anyone invoking the setters would also have
// to take care of the double-linked list, similarly to how it is done in the
// convenience constructor move:after:(). Alternatively, setters could be
// implemented that can handle double-linking.
@property(assign) GoMove* previous;       // do not retain, otherwise there would be a retain cycle
@property(retain) GoMove* next;   // retain here, making us the parent, and next the child

@end
