#import "LibrariesDetailViewController.h"
#import "LibrariesDetailLabel.h"
#import "LibrariesRenewResultViewController.h"
#import "MITUIConstants.h"
#import "MobileRequestOperation.h"
#import "MITNavigationActivityView.h"
#import "Foundation+MITAdditions.h"

@interface LibrariesDetailViewController ()
@property (nonatomic,retain) NSDictionary *details;
@property (nonatomic) LibrariesDetailType type;
@property (nonatomic, retain) MobileRequestOperation *request;
@property (nonatomic, assign) UIButton *renewButton;
@end

@implementation LibrariesDetailViewController
@synthesize details = _details;
@synthesize type = _type;
@synthesize request = _request;
@synthesize renewButton = _renewButton;



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

- (void)dealloc
{
    self.details = nil;
    [self.request cancel];
    self.request = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)loadView
{
    CGFloat navHeight = self.navigationController.navigationBarHidden ? 0 : CGRectGetHeight(self.navigationController.navigationBar.frame);
    CGRect viewRect = [[UIScreen mainScreen] applicationFrame];
    viewRect.origin.y += navHeight;
    viewRect.size.height -= navHeight;

    UIView *view = [[[UIView alloc] initWithFrame:viewRect] autorelease];

    viewRect = view.bounds;
    
    {
        LibrariesDetailLabel *detailLabel = [[[LibrariesDetailLabel alloc] initWithBook:self.details] autorelease];
        detailLabel.backgroundColor = [UIColor whiteColor];
        CGRect detailFrame = CGRectMake(viewRect.origin.x,
                                        viewRect.origin.y,
                                        CGRectGetWidth(viewRect),
                                        0);
        detailLabel.textInsets = UIEdgeInsetsMake(10, 10, 5, 10);
        detailFrame.size = [detailLabel sizeThatFits:detailFrame.size];
        detailLabel.frame = detailFrame;
        
        [view addSubview:detailLabel];
        viewRect.origin.y = CGRectGetMaxY(detailLabel.frame);
    }

    {
        UIView *statusView = [[[UIView alloc] init] autorelease];

        UIEdgeInsets statusInsets = UIEdgeInsetsMake(0, 10, 10, 10);
        CGRect statusContentFrame = CGRectMake(0, 0, CGRectGetWidth(viewRect), CGFLOAT_MAX);;
        statusContentFrame.origin = CGPointZero;
        statusContentFrame = UIEdgeInsetsInsetRect(statusContentFrame,statusInsets);

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
            iconFrame.origin = statusContentFrame.origin;
            iconFrame.origin.y += 2.0;
            
            statusIcon.frame = iconFrame;

            [statusView addSubview:statusIcon];
            statusContentFrame.origin.x += CGRectGetWidth(iconFrame) + 5;
            
        }


        UILabel *statusLabel = [[[UILabel alloc] init] autorelease];
        statusLabel.numberOfLines = 0;
        statusLabel.lineBreakMode = UILineBreakModeWordWrap;
        statusLabel.font = [UIFont systemFontOfSize:14.0];
        
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
            {
                [statusText appendFormat:@"Amount owed: %@", [self.details objectForKey:@"display-amount"]];

                NSTimeInterval fineInterval = [[self.details objectForKey:@"fine-date"] doubleValue];
                NSDate *fineDate = [NSDate dateWithTimeIntervalSince1970:fineInterval];
                [statusText appendFormat:@"\nFined on %@", [NSDateFormatter localizedStringFromDate:fineDate
                                                                       dateStyle:NSDateFormatterShortStyle
                                                                       timeStyle:NSDateFormatterNoStyle]];

                statusLabel.textColor = [UIColor redColor];
                statusLabel.font = [UIFont boldSystemFontOfSize:14.0];
            }
            default:
                break;
        }


        CGRect statusFrame = CGRectZero;
        statusFrame.origin = CGPointMake(statusContentFrame.origin.x, statusContentFrame.origin.y);
        statusFrame.size = [statusText sizeWithFont:statusLabel.font
                                  constrainedToSize:CGSizeMake(CGRectGetMaxX(statusContentFrame) - CGRectGetMaxX(iconFrame),
                                                               CGRectGetMaxY(statusContentFrame))
                                      lineBreakMode:statusLabel.lineBreakMode];

        statusLabel.text = [[statusText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
        statusLabel.frame = statusFrame;
        [statusView addSubview:statusLabel];


        statusView.backgroundColor = [UIColor whiteColor];
        statusView.frame = CGRectMake(viewRect.origin.x,
                                      viewRect.origin.y,
                                      CGRectGetWidth(viewRect),
                                      MAX(CGRectGetHeight(statusFrame), CGRectGetHeight(iconFrame)) + statusInsets.bottom);
        [view addSubview:statusView];

        viewRect.origin.y = CGRectGetMaxY(statusView.frame) + 25;
    }

    if (self.type == LibrariesDetailLoanType)
    {
        UIEdgeInsets buttonInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        CGRect loginFrame = CGRectMake(viewRect.origin.x,
                                       viewRect.origin.y,
                                       CGRectGetWidth(viewRect),
                                       44);
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

        [view addSubview:renewButton];
        self.renewButton = renewButton;
    }

    [self setView:view];
}

- (IBAction)renewBook:(id)sender
{
    MITNavigationActivityView *activityView = [[[MITNavigationActivityView alloc] init] autorelease];
    self.navigationItem.titleView = activityView;
    [activityView startActivityWithTitle:@"Renewing..."];
    self.renewButton.enabled = NO;
    
    NSDictionary *params = [NSDictionary dictionaryWithObject:[self.details objectForKey:@"barcode"]
                                                       forKey:@"barcodes"];
    MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                            command:@"renewBooks"
                                                                         parameters:params];
    [operation setCompleteBlock:^(MobileRequestOperation *operation, id jsonData, NSError *error) {
        self.request = nil;
        self.navigationItem.titleView = nil;
        self.renewButton.enabled = YES;

        if (error)
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Renew"
                                                             message:[error localizedDescription]
                                                            delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
            [alert show];
        }
        else
        {
            LibrariesRenewResultViewController *vc = [[[LibrariesRenewResultViewController alloc] initWithItems:(NSArray *) jsonData] autorelease];
            [self.navigationController pushViewController:vc
                                                 animated:YES];
        }

    }];

    self.request = operation;
    [operation start];
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
