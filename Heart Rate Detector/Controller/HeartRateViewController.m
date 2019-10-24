//
//  HeartRateViewController.m
//  Heart Rate Detector
//
//  Created by Jay Bergonia on 02/10/2019.
//  Copyright © 2019 Jay Bergonia. All rights reserved.
//

#import "HeartRateViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PulseDetector.h"
#import "Fiter.h"
@interface HeartRateViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>{
    BOOL showText; //自己个性化加个标识 // add their own personalized identity
    BOOL blinkStatus;
    BOOL startDetecting;
    BOOL pausedDetecting;
    BOOL cameraPressed;
    int totalSeconds;
    NSTimer *timer;
}
@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) AVCaptureDevice *camera;
@property(nonatomic, strong) PulseDetector *pulseDetector;
@property(nonatomic, strong) Fiter *fiter;
@property(nonatomic, assign) CURRENT_STATE currentState;
@property(nonatomic, assign) int validFrameCounter;

@end

@implementation HeartRateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fiter = [[Fiter alloc]init];
    
    self.pulseDetector = [[PulseDetector alloc]init];
    
    self.startMeasureBtn.layer.cornerRadius = 10;
    self.startMeasureBtn.clipsToBounds = YES;
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // show intro VC
    [self segueToVC:@"introVC"];
    
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)segueToVC:(NSString *)controllerID {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *ivc = [storyboard instantiateViewControllerWithIdentifier:controllerID];
    [self presentViewController:ivc animated:YES completion:nil];
}

- (IBAction)startBtnPressed:(id)sender {
    
    if (!startDetecting) {
        [self startCountDown];
        
        if (!pausedDetecting) {
            // start HeartRate capture
            [self startCameraCapture];
        } else {
            [self resume];
        }
    } else {
        [self pause];
        pausedDetecting = YES;
        self.heartMainTitleLbl.text = NSLocalizedString(@"heartRateMeasureTitle", nil);
        self.heartSubTitleLbl.text = NSLocalizedString(@"pressToStartSubTitle", nil);
        self.bpmValueLabel.text = @"00";
    }
    
    [self.startMeasureBtn setTitle: startDetecting ? NSLocalizedString(@"startYourMeasureText", nil) : NSLocalizedString(@"cancelYourMeasureText", nil) forState:UIControlStateNormal];
    startDetecting = !startDetecting ? YES : NO;
}


- (void) startCountDown {
    self.countDownLabel.hidden = NO;
    totalSeconds = DEFAULT_TIMER;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0
      target:self
    selector:@selector(timer)
    userInfo:nil
     repeats:YES];
}

- (void)timer {
    
    if (cameraPressed) {
        totalSeconds--;
        _countDownLabel.text = [NSString stringWithFormat:NSLocalizedString(@"countDownText", nil), totalSeconds];
    }
    
    if ( totalSeconds == 0 ) {
        [timer invalidate];
        [self.heartImage setImage:[UIImage imageNamed:@"digital_heart"]];
        self.countDownLabel.hidden = YES;
        
        NSTimer *quick = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startBtnPressed:) userInfo:nil repeats:NO];
        
        if (![self.bpmValueLabel.text isEqual: @"00"]) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"heartRateResultText", nil)
                                       message:[NSString stringWithFormat:@"%@ BPM", self.bpmValueLabel.text]
                                       preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {}];

            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    
    if(blinkStatus == NO){
        [self.heartImage setImage:[UIImage imageNamed:@"red_heart"]];
        blinkStatus = YES;
    }else {
        [self.heartImage setImage:[UIImage imageNamed:@"digital_heart"]];
        blinkStatus = NO;
    }
}

//start capturing frame
- (void) startCameraCapture {
    
    // Create AVCapture
    self.session = [[AVCaptureSession alloc]init];
    
    // get the default camera equipment
    self.camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Create a AVCaptureInput camera equipment
    NSError *error=nil;
    AVCaptureInput* cameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.camera error:&error];
    if (cameraInput == nil) {
        NSLog(@"Error to create camera capture:%@",error);
    }
    
    // set the output
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // create a queue run captured
    dispatch_queue_t captureQueue=dispatch_queue_create("captureQueue", NULL);
    
    // set their own commission to capture
    [videoOutput setSampleBufferDelegate:self queue:captureQueue];
    
    //Configure pixel format
    videoOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, nil];
    
    // minimum acceptable frame rate to 10 fps
    videoOutput.minFrameDuration=CMTimeMake(1, 10);
    
    
    // size of the frame - minimum frame (size available)
    [self.session setSessionPreset:AVCaptureSessionPresetLow];
    
    // add an input and output
    [self.session addInput:cameraInput];
    [self.session addOutput:videoOutput];
    
    //start up
    [self.session startRunning];
    
    // Camera status
    self.currentState=STATE_SAMPLING;
    
    //Open torch mode - no it can not detect a pulse, but it enhances capture rate
    if([self.camera isTorchModeSupported:AVCaptureTorchModeOn]) {
        [self.camera lockForConfiguration:nil];
        self.camera.torchMode=AVCaptureTorchModeOn;
        [self.camera unlockForConfiguration];
    }
    
    // Stop program
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    //Timer executed once every 0.1 seconds
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update) userInfo:nil repeats:YES];

}

-(void) stopCameraCapture {
    [self.session stopRunning];
    self.session=nil;
}

