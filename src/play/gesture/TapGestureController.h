// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
@class PlayView;
@class ScoringModel;


// -----------------------------------------------------------------------------
/// @brief The TapGestureController class is responsible for managing the tap
/// gesture on the "Play" view. Tapping is used to mark dead stones during
/// scoring.
// -----------------------------------------------------------------------------
@interface TapGestureController : NSObject <UIGestureRecognizerDelegate>
{
}

- (id) initWithPlayView:(PlayView*)playView scoringModel:(ScoringModel*)scoringModel;

@end
