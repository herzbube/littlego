// -----------------------------------------------------------------------------
// Copyright 2024 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The UserManualUtilities class is a container for various utility
/// functions related to managing the user manual.
///
/// All functions in UserManualUtilities are class methods, so there is no need
/// to create an instance of UserManualUtilities.
// -----------------------------------------------------------------------------
@interface UserManualUtilities : NSObject
{
}

+ (NSString*) userManualBaseFolderPath;
+ (NSString*) filePathForUserManualFileNamed:(NSString*)fileName fileExists:(BOOL*)fileExists;
+ (NSString*) userManualEntryPointFilePath;

@end
