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
#import "AnnotationViewControllerPhonePortraitOnly.h"
#import "../model/BoardViewModel.h"
#import "../../command/node/ChangeAnnotationDataCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeAnnotation.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


enum ItemPickerContext
{
  BoardPositionValuationItemPickerContext,
  MoveValuationItemPickerContext,
  BoardPositionHotspotDesignationItemPickerContext,
};

static const int spacerTopTag = 1;
static const int spacerBottomTag = 2;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// AnnotationViewControllerPhonePortraitOnly.
// -----------------------------------------------------------------------------
@interface AnnotationViewControllerPhonePortraitOnly()
@property(nonatomic, assign) bool presentViewControllersInPopover;
@property(nonatomic, assign) bool contentNeedsUpdate;
@property(nonatomic, assign) bool buttonStatesNeedsUpdate;
@property(nonatomic, assign) int labelFontSize;
@property(nonatomic, assign) int iconHeight;
@property(nonatomic, assign) int mainViewMargin;
@property(nonatomic, assign) int buttonVerticalSpacing;
@property(nonatomic, retain) PageViewController* customPageViewController;
@property(nonatomic, retain) UIViewController* valuationViewController;
@property(nonatomic, retain) UIStackView* valuationViewStackView;
@property(nonatomic, retain) UILabel* positionValuationLabel;
@property(nonatomic, retain) UIButton* positionValuationButton;
@property(nonatomic, retain) UILabel* moveValuationLabel;
@property(nonatomic, retain) UIButton* moveValuationButton;
@property(nonatomic, retain) UILabel* hotspotLabel;
@property(nonatomic, retain) UIButton* hotspotButton;
@property(nonatomic, retain) UILabel* estimatedScoreLabel;
@property(nonatomic, retain) UIButton* estimatedScoreButton;
@property(nonatomic, retain) UIViewController* descriptionViewController;
@property(nonatomic, retain) UIView* descriptionLabelContainerView;
@property(nonatomic, retain) UIScrollView* descriptionScrollView;
@property(nonatomic, retain) UIView* descriptionContentView;
@property(nonatomic, retain) UILabel* shortDescriptionLabel;
@property(nonatomic, retain) UILabel* longDescriptionLabel;
@property(nonatomic, retain) UIView* descriptionSpacerView;
@property(nonatomic, retain) UIView* descriptionButtonContainerView;
@property(nonatomic, retain) UIButton* descriptionEditButton;
@property(nonatomic, retain) UIButton* descriptionRemoveButton;
@property(nonatomic, retain) UIView* descriptionButtonSpacerView;
@property(nonatomic, retain) NSLayoutConstraint* descriptionLabelsVerticalSpacingConstraint;
@end


@implementation AnnotationViewControllerPhonePortraitOnly

