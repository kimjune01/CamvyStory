

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import <APToast/UIView+APToast.h>
#import "APToast.h"
#import "APToaster.h"
#import "GAITrackedViewController.h"

@interface CMVCameraViewController : GAITrackedViewController <GPUImageMovieWriterDelegate> {
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageOutput<GPUImageInput> *otherFilter;
    GPUImageMovieWriter *movieWriter;
    NSURL *movieURL;
    int bShotCounter;
}

@property (strong, nonatomic) IBOutlet UIButton *flashButton;
- (IBAction)flashButton:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *frontFlash;
@property (strong, nonatomic) IBOutlet UIButton *makeButton;
- (IBAction)makeButton:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *timerLabel;
@property (strong, nonatomic) IBOutlet UIButton *switchButton;
@property (strong, nonatomic) IBOutlet UIButton *undoButton;
- (IBAction)undoButton:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
- (IBAction)recordButton:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *recordingIndicator;


@end
