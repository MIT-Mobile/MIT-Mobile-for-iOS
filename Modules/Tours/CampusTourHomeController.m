#import "CampusTourHomeController.h"
#import "CampusTour.h"
#import "ScrollFadeImageView.h"
#import "TourIntroViewController.h"
#import "UIKit+MITAdditions.h"
#import "IntroToMITController.h"

@interface CampusTourHomeController (Private)

- (void)loadTourInfo;

@end

@implementation CampusTourHomeController

@synthesize tours, scrollingBackground, tableView = _tableView;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    if (!scrollingBackground) {
        self.scrollingBackground = [[[ScrollFadeImageView alloc] initWithFrame:self.view.frame] autorelease];
        scrollingBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollingBackground.animationImages = [NSArray arrayWithObjects:
                                               [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tours/tour_wallpaper_killian.jpg"]] autorelease],
                                               [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tours/tour_wallpaper_stata.jpg"]] autorelease],
                                               [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tours/tour_wallpaper_great_sail.jpg"]] autorelease],
                                               nil];
        scrollingBackground.scrollDistance = 40;
        [self.view insertSubview:scrollingBackground atIndex:0];
    }
    
    [scrollingBackground startAnimating];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [scrollingBackground stopAnimating];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    
    self.navigationItem.title = @"Campus Tour";
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Tour"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:nil action:nil] autorelease];
    
    [self loadTourInfo];
    
    NSString *introText = NSLocalizedString(@"TOUR_INTRO_TEXT", nil);
    UIFont *font = [UIFont systemFontOfSize:16];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(12,
																12,
                                                                self.view.bounds.size.width - 12, 
																0)] autorelease];
    label.font = font;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.text = introText;
	[label sizeToFit];
    [self.view addSubview:label];
	
	
    CGFloat tableHeight = 44 * 3 + 40; // three cells plus some padding
    CGRect tableFrame = CGRectMake(0, self.view.frame.size.height - tableHeight,
                                   self.view.frame.size.width, tableHeight);
    self.tableView = [[[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleGrouped] autorelease];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorColor = [UIColor clearColor];
    _tableView.scrollEnabled = NO;
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_tableView];
}

- (void)loadTourInfo {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tourInfoLoaded:) name:TourInfoLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tourInfoFailedToLoad:) name:TourInfoFailedToLoadNotification object:nil];
    
    self.tours = [[ToursDataManager sharedManager] allTours];
    if (!self.tours) {
        loading = YES;
    } else {
        [self tourInfoLoaded:nil];
    }
}

- (void)tourInfoLoaded:(NSNotification *)aNotification {
    // Remember to stop observing as soon as the task is done.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoFailedToLoadNotification object:nil];

    loading = NO;
    shouldRetry = NO;
    
    self.tours = [[ToursDataManager sharedManager] allTours];

    [self.tableView reloadData];
}

- (void)tourInfoFailedToLoad:(NSNotification *)aNotification {
    // Remember to stop observing as soon as the task is done.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TourInfoFailedToLoadNotification object:nil];

    loading = NO;
    shouldRetry = YES;
    [self.tableView reloadData];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [scrollingBackground removeFromSuperview];
    self.scrollingBackground = nil;
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];

    self.scrollingBackground = nil;
    self.tableView = nil;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tableView = nil;
    self.tours = nil;
    self.scrollingBackground = nil;
    
    
    [super dealloc];
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
    static NSString *cellID = @"fawnrubw";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    UIView *hairline = [cell viewWithTag:5235];
    if (hairline) {
        [hairline removeFromSuperview];
    }
    
    switch (indexPath.section) {
        case 0:
            cell.backgroundColor = [UIColor colorWithRed:0.6 green:0 blue:0 alpha:0.8];
            cell.textLabel.textColor = [UIColor whiteColor];
            
            if (self.tours) {
                cell.textLabel.text = @"Begin Self-Guided Tour";
                //CampusTour *tour = [self.tours objectAtIndex:indexPath.row];
                //cell.textLabel.text = tour.title;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-arrow-white.png"]] autorelease];
            } else if (shouldRetry && !loading) {
                cell.textLabel.text = @"Retry Loading";
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.accessoryView = nil;
            } else {
                cell.textLabel.text = @"Loading...";
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                UIActivityIndicatorView *activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
                [activityView startAnimating];
                cell.accessoryView = activityView;
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Introduction to MIT";
                cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-arrow-white.png"]] autorelease];
            } else {
                UIView *hairline = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width - 20, 1)] autorelease];
                hairline.backgroundColor = [UIColor colorWithHexString:@"#666666"];
                hairline.tag = 5235;
                [cell.contentView addSubview:hairline];
                cell.textLabel.text = @"Guided Tours";
                cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/action-external-white.png"]] autorelease];
            }
            cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
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
                
                TourIntroViewController *introController = [[[TourIntroViewController alloc] init] autorelease];
                [self.navigationController pushViewController:introController animated:YES];
                [scrollingBackground stopAnimating];
            } else if (shouldRetry) {
                [self loadTourInfo];
                [self.tableView reloadData];
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                IntroToMITController *introVC = [[[IntroToMITController alloc] init] autorelease];
                [self.navigationController pushViewController:introVC animated:YES];
                [scrollingBackground stopAnimating];
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
