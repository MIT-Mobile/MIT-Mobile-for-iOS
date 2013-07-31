#import <UIKit/UIKit.h>
#import "MITTabHeaderView.h"

@interface LibrariesLoanSummaryView : MITTabHeaderView
@property UIEdgeInsets edgeInsets;
@property (nonatomic,copy) NSDictionary* accountDetails;
@property (nonatomic,weak) UIButton* renewButton;
@end
