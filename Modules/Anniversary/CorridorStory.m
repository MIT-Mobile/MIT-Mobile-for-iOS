#import "CorridorStory.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"

@implementation CorridorStory 

@dynamic title;
@dynamic firstName;
@dynamic date;
@dynamic imageWidth;
@dynamic imageHeight;
@dynamic imageURL;
@dynamic imageData;
@dynamic htmlBody;
@dynamic plainBody;
@dynamic affiliation;
@dynamic lastName;
@dynamic uniqueID;
@dynamic ordinality;

+ (CorridorStory *)corridorStoryWithDictionary:(NSDictionary *)aDict {
	
	NSString *unique = [aDict objectForKey:@"unique-id"];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uniqueID == %@", unique];
	CorridorStory *corridorStory = [[CoreDataManager objectsForEntity:@"CorridorStory" matchingPredicate:predicate] lastObject];
	if (!corridorStory) {
		corridorStory = [CoreDataManager insertNewObjectForEntityForName:@"CorridorStory"];
	}

	if (corridorStory) {
		corridorStory.title = [aDict objectForKey:@"title"];
		corridorStory.firstName = [aDict objectForKey:@"firstname"];
		corridorStory.lastName = [aDict objectForKey:@"lastname"];
		corridorStory.affiliation = [aDict objectForKey:@"affiliation"];
		
		NSTimeInterval timestamp = [[aDict objectForKey:@"date-posted-unix"] doubleValue];
		NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
		corridorStory.date = postDate;
		
//		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//		formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
//		[formatter setDateFormat:@"EEE, MM/dd/y"];
//		[formatter setTimeZone:[NSTimeZone localTimeZone]];
//		NSDate *postDate = [formatter dateFromString:[aDict objectForKey:@"date-posted"]];
//		[formatter release];
		
		corridorStory.htmlBody = [aDict objectForKey:@"body"];
		corridorStory.plainBody = [[aDict objectForKey:@"plain-text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		// note that this code accepts dimensions as either strings or integers
		corridorStory.imageWidth = [NSNumber numberWithInteger:[[aDict valueForKeyPath:@"image.width"] integerValue]];
		corridorStory.imageHeight = [NSNumber numberWithInteger:[[aDict valueForKeyPath:@"image.height"] integerValue]];
		corridorStory.imageURL = [aDict valueForKeyPath:@"image.src"];
		
		corridorStory.imageData = nil; // filled in later by async img view
		
		corridorStory.uniqueID = unique;
		
		// Sorts stories in the order they were created since launching the application, but with the addition of the current time so that the order is meaningful across runs of the application
		static NSTimeInterval order_parsed = 0;
		if (order_parsed == 0) {
			// 1293861600 == 1/1/2011
			NSDate *today = [NSDate date];
			NSDate *newYear = [NSDate dateWithTimeIntervalSince1970:1293861600.0];
			order_parsed = [today timeIntervalSinceDate:newYear] * 100.0;
		}
		order_parsed--; // most recently parsed have a higher number
		corridorStory.ordinality = [NSNumber numberWithInteger:order_parsed];
	}
	return corridorStory;
}

- (NSString *)description {

	return [NSString stringWithFormat:@"%@ : %@", self.title, [self.plainBody substringToMaxIndex:20]];
	
}


@end
