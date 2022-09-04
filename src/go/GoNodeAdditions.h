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
#import "GoNode.h"


// -----------------------------------------------------------------------------
/// @brief The GoNodeAdditions category enhances GoNode by adding tree building
/// methods, i.e. methods that allow to modify the game tree, and methods for
/// NSCoding support.
///
/// @ingroup go
///
/// As a bit of syntactic sugar the setter methods declared in the
/// GoNodeAdditions category make the GoNode properties @e firstChild,
/// @e nextSibling and @e parent (which are declared read-only in the GoNode
/// public interface) into writable properties.
// -----------------------------------------------------------------------------
@interface GoNode(GoNodeAdditions)

/// @name Tree building
//@{
- (void) setFirstChild:(GoNode*)child;
- (void) appendChild:(GoNode*)child;
- (void) insertChild:(GoNode*)child beforeReferenceChild:(GoNode*)referenceChild;
- (void) removeChild:(GoNode*)child;
- (void) replaceChild:(GoNode*)oldChild withNewChild:(GoNode*)newChild;
- (void) setNextSibling:(GoNode*)nextSibling;
- (void) setParent:(GoNode*)parent;
//@}

/// @name NSCoding support
//@{
- (void) setNodeID:(int)nodeID;
- (void) restoreTreeLinks:(NSDictionary*)nodeDictionary;
//@}

@end
