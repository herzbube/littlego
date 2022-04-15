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
#import "../../utility/ExceptionUtility.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// AnnotationViewControllerPhonePortraitOnly.
// -----------------------------------------------------------------------------
@interface AnnotationViewControllerPhonePortraitOnly()
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
@property(nonatomic, retain) UIView* descriptionLabelColumnView;
@property(nonatomic, retain) UIScrollView* descriptionScrollView;
@property(nonatomic, retain) UIView* descriptionContentView;
@property(nonatomic, retain) UILabel* shortDescriptionLabel;
@property(nonatomic, retain) UILabel* longDescriptionLabel;
@property(nonatomic, retain) UIView* descriptionLabelSpacerColumnView;
@property(nonatomic, retain) UIView* descriptionButtonColumnView;
@property(nonatomic, retain) UIButton* descriptionButton;
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
      self.labelFontSize = 10;
      break;
    case UITypePhone:
      self.labelFontSize = 11;
      break;
    case UITypePad:
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
  self.descriptionLabelColumnView = nil;
  self.descriptionScrollView = nil;
  self.descriptionContentView = nil;
  self.shortDescriptionLabel = nil;
  self.longDescriptionLabel = nil;
  self.descriptionLabelSpacerColumnView = nil;
  self.descriptionButtonColumnView = nil;
  self.descriptionButton = nil;
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
  [center addObserver:self selector:@selector(boardViewWillDisplayCrossHair:) name:boardViewWillDisplayCrossHair object:nil];
  [center addObserver:self selector:@selector(boardViewWillHideCrossHair:) name:boardViewWillHideCrossHair object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationWillBegin:) name:boardViewAnimationWillBegin object:nil];
  [center addObserver:self selector:@selector(boardViewAnimationDidEnd:) name:boardViewAnimationDidEnd object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
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
    // self.estimatedScoreButton uses a different title label font size than
    // the other buttons, which causes it to use less vertical size. With the
    // default stack view alignment (UIStackViewAlignmentFill) this causes the
    // button and its label to be positioned in a slightly different vertical
    // location than the other buttons/labels. By aligning the stack view
    // subviews to the stack view's top edge everything remains nicely aligned.
    self.valuationViewStackView.alignment = UIStackViewAlignmentTop;
  }
  else
  {
    self.valuationViewStackView.axis = UILayoutConstraintAxisVertical;
    self.valuationViewStackView.distribution = UIStackViewDistributionEqualSpacing;
  }

  self.positionValuationLabel = [self createTitleLabelInStackView:self.valuationViewStackView withTitleText:@"Position"];
  self.positionValuationButton = [self createButtonInSuperView:self.positionValuationLabel.superview];

  self.moveValuationLabel = [self createTitleLabelInStackView:self.valuationViewStackView withTitleText:@"Move"];
  self.moveValuationButton = [self createButtonInSuperView:self.moveValuationLabel.superview];

  self.hotspotLabel = [self createTitleLabelInStackView:self.valuationViewStackView withTitleText:@"Hotspot"];
  self.hotspotButton = [self createButtonInSuperView:self.hotspotLabel.superview];

  self.estimatedScoreLabel = [self createTitleLabelInStackView:self.valuationViewStackView withTitleText:@"Score"];
  self.estimatedScoreButton = [self createButtonInSuperView:self.estimatedScoreLabel.superview];

  UIFont* buttonTitleLabelFont = [UIFont systemFontOfSize:self.labelFontSize];
  self.estimatedScoreButton.titleLabel.font = buttonTitleLabelFont;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupViewHierarchy.
