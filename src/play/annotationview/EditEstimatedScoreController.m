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
#import "EditEstimatedScoreController.h"
#import "../../go/GoNodeAnnotation.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EditEstimatedScoreController.
// -----------------------------------------------------------------------------
@interface EditEstimatedScoreController()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoScoreSummary estimatedScoreSummary;
@property(nonatomic, assign, readwrite) double estimatedScoreValue;
//@}
@property(nonatomic, assign) enum GoScoreSummary currentScoreSummary;
@property(nonatomic, assign) double currentScoreValue;
@property(nonatomic, retain) UIView* contentView;
@property(nonatomic, retain) ItemPickerController* scoreSummaryPickerController;
@end


@implementation EditEstimatedScoreController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditEstimatedScoreController
/// instance that is used to edit the estimated score consisting of
/// @a estimatedScoreSummary and @a estimatedScoreValue.
// -----------------------------------------------------------------------------
+ (EditEstimatedScoreController*) controllerWithEstimatedScoreSummary:(enum GoScoreSummary)estimatedScoreSummary
                                                  estimatedScoreValue:(double)estimatedScoreValue
                                                             delegate:(id<EditEstimatedScoreControllerDelegate>)delegate
{
  EditEstimatedScoreController* controller = [[EditEstimatedScoreController alloc] init];
  if (controller)
  {
    [controller autorelease];
    controller.estimatedScoreSummary = estimatedScoreSummary;
    controller.estimatedScoreValue = estimatedScoreValue;
    controller.currentScoreSummary = estimatedScoreSummary;
    controller.currentScoreValue = estimatedScoreValue;
    controller.delegate = delegate;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditEstimatedScoreController object.
///
/// @note This is the designated initializer of EditEstimatedScoreController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.estimatedScoreSummary = GoScoreSummaryNone;
  self.estimatedScoreValue = 0.0f;
  self.currentScoreSummary = GoScoreSummaryNone;
  self.currentScoreValue = 0.0f;
  self.delegate = nil;
  self.contentView = nil;
  self.scoreSummaryPickerController = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditEstimatedScoreController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.contentView = nil;
  self.scoreSummaryPickerController = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  [self setupNavigationItem];
  [self setupChildControllers];
  [self setupContentView];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];

  [self updateDoneButtonEnabledStateForCurrentlyEnteredData];
}

#pragma mark - Navigation item setup

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the navigation item.
// -----------------------------------------------------------------------------
- (void) setupNavigationItem
{
  NSString* screenTitle = @"Edit estimated score";
  self.title = screenTitle;
  self.navigationItem.title = screenTitle;

  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)] autorelease];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.scoreSummaryPickerController = [ItemPickerController controllerWithItemList:[NSArray array]
                                                                       screenTitle:nil
                                                                indexOfDefaultItem:self.estimatedScoreSummary
                                                                          delegate:self];
  [self updateScoreSummaries];
  self.scoreSummaryPickerController.itemPickerControllerMode = ItemPickerControllerModeNonModal;
  self.scoreSummaryPickerController.footerTitle = @"Select an estimated score summary. Select \"Black wins\" or \"White wins\" to enter an estimated score value.";
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setScoreSummaryPickerController:(ItemPickerController*)scoreSummaryPickerController
{
  if (_scoreSummaryPickerController == scoreSummaryPickerController)
    return;
  if (_scoreSummaryPickerController)
  {
    [_scoreSummaryPickerController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_scoreSummaryPickerController removeFromParentViewController];
    [_scoreSummaryPickerController release];
    _scoreSummaryPickerController = nil;
  }
  if (scoreSummaryPickerController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:scoreSummaryPickerController];
    [scoreSummaryPickerController didMoveToParentViewController:self];
    [scoreSummaryPickerController retain];
    _scoreSummaryPickerController = scoreSummaryPickerController;
  }
}

#pragma mark - Content view setup

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the content view.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  self.contentView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

  // A background color is required to support UIModalPresentationAutomatic
  self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

#pragma mark - View hierarchy setup

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.contentView];
  [self.contentView addSubview:self.scoreSummaryPickerController.view];
}

#pragma mark - Auto Layout constraints

