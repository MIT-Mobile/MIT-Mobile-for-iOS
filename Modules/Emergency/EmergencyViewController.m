#import "EmergencyModule.h"
#import "EmergencyViewController.h"
#import "EmergencyContactsViewController.h"
#import "MITUIConstants.h"
#import "EmergencyData.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "MITTelephoneHandler.h"

static NSString* const MITEmergencyHTMLFormatString = @"<html>\n<head>\n<style type=\"text/css\" media=\"screen\">\nbody { margin: 0; padding: 0; font-family: \"Helvetica Neue\", Helvetica; font-size: 17px; }\n</style>\n</head>\n<body>\n%@\n</body>\n</html>";

typedef NS_ENUM(NSUInteger, MITEmergencyTableSection) {
    MITEmergencyTableSectionAlerts = 0,
    MITEmergencyTableSectionContacts,
    MITEmergencyTableSectionCount
};

@interface EmergencyViewController ()
@property (nonatomic, strong) UIWebView *infoWebView;

@property (nonatomic,copy) NSString *htmlString;
@property BOOL refreshButtonPressed;
@property UIEdgeInsets webViewInsets;
@property (nonatomic) CGFloat webViewCellHeight;
@end

@implementation EmergencyViewController
- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Emergency Info";
        _webViewInsets = UIEdgeInsetsMake(15., 15., 5., 15.);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    }
	self.tableView.backgroundView = nil;
    self.refreshControl = [UIRefreshControl new];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(refreshControlActivated:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // register for emergencydata notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoDidLoad:) name:EmergencyInfoDidLoadNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoDidFailToLoad:) name:EmergencyInfoDidFailToLoadNotification object:nil];
    
    if (!_infoWebView) {
        [self infoDidLoad:nil];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EmergencyInfoDidLoadNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EmergencyInfoDidFailToLoadNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (UIWebView *)infoWebView
{
    if (!_infoWebView) {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.tableView.bounds, self.webViewInsets)];
        webView.delegate = self;
        webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                    UIViewAutoresizingFlexibleWidth);
        webView.backgroundColor = [UIColor clearColor];
        webView.dataDetectorTypes = UIDataDetectorTypeAll;
        webView.opaque = NO;
        webView.scrollView.scrollEnabled = NO;
        webView.scrollView.showsHorizontalScrollIndicator = NO;
        webView.scrollView.showsVerticalScrollIndicator = NO;
        webView.userInteractionEnabled = NO;
        _infoWebView = webView;
    }
    return _infoWebView;
}

- (void)setHtmlString:(NSString *)htmlString
{
    _htmlString = [htmlString copy];
    self.webViewCellHeight = 0;
    [self.infoWebView loadHTMLString:self.htmlString
                             baseURL:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)refreshControlActivated:(UIRefreshControl *)refreshControl
{
    self.refreshButtonPressed = YES;
    [self refreshInfo];
}

- (void)refreshInfo
{
    self.webViewCellHeight = 0;
    [[EmergencyData sharedData] checkForEmergencies];
}

#pragma mark - UIWebView delegation
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([self.infoWebView isEqual:webView]) {
        CGRect frame = webView.frame;
        frame.size.height = 1;
        webView.frame = frame;
        CGSize size = [webView sizeThatFits:CGSizeZero];
        self.webViewCellHeight = size.height;

        [self.tableView reloadData];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *url = [request URL];
    if ([application canOpenURL:url]) {
        [application openURL:url];
    } else if ([[[request URL] absoluteString] isEqualToString:@"about:blank"]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return MITEmergencyTableSectionCount;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case MITEmergencyTableSectionAlerts: {
            return 1;
        }
        case MITEmergencyTableSectionContacts: {
            NSArray *numbers = [[EmergencyData sharedData] primaryItems];
            return [numbers count] + 1;
        }
        default: {
            return 0;
        }
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *contacts = [[EmergencyData sharedData] primaryItems];
    if (indexPath.section == MITEmergencyTableSectionAlerts) {
        
        CGFloat height = self.webViewCellHeight + self.webViewInsets.bottom + self.webViewInsets.top;
        return height;
    } else if (indexPath.section == MITEmergencyTableSectionContacts && indexPath.row < [contacts count]) {
        return 60.;
    } else {
        return 44.;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *alertCellId = @"AlertCell";
    static NSString *contactCellId = @"ContactCell";
    
    if (indexPath.section == MITEmergencyTableSectionAlerts) {
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:alertCellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.autoresizesSubviews = YES;
        cell.contentView.clipsToBounds = YES;
        
        UIWebView *webView = self.infoWebView;
        webView.frame = UIEdgeInsetsInsetRect(cell.contentView.bounds, self.webViewInsets);
        [cell.contentView addSubview:webView];
        if (!self.webViewCellHeight) {
            [self.infoWebView loadHTMLString:self.htmlString
                                     baseURL:nil];
        }
        
        return cell;
    } else if (indexPath.section == MITEmergencyTableSectionContacts) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:contactCellId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:contactCellId];
            cell.textLabel.numberOfLines = 0;
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        }
        
        NSArray *contacts = [[EmergencyData sharedData] primaryItems];
        if (indexPath.row < [contacts count]) {
            NSDictionary *contact = contacts[indexPath.row];
            cell.textLabel.text = contact[@"title"];
            // A primary contact item may be a phone number or a website URL
            if (contact[@"phone"]) {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
                cell.detailTextLabel.text = contact[@"phone"];
            } else {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            }
        } else {
            cell.textLabel.text = @"More Emergency Contacts";
            cell.detailTextLabel.text = nil;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        return cell;
    }
    
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MITEmergencyTableSectionContacts) {
        NSArray *contacts = [[EmergencyData sharedData] primaryItems];
        if (indexPath.row < [contacts count]) {
            NSDictionary *contact = contacts[indexPath.row];
            if (contact[@"phone"]) {
                [MITTelephoneHandler attemptToCallPhoneNumber:contact[@"phone"]];
            } else {
                UIApplication *application = [UIApplication sharedApplication];
                NSURL *url = [NSURL URLWithString:contact[@"url"]];
                if ([application canOpenURL:url]) {
                    [application openURL:url];
                }
            }
            
            [tableView deselectRowAtIndexPath:indexPath
                                     animated:YES];
        } else {
            EmergencyContactsViewController *contactsVC = [[EmergencyContactsViewController alloc] init];
            [self.navigationController pushViewController:contactsVC animated:YES];
            
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MITEmergencyTableSectionAlerts) {
        return nil;
    }
    
    return indexPath;
}

#pragma mark - Emergency Info Data Delegate
- (void)infoDidLoad:(NSNotification *)aNotification
{
	self.refreshButtonPressed = NO;
    
    self.htmlString = [[EmergencyData sharedData] htmlString];
    [self.tableView reloadData];
    
    [self.refreshControl endRefreshing];
}

- (void)infoDidFailToLoad:(NSNotification *)aNotification
{
    // Since emergency has never loaded successfully report failure
    self.htmlString = [NSString stringWithFormat:MITEmergencyHTMLFormatString, @"Failed to load notice."];
    [self.tableView reloadData];
	if (self.refreshButtonPressed) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Failed"
                                                            message:@"Failed to load notice from server."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
		[alertView show];
	}
	
	// touch handled
	self.refreshButtonPressed = NO;
    
    [self.refreshControl endRefreshing];
}

@end
