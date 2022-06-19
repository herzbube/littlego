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
#import "HandleMarkupEditingInteractionCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../../play/model/MarkupModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeMarkup.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/ExceptionUtility.h"

// C++ standard library
#include <set>
#include <utility>  // for std::pair
#include <vector>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// HandleMarkupEditingInteractionCommand.
// -----------------------------------------------------------------------------
@interface HandleMarkupEditingInteractionCommand()
@property(nonatomic, retain) GoPoint* point;
@property(nonatomic, retain) GoPoint* startPoint;
@property(nonatomic, retain) GoPoint* endPoint;
@end


// First invocation of the HandleMarkupEditingInteractionCommand initializer
// will initialize these static variables.
static unichar charUppercaseA = 0;
static unichar charuppercaseZ = 0;
static unichar charLowercaseA = 0;
static unichar charLowercaseZ = 0;
static unichar charZero = 0;
static unichar charNine = 0;
static int minimumNumberMarkerValue = 0;
static int maximumNumberMarkerValue = 0;
static std::vector<std::pair<char, char> > letterMarkerValueRanges;


@implementation HandleMarkupEditingInteractionCommand

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes static variables if they have not yet been initialized.
// -----------------------------------------------------------------------------
+ (void) setupStaticVariablesIfNotYetSetup
{
  if (charUppercaseA != 0)
    return;

  charUppercaseA = [@"A" characterAtIndex:0];
  charuppercaseZ = [@"Z" characterAtIndex:0];
  charLowercaseA = [@"a" characterAtIndex:0];
  charLowercaseZ = [@"z" characterAtIndex:0];
  charZero = [@"0" characterAtIndex:0];
  charNine = [@"9" characterAtIndex:0];
  minimumNumberMarkerValue = 1;
  maximumNumberMarkerValue = 999;
  letterMarkerValueRanges.push_back(std::make_pair('A', 'Z'));
  letterMarkerValueRanges.push_back(std::make_pair('a', 'z'));
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object.
///
/// @note This is the designated initializer of
/// HandleMarkupEditingInteractionCommand.
// -----------------------------------------------------------------------------
- (id) initWithPoint:(GoPoint*)point
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  [HandleMarkupEditingInteractionCommand setupStaticVariablesIfNotYetSetup];

  self.point = point;
  self.startPoint = nil;
  self.endPoint = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object.
// -----------------------------------------------------------------------------
- (id) initWithStartPoint:(GoPoint*)startPoint endPoint:(GoPoint*)endPoint
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  [HandleMarkupEditingInteractionCommand setupStaticVariablesIfNotYetSetup];

  self.point = nil;
  self.startPoint = startPoint;
  self.endPoint = endPoint;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// HandleMarkupEditingInteractionCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.point = nil;
  self.startPoint = nil;
  self.endPoint = nil;

  [super dealloc];
}

#pragma mark - CommandBase methods

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! self.point && ! (self.startPoint && self.endPoint))
  {
    DDLogError(@"%@: Unable to handle markup interaction because neither a single point nor a start/end point pair is set", self);
    return false;
  }

  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  int currentBoardPosition = boardPosition.currentBoardPosition;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode != UIAreaPlayModeEditMarkup)
  {
    // Alas, defensive programming. Cf. HandleBoardSetupInteractionCommand,
    // although the scenarios handled there should not be possible for markup
    // editing because markup editing does not involve showing an alert.
    [self showAlertNotInMarkupEditingMode:currentBoardPosition];
    return false;
  }

  if (currentBoardPosition == 0)
  {
    // Alas, defensive programming. Cf. HandleBoardSetupInteractionCommand,
    // although the scenarios handled there should not be possible for markup
    // editing because markup editing does not involve showing an alert.
    [self showAlertOnBoardPositionZero];
    return false;
  }

  GoNode* currentNode = boardPosition.currentNode;
  GoNodeMarkup* nodeMarkup = currentNode.goNodeMarkup;
  if (! nodeMarkup)
  {
    nodeMarkup = [[[GoNodeMarkup alloc] init] autorelease];
    currentNode.goNodeMarkup = nodeMarkup;
  }

  MarkupModel* markupModel = [ApplicationDelegate sharedDelegate].markupModel;
  if (self.point)
  {
    if (markupModel.markupTool == MarkupToolLabel)
    {
      [self handleEnterNewLabelTextOnPoint:self.point
                           withMarkupModel:markupModel
                                      node:currentNode];
    }
    else
    {
      [self handleMarkupEditingInteractionOnPoint:self.point
                              optionalSecondPoint:nil
                                  withMarkupModel:markupModel
                                        labelText:nil
                                             node:currentNode];
    }
  }
  else
  {
    [self handleMarkupEditingInteractionOnPoint:self.startPoint
                            optionalSecondPoint:self.endPoint
                                withMarkupModel:markupModel
                                      labelText:nil
                                           node:currentNode];
  }

  return true;
}

