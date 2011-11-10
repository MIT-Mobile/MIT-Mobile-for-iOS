#import <UIKit/UIKit.h>
#import "MITTabHeaderView.h"

@interface LibrariesLoanSummaryView : MITTabHeaderView
@property (nonatomic,retain) UIBarButtonItem* renewButton;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic,retain) NSDictionary* accountDetails;
@end
