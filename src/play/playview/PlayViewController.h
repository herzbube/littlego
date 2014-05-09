// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
@class PanGestureController;


// -----------------------------------------------------------------------------
/// @brief The PlayViewController class is responsible for setting up the main
/// view on the "Play" tab that represents the Go board.
///
/// PlayViewController is a child view controller.
// -----------------------------------------------------------------------------
@interface PlayViewController : UIViewController
{
}

@property(nonatomic, retain) PlayView* playView;
@property(nonatomic, retain) PanGestureController* panGestureController;

@end