#pragma mark - Helpers for doIt

// -----------------------------------------------------------------------------
/// @brief Performs the actual markup editing interaction handling. Is called
/// both from doIt() and after the user entered a new label text when the
/// markup tool is #MarkupToolLabel.
// -----------------------------------------------------------------------------
- (void) handleMarkupEditingInteractionOnPoint:(GoPoint*)point
                           optionalSecondPoint:(GoPoint*)secondPoint
                               withMarkupModel:(MarkupModel*)markupModel
                                     labelText:(NSString*)labelText
                                          node:(GoNode*)node
{
  bool applicationStateDidChange = false;

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];

    NSString* intersection = point.vertex.string;
    GoNodeMarkup* nodeMarkup = node.goNodeMarkup;

    NSArray* pointsWithChangedMarkup = nil;

    switch (markupModel.markupTool)
    {
      case MarkupToolSymbol:
      {
        bool markupDataDidChange = [self handlePlaceSymbol:markupModel.markupType onIntersection:intersection withNodeMarkup:nodeMarkup];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[point];
        break;
      }
      case MarkupToolMarker:
      {
        bool markupDataDidChange = [self handlePlaceMarker:markupModel.markupType onIntersection:intersection withNodeMarkup:nodeMarkup];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[point];
        break;
      }
      case MarkupToolLabel:
      {
        bool markupDataDidChange = [self handlePlaceLabel:labelText onIntersection:intersection withNodeMarkup:nodeMarkup];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[point];
        break;
      }
      case MarkupToolConnection:
      {
        if (secondPoint)
        {
          NSString* fromIntersection = intersection;
          NSString* toIntersection = secondPoint.vertex.string;
          bool markupDataDidChange = [self handlePlaceConnection:markupModel.markupType fromIntersection:fromIntersection toIntersection:toIntersection withNodeMarkup:nodeMarkup];
          if (markupDataDidChange)
            pointsWithChangedMarkup = @[point, secondPoint];
        }
        else
        {
          pointsWithChangedMarkup = [self handleRemoveConnectionIfExistsAtIntersection:intersection withNodeMarkup:nodeMarkup];
        }
        break;
      }
      case MarkupToolEraser:
      {
        if (secondPoint)
        {
          NSString* fromIntersection = intersection;
          NSString* toIntersection = secondPoint.vertex.string;
          pointsWithChangedMarkup = [self handleEraseMarkupInRectangleFromIntersection:fromIntersection toIntersection:toIntersection withNodeMarkup:nodeMarkup];
        }
        else
        {
          pointsWithChangedMarkup = [self handleEraseMarkupOnIntersection:intersection withNodeMarkup:nodeMarkup];
        }
        break;
      }
      default:
      {
        applicationStateDidChange = false;
        NSString* errorMessage = [NSString stringWithFormat:@"Failed to handle markup editing interaction, found unsupported markup tool: %d (markup type = %d)", markupModel.markupTool, markupModel.markupType];
        DDLogError(@"%@: %@", self, errorMessage);
        NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }
    }

    if (! nodeMarkup.hasMarkup)
      node.goNodeMarkup = nil;

    if (pointsWithChangedMarkup)
    {
      applicationStateDidChange = true;
      [[NSNotificationCenter defaultCenter] postNotificationName:markupOnPointsDidChange object:pointsWithChangedMarkup];
      [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
    }
  }
  @finally
  {
    if (applicationStateDidChange)
      [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that informs the user that the markup editing
/// interaction is not possible because the application is currently not in
/// markup editing mode.
// -----------------------------------------------------------------------------
- (void) showAlertNotInMarkupEditingMode:(int)currentBoardPosition
{
  NSString* alertTitle = @"Markup editing action canceled";
  NSString* alertMessage;
  // Try to find out why we are no longer in markup editing mode so that we can
  // display a more informative alert message
  if (currentBoardPosition == 0)
    alertMessage = @"The markup editing action was canceled because the board shows board position 0 and is no longer in markup editing mode. Markup can only be edited on board positions greater than zero.";
  else
    alertMessage = @"The markup editing action was canceled because the board is no longer in markup editing mode.";
  DDLogWarn(@"%@: %@", self, alertMessage);

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeOk];
  };

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:alertTitle
                                                                                  message:alertMessage
                                                                                okHandler:okActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that informs the user that the markup editing
/// interaction is not possible because the board is currently showing board
/// position 0.
// -----------------------------------------------------------------------------
- (void) showAlertOnBoardPositionZero
{
  NSString* alertTitle = @"Markup editing action canceled";
  NSString* alertMessage = @"The markup editing action was canceled because the board shows board position 0. Markup can only be edited on board positions greater than zero.";
  DDLogWarn(@"%@: %@", self, alertMessage);

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeOk];
  };

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:alertTitle
                                                                                  message:alertMessage
                                                                                okHandler:okActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

