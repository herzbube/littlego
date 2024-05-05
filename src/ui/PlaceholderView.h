// -----------------------------------------------------------------------------
// Copyright 2021-2024 Patrick Näf (herzbube@herzbube.ch)
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


/// @brief Enumerates styles how the placeholder view lays out its content.
enum PlaceholderViewStyle
{
  /// @brief PlaceholderView divides its height into thirds and places the
  /// placeholder label so that its top edge starts after one third. The result
  /// is a generous spacing of one third at the top and the label gets
  /// sufficient vertical space in case longer texts are shown.
  ///
  /// @verbatim
  /// +--PlaceholderView-------------+
  /// | +-One third----------------+ |
  /// | |                          | |
  /// | |                          | |
  /// | |                          | |
  /// | |                          | |
  /// | +--------------------------+ |
  /// | +-Two thirds---------------+ |
  /// | | +-Placeholder label----+ | |
  /// | | | Placeholder text     | | |
  /// | | +----------------------+ | |
  /// | |                          | |
  /// | |                          | |
  /// | |                          | |
  /// | |                          | |
  /// | |                          | |
  /// | |                          | |
  /// | |                          | |
  /// | +--------------------------+ |
  /// +------------------------------+
  /// @endverbatim
  PlaceholderViewStyleThirds,

  /// @brief PlaceholderView vertically centers the placeholder label.
  PlaceholderViewStyleCenter
};

// -----------------------------------------------------------------------------
/// @brief The PlaceholderView class displays a single label with a placeholder
/// text, rendered in larger-than-normal font. PlaceholderView is intended to be
/// shown instead of real content, or when no other content is available.
// -----------------------------------------------------------------------------
@interface PlaceholderView : UIView
{
}

- (id) initWithFrame:(CGRect)rect placeholderText:(NSString*)placeholderText;
- (id) initWithFrame:(CGRect)rect placeholderText:(NSString*)placeholderText style:(enum PlaceholderViewStyle)placeholderViewStyle;

@property(nonatomic, retain, readonly) UILabel* placeholderLabel;
@property(nonatomic, assign, readonly) enum PlaceholderViewStyle placeholderViewStyle;

@end
