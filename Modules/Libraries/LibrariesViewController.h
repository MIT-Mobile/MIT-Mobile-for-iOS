#import <UIKit/UIKit.h>

typedef enum {
    LinksStatusLoaded,
    LinksStatusLoading,
    LinksStatusFailed
} LinksStatus;

@interface LibrariesViewController : UITableViewController <JSONLoadedDelegate>  {
    
}

@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) MITMobileWebAPI *linksRequest;
@property (nonatomic, retain) NSArray *links;
@property LinksStatus linksStatus;

@end
