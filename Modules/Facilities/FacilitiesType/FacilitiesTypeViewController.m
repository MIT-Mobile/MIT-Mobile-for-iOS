#import "FacilitiesTypeViewController.h"
#import "FacilitiesSummaryViewController.h"
#import "FacilitiesConstants.h"
#import "FacilitiesLocationData.h"
#import "UIKit+MITAdditions.h"
#import "FacilitiesRepairType.h"
#import <QuartzCore/QuartzCore.h>

@interface FacilitiesTypeViewController ()
{
    NSArray *_problemTypes;
}
@property (nonatomic,retain) id observerToken;
@end

@implementation FacilitiesTypeViewController
@synthesize userData = _userData;
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;
@dynamic problemTypes;

- (id)init {
    self = [super init];
    
    if (self) {
        self.title = @"What is it?";
        self.userData = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.userData = nil;
    self.tableView = nil;
    self.view = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSArray*)repairTypes {
    return [[FacilitiesLocationData sharedData] allRepairTypes];
}

#pragma mark - View lifecycle
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    screenFrame.origin = CGPointZero;

    UIView *mainView = [[[UIView alloc] initWithFrame:screenFrame] autorelease];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor clearColor];

    {
        CGRect tableRect = screenFrame;
        UITableView *tableView = [[[UITableView alloc] initWithFrame: tableRect
                                                               style: UITableViewStyleGrouped] autorelease];
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
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.observerToken == nil) {
        self.observerToken = [[FacilitiesLocationData sharedData] addUpdateObserver:^(NSString *name, BOOL dataUpdated, id userData) {
                                                   if ([userData isEqualToString:FacilitiesRepairTypesKey]) {
                                                       [self.loadingView removeFromSuperview];
                                                       self.loadingView = nil;
                                                       self.tableView.hidden = NO;
                                                        
                                                       if (dataUpdated || self.problemTypes == nil) {
                                                          self.problemTypes = nil;
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

- (void)setProblemTypes:(NSArray *)typesArray {
    if (_problemTypes != nil) {
        [_problemTypes release];
    }
    
    _problemTypes = [typesArray retain];
}

- (NSArray*)problemTypes {
    if (_problemTypes == nil) {
        [self setProblemTypes:[self repairTypes]];
    }
    
    return _problemTypes;
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
    return [[self problemTypes] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"typeCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:reuseIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    FacilitiesRepairType *type = (FacilitiesRepairType *)[[self problemTypes] objectAtIndex:indexPath.row];
    cell.textLabel.text = type.name;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.userData];
    [dict setObject:[[self repairTypes] objectAtIndex:indexPath.row]
             forKey:FacilitiesRequestRepairTypeKey];
    
    FacilitiesSummaryViewController *vc = [[[FacilitiesSummaryViewController alloc] init] autorelease];
    vc.reportData = dict;
    [self.navigationController pushViewController:vc
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}
@end
