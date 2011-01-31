
#import <Foundation/Foundation.h>
#import "StellarModel.h"
#import "MITSearchDisplayController.h"

@class StellarMainTableController;

@interface StellarSearch : NSObject <
	UITableViewDataSource, 
	UITableViewDelegate, 
	UISearchBarDelegate,
    MITSearchDisplayDelegate,
	UIAlertViewDelegate,
	ClassesSearchDelegate> {

		BOOL activeMode;
		BOOL hasSearchInitiated;
		NSArray *lastResults;
		StellarMainTableController *viewController;
		UISearchBar *searchBar;
}

@property (nonatomic, retain) NSArray *lastResults;
@property (nonatomic, readonly) BOOL activeMode;
@property (nonatomic, retain) UISearchBar *searchBar;

- (id) initWithSearchBar: (UISearchBar *)theSearchBar viewController: (StellarMainTableController *)controller;

- (void) endSearchMode;

- (BOOL) isSearchResultsVisible;

@end
