//
//  HeartRateViewController.h
//  Heart Rate Detector
//
//  Created by Jay Bergonia on 02/10/2019.
//  Copyright © 2019 Jay Bergonia. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CURRENT_STATE) {
    STATE_PAUSED,
    STATE_SAMPLING
};

#define MIN_FRAMES_FOR_FILTER_TO_SETTLE 10
#define DEFAULT_TIMER 30

@interface HeartRateViewController : UIViewController
// title stack
@property (weak, nonatomic) IBOutlet UILabel *heartMainTitleLbl;
@property (weak, nonatomic) IBOutlet UILabel *heartSubTitleLbl;

//main view stack
@property (weak, nonatomic) IBOutlet UIImageView *heartImage;
@property (weak, nonatomic) IBOutlet UILabel *bpmValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *bpmUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *countDownLabel;

@property (weak, nonatomic) IBOutlet UIButton *startMeasureBtn;

@end

NS_ASSUME_NONNULL_END
