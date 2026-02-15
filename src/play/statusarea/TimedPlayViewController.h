// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The TimedPlayViewController class is responsible for displaying
/// information related to timed play in #UIAreaPlay.
///
/// TimedPlayViewController shows one of two child view controllers depending
/// on whether the time data in the currently selected node is valid or not:
/// - Valid time data => TimeViewController.
/// - Invalid time data => InvalidTimeDataViewController.
///
/// TimedPlayViewController supports two modes (which it forwards to its child
/// view controllers):
/// - In "clock view" mode, TimedPlayViewController displays player clocks.
/// - In "node time data view" mode, TimedPlayViewController displays the time
///   data of the currently selected node.
// -----------------------------------------------------------------------------
@interface TimedPlayViewController : UIViewController
{
}

- (id) initWithClockView;
- (id) initWithNodeTimeDataView;

@end
