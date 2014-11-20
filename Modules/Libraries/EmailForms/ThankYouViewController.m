#import "ThankYouViewController.h"
#import "UIKit+MITAdditions.h"
#import "LibrariesModule.h"
#import "MITLoadingActivityView.h"

@interface ThankYouViewController ()
@property (nonatomic, weak) MITLoadingActivityView *loadingView;

- (IBAction)returnToHomeButtonTapped:(id)sender;

@end

@implementation ThankYouViewController
- (id)initWithMessage:(NSString *)message {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.title = nil;
        self.message = message;
    }
    return self;
}

- (void)setMessage:(NSString *)message {
    if (![_message isEqual:message]) {
        _message = [message copy];
        
        [self.loadingView removeFromSuperview];
        [self.tableView reloadData];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundView = nil;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    }
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(returnToHomeButtonTapped:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    // show a loading indicator
    if ([self.message length] == 0) {
        if (!self.loadingView) {
            MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:self.view.bounds];
            loadingView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleHeight);
            loadingView.frame = self.view.bounds;
            [self.view addSubview:loadingView];
            self.loadingView = loadingView;
        }
    }
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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // There's two sections and one row per section.
    switch (indexPath.section) {
        case 0:
        default: {
            CGSize messageSize =  [self.message  sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                                            constrainedToSize:CGSizeMake(280, 1000)
                                                lineBreakMode:NSLineBreakByWordWrapping];
            return messageSize.height + 20;
            break;
        }
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 0;
    }
    
    if (indexPath.section == 0) {
        // The thank you text cell.
        cell.textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        cell.textLabel.text = self.message;
    }
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == 0)  {
        [self returnToHomeButtonTapped:nil];
    }
}

#pragma mark Actions
- (IBAction)returnToHomeButtonTapped:(id)sender {
    UIViewController *homeViewController = [self.navigationController.viewControllers firstObject];
    [self.navigationController popToViewController:homeViewController animated:YES];
}

@end
