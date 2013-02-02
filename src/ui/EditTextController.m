// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"
#import "../utility/UIColorAdditions.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for EditTextController.
// -----------------------------------------------------------------------------
@interface EditTextController()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) loadView;
- (void) viewDidLoad;
- (void) viewWillAppear:(BOOL)animated;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name Action methods
//@{
- (void) done:(id)sender;
- (void) cancel:(id)sender;
//@}
/// @name UITextFieldDelegate protocol method.
//@{
- (BOOL) textField:(UITextField*)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
- (BOOL) textFieldShouldClear:(UITextField*)aTextField;
- (BOOL) textFieldShouldReturn:(UITextField*)aTextField;
//@}
/// @name UITextViewDelegate protocol method.
//@{
- (void) textViewDidChange:(UITextView*)aTextView;
//@}
/// @name Helpers
//@{
- (bool) isTextAcceptable:(NSString*)aText;
//@}
/// @name Privately declared property
//@{
@property(nonatomic, retain) UITextField* textField;
@property(nonatomic, retain) UITextView* textView;
//@}
@end


@implementation EditTextController

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
  self = [super init];
  if (! self)
    return nil;

  self.textField = nil;
  self.textView = nil;
  self.context = nil;
  self.editTextControllerStyle = EditTextControllerStyleTextField;
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
  self.textField = nil;
  self.textView = nil;
  self.context = nil;
  self.delegate = nil;
  self.text = nil;
  self.placeholder = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  int mainViewX = 0;
  int mainViewY = 0;
  int mainViewWidth = [UiElementMetrics screenWidth];
  int mainViewHeight = ([UiElementMetrics screenHeight]
                        - [UiElementMetrics tabBarHeight]
                        - [UiElementMetrics navigationBarHeight]
                        - [UiElementMetrics statusBarHeight]);
  CGRect mainViewFrame = CGRectMake(mainViewX, mainViewY, mainViewWidth, mainViewHeight);
  self.view = [[[UIView alloc] initWithFrame:mainViewFrame] autorelease];


  [UiUtilities addGroupTableViewBackgroundToView:self.view];
  switch (self.editTextControllerStyle)
  {
    case EditTextControllerStyleTextField:
    {
      int textFieldX = [UiElementMetrics tableViewCellMarginHorizontal];
      int textFieldY = [UiElementMetrics tableViewMarginVertical];
      int textFieldWidth = self.view.bounds.size.width - 2 * textFieldX;
      int textFieldHeight = [UiElementMetrics textFieldHeight];
      CGRect textFieldRect = CGRectMake(textFieldX, textFieldY, textFieldWidth, textFieldHeight);
      self.textField = [[[UITextField alloc] initWithFrame:textFieldRect] autorelease];
      [self.view addSubview:self.textField];

      self.textField.borderStyle = UITextBorderStyleRoundedRect;
      self.textField.textColor = [UIColor slateBlueColor];
      self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
      self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
      self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
      self.textField.enablesReturnKeyAutomatically = YES;
      self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
      self.textField.spellCheckingType = UITextSpellCheckingTypeNo;

      self.textField.delegate = self;
      self.textField.text = self.text;
      self.textField.placeholder = self.placeholder;
      break;
    }
    case EditTextControllerStyleTextView:
    {
      int textViewX = [UiElementMetrics tableViewCellMarginHorizontal];
      int textViewY = [UiElementMetrics tableViewMarginVertical];
      int textViewWidth = self.view.bounds.size.width - 2 * textViewX;
      // Use up only half of the available height to leave room for the keyboard
      int textViewHeight = (self.view.bounds.size.height - 2 * textViewY) / 2;
      CGRect textViewRect = CGRectMake(textViewX, textViewY, textViewWidth, textViewHeight);
      self.textView = [[[UITextView alloc] initWithFrame:textViewRect] autorelease];
      [self.view addSubview:self.textView];

      self.textView.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];  // remove bold'ness
      self.textView.textColor = [UIColor slateBlueColor];
      self.textView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
      self.textView.contentInset = UIEdgeInsetsMake([UiElementMetrics tableViewCellContentDistanceFromEdgeVertical],
                                                    [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal],
                                                    [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical],
                                                    [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal]);

      self.textView.layer.borderColor = [UIColor whiteColor].CGColor;
      self.textView.layer.borderWidth = 2.3;
      self.textView.layer.cornerRadius = 15;
      self.textView.clipsToBounds = YES;
      
      self.textView.delegate = self;
      self.textView.text = self.text;
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                        target:self
                                                                                        action:@selector(cancel:)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(done:)];

  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:self.text];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the view is about to made visible.
// -----------------------------------------------------------------------------
- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  // Place the insertion point into the text field
  [self.textField becomeFirstResponder];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

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

// -----------------------------------------------------------------------------
/// @brief Returns true if @a text is acceptable as valid input.
// -----------------------------------------------------------------------------
- (bool) isTextAcceptable:(NSString*)aText
{
  if (self.acceptEmptyText)
    return true;
  return (aText.length > 0);
}

// -----------------------------------------------------------------------------
/// @brief UITextViewdDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) textViewDidChange:(UITextView*)aTextView
{
  self.navigationItem.rightBarButtonItem.enabled = [self isTextAcceptable:aTextView.text];
}

@end
