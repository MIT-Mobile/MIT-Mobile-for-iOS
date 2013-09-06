#import "FacilitiesTypeViewController.h"
#import "FacilitiesSummaryViewController.h"
#import "FacilitiesConstants.h"
#import "FacilitiesLocationData.h"
#import "UIKit+MITAdditions.h"
#import "FacilitiesRepairType.h"
#import <QuartzCore/QuartzCore.h>

@interface FacilitiesTypeViewController ()
@property (nonatomic,retain) id observerToken;
@end

@implementation FacilitiesTypeViewController
@synthesize userData = _userData;
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;

- (id)init {
    self = [super init];
    
    if (self) {
        self.title = @"What is it?";
        self.userData = nil;
    }
    
    return self;
}

- (NSArray*)repairTypes {
    return [[FacilitiesLocationData sharedData] allRepairTypes];
}

#pragma mark - View lifecycle
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    screenFrame.origin = CGPointZero;

    UIView *mainView = [[UIView alloc] initWithFrame:screenFrame];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor mit_backgroundColor];

    {
        CGRect tableRect = screenFrame;
        UITableView *tableView = [[UITableView alloc] initWithFrame: tableRect
                                                               style: UITableViewStyleGrouped];
        [tableView applyStandardColors];

        tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth);
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.hidden = YES;
        tableView.scrollEnabled = YES;
        tableView.autoresizesSubviews = YES;

        self.tableView = tableView;
        [mainView addSubview:tableView];
    }

    {
        CGRect loadingFrame = screenFrame;
        MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:loadingFrame];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                             UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor clearColor];

        self.loadingView = loadingView;
        [mainView insertSubview:loadingView
                   aboveSubview:self.tableView];
    }

    self.view = mainView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.observerToken == nil) {
        self.observerToken = [[FacilitiesLocationData sharedData] addUpdateObserver:^(NSString *name, BOOL dataUpdated, id userData) {
                                                   if ([userData isEqualToString:FacilitiesRepairTypesKey]) {
                                                       [self.loadingView removeFromSuperview];
                                                       self.loadingView = nil;
                                                       self.tableView.hidden = NO;
                                                       
                                                       if (dataUpdated) {
                                                           [self.tableView reloadData];
                                                       }
                                                   }
                                               }];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    if (self.observerToken) {
        [[FacilitiesLocationData sharedData] removeUpdateObserver:self.observerToken];
        self.observerToken = nil;
    }
    
    self.tableView = nil;
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

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self repairTypes] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"typeCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:reuseIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    FacilitiesRepairType *type = (FacilitiesRepairType *)[[self repairTypes] objectAtIndex:indexPath.row];
    cell.textLabel.text = type.name;

    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.userData];
    [dict setObject:[[self repairTypes] objectAtIndex:indexPath.row]
             forKey:FacilitiesRequestRepairTypeKey];
    
    FacilitiesSummaryViewController *vc = [[FacilitiesSummaryViewController alloc] init];
    vc.reportData = dict;
    [self.navigationController pushViewController:vc
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}
@end
