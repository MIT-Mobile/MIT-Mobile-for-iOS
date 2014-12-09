#import <UIKit/UIKit.h>
#import "MITAutoSizingCell.h"

@class MITLibrariesCitationCell;
@class MITLibrariesCitation;

@protocol MITLibrariesCitationCellDelegate <NSObject>

- (void)citationCellShareButtonPressed:(NSAttributedString *)shareString;

@end

@interface MITLibrariesCitationCell : MITAutoSizingCell

@property (nonatomic, weak) id<MITLibrariesCitationCellDelegate> delegate;

- (void)setContent:(MITLibrariesCitation *)citation;

@end
