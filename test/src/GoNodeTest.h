// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
///
/// For the following properties there are no dedicated test methods, because
/// these properties are tested extensively as part of the other tests.
/// - firstChild
/// - lastChild
/// - nextSibling
/// - previousSibling
/// - parent
/// - zobristHash
///
/// These properties are not explicitly tested because both their getter and
/// setter do not contain any logic:
/// - goNodeSetup
/// - goMove
/// - goNodeAnnotation
/// - goNodeMarkup
/// - nodeID (the property is declared privately and only the setter is exposed
///   via GoNodeAdditions)
///
/// Finally, the GoNodeAdditions method restoreTreeLinks:() is not testable in
/// an isolated manner because its implementation is closely tied to the
/// archiving/unarchiving logic of GoNodeTest. Test coverage for
/// restoreTreeLinks:() is therefore delegated to the archiving/unarchiving
/// test(s) in GoGameTest.
// -----------------------------------------------------------------------------
@interface GoNodeTest : BaseTestCase
{
}

- (void) testInitialState;
- (void) testNode;
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
- (void) testHasNextSibling;
- (void) testHasPreviousSibling;
- (void) testHasParent;
- (void) testIsRoot;
- (void) testIsLeaf;
- (void) testEmpty;
- (void) testModifyBoard;
- (void) testRevertBoard;
- (void) testCalculateZobristHash;

@end
