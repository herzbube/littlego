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
/// @brief The GoNodeMarkupTest class contains unit tests that exercise the
/// GoNodeMarkup class.
// -----------------------------------------------------------------------------
@interface GoNodeMarkupTest : BaseTestCase
{
}

- (void) testInitialState;
- (void) testHasMarkup;
- (void) testSetSymbolAtVertex;
- (void) testRemoveSymbolAtVertex;
- (void) testReplaceSymbols;
- (void) testRemoveAllSymbols;
- (void) testSetConnectionFromVertexToVertex;
- (void) testRemoveConnectionFromVertexToVertex;
- (void) testReplaceConnections;
- (void) testRemoveAllConnections;
- (void) testSetLabelLabelTextAtVertex;
- (void) testRemoveLabelAtVertex;
- (void) testReplaceLabels;
- (void) testRemoveAllLabels;
- (void) testRemoveNewlinesAndTrimLabel;
- (void) testLabelTypeOfLabel;
- (void) testLabelTypeOfLabelLetterMarkerValueNumberMarkerValue;
- (void) testSetDimmingAtVertex;
- (void) testRemoveDimmingAtVertex;
- (void) testReplaceDimmings;
- (void) testUndimEverything;
- (void) testRemoveAllDimmings;

@end
