// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "KeyboardHeightAdjustment.h"
#import "../ui/AutoLayoutUtility.h"

// System includes
#import <objc/runtime.h>

// Constants
NSString* associatedKeyboardHeightAdjustmentViewToAdjustHeightObjectKey = @"AssociatedKeyboardHeightAdjustmentViewToAdjustHeightObject";
NSString* associatedKeyboardHeightAdjustmentReferenceViewObjectKey = @"AssociatedKeyboardHeightAdjustmentReferenceViewObject";
NSString* associatedKeyboardHeightAdjustmentHeightConstraintLowPriorityObjectKey = @"AssociatedKeyboardHeightAdjustmentHeightConstraintLowPriorityObject";
NSString* associatedKeyboardHeightAdjustmentHeightConstraintHighPriorityObjectKey = @"AssociatedKeyboardHeightAdjustmentHeightConstraintHighPriorityObject";


// -----------------------------------------------------------------------------
// Because the KeyboardHeightAdjustment category enhances NSObject, i.e. the
// root class of the object system, the KeyboardHeightAdjustment implementation
// should use long and unique method names to minimize the risk of creating a
// naming clash with the rest of the system.
//
// Also note that it is not possible for a category to have private property
// declarations in the same way that classes can have them. The reason is that
// classes can define a class extension in their implementation file, but for
// categories no such thing as a "category extension" exists in Objective-C.
// Because of this lack, properties cannot be synthesized by the compiler, so
// the KeyboardHeightAdjustment category has to explicitly implement getters
// and setters.
// -----------------------------------------------------------------------------


@implementation NSObject(KeyboardHeightAdjustment)

#pragma mark - Getters/setters that implement private properties for KeyboardHeightAdjustment

// -----------------------------------------------------------------------------
/// @brief Getter of property @e keyboardHeightAdjustmentViewToAdjustHeight.
// -----------------------------------------------------------------------------
- (UIView*) keyboardHeightAdjustmentViewToAdjustHeight
{
  return objc_getAssociatedObject(self, associatedKeyboardHeightAdjustmentViewToAdjustHeightObjectKey);
}

// -----------------------------------------------------------------------------
/// @brief Setter of property @e keyboardHeightAdjustmentViewToAdjustHeight.
/// @a viewToAdjustHeight is assigned with weak ownership.
// -----------------------------------------------------------------------------
- (void) setKeyboardHeightAdjustmentViewToAdjustHeight:(UIView*)viewToAdjustHeight
{
  objc_setAssociatedObject(self, associatedKeyboardHeightAdjustmentViewToAdjustHeightObjectKey, viewToAdjustHeight, OBJC_ASSOCIATION_ASSIGN);
}

// -----------------------------------------------------------------------------
/// @brief Getter of property @e keyboardHeightAdjustmentReferenceView.
// -----------------------------------------------------------------------------
- (UIView*) keyboardHeightAdjustmentReferenceView
{
  return objc_getAssociatedObject(self, associatedKeyboardHeightAdjustmentReferenceViewObjectKey);
}

// -----------------------------------------------------------------------------
/// @brief Setter of property @e keyboardHeightAdjustmentReferenceView.
/// @a referenceView is assigned with weak ownership.
// -----------------------------------------------------------------------------
- (void) setKeyboardHeightAdjustmentReferenceView:(UIView*)referenceView
{
  objc_setAssociatedObject(self, associatedKeyboardHeightAdjustmentReferenceViewObjectKey, referenceView, OBJC_ASSOCIATION_ASSIGN);
}

// -----------------------------------------------------------------------------
/// @brief Getter of property
/// @e keyboardHeightAdjustmentHeightConstraintLowPriority.
// -----------------------------------------------------------------------------
- (NSLayoutConstraint*) keyboardHeightAdjustmentHeightConstraintLowPriority
{
  return objc_getAssociatedObject(self, associatedKeyboardHeightAdjustmentHeightConstraintLowPriorityObjectKey);
}

// -----------------------------------------------------------------------------
/// @brief Setter of property
/// @e keyboardHeightAdjustmentHeightConstraintLowPriority.
/// @a heightConstraintLowPriority is assigned with strong ownership.
// -----------------------------------------------------------------------------
- (void) setKeyboardHeightAdjustmentHeightConstraintLowPriority:(NSLayoutConstraint*)heightConstraintLowPriority
{
  objc_setAssociatedObject(self, associatedKeyboardHeightAdjustmentHeightConstraintLowPriorityObjectKey, heightConstraintLowPriority, OBJC_ASSOCIATION_RETAIN);
}