// -----------------------------------------------------------------------------
/// @brief Initializes an AnnotationViewControllerPhonePortraitOnly object.
/// It adjusts the view layout to the specified @a uiType.
///
/// @note This is the designated initializer of
/// AnnotationViewControllerPhonePortraitOnly.
// -----------------------------------------------------------------------------
- (id) initWithUiType:(enum UIType)uiType
{
  // Call designated initializer of superclass (AnnotationViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.contentNeedsUpdate = false;
  self.buttonStatesNeedsUpdate = false;

  // Sizes were experimentally determined to not cause vertical scrolling or
  // any kind of layout shifts on an iPhone 5S, even when a three-digit score
  // is displayed. On larger iPhones or iPads there is more space available, so
  // a slightly larger font size can be used for UITypePhone or UITypePad. The
  // font size must not be too large, though, otherwise the layout no longer
  // looks good (esp. valuation button labels must not gain too much weight
  // when compared to valuation button icons).
  switch (uiType)
  {
    case UITypePhonePortraitOnly:
      self.presentViewControllersInPopover = false;
      self.labelFontSize = 10;
      break;
    case UITypePhone:
      self.presentViewControllersInPopover = false;
      self.labelFontSize = 11;
      break;
    case UITypePad:
      self.presentViewControllersInPopover = true;
      self.labelFontSize = 12;
      break;
    default:
      [ExceptionUtility throwInvalidUIType:uiType];
      break;
  }
  self.iconHeight = 22;
  // Margins and spacings were chosen experimentally to look good but not waste
  // too much vertical space (important for smaller iPhones were space is at a
  // premium).
  self.mainViewMargin = 5;
  self.buttonVerticalSpacing = 5;

  [self releaseObjects];
  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// AnnotationViewControllerPhonePortraitOnly object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  [self releaseObjects];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.customPageViewController.delegate = nil;

  self.customPageViewController = nil;
  self.valuationViewController = nil;
  self.valuationViewStackView = nil;
  self.positionValuationLabel = nil;
  self.positionValuationButton = nil;
  self.moveValuationLabel = nil;
  self.moveValuationButton = nil;
  self.hotspotLabel = nil;
  self.hotspotButton = nil;
  self.estimatedScoreLabel = nil;
  self.estimatedScoreButton = nil;
  self.descriptionViewController = nil;
  self.descriptionLabelContainerView = nil;
  self.descriptionScrollView = nil;
  self.descriptionContentView = nil;
  self.shortDescriptionLabel = nil;
  self.longDescriptionLabel = nil;
  self.descriptionSpacerView = nil;
  self.descriptionButtonContainerView = nil;
  self.descriptionEditButton = nil;
  self.descriptionRemoveButton = nil;
  self.descriptionButtonSpacerView = nil;
  self.descriptionLabelsVerticalSpacingConstraint = nil;
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillStart:) name:boardViewPanningGestureWillStart object:nil];
  [center addObserver:self selector:@selector(boardViewPanningGestureWillEnd:) name:boardViewPanningGestureWillEnd object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationWillBegin:) name:boardViewAnimationWillBegin object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationDidEnd:) name:boardViewAnimationDidEnd object:nil];
  [center addObserver:self selector:@selector(nodeAnnotationDataDidChange:) name:nodeAnnotationDataDidChange object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  [center addObserver:self selector:@selector(statusBarOrientationWillChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  if (boardPosition)
    [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  if (boardPosition)
    [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.valuationViewController = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];
  self.descriptionViewController = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  UiSettingsModel* uiSettingsModel = appDelegate.uiSettingsModel;
  UIViewController* initialViewController;
  if (uiSettingsModel.visibleAnnotationViewPage == ValuationAnnotationViewPage)
    initialViewController = self.valuationViewController;
  else
    initialViewController = self.descriptionViewController;

  NSArray* pageViewControllers = @[self.valuationViewController, self.descriptionViewController];
  self.customPageViewController = [PageViewController pageViewControllerWithViewControllers:pageViewControllers
                                                                      initialViewController:initialViewController];

  self.customPageViewController.delegate = self;
  self.customPageViewController.pageControlPageIndicatorTintColor = [UIColor blackColor];
  self.customPageViewController.pageControlCurrentPageIndicatorTintColor = [UIColor whiteColor];

  UIInterfaceOrientation interfaceOrientation = [UiElementMetrics interfaceOrientation];
  bool orientationIsPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (orientationIsPortraitOrientation)
  {
    // In portrait orientation there is not a lot of vertical space, so we have
    // to constrain the page control's default intrinsic size to give the pages
    // more room (specifically, the buttons and their labels on the valuation
    // page).
    self.customPageViewController.pageControlHeight = 8;
  }
  else
  {
    // In landscape orientation there is not a lot of horizontal space. Since
    // iOS 14 if UIPageControl does not get enough horizontal space it hides
    // the page indicator. We don't do anything to counteract this behaviour
    // here, because we assume that the annotation view will always be laid out
    // sufficiently wide.
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setCustomPageViewController:(PageViewController*)customPageViewController
{
  if (_customPageViewController == customPageViewController)
    return;
  if (_customPageViewController)
  {
    [_customPageViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_customPageViewController removeFromParentViewController];
    [_customPageViewController release];
    _customPageViewController = nil;
  }
  if (customPageViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:customPageViewController];
    [customPageViewController didMoveToParentViewController:self];
    [customPageViewController retain];
    _customPageViewController = customPageViewController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupChildControllers];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];

  self.contentNeedsUpdate = true;
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

#pragma mark - View hierarchy setup

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.customPageViewController.view];

  [self setupValuationView:self.valuationViewController.view];
  [self setupDescriptionView:self.descriptionViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchy.
// -----------------------------------------------------------------------------
- (void) setupValuationView:(UIView*)superview
{
  self.valuationViewStackView = [self createStackViewInSuperView:superview];
  UIInterfaceOrientation interfaceOrientation = [UiElementMetrics interfaceOrientation];
  bool orientationIsPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (orientationIsPortraitOrientation)
  {
    self.valuationViewStackView.axis = UILayoutConstraintAxisHorizontal;
    self.valuationViewStackView.distribution = UIStackViewDistributionFillEqually;
  }
  else
  {
    self.valuationViewStackView.axis = UILayoutConstraintAxisVertical;
    self.valuationViewStackView.distribution = UIStackViewDistributionFillEqually;
  }

  self.valuationViewStackView.alignment = UIStackViewAlignmentCenter;

  UIView* positionValuationItem = [self createStackViewItem:self.valuationViewStackView];
  self.positionValuationLabel = [self createTitleLabelInSuperview:positionValuationItem withTitleText:@"Position"];
  self.positionValuationButton = [self createButtonInSuperView:positionValuationItem selector:@selector(editPositionValuation:)];

  UIView* moveValuationItem = [self createStackViewItem:self.valuationViewStackView];
  self.moveValuationLabel = [self createTitleLabelInSuperview:moveValuationItem withTitleText:@"Move"];
  self.moveValuationButton = [self createButtonInSuperView:moveValuationItem selector:@selector(editMoveValuation:)];

  UIView* hotspotItem = [self createStackViewItem:self.valuationViewStackView];
  self.hotspotLabel = [self createTitleLabelInSuperview:hotspotItem withTitleText:@"Hotspot"];
  self.hotspotButton = [self createButtonInSuperView:hotspotItem selector:@selector(editHotspotDesignation:)];

  UIView* estimatedScoreItem = [self createStackViewItem:self.valuationViewStackView];
  self.estimatedScoreLabel = [self createTitleLabelInSuperview:estimatedScoreItem withTitleText:@"Score"];
  self.estimatedScoreButton = [self createButtonInSuperView:estimatedScoreItem selector:@selector(editEstimatedScore:)];

  UIFont* buttonTitleLabelFont = [UIFont systemFontOfSize:self.labelFontSize];
  self.estimatedScoreButton.titleLabel.font = buttonTitleLabelFont;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchy.
// -----------------------------------------------------------------------------
- (void) setupDescriptionView:(UIView*)superview
{
  self.descriptionLabelContainerView = [self createViewInSuperView:superview];

  self.descriptionScrollView = [self createScrollViewInSuperView:self.descriptionLabelContainerView];
  self.descriptionContentView = [self createViewInSuperView:self.descriptionScrollView];

  self.shortDescriptionLabel = [self createLabelInSuperView:self.descriptionContentView];
  self.shortDescriptionLabel.numberOfLines = 0;
  self.longDescriptionLabel = [self createLabelInSuperView:self.descriptionContentView];
  self.longDescriptionLabel.numberOfLines = 0;

  self.descriptionSpacerView = [self createViewInSuperView:superview];

  self.descriptionButtonContainerView = [self createViewInSuperView:superview];
  self.descriptionEditButton = [self createButtonInSuperView:self.descriptionButtonContainerView selector:@selector(editDescription:)];
  self.descriptionButtonSpacerView = [self createViewInSuperView:self.descriptionButtonContainerView];

  [self.descriptionEditButton setImage:[[UIImage editIcon] imageByScalingToHeight:self.iconHeight]
                              forState:UIControlStateNormal];

  self.descriptionRemoveButton = [self createButtonInSuperView:self.descriptionButtonContainerView selector:@selector(removeDescription:)];
  [self.descriptionRemoveButton setImage:[[UIImage trashcanIcon] imageByScalingToHeight:self.iconHeight]
                                forState:UIControlStateNormal];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupValuationView and setupDescriptionView.
// -----------------------------------------------------------------------------
- (UIView*) createViewInSuperView:(UIView*)superview
{
  UIView* view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [superview addSubview:view];
  return view;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupValuationView and setupDescriptionView.
// -----------------------------------------------------------------------------
- (UIScrollView*) createScrollViewInSuperView:(UIView*)superview
{
  UIScrollView* scrollView = [[[UIScrollView alloc] initWithFrame:CGRectZero] autorelease];
  [superview addSubview:scrollView];
  return scrollView;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupValuationView.
// -----------------------------------------------------------------------------
- (UIStackView*) createStackViewInSuperView:(UIView*)superview
{
  UIStackView* stackView = [[[UIStackView alloc] initWithFrame:CGRectZero] autorelease];
  [superview addSubview:stackView];
  return stackView;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupValuationView.
// -----------------------------------------------------------------------------
- (UIView*) createStackViewItem:(UIStackView*)stackView
{
  UIView* stackViewItem = [self createViewInSuperView:stackView];
  [stackView addArrangedSubview:stackViewItem];

  // See implementation of setupAutoLayoutConstraintsForLabel:button: for
  // details about the meaning of spacerTop/spacerBottom.
  UIView* spacerTop = [self createViewInSuperView:stackViewItem];
  spacerTop.tag = spacerTopTag;
  UIView* spacerBottom = [self createViewInSuperView:stackViewItem];
  spacerBottom.tag = spacerBottomTag;

  return stackViewItem;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupValuationView.
// -----------------------------------------------------------------------------
- (UILabel*) createTitleLabelInSuperview:(UIView*)superview withTitleText:(NSString*)titleText
{
  UILabel* label = [self createLabelInSuperView:superview];
  label.text = titleText;
  label.textAlignment = NSTextAlignmentCenter;

  return label;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for createTitleLabelInStackView and
/// setupDescriptionView.
// -----------------------------------------------------------------------------
- (UILabel*) createLabelInSuperView:(UIView*)superview
{
  UILabel* label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  label.font = [UIFont systemFontOfSize:self.labelFontSize];
  [superview addSubview:label];
  return label;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupValuationView and setupDescriptionView.
// -----------------------------------------------------------------------------
- (UIButton*) createButtonInSuperView:(UIView*)superview selector:(SEL)selector
{
  UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
  [superview addSubview:button];
  button.tintColor = [UIColor blackColor];
  [button addTarget:self
             action:selector
   forControlEvents:UIControlEventTouchUpInside];
  return button;
}

#pragma mark - Auto Layout constraints

// -----------------------------------------------------------------------------
/// @brief Main method for setting up Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.customPageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  viewsDictionary[@"pageViewControllerView"] = self.customPageViewController.view;
  [visualFormats addObject:[NSString stringWithFormat:@"H:|-%d-[pageViewControllerView]-%d-|", self.mainViewMargin, self.mainViewMargin]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-%d-[pageViewControllerView]-%d-|", self.mainViewMargin, self.mainViewMargin]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.customPageViewController.view.superview];

  [self setupAutoLayoutConstraintsValuationView];
  [self setupAutoLayoutConstraintsDescriptionView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsValuationView
{
  self.valuationViewStackView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.valuationViewStackView.superview withSubview:self.valuationViewStackView];

  [self setupAutoLayoutConstraintsForLabel:self.positionValuationLabel button:self.positionValuationButton];
  [self setupAutoLayoutConstraintsForLabel:self.moveValuationLabel button:self.moveValuationButton];
  [self setupAutoLayoutConstraintsForLabel:self.hotspotLabel button:self.hotspotButton];
  [self setupAutoLayoutConstraintsForLabel:self.estimatedScoreLabel button:self.estimatedScoreButton];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsValuationView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsForLabel:(UILabel*)label button:(UIButton*)button
{
  // The two spacer views exist to solve a problem when the stack view's axis is
  // UILayoutConstraintAxisVertical (i.e. interface orientation Landscape) and
  // the distribution policy UIStackViewDistributionFillEqually is used. Without
  // the spacer views we would have to vertically layout label/button like this:
  //   V:|-0-[label]-%d-[button]-0-|
  // This would cause the button to expand vertically to fill the space assigned
  // to the superview by the stack view, which would then cause the button icon
  // to be rendered in the wrong position. Instead we let two spacer views soak
  // up the excess vertical space.
  UIView* spacerTop = [label.superview viewWithTag:spacerTopTag];
  UIView* spacerBottom = [label.superview viewWithTag:spacerBottomTag];

  spacerTop.translatesAutoresizingMaskIntoConstraints = NO;
  label.translatesAutoresizingMaskIntoConstraints = NO;
  button.translatesAutoresizingMaskIntoConstraints = NO;
  spacerBottom.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];
  viewsDictionary[@"spacerTop"] = spacerTop;
  viewsDictionary[@"label"] = label;
  viewsDictionary[@"button"] = button;
  viewsDictionary[@"spacerBottom"] = spacerBottom;
  [visualFormats addObject:@"H:|-0-[spacerTop]-0-|"];
  [visualFormats addObject:@"H:|-0-[label]-0-|"];
  [visualFormats addObject:@"H:|-0-[button]-0-|"];
  [visualFormats addObject:@"H:|-0-[spacerBottom]-0-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-0-[spacerTop]-0-[label]-%d-[button]-0-[spacerBottom]-0-|", self.buttonVerticalSpacing]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:label.superview];

  // Make sure that the two spacer views get the same height - this makes sure
  // that label and button are properly vertically centered in all stack view
  // items. Without this the label and button are not properly vertically
  // centered in the top and bottom stack view items.
  [AutoLayoutUtility alignFirstView:spacerBottom withSecondView:spacerTop onAttribute:NSLayoutAttributeHeight constraintHolder:label.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsDescriptionView
{
  UIInterfaceOrientation interfaceOrientation = [UiElementMetrics interfaceOrientation];
  bool orientationIsPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);

  self.descriptionLabelContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.shortDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.longDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionSpacerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionButtonContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionEditButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionRemoveButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionButtonSpacerView.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  viewsDictionary[@"descriptionLabelContainerView"] = self.descriptionLabelContainerView;
  viewsDictionary[@"descriptionSpacerView"] = self.descriptionSpacerView;
  viewsDictionary[@"descriptionButtonContainerView"] = self.descriptionButtonContainerView;
  if (orientationIsPortraitOrientation)
  {
    [visualFormats addObject:@"H:|-0-[descriptionLabelContainerView]-0-[descriptionSpacerView]-[descriptionButtonContainerView]-0-|"];
    [visualFormats addObject:@"V:|-0-[descriptionLabelContainerView]-0-|"];
    [visualFormats addObject:@"V:|-0-[descriptionSpacerView]-0-|"];
    [visualFormats addObject:@"V:|-0-[descriptionButtonContainerView]-0-|"];
  }
  else
  {
    [visualFormats addObject:@"H:|-0-[descriptionButtonContainerView]-0-|"];
    [visualFormats addObject:@"H:|-0-[descriptionSpacerView]-0-|"];
    [visualFormats addObject:@"H:|-0-[descriptionLabelContainerView]-0-|"];
    [visualFormats addObject:@"V:|-0-[descriptionButtonContainerView]-0-[descriptionSpacerView]-[descriptionLabelContainerView]-0-|"];
  }
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.descriptionLabelContainerView.superview];

  [self setupAutoLayoutConstraintsScrollView:self.descriptionScrollView
                              andContentView:self.descriptionContentView];

  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  viewsDictionary[@"shortDescriptionLabel"] = self.shortDescriptionLabel;
  viewsDictionary[@"longDescriptionLabel"] = self.longDescriptionLabel;
  [visualFormats addObject:@"H:|-0-[shortDescriptionLabel]-0-|"];
  [visualFormats addObject:@"H:|-0-[longDescriptionLabel]-0-|"];
  [visualFormats addObject:@"V:|-0-[shortDescriptionLabel]"];
  [visualFormats addObject:@"V:[longDescriptionLabel]-0-|"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.shortDescriptionLabel.superview];

  // The spacing between the two labels needs to be set to 0 dynamically
  // when only longDescriptionLabel has a text
  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  viewsDictionary[@"shortDescriptionLabel"] = self.shortDescriptionLabel;
  viewsDictionary[@"longDescriptionLabel"] = self.longDescriptionLabel;
  [visualFormats addObject:@"V:[shortDescriptionLabel]-0-[longDescriptionLabel]"];
  NSArray* constraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.shortDescriptionLabel.superview];
  self.descriptionLabelsVerticalSpacingConstraint = constraints.firstObject;

  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  viewsDictionary[@"descriptionEditButton"] = self.descriptionEditButton;
  viewsDictionary[@"descriptionRemoveButton"] = self.descriptionRemoveButton;
  viewsDictionary[@"descriptionButtonSpacerView"] = self.descriptionButtonSpacerView;
  if (orientationIsPortraitOrientation)
  {
    [visualFormats addObject:@"H:|-0-[descriptionEditButton]-0-|"];
    [visualFormats addObject:@"H:|-0-[descriptionRemoveButton]-0-|"];
    [visualFormats addObject:@"H:|-0-[descriptionButtonSpacerView]-0-|"];
    [visualFormats addObject:@"V:|-0-[descriptionEditButton]-[descriptionRemoveButton]-0-[descriptionButtonSpacerView]-0-|"];
  }
  else
  {
    [visualFormats addObject:@"H:|-0-[descriptionEditButton]-[descriptionRemoveButton]-0-[descriptionButtonSpacerView]-0-|"];
    [visualFormats addObject:@"V:|-0-[descriptionEditButton]-0-|"];
    [visualFormats addObject:@"V:|-0-[descriptionRemoveButton]-0-|"];
    [visualFormats addObject:@"V:|-0-[descriptionButtonSpacerView]-0-|"];
  }
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.descriptionEditButton.superview];

  // The button must resist compression more than the labels in
  // self.descriptionLabelContainerView, otherwise a long label text can cause
  // the button to be squashed (observed in layouts slightly different than the
  // current one). More important, the increased compression resistance also
  // fixes a weird problem with the current layout, where shortDescriptionLabel
  // sometimes truncates its text when the text becomes too long (e.g. longer
  // than two lines, but shorter texts have also been seen truncated). The
  // problem occurs only when both labels have numberOfLines != 1, so a
  // workaround was to set numberOfLines to 1 for that label that has no text.
  // As soon as both labels have text, though, the workaround is no longer
  // possible. In any case, invoking setContentCompressionResistancePriority
  // with the highest value completely fixes the truncation problem.
  if (orientationIsPortraitOrientation)
    [self.descriptionEditButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraintsValuationView and
/// setupAutoLayoutConstraintsDescriptionView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsScrollView:(UIScrollView*)scrollView
                               andContentView:(UIView*)contentView
{
  scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:scrollView.superview withSubview:scrollView];

  // This allows the scroll view to get its content size from its content view
  // via Auto Layout. It's important that the constraints attach the content
  // view edges to the scroll view edges. fillSuperview:withSubview does this
  // for us.
  contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:contentView.superview withSubview:contentView];

  // Prevent horizontal scrolling - content should extend vertically but not
  // horizontally. Specifically this is important for the short and long
  // description labels which can contain potentially very long texts. For these
  // we have set numberOfLines to 0 so that they can expand vertically.
  [NSLayoutConstraint constraintWithItem:contentView
                               attribute:NSLayoutAttributeWidth
                               relatedBy:NSLayoutRelationEqual
                                  toItem:scrollView
                               attribute:NSLayoutAttributeWidth
                              multiplier:1.0f
                                constant:0.0f].active = YES;
}

#pragma mark - PageViewControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief PageViewControllerDelegate method.
// -----------------------------------------------------------------------------
- (void) pageViewController:(PageViewController*)pageViewController
     didHideViewController:(UIViewController*)currentViewController
     didShowViewController:(UIViewController*)nextViewController
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  UiSettingsModel* uiSettingsModel = appDelegate.uiSettingsModel;
  if (nextViewController == self.valuationViewController)
    uiSettingsModel.visibleAnnotationViewPage = ValuationAnnotationViewPage;
  else
    uiSettingsModel.visibleAnnotationViewPage = DescriptionAnnotationViewPage;
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  GoBoardPosition* boardPosition = oldGame.boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  GoBoardPosition* boardPosition = newGame.boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:NSKeyValueObservingOptionOld context:NULL];
  self.contentNeedsUpdate = true;
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillStart notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillStart:(NSNotification*)notification
{
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewPanningGestureWillEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewPanningGestureWillEnd:(NSNotification*)notification
{
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationWillBegin notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationWillBegin:(NSNotification*)notification
{
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationDidEnd notification.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationDidEnd:(NSNotification*)notification
{
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeAnnotationDataDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeAnnotationDataDidChange:(NSNotification*)notification
{
  GoNode* node = [self nodeWithAnnotationData];
  if (node != notification.object)
    return;

  self.contentNeedsUpdate = true;
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the
/// #UIApplicationWillChangeStatusBarOrientationNotification notification.
// -----------------------------------------------------------------------------
- (void) statusBarOrientationWillChange:(NSNotification*)notification
{
  // When the interface orientation changes this controller will be deallocated.
  // Presented view controllers have this controller set as their delegate, so
  // we must dismiss them now to avoid access to a deallocated object.
  //
  // Note: On UITypePhone we don't support landscape, but when the interface
  // orientation changes from UIInterfaceOrientationPortrait to
  // UIInterfaceOrientationPortraitUpsideDown or vice versa the notification
  // UIApplicationWillChangeStatusBarOrientationNotification is still sent,
  // causing the dismissal of the presented view controller even though it
  // would not be necessary.
  if (self.presentedViewController)
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"currentBoardPosition"])
  {
    self.contentNeedsUpdate = true;
    self.buttonStatesNeedsUpdate = true;
    [self delayedUpdate];
  }
  else
  {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(delayedUpdate) withObject:nil waitUntilDone:YES];
    return;
  }
  [self updateContent];
  [self updateButtonStates];
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
// -----------------------------------------------------------------------------
- (void) updateContent
{
  if (! self.contentNeedsUpdate)
    return;
  self.contentNeedsUpdate = false;

  GoNode* node = [self nodeWithAnnotationData];
  if (node)
  {
    [self updateValuationViewContent:node];
    [self updateDescriptionViewContent:node];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateContent.
// -----------------------------------------------------------------------------
- (void) updateValuationViewContent:(GoNode*)node
{
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;
  GoMove* move = node.goMove;

  enum GoBoardPositionValuation goBoardPositionValuation = nodeAnnotation ? nodeAnnotation.goBoardPositionValuation : GoBoardPositionValuationNone;
  [self.positionValuationButton setImage:[[UIImage iconForBoardPositionValuation:goBoardPositionValuation] imageByScalingToHeight:self.iconHeight]
                                forState:UIControlStateNormal];

  enum GoMoveValuation goMoveValuation = move ? move.goMoveValuation : GoMoveValuationNone;
  [self.moveValuationButton setImage:[[UIImage iconForMoveValuation:goMoveValuation] imageByScalingToHeight:self.iconHeight]
                            forState:UIControlStateNormal];

  enum GoBoardPositionHotspotDesignation goBoardPositionHotspotDesignation = nodeAnnotation ? nodeAnnotation.goBoardPositionHotspotDesignation : GoBoardPositionHotspotDesignationNone;
  [self.hotspotButton setImage:[[UIImage iconForBoardPositionHotspotDesignation:goBoardPositionHotspotDesignation] imageByScalingToHeight:self.iconHeight]
                      forState:UIControlStateNormal];
  if (goBoardPositionHotspotDesignation == GoBoardPositionHotspotDesignationYesEmphasized)
    self.hotspotButton.tintColor = [UIColor hotspotColor:goBoardPositionHotspotDesignation];
  else
    self.hotspotButton.tintColor = [UIColor blackColor];

  enum GoScoreSummary goScoreSummary = nodeAnnotation ? nodeAnnotation.estimatedScoreSummary : GoScoreSummaryNone;
  NSString* estimatedScoreButtonText = nil;
  UIImage* estimatedScoreButtonImage = nil;
  if (goScoreSummary != GoScoreSummaryNone)
    estimatedScoreButtonText = [NSString shortStringWithScoreSummary:goScoreSummary scoreValue:nodeAnnotation.estimatedScoreValue];
  else
    estimatedScoreButtonImage = [[UIImage iconForScoreSummary:goScoreSummary] imageByScalingToHeight:self.iconHeight];
  [self.estimatedScoreButton setTitle:estimatedScoreButtonText
                             forState:UIControlStateNormal];
  [self.estimatedScoreButton setImage:estimatedScoreButtonImage
                             forState:UIControlStateNormal];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updateContent.
// -----------------------------------------------------------------------------
- (void) updateDescriptionViewContent:(GoNode*)node
{
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;

  NSString* shortDescriptionText = nodeAnnotation ? nodeAnnotation.shortDescription : nil;
  NSString* longDescriptionText = nodeAnnotation ? nodeAnnotation.longDescription : nil;

  UIColor* shortDescriptionTextColor;
  if (! shortDescriptionText && ! longDescriptionText)
  {
    shortDescriptionText = @"No description. Tap the Edit button to add one.";
    shortDescriptionTextColor = [UIColor labelTextColorPlaceholderText];
  }
  else
  {
    shortDescriptionTextColor = [UIColor labelTextColorRegularText];
  }

  self.shortDescriptionLabel.text = shortDescriptionText;
  self.longDescriptionLabel.text = longDescriptionText;
  self.shortDescriptionLabel.textColor = shortDescriptionTextColor;

  if (shortDescriptionText && longDescriptionText)
    self.descriptionLabelsVerticalSpacingConstraint.constant = [UiElementMetrics verticalSpacingSiblings];
  else
    self.descriptionLabelsVerticalSpacingConstraint.constant = 0;
}

// -----------------------------------------------------------------------------
/// @brief Updater method.
// -----------------------------------------------------------------------------
- (void) updateButtonStates
{
  if (! self.buttonStatesNeedsUpdate)
    return;
  self.buttonStatesNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  GoBoardPosition* boardPosition = game.boardPosition;
  GoNode* node = boardPosition.currentNode;

  BOOL isPositionValuationButtonEnabled = NO;
  BOOL isMoveValuationButtonEnabled = NO;
  BOOL isHotspotButtonEnabled = NO;
  BOOL isEstimatedScoreButtonEnabled = NO;
  BOOL isDescriptionEditButtonEnabled = NO;
  BOOL isDescriptionRemoveButtonEnabled = NO;

  if (! game ||
      ! node ||
      game.isComputerThinking ||
      appDelegate.boardViewModel.boardViewPanningGestureIsInProgress ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    isPositionValuationButtonEnabled = NO;
    isMoveValuationButtonEnabled = NO;
    isHotspotButtonEnabled = NO;
    isEstimatedScoreButtonEnabled = NO;
    isDescriptionEditButtonEnabled = NO;
    isDescriptionRemoveButtonEnabled = NO;
  }
  else
  {
    // First board position = root node => It does not make much sense to have
    // a position valuation in the root node (because the root node does not
    // contain a position), and without a position it also does not make sense
    // to mark the root node as a hotspot, or assign a score estimate to it.
    // Still, we allow the user to define these things if she so chooses for
    // some reason that we cannot foresee.
    isPositionValuationButtonEnabled = YES;
    isMoveValuationButtonEnabled = node.goMove ? YES : NO;
    isHotspotButtonEnabled = YES;
    isEstimatedScoreButtonEnabled = YES;

    isDescriptionEditButtonEnabled = YES;
    isDescriptionRemoveButtonEnabled = (node.goNodeAnnotation.shortDescription || node.goNodeAnnotation.longDescription) ? YES : NO;
  }

  self.positionValuationButton.enabled = isPositionValuationButtonEnabled;
  self.moveValuationButton.enabled = isMoveValuationButtonEnabled;
  self.hotspotButton.enabled = isHotspotButtonEnabled;
  self.estimatedScoreButton.enabled = isEstimatedScoreButtonEnabled;
  self.descriptionEditButton.enabled = isDescriptionEditButtonEnabled;
  self.descriptionRemoveButton.enabled = isDescriptionRemoveButtonEnabled;
}

#pragma mark - Button handlers

// -----------------------------------------------------------------------------
/// @brief Displays a pop up that allows the user to change the position
/// valuation.
// -----------------------------------------------------------------------------
- (void) editPositionValuation:(id)sender
{
  NSMutableArray* itemList = [NSMutableArray array];
  for (enum GoBoardPositionValuation positionValuation = GoBoardPositionValuationFirst; positionValuation <= GoBoardPositionValuationLast; positionValuation++)
  {
    NSString* positionValuationText = [NSString stringWithBoardPositionValuation:positionValuation];
    UIImage* positionValuationIcon = [UIImage iconForBoardPositionValuation:positionValuation];
    [itemList addObject:@[positionValuationText, positionValuationIcon]];
  }

  GoNode* node = [self nodeWithAnnotationData];
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;

  int indexOfDefaultItem = nodeAnnotation ? nodeAnnotation.goBoardPositionValuation : GoBoardPositionValuationNone;
  NSString* screenTitle = @"Select position valuation";
  NSString* footerTitle = @"Select a position valuation.";
  id context = [NSNumber numberWithInt:BoardPositionValuationItemPickerContext];
  UIButton* button = sender;

  [self presentItemPickerControllerWithItemList:itemList
                             indexOfDefaultItem:indexOfDefaultItem
                                    screenTitle:screenTitle
                                    footerTitle:footerTitle
                                        context:context
                                     sourceView:button];
}

// -----------------------------------------------------------------------------
/// @brief Displays a pop up that allows the user to change the move valuation.
// -----------------------------------------------------------------------------
- (void) editMoveValuation:(id)sender
{
  NSMutableArray* itemList = [NSMutableArray array];
  for (enum GoMoveValuation moveValuation = GoMoveValuationFirst; moveValuation <= GoMoveValuationLast; moveValuation++)
  {
    NSString* moveValuationText = [NSString stringWithMoveValuation:moveValuation];
    UIImage* moveValuationIcon = [UIImage iconForMoveValuation:moveValuation];
    [itemList addObject:@[moveValuationText, moveValuationIcon]];
  }

  GoNode* node = [self nodeWithAnnotationData];
  GoMove* move = node.goMove;

  int indexOfDefaultItem = move ? move.goMoveValuation : GoMoveValuationNone;
  NSString* screenTitle = @"Select move valuation";
  NSString* footerTitle = @"Select a move valuation.";
  id context = [NSNumber numberWithInt:MoveValuationItemPickerContext];
  UIButton* button = sender;

  [self presentItemPickerControllerWithItemList:itemList
                             indexOfDefaultItem:indexOfDefaultItem
                                    screenTitle:screenTitle
                                    footerTitle:footerTitle
                                        context:context
                                     sourceView:button];
}

// -----------------------------------------------------------------------------
/// @brief Displays a pop up that allows the user to change the hotspot
/// designation.
// -----------------------------------------------------------------------------
- (void) editHotspotDesignation:(id)sender
{
  NSMutableArray* itemList = [NSMutableArray array];
  for (enum GoBoardPositionHotspotDesignation hotspotDesignation = GoBoardPositionHotspotDesignationFirst; hotspotDesignation <= GoBoardPositionHotspotDesignationLast; hotspotDesignation++)
  {
    NSString* hotspotDesignationText = [NSString stringWithBoardPositionHotspotDesignation:hotspotDesignation];
    UIImage* hotspotDesignationIcon = [UIImage iconForBoardPositionHotspotDesignation:hotspotDesignation];
    if (hotspotDesignation == GoBoardPositionHotspotDesignationYesEmphasized)
      hotspotDesignationIcon = [hotspotDesignationIcon imageByTintingWithColor:[UIColor hotspotColor:hotspotDesignation]];
    [itemList addObject:@[hotspotDesignationText, hotspotDesignationIcon]];
  }

  GoNode* node = [self nodeWithAnnotationData];
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;

  int indexOfDefaultItem = nodeAnnotation ? nodeAnnotation.goBoardPositionHotspotDesignation : GoBoardPositionHotspotDesignationNone;
  NSString* screenTitle = @"Select hotspot designation";
  NSString* footerTitle = @"Select a hotspot designation.";
  id context = [NSNumber numberWithInt:BoardPositionHotspotDesignationItemPickerContext];
  UIButton* button = sender;

  [self presentItemPickerControllerWithItemList:itemList
                             indexOfDefaultItem:indexOfDefaultItem
                                    screenTitle:screenTitle
                                    footerTitle:footerTitle
                                        context:context
                                     sourceView:button];
}

// -----------------------------------------------------------------------------
/// @brief Displays a pop up that allows the user to change the estimated score.
// -----------------------------------------------------------------------------
- (void) editEstimatedScore:(id)sender
{
  GoNode* node = [self nodeWithAnnotationData];
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;

  enum GoScoreSummary estimatedScoreSummary = nodeAnnotation ? nodeAnnotation.estimatedScoreSummary : GoScoreSummaryNone;
  double estimatedScoreValue = nodeAnnotation ? nodeAnnotation.estimatedScoreValue : 0.0f;
  EditEstimatedScoreController* editEstimatedScoreController = [EditEstimatedScoreController controllerWithEstimatedScoreSummary:estimatedScoreSummary
                                                                                                             estimatedScoreValue:estimatedScoreValue
                                                                                                                        delegate:self];
  [self presentNavigationControllerWithRootViewController:editEstimatedScoreController
                                        usingPopoverStyle:self.presentViewControllersInPopover
                                        popoverSourceView:sender
                                     popoverBarButtonItem:nil];
}

// -----------------------------------------------------------------------------
/// @brief Displays a pop up that allows the user to change the short and long
/// description texts.
// -----------------------------------------------------------------------------
- (void) editDescription:(id)sender
{
  GoNode* node = [self nodeWithAnnotationData];
  GoNodeAnnotation* nodeAnnotation = node.goNodeAnnotation;

  NSString* shortDescription = nodeAnnotation ? nodeAnnotation.shortDescription : nil;
  NSString* longDescription = nodeAnnotation ? nodeAnnotation.longDescription : nil;
  EditNodeDescriptionController* editNodeDescriptionController = [EditNodeDescriptionController controllerWithShortDescription:shortDescription
                                                                                                               longDescription:longDescription
                                                                                                                      delegate:self];
  [self presentNavigationControllerWithRootViewController:editNodeDescriptionController
                                        usingPopoverStyle:self.presentViewControllersInPopover
                                        popoverSourceView:sender
                                     popoverBarButtonItem:nil];
}

// -----------------------------------------------------------------------------
/// @brief Removes both the short and long description.
// -----------------------------------------------------------------------------
- (void) removeDescription:(id)sender
{
  GoNode* node = [self nodeWithAnnotationData];
  [[[[ChangeAnnotationDataCommand alloc] initWithNode:node shortDescription:nil longDescription:nil] autorelease] submit];
}

#pragma mark - View controller presentation

// -----------------------------------------------------------------------------
/// @brief Helper for editPositionValuation:(), editMoveValuation:() and
/// editHotspotDesignation:()
// -----------------------------------------------------------------------------
- (void) presentItemPickerControllerWithItemList:(NSArray*)itemList
                              indexOfDefaultItem:(int)indexOfDefaultItem
                                     screenTitle:(NSString*)screenTitle
                                     footerTitle:(NSString*)footerTitle
                                         context:(id)context
                                      sourceView:(UIView*)sourceView
{
  ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                screenTitle:screenTitle
                                                                         indexOfDefaultItem:indexOfDefaultItem
                                                                                   delegate:self];
  itemPickerController.footerTitle = footerTitle;
  itemPickerController.context = context;

  // Unlike editing of the estimated score summary and the node descriptions,
  // which require "cancel" and "done" buttons because of the more complex
  // nature of the editing process, for the simple ItemPickerController use
  // case we want the user be able to select a new value with a single tap.
  // We therefore present the ItemPickerController in non-modal mode.
  itemPickerController.itemPickerControllerMode = ItemPickerControllerModeNonModal;

  if (! self.presentViewControllersInPopover)
  {
    // In modal presentation style we display a "cancel" item to provide the
    // user with a means to cancel. To contrast: In popover presentation style
    // the means to cancel exists by simply tapping outside the popover.
    itemPickerController.displayCancelItem = true;
  }

  [self presentNavigationControllerWithRootViewController:itemPickerController
                                        usingPopoverStyle:self.presentViewControllersInPopover
                                        popoverSourceView:sourceView
                                     popoverBarButtonItem:nil];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (! didMakeSelection)
  {
    [self dismissViewControllerAnimated:YES completion:nil];
    return;
  }

  GoNode* node = [self nodeWithAnnotationData];

  enum ItemPickerContext itemPickerContext = [controller.context intValue];
  if (itemPickerContext == BoardPositionValuationItemPickerContext)
    [[[[ChangeAnnotationDataCommand alloc] initWithNode:node boardPositionValuation:controller.indexOfSelectedItem] autorelease] submit];
  else if (itemPickerContext == MoveValuationItemPickerContext)
    [[[[ChangeAnnotationDataCommand alloc] initWithNode:node moveValuation:controller.indexOfSelectedItem] autorelease] submit];
  else if (itemPickerContext == BoardPositionHotspotDesignationItemPickerContext)
    [[[[ChangeAnnotationDataCommand alloc] initWithNode:node boardPositionHotspotDesignation:controller.indexOfSelectedItem] autorelease] submit];
  else
    assert(0);

  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EditEstimatedScoreControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditEstimatedScoreControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) editEstimatedScoreControllerDidEndEditing:(EditEstimatedScoreController*)controller didChangeEstimatedScore:(bool)didChangeEstimatedScore
{
  enum GoScoreSummary newEstimatedScoreSummary = controller.estimatedScoreSummary;
  double newEstimatedScoreValue = controller.estimatedScoreValue;

  [self dismissViewControllerAnimated:YES completion:nil];

  if (! didChangeEstimatedScore)
    return;

  GoNode* node = [self nodeWithAnnotationData];

  [[[[ChangeAnnotationDataCommand alloc] initWithNode:node
                                estimatedScoreSummary:newEstimatedScoreSummary
                                                value:newEstimatedScoreValue] autorelease] submit];
}

#pragma mark - EditNodeDescriptionControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditNodeDescriptionControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) editNodeDescriptionControllerDidEndEditing:(EditNodeDescriptionController*)controller didChangeDescriptions:(bool)didChangeDescriptions
{
  NSString* newShortDescription = controller.shortDescription;
  NSString* newLongDescription = controller.longDescription;

  [self dismissViewControllerAnimated:YES completion:nil];

  if (! didChangeDescriptions)
    return;

  GoNode* node = [self nodeWithAnnotationData];

  // Use submitAfterDelay: instead of submit because of an extremely weird
  // and inexplicable layout issue that only occurs under the following
  // conditions:
  // - App must run on a real device, not on the simulator.
  // - UIType must be UITypePhone, i.e. problem does not occur on iPad.
  // - Interface orientation must be Portrait, not Landscape.
  // - The presented controller must be EditNodeDescriptionController, and the
  //   keyboard must be visible at the time when the user taps the "Done"
  //   button.
  //
  // The problem does not occur:
  // - If EditNodeDescriptionController does not display the keyboard at all
  //   (tested with becomeFirstResponder disabled so that the keyboard is
  //   never displayed at all).
  // - If EditNodeDescriptionController displayed the keyboard at the start, but
  //   then does not display it anymore at the time when the user taps the
  //   "Done" button (tested by programmatically hiding the keyboard with
  //   resignFirstResponder).
  // - If KeyboardHeightAdjustment is disabled in EditNodeDescriptionController.
  // - If another controller (EditEstimatedScoreController) is presented and
  //   that controller at some time displays the keyboard.
  //
  // What *is* the problem? When BoardPositionCollectionViewController receives
  // the notification nodeAnnotationDataDidChange it reloads the board position
  // cell. This causes BoardPositionCollectionViewCell::setBoardPosition:() to
  // be invoked, which in most cases causes the cell to update its internal
  // Auto Layout constraints due to the changed data. When that happens the
  // layout of ***ALL*** collection view cells that are currently visible
  // becomes broken and the Xcode debug windows displays Auto Layout constraint
  // warnings for all affected cells. The user can fix the display by scrolling
  // the collection view, causing the cells to be re-layouted.
  //
  // After much debugging it has been found that the problem simply disappears
  // if the command that triggers the update in
  // BoardPositionCollectionViewController is slightly delayed. Presumably this
  // is because the delay gives UiKit the time it needs to fully dismiss
  // EditNodeDescriptionController and the keyboard.
  //
  // Problem seen with Xcode 13.2.1, iOS base SDK 15.2, iPhone 12 Pro Max with
  // iOS 15.6.1.
  [[[[ChangeAnnotationDataCommand alloc] initWithNode:node
                                     shortDescription:newShortDescription
                                      longDescription:newLongDescription] autorelease] submitAfterDelay:0];
}

#pragma mark - Helpers

// -----------------------------------------------------------------------------
/// @brief Returns the GoNode object whose annotation data is displayed and
/// edited by the controller.
// -----------------------------------------------------------------------------
- (GoNode*) nodeWithAnnotationData
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  GoNode* node = boardPosition.currentNode;
  return node;
}

@end
