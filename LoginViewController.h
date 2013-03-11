//
//  LoginViewController.h
//  FacebookLoginTest
//
//  Created by John Verrone on 1/24/13.
//  Copyright (c) 2013 John Verrone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface LoginViewController : UIViewController <FBLoginViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *inputText;
@property (weak, nonatomic) IBOutlet UIButton *authButton;
@property (weak, nonatomic) IBOutlet UILabel *profileName;
@property (weak, nonatomic) IBOutlet UILabel *authCode;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (strong, nonatomic) NSMutableDictionary *postParams;


- (IBAction)shareNativeDialog:(id)sender;
- (IBAction)shareAPI:(id)sender;


@end