#pragma mark Pause and Resume of pulse detection
-(void) pause {
    if(self.currentState==STATE_PAUSED) return;
    
    //Turn off the flash
    if([self.camera isTorchModeSupported:AVCaptureTorchModeOn]) {
        [self.camera lockForConfiguration:nil];
        self.camera.torchMode=AVCaptureTorchModeOff;
        [self.camera unlockForConfiguration];
    }
    self.currentState=STATE_PAUSED;
    
    // exit the program or turn off the background
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

-(void) resume {
    if(self.currentState!=STATE_PAUSED) return;
    
    // turn off the flash
    if([self.camera isTorchModeSupported:AVCaptureTorchModeOn]) {
        [self.camera lockForConfiguration:nil];
        self.camera.torchMode=AVCaptureTorchModeOn;
        [self.camera unlockForConfiguration];
    }
    self.currentState=STATE_SAMPLING;
    
    // exit the program or turn off the background
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

// find online algorithm
void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v ) {
    float min, max, delta;
    min = MIN( r, MIN(g, b ));
    max = MAX( r, MAX(g, b ));
    *v = max;
    delta = max - min;
    if( max != 0 )
        *s = delta / max;
    else {
        // r = g = b = 0
        *s = 0;
        *h = -1;
        return;
    }
    if( r == max )
        *h = ( g - b ) / delta;
    else if( g == max )
        *h=2+(b-r)/delta;
    else
        *h=4+(r-g)/delta;
    *h *= 60;
    if( *h < 0 )
        *h += 360;
}

//processing video frames
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    // judge to stop and do not do any processing
    if(self.currentState==STATE_PAUSED) {
        
        // reset our frame counter
        self.validFrameCounter = 0;
        return;
    }
    
    
    // Analyzing fluctuations in blood // Get Value
    if (self.validFrameCounter == 0) {
        
   
        dispatch_async(dispatch_get_main_queue(), ^{
            // callback or notify the main thread is refreshed,
            self.heartMainTitleLbl.text=NSLocalizedString(@"placeFingerText", nil);
        });

    } else {
        
        
        // get the data (may be used to display a progress bar or electrocardiogram) ********
        NSLog(@"int:%d",self.validFrameCounter);
        //*********
        if (!showText) {
            //notify the main thread refresh
            dispatch_async(dispatch_get_main_queue(), ^{
                // callback or notify the main thread is refreshed,
                self.heartMainTitleLbl.text = NSLocalizedString(@"detectingPulseText", nil);
            });
        }
    }
    
    // image buffer
    CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock image buffer
    CVPixelBufferLockBaseAddress(cvimgRef,0);
    
    //Access to data
    size_t width=CVPixelBufferGetWidth(cvimgRef);
    
    size_t height=CVPixelBufferGetHeight(cvimgRef);
    
    // Acquiring an image bytes
    uint8_t *buf=(uint8_t *) CVPixelBufferGetBaseAddress(cvimgRef);
    
    size_t bprow=CVPixelBufferGetBytesPerRow(cvimgRef);
    
    //The average value of the rgb frame
    float r=0,g=0,b=0;
    for(int y=0; y<height; y++) {
        for(int x=0; x<width*4; x+=4) {
            b+=buf[x];
            g+=buf[x+1];
            r+=buf[x+2];
        }
        buf+=bprow;
    }
    r/=255*(float) (width*height);
    g/=255*(float) (width*height);
    b/=255*(float) (width*height);
    
    // to convert from rgb hsv colourspace
    float h,s,v;
    
    RGBtoHSV(r, g, b, &h, &s, &v);
    
    // do a check to see if a finger is placed in the camera
    if(s>0.5 && v>0.5) {
        
        // increase the effective number of frames
        self.validFrameCounter++;
        
        // tone value filter, the filter is a simple band-pass filter to eliminate high frequency noise and any DC component
        float filtered=[self.fiter processValue:h];
        
        
        if(self.validFrameCounter > MIN_FRAMES_FOR_FILTER_TO_SETTLE) {
            
            // Add a new value into a pulse detector
            [self.pulseDetector addNewValue:filtered atTime:CACurrentMediaTime()];
        }
    } else {
        self.validFrameCounter = 0;
        
        // clear pulse detector - we only need to do this once
        [self.pulseDetector reset];
    }
}

-(void) update {
    
    NSInteger distance =  MIN(100, (100 * self.validFrameCounter)/MIN_FRAMES_FOR_FILTER_TO_SETTLE);
    
    // display 100 a distance equal Loading
    if (distance == 100) showText = NO;
    
    cameraPressed = (distance == 100) ? YES : NO;
    
    self.heartSubTitleLbl.text = (self.currentState!=STATE_PAUSED) ? [NSString stringWithFormat:NSLocalizedString(@"setFingerOnCameraText", nil),distance] : NSLocalizedString(@"pressToStartSubTitle", nil);
    
    // If stopped and do nothing
    if(self.currentState==STATE_PAUSED) return;
    
    // The average period of the pulse repetition frequency of the pulse detector to give
    float avePeriod=[self.pulseDetector getAverage];
    
    
    // value obtained (after processing)
//    NSLog(@"avePeriod:%f",avePeriod);
    
    if(avePeriod==INVALID_PULSE_PERIOD) {
        
        // no value available temporarily to do post-processing may be used

        
    } else {
        
        showText = YES;// displays heart rate value
        
        // show value is out there
        float pulse=60.0/avePeriod;
   
        dispatch_async(dispatch_get_main_queue(), ^{
            // Callback or notify the main thread is refreshing
            self.bpmValueLabel.text=[NSString stringWithFormat:@"%0.0f", pulse];
            

        });
        
    }
}


@end
