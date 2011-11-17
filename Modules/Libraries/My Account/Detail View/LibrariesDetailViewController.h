#import <UIKit/UIKit.h>

typedef enum {
    LibrariesDetailLoanType = 0,
    LibrariesDetailFineType,
    LibrariesDetailHoldType
} LibrariesDetailType;

@interface LibrariesDetailViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>
- (id)initWithBookDetails:(NSDictionary*)dictionary detailType:(LibrariesDetailType)type;
@end
