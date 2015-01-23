#import <Foundation/Foundation.h>
#import "MITMapPlaceSelectionDelegate.h"

@protocol MITMapPlaceSelector <NSObject>

@property (nonatomic, weak) id <MITMapPlaceSelectionDelegate> delegate;

@end
