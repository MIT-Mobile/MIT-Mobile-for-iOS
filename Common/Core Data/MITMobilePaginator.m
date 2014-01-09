#import "MITMobilePaginator.h"

@interface MITMobilePaginator ()
@property (nonatomic,copy) NSString *resourceName;
@property (nonatomic,copy) NSDictionary *parameters;

@property (nonatomic,strong) NSURL *firstPage;
@property (nonatomic,strong) NSURL *currentPage;
@property (nonatomic,strong) NSURL *nextPage;

@property (nonatomic,strong) NSMutableArray *pageStack;
@end


// 0th:
//  Next Page -> First Page -> Request
//  First Page -> First Page -> Request
//  Previous Page -> nop
//  Last Page -> nil or self.lastPage

// n-1th
//  Next Page -> self.nextPage
//  Previous Page -> [pageStack lastObject]
//  First Page -> [pageStack firstObject]
//  Last Page -> self.lastPage (optional)

// nth
//  Next Page -> nil
//  Previous Page -> [pageStack lastObject] or self.previousPage
//  First Page -> nil or self.firstPage or [pageStack firstObject]
//  Last Page -> self.currentPage


@implementation MITMobilePaginator
+ (NSRegularExpression*)linkHeaderRegularExpression
{
    static NSRegularExpression *linkHeaderRegularExpression = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"<([^>])>;\\s+rel=\"([a-z]+)\",?";
        NSError *error = nil;
        linkHeaderRegularExpression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:&error];

        NSAssert(linkHeaderRegularExpression, @"failed to create 'link' header regular expression: %@", error);
    });

    return linkHeaderRegularExpression;
}

- (instancetype)initWithResourceNamed:(NSString*)resourceName parameters:(NSDictionary*)parameters
{
    self = [super init];

    if (self) {
        _resourceName = [resourceName copy];
        _parameters = [parameters copy];
    }

    return self;
}

- (void)nextPage:(void (^)(NSArray *objects, NSError *error))block
{
    if (!self.firstPage) {

    }
}

- (void)previousPage:(void (^)(NSArray *objects, NSError *error))block
{

}

- (void)firstPage:(void (^)(NSArray *objects, NSError *error))block
{
    if ([self.pageStack count]) {

    }
}

- (void)lastPage:(void (^)(NSArray *objects, NSError *error))block
{

}

@end
