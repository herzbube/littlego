// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "AnnotationViewController.h"
#import "AnnotationViewControllerPhonePortraitOnly.h"
#import "../../shared/LayoutManager.h"
#import "../../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for AnnotationViewController.
// -----------------------------------------------------------------------------
@interface AnnotationViewController()
@end


@implementation AnnotationViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a UI type-dependent controller
/// object that knows how to set up the correct view hierarchy for the current
/// UI type.
// -----------------------------------------------------------------------------
+ (AnnotationViewController*) annotationViewController
{
  AnnotationViewController* annotationViewController = nil;
  switch ([LayoutManager sharedManager].uiType)
  {
    case UITypePhonePortraitOnly:
      annotationViewController = [[[AnnotationViewControllerPhonePortraitOnly alloc] init] autorelease];
      break;
    default:
      [ExceptionUtility throwInvalidUIType:[LayoutManager sharedManager].uiType];
  }

  return annotationViewController;
}

// -----------------------------------------------------------------------------
/// @brief Applies a "transparent" style to the view managed by this
/// AnnotationViewController, the transparency making it appear as if the view
/// "floats" on top of its superview.
///
/// The style applied by this method is the same "transparent" style  that is
/// also used by ButtonBoxController.
// -----------------------------------------------------------------------------
- (void) applyTransparentStyle
{
  self.view.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.6f];
  self.view.layer.borderWidth = 1;
}

@end
