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
  NSDataDetector* urlDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:NULL];
  fileContent = [urlDetector stringByReplacingMatchesInString:fileContent
                                                      options:0
                                                        range:NSMakeRange(0, fileContent.length)
                                                 withTemplate:@"<a href=\"$0\">$0</a>"];

  bool useNextLineAsSectionTitle = false;
  bool ignoreNextLineIfItIsSectionSeparator = false;
  NSString* sectionTitle = nil;
  NSMutableArray* sectionContentLines = [NSMutableArray arrayWithCapacity:0];
  
  NSArray* fileContentLines = [fileContent componentsSeparatedByString:@"\n"];
  for (NSString* fileContentLine in fileContentLines)
  {
    if ([fileContentLine hasPrefix:@"---"])
    {
      if (ignoreNextLineIfItIsSectionSeparator)
      {
        // ignore the line as requested
      }
      else
      {
        useNextLineAsSectionTitle = true;

        if (sectionTitle)
        {
          // Ignore some sections with special titles
          if (! [sectionTitle isEqualToString:@"Table of Contents"] &&
              ! [sectionTitle isEqualToString:@"Purpose of this document"])
          {
            // Remember section title
            [self.sectionTitles addObject:sectionTitle];
            // Parse section content & remember parsed content
            NSString* sectionContent = [self parseSectionContentLines:sectionContentLines];
            [self.sectionContents addObject:sectionContent];
          }
          // Prepare for next section
          sectionTitle = nil;
          [sectionContentLines removeAllObjects];
        }
      }
    }
    else if (useNextLineAsSectionTitle)
    {
      sectionTitle = fileContentLine;
      useNextLineAsSectionTitle = false;
      ignoreNextLineIfItIsSectionSeparator = true;
    }
    else
    {
      if (ignoreNextLineIfItIsSectionSeparator)
        ignoreNextLineIfItIsSectionSeparator = false;
      [sectionContentLines addObject:fileContentLine];
    }
  }
  // Post-processing for last section in file
  if (sectionTitle)
  {
    [self.sectionTitles addObject:sectionTitle];
    NSString* sectionContent = [self parseSectionContentLines:sectionContentLines];
    [self.sectionContents addObject:sectionContent];
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

  bool paragraphHasStarted = false;
  bool listHasStarted = false;
  bool listIsUnnumbered = true;
  bool listItemHasStarted = false;
  bool useNextLineAsSubsectionTitle = false;
  bool ignoreNextLineIfItIsSubsectionSeparator = false;

  NSString* sectionContent = @"";
  for (NSString* sectionContentLine in sectionContentLines)
  {
    sectionContentLine = [sectionContentLine stringByTrimmingCharactersInSet:whitespaceCharacterSet];
    if (0 == sectionContentLine.length)
    {
      // An empty line closes a previously opened paragraph or list, but does
      // nothing if there is no list or paragraph open. This approach has the
      // following effects:
      // - Multiple empty lines in a row are "collapsed" into one
      // - Empty lines at the beginning of the section are ignored
      // - Empty lines after a subsection title are ignored
      if (paragraphHasStarted)
      {
        paragraphHasStarted = false;
        sectionContent = [sectionContent stringByAppendingString:@"</p>"];
      }
      else if (listHasStarted)
      {
        listHasStarted = false;
        listItemHasStarted = false;
        sectionContent = [sectionContent stringByAppendingString:@"</li>"];
        if (listIsUnnumbered)
          sectionContent = [sectionContent stringByAppendingString:@"</ul>"];
        else
          sectionContent = [sectionContent stringByAppendingString:@"</ol>"];
      }
    }
    else
    {
      if ([sectionContentLine hasPrefix:@"==="])
      {
        if (ignoreNextLineIfItIsSubsectionSeparator)
        {
          // ignore the line as requested
        }
        else
        {
          useNextLineAsSubsectionTitle = true;
        }
      }
      else if (useNextLineAsSubsectionTitle)
      {
        useNextLineAsSubsectionTitle = false;
        ignoreNextLineIfItIsSubsectionSeparator = true;
        if (listHasStarted)
        {
          listHasStarted = false;
          listItemHasStarted = false;
          sectionContent = [sectionContent stringByAppendingString:@"</li>"];
          if (listIsUnnumbered)
            sectionContent = [sectionContent stringByAppendingString:@"</ul>"];
          else
            sectionContent = [sectionContent stringByAppendingString:@"</ol>"];
        }
        else if (paragraphHasStarted)
        {
          paragraphHasStarted = false;
          sectionContent = [sectionContent stringByAppendingString:@"</p>"];
        }
        sectionContent = [sectionContent stringByAppendingFormat:@"<p class=\"section-header\">%@</p>",
                          sectionContentLine];
      }
      else
      {
        ignoreNextLineIfItIsSubsectionSeparator = false;

        if ([sectionContentLine hasPrefix:@"- "] || [sectionContentLine hasPrefix:@"1. "])
        {
          if (paragraphHasStarted)
          {
            paragraphHasStarted = false;
            sectionContent = [sectionContent stringByAppendingString:@"</p>"];
          }
          if ([sectionContentLine hasPrefix:@"- "])
          {
            listIsUnnumbered = true;
            sectionContentLine = [sectionContentLine stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@""];
          }
          else
          {
            listIsUnnumbered = false;
            sectionContentLine = [sectionContentLine stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:@""];
          }
          if (! listHasStarted)
          {
            listHasStarted = true;
            if (listIsUnnumbered)
              sectionContent = [sectionContent stringByAppendingString:@"<ul>"];
            else
              sectionContent = [sectionContent stringByAppendingString:@"<ol>"];
          }
          if (listItemHasStarted)
            sectionContent = [sectionContent stringByAppendingString:@"</li>"];
          else
            listItemHasStarted = true;
          sectionContent = [sectionContent stringByAppendingFormat:@"<li> %@",
                            sectionContentLine];
        }
        else
        {
          if (listHasStarted)
          {
            // do nothing if a list has started, we're just adding lines to
            // the current list entry
          }
          else if (! paragraphHasStarted)
          {
            paragraphHasStarted = true;
            sectionContent = [sectionContent stringByAppendingString:@"<p class=\"section\">"];
          }
          sectionContent = [sectionContent stringByAppendingFormat:@" %@",
                            sectionContentLine];
        }
      }
    }
  }
  if (listHasStarted)
  {
    listHasStarted = false;
    listItemHasStarted = false;
    sectionContent = [sectionContent stringByAppendingString:@"</li>"];
    if (listIsUnnumbered)
      sectionContent = [sectionContent stringByAppendingString:@"</ul>"];
    else
      sectionContent = [sectionContent stringByAppendingString:@"</ol>"];
  }
  else if (paragraphHasStarted)
  {
    paragraphHasStarted = false;
    sectionContent = [sectionContent stringByAppendingString:@"</p>"];
  }

  return [NSString stringWithFormat:@""
          "<html>"
          "<head>"
          "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>"
          "<style type=\"text/css\">"
          "body { font-family:helvetica; font-size: small; }"
          "p.section-header { text-align: center; font-weight: bold; background-color: Lavender }"
          "p.section { }"
          "</style>"
          "</head>"
          "<body>"
          "%@"
          "</body>"
          "</html>", sectionContent];
}

@end
