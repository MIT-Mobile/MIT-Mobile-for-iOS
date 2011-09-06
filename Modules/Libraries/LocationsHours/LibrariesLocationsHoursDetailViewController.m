#import "LibrariesLocationsHoursDetailViewController.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"

#define TITLE_ROW 0
#define LOADING_STATUS_ROW 1
#define PHONE_ROW 1
#define LOCATION_ROW 2

@implementation LibrariesLocationsHoursDetailViewController
@synthesize library;
@synthesize librariesDetailStatus;
@synthesize request;

- (void)dealloc
{
    self.request = nil;
    self.library = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView applyStandardColors];
    
    self.title = @"Detail";

    if (![self.library hasDetails]) {
        self.librariesDetailStatus = LibrariesDetailStatusLoading;
        
        NSDictionary *params = [NSDictionary dictionaryWithObject:self.library.title forKey:@"library"];
        self.request = [[[MITMobileWebAPI alloc] initWithModule:@"libraries" command:@"locationDetail" parameters:params] autorelease];
        self.request.jsonDelegate = self;
        [self.request start];
    } else {
        self.librariesDetailStatus = LibrariesDetailStatusLoaded;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.librariesDetailStatus == LibrariesDetailStatusLoaded) {
        return 3; // title, phone, location
    } else {
        return 2; // title, loading indicator
    }
}

- (UITableViewCell *)defaultRowWithTable:(UITableView *)tableView {
    NSString *cellIdentifier = @"defaultRow";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier]autorelease];
        [cell applyStandardFonts];
    }  
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.row == TITLE_ROW) {
        cell = [self defaultRowWithTable:tableView];
        cell.textLabel.text = self.library.title;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        if (self.librariesDetailStatus != LibrariesDetailStatusLoaded) {
            cell = [self defaultRowWithTable:tableView];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;            
            if (self.librariesDetailStatus == LibrariesDetailStatusLoading) {
                cell.textLabel.text = @"Loading...";
            } else if (self.librariesDetailStatus == LibrariesDetailStatusLoadingFailed) {
                cell.textLabel.text = @"Failed loading details";
            }
        } else {
            if (indexPath.row == PHONE_ROW) {
                cell = [self defaultRowWithTable:tableView];
                cell.textLabel.text = self.library.telephone;
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            } else if (indexPath.row == LOCATION_ROW) {
                cell = [self defaultRowWithTable:tableView];
                cell.textLabel.text = [NSString stringWithFormat:@"Room %@", self.library.location];
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
        }
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.librariesDetailStatus == LibrariesDetailStatusLoaded) {
        if (indexPath.row == PHONE_ROW) {
            NSString *phoneNumber = [self.library.telephone stringByReplacingOccurrencesOfString:@"." withString:@""];
            NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
            if ([[UIApplication sharedApplication] canOpenURL:externURL])
                [[UIApplication sharedApplication] openURL:externURL];
        } else if (indexPath.row == LOCATION_ROW) {
            [[UIApplication sharedApplication] openURL:[NSURL internalURLWithModuleTag:CampusMapTag path:@"search" query:self.library.location]];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - JSONLoaded delegate methods

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
    [self.library updateDetailsWithDict:JSONObject];
    [CoreDataManager saveData];
    self.librariesDetailStatus = LibrariesDetailStatusLoaded;
    [self.tableView reloadData];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
    return NO;
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
    self.librariesDetailStatus = LibrariesDetailStatusLoadingFailed;
    [self.tableView reloadData];
}



@end
