#import "MITResultsPager.h"
#import "MITMobile.h"

@interface MITResultsPager ()
@property (nonatomic,strong) NSHTTPURLResponse *response;

@property (nonatomic,strong) NSURL *previousPageURL;
@property (nonatomic,strong) NSURL *nextPageURL;

@property (nonatomic,strong) NSURL *firstPageURL;
@property (nonatomic,strong) NSURL *lastPageURL;
@end

@implementation MITResultsPager
+ (NSRegularExpression*)linkHeaderRegularExpression
{
    static NSRegularExpression *linkHeaderRegularExpression = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"<([^>])>;\\s+rel=\"([a-z]+)\"(?:, )?";
        NSError *error = nil;
        linkHeaderRegularExpression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:&error];
        
        NSAssert(linkHeaderRegularExpression, @"failed to create 'link' header regular expression: %@", error);
    });
    
    return linkHeaderRegularExpression;
}

+ (instancetype)resultsPagerWithResponse:(NSHTTPURLResponse*)response
{
    NSParameterAssert(response);
    MITResultsPager *resultsPager = [[MITResultsPager alloc] init];
    resultsPager.response = response;
    
    return resultsPager;
}

- (BOOL)firstPage:(void (^)(NSArray *objects, NSError *error))block
{
    if (self.firstPageURL) {
        __weak MITResultsPager *weakSelf = self;
        [[MITMobile defaultManager] getObjectsForURL:self.firstPageURL
                                          completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                              MITResultsPager *blockSelf = weakSelf;
                                              if (blockSelf) {
                                                  if (!error) {
                                                      blockSelf.response = response;
                                                  }
                                                  
                                                  if (block) {
                                                      block([result array], error);
                                                  }
                                              }
                                          }];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)lastPage:(void (^)(NSArray *objects, NSError *error))block
{
    if (self.lastPageURL) {
        __weak MITResultsPager *weakSelf = self;
        [[MITMobile defaultManager] getObjectsForURL:self.lastPageURL
                                          completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                              MITResultsPager *blockSelf = weakSelf;
                                              if (blockSelf) {
                                                  if (!error) {
                                                      blockSelf.response = response;
                                                  }
                                                  
                                                  if (block) {
                                                      block([result array], error);
                                                  }
                                              }
                                          }];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)nextPage:(void (^)(NSArray *objects, NSError *error))block
{
    if (self.nextPageURL) {
        __weak MITResultsPager *weakSelf = self;
        [[MITMobile defaultManager] getObjectsForURL:self.nextPageURL
                                          completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                              MITResultsPager *blockSelf = weakSelf;
                                              if (blockSelf) {
                                                  if (!error) {
                                                      blockSelf.response = response;
                                                  }
                                                  
                                                  if (block) {
                                                      block([result array], error);
                                                  }
                                              }
                                          }];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)previousPage:(void (^)(NSArray *objects, NSError *error))block
{
    if (self.previousPageURL) {
        __weak MITResultsPager *weakSelf = self;
        [[MITMobile defaultManager] getObjectsForURL:self.previousPageURL
                                          completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                              MITResultsPager *blockSelf = weakSelf;
                                              if (blockSelf) {
                                                  if (!error) {
                                                      blockSelf.response = response;
                                                  }
                                                  
                                                  if (block) {
                                                      block([result array], error);
                                                  }
                                              }
                                          }];
        return YES;
    } else {
        return NO;
    }
}

- (void)setResponse:(NSHTTPURLResponse *)response
{
    if (![_response isEqual:response]) {
        _response = response;
        
        NSString *linkHeader = [response allHeaderFields][@"Link"];
        NSRegularExpression *linkRegExp = [MITResultsPager linkHeaderRegularExpression];
        
        [[linkHeader componentsSeparatedByString:@","] enumerateObjectsUsingBlock:^(NSString *link, NSUInteger idx, BOOL *stop) {
            NSString *trimmedLink = [link stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [linkRegExp enumerateMatchesInString:trimmedLink options:0
                                           range:NSMakeRange(0, [trimmedLink length])
                                      usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                          if ([result numberOfRanges] != 3) {
                                              NSRange fullRange = [result rangeAtIndex:0];
                                              DDLogWarn(@"invalid 'Link' value '%@'",[link substringWithRange:fullRange]);
                                          } else {
                                              NSString *urlString = [link substringWithRange:[result rangeAtIndex:1]];
                                              NSURL *url = [NSURL URLWithString:urlString];
                                              
                                              NSString *type = [link substringWithRange:[result rangeAtIndex:2]];
                                              if ([type isEqualToString:@"next"]) {
                                                  self.nextPageURL = url;
                                              } else if ([type isEqualToString:@"first"]) {
                                                  self.firstPageURL = url;
                                              } else {
                                                  DDLogVerbose(@"Setting '%@' to '%@'",type,url);
                                              }
                                          }
                                      }];
        }];
    }
}

@end
