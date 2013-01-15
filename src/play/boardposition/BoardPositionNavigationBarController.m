// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionNavigationBarController.h"
#import "../../command/boardposition/ChangeBoardPositionCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../ui/UiElementMetrics.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// BoardPositionNavigationBarController.
// -----------------------------------------------------------------------------
@interface BoardPositionNavigationBarController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Notification responders
//@{
- (void) computerPlayerThinkingStarts:(NSNotification*)notification;
- (void) computerPlayerThinkingStops:(NSNotification*)notification;
//@}
/// @name Action methods
//@{
- (void) rewindToStart:(id)sender;
- (void) rewind:(id)sender;
- (void) previousBoardPosition:(id)sender;
- (void) nextBoardPosition:(id)sender;
- (void) fastForward:(id)sender;
- (void) fastForwardToEnd:(id)sender;
//@}
/// @name Private helpers
//@{
- (void) setupNavigationBarButtons;
- (UIButton*) addButtonWithImageNamed:(NSString*)imageName afterButton:(UIButton*)previousButton withSelector:(SEL)selector;
- (void) adjustFrameForButton:(UIButton*)button withImage:(UIImage*)buttonImage withPreviousButton:(UIButton*)previousButton;
- (void) setImageInsetsForButton:(UIButton*)button withImage:(UIImage*)buttonImage;
- (void) applyBackgroundToButton:(UIButton*)button;
- (void) applyBorderToButton:(UIButton*)button;
- (void) applyShadowToButton:(UIButton*)button;
- (void) setupNotificationResponders;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) UIView* navigationBarView;
@property(nonatomic, assign) CGFloat horizontalDistanceOfButtonEdgeFromContainerEdge;
@property(nonatomic, assign) CGFloat verticalDistanceOfButtonEdgeFromContainerEdge;
@property(nonatomic, assign) CGFloat horizontalButtonImageEdgeInset;
@property(nonatomic, assign) CGFloat minimalVerticalButtonImageEdgeInset;
@property(nonatomic, assign) CGFloat shadowRadius;
@property(nonatomic, assign) CGFloat shadowOffset;
@property(nonatomic, assign) CGFloat buttonY;
@property(nonatomic, assign) CGFloat buttonHeight;
@property(nonatomic, retain) UIColor* buttonBackgroundGradientStartColor;
@property(nonatomic, retain) UIColor* buttonBackgroundGradientEndColor;
@property(nonatomic, assign) int numberOfBoardPositionsOnPage;
@property(nonatomic, assign, getter=isTappingEnabled) bool tappingEnabled;
//@}
@end


@implementation BoardPositionNavigationBarController

@synthesize navigationBarView;
@synthesize horizontalDistanceOfButtonEdgeFromContainerEdge;
@synthesize verticalDistanceOfButtonEdgeFromContainerEdge;
@synthesize horizontalButtonImageEdgeInset;
@synthesize minimalVerticalButtonImageEdgeInset;
@synthesize shadowRadius;
@synthesize shadowOffset;
@synthesize buttonY;
@synthesize buttonHeight;
@synthesize buttonBackgroundGradientStartColor;
@synthesize buttonBackgroundGradientEndColor;
@synthesize numberOfBoardPositionsOnPage;
@synthesize tappingEnabled;


// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionNavigationBarController object that
/// places its button into @a view.
///
/// @note This is the designated initializer of
/// BoardPositionNavigationBarController.
// -----------------------------------------------------------------------------
- (id) initWithNavigationBarView:(UIView*)view
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.navigationBarView = view;
  self.numberOfBoardPositionsOnPage = 10;
  self.tappingEnabled = true;

  [self setupButtonMetrics];
  [self setupNavigationBarButtons];
  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// BoardPositionNavigationBarController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.navigationBarView = nil;
  self.buttonBackgroundGradientStartColor = nil;
  self.buttonBackgroundGradientEndColor = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupButtonMetrics
{
  self.horizontalDistanceOfButtonEdgeFromContainerEdge = 0.0;
  self.verticalDistanceOfButtonEdgeFromContainerEdge = 0.0;
  self.horizontalButtonImageEdgeInset = 10.0;
  self.minimalVerticalButtonImageEdgeInset = 2.0;
  self.shadowRadius = 2.0;
  self.shadowOffset = 2.0;
  self.buttonY = self.verticalDistanceOfButtonEdgeFromContainerEdge;
  self.buttonHeight = (self.navigationBarView.frame.size.height
                       - (2 * self.verticalDistanceOfButtonEdgeFromContainerEdge)
                       - self.shadowRadius
                       - self.shadowOffset);
  self.buttonBackgroundGradientStartColor = [UIColor colorFromHexString:@"fcfcfc"];
  self.buttonBackgroundGradientEndColor = [UIColor colorFromHexString:@"a7aab2"];

}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNavigationBarButtons
{
  UIButton* button = nil;
  button = [self addButtonWithImageNamed:rewindToStartButtonIconResource afterButton:button withSelector:@selector(rewindToStart:)];
  button = [self addButtonWithImageNamed:rewindButtonIconResource afterButton:button withSelector:@selector(rewind:)];
  button = [self addButtonWithImageNamed:backButtonIconResource afterButton:button withSelector:@selector(previousBoardPosition:)];
  button = [self addButtonWithImageNamed:playButtonIconResource afterButton:button withSelector:@selector(nextBoardPosition:)];
  button = [self addButtonWithImageNamed:fastForwardButtonIconResource afterButton:button withSelector:@selector(fastForward:)];
  button = [self addButtonWithImageNamed:forwardToEndButtonIconResource afterButton:button withSelector:@selector(fastForwardToEnd:)];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupNavigationBarButtons().
// -----------------------------------------------------------------------------
- (UIButton*) addButtonWithImageNamed:(NSString*)imageName afterButton:(UIButton*)previousButton withSelector:(SEL)selector
{
  UIImage* buttonImage = [UIImage imageNamed:imageName];
  buttonImage = [UIImage imageByApplyingUIBarButtonItemStyling:buttonImage];

  UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setImage:buttonImage forState:UIControlStateNormal];
  [self adjustFrameForButton:button withImage:buttonImage withPreviousButton:(UIButton*)previousButton];
  [self setImageInsetsForButton:button withImage:buttonImage];
  [self applyBackgroundToButton:button];
  [self applyBorderToButton:button];
  [self applyShadowToButton:button];

  [self.navigationBarView addSubview:button];
  [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

  return button;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for addButtonWithImageNamed:afterButton:withSelector:().
// -----------------------------------------------------------------------------
- (void) adjustFrameForButton:(UIButton*)button withImage:(UIImage*)buttonImage withPreviousButton:(UIButton*)previousButton
{
  CGFloat buttonX;
  if (previousButton)
    buttonX = CGRectGetMaxX(previousButton.frame) + [UiElementMetrics spacingHorizontal];
  else
    buttonX = self.horizontalDistanceOfButtonEdgeFromContainerEdge;
  CGFloat buttonWidth = buttonImage.size.width + 2 * self.horizontalButtonImageEdgeInset;
  button.frame = CGRectMake(buttonX, self.buttonY, buttonWidth, self.buttonHeight);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for addButtonWithImageNamed:afterButton:withSelector:().
// -----------------------------------------------------------------------------
- (void) setImageInsetsForButton:(UIButton*)button withImage:(UIImage*)buttonImage
{
  CGRect buttonFrame = button.frame;
  CGFloat verticalButtonImageEdgeInset = ((buttonFrame.size.height - buttonImage.size.height) / 2);
  button.imageEdgeInsets = UIEdgeInsetsMake(verticalButtonImageEdgeInset,
                                            self.horizontalButtonImageEdgeInset,
                                            verticalButtonImageEdgeInset,
                                            self.horizontalButtonImageEdgeInset);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for addButtonWithImageNamed:afterButton:withSelector:().
// -----------------------------------------------------------------------------
- (void) applyBackgroundToButton:(UIButton*)button
{
  CGSize backgroundPatternSize = button.frame.size;
  UIImage* backgroundPattern = [UIImage gradientImageWithSize:backgroundPatternSize
                                                   startColor:self.buttonBackgroundGradientStartColor
                                                     endColor:self.buttonBackgroundGradientEndColor];
  button.layer.contents = (id)backgroundPattern.CGImage;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for addButtonWithImageNamed:afterButton:withSelector:().
// -----------------------------------------------------------------------------
- (void) applyBorderToButton:(UIButton*)button
{
  button.layer.borderColor = [UIColor lightGrayColor].CGColor;
  button.layer.borderWidth = 1.0f;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for addButtonWithImageNamed:afterButton:withSelector:().
// -----------------------------------------------------------------------------
- (void) applyShadowToButton:(UIButton*)button
{
  button.layer.shadowColor = [UIColor blackColor].CGColor;
  button.layer.shadowOpacity = 0.8f;
  button.layer.shadowRadius = self.shadowRadius;
  button.layer.shadowOffset = CGSizeMake(self.shadowOffset, self.shadowOffset);
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(computerPlayerThinkingStarts:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingStops:) name:computerPlayerThinkingStops object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStarts:(NSNotification*)notification
{
  self.tappingEnabled = false;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStops notification.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingStops:(NSNotification*)notification
{
  self.tappingEnabled = true;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "rewind to start" button.
// -----------------------------------------------------------------------------
- (void) rewindToStart:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithFirstBoardPosition] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "rewind" button.
// -----------------------------------------------------------------------------
- (void) rewind:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithOffset:(- self.numberOfBoardPositionsOnPage)] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "previous board position" button.
// -----------------------------------------------------------------------------
- (void) previousBoardPosition:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithOffset:-1] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "next board position" button.
// -----------------------------------------------------------------------------
- (void) nextBoardPosition:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithOffset:1] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "fast forward" button.
// -----------------------------------------------------------------------------
- (void) fastForward:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithOffset:self.numberOfBoardPositionsOnPage] submit];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the user tapping the "fast forward to end" button.
// -----------------------------------------------------------------------------
- (void) fastForwardToEnd:(id)sender
{
  if (self.isTappingEnabled)
    [[[ChangeBoardPositionCommand alloc] initWithLastBoardPosition] submit];
}

@end
