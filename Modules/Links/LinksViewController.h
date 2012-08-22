#import <UIKit/UIKit.h>
#import "MITMobileWebApi.h"
#import "MITLoadingActivityView.h"

@interface LinksViewController : UIViewController <JSONLoadedDelegate, UITableViewDataSource, UITableViewDelegate>
{
    UITableView *table;
    BOOL requestWasDispatched;
	MITMobileWebAPI *api;
    MITLoadingActivityView *_loadingView;
    
}

@property (nonatomic, retain) NSArray * linkResults;           // array holds sections of links

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject;
- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error;


// Table View Data Source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;

// Table View
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section;

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section;

@end
