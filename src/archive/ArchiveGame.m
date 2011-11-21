// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "ArchiveGame.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ArchiveGame.
// -----------------------------------------------------------------------------
@interface ArchiveGame()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Property accessors
//@{
- (NSString*) name;
//@}
@end


@implementation ArchiveGame

@synthesize fileName;
@synthesize fileDate;
@synthesize fileSize;


// -----------------------------------------------------------------------------
/// @brief Initializes a ArchiveGame object. The properties that describe the
/// object have empty string values.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithFileName:nil fileAttributes:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a ArchiveGame object. The object's file name property is
/// set to @a aFileName. Other property values are taken from @a fileAttributes;
/// the dictionary is expected to contain values obtained via NSFileManager's
/// attributesOfItemAtPath:error:().
///
/// @a fileName and @a fileAttributes may be empty, in which case the properties
/// that describe this ArchiveGame object are set to empty string values.
///
/// @note This is the designated initializer of ArchiveGame.
// -----------------------------------------------------------------------------
- (id) initWithFileName:(NSString*)aFileName fileAttributes:(NSDictionary*)fileAttributes
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  if (! aFileName)
    self.fileName = @"";
  else
    self.fileName = aFileName;

  if (! fileAttributes)
  {
    self.fileDate = @"";
    self.fileSize = @"";
  }
  else
    [self updateFileAttributes:fileAttributes];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ArchiveGame object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.fileName = nil;
  self.fileDate = nil;
  self.fileSize = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Updates the attributes of this ArchiveGame object with values from
/// @a fileAttributes.
// -----------------------------------------------------------------------------
- (void) updateFileAttributes:(NSDictionary*)fileAttributes
{
  NSDate* fileModificationDate = [fileAttributes fileModificationDate];
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setLocale:[NSLocale currentLocale]];
  [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
  [dateFormatter setDateStyle:NSDateFormatterShortStyle];
  self.fileDate = [dateFormatter stringFromDate:fileModificationDate];
  [dateFormatter release];

  unsigned long long fileSizeInBytes = [fileAttributes fileSize];
  float fileSizeInKB = fileSizeInBytes / 1024.0;
  self.fileSize = [NSString stringWithFormat:@"%0.1f", fileSizeInKB];
}

// -----------------------------------------------------------------------------
/// @brief Returns the result of comparing the values of the fileName property
/// of this ArchiveGame and @a aGame.
///
/// This method is used for sorting ArchiveGame objects by their file name.
// -----------------------------------------------------------------------------
- (NSComparisonResult) compare:(ArchiveGame*)aGame
{
  return [self.fileName localizedCompare:aGame.fileName];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSString*) name
{
  return [fileName stringByReplacingOccurrencesOfString:@".sgf" withString:@""];
}

@end
