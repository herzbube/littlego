// -----------------------------------------------------------------------------
// Copyright 2025-2026 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The TimeViewController class is responsible for displaying
/// time-related information in #UIAreaPlay.
///
/// TimeViewController supports two modes:
/// - In "clock view" mode, TimeViewController shows two TimeView instances
///   side-by-side, representing the two players' clocks. In this mode,
///   TimeViewController also provides gesture handling so that the user can
///   suspend or resume a player's clock.
/// - In "node time data view" mode, TimeViewController shows only a single
///   TimeView that displays the time data in the currently selected node.
// -----------------------------------------------------------------------------
@interface TimeViewController : UIViewController
{
}

/// @brief The pre-calculated size of the view of TimeViewController when it
/// operates in "clock view" mode.
///
/// When this method is invoked the first time, it performs the necessary size
/// calculations.
+ (CGSize) timeViewControllerClockViewSize;

- (id) initWithClockView;
- (id) initWithNodeTimeDataView;

@end
