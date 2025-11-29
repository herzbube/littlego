// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The FilesystemOperations class is a container for filesystem
/// functions that perform filesystem-related operations.
///
/// All functions in FilesystemOperations are class methods, so there is no need
/// to create an instance of AccessibilityUtility.
///
/// The implementation of the functions in FilesystemOperations is designed
/// to go reasonably well together with the notifications sent by
/// FilesystemMonitor to its delegate. See the documentation of the individual
/// class methods for which notifications to expect.
// -----------------------------------------------------------------------------
@interface FilesystemOperations : NSObject
{
}

+ (bool) copyItemAtPath:(NSString*)sourcePath
          overwritePath:(NSString*)destinationPath
              errorCode:(int*)errorCode;
+ (bool) moveItemAtPath:(NSString*)sourcePath
          overwritePath:(NSString*)destinationPath
              errorCode:(int*)errorCode;
+ (bool) deleteItemIfExists:(NSString*)path
       numberOfItemsDeleted:(unsigned long*)numberOfItemsDeleted
                  errorCode:(int*)errorCode;

@end
