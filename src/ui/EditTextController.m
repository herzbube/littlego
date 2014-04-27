// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "EditTextController.h"
#import "../ui/AutoLayoutUtility.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for EditTextController.
// -----------------------------------------------------------------------------
@interface EditTextController()
@property(nonatomic, retain) UITextField* textField;
@property(nonatomic, retain) UITextView* textView;
@property(nonatomic, assign) UIResponder* firstResponderWhenViewWillAppear;
@property(nonatomic, retain) NSLayoutConstraint* textViewHeightConstraint;
@end


@implementation EditTextController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditTextController instance of
/// grouped style that is used to edit @a text.
// -----------------------------------------------------------------------------
+ (EditTextController*) controllerWithText:(NSString*)text style:(enum EditTextControllerStyle)style delegate:(id<EditTextDelegate>)delegate
{
  EditTextController* controller = [[EditTextController alloc] init];
  if (controller)
  {
    [controller autorelease];
    controller.editTextControllerStyle = style;
    controller.delegate = delegate;
    controller.text = text;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an EditTextController object.
///
/// @note This is the designated initializer of EditTextController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.textField = nil;
  self.textView = nil;
  self.firstResponderWhenViewWillAppear = nil;
  self.textViewHeightConstraint = nil;
  self.context = nil;
  self.editTextControllerStyle = EditTextControllerStyleTextField;
  self.keyboardType = UIKeyboardTypeDefault;
  self.delegate = nil;
  self.text = nil;
  self.placeholder = nil;
  self.acceptEmptyText = false;
  self.textHasChanged = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditTextController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.textField = nil;
  self.textView = nil;
  self.firstResponderWhenViewWillAppear = nil;
  self.textViewHeightConstraint = nil;
  self.context = nil;
  self.delegate = nil;
  self.text = nil;
  self.placeholder = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self setupNavigationItem];
  switch (self.editTextControllerStyle)
  {
    case EditTextControllerStyleTextField:
    {
      [self setupTextField];
      self.firstResponderWhenViewWillAppear = self.textField;
      break;
    }
    case EditTextControllerStyleTextView:
    {
      [self setupTextView];
      self.firstResponderWhenViewWillAppear = self.textView;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"EditTextControllerStyle is invalid: %d", self.editTextControllerStyle];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  // Place the insertion point into the text field or text view
  [self.firstResponderWhenViewWillAppear becomeFirstResponder];
}

#pragma mark - Setup text field

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupTextField
{
  self.textField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.textField];
  [self setupTextFieldAutoLayoutConstraints];
  [self configureTextField];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupTextFieldAutoLayoutConstraints
{
  self.textField.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.textField, @"textField",
                                   self.topLayoutGuide, @"topLayoutGuide",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-[textField]-|",
                            @"V:[topLayoutGuide]-[textField]",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) configureTextField
{
  self.textField.borderStyle = UITextBorderStyleRoundedRect;
  self.textField.textColor = [UIColor slateBlueColor];
  self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.textField.enablesReturnKeyAutomatically = YES;
  self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  self.textField.spellCheckingType = UITextSpellCheckingTypeNo;

  self.textField.delegate = self;
  self.textField.text = self.text;
  self.textField.placeholder = self.placeholder;
  self.textField.keyboardType = self.keyboardType;
}

#pragma mark - Setup text view

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupTextView
{
  self.textView = [[[UITextView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.textView];
  [self setupTextViewAutoLayoutConstraints];
  [self configureTextView];
  [self setupNotificationResponders];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupTextViewAutoLayoutConstraints
{
  self.textView.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.textView, @"textView",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|[textView]|",
                            // The VC's automaticallyAdjustsScrollViewInsets
                            // property adjusts the top so that we don't have
                            // to align to self.topLayoutGuide. Also note that
                            // the textView bottom is handled by additional
                            // constraints below.
                            @"V:|[textView]",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.view];

  // ----------------------------------------
  // Precondition for the following constraints to work: We expect that this VC
  // is presented modally in a nagivation controller, so this VC's root view
  // should extend to the bottom of the screen to where the keyboard pops up
  // from. Also, self.bottomLayoutGuide can be disregarded.
  // ----------------------------------------

  // Constraint that allows the text view to extend its bottom down to the
  // bottom of this VC's root view. This constraint is permanently installed.
  // It has a low priority so that it can be overridden by the second, optional
  // constraint that is active only while the keyboard is displayed.
  // Note: Although the visual format string for this constraint is quite
  // simple ("V:[textView]|"), we can't use the visual format API because it
  // does not allow us to set a priority for the constraint.
  NSLayoutConstraint* textViewHeightConstraintLowPriority = [NSLayoutConstraint constraintWithItem:self.textView
                                                                                         attribute:NSLayoutAttributeBottom
                                                                                         relatedBy:NSLayoutRelationEqual
                                                                                            toItem:self.view
                                                                                         attribute:NSLayoutAttributeBottom
                                                                                        multiplier:1.0f
                                                                                          constant:0];
  textViewHeightConstraintLowPriority.priority = UILayoutPriorityDefaultLow;
  [self.view addConstraint:textViewHeightConstraintLowPriority];

  // Constraint that allows the text view to extend its bottom down to the top
  // of the keyboard. This constraint is not installed yet. It will be
  // dynamically installed/uninstalled whenever the keyboard is shown/hidden.
  // While this constraint is installed, it will take precedence over the
  // low-priority constraint that we created above.
  self.textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.textView
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0f
                                                                constant:0];
  self.textViewHeightConstraint.priority = UILayoutPriorityDefaultHigh;
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) configureTextView
{
  self.textView.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  self.textView.textColor = [UIColor slateBlueColor];

  self.textView.delegate = self;
  self.textView.text = self.text;
  self.textView.keyboardType = self.keyboardType;
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup other view stuff

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupNavigationItem
{
  [super viewDidLoad];
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)] autorelease];

  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:self.text];
}

