// -----------------------------------------------------------------------------
// Copyright 2013-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "VersionInfoUtilities.h"


@implementation VersionInfoUtilities


// -----------------------------------------------------------------------------
/// @brief Returns the name of the application bundle.
///
/// The information is retrieved from the application bundle's Info.plist file
/// using the CFBundleDisplayName key.
// -----------------------------------------------------------------------------
+ (NSString*) applicationName
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}

// -----------------------------------------------------------------------------
/// @brief Returns the version of the application bundle.
///
/// The information is retrieved from the application bundle's Info.plist file
/// using the CFBundleShortVersionString key.
// -----------------------------------------------------------------------------
+ (NSString*) applicationVersion
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

// -----------------------------------------------------------------------------
/// @brief Returns the copyright of the application bundle.
///
/// The information is retrieved from the application bundle's Info.plist file
/// using the NSHumanReadableCopyright key.
// -----------------------------------------------------------------------------
+ (NSString*) applicationCopyright
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
}

// -----------------------------------------------------------------------------
/// @brief Returns an NSDate object that refers to the date/time (in local time
/// of the build system) that the application was built.
// -----------------------------------------------------------------------------
+ (NSDate*) buildDateTime
{
  static NSDate* buildDate = nil;
  if (! buildDate)
  {
    // Specs for __DATE__ and __TIME preprocessor macros:
    // https://www.cplusplus.com/doc/tutorial/preprocessor/
    // https://gcc.gnu.org/onlinedocs/cpp/Standard-Predefined-Macros.html
    // Experimentation shows that the result looks like this:
    //   "May 9 2013 19:02:02"
    // The month is an abbreviation in English, the day is not prefixed with 0,
    // the time is in 24h format and the time parts use 0 prefixes. The time is
    // local time.
    NSString* buildDateString = [NSString stringWithFormat:@"%@ %@", @__DATE__, @__TIME__];
    // The following code is largely taken from the answer to this SO question:
    // https://stackoverflow.com/questions/2862469/iphone-sdk-objective-c-date-compile-date-cant-be-converted-to-an-nsdate
    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    dateFormatter.dateFormat = @"MMM d yyyy HH:mm:ss";
    NSLocale* usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    dateFormatter.locale = usLocale;
    buildDate = [dateFormatter dateFromString:buildDateString];
    [buildDate retain];
  }
  return buildDate;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that uses the current locale to represent the NSDate
/// returned by buildDateTime(). The format used is NSDateFormatterShortStyle
/// for the date, and NSDateFormatterMediumStyle (to include seconds) for the
/// time.
// -----------------------------------------------------------------------------
+ (NSString*) buildDateTimeString
{
  static NSDateFormatter* dateFormatter = nil;
  if (! dateFormatter)
  {
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale currentLocale];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
  }
  return [dateFormatter stringFromDate:[VersionInfoUtilities buildDateTime]];
}

@end
