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



// -----------------------------------------------------------------------------
/// @brief The SgfSettingsModel class provides user defaults data to its clients
/// that is related to reading and writing SGF data.
///
/// @ingroup sgf
///
/// @par Syntax checking levels
///
/// The value of the @e syntaxCheckingLevel property denotes how strict the
/// syntax of SGF content is checked when the SGF content is loaded. A lower
/// value indicates that less checking takes place, while a higher value
/// indicates that more checking takes place.
///
/// Each syntax checking level value represents a certain pre-defined (i.e.
/// hardcoded) combination of SGF loading settings. Changing the syntax level
/// checking will result in the SGF loading settings being updated to the
/// combination of values that represent the new syntax checking level. Only
/// syntax checking levels in the range between #minimumSyntaxCheckingLevel and
/// #maximumSyntaxCheckingLevel can be assigned. An exception is raised if you
/// try to assign any other value.
///
/// When querying the property, the value #customSyntaxCheckingLevel indicates
/// an unknown (i.e. not pre-defined) combination of SGF loading settings.
// -----------------------------------------------------------------------------
@interface SgfSettingsModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;
- (void) resetToRegistrationDomainDefaults;
- (void) resetSyntaxCheckingLevelPropertiesToDefaultValues;

// -----------------------------------------------------------------------------
/// @name Properties that are not user defaults
// -----------------------------------------------------------------------------
//@{
/// @brief The syntax checking level that is currently in use. See the class
/// documentation for details. Assigning a value outside the range of
/// pre-defined syntax checking levels results in an exception being raised.
@property(nonatomic, assign) int syntaxCheckingLevel;
//@}

// -----------------------------------------------------------------------------
/// @name User defaults properties tied to syntax checking level
// -----------------------------------------------------------------------------
//@{
/// @brief Types of messages that are currently allowed in order for loading of
/// SGF content to be successful.
@property(nonatomic, assign) enum SgfLoadSuccessType loadSuccessType;
/// @brief True if restrictive checking is enabled (i.e. syntax checking is
/// even more pedantic than normal). False if restrictive checking is disabled.
@property(nonatomic, assign) bool enableRestrictiveChecking;
/// @brief True if all warning messages (critical and non-critical) are
/// disabled. False if warning messages are generated as normal.
@property(nonatomic, assign) bool disableAllWarningMessages;
/// @brief List of warning and error messages to disable. Fatal errors cannot
/// be disabled. Array elements are NSNumber objects, each wrapping an
/// SGFCMessageID value.
@property(nonatomic, retain) NSArray* disabledMessages;
//@}

// -----------------------------------------------------------------------------
/// @name User defaults properties not tied to syntax checking level
// -----------------------------------------------------------------------------
//@{
/// @brief Encoding mode that is currently used to decode SGF content when
/// reading.
@property(nonatomic, assign) enum SgfEncodingMode encodingMode;
/// @brief The default encoding to use in case the SGF content does not specify
/// an encoding (CA property) and no forced encoding has been set. Is an empty
/// string if SGFC's built-in default encoding should be used.
@property(nonatomic, retain) NSString* defaultEncoding;
/// @brief Encoding to use in all cases, overriding even the encoding that the
/// SGF content specifies.
@property(nonatomic, retain) NSString* forcedEncoding;
/// @brief True if the order of variations is reversed. False if the order of
/// variations is as it appears in the SGF content.
@property(nonatomic, assign) bool reverseVariationOrdering;
//@}

@end