#pragma mark - Alert handler

// -----------------------------------------------------------------------------
/// @brief Alert handler method.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonType)alertButtonType
{
  [self autorelease];  // balance retain that is sent before an alert is shown
}

#pragma mark - Place symbol

// -----------------------------------------------------------------------------
/// @brief Entry point for handling symbol markup placing. Returns true if
/// markup data changed, returns false if markup data did not change.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (bool) handlePlaceSymbol:(enum MarkupType)markupType
            onIntersection:(NSString*)intersection
            withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  // TODO xxx user preference
  bool exclusiveSymbols = true;

  enum GoMarkupSymbol symbolForSelectedMarkupType = [self symbolForMarkupType:markupType];
  NSSet* symbolsThatCannotBeUsed = [NSSet set];
  bool symbolExists = false;
  enum GoMarkupSymbol existingSymbol = GoMarkupSymbolCircle;  // dummy initialize

  NSDictionary* symbols = nodeMarkup.symbols;
  if (symbols)
  {
    NSNumber* existingSymbolAsNumber = symbols[intersection];
    if (existingSymbolAsNumber)
    {
      symbolExists = true;
      existingSymbol = static_cast<GoMarkupSymbol>(existingSymbolAsNumber.intValue);
    }

    if (exclusiveSymbols)
      symbolsThatCannotBeUsed = [[[NSSet alloc] initWithArray:symbols.allValues] autorelease];
    else if (symbolExists)
      symbolsThatCannotBeUsed = [[[NSSet alloc] initWithArray:@[existingSymbolAsNumber]] autorelease];
  }

  enum GoMarkupSymbol newSymbol;
  bool canUseNewSymbol = false;

  if (symbolExists)
  {
    // Cycle through the symbols, starting with the next symbol after the
    // existing one. When we reach the selected markup type without having found
    // a free symbol, we delete the existing symbol, even if there are free
    // symbols afterwards. This allows the user to cycle through the free
    // symbols and eventually get rid of the existing symbol.
    newSymbol = [self nextSymbolAfterSymbol:existingSymbol];

    while (newSymbol != symbolForSelectedMarkupType && ! canUseNewSymbol)
    {
      NSNumber* newSymbolAsNumber = [NSNumber numberWithInt:newSymbol];
      if ([symbolsThatCannotBeUsed containsObject:newSymbolAsNumber])
        newSymbol = [self nextSymbolAfterSymbol:newSymbol];
      else
        canUseNewSymbol = true;
    }
  }
  else
  {
    // Cycle through the symbols, starting with the selected markup type. When
    // we reach the selected markup type without having found a free symbol, we
    // do nothing => this can happen only in exclusive mode when all symbols
    // have already been placed; the user in this case has to remove an existing
    // symbol first.
    newSymbol = symbolForSelectedMarkupType;

    do
    {
      NSNumber* newSymbolAsNumber = [NSNumber numberWithInt:newSymbol];
      if ([symbolsThatCannotBeUsed containsObject:newSymbolAsNumber])
        newSymbol = [self nextSymbolAfterSymbol:newSymbol];
      else
        canUseNewSymbol = true;
    }
    while (newSymbol != symbolForSelectedMarkupType && ! canUseNewSymbol);
  }

  bool markupDataDidChange = true;
  if (canUseNewSymbol)
    [nodeMarkup setSymbol:newSymbol atVertex:intersection];
  else if (symbolExists)
    [nodeMarkup removeSymbolAtVertex:intersection];
  else
    markupDataDidChange = false;

  if (markupDataDidChange)
    [nodeMarkup removeLabelAtVertex:intersection];

  return markupDataDidChange;
}

