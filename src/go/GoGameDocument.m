// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoGameDocument.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoGameDocument.
// -----------------------------------------------------------------------------
@interface GoGameDocument()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSString* documentName;
//@}
@end


@implementation GoGameDocument

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameDocument object with its dirty flag set to false.
///
/// @note This is the designated initializer of GoGameDocument.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.dirty = false;
  self.documentName = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;

  _dirty = [decoder decodeBoolForKey:goGameDocumentDirtyKey];
  _documentName = [[decoder decodeObjectOfClass:[NSString class] forKey:goGameDocumentDocumentNameKey] retain];
  
  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSSecureCoding protocol method.
// -----------------------------------------------------------------------------
+ (BOOL) supportsSecureCoding
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoGameDocument object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.documentName = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeBool:self.isDirty forKey:goGameDocumentDirtyKey];
  [encoder encodeObject:self.documentName forKey:goGameDocumentDocumentNameKey];
}

// -----------------------------------------------------------------------------
/// @brief Notifies this GoGameDocument that the game was loaded.
///
/// Invoking this method clears the document's "dirty" flag and updates the
/// document name property with the value of @a documentName.
///
/// @note @a documentName is not a file name, i.e. it should not have an .sgf
/// extension.
// -----------------------------------------------------------------------------
- (void) load:(NSString*)documentName
{
  DDLogVerbose(@"Loading document, old dirty status = %d, old name = %@, new name = %@", self.isDirty, self.documentName, documentName);
  self.dirty = false;
  self.documentName = documentName;
}

// -----------------------------------------------------------------------------
/// @brief Notifies this GoGameDocument that the game was saved.
///
/// Invoking this method clears the document's "dirty" flag and updates the
/// document name property with the value of @a documentName.
///
/// @note @a documentName is not a file name, i.e. it should not have an .sgf
/// extension.
// -----------------------------------------------------------------------------
- (void) save:(NSString*)documentName
{
  DDLogVerbose(@"Saving document, old dirty status = %d, old name = %@, new name = %@", self.isDirty, self.documentName, documentName);
  self.dirty = false;
  self.documentName = documentName;
}

@end
