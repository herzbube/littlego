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
/// MagnifyingView also has several optional features to make the loupe look
/// great:
/// - A radial gradient that progresses downwards, from mostly transparent black
///   at the upper edge of the loupe, to fully transparent white in the lower
///   part of the loupe. This attempts to recreate the light distortion effect
///   of a magnifying glass.
/// - A border around the loupe
/// - A hotspot that marks the center of magnification
///
/// The radial gradient is the most difficult part of MagnifyingView to
/// customize. Things that need to be considered:
/// - Size of the magnified area. This influences the center and radius of the
///   gradient's inner circle. These can be adjusted by defining their vertical
///   distance from the bottom of the loupe.
/// - Lightness/darkness of the magnified content. If the magnified content is
///   very light (e.g. because of a white background) then the loupe can be
///   made darker than if the magnified content is rather dark. The amount of
///   alpha on the black color determines how dark the loupe appears.
///
/// This is how the radial gradient looks like, using overblown ASCII art :-).
/// @verbatim
///                      ,,ggddY""""Ybbgg,,
///                 ,agd""'              `""bg,
///              ,gdP"                       "Ybg,
///            ,dP"                             "Yb,
///          ,dP"                                 "Yb,
///         ,8"                                     "8,
///        ,8'                                       `8,
///       ,8'                                         `8,
///       d'                                           `b
///       8                                             8
///       8                                             8
///       8                                             8
///       8                                             8
///       Y,                                           ,P
///       `8,                 ,gPPRg,                 ,8'
///        `8,               dP'   `Yb               ,8'
///         `8a              8)     (8              a8'
///          `Yba            Yb     dP            adP'
///            "Yba           "8ggg8"           adY"
///              `"Yba,                     ,adP"'
///                 `"Y8ba,             ,ad8P"'
///                      ``""YYbaaadPP""''
/// @endverbatim
// -----------------------------------------------------------------------------
@interface MagnifyingView : UIView
{
}

@property(nonatomic, retain) UIImage* magnifiedImage;

@property(nonatomic, assign) bool gradientEnabled;
@property(nonatomic, retain) UIColor* gradientOuterColor;
@property(nonatomic, retain) UIColor* gradientInnerColor;
@property(nonatomic, assign) CGFloat gradientInnerCircleCenterDistanceFromBottom;
@property(nonatomic, assign) CGFloat gradientInnerCircleEdgeDistanceFromBottom;
@property(nonatomic, assign) bool borderEnabled;
@property(nonatomic, retain) UIColor* borderColor;
@property(nonatomic, assign) CGFloat borderWidth;
@property(nonatomic, assign) bool hotspotEnabled;
@property(nonatomic, retain) UIColor* hotspotColor;
@property(nonatomic, assign) CGFloat hotspotRadius;

@end
