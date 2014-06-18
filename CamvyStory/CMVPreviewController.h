#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <APToast/UIView+APToast.h>

#import "AVSECommand.h"
#import "AVSESpliceCommand.h"
#import "AVSEExportCommand.h"
#import "CompositionSingleton.h"
#import "APToast.h"
#import "APToaster.h"
#import "GAITrackedViewController.h"

@interface CMVPreviewController : GAITrackedViewController <MPMediaPickerControllerDelegate, UINavigationControllerDelegate>
{
	AVSEExportCommand *exportCommand;
    NSMutableArray *libraryAssets;
}

@property (strong, nonatomic)AVPlayer *player;
@property (retain, nonatomic)AVPlayerLayer *playerLayer;
@property double currentTime;
@property (readonly) double duration;

@property (strong, nonatomic)NSString *videoUrl;
@property (strong, nonatomic)AVMutableComposition *composition;
@property (strong, nonatomic)AVMutableVideoComposition *videoComposition;
@property (strong, nonatomic)AVMutableAudioMix *audioMix;

@property (strong, nonatomic)IBOutlet UIButton *exportButton;
@property (strong, nonatomic)IBOutlet UIView *playerView;
@property (retain, nonatomic) IBOutlet UIButton *changeMusicButton;
@property (retain, nonatomic) IBOutlet UIButton *resetButton;
@property (retain, nonatomic) IBOutlet UIButton *playButton;
@property (retain, nonatomic) IBOutlet UIButton *infoButton;
@property (strong, nonatomic) IBOutlet UIButton *moreButton;

@property int thisManyBRecorded;

- (void)reloadPlayerView;
- (void)exportWillBegin;
- (void)exportDidEnd;
- (void)editCommandCompletionNotificationReceiver:(NSNotification*)notification;
- (void)exportCommandCompletionNotificationReceiver:(NSNotification*)notification;

- (IBAction)exportToMovie:(id)sender;
- (IBAction)changeMusicButton:(id)sender;
- (IBAction)resetButton:(id)sender;
- (IBAction)infoButton:(id)sender;
- (IBAction)playButton:(id)sender;
- (IBAction)moreButton:(id)sender;



@end