// -----------------------------------------------------------------------------
/// @brief Returns the next symbol in enumeration #GoMarkupSymbol after
/// @a symbol. Returns the first symbol when @a symbol is the last symbol.
// -----------------------------------------------------------------------------
- (enum GoMarkupSymbol) nextSymbolAfterSymbol:(enum GoMarkupSymbol)symbol
{
  switch (symbol)
  {
    case GoMarkupSymbolCircle:
      return GoMarkupSymbolSquare;
    case GoMarkupSymbolSquare:
      return GoMarkupSymbolTriangle;
    case GoMarkupSymbolTriangle:
      return GoMarkupSymbolX;
    case GoMarkupSymbolX:
      return GoMarkupSymbolSelected;
    case GoMarkupSymbolSelected:
      return GoMarkupSymbolCircle;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"nextSymbolAfterSymbol failed: invalid symbol %d" argumentValue:symbol];
      return GoMarkupSymbolCircle;  // dummy return to make compiler happy
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps a value @a markupType from the enumeration #MarkupType to a
/// a value from the enumeration #GoMarkupSymbol and returns the mapped value.
/// Raises an exception if mapping is not possible.
///
/// @exception InvalidArgumentException Is thrown if @a markupType cannot be
/// mapped. Only markup types for symbols can be mapped.
// -----------------------------------------------------------------------------
- (enum GoMarkupSymbol) symbolForMarkupType:(enum MarkupType)markupType
{
  switch (markupType)
  {
    case MarkupTypeSymbolCircle:
      return GoMarkupSymbolCircle;
    case MarkupTypeSymbolSquare:
      return GoMarkupSymbolSquare;
    case MarkupTypeSymbolTriangle:
      return GoMarkupSymbolTriangle;
    case MarkupTypeSymbolX:
      return GoMarkupSymbolX;
    case MarkupTypeSymbolSelected:
      return GoMarkupSymbolSelected;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"symbolForMarkupType failed: invalid markup type %d" argumentValue:markupType];
      return GoMarkupSymbolCircle;  // dummy return to make compiler happy
  }
}

#pragma mark - Place marker