// -----------------------------------------------------------------------------
/// @brief Getter of property
/// @e keyboardHeightAdjustmentHeightConstraintHighPriority.
// -----------------------------------------------------------------------------
- (NSLayoutConstraint*) keyboardHeightAdjustmentHeightConstraintHighPriority
{
  return objc_getAssociatedObject(self, associatedKeyboardHeightAdjustmentHeightConstraintHighPriorityObjectKey);
}

// -----------------------------------------------------------------------------
/// @brief Setter of property
/// @e keyboardHeightAdjustmentHeightConstraintHighPriority.
/// @a heightConstraintHighPriority is assigned with strong ownership.
// -----------------------------------------------------------------------------
- (void) setKeyboardHeightAdjustmentHeightConstraintHighPriority:(NSLayoutConstraint*)heightConstraintHighPriority
{
  objc_setAssociatedObject(self, associatedKeyboardHeightAdjustmentHeightConstraintHighPriorityObjectKey, heightConstraintHighPriority, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Public interface

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) beginObservingKeyboardWithViewToAdjustHeight:(UIView*)viewToAdjustHeight referenceView:(UIView*)referenceView
{
  self.keyboardHeightAdjustmentViewToAdjustHeight = viewToAdjustHeight;
  self.keyboardHeightAdjustmentReferenceView = referenceView;

  // Constraint that allows the view to extend its bottom down to the bottom of
  // the reference view. This constraint is permanently installed. It has a low
  // priority so that it can be overridden by the second, optional constraint
  // that is active only while the keyboard is displayed.
  // Note: Although the visual format string for this constraint is quite
  // simple ("V:[viewToAdjustHeight]-|"), we can't use the visual format API
  // because it does not allow us to set a priority for the constraint.
  self.keyboardHeightAdjustmentHeightConstraintLowPriority = [NSLayoutConstraint constraintWithItem:viewToAdjustHeight
                                                                                          attribute:NSLayoutAttributeBottom
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:referenceView.layoutMarginsGuide
                                                                                          attribute:NSLayoutAttributeBottom
                                                                                         multiplier:1.0f
                                                                                           constant:0];
  self.keyboardHeightAdjustmentHeightConstraintLowPriority.priority = UILayoutPriorityDefaultLow;
  self.keyboardHeightAdjustmentHeightConstraintLowPriority.active = YES;

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHeightAdjustmentKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHeightAdjustmentKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) endObservingKeyboardWithViewToAdjustHeight:(UIView*)viewToAdjustHeight referenceView:(UIView*)referenceView
{
  [self keyboardHeightAdjustmentRemoveHeightConstraintLowPriority];
  [self keyboardHeightAdjustmentRemoveHeightConstraintHighPriority];

  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

  self.keyboardHeightAdjustmentViewToAdjustHeight = nil;
  self.keyboardHeightAdjustmentReferenceView = nil;
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (bool) isObservingKeyboardWithViewToAdjustHeight:(UIView*)viewToAdjustHeight referenceView:(UIView*)referenceView
{
  return (self.keyboardHeightAdjustmentViewToAdjustHeight == viewToAdjustHeight &&
          self.keyboardHeightAdjustmentReferenceView == referenceView);
}

// -----------------------------------------------------------------------------
/// @brief Private helper that removes
/// self.keyboardHeightAdjustmentHeightConstraintLowPriority.
// -----------------------------------------------------------------------------
- (void) keyboardHeightAdjustmentRemoveHeightConstraintLowPriority
{
  self.keyboardHeightAdjustmentHeightConstraintLowPriority.active = NO;
  self.keyboardHeightAdjustmentHeightConstraintLowPriority = nil;
}

// -----------------------------------------------------------------------------
/// @brief Private helper that removes
/// self.keyboardHeightAdjustmentHeightConstraintHighPriority.
// -----------------------------------------------------------------------------
- (void) keyboardHeightAdjustmentRemoveHeightConstraintHighPriority
{
  [self.keyboardHeightAdjustmentReferenceView removeConstraint:self.keyboardHeightAdjustmentHeightConstraintHighPriority];
  self.keyboardHeightAdjustmentHeightConstraintHighPriority = nil;
}

#pragma mark - Adjust text view size when keyboard appears/disappears

// -----------------------------------------------------------------------------
/// @brief Responds to the keyboard being shown. Creates a high-priority
/// Auto Layout constraint that overrides the default constraint for defining
/// the height of @e self.keyboardHeightAdjustmentViewToAdjustHeight. The new
/// constraint forces @e self.keyboardHeightAdjustmentViewToAdjustHeight to
/// become smaller to make room for the keyboard.
///
/// @todo Try to simplify the implementation of this method, and of
/// keyboardWillHide:(), by using UIKeyboardLayoutGuide. This requires iOS 15
/// to be the deployment target.
// -----------------------------------------------------------------------------
- (void) keyboardHeightAdjustmentKeyboardWillShow:(NSNotification*)notification
{
  // keyboardWillShow is sometimes invoked multiple times without a
  // balancing keyboardWillHide in between
  if (self.keyboardHeightAdjustmentHeightConstraintHighPriority)
    [self keyboardHeightAdjustmentRemoveHeightConstraintHighPriority];

  NSDictionary* userInfo = [notification userInfo];

  // The frame we get from the notification is in screen coordinates where width
  // and height might be swapped depending on the current interface orientation.
  // We invoke convertRect:fromView: in order to translate the frame into our
  // view coordinates. This translation resolves all interface orientation
  // complexities for us.
  NSValue* keyboardFrameAsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGRect keyboardFrame = [keyboardFrameAsValue CGRectValue];
  keyboardFrame = [self.keyboardHeightAdjustmentReferenceView convertRect:keyboardFrame fromView:nil];
  CGFloat distanceFromViewBottom = keyboardFrame.size.height;

  // Constraint that allows the view to extend its bottom down to the top
  // of the keyboard.
  self.keyboardHeightAdjustmentHeightConstraintHighPriority = [NSLayoutConstraint constraintWithItem:self.keyboardHeightAdjustmentViewToAdjustHeight
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                           relatedBy:NSLayoutRelationEqual
                                                                                              toItem:self.keyboardHeightAdjustmentReferenceView.layoutMarginsGuide
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                          multiplier:1.0f
                                                                                            constant:0];
  // The constraint uses the negative of distanceFromViewBottom because we want
  // to express the **difference** of the bottom of the two views involved in
  // the constraint (self.keyboardHeightAdjustmentViewToAdjustHeight and
  // self.keyboardHeightAdjustmentReferenceView). In order for this to work, the
  // reference view must extend to the bottom of the screen to where the
  // keyboard pops up from.
  self.keyboardHeightAdjustmentHeightConstraintHighPriority.constant = -distanceFromViewBottom;
  // While this constraint is installed, it will take precedence over
  // self.keyboardHeightAdjustmentHeightConstraintLowPriority
  self.keyboardHeightAdjustmentHeightConstraintHighPriority.priority = UILayoutPriorityDefaultHigh;

  NSNumber* animationDurationAsNumber = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
  NSTimeInterval animationDuration = [animationDurationAsNumber doubleValue];
  [UIView animateWithDuration:animationDuration animations:^{
    [self.keyboardHeightAdjustmentReferenceView addConstraint:self.keyboardHeightAdjustmentHeightConstraintHighPriority];
    [self.keyboardHeightAdjustmentReferenceView layoutIfNeeded];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the keyboard being hidden. Removes the high-priority
/// Auto layout constraint created by
/// keyboardHeightAdjustmentKeyboardWillShow:().
/// @e self.keyboardHeightAdjustmentViewToAdjustHeight is allowed to become
/// bigger to take up the room freed by the disappearance of the keyboard.
// -----------------------------------------------------------------------------
- (void) keyboardHeightAdjustmentKeyboardWillHide:(NSNotification*)notification
{
  // keyboardWillHide is sometimes invoked multiple times although
  // keyboardWillShow has been invoked only once
  if (!self.keyboardHeightAdjustmentHeightConstraintHighPriority)
    return;

  NSDictionary* userInfo = [notification userInfo];
  NSNumber* animationDurationAsNumber = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
  NSTimeInterval animationDuration = [animationDurationAsNumber doubleValue];
  [UIView animateWithDuration:animationDuration animations:^{
    [self keyboardHeightAdjustmentRemoveHeightConstraintHighPriority];
    [self.keyboardHeightAdjustmentReferenceView layoutIfNeeded];
  }];
}

@end
