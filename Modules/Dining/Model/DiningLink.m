#import "DiningLink.h"
#import "DiningRoot.h"
#import "CoreDataManager.h"

@implementation DiningLink

@dynamic name;
@dynamic url;
@dynamic ordinality;
@dynamic root;

+ (DiningLink *)newLinkWithDictionary:(NSDictionary *)dict {
    DiningLink *link;
    if (dict[@"name"] && dict[@"url"]) {
        link = [CoreDataManager insertNewObjectForEntityForName:@"DiningLink"];
        link.name = dict[@"name"];
        link.url = dict[@"url"];
    }
    return link;
}

@end
