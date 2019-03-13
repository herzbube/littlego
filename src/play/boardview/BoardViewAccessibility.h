// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
@class BoardView;


// -----------------------------------------------------------------------------
/// @brief The BoardViewAccessibility class is used by the BoardView class to
/// handle accessibility related stuff.
///
/// UI testing is based on the accessibility API that is deeply embedded in
/// UIKit. Because graphical board elements are drawn via CoreGraphics, not via
/// UIKit, these elements are not exposed to the accessibility layer and are
/// thus not available for UI testing.
///
/// The solution for this problem is that BoardView acts as a
/// UIAccessibilityContainer, exposing an array of UIAccessibilityElement
/// objects to the accessibility layer and thus to UI tests. BoardView delegates
/// the actual work for assembling the array of UIAccessibilityElement objects
/// to BoardViewAccessibility.
///
/// BoardViewAccessibility is also responsible for notifying the accessibility
/// layer when the content of the array changes.
// -----------------------------------------------------------------------------
@interface BoardViewAccessibility : NSObject
{
}

- (id) initWithBoardView:(BoardView*)boardView;

@property(nonatomic, retain, readonly) NSArray* accessibilityElements;

@end
