// -----------------------------------------------------------------------------
// Copyright 2015-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "LayoutManager.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LayoutManager.
// -----------------------------------------------------------------------------
@interface LayoutManager()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum UIType uiType;
@property(nonatomic, assign, readwrite) UIInterfaceOrientationMask supportedInterfaceOrientations;
//@}
@end


@implementation LayoutManager

// -----------------------------------------------------------------------------
/// @brief Shared instance of LayoutManager.
// -----------------------------------------------------------------------------
static LayoutManager* sharedManager = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared LayoutManager object.
// -----------------------------------------------------------------------------
+ (LayoutManager*) sharedManager
{
  @synchronized(self)
  {
    if (! sharedManager)
      sharedManager = [[LayoutManager alloc] init];
    return sharedManager;
  }
}

// -----------------------------------------------------------------------------
/// @brief Releases the shared LayoutManager object.
// -----------------------------------------------------------------------------
+ (void) releaseSharedManager
{
  @synchronized(self)
  {
    if (sharedManager)
    {
      [sharedManager release];
      sharedManager = nil;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Initializes a LayoutManager object.
///
/// @note This is the designated initializer of LayoutManager.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  // The order in which methods are called is important
  [self setupUIType];
  [self setupSupportedInterfaceOrientations];
  self.shouldAutorotate = true;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LayoutManager object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupUIType
{
  self.uiType = [LayoutManager uiTypeForUserInterfaceIdiom:[[UIDevice currentDevice] userInterfaceIdiom]
                                                screenSize:[UIScreen mainScreen].bounds.size];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupSupportedInterfaceOrientations
{
  self.supportedInterfaceOrientations = [LayoutManager supportedInterfaceOrientationsForUiType:self.uiType];
}

#pragma mark - UINavigationControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UINavigationControllerDelegate method.
///
/// Read the class documentation for details why this override exists.
// -----------------------------------------------------------------------------
- (UIInterfaceOrientationMask) navigationControllerSupportedInterfaceOrientations:(UINavigationController*)navigationController
{
  return self.supportedInterfaceOrientations;
}

#pragma mark - Public interface

// -----------------------------------------------------------------------------
/// @brief Returns the user interface type that matches the specified user
/// interface idiom @a userInterfaceIdiom and the specified screen size
/// @a screenSize.
///
/// This method is in LayoutManager's public interface so that the algorithm
/// for determining the user interface type can be reused during UI tests.
// -----------------------------------------------------------------------------
+ (enum UIType) uiTypeForUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
                                 screenSize:(CGSize)screenSize
{
  if (userInterfaceIdiom == UIUserInterfaceIdiomPhone)
  {
    // iPhone 5S and below: 320x480
    // iPhone 6: 375x667
    // iPhone 6 Plus: 414x736

    // The way how UIScreen reports its bounds has changed in iOS 8. By using
    // MIN() and MAX() we don't care...
    CGFloat smallerDimension = MIN(screenSize.width, screenSize.height);
    CGFloat largerDimension = MAX(screenSize.width, screenSize.height);

    // TODO Not a terribly sophisticated way how to find out whether we are on a
    // device that supports landscape orientations. In an ideal world we would
    // like to probe for the size class of the screen when the device is held
    // in landscape orientation - when the size class is compact we would know
    // that landscape is a no-go. Unfortunately there doesn't seem to exist
    // such a probing method. Although UIScreen has a UITraitCollection, we
    // can't use that because the values always reflect the current user
    // interface orientation :-(
    if (smallerDimension >= 400 && largerDimension >= 700)
      return UITypePhone;
    else
      return UITypePhonePortraitOnly;
  }
  else
  {
    return UITypePad;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the interface orientations supported by the specified user
/// interface type @a uiType.
///
/// This method is in LayoutManager's public interface so that the algorithm
/// for determining the interface orientations can be reused during UI tests.
// -----------------------------------------------------------------------------
+ (UIInterfaceOrientationMask) supportedInterfaceOrientationsForUiType:(enum UIType)uiType
{
  switch (uiType)
  {
    case UITypePhonePortraitOnly:
    {
      // Although here we indicate support for upside-down, iOS does not rotate
      // to upside-down on devices with a notch
      return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
    }
    case UITypePhone:
    case UITypePad:
    {
      return UIInterfaceOrientationMaskAll;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Unexpected UI type %d", uiType];
#ifndef LITTLEGO_UITESTS
      DDLogError(@"%@: %@", self, errorMessage);
#endif
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
