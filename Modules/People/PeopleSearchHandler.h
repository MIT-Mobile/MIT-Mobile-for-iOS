//
//  PeopleSearchHandler.h
//  MIT Mobile
//
//  Created by YevDev on 5/26/14.
//
//

#import <Foundation/Foundation.h>

@interface PeopleSearchHandler : NSObject

@property (nonatomic, copy) NSString *searchTerms;
@property (nonatomic, copy) NSArray *searchTokens;
@property (nonatomic,copy) NSArray *searchResults;

@property BOOL searchCancelled;

- (void)performSearchWithCompletionHandler:(void(^)(BOOL isSuccess))completionHandler;

@end
