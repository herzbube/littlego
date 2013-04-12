// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The StatusLineController class is responsible for displaying texts
/// appropriate to the current game situation in the status line that is visible
/// on the Play tab.
///
/// This is a very simple class that has been refactored out from the main
/// PlayView class to keep that class focused on drawing the Go board.
// -----------------------------------------------------------------------------
@interface StatusLineController : NSObject
{
}

+ (StatusLineController*) controllerWithStatusLine:(UILabel*)statusLine;

@end
