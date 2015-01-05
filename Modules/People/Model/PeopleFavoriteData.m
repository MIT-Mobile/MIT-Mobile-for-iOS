#import "PeopleFavoriteData.h"
#import "CoreDataManager.h"

@implementation PeopleFavoriteData

+ (NSArray *) retrieveFavoritePeople
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"favoriteIndex" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"favorite == YES"];
    return [CoreDataManager objectsForEntity:@"PersonDetails" matchingPredicate:predicate sortDescriptors:@[sortDescriptor]];
}

+ (void) movePerson:(PersonDetails *)personDetails fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    NSMutableArray *favorites = [[self retrieveFavoritePeople] mutableCopy];
    [favorites removeObject:personDetails];
    [favorites insertObject:personDetails atIndex:toIndex];
    
    NSInteger index = 0;
    for( PersonDetails *person in favorites )
    {
        person.favoriteIndex = index;
        index++;
    }
    
    [CoreDataManager saveData];
}

+ (void) setPerson:(PersonDetails *)person asFavorite:(BOOL)isFavorite
{
    [person setValue:@(isFavorite) forKey:@"favorite"];
    [CoreDataManager saveData];
}

+ (void)removeAll
{
    NSMutableArray *favorites = [[self retrieveFavoritePeople] mutableCopy];
    for( PersonDetails *personDetails in favorites )
    {
        [personDetails setValue:@(NO) forKey:@"favorite"];
    }
    
    [CoreDataManager saveData];
}

@end
