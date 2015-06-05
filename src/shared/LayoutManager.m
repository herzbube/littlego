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
#import "LayoutManager.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for EditTextController.
// -----------------------------------------------------------------------------
@interface LayoutManager()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum UIType uiType;
@property(nonatomic, assign, readwrite) NSUInteger supportedInterfaceOrientations;
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
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    // iPhone 5S and below: 320x480
    // iPhone 6: 375x667
    // iPhone 6 Plus: 414x736
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
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
      self.uiType = UITypePhone;
    else
      self.uiType = UITypePhonePortraitOnly;
  }
  else
  {
    self.uiType = UITypePad;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupSupportedInterfaceOrientations
{
  switch (self.uiType)
  {
    case UITypePhonePortraitOnly:
    {
      self.supportedInterfaceOrientations = (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
      break;
    }
    case UITypePhone:
    case UITypePad:
    {
      self.supportedInterfaceOrientations = UIInterfaceOrientationMaskAll;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Unexpected UI type %d", self.uiType];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