#pragma mark - Adjust text view size when keyboard appears/disappears

// -----------------------------------------------------------------------------
/// @brief Responds to the keyboard being shown. Calculates the proper constant
/// for @e self.textViewHeightConstraint and installs the constraint, thus
/// forcing @e self.textView to become smaller.
// -----------------------------------------------------------------------------
- (void) keyboardWillShow:(NSNotification*)notification
{
  NSDictionary* userInfo = [notification userInfo];

  // The frame we get from the notification is in screen coordinates where width
  // and height might be swapped depending on the current interface orientation.
  // We invoke convertRect:fromView: in order to translate the frame into our
  // view coordinates. This translation resolves all interface orientation
  // complexities for us.
  NSValue* keyboardFrameAsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGRect keyboardFrame = [keyboardFrameAsValue CGRectValue];
  keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
  CGFloat distanceFromViewBottom = keyboardFrame.size.height;

  // Constraint that allows the text view to extend its bottom down to the top
  // of the keyboard. This constraint is not installed yet. It will be
  // dynamically installed/uninstalled whenever the keyboard is shown/hidden.
  // While this constraint is installed, it will take precedence over the
  // low-priority constraint that we created above.
  self.textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.textView
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0f
                                                                constant:0];
  self.textViewHeightConstraint.priority = UILayoutPriorityDefaultHigh;


  // We make distanceFromViewBottom negative for the constraint because we want
  // to express the difference of the bottom of the two views.
  self.textViewHeightConstraint.constant = -distanceFromViewBottom;

  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  [UIView animateWithDuration:animationDuration animations:^{
    [self.view addConstraint:self.textViewHeightConstraint];
    [self.view layoutIfNeeded];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the keyboard being hidden. Removes
/// @e self.textViewHeightConstraint, thus allowing @e self.textView to become
/// bigger.
// -----------------------------------------------------------------------------
- (void) keyboardWillHide:(NSNotification*)notification
{
  NSDictionary* userInfo = [notification userInfo];
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  [UIView animateWithDuration:animationDuration animations:^{
    [self.view removeConstraint:self.textViewHeightConstraint];
    self.textViewHeightConstraint = nil;
    [self.view layoutIfNeeded];
  }];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished editing the text.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  NSString* textFromControl = nil;
  if (EditTextControllerStyleTextField == self.editTextControllerStyle)
    textFromControl = self.textField.text;
  else
    textFromControl = self.textView.text;
  if (! [self.delegate controller:self shouldEndEditingWithText:textFromControl])
    return;
  self.textHasChanged = ! [self.text isEqualToString:textFromControl];
  self.text = textFromControl;
  [self.delegate didEndEditing:self didCancel:false];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled editing the text.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate didEndEditing:self didCancel:true];
}

#pragma mark - UITextFieldDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
///
/// An alternative to using the delegate protocol is to listen for notifications
/// sent by the text field.
// -----------------------------------------------------------------------------
- (BOOL) textField:(UITextField*)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
  // Compose the string as it would look like if the proposed change had already
  // been made
  NSString* newText = [aTextField.text stringByReplacingCharactersInRange:range withString:string];
  // Make sure that, if the text is not acceptable input, the view cannot be
  // left except by cancelling
  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:newText];
  // Accept all changes, even those that make the text not acceptable input
  // -> the user must simply continue editing until the text becomes acceptable
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldClear:(UITextField*)aTextField
{
  self.navigationItem.rightBarButtonItem.enabled = NO;
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldReturn:(UITextField*)aTextField
{
  if (! [self isTextAcceptable:self.textField.text])
    return NO;
  [self done:nil];
  return YES;
}

#pragma mark - UITextViewdDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITextViewdDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) textViewDidChange:(UITextView*)aTextView
{
  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:aTextView.text];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if @a text is acceptable as valid input.
// -----------------------------------------------------------------------------
- (bool) isTextAcceptable:(NSString*)aText
{
  if (self.acceptEmptyText)
    return true;
  return (aText.length > 0);
}

@end
