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
/// @brief The InvalidTimeDataView class is a UIView subclass that displays
/// information about why the time data in the currently selected node is
/// invalid.
// -----------------------------------------------------------------------------
@interface InvalidTimeDataView : UIView
{
}

/// @brief True if the time data in the currently selected node is valid. False
/// if time data is not valid. In the latter case, the value of property
/// @e timeDataInvalidReason indicates the reason why the time data is not
/// valid.
@property(nonatomic, assign) bool isTimeDataValid;

/// @brief If property @e isTimeDataValid is false, indicates the reason why
/// the time data is not valid. If property @e isTimeDataValid is true, this
/// property has value -1.
@property(nonatomic, assign) enum GoTimeDataInvalidReason timeDataInvalidReason;

@end
