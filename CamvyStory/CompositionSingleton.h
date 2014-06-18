

#import <Foundation/Foundation.h>

@interface CompositionSingleton : NSObject{
}

@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, retain) NSURL *musicPath;
@property (nonatomic, retain) NSMutableArray *aShotListURLs;
@property (nonatomic, retain) NSMutableArray *bShotListURLs;
@property int thisManyBrollRecorded;

- (void)resetSingleton;
+ (id)sharedSingleton;

@end
