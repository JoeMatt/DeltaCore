//
//  DeltaCore.h
//  DeltaCore
//
//  Created by Joseph Mattiello on 2/6/23.
//  Copyright (c) 2023 Joseph Mattiello. All rights reserved.
//

#import <Foundation/Foundation.h>
//! Project version number for DeltaCore.
FOUNDATION_EXPORT double DeltaCoreVersionNumber;

//! Project version string for DeltaCore.
FOUNDATION_EXPORT const unsigned char DeltaCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DeltaCore/PublicHeader.h>
typedef NSString *GameType NS_TYPED_EXTENSIBLE_ENUM;
typedef NSString *CheatType NS_TYPED_EXTENSIBLE_ENUM;
typedef NSString *GameControllerInputType NS_TYPED_EXTENSIBLE_ENUM;

extern NSNotificationName const DeltaRegistrationRequestNotification;

// HACK: Needed because the generated DeltaCore-Swift header file uses @import syntax, which isn't supported in Objective-C++ code.
#ifdef __cplusplus
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#endif

//#if __has_include("<UIKit/UIKit.h>")
#import <UIKit/UIKit.h>

// Used by GameWindow.
@interface UIWindow (Private)

@property (nullable, weak, nonatomic, setter=_setLastFirstResponder:) UIResponder *_lastFirstResponder /* API_AVAILABLE(ios(16)) */;
- (void)_restoreFirstResponder /* API_AVAILABLE(ios(16)) */;

@end

//#endif
