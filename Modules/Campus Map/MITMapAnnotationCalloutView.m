#import "MITMapAnnotationCalloutView.h"
#import "MITMapView.h"
#import "MITMapAnnotationView.h"

static const CGFloat kCalloutWidth = 275;
static const CGFloat kBuffer = 10;
static const CGFloat kTitleFontSize = 16;
static const CGFloat kSubTitleFontSize = 12;

@interface MITMapAnnotationCalloutView(Private) 

- (void)setupSubviews;

@end


@implementation MITMapAnnotationCalloutView
@synthesize annotationView = _annotationView;
@synthesize mapView = _mapView;

- (id)initWithAnnotationView:(MITMapAnnotationView *)annotationView mapView:(MITMapView*)mapView
{
	self = [super initWithFrame:CGRectMake(10, 150, 275, 125)];
	if (self) {
		self.mapView = mapView;
		self.annotationView = annotationView;
        
        self.titleLabel.text = [self.annotationView.annotation title];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:kTitleFontSize];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        
        self.detailLabel.text = [self.annotationView.annotation subtitle];
        self.detailLabel.font = [UIFont systemFontOfSize:kSubTitleFontSize];
        self.detailLabel.numberOfLines = 0;
        self.detailLabel.lineBreakMode = UILineBreakModeWordWrap;
        
        [self sizeToFit];
	}
	
	return self;
}

@end
