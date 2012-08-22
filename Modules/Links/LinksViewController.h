#import <UIKit/UIKit.h>
#import "MobileRequestOperation.h"
#import "MITLoadingActivityView.h"

@interface LinksViewController : UIViewController < UITableViewDataSource, UITableViewDelegate>
{
    NSArray         *_linkResults;
    UITableView     *table;
    BOOL requestWasDispatched;
    MITLoadingActivityView *_loadingView;
    
}

- (void) replaceTableViewWithUpdatedLinks;

// Table View Data Source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;

// Table View
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section;

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
