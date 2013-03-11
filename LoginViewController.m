//
//  LoginViewController.m
//  FacebookLoginTest
//
//  Created by John Verrone on 1/24/13.
//  Copyright (c) 2013 John Verrone. All rights reserved.
//

#import "LoginViewController.h"
#import "LoginAppDelegate.h"

@interface LoginViewController ()


@end

@implementation LoginViewController

NSString *curID = nil;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(sessionStateChanged:)
     name:FBSessionStateChangedNotification
     object:nil];
    
    // Check the session for a cached token to show the proper authenticated
    // UI. However, since this is not user intitiated, do not show the login UX.
    LoginAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate openSessionWithAllowLoginUI:NO];
    
    self.postParams =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     @"Game of Thrones: The North Remembers", @"name",
     @"Season 2, Episode 1", @"caption",
     @"Tyrion arrives at Kings Landing to take his father's place as Hand of the King. Stannis Baratheon plans to take the Iron Throne for his own. Robb tries to decide his next move in the war. The Night's Watch arrive at the house of Craster.", @"description",
     @"https://www.imdb.com/title/tt1971833/", @"link",
     @"http://images5.fanpop.com/image/photos/29400000/GOT-game-of-thrones-29426322-1600-1200.jpg", @"picture",
     nil];
    
    
    self.authButton.hidden = YES;
    self.profileName.text = nil;
    self.authCode.text = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)authButtonAction:(id)sender {
    LoginAppDelegate *appDelegate =
    [[UIApplication sharedApplication] delegate];
    
    // If the user is authenticated, log out when the button is clicked.
    // If the user is not authenticated, log in when the button is clicked.
    if (FBSession.activeSession.isOpen) {
        [appDelegate closeSession];
    } else {
        [appDelegate openSessionWithAllowLoginUI:YES];
    }
}

- (void)sessionStateChanged:(NSNotification*)notification {
    if (FBSession.activeSession.isOpen) {
        [FBRequestConnection
         startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                           id<FBGraphUser> user,
                                           NSError *error) {
             if (!error) {
                 self.profileName.text = user.name;
                 self.authCode.text = [[[FBSession activeSession] accessTokenData] accessToken];
                 self.authButton.hidden = NO;
             }
         }];
    } else {
        self.authButton.hidden = YES;
        self.authCode.text = nil;
        self.profileName.text = nil;
    }
}


/*
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}


- (IBAction)shareNativeDialog:(id)sender {
    LoginAppDelegate *appDelegate =
    [[UIApplication sharedApplication] delegate];
    
    if (!FBSession.activeSession.isOpen) {
        // The user has initiated a login, so call the openSession method
        // and show the login UX if necessary.
        [appDelegate openSessionWithAllowLoginUI:YES];
        
    }
    
    // If the user is authenticated, log out when the button is clicked.
    // If the user is not authenticated, log in when the button is clicked.
    if (FBSession.activeSession.isOpen) {
        
        // Put together the dialog parameters
        NSMutableDictionary *params =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
         @"Game of Thrones: The North Remembers", @"name",
         @"Season 2, Episode 1", @"caption",
         @"Tyrion arrives at Kings Landing to take his father's place as Hand of the King. Stannis Baratheon plans to take the Iron Throne for his own. Robb tries to decide his next move in the war. The Night's Watch arrive at the house of Craster.", @"description",
         @"https://www.imdb.com/title/tt1971833/", @"link",
         @"http://images5.fanpop.com/image/photos/29400000/GOT-game-of-thrones-29426322-1600-1200.jpg", @"picture",
         nil];
        
        // Invoke the dialog
        [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                               parameters:params
                                                  handler:
         ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
             if (error) {
                 // Case A: Error launching the dialog or publishing story.
                 NSLog(@"Error publishing story.");
             } else {
                 if (result == FBWebDialogResultDialogNotCompleted) {
                     // Case B: User clicked the "x" icon
                     NSLog(@"User canceled story publishing.");
                 } else {
                     // Case C: Dialog shown and the user clicks Cancel or Share
                     NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                     if (![urlParams valueForKey:@"post_id"]) {
                         // User clicked the Cancel button
                         NSLog(@"User canceled story publishing.");
                     } else {
                         // User clicked the Share button
                         NSString *postID = [urlParams valueForKey:@"post_id"];
                         NSLog(@"Posted story, id: %@", postID);
                     }
                 }
             }
         }];
    }
    
}

- (IBAction)shareAPI:(id)sender {
    
    // Hide keyboard if showing when button clicked
    if ([self.inputText isFirstResponder]) {
        [self.inputText resignFirstResponder];
    }
    
    LoginAppDelegate *appDelegate =
    [[UIApplication sharedApplication] delegate];
    
    if (!FBSession.activeSession.isOpen) {
        // The user has initiated a login, so call the openSession method
        // and show the login UX if necessary.
        [appDelegate openSessionWithAllowLoginUI:YES];
        
    } else {
        [self.postParams setObject:self.inputText.text
                            forKey:@"message"];
        [self publishStory];
    }
}

- (void)publishStory {
    [FBRequestConnection
     startWithGraphPath:@"me/feed"
     parameters:self.postParams
     HTTPMethod:@"POST"
     completionHandler:^(FBRequestConnection *connection,
                         id result,
                         NSError *error) {
         NSString *alertText;
         if (error) {
             alertText = [NSString stringWithFormat:
                          @"error: domain = %@, code = %d",
                          error.domain, error.code];
         } else {
             alertText = [NSString stringWithFormat:
                          @"Posted action, id: %@",
                          [result objectForKey:@"id"]];
         }
         // Show the result in an alert
         [[[UIAlertView alloc] initWithTitle:@"Result"
                                     message:alertText
                                    delegate:self
                           cancelButtonTitle:@"OK!"
                           otherButtonTitles:nil]
          show];
     }];
    
}
@end
