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


// Forward declarations
@class GoNode;
@class GoNodeMarkup;
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The MarkupUtilities class is a container for various utility
/// functions related to board markup.
///
/// @ingroup sgf
///
/// All functions in MarkupUtilities are class methods, so there is no need to
/// create an instance of MarkupUtilities.
// -----------------------------------------------------------------------------
@interface MarkupUtilities : NSObject
{
}

+ (enum MarkupTool) markupToolForMarkupType:(enum MarkupType)markupType;

+ (enum GoMarkupSymbol) symbolForMarkupType:(enum MarkupType)markupType;
+ (enum MarkupType) markupTypeForSymbol:(enum GoMarkupSymbol)symbol;
+ (enum GoMarkupSymbol) nextSymbolAfterSymbol:(enum GoMarkupSymbol)symbol;

+ (enum GoMarkupConnection) connectionForMarkupType:(enum MarkupType)markupType;
+ (enum MarkupType) markupTypeForConnection:(enum GoMarkupConnection)connection;

+ (enum GoMarkupLabel) labelForMarkupType:(enum MarkupType)markupType;
+ (enum MarkupType) markupTypeForLabel:(enum GoMarkupLabel)label;
+ (NSString*) nextFreeMarkerOfType:(enum GoMarkupLabel)labelType
                      inNodeMarkup:(GoNodeMarkup*)nodeMarkup
                    fillMarkerGaps:(bool)fillMarkerGaps;

+ (bool) shouldDisplayMarkupIndicatorForNode:(GoNode*)node;
+ (bool) markupExistsOnPoint:(GoPoint*)point forNode:(GoNode*)node ignoreLabels:(bool)ignoreLabels;
+ (bool) markupExistsOnPoint:(GoPoint*)point forNode:(GoNode*)node ignoreLabels:(bool)ignoreLabels firstMarkupType:(enum MarkupType*)markupType;
+ (bool) markupExistsOnPoint:(GoPoint*)point forNode:(GoNode*)node ignoreLabels:(bool)ignoreLabels firstMarkupType:(enum MarkupType*)markupType firstMarkupInfo:(id*)markupInfo;

@end