// -----------------------------------------------------------------------------
/// @brief Main method for setting up Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSafeAreaOfSuperview:self.contentView.superview withSubview:self.contentView];

  self.scoreSummaryPickerController.view.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.scoreSummaryPickerController.view.superview withSubview:self.scoreSummaryPickerController.view];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if ([self selectedScoreSummaryAllowsEnteringScoreValue])
  {
    NSString* scoreValueAsText;
    if (self.currentScoreValue > 0.0)
    {
      scoreValueAsText = [self scoreValueAsText:self.currentScoreValue];
    }
    else
    {
      // Use a non-zero value to avoid an ugly initial validation error in
      // EditTextController. The user didn't do anything wrong, so don't
      // confront her.
      scoreValueAsText = [self scoreValueAsText:1.0];
    }

    EditTextController* editTextController = [[EditTextController controllerWithText:scoreValueAsText
                                                                               style:EditTextControllerStyleTextField
                                                                            delegate:self] retain];
    editTextController.title = @"Enter score value";
    editTextController.keyboardType = UIKeyboardTypeDecimalPad;
    [self.navigationController pushViewController:editTextController animated:YES];
    [editTextController release];
  }
  else
  {
    // Keep the current score value so the user can return to it when she
    // temporarily selected a score summary that does not support a value
    [self updateCurrentScoreSummary:[self selectedScoreSummary]
                         scoreValue:self.currentScoreValue];

  }
}

#pragma mark - EditTextDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController isTextValid:(NSString*)text validationErrorMessage:(NSString**)validationErrorMessage
{
  bool isTextValid = [self controller:editTextController isTextValid:text];

  if (validationErrorMessage)
  {
    if (isTextValid)
      *validationErrorMessage = nil;
    else
      *validationErrorMessage = @"Please enter a numeric score value greater than zero.";
  }

  return isTextValid;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  return [self controller:editTextController isTextValid:text];
}

