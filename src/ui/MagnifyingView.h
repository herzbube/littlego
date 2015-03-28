// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The MagnifyingView class draws a provided UIImage so that it appears
/// as if inside a circular loupe.
///
/// The circular loupe effect is achieved simply by clipping the provided image
/// to a circular path whose diameter is equal to the size of the
/// MagnifyingView. If MagnifyingView is rectangular, the lesser dimension of
/// the rectangle is used as the diameter.
///
/// In addition to clipping, MagnifyingView also draws a stroked circle around
/// the magnified image, to separate the image from its surrounding content.
// -----------------------------------------------------------------------------
@interface MagnifyingView : UIView
{
}

@property(nonatomic, retain) UIImage* magnifiedImage;

@end
