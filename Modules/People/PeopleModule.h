#import "MITNavigationModule.h"
#import "PeopleSearchViewController.h"

@interface PeopleModule : MITNavigationModule
@property(nonatomic,strong) PeopleSearchViewController *rootViewController;

- (instancetype)init;
@end

