#import <UIKit/UIKit.h>

typedef enum {
    LinksStatusLoaded,
    LinksStatusLoading,
    LinksStatusFailed
} LinksStatus;

@interface LibrariesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, JSONLoadedDelegate>  {
    
}

@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) MITMobileWebAPI *linksRequest;
@property (nonatomic, retain) NSArray *links;
@property LinksStatus linksStatus;

@end
