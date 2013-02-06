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
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    
    if (self.navigationController)
    {
        if (self.navigationController.isNavigationBarHidden == NO)
        {
            mainFrame.origin.y += CGRectGetHeight(self.navigationController.navigationBar.frame);
            mainFrame.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
        }
        
        if (self.navigationController.isToolbarHidden == NO)
        {
            mainFrame.size.height -= CGRectGetHeight(self.navigationController.toolbar.frame);
        }
    }
    
    UIView *mainView = [[UIView alloc] initWithFrame:mainFrame];
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor clearColor];
    
    CGRect viewBounds = mainView.bounds;
    
    {
        ScrollFadeImageView *fadeView = [[ScrollFadeImageView alloc] initWithFrame:viewBounds];
        fadeView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight |
                                     UIViewAutoresizingFlexibleBottomMargin);
        fadeView.animationImages = [NSArray arrayWithObjects:
                                               [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tours/tour_wallpaper_killian.jpg"]],
                                               [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tours/tour_wallpaper_stata.jpg"]],
                                               [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tours/tour_wallpaper_great_sail.jpg"]],
                                               nil];
        fadeView.scrollDistance = 40;
        [mainView addSubview:fadeView];
        self.scrollingBackground = fadeView;
    }
    
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12,
                                                                   12,
                                                                   CGRectGetWidth(viewBounds) - 12,
                                                                   0)];
        label.backgroundColor = [UIColor clearColor];
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:16];
        label.text = NSLocalizedString(@"TOUR_INTRO_TEXT", nil);
        label.textColor = [UIColor whiteColor];
        [label sizeToFit];
        self.introTextLabel = label;
        [mainView addSubview:label];
    }
    
    {
        CGFloat tableHeight = 44 * 3 + 40; // three cells plus some padding
        CGRect tableFrame = CGRectMake(0,
                                       CGRectGetHeight(viewBounds) - tableHeight,
                                       CGRectGetWidth(viewBounds),
                                       tableHeight);
        UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.separatorColor = [UIColor clearColor];
        tableView.backgroundView.hidden = YES;
        tableView.scrollEnabled = NO;
        
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        self.tableView = tableView;
        [mainView insertSubview:tableView aboveSubview:self.scrollingBackground];
    }
    
    self.view = mainView;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [self.scrollingBackground startAnimating];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
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
                num = self.tours.count;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row != 0) {
        return tableView.rowHeight + 1;
    }
    return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static CGFloat cellAlpha = 0.85;
    static NSString *cellID = @"fawnrubw";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    UIView *hairline = [cell viewWithTag:5235];
    if (hairline) {
        [hairline removeFromSuperview];
    }
    
    switch (indexPath.section) {
        case 0:
            cell.backgroundColor = [UIColor colorWithRed:0.6 green:0 blue:0 alpha:cellAlpha];
            cell.textLabel.textColor = [UIColor whiteColor];
            
            if (self.tours) {
                cell.textLabel.text = @"Begin Self-Guided Tour";
                //CampusTour *tour = [self.tours objectAtIndex:indexPath.row];
                //cell.textLabel.text = tour.title;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-arrow-white.png"]];
            } else if (self.shouldRetry && !self.isLoading) {
                cell.textLabel.text = @"Retry Loading";
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryType = UITableViewCellAccessoryNone;
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
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-arrow-white.png"]];
            } else {
                UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 20, 1)];
                hairline.backgroundColor = [UIColor colorWithHexString:@"#666666"];
                hairline.tag = 5235;
                
                //Adding this to the cell itself as the content view is clipped
                // on either side of the cell's view
                [cell addSubview:hairline];
                cell.textLabel.text = @"Guided Tours";
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-external-white.png"]];
                cell.autoresizesSubviews = YES;
            }
            cell.backgroundColor = [UIColor colorWithWhite:0 alpha:cellAlpha];
            cell.textLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1];
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
                CampusTour *tour = [self.tours objectAtIndex:indexPath.row];
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
