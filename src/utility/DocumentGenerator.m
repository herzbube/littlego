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
#import "DocumentGenerator.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for DocumentGenerator.
// -----------------------------------------------------------------------------
@interface DocumentGenerator()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Private helpers
//@{
- (void) parseFileContent:(NSString*)fileContent;
- (NSString*) parseSectionContentLines:(NSArray*)sectionContentLines;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) int numberOfSections;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) NSMutableArray* sectionTitles;
@property(nonatomic, retain) NSMutableArray* sectionContents;
//@}
@end


@implementation DocumentGenerator


@synthesize numberOfSections;
@synthesize sectionTitles;
@synthesize sectionContents;


// -----------------------------------------------------------------------------
/// @brief Initializes a DocumentGenerator object with @a fileContent to parse
/// according to the rules set out in the class documentation.
///
/// @note This is the designated initializer of DocumentGenerator.
// -----------------------------------------------------------------------------
- (id) initWithFileContent:(NSString*)fileContent
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.numberOfSections = 0;
  self.sectionTitles = [NSMutableArray arrayWithCapacity:0];
  self.sectionContents = [NSMutableArray arrayWithCapacity:0];

  [self parseFileContent:fileContent];
  
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DocumentGenerator object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.sectionTitles = nil;
  self.sectionContents = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of sections that were found by this
/// DocumentGenerator.
// -----------------------------------------------------------------------------
- (int) numberOfSections
{
  return self.sectionTitles.count;
}

// -----------------------------------------------------------------------------
/// @brief Returns the title of the section referenced by @a sectionIndex. The
/// index is zero-based.
// -----------------------------------------------------------------------------
- (NSString*) sectionTitle:(int)sectionIndex
{
  return [self.sectionTitles objectAtIndex:sectionIndex];
}

// -----------------------------------------------------------------------------
/// @brief Returns the content of the section referenced by @a sectionIndex. The
/// index is zero-based.
///
/// The content of the section that is returned is a valid HTML document.
// -----------------------------------------------------------------------------
- (NSString*) sectionContent:(int)sectionIndex
{
  return [self.sectionContents objectAtIndex:sectionIndex];
}

// -----------------------------------------------------------------------------
/// @brief Parses the string @a fileContent which represents the content of a
/// structured text file.
///
/// This method is invoked by the designated initializer of DocumentGenerator
/// and populates properties of the DocumentGenerator instance with values
/// extracted from @a fileContent.
// -----------------------------------------------------------------------------
- (void) parseFileContent:(NSString*)fileContent
{
  bool firstSectionFound = false;
  NSString* previousFileContentLine = nil;
  NSMutableArray* sectionContentLines = [NSMutableArray arrayWithCapacity:0];
  NSArray* fileContentLines = [fileContent componentsSeparatedByString:@"\n"];
  for (NSString* fileContentLine in fileContentLines)
  {
    if ([fileContentLine hasPrefix:@"---"])
    {
      NSString* sectionTitle;
      if (! previousFileContentLine)
        sectionTitle = @"Section foo";  // we have no real section title if the very first line in the file is a separator
      else
        sectionTitle = previousFileContentLine;
      [self.sectionTitles addObject:sectionTitle];

      if (! firstSectionFound)
        firstSectionFound = true;
      else
      {
        [sectionContentLines removeLastObject];  // last object is the title of the new section
        NSString* sectionContent = [self parseSectionContentLines:sectionContentLines];
        [self.sectionContents addObject:sectionContent];
        [sectionContentLines removeAllObjects];
      }
    }
    else
    {
      if (firstSectionFound)
        [sectionContentLines addObject:fileContentLine];
    }
    previousFileContentLine = fileContentLine;
  }
  if (firstSectionFound)
  {
    [sectionContentLines removeLastObject];  // last object is the title of the new section
    NSString* sectionContent = [self parseSectionContentLines:sectionContentLines];
    [self.sectionContents addObject:sectionContent];
    [sectionContentLines removeAllObjects];
  }
}

// -----------------------------------------------------------------------------
/// @brief Parses the content of @a sectionContentLines and converts it into an
/// HTML document. Returns that HTML document.
///
/// Assumes that the objects in @a sectionContentLines are strings that contain
/// lines of the original file content. All lines in @a sectionContentLines
/// together form a single section.
///
/// This method is invoked as part of the initialization process when a new
/// DocumentGenerator instance is created.
// -----------------------------------------------------------------------------
- (NSString*) parseSectionContentLines:(NSArray*)sectionContentLines
{
  NSCharacterSet* whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];

  // Initial value true causes leading empty lines to be skipped
  bool previousLineWasEmptyLine = true;
  NSString* sectionContent = @"<p>";
  for (NSString* sectionContentLine in sectionContentLines)
  {
    sectionContentLine = [sectionContentLine stringByTrimmingCharactersInSet:whitespaceCharacterSet];
    if (0 == sectionContentLine.length)
    {
      // Collapse multiple empty lines into one paragraph
      if (! previousLineWasEmptyLine)
        sectionContent = [sectionContent stringByAppendingString:@"</p><p>"];
      previousLineWasEmptyLine = true;
    }
    else
    {
      sectionContent = [NSString stringWithFormat:@"%@ %@", sectionContent, sectionContentLine];
      previousLineWasEmptyLine = false;
    }
  }
  sectionContent = [sectionContent stringByAppendingString:@"</p>"];

  return [NSString stringWithFormat:@""
          "<html>"
          "<head>"
          "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>"
          "<style type=\"text/css\">"
          "body { font-family:helvetica; font-size: small; }"
          "</style>"
          "</head>"
          "<body>"
          "%@"
          "</body>"
          "</html>", sectionContent];
}

@end
