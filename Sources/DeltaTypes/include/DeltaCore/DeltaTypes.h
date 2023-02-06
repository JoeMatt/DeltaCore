//
//  DeltaTypes.h
//  DeltaTypes
//
//  Created by Joseph Mattiello on 2/6/23.
//  Copyright (c) 2023 Joseph Mattiello. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for DeltaTypes.
FOUNDATION_EXPORT double DeltaTypesVersionNumber;

//! Project version string for DeltaTypes.
FOUNDATION_EXPORT const unsigned char DeltaTypesVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DeltaTypes/PublicHeader.h>
typedef NSString *GameType NS_TYPED_EXTENSIBLE_ENUM;
typedef NSString *CheatType NS_TYPED_EXTENSIBLE_ENUM;
typedef NSString *GameControllerInputType NS_TYPED_EXTENSIBLE_ENUM;

extern NSNotificationName const DeltaRegistrationRequestNotification;

// HACK: Needed because the generated DeltaTypes-Swift header file uses @import syntax, which isn't supported in Objective-C++ code.
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
