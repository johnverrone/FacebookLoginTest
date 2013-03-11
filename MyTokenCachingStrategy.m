//
//  MyTokenCachingStrategy.m
//  FacebookLoginTest
//
//  Created by John Verrone on 1/28/13.
//  Copyright (c) 2013 John Verrone. All rights reserved.
//

#import "MyTokenCachingStrategy.h"
#import "JSONKit.h"

// Remote cache - back-end server
static NSString* kBackendURL = @"http://coxcommtest.zxq.net/token.php";

// Remote cache - date format
static NSString* kDateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZ";

@interface MyTokenCachingStrategy ()

@end

@implementation MyTokenCachingStrategy

- (id) init
{
    self = [super init];
    if (self) {
        _thirdPartySessionId = @"";
    }
    return self;
}

/*
 * Helper method to look for strings that represent dates and
 * convert them to NSDate objects.
 */
- (NSMutableDictionary *) dictionaryDateParse: (NSDictionary *) data {
    // Date format for date checks
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDateFormat];
    // Dictionary to return
    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
    // Enumerate through the input dictionary
    [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        // Check if strings are dates
        if ([obj isKindOfClass:[NSString class]]) {
            NSDate *objDate = nil;
            BOOL isDate = [dateFormatter getObjectValue:&objDate
                                              forString:obj
                                       errorDescription:nil];
            if (isDate) {
                [resultDictionary setObject:objDate forKey:key];
            } else {
                [resultDictionary setObject:obj forKey:key];
            }
        } else {
            // Non-string, just keep as-is
            [resultDictionary setObject:obj forKey:key];
        }
    }];
    return resultDictionary;
}

/*
 * Helper method to check the back-end server response
 * for both reads and writes.
 */
- (NSDictionary *) handleResponse:(NSData *)responseData {
    // String representation of HTTP response data
    NSString* responseString = [[NSString alloc]
                                initWithData:responseData
                                encoding:NSUTF8StringEncoding];
    id result = [responseString objectFromJSONString];
    // Check for a properly formatted response
    if ([result isKindOfClass:[NSDictionary class]] &&
        [result objectForKey:@"status"]) {
        // Check if we got a success case back
        BOOL success = [[result objectForKey:@"status"] boolValue];
        if (!success) {
            // Handle the error case
            NSLog(@"Error: %@", [result objectForKey:@"errorMessage"]);
            return nil;
        } else {
            // Check for returned token data (in the case of read requests)
            if ([result objectForKey:@"token_info"]) {
                // Create an NSDictionary of the token data
                NSDictionary *tokenResult = [[result objectForKey:@"token_info"]
                                             objectFromJSONString];
                // Check if valid data returned, i.e. not nil
                if ([tokenResult isKindOfClass:[NSDictionary class]]) {
                    // Parse the results to handle conversion for
                    // date values.
                    return [self dictionaryDateParse:tokenResult];
                } else {
                    return nil;
                }
            } else {
                return nil;
            }
        }
    } else {
        NSLog(@"Error, did not get any data back");
        return nil;
    }
}

- (void) writeData:(NSDictionary *) data {
    NSLog(@"WriteData = %@", data);
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDateFormat];
    NSString *jsonDataString = [data JSONStringWithOptions:JKParseOptionNone
                     serializeUnsupportedClassesUsingBlock:^id(id object) {
                         // JSONKit does not support dates, so convert date
                         // objects to a formatted string.
                         if([object isKindOfClass:[NSDate class]]) {
                             return([dateFormatter stringFromDate:object]);
                         } else {
                             return nil;
                         }
                     }
                                                     error:nil];
    NSURLResponse *response = nil;
    NSError *error = nil;
    // Set up a URL request to the back-end server
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:
                                       [NSURL URLWithString:kBackendURL]];
    // Configure an HTTP POST
    [urlRequest setHTTPMethod:@"POST"];
    // Pass in post data: the unique ID and the JSON string
    // representation of the token data.
    NSString *postData = [NSString stringWithFormat:@"unique_id=%@&token_info=%@",
                          self.thirdPartySessionId,jsonDataString];
    [urlRequest setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    // Make a synchronous request
    NSData *responseData = (NSMutableData *)[NSURLConnection
                                             sendSynchronousRequest:urlRequest
                                             returningResponse:&response
                                             error:&error];
    // Process the returned data
    [self handleResponse:responseData];
}

- (NSDictionary *) readData {
    NSURLResponse *response = nil;
    NSError *error = nil;
    // Set up a URL request to the back-end server, a
    // GET request with the unique ID passed in.
    NSString *urlString = [NSString stringWithFormat:@"%@?unique_id=%@",
                           kBackendURL, self.thirdPartySessionId];
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:
                                [NSURL URLWithString:urlString]];
    // Make a synchronous request
    NSData *responseData = (NSMutableData *)[NSURLConnection
                                             sendSynchronousRequest:urlRequest
                                             returningResponse:&response
                                             error:&error];
    if (nil != responseData) {
        // Process the returned data
        return [self handleResponse:responseData];
    } else {
        return nil;
    }
}

- (void)cacheTokenInformation:(NSDictionary*)tokenInformation {
    [self writeData:tokenInformation];
}

- (NSDictionary*)fetchTokenInformation;
{
    return [self readData];
}

- (void)clearToken
{
    [self writeData:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
}

@end