// -----------------------------------------------------------------------------
/// @brief Entry point for handling marker markup placing. Returns true if
/// markup data changed, returns false if markup data did not change.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (bool) handlePlaceMarker:(enum MarkupType)markupType
            onIntersection:(NSString*)intersection
            withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  bool markerOfRequestedTypeExists = false;
  char nextFreeLetterMarkerValue = letterMarkerValueRanges.front().first;
  int nextFreeNumberMarkerValue = minimumNumberMarkerValue;
  bool canUseNextFreeMarkerValue = false;

  NSDictionary* labels = nodeMarkup.labels;
  if (labels)
  {
    NSString* label = labels[intersection];
    if (label)
    {
      char letterMarkerValue;
      int numberMarkerValue;
      enum MarkupType markupTypeOfLabel = [self markupTypeOfLabel:label
                                                letterMarkerValue:&letterMarkerValue
                                                numberMarkerValue:&numberMarkerValue];
      markerOfRequestedTypeExists = (markupType == markupTypeOfLabel);
    }
    
    std::set<char> usedLetterMarkerValues;
    std::set<char> usedNumberMarkerValues;
    for (NSString* label in labels.allValues)
    {
      char letterMarkerValue;
      int numberMarkerValue;
      enum MarkupType markupTypeOfLabel = [self markupTypeOfLabel:label
                                                letterMarkerValue:&letterMarkerValue
                                                numberMarkerValue:&numberMarkerValue];
      if (markupTypeOfLabel == MarkupTypeMarkerLetter)
        usedLetterMarkerValues.insert(letterMarkerValue);
      else if (markupTypeOfLabel == MarkupTypeMarkerNumber)
        usedNumberMarkerValues.insert(numberMarkerValue);
    }

    if (markupType == MarkupTypeMarkerLetter)
    {
      for (auto letterMarkerValueRange : letterMarkerValueRanges)
      {
        nextFreeLetterMarkerValue = letterMarkerValueRange.first;
        while (nextFreeLetterMarkerValue <= letterMarkerValueRange.second && ! canUseNextFreeMarkerValue)
        {
          if (usedLetterMarkerValues.find(nextFreeLetterMarkerValue) != usedLetterMarkerValues.end())
            nextFreeLetterMarkerValue++;
          else
            canUseNextFreeMarkerValue = true;
        }

        if (canUseNextFreeMarkerValue)
          break;
      }
    }
    else
    {
      while (nextFreeNumberMarkerValue <= maximumNumberMarkerValue && ! canUseNextFreeMarkerValue)
      {
        if (usedNumberMarkerValues.find(nextFreeNumberMarkerValue) != usedNumberMarkerValues.end())
          nextFreeNumberMarkerValue++;
        else
          canUseNextFreeMarkerValue = true;
      }
    }
  }
  else
  {
    canUseNextFreeMarkerValue = true;
  }

  bool markupDataDidChange = true;
  if (canUseNextFreeMarkerValue)
  {
    NSString* newMarker;
    if (markupType == MarkupTypeMarkerLetter)
      newMarker = [NSString stringWithFormat:@"%c" , nextFreeLetterMarkerValue];
    else
      newMarker = [NSString stringWithFormat:@"%d" , nextFreeNumberMarkerValue];

    [nodeMarkup setLabel:newMarker atVertex:intersection];
  }
  else if (markerOfRequestedTypeExists)
  {
    [nodeMarkup removeLabelAtVertex:intersection];
  }
  else
  {
    markupDataDidChange = false;
  }

  if (markupDataDidChange)
    [nodeMarkup removeSymbolAtVertex:intersection];

  return markupDataDidChange;
}

