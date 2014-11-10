#import "CampusTourHomeController.h"
#import "CampusTour.h"
#import "ScrollFadeImageView.h"
#import "TourIntroViewController.h"
#import "UIKit+MITAdditions.h"
#import "IntroToMITController.h"

@interface CampusTourHomeController ()
@property (nonatomic,weak) ScrollFadeImageView *scrollingBackground;
@property (nonatomic,weak) UILabel *introTextLabel;
@property (nonatomic,weak) UITableView *tableView;

@property (nonatomic,assign,getter=isLoading) BOOL loading;
@property (nonatomic,assign) BOOL shouldRetry;
- (void)loadTourInfo;
@end

@implementation CampusTourHomeController

- (void)loadView
{
    CGRect mainFrame = [[UIScreen mainScreen] bounds];
    
    UIView *mainView = [[UIView alloc] initWithFrame:mainFrame];
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor clearColor];
    
    CGRect viewBounds = mainView.bounds;
    
    {
        ScrollFadeImageView *fadeView = [[ScrollFadeImageView alloc] initWithFrame:viewBounds];
        fadeView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
        fadeView.animationImages = [NSArray arrayWithObjects:
                                               [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageToursWallpaperKillian]],
                                               [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageToursWallpaperStata]],
                                               [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageToursWallpaperGreatSail]],
                                               nil];
        fadeView.scrollDistance = 40;
        [mainView addSubview:fadeView];
        self.scrollingBackground = fadeView;
    }
    
    {
        CGFloat offset = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? 64. : 0;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.,
                                                                   15. + offset,
                                                                   CGRectGetWidth(viewBounds) - 30.,
                                                                   0)];
        
        label.backgroundColor = [UIColor clearColor];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        label.text = NSLocalizedString(@"TOUR_INTRO_TEXT", nil);
        label.textColor = [UIColor whiteColor];
        [label sizeToFit];
        self.introTextLabel = label;
        [mainView addSubview:label];
    }
    
    {
        CGFloat tableHeight = 44 * 3 + 50; // three cells plus some padding
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            tableHeight += 20. + 20.; // extra padding on iOS 7
        }
        CGRect tableFrame = CGRectMake(0,
                                       CGRectGetHeight(viewBounds) - tableHeight,
                                       CGRectGetWidth(viewBounds),
                                       tableHeight);
        UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.backgroundView = nil;
        tableView.scrollEnabled = NO;
        
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.tableView = tableView;
        [mainView insertSubview:tableView aboveSubview:self.scrollingBackground];
    }
    
    self.view = mainView;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.scrollingBackground startAnimating];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.scrollingBackground stopAnimating];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    
    self.navigationItem.title = @"Campus Tour";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tour"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:nil action:nil];
    
    [self loadTourInfo];
}

- (void)loadTourInfo {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tourInfoLoaded:) name:TourInfoLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tourInfoFailedToLoad:) name:TourInfoFailedToLoadNotification object:nil];
    
    self.tours = [[ToursDataManager sharedManager] allTours];
    if (!self.tours) {
        self.loading = YES;
    } else {
        [self tourInfoLoaded:nil];
    }
}

- (void)tourInfoLoaded:(NSNotification *)aNotification {
    // Remember to stop observing as soon as the task is done.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoFailedToLoadNotification object:nil];

    self.loading = NO;
    self.shouldRetry = NO;
    
    self.tours = [[ToursDataManager sharedManager] allTours];

    [self.tableView reloadData];
}

- (void)tourInfoFailedToLoad:(NSNotification *)aNotification {
    // Remember to stop observing as soon as the task is done.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoFailedToLoadNotification object:nil];

    self.loading = NO;
    self.shouldRetry = YES;
    [self.tableView reloadData];
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

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoFailedToLoadNotification object:nil];

    self.tours = nil;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger num = 0;
    switch (section) {
        case 0:
            if (self.tours) {
                num = [self.tours count];
            } else {
                num = 1;
            }
            break;
        case 1:
            num = 2;
            break;
        default:
            break;
    }
    return num;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"fawnrubw";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;
    UIView *hairline = [cell viewWithTag:5235];
    if (hairline) {
        [hairline removeFromSuperview];
    }
    
    switch (indexPath.section) {
        case 0:
            cell.backgroundColor = [[UIColor mit_tintColor] colorWithAlphaComponent:0.75];
            cell.textLabel.textColor = [UIColor whiteColor];
            
            if (self.tours) {
                cell.textLabel.text = @"Begin Self-Guided Tour";
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
            } else if (self.shouldRetry && !self.isLoading) {
                cell.textLabel.text = @"Retry Loading";
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryView = nil;
            } else {
                cell.textLabel.text = @"Loading...";
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                [activityView startAnimating];
                cell.accessoryView = activityView;
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Introduction to MIT";
            } else {
                CGRect hairlineFrame = CGRectMake(15, 0, tableView.frame.size.width - 15, 1.0 / [[UIScreen mainScreen] scale]);
                UIView *hairline = [[UIView alloc] initWithFrame:hairlineFrame];
                hairline.backgroundColor = [UIColor lightGrayColor];
                hairline.tag = 5235;
                
                //Adding this to the cell itself as the content view is clipped
                // on either side of the cell's view
                [cell addSubview:hairline];
                cell.textLabel.text = @"Guided Tours";
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MITImageActionExternalWhite]];
                cell.autoresizesSubviews = YES;
            }
            cell.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            break;
        default:
            break;
    }
    
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            if (self.tours) {
                CampusTour *tour = self.tours[indexPath.row];
                [[ToursDataManager sharedManager] setActiveTourID:tour.tourID];
                
                TourIntroViewController *introController = [[TourIntroViewController alloc] init];
                [self.navigationController pushViewController:introController animated:YES];
                [self.scrollingBackground stopAnimating];
            } else if (self.shouldRetry) {
                [self loadTourInfo];
                [self.tableView reloadData];
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                IntroToMITController *introVC = [[IntroToMITController alloc] init];
                [self.navigationController pushViewController:introVC animated:YES];
                [self.scrollingBackground stopAnimating];
            } else {
                NSURL *url = [NSURL URLWithString:@"http://web.mit.edu/infocenter/campustours.html"];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
            break;
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
