#import "PeopleModule.h"
#import "MITModuleURL.h"
#import "PeopleSearchViewController.h"
#import "PeopleDetailsViewController.h"
#import "PeopleRecentsData.h"
#import "PersonDetails.h"
#import "MITAdditions.h"

static NSString * const PeopleStateSearchBegin = @"search-begin";
static NSString * const PeopleStateSearchComplete = @"search-complete";
static NSString * const PeopleStateSearchExternal = @"search";
static NSString * const PeopleStateDetail = @"detail";

@interface PeopleModule()

@property (nonatomic,readonly) PeopleSearchViewController *peopleController;

@end

@implementation PeopleModule
@synthesize peopleController = _peopleController;

- (id)init
{
    self = [super initWithName:MITModuleTagDirectory title:@"Directory"];
    if (self) {
        self.longTitle = @"People Directory";
        self.imageName = @"people";
    }

    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    UIUserInterfaceIdiom currentUserInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];

    UIStoryboard *storyboard = nil;
    if (currentUserInterfaceIdiom) {
        storyboard = [UIStoryboard storyboardWithName:@"People" bundle:nil];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"People_iPad" bundle:nil];
    }

    NSAssert(storyboard, @"failed to load storyboard for %@",self);
    self.rootViewController = [storyboard instantiateInitialViewController];
}

- (void)didReceiveRequestWithURL:(NSURL *)url
{
    [super didReceiveRequestWithURL:url];

    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:url.pathComponents];
    if ([[pathComponents firstObject] isEqualToString:@"/"]) {

    }

    NSString *action = [pathComponents firstObject];
    if (!action) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        return;
    }

    NSString *query = [url.query urlDecodeUsingEncoding:NSUTF8StringEncoding];
    if ([action isEqualToString:PeopleStateSearchBegin]) {
        self.rootViewController.searchBar.text = query;
        [self.rootViewController.searchDisplayController setActive:YES animated:NO];
        return;
    }

    if ([query length]) {
        if ([action isEqualToString:PeopleStateSearchComplete]) {
            [self.peopleController beginExternalSearch:query];
        } else if ([action isEqualToString:PeopleStateSearchExternal]) {
            [self.rootViewController beginExternalSearch:query];
        } else if ([action isEqualToString:PeopleStateDetail]) {
            PersonDetails *person = [PeopleRecentsData personWithUID:query];
            if (person) {
                PeopleDetailsViewController *detailVC = [[PeopleDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                detailVC.personDetails = person;

                [self.navigationController pushViewController:detailVC animated:NO];
            }
        }
    }
}

@end
