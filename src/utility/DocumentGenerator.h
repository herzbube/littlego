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


// Forward declarations
@class NSString;


// -----------------------------------------------------------------------------
/// @brief The DocumentGenerator class parses a text file and generates a set
/// of HTML documents from the file content. The HTML documents can then be
/// conveniently displayed in a WKWebView.
///
/// DocumentGenerator assumes that the text file is structured according to
/// the following rules:
/// - The document is partitioned into groups and sections
/// - Sections are the main structuring element of the text file, while groups
///   are a simple means to provide sections with a common heading
/// - DocumentGenerator creates one HTML document for each section
/// - A section has a title and a content; the section title can be used to
///   refer to the HTML document in the GUI, the section content is also the
///   content of the HTML document
/// - The leadin for a section is a separator line that begins with 3 or more
///   dashes, i.e. "---"
/// - The single line below the separator is the section title
/// - If another separator line is found below the section title it is ignored
/// - All lines below the separator, until either the next group title, section
///   title or until end-of-file, form the section content
/// - Group titles are defined exactly the same as section titles, with the
///   exception that separator lines begin with 3 or more asterisks, i.e. "***"
/// - If the text file does not contain an explicit group title,
///   DocumentGenerator still adds one implicit group, albeit without a title
///
/// DocumentGenerator parses the section content lines for a few patterns to
/// generate the following markup within the section's HTML document:
/// - Subsection titles
///   - A specially marked up title paragraph is created if a separator line is
///     found that begins with 3 or more equal signs, i.e. "==="
///   - The single line below the separator is the subsection title
///   - If another separator line is found below the subsection title it is
///     ignored
/// - An empty line, or a line that contains only whitespace, starts a new
///   paragraph
/// - Lists
///   - A line that starts with "- " starts a new unnumberd list, or a new list
///     item if a list has already been started by a previous item
///   - The list is terminated by an empty line, or a line that contains only
///     whitespace
///   - Ditto for numbered lists, but the line must start with "1. "
///   - Lists can be arbitrarily nested.
/// - URLs (e.g. http://) are used to create anchor HTML elements
// -----------------------------------------------------------------------------
@interface DocumentGenerator : NSObject
{
}

- (id) initWithFileContent:(NSString*)fileContent;
- (NSString*) titleForGroup:(int)groupIndex;
- (int) numberOfSectionsInGroup:(int)groupIndex;
- (NSString*) titleForSection:(int)sectionIndex inGroup:(int)groupIndex;
- (NSString*) contentForSection:(int)sectionIndex inGroup:(int)groupIndex;

@property(nonatomic, assign, readonly) int numberOfGroups;

@end
