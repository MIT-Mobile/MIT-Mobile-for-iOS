#import "MITLibrariesHomeViewController.h"
#import "MITLibrariesWebservices.h"

@interface MITLibrariesHomeViewController ()

@property (nonatomic, strong) NSArray *links;

@end

@implementation MITLibrariesHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [MITLibrariesWebservices getLinksWithCompletion:^(NSArray *links, NSError *error) {
        if (links) {
            self.links = links;
            NSLog(@"links: %@", links);
        }
        else {
            self.links = @[];
        }
    }];
    
    [MITLibrariesWebservices getLibrariesWithCompletion:^(NSArray *libraries, NSError *error) {
        
    }];
    
    [MITLibrariesWebservices getResultsForSearch:@"bananas" startingIndex:0 completion:^(NSArray *items, NSInteger nextIndex, NSInteger totalResults, NSError *error) {
        if (items.count > 0) {
            [MITLibrariesWebservices getItemDetailsForItem:items[0] completion:^(MITLibrariesItem *item, NSError *error) {
                
            }];
        }
            
    }];
}

@end