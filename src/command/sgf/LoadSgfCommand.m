// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "LoadSgfCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../sgf/SgfSettingsModel.h"
#import "../../sgf/SgfUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LoadSgfCommand.
// -----------------------------------------------------------------------------
@interface LoadSgfCommand()
@property(nonatomic, retain) NSString* sgfFilePath;
@end


@implementation LoadSgfCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a LoadSgfCommand object that will load the SGF file
/// identified by the full file path @a sgfFilePath.
///
/// @note This is the designated initializer of LoadSgfCommand.
// -----------------------------------------------------------------------------
- (id) initWithSgfFilePath:(NSString*)sgfFilePath
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.sgfFilePath = sgfFilePath;
  self.sgfDocumentReadResultSingleEncoding = nil;
  self.sgfDocumentReadResultMultipleEncodings = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LoadSgfCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.sgfFilePath = nil;
  self.sgfDocumentReadResultSingleEncoding = nil;
  self.sgfDocumentReadResultMultipleEncodings = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! self.sgfFilePath)
  {
    DDLogError(@"%@: No SGF file path provided", [self shortDescription]);
    return false;
  }
  DDLogVerbose(@"%@: Loading SGF file %@", [self shortDescription], self.sgfFilePath);

  SgfSettingsModel* sgfSettingsModel = [ApplicationDelegate sharedDelegate].sgfSettingsModel;
  SGFCDocumentReader* documentReader = [SGFCDocumentReader documentReader];

  if (sgfSettingsModel.encodingMode == SgfEncodingModeSingleEncoding ||
      sgfSettingsModel.encodingMode == SgfEncodingModeMultipleEncodings)
  {
    [self performReadOperatonWithReader:documentReader
                       withEncodingMode:sgfSettingsModel.encodingMode
                    withValuesFromModel:sgfSettingsModel];
  }
  else
  {
    bool success = [self performReadOperatonWithReader:documentReader
                                      withEncodingMode:SgfEncodingModeSingleEncoding
                                   withValuesFromModel:sgfSettingsModel];

    if (! success)
    {
      [self performReadOperatonWithReader:documentReader
                         withEncodingMode:SgfEncodingModeMultipleEncodings
                      withValuesFromModel:sgfSettingsModel];
    }
  }

  return true;
}

#pragma mark - Private helpers

- (bool) performReadOperatonWithReader:(SGFCDocumentReader*)documentReader
                      withEncodingMode:(enum SgfEncodingMode)encodingMode
                   withValuesFromModel:(SgfSettingsModel*)sgfSettingsModel
{
  SGFCArguments* arguments = documentReader.arguments;
  [self setupReaderArguments:documentReader withValuesFromModel:sgfSettingsModel];

  if (encodingMode == SgfEncodingModeSingleEncoding)
    [arguments addArgumentWithType:SGFCArgumentTypeEncodingMode withIntParameter:1];
  else
    [arguments addArgumentWithType:SGFCArgumentTypeEncodingMode withIntParameter:2];

  SGFCDocumentReadResult* readResult = [documentReader readSgfContentFromFile:self.sgfFilePath];

  if (encodingMode == SgfEncodingModeSingleEncoding)
    self.sgfDocumentReadResultSingleEncoding = readResult;
  else
    self.sgfDocumentReadResultMultipleEncodings = readResult;

  return [SgfUtilities isLoadOperationSuccessful:readResult
                             withLoadSuccessType:sgfSettingsModel.loadSuccessType];
}

- (void) setupReaderArguments:(SGFCDocumentReader*)documentReader
          withValuesFromModel:(SgfSettingsModel*)sgfSettingsModel
{
  SGFCArguments* arguments = documentReader.arguments;

  [arguments clearArguments];

  if (sgfSettingsModel.disableAllWarningMessages)
    [arguments addArgumentWithType:SGFCArgumentTypeDisableWarningMessages];
  if (sgfSettingsModel.enableRestrictiveChecking)
    [arguments addArgumentWithType:SGFCArgumentTypeEnableRestrictiveChecking];
  // The UI does not prevent adding the same ID multiple times, but SgfcKit
  // raises an exception if we pass the same ID multiple times. NSSet performs
  // de-duplication for us.
  NSSet* disabledMessages = [[NSSet alloc] initWithArray:sgfSettingsModel.disabledMessages];
  for (NSNumber* disabledMessageIDAsNumber in disabledMessages)
  {
    SGFCMessageID disabledMessageID = [disabledMessageIDAsNumber integerValue];
    [arguments addArgumentWithType:SGFCArgumentTypeDisableMessageID withMessageIDParameter:disabledMessageID];
  }

  if (sgfSettingsModel.defaultEncoding.length > 0)
    [arguments addArgumentWithType:SGFCArgumentTypeDefaultEncoding withStringParameter:sgfSettingsModel.defaultEncoding];
  if (sgfSettingsModel.forcedEncoding.length > 0)
    [arguments addArgumentWithType:SGFCArgumentTypeForcedEncoding withStringParameter:sgfSettingsModel.forcedEncoding];

  if (sgfSettingsModel.reverseVariationOrdering)
    [arguments addArgumentWithType:SGFCArgumentTypeReverseVariationOrdering];

  // This generates SGFCMessageIDEmptyNodeDeleted, which is why the message is
  // in the default list of disabled messages
  [arguments addArgumentWithType:SGFCArgumentTypeDeleteEmptyNodes];
}

@end
