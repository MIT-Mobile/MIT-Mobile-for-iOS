#import "CMModule.h"

@implementation CMModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagCampusMap title:@"Map"];
    if (self != nil) {
        self.longTitle = @"Campus Map";
        self.imageName = MITImageMapModuleIcon;
    }

    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    MITMapHomeViewController *rootViewController = [[MITMapHomeViewController alloc] init];
    self.rootViewController = rootViewController;
}

- (void)didReceiveRequestWithURL:(NSURL *)url
{
    [super didReceiveRequestWithURL:url];
    NSString *urlString = [url absoluteString];
    NSString *baseURLString = [self baseURLString];
    if ([urlString hasPrefix:baseURLString]) {
        NSString *queryString = [urlString substringFromIndex:baseURLString.length];
        NSArray *queryComponents = [queryString componentsSeparatedByString:@"/"];
        if (queryComponents.count != 2) {
            NSLog(@"Invalid number of components in url: %@. If you would like to use more components, this method should be revisited.", queryString);
            return;
        }
        NSString *queryParameter = queryComponents.firstObject;
        NSString *query = queryComponents.lastObject;
        [self.rootViewController handleURLQuery:query forQueryParameter:queryParameter];
    }
}

- (NSString *)baseURLString
{
    return [NSString stringWithFormat:@"%@://%@/",MITInternalURLScheme,MITModuleTagCampusMap];
}

@end
