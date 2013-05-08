#import <UIKit/UIKit.h>
#import "WorldCatSearchController.h"

typedef enum {
    LinksStatusLoaded,
    LinksStatusLoading,
    LinksStatusFailed
} LinksStatus;

@interface LibrariesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate,UISearchDisplayDelegate>  {
    
}

@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSArray *links;
@property (nonatomic, retain) WorldCatSearchController *searchController;
@property LinksStatus linksStatus;

@end
