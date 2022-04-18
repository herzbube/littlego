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
  enum UIType uiType = [LayoutManager sharedManager].uiType;
  switch (uiType)
  {
    case UITypePhonePortraitOnly:
    case UITypePhone:
    case UITypePad:
      annotationViewController = [[[AnnotationViewControllerPhonePortraitOnly alloc] initWithUiType:uiType] autorelease];
      break;
    default:
      [ExceptionUtility throwInvalidUIType:[LayoutManager sharedManager].uiType];
  }

  return annotationViewController;
}

@end
