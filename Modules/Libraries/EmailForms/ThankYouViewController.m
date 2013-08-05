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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.hidesBackButton = YES;

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
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // There's two sections and one row per section.
    switch (indexPath.section) {
        case 0: {
            CGSize messageSize =  [self.message  sizeWithFont:[UIFont systemFontOfSize:15.]
                                            constrainedToSize:CGSizeMake(280, 1000)
                                                lineBreakMode:UILineBreakModeWordWrap];
            return messageSize.height + 20;
            break;
        }
        case 1:
        default:
            return 45.0 - 2.0; // height of the image minus imaginary border space 
            break;
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
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.textLabel.numberOfLines = 0;
    }
    
    if (indexPath.section == 0) {
        // The thank you text cell.
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.textLabel.text = self.message;
    } else {
        // The "button".
        UIImageView *imageView =  [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"global/return_button.png"]];
        cell.backgroundView = imageView;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.text = @"Return to Libraries";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
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
    LibrariesModule *librariesModule = (LibrariesModule *)[MIT_MobileAppDelegate moduleForTag:LibrariesTag];
    [self.navigationController popToViewController:librariesModule.moduleHomeController animated:YES];
}

@end
