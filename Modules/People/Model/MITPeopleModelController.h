//
//  MITPeopleModelController.h
//  MIT Mobile
//
//  Created by Yev Motov on 7/18/14.
//
//

#import <Foundation/Foundation.h>

@interface MITPeopleModelController : NSObject

- (NSArray *)recentSearchTermsWithFilterString:(NSString *)filterString;
- (void)addRecentSearchTerm:(NSString *)searchTerm error:(NSError *)error;
- (void)clearRecentSearchTermsWithError:(NSError *)error;

@end
