#import "ThankYouViewController.h"
#import "UIKit+MITAdditions.h"
#import "LibrariesModule.h"

@interface ThankYouViewController ()

@property (nonatomic, retain) NSString *thankYouText;

- (IBAction)returnToHomeButtonTapped:(id)sender;

@end

@implementation ThankYouViewController

@synthesize thankYouText;

- (id)initWithMessage:(NSString *)message {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.title = @"Thank You";
        self.thankYouText = message;
    }
    return self;
}

- (void)dealloc {
    [thankYouText release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.hidesBackButton = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    if (indexPath.section == 0) {
        CGSize thankYouTextSize = 
        [self.thankYouText 
         sizeWithFont:[UIFont systemFontOfSize:15.0f] 
         constrainedToSize:CGSizeMake(280, 1000) 
         lineBreakMode:UILineBreakModeWordWrap];
        return thankYouTextSize.height + 20;
    }
    else {
        return 45.0f;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = 
        [[[UITableViewCell alloc] 
          initWithStyle:UITableViewCellStyleDefault 
          reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.textLabel.numberOfLines = 0;
    }
    
    if (indexPath.section == 0) {
        // The thank you text cell.
        cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
        cell.textLabel.text = self.thankYouText;
    }
    else {
        // The "button".
        UIImageView *imageView = 
        [[UIImageView alloc] 
         initWithImage:[UIImage imageNamed:@"global/return_button.png"]];
        cell.backgroundView = imageView;
        [imageView release];
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
