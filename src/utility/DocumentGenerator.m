// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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


enum ListType
{
  ListTypeUnnumbered,
  ListTypeNumbered,
  ListTypeDefinition,
};

static const int unnumberedIndentationSpaces = 2;
static const int numberedIndentationSpaces = 3;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for DocumentGenerator.
// -----------------------------------------------------------------------------
@interface DocumentGenerator()
@property(nonatomic, retain) NSMutableArray* groupTitles;
@property(nonatomic, retain) NSMutableArray* sectionIndexPaths;  // each element is another NSMutableArray
@property(nonatomic, retain) NSMutableArray* sectionTitles;
@property(nonatomic, retain) NSMutableArray* sectionContents;
@end


@implementation DocumentGenerator

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

  self.groupTitles = [NSMutableArray arrayWithCapacity:0];
  self.sectionIndexPaths = [NSMutableArray arrayWithCapacity:0];
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
  self.groupTitles = nil;
  self.sectionIndexPaths = nil;
  self.sectionTitles = nil;
  self.sectionContents = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of groups that were found by this
/// DocumentGenerator.
// -----------------------------------------------------------------------------
- (int) numberOfGroups
{
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this generator was not made to handle more than pow(2, 31)
  // groups.
  return (int)self.sectionIndexPaths.count;
}

