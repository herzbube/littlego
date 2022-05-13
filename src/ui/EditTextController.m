// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
@property(nonatomic, assign) UIView* contentView;
@property(nonatomic, retain) UITextField* textField;
@property(nonatomic, retain) UITextView* textView;
@property(nonatomic, retain) UILabel* validationErrorLabel;
@property(nonatomic, assign) UIResponder* firstResponderWhenViewWillAppear;
@property(nonatomic, retain) NSLayoutConstraint* textViewHeightConstraint;
@property(nonatomic, assign) CGFloat validTextBorderWidth;
@property(nonatomic, retain) UIColor* validTextBorderColor;
@property(nonatomic, assign) CGFloat invalidTextBorderWidth;
@property(nonatomic, retain) UIColor* inValidTextBorderColor;
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

  self.contentView = nil;
  self.textField = nil;
  self.textView = nil;
  self.validationErrorLabel = nil;
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
  self.validTextBorderWidth = 0.0f;
  self.validTextBorderColor = nil;
  self.invalidTextBorderWidth = 0.5f;
  self.inValidTextBorderColor = [UIColor redColor];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditTextController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.contentView = nil;
  self.textField = nil;
  self.textView = nil;
  self.validationErrorLabel = nil;
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
  [super loadView];

  self.contentView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.contentView];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSafeAreaOfSuperview:self.view withSubview:self.contentView];

  self.validationErrorLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  [self.contentView addSubview:self.validationErrorLabel];
  self.validationErrorLabel.textColor = [UIColor redColor];
  self.validationErrorLabel.numberOfLines = 0;

  // A background color is required to support UIModalPresentationAutomatic
  self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

  [self setupNavigationItem];
  switch (self.editTextControllerStyle)
  {
    case EditTextControllerStyleTextField:
    {
      [self setupTextField];
      self.firstResponderWhenViewWillAppear = self.textField;
      self.validTextBorderWidth = self.textField.layer.borderWidth;
      self.validTextBorderColor = [UIColor colorWithCGColor:self.textField.layer.borderColor];
      break;
    }
    case EditTextControllerStyleTextView:
    {
      [self setupTextView];
      self.firstResponderWhenViewWillAppear = self.textView;
      self.validTextBorderWidth = self.textView.layer.borderWidth;
      self.validTextBorderColor = [UIColor colorWithCGColor:self.textView.layer.borderColor];
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

  [self validateText:self.text];
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
  [self.contentView addSubview:self.textField];
  [self setupTextFieldAutoLayoutConstraints];
  [self configureTextField];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) setupTextFieldAutoLayoutConstraints
{
  self.textField.translatesAutoresizingMaskIntoConstraints = NO;
  self.validationErrorLabel.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.textField, @"textField",
                                   self.validationErrorLabel, @"validationErrorLabel",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-[textField]-|",
                            @"H:|-[validationErrorLabel]-|",
                            @"V:|-[textField]-[validationErrorLabel]",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.contentView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) configureTextField
{
  self.textField.borderStyle = UITextBorderStyleRoundedRect;
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
  [self.contentView addSubview:self.textView];
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
  self.validationErrorLabel.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.textView, @"textView",
                                   self.validationErrorLabel, @"validationErrorLabel",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-[textView]-|",
                            @"H:|-[validationErrorLabel]-|",
                            @"V:|-[textView]-[validationErrorLabel]",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.contentView];

  // Constraint that allows the text view to extend its bottom down to the
  // bottom of the content view. This constraint is permanently installed.
  // It has a low priority so that it can be overridden by the second, optional
  // constraint that is active only while the keyboard is displayed.
  // Note: Although the visual format string for this constraint is quite
  // simple ("V:[textView]-|"), we can't use the visual format API because it
  // does not allow us to set a priority for the constraint.
  NSLayoutConstraint* textViewHeightConstraintLowPriority = [NSLayoutConstraint constraintWithItem:self.validationErrorLabel
                                                                                         attribute:NSLayoutAttributeBottom
                                                                                         relatedBy:NSLayoutRelationEqual
                                                                                            toItem:self.contentView.layoutMarginsGuide
                                                                                         attribute:NSLayoutAttributeBottom
                                                                                        multiplier:1.0f
                                                                                          constant:0];
  textViewHeightConstraintLowPriority.priority = UILayoutPriorityDefaultLow;
  [self.contentView addConstraint:textViewHeightConstraintLowPriority];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) configureTextView
{
  self.textView.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];

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
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)] autorelease];
}

#pragma mark - Adjust text view size when keyboard appears/disappears

