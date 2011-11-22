#import "LibrariesDetailViewController.h"
#import "LibrariesDetailLabel.h"
#import "LibrariesRenewResultViewController.h"
#import "MITUIConstants.h"

#define PADDING 10.0
#define PADDED_WIDTH(x) (floorf(x - PADDING))

@interface LibrariesDetailViewController ()
@property (nonatomic,retain) NSDictionary *details;
@property (nonatomic) LibrariesDetailType type;
@property (nonatomic,retain) NSMutableDictionary *tableCells;
@end

@implementation LibrariesDetailViewController
@synthesize details = _details;
@synthesize type = _type;
@synthesize tableCells = _tableCells;

- (id)initWithBookDetails:(NSDictionary*)dictionary detailType:(LibrariesDetailType)type
{
    self = [super initWithNibName:nil
                            bundle:nil];
    if (self) {
        self.type = type;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadTableCells
{
    NSMutableDictionary *cells = [NSMutableDictionary dictionary];
    
    {
        UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:nil] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        LibrariesDetailLabel *label = [[[LibrariesDetailLabel alloc] initWithBook:self.details] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        
        CGRect contentFrame = cell.contentView.frame;
        contentFrame.size = [label sizeThatFits:contentFrame.size];
        
        [cell.contentView addSubview:label];
        
        cell.contentView.frame = contentFrame;
        contentFrame.origin = cell.contentView.bounds.origin;
        label.frame = contentFrame;
        
        
        [cells setObject:cell
                  forKey:[NSIndexPath indexPathForRow:0
                                            inSection:0]];
    }
    
    {
        UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:nil] autorelease];
        switch(self.type)
        {
            case LibrariesDetailFineType:
            {
                cell.textLabel.text = @"Fine date: \nAmount owed: +∞";
                break;
            }
                
            case LibrariesDetailHoldType:
            {
                cell.textLabel.text = @"In Process";
                break;
            }
                
            case LibrariesDetailLoanType:
            {
                cell.textLabel.textColor = [UIColor redColor];
                cell.textLabel.text = @"Long Overdue";
                break;
            }
        }
        
        [cells setObject:cell
                  forKey:[NSIndexPath indexPathForRow:0
                                            inSection:1]];
    }
    
    if (self.type)
    {
        UITableViewCell *buttonCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        buttonCell.accessoryType = UITableViewCellAccessoryNone;
        buttonCell.editingAccessoryType = UITableViewCellAccessoryNone;
        buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
        buttonCell.backgroundColor = [UIColor clearColor];
        
        UIView *transparentView = [[[UIView alloc] initWithFrame:CGRectMake(0,0,320,44)] autorelease];
        transparentView.backgroundColor = [UIColor clearColor];
        transparentView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                            UIViewAutoresizingFlexibleWidth);
        [buttonCell setBackgroundView:transparentView];
        
        UIEdgeInsets buttonInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        CGRect loginFrame = CGRectMake(0,0,320,44);
        loginFrame = UIEdgeInsetsInsetRect(loginFrame, buttonInsets);
        
        UIButton *renewButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        renewButton.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        renewButton.frame = loginFrame;
        
        [renewButton setTitle:@"Renew this book"
                     forState:UIControlStateNormal];
        [renewButton setTitleColor:[UIColor grayColor]
                          forState:UIControlStateDisabled];
        [renewButton addTarget:self
                        action:@selector(renewBook:)
              forControlEvents:UIControlEventTouchUpInside];
        
        [buttonCell.contentView addSubview:renewButton];
    }
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    CGFloat navHeight = self.navigationController.navigationBarHidden ? 0 : CGRectGetHeight(self.navigationController.navigationBar.frame);
    CGRect viewRect = [[UIScreen mainScreen] applicationFrame];
    viewRect = UIEdgeInsetsInsetRect(viewRect, UIEdgeInsetsMake(navHeight, 0, 0, 0));
    
    UIView *view = [[[UIView alloc] initWithFrame:viewRect] autorelease];
    CGPoint origin = CGPointZero;
    
    {
        CGRect tableFrame = CGRectZero;
        tableFrame.origin = origin;
        tableFrame.size = viewRect.size;
        
        UITableView *tableView = [[[UITableView alloc] initWithFrame:tableFrame
                                                               style:UITableViewStyleGrouped] autorelease];
        tableView.delegate = self;
        tableView.dataSource = self;
        [view addSubview:tableView];
    }

    [self setView:view];
}

- (IBAction)renewBook:(id)sender
{
    LibrariesRenewResultViewController *vc = [[[LibrariesRenewResultViewController alloc] initWithItems:[NSArray arrayWithObject:self.details]] autorelease];
    [self.navigationController pushViewController:vc
                                         animated:YES];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITableView Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger maxSection = 0;
    
    for (NSIndexPath *indexPath in self.tableCells)
    {
        if (indexPath.section > maxSection)
        {
            maxSection = indexPath.section;
        }
    }
    
    return (maxSection + 1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount = 0;
    
    for (NSIndexPath *indexPath in self.tableCells)
    {
        if (indexPath.section == section)
        {
            ++rowCount;
        }
    }
    
    return rowCount;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tableCells objectForKey:indexPath];
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;

    if ((self.type == LibrariesDetailLoanType) && (section == 2))
    {
        CGSize size = [@"Status" sizeWithFont:[UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE]
                            constrainedToSize:CGSizeMake(PADDED_WIDTH(320),CGFLOAT_MAX)
                                lineBreakMode:UILineBreakModeWordWrap];
        
        height = size.height;
    }
    
    return height;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionHeader = nil;
    
    if ((self.type == LibrariesDetailLoanType) && (section == 2))
    {
        UILabel *titleView = titleView = [[[UILabel alloc] init] autorelease];
        titleView.font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
        titleView.textColor = GROUPED_SECTION_FONT_COLOR;
        titleView.backgroundColor = [UIColor clearColor];
        titleView.lineBreakMode = UILineBreakModeTailTruncation;
        titleView.text = @"Status";
        
        CGSize titleSize = [titleView.text sizeWithFont:titleView.font
                                      constrainedToSize:CGSizeMake(PADDED_WIDTH(320),CGFLOAT_MAX)
                                          lineBreakMode:titleView.lineBreakMode];
        titleView.frame = CGRectMake(PADDING,
                                     0,
                                     titleSize.width,
                                     titleSize.height);
        sectionHeader = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, titleSize.height)] autorelease];
        [sectionHeader addSubview:titleView];
    }
    
    return sectionHeader;
}


#pragma mark - UITableView Delegate

@end