// -----------------------------------------------------------------------------
/// @brief Returns the markup type that @a label corresponds to and fills one
/// of the out variables if appropriate.
///
/// If @a label contains a single letter A-Z or a-z from the latin alphabet,
/// the return value is #MarkupTypeMarkerLetter and this method fills the out
/// variable @a letterMarkerValue with the char value of the single letter.
///
/// If @a label contains only digit characters that form an integer number in
/// the range of 1-999, the return value is #MarkupTypeMarkerNumber and this
/// method fills the out variable @a numberMarkerValue with the int value of the
/// integer number.
///
/// In all other cases the return value is #MarkupTypeLabel and the value of
/// both out variables is undefined.
// -----------------------------------------------------------------------------
- (enum MarkupType) markupTypeOfLabel:(NSString*)label
                    letterMarkerValue:(char*)letterMarkerValue
                    numberMarkerValue:(int*)numberMarkerValue
{
  NSUInteger labelLength = label.length;
  if (labelLength == 1)
  {
    // Code in this branch should hopefully be faster than using regex

    unichar labelCharacter = [label characterAtIndex:0];
    if (labelCharacter >= charUppercaseA && labelCharacter <= charuppercaseZ)
    {
      *letterMarkerValue = labelCharacter - charUppercaseA + 'A';
      return MarkupTypeMarkerLetter;
    }
    else if (labelCharacter >= charLowercaseA && labelCharacter <= charLowercaseZ)
    {
      *letterMarkerValue = labelCharacter - charLowercaseA + 'a';
      return MarkupTypeMarkerLetter;
    }
    else if (labelCharacter >= charZero && labelCharacter <= charNine)
    {
      *numberMarkerValue = labelCharacter - charZero;
      if (*numberMarkerValue >= minimumNumberMarkerValue && *numberMarkerValue <= maximumNumberMarkerValue)
        return MarkupTypeMarkerNumber;
      else
        return MarkupTypeLabel;
    }
    else
    {
      return MarkupTypeLabel;
    }
  }
  else
  {
    NSRegularExpression* regexNumbers = [[NSRegularExpression alloc] initWithPattern:@"^[0-9]+$" options:0 error:nil];
    NSRange allCharactersRange = NSMakeRange(0, labelLength);
    if ([regexNumbers numberOfMatchesInString:label options:0 range:allCharactersRange] > 0)
    {
      *numberMarkerValue = [self labelAsNumberMarkerValue:label];
      if (*numberMarkerValue != -1)
        return MarkupTypeMarkerNumber;
      else
        return MarkupTypeLabel;
    }
    else
    {
      return MarkupTypeLabel;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the number marker value that corresponds to @a label.
/// Returns -1 if conversion of @a label fails, indicating that @a label does
/// not represent a valid number marker value.
///
/// This method expects that a previous step has verified that @a label is not
/// empty and does not contain any characters that are not digits. If this is
/// not the case, then the NSNumberFormatter that is used by the implementation
/// of this method will gracefully handle leading/trailing space characters and
/// locale-specific group or decimal separators.
// -----------------------------------------------------------------------------
- (int) labelAsNumberMarkerValue:(NSString*)label
{
  NSNumberFormatter* numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
  // Parses the text as an integer number
  numberFormatter.numberStyle = NSNumberFormatterNoStyle;
  // If the string contains any characters other than numerical digits or
  // locale-appropriate group or decimal separators, parsing will fail.
  // Leading/trailing space is ignored.
  // Returns nil if parsing fails.
  NSNumber* number = [numberFormatter numberFromString:label];
  if (! number)
    return -1;

  int numberMarkerValue = [number intValue];
  if (numberMarkerValue >= minimumNumberMarkerValue && numberMarkerValue <= maximumNumberMarkerValue)
    return numberMarkerValue;
  else
    return -1;
}

#pragma mark - Place label

// -----------------------------------------------------------------------------
/// @brief Entry point for handling label markup placing. Returns true if
/// markup data changed, returns false if markup data did not change.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (bool) handlePlaceLabel:(NSString*)labelText
           onIntersection:(NSString*)intersection
           withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  NSString* existingLabel = nil;

  NSDictionary* labels = nodeMarkup.labels;
  if (labels)
    existingLabel = labels[intersection];

  // Clean up user input
  labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:labelText];

  bool markupDataDidChange = true;
  if (labelText && labelText.length > 0)
  {
    if (existingLabel && [labelText isEqualToString:existingLabel])
      markupDataDidChange = false;
    else
      [nodeMarkup setLabel:labelText atVertex:intersection];
  }
  else
  {
    if (existingLabel)
      [nodeMarkup removeLabelAtVertex:intersection];
    else
      markupDataDidChange = false;
  }

  if (markupDataDidChange)
    [nodeMarkup removeSymbolAtVertex:intersection];

  return markupDataDidChange;
}

#pragma mark - Place label - Present EditTextDelegate

// -----------------------------------------------------------------------------
/// @brief Presents a popup that allows the user to enter a new label text.
/// If the user did not cancel the editing process, invokes
/// handleMarkupEditingInteractionOnIntersection:withMarkupModel:labelText:nodeMarkup:().
///
/// This method is invoked from doIt() and not from
/// handleMarkupEditingInteractionOnPoint:optionalSecondPoint:withMarkupModel:labelText:node:(),
/// because the latter wraps the invocation of its handler methods into a pair
/// of beginSavePoint/commitSavePoint method calls, which requires the handler
/// method to work synchronously. This method does not work synchronously, it
/// presents EditTextDelegate.
// -----------------------------------------------------------------------------
- (void) handleEnterNewLabelTextOnPoint:(GoPoint*)point
                        withMarkupModel:(MarkupModel*)markupModel
                                   node:(GoNode*)node
{
  NSString* intersection = point.vertex.string;
  GoNodeMarkup* nodeMarkup = node.goNodeMarkup;

  NSDictionary* labels = nodeMarkup.labels;
  NSString* labelText = labels ? labels[intersection] : nil;

  EditTextController* editTextController = [[EditTextController controllerWithText:labelText
                                                                             style:EditTextControllerStyleTextField
                                                                          delegate:self] retain];
  editTextController.title = @"Edit label text";
  editTextController.acceptEmptyText = true;
  editTextController.context = @[point, markupModel, node];

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.window.rootViewController presentNavigationControllerWithRootViewController:editTextController];
  [editTextController release];

  [self retain];  // must survive until EditTextController invokes the delegate method that indicates the end of the editing session
}

