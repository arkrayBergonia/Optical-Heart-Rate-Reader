//
//  PulseDetector.mm
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

#import <QuartzCore/QuartzCore.h>
#import "PulseDetector.h"
#import <vector>
#import <algorithm>

#define MAX_PERIOD 1.5
#define MIN_PERIOD 0.1
#define INVALID_ENTRY -100

@implementation PulseDetector

@synthesize periodStart;


- (id) init
{
	self = [super init];
	if (self != nil) {
    // New set - reset everything to invalid
    [self reset];
	}
	return self;
}

-(void) reset {
	for(int i=0; i<MAX_PERIODS_TO_STORE; i++) {
		periods[i]=INVALID_ENTRY;
	}
	for(int i=0; i<AVERAGE_SIZE; i++) {
		upVals[i]=INVALID_ENTRY;
		downVals[i]=INVALID_ENTRY;
	}	
  freq=0.5;
  periodIndex=0;
  downValIndex=0;
  upValIndex=0;
}

-(float) addNewValue:(float) newVal atTime:(double) time {	
  // We track the number of values ​​above and below zero
    
	if(newVal>0) {
		upVals[upValIndex]=newVal;
		upValIndex++;
		if(upValIndex>=AVERAGE_SIZE) {
			upValIndex=0;
		}
	}
	if(newVal<0) {
		downVals[downValIndex]=-newVal;
		downValIndex++;
		if(downValIndex>=AVERAGE_SIZE) {
			downValIndex=0;
		}		
	}
  // calculates an average value greater than zero
    
	float count=0;
	float total=0;
	for(int i=0; i<AVERAGE_SIZE; i++) {
		if(upVals[i]!=INVALID_ENTRY) {
			count++;
			total+=upVals[i];
		}
	}
	float averageUp=total/count;
  // and average less than zero
    
	count=0;
	total=0;
	for(int i=0; i<AVERAGE_SIZE; i++) {
		if(downVals[i]!=INVALID_ENTRY) {
			count++;
			total+=downVals[i];
		}
	}
	float averageDown=total/count;

  // is the new value a down value?
	if(newVal<-0.5*averageDown) {
		wasDown=true;
	}
	
    // is the new value an up value and were we previously in the down state?
	if(newVal>=0.5*averageUp && wasDown) {
		wasDown=false;
    // work out the difference between now and the last time this happenned
		if(time-periodStart<MAX_PERIOD && time-periodStart>MIN_PERIOD) {
			periods[periodIndex]=time-periodStart;
			periodTimes[periodIndex]=time;
			periodIndex++;
			if(periodIndex>=MAX_PERIODS_TO_STORE) {
				periodIndex=0;
			}
		}
        // track when the transition happened
		periodStart=time;
	}
    
    // return up or down
	if(newVal<-0.5*averageDown) {
		return -1;
	} else if(newVal>0.5*averageUp) {
		return 1;
	}
	return 0;
}

-(float) getAverage {
	double time=CACurrentMediaTime();
	double total=0;
	double count=0;
	for(int i=0; i<MAX_PERIODS_TO_STORE; i++) {

        if(periods[i]!=INVALID_ENTRY  && time-periodTimes[i]<10) {
			count++;
			total+=periods[i];
		}
	}
    
    // do we have enough values?
	if(count>2) {
		return total/count;
	}
	return INVALID_PULSE_PERIOD;
}

@end
