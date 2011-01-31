#import "FeatureLink.h"
#import "CoreDataManager.h"

@implementation FeatureLink 

@dynamic featureSection;
@dynamic featureID;
@dynamic tintColor;
@dynamic subtitle;
@dynamic title;
@dynamic photo;
@dynamic photoURL;
@dynamic photoWidth;
@dynamic photoHeight;
@dynamic url;
@dynamic sortOrder;


+ (FeatureLink *)featureLinkWithDictionary:(NSDictionary *)aDict {
	FeatureLink *featureLink = [CoreDataManager insertNewObjectForEntityForName:@"FeatureLink"];

	static NSInteger fallbackSortOrder = 1000; // something to fall back on in case sort order is not defined on the server
	
	if (featureLink) {
		featureLink.featureID = [aDict objectForKey:@"id"];
		featureLink.title = [aDict objectForKey:@"title"];
		featureLink.subtitle = [aDict objectForKey:@"subtitle"];
		featureLink.tintColor = [aDict objectForKey:@"tint-color"];
		featureLink.url = [aDict objectForKey:@"url"];
		featureLink.photoURL = [aDict objectForKey:@"photo-url"];
		
		NSDictionary *dimensions = [aDict objectForKey:@"dimensions"];
		if (dimensions) {
			featureLink.photoWidth = [dimensions objectForKey:@"width"];
			featureLink.photoHeight = [dimensions objectForKey:@"height"];
		}
		
		NSNumber *order = [aDict objectForKey:@"sort-order"];
		if (!order) {
			order = [NSNumber numberWithInteger:fallbackSortOrder];
			fallbackSortOrder++;
		}
		featureLink.sortOrder = order;
	}
	return featureLink;
}

- (NSString *)description {
	return self.title;
}

@end
