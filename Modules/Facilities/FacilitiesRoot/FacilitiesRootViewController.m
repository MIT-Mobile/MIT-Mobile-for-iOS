#import "FacilitiesRootViewController.h"

#import "FacilitiesCategoryViewController.h"
#import "UIKit+MITAdditions.h"

#pragma mark - Private Interface
@interface FacilitiesRootViewController ()
@property (nonatomic,retain) UITextView *textView;
@property (nonatomic,retain) UITableView* tableView;
@end


#pragma mark -
@implementation FacilitiesRootViewController
@synthesize textView = _textView;
@synthesize tableView = _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Building Services";
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.textView.backgroundColor = [UIColor clearColor];
    [self.tableView applyStandardColors];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.textView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITableViewDelegate Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 2;
        default:
            return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseCellIdentifier = @"FacilitiesCell";
    
    // Strings for each of the cells used in the table view.
    // These could be inlined but it's a bit easier to find them if they are all
    //  in one spot instead of interspersed in the code.
    static NSString *emailCellText = @"Email Facilities";
    static NSString *callCellText = @"Call Facilities";
    static NSString *reportCellText = @"Report a Problem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseCellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:reuseCellIdentifier] autorelease];
    }
    
    switch (indexPath.section) {
        case 0:
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = reportCellText;
            break;
        
        case 1:
            cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            
            switch (indexPath.row) {
                case 0:
                    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
                    cell.textLabel.text = emailCellText;
                    break;
                case 1:
                    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
                    cell.textLabel.text = callCellText;
                    break;
                default:
                    break;
            }
            
        default:
            break;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0) && (indexPath.row == 0)) {
        FacilitiesCategoryViewController *vc = [[[FacilitiesCategoryViewController alloc] init] autorelease];
        [self.navigationController pushViewController:vc
                                             animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
}

@end