// -----------------------------------------------------------------------------
/// @brief Returns the title of the group referenced by @a groupIndex. The
/// index is zero-based.
// -----------------------------------------------------------------------------
- (NSString*) titleForGroup:(int)groupIndex
{
  return [self.groupTitles objectAtIndex:groupIndex];
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of sections in the group referenced by
/// @a groupIndex. The index is zero-based.
// -----------------------------------------------------------------------------
- (int) numberOfSectionsInGroup:(int)groupIndex
{
  NSArray* sectionIndexList = [self.sectionIndexPaths objectAtIndex:groupIndex];
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this generator was not made to handle more than pow(2, 31)
  // sections.
  return (int)sectionIndexList.count;
}

// -----------------------------------------------------------------------------
/// @brief Returns the section ID referenced by @a sectionIndex and
/// @a groupIndex. The indices are zero-based.
///
/// The section ID returned is actually an index that can be used to access
/// elements in @e sectionTitles and @e sectionContents.
///
/// This is an internal helper.
// -----------------------------------------------------------------------------
- (int) sectionIDForSection:(int)sectionIndex inGroup:(int)groupIndex
{
  NSArray* sectionIDList = [self.sectionIndexPaths objectAtIndex:groupIndex];
  NSNumber* sectionID = [sectionIDList objectAtIndex:sectionIndex];
  return [sectionID intValue];
}

// -----------------------------------------------------------------------------
/// @brief Adds a new group. Returns the zero-based index that references the
/// new group.
///
/// This is an internal helper.
// -----------------------------------------------------------------------------
- (int) addGroup
{
  [self.sectionIndexPaths addObject:[NSMutableArray arrayWithCapacity:0]];
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this generator was not made to handle more than pow(2, 31)
  // groups.
  return ((int)self.sectionIndexPaths.count - 1);
}

// -----------------------------------------------------------------------------
/// @brief Adds a new section to group referenced by @a groupIndex. The index
/// is zero-based.
///
/// This is an internal helper.
// -----------------------------------------------------------------------------
- (void) addSectionID:(int)sectionID toGroup:(int)groupIndex
{
  NSMutableArray* sectionIDList = [self.sectionIndexPaths objectAtIndex:groupIndex];
  [sectionIDList addObject:[NSNumber numberWithInt:sectionID]];
}

// -----------------------------------------------------------------------------
/// @brief Returns the title of the section referenced by @a sectionIndex and
/// @a groupIndex. The indices are zero-based.
// -----------------------------------------------------------------------------
- (NSString*) titleForSection:(int)sectionIndex inGroup:(int)groupIndex
{
  int sectionID = [self sectionIDForSection:sectionIndex inGroup:groupIndex];
  return [self.sectionTitles objectAtIndex:sectionID];
}

// -----------------------------------------------------------------------------
/// @brief Returns the content of the section referenced by @a sectionIndex and
/// @a groupIndex. The indices are zero-based.
///
/// The content of the section that is returned is a valid HTML document.
// -----------------------------------------------------------------------------
- (NSString*) contentForSection:(int)sectionIndex inGroup:(int)groupIndex
{
  int sectionID = [self sectionIDForSection:sectionIndex inGroup:groupIndex];
  return [self.sectionContents objectAtIndex:sectionID];
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

  bool useNextLineAsGroupTitle = false;
  bool ignoreNextLineIfItIsGroupSeparator = false;
  NSString* groupTitle = nil;
  NSMutableArray* groupContentLines = [NSMutableArray arrayWithCapacity:0];
  
  NSArray* fileContentLines = [fileContent componentsSeparatedByString:@"\n"];
  for (NSString* fileContentLine in fileContentLines)
  {
    if ([fileContentLine hasPrefix:@"***"])
    {
      if (ignoreNextLineIfItIsGroupSeparator)
      {
        // ignore the line as requested
      }
      else
      {
        useNextLineAsGroupTitle = true;

        if (groupTitle)
        {
          // Add group
          int groupIndex = [self addGroup];
          // Remember group title
          [self.groupTitles addObject:groupTitle];
          // Parse group content, modifying internal state as a side effect
          [self parseGroupContentLines:groupContentLines forGroup:groupIndex];
          // Prepare for next group
          groupTitle = nil;
          [groupContentLines removeAllObjects];
        }
      }
    }
    else if (useNextLineAsGroupTitle)
    {
      groupTitle = fileContentLine;
      useNextLineAsGroupTitle = false;
      ignoreNextLineIfItIsGroupSeparator = true;
    }
    else
    {
      if (ignoreNextLineIfItIsGroupSeparator)
        ignoreNextLineIfItIsGroupSeparator = false;
      [groupContentLines addObject:fileContentLine];
    }
  }
  // Post-processing for last group in file. Also post-process if there was no
  // group at all.
  if (groupTitle || 0 == [self numberOfGroups])
  {
    int groupIndex = [self addGroup];
    // Must not add a nil object, but an empty string is also adequate (table
    // views do not display empty string headers)
    if (! groupTitle)
      groupTitle = @"";
    [self.groupTitles addObject:groupTitle];
    [self parseGroupContentLines:groupContentLines forGroup:groupIndex];
  }
}

// -----------------------------------------------------------------------------
/// @brief Parses the content of @a groupContentLines and creates sections from
/// it. As a side effect, adds sections to the group referenced by
/// @a groupIndex.
///
/// Assumes that the objects in @a groupContentLines are strings that contain
/// lines of the original file content. All lines in @a groupContentLines
/// together form a single group.
///
/// This method is invoked as part of the initialization process when a new
/// DocumentGenerator instance is created.
// -----------------------------------------------------------------------------
- (void) parseGroupContentLines:(NSArray*)groupContentLines forGroup:(int)groupIndex
{
  bool useNextLineAsSectionTitle = false;
  bool ignoreNextLineIfItIsSectionSeparator = false;
  NSString* sectionTitle = nil;
  NSMutableArray* sectionContentLines = [NSMutableArray arrayWithCapacity:0];

  for (NSString* groupContentLine in groupContentLines)
  {
    if ([groupContentLine hasPrefix:@"---"])
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
            // Add section to group
            // Cast is required because NSUInteger and int differ in size in
            // 64-bit. Cast is safe because this generator was not made to
            // handle more than pow(2, 31) sections.
            int sectionID = (int)self.sectionTitles.count - 1;  // section ID is actually the index of the section title that we just added
            [self addSectionID:sectionID toGroup:groupIndex];
          }
          // Prepare for next section
          sectionTitle = nil;
          [sectionContentLines removeAllObjects];
        }
      }
    }
    else if (useNextLineAsSectionTitle)
    {
      sectionTitle = groupContentLine;
      useNextLineAsSectionTitle = false;
      ignoreNextLineIfItIsSectionSeparator = true;
    }
    else
    {
      if (ignoreNextLineIfItIsSectionSeparator)
        ignoreNextLineIfItIsSectionSeparator = false;
      [sectionContentLines addObject:groupContentLine];
    }
  }
  // Post-processing for last section in file
  if (sectionTitle)
  {
    [self.sectionTitles addObject:sectionTitle];
    NSString* sectionContent = [self parseSectionContentLines:sectionContentLines];
    [self.sectionContents addObject:sectionContent];
    // Cast is required because NSUInteger and int differ in size in 64-bit.
    // Cast is safe because this generator was not made to handle more than
    // pow(2, 31) sections.
    int sectionID = (int)self.sectionTitles.count - 1;
    [self addSectionID:sectionID toGroup:groupIndex];
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
  NSMutableArray* listStack = [NSMutableArray array];
  NSError* error = nil;;
  NSRegularExpression* emptyLineRegex = [NSRegularExpression regularExpressionWithPattern:@"^ *$"
                                                                                  options:0
                                                                                    error:&error];
  NSRegularExpression* listRegex = [NSRegularExpression regularExpressionWithPattern:@"^( *)(-|1\\.) "
                                                                             options:0
                                                                               error:&error];
  NSRegularExpression* indentationRegex = [NSRegularExpression regularExpressionWithPattern:@"^( *)[^ ]*"
                                                                             options:0
                                                                               error:&error];
  bool paragraphHasStarted = false;
  bool useNextLineAsSubsectionTitle = false;
  bool ignoreNextLineIfItIsSubsectionSeparator = false;

  NSString* sectionContent = @"";
  for (NSString* sectionContentLine in sectionContentLines)
  {
    NSUInteger numberOfMatches = [emptyLineRegex numberOfMatchesInString:sectionContentLine
                                                                 options:0
                                                                   range:NSMakeRange(0, sectionContentLine.length)];
    if (1 == numberOfMatches)
    {
      // An empty line closes a previously opened paragraph or list, but does
      // nothing if there is no list or paragraph open. This approach has the
      // following effects:
      // - Multiple empty lines in a row are "collapsed" into one
      // - Empty lines at the beginning of the section are ignored
      // - Empty lines after a subsection title are ignored
      if (listStack.count > 0)
      {
        sectionContent = [self closeListStack:listStack inSectionContent:sectionContent];
      }
      else if (paragraphHasStarted)
      {
        paragraphHasStarted = false;
        sectionContent = [sectionContent stringByAppendingString:@"</p>"];
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
        if (listStack.count > 0)
        {
          sectionContent = [self closeListStack:listStack inSectionContent:sectionContent];
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

        NSTextCheckingResult* listRegexMatch = [listRegex firstMatchInString:sectionContentLine
                                                                     options:0
                                                                       range:NSMakeRange(0, sectionContentLine.length)];
        if (listRegexMatch)
        {
          if (paragraphHasStarted)
          {
            paragraphHasStarted = false;
            sectionContent = [sectionContent stringByAppendingString:@"</p>"];
          }

          NSString* substringIndentation = [sectionContentLine substringWithRange:[listRegexMatch rangeAtIndex:1]];
          NSInteger newListItemIndentationSpaces = substringIndentation.length;

          NSString* substringItemType = [sectionContentLine substringWithRange:[listRegexMatch rangeAtIndex:2]];
          enum ListType newListType;
          if ([substringItemType hasPrefix:@"-"])
            newListType = ListTypeUnnumbered;
          else
            newListType = ListTypeNumbered;

          NSInteger currentListItemIndentationSpaces = [self listItemIndentationSpacesAtTopOfListStack:listStack];
          if (newListItemIndentationSpaces > currentListItemIndentationSpaces)
          {
            int indentationSpaces = 0;
            if (newListType == ListTypeUnnumbered)
            {
              sectionContent = [sectionContent stringByAppendingString:@"<ul>"];
              indentationSpaces = unnumberedIndentationSpaces;
            }
            else
            {
              sectionContent = [sectionContent stringByAppendingString:@"<ol>"];
              indentationSpaces = numberedIndentationSpaces;
            }

            if (listStack.count > 0 && (currentListItemIndentationSpaces + indentationSpaces) != newListItemIndentationSpaces)
            {
              @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                             reason:@"Indendation mismatch when beginning new list"
                                           userInfo:nil];
            }

            [listStack addObject:[NSNumber numberWithInt:newListType]];
          }
          else if (newListItemIndentationSpaces < currentListItemIndentationSpaces)
          {
            sectionContent = [self popListStack:listStack
                 untilListItemIndentationSpaces:newListItemIndentationSpaces
                               inSectionContent:sectionContent];
          }
          else
          {
            sectionContent = [sectionContent stringByAppendingString:@"</li>"];
          }

          // Remove matched string
          NSRange matchRange = [listRegexMatch range];
          sectionContentLine = [sectionContentLine substringFromIndex:NSMaxRange(matchRange)];

          sectionContent = [sectionContent stringByAppendingString:@"<li>"];
          sectionContent = [sectionContent stringByAppendingString:sectionContentLine];
        }
        else
        {
          if (listStack.count > 0)
          {
            NSTextCheckingResult* indentationRegexMatch = [indentationRegex firstMatchInString:sectionContentLine
                                                                                       options:0
                                                                                         range:NSMakeRange(0, sectionContentLine.length)];

            // No need to check for nil - the regex matches always
            NSString* substringIndentation = [sectionContentLine substringWithRange:[indentationRegexMatch rangeAtIndex:1]];
            NSInteger newLineIndentationSpaces = substringIndentation.length;

            sectionContent = [self popListStack:listStack
                     untilLineIndentationSpaces:newLineIndentationSpaces
                               inSectionContent:sectionContent];
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

  if (listStack.count > 0)
    sectionContent = [self closeListStack:listStack inSectionContent:sectionContent];
  else if (paragraphHasStarted)
    sectionContent = [sectionContent stringByAppendingString:@"</p>"];

  return [NSString stringWithFormat:@""
          "<html>"
          "<head>"
          "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>"
          "<meta name=\"viewport\" content=\"initial-scale=1.0\"/>"
          "<style type=\"text/css\">"
          ":root { color-scheme: light dark; --section-header-background-color: Lavender; --link-color: blue; }"
          "@media screen and (prefers-color-scheme: dark) { :root { --section-header-background-color: cornflowerblue; --link-color: #93d5ff; } }"
          "a { color: var(--link-color); }"
          "body { font-family:helvetica; font-size: small; }"
          "p.section-header { text-align: center; font-weight: bold; background-color: var(--section-header-background-color) }"
          "p.section { }"
          "</style>"
          "</head>"
          "<body>"
          "%@"
          "</body>"
          "</html>", sectionContent];
}

// -----------------------------------------------------------------------------
/// @brief Pops lists from the specified list stack, one after the other, until
/// the list stack is empty. Does nothing if the list stack is empty.
// -----------------------------------------------------------------------------
- (NSString*) closeListStack:(NSMutableArray*)listStack inSectionContent:(NSString*)sectionContent
{
  if (listStack.count == 0)
    return sectionContent;

  while (listStack.count > 0)
    sectionContent = [self popListStack:listStack inSectionContent:sectionContent];

  return sectionContent;
}

// -----------------------------------------------------------------------------
/// @brief Pops the list at the top of the specified list stack.
// -----------------------------------------------------------------------------
- (NSString*) popListStack:(NSMutableArray*)listStack inSectionContent:(NSString*)sectionContent
{
  sectionContent = [sectionContent stringByAppendingString:@"</li>"];

  NSNumber* listTypeAsNumber = [listStack lastObject];
  enum ListType listType = listTypeAsNumber.intValue;

  if (listType == ListTypeUnnumbered)
    sectionContent = [sectionContent stringByAppendingString:@"</ul>"];
  else
    sectionContent = [sectionContent stringByAppendingString:@"</ol>"];

  [listStack removeLastObject];

  return sectionContent;
}

// -----------------------------------------------------------------------------
/// @brief Pops lists from the specified list stack, one after the other, until
/// the list stack has reached the nesting level required for a line with the
/// specified number of indentation spaces. Does nothing If the list stack
/// is already at the required level.
///
/// Raises an @e NSInternalInconsistencyException if the list stack's nesting
/// level is currently below the required level.
// -----------------------------------------------------------------------------
- (NSString*) popListStack:(NSMutableArray*)listStack
untilLineIndentationSpaces:(NSInteger)indentationSpaces
          inSectionContent:(NSString*)sectionContent
{
  while (true)
  {
    NSInteger lineIndentationSpacesAtTopOfListStack = [self lineIndentationSpacesAtTopOfListStack:listStack];
    if (indentationSpaces == lineIndentationSpacesAtTopOfListStack)
    {
      break;
    }
    else if (indentationSpaces > lineIndentationSpacesAtTopOfListStack)
    {
      @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                     reason:@"Indendation mismatch"
                                   userInfo:nil];
    }

    sectionContent = [self popListStack:listStack inSectionContent:sectionContent];
  }

  return sectionContent;
}

// -----------------------------------------------------------------------------
/// @brief Pops lists from the specified list stack, one after the other, until
/// the list stack has reached the nesting level required for a list item with
/// the specified number of indentation spaces. Does nothing If the list stack
/// is already at the required level.
///
/// Raises an @e NSInternalInconsistencyException if the list stack's nesting
/// level is currently below the required level.
// -----------------------------------------------------------------------------
- (NSString*) popListStack:(NSMutableArray*)listStack
untilListItemIndentationSpaces:(NSInteger)indentationSpaces
          inSectionContent:(NSString*)sectionContent
{
  while (true)
  {
    NSInteger listItemIndentationSpacesAtTopOfListStack = [self listItemIndentationSpacesAtTopOfListStack:listStack];
    if (indentationSpaces == listItemIndentationSpacesAtTopOfListStack)
    {
      break;
    }
    else if (indentationSpaces > listItemIndentationSpacesAtTopOfListStack)
    {
      @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                     reason:@"Indendation mismatch"
                                   userInfo:nil];
    }

    sectionContent = [self popListStack:listStack inSectionContent:sectionContent];
  }

  return sectionContent;
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of indentation spaces needed for a line that
/// belongs to a list item that in turn belongs to the list currently at the
/// top of the specified list stack. Returns -1 if the list stack is empty.
// -----------------------------------------------------------------------------
- (NSInteger) lineIndentationSpacesAtTopOfListStack:(NSArray*)listStack
{
  if (listStack.count == 0)
    return -1;

  NSInteger indentationSpacesForLineAtTopOfListStack = 0;

  for (NSNumber* listTypeAsNumber in listStack)
  {
    enum ListType listType = listTypeAsNumber.intValue;

    if (listType == ListTypeUnnumbered)
      indentationSpacesForLineAtTopOfListStack += unnumberedIndentationSpaces;
    else
      indentationSpacesForLineAtTopOfListStack += numberedIndentationSpaces;
  }

  return indentationSpacesForLineAtTopOfListStack;
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of indentation spaces needed for a list item that
/// belongs to the list currently at the top of the specified list stack.
/// Returns -1 if the list stack is empty.
// -----------------------------------------------------------------------------
- (NSInteger) listItemIndentationSpacesAtTopOfListStack:(NSArray*)listStack
{
  if (listStack.count == 0)
    return -1;

  NSInteger listItemIndentationSpacesAtTopOfListStack = 0;

  int indentationSpacesOfPreviousList = 0;
  for (NSNumber* listTypeAsNumber in listStack)
  {
    listItemIndentationSpacesAtTopOfListStack += indentationSpacesOfPreviousList;

    enum ListType listType = listTypeAsNumber.intValue;

    if (listType == ListTypeUnnumbered)
      indentationSpacesOfPreviousList = unnumberedIndentationSpaces;
    else
      indentationSpacesOfPreviousList = numberedIndentationSpaces;
  }

  return listItemIndentationSpacesAtTopOfListStack;
}

@end
