// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "EditNodeDescriptionController.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/KeyboardHeightAdjustment.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EditNodeDescriptionController.
// -----------------------------------------------------------------------------
@interface EditNodeDescriptionController()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSString* shortDescription;
@property(nonatomic, retain, readwrite) NSString* longDescription;
//@}
@property(nonatomic, retain) UIView* contentView;
@property(nonatomic, retain) UILabel* shortDescriptionLabel;
@property(nonatomic, retain) UITextField* shortDescriptionTextField;
@property(nonatomic, retain) UILabel* longDescriptionLabel;
@property(nonatomic, retain) UITextView* longDescriptionTextView;
@end


@implementation EditNodeDescriptionController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditNodeDescriptionController
/// instance that is used to edit the short and long description texts
/// @a shortDescription and @a longDescription.
// -----------------------------------------------------------------------------
+ (EditNodeDescriptionController*) controllerWithShortDescription:(NSString*)shortDescription
                                                  longDescription:(NSString*)longDescription
                                                         delegate:(id<EditNodeDescriptionControllerDelegate>)delegate
{
  EditNodeDescriptionController* controller = [[EditNodeDescriptionController alloc] init];
  if (controller)
  {
    [controller autorelease];
    controller.shortDescription = shortDescription;
    controller.longDescription = longDescription;
    controller.delegate = delegate;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditNodeDescriptionController object.
///
/// @note This is the designated initializer of EditNodeDescriptionController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.shortDescription = nil;
  self.longDescription = nil;
  self.delegate = nil;
  self.contentView = nil;
  self.shortDescriptionLabel = nil;
  self.shortDescriptionTextField = nil;
  self.longDescriptionLabel = nil;
  self.longDescriptionTextView = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditNodeDescriptionController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if ([self isObservingKeyboardWithViewToAdjustHeight:self.longDescriptionTextView
                                        referenceView:self.longDescriptionTextView.superview])
  {
    [self endObservingKeyboardWithViewToAdjustHeight:self.longDescriptionTextView
                                       referenceView:self.longDescriptionTextView.superview];
  }
  self.shortDescription = nil;
  self.longDescription = nil;
  self.delegate = nil;
  self.contentView = nil;
  self.shortDescriptionLabel = nil;
  self.shortDescriptionTextField = nil;
  self.longDescriptionLabel = nil;
  self.longDescriptionTextView = nil;
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
  [self setupContentView];
  [self setupShortDescriptionTextField];
  [self setupLongDescriptionTextView];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.shortDescriptionTextField becomeFirstResponder];
}

#pragma mark - Navigation item setup

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the navigation item.
// -----------------------------------------------------------------------------
- (void) setupNavigationItem
{
  NSString* screenTitle = @"Edit node description";
  self.title = screenTitle;
  self.navigationItem.title = screenTitle;

  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)] autorelease];
}

#pragma mark - Content view setup

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the content view.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  self.contentView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

  // A background color is required to support UIModalPresentationAutomatic
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
}

#pragma mark - Setup short description text field

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the short description text field.
// -----------------------------------------------------------------------------
- (void) setupShortDescriptionTextField
{
  self.shortDescriptionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.shortDescriptionLabel.text = @"Short description";

  self.shortDescriptionTextField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
  if (self.shortDescription)
    self.shortDescriptionTextField.text = self.shortDescription;

  self.shortDescriptionTextField.borderStyle = UITextBorderStyleRoundedRect;
  self.shortDescriptionTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
  self.shortDescriptionTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.shortDescriptionTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.shortDescriptionTextField.enablesReturnKeyAutomatically = YES;
  self.shortDescriptionTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  self.shortDescriptionTextField.spellCheckingType = UITextSpellCheckingTypeNo;
}

#pragma mark - Setup long description text view

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the long description text view.
// -----------------------------------------------------------------------------
- (void) setupLongDescriptionTextView
{
  self.longDescriptionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.longDescriptionLabel.text = @"Long description";

  self.longDescriptionTextView = [[[UITextView alloc] initWithFrame:CGRectZero] autorelease];
  if (self.longDescription)
    self.longDescriptionTextView.text = self.longDescription;

  self.longDescriptionTextView.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
}

#pragma mark - View hierarchy setup

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.contentView];
  [self.contentView addSubview:self.shortDescriptionLabel];
  [self.contentView addSubview:self.shortDescriptionTextField];
  [self.contentView addSubview:self.longDescriptionLabel];
  [self.contentView addSubview:self.longDescriptionTextView];
}

#pragma mark - Auto Layout constraints

// -----------------------------------------------------------------------------
/// @brief Main method for setting up Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSafeAreaOfSuperview:self.contentView.superview withSubview:self.contentView];

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.shortDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.shortDescriptionTextField.translatesAutoresizingMaskIntoConstraints = NO;
  self.longDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.longDescriptionTextView.translatesAutoresizingMaskIntoConstraints = NO;
  viewsDictionary[@"shortDescriptionLabel"] = self.shortDescriptionLabel;
  viewsDictionary[@"shortDescriptionTextField"] = self.shortDescriptionTextField;
  viewsDictionary[@"longDescriptionLabel"] = self.longDescriptionLabel;
  viewsDictionary[@"longDescriptionTextView"] = self.longDescriptionTextView;
  [visualFormats addObject:@"H:|-[shortDescriptionLabel]-|"];
  [visualFormats addObject:@"H:|-[shortDescriptionTextField]-|"];
  [visualFormats addObject:@"H:|-[longDescriptionLabel]-|"];
  [visualFormats addObject:@"H:|-[longDescriptionTextView]-|"];
  // Important: Don't attach the bottom of longDescriptionTextView! This is
  // managed by KeyboardHeightAdjustment.
  [visualFormats addObject:@"V:|-[shortDescriptionLabel]-[shortDescriptionTextField]-[longDescriptionLabel]-[longDescriptionTextView]"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.shortDescriptionLabel.superview];

  // If this controller is presented in a popover then we assume that we are
  // on iPadOS and that the OS will automatically adjust the popover size or
  // location to accomodate the keyboard when it appears.
  if (self.popoverPresentationController)
  {
    [viewsDictionary removeAllObjects];
    [visualFormats removeAllObjects];
    viewsDictionary[@"longDescriptionTextView"] = self.longDescriptionTextView;
    [visualFormats addObject:@"V:[longDescriptionTextView]-|"];
    [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.longDescriptionTextView.superview];
  }
  else
  {
    [self beginObservingKeyboardWithViewToAdjustHeight:self.longDescriptionTextView
                                         referenceView:self.longDescriptionTextView.superview];
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished entering an estimated score.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  NSString* newShortDescription = (self.shortDescriptionTextField.text.length > 0) ? self.shortDescriptionTextField.text : nil;
  NSString* newLongDescription = (self.longDescriptionTextView.text.length > 0) ? self.longDescriptionTextView.text : nil;

  bool didChangeDescriptions;
  if ([NSString nullableString:newShortDescription isEqualToNullableString:self.shortDescription] &&
      [NSString nullableString:newLongDescription isEqualToNullableString:self.longDescription])
  {
    didChangeDescriptions = false;
  }
  else
  {
    didChangeDescriptions = true;
    self.shortDescription = newShortDescription;
    self.longDescription = newLongDescription;
  }

  [self.delegate editNodeDescriptionControllerDidEndEditing:self didChangeDescriptions:didChangeDescriptions];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled entering an estimated score.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  bool didChangeDescriptions = false;
  [self.delegate editNodeDescriptionControllerDidEndEditing:self didChangeDescriptions:didChangeDescriptions];
}

@end