#pragma mark - Place label - EditTextDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  return true;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel
{
  [self autorelease];  // balance retain that is sent before EditTextController is shown

  if (! didCancel)
  {
    NSArray* context = editTextController.context;
    GoPoint* point = [context objectAtIndex:0];
    MarkupModel* markupModel = [context objectAtIndex:1];
    GoNode* node = [context objectAtIndex:2];

    NSString* labelText = editTextController.text;

    [self handleMarkupEditingInteractionOnPoint:point
                            optionalSecondPoint:nil
                                withMarkupModel:markupModel
                                      labelText:labelText
                                           node:node];
  }

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Place/remove connection

// -----------------------------------------------------------------------------
/// @brief Entry point for handling connection markup placing. Returns true if
/// markup data changed, returns false if markup data did not change.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (bool) handlePlaceConnection:(enum MarkupType)markupType
              fromIntersection:(NSString*)fromIntersection
                toIntersection:(NSString*)toIntersection
                withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  bool connectionExists = false;
  enum GoMarkupConnection existingConnection = GoMarkupConnectionArrow;  // dummy initialize

  NSDictionary* connections = nodeMarkup.connections;
  if (connections)
  {
    NSArray* intersections = @[fromIntersection, toIntersection];
    NSNumber* existingConnectionAsNumber = connections[intersections];
    if (existingConnectionAsNumber)
    {
      connectionExists = true;
      existingConnection = static_cast<GoMarkupConnection>(existingConnectionAsNumber.intValue);
    }
  }

  enum GoMarkupConnection newConnection = (markupType == MarkupTypeConnectionArrow)
    ? GoMarkupConnectionArrow
    : GoMarkupConnectionLine;

  bool markupDataDidChange = true;
  if (connectionExists && existingConnection == newConnection)
    markupDataDidChange = false;
  else
    [nodeMarkup setConnection:newConnection fromVertex:fromIntersection toVertex:toIntersection];

  return markupDataDidChange;
}

// -----------------------------------------------------------------------------
/// @brief Entry point for handling connection markup removal. Returns an array
/// with the start/end GoPoint objects of the connection that was removed.
/// Returns @e nil if no connection was removed.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (NSArray*) handleRemoveConnectionIfExistsAtIntersection:(NSString*)intersection
                                           withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  NSDictionary* connections = nodeMarkup.connections;
  if (connections)
  {
    for (NSArray* key in connections.allKeys)
    {
      if ([key containsObject:intersection])
      {
        NSString* fromIntersection = key.firstObject;
        NSString* toIntersection = key.lastObject;
        [nodeMarkup removeConnectionFromVertex:fromIntersection toVertex:toIntersection];
        return [self pointsArrayWithFromIntersection:fromIntersection toIntersection:toIntersection];
      }
    }
  }

  return nil;
}

#pragma mark - Erase markup

// -----------------------------------------------------------------------------
/// @brief Entry point for handling markup erasing on a single intersection. If
/// a connection was removed, returns an array with the start/end GoPoint
/// objects of the connection that was removed. If a symbol or label was
/// removed, returns an array with the GoPoint object from which the symbol or
/// label was removed. Returns @e nil if no markup was removed.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (NSArray*) handleEraseMarkupOnIntersection:(NSString*)intersection
                              withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  if (nodeMarkup.symbols && nodeMarkup.symbols[intersection])
  {
    [nodeMarkup removeSymbolAtVertex:intersection];
    return [self pointsArrayWithIntersection:intersection];
  }
  else if (nodeMarkup.labels && nodeMarkup.labels[intersection])
  {
    [nodeMarkup removeLabelAtVertex:intersection];
    return [self pointsArrayWithIntersection:intersection];
  }
  else if (nodeMarkup.connections)
  {
    return [self handleRemoveConnectionIfExistsAtIntersection:intersection withNodeMarkup:nodeMarkup];
  }

  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Entry point for handling markup erasing in a rectangle defined by
