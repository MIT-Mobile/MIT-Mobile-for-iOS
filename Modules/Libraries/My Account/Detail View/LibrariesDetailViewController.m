#import "LibrariesDetailViewController.h"
#import "LibrariesDetailLabel.h"
#import "LibrariesRenewResultViewController.h"
#import "MITUIConstants.h"

#define PADDING 10.0
#define PADDED_WIDTH(x) (floorf(x - PADDING))

@interface LibrariesDetailViewController ()
@property (nonatomic,retain) NSDictionary *details;
@property (nonatomic) LibrariesDetailType type;
@end

@implementation LibrariesDetailViewController
@synthesize details = _details;
@synthesize type = _type;

- (id)initWithBookDetails:(NSDictionary*)dictionary detailType:(LibrariesDetailType)type
{
    self = [super initWithNibName:nil
                            bundle:nil];
    if (self) {
        self.type = type;
        self.details = dictionary;
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
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
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
    
    if (self.type == LibrariesDetailLoanType)
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
        
        [buttonCell addSubview:renewButton];
        [cells setObject:buttonCell
                  forKey:[NSIndexPath indexPathForRow:0
                                            inSection:2]];
    }

}


- (void)loadView
{
    CGFloat navHeight = self.navigationController.navigationBarHidden ? 0 : CGRectGetHeight(self.navigationController.navigationBar.frame);
    CGRect viewRect = [[UIScreen mainScreen] applicationFrame];
    viewRect = UIEdgeInsetsInsetRect(viewRect, UIEdgeInsetsMake(navHeight, 0, 0, 0));

    UIView *view = [[[UIView alloc] initWithFrame:viewRect] autorelease];
    CGPoint origin = CGPointZero;
    
    {
        LibrariesDetailLabel *detailLabel = [[[LibrariesDetailLabel alloc] initWithBook:self.details] autorelease];
        CGRect detailFrame = CGRectMake(origin.x,origin.y,
                                        CGRectGetWidth(viewRect),0);
        detailLabel.frame = detailFrame;
        [detailLabel sizeToFit];
        
        [view addSubview:detailLabel];
        origin.y += CGRectGetMaxY(detailLabel.frame);
    }

    {
        UIView *statusView = [[[UIView alloc] init] autorelease];
        CGPoint subOrigin = CGPointZero;

        UIImageView *statusIcon = nil;
        switch (self.type)
        {
            case LibrariesDetailHoldType:
                if ([[self.details objectForKey:@"ready"] boolValue])
                {
                    statusIcon = [[[UIImageView alloc] init] autorelease];
                    statusIcon.image = [UIImage imageNamed:@"libraries/status-ok"];
                }
                break;

            case LibrariesDetailLoanType:
                if ([[self.details objectForKey:@"overdue"] boolValue])
                {
                    statusIcon = [[[UIImageView alloc] init] autorelease];
                    statusIcon.image = [UIImage imageNamed:@"libraries/status-alert"];
                }
                break;

            case LibrariesDetailFineType:
            default:
                break;
        }

        CGRect iconFrame = CGRectZero;
        if (statusIcon)
        {
            iconFrame.size = statusIcon.image.size;
            iconFrame.origin = subOrigin;
            statusIcon.frame = iconFrame;
            statusIcon.backgroundColor = [UIColor whiteColor];

            [statusView addSubview:statusIcon];
            subOrigin.x += CGRectGetWidth(iconFrame) + 5;
            
        }


        UILabel *statusLabel = [[[UILabel alloc] init] autorelease];
        statusLabel.numberOfLines = 0;
        statusLabel.lineBreakMode = UILineBreakModeWordWrap;
        
        NSMutableString *statusText = [NSMutableString string];
        switch (self.type)
        {
            case LibrariesDetailHoldType:
            {
                [statusText appendString:[self.details objectForKey:@"status"]];
                if ([[self.details objectForKey:@"ready"] boolValue])
                {
                    statusLabel.textColor = [UIColor colorWithRed:0
                                                            green:0.5
                                                             blue:0
                                                            alpha:1.0];
                    [statusText appendFormat:@"\nPick up at %@", [self.details objectForKey:@"pickup-location"]];
                }
                else
                {
                    statusLabel.textColor = [UIColor blackColor];
                    statusIcon.hidden = YES;
                }
                break;
            }


            case LibrariesDetailLoanType:
            {
                if ([[self.details objectForKey:@"has-hold"] boolValue])
                {
                    [statusText appendString:@"Item has holds\n"];
                }

                if ([[self.details objectForKey:@"overdue"] boolValue])
                {
                    statusLabel.textColor = [UIColor redColor];
                }
                else
                {
                    statusLabel.textColor = [UIColor blackColor];
                    statusIcon.hidden = YES;
                }

                NSString *dueText = [self.details objectForKey:@"dueText"];
                if (dueText)
                {
                    [statusText appendString:dueText];
                }
                break;
            }

            case LibrariesDetailFineType:
            default:
                break;
        }


        CGRect statusFrame = CGRectZero;
        statusFrame.origin = CGPointMake(subOrigin.x, subOrigin.y);
        statusFrame.size = [statusText sizeWithFont:statusLabel.font
                                  constrainedToSize:CGSizeMake(CGRectGetMaxX(viewRect) - subOrigin.x,
                                                               CGRectGetMaxY(viewRect) - subOrigin.y)
                                      lineBreakMode:statusLabel.lineBreakMode];

        statusLabel.text = statusText;
        statusLabel.frame = statusFrame;
        [statusView addSubview:statusLabel];


        statusView.backgroundColor = [UIColor whiteColor];
        statusView.frame = CGRectMake(origin.x,
                                      origin.y,
                                      CGRectGetWidth(viewRect),
                MAX(CGRectGetHeight(statusFrame), CGRectGetHeight(iconFrame)));
        [view addSubview:statusView];
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
@end
