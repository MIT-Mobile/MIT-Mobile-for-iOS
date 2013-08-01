#import <UIKit/UIKit.h>
#import "WorldCatSearchController.h"

typedef enum {
    LinksStatusLoaded,
    LinksStatusLoading,
    LinksStatusFailed
} LinksStatus;

@interface LibrariesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate,UISearchDisplayDelegate>
@property (strong) WorldCatSearchController *searchController;
@property (readonly, copy) NSArray *links;
@property LinksStatus linksStatus;

@end
