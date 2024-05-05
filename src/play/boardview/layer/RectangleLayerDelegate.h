// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewLayerDelegateBase.h"


// -----------------------------------------------------------------------------
/// @brief The RectangleLayerDelegate class is responsible for drawing on points
/// that form a consecutive, unbroken area on the board, i.e. a rectangle (a
/// square is just a special form of rectangle). RectangleLayerDelegate can
/// draw only one rectangle at a time.
///
/// The main use of RectangleLayerDelegate is to draw a temporary overlay at the
/// top of the stack of layers that make up the board view. The rectangular area
/// drawn by RectangleLayerDelegate can change in form and size. The benefit of
/// the overlay mechanism is that other layers do not have to redraw their stuff
/// when this happens.
// -----------------------------------------------------------------------------
@interface RectangleLayerDelegate : BoardViewLayerDelegateBase
{
}

@end
