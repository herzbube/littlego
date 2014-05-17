// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The FontRange class precalculates rectangles required to draw a given
/// string with variable font sizes. You use FontRange when you know in advance
/// which text you want to draw, and which font you want to use for drawing, but
/// you don't know yet which font size you will be using.
///
/// When you create a FontRange object you specify the text that you want to
/// draw, and the minimum and maximum font size you expect to use for drawing.
/// Currently FontRange only supports drawing with the system font, in a later
/// version you will be able to supply the font name.
///
/// When you are ready to draw the text, you query the FontRange object by
/// specifying the width that you have available for drawing the text. As a
/// result, FontRange will provide you with the following:
/// - A UIFont object. If you use this UIFont for drawing the text specified
///   at construction time, the drawn text will make maximum use of the width
///   you specified. In other words, if you were using a UIFont object with a
///   font size that is 1 unit larger, the drawn text would no longer fit into
///   the width you specified.
/// - A CGSize structure. This is the precalculated size required to draw the
///   text specified at construction time with the UIFont that you just received
///   as the first result of the query.
///
/// @note The use case that FontRange was originally developed for is the
/// drawing of move numbers on a Go board. The client knows in advance the
/// largest move number it will draw ("largest" in terms of space required for
/// drawing the number), but it does not yet know which size will be available
/// for drawing the move numbers (the available size varies with the size of
/// Go stones). When it is time to draw, the client specifies the available
/// size and uses the resulting UIFont to do the drawing. It uses the resulting
/// CGSize to create the drawing rectangle. Because move numbers are of varying
/// length, the client draws the move number centered within the rectangle.
// -----------------------------------------------------------------------------
@interface FontRange : NSObject
{
}

- (id) initWithText:(NSString*)text
    minimumFontSize:(int)minimumFontSize
    maximumFontSize:(int)maximumFontSize;

- (bool) queryForWidth:(CGFloat)width
                  font:(UIFont**)font
              textSize:(CGSize*)textSize;

@end
