#import "LibrariesDetailViewController.h"
#import "LibrariesDetailLabel.h"
#import "LibrariesRenewResultViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITNavigationActivityView.h"
#import "Foundation+MITAdditions.h"

#import "MITTouchstoneRequestOperation+MITMobileV2.h"

@interface LibrariesDetailViewController ()
@property (nonatomic, weak) UIButton *renewButton;
@property (nonatomic,weak) MITTouchstoneRequestOperation *requestOperation;
@property (copy) NSDictionary *details;
@property LibrariesDetailType type;
@end

@implementation LibrariesDetailViewController
- (id)initWithBookDetails:(NSDictionary*)dictionary detailType:(LibrariesDetailType)type
{
    self = [super initWithNibName:nil
                            bundle:nil];
    if (self) {
        self.type = type;
        self.details = dictionary;
        
        switch (type) {
            case LibrariesDetailLoanType:
                self.title = @"Loan";
                break;
            case LibrariesDetailFineType:
                self.title = @"Fine";
                break;
            case LibrariesDetailHoldType:
                self.title = @"Hold";
                break;
        }
    }
    return self;
}

- (void)dealloc
{
    [self.requestOperation cancel];
}

#pragma mark - View lifecycle
- (void)loadView
{
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    
    if (self.navigationController.navigationBarHidden == NO)
    {
        mainFrame.origin.y += CGRectGetHeight(self.navigationController.navigationBar.frame);
        mainFrame.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
    }
    UIScrollView *mainView = [[UIScrollView alloc] initWithFrame:mainFrame];

    CGRect contentFrame = mainFrame;
    contentFrame.origin = CGPointZero;
    contentFrame.size.height = 0.0;
    
    UIEdgeInsets detailInsets = UIEdgeInsetsMake(14, 15, 14, 15);
    UIEdgeInsets statusInsets = UIEdgeInsetsMake(4 - detailInsets.top, 15, 4, 15);

    mainView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        detailInsets = UIEdgeInsetsMake(14, 10, 14, 10);
        statusInsets = UIEdgeInsetsMake(4 - detailInsets.top, 10, 4, 10);
        mainView.backgroundColor = [UIColor mit_backgroundColor];
    }
    
    {
        LibrariesDetailLabel *detailLabel = [[LibrariesDetailLabel alloc] initWithBook:self.details];
        detailLabel.backgroundColor = [UIColor whiteColor];
        CGRect detailFrame = CGRectMake(contentFrame.origin.x,
                                        contentFrame.origin.y,
                                        CGRectGetWidth(contentFrame),
                                        0);
        detailLabel.textInsets = detailInsets;
        detailFrame.size = [detailLabel sizeThatFits:detailFrame.size];
        detailLabel.frame = detailFrame;

        [mainView addSubview:detailLabel];
        contentFrame.origin.y = CGRectGetMaxY(detailFrame);
    }


    {
        UIView *statusView = [[UIView alloc] init];

        CGRect statusContentFrame = CGRectMake(0, 0, CGRectGetWidth(contentFrame), CGFLOAT_MAX);;
        statusContentFrame.origin = CGPointZero;
        statusContentFrame = UIEdgeInsetsInsetRect(statusContentFrame, statusInsets);

        UIImageView *statusIcon = nil;
        switch (self.type)
        {
            case LibrariesDetailHoldType:
                if ([self.details[@"ready"] boolValue])
                {
                    statusIcon = [[UIImageView alloc] init];
                    statusIcon.image = [UIImage imageNamed:MITImageLibrariesStatusReady];
                }
                break;

            case LibrariesDetailLoanType:
                if ([self.details[@"overdue"] boolValue])
                {
                    statusIcon = [[UIImageView alloc] init];
                    statusIcon.image = [UIImage imageNamed:MITImageLibrariesStatusAlert];
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

            statusIcon.frame = iconFrame;

            [statusView addSubview:statusIcon];
            statusContentFrame.origin.x += CGRectGetWidth(iconFrame) + 4.0;
        }


        UILabel *statusLabel = [[UILabel alloc] init];
        statusLabel.numberOfLines = 0;
        statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
        statusLabel.font = [UIFont systemFontOfSize:14.0];

        NSMutableString *statusText = [NSMutableString string];
        switch (self.type)
        {
            case LibrariesDetailHoldType:
            {
                [statusText appendString:self.details[@"status"]];
                if ([self.details[@"ready"] boolValue])
                {
                    statusLabel.textColor = [UIColor colorWithRed:0
                                                            green:0.5
                                                             blue:0
                                                            alpha:1.0];
                    [statusText appendFormat:@"\nPick up at %@", self.details[@"pickup-location"]];
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
                if ([self.details[@"has-hold"] boolValue]) {
                    [statusText appendString:@"Item has holds\n"];
                }

                if ([self.details[@"overdue"] boolValue]) {
                    statusLabel.textColor = [UIColor redColor];
                } else {
                    statusLabel.textColor = [UIColor blackColor];
                    statusIcon.hidden = YES;
                }

                NSString *dueText = self.details[@"dueText"];
                if ([dueText length]) {
                    [statusText appendString:dueText];
                }
                break;
            }

            case LibrariesDetailFineType:
            default:
                break;
        }

        if (statusIcon || [statusText length] > 0)
        {
            CGRect statusFrame = CGRectZero;
            statusFrame.origin = CGPointMake(statusContentFrame.origin.x, statusContentFrame.origin.y);
            statusFrame.size = [statusText sizeWithFont:statusLabel.font
                                      constrainedToSize:CGSizeMake(CGRectGetMaxX(statusContentFrame) - CGRectGetMaxX(iconFrame),
                                                                   CGRectGetMaxY(statusContentFrame))
                                          lineBreakMode:statusLabel.lineBreakMode];
            
            // make sure that label's total width + initial X position doesn't go over the main screen frame.
            if( (statusFrame.size.width + statusFrame.origin.x) >= mainFrame.size.width )
            {
               statusFrame.size.width -= statusFrame.origin.x;
            }

            statusLabel.text = [[statusText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByDecodingXMLEntities];
            statusLabel.frame = statusFrame;
            [statusView addSubview:statusLabel];


            statusView.backgroundColor = [UIColor whiteColor];
            statusView.frame = CGRectMake(contentFrame.origin.x,
                                          contentFrame.origin.y,
                                          CGRectGetWidth(contentFrame),
                    MAX(CGRectGetHeight(statusFrame), CGRectGetHeight(iconFrame)) + statusInsets.bottom);
            [mainView addSubview:statusView];
            contentFrame.origin.y = CGRectGetMaxY(statusView.frame) + 25;
        }
    }

    if (self.type == LibrariesDetailLoanType)
    {
        UIEdgeInsets buttonInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            buttonInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        }
        CGRect loginFrame = CGRectMake(contentFrame.origin.x,
                                       contentFrame.origin.y,
                                       CGRectGetWidth(contentFrame),
                                       44);
        loginFrame = UIEdgeInsetsInsetRect(loginFrame, buttonInsets);

        UIButton *renewButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        renewButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        renewButton.frame = loginFrame;

        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {

            renewButton.backgroundColor = [UIColor whiteColor];
            renewButton.adjustsImageWhenHighlighted = NO;
            
            UIColor *color = [UIColor darkGrayColor];
            CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
            UIGraphicsBeginImageContext(rect.size);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGContextSetFillColorWithColor(context, [color CGColor]);
            CGContextFillRect(context, rect);
            
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [renewButton setBackgroundImage:image forState:UIControlStateHighlighted];
            
            renewButton.titleLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        }
        
        [renewButton setTitle:@"Renew this Book"
                     forState:UIControlStateNormal];
        [renewButton setTitleColor:[UIColor grayColor]
                          forState:UIControlStateDisabled];
        [renewButton addTarget:self
                        action:@selector(renewBook:)
              forControlEvents:UIControlEventTouchUpInside];
        self.renewButton.titleLabel.textColor = [UIColor blackColor];

        [mainView addSubview:renewButton];
        self.renewButton = renewButton;
        contentFrame.origin.y = CGRectGetMaxY(loginFrame) + 5.0;
    }

    mainView.contentSize = CGSizeMake(CGRectGetWidth(contentFrame), contentFrame.origin.y);
    mainView.showsHorizontalScrollIndicator = NO;
    mainView.alwaysBounceHorizontal = NO;

    [self setView:mainView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

#pragma mark - User Actions

- (IBAction)renewBook:(id)sender
{
    MITNavigationActivityView *activityView = [[MITNavigationActivityView alloc] init];
    self.navigationItem.titleView = activityView;
    [activityView startActivityWithTitle:@"Renewing..."];
    self.renewButton.enabled = NO;

    NSURLRequest *request = [NSURLRequest requestForModule:@"libraries" command:@"renewBooks" parameters:@{@"barcodes":self.details[@"barcode"]}];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak LibrariesDetailViewController *weakSelf = self;
    [requestOperation setCompleteBlock:^(MITTouchstoneRequestOperation *operation, NSArray *content, NSString *contentType, NSError *error) {
        LibrariesDetailViewController *blockSelf = weakSelf;

        if (!blockSelf) {
            return;
        } else if (!(blockSelf.requestOperation == operation)) {
            return;
        } else  {
            blockSelf.navigationItem.titleView = nil;
            blockSelf.renewButton.enabled = YES;

            if (error || [content isKindOfClass:[NSArray class]]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Renew"
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                [alert show];
            } else {
                LibrariesRenewResultViewController *vc = [[LibrariesRenewResultViewController alloc] initWithItems:content];
                [blockSelf.navigationController pushViewController:vc animated:YES];
            }
        }
    }];

    [self.requestOperation cancel];
    self.requestOperation = requestOperation;
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

@end
