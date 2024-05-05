// -----------------------------------------------------------------------------
// Copyright 2023-2024 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief Helper class that collects the options governing how to create a
/// new GoNode and insert it into the game tree, including a post-insert action
/// to perform.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoNodeCreationOptions : NSObject
{
}

+ (GoNodeCreationOptions*) nodeCreationOptions;
+ (GoNodeCreationOptions*) nodeCreationOptionsWithInsertPosition:(enum GoNewNodeInsertPosition)newNodeInsertPosition
                                                postInsertAction:(enum GoNewNodePostInsertAction)newNodePostInsertAction;

@property(nonatomic, assign, readonly) enum GoNewNodeInsertPosition newNodeInsertPosition;
@property(nonatomic, assign, readonly) enum GoNewNodePostInsertAction newNodePostInsertAction;

@end
