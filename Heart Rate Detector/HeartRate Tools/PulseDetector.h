//
//  PulseDetector.h
//  HeartRate_Demo
//
//  Created by Gurpreet Singh on 31/10/2013.
//  Copyright (c) 2015 Pubnub. All rights reserved.
//

/*
The PulseDetector class defines the functions addNewValue( ) and getAverage( ) which are used to get the pulse rate from valid frames out of 10 frames per second and derive the average reading for a one minute interval.
 
 PulseDetectorクラスは、毎秒10個のフレームのうち、有効なフレームから脈拍数を取得し、1分間隔の平均読取値を導出するために使用されるaddNewValue（）とgetAverage（）関数を定義します。
 
source: https://www.pubnub.com/blog/tutorial-realtime-ios-heart-rate-monitor-dashboard/
*/

#import <Foundation/Foundation.h>

#define MAX_PERIODS_TO_STORE 20
#define AVERAGE_SIZE 20
#define INVALID_PULSE_PERIOD -1

@interface PulseDetector : NSObject {
	float upVals[AVERAGE_SIZE];
	float downVals[AVERAGE_SIZE];
	int upValIndex;
	int downValIndex;
	
	float lastVal;
	float periodStart;
	double periods[MAX_PERIODS_TO_STORE];
	double periodTimes[MAX_PERIODS_TO_STORE];
	
	int periodIndex;
	bool started;
	float freq;
	float average;
	
	bool wasDown;
}

@property (nonatomic, assign) float periodStart;


-(float) addNewValue:(float) newVal atTime:(double) time;
-(float) getAverage;
-(void) reset;

@end