// -----------------------------------------------------------------------------
- (void) setupDescriptionView:(UIView*)superview
{
  self.descriptionLabelColumnView = [self createViewInSuperView:superview];

  self.descriptionScrollView = [self createScrollViewInSuperView:self.descriptionLabelColumnView];
  self.descriptionContentView = [self createViewInSuperView:self.descriptionScrollView];

  self.shortDescriptionLabel = [self createLabelInSuperView:self.descriptionContentView];
  self.shortDescriptionLabel.numberOfLines = 0;
  self.longDescriptionLabel = [self createLabelInSuperView:self.descriptionContentView];
  self.longDescriptionLabel.numberOfLines = 0;

  self.descriptionLabelSpacerColumnView = [self createViewInSuperView:superview];

  self.descriptionButtonColumnView = [self createViewInSuperView:superview];
  self.descriptionButton = [self createButtonInSuperView:self.descriptionButtonColumnView];
  self.descriptionButtonSpacerView = [self createViewInSuperView:self.descriptionButtonColumnView];

  [self.descriptionButton setImage:[[UIImage editIcon] imageByScalingToHeight:self.iconHeight]
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
- (UILabel*) createTitleLabelInStackView:(UIStackView*)stackView withTitleText:(NSString*)titleText
{
  UIView* positionValuationBox = [self createViewInSuperView:stackView];
  [stackView addArrangedSubview:positionValuationBox];

  UILabel* label = [self createLabelInSuperView:positionValuationBox];
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
- (UIButton*) createButtonInSuperView:(UIView*)superview
{
  UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
  [superview addSubview:button];
  button.tintColor = [UIColor blackColor];
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
  label.translatesAutoresizingMaskIntoConstraints = NO;
  button.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];
  viewsDictionary[@"label"] = label;
  viewsDictionary[@"button"] = button;
  [visualFormats addObject:@"H:|-0-[label]-0-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-0-[label]-%d-[button]-0-|", self.buttonVerticalSpacing]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:label.superview];

  [AutoLayoutUtility alignFirstView:button withSecondView:label onAttribute:NSLayoutAttributeCenterX constraintHolder:label.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupAutoLayoutConstraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsDescriptionView
{
  self.descriptionLabelColumnView.translatesAutoresizingMaskIntoConstraints = NO;
  self.shortDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.longDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionLabelSpacerColumnView.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionButtonColumnView.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionButtonSpacerView.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  viewsDictionary[@"descriptionLabelColumnView"] = self.descriptionLabelColumnView;
  viewsDictionary[@"descriptionLabelSpacerColumnView"] = self.descriptionLabelSpacerColumnView;
  viewsDictionary[@"descriptionButtonColumnView"] = self.descriptionButtonColumnView;
  [visualFormats addObject:@"H:|-0-[descriptionLabelColumnView]-0-[descriptionLabelSpacerColumnView]-[descriptionButtonColumnView]-0-|"];
  [visualFormats addObject:@"V:|-0-[descriptionLabelColumnView]-0-|"];
  [visualFormats addObject:@"V:|-0-[descriptionLabelSpacerColumnView]-0-|"];
  [visualFormats addObject:@"V:|-0-[descriptionButtonColumnView]-0-|"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.descriptionLabelColumnView.superview];

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
  viewsDictionary[@"descriptionButton"] = self.descriptionButton;
  viewsDictionary[@"descriptionButtonSpacerView"] = self.descriptionButtonSpacerView;
  [visualFormats addObject:@"H:|-0-[descriptionButton]-0-|"];
  [visualFormats addObject:@"H:|-0-[descriptionButtonSpacerView]-0-|"];
  [visualFormats addObject:@"V:|-0-[descriptionButton]-0-[descriptionButtonSpacerView]-0-|"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.descriptionButton.superview];

  // The button must resist compression more than the labels in
  // self.descriptionLabelColumnView, otherwise a long label text can cause the
  // button to be squashed (observed in layouts slightly different than the
  // current one). More important, the increased compression resistance also
  // fixes a weird problem with the current layout, where shortDescriptionLabel
  // sometimes truncates its text when the text becomes too long (e.g. longer
  // than two lines, but shorter texts have also been seen truncated). The
  // problem occurs only when both labels have numberOfLines != 1, so a
  // workaround was to set numberOfLines to 1 for that label that has no text.
  // As soon as both labels have text, though, the workaround is no longer
  // possible. In any case, invoking setContentCompressionResistancePriority
  // with the highest value completely fixes the truncation problem.
  [self.descriptionButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
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
/// @brief Responds to the #boardViewWillDisplayCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillDisplayCrossHair:(NSNotification*)notification
{
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewWillHideCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillHideCrossHair:(NSNotification*)notification
{
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationWillBegin notifications.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationWillBegin:(NSNotification*)notification
{
  self.buttonStatesNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewAnimationDidEnd notifications.
// -----------------------------------------------------------------------------
- (void) boardViewAnimationDidEnd:(NSNotification*)notification
{
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

  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  GoNode* node = boardPosition.currentNode;

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
  self.shortDescriptionLabel.text = shortDescriptionText;

  NSString* longDescriptionText = nodeAnnotation ? nodeAnnotation.longDescription : nil;
  self.longDescriptionLabel.text = longDescriptionText;

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
  BOOL isDescriptionButtonEnabled = NO;

  if (! game ||
      ! node ||
      game.isComputerThinking ||
      appDelegate.boardViewModel.boardViewDisplaysCrossHair ||
      appDelegate.boardViewModel.boardViewDisplaysAnimation)
  {
    isPositionValuationButtonEnabled = NO;
    isMoveValuationButtonEnabled = NO;
    isHotspotButtonEnabled = NO;
    isEstimatedScoreButtonEnabled = NO;
    isDescriptionButtonEnabled = NO;
  }
  else
  {
    // First board position = root node
    // - Root node cannot contain moves, so it also cannot contain move
    //   annotation properties
    // - It also does not make sense to have position valuation properties in
    //   the root node, as the root node does not contain a position
    // - Without a position it does not make sense to mark the root node as a
    //   hotspot, or assign a score estimate to it
    // - However, it is conceivable that even the root node can have a node
    //   title (= short description) or a comment (= long description) in it

    isPositionValuationButtonEnabled = game.boardPosition.isFirstPosition ? NO : YES;
    if (node.goMove)
      isMoveValuationButtonEnabled = game.boardPosition.isFirstPosition ? NO : YES;
    else
      isMoveValuationButtonEnabled = NO;
    isHotspotButtonEnabled = game.boardPosition.isFirstPosition ? NO : YES;
    isEstimatedScoreButtonEnabled = game.boardPosition.isFirstPosition ? NO : YES;
    isDescriptionButtonEnabled = YES;
  }

  self.positionValuationButton.enabled = isPositionValuationButtonEnabled;
  self.moveValuationButton.enabled = isMoveValuationButtonEnabled;
  self.hotspotButton.enabled = isHotspotButtonEnabled;
  self.estimatedScoreButton.enabled = isEstimatedScoreButtonEnabled;
  self.descriptionButton.enabled = isDescriptionButtonEnabled;
}

@end
