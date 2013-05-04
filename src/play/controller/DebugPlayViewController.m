// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "DebugPlayViewController.h"
#import "../playview/PlayView.h"
#import "../model/PlayViewModel.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/UiElementMetrics.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for DebugPlayViewController.
// -----------------------------------------------------------------------------
@interface DebugPlayViewController()
@property(nonatomic, retain) UITextField* normalLineWidthTextField;
@property(nonatomic, retain) UITextField* boundingLineWidthTextField;
@property(nonatomic, retain) UITextField* starPointRadiusTextField;
@property(nonatomic, retain) UITextField* stoneRadiusPercentageTextField;
@end


@implementation DebugPlayViewController

// -----------------------------------------------------------------------------
/// @brief Initializes an DebugPlayViewController object.
///
/// @note This is the designated initializer of DebugPlayViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.normalLineWidthTextField = nil;
  self.boundingLineWidthTextField = nil;
  self.starPointRadiusTextField = nil;
  self.stoneRadiusPercentageTextField = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DebugPlayViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.normalLineWidthTextField = nil;
  self.boundingLineWidthTextField = nil;
  self.starPointRadiusTextField = nil;
  self.stoneRadiusPercentageTextField = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  static const int textFieldCount = 5;
  CGFloat viewFrameX = [UiElementMetrics spacingHorizontal];
  CGFloat viewFrameY = [UiElementMetrics spacingVertical];
  CGFloat viewFrameWidth = 200;  // sufficient width for one text field
  CGFloat viewFrameHeight = (textFieldCount * [UiElementMetrics textFieldHeight]
                             + (textFieldCount - 1) * [UiElementMetrics spacingVertical]);
  CGRect viewFrame = CGRectMake(viewFrameX, viewFrameY, viewFrameWidth, viewFrameHeight);
  self.view = [[[UIView alloc] initWithFrame:viewFrame] autorelease];

  CGRect textFieldFrame = CGRectMake(0, 0, viewFrameWidth, [UiElementMetrics textFieldHeight]);
  for (int textFieldIndex = 0; textFieldIndex < textFieldCount; ++textFieldIndex)
  {
    UITextField* textField = [self createTextFieldWithFrame:textFieldFrame];

    NSString* placeHolderString;
    if (0 == textFieldIndex)
    {
      self.normalLineWidthTextField = textField;
      placeHolderString = @"NormalLineWidth";
    }
    else if (1 == textFieldIndex)
    {
      self.boundingLineWidthTextField = textField;
      placeHolderString = @"BoundingLineWidth";
    }
    else if (2 == textFieldIndex)
    {
      self.starPointRadiusTextField = textField;
      placeHolderString = @"StarPointRadius";
    }
    else if (3 == textFieldIndex)
    {
      self.stoneRadiusPercentageTextField = textField;
      placeHolderString = @"StoneRadiusPercentage";
    }

    textField.placeholder = placeHolderString;
    textFieldFrame.origin.y += textFieldFrame.size.height + [UiElementMetrics spacingVertical];
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a new UITextField object.
///
/// The text field is added to the DebugPlayViewController root view using
/// @a textFieldFrame. In addition the text field is set up with useful default
/// property values that make it usable for display.
// -----------------------------------------------------------------------------
- (UITextField*) createTextFieldWithFrame:(CGRect)textFieldFrame
{
  UITextField* textField = [[[UITextField alloc] initWithFrame:textFieldFrame] autorelease];
  [self.view addSubview:textField];
  textField.delegate = self;

  textField.borderStyle = UITextBorderStyleRoundedRect;
  textField.textColor = [UIColor slateBlueColor];
  textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  textField.autocorrectionType = UITextAutocorrectionTypeNo;
  textField.enablesReturnKeyAutomatically = YES;
  textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

  return textField;
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldReturn:(UITextField*)aTextField
{
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  PlayViewModel* playViewModel = delegate.playViewModel;

  bool valueChanged = false;
  int newIntValue = [aTextField.text intValue];
  float newFloatValue = [aTextField.text floatValue];
  if (newIntValue > 0 || newFloatValue > 0.0)
  {
    valueChanged = true;
    if (aTextField == self.normalLineWidthTextField)
      playViewModel.normalLineWidth = newIntValue;
    if (aTextField == self.boundingLineWidthTextField)
      playViewModel.boundingLineWidth = newIntValue;
    if (aTextField == self.starPointRadiusTextField)
      playViewModel.starPointRadius = newIntValue;
    if (aTextField == self.stoneRadiusPercentageTextField)
      playViewModel.stoneRadiusPercentage = newFloatValue;
  }

  if (valueChanged)
  {
    PlayView* playView = [PlayView sharedView];
    [playView setNeedsLayout];  // dummy update to force a complete redraw
  }

  return YES;
}

@end
