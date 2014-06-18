

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

extern NSString* const AVSEEditCommandCompletionNotification;
extern NSString* const AVSEExportCommandCompletionNotification;

@interface AVSECommand : NSObject

@property (strong, nonatomic) AVMutableComposition *mutableComposition;
@property (strong, nonatomic) AVMutableVideoComposition *mutableVideoComposition;
@property (strong, nonatomic) AVMutableAudioMix *mutableAudioMix;
@property int thisManyBRecorded;

- (id)initWithComposition:(AVMutableComposition*)composition
         videoComposition:(AVMutableVideoComposition*)videoComposition
                 audioMix:(AVMutableAudioMix*)audioMix;
- (void)perform;
@end
