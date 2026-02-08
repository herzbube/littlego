// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "InvalidTimeDataViewController.h"
#import "InvalidTimeDataDetailViewController.h"
#import "InvalidTimeDataView.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoNode.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// InvalidTimeDataViewController.
// -----------------------------------------------------------------------------
@interface InvalidTimeDataViewController()
@property(nonatomic, retain) InvalidTimeDataView* invalidTimeDataView;
@property(nonatomic, retain) UIButton* infoButton;
@property(nonatomic, assign) bool invalidTimeDataNeedsUpdate;
@property(nonatomic, assign) enum UIType uiType;
@property(nonatomic, assign) int iconHeight;
@property(nonatomic, assign) bool presentInfoTextInPopover;
@end


@implementation InvalidTimeDataViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an InvalidTimeDataViewController object.
///
/// @note This is the designated initializer of InvalidTimeDataViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.invalidTimeDataView = nil;
  self.infoButton = nil;
  self.invalidTimeDataNeedsUpdate = false;

  self.uiType = [LayoutManager sharedManager].uiType;
  self.iconHeight = [UiElementMetrics iconHeightForUiType:self.uiType];
  self.presentInfoTextInPopover = (self.uiType == UITypePad);

  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this InvalidTimeDataViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  
  self.invalidTimeDataView = nil;
  self.infoButton = nil;

  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(currentBoardPositionDidChange:) name:currentBoardPositionDidChange object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupViewHierarchy];
  [self configureView];
  [self setupAutoLayoutConstraints];

  // This controller can be instantiated in response to goGameDidCreate. In
  // that case it will miss goGameDidCreate, so to make sure the view is
  // properly initialized we have to trigger an update here.
  self.invalidTimeDataNeedsUpdate = true;
  [self updateInvalidTimeData];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
    [self updateColors];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Sets up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.invalidTimeDataView = [[[InvalidTimeDataView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.invalidTimeDataView];

  self.infoButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.view addSubview:self.infoButton];
}

// -----------------------------------------------------------------------------
/// @brief Configures the view and its elements.
// -----------------------------------------------------------------------------
- (void) configureView
{
  [self.infoButton setImage:[[UIImage imageNamed:uiAreaAboutIconResource] imageByScalingToHeight:self.iconHeight]
                   forState:UIControlStateNormal];

  [self.infoButton addTarget:self
                      action:@selector(showInfo:)
            forControlEvents:UIControlEventTouchUpInside];

  [self updateColors];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.invalidTimeDataView.translatesAutoresizingMaskIntoConstraints = NO;
  self.infoButton.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"invalidTimeDataView"] = self.invalidTimeDataView;
  viewsDictionary[@"infoButton"] = self.infoButton;

  [visualFormats addObject:@"H:|-[invalidTimeDataView]-[infoButton]-|"];
  [visualFormats addObject:@"V:|-[invalidTimeDataView]-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[infoButton(==%d)]", self.iconHeight]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[infoButton(==%d)]", self.iconHeight]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];

  [AutoLayoutUtility centerSubview:self.infoButton
                       inSuperview:self.view
                            onAxis:UILayoutConstraintAxisVertical];
}

#pragma mark - User interface style handling (light/dark mode)

// -----------------------------------------------------------------------------
/// @brief Updates all kinds of colors to match the current
/// UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateColors
{
  UITraitCollection* traitCollection = self.traitCollection;
  [UiUtilities applyTransparentStyleToView:self.view traitCollection:traitCollection];
  [UiUtilities applyTintColorToButton:self.infoButton traitCollection:traitCollection];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  self.invalidTimeDataNeedsUpdate = true;
  [self updateInvalidTimeData];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #currentBoardPositionDidChange notification.
// -----------------------------------------------------------------------------
- (void) currentBoardPositionDidChange:(NSNotification*)notification
{
  self.invalidTimeDataNeedsUpdate = true;
  [self updateInvalidTimeData];
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Updates the InvalidTimeDataView to display the currently selected
/// node's information about time data invalidity.
// -----------------------------------------------------------------------------
- (void) updateInvalidTimeData
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(updateInvalidTimeData) withObject:nil waitUntilDone:YES];
    return;
  }

  if (! self.invalidTimeDataNeedsUpdate)
    return;
  self.invalidTimeDataNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  GoNode* currentNode = game.boardPosition.currentNode;

  self.invalidTimeDataView.isTimeDataValid = currentNode.isTimeDataValid;
  self.invalidTimeDataView.timeDataInvalidReason = currentNode.timeDataInvalidReason;
}

#pragma mark - Button handlers

// -----------------------------------------------------------------------------
/// @brief Displays a pop up that shows detailed information about why the time
/// data in the currently selected node is invalid.
// -----------------------------------------------------------------------------
- (void) showInfo:(id)sender
{
  GoGame* game = [GoGame sharedGame];
  GoNode* currentNode = game.boardPosition.currentNode;

  InvalidTimeDataDetailViewController* invalidTimeDataDetailViewController = [[[InvalidTimeDataDetailViewController alloc] initWithGame:game
                                                                                                                            currentNode:currentNode] autorelease];
  [self presentNavigationControllerWithRootViewController:invalidTimeDataDetailViewController
                                        usingPopoverStyle:self.presentInfoTextInPopover
                                        popoverSourceView:sender
                                     popoverBarButtonItem:nil];
}

@end
