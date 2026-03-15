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
#import "EditGameInfoRulesController.h"
#import "../../go/GoGameInfoRules.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EditGameInfoRulesController.
// -----------------------------------------------------------------------------
@interface EditGameInfoRulesController()
@property(nonatomic, retain) UIView* contentView;
@property(nonatomic, retain) UIStackView* textFieldStackView;
@property(nonatomic, retain) UILabel* textFieldLabel;
@property(nonatomic, retain) UITextField* textField;
@property(nonatomic, retain) ItemPickerController* itemPickerController;
@property(nonatomic, retain) NSLayoutConstraint* textFieldStackViewZeroHeightConstraint;
@end


@implementation EditGameInfoRulesController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditGameInfoRulesController
/// instance that is used to edit the estimated score consisting of
/// @a estimatedScoreSummary and @a estimatedScoreValue.
// -----------------------------------------------------------------------------
+ (EditGameInfoRulesController*) controllerWithGameInfoRules:(GoGameInfoRules*)gameInfoRules
                                                             delegate:(id<EditGameInfoRulesControllerDelegate>)delegate;
{
  EditGameInfoRulesController* controller = [[EditGameInfoRulesController alloc] init];
  if (controller)
  {
    [controller autorelease];
    controller.gameInfoRules = gameInfoRules;
    controller.delegate = delegate;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditGameInfoRulesController object.
///
/// @note This is the designated initializer of EditGameInfoRulesController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.gameInfoRules = nil;
  self.delegate = nil;
  self.contentView = nil;
  self.textFieldStackView = nil;
  self.textFieldLabel = nil;
  self.textField = nil;
  self.itemPickerController = nil;
  self.textFieldStackViewZeroHeightConstraint = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditGameInfoRulesController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.contentView = nil;
  self.textFieldStackView = nil;
  self.textFieldLabel = nil;
  self.textField = nil;
  self.itemPickerController = nil;
  self.textFieldStackViewZeroHeightConstraint = nil;

  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setItemPickerController:(ItemPickerController*)itemPickerController
{
  if (_itemPickerController == itemPickerController)
    return;
  if (_itemPickerController)
  {
    [_itemPickerController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_itemPickerController removeFromParentViewController];
    [_itemPickerController release];
    _itemPickerController = nil;
  }
  if (itemPickerController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:itemPickerController];
    [itemPickerController didMoveToParentViewController:self];
    [itemPickerController retain];
    _itemPickerController = itemPickerController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  [self setupNavigationItem];
  [self setupItemPickerController];
  [self createViews];
  [self setupViewHierarchy];
  [self configureViews];
  [self setupAutoLayoutConstraints];

  [self updateTextFieldVisibility];
}

#pragma mark - Helpers for viewDidLoad

// -----------------------------------------------------------------------------
/// @brief Helper for viewDidLoad().
// -----------------------------------------------------------------------------
- (void) setupNavigationItem
{
  NSString* screenTitle = @"Edit game rules";
  self.title = screenTitle;
  self.navigationItem.title = screenTitle;

  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Helper for viewDidLoad().
// -----------------------------------------------------------------------------
- (void) setupItemPickerController
{
  NSMutableArray* itemList = [NSMutableArray array];
  int indexOfDefaultItem = -1;

  enum GoGameInfoRule defaultGameInfoRule = self.gameInfoRules.gameInfoRule;
  for (enum GoGameInfoRule gameInfoRule = GoGameInfoRuleFirst; gameInfoRule <= GoGameInfoRuleLast; ++gameInfoRule)
  {
    NSString* gameInfoRuleString = [NSString stringWithGameInfoRule:gameInfoRule];
    [itemList addObject:gameInfoRuleString];
    if (gameInfoRule == defaultGameInfoRule)
      indexOfDefaultItem = gameInfoRule;
  }

  self.itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                               screenTitle:nil
                                                        indexOfDefaultItem:indexOfDefaultItem
                                                                  delegate:self];
  self.itemPickerController.itemPickerControllerMode = ItemPickerControllerModeNonModal;
  self.itemPickerController.footerTitle = [NSString stringWithFormat:@"Select \"%@\" if you want to enter a rule set name of your own.",
                                           [NSString stringWithGameInfoRule:GoGameInfoRuleSgfString]];
  // User taps on the GoGameInfoRuleSgfString item, then enters someting into
  // the text field, then taps the GoGameInfoRuleSgfString item again, we don't
  // want to get a notification, because we would then set the text field text
  // to nil, deleting the user's entered text.
  self.itemPickerController.notifyDelegateOnlyWhenSelectionChanges = true;
}

// -----------------------------------------------------------------------------
/// @brief Helper for viewDidLoad().
// -----------------------------------------------------------------------------
- (void) createViews
{
  self.contentView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

  self.textFieldStackView = [[[UIStackView alloc] initWithFrame:CGRectZero] autorelease];
  self.textFieldStackView.axis = UILayoutConstraintAxisVertical;

  self.textFieldLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.textField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Helper for viewDidLoad().
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.contentView];

  [self.contentView addSubview:self.textFieldStackView];
  [self.contentView addSubview:self.itemPickerController.view];

  [self.textFieldStackView addArrangedSubview:self.textFieldLabel];
  [self.textFieldStackView addArrangedSubview:self.textField];
}

// -----------------------------------------------------------------------------
/// @brief Helper for viewDidLoad().
// -----------------------------------------------------------------------------
- (void) configureViews
{
  // A background color is required to support UIModalPresentationAutomatic
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

  self.textFieldLabel.text = @"Custom rule set name:";

  [UiUtilities configureTextFieldForTextInput:self.textField];
  self.textField.placeholder = @"Enter a custom rule set name";
  if (self.gameInfoRules.gameInfoRule == GoGameInfoRuleSgfString)
    self.textField.text = self.gameInfoRules.sgfString;

  self.textFieldStackView.spacing = [AutoLayoutUtility verticalSpacingSiblings];
}

// -----------------------------------------------------------------------------
/// @brief Helper for viewDidLoad().
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSafeAreaOfSuperview:self.contentView.superview withSubview:self.contentView];

  self.textFieldStackView.translatesAutoresizingMaskIntoConstraints = NO;
  self.itemPickerController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  viewsDictionary[@"textFieldStackView"] = self.textFieldStackView;
  viewsDictionary[@"itemPickerControllerView"] = self.itemPickerController.view;

  NSMutableArray* visualFormats = [NSMutableArray array];
  [visualFormats addObject:@"H:|-[textFieldStackView]-|"];
  [visualFormats addObject:@"H:|-[itemPickerControllerView]-|"];
  // In an ideal world we would prefer to place the text field below the item
  // picker view, but if we do this then the item picker table view pushes the
  // text field to the bottom of the content view. This is an unsolved layout
  // problem. An attempt to solve the problem resulted in StaticTableView, but
  // ultimately failed - see class documentation of StaticTableView.
  [visualFormats addObject:@"V:|-[textFieldStackView]-[itemPickerControllerView]|"];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.contentView];

  self.textFieldStackViewZeroHeightConstraint = [AutoLayoutUtility setZeroHeightConstraint:self.textFieldStackView
                                                                          constraintHolder:self.contentView];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  self.textField.text = nil;
  [self updateTextFieldVisibility];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  bool didChangeGameInfoRules;
  if (self.itemPickerController.indexOfSelectedItem != self.gameInfoRules.gameInfoRule)
  {
    didChangeGameInfoRules = true;
  }
  else if (self.itemPickerController.indexOfSelectedItem == GoGameInfoRuleSgfString &&
           [self.textField.text isEqualToString:self.gameInfoRules.sgfString])
  {
    didChangeGameInfoRules = false;
  }
  else
  {
    didChangeGameInfoRules = true;
  }

  // The setter that we use updates the other property. Also if a user-entered
  // string happens to match one of the strings pre-defined by the SGF
  // specification, the setSgfString:() setter will change
  // GoGameInfoRuleSgfString to some other enum value. We don't update our
  // UI anymore to cover this case, because we assume that the delegate will
  // dismiss this controller.
  if (self.itemPickerController.indexOfSelectedItem == GoGameInfoRuleSgfString)
    self.gameInfoRules.sgfString = self.textField.text;
  else
    self.gameInfoRules.gameInfoRule = self.itemPickerController.indexOfSelectedItem;

  [self.delegate editGameInfoRulesControllerDidEndEditing:self didChangeGameInfoRules:didChangeGameInfoRules];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled editing.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  bool didChangeGameInfoRules = false;
  [self.delegate editGameInfoRulesControllerDidEndEditing:self didChangeGameInfoRules:didChangeGameInfoRules];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Places the insertion point into the text field if it is currently
/// visible.
// -----------------------------------------------------------------------------
- (void) updateTextFieldVisibility
{
  if (self.itemPickerController.indexOfSelectedItem == GoGameInfoRuleSgfString)
  {
    self.textFieldStackViewZeroHeightConstraint.active = NO;
  }
  else
  {
    self.textFieldStackViewZeroHeightConstraint.active = YES;
  }
//  self.textFieldStackView.hidden = (self.itemPickerController.indexOfSelectedItem != GoGameInfoRuleSgfString
//                                    ? YES
//                                    : NO);
  [self placeInsertionPointIntoTextFieldIfNecessary];
}

// -----------------------------------------------------------------------------
/// @brief Places the insertion point into the text field if it is currently
/// visible.
// -----------------------------------------------------------------------------
- (void) placeInsertionPointIntoTextFieldIfNecessary
{
  if (self.textFieldStackViewZeroHeightConstraint.active == NO)
//  if (! self.textFieldStackView.hidden)
    [self.textField becomeFirstResponder];
}

@end