/// the diagonally opposite corner intersections @a fromIntersection and
/// @a toIntersection. If a single connection was removed, returns an array with
/// the start/end GoPoint objects of the connection that was removed. If a
/// single symbol or label was removed, returns an array with the GoPoint object
/// from which the symbol or label was removed. If more than one markup element
/// was removed, returns an empty array. Returns @e nil if no markup was
/// removed.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (NSArray*) handleEraseMarkupInRectangleFromIntersection:(NSString*)fromIntersection
                                           toIntersection:(NSString*)toIntersection
                                           withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  NSArray* pointsArray = [self pointsArrayWithFromIntersection:fromIntersection toIntersection:toIntersection];
  GoPoint* fromPoint = pointsArray.firstObject;
  GoPoint* toPoint = pointsArray.lastObject;

  GoGame* game = [GoGame sharedGame];
  NSArray* pointsInSelectionRectangle = [GoUtilities pointsInRectangleDelimitedByCornerPoint:fromPoint
                                                                         oppositeCornerPoint:toPoint
                                                                                      inGame:game];

  // If by chance only one symbol, marker, label or connection is erased
  // then we can tell the rest of the application about this => drawing will
  // be optimized. If many markup items are erased then the information becomes
  // too complex to parse, so we don't provide the information and let the
  // entire board redraw its symbol layers.
  bool singleOrNoMarkupWasErased = true;
  NSArray* pointsWithChangedMarkup = nil;

  for (GoPoint* pointInSelectionRectangle in pointsInSelectionRectangle)
  {
    NSString* intersection = pointInSelectionRectangle.vertex.string;

    NSDictionary* symbols = nodeMarkup.symbols;
    if (symbols && symbols[intersection])
    {
      [nodeMarkup removeSymbolAtVertex:intersection];

      if (pointsWithChangedMarkup)
        singleOrNoMarkupWasErased = false;
      else
        pointsWithChangedMarkup = @[pointInSelectionRectangle];
    }

    NSDictionary* labels = nodeMarkup.labels;
    if (labels && labels[intersection])
    {
      [nodeMarkup removeLabelAtVertex:intersection];

      if (pointsWithChangedMarkup)
        singleOrNoMarkupWasErased = false;
      else
        pointsWithChangedMarkup = @[pointInSelectionRectangle];
    }

    NSDictionary* connections = nodeMarkup.connections;
    if (connections)
    {
      for (NSArray* key in connections.allKeys)
      {
        if ([key containsObject:intersection])
        {
          NSString* fromIntersection = key.firstObject;
          NSString* toIntersection = key.lastObject;
          [nodeMarkup removeConnectionFromVertex:fromIntersection toVertex:toIntersection];

          if (pointsWithChangedMarkup)
            singleOrNoMarkupWasErased = false;
          else
            pointsWithChangedMarkup = [self pointsArrayWithFromIntersection:fromIntersection toIntersection:toIntersection];
        }
      }
    }
  }

  if (singleOrNoMarkupWasErased)
    return pointsWithChangedMarkup;
  else
    return @[];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Private helper. Returns an NSArray with a GoPoint object that
/// corresponds to @a intersection.
// -----------------------------------------------------------------------------
- (NSArray*) pointsArrayWithIntersection:(NSString*)intersection
{
  GoBoard* board = [GoGame sharedGame].board;
  GoPoint* point = [board pointAtVertex:intersection];
  return @[point];
}

// -----------------------------------------------------------------------------
/// @brief Private helper. Returns an NSArray with two GoPoint objects that
/// correspond to @a fromIntersection and @a toIntersection.
// -----------------------------------------------------------------------------
- (NSArray*) pointsArrayWithFromIntersection:(NSString*)fromIntersection
                              toIntersection:(NSString*)toIntersection
{
  GoBoard* board = [GoGame sharedGame].board;
  GoPoint* fromPoint = [board pointAtVertex:fromIntersection];
  GoPoint* toPoint = [board pointAtVertex:toIntersection];
  return @[fromPoint, toPoint];
}

@end
