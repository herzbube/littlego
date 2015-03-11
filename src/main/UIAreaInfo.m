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


// Project includes
#import "UIAreaInfo.h"

// System includes
#import <objc/runtime.h>

// Constants
NSString* associatedUIAreaObjectKey = @"AssociatedUIAreaObject";


@implementation UIViewController(UIAreaInfo)

- (enum UIArea) uiArea
{
  NSNumber* uiAreaAsNumber = objc_getAssociatedObject(self, associatedUIAreaObjectKey);
  if (uiAreaAsNumber)
    return [uiAreaAsNumber intValue];
  else
    return UIAreaUnknown;
}

- (void) setUiArea:(enum UIArea)uiArea
{
  objc_setAssociatedObject(self, associatedUIAreaObjectKey, [NSNumber numberWithInt:uiArea], OBJC_ASSOCIATION_RETAIN);
}

@end