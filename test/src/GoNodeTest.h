// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The GoNodeTest class contains unit tests that exercise the GoNode
/// class (including the operations defined in the GoNodeAdditions category).
// -----------------------------------------------------------------------------
@interface GoNodeTest : BaseTestCase
{
}

- (void) testInitialState;
- (void) testNode;
- (void) testNodeWithMove;
- (void) testSetFirstChild;
- (void) testChildrenAndHasChildrenAndIsBranchingNode;
- (void) testAppendChild;
- (void) testInsertChildBeforeReferenceChildWhenReferenceChildIsNil;
- (void) testInsertChildBeforeReferenceChildWhenReferenceChildIsNotNil;
- (void) testRemoveChild;
- (void) testReplaceChild;
- (void) testSetNextSibling;
- (void) testSetParent;
- (void) testIsDescendantOfNode;
- (void) testIsAncestorOfNode;
- (void) testEmpty;
- (void) testModifyBoard;
- (void) testRevertBoard;

@end
