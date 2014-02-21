#import "CoreDataManager.h"
#import "LibrariesLocationsHoursViewController.h"
#import "LibrariesLocationsHoursDetailViewController.h"
#import "LibrariesLocationsHours.h"
#import "MITLoadingActivityView.h"
#import "MITUIConstants.h"
#import "MobileRequestOperation.h"
#import "MITMobileWebAPI.h"

@interface LibrariesLocationsHoursViewController ()
@property (nonatomic, weak) UIView *loadingView;
@end

@implementation LibrariesLocationsHoursViewController
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundView = nil;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    }
    self.title = @"Locations & Hours";
    
    if (!self.libraries) {
        if (!self.loadingView) {
            MITLoadingActivityView* loadingView = [[MITLoadingActivityView alloc] initWithFrame:self.view.bounds];
            loadingView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                                 UIViewAutoresizingFlexibleHeight);
            self.loadingView = loadingView;
            [self.view addSubview:self.loadingView];
        }
        
        MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"libraries"
                                                                                 command:@"locations"
                                                                              parameters:nil];
        request.completeBlock = ^(MobileRequestOperation *operation, NSArray *libraryItems, NSString *contentType, NSError *error) {
            if (error) {
                [UIAlertView alertViewForError:error withTitle:@"Libraries" alertViewDelegate:self];
            } else {
                [LibrariesLocationsHours removeAllLibraries];
                NSMutableArray *mutableLibraries = [NSMutableArray arrayWithCapacity:[libraryItems count]];
                
                for (NSDictionary *libraryItem in libraryItems) {
                    LibrariesLocationsHours *library = [LibrariesLocationsHours libraryWithDict:libraryItem];
                    [mutableLibraries addObject:library];
                }
                
                [CoreDataManager saveData];
                [self.loadingView removeFromSuperview];
                self.loadingView = nil;
                self.libraries = mutableLibraries;
                [self.tableView reloadData];
            }
        };

        [[NSOperationQueue mainQueue] addOperation:request];
    }
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.loadingView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.libraries) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.libraries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    }
    
    LibrariesLocationsHours *library = self.libraries[indexPath.row];
    cell.textLabel.text = library.title;
    cell.detailTextLabel.text = library.status;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LibrariesLocationsHoursDetailViewController *detailController = [[LibrariesLocationsHoursDetailViewController alloc] init];
    detailController.library = self.libraries[indexPath.row];
    [self.navigationController pushViewController:detailController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    CGFloat width = self.tableView.bounds.size.width;
    width -= 30;
    LibrariesLocationsHours *library = self.libraries[indexPath.row];
    CGSize titleSize = [library.title sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]
                                 constrainedToSize:CGSizeMake(width, 2000)];
    return titleSize.height + 2 * 11 + [UIFont systemFontOfSize:[UIFont smallSystemFontSize]].lineHeight;
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.navigationController.visibleViewController == self) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