// -----------------------------------------------------------------------------
/// @brief Responds to the keyboard being shown. Creates a high-priority
/// Auto Layout constraint that overrides the default constraint for defining
/// the height of @e self.textView. The new constraint forces @e self.textView
/// to become smaller to make room for the keyboard.
// -----------------------------------------------------------------------------
- (void) keyboardWillShow:(NSNotification*)notification
{
  // keyboardWillShow is sometimes invoked multiple times without a
  // balancing keyboardWillHide in between
  if (self.textViewHeightConstraint)
    [self removeTextViewHeightConstraint];

  NSDictionary* userInfo = [notification userInfo];

  // The frame we get from the notification is in screen coordinates where width
  // and height might be swapped depending on the current interface orientation.
  // We invoke convertRect:fromView: in order to translate the frame into our
  // view coordinates. This translation resolves all interface orientation
  // complexities for us.
  NSValue* keyboardFrameAsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGRect keyboardFrame = [keyboardFrameAsValue CGRectValue];
  keyboardFrame = [self.contentView convertRect:keyboardFrame fromView:nil];
  CGFloat distanceFromViewBottom = keyboardFrame.size.height;

  // Constraint that allows the text view to extend its bottom down to the top
  // of the keyboard. The validation error label resists vertical expansion
  // more than the text view, so the text view will get the height.
  self.textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.validationErrorLabel
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.contentView.layoutMarginsGuide
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0f
                                                                constant:0];
  // The constraint uses the negative of distanceFromViewBottom because we want
  // to express the **difference** of the bottom of the two views involved in
  // the constraint (self.textView and self.contentView). In order for this to
  // work, the content view must extend to the bottom of the screen to where
  // the keyboard pops up from. This should be the case if this VC is presented
  // modally in a nagivation controller.
  self.textViewHeightConstraint.constant = -distanceFromViewBottom;
  // While this constraint is installed, it will take precedence over the
  // low-priority constraint that was permanently installed in
  // setupTextViewAutoLayoutConstraints()
  self.textViewHeightConstraint.priority = UILayoutPriorityDefaultHigh;

  NSNumber* animationDurationAsNumber = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
  NSTimeInterval animationDuration = [animationDurationAsNumber doubleValue];
  [UIView animateWithDuration:animationDuration animations:^{
    [self.contentView addConstraint:self.textViewHeightConstraint];
    [self.contentView layoutIfNeeded];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the keyboard being hidden. Removes the high-priority
/// Auto layout constraint created by keyboardWillShow:(). @e self.textView is
/// allowed to become bigger to take up the room freed by the disappearance of
/// the keyboard.
// -----------------------------------------------------------------------------
- (void) keyboardWillHide:(NSNotification*)notification
{
  // keyboardWillHide is sometimes invoked multiple times although
  // keyboardWillShow has been invoked only once
  if (!self.textViewHeightConstraint)
    return;

  NSDictionary* userInfo = [notification userInfo];
  NSNumber* animationDurationAsNumber = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
  NSTimeInterval animationDuration = [animationDurationAsNumber doubleValue];
  [UIView animateWithDuration:animationDuration animations:^{
    [self removeTextViewHeightConstraint];
    [self.contentView layoutIfNeeded];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Private helper that removes self.textViewHeightConstraint.
// -----------------------------------------------------------------------------
- (void) removeTextViewHeightConstraint
{
  [self.contentView removeConstraint:self.textViewHeightConstraint];
  self.textViewHeightConstraint = nil;
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
  [self validateText:newText];
  // Accept all changes, even those that make the text not acceptable input
  // -> the user must simply continue editing until the text becomes acceptable
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldClear:(UITextField*)aTextField
{
  NSString* newText = @"";
  [self validateText:newText];
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldReturn:(UITextField*)aTextField
{
  bool isTextValid = [self validateText:self.textField.text];
  if (! isTextValid)
    return NO;
  [self done:nil];
  return YES;
}

#pragma mark - UITextViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITextViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) textViewDidChange:(UITextView*)aTextView
{
  [self validateText:aTextView.text];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if @a text is a valid input. As a side effect, updates
/// the UI to reflect the result of the validation.
// -----------------------------------------------------------------------------
- (bool) validateText:(NSString*)text
{
  bool isTextValid;
  NSString* validationErrorMessage;

  SEL selector = @selector(controller:isTextValid:validationErrorMessage:);
  if ([self.delegate respondsToSelector:selector])
  {
    // Initialize in case the delegate does not set anything
    validationErrorMessage = nil;
    
    isTextValid = [self.delegate controller:self
                                isTextValid:text
                     validationErrorMessage:&validationErrorMessage];
  }
  else
  {
    // The only error that can occur is an empty text. Applying a colored border
    // to the input control should be sufficient as an indicator.
    validationErrorMessage = nil;

    if (self.acceptEmptyText)
      isTextValid = true;
    else
      isTextValid = (text.length > 0);
  }

  CGFloat borderWith;
  UIColor* borderColor;
  if (isTextValid)
  {
    borderWith = self.validTextBorderWidth;
    borderColor = self.validTextBorderColor;
  }
  else
  {
    borderWith = self.invalidTextBorderWidth;
    borderColor = self.inValidTextBorderColor;
  }

  if (EditTextControllerStyleTextField == self.editTextControllerStyle)
  {
    self.textField.layer.borderWidth = borderWith;
    self.textField.layer.borderColor = borderColor.CGColor;
  }
  else
  {
    self.textView.layer.borderWidth = borderWith;
    self.textView.layer.borderColor = borderColor.CGColor;
  }

  self.validationErrorLabel.text = isTextValid ? nil : validationErrorMessage;
  self.navigationItem.rightBarButtonItem.enabled = isTextValid ? YES : NO;
  return isTextValid;
}

@end
