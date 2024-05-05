// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "BaseTestCase.h"


// -----------------------------------------------------------------------------
/// @brief The GoMoveTest class contains unit tests that exercise the GoMove
/// class.
// -----------------------------------------------------------------------------
@interface GoMoveTest : BaseTestCase
{
}

- (void) testMoveByAfter;
- (void) testPoint;
- (void) testCapturedStones;
- (void) testCapturedStonesHandicapAndSetup;
- (void) testDoIt;
- (void) testUndo;
- (void) testMoveNumber;
- (void) testGoMoveValuation;

@end
