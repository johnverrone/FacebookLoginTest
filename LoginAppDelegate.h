//
//  LoginAppDelegate.h
//  FacebookLoginTest
//
//  Created by John Verrone on 1/24/13.
//  Copyright (c) 2013 John Verrone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>
#import "MyTokenCachingStrategy.h"

extern NSString *const FBSessionStateChangedNotification;

@interface LoginAppDelegate : UIResponder <UIApplicationDelegate>

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (void) closeSession;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) MyTokenCachingStrategy *tokenCaching;

@end
