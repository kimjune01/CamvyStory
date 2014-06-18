

#import "AVSECommand.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface AVSEExportCommand : AVSECommand

@property (strong, nonatomic)AVAssetExportSession *exportSession;

@end