// -----------------------------------------------------------------------------
/// @brief Helper method for EditTextDelegate protocol methods.
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController isTextValid:(NSString*)text
{
  // self.currentScoreSummary has not yet been updated with the selected score
  // summary because the user might still cancel the text editing process (in
  // which case we want to revert ItemPickerController to
  // self.currentScoreSummary)
  enum GoScoreSummary selectedScoreSummary = [self selectedScoreSummary];
  double scoreValue = [self textAsScoreValue:text];
  bool isValidScore = [self isValidScoreSummary:selectedScoreSummary scoreValue:scoreValue];

  return isValidScore;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel
{
  if (didCancel)
  {
    self.scoreSummaryPickerController.indexOfSelectedItem = self.currentScoreSummary;
  }
  else
  {
    [self updateCurrentScoreSummary:[self selectedScoreSummary]
                         scoreValue:[self textAsScoreValue:editTextController.text]];
  }

  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished entering an estimated score.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  enum GoScoreSummary scoreSummary = self.currentScoreSummary;
  double scoreValue;
  if ([self currentScoreSummaryAllowsEnteringScoreValue])
    scoreValue = self.currentScoreValue;
  else
    scoreValue = 0.0f;

  bool didChangeEstimatedScore;
  if (scoreSummary == self.estimatedScoreSummary && scoreValue == self.estimatedScoreValue)
  {
    didChangeEstimatedScore = false;
  }
  else
  {
    didChangeEstimatedScore = true;
    self.estimatedScoreSummary = scoreSummary;
    self.estimatedScoreValue = scoreValue;
  }

  [self.delegate editEstimatedScoreControllerDidEndEditing:self didChangeEstimatedScore:didChangeEstimatedScore];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled entering an estimated score.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  bool didChangeEstimatedScore = false;
  [self.delegate editEstimatedScoreControllerDidEndEditing:self didChangeEstimatedScore:didChangeEstimatedScore];
}

#pragma mark - UI control updaters

// -----------------------------------------------------------------------------
/// @brief Updates the score summaries available for selection from the
/// currently entered data.
// -----------------------------------------------------------------------------
- (void) updateCurrentScoreSummary:(enum GoScoreSummary)scoreSummary scoreValue:(double)scoreValue
{
  if (self.currentScoreSummary == scoreSummary && self.currentScoreValue == scoreValue)
    return;

  self.currentScoreSummary = scoreSummary;
  self.currentScoreValue = scoreValue;

  [self updateScoreSummaries];
  [self updateDoneButtonEnabledStateForCurrentlyEnteredData];
}

// -----------------------------------------------------------------------------
/// @brief Updates the score summaries available for selection from the
/// currently entered data.
// -----------------------------------------------------------------------------
- (void) updateScoreSummaries
{
  bool currentScoreSummaryAllowsEnteringScoreValue = [self currentScoreSummaryAllowsEnteringScoreValue];

  NSMutableArray* itemList = [NSMutableArray array];
  for (enum GoScoreSummary scoreSummary = GoScoreSummaryFirst; scoreSummary <= GoScoreSummaryLast; scoreSummary++)
  {
    NSString* scoreSummaryText;
    if (scoreSummary == self.currentScoreSummary && currentScoreSummaryAllowsEnteringScoreValue)
      scoreSummaryText = [NSString stringWithScoreSummary:scoreSummary scoreValue:self.currentScoreValue];
    else
      scoreSummaryText = [NSString stringWithScoreSummary:scoreSummary];
    UIImage* scoreSummaryIcon = [UIImage iconForScoreSummary:scoreSummary];
    [itemList addObject:@[scoreSummaryText, scoreSummaryIcon]];
  }
  self.scoreSummaryPickerController.itemList = itemList;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "done" button depending on whether
/// or not the currently entered data constitutes a valid estimated score.
// -----------------------------------------------------------------------------
- (void) updateDoneButtonEnabledStateForCurrentlyEnteredData
{
  BOOL enabled = [self isCurrentDataValid] ? YES : NO;
  self.navigationItem.rightBarButtonItem.enabled = enabled;
}

#pragma mark - Data validation and conversion methods

// -----------------------------------------------------------------------------
/// @brief Returns true if the currently entered data constitutes a valid
/// estimated score. Returns false if not.
// -----------------------------------------------------------------------------
- (bool) isCurrentDataValid
{
  double scoreValue;
  if ([self currentScoreSummaryAllowsEnteringScoreValue])
    scoreValue = self.currentScoreValue;
  else
    scoreValue = 0.0f;
  return [self isValidScoreSummary:self.currentScoreSummary
                        scoreValue:scoreValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a scoreSummary together with @a scoreValue
/// constitutes a valid estimated score. Returns false if not.
// -----------------------------------------------------------------------------
- (bool) isValidScoreSummary:(enum GoScoreSummary)scoreSummary
                  scoreValue:(double)scoreValue
{
  return [GoNodeAnnotation isValidEstimatedScoreSummary:scoreSummary value:scoreValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the currently entered score summary allows entering
/// a score value. Returns false if not.
// -----------------------------------------------------------------------------
- (bool) currentScoreSummaryAllowsEnteringScoreValue
{
  return [self scoreSummaryAllowsEnteringScoreValue:self.currentScoreSummary];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the score summary currently selected in the
/// ItemPickerController allows entering a score value. Returns false if not.
// -----------------------------------------------------------------------------
- (bool) selectedScoreSummaryAllowsEnteringScoreValue
{
  enum GoScoreSummary selectedScoreSummary = [self selectedScoreSummary];
  return [self scoreSummaryAllowsEnteringScoreValue:selectedScoreSummary];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @a scoreSummary allows entering a score value.
/// Returns false if not.
// -----------------------------------------------------------------------------
- (bool) scoreSummaryAllowsEnteringScoreValue:(enum GoScoreSummary)scoreSummary
{
  return (scoreSummary == GoScoreSummaryBlackWins || scoreSummary == GoScoreSummaryWhiteWins);
}

// -----------------------------------------------------------------------------
/// @brief Returns the #GoScoreSummary value that corresponds to the currently
/// selected item in the ItemPickerController.
// -----------------------------------------------------------------------------
- (enum GoScoreSummary) selectedScoreSummary
{
  enum GoScoreSummary selectedScoreSummary = self.scoreSummaryPickerController.indexOfSelectedItem;
  return selectedScoreSummary;
}

// -----------------------------------------------------------------------------
/// @brief Returns the score value that corresponds to @a text. Returns -1.0f
/// if conversion of @a text to a double value fails, indicating that @a text
/// cannot represent a valid score value.
// -----------------------------------------------------------------------------
- (double) textAsScoreValue:(NSString*)text
{
  if (text.length == 0)
    return -1.0f;

  NSNumberFormatter* numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
  // Parses the text as a decimal number
  numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  // If the string contains any characters other than numerical digits or
  // locale-appropriate group or decimal separators, parsing will fail.
  // Leading/trailing space is ignored.
  // Returns nil if parsing fails.
  NSNumber* number = [numberFormatter numberFromString:text];
  if (! number)
    return -1.0f;

  double scoreValue = [number doubleValue];
  return scoreValue;
}

// -----------------------------------------------------------------------------
/// @brief Returns the score value @a scoreValue represented as string.
// -----------------------------------------------------------------------------
- (NSString*) scoreValueAsText:(double)scoreValue
{
  NSNumberFormatter* numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
  numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  numberFormatter.usesGroupingSeparator = NO;
  return [numberFormatter stringFromNumber:[NSNumber numberWithDouble:scoreValue]];
}

@end
