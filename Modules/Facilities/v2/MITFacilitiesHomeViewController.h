//
//  MITFacilitiesHomeViewController.h
//  MIT Mobile
//
//

#import <UIKit/UIKit.h>
#import "FacilitiesLocation.h"

@interface MITFacilitiesHomeViewController : UIViewController

@end

// Editable Cell
@interface MITFacilitiesEditableFieldCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UITextView *subtitleTextView;

@end

// Non-Editable Cell
@interface MITFacilitiesNonEditableFieldCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;

@end

// Non-Editable Leased Message Cell
@interface MITFacilitiesLeasedMessageCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;

@end
