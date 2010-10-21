#import <Foundation/Foundation.h>
#import "MITMapView.h"

@interface CalendarMapView : MITMapView {

	NSArray *_events;

}

@property (nonatomic, retain) NSArray *events;

@end
